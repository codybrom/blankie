//
//  SoundSheet+Initialization.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

// MARK: - Initialization
extension SoundSheet {
  mutating func initializeAddMode(preselectedFile: URL?) {
    let fileName = preselectedFile?.deletingPathExtension().lastPathComponent ?? ""
    _soundName = State(initialValue: fileName)
    _selectedIcon = State(initialValue: "waveform.circle")
    _selectedFile = State(initialValue: preselectedFile)
    _initialSoundName = State(initialValue: fileName)
    _initialSelectedIcon = State(initialValue: "waveform.circle")
  }

  mutating func initializeEditMode(customSoundData: CustomSoundData) {
    if let sound = AudioManager.shared.sounds.first(where: {
      $0.customSoundDataID == customSoundData.id
    }) {
      let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
      let name = customization?.customTitle ?? sound.originalTitle
      let icon = customization?.customIconName ?? sound.originalSystemIconName
      let randomize = customization?.randomizeStartPosition ?? true
      let normalize = customization?.normalizeAudio ?? true
      let volume = customization?.volumeAdjustment ?? 1.0
      let loop = customization?.loopSound ?? true

      _soundName = State(initialValue: name)
      _selectedIcon = State(initialValue: icon)
      _randomizeStartPosition = State(initialValue: randomize)
      _normalizeAudio = State(initialValue: normalize)
      _volumeAdjustment = State(initialValue: volume)
      _loopSound = State(initialValue: loop)
      _initialSoundName = State(initialValue: name)
      _initialSelectedIcon = State(initialValue: icon)
      _initialRandomizeStartPosition = State(initialValue: randomize)
      _initialNormalizeAudio = State(initialValue: normalize)
      _initialVolumeAdjustment = State(initialValue: volume)
      _initialLoopSound = State(initialValue: loop)

      if let colorName = customization?.customColorName,
        let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
      {
        _selectedColor = State(initialValue: color)
        _initialSelectedColor = State(initialValue: color)
      }
    } else {
      _soundName = State(initialValue: customSoundData.title)
      _selectedIcon = State(initialValue: customSoundData.systemIconName)
      _randomizeStartPosition = State(initialValue: customSoundData.randomizeStartPosition)
      _normalizeAudio = State(initialValue: customSoundData.normalizeAudio)
      _volumeAdjustment = State(initialValue: customSoundData.volumeAdjustment)
      _loopSound = State(initialValue: customSoundData.loopSound)
      _initialSoundName = State(initialValue: customSoundData.title)
      _initialSelectedIcon = State(initialValue: customSoundData.systemIconName)
      _initialRandomizeStartPosition = State(initialValue: customSoundData.randomizeStartPosition)
      _initialNormalizeAudio = State(initialValue: customSoundData.normalizeAudio)
      _initialVolumeAdjustment = State(initialValue: customSoundData.volumeAdjustment)
      _initialLoopSound = State(initialValue: customSoundData.loopSound)
    }
  }

  mutating func initializeCustomizeMode(sound: Sound) {
    let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
    let name = customization?.customTitle ?? sound.originalTitle
    let icon = customization?.customIconName ?? sound.originalSystemIconName
    let randomize = customization?.randomizeStartPosition ?? true
    let normalize = customization?.normalizeAudio ?? true
    let volume = customization?.volumeAdjustment ?? 1.0
    let loop = customization?.loopSound ?? true

    _soundName = State(initialValue: name)
    _selectedIcon = State(initialValue: icon)
    _randomizeStartPosition = State(initialValue: randomize)
    _normalizeAudio = State(initialValue: normalize)
    _volumeAdjustment = State(initialValue: volume)
    _loopSound = State(initialValue: loop)
    _initialSoundName = State(initialValue: name)
    _initialSelectedIcon = State(initialValue: icon)
    _initialRandomizeStartPosition = State(initialValue: randomize)
    _initialNormalizeAudio = State(initialValue: normalize)
    _initialVolumeAdjustment = State(initialValue: volume)
    _initialLoopSound = State(initialValue: loop)

    if let colorName = customization?.customColorName,
      let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
    {
      _selectedColor = State(initialValue: color)
      _initialSelectedColor = State(initialValue: color)
    }
  }
}
