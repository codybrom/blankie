//
//  PresetImporter.swift
//  Blankie
//
//  Created by Cody Bromley on 6/25/25.
//

import Foundation
import SwiftUI

// MARK: - Duplicate Detection Helper

private struct DuplicateDetectionHelper {
  static func checkForDuplicatePreset(_ preset: Preset) async -> Preset? {
    await MainActor.run {
      let existingPresets = PresetManager.shared.presets

      // Check if we've already imported this exact preset (by original ID)
      if let duplicate = existingPresets.first(where: { $0.originalId == preset.id }) {
        print("🔍 Import: Found previously imported preset with original ID \(preset.id)")
        return duplicate
      }

      // Check for same name to avoid confusion
      if let sameName = existingPresets.first(where: { $0.name == preset.name }) {
        print("🔍 Import: Found existing preset with same name '\(preset.name)'")
        return sameName
      }

      return nil
    }
  }

  static func generateUniquePresetName(baseName: String) async -> String {
    await MainActor.run {
      let existingPresets = PresetManager.shared.presets
      let existingNames = Set(existingPresets.map(\.name))

      // If the base name is unique, use it
      if !existingNames.contains(baseName) {
        return baseName
      }

      // Find the next available number
      var counter = 2
      while true {
        let candidateName = "\(baseName) (\(counter))"
        if !existingNames.contains(candidateName) {
          print("🔍 Import: Generated unique name '\(candidateName)'")
          return candidateName
        }
        counter += 1
      }
    }
  }

  struct ExistingSoundInfo {
    let id: UUID
    let sha256Hash: String?
  }

  static func checkIfSoundExists(_ soundMetadata: CustomSoundMetadata) async -> ExistingSoundInfo? {
    await MainActor.run {
      // Check if a custom sound with the same ID already exists
      let customSoundManager = CustomSoundManager.shared
      let existingSounds = customSoundManager.getAllCustomSounds()

      // Check by original ID first (most reliable)
      if let existingSound = existingSounds.first(where: { $0.id == soundMetadata.id }) {
        return ExistingSoundInfo(id: existingSound.id, sha256Hash: existingSound.sha256Hash)
      }

      // Also check by original filename as backup (in case IDs changed)
      if let existingByFilename = existingSounds.first(where: { existing in
        existing.originalFileName == soundMetadata.originalFileName
          && existing.title == soundMetadata.title
      }) {
        return ExistingSoundInfo(
          id: existingByFilename.id, sha256Hash: existingByFilename.sha256Hash)
      }

      return nil
    }
  }
}

// MARK: - Sound Customization Helper

private struct SoundCustomizationImporter {
  static func importFromManifest(from archiveURL: URL) async throws {
    let soundsDir = archiveURL.appendingPathComponent(PresetArchive.soundsDirectoryName)
    let metadataURL = soundsDir.appendingPathComponent(PresetArchive.soundsMetadataFileName)

    // Check if metadata file exists
    guard FileManager.default.fileExists(atPath: metadataURL.path) else {
      print("📦 Import: No sound metadata found in archive")
      return
    }

    do {
      let metadataData = try Data(contentsOf: metadataURL)

      let soundsManifest = try JSONDecoder().decode(SoundsManifest.self, from: metadataData)
      let customizations = soundsManifest.builtInCustomizations
      await applyCustomizations(customizations)
    } catch {
      print("⚠️ Import: Failed to import sound customizations: \(error)")
      // Don't throw error - customizations are optional
    }
  }

