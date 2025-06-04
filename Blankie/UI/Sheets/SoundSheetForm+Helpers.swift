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
      if let peakLevel = customSound.detectedPeakLevel {
        let percentage = Int(peakLevel * 100)
        let normFactor = AudioAnalyzer.calculateNormalizationFactor(peakLevel: peakLevel)
        let gainDB = 20 * log10(normFactor)
        return (peak: "\(percentage)%", gain: String(format: "%+.1fdB", gainDB))
      }
    case .customize(let sound):
      if let lufs = sound.lufs, let normalizationFactor = sound.normalizationFactor {
        let lufsStr = String(format: "%.1f LUFS", lufs)
        let gainDB = 20 * log10(normalizationFactor)
        return (peak: lufsStr, gain: String(format: "%+.1fdB", gainDB))
      }
    case .add:
      return nil
    }
    return nil
  }
}
