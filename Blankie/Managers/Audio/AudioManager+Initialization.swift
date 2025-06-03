//
//  AudioManager+Initialization.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import Combine
import Foundation
import SwiftUI

extension AudioManager {
  func setupSoundObservers() {
    // Clear any existing observers
    cancellables.removeAll()
    // Set up new observers for each sound
    for sound in sounds {
      sound.objectWillChange
        .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
        .sink { [weak self] _ in
          guard let self = self else { return }
          Task { @MainActor in
            self.updateHasSelectedSounds()
            PresetManager.shared.updateCurrentPresetState()
          }
        }
        .store(in: &cancellables)
    }
    // Update initial state
    updateHasSelectedSounds()
  }

  func updateHasSelectedSounds() {
    let newValue = sounds.contains { $0.isSelected && !$0.isHidden }
    if hasSelectedSounds != newValue {
      print("🎵 AudioManager: hasSelectedSounds changed from \(hasSelectedSounds) to \(newValue)")
      hasSelectedSounds = newValue
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
}
