//
//  AudioFileImporter.swift
//  Blankie
//
//  Created by Cody Bromley on 6/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class AudioFileImporter: ObservableObject {
  static let shared = AudioFileImporter()

  @Published var showingSoundSheet = false
  @Published var fileToImport: URL?

  init() {
    // Check for any files shared via the share extension
    checkForSharedFiles()
  }

  func handleIncomingFile(_ url: URL) {
    // Handle URL scheme from share extension
    if url.scheme == "blankie" && url.host == "import" {
      handleShareExtensionImport(url)
      return
    }

    print("🎵 AudioFileImporter: Received file: \(url.lastPathComponent)")

    // Verify it's an audio file
    guard let type = UTType(filenameExtension: url.pathExtension),
      type.conforms(to: .audio)
    else {
      print("❌ AudioFileImporter: Unsupported file type: \(url.pathExtension)")
      return
    }

    // Start accessing security-scoped resource
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    print("🔐 AudioFileImporter: Security-scoped access started: \(didStartAccessing)")

    // Copy the file to a temporary location that the app owns
    let tempDir = FileManager.default.temporaryDirectory
    let tempFileURL = tempDir.appendingPathComponent(url.lastPathComponent)

    do {
      // Remove existing temp file if needed
      try? FileManager.default.removeItem(at: tempFileURL)

      // Copy the file to temp directory
      try FileManager.default.copyItem(at: url, to: tempFileURL)
      print("✅ AudioFileImporter: Copied file to temp directory: \(tempFileURL.lastPathComponent)")

      // Store the temp file URL and show the sound sheet
      fileToImport = tempFileURL
      showingSoundSheet = true
    } catch {
      print("❌ AudioFileImporter: Failed to copy file: \(error)")
    }

    // Stop accessing the security-scoped resource
    if didStartAccessing {
      url.stopAccessingSecurityScopedResource()
    }
  }

  private func handleShareExtensionImport(_ url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let filePathItem = components.queryItems?.first(where: { $0.name == "file" }),
      let filePath = filePathItem.value
    else {
      print("❌ AudioFileImporter: Invalid share extension URL")
      return
    }

    let sharedFileURL = URL(fileURLWithPath: filePath)
    print("🎵 AudioFileImporter: Received from share extension: \(sharedFileURL.lastPathComponent)")

    // Verify the file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
      print("❌ AudioFileImporter: Shared file doesn't exist")
      return
    }

    // Verify it's an audio file using UTType
    guard let type = UTType(filenameExtension: sharedFileURL.pathExtension),
      type.conforms(to: .audio)
    else {
      print("❌ AudioFileImporter: Unsupported file type: \(sharedFileURL.pathExtension)")
      return
    }

    // Copy the file to a temporary location that the app owns
    let tempDir = FileManager.default.temporaryDirectory
    let tempFileURL = tempDir.appendingPathComponent(sharedFileURL.lastPathComponent)

    do {
      // Remove existing temp file if needed
      try? FileManager.default.removeItem(at: tempFileURL)

      // Copy from shared container to app's temp directory
      try FileManager.default.copyItem(at: sharedFileURL, to: tempFileURL)
      print("🎵 AudioFileImporter: Copied shared file to temp directory")

      // Clean up the shared file
      try? FileManager.default.removeItem(at: sharedFileURL)

      // Store the temp file URL and show the sound sheet
      fileToImport = tempFileURL
      showingSoundSheet = true
    } catch {
      print("❌ AudioFileImporter: Failed to copy shared file: \(error)")
    }
  }

  func clearImport() {
    fileToImport = nil
    showingSoundSheet = false
  }

  func checkForSharedFiles() {
    // Dynamically construct app group identifier from bundle ID
    guard let bundleId = Bundle.main.bundleIdentifier else {
      print("❌ AudioFileImporter: No bundle identifier found")
      return
    }

    let groupIdentifier = "group.\(bundleId)"

    guard
      let sharedContainer = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupIdentifier
      )
    else {
      print("❌ AudioFileImporter: Failed to get shared container for group: \(groupIdentifier)")
      print(
        "❌ AudioFileImporter: Make sure App Groups capability is enabled with identifier: \(groupIdentifier)"
      )
      print(
        "❌ AudioFileImporter: If you're a developer, please update the entitlements files as described in DEVELOPMENT.md"
      )
      print(
        "❌ AudioFileImporter: The entitlements must use 'group.' prefix followed by your bundle identifier"
      )
      return
    }

    print("✅ AudioFileImporter: Successfully accessed shared container at: \(sharedContainer.path)")

    let inboxDir = sharedContainer.appendingPathComponent("inbox", isDirectory: true)

    do {
      let files = try FileManager.default.contentsOfDirectory(
        at: inboxDir,
        includingPropertiesForKeys: [.creationDateKey],
        options: .skipsHiddenFiles
      )

      // Process the first audio file found
      for fileURL in files
      where UTType(filenameExtension: fileURL.pathExtension)?.conforms(to: .audio) ?? false {
        print("🎵 AudioFileImporter: Found shared file: \(fileURL.lastPathComponent)")

        // Copy to temp directory and import
        let tempDir = FileManager.default.temporaryDirectory
        let tempFileURL = tempDir.appendingPathComponent(fileURL.lastPathComponent)

        try? FileManager.default.removeItem(at: tempFileURL)
        try FileManager.default.copyItem(at: fileURL, to: tempFileURL)

        // Remove from inbox
        try? FileManager.default.removeItem(at: fileURL)

        // Import the file
        fileToImport = tempFileURL
        showingSoundSheet = true
        break
      }
    } catch {
      // Inbox might not exist yet, which is fine
    }
  }
}
