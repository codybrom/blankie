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

    // Check if the sound was already playing
    let wasPlaying = sound.isSelected && isGloballyPlaying

    // Save original state before modifying
    soloModeOriginalVolume = sound.volume
    soloModeOriginalSelection = sound.isSelected

    // Pause all OTHER sounds (not the one we're soloing)
    for otherSound in sounds where otherSound.id != sound.id {
      otherSound.pause()
    }

    // Set solo mode
    soloModeSound = sound

    // Save to persistent storage
    GlobalSettings.shared.saveSoloModeSound(fileName: sound.fileName)

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

    // If the sound was already playing, keep it playing
    // Otherwise start it
    if wasPlaying {
      // Sound should already be playing, just ensure volume is updated
      sound.updateVolume()
    } else {
      // Start playing the solo sound
      sound.play()
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

    // Check if we should keep playing after exiting solo mode
    let shouldKeepPlaying = isGloballyPlaying

    // Save the original selection state before clearing it
    let wasOriginallySelected = soloModeOriginalSelection ?? false

    // Check if the solo sound should continue playing after exit
    let soloShouldContinuePlaying = wasOriginallySelected && shouldKeepPlaying

    // Only pause the solo sound if it shouldn't continue playing
    if !soloShouldContinuePlaying {
      print("🎵 AudioManager: Pausing solo sound")
      soloSound.pause()
    } else {
      print("🎵 AudioManager: Solo sound will continue playing in normal mode")
    }

    // Restore original state
    if let originalVolume = soloModeOriginalVolume {
      print("🎵 AudioManager: Restoring original volume: \(originalVolume)")
      soloSound.volume = originalVolume
      soloModeOriginalVolume = nil
      // Update volume if sound is still playing
      if soloShouldContinuePlaying {
        soloSound.updateVolume()
      }
    }

    if let originalSelection = soloModeOriginalSelection {
      print("🎵 AudioManager: Restoring original selection: \(originalSelection)")
      soloSound.isSelected = originalSelection
      soloModeOriginalSelection = nil
    }

    // Clear solo mode
    soloModeSound = nil

    // Clear from persistent storage
    GlobalSettings.shared.saveSoloModeSound(fileName: nil)

    // Restore normal playback if we were playing
    if shouldKeepPlaying {
      print("🎵 AudioManager: Restoring playback for selected sounds")
      // Play all sounds that should be playing according to the preset
      for sound in sounds where sound.isSelected {
        // Skip the solo sound since it's already playing if it should be
        if sound.id == soloSound.id && soloShouldContinuePlaying {
          continue
        }
        sound.play()
      }
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
