//
//  SoundSheetForm+Helpers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import SwiftUI

extension SoundSheetForm {

  var textColorForCurrentTheme: Color {
    let color = GlobalSettings.shared.customAccentColor ?? .accentColor
    #if os(macOS)
      if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
        let brightness =
          (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
          + (0.114 * nsColor.blueComponent)
        return brightness > 0.5 ? .black : .white
      } else {
        return .white
      }
    #else
      return .white
    #endif
  }

  func textColorForAccentColor(_ accentColor: AccentColor) -> Color {
    guard let color = accentColor.color else { return .white }
    #if os(macOS)
      if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
        let brightness =
          (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
          + (0.114 * nsColor.blueComponent)
        return brightness > 0.5 ? .black : .white
      } else {
        return .white
      }
    #else
      return .white
    #endif
  }

  var volumePercentageText: String {
    let percentage = Int((volumeAdjustment - 1.0) * 100)
    if percentage > 0 {
      return "+\(percentage)%"
    } else if percentage < 0 {
      return "\(percentage)%"
    } else {
      return "0%"
    }
  }

  func togglePreview() {
    if isPreviewing {
      stopPreview()
    } else {
      startPreview()
    }
  }

  func startPreview() {
    // This will be implemented in the parent view
    isPreviewing = true
  }

  func stopPreview() {
    // This will be implemented in the parent view
    isPreviewing = false
  }

  func updatePreviewVolume() {
    // This will be implemented in the parent view
  }

  func getPeakLevelInfo() -> (peak: String, gain: String)? {
    switch mode {
    case .edit(let customSound):
      // Check for cached playback profile first
      let profileKey = "\(customSound.fileName)"
      if let profile = PlaybackProfileStore.shared.profile(for: profileKey) {
        let lufsStr = String(format: "%.1f LUFS", profile.integratedLUFS)
        let truePeakStr = String(format: "%.1f dBTP", profile.truePeakdBTP)
        let gainStr = String(format: "%+.1f dB", profile.gainDB)
        return (peak: "\(lufsStr), TP: \(truePeakStr)", gain: gainStr)
      } else if let lufs = customSound.detectedLUFS {
        let lufsStr = String(format: "%.1f LUFS", lufs)
        let gainDB = AudioAnalyzer.targetLUFS - lufs
        return (peak: lufsStr, gain: String(format: "%+.1f dB", gainDB))
      } else if let peakLevel = customSound.detectedPeakLevel {
        let percentage = Int(peakLevel * 100)
        let normFactor = AudioAnalyzer.calculateNormalizationFactor(peakLevel: peakLevel)
        let gainDB = 20 * log10(normFactor)
        return (peak: "\(percentage)%", gain: String(format: "%+.1f dB", gainDB))
      }
    case .customize(let sound):
      // Check for cached playback profile first
      let profileKey = "\(sound.fileName).\(sound.fileExtension)"
      if let profile = PlaybackProfileStore.shared.profile(for: profileKey) {
        let lufsStr = String(format: "%.1f LUFS", profile.integratedLUFS)
        let truePeakStr = String(format: "%.1f dBTP", profile.truePeakdBTP)
        let gainStr = String(format: "%+.1f dB", profile.gainDB)
        let limiterStr = profile.needsLimiter ? " 🔒" : ""
        return (peak: "\(lufsStr), TP: \(truePeakStr)\(limiterStr)", gain: gainStr)
      } else if let lufs = sound.lufs, let normalizationFactor = sound.normalizationFactor {
        let lufsStr = String(format: "%.1f LUFS", lufs)
        let gainDB = 20 * log10(normalizationFactor)
        let limiterStr = sound.needsLimiter ? " 🔒" : ""
        return (peak: lufsStr + limiterStr, gain: String(format: "%+.1f dB", gainDB))
      }
    case .add:
      return nil
    }
    return nil
  }
}
