import SwiftUI

struct SettingsView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section(
          header: Text("Appearance", comment: "Settings section header for appearance options")
        ) {
          Picker(
            selection: Binding(
              get: { globalSettings.appearance },
              set: { globalSettings.setAppearance($0) }
            ),
            label: Text("Theme", comment: "Appearance theme picker label")
          ) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
              Label(
                mode.rawValue,
                systemImage: mode.icon
              ).tag(mode)
            }
          }

          NavigationLink(destination: AccentColorPicker()) {
            HStack {
              Text("Accent Color", comment: "Accent color picker label")
              Spacer()
              Circle()
                .fill(globalSettings.customAccentColor ?? .accentColor)
                .frame(width: 20, height: 20)
            }
          }
        }

        Section(header: Text("Behavior", comment: "Settings section header for behavior options")) {
          Toggle(
            "Always Start Paused",
            isOn: Binding(
              get: { globalSettings.alwaysStartPaused },
              set: { globalSettings.setAlwaysStartPaused($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)
        }

        Section(
          header: Text("About Blankie", comment: "Settings section header for about information")
        ) {
          NavigationLink(destination: AboutView()) {
            Text("About Blankie", comment: "About view navigation label")
          }

          Link(destination: URL(string: "https://blankie.rest/faq")!) {
            HStack {
              Text("Blankie Help", comment: "Help and FAQ link label")
              Spacer()
              Image(systemName: "safari")
                .foregroundColor(.secondary)
            }
          }
        }
      }
      .navigationTitle("Settings")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            dismiss()
          } label: {
            Text("Done", comment: "Settings done button")
          }
        }
      }
    }
  }
}

struct AccentColorPicker: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared

  private let columns = [
    GridItem(.adaptive(minimum: 44))
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LazyVGrid(columns: columns, spacing: 16) {
          #if os(macOS)
            // System color option - only available on macOS
            Button(action: {
              globalSettings.setAccentColor(nil)
            }) {
              VStack {
                ZStack {
                  Circle()
                    .strokeBorder(Color.primary, lineWidth: 1)
                    .frame(width: 44, height: 44)

                  if globalSettings.customAccentColor == nil {
                    Image(systemName: "checkmark")
                      .foregroundColor(.primary)
                  }
                }

                Text("System", comment: "System accent color option")
                  .font(.caption)
              }
            }
            .buttonStyle(.plain)
          #endif

          // Color options
          ForEach(AccentColor.allCases.dropFirst(), id: \.self) { colorOption in
            Button(action: {
              globalSettings.setAccentColor(colorOption.color)
            }) {
              VStack {
                ZStack {
                  Circle()
                    .fill(colorOption.color ?? .accentColor)
                    .frame(width: 44, height: 44)

                  if globalSettings.customAccentColor == colorOption.color {
                    Image(systemName: "checkmark")
                      .foregroundColor(.white)
                  }
                }

                Text(colorOption.name)
                  .font(.caption)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
      }
    }
    .navigationTitle("Accent Color")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
