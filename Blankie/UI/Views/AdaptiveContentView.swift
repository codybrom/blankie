import SwiftUI

struct AdaptiveContentView: View {
  @Binding var showingAbout: Bool
  @Binding var showingSettings: Bool

  @ObservedObject private var audioManager = AudioManager.shared
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @ObservedObject private var presetManager = PresetManager.shared

  @State private var showingVolumeControls = false
  @State private var showingPresetPicker = false
  @State private var hideInactiveSounds = false
  @State private var columnVisibility: NavigationSplitViewVisibility = .automatic  // Correct type

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  // Calculate filtered sounds based on hideInactiveSounds preference
  private var filteredSounds: [Sound] {
    // Simplified expression that's easier for the compiler to type-check
    let sounds = audioManager.sounds
    return sounds.filter { sound in
      if hideInactiveSounds {
        return sound.isSelected
      } else {
        return true
      }
    }
  }

  // Determine if we're on iPad or Mac
  private var isLargeDevice: Bool {
    horizontalSizeClass == .regular
  }

  // Computed properties for columns and columnWidth
  private var columns: [GridItem] {
    if isLargeDevice {
      return [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)]
    } else {
      return Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    }
  }

  private var columnWidth: CGFloat {
    if isLargeDevice {
      return 150
    } else {
      #if os(iOS)
      return (UIScreen.main.bounds.width - 40) / 3  // 40 for padding/spacing
      #else
      return 100 // Fallback for other platforms
      #endif
    }
  }

  var body: some View {
    Group {
      if isLargeDevice {
        largeDeviceLayout
      } else {
        smallDeviceLayout
      }
    }
    .sheet(isPresented: $showingVolumeControls) {
      VolumeControlsView()
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
              Label("Volume", systemImage: "speaker.wave.2")
            }
          }
        }
    }
    .navigationSplitViewStyle(.balanced)
  }

  // Sidebar content for split view
  private var sidebarContent: some View {
    List {
      Section("Presets") {
        ForEach(presetManager.presets) { preset in
          presetRow(preset)
        }

        Button(action: {
          showingPresetPicker = true
        }) {
          Label("Add Preset", systemImage: "plus")
        }
      }

      Section("Settings") {
        settingsButtons
      }
    }
    .navigationTitle("Blankie")
  }

  // Settings buttons in sidebar
  private var settingsButtons: some View {
    Group {
      Button(action: {
        showingSettings = true
      }) {
        Label("Preferences", systemImage: "gear")
      }

      Button(action: {
        showingAbout = true
      }) {
        Label("About", systemImage: "info.circle")
      }

      Button(action: {
        withAnimation {
          hideInactiveSounds.toggle()
        }
      }) {
        let iconName = hideInactiveSounds ? "eye" : "eye.slash"
        let labelText = hideInactiveSounds ? "Show All Sounds" : "Hide Inactive Sounds"
        Label(labelText, systemImage: iconName)
      }
    }
  }

  // Single preset row
  private func presetRow(_ preset: Preset) -> some View {
    Button(action: {
      Task {
        do {
          try presetManager.applyPreset(preset)
        } catch {
          print("Error applying preset: \(error)")
        }
      }
    }) {
      HStack {
        Text(preset.name)
          .foregroundColor(.primary)

        Spacer()

        if presetManager.currentPreset?.id == preset.id {
          Image(systemName: "checkmark")
            .foregroundColor(.accentColor)
        }
      }
    }
    .contextMenu {
      if !preset.isDefault {
        Button(role: .destructive) {
          presetManager.deletePreset(preset)
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
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
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          menuButton
        }
      }
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
        Label("Settings", systemImage: "gear")
      }

      Button(action: {
        showingAbout = true
      }) {
        Label("About", systemImage: "info.circle")
      }
    } label: {
      Image(systemName: "ellipsis.circle")
    }
  }

  // Main sound grid that's shared between layouts
  private var mainSoundGridView: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(filteredSounds) { sound in
          SoundIcon(sound: sound, maxWidth: columnWidth)
        }
      }
      .padding()
      .animation(.easeInOut, value: filteredSounds.count)
    }
  }

  // Bottom playback controls for iPhone layout
  private var playbackControlsView: some View {
    VStack(spacing: 0) {
      Divider()

      HStack(spacing: 20) {
        // Volume button
        volumeButton

        // Play/Pause button
        playPauseButton

        // Options button
        hideShowButton
      }
      .padding(.vertical, 8)
      .background(.ultraThinMaterial)
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
            globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2)
          )
          .frame(width: 60, height: 60)

        let imageName = audioManager.isGloballyPlaying ? "pause.fill" : "play.fill"
        let xOffset: CGFloat = audioManager.isGloballyPlaying ? 0 : 2

        Image(systemName: imageName)
          .font(.system(size: 26))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          .offset(x: xOffset)
      }
    }
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
