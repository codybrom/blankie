//
//  View+ErrorHandling.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

extension View {
  func handleAudioErrors() -> some View {
    self.modifier(AudioErrorHandler())
  }
}
