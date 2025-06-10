//
//  SoundSheetMacOSLayout.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

struct SoundSheetMacOSLayout: View {
  let mode: SoundSheetMode
  let isFilePreselected: Bool
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
  let hasChanges: Bool
  let title: LocalizedStringKey
  let buttonTitle: LocalizedStringKey
  let isDisabled: Bool
  let performAction: () -> Void
  let stopPreview: () -> Void
  let dismiss: DismissAction

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 8) {
        Text(title)
          .font(.title2.bold())
      }
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      CleanSoundSheetForm(
        mode: mode,
        isFilePreselected: isFilePreselected,
        soundName: $soundName,
        selectedIcon: $selectedIcon,
        selectedFile: $selectedFile,
        isImporting: $isImporting,
        selectedColor: $selectedColor,
        randomizeStartPosition: $randomizeStartPosition,
        normalizeAudio: $normalizeAudio,
        volumeAdjustment: $volumeAdjustment,
        loopSound: $loopSound,
        isPreviewing: $isPreviewing,
        previewSound: $previewSound
      )

      Spacer()
      Divider()

      Group {
        if hasChanges {
          HStack {
            Button("Cancel") {
              if isPreviewing {
                stopPreview()
              }
              dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)

            Spacer()

            Button {
              performAction()
            } label: {
              Text(buttonTitle)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDisabled)
            .keyboardShortcut(.return)
          }
          .padding()
        } else {
          HStack {
            Button("Done") {
              if isPreviewing {
                stopPreview()
              }
              dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)

            Spacer()
          }
          .padding()
        }
      }
    }
    .frame(width: 450, height: mode.isAdd ? 600 : 580)
  }
}
