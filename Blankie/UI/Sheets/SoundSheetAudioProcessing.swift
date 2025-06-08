//
//  SoundSheetAudioProcessing.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

extension CleanSoundSheetForm {
  @ViewBuilder
  var audioProcessingSection: some View {
    Section(header: Text("Audio", comment: "Audio options section header")) {
      Toggle(isOn: $randomizeStartPosition) {
        Text(
          "Randomize Start Position",
          comment: "Toggle label for randomizing sound start position"
        )
      }
      .tint(globalSettings.customAccentColor ?? .accentColor)

      Toggle(isOn: $loopSound) {
        Text(
          "Loop Sound",
          comment: "Toggle label for looping sound playback"
        )
      }
      .tint(globalSettings.customAccentColor ?? .accentColor)

      Toggle(isOn: $normalizeAudio) {
        VStack(alignment: .leading, spacing: 2) {
          Text(
            "Sound Check",
            comment: "Toggle label for Sound Check (audio normalization)"
          )
          Text(
            "Sound Check adjusts the loudness between different sounds to play at the same volume.",
            comment: "Description for Sound Check toggle"
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .tint(globalSettings.customAccentColor ?? .accentColor)

      // Volume Adjustment (only visible when normalization is OFF)
      if !normalizeAudio {
        volumeAdjustmentView
      }
    }
  }

  @ViewBuilder
  var volumeAdjustmentView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Volume Adjustment", comment: "Volume adjustment field label")
        Spacer()
        Text(volumePercentageText)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      HStack {
        Text("-50%", comment: "Volume decrease label")
          .font(.caption)
          .foregroundColor(.secondary)

        Slider(value: $volumeAdjustment, in: 0.5...8.0, step: 0.01)
          .tint(globalSettings.customAccentColor ?? .accentColor)

        Text("+700%", comment: "Volume increase label")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}
