//
//  AudioManager+PlaybackControl.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import AVFoundation
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

  func setPlaybackState(_ playing: Bool, forceUpdate: Bool = false) {
    Task { @MainActor [weak self] in
      guard let self = self else { return }

      guard !self.isInitializing || forceUpdate else {
        print("🎵 AudioManager: Ignoring setPlaybackState during initialization")
        return
      }

      if self.isGloballyPlaying != playing {
        print(
          "🎵 AudioManager: Setting playback state to \(playing) - Current global state: \(self.isGloballyPlaying)"
        )
        self.isGloballyPlaying = playing

        if playing {
          self.playSelected()
        } else {
          self.pauseAll()
        }
        let currentPreset = PresetManager.shared.currentPreset
        self.nowPlayingManager.updateInfo(
          presetName: currentPreset?.name,
          creatorName: currentPreset?.creatorName,
          artworkData: currentPreset?.artworkData,
          isPlaying: playing
        )
      } else {
        print("🎵 AudioManager: setPlaybackState called, but state is the same \(playing), ignoring")
      }
    }
  }

  func playSelected() {
    print("🎵 AudioManager: Playing selected sounds")
    guard isGloballyPlaying else {
      print("🎵 AudioManager: Not playing sounds because global playback is disabled")
      return
    }

    #if os(iOS) || os(visionOS)
      // Setup audio session when starting playback
      setupAudioSessionForPlayback()
      // Setup audio session observers on first playback
      setupAudioSessionObservers()
    #endif

    // If in solo mode, play only the solo sound
    if let soloSound = soloModeSound {
      print("  - In solo mode, playing only '\(soloSound.fileName)'")

      // Play the solo sound at its current volume
      soloSound.play()

      // Update Now Playing info for solo mode
      nowPlayingManager.updateInfo(
        presetName: soloSound.title,
        isPlaying: true
      )
      return
    }

    // Normal mode: play all selected sounds according to preset
    for sound in sounds where sound.isSelected {
      print(
        "  - About to play '\(sound.fileName)', isSelected: \(sound.isSelected), player exists: \(sound.player != nil)"
      )
      sound.play()
      print(
        "  - After play call for '\(sound.fileName)', player playing: \(sound.player?.isPlaying ?? false), volume: \(sound.player?.volume ?? 0)"
      )
    }

    // Update Now Playing info with full preset details
    let currentPreset = PresetManager.shared.currentPreset
    self.nowPlayingManager.updateInfo(
      presetName: currentPreset?.name,
      creatorName: currentPreset?.creatorName,
      artworkData: currentPreset?.artworkData,
      isPlaying: true
    )
  }

  func pauseAll() {
    print("🎵 AudioManager: Pausing all sounds")
    print("  - Current global play state: \(isGloballyPlaying)")

    sounds.forEach { sound in
      if sound.isSelected {
        print("  - Pausing '\(sound.fileName)'")
        sound.pause()
      }
    }

    #if os(iOS) || os(visionOS)
      // Deactivate audio session when stopping to allow other apps to play
      do {
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        print("🎵 AudioManager: Audio session deactivated")
      } catch {
        print("❌ AudioManager: Failed to deactivate audio session: \(error)")
      }
    #endif

    print("🎵 AudioManager: Pause all complete")
  }

  @MainActor
  public func setGlobalPlaybackState(_ playing: Bool, forceUpdate: Bool = false) {
    guard !isInitializing || forceUpdate else {
      print("🎵 AudioManager: Ignoring setPlaybackState during initialization")
      return
    }

    print(
      "🎵 AudioManager: Setting playback state to \(playing) - Current global state: \(self.isGloballyPlaying)"
    )

    // Update state first
    self.isGloballyPlaying = playing

    // Then handle playback
    if playing {
      self.playSelected()
    } else {
      self.pauseAll()
    }

    // Always update Now Playing info with full preset details
    if let soloSound = soloModeSound {
      // In solo mode, just show the sound title
      nowPlayingManager.updateInfo(
        presetName: soloSound.title,
        isPlaying: isGloballyPlaying
      )
    } else {
      // Normal mode - include full preset details
      let currentPreset = PresetManager.shared.currentPreset
      nowPlayingManager.updateInfo(
        presetName: currentPreset?.name,
        creatorName: currentPreset?.creatorName,
        artworkData: currentPreset?.artworkData,
        isPlaying: isGloballyPlaying
      )
    }
  }
}
