//
//  AppDelegate.swift
//  Blankie
//
//  Created by Cody Bromley on 4/3/25.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Listen for language change notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(languageDidChange),
      name: Notification.Name("LanguageDidChange"),
      object: nil
    )

    // Listen for locale changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(localeDidChange),
      name: NSLocale.currentLocaleDidChangeNotification,
      object: nil
    )

    // If there's a saved language preference, apply it at launch
    if let languageCode = UserDefaults.standard.string(forKey: "languagePreference"),
      languageCode != "system" {
      print("🌐 AppDelegate: Applying saved language \(languageCode) at launch")
      UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
    }

    // Clear restart flag if we're coming back from a restart
    if UserDefaults.standard.bool(forKey: "AppIsRestarting") {
      print("🔄 App detected post-restart state for language change")
      UserDefaults.standard.removeObject(forKey: "AppIsRestarting")
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Prevent app from quitting when last window closes
  }

  // Handle language change
  @objc private func languageDidChange(_ notification: Notification) {
    print("🌐 AppDelegate: Received language change notification")
    // The language has already been changed in UserDefaults by the Language.applyLanguage method

    // Try to refresh any localized strings throughout the app
    refreshAppLocalization()
  }

  // Handle locale change
  @objc private func localeDidChange(_ notification: Notification) {
    print("🌐 AppDelegate: Locale changed, refreshing localized content")
    refreshAppLocalization()
  }

  private func refreshAppLocalization() {
    // Try to refresh UI elements with new language
    DispatchQueue.main.async {
      // Force redraw of all windows
      for window in NSApplication.shared.windows {
        window.update()
        window.display()

        // Try to refresh view controllers
        if let contentView = window.contentView {
          contentView.needsDisplay = true
          contentView.needsLayout = true
          contentView.layout()
          contentView.display()
        }
      }
    }
  }
}
