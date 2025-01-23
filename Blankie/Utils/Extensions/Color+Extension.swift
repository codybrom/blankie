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
    case .system: return "System"
    case .red: return "Red"
    case .pink: return "Pink"
    case .orange: return "Orange"
    case .brown: return "Brown"
    case .yellow: return "Yellow"
    case .green: return "Green"
    case .mint: return "Mint"
    case .teal: return "Teal"
    case .cyan: return "Cyan"
    case .blue: return "Blue"
    case .indigo: return "Indigo"
    case .purple: return "Purple"
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
  case system = "System"
  case light = "Light"
  case dark = "Dark"

  var icon: String {
    switch self {
    case .system: return "circle.lefthalf.filled"
    case .light: return "sun.max.fill"
    case .dark: return "moon.fill"
    }
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
