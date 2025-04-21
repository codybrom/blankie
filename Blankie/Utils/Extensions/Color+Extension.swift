//
//  AccentColor.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

enum AccentColor: CaseIterable {
  case system
  case red
  case pink
  case orange
  case brown
  case yellow
  case green
  case mint
  case teal
  case cyan
  case blue
  case indigo
  case purple

  var name: String {
    switch self {
    case .system: return NSLocalizedString("System", comment: "Accent color name")
    case .red: return NSLocalizedString("Red", comment: "Accent color name")
    case .pink: return NSLocalizedString("Pink", comment: "Accent color name")
    case .orange: return NSLocalizedString("Orange", comment: "Accent color name")
    case .brown: return NSLocalizedString("Brown", comment: "Accent color name")
    case .yellow: return NSLocalizedString("Yellow", comment: "Accent color name")
    case .green: return NSLocalizedString("Green", comment: "Accent color name")
    case .mint: return NSLocalizedString("Mint", comment: "Accent color name")
    case .teal: return NSLocalizedString("Teal", comment: "Accent color name")
    case .cyan: return NSLocalizedString("Cyan", comment: "Accent color name")
    case .blue: return NSLocalizedString("Blue", comment: "Accent color name")
    case .indigo: return NSLocalizedString("Indigo", comment: "Accent color name")
    case .purple: return NSLocalizedString("Purple", comment: "Accent color name")
    }
  }

  var color: Color? {
    switch self {
    case .system: return nil
    case .red: return .red
    case .pink: return .pink
    case .orange: return .orange
    case .brown: return .brown
    case .yellow: return .yellow
    case .green: return .green
    case .mint: return .mint
    case .teal: return .teal
    case .cyan: return .cyan
    case .blue: return .blue
    case .indigo: return .indigo
    case .purple: return .purple
    }
  }
}

enum AppearanceMode: String, CaseIterable {
  case system = "system"
  case light = "light"
  case dark = "dark"

  var localizedName: String {
    switch self {
    case .system: return NSLocalizedString("System", comment: "Appearance mode")
    case .light: return NSLocalizedString("Light", comment: "Appearance mode")
    case .dark: return NSLocalizedString("Dark", comment: "Appearance mode")
    }
  }

  var icon: String {
    switch self {
    case .system: return "circle.lefthalf.filled"
    case .light: return "sun.max.fill"
    case .dark: return "moon.fill"
    }
  }

  var displayName: String {
    localizedName
  }
}

extension Color {
  var toString: String {
    switch self {
    case .red: return "red"
    case .pink: return "pink"
    case .orange: return "orange"
    case .brown: return "brown"
    case .yellow: return "yellow"
    case .green: return "green"
    case .mint: return "mint"
    case .teal: return "teal"
    case .cyan: return "cyan"
    case .blue: return "blue"
    case .indigo: return "indigo"
    case .purple: return "purple"
    default: return ""
    }
  }

  private static let colorMap: [String: Color] = [
    "red": .red,
    "pink": .pink,
    "orange": .orange,
    "brown": .brown,
    "yellow": .yellow,
    "green": .green,
    "mint": .mint,
    "teal": .teal,
    "cyan": .cyan,
    "blue": .blue,
    "indigo": .indigo,
    "purple": .purple,
  ]

  init?(fromString string: String) {
    if let color = Self.colorMap[string] {
      self = color
    } else {
      return nil
    }
  }
}
