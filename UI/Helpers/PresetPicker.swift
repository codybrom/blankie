//
//  PresetPicker.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

struct PresetPicker: View {
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var showingPresetPopover = false
  @State private var newPresetName = ""
  @State private var error: Error?
  @State private var showingNewPresetSheet = false
  @State private var selectedPresetForEdit: Preset?

  var body: some View {
    HStack {
      Button {
        showingPresetPopover.toggle()
      } label: {
        HStack(spacing: 4) {
          Text(
            presetManager.hasCustomPresets
              ? (presetManager.currentPreset?.name ?? "Default") : "Presets"
          )
          .fontWeight(.bold)
          Image(systemName: "chevron.down")
            .imageScale(.small)
        }
      }
      .buttonStyle(.plain)
      .disabled(presetManager.isLoading)
      .popover(isPresented: $showingPresetPopover, arrowEdge: .bottom) {
        if presetManager.isLoading {
          PresetLoadingView()
        } else {
          VStack(spacing: 0) {
            PresetList(
              presetManager: presetManager, isPresented: $showingPresetPopover,
              selectedPresetForEdit: $selectedPresetForEdit
            )
            .frame(maxWidth: 300)
            Divider()

            Button(action: {
              showingPresetPopover = false
              showingNewPresetSheet = true

            }) {
              Label("New Preset", systemImage: "plus")
            }
            .buttonStyle(.plain)
            .padding(8)
          }
        }
      }
    }
    .sheet(isPresented: $showingNewPresetSheet) {
      NewPresetSheet(
        presetName: $newPresetName,
        isPresented: $showingNewPresetSheet
      )
    }
    .sheet(item: $selectedPresetForEdit) { preset in
      EditPresetSheet(
        preset: preset,
        presetName: $newPresetName,
        isPresented: $selectedPresetForEdit
      )
    }
  }

  // Removed the helper function completely
}

private struct PresetList: View {
  @ObservedObject var presetManager: PresetManager
  @Binding var isPresented: Bool
  @Binding var selectedPresetForEdit: Preset?
  @State private var error: Error?

  var body: some View {
    VStack(spacing: 0) {
      if presetManager.isLoading {
        PresetLoadingView()
      } else if !presetManager.hasCustomPresets {
        // Show empty state only if there are zero *custom* presets
        PresetEmptyState(showingNewPresetSheet: $isPresented)
      } else {
        // Custom presets
        ForEach(presetManager.presets.filter { !$0.isDefault }) { preset in
          PresetRow(
            preset: preset, isPresented: $isPresented, selectedPresetForEdit: $selectedPresetForEdit
          )
          if preset.id != presetManager.presets.last?.id {
            Divider()
          }
        }
      }
    }
    .background(Color(NSColor.controlBackgroundColor))
    .alert("Error", isPresented: .constant(error != nil)) {
      Button("OK") { error = nil }
    } message: {
      if let error = error {
        Text(error.localizedDescription)
      }
    }
  }
}
private struct PresetRow: View {
  let preset: Preset
  @Binding var isPresented: Bool
  @Binding var selectedPresetForEdit: Preset?
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var showingEditSheet = false
  @State private var presetName: String = ""
  @State private var error: Error?

  var body: some View {
    HStack(spacing: 8) {
      Button(action: {
        do {
          try presetManager.applyPreset(preset)
          isPresented = false
        } catch {
          self.error = error
        }
      }) {
        HStack {
          Text(preset.name)
            .foregroundStyle(.primary)

          Spacer()

          if presetManager.currentPreset?.id == preset.id {
            Image(systemName: "checkmark")
              .foregroundStyle(.blue)
          }
        }
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)

      // Only show edit and delete buttons for non-default presets
      if !preset.isDefault {
        Button(action: {
          selectedPresetForEdit = preset
        }) {
          Image(systemName: "pencil")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Rename Preset")
        Button(action: {
          presetManager.deletePreset(preset)
        }) {
          Image(systemName: "trash")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Delete Preset")
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .alert("Error", isPresented: .constant(error != nil)) {
      Button("OK") { error = nil }
    } message: {
      if let error = error {
        Text(error.localizedDescription)
      }
    }
  }
}
