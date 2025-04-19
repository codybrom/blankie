//
//  VolumeControlsView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

public enum VolumeControlStyle {
  case popover
  case sheet
}

struct VolumeControlsView: View {
  @ObservedObject private var audioManager = AudioManager.shared
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  let style: VolumeControlStyle

  var accentColor: Color {
    globalSettings.customAccentColor ?? .accentColor
  }

  var body: some View {
    if style == .sheet {
      NavigationView {
        ScrollView {
          sheetContent
            .padding(.bottom, 30)
        }
        .navigationTitle("Volume Controls")
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Done") { dismiss() }
          }
        }
      }
    } else {
      popoverContent
    }
  }

  // Popover-style content view
  private var popoverContent: some View {
    VStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Global Volume")
          .font(.caption)
        Slider(
          value: Binding(
            get: { globalSettings.volume },
            set: { globalSettings.setVolume($0) }
          ),
          in: 0...1
        )
        .frame(width: 200)
        .tint(accentColor)
      }

      if audioManager.sounds.contains(where: \.isSelected) {
        Divider()

        ForEach(audioManager.sounds.filter(\.isSelected)) { sound in
          VStack(alignment: .leading, spacing: 4) {
            Text(sound.title)
              .font(.caption)

            Slider(
              value: Binding(
                get: { Double(sound.volume) },
                set: { sound.volume = Float($0) }
              ), in: 0...1
            )
            .frame(width: 200)
            .tint(accentColor)
          }
        }
      }

      Divider()

      Button("Reset Sounds") {
        audioManager.resetSounds()
      }
      .font(.caption)
    }
    .padding()
  }

  // Sheet-style content view
  private var sheetContent: some View {
    VStack(spacing: 24) {
      // Global volume slider
      VStack(alignment: .leading, spacing: 8) {
        Text("All Sounds")
          .font(.headline)

        HStack {
          Image(systemName: "speaker.wave.1.fill")
            .foregroundColor(.secondary)

          Slider(
            value: Binding(
              get: { globalSettings.volume },
              set: { globalSettings.setVolume($0) }
            ),
            in: 0...1
          )
          .tint(accentColor)

          Image(systemName: "speaker.wave.3.fill")
            .foregroundColor(.secondary)
        }
      }
      .padding(.horizontal)
      .padding(.top)

      // Active sound sliders
      if audioManager.sounds.contains(where: \.isSelected) {
        Divider()
          .padding(.horizontal)

        VStack(alignment: .leading, spacing: 16) {
          Text("Active Sounds")
            .font(.headline)
            .padding(.horizontal)

          ForEach(audioManager.sounds.filter(\.isSelected)) { sound in
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: sound.systemIconName)
                  .foregroundColor(accentColor)

                Text(sound.title)
                  .font(.callout)
              }

              HStack {
                Image(systemName: "speaker.wave.1.fill")
                  .foregroundColor(.secondary)
                  .font(.caption)

                Slider(
                  value: Binding(
                    get: { Double(sound.volume) },
                    set: { sound.volume = Float($0) }
                  ), in: 0...1
                )
                .tint(accentColor)

                Image(systemName: "speaker.wave.3.fill")
                  .foregroundColor(.secondary)
                  .font(.caption)
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
          }
        }
      }

      Divider()
        .padding(.horizontal)

      // Reset button
      Button(action: {
        // Provide haptic feedback if enabled (iOS only)
        if globalSettings.enableHaptics {
          #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
          #endif
        }

        audioManager.resetSounds()
        dismiss()
      }) {
        Text("Reset All Sounds")
          .foregroundColor(.red)
      }
      .padding()
      .buttonStyle(.bordered)
    }
    .padding()
  }
}

// Preview Provider
struct VolumeControlsView_Previews: PreviewProvider {
  static var previews: some View {
    VolumeControlsView(style: .sheet)
  }
}
