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


private enum UserDefaultsKeys {
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

  private var observers = Set<AnyCancellable>()
  private var volumeDebounceTimer: Timer?

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
      UserDefaults.standard.object(forKey: UserDefaultsKeys.lowerVolumeWithOtherAudio) as? Bool ?? false
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

    // After initialization, setup observers
    setupObservers()
    logCurrentSettings()
  }

  private func validateVolume(_ volume: Double) -> Double {
    min(max(volume, 0.0), 1.0)
  }

  private func setupObservers() {
    _appearance.projectedValue.sink { [weak self] newValue in
      UserDefaults.standard.setValue(newValue.rawValue, forKey: UserDefaultsKeys.appearance)
      self?.updateAppAppearance()
    }.store(in: &observers)

    _customAccentColor.projectedValue.sink { newColor in
      if let color = newColor {
        UserDefaults.standard.set(color.toString, forKey: UserDefaultsKeys.accentColor)
      } else {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.accentColor)
      }
    }.store(in: &observers)

    _autoPlayOnLaunch.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.autoPlayOnLaunch)
    }.store(in: &observers)

    _hideInactiveSounds.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.hideInactiveSounds)
    }.store(in: &observers)

    _enableHaptics.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.enableHaptics)
    }.store(in: &observers)

    _enableSpatialAudio.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.enableSpatialAudio)
    }.store(in: &observers)

    _mixWithOthers.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.mixWithOthers)
    }.store(in: &observers)

    _lowerVolumeWithOtherAudio.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.lowerVolumeWithOtherAudio)
    }.store(in: &observers)

    _volumeWithOtherAudio.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.volumeWithOtherAudio)
    }.store(in: &observers)

    _language.projectedValue.sink { newValue in
      UserDefaults.standard.setValue(newValue.code, forKey: UserDefaultsKeys.language)
    }.store(in: &observers)
  }

  private func debouncedSaveVolume(_ newVolume: Double) {
    volumeDebounceTimer?.invalidate()
    volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {
      [weak self] _ in
      self?.saveVolume(newVolume)
    }
  }

  private func saveVolume(_ newVolume: Double) {
    let validVolume = validateVolume(newVolume)
    UserDefaults.standard.set(validVolume, forKey: UserDefaultsKeys.volume)
    print("⚙️ GlobalSettings: Saved volume: \(validVolume)")

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
    logCurrentSettings()
  }

  @MainActor
  func setAccentColor(_ newColor: Color?) {
    customAccentColor = newColor
    logCurrentSettings()
  }

  @MainActor
  func setAutoPlayOnLaunch(_ value: Bool) {
    autoPlayOnLaunch = value
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
    logCurrentSettings()
  }

  @MainActor
  func setEnableSpatialAudio(_ value: Bool) {
    enableSpatialAudio = value
    // Here we would also update the audio engine to enable/disable spatial audio
    logCurrentSettings()
  }

  @MainActor
  func setMixWithOthers(_ value: Bool) {
    mixWithOthers = value
    #if os(iOS) || os(visionOS)
      // Update audio session configuration
      updateAudioSession()
    #endif
    logCurrentSettings()
  }

  @MainActor
  func setLowerVolumeWithOtherAudio(_ value: Bool) {
    lowerVolumeWithOtherAudio = value
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
    volumeWithOtherAudio = max(0.0, min(1.0, level)) // Clamp between 0.0 and 1.0
    // Apply the new volume level to currently playing sounds
    if AudioManager.shared.isGloballyPlaying {
      AudioManager.shared.applyVolumeSettings()
    }
    logCurrentSettings()
  }

  #if os(iOS) || os(visionOS)
    private func updateAudioSession() {
      do {
        let wasPlaying = AudioManager.shared.isGloballyPlaying

        // Configure the session based on mixWithOthers setting
        if mixWithOthers {
          // Allow mixing with other apps - we handle volume manually
          let options: AVAudioSession.CategoryOptions = [.mixWithOthers]
          print("⚙️ GlobalSettings: Setting Mix mode with manual volume control")

          try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: options
          )
        } else {
          // Exclusive playback mode - no mixing
          try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: []  // No options means exclusive playback
          )
        }

        // Always activate if we're currently playing to ensure we take over
        if wasPlaying {
          try AVAudioSession.sharedInstance().setActive(true)

          // Restart playback since changing to exclusive mode may have interrupted it
          AudioManager.shared.playSelected()

          // Update Now Playing info
          AudioManager.shared.updateNowPlayingState()
        }

        print(
          "⚙️ GlobalSettings: Updated audio session with mixWithOthers: \(mixWithOthers), volumeWithOtherAudio: \(volumeWithOtherAudio), activated: \(wasPlaying)"
        )
      } catch {
        print("❌ GlobalSettings: Failed to update audio session: \(error)")
      }
    }
  #endif

  @MainActor
  func setLanguage(_ newLanguage: Language) {
    guard newLanguage.code != language.code else {
      print("🌐 Language not changed (already set to \(language.code))")
      return
    }

    print("🌐 GlobalSettings: Changing language from \(language.code) to \(newLanguage.code)")
    language = newLanguage

    needsRestartForLanguageChange = true
    Language.applyLanguage(newLanguage)
    logCurrentSettings()
  }

  func logCurrentSettings() {
    print("\n⚙️ GlobalSettings: Current State")
    print("  - Volume: \(volume)")
    print("  - Appearance: \(appearance.rawValue)")
    print("  - Custom Accent Color: \(customAccentColor?.toString ?? "System")")
    print("  - Auto-play on Launch: \(autoPlayOnLaunch)")
    print("  - Hide Inactive Sounds: \(hideInactiveSounds)")
    print("  - Enable Haptics: \(enableHaptics)")
    print("  - Enable Spatial Audio: \(enableSpatialAudio)")
    print("  - Mix With Others: \(mixWithOthers)")
    print("  - Volume With Other Audio: \(volumeWithOtherAudio)")
    print("  - Language: \(language.code)")
    print("  - Available Languages: \(availableLanguages.map { $0.code }.joined(separator: ", "))")
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
