//
//  DraggableSoundIcon+Helpers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension DraggableSoundIcon {
    // MARK: - Helper Methods

    func getSoundAuthor(for sound: Sound) -> String? {
      // Credits functionality has been removed or changed
      return nil
    }

    func isCustomSound(_ sound: Sound) -> Bool {
      return sound.isCustom
    }

    func startJiggle() {
      withAnimation(
        Animation.linear(duration: 0.08)
          .repeatForever(autoreverses: true)
      ) {
        jiggleAnimation = true
      }
    }

    func stopJiggle() {
      jiggleAnimation = false
    }

    func handleJiggle() {
      if editMode == .active {
        startJiggle()
      } else {
        stopJiggle()
      }
    }

    func createDragItem() -> NSItemProvider {
      return NSItemProvider(object: "\(index)" as NSString)
    }
  }
#endif
