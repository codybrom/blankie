//
//  SoundSheetForm.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import SwiftUI

struct SoundSheetForm: View {
  let mode: SoundSheetMode
  @Binding var soundName: String
  @Binding var selectedIcon: String
  @Binding var selectedFile: URL?
  @Binding var isImporting: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // File selection (only for add mode)
      if case .add = mode {
        SoundFileSelector(
          selectedFile: $selectedFile,
          soundName: $soundName,
          isImporting: $isImporting
        )
      }

      // Name Input
      VStack(alignment: .leading, spacing: 8) {
        Text("Name", comment: "Display name field label")
          .font(.headline)
        TextField(text: $soundName) {
          Text("Enter a name for this sound", comment: "Sound name text field placeholder")
        }
        .textFieldStyle(.roundedBorder)
      }

      // Icon Selection
      SoundIconSelector(selectedIcon: $selectedIcon)
    }
    .padding(20)
  }
}

struct SoundSheetProcessingOverlay: View {
  let progressMessage: LocalizedStringKey

  var body: some View {
    ZStack {
      Color.black.opacity(0.3)
        .ignoresSafeArea()

      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.5)
        Text(progressMessage)
          .font(.headline)
      }
      .padding(24)
      .background(
        Group {
          #if os(macOS)
            Color(NSColor.windowBackgroundColor)
          #else
            Color(UIColor.systemBackground)
          #endif
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(radius: 20)
    }
  }
}
