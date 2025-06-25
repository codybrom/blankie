//
//  BlankieApp.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import AVFAudio
import SwiftData
import SwiftUI

@main
struct BlankieApp: App {
  let modelContainer: ModelContainer
  private let appSetup: AppSetup

  // Shared state objects
  @StateObject private var globalSettings = GlobalSettings.shared
  @State private var showingAbout = false

  // Initialize SwiftData
  init() {
    // Reset defaults if running UI tests
    UITestingHelper.resetAllDefaults()

    modelContainer = AppSetup.createModelContainer()
    appSetup = AppSetup(modelContainer: modelContainer)
  }

  #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    @StateObject private var windowObserver = WindowObserver.shared
    @State private var showingShortcuts = false
    @State private var showingNewPresetPopover = false
    @State private var presetName = ""

    var body: some Scene {
      Window("Blankie", id: "main") {
        WindowDefaults.defaultContentView(
          showingAbout: $showingAbout,
          showingShortcuts: $showingShortcuts,
          showingNewPresetPopover: $showingNewPresetPopover,
          presetName: $presetName,
          showingSettings: .constant(false)
        )
        .sharedAppModifiers(appSetup: appSetup, globalSettings: globalSettings)
      }
      .modelContainer(modelContainer)
      .defaultPosition(.center)
      .windowResizability(.contentSize)
      .windowStyle(.automatic)
      .defaultSize(width: WindowDefaults.defaultWidth, height: WindowDefaults.defaultHeight)
      .windowToolbarStyle(.unified)
      .commandsReplaced {
        AppCommands(showingAbout: $showingAbout, hasWindow: $windowObserver.hasVisibleWindow)
      }

      Settings {
        PreferencesView()
      }
    }

  #elseif os(iOS) || os(visionOS)
    @UIApplicationDelegateAdaptor(IOSAppDelegate.self) private var appDelegate
    @StateObject private var presetManager = PresetManager.shared
    @StateObject private var timerManager = TimerManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
      WindowGroup {
        AdaptiveContentView(
          showingAbout: $showingAbout
        )
        .sharedAppModifiers(appSetup: appSetup, globalSettings: globalSettings)
        .preferredColorScheme(
          globalSettings.appearance == .system
            ? nil : (globalSettings.appearance == .dark ? .dark : .light)
        )
        .onChange(of: scenePhase) { _, _ in
          timerManager.handleScenePhaseChange()
        }
      }
      .modelContainer(modelContainer)
    }
  #endif
}

#if DEBUG
  struct BlankieApp_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        ForEach(["Light Mode", "Dark Mode"], id: \.self) { scheme in
          Group {
            #if os(macOS)
              WindowDefaults.defaultContentView(
                showingAbout: .constant(false),
                showingShortcuts: .constant(false),
                showingNewPresetPopover: .constant(false),
                presetName: .constant(""),
                showingSettings: .constant(false)
              )
              .frame(width: 450, height: 450)
            #else
              AdaptiveContentView(showingAbout: .constant(false))
            #endif
          }
          .preferredColorScheme(scheme == "Dark Mode" ? .dark : .light)
          .previewDisplayName(scheme)
        }
      }
    }
  }
#endif
