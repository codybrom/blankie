//
//  PreferencesView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @State private var showingRestartAlert = false
  private let colorsPerRow = 6

  var accentColorForUI: Color {
    globalSettings.customAccentColor ?? .accentColor
  }

  var textColorForAccent: Color {
    if let nsColor = NSColor(accentColorForUI).usingColorSpace(.sRGB) {
      let brightness =
        (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
        + (0.114 * nsColor.blueComponent)
      return brightness > 0.5 ? .black : .white
    }
    return .white
  }

  var appearanceButtons: some View {
    HStack(spacing: 8) {
      ForEach(AppearanceMode.allCases, id: \.self) { mode in
        Button(
          action: { globalSettings.setAppearance(mode) },
          label: {
            HStack(spacing: 4) {
              Image(systemName: mode.icon)
              Text(mode.localizedName)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              globalSettings.appearance == mode ? accentColorForUI : Color.secondary.opacity(0.2)
            )
            .foregroundColor(globalSettings.appearance == mode ? textColorForAccent : .primary)
            .cornerRadius(6)
          }
        )
        .buttonStyle(.plain)
      }
    }
  }

  var colorButtons: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Button(
          action: { globalSettings.setAccentColor(nil) },
          label: {
            Text("System", comment: "System accent color option")
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
        )
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

  var languageMenu: some View {
    Picker(
      "Language",
      selection: Binding(
        get: { globalSettings.language },
        set: { globalSettings.setLanguage($0) }
      )
    ) {
      ForEach(globalSettings.availableLanguages) { language in
        HStack {
          Image(systemName: language.icon)
          Text(language.displayName)
        }
        .tag(language)
      }
    }
    .pickerStyle(.menu)
    .labelsHidden()
    .frame(width: 180)
  }

  var body: some View {
    Form {
      Section {
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

        HStack(spacing: 16) {
          Text("Language")
            .frame(width: 100, alignment: .leading)
          languageMenu
        }
      } header: {
        Text("Appearance")
      }

      Section {
        Toggle(
          LocalizedStringKey("Always Start Paused"),
          isOn: Binding(
            get: { globalSettings.alwaysStartPaused },
            set: { globalSettings.setAlwaysStartPaused($0) }
          )
        )
        .help("If disabled, Blankie will immediately play your most recent preset on launch")
        .tint(accentColorForUI)
      } header: {
        Text("Behavior")
      }
    }
    .formStyle(.grouped)
    .padding()
    .frame(width: 500)
    .onChange(of: globalSettings.needsRestartForLanguageChange) {
      if globalSettings.needsRestartForLanguageChange {
        showingRestartAlert = true
        globalSettings.needsRestartForLanguageChange = false  // reset
      }
    }
    .alert(
      Text("Language Changed"),
      isPresented: $showingRestartAlert
    ) {
      Button("Restart Now") {
        Language.restartApp()
      }
      Button("Later", role: .cancel) {}
    } message: {
      Text("You will need to restart Blankie for the language change to take effect.")
    }
  }
}

#Preview("Preferences") {
  PreferencesView()
}

#Preview("Dark Mode") {
  PreferencesView()
    .preferredColorScheme(.dark)
}
