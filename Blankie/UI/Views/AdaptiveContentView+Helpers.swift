import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Calculate filtered sounds based on hideInactiveSounds preference
    var filteredSounds: [Sound] {
      let sounds = audioManager.sounds
      return sounds.filter { sound in
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
  }
#endif
