//
//  PresetManager+Persistence.swift
//  Blankie
//
//  Created by Cody Bromley on 1/30/25.
//

import SwiftUI

// MARK: - Persistence

extension PresetManager {
  @MainActor
  func loadPresets() async {
    print("\n🎛️ PresetManager: --- Begin Loading Presets ---")
    isLoading = true

    do {
      // Load or create default preset
      let defaultPreset = PresetStorage.loadDefaultPreset() ?? createDefaultPreset()
      presets = [defaultPreset]

      // Load custom presets
      let customPresets = PresetStorage.loadCustomPresets()
      if !customPresets.isEmpty {
        presets.append(contentsOf: customPresets)
      }

      updateCustomPresetStatus()

      // Load last active preset or default
      if let lastID = PresetStorage.loadLastActivePresetID(),
        let lastPreset = presets.first(where: { $0.id == lastID })
      {
        print("\n🎛️ PresetManager: Loading last active preset:")
        logPresetState(lastPreset)
        try applyPreset(lastPreset, isInitialLoad: true)
      } else {
        print("\n🎛️ PresetManager: No last active preset, applying default")
        try applyPreset(presets[0], isInitialLoad: true)
      }
    } catch {
      handleError(error)
    }

    isLoading = false
    isInitialLoad = false
    print("🎛️ PresetManager: --- End Loading Presets ---\n")
  }

  @MainActor
  func savePresets() {
    print("\n🎛️ PresetManager: --- Begin Saving Presets ---")

    // Update current preset's state before saving
    if let currentPreset = currentPreset,
      let index = presets.firstIndex(where: { $0.id == currentPreset.id })
    {
      var updatedPreset = currentPreset
      updatedPreset.soundStates = AudioManager.shared.sounds.map { sound in
        PresetState(
          fileName: sound.fileName,
          isSelected: sound.isSelected,
          volume: sound.volume
        )
      }
      presets[index] = updatedPreset
      self.currentPreset = updatedPreset

      print("Saving current preset state for '\(updatedPreset.name)':")
      print("  - Active sounds:")
      updatedPreset.soundStates
        .filter { $0.isSelected }
        .forEach { state in
          print("    * \(state.fileName) (Volume: \(state.volume))")
        }
    }

    let defaultPreset = presets.first { $0.isDefault }
    let customPresets = presets.filter { !$0.isDefault }

    if let defaultPreset = defaultPreset {
      PresetStorage.saveDefaultPreset(defaultPreset)
    }
    PresetStorage.saveCustomPresets(customPresets)
    print("🎛️ PresetManager: --- End Saving Presets ---\n")
  }
}
