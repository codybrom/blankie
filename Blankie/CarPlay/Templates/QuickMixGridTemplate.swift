//
// QuickMixGridTemplate.swift
// Blankie
//
// Created by Cody Bromley on 6/7/25.
//

#if CARPLAY_ENABLED

  import CarPlay
  import SwiftUI

  enum QuickMixGridTemplate {

    static func createTemplate() -> CPGridTemplate {
      let gridButtons = createGridButtons()

      let template = CPGridTemplate(
        title: "Quick Mix",
        gridButtons: gridButtons
      )

      // Set tab image
      template.tabImage = UIImage(systemName: "square.grid.2x2")

      return template
    }

    static func updateTemplate(_ template: CPGridTemplate) {
      // Update grid buttons with current state
      let updatedButtons = createGridButtons()
      template.updateGridButtons(updatedButtons)
    }

    private static func createGridButtons() -> [CPGridButton] {
      let quickMixSounds = CarPlayInterfaceController.shared.quickMixSoundFileNames

      return quickMixSounds.compactMap { fileName in
        guard let sound = AudioManager.shared.sounds.first(where: { $0.fileName == fileName })
        else {
          return nil
        }

        return createGridButton(for: sound)
      }
    }

    private static func createGridButton(for sound: Sound) -> CPGridButton {
      // Check if sound is currently playing (not in solo mode)
      let isPlaying = sound.player?.isPlaying == true && AudioManager.shared.soloModeSound == nil

      // Create button titles
      let titles = [sound.title]

      // Create button with system image for now
      let button = CPGridButton(
        titleVariants: titles,
        image: getButtonImage(for: sound, isPlaying: isPlaying)
      ) { button in
        handleSoundToggle(sound, button: button)
      }

      return button
    }

    private static func getButtonImage(for sound: Sound, isPlaying: Bool) -> UIImage {
      // Create a colored circle background with the icon
      let size = CGSize(width: 100, height: 100)
      let renderer = UIGraphicsImageRenderer(size: size)

      return renderer.image { _ in
        // Get the color for this sound
        let backgroundColor = getBackgroundColor(for: sound, isPlaying: isPlaying)

        // Draw the circle background with opacity (matching Blankie app)
        backgroundColor.withAlphaComponent(isPlaying ? 0.3 : 0.2).setFill()
        let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
        circle.fill()

        // Draw the icon in the center
        let iconName = sound.systemIconName
        let icon = UIImage(systemName: iconName) ?? UIImage(systemName: "speaker.wave.2")!

        // Use configuration for better icon rendering
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        let configuredIcon = icon.withConfiguration(iconConfig)

        let iconSize = CGSize(width: 50, height: 50)
        let iconRect = CGRect(
          x: (size.width - iconSize.width) / 2,
          y: (size.height - iconSize.height) / 2,
          width: iconSize.width,
          height: iconSize.height
        )

        // Draw icon - use color when playing, gray when not
        if isPlaying {
          backgroundColor.setFill()
        } else {
          UIColor.label.setFill()  // Adapts to light/dark mode
        }
        configuredIcon.withRenderingMode(.alwaysTemplate).draw(in: iconRect)
      }
    }

    private static func getBackgroundColor(for sound: Sound, isPlaying: Bool) -> UIColor {
      // When not playing, use gray (matching Blankie app behavior)
      guard isPlaying else {
        return UIColor.systemGray.withAlphaComponent(0.3)
      }

      // When playing, use the sound's custom color or a default color
      if let customColor = sound.customColor {
        // Convert SwiftUI Color to UIColor
        return UIColor(customColor)
      }

      // Define default colors for each sound (matching Blankie's defaults)
      let soundColors: [String: UIColor] = [
        "rain": UIColor.systemBlue,
        "waves": UIColor.systemTeal,
        "fireplace": UIColor.systemOrange,
        "white-noise": UIColor.systemGray,
        "wind": UIColor.systemGreen,
        "stream": UIColor.systemCyan,
        "birds": UIColor.systemYellow,
        "coffee-shop": UIColor.systemBrown,
      ]

      return soundColors[sound.fileName] ?? UIColor.systemPurple
    }

    private static func handleSoundToggle(_ sound: Sound, button: CPGridButton) {
      Task { @MainActor in
        // Check if we're in CarPlay Quick Mix mode
        if !AudioManager.shared.isCarPlayQuickMix {
          // Enter CarPlay Quick Mix mode with this sound
          AudioManager.shared.enterCarPlayQuickMix(with: [sound])
        } else {
          // We're already in Quick Mix, toggle this specific sound
          AudioManager.shared.toggleCarPlayQuickMixSound(sound)
        }

        // Update the interface
        CarPlayInterfaceController.shared.updateAllTemplates()

        // Post notification for other parts of the app
        NotificationCenter.default.post(name: .soundStateChanged, object: sound)
      }
    }

  }

#endif
