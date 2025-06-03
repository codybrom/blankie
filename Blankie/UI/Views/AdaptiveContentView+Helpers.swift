import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Calculate filtered sounds based on hideInactiveSounds preference and visibility
    var filteredSounds: [Sound] {
      // Include soundsUpdateTrigger to force updates when sounds change
      _ = soundsUpdateTrigger
      let visibleSounds = audioManager.getVisibleSounds()
      return visibleSounds.filter { sound in
        if hideInactiveSounds {
          return sound.isSelected
        } else {
          return true
        }
      }
    }

    // Determine if we're on iPad or Mac
    var isLargeDevice: Bool {
      horizontalSizeClass == .regular
    }

    // Computed properties for columns and columnWidth
    var columns: [GridItem] {
      if isLargeDevice {
        // iPad/larger screens
        switch globalSettings.iconSize {
        case .small:
          return [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 4)]
        case .medium:
          return [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)]
        case .large:
          return [GridItem(.adaptive(minimum: 240, maximum: 280), spacing: 24)]
        }
      } else {
        // iPhone
        let columnCount: Int
        switch globalSettings.iconSize {
        case .small:
          columnCount = 4
        case .medium:
          columnCount = 3
        case .large:
          columnCount = 2
        }
        let spacing: CGFloat
        switch globalSettings.iconSize {
        case .small:
          spacing = 1
        case .medium:
          spacing = 10
        case .large:
          spacing = 8
        }
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
      }
    }

    var columnWidth: CGFloat {
      if isLargeDevice {
        switch globalSettings.iconSize {
        case .small:
          return 60
        case .medium:
          return 150
        case .large:
          return 300
        }
      } else {
        #if os(iOS)
          let screenWidth = UIScreen.main.bounds.width
          let columnCount: CGFloat
          switch globalSettings.iconSize {
          case .small:
            columnCount = 4
          case .medium:
            columnCount = 3
          case .large:
            columnCount = 2
          }
          let spacing: CGFloat
          switch globalSettings.iconSize {
          case .small:
            spacing = 1
          case .medium:
            spacing = 10
          case .large:
            spacing = 8
          }
          let width = (screenWidth - (40 + (spacing * (columnCount - 1)))) / columnCount
          return width
        #else
          return 100  // Fallback for other platforms
        #endif
      }
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
  }
#endif
