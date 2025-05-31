//
//  CustomSound.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import AVFoundation
import Foundation
import SwiftUI

/// A subclass of Sound specifically for custom imported sounds
class CustomSound: Sound {
  let customSoundData: CustomSoundData
  let fileURL: URL

  init(
    title: String, systemIconName: String, fileName: String, fileExtension: String, fileURL: URL,
    customSoundData: CustomSoundData
  ) {
    self.fileURL = fileURL
    self.customSoundData = customSoundData
    super.init(
      title: title, systemIconName: systemIconName, fileName: fileName, fileExtension: fileExtension, defaultOrder: 1000
    )
  }

  /// Override to load from documents directory instead of bundle
  override open func loadSound() {
    do {
      player = try AVAudioPlayer(contentsOf: fileURL)
      player?.volume = volume * Float(GlobalSettings.shared.volume)
      player?.numberOfLoops = -1
      player?.enableRate = false  // Disable rate/pitch adjustment
      player?.prepareToPlay()
      print("🔊 CustomSound: Loaded sound '\(fileName).\(fileExtension)' from \(fileURL.path)")
    } catch {
      print("❌ CustomSound: Failed to load '\(fileName).\(fileExtension)': \(error)")
      ErrorReporter.shared.report(AudioError.loadFailed(error))
    }
  }

  /// Delete the custom sound
  func delete() -> Result<Void, Error> {
    return CustomSoundManager.shared.deleteCustomSound(customSoundData)
  }
}
