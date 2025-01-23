//
//  AppState.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

class AppState: ObservableObject {
  static let shared = AppState()

  @Published var isAboutViewPresented = false
  @Published var hideInactiveSounds = false

  private init() {
    hideInactiveSounds = UserDefaults.standard.bool(forKey: "hideInactiveSounds")
  }
}
