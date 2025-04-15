import SwiftUI

struct PresetPickerView: View {
  @ObservedObject private var presetManager = PresetManager.shared
  @State private var showingNewPresetAlert = false
  @State private var newPresetName = ""
  @State private var presetToRename: Preset? = nil
  @State private var updatedPresetName = ""
  @State private var presetToDelete: Preset? = nil
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      List {
        if presetManager.isLoading {
          // Loading view
          HStack {
            Spacer()
            ProgressView("Loading presets...")
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

              Text("No Custom Presets")
                .font(.headline)

              Text("Save your current sound configuration as a preset to quickly access it later.")
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
                Label("Rename", systemImage: "pencil")
              }
              .tint(.blue)

              Button(role: .destructive) {
                presetToDelete = preset
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }

          // Default preset
          if let defaultPreset = presetManager.presets.first(where: { $0.isDefault }) {
            Button {
              // Apply the default preset
              Task {
                do {
                  try presetManager.applyPreset(defaultPreset)
                  dismiss()
                } catch {
                  print("Error applying preset: \(error)")
                }
              }
            } label: {
              HStack {
                Text("Default")
                  .foregroundColor(.primary)

                Spacer()

                if presetManager.currentPreset?.id == defaultPreset.id {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
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
          Button("Done") {
            dismiss()
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

        Button("Save") {
          if !newPresetName.isEmpty {
            Task {
              presetManager.saveNewPreset(name: newPresetName)
              newPresetName = ""
            }
          }
        }
      } message: {
        Text("Save current sound configuration as a preset.")
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
          Text("Are you sure you want to delete '\(preset.name)'? This action cannot be undone.")
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
        Text("Rename Preset")
          .font(.headline)

        TextField("Preset Name", text: $presetName)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal)

        HStack(spacing: 40) {
          Button("Cancel") {
            onCancel()
            dismiss()
          }

          Button("Save") {
            onSave(presetName)
            dismiss()
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
