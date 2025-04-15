//
//  GlobalSettings.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import Combine
import SwiftUI

private enum UserDefaultsKeys {
  static let volume = "globalVolume"
  static let appearance = "appearanceMode"
  static let accentColor = "customAccentColor"
  static let alwaysStartPaused = "alwaysStartPaused"
  static let hideInactiveSounds = "hideInactiveSounds"
  static let enableHaptics = "enableHaptics"
  static let enableSpatialAudio = "enableSpatialAudio"
}

class GlobalSettings: ObservableObject {
  static let shared = GlobalSettings()

  @Published private(set) var volume: Double
  @Published private(set) var appearance: AppearanceMode
  @Published private(set) var customAccentColor: Color?
  @Published private(set) var alwaysStartPaused: Bool
  @Published private(set) var hideInactiveSounds: Bool

  // Platform-specific settings
  @Published private(set) var enableHaptics: Bool = true
  @Published private(set) var enableSpatialAudio: Bool = false

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

    // Default to true for alwaysStartPaused if not set
    alwaysStartPaused =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.alwaysStartPaused) as? Bool ?? true

    // Hide inactive sounds preference
    hideInactiveSounds = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideInactiveSounds)

    // Load platform-specific preferences
    enableHaptics =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.enableHaptics) as? Bool ?? true
    enableSpatialAudio =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.enableSpatialAudio) as? Bool ?? false

    // After initialization, setup observers
    setupObservers()
    logCurrentSettings()
  }

  private func validateVolume(_ volume: Double) -> Double {
    min(max(volume, 0.0), 1.0)
  }

  private func setupObservers() {
    _appearance.projectedValue.sink { newValue in
      UserDefaults.standard.setValue(newValue.rawValue, forKey: UserDefaultsKeys.appearance)
    }.store(in: &observers)

    _customAccentColor.projectedValue.sink { newColor in
      if let color = newColor {
        UserDefaults.standard.set(color.toString, forKey: UserDefaultsKeys.accentColor)
      } else {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.accentColor)
      }
    }.store(in: &observers)

    _alwaysStartPaused.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.alwaysStartPaused)
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
  func setAlwaysStartPaused(_ value: Bool) {
    alwaysStartPaused = value
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

  func logCurrentSettings() {
    print("\n⚙️ GlobalSettings: Current State")
    print("  - Volume: \(volume)")
    print("  - Appearance: \(appearance.rawValue)")
    print("  - Custom Accent Color: \(customAccentColor?.toString ?? "System")")
    print("  - Always Start Paused: \(alwaysStartPaused)")
    print("  - Hide Inactive Sounds: \(hideInactiveSounds)")
    print("  - Enable Haptics: \(enableHaptics)")
    print("  - Enable Spatial Audio: \(enableSpatialAudio)")
  }
}
