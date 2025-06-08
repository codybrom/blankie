//
//  NowPlayingManager.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import AVFoundation
import MediaPlayer
import SwiftUI

/// Manages Now Playing info for media playback controls
final class NowPlayingManager {
  private var nowPlayingInfo: [String: Any] = [:]

  private var isSetup = false

  init() {
    // Don't setup immediately to avoid triggering audio session
  }

  private func setupNowPlaying() {
    guard !isSetup else { return }
    print("🎵 NowPlayingManager: Setting up Now Playing info")
    isSetup = true

    nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
    nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0  // Start as paused

    #if os(iOS) || os(visionOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = UIImage(data: imageData)
      {
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      }
    #elseif os(macOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = NSImage(data: imageData)
      {
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      }
    #endif
  }

  func updateInfo(presetName: String? = nil, isPlaying: Bool) {
    setupNowPlaying()  // Ensure setup is done before updating

    // Get the current preset name for the title
    let displayTitle: String
    let artistInfo: String

    // Check if we're in solo mode
    if let soloSound = AudioManager.shared.soloModeSound {
      displayTitle = soloSound.title
      artistInfo = "Solo Mode • Blankie"
    } else if let name = presetName {
      // Handle special presets
      if name == "Quick Mix (CarPlay)" {
        displayTitle = "Quick Mix"
      } else if name != "Default" && !name.starts(with: "Preset ") {
        displayTitle = name
      } else {
        displayTitle = "Custom Mix"
      }

      // Get active sounds for artist field
      let activeSounds = AudioManager.shared.sounds.filter { $0.player?.isPlaying == true }
      if !activeSounds.isEmpty {
        let soundNames = activeSounds.prefix(3).map { $0.title }.joined(separator: " + ")
        if activeSounds.count > 3 {
          artistInfo = "\(soundNames) +\(activeSounds.count - 3)"
        } else {
          artistInfo = soundNames
        }
      } else {
        artistInfo = "Blankie"
      }
    } else {
      displayTitle = "Custom Mix"

      // Get active sounds for artist field
      let activeSounds = AudioManager.shared.sounds.filter { $0.player?.isPlaying == true }
      if !activeSounds.isEmpty {
        let soundNames = activeSounds.prefix(3).map { $0.title }.joined(separator: " + ")
        if activeSounds.count > 3 {
          artistInfo = "\(soundNames) +\(activeSounds.count - 3)"
        } else {
          artistInfo = soundNames
        }
      } else {
        artistInfo = "Blankie"
      }
    }

    print(
      "🎵 NowPlayingManager: Updating Now Playing info with title: \(displayTitle), artist: \(artistInfo)"
    )

    nowPlayingInfo[MPMediaItemPropertyTitle] = displayTitle
    nowPlayingInfo[MPMediaItemPropertyArtist] = artistInfo
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Blankie"
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

    #if os(iOS) || os(visionOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = UIImage(data: imageData)
      {
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      }
    #elseif os(macOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = NSImage(data: imageData)
      {
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
      }
    #endif

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func updatePlaybackState(isPlaying: Bool) {
    setupNowPlaying()  // Ensure setup is done before updating

    // Ensure nowPlayingInfo dictionary exists
    if nowPlayingInfo.isEmpty {
      // Recreate basic info if needed
      nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
      nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"
    }

    // Update playback state
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0  // Infinite for ambient sounds

    // Update the now playing info
    print(
      "🎵 NowPlayingManager: Updating now playing state to \(isPlaying), playbackRate: \(nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? -1)"
    )
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  func clear() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
}
