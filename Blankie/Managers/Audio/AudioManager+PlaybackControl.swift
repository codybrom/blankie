//
//  AudioManager+PlaybackControl.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import Foundation
import SwiftUI

extension AudioManager {
  /// Toggles the playback state of all selected sounds
  @MainActor func togglePlayback() {
    print("🎵 AudioManager: Toggling playback")
    print("  - Current state (pre-toggle): \(isGloballyPlaying)")
    setGlobalPlaybackState(!isGloballyPlaying)
    print("  - New state (post-toggle): \(isGloballyPlaying)")
  }

  @MainActor
  func resetSounds() {
    print("🎵 AudioManager: Resetting all sounds")

    // First pause all sounds immediately
    sounds.forEach { sound in
      print("  - Stopping '\(sound.fileName)'")
      sound.pause(immediate: true)
    }
    setGlobalPlaybackState(false)
    // Reset all sounds
    sounds.forEach { sound in
      sound.volume = 0.75
      sound.isSelected = false
    }
    // Reset "All Sounds" volume
    GlobalSettings.shared.setVolume(1.0)

    // Update hasSelectedSounds after resetting
    updateHasSelectedSounds()

    // Call the reset callback
    onReset?()
    print("🎵 AudioManager: Reset complete")
  }

  public func updateNowPlayingInfoForPreset(
    presetName: String? = nil, creatorName: String? = nil, artworkData: Data? = nil
  ) {
    nowPlayingManager.updateInfo(
      presetName: presetName,
      creatorName: creatorName,
      artworkData: artworkData,
      isPlaying: isGloballyPlaying
    )
  }

  func updateNowPlayingState() {
    nowPlayingManager.updatePlaybackState(isPlaying: isGloballyPlaying)
  }
}
