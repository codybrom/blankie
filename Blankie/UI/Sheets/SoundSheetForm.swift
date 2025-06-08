//
//  SoundSheetForm.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import SwiftUI

struct SoundSheetForm: View {
  let mode: SoundSheetMode
  @Binding var soundName: String
  @Binding var selectedIcon: String
  @Binding var selectedFile: URL?
  @Binding var isImporting: Bool
  @Binding var selectedColor: AccentColor?
  @Binding var randomizeStartPosition: Bool
  @Binding var normalizeAudio: Bool
  @Binding var volumeAdjustment: Float
  @Binding var loopSound: Bool
  @Binding var isPreviewing: Bool
  @Binding var previewSound: Sound?

  @ObservedObject var globalSettings = GlobalSettings.shared

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
    isPreviewing.toggle()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // File selection (only for add mode)
      if case .add = mode {
        SoundFileSelector(
          selectedFile: $selectedFile,
          soundName: $soundName,
          isImporting: $isImporting
        )
      }

      // Name Input
      VStack(alignment: .leading, spacing: 8) {
        Text("Name", comment: "Display name field label")
          .font(.headline)
        TextField(text: $soundName) {
          Text("Enter a name for this sound", comment: "Sound name text field placeholder")
        }
        .textFieldStyle(.roundedBorder)
      }

      // Icon Selection
      SoundIconSelector(selectedIcon: $selectedIcon)

      // Color Selection (for customize and edit modes)
      switch mode {
      case .customize, .edit:
        ColorSelectionView(selectedColor: $selectedColor)
      case .add:
        EmptyView()
      }

      // Randomize Start Position Toggle
      VStack(alignment: .leading, spacing: 8) {
        Toggle(isOn: $randomizeStartPosition) {
          VStack(alignment: .leading, spacing: 2) {
            Text(
              "Randomize Start Position",
              comment: "Toggle label for randomizing sound start position"
            )
            .font(.headline)
            Text(
              "Start playback from a random position each time",
              comment: "Description for randomize start position toggle"
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }
        .toggleStyle(.switch)
      }

      // Loop Sound Toggle
      VStack(alignment: .leading, spacing: 8) {
        Toggle(isOn: $loopSound) {
          VStack(alignment: .leading, spacing: 2) {
            Text(
              "Loop Sound",
              comment: "Toggle label for looping sound playback"
            )
            .font(.headline)
            Text(
              "Repeat continuously when playing",
              comment: "Description for loop sound toggle"
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }
        .toggleStyle(.switch)
      }

      // Audio Normalization Controls
      VStack(alignment: .leading, spacing: 8) {
        Toggle(isOn: $normalizeAudio) {
          VStack(alignment: .leading, spacing: 2) {
            Text(
              "Normalize Audio",
              comment: "Toggle label for audio normalization"
            )
            .font(.headline)
            Text(
              "Automatically balance volume levels",
              comment: "Description for audio normalization toggle"
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }
        .toggleStyle(.switch)
      }

      // Preview Button (always visible)
      HStack {
        Spacer()
        Button(action: togglePreview) {
          Label(
            isPreviewing ? "Stop Preview" : "Preview",
            systemImage: isPreviewing ? "stop.fill" : "play.fill"
          )
        }
        .buttonStyle(.bordered)
      }
      .padding(.top, 8)

      // Volume Adjustment (only visible when normalization is OFF)
      if !normalizeAudio {
        VStack(alignment: .leading, spacing: 8) {
          Text("Volume Adjustment", comment: "Volume adjustment field label")
            .font(.headline)

          VStack(spacing: 8) {
            HStack {
              Text("-50%", comment: "Volume decrease label")
                .font(.caption)
                .foregroundColor(.secondary)

              Slider(value: $volumeAdjustment, in: 0.5...1.5, step: 0.01)

              Text("+50%", comment: "Volume increase label")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            HStack {
              Spacer()
              Text(volumePercentageText)
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
            }
          }
        }
      }
    }
    .padding(20)
  }

}
