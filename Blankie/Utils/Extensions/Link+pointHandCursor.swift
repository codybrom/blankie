//
//  Link+pointHandCursor.swift
//  Blankie
//
//  Created by Cody Bromley on 1/11/25.
//

import SwiftUI

extension Link {
    func pointingHandCursor() -> some View {
        self.onHover { inside in
            if inside {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}
