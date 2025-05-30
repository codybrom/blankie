import SwiftUI

struct SettingsView: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section(
          header: Text("Appearance", comment: "Settings section header for appearance options")
        ) {
          NavigationLink(destination: ThemePicker()) {
            HStack {
              Text("Theme", comment: "Appearance theme picker label")
              Spacer()
              Text(globalSettings.appearance.localizedName)
                .foregroundColor(.secondary)
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

        Section(
          header: Text("Playback", comment: "Settings section header for behavior options"),
        ) {
          Toggle(
            "Always Start Paused",
            isOn: Binding(
              get: { globalSettings.alwaysStartPaused },
              set: { globalSettings.setAlwaysStartPaused($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)

          #if os(iOS) || os(visionOS)
            VStack(alignment: .leading, spacing: 4) {
              Toggle(
                "Mix with Other Audio",
                isOn: Binding(
                  get: { globalSettings.mixWithOthers },
                  set: { globalSettings.setMixWithOthers($0) }
                )
              )
              .tint(globalSettings.customAccentColor ?? .accentColor)

              Text(
                "If enabled, Blankie can be used at the same time as other apps but playback cannot be controlled using your device's Now Playing widget or audio device controls.",
                comment: "Mix with others toggle caption"
              )
              .font(.caption)
              .foregroundColor(.secondary)
            }
          #endif
        }

        Section(
          header: Text("Sounds", comment: "Settings section header for sound management")
        ) {
          NavigationLink(destination: SoundManagementView()) {
            HStack {
              Text("Manage Sounds", comment: "Sound management label")
              Spacer()
              let hiddenCount = AudioManager.shared.sounds.filter { $0.isHidden }.count
              if hiddenCount > 0 {
                Text("\(hiddenCount) hidden")
                  .font(.caption)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(.secondary.opacity(0.3))
                  .foregroundColor(.secondary)
                  .clipShape(Capsule())
              }
            }
          }

          NavigationLink(destination: SoundCustomizationManagementView()) {
            HStack {
              Text("Sound Customizations", comment: "Sound customization management label")
              Spacer()
              let customizedCount = SoundCustomizationManager.shared.customizedSounds.count
              if customizedCount > 0 {
                Text("\(customizedCount) customized")
                  .font(.caption)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(.secondary.opacity(0.3))
                  .foregroundColor(.secondary)
                  .clipShape(Capsule())
              }
            }
          }
        }

        Section {
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

struct ThemePicker: View {
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      ForEach(AppearanceMode.allCases, id: \.self) { mode in
        Button(action: {
          globalSettings.setAppearance(mode)
          dismiss()
        }) {
          HStack {
            Text(mode.localizedName)
              .foregroundColor(.primary)
            Spacer()
            Image(systemName: mode.icon)
              .foregroundColor(.secondary)
              .padding(.trailing, 8)
            if globalSettings.appearance == mode {
              Image(systemName: "checkmark")
                .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
            }
          }
        }
      }
    }
    .navigationTitle("Theme")
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