  private static func applyCustomizations(_ customizations: [SoundCustomization]) async {
    guard !customizations.isEmpty else {
      print("📦 Import: No sound customizations to apply")
      return
    }

    await MainActor.run {
      let customizationManager = SoundCustomizationManager.shared
      var appliedCount = 0
      var skippedCount = 0

      for customization in customizations {
        // Check if this sound already has customizations - if so, skip to preserve user's settings
        if customizationManager.getCustomization(for: customization.fileName) != nil {
          skippedCount += 1
          continue
        }

        // Apply each customization property if it's not nil
        if let title = customization.customTitle {
          customizationManager.setCustomTitle(title, for: customization.fileName)
        }
        if let iconName = customization.customIconName {
          customizationManager.setCustomIcon(iconName, for: customization.fileName)
        }
        if let colorName = customization.customColorName {
          customizationManager.setCustomColor(colorName, for: customization.fileName)
        }
        if let randomizeStart = customization.randomizeStartPosition {
          customizationManager.setRandomizeStartPosition(
            randomizeStart, for: customization.fileName)
        }
        if let normalizeAudio = customization.normalizeAudio {
          customizationManager.setNormalizeAudio(normalizeAudio, for: customization.fileName)
        }
        if let volumeAdjustment = customization.volumeAdjustment {
          customizationManager.setVolumeAdjustment(volumeAdjustment, for: customization.fileName)
        }
        if let loopSound = customization.loopSound {
          customizationManager.setLoopSound(loopSound, for: customization.fileName)
        }

        appliedCount += 1
      }

      print(
        "📦 Import: Applied \(appliedCount) sound customizations, skipped \(skippedCount) existing")
    }
  }
}

class PresetImporter {

  static let shared = PresetImporter()

  private init() {}

  // Type aliases for helper structs
  fileprivate typealias ExistingSoundInfo = DuplicateDetectionHelper.ExistingSoundInfo

  enum ImportError: LocalizedError {
    case invalidArchive
    case incompatibleVersion
    case missingRequiredFiles
    case corruptedData
    case sharingRestricted
    case soundImportFailed(String)

    var errorDescription: String? {
      switch self {
      case .invalidArchive:
        return "Invalid .blankie file"
      case .incompatibleVersion:
        return "This preset requires a newer version of Blankie"
      case .missingRequiredFiles:
        return "Missing required files in preset archive"
      case .corruptedData:
        return "Preset data is corrupted"
      case .sharingRestricted:
        return "This preset cannot be modified due to sharing restrictions"
      case .soundImportFailed(let soundName):
        return "Failed to import custom sound: \(soundName)"
      }
    }
  }

  // MARK: - Import Logic

  func importArchive(from url: URL) async throws -> Preset {
    // Ensure we have access to the security-scoped resource
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    // Extract archive
    let (archiveURL, tempExtractedURL) = try extractArchive(from: url)

    defer {
      // Clean up temporary files
      if let tempURL = tempExtractedURL {
        try? FileManager.default.removeItem(at: tempURL)
        print("🗑️ Import: Cleaned up extracted files at \(tempURL.lastPathComponent)")
      }
      // Clean up the imported file if it's in the tmp directory
      if url.path.contains("/tmp/") {
        try? FileManager.default.removeItem(at: url)
        print("🗑️ Import: Cleaned up temporary file at \(url.lastPathComponent)")
      }
    }

    // Step 1: Validate archive structure
    try validateArchiveStructure(at: archiveURL)

    // Read and validate manifest
    let manifest = try await readManifest(from: archiveURL)
    try validateCompatibility(manifest)

    // Read preset data
    var preset = try await readPreset(from: archiveURL)

    // Check for duplicate preset
    if await DuplicateDetectionHelper.checkForDuplicatePreset(preset) != nil {
      print("⚠️ Import: Found existing preset with ID \(preset.id)")
      // Generate a unique name with number suffix
      preset.name = await DuplicateDetectionHelper.generateUniquePresetName(baseName: preset.name)
    }

    // Step 2: Import artwork if present
    try await importArtwork(for: &preset, from: archiveURL)

    // Step 3: Import custom sounds if present
    let idMapping = try await importCustomSounds(for: preset, from: archiveURL)

    // Step 3.5: Import sound customizations if present (now included in metadata)
    try await SoundCustomizationImporter.importFromManifest(from: archiveURL)

    // Step 4: Update preset sound states with correct IDs
    if !idMapping.isEmpty {
      preset = updatePresetSoundStates(preset, with: idMapping)
    }

    // Step 5: Generate new UUID to avoid conflicts
    preset = createNewPresetInstance(from: preset)

    // Step 6: Add to preset manager and activate
    await addAndActivatePreset(preset)

    return preset
  }

