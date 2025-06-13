//
//  AudioManager+SoundManagement.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import Foundation
import SwiftData

extension AudioManager {
  // MARK: - Sound Management

  @MainActor
  func getVisibleSounds() -> [Sound] {
    sounds.sorted { $0.customOrder < $1.customOrder }
  }

  /// Move a sound to a new position
  func moveSound(from sourceIndex: Int, to destinationIndex: Int) {
    let allSounds = sounds.sorted { $0.customOrder < $1.customOrder }
    guard sourceIndex < allSounds.count && destinationIndex <= allSounds.count else {
      return
    }

    // Update the custom order for all sounds
    var updatedSounds = allSounds
    let movedSound = updatedSounds.remove(at: sourceIndex)
    updatedSounds.insert(movedSound, at: min(destinationIndex, updatedSounds.count))

    // Assign new order values
    for (index, sound) in updatedSounds.enumerated() {
      sound.customOrder = index
    }

    objectWillChange.send()
    print(
      "🎵 AudioManager: Moved sound '\(movedSound.fileName)' from \(sourceIndex) to \(destinationIndex)"
    )
  }

  /// Move a visible sound to a new position
  @MainActor
  func moveVisibleSound(from sourceIndex: Int, to destinationIndex: Int) {
    let visibleSounds = getVisibleSounds()
    guard sourceIndex < visibleSounds.count && destinationIndex <= visibleSounds.count else {
      return
    }

    // Update the custom order for all visible sounds
    var updatedSounds = visibleSounds
    let movedSound = updatedSounds.remove(at: sourceIndex)
    updatedSounds.insert(movedSound, at: min(destinationIndex, updatedSounds.count))

    // Assign new order values
    for (index, sound) in updatedSounds.enumerated() {
      sound.customOrder = index
    }

    objectWillChange.send()
    print(
      "🎵 AudioManager: Moved visible sound '\(movedSound.fileName)' from \(sourceIndex) to \(destinationIndex)"
    )
  }

  /// Move visible sounds from source indices to destination (for List's onMove)
  @MainActor
  func moveVisibleSounds(from source: IndexSet, to destination: Int) {
    var visibleSounds = getVisibleSounds()
    visibleSounds.move(fromOffsets: source, toOffset: destination)

    // Assign new order values
    for (index, sound) in visibleSounds.enumerated() {
      sound.customOrder = index
    }

    objectWillChange.send()
    print("🎵 AudioManager: Moved sounds from \(source) to \(destination)")
  }

  /// Apply volume settings to all playing sounds by triggering volume updates
  func applyVolumeSettings() {
    print("🎵 AudioManager: Updating volumes for volume settings change")

    for sound in sounds where sound.isSelected {
      // Trigger volume recalculation which will include custom volume settings
      sound.updateVolume()
    }
  }
}
