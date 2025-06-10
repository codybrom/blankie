//
//  SoundSheetChangeHandlers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

struct SoundSheetChangeHandlers: ViewModifier {
  @Binding var isPreviewing: Bool
  @Binding var normalizeAudio: Bool
  @Binding var volumeAdjustment: Float
  @Binding var randomizeStartPosition: Bool
  @Binding var loopSound: Bool

  let startPreview: () -> Void
  let stopPreview: () -> Void
  let updateSoundSettings: () -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: isPreviewing) { _, previewing in
        print("🎵 SoundSheetChangeHandlers: isPreviewing changed to: \(previewing)")
        if previewing {
          startPreview()
        } else {
          stopPreview()
        }
      }
      .onChange(of: normalizeAudio) { _, _ in
        updateSoundSettings()
      }
      .onChange(of: volumeAdjustment) { _, _ in
        updateSoundSettings()
      }
      .onChange(of: randomizeStartPosition) { _, _ in
        updateSoundSettings()
      }
      .onChange(of: loopSound) { _, _ in
        updateSoundSettings()
      }
  }
}
