//
//  SoundDropDelegate.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import SwiftUI

struct SoundDropDelegate: DropDelegate {
  let audioManager: AudioManager
  let targetIndex: Int
  let sounds: [Sound]
  @Binding var draggedIndex: Int?
  @Binding var hoveredIndex: Int?
  let cancelTimer: () -> Void

  func dropEntered(info: DropInfo) {
    // Only update hover and provide haptic if we're actively dragging
    guard draggedIndex != nil else { return }

    hoveredIndex = targetIndex

    if GlobalSettings.shared.enableHaptics {
      #if os(iOS)
        print("🎯 HAPTIC: dropEntered - light impact")
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
      #endif
    }
  }

  func dropExited(info: DropInfo) {
    if hoveredIndex == targetIndex {
      hoveredIndex = nil
    }
  }

  func dropUpdated(info: DropInfo) -> DropProposal? {
    // Keep the hovered index updated
    hoveredIndex = targetIndex
    return DropProposal(operation: .move)
  }

  func performDrop(info: DropInfo) -> Bool {
    guard let provider = info.itemProviders(for: [.text]).first else { return false }

    // Immediate haptic feedback on drop
    if GlobalSettings.shared.enableHaptics {
      #if os(iOS)
        print("🎯 HAPTIC: performDrop - success notification")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
      #endif
    }

    provider.loadObject(ofClass: NSString.self) { object, _ in
      guard let sourceIndexString = object as? String,
        let sourceIndex = Int(sourceIndexString)
      else { return }

      DispatchQueue.main.async {
        if sourceIndex != targetIndex {
          audioManager.moveVisibleSound(from: sourceIndex, to: targetIndex)
        }
        cancelTimer()
        draggedIndex = nil
        hoveredIndex = nil
      }
    }
    return true
  }
}
