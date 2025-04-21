//
//  PresetActionButtons.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

struct PresetActionButtons: View {
  let preset: Preset
  @State private var showingDeleteAlert = false
  @ObservedObject private var presetManager = PresetManager.shared

  var body: some View {
    HStack(spacing: 12) {
      if !preset.isDefault {
        Button(role: .destructive) {
          showingDeleteAlert = true
        } label: {
          Label(NSLocalizedString("Delete", comment: "Delete preset button"), systemImage: "trash")
        }
        .buttonStyle(.borderless)
        .alert(NSLocalizedString("Delete Preset", comment: "Delete preset alert title"), isPresented: $showingDeleteAlert) {
          Button(NSLocalizedString("Cancel", comment: "Cancel delete preset"), role: .cancel) {}
          Button(NSLocalizedString("Delete", comment: "Delete preset confirm button"), role: .destructive) {
            Task {
              presetManager.deletePreset(preset)
            }
          }
        } message: {
          Text(String(format: NSLocalizedString("Are you sure you want to delete '%@'? This action cannot be undone.", comment: "Delete preset confirmation message"), preset.name))
        }
      }
    }
  }
}
