//
//  SoundSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 5/28/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum SoundSheetMode {
  case add
  case edit(CustomSoundData)
  case customize(Sound)
}

struct SoundSheet: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext

  let mode: SoundSheetMode

  @State var soundName: String = ""
  @State var selectedIcon: String = "waveform.circle"
  @State var selectedColor: AccentColor?
  @State var selectedFile: URL?
  @State var isImporting = false
  @State var importError: Error?
  @State var showingError = false
  @State var isProcessing = false
  @State var randomizeStartPosition: Bool = true
  @State var normalizeAudio: Bool = true
  @State var volumeAdjustment: Float = 1.0
  @State var loopSound: Bool = true
  @State var isPreviewing: Bool = false
  @State var previewSound: Sound?
  @State var originalCustomization: SoundCustomization?

  let isFilePreselected: Bool

  init(mode: SoundSheetMode, preselectedFile: URL? = nil) {
    self.isFilePreselected = preselectedFile != nil
    self.mode = mode

    switch mode {
    case .add:
      // Initialize with filename as temporary name
      let fileName = preselectedFile?.deletingPathExtension().lastPathComponent ?? ""
      _soundName = State(initialValue: fileName)
      _selectedIcon = State(initialValue: "waveform.circle")
      _selectedFile = State(initialValue: preselectedFile)
    case .edit(let customSoundData):
      // Find the corresponding Sound object to get consistent data
      if let sound = AudioManager.shared.sounds.first(where: {
        $0.customSoundDataID == customSoundData.id
      }) {
        let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
        _soundName = State(initialValue: customization?.customTitle ?? sound.originalTitle)
        _selectedIcon = State(
          initialValue: customization?.customIconName ?? sound.originalSystemIconName)
        _randomizeStartPosition = State(initialValue: customization?.randomizeStartPosition ?? true)
        _normalizeAudio = State(initialValue: customization?.normalizeAudio ?? true)
        _volumeAdjustment = State(initialValue: customization?.volumeAdjustment ?? 1.0)
        _loopSound = State(initialValue: customization?.loopSound ?? true)
        // Load color customization if it exists
        if let colorName = customization?.customColorName,
          let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
        {
          _selectedColor = State(initialValue: color)
        }
      } else {
        // Fallback to customSoundData values if Sound not found
        _soundName = State(initialValue: customSoundData.title)
        _selectedIcon = State(initialValue: customSoundData.systemIconName)
        _randomizeStartPosition = State(initialValue: customSoundData.randomizeStartPosition)
        _normalizeAudio = State(initialValue: customSoundData.normalizeAudio)
        _volumeAdjustment = State(initialValue: customSoundData.volumeAdjustment)
        _loopSound = State(initialValue: customSoundData.loopSound)
      }
    case .customize(let sound):
      let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
      _soundName = State(initialValue: customization?.customTitle ?? sound.originalTitle)
      _selectedIcon = State(
        initialValue: customization?.customIconName ?? sound.originalSystemIconName)
      _randomizeStartPosition = State(initialValue: customization?.randomizeStartPosition ?? true)
      _normalizeAudio = State(initialValue: customization?.normalizeAudio ?? true)
      _volumeAdjustment = State(initialValue: customization?.volumeAdjustment ?? 1.0)
      _loopSound = State(initialValue: customization?.loopSound ?? true)
      if let colorName = customization?.customColorName,
        let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
      {
        _selectedColor = State(initialValue: color)
      }
    }
  }

  var body: some View {
    Group {
      #if os(macOS)
        VStack(spacing: 0) {
          // Header
          VStack(spacing: 8) {
            Text(title)
              .font(.title2.bold())
          }
          .padding(.top, 20)
          .padding(.bottom, 16)

          Divider()

          // Content
          CleanSoundSheetForm(
            mode: mode,
            isFilePreselected: isFilePreselected,
            soundName: $soundName,
            selectedIcon: $selectedIcon,
            selectedFile: $selectedFile,
            isImporting: $isImporting,
            selectedColor: $selectedColor,
            randomizeStartPosition: $randomizeStartPosition,
            normalizeAudio: $normalizeAudio,
            volumeAdjustment: $volumeAdjustment,
            loopSound: $loopSound,
            isPreviewing: $isPreviewing,
            previewSound: $previewSound
          )

          Spacer()

          Divider()

          // Footer buttons
          HStack {
            Button("Cancel") {
              dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)

            Spacer()

            Button {
              performAction()
            } label: {
              Text(buttonTitle)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDisabled)
            .keyboardShortcut(.return)
          }
          .padding()
        }
        .frame(width: 450, height: mode.isAdd ? 600 : 580)
      #else
        NavigationView {
          CleanSoundSheetForm(
            mode: mode,
            isFilePreselected: isFilePreselected,
            soundName: $soundName,
            selectedIcon: $selectedIcon,
            selectedFile: $selectedFile,
            isImporting: $isImporting,
            selectedColor: $selectedColor,
            randomizeStartPosition: $randomizeStartPosition,
            normalizeAudio: $normalizeAudio,
            volumeAdjustment: $volumeAdjustment,
            loopSound: $loopSound,
            isPreviewing: $isPreviewing,
            previewSound: $previewSound
          )
          .navigationTitle(title)
          .navigationBarTitleDisplayMode(.inline)
          .navigationBarBackButtonHidden(true)
          .navigationBarItems(
            leading: Button("Cancel") {
              dismiss()
            },
            trailing: Button("Save") {
              performAction()
            }
            .disabled(isDisabled)
          )
        }
      #endif
    }
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [
        UTType.audio,
        UTType.mp3,
        UTType.wav,
        UTType.mpeg4Audio,
      ],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let files):
        if let file = files.first {
          selectedFile = file
          // Extract metadata title or use filename as fallback
          if soundName.isEmpty {
            Task {
              // Try to get ID3 title from metadata
              if let metadataTitle = await CustomSoundManager.shared.extractMetadataTitle(
                from: file)
              {
                soundName = metadataTitle
              } else {
                // Fallback to filename without extension
                soundName = file.deletingPathExtension().lastPathComponent
              }
            }
          }
        }
      case .failure(let error):
        importError = error
        showingError = true
      }
    }
    .alert(
      Text("Import Error", comment: "Import error alert title"), isPresented: $showingError,
      presenting: importError
    ) { _ in
      Button("OK", role: .cancel) {}
    } message: { error in
      Text(error.localizedDescription)
    }
    .overlay(alignment: .center) {
      if isProcessing {
        processingOverlay
      }
    }
    .onChange(of: isPreviewing) { _, previewing in
      if previewing {
        startPreview()
      } else {
        stopPreview()
      }
    }
    .onChange(of: normalizeAudio) { _, _ in
      updateSoundSettings()
    }
    .onChange(of: volumeAdjustment) { _, _ in
      updateSoundSettings()
    }
    .onChange(of: randomizeStartPosition) { _, _ in
      updateSoundSettings()
    }
    .onChange(of: loopSound) { _, _ in
      updateSoundSettings()
    }
    .onAppear {
      // Trigger LUFS analysis for custom sounds missing data
      if case .customize(let sound) = mode {
        sound.ensureLUFSAnalysis()
      } else if case .edit(let customSoundData) = mode,
        let sound = AudioManager.shared.sounds.first(where: {
          $0.customSoundDataID == customSoundData.id
        })
      {
        sound.ensureLUFSAnalysis()
      } else if case .add = mode, let preselectedFile = selectedFile {
        // Extract metadata title for pre-selected files
        Task {
          if let metadataTitle = await CustomSoundManager.shared.extractMetadataTitle(
            from: preselectedFile)
          {
            // Only update if user hasn't modified the name
            if soundName == preselectedFile.deletingPathExtension().lastPathComponent {
              soundName = metadataTitle
            }
          }
        }
      }
    }
    .onDisappear {
      // Clean up preview when sheet closes
      if isPreviewing {
        stopPreview()
      }
    }
  }

}

