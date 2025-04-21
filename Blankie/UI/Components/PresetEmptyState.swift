//
//  PresetEmptyState.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

struct PresetEmptyState: View {
  @Binding var showingNewPresetSheet: Bool

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "star.circle")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text(NSLocalizedString("No Custom Presets", comment: "Empty state title"))
        .font(.headline)

      Text(
        NSLocalizedString(
          "Save your current sound configuration as a preset to quickly access it later.",
          comment: "Empty state subtitle")
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .lineLimit(nil)
    }
    .padding()
    .frame(idealWidth: 250, maxWidth: 250, minHeight: 100)
  }
}
