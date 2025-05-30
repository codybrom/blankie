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

  private let customSoundsDirectory = "CustomSounds"
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

  private func getCustomSoundsDirectoryURL() -> URL? {
    guard
      let documentsDirectory = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
      ).first
    else {
      print("❌ CustomSoundManager: Could not access documents directory")
      return nil
    }

    return documentsDirectory.appendingPathComponent(customSoundsDirectory)
  }

  // MARK: - Sound Import

  /// Import a sound file into the app's storage and add it to the database
  /// - Parameters:
  ///   - sourceURL: URL of the sound file to import
  ///   - title: Display name for the sound
  ///   - iconName: SF Symbol name to use for the sound
  /// - Returns: A Result with the created CustomSoundData or an error
  @Sendable
  func importSound(from sourceURL: URL, title: String, iconName: String) async -> Result<
    CustomSoundData, CustomSoundError
  > {
    // Generate a unique filename to prevent conflicts
    let uniqueFileName = UUID().uuidString
    let fileExtension = sourceURL.pathExtension.lowercased()

    // Verify the file is a supported audio format
    guard isSupportedAudioFormat(fileExtension) else {
      return .failure(CustomSoundError.unsupportedFormat)
    }

    do {
      // Validate audio file
      let validationResult = try await validateAudioFile(at: sourceURL)
      if case .failure(let error) = validationResult {
        switch error {
        case let customSoundError as CustomSoundError:
          return .failure(customSoundError)
        default:
          return .failure(.invalidAudioFile(error))
        }
      }

      // Copy file to app storage
      guard
        (try copyToCustomSoundsDirectory(
          source: sourceURL,
          filename: uniqueFileName,
          extension: fileExtension
        )) != nil
      else {
        return .failure(CustomSoundError.fileCopyFailed)
      }

      // Create database record
      let customSound = CustomSoundData(
        title: title,
        systemIconName: iconName,
        fileName: uniqueFileName,
        fileExtension: fileExtension,
        originalFileName: sourceURL.lastPathComponent
      )

      // Save to SwiftData
      modelContext?.insert(customSound)
      try modelContext?.save()

      // Notify audio manager to refresh sounds
      NotificationCenter.default.post(name: .customSoundAdded, object: nil)

      return .success(customSound)
    } catch {
      print("❌ CustomSoundManager: Failed to import sound: \(error)")
      return .failure(.invalidAudioFile(error))
    }
  }

  private func copyToCustomSoundsDirectory(source: URL, filename: String, extension ext: String)
    throws -> URL? {
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

  private func isSupportedAudioFormat(_ extension: String) -> Bool {
    let supportedFormats = ["wav", "mp3", "m4a", "aac", "aiff"]
    return supportedFormats.contains(`extension`.lowercased())
  }

  // MARK: - Sound Validation

  /// Validate an audio file before importing
  /// - Parameter url: URL of the audio file to validate
  /// - Returns: Result indicating success or failure
  private func validateAudioFile(at url: URL) async throws -> Result<Void, Error> {
    print("🔍 CustomSoundManager: Validating audio file at \(url.path)")

    // Ensure we have access to the security-scoped resource
    let didStartAccess = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      // Try to read the file data to verify access
      _ = try Data(contentsOf: url, options: .alwaysMapped)

      // Try to create an AVAudioPlayer to verify file is valid
      let audioPlayer = try AVAudioPlayer(contentsOf: url)
      print("✅ CustomSoundManager: Successfully created AVAudioPlayer for \(url.lastPathComponent)")

      // Check file size (limit to 50MB)
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
      if let fileSize = fileAttributes[.size] as? UInt64, fileSize > 50_000_000 {
        return .failure(CustomSoundError.fileTooLarge)
      }

      // Check duration (limit to 10 minutes)
      if audioPlayer.duration > 600 {
        return .failure(CustomSoundError.durationTooLong)
      }

      return .success(())
    } catch {
      let nsError = error as NSError
      print(
        "❌ CustomSoundManager: Audio validation error: \(error.localizedDescription), code: \(nsError.code), domain: \(nsError.domain)"
      )
      return .failure(CustomSoundError.invalidAudioFile(error))
    }
  }

  // MARK: - Sound Retrieval

  /// Get all custom sounds
  /// - Returns: Array of CustomSoundData objects
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

  /// Get the URL for a custom sound file
  /// - Parameter customSound: The CustomSoundData object
  /// - Returns: URL to the sound file or nil if not found
  func getURLForCustomSound(_ customSound: CustomSoundData) -> URL? {
    guard let directoryURL = getCustomSoundsDirectoryURL() else {
      return nil
    }

    let soundURL = directoryURL.appendingPathComponent(
      "\(customSound.fileName).\(customSound.fileExtension)")
    if FileManager.default.fileExists(atPath: soundURL.path) {
      return soundURL
    }

    return nil
  }

  // MARK: - Sound Deletion

  /// Delete a custom sound
  /// - Parameter customSound: The CustomSoundData to delete
  /// - Returns: Result indicating success or failure
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
      return "Audio file is too long. Maximum duration is 10 minutes."
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
