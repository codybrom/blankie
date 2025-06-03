//
//  GlobalSettings+AudioSession.swift
//  Blankie
//
//  Created by Cody Bromley on 6/2/25.
//

import AVFoundation
import Foundation

#if os(iOS) || os(visionOS)
  extension GlobalSettings {
    func updateAudioSession() {
      do {
        let wasPlaying = AudioManager.shared.isGloballyPlaying

        // Configure the session based on mixWithOthers setting
        if mixWithOthers {
          // Allow mixing with other apps - we handle volume manually
          let options: AVAudioSession.CategoryOptions = [.mixWithOthers]
          print("⚙️ GlobalSettings: Setting Mix mode with manual volume control")

          try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: options
          )
        } else {
          // Exclusive playback mode - no mixing
          try AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: []  // No options means exclusive playback
          )
        }

        // Always activate if we're currently playing to ensure we take over
        if wasPlaying {
          try AVAudioSession.sharedInstance().setActive(true)

          // Restart playback since changing to exclusive mode may have interrupted it
          AudioManager.shared.playSelected()

          // Update Now Playing info
          AudioManager.shared.updateNowPlayingState()
        }

        print(
          "⚙️ GlobalSettings: Updated audio session with mixWithOthers: \(mixWithOthers), volumeWithOtherAudio: \(volumeWithOtherAudio), activated: \(wasPlaying)"
        )
      } catch {
        print("❌ GlobalSettings: Failed to update audio session: \(error)")
      }
    }
  }
#endif
