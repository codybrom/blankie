//
//  GridSoundButtonWrapper.swift
//  Blankie
//
//  Created by Cody Bromley on 6/10/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  struct GridSoundButtonWrapper: View {
    let sound: Sound
    let index: Int
    @Binding var editMode: EditMode
    @Binding var draggedIndex: Int?
    let audioManager: AudioManager
    let onMove: ((Int, Int) -> Void)?

    @State private var isDropTarget = false

    var body: some View {
      Group {
        if editMode == .active {
          GridSoundButton(sound: sound, editMode: $editMode)
            .overlay(
              // Drop target overlay
              RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .allowsHitTesting(false)
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(
                      isDropTarget && draggedIndex != nil && draggedIndex != index
                        ? (GlobalSettings.shared.customAccentColor ?? .accentColor)
                        : Color.clear,
                      lineWidth: 3
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDropTarget)
                )
            )
            .draggable(sound.id.uuidString) {
              // Drag preview
              GridSoundButton(sound: sound, editMode: .constant(.inactive))
                .scaleEffect(0.9)
                .opacity(0.8)
                .onAppear {
                  draggedIndex = index
                }
            }
            .dropDestination(for: String.self) { _, _ in
              // Reset drop target state
              isDropTarget = false

              if let draggedIdx = draggedIndex,
                draggedIdx != index
              {
                // Perform the move on drop using the provided move handler
                withAnimation(.easeInOut(duration: 0.2)) {
                  if let onMove = onMove {
                    onMove(draggedIdx, index)
                  } else {
                    // Fallback to default behavior for backward compatibility
                    audioManager.moveVisibleSound(from: draggedIdx, to: index)
                  }
                }
                draggedIndex = nil
                return true
              }
              return false
            } isTargeted: { targeted in
              // Update drop target state for visual feedback
              isDropTarget = targeted
            }
        } else {
          GridSoundButton(sound: sound, editMode: $editMode)
        }
      }
    }
  }
#endif
