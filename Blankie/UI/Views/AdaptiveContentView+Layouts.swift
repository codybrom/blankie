//
//  AdaptiveContentView+Layouts.swift
//  Blankie
//
//  Created by Cody Bromley on 6/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // MARK: - Solo Mode View

    @ViewBuilder
    func soloModeView(for soloSound: Sound) -> some View {
      VStack {
        Spacer()
        DraggableSoundIcon(
          sound: soloSound,
          maxWidth: 280,
          index: 0,
          draggedIndex: .constant(nil),
          hoveredIndex: .constant(nil),
          onDragStart: {},
          onDrop: { _ in },
          onEditSound: { sound in
            soundToEdit = sound
          },
          isSoloMode: true
        )
        .scaleEffect(1.0)
        .transition(
          .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
          )
        )
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    }

    // MARK: - Grid View

    @ViewBuilder
    var gridView: some View {
      ScrollView {
        LazyVGrid(
          columns: columns,
          spacing: globalSettings.iconSize == .small
            ? 2 : (globalSettings.iconSize == .medium ? 8 : 12)
        ) {
          ForEach(Array(filteredSounds.enumerated()), id: \.element.id) { index, sound in
            DraggableSoundIcon(
              sound: sound,
              maxWidth: columnWidth,
              index: index,
              draggedIndex: $draggedIndex,
              hoveredIndex: $hoveredIndex,
              onDragStart: {
                draggedIndex = index
                startDragResetTimer()
              },
              onDrop: { sourceIndex in
                audioManager.moveVisibleSound(from: sourceIndex, to: index)
                cancelDragResetTimer()
              },
              onEditSound: { sound in
                soundToEdit = sound
              },
              onEnterEditMode: enterEditMode,
              editMode: editMode
            )
          }
        }
        .padding()
        .animation(.easeInOut, value: filteredSounds.count)
      }
    }

    // MARK: - List View

    @ViewBuilder
    var listView: some View {
      List {
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
              contextMenuContent(for: sound)
            }
        }
        .onMove(perform: editMode == .active ? moveItems : nil)
        .deleteDisabled(true)
      }
      .listStyle(.plain)
      .environment(\.editMode, $editMode)
      .padding(.top, 8)
      .id("\(globalSettings.showSoundNames)-\(globalSettings.hideInactiveSoundSliders)")
    }

    // MARK: - Empty State View

    @ViewBuilder
    var emptyStateView: some View {
      VStack(spacing: 20) {
        Spacer()

        VStack(spacing: 12) {
          Image(
            systemName: audioManager.getVisibleSounds().isEmpty
              ? "eye.slash.circle" : "speaker.slash.circle"
          )
          .font(.system(size: 48))
          .foregroundStyle(.secondary)

          Text(
            audioManager.getVisibleSounds().isEmpty
              ? "No Visible Sounds" : "No Active Sounds"
          )
          .font(.headline)
          .foregroundColor(.primary)
        }

        if audioManager.getVisibleSounds().isEmpty {
          Button(action: {
            showingSoundManagement = true
          }) {
            Text("Manage Sounds")
              .font(.system(.subheadline, weight: .medium))
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 10)
              .background(globalSettings.customAccentColor ?? .accentColor)
              .cornerRadius(8)
          }
          .buttonStyle(.plain)
        } else {
          Button(action: {
            withAnimation {
              hideInactiveSounds = false
            }
          }) {
            Text("Show Inactive Sounds")
              .font(.system(.subheadline, weight: .medium))
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 10)
              .background(globalSettings.customAccentColor ?? .accentColor)
              .cornerRadius(8)
          }
          .buttonStyle(.plain)
        }

        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func moveItems(from source: IndexSet, to destination: Int) {
      audioManager.moveVisibleSounds(from: source, to: destination)
    }

    @ViewBuilder
    private func soundRow(for sound: Sound) -> some View {
      SoundRowView(sound: sound, globalSettings: globalSettings, audioManager: audioManager)
    }

    @ViewBuilder
    private func contextMenuContent(for sound: Sound) -> some View {
      Text(
        isCustomSound(sound)
          ? "\(sound.title) (Custom • Added By You)"
          : "\(sound.title) (Built-in\(getSoundAuthor(for: sound).map { " • By \($0)" } ?? ""))"
      )
      .font(.title2)
      .fontWeight(.bold)

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

      Button(action: {
        soundToEdit = sound
      }) {
        Label("Customize", systemImage: "paintbrush")
      }

      Divider()

      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          editMode = editMode == .active ? .inactive : .active
        }
      }) {
        Label(
          editMode == .active ? "Done Reordering" : "Reorder",
          systemImage: editMode == .active ? "checkmark" : "arrow.up.arrow.down"
        )
      }
    }

    private func getSoundAuthor(for sound: Sound) -> String? {
      if isCustomSound(sound) {
        return "You"
      }

      let credits = SoundCreditsManager.shared.credits
      return credits.first { $0.soundName == sound.fileName || $0.name == sound.title }?.author
    }

    private func isCustomSound(_ sound: Sound) -> Bool {
      let credits = SoundCreditsManager.shared.credits
      let isInCredits = credits.contains {
        $0.soundName == sound.fileName || $0.name == sound.title
      }
      return !isInCredits
    }
  }
#endif
