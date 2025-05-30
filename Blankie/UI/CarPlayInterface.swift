// CarPlayInterface.swift
// Blankie
//
// Created by Cody Bromley on 4/18/25.
//

#if CARPLAY_ENABLED

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

      print("🚗 CarPlay: Updating interface at \(Date())")

      // Just show the preset list
      let presetsTemplate = createPresetsTemplate()

      // Force update by setting root template
      interfaceController.setRootTemplate(presetsTemplate, animated: false, completion: nil)
    }

    // MARK: - Template Creation

    private func createPresetsTemplate() -> CPTemplate {
      let presets = PresetManager.shared.presets

      // Just show the preset list
      let presetItems = presets.map { createPresetListItem($0) }

      return CPListTemplate(title: "Blankie", sections: [CPListSection(items: presetItems)])
    }

    private func createPresetListItem(_ preset: Preset) -> CPListItem {
      let currentPresetId = PresetManager.shared.currentPreset?.id
      let isActive = preset.id == currentPresetId
      let activeIndicator = isActive ? " ✓" : ""

      print(
        "🚗 CarPlay: Creating preset item '\(preset.name)' - isActive: \(isActive), currentPresetId: \(currentPresetId?.uuidString ?? "nil")"
      )

      let item = CPListItem(
        text: "\(preset.name)\(activeIndicator)", detailText: getPresetDetailText(preset))

      // Use a weak capture to avoid the 'self' in concurrently-executing code error
      let weakSelf = self
      item.handler = { _, completion in
        Task {
          do {
            try await PresetManager.shared.applyPreset(preset)
            await MainActor.run {
              // Always ensure playback starts when selecting a preset in CarPlay
              AudioManager.shared.setGlobalPlaybackState(true)
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
        .sink { [weak self] isPlaying in
          print("🚗 CarPlay: Playback state changed to: \(isPlaying)")
          // Only update if we're showing the root template (not Now Playing)
          if let interfaceController = self?.interfaceController,
            interfaceController.topTemplate === interfaceController.rootTemplate {
            print("🚗 CarPlay: Updating interface for playback state change")
            self?.updateInterface()
          }
        }
        .store(in: &cancellables)
    }

    private func observePresetManagerChanges() {
      // Observe current preset
      PresetManager.shared.$currentPreset
        .sink { [weak self] preset in
          print("🚗 CarPlay: Current preset changed to: \(preset?.name ?? "nil")")
          self?.updateInterface()
        }
        .store(in: &cancellables)

      // Also observe presets array changes
      PresetManager.shared.$presets
        .sink { [weak self] _ in
          print("🚗 CarPlay: Presets array changed")
          self?.updateInterface()
        }
        .store(in: &cancellables)
    }
  }

#endif
