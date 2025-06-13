//
//  SoundSheet+State.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

// MARK: - Initialization Helpers
struct SoundSheetInitValues {
  let soundName: String
  let selectedIcon: String
  let selectedFile: URL?
  let randomizeStartPosition: Bool
  let normalizeAudio: Bool
  let volumeAdjustment: Float
  let loopSound: Bool
  let selectedColor: AccentColor?
  let initialSoundName: String
  let initialSelectedIcon: String
  let initialRandomizeStartPosition: Bool
  let initialNormalizeAudio: Bool
  let initialVolumeAdjustment: Float
  let initialLoopSound: Bool
  let initialSelectedColor: AccentColor?

  init(
    soundName: String = "",
    selectedIcon: String = "waveform.circle",
    selectedFile: URL? = nil,
    randomizeStartPosition: Bool = true,
    normalizeAudio: Bool = true,
    volumeAdjustment: Float = 1.0,
    loopSound: Bool = true,
    selectedColor: AccentColor? = nil
  ) {
    self.soundName = soundName
    self.selectedIcon = selectedIcon
    self.selectedFile = selectedFile
    self.randomizeStartPosition = randomizeStartPosition
    self.normalizeAudio = normalizeAudio
    self.volumeAdjustment = volumeAdjustment
    self.loopSound = loopSound
    self.selectedColor = selectedColor
    self.initialSoundName = soundName
    self.initialSelectedIcon = selectedIcon
    self.initialRandomizeStartPosition = randomizeStartPosition
    self.initialNormalizeAudio = normalizeAudio
    self.initialVolumeAdjustment = volumeAdjustment
    self.initialLoopSound = loopSound
    self.initialSelectedColor = selectedColor
  }
}

// MARK: - State Management
extension SoundSheet {
  var hasChanges: Bool {
    switch mode {
    case .edit:
      return false  // No save/cancel buttons in edit mode - changes are instant
    case .add:
      return true  // Add mode still needs save button
    }
  }

  func updateSoundSettings() {
    if isPreviewing {
      updatePreviewVolume()
    }

    if case .edit(let sound) = mode {
      applyCustomizationInstantly(sound)
    }
  }

  func getOriginalCustomization() -> SoundCustomization? {
    switch mode {
    case .edit(let sound):
      return SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
    case .add:
      return nil
    }
  }

  // MARK: - Initialization Factory Methods
  static func createAddModeInitValues(preselectedFile: URL?) -> SoundSheetInitValues {
    let fileName = preselectedFile?.deletingPathExtension().lastPathComponent ?? ""
    return SoundSheetInitValues(
      soundName: fileName,
      selectedFile: preselectedFile
    )
  }

  static func createEditModeInitValues(sound: Sound) -> SoundSheetInitValues {
    let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
    let color = customization?.customColorName.flatMap { colorName in
      AccentColor.allCases.first { $0.color?.toString == colorName }
    }

    return SoundSheetInitValues(
      soundName: customization?.customTitle ?? sound.originalTitle,
      selectedIcon: customization?.customIconName ?? sound.originalSystemIconName,
      randomizeStartPosition: customization?.randomizeStartPosition ?? true,
      normalizeAudio: customization?.normalizeAudio ?? true,
      volumeAdjustment: customization?.volumeAdjustment ?? 1.0,
      loopSound: customization?.loopSound ?? true,
      selectedColor: color
    )
  }
}
