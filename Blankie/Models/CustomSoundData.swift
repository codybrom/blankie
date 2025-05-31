//
//  CustomSoundData.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import Foundation
import SwiftData

@Model
class CustomSoundData {
  var id = UUID()
  var title: String
  var systemIconName: String
  var fileName: String
  var fileExtension: String
  var dateAdded: Date

  // We don't need full credit info for custom sounds, but we'll track some basic info
  var originalFileName: String?

  init(
    title: String,
    systemIconName: String,
    fileName: String,
    fileExtension: String,
    originalFileName: String? = nil
  ) {
    self.title = title
    self.systemIconName = systemIconName
    self.fileName = fileName
    self.fileExtension = fileExtension
    self.dateAdded = Date()
    self.originalFileName = originalFileName
  }

  // Convert to SoundData for compatibility with existing system
  func toSoundData() -> SoundData {
    return SoundData(
      defaultOrder: 1000,  // Place custom sounds after built-in sounds
      title: title,
      systemIconName: systemIconName,
      fileName: fileName,
      author: "Custom Sound",
      authorUrl: nil,
      license: "Custom",
      editor: nil,
      editorUrl: nil,
      soundUrl: "",
      soundName: originalFileName ?? fileName
    )
  }
}
