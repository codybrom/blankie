//
//  CustomSoundManager.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import AVFoundation
import Foundation
import SwiftData
import SwiftUI

/// Manager responsible for importing, storing, and retrieving custom sounds
class CustomSoundManager {
  static let shared = CustomSoundManager()

  let customSoundsDirectory = "CustomSounds"
  private var modelContext: ModelContext?

  private init() {
    setupCustomSoundsDirectory()
  }

  // MARK: - Setup

  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  private func setupCustomSoundsDirectory() {
    guard let directoryURL = getCustomSoundsDirectoryURL() else { return }

    if !FileManager.default.fileExists(atPath: directoryURL.path) {
      do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        print("📂 CustomSoundManager: Created custom sounds directory at \(directoryURL.path)")
      } catch {
        print("❌ CustomSoundManager: Failed to create custom sounds directory: \(error)")
        ErrorReporter.shared.report(error)
      }
    }
  }

  // MARK: - Sound Import

  /// Import a sound file into the app's storage and add it to the database
  /// - Parameters:
  ///   - sourceURL: URL of the sound file to import
  ///   - title: Display name for the sound
  ///   - iconName: SF Symbol name to use for the sound
  ///   - randomizeStartPosition: Whether to randomize the start position when playing
  /// - Returns: A Result with the created CustomSoundData or an error
  @MainActor
  func importSound(
    from sourceURL: URL, title: String, iconName: String, randomizeStartPosition: Bool = true
  ) async -> Result<
    CustomSoundData, CustomSoundError
  > {
    let uniqueFileName = UUID().uuidString
    let fileExtension = sourceURL.pathExtension.lowercased()

    guard isSupportedAudioFormat(fileExtension) else {
      return .failure(CustomSoundError.unsupportedFormat)
    }

    do {
      try await validateImportableAudioFile(at: sourceURL)
      let copiedURL = try copyFileForImport(
        sourceURL, uniqueFileName: uniqueFileName, fileExtension: fileExtension)
      let importData = SoundImportData(
        sourceURL: sourceURL, copiedURL: copiedURL, title: title, iconName: iconName,
        uniqueFileName: uniqueFileName, fileExtension: fileExtension,
        randomizeStartPosition: randomizeStartPosition
      )
      let customSound = try await createCustomSoundRecord(from: importData)
      try saveCustomSoundToDatabase(customSound)

      NotificationCenter.default.post(name: .customSoundAdded, object: nil)
      return .success(customSound)
    } catch {
      print("❌ CustomSoundManager: Failed to import sound: \(error)")
      return .failure(.invalidAudioFile(error))
    }
  }

  private func validateImportableAudioFile(at sourceURL: URL) async throws {
    let validationResult = try await validateAudioFile(at: sourceURL)
    if case .failure(let error) = validationResult {
      throw (error as? CustomSoundError) ?? CustomSoundError.invalidAudioFile(error)
    }
  }

  private func copyFileForImport(_ sourceURL: URL, uniqueFileName: String, fileExtension: String)
    throws -> URL
  {
    guard
      let copiedURL = try copyToCustomSoundsDirectory(
        source: sourceURL, filename: uniqueFileName, extension: fileExtension
      )
    else {
      throw CustomSoundError.fileCopyFailed
    }
    return copiedURL
  }

  @MainActor
  private func createCustomSoundRecord(from importData: SoundImportData) async throws
    -> CustomSoundData
  {
    let analysis = await AudioAnalyzer.comprehensiveAnalysis(at: importData.copiedURL)
    let lufsResult =
      analysis.lufs != nil
      ? (lufs: analysis.lufs!, normalizationFactor: analysis.normalizationFactor) : nil

    // Create and store playback profile for efficient runtime use
    if let profile = PlaybackProfile.from(analysis: analysis, filename: importData.uniqueFileName) {
      PlaybackProfileStore.shared.store(profile)
      print("💾 CustomSoundManager: Stored playback profile for \(importData.uniqueFileName)")
    }

    return CustomSoundData(
      title: importData.title, systemIconName: importData.iconName,
      fileName: importData.uniqueFileName,
      fileExtension: importData.fileExtension,
      originalFileName: importData.sourceURL.lastPathComponent,
      randomizeStartPosition: importData.randomizeStartPosition,
      normalizeAudio: true, volumeAdjustment: 1.0, detectedPeakLevel: analysis.peakLevel,
      detectedLUFS: lufsResult?.lufs, normalizationFactor: lufsResult?.normalizationFactor
    )
  }

  @MainActor
  private func saveCustomSoundToDatabase(_ customSound: CustomSoundData) throws {
    guard let modelContext = self.modelContext else {
      throw CustomSoundError.databaseError
    }
    modelContext.insert(customSound)
    try modelContext.save()
  }

  private func copyToCustomSoundsDirectory(source: URL, filename: String, extension ext: String)
    throws -> URL?
  {
    guard let directoryURL = getCustomSoundsDirectoryURL() else {
      return nil
    }

    // Ensure we have access to the security-scoped resource
    let didStartAccess = source.startAccessingSecurityScopedResource()
    defer {
      if didStartAccess {
        source.stopAccessingSecurityScopedResource()
      }
    }

    let destinationURL = directoryURL.appendingPathComponent("\(filename).\(ext)")

    do {
      // Read the source file data instead of directly copying the file
      let data = try Data(contentsOf: source)
      try data.write(to: destinationURL)
      print("📂 CustomSoundManager: Successfully copied file to \(destinationURL.path)")
      return destinationURL
    } catch {
      print("❌ CustomSoundManager: Failed to copy file: \(error.localizedDescription)")
      throw error
    }
  }

  // MARK: - Sound Retrieval

  /// Get all custom sounds
  /// - Returns: Array of CustomSoundData objects
  @MainActor
  func getAllCustomSounds() -> [CustomSoundData] {
    guard let modelContext = modelContext else {
      return []
    }

    do {
      let descriptor = FetchDescriptor<CustomSoundData>(sortBy: [SortDescriptor(\.dateAdded)])
      return try modelContext.fetch(descriptor)
    } catch {
      print("❌ CustomSoundManager: Failed to fetch custom sounds: \(error)")
      return []
    }
  }

  // MARK: - Sound Retrieval

  /// Get a custom sound by its ID
  /// - Parameter id: The UUID of the custom sound
  /// - Returns: The CustomSoundData if found
  @MainActor
  func getCustomSound(by id: UUID) -> CustomSoundData? {
    guard let modelContext = modelContext else { return nil }

    let descriptor = FetchDescriptor<CustomSoundData>(
      predicate: #Predicate { $0.id == id }
    )

    do {
      let results = try modelContext.fetch(descriptor)
      return results.first
    } catch {
      print("❌ CustomSoundManager: Failed to fetch custom sound by ID: \(error)")
      return nil
    }
  }

  // MARK: - Sound Deletion

  /// Delete a custom sound
  /// - Parameter customSound: The CustomSoundData to delete
  /// - Returns: Result indicating success or failure
  @MainActor
  func deleteCustomSound(_ customSound: CustomSoundData) -> Result<Void, Error> {
    guard let modelContext = modelContext else {
      return .failure(CustomSoundError.databaseError)
    }

    do {
      // Delete the file
      if let soundURL = getURLForCustomSound(customSound) {
        try FileManager.default.removeItem(at: soundURL)
      }

      // Delete from database
      modelContext.delete(customSound)
      try modelContext.save()

      // Notify audio manager
      NotificationCenter.default.post(name: .customSoundDeleted, object: nil)

      return .success(())
    } catch {
      print("❌ CustomSoundManager: Failed to delete custom sound: \(error)")
      return .failure(error)
    }
  }

  // MARK: - Save Context

  @MainActor
  func saveContext() throws {
    try modelContext?.save()
  }
}

// MARK: - Errors

enum CustomSoundError: Error, LocalizedError, Sendable {
  case unsupportedFormat
  case fileCopyFailed
  case fileTooLarge
  case durationTooLong
  case invalidAudioFile(Error)
  case databaseError

  var errorDescription: String? {
    switch self {
    case .unsupportedFormat:
      return "Unsupported audio format. Please use WAV, MP3, M4A, AAC, or AIFF files."
    case .fileCopyFailed:
      return "Failed to copy the audio file."
    case .fileTooLarge:
      return "Audio file is too large. Maximum size is 50MB."
    case .durationTooLong:
      return "Audio file is too long. Maximum duration is 120 minutes."
    case .invalidAudioFile(let error):
      return "Invalid audio file: \(error.localizedDescription)"
    case .databaseError:
      return "Failed to access the database."
    }
  }
}

// MARK: - Notification Extensions

extension Notification.Name {
  static let customSoundAdded = Notification.Name("customSoundAdded")
  static let customSoundDeleted = Notification.Name("customSoundDeleted")
}
