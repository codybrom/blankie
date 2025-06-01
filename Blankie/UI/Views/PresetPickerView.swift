import SwiftUI

struct PresetPickerView: View {
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var showingNewPresetAlert = false
  @State private var newPresetName = ""
  @State private var presetToRename: Preset?
  @State private var updatedPresetName = ""
  @State private var presetToDelete: Preset?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        if presetManager.isLoading {
          // Loading view
          HStack {
            Spacer()
            ProgressView("Loading Presets...")
            Spacer()
          }
          .padding()
        } else if !presetManager.hasCustomPresets {
          // Empty state
          HStack {
            Spacer()
            VStack(spacing: 12) {
              Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

              Text("No Custom Presets", comment: "Empty state title for presets")
                .font(.headline)

              Text(
                "Save your current sound configuration as a preset to quickly access it later.",
                comment: "Empty state description for presets"
              )
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: 250)
            Spacer()
          }
          .listRowBackground(Color.clear)
        } else {
          // List of presets
          ForEach(presetManager.presets.filter { !$0.isDefault }) { preset in
            Button {
              // Apply the preset
              Task {
                do {
                  try presetManager.applyPreset(preset)
                  dismiss()
                } catch {
                  print("Error applying preset: \(error)")
                }
              }
            } label: {
              HStack {
                Text(preset.name)
                  .foregroundColor(.primary)

                Spacer()

                if presetManager.currentPreset?.id == preset.id {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
            }
            .swipeActions {
              Button {
                presetToRename = preset
                updatedPresetName = preset.name
              } label: {
                Label("Rename Preset", systemImage: "pencil")
              }
              .tint(.blue)

              Button(role: .destructive) {
                presetToDelete = preset
              } label: {
                Label("Delete Preset", systemImage: "trash")
              }
            }
          }
        }
      }
      .navigationTitle("Presets")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showingNewPresetAlert = true
          } label: {
            Label("New Preset", systemImage: "plus")
          }
        }

        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Done", comment: "Toolbar done button")
          }
        }
      }
      .sheet(item: $presetToRename) { preset in
        RenamePresetView(
          preset: preset,
          presetName: updatedPresetName,
          onSave: { newName in
            Task {
              if !newName.isEmpty {
                presetManager.updatePreset(preset, newName: newName)
              }
              presetToRename = nil
            }
          },
          onCancel: {
            presetToRename = nil
          }
        )
        .presentationDetents([.fraction(0.3)])
      }
      .alert("New Preset", isPresented: $showingNewPresetAlert) {
        TextField("Preset Name", text: $newPresetName)

        Button("Cancel", role: .cancel) {
          newPresetName = ""
        }

        Button {
          if !newPresetName.isEmpty {
            Task {
              presetManager.saveNewPreset(name: newPresetName)
              newPresetName = ""
            }
          }
        } label: {
          Text("Save", comment: "Save preset button")
        }
      } message: {
        Text("Save current sound configuration as a preset.", comment: "New preset alert message")
      }
      .alert(
        "Delete Preset",
        isPresented: .init(
          get: { presetToDelete != nil },
          set: { if !$0 { presetToDelete = nil } }
        )
      ) {
        Button("Cancel", role: .cancel) {
          presetToDelete = nil
        }

        Button("Delete", role: .destructive) {
          if let preset = presetToDelete {
            Task {
              presetManager.deletePreset(preset)
              presetToDelete = nil
            }
          }
        }
      } message: {
        if let preset = presetToDelete {
          Text(
            "Are you sure you want to delete '\(preset.name)'? This action cannot be undone.",
            comment: "Delete preset confirmation message")
        }
      }
    }
  }
}

struct RenamePresetView: View {
  let preset: Preset
  @State var presetName: String
  let onSave: (String) -> Void
  let onCancel: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Rename Preset", comment: "Rename preset view title")
          .font(.headline)

        TextField("Preset Name", text: $presetName)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal)

        HStack(spacing: 40) {
          Button("Cancel") {
            onCancel()
            dismiss()
          }

          Button {
            onSave(presetName)
            dismiss()
          } label: {
            Text("Save", comment: "Save preset button")
          }
          .buttonStyle(.borderedProminent)
          .disabled(presetName.isEmpty)
        }
        .padding(.top)
      }
      .padding()
    }
  }
}

// Preview Provider
struct PresetPickerView_Previews: PreviewProvider {
  static var previews: some View {
    PresetPickerView()
  }
}
