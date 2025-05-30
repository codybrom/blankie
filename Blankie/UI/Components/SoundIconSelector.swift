//
//  SoundIconSelector.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import SwiftUI

private struct IconData {
  static let iconCategories: [String: [String]] = loadIconCategories()

  private static func loadIconCategories() -> [String: [String]] {
    // Helper enum to decode JSON with nested categories
    enum IconCategory: Decodable {
      case simple([String])
      case nested([String: [String]])

      var allIcons: [String] {
        switch self {
        case .simple(let icons):
          return icons
        case .nested(let subcategories):
          return subcategories.values.flatMap { $0 }
        }
      }

      init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let icons = try? container.decode([String].self) {
          self = .simple(icons)
        } else if let subcategories = try? container.decode([String: [String]].self) {
          self = .nested(subcategories)
        } else {
          throw DecodingError.typeMismatch(
            IconCategory.self,
            DecodingError.Context(
              codingPath: decoder.codingPath,
              debugDescription: "Expected array or dictionary"
            )
          )
        }
      }
    }

    guard let url = Bundle.main.url(forResource: "icon-categories", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let categories = try? JSONDecoder().decode([String: IconCategory].self, from: data)
    else {
      return [:]
    }

    // Flatten nested categories
    var flatCategories: [String: [String]] = [:]
    for (key, value) in categories {
      flatCategories[key] = value.allIcons
    }
    return flatCategories
  }
}

struct SoundIconSelector: View {
  @Binding var selectedIcon: String
  @State private var iconSearchText = ""
  @State private var selectedIconCategory = "Popular"

  // Icon categories with curated selections
  private let iconCategories = IconData.iconCategories

  private var searchResults: [String] {
    if iconSearchText.isEmpty {
      return iconCategories[selectedIconCategory] ?? []
    }

    // Search across all categories
    let allIcons = iconCategories.values.flatMap { $0 }
    let uniqueIcons = Array(Set(allIcons))

    return uniqueIcons.filter { icon in
      icon.localizedCaseInsensitiveContains(iconSearchText)
    }.sorted()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Icon", comment: "Icon selection label")
          .font(.headline)
        Spacer()
        Text("Selected:", comment: "Selected icon label")
        Image(systemName: selectedIcon)
          .font(.title2)
          .foregroundStyle(.tint)
      }

      // Search and category picker
      HStack(spacing: 8) {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
          TextField(text: $iconSearchText) {
            Text("Search icons...", comment: "Icon search field placeholder")
          }
          .textFieldStyle(.plain)
        }
        .padding(6)
        .background(
          Group {
            #if os(macOS)
              Color(NSColor.controlBackgroundColor)
            #else
              Color(UIColor.systemBackground)
            #endif
          }
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))

        if iconSearchText.isEmpty {
          Picker(
            selection: $selectedIconCategory,
            label: Text("Category", comment: "Icon category picker label")
          ) {
            ForEach(Array(iconCategories.keys).sorted(), id: \.self) { category in
              Text(category).tag(category)
            }
          }
          .pickerStyle(.menu)
          .labelsHidden()
          .frame(width: 120)
        }
      }

      ScrollView {
        if searchResults.isEmpty && !iconSearchText.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "questionmark.square.dashed")
              .font(.largeTitle)
              .foregroundStyle(.tertiary)
            Text("No matching icons found", comment: "No icon search results message")
              .font(.headline)
            Text(
              "Try a different search term",
              comment: "No icon search results suggestion"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 40)
        } else {
          LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(50), spacing: 8), count: 6),
            spacing: 8
          ) {
            ForEach(searchResults, id: \.self) { iconName in
              Button {
                selectedIcon = iconName
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: iconName)
                    .font(.system(size: 24))
                    .frame(height: 30)
                  if !iconSearchText.isEmpty {
                    Text(iconName)
                      .font(.system(size: 8))
                      .lineLimit(1)
                      .truncationMode(.middle)
                  }
                }
                .frame(width: 50, height: iconSearchText.isEmpty ? 50 : 60)
                .background(
                  selectedIcon == iconName
                    ? Color.accentColor.opacity(0.2)
                    : Color.primary.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(
                      selectedIcon == iconName ? Color.accentColor : Color.clear,
                      lineWidth: 2
                    )
                )
              }
              .buttonStyle(.plain)
              .help(iconName)
            }
          }
          .padding(4)
        }
      }
      .frame(height: 200)
      .background(
        Group {
          #if os(macOS)
            Color(NSColor.textBackgroundColor)
          #else
            Color(UIColor.systemBackground)
          #endif
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }
}

// MARK: - Previews

#Preview {
  @Previewable @State var selectedIcon = "waveform.circle"

  SoundIconSelector(selectedIcon: $selectedIcon)
    .padding()
    .frame(width: 450)
}
