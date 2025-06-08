//
//  GlobalSettings+Initialization.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import Foundation
import SwiftUI

extension GlobalSettings {
  func loadBasicSettings() {
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

    // Show labels preference (default to true)
    showSoundNames =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.showSoundNames) as? Bool ?? true

    // Icon size preference (default to medium)
    if let savedSize = UserDefaults.standard.string(forKey: UserDefaultsKeys.iconSize),
      let size = IconSize(rawValue: savedSize)
    {
      iconSize = size
    } else {
      iconSize = .medium
    }

    // Show list view preference (default to false - grid view)
    showingListView = UserDefaults.standard.bool(forKey: UserDefaultsKeys.showingListView)

    // Show progress border preference (default to true)
    showProgressBorder =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.showProgressBorder) as? Bool ?? true

    // Hide inactive sound sliders preference (default to false)
    hideInactiveSoundSliders =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.hideInactiveSoundSliders) as? Bool
      ?? false

    // Lock portrait orientation on iOS preference (default to false)
    lockPortraitOrientationiOS =
      UserDefaults.standard.object(forKey: UserDefaultsKeys.lockPortraitOrientationiOS) as? Bool
      ?? false
  }

  func loadPlatformSettings() {
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
  }

  func loadLanguageSettings() {
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
  }

  func migrateLegacySettings() {
    // Migration: Convert old alwaysStartPaused setting to new autoPlayOnLaunch setting
    if let oldValue = UserDefaults.standard.object(forKey: "alwaysStartPaused") as? Bool {
      print(
        "🔄 GlobalSettings: Migrating alwaysStartPaused(\(oldValue)) to autoPlayOnLaunch(\(!oldValue))"
      )
      autoPlayOnLaunch = !oldValue  // Flip the logic
      UserDefaults.standard.set(autoPlayOnLaunch, forKey: UserDefaultsKeys.autoPlayOnLaunch)
      UserDefaults.standard.removeObject(forKey: "alwaysStartPaused")  // Remove old key
    }
  }
}