  private func extractArchive(from url: URL) throws -> (
    archiveURL: URL, tempExtractedURL: URL?
  ) {
    var archiveURL = url
    var tempExtractedURL: URL?

    // If it's a file (not a directory), we need to extract it
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    {
      print("📦 Import: Detected compressed .blankie file, extracting...")

      // Create a temporary directory for extraction
      let tempDir = FileManager.default.temporaryDirectory
      let extractionDir = tempDir.appendingPathComponent("blankie-import-\(UUID().uuidString)")

      do {
        // Create extraction directory
        try FileManager.default.createDirectory(
          at: extractionDir, withIntermediateDirectories: true)

        try ArchiveUtility.extract(from: url, to: extractionDir)

        archiveURL = extractionDir
        tempExtractedURL = extractionDir
        print("✅ Import: Successfully extracted to \(extractionDir.lastPathComponent)")

      } catch {
        print("❌ Import: Failed to extract archive: \(error)")
        throw ImportError.invalidArchive
      }
    }

    return (archiveURL, tempExtractedURL)
  }
}

// MARK: - Sound Import Extension

extension PresetImporter {
  @MainActor
  func importCustomSounds(
    for preset: Preset, from archiveURL: URL
  ) async throws -> [UUID: UUID] {
    let soundsDir = archiveURL.appendingPathComponent(PresetArchive.soundsDirectoryName)

    guard FileManager.default.fileExists(atPath: soundsDir.path) else {
      return [:]  // No custom sounds to import
    }

    // Read sounds metadata
    let customSounds = try readSoundsMetadata(from: soundsDir)
    guard !customSounds.isEmpty else {
      return [:]
    }

    // Import each custom sound
    var importedCount = 0
    var idMapping: [UUID: UUID] = [:]  // Maps original IDs to actual IDs (existing or new)

    for soundMetadata in customSounds {
      // Process existing sound if found
      if let existingSound = await DuplicateDetectionHelper.checkIfSoundExists(soundMetadata) {
        if let mappedId = await processExistingSound(
          soundMetadata, existingSound, &importedCount)
        {
          idMapping[soundMetadata.id] = mappedId
          continue
        }
      }

      // Import new sound
      let soundFileURL = soundsDir.appendingPathComponent(soundMetadata.fileName)
      let importedId = try await importNewSound(
        soundMetadata, soundFileURL, preset, &importedCount)
      idMapping[soundMetadata.id] = importedId
    }

    return idMapping
  }

  private func readSoundsMetadata(from soundsDir: URL) throws -> [CustomSoundMetadata] {
    let metadataURL = soundsDir.appendingPathComponent(PresetArchive.soundsMetadataFileName)
    guard FileManager.default.fileExists(atPath: metadataURL.path) else {
      return []
    }

    let metadataData = try Data(contentsOf: metadataURL)
    let soundsManifest = try JSONDecoder().decode(SoundsManifest.self, from: metadataData)
    return soundsManifest.customSounds
  }

  @MainActor
  private func processExistingSound(
    _ soundMetadata: CustomSoundMetadata,
    _ existingSound: ExistingSoundInfo,
    _ importedCount: inout Int
  ) async -> UUID? {
    print("🔍 Import: Sound '\(soundMetadata.title)' already exists with ID \(existingSound.id)")

    // If we have SHA hashes, verify they match
    if let existingHash = existingSound.sha256Hash,
      let importHash = soundMetadata.sha256Hash,
      existingHash != importHash
    {
      print(
        "⚠️ Import: SHA hash mismatch for '\(soundMetadata.title)' - treating as different file")
      return nil  // Continue with import as it's a different file
    }

    // Same file, skip import but record the ID mapping
    print("✅ Import: SHA hash matches or not available - skipping duplicate import")
    importedCount += 1
    return existingSound.id
  }

