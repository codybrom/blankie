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
    setLoading(true)

    do {
      // Load or create default preset
      let defaultPreset = PresetStorage.loadDefaultPreset() ?? createDefaultPreset()
      setPresets([defaultPreset])

      // Load custom presets
      let customPresets = PresetStorage.loadCustomPresets()
      if !customPresets.isEmpty {
        var allPresets = presets
        allPresets.append(contentsOf: customPresets)
        setPresets(allPresets)
      }

      // Migrate any presets that contain old sound names with file extensions
      migratePresetSoundNames()

      // Ensure all custom presets have order values
      ensurePresetOrder()

      updateCustomPresetStatus()

      // Load last active preset or default
      if let lastID = PresetStorage.loadLastActivePresetID() {
        print("🎛️ PresetManager: Found last active preset ID: \(lastID)")
        if let lastPreset = presets.first(where: { $0.id == lastID }) {
          print("🎛️ PresetManager: ✅ Found matching preset: '\(lastPreset.name)'")
          print("\n🎛️ PresetManager: Loading last active preset:")
          logPresetState(lastPreset)
          try applyPreset(lastPreset, isInitialLoad: true)
          print("🎛️ PresetManager: ✅ Successfully applied last active preset '\(lastPreset.name)'")
        } else {
          print("❌ PresetManager: Last active preset ID \(lastID) not found in loaded presets")
          print("🎛️ PresetManager: Available presets: \(presets.map { "\($0.name) (\($0.id))" })")
          print("🎛️ PresetManager: Falling back to default preset")
          try applyPreset(presets[0], isInitialLoad: true)
        }
      } else {
        print("🎛️ PresetManager: No last active preset ID found, applying default")
        try applyPreset(presets[0], isInitialLoad: true)
      }
    } catch {
      handleError(error)
    }

    setLoading(false)
    setInitialLoad(false)
    print("🎛️ PresetManager: --- End Loading Presets ---\n")
  }

  @MainActor
  func savePresets() {
    print("\n🎛️ PresetManager: --- Begin Saving Presets ---")

    // Update current preset's state before saving
    if let currentPreset = currentPreset,
      let index = presets.firstIndex(where: { $0.id == currentPreset.id })
    {
      // Get the preset from the array to preserve any updates (like order)
      var updatedPreset = presets[index]
      // For custom presets, only update sounds that are already in the preset
      if !updatedPreset.isDefault {
        updatedPreset.soundStates = updatedPreset.soundStates.map { existingState in
          // Find the current sound state
          if let sound = AudioManager.shared.sounds.first(where: {
            $0.fileName == existingState.fileName
          }) {
            return PresetState(
              fileName: existingState.fileName,
              isSelected: sound.isSelected,
              volume: sound.volume
            )
          }
          return existingState
        }
      } else {
        // For default preset, include all sounds
        updatedPreset.soundStates = AudioManager.shared.sounds.map { sound in
          PresetState(
            fileName: sound.fileName,
            isSelected: sound.isSelected,
            volume: sound.volume
          )
        }
      }
      updatePresetAtIndex(index, with: updatedPreset)
      setCurrentPreset(updatedPreset)

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

    // Move file I/O to background queue to prevent UI blocking
    Task.detached {
      if let defaultPreset = defaultPreset {
        PresetStorage.saveDefaultPreset(defaultPreset)
      }
      PresetStorage.saveCustomPresets(customPresets)
    }

    // Cache thumbnails for quick access
    Task {
      await cacheAllThumbnails()
    }

    print("🎛️ PresetManager: --- End Saving Presets ---\n")
  }

  /// Migrates preset sound names from old format (with file extensions) to new format (without extensions)
  private func migratePresetSoundNames() {
    let legacyExtensions = ["mp3", "m4a", "wav", "aiff"]
    var migratedPresets = [Preset]()
    var hasMigrations = false

    for preset in presets {
      var migratedSoundStates = [PresetState]()
      var presetHasMigrations = false

      for soundState in preset.soundStates {
        var migratedFileName = soundState.fileName

        // Check if this fileName has a legacy extension
        for ext in legacyExtensions where soundState.fileName.hasSuffix(".\(ext)") {
          migratedFileName = soundState.fileName.replacingOccurrences(of: ".\(ext)", with: "")
          presetHasMigrations = true
          print(
            "🔄 PresetManager: Migrating sound name in preset '\(preset.name)': '\(soundState.fileName)' -> '\(migratedFileName)'"
          )
          break
        }

        migratedSoundStates.append(
          PresetState(
            fileName: migratedFileName,
            isSelected: soundState.isSelected,
            volume: soundState.volume
          ))
      }

      if presetHasMigrations {
        var migratedPreset = preset
        migratedPreset.soundStates = migratedSoundStates
        migratedPresets.append(migratedPreset)
        hasMigrations = true
      } else {
        migratedPresets.append(preset)
      }
    }

    if hasMigrations {
      setPresets(migratedPresets)
      print("🔄 PresetManager: Preset migration completed, saving updated presets")

      // Save the migrated presets immediately
      let defaultPreset = migratedPresets.first { $0.isDefault }
      let customPresets = migratedPresets.filter { !$0.isDefault }

      if let defaultPreset = defaultPreset {
        PresetStorage.saveDefaultPreset(defaultPreset)
      }
      PresetStorage.saveCustomPresets(customPresets)
    }
  }

  /// Ensures all custom presets have unique order values assigned
  @MainActor
  private func ensurePresetOrder() {
    var needsSave = false
    var updatedPresets = presets

    // Get custom presets
    let customPresets = updatedPresets.filter { !$0.isDefault }

    // Check for duplicates or nil order values
    var orderValues = Set<Int>()
    var hasDuplicates = false

    for preset in customPresets {
      if let order = preset.order {
        if orderValues.contains(order) {
          hasDuplicates = true
          print("🎛️ PresetManager: Found duplicate order value: \(order)")
          break
        }
        orderValues.insert(order)
      }
    }

    // Check if any custom preset is missing order or has duplicates
    let hasUnorderedPresets = customPresets.contains { $0.order == nil } || hasDuplicates

    if hasUnorderedPresets {
      print("🎛️ PresetManager: Reassigning order values to all custom presets")

      // Sort custom presets by current order (if exists) then by name
      let sortedCustomPresets = customPresets.sorted { preset1, preset2 in
        // First sort by existing order if both have it
        if let order1 = preset1.order, let order2 = preset2.order {
          return order1 < order2
        }
        // Put presets with order before those without
        if preset1.order != nil && preset2.order == nil {
          return true
        }
        if preset1.order == nil && preset2.order != nil {
          return false
        }
        // Fall back to name comparison
        return preset1.name < preset2.name
      }

      // Assign sequential order values to all custom presets
      for (index, preset) in sortedCustomPresets.enumerated() {
        var updatedPreset = preset
        updatedPreset.order = index
        print("🎛️ PresetManager: Assigning order \(index) to preset '\(preset.name)'")

        if let presetIndex = updatedPresets.firstIndex(where: { $0.id == preset.id }) {
          updatedPresets[presetIndex] = updatedPreset
          needsSave = true
        }
      }

      if needsSave {
        setPresets(updatedPresets)
        savePresets()
      }
    }
  }
}
