//
//  AdaptiveContentView+ListView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/3/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  // Separate view struct to properly observe Sound changes
  struct SoundRowView: View {
    @ObservedObject var sound: Sound
    @ObservedObject var globalSettings: GlobalSettings
    @ObservedObject var audioManager: AudioManager

    var body: some View {
      HStack(spacing: 16) {
        soundRowIcon
        soundRowControls
      }
    }

    private var soundRowIcon: some View {
      ZStack {
        Circle()
          .fill(
            !audioManager.isGloballyPlaying || !sound.isSelected
              ? .clear
              : (sound.customColor ?? (globalSettings.customAccentColor ?? .accentColor))
                .opacity(0.2)
          )
          .frame(width: 50, height: 50)

        Image(systemName: sound.systemIconName)
          .font(.system(size: 24))
          .foregroundColor(
            !audioManager.isGloballyPlaying
              ? .gray
              : (sound.isSelected
                ? (sound.customColor ?? (globalSettings.customAccentColor ?? .accentColor))
                : .gray))
      }
      .onTapGesture {
        // If global playback is paused and this sound is already selected,
        // start global playback instead of deselecting the sound
        if !audioManager.isGloballyPlaying && sound.isSelected {
          audioManager.setGlobalPlaybackState(true)
        } else {
          sound.toggle()
        }
      }
    }

    private var soundRowControls: some View {
      VStack(alignment: .leading, spacing: 4) {
        if !globalSettings.showSoundNames {
          Spacer()
        }
        if globalSettings.showSoundNames {
          HStack {
            Text(LocalizedStringKey(sound.title))
              .font(
                .callout.weight(
                  Locale.current.scriptCategory == .standard ? .regular : .thin)
              )
              .foregroundColor(.primary)

            Spacer()

            Text("\(Int(sound.volume * 100))%")
              .font(.caption)
              .foregroundColor(.secondary)
              .monospacedDigit()
          }
        }

        // Volume slider
        Slider(
          value: Binding(
            get: { Double(sound.volume) },
            set: { sound.volume = Float($0) }
          ),
          in: 0...1
        )
        .tint(
          sound.isSelected
            ? (sound.customColor ?? (globalSettings.customAccentColor ?? .accentColor))
            : .gray
        )
        .disabled(!sound.isSelected)

        if !globalSettings.showSoundNames {
          Spacer()
        }
      }
    }
  }

  extension AdaptiveContentView {
    // List view for small devices
    var soundListView: some View {
      return List {
        ForEach(filteredSounds) { sound in
          soundRow(for: sound)
            .id("\(sound.id)-\(sound.isSelected)-\(audioManager.isGloballyPlaying)")
            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20))
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button {
                soundToEdit = sound
              } label: {
                Label("Edit", systemImage: "pencil")
              }
              .tint(.blue)

              // Solo button - only show if not already in solo mode
              if audioManager.soloModeSound?.id != sound.id {
                Button {
                  if globalSettings.enableHaptics {
                    #if os(iOS)
                      let generator = UIImpactFeedbackGenerator(style: .medium)
                      generator.impactOccurred()
                    #endif
                  }
                  withAnimation(.easeInOut(duration: 0.3)) {
                    audioManager.toggleSoloMode(for: sound)
                  }
                } label: {
                  Label("Solo", systemImage: "headphones")
                }
                .tint(.orange)
              }
            }
            .contextMenu {
              // Title with credits
              Text(
                isCustomSound(sound)
                  ? "\(sound.title) (Custom • Added By You)"
                  : "\(sound.title) (Built-in\(getSoundAuthor(for: sound).map { " • By \($0)" } ?? ""))"
              )
              .font(.title2)
              .fontWeight(.bold)

              // Solo Mode - only show if not already in solo mode
              if audioManager.soloModeSound?.id != sound.id {
                Button(action: {
                  if globalSettings.enableHaptics {
                    #if os(iOS)
                      let generator = UIImpactFeedbackGenerator(style: .medium)
                      generator.impactOccurred()
                    #endif
                  }
                  withAnimation(.easeInOut(duration: 0.3)) {
                    audioManager.toggleSoloMode(for: sound)
                  }
                }) {
                  Label("Solo", systemImage: "headphones")
                }
              }

              // Customize Sound
              Button(action: {
                soundToEdit = sound
              }) {
                Label("Customize", systemImage: "paintbrush")
              }

              Divider()

              // Reorder
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  if editMode == .active {
                    exitEditMode()
                  } else {
                    enterEditMode()
                  }
                }
              }) {
                Label(
                  editMode == .active ? "Done Reordering" : "Reorder",
                  systemImage: editMode == .active ? "checkmark" : "arrow.up.arrow.down")
              }
            }
        }
        .onMove(perform: editMode == .active ? moveItems : nil)
        .deleteDisabled(true)
      }
      .listStyle(.plain)
      .environment(\.editMode, $editMode)
      .transition(.opacity)
      .padding(.top, 8)
      .id("\(globalSettings.showSoundNames)-\(globalSettings.hideInactiveSoundSliders)")
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
      audioManager.moveVisibleSounds(from: source, to: destination)
    }

    private func getSoundAuthor(for sound: Sound) -> String? {
      // Check if it's a custom sound first
      if isCustomSound(sound) {
        return "You"  // Custom sounds are created by the user
      }

      // For built-in sounds, get author from credits
      let credits = SoundCreditsManager.shared.credits
      return credits.first { $0.soundName == sound.fileName || $0.name == sound.title }?.author
    }

    private func isCustomSound(_ sound: Sound) -> Bool {
      // Custom sounds typically have higher defaultOrder values (1000+)
      // or are not found in the built-in credits
      let credits = SoundCreditsManager.shared.credits
      let isInCredits = credits.contains {
        $0.soundName == sound.fileName || $0.name == sound.title
      }
      return !isInCredits
    }

    @ViewBuilder
    private func soundRow(for sound: Sound) -> some View {
      SoundRowView(sound: sound, globalSettings: globalSettings, audioManager: audioManager)
    }

  }
#endif
