//
//  BlankieToolbar.swift
//  Blankie
//
//  Created by Cody Bromley on 1/11/25.
//

import SwiftUI

struct BlankieToolbar: ToolbarContent {
  @Binding var showingAbout: Bool
  @Binding var showingShortcuts: Bool
  @StateObject private var audioManager = AudioManager.shared

  var body: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      if !PresetManager.shared.presets.isEmpty {
        PresetPicker()
      }
    }

    // Right side - Menu
    ToolbarItem(placement: .primaryAction) {
      Menu {
        SettingsLink {
          Text("Preferences...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Keyboard Shortcuts") {
          showingShortcuts.toggle()
        }
        .keyboardShortcut("?", modifiers: [.command, .shift])

        Button("About Blankie") {
          showingAbout = true
        }

        Divider()

        Button("Quit Blankie") {
          audioManager.pauseAll()
          exit(0)
        }
        .keyboardShortcut("q", modifiers: .command)
      } label: {
        Image(systemName: "line.3.horizontal")
      }
      .menuIndicator(.hidden)
      .menuStyle(.borderlessButton)
    }
  }
}