  @MainActor
  private func importNewSound(
    _ soundMetadata: CustomSoundMetadata,
    _ soundFileURL: URL,
    _ preset: Preset,
    _ importedCount: inout Int
  ) async throws -> UUID {
    guard FileManager.default.fileExists(atPath: soundFileURL.path) else {
      throw ImportError.soundImportFailed(soundMetadata.title)
    }

    do {
      // Create custom sound data from metadata
      let customSoundData = createCustomSoundData(from: soundMetadata, preset: preset)

      // Import the sound
      let result = await CustomSoundManager.shared.importSound(
        from: soundFileURL,
        title: customSoundData.title,
        iconName: customSoundData.systemIconName,
        randomizeStartPosition: customSoundData.randomizeStartPosition
      )

      let importedSound: CustomSoundData
      switch result {
      case .success(let sound):
        importedSound = sound
      case .failure(let error):
        print("❌ PresetImporter: Failed to import sound: \(error)")
        throw ImportError.soundImportFailed(customSoundData.title)
      }

      // Update progress
      importedCount += 1

      return importedSound.id

    } catch {
      throw ImportError.soundImportFailed(soundMetadata.title)
    }
  }

  private func createCustomSoundData(from soundMetadata: CustomSoundMetadata, preset: Preset)
    -> CustomSoundData
  {
    // Extract file info from metadata
    let fileNameWithoutExtension = (soundMetadata.fileName as NSString).deletingPathExtension
    let fileExtension = (soundMetadata.fileName as NSString).pathExtension

    // Create CustomSoundData from metadata - PRESERVING THE ORIGINAL ID
    let customSoundData = CustomSoundData(
      title: soundMetadata.title,
      systemIconName: "speaker.wave.3.fill",  // Default icon for imported sounds
      fileName: fileNameWithoutExtension,
      fileExtension: fileExtension,
      originalFileName: soundMetadata.originalFileName,
      detectedLUFS: soundMetadata.lufsValue != nil ? Float(soundMetadata.lufsValue!) : nil,
      creditAuthor: soundMetadata.credits?.author,
      creditSourceUrl: soundMetadata.credits?.sourceUrl,
      creditLicenseType: soundMetadata.credits?.license ?? "",
      creditCustomLicenseText: soundMetadata.credits?.customLicenseText,
      creditCustomLicenseUrl: soundMetadata.credits?.customLicenseUrl,
      importedFromPresetId: preset.id,
      importedFromPresetName: preset.name
    )

    // Preserve the original ID and SHA hash so presets can share sounds
    customSoundData.id = soundMetadata.id
    customSoundData.sha256Hash = soundMetadata.sha256Hash

    return customSoundData
  }
}

// MARK: - Processing & Updates Extension

extension PresetImporter {
  func importArtwork(for preset: inout Preset, from archiveURL: URL) async throws {
    let artworkURL = archiveURL.appendingPathComponent(PresetArchive.artworkFileName)
    let backgroundURL = archiveURL.appendingPathComponent(PresetArchive.backgroundFileName)

    // Import preset artwork
    if FileManager.default.fileExists(atPath: artworkURL.path) {
      let artworkData = try Data(contentsOf: artworkURL)
      let artworkId = try await PresetArtworkManager.shared.saveArtwork(
        artworkData, for: preset.id, type: .artwork)
      preset.artworkId = artworkId
    }

    // Import background image
    if FileManager.default.fileExists(atPath: backgroundURL.path) {
      let backgroundData = try Data(contentsOf: backgroundURL)
      let backgroundId = try await PresetArtworkManager.shared.saveArtwork(
        backgroundData, for: preset.id, type: .background)
      preset.backgroundImageId = backgroundId
    }
  }

  func updatePresetSoundStates(_ preset: Preset, with idMapping: [UUID: UUID]) -> Preset {
    var updatedPreset = preset

    // Update sound states to use the correct IDs
    updatedPreset.soundStates = preset.soundStates.map { state in
      // Check if this is a custom sound by looking for its ID in the mapping
      // The fileName for custom sounds is typically the UUID string
      if let soundId = UUID(uuidString: state.fileName),
        let mappedId = idMapping[soundId]
      {
        // Create a new PresetState with the mapped ID
        let updatedState = PresetState(
          fileName: mappedId.uuidString,
          isSelected: state.isSelected,
          volume: state.volume
        )
        print("📝 Import: Updated sound state from \(state.fileName) to \(mappedId.uuidString)")
        return updatedState
      }

      // Not a custom sound or not in mapping, keep as is
      return state
    }

    return updatedPreset
  }

