//
//  WindowObserver.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

class WindowObserver: ObservableObject {
  static let shared = WindowObserver()
  @Published var hasVisibleWindow = false

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidBecomeKey),
      name: NSWindow.didBecomeKeyNotification,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidClose),
      name: NSWindow.willCloseNotification,
      object: nil)
  }

  @objc private func windowDidBecomeKey(_ notification: Notification) {
    print("WindowObserver: windowDidBecomeKey called")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.hasVisibleWindow = true
    }
  }

  @objc private func windowDidClose(_ notification: Notification) {
    print("WindowObserver: windowDidClose called")
    // Check if any main windows are still visible
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.checkVisibleWindows()
    }
  }

  private func checkVisibleWindows() {
    print("WindowObserver: checkVisibleWindows called")
    self.hasVisibleWindow = NSApp.windows.contains { window in
      window.isVisible && !window.isMiniaturized && window.toolbar != nil
    }
  }
}
