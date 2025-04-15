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
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 16) {
      Text("Edit Preset")
        .font(.headline)

      if preset.isDefault {
        Text("The default preset cannot be renamed")
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
          .onAppear {
            presetName = preset.name
          }

        if let error = error {
          Text(error)
            .foregroundStyle(.red)
            .font(.caption)
        }

        HStack(spacing: 16) {
          Button("Cancel") {
            isPresented = nil
          }

          Button("Save") {
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
