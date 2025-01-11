//
//  SoundCredit.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

// Sound credit model
struct SoundCredit {
  let name: String
  let author: String
  let license: License
  let editor: String?
  let soundUrl: URL?

  var attributionText: String {
    let text = "\""
    return text
  }
}
