//
//  PresetSheets.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  import PhotosUI
#elseif os(macOS)
  import AppKit

  extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
      guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
      }
      let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
      return bitmapRep.representation(
        using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
  }
#endif

struct SoundSelectionView: View {
  @Binding var selectedSounds: Set<String>
  let orderedSounds: [Sound]
  @Environment(\.dismiss) private var dismiss

  private func soundRowContent(for sound: Sound) -> some View {
    HStack(spacing: 12) {
      let isRowSelected = selectedSounds.contains(sound.fileName)

      Image(systemName: sound.systemIconName)
        .foregroundColor(isRowSelected ? sound.customColor : .white)
        .frame(width: 20)

      Text(sound.title)

      Spacer()

      Image(systemName: isRowSelected ? "checkmark" : "")
        .foregroundStyle(.accent)
    }
  }

  var body: some View {
    List {
      ForEach(orderedSounds, id: \.id) { sound in
        soundRowContent(for: sound)
          .contentShape(Rectangle())
          .onTapGesture {
            if selectedSounds.contains(sound.fileName) {
              selectedSounds.remove(sound.fileName)
            } else {
              selectedSounds.insert(sound.fileName)
            }
          }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Sounds")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarItems(
        trailing: Menu {
          Button("Select All") {
            selectedSounds = Set(orderedSounds.map(\.fileName))
          }
          Button("Clear All") {
            selectedSounds.removeAll()
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      )
    #else
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Menu {
            Button("Select All") {
              selectedSounds = Set(orderedSounds.map(\.fileName))
            }
            Button("Clear All") {
              selectedSounds.removeAll()
            }
          } label: {
            Label("Options", systemImage: "ellipsis.circle")
          }
        }
      }
    #endif
  }
}

struct CreatePresetSheet: View {
  @Binding var isPresented: Bool
  @ObservedObject private var presetManager = PresetManager.shared
  @ObservedObject private var audioManager = AudioManager.shared
  @State private var presetName = ""
  @State private var creatorName = ""
  @State private var error: String?
  @State private var selectedSounds: Set<String> = []
  @State private var showingSoundSelection = false
  @State private var artworkData: Data?
  @State private var showingImagePicker = false
  @State private var showingImageCropper = false
  #if os(iOS) || os(visionOS)
    @State private var selectedImage: UIImage?
  #endif
  @Environment(\.dismiss) private var dismiss

  // Get sounds in alphabetical order
  var orderedSounds: [Sound] {
    audioManager.sounds.sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            Text("Name")
              .foregroundStyle(.secondary)
            Spacer()
            TextField("Required", text: $presetName)
              .multilineTextAlignment(.trailing)
          }
        }

        if let error = error {
          Section {
            Label(error, systemImage: "exclamationmark.triangle.fill")
              .foregroundStyle(.red)
          }
        }

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

