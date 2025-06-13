//
//  PresetManager+Helpers.swift
//  Blankie
//
//  Created by Cody Bromley on 1/30/25.
//

import SwiftUI

// MARK: - Helper Methods

extension PresetManager {
  func handleError(_ error: Error) {
    print("❌ PresetManager: Error occurred: \(error.localizedDescription)")
    setError(error)
  }

  func updateCustomPresetStatus() {
    setHasCustomPresets(presets.contains { !$0.isDefault })
  }

  func createDefaultPreset() -> Preset {
    print("🎛️ PresetManager: Creating new default preset")
    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    return Preset(
      id: UUID(),
      name: "Default",
      soundStates: AudioManager.shared.sounds.map { sound in
        PresetState(
          fileName: sound.fileName,
          isSelected: false,
          volume: 1.0
        )
      },
      isDefault: true,
      createdVersion: currentVersion,
      lastModifiedVersion: currentVersion,
      soundOrder: AudioManager.shared.sounds.map(\.fileName)
    )
  }

  func logPresetState(_ preset: Preset) {
    print("  - Name: '\(preset.name)'")
    print("  - ID: \(preset.id)")
    print("  - Is Default: \(preset.isDefault)")

    // Only log active sounds
    let activeStates = preset.soundStates.filter { $0.isSelected }
    if !activeStates.isEmpty {
      print("  - Active Sounds:")
      activeStates.forEach { state in
        print("    * \(state.fileName) (Volume: \(state.volume))")
      }
    }
  }

  func logPresetApplication(_ preset: Preset) {
    print("\n🎛️ PresetManager: --- Begin Apply Preset ---")
    print("🎛️ PresetManager: Applying preset '\(preset.name)':")
    print("  - ID: \(preset.id)")
    print("  - Is Default: \(preset.isDefault)")
    print("  - Active Sounds:")
    preset.soundStates
      .filter { $0.isSelected }.forEach { state in
        print("    * \(state.fileName) (Volume: \(state.volume))")
      }
  }

  func applySoundStates(_ targetStates: [PresetState]) {
    // Get the file names of sounds that should be in this preset
    let presetSoundFileNames = Set(targetStates.map(\.fileName))

    // First, disable all sounds that are NOT in this preset
    AudioManager.shared.sounds.forEach { sound in
      if !presetSoundFileNames.contains(sound.fileName) && sound.isSelected {
        print("  - Disabling '\(sound.fileName)' (not in preset)")
        sound.isSelected = false
      }
    }

    // Then, apply the states for sounds that ARE in this preset
    targetStates.forEach { state in
      if let sound = AudioManager.shared.sounds.first(where: { $0.fileName == state.fileName }) {
        let selectionChanged = sound.isSelected != state.isSelected
        let volumeChanged = sound.volume != state.volume

        if selectionChanged || volumeChanged {
          print("  - Configuring '\(sound.fileName)':")
          if selectionChanged {
            print("    * Selection: \(sound.isSelected) -> \(state.isSelected)")
          }
          if volumeChanged {
            print("    * Volume: \(sound.volume) -> \(state.volume)")
          }

          sound.isSelected = state.isSelected
          sound.volume = state.volume
        }
      }
    }
  }

  func applySoundOrder(_ soundOrder: [String]) {
    print("🎛️ PresetManager: Applying custom sound order")

    // Apply the order from the preset
    for (index, fileName) in soundOrder.enumerated() {
      if let sound = AudioManager.shared.sounds.first(where: { $0.fileName == fileName }) {
        let oldOrder = sound.customOrder
        sound.customOrder = index
        if oldOrder != index {
          print("  - '\(fileName)': Order \(oldOrder) -> \(index)")
        }
      }
    }

    // Handle any sounds not in the preset order (new sounds added after preset creation)
    let unorderedSounds = AudioManager.shared.sounds.filter { sound in
      !soundOrder.contains(sound.fileName)
    }

    if !unorderedSounds.isEmpty {
      let nextOrderValue = soundOrder.count
      print(
        "🎛️ PresetManager: Assigning order to \(unorderedSounds.count) unordered sounds starting at \(nextOrderValue)"
      )

      for (offset, sound) in unorderedSounds.enumerated() {
        sound.customOrder = nextOrderValue + offset
        print("  - '\(sound.fileName)': New order \(nextOrderValue + offset)")
      }
    }
  }
}
