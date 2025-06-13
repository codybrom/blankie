//
// PresetManager+ApplicationHelpers.swift
// Blankie
//
// Created by Cody Bromley on 6/9/25.
//

import Foundation

extension PresetManager {

  @MainActor func handleAlreadyActivePreset(_ preset: Preset) {
    print("🎛️ PresetManager: Preset already active, but still updating Now Playing info")
    print(
      "🎨 PresetManager: Artwork data: \(preset.artworkData != nil ? "✅ \(preset.artworkData!.count) bytes" : "❌ None")"
    )
    AudioManager.shared.updateNowPlayingInfoForPreset(
      presetName: preset.activeTitle,
      creatorName: preset.creatorName,
      artworkData: preset.artworkData
    )
  }

  @MainActor func preparePresetApplication(_ preset: Preset) {
    currentPreset = preset
    PresetStorage.saveLastActivePresetID(preset.id)

    print(
      "🎨 PresetManager: Updating Now Playing with artwork: \(preset.artworkData != nil ? "✅ \(preset.artworkData!.count) bytes" : "❌ None")"
    )
    AudioManager.shared.updateNowPlayingInfoForPreset(
      presetName: preset.activeTitle,
      creatorName: preset.creatorName,
      artworkData: preset.artworkData
    )
  }

  func executePresetApplication(preset: Preset, isInitialLoad: Bool) {
    let targetStates = preset.soundStates
    let wasPlaying = AudioManager.shared.isGloballyPlaying

    Task { @MainActor in
      if wasPlaying {
        AudioManager.shared.pauseAll()
        try? await Task.sleep(nanoseconds: 300_000_000)
      }

      applySoundStates(targetStates)

      if let soundOrder = preset.soundOrder {
        applySoundOrder(soundOrder)
      }

      try? await Task.sleep(nanoseconds: 100_000_000)

      let shouldAutoPlay = !isInitialLoad || GlobalSettings.shared.autoPlayOnLaunch
      if shouldAutoPlay && targetStates.contains(where: { $0.isSelected }) {
        AudioManager.shared.setGlobalPlaybackState(true)
      }
    }
  }
}
