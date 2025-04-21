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
        Button(NSLocalizedString("Add Sound (Coming Soon!)", comment: "Add sound menu item")) {
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
            Text(
              NSLocalizedString("Hide Inactive Sounds", comment: "Hide inactive sounds menu item"))
            if appState.hideInactiveSounds {
              Spacer()
              Image(systemName: "checkmark")
            }
          }
        }
        .keyboardShortcut("h", modifiers: [.control, .command])

        Divider()

        Button(NSLocalizedString("About Blankie", comment: "About menu item")) {
          showingAbout = true
          appState.isAboutViewPresented = true
        }

        Button(NSLocalizedString("Keyboard Shortcuts", comment: "Keyboard shortcuts menu item")) {
          showingShortcuts = true
        }
        .keyboardShortcut("?", modifiers: [.command, .shift])

        SettingsLink {
          Text(NSLocalizedString("Preferences...", comment: "Preferences menu item"))
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(NSLocalizedString("Quit Blankie", comment: "Quit menu item")) {
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
