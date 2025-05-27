//
//  BlankieToolbar.swift
//  Blankie
//
//  Created by Cody Bromley on 1/11/25.
//

import SwiftUI

#if os(macOS)
  struct BlankieToolbar: ToolbarContent {
    @Binding var showingAbout: Bool
    @Binding var showingShortcuts: Bool
    @Binding var showingNewPresetPopover: Bool
    @Binding var presetName: String
    @State private var showingImportSoundSheet = false
    @State private var showingCustomSoundsView = false

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
          Button {
            showingCustomSoundsView = true
          } label: {
            Text("Manage Custom Sounds", comment: "Menu item to manage custom sounds")
          }
          .keyboardShortcut("o", modifiers: .command)

          Button {
            withAnimation {
              appState.hideInactiveSounds.toggle()
              UserDefaults.standard.set(appState.hideInactiveSounds, forKey: "hideInactiveSounds")
            }
          } label: {
            HStack {
              Text("Hide Inactive Sounds", comment: "Toggle to hide sounds that are not active")
              if appState.hideInactiveSounds {
                Spacer()
                Image(systemName: "checkmark")
              }
            }
          }
          .keyboardShortcut("h", modifiers: [.control, .command])

          Divider()

          Button {
            showingAbout = true
            appState.isAboutViewPresented = true
          } label: {
            Text("About Blankie", comment: "Menu item to show about window")
          }

          Button {
            showingShortcuts = true
          } label: {
            Text("Keyboard Shortcuts", comment: "Menu item to show keyboard shortcuts")
          }
          .keyboardShortcut("?", modifiers: [.command, .shift])

          SettingsLink {
            Text("Preferences...", comment: "Preferences menu item")
          }
          .keyboardShortcut(",", modifiers: .command)

          Divider()

          Button {
            audioManager.pauseAll()
            exit(0)
          } label: {
            Text("Quit Blankie", comment: "Menu item to quit the application")
          }
          .keyboardShortcut("q", modifiers: .command)
        } label: {
          Image(systemName: "line.3.horizontal")
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .sheet(isPresented: $showingImportSoundSheet) {
          ImportSoundSheet()
        }
        .sheet(isPresented: $showingCustomSoundsView) {
          CustomSoundsView()
            .frame(width: 450, height: 500)
        }
      }
    }
  }
#endif

// Add an iOS-compatible version that does nothing
#if os(iOS) || os(visionOS)
  struct BlankieToolbar: ToolbarContent {
    @Binding var showingAbout: Bool
    @Binding var showingShortcuts: Bool
    @Binding var showingNewPresetPopover: Bool
    @Binding var presetName: String

    var body: some ToolbarContent {
      // For iOS, we need to provide at least one item
      ToolbarItem(placement: .navigationBarTrailing) {
        EmptyView()
      }
    }
  }
#endif
