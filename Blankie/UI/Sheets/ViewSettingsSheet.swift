//
//  ViewSettingsSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 1/7/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  struct ViewSettingsSheet: View {
    @Binding var isPresented: Bool
    @Binding var showingListView: Bool
    @Binding var hideInactiveSounds: Bool

    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var presetManager = PresetManager.shared
    @Environment(\.dismiss) var dismiss

    @State var backgroundBlurRadius: Double = 20.0
    @State var backgroundOpacity: Double = 0.5
    @State var showScrollIndicator = false

    var body: some View {
      NavigationStack {
        Form {
          Section {
            // Options that don't apply in solo mode or Quick Mix mode
            if audioManager.soloModeSound == nil && !audioManager.isQuickMix {
              // View Mode
              Picker("View Mode", selection: $showingListView) {
                Text("Grid").tag(false)
                Text("List").tag(true)
              }
              .pickerStyle(.segmented)

              // Icon Size - only show in grid view and only on macOS
              #if os(macOS)
                if !showingListView {
                  Picker(
                    "Icon Size",
                    selection: Binding(
                      get: { globalSettings.iconSize },
                      set: { globalSettings.setIconSize($0) }
                    )
                  ) {
                    Text("Small").tag(IconSize.small)
                    Text("Medium").tag(IconSize.medium)
                    Text("Large").tag(IconSize.large)
                  }
                  .pickerStyle(.menu)
                }
              #endif

              // Toggles
              Toggle(
                "Show Labels",
                isOn: Binding(
                  get: { globalSettings.showSoundNames },
                  set: { globalSettings.setShowSoundNames($0) }
                )
              )

              #if os(macOS)
                Toggle(
                  "Show Inactive Sounds",
                  isOn: Binding(
                    get: { !hideInactiveSounds },
                    set: { hideInactiveSounds = !$0 }
                  )
                )
              #endif
            }

            // Progress Borders - show in solo mode and grid view, but not in Quick Mix
            if !audioManager.isQuickMix
              && (audioManager.soloModeSound != nil || !showingListView)
            {
              Toggle(
                "Show Progress Borders",
                isOn: Binding(
                  get: { globalSettings.showProgressBorder },
                  set: { globalSettings.setShowProgressBorder($0) }
                )
              )
            }

            // Appearance
            Picker(
              "Appearance",
              selection: Binding(
                get: { globalSettings.appearance },
                set: { globalSettings.setAppearance($0) }
              )
            ) {
              ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Text(mode.localizedName).tag(mode)
              }
            }
            .pickerStyle(.menu)

            // Theme Color
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Theme Color")
                  .foregroundColor(.primary)
                Spacer()
              }

              colorPickerSection
            }
          }

          // Background settings section
          if let preset = presetManager.currentPreset,
            !preset.isDefault
          {
            Section("Background") {
              // Show background toggle
              Toggle(
                "Show Background Image",
                isOn: Binding(
                  get: { preset.showBackgroundImage ?? false },
                  set: { newValue in
                    updatePresetBackgroundVisibility(newValue)
                  }
                ))

              // Only show controls if background is enabled and has an image
              if preset.showBackgroundImage ?? false,
                preset.backgroundImageId != nil
                  || (preset.useArtworkAsBackground ?? false && preset.artworkId != nil)
              {
                // Blur Control
                VStack(alignment: .leading, spacing: 8) {
                  Text("Blur")
                    .font(.subheadline)

                  Picker("Blur", selection: $backgroundBlurRadius) {
                    Text("None").tag(0.0)
                    Text("Low").tag(3.0)
                    Text("Medium").tag(15.0)
                    Text("High").tag(25.0)
                  }
                  .pickerStyle(.segmented)
                  .labelsHidden()
                }

                // Opacity Control
                VStack(alignment: .leading, spacing: 8) {
                  Text("Opacity")
                    .font(.subheadline)

                  Picker(
                    "Opacity",
                    selection: Binding(
                      get: {
                        // Convert opacity value to closest option
                        switch backgroundOpacity {
                        case 0..<0.5: return 0.3
                        case 0.5..<0.85: return 0.65
                        default: return 1.0
                        }
                      },
                      set: { newValue in
                        backgroundOpacity = newValue
                      }
                    )
                  ) {
                    Text("Low").tag(0.3)
                    Text("Medium").tag(0.65)
                    Text("Full").tag(1.0)
                  }
                  .pickerStyle(.segmented)
                  .labelsHidden()
                }

                Text("Edit background image in preset settings")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
        .padding(.top, -30)
        .navigationTitle("View Settings")
        .navigationBarTitleDisplayMode(.inline)
        .listSectionSpacing(.compact)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
      .onChange(of: showingListView) { _, newValue in
        globalSettings.setShowingListView(newValue)
      }
      .preferredColorScheme(
        globalSettings.appearance == .system
          ? nil
          : (globalSettings.appearance == .dark ? .dark : .light)
      )
      .onAppear {
        if let preset = presetManager.currentPreset {
          backgroundBlurRadius = preset.backgroundBlurRadius ?? 15.0
          backgroundOpacity = preset.backgroundOpacity ?? 0.65
        }
      }
      .onChange(of: backgroundBlurRadius) { _, _ in
        updatePresetBackground()
      }
      .onChange(of: backgroundOpacity) { _, _ in
        updatePresetBackground()
      }
    }

    private func updatePresetBackground() {
      guard let preset = presetManager.currentPreset,
        !preset.isDefault
      else { return }

      var updatedPreset = preset
      updatedPreset.backgroundBlurRadius = backgroundBlurRadius
      updatedPreset.backgroundOpacity = backgroundOpacity

      // Update the preset in the manager
      if let index = presetManager.presets.firstIndex(where: { $0.id == preset.id }) {
        var updatedPresets = presetManager.presets
        updatedPresets[index] = updatedPreset
        presetManager.setPresets(updatedPresets)

        // Update current preset if it's the active one
        if presetManager.currentPreset?.id == preset.id {
          presetManager.setCurrentPreset(updatedPreset)
        }

        // Save the changes
        PresetStorage.saveCustomPresets(presetManager.presets.filter { !$0.isDefault })
      }
    }

    private func updatePresetBackgroundVisibility(_ show: Bool) {
      guard let preset = presetManager.currentPreset,
        !preset.isDefault
      else { return }

      var updatedPreset = preset
      updatedPreset.showBackgroundImage = show

      // Update the preset in the manager
      if let index = presetManager.presets.firstIndex(where: { $0.id == preset.id }) {
        var updatedPresets = presetManager.presets
        updatedPresets[index] = updatedPreset
        presetManager.setPresets(updatedPresets)

        // Update current preset if it's the active one
        if presetManager.currentPreset?.id == preset.id {
          presetManager.setCurrentPreset(updatedPreset)
        }

        // Save the changes
        PresetStorage.saveCustomPresets(presetManager.presets.filter { !$0.isDefault })
      }
    }
  }
#endif
