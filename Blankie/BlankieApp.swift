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
  @StateObject private var audioFileImporter = AudioFileImporter.shared

  // Initialize SwiftData
  init() {
    // Reset defaults if running UI tests
    UITestingHelper.resetAllDefaults()

    do {
      modelContainer = try ModelContainer(for: CustomSoundData.self)
      print("🗄️ BlankieApp: Successfully created SwiftData model container")
    } catch {
      fatalError("❌ BlankieApp: Failed to create SwiftData model container: \(error)")
    }
  }

  #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate

    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var windowObserver = WindowObserver.shared
    @StateObject private var globalSettings = GlobalSettings.shared
    @State private var showingAbout = false
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
        .onAppear {
          // Pass model context to AudioManager for custom sounds
          AudioManager.shared.setModelContext(modelContainer.mainContext)
        }
        .accentColor(globalSettings.customAccentColor ?? .accentColor)
        .onOpenURL { url in
          audioFileImporter.handleIncomingFile(url)
        }
        .sheet(isPresented: $audioFileImporter.showingSoundSheet) {
          SoundSheet(mode: .add, preselectedFile: audioFileImporter.fileToImport)
            .onDisappear {
              audioFileImporter.clearImport()
            }
        }
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

    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var presetManager = PresetManager.shared
    @StateObject private var globalSettings = GlobalSettings.shared
    @StateObject private var timerManager = TimerManager.shared

    @State private var showingAbout = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
      WindowGroup {
        UniversalContentView(
          showingAbout: $showingAbout
        )
        .preferredColorScheme(
          globalSettings.appearance == .system
            ? nil : (globalSettings.appearance == .dark ? .dark : .light)
        )
        .accentColor(globalSettings.customAccentColor ?? .accentColor)
        .onAppear {
          // Pass model context to AudioManager for custom sounds
          AudioManager.shared.setModelContext(modelContainer.mainContext)
        }
        .onChange(of: scenePhase) {
          timerManager.handleScenePhaseChange()
        }
        .onOpenURL { url in
          audioFileImporter.handleIncomingFile(url)
        }
        .sheet(isPresented: $audioFileImporter.showingSoundSheet) {
          SoundSheet(mode: .add, preselectedFile: audioFileImporter.fileToImport)
            .onDisappear {
              audioFileImporter.clearImport()
            }
        }
      }
      .modelContainer(modelContainer)

      #if os(visionOS)
        // VisionOS specific immersive space
        ImmersiveSpace(id: "blankieSpace") {
          // VisionOSImmersiveView will need to be implemented
          // or commented out until visionOS support is ready
          Text("Immersive Audio Experience")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      #endif
    }
  #endif
}

// Universal wrapper view that adapts to each platform
struct UniversalContentView: View {
  @Binding var showingAbout: Bool

  var body: some View {
    #if os(macOS)
      ContentView(
        showingAbout: $showingAbout,
        showingShortcuts: .constant(false),
        showingNewPresetPopover: .constant(false),
        presetName: .constant("")
      )
    #elseif os(visionOS)
      // For visionOS, use iOS view until specific implementation is ready
      AdaptiveContentView(
        showingAbout: $showingAbout
      )
    #else
      AdaptiveContentView(
        showingAbout: $showingAbout
      )
    #endif
  }
}

#if DEBUG
  struct BlankieApp_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        ForEach(["Light Mode", "Dark Mode"], id: \.self) { scheme in
          #if os(macOS)
            WindowDefaults.defaultContentView(
              showingAbout: .constant(false),
              showingShortcuts: .constant(false),
              showingNewPresetPopover: .constant(false),
              presetName: .constant(""),
              showingSettings: .constant(false)
            )
            .frame(width: 450, height: 450)
            .preferredColorScheme(scheme == "Dark Mode" ? .dark : .light)
            .previewDisplayName(scheme)
          #else
            UniversalContentView(
              showingAbout: .constant(false)
            )
            .preferredColorScheme(scheme == "Dark Mode" ? .dark : .light)
            .previewDisplayName(scheme)
          #endif
        }
      }
      .previewLayout(.sizeThatFits)
    }
  }
#endif
