//
//  AudioErrorHandler.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

struct AudioErrorHandler: ViewModifier {
  @ObservedObject private var errorReporter = ErrorReporter.shared

  func body(content: Content) -> some View {
    content
      .alert(
        "Error",
        isPresented: .init(
          get: { errorReporter.lastError != nil },
          set: { if !$0 { errorReporter.lastError = nil } }
        )
      ) {
        Button("OK") {
          errorReporter.lastError = nil
        }
      } message: {
        if let error = errorReporter.lastError {
          Text(error.localizedDescription)
        }
      }
  }
}
