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
      loadCustomSounds()
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
          let supportedExtensions = ["wav", "m4a", "mp3", "aiff"]
          let fileExtension =
            supportedExtensions.first { soundData.fileName.hasSuffix(".\($0)") } ?? "mp3"
          let cleanedFileName = soundData.fileName.replacingOccurrences(
            of: ".\(fileExtension)", with: "")

          return Sound(
            title: soundData.title,
            systemIconName: soundData.systemIconName,
            fileName: cleanedFileName,
            fileExtension: fileExtension,
            defaultOrder: soundData.defaultOrder
          )
        }

      // Add built-in sounds to the sounds array
      self.sounds.append(contentsOf: builtInSounds)

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

  func loadCustomSounds() {
    print("🎵 AudioManager: Loading custom sounds")

    // Get all custom sounds from the database
    let customSoundData = CustomSoundManager.shared.getAllCustomSounds()

    // Remove any existing custom sounds from the array
    sounds.removeAll(where: { $0 is CustomSound })

    // Create Sound objects for each custom sound
    let customSounds = customSoundData.compactMap { data -> CustomSound? in
      guard let url = CustomSoundManager.shared.getURLForCustomSound(data) else {
        print("❌ AudioManager: Could not get URL for custom sound \(data.fileName)")
        return nil
      }

      return CustomSound(
        title: data.title,
        systemIconName: data.systemIconName,
        fileName: data.fileName,
        fileExtension: data.fileExtension,
        fileURL: url,
        customSoundData: data
      )
    }

    // Add custom sounds to the array
    sounds.append(contentsOf: customSounds)
    print("🎵 AudioManager: Loaded \(customSounds.count) custom sounds")

    // Re-setup observers for the new sounds
    setupSoundObservers()
  }

  private struct SoundsContainer: Codable {
    let sounds: [SoundData]
  }
}
