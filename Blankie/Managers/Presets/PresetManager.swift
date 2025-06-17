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
  @Published var currentPreset: Preset? {
    didSet {
      AudioManager.shared.updateNowPlayingInfoForPreset(
        presetName: currentPreset?.activeTitle,
        creatorName: currentPreset?.creatorName,
        artworkId: currentPreset?.artworkId
      )
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

    // Don't load presets immediately - wait for custom sounds to be loaded
    // This will be triggered by initializePresetManager() after AudioManager setup
    print("🎛️ PresetManager: --- End Initialization (deferred preset loading) ---\n")
  }

  /// Initialize preset manager after AudioManager has loaded all sounds (including custom)
  @MainActor
  func initializePresetManager() async {
    guard isInitializing else {
      print("🎛️ PresetManager: Already initialized, skipping")
      return
    }

    print("🎛️ PresetManager: --- Begin Preset Loading After Sound Setup ---")
    await loadPresets()
    isInitializing = false
    print("🎛️ PresetManager: --- End Preset Loading After Sound Setup ---\n")
  }

  // Helper methods for extensions to set private properties
  func setLoading(_ loading: Bool) {
    isLoading = loading
  }

  func setPresets(_ newPresets: [Preset]) {
    presets = newPresets
  }

  func updatePresetAtIndex(_ index: Int, with preset: Preset) {
    presets[index] = preset
  }

  func setCurrentPreset(_ preset: Preset?) {
    currentPreset = preset
  }

  func setInitialLoad(_ initial: Bool) {
    isInitialLoad = initial
  }

  func setError(_ error: Error?) {
    self.error = error
  }

  func setHasCustomPresets(_ has: Bool) {
    hasCustomPresets = has
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
  func updatePreset(_ preset: Preset, newName: String) {
    print("\n🎛️ PresetManager: Updating preset '\(preset.name)' to '\(newName)'")

    guard let index = presets.firstIndex(where: { $0.id == preset.id }) else {
      handleError(PresetError.invalidPreset)
      return
    }

    var updatedPreset = preset
    updatedPreset.name = newName
    updatedPreset.lastModifiedVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

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

    // Remove cached thumbnail
    removeThumbnail(for: preset.id)

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
  func clearCurrentPreset() {
    currentPreset = nil
  }

  @MainActor
  func updateCurrentPresetState() {
    if isInitializing { return }

    guard let preset = currentPreset else {
      if !isInitializing {
        print("❌ PresetManager: No current preset to update")
      }
      return
    }

    let (newStates, currentSoundOrder) = generateUpdatedPresetData(for: preset)
    updatePresetIfChanged(
      preset: preset, newStates: newStates, currentSoundOrder: currentSoundOrder)
  }

  private func generateUpdatedPresetData(for preset: Preset) -> ([PresetState], [String]) {
    // Get the file names of sounds that should be in this preset
    let presetSoundFileNames = Set(preset.soundStates.map(\.fileName))

    // Only include sounds that are part of this preset
    let newStates = AudioManager.shared.sounds
      .filter { presetSoundFileNames.contains($0.fileName) }
      .map { sound in
        PresetState(
          fileName: sound.fileName,
          isSelected: sound.isSelected,
          volume: sound.volume
        )
      }

    // Only include sound order for sounds in this preset
    let currentSoundOrder = AudioManager.shared.sounds
      .filter { presetSoundFileNames.contains($0.fileName) }
      .sorted { $0.customOrder < $1.customOrder }
      .map(\.fileName)

    return (newStates, currentSoundOrder)
  }

  @MainActor private func updatePresetIfChanged(
    preset: Preset, newStates: [PresetState], currentSoundOrder: [String]
  ) {
    let orderChanged = preset.soundOrder != currentSoundOrder
    if preset.soundStates != newStates || orderChanged {
      var updatedPreset = preset
      updatedPreset.soundStates = newStates
      updatedPreset.soundOrder = currentSoundOrder
      updatedPreset.lastModifiedVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

      if let index = presets.firstIndex(where: { $0.id == preset.id }) {
        presets[index] = updatedPreset
        currentPreset = updatedPreset
        savePresets()
      }
    }
  }

  @MainActor
  func applyPreset(_ preset: Preset, isInitialLoad: Bool = false, forceReapply: Bool = false) throws
  {
    logPresetApplication(preset)

    guard preset.validate() else {
      throw PresetError.invalidPreset
    }

    if preset.id == currentPreset?.id && !isInitialLoad && !forceReapply {
      handleAlreadyActivePreset(preset)
      return
    }

    preparePresetApplication(preset)
    executePresetApplication(preset: preset, isInitialLoad: isInitialLoad)

    print("🎛️ PresetManager: --- End Apply Preset ---\n")
  }

  /// Remove deleted custom sounds from all presets
  @MainActor
  func cleanupDeletedCustomSounds() {
    print("🎛️ PresetManager: Cleaning up deleted custom sounds from presets")

    // Get current valid sound file names
    let validSoundFileNames = Set(AudioManager.shared.sounds.map(\.fileName))

    // Update each preset to remove invalid sound states
    for (index, preset) in presets.enumerated() {
      let validSoundStates = preset.soundStates.filter { soundState in
        validSoundFileNames.contains(soundState.fileName)
      }

      // Only update if there were changes
      if validSoundStates.count != preset.soundStates.count {
        var updatedPreset = preset
        updatedPreset.soundStates = validSoundStates
        presets[index] = updatedPreset

        // Update current preset if needed
        if currentPreset?.id == preset.id {
          currentPreset = updatedPreset
        }

        print(
          "🎛️ PresetManager: Removed \(preset.soundStates.count - validSoundStates.count) deleted sounds from preset '\(preset.name)'"
        )
      }
    }

    // Save the cleaned up presets
    savePresets()
  }

}
