//
//  AudioManager+Persistence.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import Foundation

extension AudioManager {
  func loadSavedState() {
    guard let state = UserDefaults.standard.array(forKey: "soundState") as? [[String: Any]] else {
      return
    }
    for savedState in state {
      guard let fileName = savedState["fileName"] as? String,
        let sound = sounds.first(where: { $0.fileName == fileName })
      else {
        continue
      }
      sound.isSelected = savedState["isSelected"] as? Bool ?? false
      sound.volume = savedState["volume"] as? Float ?? 1.0
    }
  }

  func saveState() {
    // Don't save state during Quick Mix mode - volume changes are temporary
    guard !isQuickMix else {
      print("🚗 AudioManager: Skipping state save during Quick Mix mode")
      return
    }

    let state = sounds.map { sound in
      [
        "id": sound.id.uuidString,
        "fileName": sound.fileName,
        "isSelected": sound.isSelected,
        "volume": sound.volume,
      ]
    }
    UserDefaults.standard.set(state, forKey: "soundState")
  }

  func updateDefaultSoundOrder(from source: IndexSet, to destination: Int) {
    defaultSoundOrder.move(fromOffsets: source, toOffset: destination)
    UserDefaults.standard.set(defaultSoundOrder, forKey: "defaultSoundOrder")
    objectWillChange.send()
    print("🎵 AudioManager: Updated default sound order - moved from \(source) to \(destination)")
  }
}