// MARK: - Real-time Updates

extension SoundSheet {
  private func updateSoundSettings() {
    // Update preview if active
    if isPreviewing {
      updatePreviewVolume()
    }

    // Also update the actual sound if it's currently playing
    switch mode {
    case .customize(let sound):
      // Update temporary customization for the sound
      var tempCustomization = SoundCustomizationManager.shared.getOrCreateCustomization(
        for: sound.fileName)
      tempCustomization.normalizeAudio = normalizeAudio
      tempCustomization.volumeAdjustment = volumeAdjustment
      tempCustomization.randomizeStartPosition = randomizeStartPosition
      tempCustomization.loopSound = loopSound
      SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

      // If the sound is currently playing, update its volume immediately
      if sound.player?.isPlaying == true {
        sound.updateVolume()
      }

      // Update loop setting if player exists
      if let player = sound.player {
        player.numberOfLoops = loopSound ? -1 : 0
      }

    case .edit(let customSoundData):
      // For custom sounds, find the corresponding Sound object and update it
      if let sound = AudioManager.shared.sounds.first(where: {
        $0.customSoundDataID == customSoundData.id
      }) {
        var tempCustomization = SoundCustomizationManager.shared.getOrCreateCustomization(
          for: sound.fileName)
        tempCustomization.normalizeAudio = normalizeAudio
        tempCustomization.volumeAdjustment = volumeAdjustment
        tempCustomization.randomizeStartPosition = randomizeStartPosition
        tempCustomization.loopSound = loopSound
        SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

        // If the sound is currently playing, update its volume immediately
        if sound.player?.isPlaying == true {
          sound.updateVolume()
        }

        // Update loop setting if player exists
        if let player = sound.player {
          player.numberOfLoops = loopSound ? -1 : 0
        }
      }

    case .add:
      // No real-time update needed for add mode
      break
    }
  }
}

// MARK: - Mode Extensions

extension SoundSheetMode {
  var isAdd: Bool {
    switch self {
    case .add:
      return true
    case .edit, .customize:
      return false
    }
  }
}

// MARK: - Previews

#Preview("Add Mode") {
  SoundSheet(mode: .add)
}

#Preview("Edit Mode") {
  let previewSound = CustomSoundData(
    title: "Sample Sound",
    systemIconName: "waveform",
    fileName: "sample",
    fileExtension: "mp3"
  )

  return SoundSheet(mode: .edit(previewSound))
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
