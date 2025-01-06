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
          Label("Delete", systemImage: "trash")
        }
        .buttonStyle(.borderless)
        .alert("Delete Preset", isPresented: $showingDeleteAlert) {
          Button("Cancel", role: .cancel) {}
          Button("Delete", role: .destructive) {
            Task {
              await presetManager.deletePreset(preset)
            }
          }
        } message: {
          Text("Are you sure you want to delete '\(preset.name)'? This action cannot be undone.")
        }
      }
    }
  }
}
