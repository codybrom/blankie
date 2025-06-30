//
//  ThemePickerSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  struct ThemePickerSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var globalSettings = GlobalSettings.shared

    var body: some View {
      NavigationView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
              .font(.headline)

            HStack {
              Spacer()
              HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                  Button(action: {
                    globalSettings.setAppearance(mode)
                  }) {
                    HStack(spacing: 4) {
                      Image(systemName: mode.icon)
                      Text(mode.localizedName)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                      globalSettings.appearance == mode
                        ? (globalSettings.customAccentColor ?? .accentColor)
                        : Color.secondary.opacity(0.2)
                    )
                    .foregroundColor(
                      globalSettings.appearance == mode ? .white : .primary
                    )
                    .cornerRadius(8)
                  }
                  .buttonStyle(.plain)
                }
              }
              Spacer()
            }
          }

          VStack(alignment: .leading, spacing: 12) {
            Text("Accent Color")
              .font(.headline)

            let availableColors = Array(AccentColor.allCases.dropFirst())
            let colorsPerRow = 6

            VStack(alignment: .center, spacing: 12) {
              ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 12) {
                  Spacer()
                  ForEach(0..<colorsPerRow, id: \.self) { col in
                    let index = row * colorsPerRow + col
                    if index < availableColors.count {
                      let color = availableColors[index]
                      Button(action: {
                        globalSettings.setAccentColor(color.color)
                      }) {
                        Circle()
                          .fill(color.color ?? .accentColor)
                          .frame(width: 44, height: 44)
                          .overlay(
                            Circle()
                              .stroke(
                                globalSettings.customAccentColor == color.color ? .white : .clear,
                                lineWidth: 3
                              )
                          )
                          .overlay(
                            globalSettings.customAccentColor == color.color
                              ? Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                              : nil
                          )
                      }
                      .buttonStyle(.plain)
                    }
                  }
                  Spacer()
                }
              }
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            let needsReset =
              globalSettings.appearance != .system || globalSettings.customAccentColor != nil
            if needsReset {
              Button("Reset") {
                globalSettings.setAppearance(.system)
                globalSettings.setAccentColor(nil)
              }
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
              isPresented = false
            }
          }
        }
      }
      .presentationDetents([.fraction(0.45)])
    }
  }
#endif
