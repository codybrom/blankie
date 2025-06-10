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
  @State var previousSoloModeSound: Sound?
  @State var wasPreviewSoundPlaying: Bool = false

  // Track initial values to detect changes
  @State var initialSoundName: String = ""
  @State var initialSelectedIcon: String = ""
  @State var initialSelectedColor: AccentColor?
  @State var initialRandomizeStartPosition: Bool = true
  @State var initialNormalizeAudio: Bool = true
  @State var initialVolumeAdjustment: Float = 1.0
  @State var initialLoopSound: Bool = true

  var hasChanges: Bool {
    switch mode {
    case .customize:
      return soundName != initialSoundName || selectedIcon != initialSelectedIcon
        || selectedColor != initialSelectedColor
        || randomizeStartPosition != initialRandomizeStartPosition
        || normalizeAudio != initialNormalizeAudio || volumeAdjustment != initialVolumeAdjustment
        || loopSound != initialLoopSound
    case .add, .edit:
      return true
    }
  }

  let isFilePreselected: Bool

  init(mode: SoundSheetMode, preselectedFile: URL? = nil) {
    self.isFilePreselected = preselectedFile != nil
    self.mode = mode

    switch mode {
    case .add:
      initializeAddMode(preselectedFile: preselectedFile)
    case .edit(let customSoundData):
      initializeEditMode(customSoundData: customSoundData)
    case .customize(let sound):
      initializeCustomizeMode(sound: sound)
    }
  }

  var body: some View {
    Group {
      #if os(macOS)
        macOSLayout
      #else
        iOSLayout
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
      handleFileImport(result: result)
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
      originalCustomization = getOriginalCustomization()
      if case .customize(let sound) = mode {
        previewSound = sound
      }
    }
    .onDisappear {
      if case .customize(let sound) = mode {
        if let originalCustomization = originalCustomization {
          SoundCustomizationManager.shared.addCustomization(originalCustomization)
        } else {
          SoundCustomizationManager.shared.removeCustomization(for: sound.fileName)
        }
      }
      if isPreviewing {
        stopPreview()
      }
    }
  }

  private var macOSLayout: some View {
    SoundSheetMacOSLayout(
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
      previewSound: $previewSound,
      hasChanges: hasChanges,
      title: title,
      buttonTitle: buttonTitle,
      isDisabled: isDisabled,
      performAction: performAction,
      stopPreview: stopPreview,
      dismiss: dismiss
    )
  }

  private var iOSLayout: some View {
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
        leading: leadingNavigationButton,
        trailing: trailingNavigationButton
      )
    }
    .navigationViewStyle(.stack)
  }

  @ViewBuilder
  private var leadingNavigationButton: some View {
    if hasChanges {
      Button("Cancel") {
        if isPreviewing {
          stopPreview()
        }
        dismiss()
      }
    } else {
      Button("Done") {
        if isPreviewing {
          stopPreview()
        }
        dismiss()
      }
    }
  }

  @ViewBuilder
  private var trailingNavigationButton: some View {
    if hasChanges {
      Button("Save") {
        performAction()
      }
      .disabled(isDisabled)
    }
  }

  private func handleFileImport(result: Result<[URL], Error>) {
    switch result {
    case .success(let files):
      if let file = files.first {
        selectedFile = file
        if soundName.isEmpty {
          Task {
            if let metadataTitle = await CustomSoundManager.shared.extractMetadataTitle(from: file)
            {
              soundName = metadataTitle
            } else {
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
}

extension SoundSheetMode {
  var isAdd: Bool {
    if case .add = self {
      return true
    }
    return false
  }
}

#Preview("Add Mode") {
  SoundSheet(mode: .add)
}

#Preview("Customize Mode") {
  SoundSheet(mode: .customize(Sound.preview))
}
