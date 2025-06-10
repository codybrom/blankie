//
//  QuickMixView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

struct QuickMixView: View {
  @ObservedObject var audioManager = AudioManager.shared

  // Quick Mix sounds (8 most popular)
  private let quickMixSoundFileNames = [
    "rain", "waves", "fireplace", "white-noise",
    "wind", "stream", "birds", "coffee-shop",
  ]

  private var quickMixSounds: [Sound] {
    return quickMixSoundFileNames.compactMap { fileName in
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
              QuickMixSoundButton(sound: sound)
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

  var body: some View {
    Button(action: {
      audioManager.toggleCarPlayQuickMixSound(sound)
    }) {
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

#Preview {
  QuickMixView()
}
