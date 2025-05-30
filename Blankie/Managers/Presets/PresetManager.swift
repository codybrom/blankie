//
//  PresetManager.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import Combine
import SwiftUI

#if os(iOS)
  import UIKit
#endif

class PresetManager: ObservableObject {
  private var isInitializing = true
  static let shared = PresetManager()

  @Published private(set) var presets: [Preset] = []
  @Published private(set) var currentPreset: Preset? {
    didSet {
      AudioManager.shared.updateNowPlayingInfoForPreset(presetName: currentPreset?.name)
    }
  }
  @Published private(set) var hasCustomPresets: Bool = false
  @Published private(set) var isLoading: Bool = true
  @Published private(set) var error: Error?

  private var cancellables = Set<AnyCancellable>()
  private var isInitialLoad = true

  private init() {
    print("\n🎛️ PresetManager: --- Begin Initialization ---")

    // Set up a single observer for state changes
    AudioManager.shared.$sounds
      .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.updateCurrentPresetState()  // Remove await
        }
      }
      .store(in: &cancellables)

    Task { @MainActor in
      await loadPresets()
      isInitializing = false
    }
    print("🎛️ PresetManager: --- End Initialization ---\n")
  }

  deinit {
    cancellables.forEach { $0.cancel() }
    print("🎛️ PresetManager: Cleaned up")
  }
}

// MARK: - Lifecycle Observers

extension PresetManager {
  private func setupObservers() {
    // Observe app lifecycle for state changes that might affect presets
    #if os(iOS)
      NotificationCenter.default
        .publisher(for: UIApplication.willTerminateNotification)
        .sink { [weak self] _ in
          Task { @MainActor in
            self?.savePresets()
          }
        }
        .store(in: &cancellables)

      // Observe audio manager for state changes that might affect presets
      NotificationCenter.default
        .publisher(for: UIApplication.didEnterBackgroundNotification)
        .sink { [weak self] _ in
          Task { @MainActor in
            self?.savePresets()
          }
        }
        .store(in: &cancellables)
    #endif
  }

}

// MARK: - Preset CRUD Operations

extension PresetManager {
  @MainActor
  func saveNewPreset(name: String) {
    print("\n🎛️ PresetManager: --- Begin Creating New Preset ---")
    print("🎛️ PresetManager: Creating new preset '\(name)' from current state")

    do {
      let newPreset = try createPresetFromCurrentState(name: name)
      presets.append(newPreset)
      updateCustomPresetStatus()

      print("🎛️ PresetManager: New preset created:")
      logPresetState(newPreset)

      savePresets()
      try applyPreset(newPreset)
      print("🎛️ PresetManager: --- End Creating New Preset ---\n")
    } catch {
      handleError(error)
    }
  }

  @MainActor
  func updatePreset(_ preset: Preset, newName: String) {
    print("\n🎛️ PresetManager: Updating preset '\(preset.name)' to '\(newName)'")

    guard let index = presets.firstIndex(where: { $0.id == preset.id }) else {
      handleError(PresetError.invalidPreset)
      return
    }

    var updatedPreset = preset
    updatedPreset.name = newName

    // Validate the updated preset
    guard updatedPreset.validate() else {
      handleError(PresetError.invalidPreset)
      return
    }

    presets[index] = updatedPreset

    if currentPreset?.id == preset.id {
      currentPreset = updatedPreset
    }

    savePresets()
    print("🎛️ PresetManager: Preset updated successfully\n")
  }

  @MainActor
  func deletePreset(_ preset: Preset) {
    print("\n🎛️ PresetManager: --- Begin Delete Preset ---")
    print("🎛️ PresetManager: Attempting to delete preset '\(preset.name)'")

    guard !preset.isDefault else {
      handleError(PresetError.invalidPreset)
      return
    }

    let wasCurrentPreset = (currentPreset?.id == preset.id)

    presets.removeAll { $0.id == preset.id }
    updateCustomPresetStatus()

    if wasCurrentPreset {
      print("🎛️ PresetManager: Deleted current preset, switching to default/next")

      // Find next available CUSTOM preset
      if let nextCustomPreset = presets.first(where: { !$0.isDefault }) {
        do {
          print("🎛️ PresetManager: Applying next custom preset '\(nextCustomPreset.name)'")
          try applyPreset(nextCustomPreset)
        } catch {
          handleError(error)
        }
      } else {
        // If no other custom presets exist, copy the deleted preset's state to the default preset
        if let defaultPresetIndex = presets.firstIndex(where: { $0.isDefault }) {
          // Copy current state
          var updatedDefaultPreset = presets[defaultPresetIndex]
          updatedDefaultPreset.soundStates = preset.soundStates
          presets[defaultPresetIndex] = updatedDefaultPreset
          currentPreset = nil

          do {
            print(
              "🎛️ PresetManager: No other custom presets. Updating default and setting current preset to nil."
            )
            try applyPreset(updatedDefaultPreset)
          } catch {
            handleError(error)
          }

        } else {
          print("🎛️ PresetManager: No default or custom presets to switch too after deletion")
        }
      }
    }

    savePresets()
    print("🎛️ PresetManager: --- End Delete Preset ---\n")
  }

}

// MARK: - Preset State Management

extension PresetManager {
  @MainActor
  func updateCurrentPresetState() {
    // Don't update during initialization
    if isInitializing { return }

    guard let preset = currentPreset else {
      // Only log this once, not repeatedly
      if !isInitializing {
        print("❌ PresetManager: No current preset to update")
      }
      return
    }

    // Get current state
    let newStates = AudioManager.shared.sounds.map { sound in
      PresetState(
        fileName: sound.fileName,
        isSelected: sound.isSelected,
        volume: sound.volume
      )
    }

    // Only update if state has actually changed
    if preset.soundStates != newStates {
      var updatedPreset = preset
      updatedPreset.soundStates = newStates

      if let index = presets.firstIndex(where: { $0.id == preset.id }) {
        presets[index] = updatedPreset
        currentPreset = updatedPreset
        savePresets()
      }
    }
  }

  @MainActor
  func applyPreset(_ preset: Preset, isInitialLoad: Bool = false) throws {
    logPresetApplication(preset)

    guard preset.validate() else {
      throw PresetError.invalidPreset
    }

    if preset.id == currentPreset?.id && !isInitialLoad {
      print("🎛️ PresetManager: Preset already active, ignoring")
      return
    }

    let targetStates = preset.soundStates
    let wasPlaying = AudioManager.shared.isGloballyPlaying

    // Update current preset before any audio changes
    currentPreset = preset
    PresetStorage.saveLastActivePresetID(preset.id)

    // Explicitly update Now Playing info with preset name
    AudioManager.shared.updateNowPlayingInfoForPreset(presetName: preset.name)

    Task {
      if wasPlaying {
        AudioManager.shared.pauseAll()
        try? await Task.sleep(nanoseconds: 300_000_000)
      }

      // Apply states all at once
      applySoundStates(targetStates)

      // Wait a bit for states to settle
      try? await Task.sleep(nanoseconds: 100_000_000)

      if wasPlaying || (isInitialLoad && !GlobalSettings.shared.alwaysStartPaused) {
        if targetStates.contains(where: { $0.isSelected }) {
          AudioManager.shared.setGlobalPlaybackState(true)
        }
      }
    }

    print("🎛️ PresetManager: --- End Apply Preset ---\n")
  }

}
