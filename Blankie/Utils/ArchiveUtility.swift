//
//  ArchiveUtility.swift
//  Blankie
//
//  Created by Cody Bromley on 6/26/25.
//

import Foundation
import ZIPFoundation

/// ZIP archive utility using ZIPFoundation
struct ArchiveUtility {

  static func extract(from archiveURL: URL, to destinationURL: URL) throws {
    try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

    let archive = try Archive(url: archiveURL, accessMode: .read)

    for entry in archive {
      let path = destinationURL.appendingPathComponent(entry.path)
      if entry.type == .directory {
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
      } else {
        let parent = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        _ = try archive.extract(entry, to: path)
      }
    }
  }

  static func create(from sourceURL: URL, to archiveURL: URL) throws {
    print("📦 ArchiveUtility: Creating archive from \(sourceURL.path) to \(archiveURL.path)")

    if FileManager.default.fileExists(atPath: archiveURL.path) {
      try FileManager.default.removeItem(at: archiveURL)
      print("📦 ArchiveUtility: Removed existing archive")
    }

    print("📦 ArchiveUtility: Creating new archive...")
    let archive = try Archive(url: archiveURL, accessMode: .create)
    print("📦 ArchiveUtility: Archive created successfully")

    let fileManager = FileManager.default
    guard
      let enumerator = fileManager.enumerator(
        at: sourceURL, includingPropertiesForKeys: [.isDirectoryKey])
    else {
      throw NSError(
        domain: "ArchiveUtility", code: 3,
        userInfo: [NSLocalizedDescriptionKey: "Cannot enumerate source directory"])
    }

    print("📦 ArchiveUtility: Starting to enumerate files...")
    var fileCount = 0

    for case let fileURL as URL in enumerator {
      let relativePath = fileURL.path.replacingOccurrences(of: sourceURL.path + "/", with: "")

      // Skip empty relative paths
      if relativePath.isEmpty {
        continue
      }

      print("📦 ArchiveUtility: Processing \(relativePath)")

      var isDirectory: ObjCBool = false
      fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)

      if isDirectory.boolValue {
        try archive.addEntry(
          with: relativePath + "/",
          type: .directory,
          uncompressedSize: Int64(0),
          compressionMethod: .none
        ) { _, _ in return Data() }
        print("📦 ArchiveUtility: Added directory: \(relativePath)/")
      } else {
        // Get file size without loading into memory
        let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0

        try archive.addEntry(
          with: relativePath,
          type: .file,
          uncompressedSize: fileSize,
          compressionMethod: .none  // Store without compression
        ) { position, size in
          // Stream file data in chunks
          let fileHandle = try FileHandle(forReadingFrom: fileURL)
          defer { try? fileHandle.close() }

          try fileHandle.seek(toOffset: UInt64(position))
          let data = fileHandle.readData(ofLength: size)
          return data
        }
        print("📦 ArchiveUtility: Added file: \(relativePath) (\(fileSize) bytes)")
        fileCount += 1
      }
    }

    print("📦 ArchiveUtility: Archive creation completed with \(fileCount) files")
  }
}
