//
//  UITestingHelper.swift
//  Blankie
//
//  Created by Assistant on 5/27/25.
//

import Foundation

/// Helper class for UI testing setup and teardown
enum UITestingHelper {

  /// Check if we're running in UI testing mode with reset flag
  static func shouldResetForUITesting() -> Bool {
    return ProcessInfo.processInfo.arguments.contains("-UITestingResetDefaults")
  }

  /// Reset all UserDefaults to provide a clean state for UI testing
  static func resetAllDefaults() {
    guard shouldResetForUITesting() else { return }

    print("🧹 UITestingHelper: Resetting all UserDefaults for UI testing")

    // Reset all UserDefaults for the app bundle
    if let bundleId = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: bundleId)
      UserDefaults.standard.synchronize()
    }

    // Reset preset manager defaults
    UserDefaults.standard.removeObject(forKey: "presets")
    UserDefaults.standard.removeObject(forKey: "currentPresetID")

    // Reset any existing window frame data
    UserDefaults.standard.removeObject(forKey: "LastWindowFrame")
    UserDefaults.standard.removeObject(forKey: "NSWindow Frame main")
    UserDefaults.standard.removeObject(forKey: "HasSavedWindowPosition")

    // Reset global settings
    UserDefaults.standard.removeObject(forKey: "globalVolume")
    UserDefaults.standard.removeObject(forKey: "customAccentColor")
    UserDefaults.standard.removeObject(forKey: "enableHaptics")
    UserDefaults.standard.removeObject(forKey: "colorScheme")

    // Explicitly set these to false for UI testing
    UserDefaults.standard.set(false, forKey: "alwaysStartPaused")
    UserDefaults.standard.set(false, forKey: "hideInactiveSounds")

    // Force playback to start for screenshots
    if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
      UserDefaults.standard.set(true, forKey: "forceStartPlayback")
    }

    // Check if we should force dark mode
    if ProcessInfo.processInfo.arguments.contains("-ForceDarkMode") {
      UserDefaults.standard.set("dark", forKey: "appearanceMode")
    } else {
      // Default to light mode for consistency in screenshots
      UserDefaults.standard.set("light", forKey: "appearanceMode")
    }

    // Set consistent window size for screenshots
    let windowFrameDict: [String: Double] = [
      "x": 485.0,  // Center on a 1920px wide screen
      "y": 277.0,  // Center on a 1080px tall screen
      "width": 950.0,
      "height": 540.0,
    ]
    UserDefaults.standard.set(windowFrameDict, forKey: "LastWindowFrame")
    UserDefaults.standard.set(true, forKey: "HasSavedWindowPosition")

    // Reset all sound-related defaults
    let soundNames = [
      "rain", "storm", "wind", "waves", "stream", "birds", "summer-night",
      "train", "boat", "city", "coffee-shop", "fireplace", "pink-noise", "white-noise",
    ]

    // For screenshot mode, set specific sounds as selected
    if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
      // Reset all sounds first
      for soundName in soundNames {
        UserDefaults.standard.removeObject(forKey: "\(soundName)_volume")
        UserDefaults.standard.set(false, forKey: "\(soundName)_isSelected")
      }

      // Then activate and set volumes for our specific sounds
      UserDefaults.standard.set(true, forKey: "rain_isSelected")
      UserDefaults.standard.set(0.8, forKey: "rain_volume")

      UserDefaults.standard.set(true, forKey: "storm_isSelected")
      UserDefaults.standard.set(0.6, forKey: "storm_volume")

      UserDefaults.standard.set(true, forKey: "wind_isSelected")
      UserDefaults.standard.set(0.9, forKey: "wind_volume")

      UserDefaults.standard.set(true, forKey: "waves_isSelected")
      UserDefaults.standard.set(0.4, forKey: "waves_volume")

      UserDefaults.standard.set(true, forKey: "boat_isSelected")
      UserDefaults.standard.set(0.7, forKey: "boat_volume")
    } else {
      // Normal reset - clear everything
      for soundName in soundNames {
        UserDefaults.standard.removeObject(forKey: "\(soundName)_volume")
        UserDefaults.standard.removeObject(forKey: "\(soundName)_isSelected")
      }
    }

    UserDefaults.standard.synchronize()

    // Verify the window frame was set
    if let savedFrame = UserDefaults.standard.dictionary(forKey: "LastWindowFrame") {
      print("🧹 UITestingHelper: Window frame set to: \(savedFrame)")
    }

    print("🧹 UITestingHelper: UserDefaults reset complete")
  }
}
