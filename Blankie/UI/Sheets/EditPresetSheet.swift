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
  @State private var presetName: String = ""
  @State private var creatorName: String = ""
  @State private var selectedSounds: Set<String> = []
  @State private var error: String?
  @State private var showingSoundSelection = false
  @State private var artworkData: Data?
  @State private var showingImagePicker = false
  @State private var showingImageCropper = false
  #if os(iOS) || os(visionOS)
    @State private var selectedImage: UIImage?
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
          leading: Button("Cancel") { isPresented = nil },
          trailing: !preset.isDefault
            ? Button("Save") { savePresetChanges() }
              .fontWeight(.semibold)
              .disabled(presetName.isEmpty || selectedSounds.isEmpty)
            : nil
        )
      #else
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 500, minHeight: preset.isDefault ? 200 : 300)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { isPresented = nil }
          }
          if !preset.isDefault {
            ToolbarItem(placement: .confirmationAction) {
              Button("Save") { savePresetChanges() }
              .keyboardShortcut(.return)
              .disabled(presetName.isEmpty || selectedSounds.isEmpty)
            }
          }
        }
      #endif
      .onAppear(perform: setupInitialValues)
      #if os(iOS) || os(visionOS)
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
  }
}

extension EditPresetSheet {
  var defaultPresetSection: some View {
    Section("Preset Information") {
      LabeledContent("Name", value: "All Sounds")
      Text("The default preset cannot be modified")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  var editablePresetSections: some View {
    Group {
      basicInfoSection
      errorSection
      creatorSection
      artworkSection
      soundsSection
    }
  }

  var basicInfoSection: some View {
    Section {
      HStack {
        Text("Name")
          .foregroundStyle(.secondary)
        Spacer()
        TextField("Required", text: $presetName)
          .multilineTextAlignment(.trailing)
      }
    }
  }

  @ViewBuilder
  var errorSection: some View {
    if let error = error {
      Section {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
      }
    }
  }

  var creatorSection: some View {
    Section {
      HStack {
        Text("Creator")
          .foregroundStyle(.secondary)
        Spacer()
        TextField("Optional", text: $creatorName)
          .multilineTextAlignment(.trailing)
      }
    } footer: {
      Text("Shows in Now Playing info")
        .font(.caption)
    }
  }

  var artworkSection: some View {
    Section {
      Button {
        showingImagePicker = true
      } label: {
        HStack {
          Text("Artwork")
          Spacer()
          artworkPreview
        }
      }
      .buttonStyle(.plain)
    } footer: {
      Text("Custom artwork for Now Playing")
        .font(.caption)
    }
  }

  @ViewBuilder
  var artworkPreview: some View {
    if let artworkData = artworkData {
      #if os(iOS) || os(visionOS)
        if let uiImage = UIImage(data: artworkData) {
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      #elseif os(macOS)
        if let nsImage = NSImage(data: artworkData) {
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      #endif
    } else {
      Text("Select Image")
        .foregroundStyle(.secondary)
    }
  }

  var soundsSection: some View {
    Section {
      NavigationLink(
        destination: SoundSelectionView(
          selectedSounds: $selectedSounds, orderedSounds: orderedSounds)
      ) {
        HStack {
          Text("Sounds")
          Spacer()
          Text("\(selectedSounds.count) Sounds")
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  func setupInitialValues() {
    presetName = preset.name
    creatorName = preset.creatorName ?? ""
    selectedSounds = Set(preset.soundStates.map(\.fileName))
    artworkData = preset.artworkData
  }

  func savePresetChanges() {
    guard !presetName.isEmpty else {
      error = "Preset name cannot be empty"
      return
    }

    do {
      let currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
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

      var updatedPreset = preset
      updatedPreset.name = presetName
      updatedPreset.creatorName = creatorName.isEmpty ? nil : creatorName
      updatedPreset.soundStates = selectedSoundStates
      updatedPreset.artworkData = artworkData
      updatedPreset.lastModifiedVersion = currentVersion

      var currentPresets = presetManager.presets
      if let index = currentPresets.firstIndex(where: { $0.id == preset.id }) {
        currentPresets[index] = updatedPreset
        presetManager.setPresets(currentPresets)
        presetManager.savePresets()

        if presetManager.currentPreset?.id == preset.id {
          try presetManager.applyPreset(updatedPreset)
        }
      }

      isPresented = nil
    } catch {
      self.error = "Failed to save changes"
    }
  }
}

// MARK: - macOS Image Handling
#if os(macOS)
  extension EditPresetSheet {
    fileprivate func handleMacOSImageImport(_ result: Result<[URL], Error>) {
      switch result {
      case .success(let urls):
        guard let url = urls.first else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
          if accessing {
            url.stopAccessingSecurityScopedResource()
          }
        }

        do {
          let data = try Data(contentsOf: url)
          if let nsImage = NSImage(data: data) {
            if abs(nsImage.size.width - nsImage.size.height) < 1 {
              artworkData = nsImage.jpegData(compressionQuality: 0.8)
            } else {
              let squareImage = cropToSquareMacOS(image: nsImage)
              artworkData = squareImage.jpegData(compressionQuality: 0.8)
            }
          } else {
            artworkData = data
          }
        } catch {
          print("❌ macOS Image Picker: Failed to load image: \(error)")
        }
      case .failure(let error):
        print("❌ macOS Image Picker: Image picker error: \(error)")
      }
    }

    fileprivate func cropToSquareMacOS(image: NSImage) -> NSImage {
      let size = min(image.size.width, image.size.height)
      let offsetX = (image.size.width - size) / 2
      let offsetY = (image.size.height - size) / 2
      let cropRect = NSRect(x: offsetX, y: offsetY, width: size, height: size)

      guard
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(
          to: cropRect)
      else {
        return image
      }

      return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
  }
#endif
