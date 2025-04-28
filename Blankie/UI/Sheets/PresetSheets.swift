//
//  PresetSheets.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

struct EditPresetSheet: View {
  let preset: Preset
  @Binding var presetName: String
  @Binding var isPresented: Preset?
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var error: String?

  var body: some View {
    VStack(spacing: 16) {
      Text("Edit Preset", comment: "Edit preset sheet title")
        .font(.headline)

      if preset.isDefault {
        Text("The default preset cannot be renamed", comment: "Default preset rename warning")
          .foregroundStyle(.secondary)
          .font(.caption)
      } else {
        TextField("Preset Name", text: $presetName)
          .textFieldStyle(.roundedBorder)
          .frame(width: 200)
          .onSubmit {
            if !presetName.isEmpty {
              Task {
                presetManager.updatePreset(preset, newName: presetName)
                isPresented = nil
              }
            } else {
              error = "Preset name cannot be empty"
            }
          }

        if let error = error {
          Text(error)
            .foregroundStyle(.red)
            .font(.caption)
        }

        HStack(spacing: 16) {
          Button("Cancel", systemImage: "Cancel button") {
            isPresented = nil
          }

          Button("Save", systemImage: "Save button") {
            if !presetName.isEmpty {
              Task {
                presetManager.updatePreset(preset, newName: presetName)
                isPresented = nil
              }
            } else {
              error = "Preset name cannot be empty"
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(presetName.isEmpty)
        }
      }
    }
    .padding()
    .frame(width: 300)
    .fixedSize()
  }
}
