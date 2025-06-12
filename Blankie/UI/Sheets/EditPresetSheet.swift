//
//  EditPresetSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

struct EditPresetSheet: View {
  let preset: Preset
  @Binding var isPresented: Preset?
  @ObservedObject private var presetManager = PresetManager.shared
  @ObservedObject private var audioManager = AudioManager.shared
  @State var presetName: String = ""
  @State var creatorName: String = ""
  @State var selectedSounds: Set<String> = []
  @State var error: String?
  @State var showingSoundSelection = false
  @State var artworkData: Data?
  @State var showingImagePicker = false
  @State var showingImageCropper = false
  @State var presetToDelete: Preset?
  #if os(iOS) || os(visionOS)
    @State private var selectedImage: UIImage?
    @State private var navigationPath = NavigationPath()
  #endif
  @Environment(\.dismiss) private var dismiss

  var orderedSounds: [Sound] {
    audioManager.sounds.sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        if preset.isDefault {
          defaultPresetSection
        } else {
          editablePresetSections
        }
      }
      .navigationTitle(preset.isDefault ? "View Preset" : "Edit Preset")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
          leading: Button("Done") { isPresented = nil }
        )
      #else
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 500, minHeight: preset.isDefault ? 200 : 300)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Done") { isPresented = nil }
            .keyboardShortcut(.escape)
          }
        }
      #endif
      .onAppear(perform: setupInitialValues)
      #if os(iOS) || os(visionOS)
        .sheet(isPresented: $showingSoundSelection) {
          NavigationStack {
            SoundSelectionView(
              selectedSounds: $selectedSounds,
              orderedSounds: orderedSounds
            )
            .navigationBarItems(
              leading: Button("Done") {
                showingSoundSelection = false
              }
            )
          }
        }
        .sheet(isPresented: $showingImagePicker) {
          ImagePicker(selectedImage: $selectedImage)
          .onDisappear {
            if selectedImage != nil {
              showingImageCropper = true
            }
          }
        }
        .sheet(isPresented: $showingImageCropper) {
          if let image = selectedImage {
            ImageCropperView(
              originalImage: .constant(image),
              croppedImageData: $artworkData
            )
          }
        }
      #else
        .fileImporter(
          isPresented: $showingImagePicker,
          allowedContentTypes: [.image],
          allowsMultipleSelection: false
        ) { result in
          handleMacOSImageImport(result)
        }
      #endif
    }
    .alert(
      "Delete Preset",
      isPresented: .init(
        get: { presetToDelete != nil },
        set: { if !$0 { presetToDelete = nil } }
      )
    ) {
      Button("Cancel", role: .cancel) {
        presetToDelete = nil
      }
      Button("Delete", role: .destructive) {
        if let preset = presetToDelete {
          deletePreset(preset)
        }
      }
    } message: {
      if let preset = presetToDelete {
        Text("Are you sure you want to delete \"\(preset.name)\"? This action cannot be undone.")
      }
    }
  }
}

extension EditPresetSheet {
  var editablePresetSections: some View {
    Group {
      errorSection
      soundsSection
      nowPlayingInfoSection  // Name, Creator & Artwork together
      deleteSection
    }
  }

  func setupInitialValues() {
    presetName = preset.name
    creatorName = preset.creatorName ?? ""
    selectedSounds = Set(preset.soundStates.map(\.fileName))
    artworkData = preset.artworkData
  }

  func applyChangesInstantly() {
    guard !presetName.isEmpty else {
      error = "Preset name cannot be empty"
      return
    }

    do {
      let updatedPreset = createUpdatedPreset()

      var currentPresets = presetManager.presets
      if let index = currentPresets.firstIndex(where: { $0.id == preset.id }) {
        currentPresets[index] = updatedPreset
        presetManager.setPresets(currentPresets)

        // Update current preset reference if this is the active preset
        if presetManager.currentPreset?.id == preset.id {
          presetManager.setCurrentPreset(updatedPreset)
          // Apply the preset changes immediately if it's currently active
          try presetManager.applyPreset(updatedPreset)
        }

        // Save presets directly without overriding the current preset state
        savePresetsDirectly()
      }
    } catch {
      print("❌ EditPresetSheet: Failed to apply changes - \(error)")
      self.error = "Failed to apply changes: \(error.localizedDescription)"
    }
  }

  private func createUpdatedPreset() -> Preset {
    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // Create sound states for all selected sounds
    let selectedSoundStates =
      orderedSounds
      .filter { selectedSounds.contains($0.fileName) }
      .map { sound in
        PresetState(
          fileName: sound.fileName,
          isSelected: sound.isSelected,
          volume: sound.volume
        )
      }

    print(
      "🎨 EditPresetSheet: Creating \(selectedSoundStates.count) sound states from \(selectedSounds.count) selected sounds"
    )

    var updatedPreset = preset
    updatedPreset.name = presetName
    updatedPreset.creatorName = creatorName.isEmpty ? nil : creatorName
    updatedPreset.soundStates = selectedSoundStates
    updatedPreset.artworkData = artworkData
    updatedPreset.lastModifiedVersion = currentVersion

    return updatedPreset
  }

  // MARK: - Direct Preset Saving

  private func savePresetsDirectly() {
    let defaultPreset = presetManager.presets.first { $0.isDefault }
    let customPresets = presetManager.presets.filter { !$0.isDefault }

    if let defaultPreset = defaultPreset {
      PresetStorage.saveDefaultPreset(defaultPreset)
    }
    PresetStorage.saveCustomPresets(customPresets)
    print("🎨 EditPresetSheet: Presets saved directly without state override")
  }

  private func deletePreset(_ preset: Preset) {
    presetManager.deletePreset(preset)
    isPresented = nil
  }

}
