//
//  AppCommands.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct AppCommands: Commands {
  @Binding var showingAbout: Bool
  @Binding var hasWindow: Bool
  @ObservedObject private var appState = AppState.shared

  var body: some Commands {
    CommandGroup(replacing: .appInfo) {
      Button("About Blankie") {
        showingAbout = true
      }
    }

    CommandGroup(replacing: .newItem) {
      Button("New Window") {
        if !hasWindow {
          let controller = NSWindowController(
            window: NSWindow(
              contentRect: WindowDefaults.defaultFrame,
              styleMask: WindowDefaults.styleMask,
              backing: .buffered,
              defer: false
            )
          )

          if let window = controller.window {
            WindowDefaults.configureWindow(window)

            let contentView = WindowDefaults.defaultContentView(
              showingAbout: $showingAbout,
              showingShortcuts: .constant(false),
              showingNewPresetPopover: .constant(false),
              presetName: .constant("")
            )

            let hostingView = NSHostingView(rootView: contentView)
            window.contentView = hostingView
            controller.showWindow(nil)
            hasWindow = true
          }
        }
      }
      .disabled(hasWindow)
      .keyboardShortcut("n", modifiers: .command)
    }

    CommandGroup(after: .toolbar) {
      Button(appState.hideInactiveSounds ? "Show All Sounds" : "Hide Inactive Sounds") {
        withAnimation {
          appState.hideInactiveSounds.toggle()
          UserDefaults.standard.set(appState.hideInactiveSounds, forKey: "hideInactiveSounds")
        }
      }
      .keyboardShortcut("h", modifiers: [.control, .command])
    }

    // Add Help menu command
    CommandGroup(replacing: .help) {
      Button("Blankie Help") {
        if let url = URL(string: "https://blankie.rest/faq") {
          NSWorkspace.shared.open(url)
        }
      }
    }
  }
}
