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

    // Restore original state
    if let originalVolume = soloModeOriginalVolume {
      soloSound.volume = originalVolume
      soloModeOriginalVolume = nil
    }

    if let originalSelection = soloModeOriginalSelection {
      soloSound.isSelected = originalSelection
      soloModeOriginalSelection = nil
    }

    // Clear solo mode
    soloModeSound = nil

    // Restore normal playback (playing the sounds that were selected in the preset)
    if isGloballyPlaying {
      pauseAll()
      playSelected()  // This will play according to the preset's actual state
    }

    // Update Now Playing info
    nowPlayingManager.updateInfo(
      presetName: PresetManager.shared.currentPreset?.name,
      isPlaying: isGloballyPlaying
    )
  }
}
