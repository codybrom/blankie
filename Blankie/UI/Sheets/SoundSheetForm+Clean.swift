//
//  SoundSheetForm+Clean.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import SwiftUI

struct CleanSoundSheetForm: View {
  let mode: SoundSheetMode
  let isFilePreselected: Bool
  @Binding var soundName: String
  @Binding var selectedIcon: String
  @Binding var selectedFile: URL?
  @Binding var isImporting: Bool
  @Binding var selectedColor: AccentColor?
  @Binding var randomizeStartPosition: Bool
  @Binding var normalizeAudio: Bool
  @Binding var volumeAdjustment: Float
  @Binding var loopSound: Bool
  @Binding var isPreviewing: Bool
  @Binding var previewSound: Sound?

  @ObservedObject var globalSettings = GlobalSettings.shared
  @State var showingIconPicker = false

  var body: some View {
    Form {
      // File selection (only for add mode)
      if case .add = mode {
        Section {
          SoundFileSelector(
            selectedFile: $selectedFile,
            soundName: $soundName,
            isImporting: $isImporting,
            hideChangeButton: isFilePreselected
          )
        }
      }

      // Basic Information
      basicInformationSection

      // Audio Processing
      audioProcessingSection

      // Reset Section (only for built-in sounds)
      resetSection

      // Preview Section
      previewSection
    }
    .sheet(isPresented: $showingIconPicker) {
      NavigationStack {
        IconPickerView(selectedIcon: $selectedIcon)
      }
    }
    #if os(macOS)
      .frame(minHeight: 500)
    #endif
  }

  func resetToDefaults(for sound: Sound) {
    // Reset all values to defaults
    soundName = sound.originalTitle
    selectedIcon = sound.originalSystemIconName
    selectedColor = nil
    randomizeStartPosition = true
    normalizeAudio = true
    volumeAdjustment = 1.0
    loopSound = true

    // If previewing, update the preview with new settings
    if isPreviewing {
      updatePreviewVolume()
    }
  }
}
