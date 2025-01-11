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
}

class GlobalSettings: ObservableObject {
  static let shared = GlobalSettings()

  @Published private(set) var volume: Double
  @Published private(set) var appearance: AppearanceMode
  @Published private(set) var customAccentColor: Color?
  @Published private(set) var alwaysStartPaused: Bool

  private var observers = Set<AnyCancellable>()

  private init() {
    // Initialize properties directly
    let savedVolume = UserDefaults.standard.double(forKey: "globalVolume")
    volume = savedVolume == 0 ? 1.0 : savedVolume

    appearance =
      UserDefaults.standard.string(forKey: "appearanceMode")
      .flatMap { AppearanceMode(rawValue: $0) } ?? .system

    // Load saved accent color
    if let colorString = UserDefaults.standard.string(forKey: "customAccentColor") {
      customAccentColor = Color(fromString: colorString)
    } else {
      customAccentColor = nil
    }

    // Default to true for alwaysStartPaused if not set
    alwaysStartPaused = UserDefaults.standard.object(forKey: "alwaysStartPaused") as? Bool ?? true

    // After initialization, setup observers and update appearance
    setupObservers()
    updateAppAppearance()
    logCurrentSettings()
  }

  private func validateVolume(_ volume: Double) -> Double {
    min(max(volume, 0.0), 1.0)
  }

  private func setupObservers() {
    _volume.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: "globalVolume")
    }.store(in: &observers)

    _appearance.projectedValue.sink { [weak self] newValue in
      UserDefaults.standard.setValue(newValue.rawValue, forKey: "appearanceMode")
      self?.updateAppAppearance()
    }.store(in: &observers)

    _customAccentColor.projectedValue.sink { newColor in
      if let color = newColor {
        UserDefaults.standard.set(color.toString, forKey: "customAccentColor")
      } else {
        UserDefaults.standard.removeObject(forKey: "customAccentColor")
      }
    }.store(in: &observers)

    _alwaysStartPaused.projectedValue.sink { newValue in
      UserDefaults.standard.set(newValue, forKey: "alwaysStartPaused")
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

  // Public methods to update values
  @MainActor
  func setVolume(_ newVolume: Double) {
    volume = newVolume
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

  func logCurrentSettings() {
    print("\n⚙️ GlobalSettings: Current State")
    print("  - Volume: \(volume)")
    print("  - Appearance: \(appearance.rawValue)")
    print("  - Custom Accent Color: \(customAccentColor?.toString ?? "System")")
    print("  - Always Start Paused: \(alwaysStartPaused)")
  }

}
