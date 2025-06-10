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
    let soundName = builtInSound?.title ?? sound?.title ?? "Unknown"
    print("🎵 SoundSheet: Starting preview for '\(soundName)' (isDisappearing: \(isDisappearing))")

    // Don't start preview if sheet is disappearing
    guard !isDisappearing else {
      print("🎵 SoundSheet: Skipping preview start - sheet is disappearing")
      return
    }

    Task { @MainActor in
      print("🎵 SoundSheet: Preview task started for '\(soundName)'")
      prepareForPreview()
      createPreviewSound()
      await startPreviewPlayback()
      print("🎵 SoundSheet: Preview started successfully for '\(soundName)'")
    }
  }

  private func prepareForPreview() {
    // Save current solo mode sound if any (for restoration after preview)
    previousSoloModeSound = AudioManager.shared.soloModeSound

    // Exit any existing solo mode first (but don't change global playback state)
    if AudioManager.shared.soloModeSound != nil {
      AudioManager.shared.exitSoloModeWithoutResuming()
    }

    // Note: We don't change global playback state here since preview mode handles it
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

    // Don't pause the sound here - preview mode will handle playback coordination
    // We want to preserve the current playback position

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

    // Note: We don't modify isSelected state during preview to avoid triggering auto-play logic

    // Apply current sheet settings as temporary customization before starting preview
    applyTemporaryCustomizationForPreview()

    // Enter preview mode (separate from solo mode)
    AudioManager.shared.enterPreviewMode(for: preview)
  }

  private func applyTemporaryCustomizationForPreview() {
    guard let preview = previewSound else { return }

    // Create temporary customization with current sheet settings
    var tempCustomization =
      SoundCustomizationManager.shared.getCustomization(for: preview.fileName)
      ?? SoundCustomization(fileName: preview.fileName)

    // Apply the current sheet settings
    tempCustomization.normalizeAudio = normalizeAudio
    tempCustomization.volumeAdjustment = volumeAdjustment
    tempCustomization.randomizeStartPosition = randomizeStartPosition

    // For customize and edit modes, also apply name and icon if changed
    switch mode {
    case .customize(let sound):
      if soundName != sound.title {
        tempCustomization.customTitle = soundName
      }
      if selectedIcon != sound.systemIconName {
        tempCustomization.customIconName = selectedIcon
      }
    case .edit:
      tempCustomization.customTitle = soundName
      tempCustomization.customIconName = selectedIcon
    case .add:
      tempCustomization.customTitle = soundName
      tempCustomization.customIconName = selectedIcon
    }

    // Apply the temporary customization
    SoundCustomizationManager.shared.updateTemporaryCustomization(tempCustomization)

    print(
      "🎵 SoundSheet: Applied temporary customization for preview - normalize: \(normalizeAudio), volume: \(volumeAdjustment)"
    )
  }

  internal func stopPreview() {
    let soundName = builtInSound?.title ?? sound?.title ?? "Unknown"
    print("🎵 SoundSheet: Stopping preview for '\(soundName)'")

    Task { @MainActor in
      if let preview = previewSound {
        print("🎵 SoundSheet: Cleaning up preview sound '\(preview.title)'")

        // Exit preview mode (this restores all original states)
        AudioManager.shared.exitPreviewMode()

        // If we had a previous solo mode sound, restore it
        if let previousSolo = previousSoloModeSound {
          print("🎵 SoundSheet: Restoring previous solo mode for '\(previousSolo.title)'")
          AudioManager.shared.enterSoloMode(for: previousSolo)
        }

        // Restore original customization settings
        if case .customize(let originalSound) = mode {
          // Don't restore anything here - let the save/cancel actions handle it
          // Just trigger update to reflect any changes
          originalSound.objectWillChange.send()
        }

        // Clean up preview sound for add/edit modes
        if case .add = mode {
          // For add mode, clean up the temporary preview sound
          preview.player?.stop()
          preview.player = nil
        } else if case .edit = mode {
          // For edit mode, clean up the temporary preview sound
          preview.player?.stop()
          preview.player = nil
        }
        // For customize mode, the preview sound is the same as the original sound,
        // so we don't clean up the player
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
      // Apply current sheet settings as temporary customization
      applyTemporaryCustomizationForPreview()

      // Update the sound's volume based on the new customization
      preview.updateVolume()

      print("🎵 SoundSheet: Preview volume updated with current sheet settings")
    }
  }

}

// MARK: - Helper Extensions

extension Float {
  func clamped(to range: ClosedRange<Float>) -> Float {
    return min(max(self, range.lowerBound), range.upperBound)
  }
}
