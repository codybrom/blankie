//
//  AdaptiveContentView+UIComponents.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  // MARK: - UI Components Extension
  extension AdaptiveContentView {
    // MARK: - Status Banners

    @ViewBuilder
    var statusBanners: some View {
      if audioManager.soloModeSound != nil && editMode == .inactive {
        // Solo mode banner
        HStack(spacing: 12) {
          Image(systemName: "headphones.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          Text("Solo Mode")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          Button("Exit") {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }
          .font(.system(.subheadline, weight: .medium))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else if editMode == .active && !isLargeDevice {
        // Reorder mode banner
        HStack(spacing: 12) {
          Image(systemName: "arrow.up.arrow.down.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          Text("Drag to Reorder")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          Button("Done") {
            withAnimation(.easeInOut(duration: 0.3)) {
              editMode = .inactive
            }
          }
          .font(.system(.subheadline, weight: .medium))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else if !audioManager.hasSelectedSounds && editMode == .inactive {
        // No sounds selected banner
        HStack(spacing: 12) {
          Image(systemName: "speaker.slash.fill")
            .font(.system(size: 16))
          Text("No Sounds Selected")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          if showingListView && !isLargeDevice {
            Button(action: {
              withAnimation(.easeInOut(duration: 0.3)) {
                editMode = editMode == .active ? .inactive : .active
              }
            }) {
              Text(editMode == .active ? "Done" : "Reorder")
                .font(.system(.subheadline, weight: .medium))
                .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
            }
            .buttonStyle(.plain)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.secondary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }

    // MARK: - Navigation Elements

    var navigationTitle: String {
      if let soloSound = audioManager.soloModeSound {
        return soloSound.title
      }

      if audioManager.isCarPlayQuickMix {
        return "Quick Mix"
      }

      if let preset = presetManager.currentPreset {
        return preset.isDefault ? "Blankie" : preset.name
      }

      return "Blankie"
    }

    var presetButton: some View {
      Button(action: {
        showingPresetPicker = true
      }) {
        HStack(spacing: 4) {
          if audioManager.soloModeSound != nil {
            Image(systemName: "headphones.circle.fill")
              .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          } else if audioManager.isCarPlayQuickMix {
            Image(systemName: "square.grid.2x2.fill")
              .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          }
          Text(navigationTitle)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          Image(systemName: "chevron.down")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }

    // MARK: - Toolbar Components

    var bottomToolbar: some View {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          // Grid/List toggle
          Spacer()
          Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
              showingListView.toggle()
            }
          }) {
            Image(systemName: showingListView ? "list.bullet" : "square.grid.3x3")
              .font(.system(size: 22))
              .foregroundColor(.primary)
              .contentTransition(.symbolEffect(.replace))
          }
          .buttonStyle(.plain)
          Spacer()

          // Play/Pause button
          Spacer()
          playPauseButton
          Spacer()

          // Menu button
          Spacer()
          menuButton
          Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
      }
    }

    var playPauseButton: some View {
      Button(action: {
        if audioManager.hasSelectedSounds {
          audioManager.togglePlayback()
        }
      }) {
        ZStack {
          Circle()
            .fill(
              audioManager.hasSelectedSounds
                ? (globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                : Color.secondary.opacity(0.1)
            )
            .frame(width: 60, height: 60)

          Image(systemName: audioManager.isGloballyPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 26))
            .foregroundColor(
              audioManager.hasSelectedSounds
                ? (globalSettings.customAccentColor ?? .accentColor)
                : .secondary
            )
            .contentTransition(
              .symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating)
            )
            .offset(x: audioManager.isGloballyPlaying ? 0 : 2)
        }
      }
      .buttonStyle(.plain)
      .disabled(!audioManager.hasSelectedSounds)
    }

    var menuButton: some View {
      Menu {
        if audioManager.soloModeSound != nil {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }) {
            Label("Exit Solo Mode", systemImage: "headphones.slash")
          }
        }

        if audioManager.isCarPlayQuickMix {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitCarPlayQuickMix()
            }
          }) {
            Label("Exit Quick Mix", systemImage: "square.grid.2x2.slash")
          }
        } else {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.enterCarPlayQuickMix()
            }
          }) {
            Label("Quick Mix Mode", systemImage: "square.grid.2x2")
          }
        }

        Section {
          Button(action: {
            showingAbout = true
          }) {
            Label("About Blankie", systemImage: "info.circle")
          }
        }

        Button(action: {
          showingViewSettings = true
        }) {
          Label("View Settings", systemImage: "slider.horizontal.3")
        }

        Button(action: {
          showingSoundManagement = true
        }) {
          Label("Sound Settings", systemImage: "waveform")
        }

        Button(action: {
          withAnimation {
            editMode = editMode == .active ? .inactive : .active
          }
        }) {
          Label(
            editMode == .active ? "Done Reordering" : "Reorder Sounds",
            systemImage: editMode == .active ? "checkmark.circle" : "arrow.up.arrow.down"
          )
        }

        Button(action: {
          showingTimer = true
        }) {
          Label("Timer", systemImage: "timer")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 22))
          .foregroundColor(.primary)
      }
    }
  }
#endif
