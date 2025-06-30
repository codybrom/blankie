//
//  PresetExporter.swift
//  Blankie
//
//  Created by Cody Bromley on 6/25/25.
//

import Foundation
import SwiftData
import SwiftUI

class PresetExporter {

  static let shared = PresetExporter()

  private init() {}

  enum ExportError: LocalizedError {
    case archiveCreationFailed
    case missingArtwork
    case missingCustomSound(String)
    case fileSystemError(String)

    var errorDescription: String? {
      switch self {
      case .archiveCreationFailed:
        return "Failed to create preset archive"
      case .missingArtwork:
        return "Missing artwork file"
      case .missingCustomSound(let soundName):
        return "Missing custom sound: \(soundName)"
      case .fileSystemError(let message):
        return "File system error: \(message)"
      }
    }
  }

  func createArchive(for preset: Preset) async throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let archiveDir = tempDir.appendingPathComponent("\(preset.name).blankie-temp")
    let archiveZip = tempDir.appendingPathComponent("\(preset.name).blankie")

    // Remove existing files if they exist
    try? FileManager.default.removeItem(at: archiveDir)
    try? FileManager.default.removeItem(at: archiveZip)

    // Create archive directory
    try FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)

    // Create archive manifest
    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    let manifest = ArchiveManifest(blankieVersion: currentVersion)

    // Get custom sounds for this preset
    let customSounds = try await getCustomSounds(for: preset)

    // Get sound customizations for this preset
    let soundCustomizations = getSoundCustomizations(for: preset)

    // Create archive object
    let archive = PresetArchive(
      manifest: manifest,
      preset: preset,
      customSounds: customSounds
    )

    // Write archive files
    try await writeManifest(archive.manifest, to: archiveDir)
    try await writePreset(archive.preset, to: archiveDir)
    try await writeArtwork(for: preset, to: archiveDir)
    try await writeCustomSounds(
      customSounds, withCustomizations: soundCustomizations, to: archiveDir)

    // Create zip file
    try await createZipFile(from: archiveDir, to: archiveZip)

    // Clean up temporary directory
    try? FileManager.default.removeItem(at: archiveDir)

    return archiveZip
  }

  private func getCustomSounds(for preset: Preset) async throws -> [CustomSoundMetadata] {
    let customSoundManager = CustomSoundManager.shared

    // Get custom sounds on main actor and immediately convert to metadata
    let customSoundMetadata = await MainActor.run {
      let allCustomSounds = customSoundManager.getAllCustomSounds()

      // Filter to sounds used in this preset
      let presetSoundFileNames = Set(preset.soundStates.map(\.fileName))
      let relevantCustomSounds = allCustomSounds.filter { customSound in
        presetSoundFileNames.contains(customSound.fileName)
      }

      // Convert to metadata
      return relevantCustomSounds.map { customSound in
        CustomSoundMetadata(from: customSound)
      }
    }

    return customSoundMetadata
  }

  private func writeManifest(_ manifest: ArchiveManifest, to archiveDir: URL) async throws {
    let manifestData = try JSONEncoder().encode(manifest)
    let manifestURL = archiveDir.appendingPathComponent(PresetArchive.manifestFileName)
    try manifestData.write(to: manifestURL)
  }

  private func writePreset(_ preset: Preset, to archiveDir: URL) async throws {
    let presetData = try JSONEncoder().encode(preset)
    let presetURL = archiveDir.appendingPathComponent(PresetArchive.presetFileName)
    try presetData.write(to: presetURL)
  }

  private func writeArtwork(for preset: Preset, to archiveDir: URL) async throws {
    // Write preset artwork if exists
    if let artworkId = preset.artworkId {
      // Get raw artwork data directly (already JPEG compressed)
      if let imageData = await PresetArtworkManager.shared.loadArtworkData(id: artworkId) {
        let artworkURL = archiveDir.appendingPathComponent(PresetArchive.artworkFileName)
        try imageData.write(to: artworkURL)
      }
    }

    // Write background image if exists and not using artwork as background
    if let backgroundId = preset.backgroundImageId,
      !(preset.useArtworkAsBackground ?? false)
    {
      // Get raw background data directly (already JPEG compressed)
      if let imageData = await PresetArtworkManager.shared.loadArtworkData(id: backgroundId) {
        let backgroundURL = archiveDir.appendingPathComponent(PresetArchive.backgroundFileName)
        try imageData.write(to: backgroundURL)
      }
    }
  }

  private func writeCustomSounds(
    _ customSounds: [CustomSoundMetadata], withCustomizations customizations: [SoundCustomization],
    to archiveDir: URL
  )
    async throws
  {
    guard !customSounds.isEmpty || !customizations.isEmpty else { return }

    // Create sounds directory
    let soundsDir = archiveDir.appendingPathComponent(PresetArchive.soundsDirectoryName)
    try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)

    // Write unified sounds metadata including customizations
    let soundsManifest = SoundsManifest(
      customSounds: customSounds, builtInCustomizations: customizations)
    let metadataURL = soundsDir.appendingPathComponent(PresetArchive.soundsMetadataFileName)
    let metadataData = try JSONEncoder().encode(soundsManifest)
    try metadataData.write(to: metadataURL)

    // Copy sound files
    let customSoundManager = CustomSoundManager.shared
    for soundMetadata in customSounds {
      // Get the sound URL on main actor to avoid sending CustomSoundData across actors
      let soundURL = await MainActor.run {
        if let customSoundData = customSoundManager.getCustomSound(by: soundMetadata.id) {
          return customSoundManager.getURLForCustomSound(customSoundData)
        }
        return nil
      }

      if let soundURL = soundURL {
        let destinationURL = soundsDir.appendingPathComponent(soundMetadata.fileName)
        try FileManager.default.copyItem(at: soundURL, to: destinationURL)
      } else {
        throw ExportError.missingCustomSound(soundMetadata.title)
      }
    }
  }

  private func getSoundCustomizations(for preset: Preset) -> [SoundCustomization] {
    let customizationManager = SoundCustomizationManager.shared

    // Get sound file names from the preset
    let presetSoundFileNames = Set(preset.soundStates.map(\.fileName))

    // Get all customizations and filter to those used in this preset
    let allCustomizations = customizationManager.getAllCustomizations()
    return allCustomizations.filter { customization in
      presetSoundFileNames.contains(customization.fileName)
    }
  }

  private func createZipFile(from sourceURL: URL, to destinationURL: URL) async throws {
    try ArchiveUtility.create(from: sourceURL, to: destinationURL)
  }
}
