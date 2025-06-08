// SoundsListTemplate.swift
// Blankie

#if CARPLAY_ENABLED

  import CarPlay
  import SwiftUI

  enum SoundsListTemplate {

    static func createTemplate() -> CPListTemplate {
      let template = CPListTemplate(
        title: "Sounds",
        sections: []
      )

      // Set tab image
      template.tabImage = UIImage(systemName: "speaker.wave.2")

      updateTemplate(template)
      return template
    }

    static func updateTemplate(_ template: CPListTemplate) {
      var sections: [CPListSection] = []

      // Get all non-hidden sounds
      let allSounds = AudioManager.shared.sounds.filter { !$0.isHidden }

      // Group sounds by category (built-in vs custom)
      let builtInSounds = allSounds.filter { !$0.isCustom }
      let customSounds = allSounds.filter { $0.isCustom }

      // Built-in sounds section
      if !builtInSounds.isEmpty {
        let sortedSounds = builtInSounds.sorted { $0.title < $1.title }
        let soundItems = sortedSounds.map { createSoundListItem($0) }
        sections.append(
          CPListSection(
            items: soundItems,
            header: "Built-in Sounds",
            sectionIndexTitle: "B"
          )
        )
      }

      // Custom sounds section
      if !customSounds.isEmpty {
        let sortedCustom = customSounds.sorted { $0.title < $1.title }
        let customItems = sortedCustom.map { createSoundListItem($0) }
        sections.append(
          CPListSection(
            items: customItems,
            header: "Custom Sounds",
            sectionIndexTitle: "C"
          )
        )
      }

      template.updateSections(sections)
    }

    private static func createSoundListItem(_ sound: Sound) -> CPListItem {
      let isInSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      let item = CPListItem(
        text: sound.title,
        detailText: sound.isCustom ? "Custom" : nil
      )

      // Add accessory if playing in solo mode
      if isInSoloMode {
        item.accessoryType = .disclosureIndicator
        item.setText("\(sound.title) ✓")
      }

      // Set image
      if let image = getSoundImage(for: sound) {
        item.setImage(image)
      }

      item.handler = { _, completion in
        Task { @MainActor in
          playSoundInSoloMode(sound)
          completion()
        }
      }

      return item
    }

    private static func getSoundImage(for sound: Sound) -> UIImage? {
      // Create a circular background with the icon centered
      let size = CGSize(width: 40, height: 40)
      let renderer = UIGraphicsImageRenderer(size: size)

      return renderer.image { _ in
        // Determine if sound is playing in solo mode
        let isInSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

        // Get background color
        let backgroundColor: UIColor
        if isInSoloMode {
          // Use sound's color when playing
          if let customColor = sound.customColor {
            backgroundColor = UIColor(customColor)
          } else {
            // Default colors for built-in sounds
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
            backgroundColor = soundColors[sound.fileName] ?? UIColor.systemPurple
          }
        } else {
          backgroundColor = UIColor.systemGray
        }

        // Draw circle background
        if isInSoloMode {
          // Show colored background when playing
          backgroundColor.withAlphaComponent(0.3).setFill()
          let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
          circle.fill()
        } else {
          // Very subtle gray background when not playing
          UIColor.systemGray.withAlphaComponent(0.1).setFill()
          let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
          circle.fill()
        }

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
          backgroundColor.setFill()
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
    }

    @MainActor
    private static func playSoundInSoloMode(_ sound: Sound) {
      // Toggle solo mode for this sound
      AudioManager.shared.toggleSoloMode(for: sound)

      // Update interface
      CarPlayInterfaceController.shared.updateAllTemplates()

      // Show Now Playing if we started playing
      if AudioManager.shared.soloModeSound != nil {
        CarPlayInterfaceController.shared.showNowPlaying()
      }
    }
  }

#endif
