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

          Toggle(
            "Show Labels",
            isOn: Binding(
              get: { globalSettings.showSoundNames },
              set: { globalSettings.setShowSoundNames($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)

          Toggle(
            "Show Progress Border",
            isOn: Binding(
              get: { globalSettings.showProgressBorder },
              set: { globalSettings.setShowProgressBorder($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)

          Picker(
            "Icon Size",
            selection: Binding(
              get: { globalSettings.iconSize },
              set: { globalSettings.setIconSize($0) }
            )
          ) {
            ForEach(IconSize.allCases, id: \.self) { size in
              Text(size.label).tag(size)
            }
          }
        }

        Section(
          header: Text("Playback", comment: "Settings section header for behavior options"),
        ) {
          Toggle(
            "Autoplay When Opened",
            isOn: Binding(
              get: { globalSettings.autoPlayOnLaunch },
              set: { globalSettings.setAutoPlayOnLaunch($0) }
            )
          )
          .tint(globalSettings.customAccentColor ?? .accentColor)

          #if os(iOS) || os(visionOS)
            VStack(alignment: .leading, spacing: 8) {
              Toggle(
                "Mix with Other Audio",
                isOn: Binding(
                  get: { globalSettings.mixWithOthers },
                  set: { globalSettings.setMixWithOthers($0) }
                )
              )
              .tint(globalSettings.customAccentColor ?? .accentColor)

              if globalSettings.mixWithOthers {
                VStack(alignment: .leading, spacing: 8) {
                  HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .foregroundColor(.orange)
                      .font(.caption)
                    Text("Device media controls won't pause Blankie")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  .padding(.vertical, 4)
                  .padding(.horizontal, 8)
                  .background(.orange.opacity(0.1))
                  .cornerRadius(6)

                  VStack(alignment: .leading, spacing: 8) {
                    HStack {
                      Text("Blankie Volume with Media")
                        .font(.subheadline)
                      Spacer()
                      Text("\(Int(globalSettings.volumeWithOtherAudio * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Slider(
                      value: Binding(
                        get: { globalSettings.volumeWithOtherAudio },
                        set: { globalSettings.setVolumeWithOtherAudio($0) }
                      ),
                      in: 0.0...1.0
                    )
                    .tint(globalSettings.customAccentColor ?? .accentColor)

                    Text("Other media plays at system volume")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
              } else {
                Text("Blankie pauses other audio and responds to device media controls")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
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
