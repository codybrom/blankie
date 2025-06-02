//
//  AudioManager+SoloMode.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import Foundation

extension AudioManager {
  // MARK: - Solo Mode

  @MainActor
  func toggleSoloMode(for sound: Sound) {
    if soloModeSound?.id == sound.id {
      // Exit solo mode
      exitSoloMode()
    } else {
      // Enter solo mode
      enterSoloMode(for: sound)
    }
  }

  @MainActor
  func enterSoloMode(for sound: Sound) {
    print("🎵 AudioManager: Entering solo mode for '\(sound.title)'")

    // Save original state before modifying
    soloModeOriginalVolume = sound.volume
    soloModeOriginalSelection = sound.isSelected

    // Pause all currently playing sounds first
    pauseAll()

    // Set solo mode
    soloModeSound = sound

    // Set the sound to full volume for solo mode
    sound.volume = 1.0

    // Temporarily mark the sound as selected for solo mode playback
    sound.isSelected = true

    // Ensure the sound is loaded
    if sound.player == nil {
      sound.loadSound()
    }

    // Always ensure we're playing in solo mode
    setGlobalPlaybackState(true)

    // Small delay to ensure audio session is ready after pause
    Task {
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second
      playSelected()
    }

    // Update Now Playing info immediately
    nowPlayingManager.updateInfo(
      presetName: sound.title,
      isPlaying: true
    )
  }

  @MainActor
  func exitSoloMode() {
    guard let soloSound = soloModeSound else { return }
    print("🎵 AudioManager: Exiting solo mode for '\(soloSound.title)'")
    print("🎵 AudioManager: Global playing state: \(isGloballyPlaying)")

    // Always pause the solo sound first
    print("🎵 AudioManager: Pausing all sounds before restoring state")
    pauseAll()

    // Restore original state
    if let originalVolume = soloModeOriginalVolume {
      print("🎵 AudioManager: Restoring original volume: \(originalVolume)")
      soloSound.volume = originalVolume
      soloModeOriginalVolume = nil
    }

    if let originalSelection = soloModeOriginalSelection {
      print("🎵 AudioManager: Restoring original selection: \(originalSelection)")
      soloSound.isSelected = originalSelection
      soloModeOriginalSelection = nil
    }

    // Clear solo mode
    soloModeSound = nil

    // Restore normal playback only if global playback is enabled
    if isGloballyPlaying {
      print("🎵 AudioManager: Global playback is enabled, playing selected sounds")
      playSelected()  // This will play according to the preset's actual state
    } else {
      print("🎵 AudioManager: Global playback is paused, keeping all sounds paused")
    }

    // Update Now Playing info
    nowPlayingManager.updateInfo(
      presetName: PresetManager.shared.currentPreset?.name,
      isPlaying: isGloballyPlaying
    )

    print("🎵 AudioManager: Exit solo mode complete")
  }
}
