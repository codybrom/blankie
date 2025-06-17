//
//  PresetManager+Thumbnails.swift
//  Blankie
//
//  Created by Cody Bromley on 6/16/25.
//

import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

extension PresetManager {
  /// Cache a small thumbnail for quick access
  @MainActor
  func cacheThumbnail(for preset: Preset) async {
    let thumbnailKey = "preset_thumb_\(preset.id.uuidString)"

    // If preset has artwork, create a small thumbnail
    if let artworkId = preset.artworkId {
      if let image = await PresetArtworkManager.shared.loadArtwork(id: artworkId) {
        #if canImport(UIKit)
          // Create a 60x60 thumbnail
          if let thumbnail = resizeImage(image, to: CGSize(width: 60, height: 60)),
            let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
          {
            UserDefaults.standard.set(thumbnailData, forKey: thumbnailKey)
          }
        #endif
      }
    } else {
      // No artwork, remove any cached thumbnail
      UserDefaults.standard.removeObject(forKey: thumbnailKey)
    }
  }

  /// Cache thumbnails for all presets
  @MainActor
  func cacheAllThumbnails() async {
    for preset in presets {
      await cacheThumbnail(for: preset)
    }
  }

  /// Remove cached thumbnail when preset is deleted
  func removeThumbnail(for presetId: UUID) {
    let thumbnailKey = "preset_thumb_\(presetId.uuidString)"
    UserDefaults.standard.removeObject(forKey: thumbnailKey)
  }

  #if canImport(UIKit)
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
      defer { UIGraphicsEndImageContext() }
      image.draw(in: CGRect(origin: .zero, size: size))
      return UIGraphicsGetImageFromCurrentImageContext()
    }
  #endif
}
