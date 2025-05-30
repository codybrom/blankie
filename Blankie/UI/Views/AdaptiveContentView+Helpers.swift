import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Calculate filtered sounds based on hideInactiveSounds preference and visibility
    var filteredSounds: [Sound] {
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
        return [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)]
      } else {
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
      }
    }

    var columnWidth: CGFloat {
      if isLargeDevice {
        return 150
      } else {
        #if os(iOS)
          return (UIScreen.main.bounds.width - 40) / 3  // 40 for padding/spacing
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
