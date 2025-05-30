//
//  GlobalSettings.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import Combine
import Foundation
import SwiftUI

private enum UserDefaultsKeys {
  static let volume = "globalVolume"
  static let appearance = "appearanceMode"
  static let accentColor = "customAccentColor"
  static let language = "languagePreference"
}

class GlobalSettings: ObservableObject {
  @Published var needsRestartForLanguageChange = false
  static let shared = GlobalSettings()

  @Published private(set) var volume: Double
  @Published private(set) var appearance: AppearanceMode
  @Published private(set) var customAccentColor: Color?
  @Published private(set) var alwaysStartPaused: Bool
  @Published private(set) var language: Language
  @Published private(set) var availableLanguages: [Language] = []

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
    alwaysStartPaused = UserDefaults.standard.object(forKey: "alwaysStartPaused") as? Bool ?? true

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

    // After initialization, setup observers and update appearance
    setupObservers()
    updateAppAppearance()
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

    _alwaysStartPaused.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: "alwaysStartPaused")
    }.store(in: &observers)

    _language.projectedValue.sink { newValue in
      UserDefaults.standard.setValue(newValue.code, forKey: UserDefaultsKeys.language)
    }.store(in: &observers)
  }

  private func updateAppAppearance() {
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
  }

  private func debouncedSaveVolume(_ newVolume: Double) {
    volumeDebounceTimer?.invalidate()
    volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {
      [weak self] _ in
      self?.saveVolume(newVolume)
    }
  }

  private func saveVolume(_ newVolume: Double) {
    let validatedVolume = validateVolume(newVolume)
    UserDefaults.standard.set(validatedVolume, forKey: "globalVolume")
    print("⚙️ GlobalSettings: Saved volume: \(validatedVolume)")
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
    updateAppAppearance()
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
    print("  - Always Start Paused: \(alwaysStartPaused)")
    print("  - Language: \(language.code)")
    print("  - Available Languages: \(availableLanguages.map { $0.code }.joined(separator: ", "))")
  }

}
