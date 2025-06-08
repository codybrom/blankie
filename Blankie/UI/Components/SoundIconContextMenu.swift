//
//  SoundIconContextMenu.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  struct SoundIconContextMenu: View {
    let sound: Sound
    let editMode: EditMode
    let onEditSound: (Sound) -> Void
    let onEnterEditMode: (() -> Void)?
    @ObservedObject private var audioManager = AudioManager.shared

    @ViewBuilder
    var body: some View {
      Button(action: {
        onEditSound(sound)
      }) {
        Label("Customize", systemImage: "slider.horizontal.3")
      }

      if audioManager.soloModeSound?.id != sound.id {
        Button(action: {
          audioManager.toggleSoloMode(for: sound)
        }) {
          Label("Solo Mode", systemImage: "headphones")
        }
      } else {
        Button(action: {
          audioManager.exitSoloMode()
        }) {
          Label("Exit Solo Mode", systemImage: "headphones.slash")
        }
      }

      if editMode == .inactive, let onEnterEditMode = onEnterEditMode {
        Button(action: onEnterEditMode) {
          Label("Reorder", systemImage: "arrow.up.arrow.down")
        }
      }

      if sound.isCustom {
        Button(
          role: .destructive,
          action: {
            // Delete custom sound
            if let customSoundDataID = sound.customSoundDataID,
              let customSoundData = CustomSoundManager.shared.getCustomSound(by: customSoundDataID)
            {
              _ = CustomSoundManager.shared.deleteCustomSound(customSoundData)
            }
          }
        ) {
          Label("Delete Sound", systemImage: "trash")
        }
      } else {
        // Built-in sounds can only be hidden
        Button(action: {
          if sound.isHidden {
            audioManager.showSound(sound)
          } else {
            audioManager.hideSound(sound)
          }
        }) {
          Label(
            sound.isHidden ? "Show Sound" : "Hide Sound",
            systemImage: sound.isHidden ? "eye" : "eye.slash"
          )
        }
      }
    }
  }
#endif
