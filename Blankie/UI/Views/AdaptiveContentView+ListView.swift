//
//  AdaptiveContentView+ListView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/3/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // List view for small devices
    var soundListView: some View {
      return List {
        ForEach(filteredSounds) { sound in
          soundRow(for: sound)
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
              // Metadata Section - Single text line with bold title and metadata
              Text(
                isCustomSound(sound)
                  ? "\(sound.title) (Custom • Added By You)"
                  : "\(sound.title) (Built-in\(getSoundAuthor(for: sound).map { " • By \($0)" } ?? ""))"
              )
              .font(.title2)
              .fontWeight(.bold)

              Divider()

              // Actions Section
              // Solo Mode
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
                  Label("Solo Mode", systemImage: "headphones")
                }
              }

              // Edit
              Button(action: {
                soundToEdit = sound
              }) {
                Label("Edit Sound", systemImage: "pencil")
              }

              // Hide
              Button(action: {
                sound.isHidden.toggle()
                if sound.isHidden && sound.isSelected {
                  sound.pause()
                }
                audioManager.updateHasSelectedSounds()
                soundsUpdateTrigger += 1
              }) {
                Label(
                  sound.isHidden ? "Show Sound" : "Hide Sound",
                  systemImage: sound.isHidden ? "eye" : "eye.slash")
              }

              Divider()

              // Reorder Section
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
                  editMode == .active ? "Done Reordering" : "Reorder Sounds",
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
      HStack(spacing: 16) {
        soundRowIcon(for: sound)
        soundRowControls(for: sound)
      }
    }

    @ViewBuilder
    private func soundRowIcon(for sound: Sound) -> some View {
      ZStack {
        Circle()
          .fill(
            sound.isSelected
              ? (sound.customColor ?? (globalSettings.customAccentColor ?? .accentColor))
                .opacity(0.2) : .clear
          )
          .frame(width: 50, height: 50)

        Image(systemName: sound.systemIconName)
          .font(.system(size: 24))
          .foregroundColor(
            sound.isSelected
              ? (sound.customColor ?? (globalSettings.customAccentColor ?? .accentColor))
              : .gray)
      }
      .onTapGesture {
        sound.toggle()
      }
    }

    @ViewBuilder
    private func soundRowControls(for sound: Sound) -> some View {
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
#endif