        Section {
          Button {
            showingImagePicker = true
          } label: {
            HStack {
              Text("Artwork")
              Spacer()
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
          }
          .buttonStyle(.plain)
        } footer: {
          Text("Custom artwork for Now Playing")
            .font(.caption)
        }

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
      .navigationTitle("New Preset")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
          leading: Button("Cancel") {
            isPresented = false
          },
          trailing: Button("Create") {
            createPreset()
          }
          .fontWeight(.semibold)
          .disabled(presetName.isEmpty || selectedSounds.isEmpty)
        )
      #else
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 500, minHeight: 300)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              isPresented = false
            }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Create") {
              createPreset()
            }
            .keyboardShortcut(.return)
            .disabled(presetName.isEmpty || selectedSounds.isEmpty)
          }
        }
      #endif
      .onAppear {
        // Start with all sounds selected by default
        if selectedSounds.isEmpty {
          selectedSounds = Set(orderedSounds.map(\.fileName))
        }
      }
      #if os(iOS) || os(visionOS)
        .sheet(isPresented: $showingImagePicker) {
          ImagePicker(
            imageData: $artworkData, selectedImage: $selectedImage,
            showingImageCropper: $showingImageCropper)
        }
        .sheet(isPresented: $showingImageCropper) {
          if let image = selectedImage {
            ImageCropperView(
              isPresented: $showingImageCropper, artworkData: $artworkData, originalImage: image)
          }
        }
      #else
        .fileImporter(
          isPresented: $showingImagePicker,
          allowedContentTypes: [.image],
          allowsMultipleSelection: false
        ) { result in
          switch result {
          case .success(let urls):
            print("🎨 macOS Image Picker: Success with \(urls.count) URLs")
            if let url = urls.first {
              print("🎨 macOS Image Picker: Processing file at \(url)")

              // Start accessing security-scoped resource
              let accessing = url.startAccessingSecurityScopedResource()
              defer {
                if accessing {
                  url.stopAccessingSecurityScopedResource()
                }
              }

              do {
                let data = try Data(contentsOf: url)
                print("🎨 macOS Image Picker: Loaded \(data.count) bytes from file")

                if let nsImage = NSImage(data: data) {
                  print("🎨 macOS Image Picker: Created NSImage with size \(nsImage.size)")

                  // Check if image is already square
                  if abs(nsImage.size.width - nsImage.size.height) < 1 {
                    print("🎨 macOS Image Picker: Image is already square, using as-is")
                    // Already square, use as-is
                    if let jpegData = nsImage.jpegData(compressionQuality: 0.8) {
                      artworkData = jpegData
                      print(
                        "🎨 macOS Image Picker: ✅ Successfully converted to JPEG (\(jpegData.count) bytes)"
                      )
                    } else {
                      print("❌ macOS Image Picker: Failed to convert NSImage to JPEG")
                    }
                  } else {
                    print("🎨 macOS Image Picker: Image is not square, cropping to square")
                    // For macOS, auto-crop for now (could add cropping UI later)
                    let squareImage = cropToSquareMacOS(image: nsImage)
                    print("🎨 macOS Image Picker: Cropped to size \(squareImage.size)")
                    if let jpegData = squareImage.jpegData(compressionQuality: 0.8) {
                      artworkData = jpegData
                      print(
                        "🎨 macOS Image Picker: ✅ Successfully converted cropped image to JPEG (\(jpegData.count) bytes)"
                      )
                    } else {
                      print("❌ macOS Image Picker: Failed to convert cropped NSImage to JPEG")
                    }
                  }
                } else {
                  print("❌ macOS Image Picker: Failed to create NSImage from data, using raw data")
                  artworkData = data
                }
              } catch {
                print("❌ macOS Image Picker: Failed to load image: \(error)")
              }
            } else {
              print("❌ macOS Image Picker: No URL in success result")
            }
          case .failure(let error):
            print("❌ macOS Image Picker: Image picker error: \(error)")
          }
        }
      #endif
    }
  }

  private func createPreset() {
    guard !presetName.isEmpty else {
      error = "Preset name cannot be empty"
      return
    }

    do {
      let currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
      // Only include selected sounds in the preset
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

      let newPreset = Preset(
        id: UUID(),
        name: presetName,
        soundStates: selectedSoundStates,
        isDefault: false,
        createdVersion: currentVersion,
        lastModifiedVersion: currentVersion,
        soundOrder: nil,  // Let preset display use alphabetical order
        creatorName: creatorName.isEmpty ? nil : creatorName,
        artworkData: artworkData
      )

      print(
        "🎨 CreatePresetSheet: Creating preset '\(presetName)' with artwork: \(artworkData != nil ? "✅ \(artworkData!.count) bytes" : "❌ None")"
      )

      // Add to presets and apply
      var currentPresets = presetManager.presets
      currentPresets.append(newPreset)
      presetManager.setPresets(currentPresets)
      presetManager.updateCustomPresetStatus()
      presetManager.savePresets()

      try presetManager.applyPreset(newPreset)
      isPresented = false
    } catch {
      self.error = "Failed to create preset"
    }
  }

  #if os(macOS)
    private func cropToSquareMacOS(image: NSImage) -> NSImage {
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

      let squareImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
      return squareImage
    }
  #endif
}

