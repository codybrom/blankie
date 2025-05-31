//
//  DropzoneManager.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import SwiftUI

class DropzoneManager: ObservableObject {
  @Published var selectedFileURL: URL?
  @Published var showingSoundSheet = false

  func setFileURL(_ url: URL) {
    selectedFileURL = url
  }

  func showSheet() {
    showingSoundSheet = true
  }

  func hideSheet() {
    showingSoundSheet = false
    selectedFileURL = nil
  }
}
