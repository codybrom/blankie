//
//  PreferencesView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct PreferencesView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  private let colorsPerRow = 6

  var accentColorForUI: Color {
    globalSettings.customAccentColor ?? .accentColor
  }

  var textColorForAccent: Color {
    #if os(macOS)
      if let nsColor = NSColor(accentColorForUI).usingColorSpace(.sRGB) {
        let brightness =
          (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
          + (0.114 * nsColor.blueComponent)
        return brightness > 0.5 ? .black : .white
      }
      return .white
    #elseif os(iOS) || os(visionOS)
      let uiColor = UIColor(accentColorForUI)
      var red: CGFloat = 0
      var green: CGFloat = 0
      var blue: CGFloat = 0
      var alpha: CGFloat = 0

      uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
      let brightness = (0.299 * red) + (0.587 * green) + (0.114 * blue)
      return brightness > 0.5 ? .black : .white
    #else
      return .white
    #endif
  }

  var appearanceButtons: some View {
    HStack(spacing: 8) {
      ForEach(AppearanceMode.allCases, id: \.self) { mode in
        Button(action: {
          globalSettings.setAppearance(mode)
        }) {
          HStack(spacing: 4) {
            Image(systemName: mode.icon)
            Text(mode == .system ? "System" : mode.rawValue)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            globalSettings.appearance == mode ? accentColorForUI : Color.secondary.opacity(0.2)
          )
          .foregroundColor(globalSettings.appearance == mode ? textColorForAccent : .primary)
          .cornerRadius(6)
        }
        .buttonStyle(.plain)
      }
    }
  }

  var colorButtons: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Button(action: {
          globalSettings.setAccentColor(nil)
        }) {
          Text("System")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              globalSettings.customAccentColor == nil
                ? accentColorForUI : Color.secondary.opacity(0.2)
            )
            .foregroundColor(
              globalSettings.customAccentColor == nil ? textColorForAccent : .primary
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)

        ForEach(Array(AccentColor.allCases.dropFirst().prefix(colorsPerRow - 1)), id: \.self) {
          color in
          ColorSquare(color: color, isSelected: color.color == globalSettings.customAccentColor)
        }
      }

      HStack(spacing: 8) {
        ForEach(Array(AccentColor.allCases.dropFirst().dropFirst(colorsPerRow - 1)), id: \.self) {
          color in
          ColorSquare(color: color, isSelected: color.color == globalSettings.customAccentColor)
        }
      }
    }
  }

  var body: some View {
    Form {
      Section("Appearance") {
        HStack(spacing: 16) {
          Text("Appearance")
            .frame(width: 100, alignment: .leading)
          appearanceButtons
        }

        HStack(alignment: .top, spacing: 16) {
          Text("Accent Color")
            .frame(width: 100, alignment: .leading)
          colorButtons
        }
      }

      Section("Behavior") {
        Toggle(
          "Always Start Paused",
          isOn: Binding(
            get: { globalSettings.alwaysStartPaused },
            set: { globalSettings.setAlwaysStartPaused($0) }
          )
        )
        #if os(macOS)
          .help("Wait for play button before starting sounds")
        #endif
        .tint(accentColorForUI)
      }

    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 450)
  }
}

#Preview("Preferences") {
  PreferencesView()
}

#Preview("Dark Mode") {
  PreferencesView()
    .preferredColorScheme(.dark)
}
