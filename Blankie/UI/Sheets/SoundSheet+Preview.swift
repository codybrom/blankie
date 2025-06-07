//
//  SoundSheet+Preview.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import SwiftUI

extension SoundSheet {
  // MARK: - Preview Methods

  internal func startPreview() {
    Task { @MainActor in
      prepareForPreview()
      createPreviewSound()
      await startPreviewPlayback()
    }
  }

  private func prepareForPreview() {
    // Exit any existing solo mode first
    if AudioManager.shared.soloModeSound != nil {
      AudioManager.shared.exitSoloMode()
    }

    // Pause all sounds
    AudioManager.shared.setGlobalPlaybackState(false)
  }

  private func createPreviewSound() {
    switch mode {
    case .add:
      // Can't preview without importing first
      isPreviewing = false
      return

    case .edit(let customSound):
      createEditPreview(customSound)

    case .customize(let sound):
      createCustomizePreview(sound)
    }
  }

  private func createEditPreview(_ customSound: CustomSoundData) {
    guard let fileURL = CustomSoundManager.shared.fileURL(for: customSound) else { return }

    // Create a preview Sound with the edited settings
    let preview = Sound(
      title: soundName,
      systemIconName: selectedIcon,
      fileName: customSound.fileName,
      fileExtension: customSound.fileExtension,
      lufs: customSound.detectedLUFS,
      normalizationFactor: customSound.normalizationFactor,
      isCustom: true,
      fileURL: fileURL,
      dateAdded: customSound.dateAdded,
      customSoundDataID: customSound.id
    )

    // Apply the preview settings via customization
    var tempCustomization = SoundCustomization(fileName: customSound.fileName)
    tempCustomization.customTitle = soundName
    tempCustomization.customIconName = selectedIcon
    tempCustomization.randomizeStartPosition = randomizeStartPosition
    tempCustomization.normalizeAudio = normalizeAudio
    tempCustomization.volumeAdjustment = volumeAdjustment
    SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

    preview.volume = 1.0
    previewSound = preview
  }

  private func createCustomizePreview(_ sound: Sound) {
    // Stop the existing sound if it's playing
    if sound.player?.isPlaying == true {
      sound.pause(immediate: true)
    }

    // Save the original customization
    originalCustomization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)

    // Apply current settings as temporary customization
    var tempCustomization = originalCustomization ?? SoundCustomization(fileName: sound.fileName)
    tempCustomization.normalizeAudio = normalizeAudio
    tempCustomization.volumeAdjustment = volumeAdjustment
    tempCustomization.randomizeStartPosition = randomizeStartPosition
    SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

    previewSound = sound
  }

  private func startPreviewPlayback() async {
    guard let preview = previewSound else { return }

    // Load the sound first
    preview.loadSound()

    // Enter solo mode and start playback
    AudioManager.shared.enterSoloMode(for: preview)
    AudioManager.shared.setGlobalPlaybackState(true)
  }

  internal func stopPreview() {
    Task { @MainActor in
      // Exit solo mode
      if let preview = previewSound {
        AudioManager.shared.exitSoloMode()
        AudioManager.shared.setGlobalPlaybackState(false)

        // Restore original customization settings for built-in sounds
        if case .customize(let originalSound) = mode {
          // Restore the original customization
          if let original = originalCustomization {
            SoundCustomizationManager.shared.updateTemporaryCustomization(original)
          } else {
            // If there was no original customization, remove it
            SoundCustomizationManager.shared.removeCustomization(for: originalSound.fileName)
          }
          // Trigger update on the sound
          originalSound.objectWillChange.send()
        }

        // Clean up the preview sound
        preview.player?.stop()
        preview.player = nil
      }

      previewSound = nil
    }
  }

  internal func updatePreviewVolume() {
    // Update volume if currently previewing
    if isPreviewing, let preview = previewSound {
      print(
        "🎵 SoundSheet: Updating preview volume - normalize: \(normalizeAudio), adjustment: \(volumeAdjustment)"
      )

      Task { @MainActor in
        switch mode {
        case .edit:
          // Update the customization for the preview sound
          if preview.isCustom {
            var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
              for: preview.fileName)
            customization.normalizeAudio = normalizeAudio
            customization.volumeAdjustment = volumeAdjustment
            SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

            // Force volume update
            preview.updateVolume()
            print("🎵 SoundSheet: Updated custom sound preview volume")

            // Log player state
            if let player = preview.player {
              print(
                "🎵 SoundSheet: Custom sound player volume: \(player.volume), isPlaying: \(player.isPlaying)"
              )
            }
          }

        case .customize(let sound):
          // For built-in sounds, we need to update the customization and then force a volume update
          var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
            for: sound.fileName)
          customization.normalizeAudio = normalizeAudio
          customization.volumeAdjustment = volumeAdjustment

          // Update temporarily without saving
          SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

          // Small delay to ensure the customization manager has updated
          try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

          // Force the sound to update its volume
          preview.updateVolume()
          print("🎵 SoundSheet: Updated built-in sound preview volume for \(sound.fileName)")

          // Log player state and customization
          if let player = preview.player {
            print(
              "🎵 SoundSheet: Built-in sound player volume: \(player.volume), isPlaying: \(player.isPlaying)"
            )
          }

          // Verify the customization was applied
          if let updatedCustomization = SoundCustomizationManager.shared.getCustomization(
            for: sound.fileName)
          {
            print(
              "🎵 SoundSheet: Verified customization - normalize: \(updatedCustomization.normalizeAudio ?? true), adjustment: \(updatedCustomization.volumeAdjustment ?? 1.0)"
            )
          }

        case .add:
          break
        }
      }
    }
  }
}

// MARK: - Helper Extensions

extension Float {
  func clamped(to range: ClosedRange<Float>) -> Float {
    return min(max(self, range.lowerBound), range.upperBound)
  }
}
