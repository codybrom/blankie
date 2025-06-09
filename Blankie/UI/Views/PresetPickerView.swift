import SwiftUI

struct PresetPickerView: View {
  @ObservedObject private var presetManager = PresetManager.shared
  @ObservedObject private var audioManager = AudioManager.shared
  @State private var showingNewPresetSheet = false
  @State private var newPresetName = ""
  @State private var presetToRename: Preset?
  @State private var updatedPresetName = ""
  @State private var presetToDelete: Preset?
  @State private var isEditMode = false
  @Environment(\.dismiss) private var dismiss

  private func deletePresets(at offsets: IndexSet) {
    let presetsToDelete = offsets.map { presetManager.presets.filter { !$0.isDefault }[$0] }
    for preset in presetsToDelete {
      presetManager.deletePreset(preset)
    }
  }

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
        } else if presetManager.presets.isEmpty {
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
          // Solo mode indicator (if active)
          if let soloSound = audioManager.soloModeSound {
            HStack {
              HStack(spacing: 8) {
                Image(systemName: "headphones.circle.fill")
                  .foregroundColor(.accentColor)
                Text("Solo Mode - \(soloSound.title)")
                  .foregroundColor(.secondary)
              }

              Spacer()

              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
            .listRowBackground(Color.secondary.opacity(0.1))
          }

          // CarPlay Quick Mix indicator (if active)
          if audioManager.isCarPlayQuickMix {
            HStack {
              HStack(spacing: 8) {
                Image(systemName: "car.circle.fill")
                  .foregroundColor(.accentColor)
                Text("Quick Mix (CarPlay)")
                  .foregroundColor(.secondary)
              }

              Spacer()

              Image(systemName: "checkmark")
                .foregroundColor(.accentColor)
            }
            .listRowBackground(Color.secondary.opacity(0.1))
          }

          // List of all presets (default first, then custom presets)
          ForEach(presetManager.presets.sorted { $0.isDefault && !$1.isDefault }) { preset in
            Button {
              // Exit solo mode if active, then apply the preset
              Task {
                do {
                  // Exit solo mode without resuming previous sounds if active
                  // This prevents the previous preset from briefly playing
                  if audioManager.soloModeSound != nil {
                    audioManager.exitSoloModeWithoutResuming()
                  }

                  // Exit CarPlay Quick Mix if we're in it
                  if audioManager.isCarPlayQuickMix {
                    audioManager.exitCarPlayQuickMix()
                  }

                  try presetManager.applyPreset(preset)
                  dismiss()
                } catch {
                  print("Error applying preset: \(error)")
                }
              }
            } label: {
              HStack {
                Text(preset.displayName)
                  .foregroundColor(.primary)

                Spacer()

                // Only show checkmark if not in solo mode AND this is the current preset
                let isSoloModeActive = audioManager.soloModeSound != nil
                let isCurrentPreset = presetManager.currentPreset?.id == preset.id

                if !isSoloModeActive && isCurrentPreset {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                }
              }
            }
            .swipeActions {
              if !isEditMode {
                Button {
                  presetToRename = preset
                  updatedPresetName = preset.name
                } label: {
                  Label(preset.isDefault ? "View Preset" : "Edit Preset", systemImage: "pencil")
                }
                .tint(.blue)

                if !preset.isDefault {
                  Button(role: .destructive) {
                    presetToDelete = preset
                  } label: {
                    Label("Delete Preset", systemImage: "trash")
                  }
                }
              }
            }
            .deleteDisabled(!isEditMode || preset.isDefault)
          }
          .onDelete(perform: isEditMode ? deletePresets : nil)
        }
      }
      .navigationTitle("Presets")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if presetManager.hasCustomPresets {
            Button {
              isEditMode.toggle()
            } label: {
              Text(isEditMode ? "Cancel" : "Edit", comment: "Edit mode toggle button")
            }
          }
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            showingNewPresetSheet = true
          } label: {
            Label("New Preset", systemImage: "plus")
          }
        }

      }
      #if os(iOS)
        .environment(\.editMode, .constant(isEditMode ? EditMode.active : EditMode.inactive))
      #endif
      .sheet(item: $presetToRename) { preset in
        EditPresetSheet(preset: preset, isPresented: $presetToRename)
      }
      .sheet(isPresented: $showingNewPresetSheet) {
        CreatePresetSheet(isPresented: $showingNewPresetSheet)
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

// Preview Provider
struct PresetPickerView_Previews: PreviewProvider {
  static var previews: some View {
    PresetPickerView()
  }
}
