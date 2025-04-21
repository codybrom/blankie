//
//  PresetLoadingView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

struct PresetLoadingView: View {
  var body: some View {
    VStack(spacing: 12) {
      ProgressView()
      Text(NSLocalizedString("Loading Presets...", comment: "Preset loading indicator"))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding()
  }
}
