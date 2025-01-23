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
  @Binding var showingNewPresetPopover: Bool
  @Binding var presetName: String

  @ObservedObject private var appState = AppState.shared
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var presetManager = PresetManager.shared

  var body: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      if !PresetManager.shared.presets.isEmpty {
        PresetPicker()
      }
    }

    ToolbarItem(placement: .primaryAction) {
      Menu {
        Button("Add Sound (Coming Soon!)") {
          // Implement add sound functionality
        }
        .keyboardShortcut("o", modifiers: .command)
        .disabled(true)

        Button {
          withAnimation {
            appState.hideInactiveSounds.toggle()
            UserDefaults.standard.set(appState.hideInactiveSounds, forKey: "hideInactiveSounds")
          }
        } label: {
          HStack {
            Text("Hide Inactive Sounds")
            if appState.hideInactiveSounds {
              Spacer()
              Image(systemName: "checkmark")
            }
          }
        }
        .keyboardShortcut("h", modifiers: [.control, .command])

        Divider()

        Button("About Blankie") {
          showingAbout = true
          appState.isAboutViewPresented = true  // Add this line
        }

        Button("Keyboard Shortcuts") {
          showingShortcuts = true
        }
        .keyboardShortcut("?", modifiers: [.command, .shift])

        SettingsLink {
          Text("Preferences...")
        }
        .keyboardShortcut(",", modifiers: .command)

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
