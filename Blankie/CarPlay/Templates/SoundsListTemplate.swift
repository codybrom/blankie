//
// SoundsListTemplate.swift
// Blankie
//
// Created by Cody Bromley on 6/7/25.
//

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

      // Get all sounds
      let allSounds = AudioManager.shared.sounds

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