  func createNewPresetInstance(from preset: Preset) -> Preset {
    // Create a new preset with a new ID to avoid conflicts
    let newPreset = Preset(
      id: UUID(),  // Generate new ID
      name: preset.name,
      soundStates: preset.soundStates,
      isDefault: false,
      createdVersion: preset.createdVersion,
      lastModifiedVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "1.1.0",
      soundOrder: preset.soundOrder,
      creatorName: preset.creatorName,
      artworkId: preset.artworkId,
      showBackgroundImage: preset.showBackgroundImage,
      useArtworkAsBackground: preset.useArtworkAsBackground,
      backgroundImageId: preset.backgroundImageId,
      backgroundBlurRadius: preset.backgroundBlurRadius,
      backgroundOpacity: preset.backgroundOpacity,
      order: preset.order,
      isImported: true,  // Mark as imported
      originalId: preset.id  // Store the original ID for duplicate detection
    )

    return newPreset
  }

  func addAndActivatePreset(_ preset: Preset) async {
    await MainActor.run {
      let presetManager = PresetManager.shared
      let audioManager = AudioManager.shared

      // Force reload of all custom sounds to ensure all imported sounds are available
      audioManager.loadCustomSounds()

      // Add to presets
      var currentPresets = presetManager.presets
      currentPresets.append(preset)
      presetManager.setPresets(currentPresets)

      // Save presets to persist the import
      presetManager.savePresets()

      // Activate the imported preset immediately
      do {
        try presetManager.applyPreset(preset)
      } catch {
        print("⚠️ Import: Failed to apply preset: \(error)")
      }

      print("📦 Import: Successfully imported and activated preset '\(preset.name)'")
    }
  }
}

// MARK: - Validation Extension

extension PresetImporter {
  func validateArchiveStructure(at url: URL) throws {
    let manifestURL = url.appendingPathComponent(PresetArchive.manifestFileName)
    let presetURL = url.appendingPathComponent(PresetArchive.presetFileName)

    guard FileManager.default.fileExists(atPath: manifestURL.path),
      FileManager.default.fileExists(atPath: presetURL.path)
    else {
      throw ImportError.missingRequiredFiles
    }
  }

  func readManifest(from archiveURL: URL) async throws -> ArchiveManifest {
    let manifestURL = archiveURL.appendingPathComponent(PresetArchive.manifestFileName)
    let manifestData = try Data(contentsOf: manifestURL)
    return try JSONDecoder().decode(ArchiveManifest.self, from: manifestData)
  }

  func validateCompatibility(_ manifest: ArchiveManifest) throws {
    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"

    guard manifest.compatibility.isCompatible(with: currentVersion) else {
      throw ImportError.incompatibleVersion
    }
  }

  func readPreset(from archiveURL: URL) async throws -> Preset {
    let presetURL = archiveURL.appendingPathComponent(PresetArchive.presetFileName)
    let presetData = try Data(contentsOf: presetURL)
    return try JSONDecoder().decode(Preset.self, from: presetData)
  }

  func countCustomSounds(in archiveURL: URL) async -> Int {
    let soundsDir = archiveURL.appendingPathComponent(PresetArchive.soundsDirectoryName)
    let metadataURL = soundsDir.appendingPathComponent(PresetArchive.soundsMetadataFileName)

    guard FileManager.default.fileExists(atPath: metadataURL.path) else {
      return 0
    }

    do {
      let metadataData = try Data(contentsOf: metadataURL)

      let soundsManifest = try JSONDecoder().decode(SoundsManifest.self, from: metadataData)
      return soundsManifest.customSounds.count
    } catch {
      return 0
    }
  }
}
