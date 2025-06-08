//
//  GlobalSettings+SoloMode.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import Foundation

extension GlobalSettings {
  @MainActor
  func saveSoloModeSound(fileName: String?) {
    if let fileName = fileName {
      UserDefaults.standard.set(fileName, forKey: UserDefaultsKeys.soloModeSoundFileName)
      print("💾 GlobalSettings: Saved solo mode sound: \(fileName)")
    } else {
      UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.soloModeSoundFileName)
      print("💾 GlobalSettings: Cleared solo mode sound")
    }
  }

  func getSavedSoloModeFileName() -> String? {
    return UserDefaults.standard.string(forKey: UserDefaultsKeys.soloModeSoundFileName)
  }
}
