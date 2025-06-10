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
    // Save current solo mode sound if any
    previousSoloModeSound = AudioManager.shared.soloModeSound

    // Exit any existing solo mode first
    if AudioManager.shared.soloModeSound != nil {
      AudioManager.shared.exitSoloModeWithoutResuming()
    }

    // Only pause all sounds if we weren't in solo mode
    if previousSoloModeSound == nil {
      AudioManager.shared.setGlobalPlaybackState(false)
    }
  }

  private func createPreviewSound() {
    switch mode {
    case .add:
      createAddPreview()

    case .edit(let customSound):
      createEditPreview(customSound)

    case .customize(let sound):
      createCustomizePreview(sound)
    }
  }

  private func createAddPreview() {
    guard let fileURL = selectedFile else {
      isPreviewing = false
      return
    }

    // Reset this flag for add mode
    wasPreviewSoundPlaying = false

    // Create a temporary preview sound
    let fileName = fileURL.deletingPathExtension().lastPathComponent
    let preview = Sound(
      title: soundName.isEmpty ? fileName : soundName,
      systemIconName: selectedIcon,
      fileName: fileName,
      fileExtension: fileURL.pathExtension,
      lufs: nil,
      normalizationFactor: 1.0,
      isCustom: true,
      fileURL: fileURL,
      dateAdded: Date(),
      customSoundDataID: nil
    )

    // Create and apply temporary customization with current settings
    var tempCustomization = SoundCustomization(fileName: fileName)
    tempCustomization.customTitle = soundName.isEmpty ? fileName : soundName
    tempCustomization.customIconName = selectedIcon
    tempCustomization.randomizeStartPosition = randomizeStartPosition
    tempCustomization.normalizeAudio = normalizeAudio
    tempCustomization.volumeAdjustment = volumeAdjustment
    SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

    // Set preview volume
    preview.volume = 1.0
    previewSound = preview
  }

  private func createEditPreview(_ customSound: CustomSoundData) {
    guard let fileURL = CustomSoundManager.shared.fileURL(for: customSound) else { return }

    // Reset this flag for edit mode
    wasPreviewSoundPlaying = false

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
    // Track if this sound was playing before preview
    wasPreviewSoundPlaying = sound.player?.isPlaying == true && sound.isSelected

    // Don't stop the sound here - let solo mode handle the transition
    // This preserves the player state for proper resumption

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

    // For customize mode, ensure the sound maintains its selection state
    // This helps exitSoloMode know whether to resume it
    if case .customize = mode, wasPreviewSoundPlaying {
      preview.isSelected = true
    }

    // Enter solo mode and start playback
    AudioManager.shared.enterSoloMode(for: preview)
    AudioManager.shared.setGlobalPlaybackState(true)
  }

  internal func stopPreview() {
    Task { @MainActor in
      if let preview = previewSound {
        // Store the playing state before making any changes
        let shouldResumePlayback: Bool
        if case .customize = mode {
          shouldResumePlayback = wasPreviewSoundPlaying
        } else {
          shouldResumePlayback = false
        }

        // If we had a previous solo mode sound, restore it
        if let previousSolo = previousSoloModeSound {
          // Exit current solo mode without resuming
          AudioManager.shared.exitSoloModeWithoutResuming()

          // Enter solo mode for the previous sound
          AudioManager.shared.enterSoloMode(for: previousSolo)
        } else {
          // No previous solo mode - exit normally to resume previous playback
          AudioManager.shared.exitSoloMode()
        }

        // Restore original customization settings
        if case .customize(let originalSound) = mode {
          // Restore the original customization
          if let original = originalCustomization {
            SoundCustomizationManager.shared.updateTemporaryCustomization(original)
          } else {
            // If there was no original customization, remove it
            SoundCustomizationManager.shared.removeCustomization(for: originalSound.fileName)
          }

          // If the sound should be playing, ensure it's in the correct state
          if shouldResumePlayback {
            // Make sure the sound maintains its selected state
            originalSound.isSelected = true

            // Force UI update
            originalSound.objectWillChange.send()

            // If global playback is on but the sound isn't playing, start it
            if AudioManager.shared.isGloballyPlaying && originalSound.player?.isPlaying != true {
              originalSound.play()
            }
          } else {
            // Trigger update to reflect customization changes
            originalSound.objectWillChange.send()
          }
        }

        // Clean up the preview sound
        // For customize mode with a playing sound, don't clean up the player
        if case .customize = mode {
          // The player is shared with the original sound, don't clean it up
        } else {
          // For add/edit modes, clean up the player
          preview.player?.stop()
          preview.player = nil
        }
      }

      previewSound = nil
      previousSoloModeSound = nil
      wasPreviewSoundPlaying = false
    }
  }

  internal func updatePreviewVolume() {
    guard isPreviewing, let preview = previewSound else { return }

    print(
      "🎵 SoundSheet: Updating preview volume - normalize: \(normalizeAudio), adjustment: \(volumeAdjustment)"
    )

    Task { @MainActor in
      switch mode {
      case .edit:
        await updateEditPreviewVolume(preview)
      case .customize(let sound):
        await updateCustomizePreviewVolume(preview, sound)
      case .add:
        updateAddPreviewVolume(preview)
      }
    }
  }

  private func updateEditPreviewVolume(_ preview: Sound) async {
    guard preview.isCustom else { return }

    var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
      for: preview.fileName)
    customization.normalizeAudio = normalizeAudio
    customization.volumeAdjustment = volumeAdjustment
    SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

    preview.updateVolume()
    print("🎵 SoundSheet: Updated custom sound preview volume")

    if let player = preview.player {
      print(
        "🎵 SoundSheet: Custom sound player volume: \(player.volume), isPlaying: \(player.isPlaying)"
      )
    }
  }

  private func updateCustomizePreviewVolume(_ preview: Sound, _ sound: Sound) async {
    var customization = SoundCustomizationManager.shared.getOrCreateCustomization(
      for: sound.fileName)
    customization.normalizeAudio = normalizeAudio
    customization.volumeAdjustment = volumeAdjustment

    SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

    try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

    preview.updateVolume()
    print("🎵 SoundSheet: Updated built-in sound preview volume for \(sound.fileName)")

    if let player = preview.player {
      print(
        "🎵 SoundSheet: Built-in sound player volume: \(player.volume), isPlaying: \(player.isPlaying)"
      )
    }

    if let updatedCustomization = SoundCustomizationManager.shared.getCustomization(
      for: sound.fileName)
    {
      print(
        "🎵 SoundSheet: Verified customization - normalize: \(updatedCustomization.normalizeAudio ?? true), adjustment: \(updatedCustomization.volumeAdjustment ?? 1.0)"
      )
    }
  }

  private func updateAddPreviewVolume(_ preview: Sound) {
    guard let fileURL = selectedFile else { return }

    let fileName = fileURL.deletingPathExtension().lastPathComponent
    var customization = SoundCustomizationManager.shared.getOrCreateCustomization(for: fileName)
    customization.normalizeAudio = normalizeAudio
    customization.volumeAdjustment = volumeAdjustment
    customization.randomizeStartPosition = randomizeStartPosition
    SoundCustomizationManager.shared.updateTemporaryCustomization(customization)

    preview.updateVolume()
    print("🎵 SoundSheet: Updated add mode preview settings")
  }
}

// MARK: - Helper Extensions

extension Float {
  func clamped(to range: ClosedRange<Float>) -> Float {
    return min(max(self, range.lowerBound), range.upperBound)
  }
}
