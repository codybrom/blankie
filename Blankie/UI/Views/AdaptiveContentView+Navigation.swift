//
//  AdaptiveContentView+Navigation.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    @ViewBuilder
    var navigationHeader: some View {
      VStack(spacing: 0) {
        // Safe area extension
        if !isLargeDevice {
          Color.clear
            .frame(height: safeAreaTop)
        }
        // Title and controls
        HStack {
          if !isLargeDevice {
            Button(action: {
              showingPresetPicker = true
            }) {
              HStack(spacing: 8) {
                HStack(spacing: 6) {
                  if audioManager.soloModeSound != nil {
                    Image(systemName: "headphones.circle.fill")
                      .font(.system(size: 24))
                      .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                  }
                  Text(navigationTitleText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                }
                Image(systemName: "chevron.down")
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(.secondary)
              }
            }
            .buttonStyle(.plain)
            .padding(.leading)
          }
          Spacer()

          if !isLargeDevice {
            HStack(spacing: 16) {
              TimerButton()
            }
            .padding(.trailing)
          }
        }
        .frame(height: isLargeDevice ? 0 : 50)
      }
      .background(
        isLargeDevice ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Material.ultraThinMaterial)
      )
    }

    // Safe area insets helper
    var safeAreaTop: CGFloat {
      #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
        {
          return window.safeAreaInsets.top
        }
      #endif
      return 0
    }

    // Header height for spacing
    var headerHeight: CGFloat {
      let height: CGFloat = 50  // Title bar height (fixed)
      return height + safeAreaTop
    }

    // Combined status indicator view
    @ViewBuilder
    var statusIndicatorView: some View {
      VStack(spacing: 0) {
        // Reorder mode banner
        if editMode == .active && showingListView && !isLargeDevice {
          reorderModeIndicator
            .transition(.opacity)
        }

        if !audioManager.hasSelectedSounds {
          noSoundsSelectedIndicator
            .transition(.opacity)
            .onAppear {
              print("🎨 UI: No sounds selected banner appeared")
            }
            .onDisappear {
              print("🎨 UI: No sounds selected banner disappeared")
            }
        }
      }
      .animation(.easeInOut(duration: 0.2), value: audioManager.soloModeSound?.id)
      .animation(.easeInOut(duration: 0.2), value: audioManager.isGloballyPlaying)
      .animation(.easeInOut(duration: 0.2), value: audioManager.sounds.map(\.isSelected))
      .animation(.easeInOut(duration: 0.3), value: editMode)
    }

    // No sounds selected indicator banner
    var noSoundsSelectedIndicator: some View {
      HStack(spacing: 12) {
        Image(systemName: "speaker.slash.fill")
          .font(.system(size: 16))
        Text("No Sounds Selected")
          .font(.system(.subheadline, design: .rounded, weight: .medium))

        Spacer()

        // Reorder button - only show in list view
        if showingListView && !isLargeDevice {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              if editMode == .active {
                exitEditMode()
              } else {
                enterEditMode()
              }
            }
          }) {
            Text(editMode == .active ? "Done" : "Reorder")
              .font(.system(.subheadline, weight: .medium))
              .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          }
          .buttonStyle(.plain)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .foregroundStyle(.secondary)
      .background(.regularMaterial)
    }

    // Reorder mode indicator banner
    var reorderModeIndicator: some View {
      HStack(spacing: 12) {
        Image(systemName: "arrow.up.arrow.down.circle.fill")
          .font(.system(size: 16))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
        Text("Drag to Reorder")
          .font(.system(.subheadline, design: .rounded, weight: .medium))

        Spacer()

        Button("Done") {
          withAnimation(.easeInOut(duration: 0.3)) {
            exitEditMode()
          }
        }
        .font(.system(.subheadline, weight: .medium))
        .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
        .buttonStyle(.plain)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .foregroundStyle(.primary)
      .background(.regularMaterial)
    }
  }
#endif
