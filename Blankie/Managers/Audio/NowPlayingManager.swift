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

    if let artwork = loadArtwork() {
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }
  }

  func updateInfo(
    presetName: String? = nil, creatorName: String? = nil, artworkData: Data? = nil, isPlaying: Bool
  ) {
    setupNowPlaying()  // Ensure setup is done before updating

    // Get the current preset name for the title
    let displayInfo = getDisplayInfo(presetName: presetName, creatorName: creatorName)

    print(
      "🎵 NowPlayingManager: Updating Now Playing info with title: \(displayInfo.title), artist: \(displayInfo.artist)"
    )

    nowPlayingInfo[MPMediaItemPropertyTitle] = displayInfo.title
    nowPlayingInfo[MPMediaItemPropertyArtist] = displayInfo.artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Blankie"
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

    // Use custom artwork if available, otherwise fall back to default
    print(
      "🎨 NowPlayingManager: Processing artwork data: \(artworkData != nil ? "✅ \(artworkData!.count) bytes" : "❌ None")"
    )
    if let customArtwork = loadCustomArtwork(from: artworkData) {
      print("🎨 NowPlayingManager: ✅ Custom artwork loaded successfully")
      nowPlayingInfo[MPMediaItemPropertyArtwork] = customArtwork
    } else if let defaultArtwork = loadArtwork() {
      print("🎨 NowPlayingManager: Using default artwork")
      nowPlayingInfo[MPMediaItemPropertyArtwork] = defaultArtwork
    } else {
      print("🎨 NowPlayingManager: ❌ No artwork available")
    }

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
