//
//  AppSetup.swift
//  Blankie
//
//  Created by Cody Bromley on 6/17/25.
//

import SwiftData
import SwiftUI

/// Handles shared app initialization and setup
struct AppSetup {
  let modelContainer: ModelContainer

  /// Initialize SwiftData container
  static func createModelContainer() -> ModelContainer {
    do {
      let container = try ModelContainer(for: CustomSoundData.self, PresetArtwork.self)
      print("🗄️ AppSetup: Successfully created SwiftData model container")
      return container
    } catch {
      fatalError("❌ AppSetup: Failed to create SwiftData model container: \(error)")
    }
  }

  /// Setup all managers with model context
  @MainActor
  func setupManagers() {
    // Pass model context to AudioManager for custom sounds
    AudioManager.shared.setModelContext(modelContainer.mainContext)

    // Pass model context to PresetArtworkManager
    PresetArtworkManager.shared.setModelContext(modelContainer.mainContext)

    // Warm artwork cache
    Task {
      await PresetArtworkManager.shared.warmCache()
    }
  }

}
