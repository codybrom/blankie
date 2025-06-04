//
//  AudioManager+SoundLoading.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftData
import SwiftUI

// MARK: - Sound Loading
extension AudioManager {
  func loadSounds() {
    print("🎵 AudioManager: Loading built-in sounds from JSON")

    // Start with an empty array
    self.sounds = []

    // Load built-in sounds
    loadBuiltInSounds()

    // Load custom sounds if available
    if modelContext != nil {
      Task { @MainActor in
        self.loadCustomSounds()
      }
    }
  }

  private func loadBuiltInSounds() {
    guard let url = Bundle.main.url(forResource: "sounds", withExtension: "json") else {
      print("❌ AudioManager: sounds.json file not found in Resources folder")
      ErrorReporter.shared.report(AudioError.fileNotFound)
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      let soundsContainer = try decoder.decode(SoundsContainer.self, from: data)

      let builtInSounds = soundsContainer.sounds
        .sorted(by: { $0.defaultOrder < $1.defaultOrder })
        .map { soundData in
          let supportedExtensions = ["m4a", "wav", "mp3", "aiff"]

          // Check if fileName already has an extension
          let hasExtension = supportedExtensions.contains { soundData.fileName.hasSuffix(".\($0)") }

          let (cleanedFileName, fileExtension): (String, String)
          if hasExtension {
            // Old format: fileName has extension, extract it
            let detectedExtension =
              supportedExtensions.first { soundData.fileName.hasSuffix(".\($0)") } ?? "mp3"
            cleanedFileName = soundData.fileName.replacingOccurrences(
              of: ".\(detectedExtension)", with: "")
            fileExtension = detectedExtension
          } else {
            // New format: fileName has no extension, detect from bundle
            cleanedFileName = soundData.fileName
            fileExtension =
              supportedExtensions.first {
                Bundle.main.url(forResource: soundData.fileName, withExtension: $0) != nil
              } ?? "mp3"
          }

          return Sound(
            title: soundData.title,
            systemIconName: soundData.systemIconName,
            fileName: cleanedFileName,
            fileExtension: fileExtension,
            defaultOrder: soundData.defaultOrder,
            lufs: soundData.lufs,
            normalizationFactor: soundData.normalizationFactor
          )
        }

      // Add built-in sounds to the sounds array
      self.sounds.append(contentsOf: builtInSounds)

      // Migrate user preferences from old format (with extensions) to new format (without extensions)
      migrateUserPreferences(for: builtInSounds)

      // Initialize custom order for sounds that don't have one saved in UserDefaults
      for (index, sound) in builtInSounds.enumerated()
      where UserDefaults.standard.object(forKey: "\(sound.fileName)_customOrder") == nil {
        sound.customOrder = index
      }

      print("🎵 AudioManager: Loaded \(builtInSounds.count) built-in sounds")
    } catch {
      print("❌ AudioManager: Failed to parse sounds.json: \(error)")
      ErrorReporter.shared.report(error)
    }
  }

  @MainActor
  func loadCustomSounds() {
    print("🎵 AudioManager: Loading custom sounds")

    // Get all custom sounds from the database
    let customSoundData = CustomSoundManager.shared.getAllCustomSounds()

    // Before removing custom sounds, stop any that are playing
    let customSoundsToRemove = sounds.filter { $0.isCustom }
    for sound in customSoundsToRemove where sound.isSelected {
      sound.pause(immediate: true)
      sound.isSelected = false
    }

    // Remove any existing custom sounds from the array
    sounds.removeAll(where: { $0.isCustom })

    // Calculate the starting order for custom sounds (after all built-in sounds)
    let maxBuiltInOrder = sounds.filter { !$0.isCustom }.map { $0.customOrder }.max() ?? 0
    let customSoundStartOrder = maxBuiltInOrder + 100  // Add some buffer space

    // Create Sound objects for each custom sound
    let customSounds = customSoundData.enumerated().compactMap { (index, data) -> Sound? in
      guard let url = CustomSoundManager.shared.getURLForCustomSound(data) else {
        print("❌ AudioManager: Could not get URL for custom sound \(data.fileName)")
        return nil
      }

      // Create customization for the custom sound with its settings
      var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
        for: data.fileName)
      customization.customTitle = data.title
      customization.customIconName = data.systemIconName
      customization.randomizeStartPosition = data.randomizeStartPosition
      customization.normalizeAudio = data.normalizeAudio
      customization.volumeAdjustment = data.volumeAdjustment
      SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

      return Sound(
        title: data.title,
        systemIconName: data.systemIconName,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
        defaultOrder: customSoundStartOrder + index,  // Increment for each custom sound
        lufs: data.detectedLUFS,
        normalizationFactor: data.normalizationFactor,
        isCustom: true,
        fileURL: url,
        dateAdded: data.dateAdded,
        customSoundDataID: data.id
      )
    }

    // Add custom sounds to the array
    sounds.append(contentsOf: customSounds)
    print("🎵 AudioManager: Loaded \(customSounds.count) custom sounds")

    // Re-setup observers for the new sounds
    setupSoundObservers()

    // Clean up deleted custom sounds from presets
    Task { @MainActor in
      PresetManager.shared.cleanupDeletedCustomSounds()
    }
  }

  private struct SoundsContainer: Codable {
    let sounds: [SoundData]
  }

  /// Migrates user preferences from old format (with file extensions) to new format (without extensions)
  private func migrateUserPreferences(for sounds: [Sound]) {
    let userDefaults = UserDefaults.standard
    let legacyExtensions = ["mp3", "m4a", "wav", "aiff"]

    for sound in sounds {
      let newFileName = sound.fileName

      // Try to find preferences with legacy extensions
      for ext in legacyExtensions {
        let legacyFileName = "\(newFileName).\(ext)"

        // Migrate isSelected
        if let legacyIsSelected = userDefaults.object(forKey: "\(legacyFileName)_isSelected")
          as? Bool
        {
          userDefaults.set(legacyIsSelected, forKey: "\(newFileName)_isSelected")
          userDefaults.removeObject(forKey: "\(legacyFileName)_isSelected")
          print("🔄 AudioManager: Migrated isSelected for '\(legacyFileName)' -> '\(newFileName)'")
        }

        // Migrate volume
        if let legacyVolume = userDefaults.object(forKey: "\(legacyFileName)_volume") as? Float {
          userDefaults.set(legacyVolume, forKey: "\(newFileName)_volume")
          userDefaults.removeObject(forKey: "\(legacyFileName)_volume")
          print("🔄 AudioManager: Migrated volume for '\(legacyFileName)' -> '\(newFileName)'")
        }

        // Migrate customOrder
        if let legacyOrder = userDefaults.object(forKey: "\(legacyFileName)_customOrder") as? Int {
          userDefaults.set(legacyOrder, forKey: "\(newFileName)_customOrder")
          userDefaults.removeObject(forKey: "\(legacyFileName)_customOrder")
          print("🔄 AudioManager: Migrated customOrder for '\(legacyFileName)' -> '\(newFileName)'")
        }

        // Migrate isHidden
        if let legacyHidden = userDefaults.object(forKey: "\(legacyFileName)_isHidden") as? Bool {
          userDefaults.set(legacyHidden, forKey: "\(newFileName)_isHidden")
          userDefaults.removeObject(forKey: "\(legacyFileName)_isHidden")
          print("🔄 AudioManager: Migrated isHidden for '\(legacyFileName)' -> '\(newFileName)'")
        }
      }
    }
  }
}
