//
//  EditPresetSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import PhotosUI
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
  @State var showBackgroundImage: Bool = false
  @State var useArtworkAsBackground: Bool = false
  @State var backgroundImageData: Data?
  @State var backgroundBlurRadius: Double = 15.0
  @State var backgroundOpacity: Double = 0.65
  @State var selectedBackgroundPhoto: PhotosPickerItem?
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
    .onChange(of: selectedBackgroundPhoto) { _, newItem in
      print("🎨 EditPresetSheet: Background photo selection changed")
      if let item = newItem {
        Task {
          await loadBackgroundImage(from: item)
          // Reset selection to allow selecting the same image again
          await MainActor.run {
            selectedBackgroundPhoto = nil
          }
        }
      }
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
      backgroundSection
      deleteSection
    }
  }

  func setupInitialValues() {
    presetName = preset.name
    creatorName = preset.creatorName ?? ""
    selectedSounds = Set(preset.soundStates.map(\.fileName))
    artworkData = preset.artworkData
    showBackgroundImage = preset.showBackgroundImage ?? false
    // Default to using artwork as background if artwork exists and useArtworkAsBackground hasn't been set
    useArtworkAsBackground = preset.useArtworkAsBackground ?? (preset.artworkData != nil)
    backgroundImageData = preset.backgroundImageData
    backgroundBlurRadius = preset.backgroundBlurRadius ?? 15.0
    backgroundOpacity = preset.backgroundOpacity ?? 0.65
  }

  func applyChangesInstantly() {
    print("🎨 EditPresetSheet: Applying changes instantly")
    guard !presetName.isEmpty else {
      error = "Preset name cannot be empty"
      return
    }

    do {
      let updatedPreset = createUpdatedPreset()
      print(
        "🎨 EditPresetSheet: Updated preset has background: \(updatedPreset.backgroundImageData != nil)"
      )

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
    updatedPreset.showBackgroundImage = showBackgroundImage
    updatedPreset.useArtworkAsBackground = useArtworkAsBackground
    updatedPreset.backgroundImageData = backgroundImageData
    updatedPreset.backgroundBlurRadius = backgroundBlurRadius
    updatedPreset.backgroundOpacity = backgroundOpacity
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

  func loadBackgroundImage(from item: PhotosPickerItem) async {
    do {
      print("🎨 EditPresetSheet: Loading background image...")
      if let data = try await item.loadTransferable(type: Data.self) {
        // Process the image to optimize size
        if let processedData = processImage(data: data) {
          await MainActor.run {
            self.backgroundImageData = processedData
            print("🎨 EditPresetSheet: Background image loaded successfully")
          }
        }
      }
    } catch {
      print("🎨 EditPresetSheet: Failed to load image: \(error)")
    }
  }

  private func processImage(data: Data) -> Data? {
    #if os(macOS)
      guard let image = NSImage(data: data) else { return nil }

      // Resize if needed (max 2048x2048)
      let maxSize: CGFloat = 2048
      var targetSize = image.size

      if image.size.width > maxSize || image.size.height > maxSize {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        targetSize = CGSize(
          width: image.size.width * scale,
          height: image.size.height * scale
        )
      }

      let resizedImage = NSImage(size: targetSize)
      resizedImage.lockFocus()
      image.draw(
        in: NSRect(origin: .zero, size: targetSize),
        from: NSRect(origin: .zero, size: image.size),
        operation: .copy,
        fraction: 1.0
      )
      resizedImage.unlockFocus()

      // Convert to JPEG with compression
      guard let tiffData = resizedImage.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData)
      else { return nil }

      return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])

    #else
      guard let image = UIImage(data: data) else { return nil }

      // Resize if needed (max 2048x2048)
      let maxSize: CGFloat = 2048
      var targetSize = image.size

      if image.size.width > maxSize || image.size.height > maxSize {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        targetSize = CGSize(
          width: image.size.width * scale,
          height: image.size.height * scale
        )
      }

      let renderer = UIGraphicsImageRenderer(size: targetSize)
      let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
      }

      return resizedImage.jpegData(compressionQuality: 0.8)
    #endif
  }

}
