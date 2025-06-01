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
    sounds.filter { !$0.isHidden }.sorted { $0.customOrder < $1.customOrder }
  }
  
  /// Move a sound to a new position
  func moveSound(from sourceIndex: Int, to destinationIndex: Int) {
    let hiddenSounds = sounds.filter { $0.isHidden }.sorted { $0.customOrder < $1.customOrder }
    guard sourceIndex < hiddenSounds.count && destinationIndex <= hiddenSounds.count else {
      return
    }

    // Update the custom order for hidden sounds
    var updatedSounds = hiddenSounds
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
  
  /// Toggle the hidden state of a sound
  func toggleSoundVisibility(_ sound: Sound) {
    sound.isHidden.toggle()
    print(
      "🎵 AudioManager: Toggled visibility for '\(sound.fileName)' to \(sound.isHidden ? "hidden" : "visible")"
    )
  }
  
  /// Hide a sound
  func hideSound(_ sound: Sound) {
    sound.isHidden = true
    
    // If the sound is currently playing, stop it immediately
    if sound.isSelected {
      sound.pause(immediate: true)
    }
    
    objectWillChange.send()
    print("🎵 AudioManager: Hidden sound '\(sound.fileName)'")
  }
  
  /// Show a sound
  func showSound(_ sound: Sound) {
    sound.isHidden = false
    objectWillChange.send()
    print("🎵 AudioManager: Showed sound '\(sound.fileName)'")
  }
}