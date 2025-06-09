//
//  NowPlayingManager+Helpers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import AVFoundation
import MediaPlayer
import SwiftUI

extension NowPlayingManager {

  func getDisplayInfo(presetName: String?, creatorName: String? = nil) -> (
    title: String, artist: String
  ) {
    // Check if we're in solo mode
    if let soloSound = AudioManager.shared.soloModeSound {
      return (title: soloSound.title, artist: "Solo Mode • Blankie")
    } else if let name = presetName {
      // Handle special presets
      let displayTitle: String
      if name == "Quick Mix (CarPlay)" {
        displayTitle = "Quick Mix"
      } else if name != "Default" && !name.starts(with: "Preset ") {
        displayTitle = name
      } else {
        displayTitle = "Custom Mix"
      }

      let artistInfo = getArtistInfo(creatorName: creatorName)
      return (title: displayTitle, artist: artistInfo)
    } else {
      let artistInfo = getArtistInfo(creatorName: creatorName)
      return (title: "Custom Mix", artist: artistInfo)
    }
  }

  private func getArtistInfo(creatorName: String? = nil) -> String {
    // If creator name is provided, show it first
    if let creator = creatorName {
      return "by \(creator) • Blankie"
    }

    // Otherwise show active sounds
    let activeSounds = AudioManager.shared.sounds.filter { $0.player?.isPlaying == true }
    if !activeSounds.isEmpty {
      let soundNames = activeSounds.prefix(3).map { $0.title }.joined(separator: " + ")
      if activeSounds.count > 3 {
        return "\(soundNames) +\(activeSounds.count - 3)"
      } else {
        return soundNames
      }
    } else {
      return "Blankie"
    }
  }

  func loadCustomArtwork(from data: Data?) -> MPMediaItemArtwork? {
    guard let artworkData = data else { return nil }

    #if os(iOS) || os(visionOS)
    if let image = UIImage(data: artworkData) {
      return MPMediaItemArtwork(boundsSize: image.size) { _ in
        return image
      }
    }
    #elseif os(macOS)
    if let image = NSImage(data: artworkData) {
      return MPMediaItemArtwork(boundsSize: image.size) { _ in
        return image
      }
    }
    #endif
    return nil
  }

  func loadArtwork() -> MPMediaItemArtwork? {
    #if os(iOS) || os(visionOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = UIImage(data: imageData)
      {
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
      }
    #elseif os(macOS)
      if let imageUrl = Bundle.main.url(forResource: "NowPlaying", withExtension: "png"),
        let imageData = try? Data(contentsOf: imageUrl),
        let image = NSImage(data: imageData)
      {
        return MPMediaItemArtwork(boundsSize: image.size) { _ in
          return image
        }
      }
    #endif
    return nil
  }
}
