//
//  AppDelegate.swift
//  Blankie
//
//  Created by Cody Bromley on 4/3/25.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Prevent app from quitting when last window closes
  }
}
