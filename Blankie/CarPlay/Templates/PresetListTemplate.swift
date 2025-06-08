// PresetListTemplate.swift
// Blankie

#if CARPLAY_ENABLED

  import CarPlay
  import SwiftUI

  enum PresetListTemplate {

    static func createTemplate() -> CPListTemplate {
      let template = CPListTemplate(
        title: "Presets",
        sections: []
      )

      // Set tab image
      template.tabImage = UIImage(systemName: "list.bullet")

      updateTemplate(template)
      return template
    }

    static func updateTemplate(_ template: CPListTemplate) {
      var sections: [CPListSection] = []

      // Get presets
      let customPresets = PresetManager.shared.presets.filter { !$0.isDefault }
      let defaultPreset = PresetManager.shared.presets.first { $0.isDefault }

      // Recent presets section (if we have any custom presets)
      if !customPresets.isEmpty {
        let sortedPresets = customPresets.sorted { preset1, preset2 in
          // Sort by last used date if available, otherwise by name
          preset1.name < preset2.name
        }

        // Show up to 3 recent presets
        let recentPresets = Array(sortedPresets.prefix(3))
        if !recentPresets.isEmpty {
          let recentItems = recentPresets.map { createPresetListItem($0) }
          sections.append(
            CPListSection(
              items: recentItems,
              header: "Recent",
              sectionIndexTitle: "R"
            )
          )
        }

        // All presets section
        let allItems = customPresets.map { createPresetListItem($0) }
        sections.append(
          CPListSection(
            items: allItems,
            header: "All Presets",
            sectionIndexTitle: "A"
          )
        )
      } else if let defaultPreset = defaultPreset {
        // No custom presets - show default as "Current Soundscape"
        let currentItem = createCurrentSoundscapeItem(defaultPreset)
        sections.append(
          CPListSection(
            items: [currentItem],
            header: "Presets",
            sectionIndexTitle: "P"
          )
        )

        // Add empty state message
        let emptyItem = CPListItem(
          text: "Create presets in iPhone app",
          detailText: "Your saved presets will appear here"
        )
        emptyItem.isEnabled = false
        sections.append(
          CPListSection(items: [emptyItem])
        )
      }

      template.updateSections(sections)
    }

    private static func createPresetListItem(_ preset: Preset) -> CPListItem {
      let currentPresetId = PresetManager.shared.currentPreset?.id
      let isActive = preset.id == currentPresetId

      let item = CPListItem(
        text: preset.name,
        detailText: getPresetDetailText(preset)
      )

      // Add checkmark accessory if active
      if isActive {
        item.accessoryType = .disclosureIndicator
        // Update text to show active state
        item.setText("\(preset.name) ✓")
      }

      item.handler = { _, completion in
        Task {
          do {
            try await PresetManager.shared.applyPreset(preset)
            await MainActor.run {
              // Ensure playback starts
              AudioManager.shared.setGlobalPlaybackState(true)
              CarPlayInterfaceController.shared.updateAllTemplates()
            }
          } catch {
            print("🚗 CarPlay: Error applying preset: \(error)")
          }
          completion()
        }
      }

      return item
    }

    private static func createCurrentSoundscapeItem(_ preset: Preset) -> CPListItem {
      let currentPresetId = PresetManager.shared.currentPreset?.id
      let isActive = preset.id == currentPresetId

      let item = CPListItem(
        text: "Current Soundscape",
        detailText: getPresetDetailText(preset)
      )

      if isActive {
        item.accessoryType = .disclosureIndicator
        item.setText("Current Soundscape ✓")
      }

      item.handler = { _, completion in
        Task {
          do {
            try await PresetManager.shared.applyPreset(preset)
            await MainActor.run {
              AudioManager.shared.setGlobalPlaybackState(true)
              CarPlayInterfaceController.shared.updateAllTemplates()
            }
          } catch {
            print("🚗 CarPlay: Error applying preset: \(error)")
          }
          completion()
        }
      }

      return item
    }

    private static func getPresetDetailText(_ preset: Preset) -> String {
      let activeSounds = preset.soundStates.filter { $0.isSelected }
      if activeSounds.isEmpty {
        return "No active sounds"
      }

      let soundNames = activeSounds.prefix(3).compactMap { soundState in
        AudioManager.shared.sounds.first { $0.fileName == soundState.fileName }?.title
      }

      if activeSounds.count > 3 {
        return "\(soundNames.joined(separator: ", ")) +\(activeSounds.count - 3)"
      } else {
        return soundNames.joined(separator: ", ")
      }
    }
  }

#endif
