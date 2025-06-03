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
    }

    // No sounds selected indicator banner
    var noSoundsSelectedIndicator: some View {
      HStack(spacing: 8) {
        Image(systemName: "speaker.slash.fill")
          .font(.system(size: 16))
        Text("No Sounds Selected")
          .font(.system(.subheadline, design: .rounded, weight: .medium))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .foregroundStyle(.secondary)
      .background(.regularMaterial)
    }
  }
#endif
