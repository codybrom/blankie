import SwiftUI

#if os(iOS) || os(visionOS)
  struct PlaybackControlsView: View {
    @Binding var showingVolumeControls: Bool
    @Binding var hideInactiveSounds: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAbout: Bool

    @State private var showingThemePicker = false
    @State private var showingSoundManagement = false

    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var globalSettings = GlobalSettings.shared

    var body: some View {
      VStack(spacing: 0) {
        // Subtle separator
        Rectangle()
          .frame(height: 0.5)
          .foregroundColor(Color.primary.opacity(0.1))

        HStack(spacing: 0) {
          // Volume button or Exit Solo Mode button
          Spacer()
          if audioManager.soloModeSound != nil {
            exitSoloModeButton
              .onAppear {
                print("🎨 UI: Exit solo mode button appeared")
              }
          } else {
            volumeButton
              .onAppear {
                print("🎨 UI: Volume button appeared")
              }
          }
          Spacer()

          // Play/Pause button
          Spacer()
          playPauseButton
          Spacer()

          // Menu button
          Spacer()
          menuButton
          Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.thickMaterial)
      }
    }

    // Volume control button
    private var volumeButton: some View {
      Button(action: {
        showingVolumeControls.toggle()
      }) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 22))
          .foregroundColor(.primary)
          .padding()
      }
    }

    // Play/pause button
    private var playPauseButton: some View {
      Button(action: {
        audioManager.togglePlayback()
      }) {
        ZStack {
          Circle()
            .fill(
              audioManager.hasSelectedSounds 
                ? (globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                : Color.secondary.opacity(0.1)
            )
            .frame(width: 60, height: 60)

          let imageName = audioManager.isGloballyPlaying ? "pause.fill" : "play.fill"
          let xOffset: CGFloat = audioManager.isGloballyPlaying ? 0 : 2

          Image(systemName: imageName)
            .font(.system(size: 26))
            .foregroundColor(
              audioManager.hasSelectedSounds 
                ? (globalSettings.customAccentColor ?? .accentColor)
                : Color.secondary
            )
            .offset(x: xOffset)
        }
      }
      .disabled(!audioManager.hasSelectedSounds)
    }

    // Exit solo mode button
    private var exitSoloModeButton: some View {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          audioManager.exitSoloMode()
        }
      }) {
        Image(systemName: "headphones.slash")
          .font(.system(size: 22))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
      }
      .buttonStyle(.plain)
    }

    // Hide/show inactive sounds button
    private var hideShowButton: some View {
      Button(action: {
        withAnimation {
          hideInactiveSounds.toggle()
        }
      }) {
        let iconName = hideInactiveSounds ? "eye.slash.fill" : "eye.fill"

        Image(systemName: iconName)
          .font(.system(size: 22))
          .foregroundColor(.primary)
          .padding()
      }
    }

    // Menu button with all options
    private var menuButton: some View {
      Menu {
        Button(action: {
          withAnimation {
            hideInactiveSounds.toggle()
          }
        }) {
          let labelText = hideInactiveSounds ? "Show All Sounds" : "Hide Inactive Sounds"
          let iconName = hideInactiveSounds ? "eye" : "eye.slash"
          Label(labelText, systemImage: iconName)
        }

        Button(action: {
          showingSoundManagement = true
        }) {
          Label("Manage Sounds", systemImage: "waveform")
        }

        Button(action: {
          showingThemePicker = true
        }) {
          Label("Theme", systemImage: "paintbrush")
        }

        Button(action: {
          showingSettings = true
        }) {
          Label {
            Text("Settings", comment: "Settings menu item")
          } icon: {
            Image(systemName: "gear")
          }
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 22))
          .foregroundColor(.primary)
          .padding()
      }
      .sheet(isPresented: $showingThemePicker) {
        NavigationView {
          VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
              Text("Appearance")
                .font(.headline)

              HStack {
                Spacer()
                HStack(spacing: 8) {
                  ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button(action: {
                      globalSettings.setAppearance(mode)
                    }) {
                      HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                        Text(mode.localizedName)
                      }
                      .padding(.horizontal, 12)
                      .padding(.vertical, 8)
                      .background(
                        globalSettings.appearance == mode
                          ? (globalSettings.customAccentColor ?? .accentColor)
                          : Color.secondary.opacity(0.2)
                      )
                      .foregroundColor(
                        globalSettings.appearance == mode ? .white : .primary
                      )
                      .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                  }
                }
                Spacer()
              }
            }

            VStack(alignment: .leading, spacing: 12) {
              Text("Accent Color")
                .font(.headline)

              let availableColors = Array(AccentColor.allCases.dropFirst())
              let colorsPerRow = 6

              VStack(alignment: .center, spacing: 12) {
                ForEach(0..<2, id: \.self) { row in
                  HStack(spacing: 12) {
                    Spacer()
                    ForEach(0..<colorsPerRow, id: \.self) { col in
                      let index = row * colorsPerRow + col
                      if index < availableColors.count {
                        let color = availableColors[index]
                        Button(action: {
                          globalSettings.setAccentColor(color.color)
                        }) {
                          Circle()
                            .fill(color.color ?? .accentColor)
                            .frame(width: 44, height: 44)
                            .overlay(
                              Circle()
                                .stroke(
                                  globalSettings.customAccentColor == color.color ? .white : .clear,
                                  lineWidth: 3
                                )
                            )
                            .overlay(
                              globalSettings.customAccentColor == color.color
                                ? Image(systemName: "checkmark")
                                  .foregroundColor(.white)
                                  .font(.system(size: 16, weight: .bold))
                                : nil
                            )
                        }
                        .buttonStyle(.plain)
                      }
                    }
                    Spacer()
                  }
                }
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.vertical, 16)
          .navigationTitle("Theme")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              let needsReset =
                globalSettings.appearance != .system || globalSettings.customAccentColor != nil
              if needsReset {
                Button("Reset") {
                  globalSettings.setAppearance(.system)
                  globalSettings.setAccentColor(nil)
                }
              }
            }

            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                showingThemePicker = false
              }
            }
          }
        }
        .presentationDetents([.fraction(0.45)])
      }
      .sheet(isPresented: $showingSoundManagement) {
        SoundManagementView()
      }
    }
  }
#endif
