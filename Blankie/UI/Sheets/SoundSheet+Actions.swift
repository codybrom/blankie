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
    // Stop preview before performing action
    if isPreviewing {
      stopPreview()
    }

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
      case .success(let customSound):
        // Add the new sound to current preset after AudioManager loads it
        // Use a delay to ensure the sound is loaded into AudioManager first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          addNewSoundToCurrentPreset(fileName: customSound.fileName)
        }
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
    // Always apply customizations when save is clicked
    // This ensures any preview changes are persisted
    applyCustomizations(sound)

    // Force an immediate volume update for the sound
    if sound.player != nil {
      sound.updateVolume()
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

    // Force save all customizations
    manager.saveCustomizations()
  }

  // MARK: - Preset Integration

  private func addNewSoundToCurrentPreset(fileName: String) {
    let presetManager = PresetManager.shared
    let audioManager = AudioManager.shared

    // Only add to preset if:
    // 1. There's a current preset
    // 2. It's not the default preset (All Sounds)
    // 3. We're not in solo mode
    // 4. We're not in CarPlay Quick Mix mode
    guard let currentPreset = presetManager.currentPreset,
      !currentPreset.isDefault,
      audioManager.soloModeSound == nil,
      !audioManager.isCarPlayQuickMix
    else {
      print("🎵 SoundSheet: Not adding to preset - conditions not met")
      return
    }

    // Check if the sound is already in the preset
    let existingSoundFileNames = Set(currentPreset.soundStates.map(\.fileName))
    guard !existingSoundFileNames.contains(fileName) else {
      print("🎵 SoundSheet: Sound already exists in preset")
      return
    }

    // Find the newly imported sound
    guard let newSound = audioManager.sounds.first(where: { $0.fileName == fileName }) else {
      print("❌ SoundSheet: Could not find imported sound with fileName: \(fileName)")
      return
    }

    print("🎵 SoundSheet: Adding '\(newSound.title)' to preset '\(currentPreset.name)'")

    // Create a new preset state for the imported sound
    let newSoundState = PresetState(
      fileName: fileName,
      isSelected: false,  // Start unselected so it doesn't interrupt current mix
      volume: newSound.volume
    )

    // Update the preset with the new sound
    var updatedPreset = currentPreset
    updatedPreset.soundStates.append(newSoundState)
    updatedPreset.lastModifiedVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // Update the preset in the manager
    var currentPresets = presetManager.presets
    if let index = currentPresets.firstIndex(where: { $0.id == currentPreset.id }) {
      currentPresets[index] = updatedPreset
      presetManager.setPresets(currentPresets)
      presetManager.setCurrentPreset(updatedPreset)

      // Save directly to avoid state override
      savePresetsDirectly()

      print(
        "🎵 SoundSheet: Successfully added sound to preset (now has \(updatedPreset.soundStates.count) sounds)"
      )
    }
  }

  // MARK: - Delete Action

  func deleteSound() {
    let customSound: CustomSoundData

    switch mode {
    case .edit(let customSoundData):
      customSound = customSoundData
    case .customize(let sound):
      guard sound.isCustom,
        let customSoundDataID = sound.customSoundDataID,
        let customSoundData = CustomSoundManager.shared.getCustomSound(by: customSoundDataID)
      else {
        return
      }
      customSound = customSoundData
    default:
      return
    }

    // Stop preview before deleting
    if isPreviewing {
      stopPreview()
    }

    let result = CustomSoundManager.shared.deleteCustomSound(customSound)

    switch result {
    case .success:
      // Remove any customizations for this sound
      SoundCustomizationManager.shared.removeCustomization(for: customSound.fileName)

      // Reload custom sounds in AudioManager
      AudioManager.shared.loadCustomSounds()

      dismiss()
    case .failure(let error):
      importError = error
      showingError = true
    }
  }

  // MARK: - Direct Preset Saving

  private func savePresetsDirectly() {
    let presetManager = PresetManager.shared
    let defaultPreset = presetManager.presets.first { $0.isDefault }
    let customPresets = presetManager.presets.filter { !$0.isDefault }

    if let defaultPreset = defaultPreset {
      PresetStorage.saveDefaultPreset(defaultPreset)
    }
    PresetStorage.saveCustomPresets(customPresets)
    print("🎵 SoundSheet: Presets saved directly without state override")
  }

  // MARK: - Cancel Action

  func handleCancel() {
    // Stop preview before canceling
    if isPreviewing {
      stopPreview()
    }

    // Restore original customization for customize mode
    if case .customize(let sound) = mode {
      if let original = originalCustomization {
        SoundCustomizationManager.shared.updateTemporaryCustomization(original)
        SoundCustomizationManager.shared.saveCustomizations()
      } else {
        // If there was no original customization, remove any temporary one
        SoundCustomizationManager.shared.removeCustomization(for: sound.fileName)
      }
      
      // Force update the sound to reflect restored settings
      sound.objectWillChange.send()
      if sound.player != nil {
        sound.updateVolume()
      }
    }
  }
}
