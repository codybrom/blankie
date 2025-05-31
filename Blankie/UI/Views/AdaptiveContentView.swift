import SwiftUI

#if os(iOS) || os(visionOS)
  struct AdaptiveContentView: View {
    @Binding var showingAbout: Bool
    @Binding var showingSettings: Bool

    @StateObject var audioManager = AudioManager.shared
    @StateObject private var globalSettings = GlobalSettings.shared
    @StateObject private var presetManager = PresetManager.shared

    @State private var showingVolumeControls = false
    @State private var showingPresetPicker = false
    @State var hideInactiveSounds = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var draggedIndex: Int?
    @State var hoveredIndex: Int?
    @State var dragResetTimer: Timer?
    @State private var showingAboutInMenu = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
      Group {
        if isLargeDevice {
          largeDeviceLayout
        } else {
          smallDeviceLayout
        }
      }
      .sheet(isPresented: $showingVolumeControls) {
        VolumeControlsView(style: .sheet)
          .presentationDetents([.medium, .large])
      }
      .sheet(isPresented: $showingSettings) {
        SettingsView()
      }
      .sheet(isPresented: $showingAbout) {
        AboutView()
      }
      .sheet(isPresented: $showingPresetPicker) {
        PresetPickerView()
          .presentationDetents([.medium, .large])
      }
      .modifier(AudioErrorHandler())
    }

    // Split view layout for iPad/Mac
    private var largeDeviceLayout: some View {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        sidebarContent
      } detail: {
        mainSoundGridView
          .navigationTitle(presetManager.currentPreset?.name ?? "Sounds")
          .toolbar {
            ToolbarItem(placement: .primaryAction) {
              Button(action: {
                showingVolumeControls = true
              }) {
                Label("All Sounds", systemImage: "speaker.wave.2")
              }
            }
            ToolbarItem(placement: .primaryAction) {
              TimerButton()
            }
          }
      }
      .navigationSplitViewStyle(.balanced)
    }

    // Sidebar content for split view
    private var sidebarContent: some View {
      SidebarContentView(
        showingPresetPicker: $showingPresetPicker,
        showingSettings: $showingSettings,
        showingAbout: $showingAbout,
        hideInactiveSounds: $hideInactiveSounds
      )
    }

    // iPhone layout
    private var smallDeviceLayout: some View {
      NavigationView {
        VStack(spacing: 0) {
          // Playback paused indicator
          if !audioManager.isGloballyPlaying {
            pausedIndicator
          }

          mainSoundGridView
          playbackControlsView
        }
        .navigationTitle("Blankie")
      }
    }

    // Paused indicator banner
    private var pausedIndicator: some View {
      HStack {
        Image(systemName: "pause.circle.fill")
        Text("Playback Paused")
          .font(.system(.subheadline, design: .rounded))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
      .background(.ultraThinMaterial)
      .foregroundStyle(.secondary)
    }

    // Menu button for small devices
    private var menuButton: some View {
      Menu {
        Button(action: {
          showingPresetPicker = true
        }) {
          Label("Presets", systemImage: "music.note.list")
        }

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
          showingSettings = true
        }) {
          Label {
            Text("Settings", comment: "Settings menu item")
          } icon: {
            Image(systemName: "gear")
          }
        }

        Button(action: {
          showingAbout = true
        }) {
          Label {
            Text("About Blankie", comment: "About menu item")
          } icon: {
            Image(systemName: "info.circle")
          }
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      }
    }

    // Main sound grid that's shared between layouts
    private var mainSoundGridView: some View {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 20) {
          ForEach(Array(filteredSounds.enumerated()), id: \.element.id) { index, sound in
            SoundIcon(sound: sound, maxWidth: columnWidth)
              .scaleEffect(draggedIndex == index ? 0.85 : 1.0)
              .opacity(draggedIndex == index ? 0.5 : 1.0)
              .offset(calculateDodgeOffset(for: index))
              .zIndex(draggedIndex == index ? 1 : 0)
              .animation(.easeInOut(duration: 0.3), value: draggedIndex)
              .animation(.easeInOut(duration: 0.3), value: hoveredIndex)
              .overlay(
                hoveredIndex == index && draggedIndex != index
                  ? RoundedRectangle(cornerRadius: 16)
                    .stroke(globalSettings.customAccentColor ?? .accentColor, lineWidth: 3)
                    .background(
                      RoundedRectangle(cornerRadius: 16)
                        .fill((globalSettings.customAccentColor ?? .accentColor).opacity(0.2))
                    )
                    .overlay(
                      VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                          .font(.system(size: 24))
                          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                        Text("Drop here")
                          .font(.caption)
                          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                      }
                    )
                    .allowsHitTesting(false)
                  : nil
              )
              .onLongPressGesture(minimumDuration: 0.5) {
                // Long press to start drag mode
                draggedIndex = index
                startDragResetTimer()
              }
              .onDrag {
                draggedIndex = index
                startDragResetTimer()
                return NSItemProvider(object: "\(index)" as NSString)
              }
              .onDrop(
                of: [.text],
                delegate: SoundDropDelegate(
                  audioManager: audioManager,
                  targetIndex: index,
                  sounds: filteredSounds,
                  draggedIndex: $draggedIndex,
                  hoveredIndex: $hoveredIndex,
                  cancelTimer: cancelDragResetTimer
                ))
          }
        }
        .padding()
        .animation(.easeInOut, value: filteredSounds.count)
      }
    }

    // Bottom playback controls for iPhone layout
    private var playbackControlsView: some View {
      PlaybackControlsView(
        showingVolumeControls: $showingVolumeControls,
        hideInactiveSounds: $hideInactiveSounds,
        showingPresetPicker: $showingPresetPicker,
        showingSettings: $showingSettings,
        showingAbout: $showingAbout
      )
    }
  }

  struct AdaptiveContentView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        // iPhone Preview
        AdaptiveContentView(
          showingAbout: .constant(false),
          showingSettings: .constant(false)
        )
        .previewDevice("iPhone 14")
        .previewDisplayName("iPhone")

        // iPad Preview
        AdaptiveContentView(
          showingAbout: .constant(false),
          showingSettings: .constant(false)
        )
        .previewDevice("iPad Pro (11-inch)")
        .previewDisplayName("iPad")
      }
    }
  }
#endif
