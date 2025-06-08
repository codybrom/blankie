//
//  AppDelegate.swift
//  Blankie
//
//  Created by Cody Bromley on 4/3/25.
//

#if os(macOS)
  import SwiftUI

  final class MacAppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
      configureWindowAppearance()
      setupNotificationObservers()
      applySavedLanguagePreference()
      clearRestartFlagIfNeeded()
      applyUITestingConfigurationIfNeeded()
    }

    private func configureWindowAppearance() {
      DispatchQueue.main.async {
        if let window = NSApplication.shared.windows.first {
          window.isOpaque = false
          window.backgroundColor = NSColor.clear
          window.hasShadow = true
          window.titlebarAppearsTransparent = false
        }
      }
    }

    private func setupNotificationObservers() {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(languageDidChange),
        name: Notification.Name("LanguageDidChange"),
        object: nil
      )

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(localeDidChange),
        name: NSLocale.currentLocaleDidChangeNotification,
        object: nil
      )
    }

    private func applySavedLanguagePreference() {
      if let languageCode = UserDefaults.standard.string(forKey: "languagePreference"),
        languageCode != "system"
      {
        print("🌐 AppDelegate: Applying saved language \(languageCode) at launch")
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
      }
    }

    private func clearRestartFlagIfNeeded() {
      if UserDefaults.standard.bool(forKey: "AppIsRestarting") {
        print("🔄 App detected post-restart state for language change")
        UserDefaults.standard.removeObject(forKey: "AppIsRestarting")
      }
    }

    private func applyUITestingConfigurationIfNeeded() {
      guard ProcessInfo.processInfo.arguments.contains("-UITestingResetDefaults") else { return }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let window = NSApplication.shared.windows.first {
          let frame = NSRect(x: 485, y: 277, width: 950, height: 540)
          window.setFrame(frame, display: true, animate: false)
          print("🪟 AppDelegate: Set window frame for UI testing to \(frame)")
        }

        // Force playback to start for screenshots
        if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
          self.configureScreenshotMode()
        }
      }
    }

    private func configureScreenshotMode() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        let audioManager = AudioManager.shared

        // Configure specific sounds for screenshots
        let soundsToActivate = [
          ("rain", 0.8),
          ("storm", 0.6),
          ("wind", 0.9),
          ("waves", 0.4),
          ("boat", 0.7),
        ]

        audioManager.sounds.forEach { $0.isSelected = false }

        for (fileName, volume) in soundsToActivate {
          if let sound = audioManager.sounds.first(where: { $0.fileName == fileName }) {
            sound.isSelected = true
            sound.volume = Float(volume)
            print("🔊 Activated \(fileName) with volume \(volume)")
          }
        }

        audioManager.setPlaybackState(true, forceUpdate: true)
        print("🎵 AppDelegate: Started playback for screenshot mode")
      }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
      return false  // Prevent app from quitting when last window closes
    }

    func applicationWillTerminate(_ notification: Notification) {
      // Save state
      AudioManager.shared.saveState()
      Task { @MainActor in
        PresetManager.shared.savePresets()
      }
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
#elseif os(iOS) || os(visionOS)
  import SwiftUI
  import UIKit

  final class IOSAppDelegate: NSObject, UIApplicationDelegate {
    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      // Setup background modes, notifications, etc.
      return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
      // Save state
      AudioManager.shared.saveState()
      Task { @MainActor in
        PresetManager.shared.savePresets()
      }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
      // Save state when entering background
      AudioManager.shared.saveState()
      Task { @MainActor in
        PresetManager.shared.savePresets()
      }
    }

    func application(
      _ application: UIApplication,
      supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
      #if os(iOS)
        if GlobalSettings.shared.lockPortraitOrientationiOS {
          return .portrait
        } else {
          return .all
        }
      #else
        return .all
      #endif
    }

  }
#endif
