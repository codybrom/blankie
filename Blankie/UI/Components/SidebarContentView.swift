import SwiftUI

#if os(iOS) || os(visionOS)
  struct SidebarContentView: View {
    @Binding var showingPresetPicker: Bool
    @Binding var showingAbout: Bool
    @Binding var hideInactiveSounds: Bool
    @Binding var showingViewSettings: Bool
    @Binding var showingSoundManagement: Bool

    @StateObject private var presetManager = PresetManager.shared
    @StateObject private var globalSettings = GlobalSettings.shared
    @State private var showingListView = false

    var body: some View {
      List {
        Section("Presets") {
          ForEach(presetManager.presets.filter { !$0.isDefault }) { preset in
            presetRow(preset)
          }

          Button(action: {
            showingPresetPicker = true
          }) {
            Label("Add Preset", systemImage: "plus")
          }
        }

        Section("Settings") {
          settingsButtons
        }
      }
      .navigationTitle("Blankie")
      .onAppear {
        showingListView = globalSettings.showingListView
      }
    }

    // Single preset row
    private func presetRow(_ preset: Preset) -> some View {
      Button(action: {
        Task {
          do {
            try presetManager.applyPreset(preset)
          } catch {
            print("Error applying preset: \(error)")
          }
        }
      }) {
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
      .contextMenu {
        if !preset.isDefault {
          Button(role: .destructive) {
            presetManager.deletePreset(preset)
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
      }
    }

    // Settings buttons in sidebar
    private var settingsButtons: some View {
      Group {
        Button(action: {
          showingViewSettings = true
        }) {
          Label("View Settings", systemImage: "slider.horizontal.3")
        }

        Button(action: {
          showingSoundManagement = true
        }) {
          Label("Sound Settings", systemImage: "waveform")
        }

        Button(action: {
          showingAbout = true
        }) {
          Label {
            Text("About Blankie", comment: "About menu item")
          } icon: {
            Image(systemName: "info.circle")
          }
        }
      }
    }
  }
#endif
