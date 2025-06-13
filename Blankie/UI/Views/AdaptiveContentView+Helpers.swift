import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Calculate filtered sounds based on current preset and hideInactiveSounds preference
    var filteredSounds: [Sound] {
      // Include soundsUpdateTrigger to force updates when sounds change
      _ = soundsUpdateTrigger
      let visibleSounds = audioManager.getVisibleSounds()

      return visibleSounds.filter { sound in
        // First check if sound is included in current preset
        if let currentPreset = presetManager.currentPreset {
          // For default preset, show all sounds
          if currentPreset.isDefault {
            // Apply hideInactiveSounds filter for default preset (but not in edit mode)
            if hideInactiveSounds && editMode == .inactive {
              return sound.isSelected
            } else {
              return true
            }
          } else {
            // For custom presets, only show sounds that are part of the preset
            let isInPreset = currentPreset.soundStates.contains { $0.fileName == sound.fileName }
            if !isInPreset {
              return false
            }

            // If sound is in preset, apply hideInactiveSounds filter (but not in edit mode)
            if hideInactiveSounds && editMode == .inactive {
              return sound.isSelected
            } else {
              return true
            }
          }
        } else {
          // No current preset - show all sounds with hideInactiveSounds filter (but not in edit mode)
          if hideInactiveSounds && editMode == .inactive {
            return sound.isSelected
          } else {
            return true
          }
        }
      }
    }

    // Determine if we're on iPad or Mac
    var isLargeDevice: Bool {
      horizontalSizeClass == .regular
    }

    // Preset background view
    @ViewBuilder
    var presetBackgroundView: some View {
      if let preset = presetManager.currentPreset,
        preset.showBackgroundImage ?? false,
        let imageData = preset.useArtworkAsBackground ?? false
          ? preset.artworkData : preset.backgroundImageData,
        let uiImage = UIImage(data: imageData)
      {
        GeometryReader { geometry in
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .blur(radius: preset.backgroundBlurRadius ?? 15)
            .opacity(preset.backgroundOpacity ?? 0.65)
            .clipped()
            .overlay(
              Color.black.opacity(0.2)  // Add slight darkening for better UI contrast
            )
        }
        .ignoresSafeArea()
      }
    }

    // Computed properties for columns and columnWidth
    var columns: [GridItem] {
      // This is now only used for macOS since iOS uses fixed 2-column grid
      #if os(macOS)
        // macOS can continue using icon size settings
        switch globalSettings.iconSize {
        case .small:
          return [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 4)]
        case .medium:
          return [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)]
        case .large:
          return [GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 24)]
        }
      #else
        // iOS uses fixed 2-column grid (handled in gridView)
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
      #endif
    }

    var columnWidth: CGFloat {
      #if os(macOS)
        switch globalSettings.iconSize {
        case .small:
          return 60
        case .medium:
          return 150
        case .large:
          return 300
        }
      #else
        // iOS uses fixed 2-column grid
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 16
        let padding: CGFloat = 32  // 16 on each side
        let width = (screenWidth - padding - spacing) / 2
        return width
      #endif
    }

    // Calculate offset for dodging animation
    func calculateDodgeOffset(for index: Int) -> CGSize {
      guard let draggedIndex = draggedIndex,
        let hoveredIndex = hoveredIndex,
        draggedIndex != index
      else {
        return .zero
      }

      // Calculate grid dimensions
      let columnsCount = isLargeDevice ? Int(ceil(Double(filteredSounds.count) / 4.0)) : 3
      let itemsPerRow = isLargeDevice ? min(4, filteredSounds.count) : columnsCount

      // Get row and column for current index and hovered index
      let currentRow = index / itemsPerRow
      let currentCol = index % itemsPerRow
      let hoveredRow = hoveredIndex / itemsPerRow
      let hoveredCol = hoveredIndex % itemsPerRow

      // Only dodge if we're in the same row or adjacent rows
      let rowDifference = abs(currentRow - hoveredRow)
      if rowDifference > 1 {
        return .zero
      }

      // Calculate dodge direction and magnitude
      let dodgeDistance: CGFloat = 20
      var offsetX: CGFloat = 0
      var offsetY: CGFloat = 0

      // Same row - horizontal dodging
      if currentRow == hoveredRow {
        if currentCol < hoveredCol {
          offsetX = -dodgeDistance
        } else if currentCol > hoveredCol {
          offsetX = dodgeDistance
        }
      }
      // Adjacent rows - slight vertical dodging
      else if rowDifference == 1 {
        if currentRow < hoveredRow {
          offsetY = -dodgeDistance / 2
        } else {
          offsetY = dodgeDistance / 2
        }

        // Also add some horizontal movement for items near the hovered column
        let colDifference = abs(currentCol - hoveredCol)
        if colDifference <= 1 {
          if currentCol < hoveredCol {
            offsetX = -dodgeDistance / 2
          } else if currentCol > hoveredCol {
            offsetX = dodgeDistance / 2
          }
        }
      }

      return CGSize(width: offsetX, height: offsetY)
    }

    // Timer management for drag state
    func startDragResetTimer() {
      dragResetTimer?.invalidate()
      dragResetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
        // Reset drag state after 3 seconds of no activity
        draggedIndex = nil
        hoveredIndex = nil
      }
    }

    func cancelDragResetTimer() {
      dragResetTimer?.invalidate()
      dragResetTimer = nil
    }

    // MARK: - Helper Properties

    var hasSelectedSounds: Bool {
      audioManager.hasSelectedSounds
    }

    func enterEditMode() {
      editMode = .active
    }

    func exitEditMode() {
      editMode = .inactive
    }
  }
#endif
