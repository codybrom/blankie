//
//  AudioManager.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import AVFoundation
import Combine
import MediaPlayer
import SwiftUI

class AudioManager: ObservableObject {
  private var cancellables = Set<AnyCancellable>()
  static let shared = AudioManager()
  var onReset: (() -> Void)?

  @Published var sounds: [Sound] = []
  @Published private(set) var isGloballyPlaying: Bool = false

  private let commandCenter = MPRemoteCommandCenter.shared()
  private var nowPlayingInfo: [String: Any] = [:]
  private var isInitializing = true

  private init() {
    print("🎵 AudioManager: Initializing")
    loadSounds()
    loadSavedState()
    setupNowPlaying()
    setupMediaControls()
    setupNotificationObservers()
    setupSoundObservers()
    // Handle autoplay behavior after a slight delay to ensure proper initialization
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isInitializing = false

      if !GlobalSettings.shared.alwaysStartPaused {
        let hasSelectedSounds = self.sounds.contains { $0.isSelected }
        if hasSelectedSounds {
          self.setPlaybackState(true)
        }
      }
    }
  }
  private func setupSoundObservers() {
    // Clear any existing observers
    cancellables.removeAll()
    // Set up new observers for each sound
    for sound in sounds {
      sound.objectWillChange
        .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
        .sink { [weak self] _ in
          guard self != nil else { return }
          Task { @MainActor in
            PresetManager.shared.updateCurrentPresetState()
          }
        }
        .store(in: &cancellables)
    }
  }
  func setPlaybackState(_ playing: Bool) {
    guard !isInitializing else {
      print("🎵 AudioManager: Ignoring setPlaybackState during initialization")
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

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
        self.updateNowPlayingInfo()
      } else {
        print("🎵 AudioManager: setPlaybackState called, but state is the same \(playing), ignoring")
      }
    }
  }
  private func loadSounds() {
    sounds = [
      Sound(title: "Rain", systemIconName: "cloud.rain", fileName: "rain"),
      Sound(title: "Storm", systemIconName: "cloud.bolt.rain", fileName: "storm"),
      Sound(title: "Wind", systemIconName: "wind", fileName: "wind"),
      Sound(title: "Waves", systemIconName: "water.waves", fileName: "waves"),
      Sound(title: "Stream", systemIconName: "humidity", fileName: "stream"),
      Sound(title: "Birds", systemIconName: "bird", fileName: "birds"),
      Sound(title: "Summer Night", systemIconName: "moon.stars.fill", fileName: "summer-night"),
      Sound(title: "Train", systemIconName: "tram.fill", fileName: "train"),
      Sound(title: "Boat", systemIconName: "sailboat.fill", fileName: "boat"),
      Sound(title: "City", systemIconName: "building.2", fileName: "city"),
      Sound(title: "Coffee Shop", systemIconName: "cup.and.saucer.fill", fileName: "coffee-shop"),
      Sound(title: "Fireplace", systemIconName: "fireplace", fileName: "fireplace"),
      Sound(title: "Pink Noise", systemIconName: "waveform.path", fileName: "pink-noise"),
      Sound(title: "White Noise", systemIconName: "waveform", fileName: "white-noise"),
    ]
  }
  private func setupMediaControls() {
    print("🎵 AudioManager: Setting up media controls")
    // Remove all previous handlers
    commandCenter.playCommand.removeTarget(nil)
    commandCenter.pauseCommand.removeTarget(nil)
    commandCenter.togglePlayPauseCommand.removeTarget(nil)

    // Add handlers
    commandCenter.playCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key play command received")
      self?.togglePlayback()
      return .success
    }
    commandCenter.pauseCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key pause command received")
      self?.togglePlayback()
      return .success
    }
    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      print("🎵 AudioManager: Media key toggle command received")
      self?.togglePlayback()
      return .success
    }
  }

  private func playSelected() {
    print("🎵 AudioManager: Playing selected sounds")
    for sound in sounds where sound.isSelected {
      print("  - Playing '\(sound.fileName)'")
      sound.play()
    }
    updateNowPlayingInfo()
  }
  private func loadSavedState() {
    guard let state = UserDefaults.standard.array(forKey: "soundState") as? [[String: Any]] else {
      return
    }
    for savedState in state {
      guard let fileName = savedState["fileName"] as? String,
        let sound = sounds.first(where: { $0.fileName == fileName })
      else {
        continue
      }
      sound.isSelected = savedState["isSelected"] as? Bool ?? false
      sound.volume = savedState["volume"] as? Float ?? 1.0
    }
  }

  private func setupNowPlaying() {
    print("🎵 AudioManager: Setting up Now Playing info")
    // Set up now playing info
    nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
    nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"

    // Optional: Add artwork
    if let image = NSImage(named: "AppIcon"),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    {
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
        NSImage(cgImage: cgImage, size: size)
      }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }
    updatePlaybackState()
  }
  private func updateNowPlayingInfo() {
    var nowPlayingInfo = [String: Any]()

    nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
    nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isGloballyPlaying ? 1.0 : 0.0

    // Add app icon as artwork
    if let image = NSImage(named: "AppIcon"),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    {
      let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
        NSImage(cgImage: cgImage, size: size)
      }
      nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    }

    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func updatePlaybackState() {
    // Update playback state
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isGloballyPlaying ? 1.0 : 0.0
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0  // Infinite for ambient sounds
    // Update the now playing info
    print(
      "🎵 AudioManager: Updating now playing state to \(isGloballyPlaying), "
        + "playbackRate: \(nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? -1)"
    )
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
  }

  private func setupNotificationObservers() {
    NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppTermination()
    }
  }
  private func handleAppTermination() {
    print("🎵 AudioManager: App is terminating, cleaning up")
    cleanup()
  }

  private func cleanup() {
    pauseAll()
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    print("🎵 AudioManager: Cleanup complete")
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
    print("🎵 AudioManager: Pause all complete")
  }
  func saveState() {
    let state = sounds.map { sound in
      [
        "id": sound.id.uuidString,
        "fileName": sound.fileName,
        "isSelected": sound.isSelected,
        "volume": sound.volume,
      ]
    }
    UserDefaults.standard.set(state, forKey: "soundState")
  }
  /// Toggles the playback state of all selected sounds
  func togglePlayback() {
    print("🎵 AudioManager: Toggling playback")
    print("  - Current state (pre-toggle): \(isGloballyPlaying)")
    setPlaybackState(!isGloballyPlaying)
    print("  - New state (post-toggle): \(isGloballyPlaying)")
  }

  func resetSounds() {
    print("🎵 AudioManager: Resetting all sounds")

    // First pause all sounds immediately
    sounds.forEach { sound in
      print("  - Stopping '\(sound.fileName)'")
      sound.pause(immediate: true)
    }
    setPlaybackState(false)
    // Reset all sounds
    sounds.forEach { sound in
      sound.volume = 1.0
      sound.isSelected = false
    }
    // Reset global volume
    GlobalSettings.shared.setVolume(1.0)

    // Call the reset callback
    onReset?()
    print("🎵 AudioManager: Reset complete")
  }

  // Public method for changing playback state
  @MainActor
  public func setGlobalPlaybackState(_ playing: Bool) {
    print("🎵 AudioManager: Setting playback state to \(playing)")
    isGloballyPlaying = playing

    if playing {
      print("🎵 AudioManager: Playing selected sounds")
      sounds.filter { $0.isSelected }.forEach { sound in
        print("  - Playing '\(sound.fileName)'")
        sound.play()
      }
    } else {
      pauseAll()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cleanup()
    print("🎵 AudioManager: Deinit called, cleanup performed")
  }
}
