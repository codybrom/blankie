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
    sound.loopSound = loopSound
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
      customization.loopSound = sound.loopSound
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
    let hasCustomizations = checkForCustomizations(sound)

    if hasCustomizations {
      applyCustomizations(sound)
    } else {
      // Remove all customizations if there are no changes
      SoundCustomizationManager.shared.resetCustomizations(for: sound.fileName)
    }

    // Sound object will automatically update through customization observer
    dismiss()
  }

  private func checkForCustomizations(_ sound: Sound) -> Bool {
    let hasCustomName = soundName != sound.originalTitle
    let hasCustomIcon = selectedIcon != sound.originalSystemIconName
    let hasCustomColor = selectedColor != nil
    let hasCustomRandomization = randomizeStartPosition != true  // Default is true
    let hasCustomNormalization = normalizeAudio != true  // Default is true
    let hasCustomVolume = volumeAdjustment != 1.0  // Default is 1.0
    let hasCustomLoop = loopSound != true  // Default is true

    return hasCustomName || hasCustomIcon || hasCustomColor || hasCustomRandomization
      || hasCustomNormalization || hasCustomVolume || hasCustomLoop
  }

  private func applyCustomizations(_ sound: Sound) {
    let manager = SoundCustomizationManager.shared

    // Name customization
    manager.setCustomTitle(
      soundName != sound.originalTitle ? soundName : nil,
      for: sound.fileName
    )

    // Icon customization
    manager.setCustomIcon(
      selectedIcon != sound.originalSystemIconName ? selectedIcon : nil,
      for: sound.fileName
    )

    // Color customization
    manager.setCustomColor(
      selectedColor?.color?.toString,
      for: sound.fileName
    )

    // Randomization customization
    manager.setRandomizeStartPosition(
      randomizeStartPosition != true ? randomizeStartPosition : nil,
      for: sound.fileName
    )

    // Normalization customization
    manager.setNormalizeAudio(
      normalizeAudio != true ? normalizeAudio : nil,
      for: sound.fileName
    )

    // Volume customization
    manager.setVolumeAdjustment(
      volumeAdjustment != 1.0 ? volumeAdjustment : nil,
      for: sound.fileName
    )

    // Loop customization
    manager.setLoopSound(
      loopSound != true ? loopSound : nil,
      for: sound.fileName
    )
  }
}
