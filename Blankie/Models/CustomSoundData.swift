//
//  CustomSoundData.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import Foundation
import SwiftData

@Model
class CustomSoundData {
  var id = UUID()
  var title: String
  var systemIconName: String
  var fileName: String
  var fileExtension: String
  var dateAdded: Date
  var randomizeStartPosition: Bool = true

  // Audio normalization settings
  var normalizeAudio: Bool = true
  var volumeAdjustment: Float = 1.0  // 0.5 = -50%, 1.0 = normal, 3.0 = +200%
  var detectedPeakLevel: Float?  // Legacy: Store the detected peak level for reference
  var detectedLUFS: Float?  // Store the detected LUFS (Loudness Units relative to Full Scale)
  var normalizationFactor: Float?  // Pre-calculated normalization factor

  // We don't need full credit info for custom sounds, but we'll track some basic info
  var originalFileName: String?

  init(
    title: String,
    systemIconName: String,
    fileName: String,
    fileExtension: String,
    originalFileName: String? = nil,
    randomizeStartPosition: Bool = true,
    normalizeAudio: Bool = true,
    volumeAdjustment: Float = 1.0,
    detectedPeakLevel: Float? = nil,
    detectedLUFS: Float? = nil,
    normalizationFactor: Float? = nil
  ) {
    self.title = title
    self.systemIconName = systemIconName
    self.fileName = fileName
    self.fileExtension = fileExtension
    self.dateAdded = Date()
    self.originalFileName = originalFileName
    self.randomizeStartPosition = randomizeStartPosition
    self.normalizeAudio = normalizeAudio
    self.volumeAdjustment = volumeAdjustment
    self.detectedPeakLevel = detectedPeakLevel
    self.detectedLUFS = detectedLUFS
    self.normalizationFactor = normalizationFactor
  }

  // Convert to SoundData for compatibility with existing system
  func toSoundData() -> SoundData {
    return SoundData(
      defaultOrder: 1000,  // Place custom sounds after built-in sounds
      title: title,
      systemIconName: systemIconName,
      fileName: fileName,
      author: "Custom Sound",
      authorUrl: nil,
      license: "Custom",
      soundUrl: "",
      soundName: originalFileName ?? fileName,
      description: nil,
      note: nil,
      lufs: detectedLUFS,
      normalizationFactor: normalizationFactor
    )
  }
}
