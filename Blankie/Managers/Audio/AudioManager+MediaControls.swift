//
//  AudioManager+MediaControls.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import MediaPlayer
import SwiftUI

// MARK: - Media Controls
extension AudioManager {
  func setupMediaControls() {
    print("🎵 AudioManager: Setting up media controls")

    let commandCenter = MPRemoteCommandCenter.shared()

    // Enable the commands
    commandCenter.playCommand.isEnabled = true
    commandCenter.pauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.isEnabled = true

    // Remove all previous handlers
    commandCenter.playCommand.removeTarget(nil)
    commandCenter.pauseCommand.removeTarget(nil)
    commandCenter.togglePlayPauseCommand.removeTarget(nil)

    // Add handlers
    commandCenter.playCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key play command received")
      Task { @MainActor in
        // Only play if we're currently paused
        if !(self?.isGloballyPlaying ?? false) {
          self?.setGlobalPlaybackState(true)
        }
      }
      return .success
    }
    commandCenter.pauseCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key pause command received")
      Task { @MainActor in
        // Only pause if we're currently playing
        if self?.isGloballyPlaying ?? false {
          self?.setGlobalPlaybackState(false)
        }
      }
      return .success
    }
    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key toggle command received")
      Task { @MainActor in
        self?.togglePlayback()
      }
      return .success
    }
  }
}
