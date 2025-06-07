//
//  SoundSheetColorPicker.swift
//  Blankie
//
//  Created by Cody Bromley on 6/6/25.
//

import SwiftUI

struct ColorPickerRow: View {
  @Binding var selectedColor: AccentColor?
  @State private var showingColorPicker = false
  @ObservedObject private var globalSettings = GlobalSettings.shared

  var body: some View {
    Button(action: {
      showingColorPicker = true
    }) {
      HStack {
        Text("Icon Color", comment: "Icon color field label")
        Spacer()

        HStack(spacing: 4) {
          Circle()
            .fill(selectedColor?.color ?? (globalSettings.customAccentColor ?? .accentColor))
            .frame(width: 20, height: 20)

          Text(selectedColor?.name ?? "Default")
            .foregroundColor(.secondary)

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .buttonStyle(.plain)
    .sheet(isPresented: $showingColorPicker) {
      ColorPickerPage(selectedColor: $selectedColor)
    }
  }
}

struct ColorPickerPage: View {
  @Binding var selectedColor: AccentColor?
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var globalSettings = GlobalSettings.shared

  private let columns = [
    GridItem(.adaptive(minimum: 60))
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          // Default option
          VStack(alignment: .leading, spacing: 12) {
            Text("Default", comment: "Default color section header")
              .font(.headline)
              .padding(.horizontal)

            Button(action: {
              selectedColor = nil
              dismiss()
            }) {
              HStack {
                Circle()
                  .fill(globalSettings.customAccentColor ?? .accentColor)
                  .frame(width: 44, height: 44)
                  .overlay(
                    selectedColor == nil
                      ? Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                      : nil
                  )

                Text("Use App Accent Color", comment: "Use default accent color option")
                  .foregroundColor(.primary)

                Spacer()
              }
              .padding(.horizontal)
              .padding(.vertical, 8)
              .background(Color.secondary.opacity(0.1))
              .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
          }

          // Color options
          VStack(alignment: .leading, spacing: 12) {
            Text("Colors", comment: "Color options section header")
              .font(.headline)
              .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
              ForEach(AccentColor.allCases.dropFirst(), id: \.self) { colorOption in
                Button(action: {
                  selectedColor = colorOption
                  dismiss()
                }) {
                  VStack(spacing: 8) {
                    Circle()
                      .fill(colorOption.color ?? .accentColor)
                      .frame(width: 44, height: 44)
                      .overlay(
                        selectedColor == colorOption
                          ? Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                          : nil
                      )

                    Text(colorOption.name)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          }
        }
        .padding(.vertical)
      }
      .navigationTitle("Icon Color")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}
