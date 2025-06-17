//
//  PresetArtwork.swift
//  Blankie
//
//  Created by Cody Bromley on 6/14/25.
//

import Foundation
import SwiftData

@Model
final class PresetArtwork {
  @Attribute(.unique) var id: UUID
  var presetId: UUID
  var imageData: Data
  var createdAt: Date
  var updatedAt: Date

  init(presetId: UUID, imageData: Data) {
    self.id = UUID()
    self.presetId = presetId
    self.imageData = imageData
    self.createdAt = Date()
    self.updatedAt = Date()
  }
}
