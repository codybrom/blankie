//
//  PresetSheets.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

struct NewPresetSheet: View {
  @Binding var presetName: String
  @Binding var isPresented: Bool
  @ObservedObject private var presetManager = PresetManager.shared

  var body: some View {
    VStack(spacing: 16) {
      Text("New Preset")
        .font(.headline)

      TextField("Preset Name", text: $presetName)
        .textFieldStyle(.roundedBorder)
        .frame(width: 200)

        .onSubmit {
          if !presetName.isEmpty {
             Task {
              await presetManager.saveNewPreset(name: presetName)
               isPresented = false
              }
          }
        }

      HStack(spacing: 16) {
        Button("Cancel") {
          isPresented = false
        }

        Button("Save") {
          if !presetName.isEmpty {
                Task {
                  await presetManager.saveNewPreset(name: presetName)
                    isPresented = false
                    }
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(presetName.isEmpty)
      }
    }
      .padding()
      .frame(width: 300)
      .fixedSize()
  }
}

struct EditPresetSheet: View {
  let preset: Preset
  @Binding var presetName: String
  @Binding var isPresented: Preset?
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var error: String?

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
            .onSubmit { // Handle enter key here
                if !presetName.isEmpty {
                  Task {
                    await presetManager.updatePreset(preset, newName: presetName)
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
          Button("Cancel") {
            isPresented = nil
          }

          Button("Save") {
                if !presetName.isEmpty {
                  Task {
                      await presetManager.updatePreset(preset, newName: presetName)
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
