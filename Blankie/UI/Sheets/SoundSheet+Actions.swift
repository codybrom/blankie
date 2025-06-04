//
//  SoundSheet+Actions.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import SwiftData
import SwiftUI

extension SoundSheet {
  // MARK: - Actions

  func performAction() {
    switch mode {
    case .add:
      importSound()
    case .edit(let sound):
      saveChanges(sound)
    case .customize(let sound):
      saveCustomization(sound)
    }
  }

  func importSound() {
    guard let selectedFile = selectedFile,
      !soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    else {
      return
    }

    isProcessing = true

    // Capture values before Task to avoid sendability issues
    let file = selectedFile
    let title = soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    let icon = selectedIcon
    let randomize = randomizeStartPosition

    Task {
      let result = await CustomSoundManager.shared.importSound(
        from: file,
        title: title,
        iconName: icon,
        randomizeStartPosition: randomize
      )

      isProcessing = false

      switch result {
      case .success:
        dismiss()
      case .failure(let error):
        importError = NSError(
          domain: "SoundImport",
          code: 0,
          userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
        )
        showingError = true
      }
    }
  }

  func saveChanges(_ sound: CustomSoundData) {
    sound.title = soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    sound.systemIconName = selectedIcon
    sound.randomizeStartPosition = randomizeStartPosition
    sound.normalizeAudio = normalizeAudio
    sound.volumeAdjustment = volumeAdjustment

    do {
      try modelContext.save()

      // Update the sound customization to sync with CustomSoundData
      var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
        for: sound.fileName)
      customization.customTitle = sound.title
      customization.customIconName = sound.systemIconName
      customization.randomizeStartPosition = sound.randomizeStartPosition
      customization.normalizeAudio = sound.normalizeAudio
      customization.volumeAdjustment = sound.volumeAdjustment

      // Handle color customization
      if let selectedColor = selectedColor {
        customization.customColorName = selectedColor.color?.toString
      } else {
        // Remove color customization if "Current Theme" is selected
        customization.customColorName = nil
      }

      SoundCustomizationManager.shared.updateTemporaryCustomization(customization)
      SoundCustomizationManager.shared.saveCustomizations()

      // Trigger sound reload to update with new settings
      AudioManager.shared.loadCustomSounds()

      dismiss()
    } catch {
      importError = error
      showingError = true
    }
  }

  func saveCustomization(_ sound: Sound) {
    // Only save if there are actual customizations
    let hasCustomName = soundName != sound.originalTitle
    let hasCustomIcon = selectedIcon != sound.originalSystemIconName
    let hasCustomColor = selectedColor != nil
    let hasCustomRandomization = randomizeStartPosition != true  // Default is true
    let hasCustomNormalization = normalizeAudio != true  // Default is true
    let hasCustomVolume = volumeAdjustment != 1.0  // Default is 1.0

    if hasCustomName || hasCustomIcon || hasCustomColor || hasCustomRandomization
      || hasCustomNormalization || hasCustomVolume
    {
      // Use the manager's methods to set customizations
      if hasCustomName {
        SoundCustomizationManager.shared.setCustomTitle(soundName, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomTitle(nil, for: sound.fileName)
      }

      if hasCustomIcon {
        SoundCustomizationManager.shared.setCustomIcon(selectedIcon, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomIcon(nil, for: sound.fileName)
      }

      if hasCustomColor {
        SoundCustomizationManager.shared.setCustomColor(
          selectedColor?.color?.toString, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomColor(nil, for: sound.fileName)
      }

      if hasCustomRandomization {
        SoundCustomizationManager.shared.setRandomizeStartPosition(
          randomizeStartPosition, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setRandomizeStartPosition(nil, for: sound.fileName)
      }

      if hasCustomNormalization {
        SoundCustomizationManager.shared.setNormalizeAudio(
          normalizeAudio, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setNormalizeAudio(nil, for: sound.fileName)
      }

      if hasCustomVolume {
        SoundCustomizationManager.shared.setVolumeAdjustment(
          volumeAdjustment, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setVolumeAdjustment(nil, for: sound.fileName)
      }
    } else {
      // Remove all customizations if there are no changes
      SoundCustomizationManager.shared.resetCustomizations(for: sound.fileName)
    }

    // Sound object will automatically update through customization observer

    dismiss()
  }
}
