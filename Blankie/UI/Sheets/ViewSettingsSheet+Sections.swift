//
//  ViewSettingsSheet+Sections.swift
//  Blankie
//
//  Created by Cody Bromley on 6/16/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension ViewSettingsSheet {
    @ViewBuilder
    var colorPickerSection: some View {
      ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(AccentColor.allCases.filter { $0 != .system }, id: \.self) { color in
              colorPickerItem(for: color)
                .id(color)  // Add ID for ScrollViewReader
            }
          }
          .padding(.horizontal, 20)  // Increased padding to prevent clipping
          .padding(.vertical, 2)  // Add vertical padding inside ScrollView
          .padding(.bottom, 10)
        }
        .scrollIndicators(.visible, axes: .horizontal)  // Always show horizontal indicator
        .scrollIndicatorsFlash(trigger: showScrollIndicator)  // Flash when triggered
        .onAppear {
          // Find the currently selected color and scroll to it
          if let currentColor = AccentColor.allCases.first(where: {
            $0.color == globalSettings.customAccentColor
          }) {
            // Use a slight delay to prevent visual glitches
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              proxy.scrollTo(currentColor, anchor: .center)
            }
          }
          // Flash indicators on appear to show it's scrollable
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showScrollIndicator.toggle()
          }
        }
      }
      .padding(.vertical, 4)
    }

    @ViewBuilder
    func colorPickerItem(for color: AccentColor) -> some View {
      let isSelected = globalSettings.customAccentColor == color.color

      Circle()
        .fill(color.color ?? .accentColor)
        .frame(width: 44, height: 44)
        .overlay(
          Circle()
            .strokeBorder(
              isSelected ? Color.primary : Color.gray.opacity(0.3),
              lineWidth: isSelected ? 3 : 1
            )
        )
        .overlay(
          isSelected
            ? Image(systemName: "checkmark")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.white)
            : nil
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)  // Reduced scale to prevent clipping
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            globalSettings.setAccentColor(color.color)
          }
        }
    }

    @ViewBuilder
    var backgroundSection: some View {
      Group {
        // Show background toggle
        Toggle(
          "Show Background Image",
          isOn: Binding(
            get: { presetManager.currentPreset?.showBackgroundImage ?? false },
            set: { newValue in
              updateBackgroundSetting(showBackground: newValue)
            }
          )
        )

        // Background image source - only show if background is enabled
        if presetManager.currentPreset?.showBackgroundImage ?? false {
          VStack(alignment: .leading, spacing: 12) {
            Text("Background Image")
              .font(.subheadline)
              .foregroundColor(.secondary)

            Picker(
              "Background Source",
              selection: Binding(
                get: { presetManager.currentPreset?.useArtworkAsBackground ?? false },
                set: { newValue in
                  updateBackgroundSetting(useArtworkAsBackground: newValue)
                }
              )
            ) {
              Text("Custom Background").tag(false)
              Text("Use Preset Artwork").tag(true)
            }
            .pickerStyle(.segmented)

            // Background blur
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Blur")
                  .font(.subheadline)
                Spacer()
                Text("\(Int(backgroundBlurRadius))")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }

              Slider(
                value: $backgroundBlurRadius,
                in: 0...50,
                step: 1
              ) { _ in
                updateBackgroundBlurAndOpacity()
              }
            }

            // Background opacity
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("Opacity")
                  .font(.subheadline)
                Spacer()
                Text("\(Int(backgroundOpacity * 100))%")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }

              Slider(
                value: $backgroundOpacity,
                in: 0...1,
                step: 0.05
              ) { _ in
                updateBackgroundBlurAndOpacity()
              }
            }
          }
        }
      }
    }

    // MARK: - Helper Methods

    private func updateBackgroundSetting(
      showBackground: Bool? = nil, useArtworkAsBackground: Bool? = nil
    ) {
      guard let currentPreset = presetManager.currentPreset,
        let index = presetManager.presets.firstIndex(where: { $0.id == currentPreset.id })
      else { return }

      var updatedPreset = currentPreset

      if let show = showBackground {
        updatedPreset.showBackgroundImage = show
      }

      if let useArtwork = useArtworkAsBackground {
        updatedPreset.useArtworkAsBackground = useArtwork
      }

      presetManager.updatePresetAtIndex(index, with: updatedPreset)
      presetManager.setCurrentPreset(updatedPreset)
      presetManager.savePresets()
    }

    private func updateBackgroundBlurAndOpacity() {
      guard let currentPreset = presetManager.currentPreset,
        let index = presetManager.presets.firstIndex(where: { $0.id == currentPreset.id })
      else { return }

      var updatedPreset = currentPreset
      updatedPreset.backgroundBlurRadius = backgroundBlurRadius
      updatedPreset.backgroundOpacity = backgroundOpacity

      presetManager.updatePresetAtIndex(index, with: updatedPreset)
      presetManager.setCurrentPreset(updatedPreset)
      presetManager.savePresets()
    }
  }
#endif
