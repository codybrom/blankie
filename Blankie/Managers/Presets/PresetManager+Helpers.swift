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
    self.error = error
  }

  func updateCustomPresetStatus() {
    hasCustomPresets = presets.contains { !$0.isDefault }
  }

  func createDefaultPreset() -> Preset {
    print("🎛️ PresetManager: Creating new default preset")
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
      isDefault: true
    )
  }

  func createPresetFromCurrentState(name: String) throws -> Preset {
    print("🎛️ PresetManager: Creating preset from current state")

    guard !name.isEmpty else {
      throw PresetError.invalidPreset
    }

    let preset = Preset(
      id: UUID(),
      name: name,
      soundStates: AudioManager.shared.sounds.map { sound in
        print(
          "  - Capturing '\(sound.fileName)': Selected: \(sound.isSelected), Volume: \(sound.volume)"
        )
        return PresetState(
          fileName: sound.fileName,
          isSelected: sound.isSelected,
          volume: sound.volume
        )
      },
      isDefault: false
    )

    guard preset.validate() else {
      throw PresetError.invalidPreset
    }

    return preset
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

  func applySoundStates(_ targetStates: [SoundState]) {
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
