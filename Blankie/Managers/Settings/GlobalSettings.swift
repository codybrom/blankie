//
//  GlobalSettings.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

enum UserDefaultsKeys {
  static let volume = "globalVolume"
  static let appearance = "appearanceMode"
  static let accentColor = "customAccentColor"
  static let autoPlayOnLaunch = "autoPlayOnLaunch"
  static let hideInactiveSounds = "hideInactiveSounds"
  static let enableHaptics = "enableHaptics"
  static let enableSpatialAudio = "enableSpatialAudio"
  static let language = "languagePreference"
  static let mixWithOthers = "mixWithOthers"
  static let lowerVolumeWithOtherAudio = "lowerVolumeWithOtherAudio"
  static let volumeWithOtherAudio = "volumeWithOtherAudio"
}

class GlobalSettings: ObservableObject {
  @Published var needsRestartForLanguageChange = false
  static let shared = GlobalSettings()

  @Published private(set) var volume: Double
  @Published private(set) var appearance: AppearanceMode
  @Published private(set) var customAccentColor: Color?
  @Published private(set) var autoPlayOnLaunch: Bool
  @Published private(set) var hideInactiveSounds: Bool
  @Published private(set) var language: Language
  @Published private(set) var availableLanguages: [Language] = []

  // Platform-specific settings
  @Published private(set) var enableHaptics: Bool = true
  @Published private(set) var enableSpatialAudio: Bool = false
  @Published private(set) var mixWithOthers: Bool = false
  @Published private(set) var lowerVolumeWithOtherAudio: Bool = false
  @Published private(set) var volumeWithOtherAudio: Double = 0.5  // 0.0 = silent, 1.0 = full volume

  var observers = Set<AnyCancellable>()
  var volumeDebounceTimer: Timer?

  private init() {
    // Initialize properties directly
    let savedVolume = UserDefaults.standard.double(forKey: UserDefaultsKeys.volume)
    volume = savedVolume == 0 ? 1.0 : savedVolume

    appearance =
      UserDefaults.standard.string(forKey: UserDefaultsKeys.appearance)
      .flatMap { AppearanceMode(rawValue: $0) } ?? .system

    // Load saved accent color
    if let colorString = UserDefaults.standard.string(forKey: UserDefaultsKeys.accentColor) {
      customAccentColor = Color(fromString: colorString)
    } else {
      customAccentColor = nil
    }

    // Default to false for autoPlayOnLaunch if not set (safer default)
    autoPlayOnLaunch =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.autoPlayOnLaunch) as? Bool ?? false

