//
//  CustomSoundManager+Metadata.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import AVFoundation
import Foundation

// MARK: - ID3 Metadata Extraction

extension CustomSoundManager {
  struct AudioMetadata {
    var title: String?
    var artist: String?
    var album: String?
    var comment: String?
    var url: String?
  }

  /// Extract comprehensive metadata from audio file including ID3 tags
  func extractAudioMetadata(from url: URL) async -> AudioMetadata {
    var metadata = AudioMetadata()

    do {
      let asset = AVURLAsset(url: url)

      // Load common metadata which includes ID3 tags
      let commonMetadata = try await asset.load(.commonMetadata)

      // Process each metadata item
      for item in commonMetadata {
        guard let key = item.commonKey else { continue }

        // Try to load the value
        if let value = try? await item.load(.value) {
          switch key {
          case .commonKeyTitle:
            metadata.title = extractStringValue(from: value)

          case .commonKeyArtist:
            metadata.artist = extractStringValue(from: value)

          case .commonKeyAlbumName:
            metadata.album = extractStringValue(from: value)

          case .commonKeyDescription:
            // Description often contains comments or additional info
            metadata.comment = extractStringValue(from: value)

          default:
            // Check for URL in other metadata fields
            if let urlString = extractStringValue(from: value),
              urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
            {
              metadata.url = urlString
            }
          }
        }
      }

      // Also check for format-specific metadata (ID3v2, iTunes metadata, etc.)
      let formatMetadata = try await asset.load(.metadata)
      for item in formatMetadata {
        // Look for additional URL fields
        if let identifier = item.identifier {
          let idString = identifier.rawValue

          // Common URL-related ID3 tags
          if idString.contains("WOAR")  // Official artist/performer webpage
            || idString.contains("WOAF")  // Official audio file webpage
            || idString.contains("WOAS")  // Official audio source webpage
            || idString.contains("WORS")  // Official internet radio station homepage
            || idString.contains("WPUB")  // Publisher's official webpage
            || idString.contains("WXXX")
          {  // User defined URL link

            if let urlValue = try? await item.load(.value),
              let urlString = extractStringValue(from: urlValue),
              metadata.url == nil
            {
              metadata.url = urlString
            }
          }

          // Also check for comment fields
          if idString.contains("COMM") || idString.contains("comment"),
            metadata.comment == nil
          {
            if let commentValue = try? await item.load(.value) {
              metadata.comment = extractStringValue(from: commentValue)
            }
          }
        }
      }

      print("🎵 CustomSoundManager: Extracted metadata:")
      print("   Title: \(metadata.title ?? "none")")
      print("   Artist: \(metadata.artist ?? "none")")
      print("   Album: \(metadata.album ?? "none")")
      print("   Comment: \(metadata.comment ?? "none")")
      print("   URL: \(metadata.url ?? "none")")

    } catch {
      print("⚠️ CustomSoundManager: Failed to extract metadata: \(error)")
    }

    return metadata
  }

  private func extractStringValue(from value: Any) -> String? {
    if let stringValue = value as? String {
      let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    } else if let data = value as? Data,
      let stringValue = String(data: data, encoding: .utf8)
    {
      let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    return nil
  }
}
