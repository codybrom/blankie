//
//  ColorPickerView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

/// Note: Currently unused
struct ColorPickerView: View {
    @ObservedObject var globalSettings = GlobalSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appearance")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation {
                        globalSettings.setAppearance(mode)
                    }
                }) {
                    HStack {
                        Image(systemName: mode.icon)
                            .frame(width: 16, height: 16)

                        Text(mode.rawValue)
                            .foregroundColor(.primary)

                        Spacer()

                        if globalSettings.appearance == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

            Divider()
                .padding(.vertical, 8)

            Text("Accent Color")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(AccentColor.allCases, id: \.self) { color in
                Button(action: {
                    globalSettings.setAccentColor(color.color)
                }) {
                    HStack {
                        Circle()
                            .fill(color.color ?? .accentColor)
                            .frame(width: 16, height: 16)

                        Text(color.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if (color == .system && globalSettings.customAccentColor == nil) ||
                           (color.color == globalSettings.customAccentColor) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

        }
        .frame(width: 200)
    }
}
