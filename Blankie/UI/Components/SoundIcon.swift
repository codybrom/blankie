//
//  SoundIcon.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftData
import SwiftUI

struct SoundIcon: View {
  @ObservedObject var sound: Sound
  @ObservedObject var globalSettings = GlobalSettings.shared
  @ObservedObject var audioManager = AudioManager.shared
  let maxWidth: CGFloat

  @State private var showingEditSheet = false
  @State private var showingDeleteConfirmation = false

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
      .frame(width: Configuration.iconSize, height: Configuration.iconSize)
      .contentShape(Circle())
      .gesture(
        TapGesture()
          .onEnded { _ in
            sound.toggle()
          }
      )
      .accessibilityIdentifier("sound-\(sound.fileName)")

      Text(LocalizedStringKey(sound.title))
        .font(
          Locale.current.identifier.hasPrefix("zh") ? .system(size: 16, weight: .thin) : .callout
        )
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .frame(maxWidth: maxWidth - (Configuration.padding.leading * 2))
        .foregroundColor(.primary)
        .contentShape(Rectangle())

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
    .contextMenu {
      Button("Hide Sound", systemImage: "eye.slash") {
        audioManager.hideSound(sound)
      }

      if sound is CustomSound {
        Button("Edit Sound", systemImage: "pencil") {
          showingEditSheet = true
        }

        Button("Delete Sound", systemImage: "trash", role: .destructive) {
          showingDeleteConfirmation = true
        }
      } else {
        // Built-in sound customization options
        Button("Customize Sound", systemImage: "slider.horizontal.3") {
          showingEditSheet = true
        }

        // Show reset option if sound has customizations
        if SoundCustomizationManager.shared.getCustomization(for: sound.fileName)?.hasCustomizations
          == true
        {
          Button("Reset to Default", systemImage: "arrow.counterclockwise") {
            SoundCustomizationManager.shared.resetCustomizations(for: sound.fileName)
          }
        }
      }
    }
    .sheet(isPresented: $showingEditSheet) {
      if let customSound = sound as? CustomSound {
        SoundSheet(mode: .edit(customSound.customSoundData))
      } else {
        SoundSheet(mode: .customize(sound))
      }
    }
    .alert(
      Text("Delete Sound", comment: "Delete sound confirmation alert title"),
      isPresented: $showingDeleteConfirmation
    ) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let customSound = sound as? CustomSound {
          deleteCustomSound(customSound)
        }
      }
    } message: {
      Text(
        "Are you sure you want to delete '\(sound.title)'? This action cannot be undone.",
        comment: "Delete custom sound confirmation message"
      )
    }
  }

  private func deleteCustomSound(_ customSound: CustomSound) {
    let result = CustomSoundManager.shared.deleteCustomSound(customSound.customSoundData)

    if case .failure(let error) = result {
      print("❌ SoundIcon: Failed to delete custom sound: \(error)")
    }
  }
}

#if DEBUG
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
#endif
