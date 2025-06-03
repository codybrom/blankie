//
//  SoundSheet+Actions.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import SwiftData
import SwiftUI

extension SoundSheet {
  // MARK: - Actions

  func performAction() {
    switch mode {
    case .add:
      importSound()
    case .edit(let sound):
      saveChanges(sound)
    case .customize(let sound):
      saveCustomization(sound)
    }
  }

  func importSound() {
    guard let selectedFile = selectedFile,
      !soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    else {
      return
    }

    isProcessing = true

    // Capture values before Task to avoid sendability issues
    let file = selectedFile
    let title = soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    let icon = selectedIcon

    Task.detached {
      let result = await CustomSoundManager.shared.importSound(
        from: file,
        title: title,
        iconName: icon
      )

      // Extract sendable values from the result
      let success: Bool
      let errorMessage: String?

      switch result {
      case .success:
        success = true
        errorMessage = nil
      case .failure(let error):
        success = false
        errorMessage = error.localizedDescription
      }

      await MainActor.run {
        isProcessing = false

        if success {
          dismiss()
        } else if let message = errorMessage {
          importError = NSError(
            domain: "SoundImport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]
          )
          showingError = true
        }
      }
    }
  }

  func saveChanges(_ sound: CustomSoundData) {
    sound.title = soundName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    sound.systemIconName = selectedIcon

    do {
      try modelContext.save()

      // Handle color customization
      if let selectedColor = selectedColor {
        SoundCustomizationManager.shared.setCustomColor(
          selectedColor.color?.toString, for: sound.fileName)
      } else {
        // Remove color customization if "Current Theme" is selected
        SoundCustomizationManager.shared.setCustomColor(nil, for: sound.fileName)
      }

      // Update the active sound object if it exists
      if let customSound = AudioManager.shared.sounds.first(where: {
        ($0 as? CustomSound)?.customSoundData.id == sound.id
      }) as? CustomSound {
        customSound.updateFromData()
        customSound.updateFromCustomization()
      }

      dismiss()
    } catch {
      importError = error
      showingError = true
    }
  }

  func saveCustomization(_ sound: Sound) {
    // Only save if there are actual customizations
    let hasCustomName = soundName != sound.originalTitle
    let hasCustomIcon = selectedIcon != sound.originalSystemIconName
    let hasCustomColor = selectedColor != nil

    if hasCustomName || hasCustomIcon || hasCustomColor {
      // Use the manager's methods to set customizations
      if hasCustomName {
        SoundCustomizationManager.shared.setCustomTitle(soundName, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomTitle(nil, for: sound.fileName)
      }

      if hasCustomIcon {
        SoundCustomizationManager.shared.setCustomIcon(selectedIcon, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomIcon(nil, for: sound.fileName)
      }

      if hasCustomColor {
        SoundCustomizationManager.shared.setCustomColor(
          selectedColor?.color?.toString, for: sound.fileName)
      } else {
        SoundCustomizationManager.shared.setCustomColor(nil, for: sound.fileName)
      }
    } else {
      // Remove all customizations if there are no changes
      SoundCustomizationManager.shared.resetCustomizations(for: sound.fileName)
    }

    // Update the sound object to reflect changes
    sound.updateFromCustomization()

    dismiss()
  }
}
