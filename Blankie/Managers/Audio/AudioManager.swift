//
//  AudioManager.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import AVFoundation
import Combine
import MediaPlayer
import SwiftData
import SwiftUI

class AudioManager: ObservableObject {
  var cancellables = Set<AnyCancellable>()
  static let shared = AudioManager()
  var onReset: (() -> Void)?

  @Published var sounds: [Sound] = []
  @Published var isGloballyPlaying: Bool = false
  @Published var soloModeSound: Sound?
  @Published var hasSelectedSounds: Bool = false
  var soloModeOriginalVolume: Float?
  var soloModeOriginalSelection: Bool?

  // CarPlay Quick Mix Mode
  @Published var isCarPlayQuickMix: Bool = false
  struct QuickMixState {
    let sound: Sound
    let isSelected: Bool
    let volume: Float
  }
  var carPlayQuickMixOriginalStates: [QuickMixState] = []

  var modelContext: ModelContext?
  let nowPlayingManager = NowPlayingManager()
  @MainActor var isInitializing = true
  var customSoundObserver: AnyCancellable?
  #if os(iOS) || os(visionOS)
    var audioSessionObserversSetup = false
  #endif

  private init() {
    print("🎵 AudioManager: Initializing - START")

    // Only load sounds and state immediately - delay media controls and observers
    print("🎵 AudioManager: About to loadSounds()")
    loadSounds()
    print("🎵 AudioManager: About to loadSavedState()")
    loadSavedState()

    // Delay media controls and notification setup to avoid triggering audio session
    Task { @MainActor in
      // Longer delay to allow app to fully launch first
      try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

      print("🎵 AudioManager: About to setupMediaControls() (delayed)")
      self.setupMediaControls()
      print("🎵 AudioManager: About to setupNotificationObservers() (delayed)")
      self.setupNotificationObservers()
      print("🎵 AudioManager: About to setupSoundObservers() (delayed)")
      self.setupSoundObservers()

      self.isInitializing = false

      // Analyze custom sounds that might be missing profiles
      Task {
        await self.analyzeCustomSoundsIfNeeded()
      }

      // Restore solo mode if it was saved
      if let savedSoloFileName = GlobalSettings.shared.getSavedSoloModeFileName(),
        let soloSound = self.sounds.first(where: { $0.fileName == savedSoloFileName })
      {
        print("🎵 AudioManager: Restoring solo mode for '\(soloSound.title)'")
        self.enterSoloMode(for: soloSound)
      } else if GlobalSettings.shared.autoPlayOnLaunch {
        let hasSelectedSounds = self.sounds.contains { $0.isSelected }
        if hasSelectedSounds {
          // Set initial state
          self.isGloballyPlaying = true

          // Start playback
          self.playSelected()

          // Update Now Playing info with full preset details
          let currentPreset = PresetManager.shared.currentPreset
          self.nowPlayingManager.updateInfo(
            presetName: currentPreset?.name,
            creatorName: currentPreset?.creatorName,
            artworkData: currentPreset?.artworkData,
            isPlaying: true
          )
        }
      } else {
        // Ensure we're in a paused state
        self.isGloballyPlaying = false
        let currentPreset = PresetManager.shared.currentPreset
        self.nowPlayingManager.updateInfo(
          presetName: currentPreset?.name,
          creatorName: currentPreset?.creatorName,
          artworkData: currentPreset?.artworkData,
          isPlaying: false
        )
      }
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cleanup()
    print("🎵 AudioManager: Deinit called, cleanup performed")
  }
}
