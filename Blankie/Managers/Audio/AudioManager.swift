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
  private var cancellables = Set<AnyCancellable>()
  static let shared = AudioManager()
  var onReset: (() -> Void)?

  @Published var sounds: [Sound] = []
  @Published private(set) var isGloballyPlaying: Bool = false

  var modelContext: ModelContext?
  let nowPlayingManager = NowPlayingManager()
  @MainActor private var isInitializing = true
  private var customSoundObserver: AnyCancellable?

  private init() {
    print("🎵 AudioManager: Initializing")
    loadSounds()
    loadSavedState()
    setupMediaControls()
    setupNotificationObservers()
    setupSoundObservers()

    // Handle autoplay behavior after a slight delay to ensure proper initialization
    Task { @MainActor in
      // Short delay to allow everything to initialize
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

      self.isInitializing = false

      if !GlobalSettings.shared.alwaysStartPaused {
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

  func setupSoundObservers() {
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

  #if os(iOS) || os(visionOS)
    func setupAudioSessionForPlayback() {
      #if CARPLAY_ENABLED
        let isCarPlayConnected = CarPlayInterface.shared.isConnected
      #else
        let isCarPlayConnected = false
      #endif

      AudioSessionManager.shared.setupForPlayback(
        mixWithOthers: GlobalSettings.shared.mixWithOthers,
        isCarPlayConnected: isCarPlayConnected
      )
    }
  #endif

  // Update playSelected to check global state
  private func playSelected() {
    print("🎵 AudioManager: Playing selected sounds")
    guard isGloballyPlaying else {
      print("🎵 AudioManager: Not playing sounds because global playback is disabled")
      return
    }

    #if os(iOS) || os(visionOS)
      // Setup audio session when starting playback
      setupAudioSessionForPlayback()
    #endif

    for sound in sounds where sound.isSelected && !sound.isHidden {
      print("  - Playing '\(sound.fileName)'")
      sound.play()
    }

    // Update Now Playing info with current preset name
    self.nowPlayingManager.updateInfo(
      presetName: PresetManager.shared.currentPreset?.name,
      isPlaying: true
    )
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

  public func updateNowPlayingInfoForPreset(presetName: String? = nil) {
    nowPlayingManager.updateInfo(
      presetName: presetName,
      isPlaying: isGloballyPlaying
    )
  }

  func updateNowPlayingState() {
    nowPlayingManager.updatePlaybackState(isPlaying: isGloballyPlaying)
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
  @MainActor func togglePlayback() {
    print("🎵 AudioManager: Toggling playback")
    print("  - Current state (pre-toggle): \(isGloballyPlaying)")
    setGlobalPlaybackState(!isGloballyPlaying)
    print("  - New state (post-toggle): \(isGloballyPlaying)")
  }

  @MainActor
  func resetSounds() {
    print("🎵 AudioManager: Resetting all sounds")

    // First pause all sounds immediately
    sounds.forEach { sound in
      print("  - Stopping '\(sound.fileName)'")
      sound.pause(immediate: true)
    }
    setGlobalPlaybackState(false)
    // Reset all sounds
    sounds.forEach { sound in
      sound.volume = 1.0
      sound.isSelected = false
    }
    // Reset "All Sounds" volume
    GlobalSettings.shared.setVolume(1.0)

    // Call the reset callback
    onReset?()
    print("🎵 AudioManager: Reset complete")
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
    nowPlayingManager.updateInfo(
      presetName: PresetManager.shared.currentPreset?.name,
      isPlaying: isGloballyPlaying
    )
  }

  // MARK: - SwiftData Integration

  /// Set up the model context for accessing custom sounds
  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
    CustomSoundManager.shared.setModelContext(context)
    setupCustomSoundObservers()
    loadCustomSounds()
  }

  private func setupCustomSoundObservers() {
    // Observe custom sound changes
    customSoundObserver = NotificationCenter.default.publisher(for: .customSoundAdded)
      .merge(with: NotificationCenter.default.publisher(for: .customSoundDeleted))
      .sink { [weak self] _ in
        Task { @MainActor in
          self?.loadCustomSounds()
        }
      }
  }

  // MARK: - Sound Management

  /// Get visible sounds in their custom order
  func getVisibleSounds() -> [Sound] {
    return sounds.filter { !$0.isHidden }.sorted { $0.customOrder < $1.customOrder }
  }

  /// Move a sound to a new position
  func moveSound(from sourceIndex: Int, to destinationIndex: Int) {
    let hiddenSounds = sounds.filter { $0.isHidden }.sorted { $0.customOrder < $1.customOrder }
    guard sourceIndex < hiddenSounds.count && destinationIndex <= hiddenSounds.count else {
      return
    }

    // Update the custom order for hidden sounds
    var updatedSounds = hiddenSounds
    let movedSound = updatedSounds.remove(at: sourceIndex)
    updatedSounds.insert(movedSound, at: min(destinationIndex, updatedSounds.count))

    // Assign new order values
    for (index, sound) in updatedSounds.enumerated() {
      sound.customOrder = index
    }

    objectWillChange.send()
    print(
      "🎵 AudioManager: Moved sound '\(movedSound.fileName)' from \(sourceIndex) to \(destinationIndex)"
    )
  }

  /// Move a visible sound to a new position
  func moveVisibleSound(from sourceIndex: Int, to destinationIndex: Int) {
    let visibleSounds = getVisibleSounds()
    guard sourceIndex < visibleSounds.count && destinationIndex <= visibleSounds.count else {
      return
    }

    // Update the custom order for all visible sounds
    var updatedSounds = visibleSounds
    let movedSound = updatedSounds.remove(at: sourceIndex)
    updatedSounds.insert(movedSound, at: min(destinationIndex, updatedSounds.count))

    // Assign new order values
    for (index, sound) in updatedSounds.enumerated() {
      sound.customOrder = index
    }

    objectWillChange.send()
    print(
      "🎵 AudioManager: Moved visible sound '\(movedSound.fileName)' from \(sourceIndex) to \(destinationIndex)"
    )
  }

  /// Toggle the hidden state of a sound
  func toggleSoundVisibility(_ sound: Sound) {
    sound.isHidden.toggle()
    print(
      "🎵 AudioManager: Toggled visibility for '\(sound.fileName)' to \(sound.isHidden ? "hidden" : "visible")"
    )
  }

  /// Hide a sound
  func hideSound(_ sound: Sound) {
    sound.isHidden = true

    // If the sound is currently playing, stop it immediately
    if sound.isSelected {
      sound.pause(immediate: true)
    }

    objectWillChange.send()
    print("🎵 AudioManager: Hidden sound '\(sound.fileName)'")
  }

  /// Show a sound
  func showSound(_ sound: Sound) {
    sound.isHidden = false
    objectWillChange.send()
    print("🎵 AudioManager: Showed sound '\(sound.fileName)'")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    cleanup()
    print("🎵 AudioManager: Deinit called, cleanup performed")
  }
}
