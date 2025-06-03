//
//  AdaptiveContentView+Menus.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Menu button for small devices
    var menuButton: some View {
      Menu {
        Button(action: {
          showingPresetPicker = true
        }) {
          Label("Presets", systemImage: "music.note.list")
        }

        Button(action: {
          withAnimation {
            hideInactiveSounds.toggle()
          }
        }) {
          let labelText = hideInactiveSounds ? "Show All Sounds" : "Hide Inactive Sounds"
          let iconName = hideInactiveSounds ? "eye" : "eye.slash"
          Label(labelText, systemImage: iconName)
        }

        Button(action: {
          showingSettings = true
        }) {
          Label {
            Text("Settings", comment: "Settings menu item")
          } icon: {
            Image(systemName: "gear")
          }
        }

        Button(action: {
          showingAbout = true
        }) {
          Label {
            Text("About Blankie", comment: "About menu item")
          } icon: {
            Image(systemName: "info.circle")
          }
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
    }

    // Menu button for bottom toolbar
    var playbackMenuButton: some View {
      Menu {
        // Exit Solo Mode option (only shown when in solo mode)
        if audioManager.soloModeSound != nil {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }) {
            Label("Exit Solo Mode", systemImage: "headphones.slash")
          }
        }

        Button(action: {
          withAnimation {
            hideInactiveSounds.toggle()
          }
        }) {
          let labelText = hideInactiveSounds ? "Show All Sounds" : "Hide Inactive Sounds"
          let iconName = hideInactiveSounds ? "eye" : "eye.slash"
          Label(labelText, systemImage: iconName)
        }
        .disabled(
          audioManager.soloModeSound == nil
            && !hideInactiveSounds
            && audioManager.sounds.allSatisfy { $0.isSelected || $0.isHidden }
        )

        Button(action: {
          showingSoundManagement = true
        }) {
          Label("Manage Sounds", systemImage: "waveform")
        }

        Button(action: {
          showingThemePicker = true
        }) {
          Label("Theme", systemImage: "paintbrush")
        }

        Button(action: {
          showingSettings = true
        }) {
          Label("Settings", systemImage: "gear")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 22))
          .foregroundColor(.primary)
      }
      .sheet(isPresented: $showingThemePicker) {
        ThemePickerSheet(isPresented: $showingThemePicker)
      }
      .sheet(isPresented: $showingSoundManagement) {
        SoundManagementView()
      }
    }
  }
#endif
