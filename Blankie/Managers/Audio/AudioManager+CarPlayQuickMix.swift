//
//  AudioManager+CarPlayQuickMix.swift
//  Blankie
//
//  Created by Cody Bromley on 6/7/25.
//

import Foundation

extension AudioManager {
  // MARK: - CarPlay Quick Mix Mode

  @MainActor
  func enterCarPlayQuickMix(with initialSounds: [Sound] = []) {
    print("🚗 AudioManager: Entering CarPlay Quick Mix mode")

    // Exit solo mode if active
    if soloModeSound != nil {
      exitSoloModeWithoutResuming()
    }

    // Clear any current preset
    PresetManager.shared.clearCurrentPreset()

    // Save original states of all sounds
    carPlayQuickMixOriginalStates = sounds.map { sound in
      QuickMixState(sound: sound, isSelected: sound.isSelected, volume: sound.volume)
    }

    // Pause all sounds first
    for sound in sounds {
      sound.pause()
      sound.isSelected = false
    }

    // Set CarPlay Quick Mix mode
    isCarPlayQuickMix = true

    // Enable only the initial sounds (if any)
    for sound in initialSounds {
      sound.isSelected = true
      sound.play()
    }

    // Update playback state
    let hasActiveSounds = sounds.contains { $0.isSelected && $0.player?.isPlaying == true }
    setGlobalPlaybackState(hasActiveSounds)

    // Update Now Playing info
    nowPlayingManager.updateInfo(
      presetName: "Quick Mix (CarPlay)",
      isPlaying: hasActiveSounds
    )
  }

  @MainActor
  func exitCarPlayQuickMix() {
    guard isCarPlayQuickMix else { return }
    print("🚗 AudioManager: Exiting CarPlay Quick Mix mode")

    // Pause all current sounds
    for sound in sounds {
      sound.pause()
    }

    // Restore original states
    for state in carPlayQuickMixOriginalStates {
      state.sound.isSelected = state.isSelected
      state.sound.volume = state.volume

      // Resume playing if it was selected before
      if state.isSelected && isGloballyPlaying {
        state.sound.play()
      }
    }

    // Clear the saved states
    carPlayQuickMixOriginalStates = []

    // Exit CarPlay Quick Mix mode
    isCarPlayQuickMix = false

    // Update Now Playing info with full preset details
    let currentPreset = PresetManager.shared.currentPreset
    nowPlayingManager.updateInfo(
      presetName: currentPreset?.name,
      creatorName: currentPreset?.creatorName,
      artworkData: currentPreset?.artworkData,
      isPlaying: isGloballyPlaying
    )
  }

  @MainActor
  func toggleCarPlayQuickMixSound(_ sound: Sound) {
    guard isCarPlayQuickMix else { return }

    if sound.isSelected {
      sound.isSelected = false
      sound.pause()
    } else {
      sound.isSelected = true
      sound.play()
    }

    // Update playback state
    let hasActiveSounds = sounds.contains { $0.isSelected && $0.player?.isPlaying == true }
    setGlobalPlaybackState(hasActiveSounds)

    // Update Now Playing info
    nowPlayingManager.updateInfo(
      presetName: "Quick Mix (CarPlay)",
      isPlaying: hasActiveSounds
    )
  }
}
