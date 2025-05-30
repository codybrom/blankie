//
//  SoundCustomization.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import Foundation
import SwiftUI

/// Represents customizations applied to built-in sounds
struct SoundCustomization: Codable, Identifiable {
  let id: UUID
  let fileName: String
  var customTitle: String?
  var customIconName: String?

  init(fileName: String, customTitle: String? = nil, customIconName: String? = nil) {
    self.id = UUID()
    self.fileName = fileName
    self.customTitle = customTitle
    self.customIconName = customIconName
  }

  /// Returns the effective title (custom or original)
  func effectiveTitle(originalTitle: String) -> String {
    return customTitle ?? originalTitle
  }

  /// Returns the effective icon name (custom or original)
  func effectiveIconName(originalIconName: String) -> String {
    return customIconName ?? originalIconName
  }

  /// Whether this customization has any custom values
  var hasCustomizations: Bool {
    return customTitle != nil || customIconName != nil
  }
}

/// Manager for built-in sound customizations
class SoundCustomizationManager: ObservableObject {
  static let shared = SoundCustomizationManager()

  @Published private var customizations: [String: SoundCustomization] = [:]

  private let userDefaultsKey = "soundCustomizations"

  private init() {
    loadCustomizations()
  }

  /// Get customization for a specific sound file name
  func getCustomization(for fileName: String) -> SoundCustomization? {
    return customizations[fileName]
  }

  /// Set custom title for a sound
  func setCustomTitle(_ title: String?, for fileName: String) {
    if title?.isEmpty == true {
      setCustomTitle(nil, for: fileName)
      return
    }

    var customization = customizations[fileName] ?? SoundCustomization(fileName: fileName)
    customization.customTitle = title

    if customization.hasCustomizations {
      customizations[fileName] = customization
    } else {
      customizations.removeValue(forKey: fileName)
    }

    saveCustomizations()
  }

  /// Set custom icon for a sound
  func setCustomIcon(_ iconName: String?, for fileName: String) {
    if iconName?.isEmpty == true {
      setCustomIcon(nil, for: fileName)
      return
    }

    var customization = customizations[fileName] ?? SoundCustomization(fileName: fileName)
    customization.customIconName = iconName

    if customization.hasCustomizations {
      customizations[fileName] = customization
    } else {
      customizations.removeValue(forKey: fileName)
    }

    saveCustomizations()
  }

  /// Reset all customizations for a specific sound
  func resetCustomizations(for fileName: String) {
    customizations.removeValue(forKey: fileName)
    saveCustomizations()
  }

  /// Reset all customizations for all sounds
  func resetAllCustomizations() {
    customizations.removeAll()
    saveCustomizations()
  }

  /// Get all customized sound file names
  var customizedSounds: [String] {
    return Array(customizations.keys)
  }

  /// Whether any sounds have customizations
  var hasAnyCustomizations: Bool {
    return !customizations.isEmpty
  }

  // MARK: - Persistence

  private func saveCustomizations() {
    do {
      let data = try JSONEncoder().encode(Array(customizations.values))
      UserDefaults.standard.set(data, forKey: userDefaultsKey)
      print("✅ SoundCustomizationManager: Saved \(customizations.count) customizations")
    } catch {
      print("❌ SoundCustomizationManager: Failed to save customizations: \(error)")
    }
  }

  private func loadCustomizations() {
    guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
      print("📦 SoundCustomizationManager: No saved customizations found")
      return
    }

    do {
      let customizationArray = try JSONDecoder().decode([SoundCustomization].self, from: data)
      customizations = Dictionary(
        uniqueKeysWithValues: customizationArray.map { ($0.fileName, $0) })
      print("✅ SoundCustomizationManager: Loaded \(customizations.count) customizations")
    } catch {
      print("❌ SoundCustomizationManager: Failed to load customizations: \(error)")
      customizations = [:]
    }
  }
}
