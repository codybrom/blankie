//
//  AppDelegate.swift
//  Blankie
//
//  Created by Cody Bromley on 4/3/25.
//

#if os(macOS)
  import SwiftUI

  final class MacAppDelegate: NSObject, NSApplicationDelegate {

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
  }
#endif
