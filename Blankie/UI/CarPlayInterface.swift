// CarPlayInterface.swift
// Blankie
//
// Created by Cody Bromley on 4/18/25.
//

import CarPlay
import Combine
import SwiftUI

class CarPlayInterface: ObservableObject {
  static let shared = CarPlayInterface()

  @Published private(set) var isConnected = false
  private var interfaceController: CPInterfaceController?
  private var cancellables = Set<AnyCancellable>()

  private init() {
    // Set up observers for audio manager and preset manager changes
    observeAudioManagerChanges()
    observePresetManagerChanges()
  }

  func setInterfaceController(_ controller: CPInterfaceController) {
    interfaceController = controller
    isConnected = true
    updateInterface()

    // Post notification about CarPlay connection
    NotificationCenter.default.post(
      name: NSNotification.Name("CarPlayConnectionChanged"),
      object: nil,
      userInfo: ["isConnected": true]
    )
  }

  func disconnect() {
    interfaceController = nil
    isConnected = false

    // Post notification about CarPlay disconnection
    NotificationCenter.default.post(
      name: NSNotification.Name("CarPlayConnectionChanged"),
      object: nil,
      userInfo: ["isConnected": false]
    )
  }

  // MARK: - Interface Management

  func updateInterface() {
    guard isConnected, let interfaceController = interfaceController else { return }

    // Create a list template with tabs
    let tabTemplates = [createPresetsTemplate(), createNowPlayingTemplate()]
    let tabTemplate = CPTabBarTemplate(templates: tabTemplates)

    interfaceController.setRootTemplate(tabTemplate, animated: true, completion: nil)
  }

  // MARK: - Template Creation

  private func createPresetsTemplate() -> CPTemplate {
    let presets = PresetManager.shared.presets

    var listItems: [CPListItem] = []

    // Group items by default vs custom presets
    let defaultPresets = presets.filter { $0.isDefault }
    let customPresets = presets.filter { !$0.isDefault }

    // Default presets section
    if !defaultPresets.isEmpty {
      let defaultItems = defaultPresets.map { createPresetListItem($0) }
      _ = CPListSection(items: defaultItems, header: "Default", sectionIndexTitle: "D")
      listItems.append(contentsOf: defaultItems)
    }

    // Custom presets section
    if !customPresets.isEmpty {
      let customItems = customPresets.map { createPresetListItem($0) }
      _ = CPListSection(items: customItems, header: "Custom Presets", sectionIndexTitle: "C")
      listItems.append(contentsOf: customItems)
    }

    return CPListTemplate(title: "Presets", sections: [CPListSection(items: listItems)])
  }

  private func createNowPlayingTemplate() -> CPTemplate {
    let isPlaying = AudioManager.shared.isGloballyPlaying

    // Create control bar buttons - using title for both since Type doesn't have play/pause
    let playPauseButton = CPBarButton(
      title: isPlaying ? "Pause" : "Play",
      handler: { [weak self] _ in
        Task { @MainActor in
          AudioManager.shared.togglePlayback()
          self?.updateInterface()
        }
      }
    )

    let resetButton = CPBarButton(
      title: "Reset",
      handler: { [weak self] _ in
        Task { @MainActor in
          AudioManager.shared.resetSounds()
          self?.updateInterface()
        }
      }
    )

    // Create items for active sounds
    var listItems: [CPListItem] = []

    // Add a global volume item
    let globalVolumeItem = CPListItem(
      text: "Global Volume", detailText: "\(Int(GlobalSettings.shared.volume * 100))%")
    listItems.append(globalVolumeItem)

    // Add items for each active sound
    let activeSounds = AudioManager.shared.sounds.filter { $0.isSelected }
    for sound in activeSounds {
      let volumePercentage = Int(sound.volume * 100)
      let item = CPListItem(text: sound.title, detailText: "Volume: \(volumePercentage)%")
      listItems.append(item)
    }

    if activeSounds.isEmpty {
      let noSoundsItem = CPListItem(
        text: "No Active Sounds", detailText: "Select a preset to begin")
      listItems.append(noSoundsItem)
    }

    // Create the template
    let template = CPListTemplate(
      title: "Now Playing",
      sections: [CPListSection(items: listItems)]
    )

    // Add the buttons to the navigation bar
    template.trailingNavigationBarButtons = [resetButton]
    template.leadingNavigationBarButtons = [playPauseButton]

    return template
  }

  private func createPresetListItem(_ preset: Preset) -> CPListItem {
    let isActive = preset.id == PresetManager.shared.currentPreset?.id
    let activeIndicator = isActive ? " ✓" : ""

    let item = CPListItem(
      text: "\(preset.name)\(activeIndicator)", detailText: getPresetDetailText(preset))

    // Use a weak capture to avoid the 'self' in concurrently-executing code error
    let weakSelf = self
    item.handler = { _, completion in
      Task {
        do {
          try await PresetManager.shared.applyPreset(preset)
          await MainActor.run {
            if !AudioManager.shared.isGloballyPlaying {
              AudioManager.shared.setGlobalPlaybackState(true)
            }
            weakSelf.updateInterface()
          }
        } catch {
          print("🚗 CarPlay: Error applying preset: \(error)")
        }
        completion()
      }
    }

    return item
  }

  private func getPresetDetailText(_ preset: Preset) -> String {
    let activeSounds = preset.soundStates.filter { $0.isSelected }
    if activeSounds.isEmpty {
      return "No active sounds"
    } else {
      // List the first few sound names
      let soundNames = activeSounds.prefix(3).map { soundState in
        AudioManager.shared.sounds.first { $0.fileName == soundState.fileName }?.title
          ?? soundState.fileName
      }
      if activeSounds.count > 3 {
        return "\(soundNames.joined(separator: ", ")) and \(activeSounds.count - 3) more"
      } else {
        return soundNames.joined(separator: ", ")
      }
    }
  }

  // MARK: - Observers

  private func observeAudioManagerChanges() {
    // Observe global playback state
    AudioManager.shared.$isGloballyPlaying
      .sink { [weak self] _ in
        self?.updateInterface()
      }
      .store(in: &cancellables)
  }

  private func observePresetManagerChanges() {
    // Observe current preset
    PresetManager.shared.$currentPreset
      .sink { [weak self] _ in
        self?.updateInterface()
      }
      .store(in: &cancellables)
  }
}
