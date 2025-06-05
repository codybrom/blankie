//
//  Sound+Playback.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import AVFoundation
import Foundation

// MARK: - Playback Controls
extension Sound {

  private var loadedPlayer: AVAudioPlayer? {
    if player == nil {
      loadSound()
    }
    return player
  }

  func play() {
    var player = loadedPlayer
    guard player != nil else {
      print("❌ Sound: No player available for '\(fileName)'")
      return
    }

    // Additional validation
    if !player!.prepareToPlay() {
      print("❌ Sound: Player not ready for '\(fileName)' - attempting to reload")
      loadSound()
      guard let reloadedPlayer = self.player else {
        print("❌ Sound: Failed to reload player for '\(fileName)'")
        return
      }
      if !reloadedPlayer.prepareToPlay() {
        print("❌ Sound: Player still not ready after reload for '\(fileName)'")
        return
      }
      // Update the local player reference to the reloaded one
      player = reloadedPlayer
    }

    // Ensure we have a valid player from this point
    guard let validPlayer = player else {
      print("❌ Sound: No valid player after validation for '\(fileName)'")
      return
    }

    // Check if randomize start position is enabled
    // Default to true for both custom and built-in sounds unless explicitly disabled
    let shouldRandomizeStart: Bool
    if let customization = SoundCustomizationManager.shared.getCustomization(for: fileName) {
      shouldRandomizeStart = customization.randomizeStartPosition ?? true
    } else {
      shouldRandomizeStart = true  // Default to true for all sounds
    }

    if shouldRandomizeStart {
      // Set a random start position within the sound's duration
      // Check if duration is valid (greater than 0 and not infinite/NaN)
      if validPlayer.duration > 0 && validPlayer.duration.isFinite {
        let randomPosition = Double.random(in: 0..<validPlayer.duration)
        validPlayer.currentTime = randomPosition
        print(
          "🎲 Sound: Starting '\(fileName)' at random position: \(randomPosition)s of \(validPlayer.duration)s"
        )
      } else {
        print(
          "⚠️ Sound: Cannot randomize start position for '\(fileName)' - invalid duration: \(validPlayer.duration)"
        )
      }
    }

    let success = validPlayer.play()
    if !success {
      print("❌ Sound: Failed to play '\(fileName)'")
      let error = NSError(
        domain: "SoundPlayback", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to play sound"])
      ErrorReporter.shared.report(AudioError.playbackFailed(error))
    } else {
      print("🔊 Sound: Playing '\(fileName)'")
    }
  }

  func pause(immediate: Bool = false) {
    if immediate {
      player?.stop()
      player?.currentTime = 0  // Reset to beginning for next play
      print("🔊 Sound: Immediately stopped '\(fileName)'")
    } else {
      player?.pause()
      print("🔊 Sound: Paused '\(fileName)'")
    }
  }

  func stop() {
    player?.stop()
    player?.currentTime = 0  // Reset to beginning for next play
    print("🔊 Sound: Stopped '\(fileName)'")
  }

  func fadeIn(duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
    guard let player = loadedPlayer else {
      completion?()
      return
    }

    print("🔊 Sound: Fading in '\(fileName)' over \(duration)s")

    // Store original volume level
    let originalVolume = player.volume
    player.volume = 0.0

    // Start playing if not already
    if !player.isPlaying {
      player.play()
    }

    // Fade in
    fadeTimer?.invalidate()
    fadeStartVolume = 0.0
    targetVolume = originalVolume

    let steps = Int(duration * 60)  // 60 steps per second
    let volumeIncrement = targetVolume / Float(steps)
    let stepDuration = duration / Double(steps)

    var currentStep = 0
    fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) {
      [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }

      currentStep += 1
      let newVolume = min(
        self.fadeStartVolume + (volumeIncrement * Float(currentStep)), self.targetVolume)
      self.player?.volume = newVolume

      if currentStep >= steps || newVolume >= self.targetVolume {
        timer.invalidate()
        self.player?.volume = self.targetVolume
        completion?()
      }
    }
  }

  func fadeOut(duration: TimeInterval = 0.5, completion: (() -> Void)? = nil) {
    guard let player = loadedPlayer, player.isPlaying else {
      completion?()
      return
    }

    print("🔊 Sound: Fading out '\(fileName)' over \(duration)s")

    fadeTimer?.invalidate()
    fadeStartVolume = player.volume
    targetVolume = 0.0

    let steps = Int(duration * 60)  // 60 steps per second
    let volumeDecrement = fadeStartVolume / Float(steps)
    let stepDuration = duration / Double(steps)

    var currentStep = 0
    fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) {
      [weak self] timer in
      guard let self = self else {
        timer.invalidate()
        return
      }

      currentStep += 1
      let newVolume = max(self.fadeStartVolume - (volumeDecrement * Float(currentStep)), 0.0)
      self.player?.volume = newVolume

      if currentStep >= steps || newVolume <= 0.0 {
        timer.invalidate()
        self.player?.volume = 0.0
        self.player?.pause()
        completion?()
      }
    }
  }

  func reset() {
    guard !isResetting else { return }
    isResetting = true

    print("🔄 Sound: Resetting '\(fileName)'")

    // Clean up timers
    fadeTimer?.invalidate()
    fadeTimer = nil
    volumeDebounceTimer?.invalidate()
    volumeDebounceTimer = nil
    updateVolumeLogTimer?.invalidate()
    updateVolumeLogTimer = nil

    // Reset player
    player?.stop()
    player = nil

    // Reset state
    isSelected = false
    volume = 1.0

    // Clear user defaults
    UserDefaults.standard.removeObject(forKey: "\(fileName)_isSelected")
    UserDefaults.standard.removeObject(forKey: "\(fileName)_volume")
    UserDefaults.standard.removeObject(forKey: "\(fileName)_customOrder")
    UserDefaults.standard.removeObject(forKey: "\(fileName)_isHidden")

    print("✅ Sound: Reset complete for '\(fileName)'")
    isResetting = false
  }
}
