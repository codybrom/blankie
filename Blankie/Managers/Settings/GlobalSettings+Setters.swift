//
//  GlobalSettings+Setters.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import Foundation
import SwiftUI

extension GlobalSettings {
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
  func setShowSoundNames(_ value: Bool) {
    showSoundNames = value
    UserDefaults.standard.set(showSoundNames, forKey: UserDefaultsKeys.showSoundNames)
    logCurrentSettings()
  }

  @MainActor
  func setIconSize(_ value: IconSize) {
    iconSize = value
    UserDefaults.standard.set(iconSize.rawValue, forKey: UserDefaultsKeys.iconSize)
    logCurrentSettings()
  }

  @MainActor
  func setShowingListView(_ value: Bool) {
    showingListView = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.showingListView)
    logCurrentSettings()
  }

  @MainActor
  func setShowProgressBorder(_ value: Bool) {
    showProgressBorder = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.showProgressBorder)
    logCurrentSettings()
  }

  @MainActor
  func setLockPortraitOrientationiOS(_ value: Bool) {
    lockPortraitOrientationiOS = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.lockPortraitOrientationiOS)
    logCurrentSettings()
  }

  @MainActor
  func setQuickMixSoundFileNames(_ value: [String]) {
    quickMixSoundFileNames = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.quickMixSoundFileNames)
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
