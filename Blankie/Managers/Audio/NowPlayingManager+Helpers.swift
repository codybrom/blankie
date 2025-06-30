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
      // Check if the sound has a creator/credited author
      let artist: String
      if let author = SoundCreditsManager.shared.getAuthor(for: soloSound.title),
        !author.isEmpty
      {
        artist = "Sound by \(author)"
      } else {
        artist = "Blankie"
      }
      return (title: soloSound.title, artist: artist)
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
      return "Mixed by \(creator)"
    }

    // Otherwise show active sounds
    let activeSounds = AudioManager.shared.sounds.filter { $0.isSelected }
    if !activeSounds.isEmpty {
      let soundNames = activeSounds.map { $0.title }.joined(separator: ", ")
      return soundNames
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
