//
//  SoundData.swift
//  Blankie
//
//  Created by Cody Bromley on 1/10/25.
//

struct SoundData: Codable {
  let defaultOrder: Int
  let title: String
  let systemIconName: String
  let fileName: String
  let author: String
  let authorUrl: String?
  let license: String
  let editor: String?
  let editorUrl: String?
  let soundUrl: String
  let soundName: String
}

struct SoundsContainer: Codable {
  let sounds: [SoundData]
}
