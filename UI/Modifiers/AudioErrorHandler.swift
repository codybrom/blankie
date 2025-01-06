//
//  AudioErrorHandler.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import SwiftUI

struct AudioErrorHandler: ViewModifier {
    @ObservedObject private var errorReporter = ErrorReporter.shared
    @State private var showingError = false

    func body(content: Content) -> some View {
        content
            .onChange(of: errorReporter.lastError != nil) { hasError in
                showingError = hasError
            }
            .alert("Error", isPresented: $showingError) {
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
