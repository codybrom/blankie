import SwiftUI

struct SettingsView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Appearance")) {
          Picker(
            "Theme",
            selection: Binding(
              get: { globalSettings.appearance },
              set: { globalSettings.setAppearance($0) }
            )
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
              Text("Accent Color")
              Spacer()
              Circle()
                .fill(globalSettings.customAccentColor ?? .accentColor)
                .frame(width: 20, height: 20)
            }
          }
        }

        Section(header: Text("Behavior")) {
          Toggle(
            "Always Start Paused",
            isOn: Binding(
              get: { globalSettings.alwaysStartPaused },
              set: { globalSettings.setAlwaysStartPaused($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)
        }

        Section(header: Text("About")) {
          NavigationLink(destination: AboutView()) {
            Text("About Blankie")
          }

          Link(destination: URL(string: "https://blankie.rest/faq")!) {
            HStack {
              Text("Help & FAQ")
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
          Button("Done") {
            dismiss()
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
          // System color option
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

                Text("S")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.primary)
              }

              Text("System")
                .font(.caption)
            }
          }
          .buttonStyle(.plain)

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
