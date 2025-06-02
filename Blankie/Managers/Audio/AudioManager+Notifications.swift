//
//  AudioManager+Notifications.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import AVFoundation
import Combine
import SwiftUI

// MARK: - Notification Observers
extension AudioManager {
  func setupNotificationObservers() {
    #if os(iOS) || os(visionOS)
      setupIOSNotificationObservers()
    #elseif os(macOS)
      setupMacOSNotificationObservers()
    #endif
  }

  #if os(iOS) || os(visionOS)
    private func setupIOSNotificationObservers() {
      setupTerminationObserver()
      setupCarPlayObserver()
      setupBackgroundObservers()
      // Delay audio session observers until first playback to avoid interrupting other apps
      // setupAudioInterruptionObserver()
      // setupAudioRouteChangeObserver()
    }

    // Call this when we first start playing to setup audio session observers
    func setupAudioSessionObservers() {
      guard !audioSessionObserversSetup else { return }
      print("🎵 AudioManager: Setting up audio session observers on first playback")
      setupAudioInterruptionObserver()
      setupAudioRouteChangeObserver()
      audioSessionObserversSetup = true
    }

    private func setupTerminationObserver() {
      NotificationCenter.default.addObserver(
        forName: UIApplication.willTerminateNotification,
        object: nil,
        queue: .main
      ) { _ in
        self.handleAppTermination()
      }
    }

    private func setupCarPlayObserver() {
      #if CARPLAY_ENABLED
        NotificationCenter.default.addObserver(
          forName: NSNotification.Name("CarPlayConnectionChanged"),
          object: nil,
          queue: .main
        ) { [weak self] notification in
          if let isConnected = notification.userInfo?["isConnected"] as? Bool {
            print("🎵 AudioManager: CarPlay connection changed to: \(isConnected)")
            if self?.isGloballyPlaying == true {
              self?.setupAudioSessionForPlayback()
            }
          }
        }
      #endif
    }

    private func setupBackgroundObservers() {
      NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.saveState()
      }

      NotificationCenter.default.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleWillEnterForeground()
      }
    }

    func handleWillEnterForeground() {
      print(
        "🎵 AudioManager: handleWillEnterForeground called - isGloballyPlaying: \(isGloballyPlaying)"
      )

      AudioSessionManager.shared.reactivateForForeground(
        mixWithOthers: GlobalSettings.shared.mixWithOthers,
        isPlaying: isGloballyPlaying)

      if isGloballyPlaying {
        nowPlayingManager.updateInfo(
          presetName: PresetManager.shared.currentPreset?.name,
          isPlaying: true
        )
      }
    }

    private func setupAudioInterruptionObserver() {
      NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        self?.handleAudioInterruption(notification)
      }
    }

    private func handleAudioInterruption(_ notification: Notification) {
      guard let userInfo = notification.userInfo,
        let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeValue)
      else {
        return
      }

      switch type {
      case .began:
        handleInterruptionBegan()
      case .ended:
        handleInterruptionEnded(userInfo: userInfo)
      @unknown default:
        break
      }
    }

    private func handleInterruptionBegan() {
      print("🎵 AudioManager: Audio interruption began - pausing playback")
      if isGloballyPlaying {
        Task { @MainActor in
          self.setGlobalPlaybackState(false)
        }
      }
    }

    private func handleInterruptionEnded(userInfo: [AnyHashable: Any]) {
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          print("🎵 AudioManager: Audio interruption ended with shouldResume flag")
          if !GlobalSettings.shared.mixWithOthers {
            print("🎵 AudioManager: Not resuming automatically in exclusive mode")
          }
        }
      }
    }

    private func setupAudioRouteChangeObserver() {
      NotificationCenter.default.addObserver(
        forName: AVAudioSession.routeChangeNotification,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        self?.handleAudioRouteChange(notification)
      }
    }

    private func handleAudioRouteChange(_ notification: Notification) {
      guard let userInfo = notification.userInfo,
        let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
      else {
        return
      }

      switch reason {
      case .oldDeviceUnavailable:
        print("🎵 AudioManager: Audio route changed - old device unavailable")
        if isGloballyPlaying {
          Task { @MainActor in
            self.setGlobalPlaybackState(false)
          }
        }
      case .newDeviceAvailable:
        print("🎵 AudioManager: Audio route changed - new device available")
      default:
        break
      }
    }
  #endif

  #if os(macOS)
    private func setupMacOSNotificationObservers() {
      NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification,
        object: nil,
        queue: .main
      ) { _ in
        self.handleAppTermination()
      }

      Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
        self?.saveState()
      }
    }
  #endif

  func handleAppTermination() {
    print("🎵 AudioManager: App is terminating, cleaning up")
    cleanup()
  }

  func cleanup() {
    saveState()
    nowPlayingManager.clear()
    print("🎵 AudioManager: Cleanup complete")
  }
}
