// CarPlaySceneDelegate.swift
// Blankie
//
// Created by Cody Bromley on 4/18/25.
//

import CarPlay
import Foundation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

  private var interfaceController: CPInterfaceController?

  // Core required method - must be implemented exactly like this
  func templateApplicationScene(
    _ scene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    print("🚗 CarPlay: Connected!")
    self.interfaceController = interfaceController

    // Set up a simple list template
    let presets = PresetManager.shared.presets
    var items: [CPListItem] = []

    // Add Now Playing button if there's an active preset
    if let currentPreset = PresetManager.shared.currentPreset {
      let nowPlayingItem = CPListItem(
        text: "Now Playing: \(currentPreset.name)",
        detailText: AudioManager.shared.isGloballyPlaying ? "Playing" : "Paused",
        image: UIImage(systemName: "play.fill")
      )
      nowPlayingItem.accessoryType = .disclosureIndicator
      nowPlayingItem.handler = { [weak self] _, completion in
        AudioManager.shared.updateNowPlayingInfoForPreset(presetName: currentPreset.name)

        // Push the Now Playing template
        self?.interfaceController?.pushTemplate(
          CPNowPlayingTemplate.shared,
          animated: true,
          completion: nil

        )
        completion()
      }
      items.append(nowPlayingItem)
    }

    // Add presets
    for preset in presets {
      let isActive = preset.id == PresetManager.shared.currentPreset?.id

      // Get list of active sound names
      let sounds = preset.soundStates
        .filter { $0.isSelected }
        .map { $0.fileName }
        .joined(separator: ", ")
      let detail = sounds.isEmpty ? "No sounds selected" : sounds

      let item = CPListItem(
        text: preset.name + (isActive ? " ✓" : ""),
        detailText: detail
      )

      item.handler = { _, completion in
        do {
          try PresetManager.shared.applyPreset(preset)
          completion()
        } catch {
          print("CarPlay: Error applying preset - \(error)")
          completion()
        }
      }
      items.append(item)
    }

    // Create and set template
    let section = CPListSection(items: items)
    let template = CPListTemplate(title: "Blankie", sections: [section])
    interfaceController.setRootTemplate(template, animated: true, completion: nil)
  }

  // Optional - handle disconnection
  private func templateApplicationScene(
    _ scene: CPTemplateApplicationScene,
    didDisconnect interfaceController: CPInterfaceController
  ) {
    print("🚗 CarPlay: Disconnected!")
    self.interfaceController = nil
  }
}
