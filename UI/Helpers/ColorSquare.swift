//
//  ColorSquare.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

struct ColorSquare: View {
    let color: AccentColor
    let isSelected: Bool
    @ObservedObject private var globalSettings = GlobalSettings.shared
    
    var textColorForAccent: Color {
        if let nsColor = NSColor(color.color ?? .accentColor).usingColorSpace(.sRGB) {
            let brightness = (0.299 * nsColor.redComponent) +
                           (0.587 * nsColor.greenComponent) +
                           (0.114 * nsColor.blueComponent)
            return brightness > 0.5 ? .black : .white
        }
        return .white
    }
    
    var body: some View {
        Button(action: {
            globalSettings.setAccentColor(color.color)
        }) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.color ?? Color.accentColor)
                .frame(width: 24, height: 24)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(textColorForAccent, lineWidth: 2)
                            .padding(2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
