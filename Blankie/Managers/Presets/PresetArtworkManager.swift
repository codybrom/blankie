//
//  PresetArtworkManager.swift
//  Blankie
//
//  Created by Cody Bromley on 6/14/25.
//

import Foundation
import SwiftData
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// Platform-specific image type
#if canImport(UIKit)
  typealias PlatformImage = UIImage
#else
  typealias PlatformImage = NSImage
#endif

@MainActor
class PresetArtworkManager: ObservableObject {
  static let shared = PresetArtworkManager()

  private var modelContext: ModelContext?
  private var imageCache: [UUID: PlatformImage] = [:]

  private init() {}

  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  /// Synchronously load background image from cache
  func loadBackgroundImage(for preset: Preset) -> PlatformImage? {
    let imageId: UUID?

    if preset.useArtworkAsBackground ?? false {
      imageId = preset.artworkId
    } else {
      imageId = preset.backgroundImageId
    }

    guard let id = imageId else { return nil }

    // Return from cache if available
    return imageCache[id]
  }

  /// Cache an image
  func cacheImage(_ image: PlatformImage, for id: UUID) {
    imageCache[id] = image
  }

  /// Save artwork for a preset
  func saveArtwork(_ imageData: Data, for presetId: UUID) async throws -> UUID {
    guard let context = modelContext else {
      throw PresetArtworkError.noModelContext
    }

    // Check if artwork already exists for this preset
    let descriptor = FetchDescriptor<PresetArtwork>(
      predicate: #Predicate { $0.presetId == presetId }
    )

    if let existingArtwork = try context.fetch(descriptor).first {
      // Update existing artwork
      existingArtwork.imageData = imageData
      existingArtwork.updatedAt = Date()
      try context.save()
      print("📸 PresetArtworkManager: Updated artwork for preset \(presetId)")
      return existingArtwork.id
    } else {
      // Create new artwork
      let artwork = PresetArtwork(presetId: presetId, imageData: imageData)
      context.insert(artwork)
      try context.save()
      print("📸 PresetArtworkManager: Saved new artwork for preset \(presetId)")
      return artwork.id
    }
  }

  /// Load artwork by ID
  func loadArtwork(id: UUID) async -> PlatformImage? {
    // Check cache first
    if let cached = imageCache[id] {
      return cached
    }

    guard let context = modelContext else {
      print("❌ PresetArtworkManager: No model context")
      return nil
    }

    let descriptor = FetchDescriptor<PresetArtwork>(
      predicate: #Predicate { $0.id == id }
    )

    do {
      let results = try context.fetch(descriptor)
      if let imageData = results.first?.imageData,
        let image = PlatformImage(data: imageData)
      {
        // Cache the image
        imageCache[id] = image
        return image
      }
    } catch {
      print("❌ PresetArtworkManager: Failed to load artwork: \(error)")
    }

    return nil
  }

  /// Load artwork for a preset
  func loadArtwork(for presetId: UUID) async throws -> Data? {
    guard let context = modelContext else {
      throw PresetArtworkError.noModelContext
    }

    let descriptor = FetchDescriptor<PresetArtwork>(
      predicate: #Predicate { $0.presetId == presetId }
    )

    let results = try context.fetch(descriptor)
    return results.first?.imageData
  }

  /// Delete artwork for a preset
  func deleteArtwork(for presetId: UUID) async throws {
    guard let context = modelContext else {
      throw PresetArtworkError.noModelContext
    }

    let descriptor = FetchDescriptor<PresetArtwork>(
      predicate: #Predicate { $0.presetId == presetId }
    )

    if let artwork = try context.fetch(descriptor).first {
      context.delete(artwork)
      try context.save()
      print("📸 PresetArtworkManager: Deleted artwork for preset \(presetId)")
    }
  }

  /// Clean up orphaned artwork (not referenced by any preset)
  func cleanupOrphanedArtwork() async throws {
    guard modelContext != nil else {
      throw PresetArtworkError.noModelContext
    }

    // This would require fetching all presets and comparing
    // For now, we'll skip this implementation
    print("📸 PresetArtworkManager: Cleanup not yet implemented")
  }
}

enum PresetArtworkError: LocalizedError {
  case noModelContext
  case artworkNotFound

  var errorDescription: String? {
    switch self {
    case .noModelContext:
      return "Model context not initialized"
    case .artworkNotFound:
      return "Artwork not found"
    }
  }
}
