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
      Text(NSLocalizedString("Edit Preset", comment: "Edit preset sheet title"))
        .font(.headline)

      if preset.isDefault {
        Text(
          NSLocalizedString(
            "The default preset cannot be renamed", comment: "Default preset rename warning")
        )
        .foregroundStyle(.secondary)
        .font(.caption)
      } else {
        TextField(
          NSLocalizedString("Preset Name", comment: "Preset name text field"), text: $presetName
        )
        .textFieldStyle(.roundedBorder)
        .frame(width: 200)
        .onSubmit {
          if !presetName.isEmpty {
            Task {
              presetManager.updatePreset(preset, newName: presetName)
              isPresented = nil
            }
          } else {
            error = NSLocalizedString(
              "Preset name cannot be empty", comment: "Empty preset name error")
          }
        }

        if let error = error {
          Text(error)
            .foregroundStyle(.red)
            .font(.caption)
        }

        HStack(spacing: 16) {
          Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
            isPresented = nil
          }

          Button(NSLocalizedString("Save", comment: "Save button")) {
            if !presetName.isEmpty {
              Task {
                presetManager.updatePreset(preset, newName: presetName)
                isPresented = nil
              }
            } else {
              error = NSLocalizedString(
                "Preset name cannot be empty", comment: "Empty preset name error")
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
