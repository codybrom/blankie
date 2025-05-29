//
//  TimerManager.swift
//  Blankie
//
//  Created by Cody Bromley on 1/29/25.
//

import Combine
import Foundation

class TimerManager: ObservableObject {
  static let shared = TimerManager()

  @Published var isTimerActive = false
  @Published var remainingTime: TimeInterval = 0
  @Published var selectedDuration: TimeInterval = 0
  @Published var selectedHours: Int
  @Published var selectedMinutes: Int

  private var timer: Timer?
  private var startTime: Date?
  private var cancellables = Set<AnyCancellable>()

  private init() {
    // Load saved duration or use defaults
    self.selectedHours = UserDefaults.standard.object(forKey: "timerLastSelectedHours") as? Int ?? 0
    self.selectedMinutes =
      UserDefaults.standard.object(forKey: "timerLastSelectedMinutes") as? Int ?? 30

    #if os(iOS) || os(visionOS)
      NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleBackgroundTransition()
      }

      NotificationCenter.default.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.handleForegroundTransition()
      }
    #endif
  }

  func startTimer(duration: TimeInterval) {
    stopTimer()

    selectedDuration = duration
    remainingTime = duration
    startTime = Date()
    isTimerActive = true

    // Save the user's selection for next time
    UserDefaults.standard.set(selectedHours, forKey: "timerLastSelectedHours")
    UserDefaults.standard.set(selectedMinutes, forKey: "timerLastSelectedMinutes")

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.updateTimer()
    }

    print("⏱️ TimerManager: Started timer for \(duration) seconds")
  }

  func stopTimer() {
    timer?.invalidate()
    timer = nil
    isTimerActive = false
    remainingTime = 0
    selectedDuration = 0
    startTime = nil

    print("⏱️ TimerManager: Timer stopped")
  }

  private func updateTimer() {
    guard let startTime = startTime else { return }

    let elapsed = Date().timeIntervalSince(startTime)
    remainingTime = max(0, selectedDuration - elapsed)

    if remainingTime <= 0 {
      handleTimerExpired()
    }
  }

  private func handleTimerExpired() {
    print("⏱️ TimerManager: Timer expired")

    stopTimer()

    Task { @MainActor in
      AudioManager.shared.setGlobalPlaybackState(false)
    }
  }

  private func handleBackgroundTransition() {
    // Timer will continue running in the background
    // No action needed
  }

  private func handleForegroundTransition() {
    // Update the timer when returning from background
    if isTimerActive {
      updateTimer()
    }
  }

  func formatRemainingTime() -> String {
    let hours = Int(remainingTime) / 3600
    let minutes = (Int(remainingTime) % 3600) / 60
    let seconds = Int(remainingTime) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  deinit {
    stopTimer()
    NotificationCenter.default.removeObserver(self)
  }
}
