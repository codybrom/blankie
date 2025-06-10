//
//  QuickMixView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

struct QuickMixView: View {
  @ObservedObject var audioManager = AudioManager.shared
  @ObservedObject var globalSettings = GlobalSettings.shared

  private var quickMixSounds: [Sound] {
    return globalSettings.quickMixSoundFileNames.compactMap { fileName in
      audioManager.sounds.first { $0.fileName == fileName && !$0.isCustom }
    }
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Quick Mix Grid
        ScrollView {
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16
          ) {
            ForEach(quickMixSounds, id: \.id) { sound in
              QuickMixSoundButton(
                sound: sound
              )
            }
          }
          .padding()
        }

        Spacer()
      }
      #if !os(macOS)
        .navigationBarHidden(true)
      #endif
    }
    #if !os(macOS)
      .navigationViewStyle(StackNavigationViewStyle())
    #endif
  }
}

struct QuickMixSoundButton: View {
  @ObservedObject var sound: Sound
  @ObservedObject var audioManager = AudioManager.shared
  @ObservedObject var globalSettings = GlobalSettings.shared
  @State private var showingQuickMixOptions = false

  var body: some View {
    VStack(spacing: 12) {
      // Icon
      ZStack {
        Circle()
          .fill(iconBackgroundColor)
          .frame(width: 80, height: 80)

        Image(systemName: sound.systemIconName)
          .font(.system(size: 32, weight: .medium))
          .foregroundColor(iconForegroundColor)
      }

      // Title
      Text(sound.title)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(backgroundColor)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(borderColor, lineWidth: sound.isSelected ? 2 : 1)
        )
    )
    .scaleEffect(sound.isSelected ? 1.05 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: sound.isSelected)
    .onTapGesture {
      audioManager.toggleCarPlayQuickMixSound(sound)
    }
    .onLongPressGesture {
      #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
      #endif
      showingQuickMixOptions = true
    }
    .popover(isPresented: $showingQuickMixOptions, arrowEdge: .top) {
      QuickMixSoundOptionsPopover(
        sound: sound
      )
      .presentationCompactAdaptation(.popover)
    }
  }

  private var backgroundColor: Color {
    if sound.isSelected {
      return (globalSettings.customAccentColor ?? .accentColor).opacity(0.1)
    } else {
      #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
      #else
        return Color(UIColor.systemBackground)
      #endif
    }
  }

  private var borderColor: Color {
    if sound.isSelected {
      return globalSettings.customAccentColor ?? .accentColor
    } else {
      return Color.secondary.opacity(0.3)
    }
  }

  private var iconBackgroundColor: Color {
    if sound.isSelected {
      return globalSettings.customAccentColor ?? .accentColor
    } else {
      return Color.secondary.opacity(0.2)
    }
  }

  private var iconForegroundColor: Color {
    if sound.isSelected {
      return .white
    } else {
      return .secondary
    }
  }
}

struct QuickMixSoundOptionsPopover: View {
  @ObservedObject var sound: Sound
  @ObservedObject var audioManager = AudioManager.shared
  @ObservedObject var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) var dismiss

  // Available sounds for replacement (exclude custom sounds and sounds already in Quick Mix)
  private var availableSounds: [Sound] {
    return audioManager.sounds.filter { availableSound in
      !availableSound.isCustom
        && !globalSettings.quickMixSoundFileNames.contains(availableSound.fileName)
    }
  }

  var body: some View {
    VStack(spacing: 16) {
      // Volume Control
      VStack(spacing: 8) {
        HStack {
          Text("Volume")
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
          Text("\(Int(sound.volume * 100))%")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 12) {
          Image(systemName: "speaker.fill")
            .font(.caption)
            .foregroundColor(.secondary)

          Slider(
            value: Binding(
              get: { sound.volume },
              set: { sound.volume = $0 }
            ), in: 0...1)

          Image(systemName: "speaker.wave.3.fill")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Replace Sound Button
      Menu {
        ForEach(availableSounds, id: \.id) { availableSound in
          Button(availableSound.title) {
            replaceSound(with: availableSound)
          }
        }
      } label: {
        HStack {
          Image(systemName: "arrow.triangle.2.circlepath")
            .font(.subheadline)
          Text("Replace Sound")
            .font(.subheadline)
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(10)
      }
    }
    .padding(16)
    .frame(minWidth: 280)
    .background(.regularMaterial)
  }

  private func replaceSound(with newSound: Sound) {
    // Find the index of the current sound in quickMixSoundFileNames
    guard let currentIndex = globalSettings.quickMixSoundFileNames.firstIndex(of: sound.fileName)
    else { return }

    // Stop the current sound if it's playing
    if sound.isSelected {
      sound.pause(immediate: true)
      sound.isSelected = false
    }

    // Replace the sound at the same position
    var updatedSounds = globalSettings.quickMixSoundFileNames
    updatedSounds[currentIndex] = newSound.fileName
    globalSettings.setQuickMixSoundFileNames(updatedSounds)

    // Start the new sound if we were playing the old one
    if audioManager.isGloballyPlaying {
      newSound.isSelected = true
      newSound.play()
    }

    // Dismiss the popover
    dismiss()
  }
}

#Preview {
  QuickMixView()
}
