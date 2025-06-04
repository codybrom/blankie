//
//  Sound.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import AVFoundation
import Combine
import SwiftUI

/// Represents a single sound with its associated properties and playback controls.
open class Sound: ObservableObject, Identifiable {

  public let id = UUID()
  let originalTitle: String
  let originalSystemIconName: String
  let fileName: String
  let fileExtension: String
  let lufs: Float?
  let normalizationFactor: Float?

  // Properties for unified sound model
  let isCustom: Bool
  let fileURL: URL?
  let dateAdded: Date?
  let customSoundDataID: UUID?  // For linking to SwiftData if needed

  // Computed properties that respect customizations
  var title: String {
    return SoundCustomizationManager.shared.getCustomization(for: fileName)?.effectiveTitle(
      originalTitle: originalTitle) ?? originalTitle
  }

  var systemIconName: String {
    return SoundCustomizationManager.shared.getCustomization(for: fileName)?.effectiveIconName(
      originalIconName: originalSystemIconName) ?? originalSystemIconName
  }

  var customColor: Color? {
    return SoundCustomizationManager.shared.getCustomization(for: fileName)?.effectiveColor
  }

  @Published var isSelected = false {
    didSet {
      UserDefaults.standard.set(isSelected, forKey: "\(fileName)_isSelected")
      print("🔊 Sound: \(fileName) -  isSelected set to \(isSelected)")

      // If sound was just selected, start playing it immediately when playback becomes active
      // Only do this after AudioManager is fully initialized to avoid circular dependency
      if isSelected && oldValue == false {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }

          // Check if playback is active, or will become active soon
          if AudioManager.shared.isGloballyPlaying {
            print(
              "🎵 Sound: Auto-playing newly selected sound '\(self.fileName)' during active playback"
            )
            self.loadSound()
            self.play()
          } else {
            // If playback isn't active yet, wait a bit for auto-start to kick in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
              guard let self = self,
                AudioManager.shared.isGloballyPlaying
              else { return }
              print(
                "🎵 Sound: Auto-playing newly selected sound '\(self.fileName)' after auto-start")
              self.loadSound()
              self.play()
            }
          }
        }
      }

      // If sound was just deselected, stop playing it immediately
      if !isSelected && oldValue == true {
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          print("🎵 Sound: Auto-stopping newly deselected sound '\(self.fileName)'")
          self.pause(immediate: true)
        }
      }
    }
  }

  @Published var isHidden = false {
    didSet {
      UserDefaults.standard.set(isHidden, forKey: "\(fileName)_isHidden")
      print("🔊 Sound: \(fileName) -  isHidden set to \(isHidden)")
    }
  }

  @Published var customOrder: Int = 0 {
    didSet {
      UserDefaults.standard.set(customOrder, forKey: "\(fileName)_customOrder")
      print("🔊 Sound: \(fileName) -  customOrder set to \(customOrder)")
    }
  }

  internal var volumeDebounceTimer: Timer?
  internal var updateVolumeLogTimer: Timer?

  @Published var volume: Float = 1.0 {
    didSet {
      guard volume >= 0 && volume <= 1 else {
        print("❌ Sound: Invalid volume for '\(fileName)'")
        ErrorReporter.shared.report(AudioError.invalidVolume)
        volume = oldValue
        return
      }

      if player?.isPlaying == true {
        updateVolume()
      }

      // Debounce the save to UserDefaults
      volumeDebounceTimer?.invalidate()
      volumeDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) {
        [weak self] _ in
        guard let self = self else { return }
        UserDefaults.standard.set(self.volume, forKey: "\(self.fileName)_volume")
        print("🔊 Sound: \(self.fileName) final volume saved as \(self.volume)")
      }
    }
  }

  var player: AVAudioPlayer?
  internal let fadeDuration: TimeInterval = 0.1
  internal var fadeTimer: Timer?
  internal var fadeStartVolume: Float = 0
  internal var targetVolume: Float = 1.0
  private var globalSettingsObserver: AnyCancellable?
  private var customizationObserver: AnyCancellable?
  internal var isResetting = false

  init(
    title: String, systemIconName: String, fileName: String, fileExtension: String = "mp3",
    defaultOrder: Int = 0, lufs: Float? = nil, normalizationFactor: Float? = nil,
    isCustom: Bool = false, fileURL: URL? = nil, dateAdded: Date? = nil,
    customSoundDataID: UUID? = nil
  ) {
    self.originalTitle = title
    self.originalSystemIconName = systemIconName
    self.fileName = fileName
    self.fileExtension = fileExtension
    self.lufs = lufs
    self.normalizationFactor = normalizationFactor
    self.isCustom = isCustom
    self.fileURL = fileURL
    self.dateAdded = dateAdded
    self.customSoundDataID = customSoundDataID

    // Restore saved volume
    self.volume = UserDefaults.standard.float(forKey: "\(fileName)_volume")
    if self.volume == 0 {
      self.volume = 1.0
    }

    // Restore selected state
    self.isSelected = UserDefaults.standard.bool(forKey: "\(fileName)_isSelected")

    // Restore hidden state
    self.isHidden = UserDefaults.standard.bool(forKey: "\(fileName)_isHidden")

    // Restore custom order (use default order if not set)
    if UserDefaults.standard.object(forKey: "\(fileName)_customOrder") != nil {
      self.customOrder = UserDefaults.standard.integer(forKey: "\(fileName)_customOrder")
    } else {
      self.customOrder = defaultOrder
    }

    // Observe "All Sounds" volume changes
    globalSettingsObserver = GlobalSettings.shared.$volume
      .sink { [weak self] _ in
        self?.updateVolume()
      }

    // Observe customization changes to trigger UI updates
    customizationObserver = SoundCustomizationManager.shared.objectWillChange
      .sink { [weak self] _ in
        DispatchQueue.main.async {
          self?.objectWillChange.send()
        }
      }

    // Don't load sound immediately to avoid triggering audio session during initialization
    // loadSound() will be called lazily when needed
  }

  open func loadSound() {
    print("🔍 Sound: Loading '\(fileName).\(fileExtension)'")

    // Determine the URL based on whether this is a custom sound
    let url: URL?
    if isCustom, let customURL = fileURL {
      url = customURL
      print("🔍 Sound: Loading custom sound from: \(customURL.path)")
    } else {
      url = Bundle.main.url(forResource: fileName, withExtension: fileExtension)
      print("🔍 Sound: Loading built-in sound from bundle")
    }

    guard let soundURL = url else {
      print("❌ Sound: File not found for '\(fileName).\(fileExtension)'")
      ErrorReporter.shared.report(AudioError.fileNotFound)
      return
    }

    do {
      player = try AVAudioPlayer(contentsOf: soundURL)
      player?.numberOfLoops = -1
      player?.enableRate = false  // Disable rate/pitch adjustment
      let prepareSuccess = player?.prepareToPlay() ?? false
      print("🔍 Sound: Prepare to play result for '\(fileName)': \(prepareSuccess)")
      // Set initial volume with normalization
      updateVolume()
      print(
        "🔊 Sound: Loaded sound '\(fileName).\(fileExtension)' with volume: \(player?.volume ?? 0)")
    } catch {
      print("❌ Sound: Failed to load '\(fileName).\(fileExtension)': \(error.localizedDescription)")
      ErrorReporter.shared.report(error)
    }
  }

  func toggle() {
    isSelected.toggle()
  }

  private func updatePresetState() {
    Task { @MainActor in
      PresetManager.shared.updateCurrentPresetState()
    }
  }

  deinit {
    print("🔄 Sound: Deinitialized '\(fileName)'")
    globalSettingsObserver?.cancel()
    customizationObserver?.cancel()
    fadeTimer?.invalidate()
    volumeDebounceTimer?.invalidate()
    updateVolumeLogTimer?.invalidate()
  }
}
