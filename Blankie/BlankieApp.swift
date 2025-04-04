//
//  BlankieApp.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftData
import SwiftUI

@main
struct BlankieApp: App {
  @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var windowObserver = WindowObserver.shared
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
        presetName: $presetName
      )
    }
    .defaultPosition(.center)
    .windowResizability(.contentSize)
    .windowStyle(.automatic)
    .defaultSize(width: WindowDefaults.defaultWidth, height: WindowDefaults.defaultHeight)
    .windowToolbarStyle(.unified)
    .commandsReplaced {
      AppCommands(showingAbout: $showingAbout, hasWindow: $windowObserver.hasVisibleWindow)
    }

    //
    //
    // MenuBarExtra("Blankie", systemImage: "waveform") {
    //   Button("Show Main Window") {
    //     NSApp.activate(ignoringOtherApps: true)
    //   }
    //
    //   Divider()
    //
    //   Button("About Blankie") {
    //     NSApp.activate(ignoringOtherApps: true)
    //     showingAbout = true
    //   }
    //
    //   Divider()
    //
    //   Button("Quit Blankie") {
    //     NSApplication.shared.terminate(nil)
    //   }
    // }

    Settings {
      PreferencesView()
    }
  }
}

#if DEBUG
  struct BlankieApp_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        ForEach(["Light Mode", "Dark Mode"], id: \.self) { scheme in
          WindowDefaults.defaultContentView(
            showingAbout: .constant(false),
            showingShortcuts: .constant(false),
            showingNewPresetPopover: .constant(false),
            presetName: .constant("")
          )
          .frame(width: 450, height: 450)
          .preferredColorScheme(scheme == "Dark Mode" ? .dark : .light)
          .previewDisplayName(scheme)
        }
      }
      .previewLayout(.sizeThatFits)
    }
  }
#endif
