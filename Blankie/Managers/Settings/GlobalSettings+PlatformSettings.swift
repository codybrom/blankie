//
//  GlobalSettings+PlatformSettings.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import Foundation

extension GlobalSettings {
  @MainActor
  func setEnableHaptics(_ value: Bool) {
    enableHaptics = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.enableHaptics)
    logCurrentSettings()
  }

  @MainActor
  func setEnableSpatialAudio(_ value: Bool) {
    enableSpatialAudio = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.enableSpatialAudio)
    // Here we would also update the audio engine to enable/disable spatial audio
    logCurrentSettings()
  }

  @MainActor
  func setMixWithOthers(_ value: Bool) {
    mixWithOthers = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.mixWithOthers)
    #if os(iOS) || os(visionOS)
      // Update audio session configuration
      updateAudioSession()
    #endif
    logCurrentSettings()
  }

  @MainActor
  func setLowerVolumeWithOtherAudio(_ value: Bool) {
    lowerVolumeWithOtherAudio = value
    UserDefaults.standard.set(value, forKey: UserDefaultsKeys.lowerVolumeWithOtherAudio)
    #if os(iOS) || os(visionOS)
      // Update audio session configuration
      updateAudioSession()
    #endif
    // Apply the new setting to currently playing sounds
    if AudioManager.shared.isGloballyPlaying {
      AudioManager.shared.applyVolumeSettings()
    }
    logCurrentSettings()
  }

  @MainActor
  func setVolumeWithOtherAudio(_ level: Double) {
    volumeWithOtherAudio = max(0.0, min(1.0, level))  // Clamp between 0.0 and 1.0
    UserDefaults.standard.set(volumeWithOtherAudio, forKey: UserDefaultsKeys.volumeWithOtherAudio)
    // Apply the new volume level to currently playing sounds
    if AudioManager.shared.isGloballyPlaying {
      AudioManager.shared.applyVolumeSettings()
    }
    logCurrentSettings()
  }
}