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
  @State var showingDeleteConfirmation: Bool = false
  @State var showingResetConfirmation: Bool = false
  @State var isDisappearing: Bool = false

  // Track initial values to detect changes
  @State var initialSoundName: String = ""
  @State var initialSelectedIcon: String = ""
  @State var initialSelectedColor: AccentColor?
  @State var initialRandomizeStartPosition: Bool = true
  @State var initialNormalizeAudio: Bool = true
  @State var initialVolumeAdjustment: Float = 1.0
  @State var initialLoopSound: Bool = true

  let isFilePreselected: Bool

  init(mode: SoundSheetMode, preselectedFile: URL? = nil) {
    self.isFilePreselected = preselectedFile != nil
    self.mode = mode

    switch mode {
    case .add:
      let values = Self.createAddModeInitValues(preselectedFile: preselectedFile)
      self._soundName = State(initialValue: values.soundName)
      self._selectedIcon = State(initialValue: values.selectedIcon)
      self._selectedFile = State(initialValue: values.selectedFile)
      self._initialSoundName = State(initialValue: values.initialSoundName)
      self._initialSelectedIcon = State(initialValue: values.initialSelectedIcon)

    case .edit(let customSoundData):
      let values = Self.createEditModeInitValues(customSoundData: customSoundData)
      self._soundName = State(initialValue: values.soundName)
      self._selectedIcon = State(initialValue: values.selectedIcon)
      self._randomizeStartPosition = State(initialValue: values.randomizeStartPosition)
      self._normalizeAudio = State(initialValue: values.normalizeAudio)
      self._volumeAdjustment = State(initialValue: values.volumeAdjustment)
      self._loopSound = State(initialValue: values.loopSound)
      self._selectedColor = State(initialValue: values.selectedColor)
      self._initialSoundName = State(initialValue: values.initialSoundName)
      self._initialSelectedIcon = State(initialValue: values.initialSelectedIcon)
      self._initialRandomizeStartPosition = State(
        initialValue: values.initialRandomizeStartPosition)
      self._initialNormalizeAudio = State(initialValue: values.initialNormalizeAudio)
      self._initialVolumeAdjustment = State(initialValue: values.initialVolumeAdjustment)
      self._initialLoopSound = State(initialValue: values.initialLoopSound)
      self._initialSelectedColor = State(initialValue: values.initialSelectedColor)

    case .customize(let sound):
      let values = Self.createCustomizeModeInitValues(sound: sound)
      self._soundName = State(initialValue: values.soundName)
      self._selectedIcon = State(initialValue: values.selectedIcon)
      self._randomizeStartPosition = State(initialValue: values.randomizeStartPosition)
      self._normalizeAudio = State(initialValue: values.normalizeAudio)
      self._volumeAdjustment = State(initialValue: values.volumeAdjustment)
      self._loopSound = State(initialValue: values.loopSound)
      self._selectedColor = State(initialValue: values.selectedColor)
      self._initialSoundName = State(initialValue: values.initialSoundName)
      self._initialSelectedIcon = State(initialValue: values.initialSelectedIcon)
      self._initialRandomizeStartPosition = State(
        initialValue: values.initialRandomizeStartPosition)
      self._initialNormalizeAudio = State(initialValue: values.initialNormalizeAudio)
      self._initialVolumeAdjustment = State(initialValue: values.initialVolumeAdjustment)
      self._initialLoopSound = State(initialValue: values.initialLoopSound)
      self._initialSelectedColor = State(initialValue: values.initialSelectedColor)
    }
  }

  var body: some View {
    baseContent
      .fileImporter(
        isPresented: $isImporting,
        allowedContentTypes: allowedContentTypes,
        allowsMultipleSelection: false
      ) { result in
        handleFileImport(result: result)
      }
      .alert(
        Text("Import Error", comment: "Import error alert title"),
        isPresented: $showingError,
        presenting: importError
      ) { _ in
        Button("OK", role: .cancel) {}
      } message: { error in
        Text(error.localizedDescription)
      }
      .alert(
        Text("Delete Sound", comment: "Delete sound confirmation alert title"),
        isPresented: $showingDeleteConfirmation
      ) {
        Button("Delete", role: .destructive) {
          deleteSound()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Are you sure you want to delete this sound? This action cannot be undone.",
          comment: "Delete sound confirmation message")
      }
      .alert(
        Text("Reset to Defaults", comment: "Reset confirmation alert title"),
        isPresented: $showingResetConfirmation
      ) {
        Button("Reset", role: .destructive) {
          if case .customize(let sound) = mode {
            handleResetToDefaults(for: sound)
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Are you sure you want to reset all customizations for this sound?",
          comment: "Reset confirmation message")
      }
      .overlay(alignment: .center) {
        if isProcessing {
          processingOverlay
        }
      }
      .modifier(
        SoundSheetChangeHandlers(
          isPreviewing: $isPreviewing,
          normalizeAudio: $normalizeAudio,
          volumeAdjustment: $volumeAdjustment,
          randomizeStartPosition: $randomizeStartPosition,
          loopSound: $loopSound,
          startPreview: startPreview,
          stopPreview: stopPreview,
          updateSoundSettings: updateSoundSettings
        )
      )
      .onAppear {
        handleOnAppear()
      }
      .onDisappear {
        handleOnDisappear()
      }
  }

  private var baseContent: some View {
    Group {
      #if os(macOS)
        macOSLayout
      #else
        iOSLayout
      #endif
    }
  }

  private var allowedContentTypes: [UTType] {
    [
      UTType.audio,
      UTType.mp3,
      UTType.wav,
      UTType.mpeg4Audio,
    ]
  }

  private func handleOnAppear() {
    let soundName = builtInSound?.title ?? sound?.title ?? "Unknown"
    print("🎵 SoundSheet: handleOnAppear called for '\(soundName)'")
    originalCustomization = getOriginalCustomization()
  }

  private func handleOnDisappear() {
    // Mark that we're disappearing to prevent re-entrance
    guard !isDisappearing else {
      print("🎵 SoundSheet: handleOnDisappear called but already disappearing")
      return
    }

    let soundName = builtInSound?.title ?? sound?.title ?? "Unknown"
    print(
      "🎵 SoundSheet: handleOnDisappear called for '\(soundName)', isPreviewing: \(isPreviewing)")
    isDisappearing = true

    // Don't restore original customization on disappear - we want to keep the saved changes
    if isPreviewing {
      print("🎵 SoundSheet: Stopping preview in onDisappear")
      stopPreview()
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

// #Preview("Customize Mode") {
//   SoundSheet(mode: .customize(Sound.preview))
// }
