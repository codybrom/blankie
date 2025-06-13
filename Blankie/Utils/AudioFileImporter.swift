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

  func handleIncomingFile(_ url: URL) {
    // Handle direct file imports via URL scheme or document picker

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

  func clearImport() {
    fileToImport = nil
    showingSoundSheet = false
  }

}
