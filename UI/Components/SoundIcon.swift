//
//  SoundIcon.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct SoundIcon: View {
  @ObservedObject var sound: Sound
  @ObservedObject var globalSettings = GlobalSettings.shared
  @ObservedObject var audioManager = AudioManager.shared
  let maxWidth: CGFloat

  private struct Configuration {
    static let iconSize: CGFloat = 100
    static let sliderWidth: CGFloat = 85
    static let spacing: CGFloat = 8
    static let padding = EdgeInsets(
      top: 12,
      leading: 10,
      bottom: 12,
      trailing: 10
    )
  }

  var accentColor: Color {
    globalSettings.customAccentColor ?? .accentColor
  }

  var iconColor: Color {
    if !audioManager.isGloballyPlaying {
      return .gray
    }
    return sound.isSelected ? accentColor : .gray
  }

  var backgroundFill: Color {
    if !audioManager.isGloballyPlaying {
      return sound.isSelected ? Color.gray.opacity(0.2) : .clear
    }
    return sound.isSelected ? accentColor.opacity(0.2) : .clear
  }

  var body: some View {
    VStack(spacing: Configuration.spacing) {
      Button(action: {
        sound.toggle()
      }) {
        ZStack {
          Circle()
            .fill(backgroundFill)
            .frame(width: Configuration.iconSize, height: Configuration.iconSize)

          Image(systemName: sound.systemIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Configuration.iconSize * 0.64, height: Configuration.iconSize * 0.64)
            .foregroundColor(iconColor)
        }
      }
      .buttonStyle(.borderless)
      .frame(width: Configuration.iconSize, height: Configuration.iconSize)

      Text(sound.title)
        .font(.callout)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .frame(maxWidth: maxWidth - (Configuration.padding.leading * 2))
        .foregroundColor(.primary)

      Slider(
        value: Binding(
          get: { Double(sound.volume) },
          set: { sound.volume = Float($0) }
        ), in: 0...1
      )
      .frame(width: Configuration.sliderWidth)
      .tint(audioManager.isGloballyPlaying ? (sound.isSelected ? accentColor : .gray) : .gray)
      .disabled(!sound.isSelected)
    }
    .padding(.vertical, Configuration.padding.top)
    .padding(.horizontal, Configuration.padding.leading)
    .frame(width: maxWidth)
  }
}
#Preview("Selected") {
  SoundIcon(
    sound: Sound(
      title: "Rain",
      systemIconName: "cloud.rain",
      fileName: "rain"
    ),
    maxWidth: 150
  )
  .onAppear {
    // Set up preview state using setter methods
    GlobalSettings.shared.setAccentColor(.blue)
    GlobalSettings.shared.setVolume(0.7)
  }
}

#Preview("Not Selected") {
  SoundIcon(
    sound: Sound(
      title: "Storm",
      systemIconName: "cloud.bolt.rain",
      fileName: "storm"
    ),
    maxWidth: 150
  )
}

#Preview("Long Title") {
  SoundIcon(
    sound: Sound(
      title: "Very Long Sound Name That Should Truncate",
      systemIconName: "speaker.wave.3.fill",
      fileName: "test"
    ),
    maxWidth: 150
  )
}

#Preview("Grid Layout") {
  LazyVGrid(
    columns: [
      GridItem(.fixed(150)),
      GridItem(.fixed(150)),
    ], spacing: 20
  ) {
    SoundIcon(
      sound: Sound(
        title: "Rain",
        systemIconName: "cloud.rain",
        fileName: "rain"
      ),
      maxWidth: 150
    )
    SoundIcon(
      sound: Sound(
        title: "Storm",
        systemIconName: "cloud.bolt.rain",
        fileName: "storm"
      ),
      maxWidth: 150
    )
    SoundIcon(
      sound: Sound(
        title: "Wind",
        systemIconName: "wind",
        fileName: "wind"
      ),
      maxWidth: 150
    )
    SoundIcon(
      sound: Sound(
        title: "Waves",
        systemIconName: "water.waves",
        fileName: "waves"
      ),
      maxWidth: 150
    )
  }
  .padding()
}