#if os(iOS) || os(visionOS)
  struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var selectedImage: UIImage?
    @Binding var showingImageCropper: Bool
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
      var config = PHPickerConfiguration()
      config.filter = .images
      config.selectionLimit = 1

      let picker = PHPickerViewController(configuration: config)
      picker.delegate = context.coordinator
      return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
      Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
      let parent: ImagePicker

      init(_ parent: ImagePicker) {
        self.parent = parent
      }

      func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        if provider.canLoadObject(ofClass: UIImage.self) {
          provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
              if let uiImage = image as? UIImage {
                // Check if image is already square
                if abs(uiImage.size.width - uiImage.size.height) < 1 {
                  // Already square, use as-is
                  self.parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                } else {
                  // Not square, show cropping interface
                  self.parent.selectedImage = uiImage
                  self.parent.showingImageCropper = true
                }
              }
            }
          }
        }
      }
    }
  }

  struct ImageCropperView: View {
    @Binding var isPresented: Bool
    @Binding var artworkData: Data?
    let originalImage: UIImage
    @State private var cropOffset = CGSize.zero
    @State private var cropScale: CGFloat = 1.0

    private func cropContent(geometry: GeometryProxy) -> some View {
      let imageSize = originalImage.size
      let containerSize = geometry.size
      let imageAspect = imageSize.width / imageSize.height
      let containerAspect = containerSize.width / containerSize.height

      let displaySize: CGSize
      if imageAspect > containerAspect {
        displaySize = CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
      } else {
        displaySize = CGSize(
          width: containerSize.height * imageAspect, height: containerSize.height)
      }

      return ZStack {
        Image(uiImage: originalImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(cropScale)
          .offset(cropOffset)
          .clipped()

        // Crop overlay
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.white, lineWidth: 2)
          .frame(
            width: min(displaySize.width, displaySize.height),
            height: min(displaySize.width, displaySize.height)
          )
          .shadow(color: .black.opacity(0.3), radius: 2)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .gesture(
        MagnificationGesture()
          .onChanged { scale in
            cropScale = max(1.0, scale)
          }
          .simultaneously(
            with:
              DragGesture()
              .onChanged { drag in
                cropOffset = drag.translation
              }
          )
      )
    }

    var body: some View {
      NavigationStack {
        VStack {
          Text("Crop to Square")
            .font(.title2)
            .padding()

          Text("Album artwork works best as a square. Drag and pinch to adjust the crop area.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

          GeometryReader { geometry in
            cropContent(geometry: geometry)
          }
          .padding()

          HStack {
            Button("Cancel") {
              isPresented = false
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Use Crop") {
              cropAndSave()
            }
            .buttonStyle(.borderedProminent)
          }
          .padding()
        }
        .navigationBarHidden(true)
      }
    }

    private func cropAndSave() {
      let croppedImage = cropImage()
      artworkData = croppedImage.jpegData(compressionQuality: 0.8)
      isPresented = false
    }

    private func cropImage() -> UIImage {
      let imageSize = originalImage.size
      let cropSize = min(imageSize.width, imageSize.height) / cropScale

      let cropRect = CGRect(
        x: (imageSize.width - cropSize) / 2 - cropOffset.width / cropScale,
        y: (imageSize.height - cropSize) / 2 - cropOffset.height / cropScale,
        width: cropSize,
        height: cropSize
      )

      guard let cgImage = originalImage.cgImage?.cropping(to: cropRect) else {
        return originalImage
      }

      return UIImage(
        cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
    }
  }
#endif

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

  // Get sounds in alphabetical order
  var orderedSounds: [Sound] {
    audioManager.sounds.sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    NavigationStack {
      Form {
        if preset.isDefault {
          Section("Preset Information") {
            LabeledContent("Name", value: "All Sounds")
            Text("The default preset cannot be modified")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        } else {
          Section {
            HStack {
              Text("Name")
                .foregroundStyle(.secondary)
              Spacer()
              TextField("Required", text: $presetName)
                .multilineTextAlignment(.trailing)
            }
          }

          if let error = error {
            Section {
              Label(error, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            }
          }

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

          Section {
            Button {
              showingImagePicker = true
            } label: {
              HStack {
                Text("Artwork")
                Spacer()
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
            }
            .buttonStyle(.plain)
          } footer: {
            Text("Custom artwork for Now Playing")
              .font(.caption)
          }

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
      }
      .navigationTitle(preset.isDefault ? "View Preset" : "Edit Preset")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
          leading: Button("Cancel") {
            isPresented = nil
          },
          trailing: !preset.isDefault
            ? Button("Save") {
              savePresetChanges()
            }
            .fontWeight(.semibold)
            .disabled(presetName.isEmpty || selectedSounds.isEmpty) : nil
        )
      #else
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 500, minHeight: preset.isDefault ? 200 : 300)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              isPresented = nil
            }
          }
          if !preset.isDefault {
            ToolbarItem(placement: .confirmationAction) {
              Button("Save") {
                savePresetChanges()
              }
              .keyboardShortcut(.return)
              .disabled(presetName.isEmpty || selectedSounds.isEmpty)
            }
          }
        }
      #endif
      .onAppear {
        presetName = preset.name
        creatorName = preset.creatorName ?? ""
        artworkData = preset.artworkData
        // Show all sounds that are in the preset (not just the ones marked as selected)
        selectedSounds = Set(preset.soundStates.map(\.fileName))
      }
      #if os(iOS) || os(visionOS)
        .sheet(isPresented: $showingImagePicker) {
          ImagePicker(
            imageData: $artworkData, selectedImage: $selectedImage,
            showingImageCropper: $showingImageCropper)
        }
        .sheet(isPresented: $showingImageCropper) {
          if let image = selectedImage {
            ImageCropperView(
              isPresented: $showingImageCropper, artworkData: $artworkData, originalImage: image)
          }
        }
      #else
        .fileImporter(
          isPresented: $showingImagePicker,
          allowedContentTypes: [.image],
          allowsMultipleSelection: false
        ) { result in
          switch result {
          case .success(let urls):
            print("🎨 macOS Image Picker: Success with \(urls.count) URLs")
            if let url = urls.first {
              print("🎨 macOS Image Picker: Processing file at \(url)")

              // Start accessing security-scoped resource
              let accessing = url.startAccessingSecurityScopedResource()
              defer {
                if accessing {
                  url.stopAccessingSecurityScopedResource()
                }
              }

              do {
                let data = try Data(contentsOf: url)
                print("🎨 macOS Image Picker: Loaded \(data.count) bytes from file")

                if let nsImage = NSImage(data: data) {
                  print("🎨 macOS Image Picker: Created NSImage with size \(nsImage.size)")

                  // Check if image is already square
                  if abs(nsImage.size.width - nsImage.size.height) < 1 {
                    print("🎨 macOS Image Picker: Image is already square, using as-is")
                    // Already square, use as-is
                    if let jpegData = nsImage.jpegData(compressionQuality: 0.8) {
                      artworkData = jpegData
                      print(
                        "🎨 macOS Image Picker: ✅ Successfully converted to JPEG (\(jpegData.count) bytes)"
                      )
                    } else {
                      print("❌ macOS Image Picker: Failed to convert NSImage to JPEG")
                    }
                  } else {
                    print("🎨 macOS Image Picker: Image is not square, cropping to square")
                    // For macOS, auto-crop for now (could add cropping UI later)
                    let squareImage = cropToSquareMacOS(image: nsImage)
                    print("🎨 macOS Image Picker: Cropped to size \(squareImage.size)")
                    if let jpegData = squareImage.jpegData(compressionQuality: 0.8) {
                      artworkData = jpegData
                      print(
                        "🎨 macOS Image Picker: ✅ Successfully converted cropped image to JPEG (\(jpegData.count) bytes)"
                      )
                    } else {
                      print("❌ macOS Image Picker: Failed to convert cropped NSImage to JPEG")
                    }
                  }
                } else {
                  print("❌ macOS Image Picker: Failed to create NSImage from data, using raw data")
                  artworkData = data
                }
              } catch {
                print("❌ macOS Image Picker: Failed to load image: \(error)")
              }
            } else {
              print("❌ macOS Image Picker: No URL in success result")
            }
          case .failure(let error):
            print("❌ macOS Image Picker: Image picker error: \(error)")
          }
        }
      #endif
    }
  }

  private func savePresetChanges() {
    guard !presetName.isEmpty else {
      error = "Preset name cannot be empty"
      return
    }

    // Find the preset in the manager and update it
    guard let index = presetManager.presets.firstIndex(where: { $0.id == preset.id }) else {
      error = "Preset not found"
      return
    }

    var updatedPreset = preset
    updatedPreset.name = presetName
    updatedPreset.lastModifiedVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // Only include selected sounds in the preset
    let selectedSoundStates =
      orderedSounds
      .filter { selectedSounds.contains($0.fileName) }
      .map { sound in
        PresetState(
          fileName: sound.fileName,
          isSelected: sound.isSelected,  // Use current play state from the sound
          volume: sound.volume  // Use current volume from the sound
        )
      }

    updatedPreset.soundStates = selectedSoundStates
    updatedPreset.creatorName = creatorName.isEmpty ? nil : creatorName
    updatedPreset.artworkData = artworkData
    // Sound order is determined by display in UI (alphabetical)

    // Update the preset in the manager
    var allPresets = presetManager.presets
    allPresets[index] = updatedPreset
    presetManager.setPresets(allPresets)

    // Update current preset if this is the active one
    if presetManager.currentPreset?.id == preset.id {
      presetManager.setCurrentPreset(updatedPreset)
    }

    presetManager.savePresets()

    // Apply the updated preset if it's currently active
    if presetManager.currentPreset?.id == preset.id {
      do {
        try presetManager.applyPreset(updatedPreset)
      } catch {
        self.error = "Failed to apply preset changes"
        return
      }
    }

    isPresented = nil
  }

  #if os(macOS)
    private func cropToSquareMacOS(image: NSImage) -> NSImage {
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

      let squareImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
      return squareImage
    }
  #endif

}