    // Hide inactive sounds preference
    hideInactiveSounds = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideInactiveSounds)

    // Load platform-specific preferences
    enableHaptics =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.enableHaptics) as? Bool ?? true
    enableSpatialAudio =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.enableSpatialAudio) as? Bool ?? false
    mixWithOthers =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.mixWithOthers) as? Bool ?? false
    lowerVolumeWithOtherAudio =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.lowerVolumeWithOtherAudio) as? Bool
      ?? false
    volumeWithOtherAudio =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.volumeWithOtherAudio) as? Double ?? 0.5

    // First initialize language with default value
    language = Language.system

    // Then load available languages
    availableLanguages = Language.getAvailableLanguages()

    // Finally, try to set the saved language preference
    let savedLanguageCode = UserDefaults.standard.string(forKey: UserDefaultsKeys.language)
    if let code = savedLanguageCode,
      let savedLanguage = availableLanguages.first(where: { $0.code == code })
    {
      language = savedLanguage
    }

    // Migration: Convert old alwaysStartPaused setting to new autoPlayOnLaunch setting
    if let oldValue = UserDefaults.standard.object(forKey: "alwaysStartPaused") as? Bool {
      print(
        "🔄 GlobalSettings: Migrating alwaysStartPaused(\(oldValue)) to autoPlayOnLaunch(\(!oldValue))"
      )
      autoPlayOnLaunch = !oldValue  // Flip the logic
      UserDefaults.standard.set(autoPlayOnLaunch, forKey: UserDefaultsKeys.autoPlayOnLaunch)
      UserDefaults.standard.removeObject(forKey: "alwaysStartPaused")  // Remove old key
    }

    // After initialization, log current settings
    logCurrentSettings()
  }

  @MainActor
  func setVolume(_ newVolume: Double) {
    volume = validateVolume(newVolume)
    debouncedSaveVolume(volume)
    logCurrentSettings()
  }

  @MainActor
  func setAppearance(_ newAppearance: AppearanceMode) {
    appearance = newAppearance
    UserDefaults.standard.setValue(newAppearance.rawValue, forKey: UserDefaultsKeys.appearance)
    updateAppAppearance()
    logCurrentSettings()
  }

  @MainActor
  func setAccentColor(_ newColor: Color?) {
    customAccentColor = newColor
    if let color = newColor {
      UserDefaults.standard.set(color.toString, forKey: UserDefaultsKeys.accentColor)
    } else {
      UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.accentColor)
    }
    logCurrentSettings()
  }

  @MainActor
  func setAutoPlayOnLaunch(_ value: Bool) {
    autoPlayOnLaunch = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.autoPlayOnLaunch)
    logCurrentSettings()
  }

  @MainActor
  func toggleHideInactiveSounds() {
    hideInactiveSounds.toggle()
    UserDefaults.standard.set(hideInactiveSounds, forKey: UserDefaultsKeys.hideInactiveSounds)
    logCurrentSettings()
  }

  @MainActor
  func setHideInactiveSounds(_ value: Bool) {
    hideInactiveSounds = value
    UserDefaults.standard.set(hideInactiveSounds, forKey: UserDefaultsKeys.hideInactiveSounds)
    logCurrentSettings()
  }

  @MainActor
  func setEnableHaptics(_ value: Bool) {
    enableHaptics = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.enableHaptics)
    logCurrentSettings()
  }

  @MainActor
  func setEnableSpatialAudio(_ value: Bool) {
    enableSpatialAudio = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.enableSpatialAudio)
    // Here we would also update the audio engine to enable/disable spatial audio
    logCurrentSettings()
  }

  @MainActor
  func setMixWithOthers(_ value: Bool) {
    mixWithOthers = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.mixWithOthers)
    #if os(iOS) || os(visionOS)
      // Update audio session configuration
      updateAudioSession()
    #endif
    logCurrentSettings()
  }

  @MainActor
  func setLowerVolumeWithOtherAudio(_ value: Bool) {
    lowerVolumeWithOtherAudio = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.lowerVolumeWithOtherAudio)
    #if os(iOS) || os(visionOS)
      // Update audio session configuration
      updateAudioSession()
    #endif
    // Apply the new setting to currently playing sounds
    if AudioManager.shared.isGloballyPlaying {
      AudioManager.shared.applyVolumeSettings()
    }
    logCurrentSettings()
  }

  @MainActor
  func setVolumeWithOtherAudio(_ level: Double) {
    volumeWithOtherAudio = max(0.0, min(1.0, level))  // Clamp between 0.0 and 1.0
    UserDefaults.standard.set(volumeWithOtherAudio, forKey: UserDefaultsKeys.volumeWithOtherAudio)
    // Apply the new volume level to currently playing sounds
    if AudioManager.shared.isGloballyPlaying {
      AudioManager.shared.applyVolumeSettings()
    }
    logCurrentSettings()
  }

  @MainActor
  func setLanguage(_ newLanguage: Language) {
    guard newLanguage.code != language.code else {
      print("🌐 Language not changed (already set to \(language.code))")
      return
    }

    print("🌐 GlobalSettings: Changing language from \(language.code) to \(newLanguage.code)")
    language = newLanguage
    UserDefaults.standard.setValue(newLanguage.code, forKey: UserDefaultsKeys.language)

    needsRestartForLanguageChange = true
    Language.applyLanguage(newLanguage)
    logCurrentSettings()
  }

  private func updateAppAppearance() {
    #if os(macOS)
      DispatchQueue.main.async {
        switch self.appearance {
        case .system:
          NSApp.appearance = nil
        case .light:
          NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
          NSApp.appearance = NSAppearance(named: .darkAqua)
        }
      }
    #endif
  }
}
