//
//  Link+pointHandCursor.swift
//  Blankie
//
//  Created by Cody Bromley on 1/11/25.
//

import SwiftUI

extension Link {
  #if os(macOS)
    func pointingHandCursor() -> some View {
      self.onHover { inside in
        if inside {
          NSCursor.pointingHand.set()
        } else {
          NSCursor.arrow.set()
        }
      }
    }
  #else
    // iOS/visionOS version - no cursor needed, but keeping the method for API compatibility
    func pointingHandCursor() -> some View {
      // On iOS, return the view unchanged
      return self
    }
  #endif
}
