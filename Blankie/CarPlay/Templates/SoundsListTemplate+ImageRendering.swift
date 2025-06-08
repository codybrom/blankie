//
// SoundsListTemplate+ImageRendering.swift
// Blankie
//
// Created by Cody Bromley on 6/8/25.
//

#if CARPLAY_ENABLED

  import CarPlay
  import SwiftUI

  extension SoundsListTemplate {

    static func getSoundImage(for sound: Sound) -> UIImage? {
      // Create a circular background with the icon centered
      let size = CGSize(width: 40, height: 40)
      let renderer = UIGraphicsImageRenderer(size: size)

      return renderer.image { _ in
        let isInSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

        drawBackground(size: size, isInSoloMode: isInSoloMode, sound: sound)
        drawIcon(size: size, isInSoloMode: isInSoloMode, sound: sound)
      }
    }

    private static func drawBackground(size: CGSize, isInSoloMode: Bool, sound: Sound) {
      let backgroundColor = getBackgroundColor(for: sound, isInSoloMode: isInSoloMode)

      if isInSoloMode {
        // Show colored background when playing
        backgroundColor.withAlphaComponent(0.3).setFill()
      } else {
        // Very subtle gray background when not playing
        UIColor.systemGray.withAlphaComponent(0.1).setFill()
      }

      let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
      circle.fill()
    }

    private static func drawIcon(size: CGSize, isInSoloMode: Bool, sound: Sound) {
      // Draw icon
      let iconName = sound.systemIconName
      let icon = UIImage(systemName: iconName) ?? UIImage(systemName: "speaker.wave.2")!

      // Configure icon size proportionally
      let iconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
      let configuredIcon = icon.withConfiguration(iconConfig)

      let iconSize = CGSize(width: 28, height: 28)
      let iconRect = CGRect(
        x: (size.width - iconSize.width) / 2,
        y: (size.height - iconSize.height) / 2,
        width: iconSize.width,
        height: iconSize.height
      )

      // Set icon color based on state and customization
      if isInSoloMode {
        getBackgroundColor(for: sound, isInSoloMode: isInSoloMode).setFill()
      } else {
        // Use custom color if available, otherwise use accent/tint color
        if let customColor = sound.customColor {
          UIColor(customColor).setFill()
        } else {
          UIColor.tintColor.setFill()  // This will use the system accent color
        }
      }
      configuredIcon.withRenderingMode(.alwaysTemplate).draw(in: iconRect)
    }

    private static func getBackgroundColor(for sound: Sound, isInSoloMode: Bool) -> UIColor {
      if isInSoloMode {
        // Use sound's color when playing
        if let customColor = sound.customColor {
          return UIColor(customColor)
        } else {
          // Default colors for built-in sounds
          return getDefaultColor(for: sound)
        }
      } else {
        return UIColor.systemGray
      }
    }

    private static func getDefaultColor(for sound: Sound) -> UIColor {
      let soundColors: [String: UIColor] = [
        "rain": UIColor.systemBlue,
        "waves": UIColor.systemTeal,
        "fireplace": UIColor.systemOrange,
        "white-noise": UIColor.systemGray,
        "wind": UIColor.systemGreen,
        "stream": UIColor.systemCyan,
        "birds": UIColor.systemYellow,
        "coffee-shop": UIColor.systemBrown,
        "storm": UIColor.systemPurple,
        "city": UIColor.systemIndigo,
        "train": UIColor.systemRed,
        "boat": UIColor.systemMint,
        "summer-night": UIColor.systemPink,
        "pink-noise": UIColor.systemGray2,
      ]
      return soundColors[sound.fileName] ?? UIColor.systemPurple
    }
  }

#endif
