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

    @ObservedObject private var globalSettings = GlobalSettings.shared
    @ObservedObject private var audioManager = AudioManager.shared
    @Environment(\.dismiss) var dismiss

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

            // Hide sliders for inactive sounds - not applicable in Quick Mix mode
            if !audioManager.isQuickMix {
              Toggle(
                "Hide Sliders for Inactive Sounds",
                isOn: Binding(
                  get: { globalSettings.hideInactiveSoundSliders },
                  set: { globalSettings.setHideInactiveSoundSliders($0) }
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
    }

    @ViewBuilder
    private var colorPickerSection: some View {
      LazyVGrid(
        columns: Array(
          repeating: GridItem(.flexible(), spacing: 10),
          count: {
            #if os(macOS)
              return 7  // 13 colors (including system) = 1 row of 7 + 1 row of 6
            #else
              return 6  // 12 colors = 2 rows of 6
            #endif
          }()),
        spacing: 10
      ) {
        #if os(macOS)
          systemColorButton
        #endif
        customColorButtons
      }
      .padding(.vertical, 8)
    }

    #if os(macOS)
      @ViewBuilder
      private var systemColorButton: some View {
        Button(action: {
          globalSettings.setAccentColor(nil)
        }) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [.red, .orange, .yellow, .green, .blue, .purple],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 36, height: 36)
              .opacity(0.8)

            Circle()
              .fill(Color(white: 0.9))
              .frame(width: 28, height: 28)

            Image(systemName: "gearshape.fill")
              .font(.system(size: 16))
              .foregroundColor(.secondary)

            if globalSettings.customAccentColor == nil {
              Circle()
                .strokeBorder(Color.primary, lineWidth: 2)
                .frame(width: 36, height: 36)
            }
          }
        }
        .buttonStyle(.plain)
      }
    #endif

    @ViewBuilder
    private var customColorButtons: some View {
      ForEach(AccentColor.allCases.filter { $0 != .system }, id: \.self) { accentColor in
        Button(action: {
          globalSettings.setAccentColor(accentColor.color)
        }) {
          ZStack {
            Circle()
              .fill(accentColor.color ?? .accentColor)
              .frame(width: 36, height: 36)

            if let customColor = globalSettings.customAccentColor,
              let colorOption = accentColor.color,
              customColor.description == colorOption.description
            {
              Circle()
                .strokeBorder(Color.primary, lineWidth: 2)
                .frame(width: 36, height: 36)
              Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundColor(.white)
            }
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
#endif
