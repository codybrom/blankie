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
  @Published private(set) var isGloballyPlaying: Bool = false
  @Published var soloModeSound: Sound?
  @Published var hasSelectedSounds: Bool = false
  var soloModeOriginalVolume: Float?
  var soloModeOriginalSelection: Bool?

  var modelContext: ModelContext?
  let nowPlayingManager = NowPlayingManager()
  @MainActor private var isInitializing = true
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

          // Update Now Playing info with preset name
          self.nowPlayingManager.updateInfo(
            presetName: PresetManager.shared.currentPreset?.name,
            isPlaying: true
          )
        }
      } else {
        // Ensure we're in a paused state
        self.isGloballyPlaying = false
        self.nowPlayingManager.updateInfo(
          presetName: PresetManager.shared.currentPreset?.name,
          isPlaying: false
        )
      }
    }
  }

  func setPlaybackState(_ playing: Bool, forceUpdate: Bool = false) {
    Task { @MainActor [weak self] in
      guard let self = self else { return }

      guard !self.isInitializing || forceUpdate else {
        print("🎵 AudioManager: Ignoring setPlaybackState during initialization")
        return
      }

      if self.isGloballyPlaying != playing {
        print(
          "🎵 AudioManager: Setting playback state to \(playing) - Current global state: \(self.isGloballyPlaying)"
        )
        self.isGloballyPlaying = playing

        if playing {
          self.playSelected()
        } else {
          self.pauseAll()
        }
        self.nowPlayingManager.updateInfo(
          presetName: PresetManager.shared.currentPreset?.name,
          isPlaying: playing
        )
      } else {
        print("🎵 AudioManager: setPlaybackState called, but state is the same \(playing), ignoring")
      }
    }
  }

  // Update playSelected to check global state
  func playSelected() {
    print("🎵 AudioManager: Playing selected sounds")
    guard isGloballyPlaying else {
      print("🎵 AudioManager: Not playing sounds because global playback is disabled")
      return
    }

    #if os(iOS) || os(visionOS)
      // Setup audio session when starting playback
      setupAudioSessionForPlayback()
      // Setup audio session observers on first playback
      setupAudioSessionObservers()
    #endif

    // If in solo mode, play only the solo sound
    if let soloSound = soloModeSound {
      print("  - In solo mode, playing only '\(soloSound.fileName)'")

      // Play the solo sound at its current volume
      soloSound.play()

      // Update Now Playing info for solo mode
      nowPlayingManager.updateInfo(
        presetName: soloSound.title,
        isPlaying: true
      )
      return
    }

    // Normal mode: play all selected sounds according to preset
    for sound in sounds where sound.isSelected && !sound.isHidden {
      print(
        "  - About to play '\(sound.fileName)', isSelected: \(sound.isSelected), player exists: \(sound.player != nil)"
      )
      sound.play()
      print(
        "  - After play call for '\(sound.fileName)', player playing: \(sound.player?.isPlaying ?? false), volume: \(sound.player?.volume ?? 0)"
      )
    }

    // Update Now Playing info with current preset name
    self.nowPlayingManager.updateInfo(
      presetName: PresetManager.shared.currentPreset?.name,
      isPlaying: true
    )
  }

  func pauseAll() {
    print("🎵 AudioManager: Pausing all sounds")
    print("  - Current global play state: \(isGloballyPlaying)")

    sounds.forEach { sound in
      if sound.isSelected {
        print("  - Pausing '\(sound.fileName)'")
        sound.pause()
      }
    }

    #if os(iOS) || os(visionOS)
      // Deactivate audio session when stopping to allow other apps to play
      do {
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        print("🎵 AudioManager: Audio session deactivated")
      } catch {
        print("❌ AudioManager: Failed to deactivate audio session: \(error)")
      }
    #endif

    print("🎵 AudioManager: Pause all complete")
  }

  // Public method for changing playback state
  @MainActor
  public func setGlobalPlaybackState(_ playing: Bool, forceUpdate: Bool = false) {
    guard !isInitializing || forceUpdate else {
      print("🎵 AudioManager: Ignoring setPlaybackState during initialization")
      return
    }

    print(
      "🎵 AudioManager: Setting playback state to \(playing) - Current global state: \(self.isGloballyPlaying)"
    )

    // Update state first
    self.isGloballyPlaying = playing

    // Then handle playback
    if playing {
      self.playSelected()
    } else {
      self.pauseAll()
    }

    // Always update Now Playing info with current preset name
    let presetName =
      soloModeSound != nil
      ? soloModeSound!.title : PresetManager.shared.currentPreset?.name
    nowPlayingManager.updateInfo(
      presetName: presetName,
      isPlaying: isGloballyPlaying
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cleanup()
    print("🎵 AudioManager: Deinit called, cleanup performed")
  }
}
