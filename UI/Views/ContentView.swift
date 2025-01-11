//
//  ContentView.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftUI

struct ContentView: View {
  @Binding var showingAbout: Bool
  @ObservedObject private var appState = AppState.shared
  @ObservedObject var audioManager = AudioManager.shared
  @ObservedObject var globalSettings = GlobalSettings.shared
  @StateObject private var presetManager = PresetManager.shared

  @State private var showingVolumePopover = false
  @State private var showingColorPicker = false
  @State private var showingShortcuts = false
  @State private var showingPreferences = false
  @State private var presetName = ""
  @State private var showingNewPresetPopover = false

  // Use appState.hideInactiveSounds instead of the binding
  private var filteredSounds: [Sound] {
    audioManager.sounds.filter { sound in
      !appState.hideInactiveSounds || sound.isSelected
    }
  }

  var textColor: Color {
    audioManager.isGloballyPlaying ? .primary : .secondary
  }

  // Define constant sizes
  private let itemWidth: CGFloat = 120  // Total width including padding
  private let minimumSpacing: CGFloat = 10

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        if !audioManager.isGloballyPlaying {
          HStack {
            Image(systemName: "pause.circle.fill")
            Text("Playback Paused")
              .font(.system(.subheadline, design: .rounded))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .background(.ultraThinMaterial)
          .foregroundStyle(.secondary)
        }
        // Main content
        ScrollView(.vertical, showsIndicators: true) {
          LazyVGrid(
            columns: calculateColumns(for: geometry.size.width),
            spacing: minimumSpacing
          ) {
            ForEach(
              audioManager.sounds.filter { sound in
                !appState.hideInactiveSounds || sound.isSelected
              }
            ) { sound in
              SoundIcon(sound: sound, maxWidth: itemWidth)
            }
          }
          .padding()
        }
        .frame(maxHeight: .infinity)

        // App bar
        VStack(spacing: 0) {
          Rectangle()
            .frame(height: 1)
            .foregroundColor(Color.gray.opacity(0.2))

          HStack(spacing: 16) {
            // Volume button with popover
            Button(action: {
              showingVolumePopover.toggle()
            }) {
              Image(systemName: "speaker.wave.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.primary)
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $showingVolumePopover, arrowEdge: .top) {
              VolumePopoverView()
            }

            // Play/Pause button
            Button(action: {
              audioManager.togglePlayback()
            }) {
              ZStack {
                Circle()
                  .fill(
                    globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2)
                  )
                  .frame(width: 50, height: 50)

                Image(systemName: audioManager.isGloballyPlaying ? "pause.fill" : "play.fill")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 20, height: 20)
                  .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                  .offset(x: audioManager.isGloballyPlaying ? 0 : 2)
              }
            }
            .buttonStyle(.borderless)

            Menu {
              Button {
                withAnimation {
                  appState.hideInactiveSounds.toggle()
                  UserDefaults.standard.set(
                    appState.hideInactiveSounds, forKey: "hideInactiveSounds")
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

              Button("Save as New Preset...") {
                presetName = ""  // Reset preset name
                showingNewPresetPopover.toggle()
              }

              Button("Add Sound (Coming Soon!)") {
                // Implement add sound functionality
              }
              .keyboardShortcut("o", modifiers: .command)
              .disabled(true)

            } label: {
              Text("⋮")  // vertical ellipsis
                .font(.system(size: 20))
                .foregroundColor(.primary)
            }
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)

            // Color picker menu -- Removed in favor of Preference Pane
            // Button(action: {
            //   showingColorPicker.toggle()
            // }) {
            //   Image(systemName: "paintpalette.fill")
            //     .resizable()
            //     .aspectRatio(contentMode: .fit)
            //     .frame(width: 20, height: 20)
            //     .foregroundColor(.primary)
            // }
            // .buttonStyle(.borderless)
            // .popover(isPresented: $showingColorPicker) {
            //   ColorPickerView()
            //     .padding()
            // }
          }
          .padding(.vertical, 12)
          .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
        .background(.ultraThinMaterial)
      }
    }

    .ignoresSafeArea(.container, edges: .horizontal)
    .animation(.easeInOut(duration: 0.2), value: audioManager.isGloballyPlaying)
    .sheet(isPresented: $showingShortcuts) {
      ShortcutsView()
        .background(.ultraThinMaterial)
        .presentationBackground(.ultraThinMaterial)
    }
    .sheet(isPresented: $appState.isAboutViewPresented) {
      AboutView()
    }
    .onAppear {
      setupResetHandler()
      if !audioManager.isGloballyPlaying {
        NSApp.dockTile.badgeLabel = "⏸"
      } else {
        NSApp.dockTile.badgeLabel = nil
      }
    }
    .onChange(of: audioManager.isGloballyPlaying) {
      if !audioManager.isGloballyPlaying {
        NSApp.dockTile.badgeLabel = "⏸"
      } else {
        NSApp.dockTile.badgeLabel = nil
      }
    }
    .modifier(AudioErrorHandler())
  }

  private func calculateColumns(for availableWidth: CGFloat) -> [GridItem] {
    let numberOfColumns = max(2, Int(availableWidth / (itemWidth + minimumSpacing)))
    return Array(
      repeating: GridItem(.fixed(itemWidth), spacing: minimumSpacing), count: numberOfColumns)
  }

  private func setupResetHandler() {
    audioManager.onReset = { @MainActor in
      showingVolumePopover = false
    }
  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentView(showingAbout: .constant(false))
        .frame(width: 600, height: 400)
    }
    .previewDisplayName("Blankie")
  }
}
