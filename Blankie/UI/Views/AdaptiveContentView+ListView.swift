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
      List {
        ForEach(filteredSounds) { sound in
          HStack(spacing: 16) {
            // Sound icon
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

            // Sound info and controls
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                if globalSettings.showSoundNames {
                  Text(LocalizedStringKey(sound.title))
                    .font(
                      .callout.weight(
                        Locale.current.scriptCategory == .standard ? .regular : .thin)
                    )
                    .foregroundColor(.primary)
                }

                Spacer()

                Text("\(Int(sound.volume * 100))%")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .monospacedDigit()
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
            }
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
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
          }
        }
      }
      .listStyle(.plain)
      .transition(.opacity)
    }
  }
#endif
