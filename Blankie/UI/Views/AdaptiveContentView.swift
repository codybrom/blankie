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
            DraggableSoundIcon(
              sound: sound,
              maxWidth: columnWidth,
              index: index,
              draggedIndex: $draggedIndex,
              hoveredIndex: $hoveredIndex,
              onDragStart: {
                draggedIndex = index
                startDragResetTimer()
              },
              onDrop: { sourceIndex in
                audioManager.moveVisibleSound(from: sourceIndex, to: index)
                cancelDragResetTimer()
              }
            )
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

  // Custom draggable sound icon that only applies drag gesture to the icon area
  struct DraggableSoundIcon: View {
    @ObservedObject var sound: Sound
    let maxWidth: CGFloat
    let index: Int
    @Binding var draggedIndex: Int?
    @Binding var hoveredIndex: Int?
    let onDragStart: () -> Void
    let onDrop: (Int) -> Void
    
    @ObservedObject private var globalSettings = GlobalSettings.shared
    @State private var isDraggingIcon = false
    
    private var filteredSounds: [Sound] {
      AudioManager.shared.getVisibleSounds()
    }
    
    var body: some View {
      VStack(spacing: 8) {
        // Icon area with drag gesture
        ZStack {
          Circle()
            .fill(backgroundFill)
            .frame(width: 100, height: 100)
          
          Image(systemName: sound.systemIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 64, height: 64)
            .foregroundColor(iconColor)
        }
        .frame(width: 100, height: 100)
        .contentShape(Circle())
        .scaleEffect(draggedIndex == index ? 0.85 : 1.0)
        .opacity(draggedIndex == index ? 0.5 : 1.0)
        .overlay(dropOverlay)
        .gesture(
          TapGesture()
            .onEnded { _ in
              sound.toggle()
            }
        )
        .onLongPressGesture(minimumDuration: 0.5) {
          onDragStart()
        }
        .onDrag {
          onDragStart()
          return NSItemProvider(object: "\(index)" as NSString)
        }
        
        // Title (not draggable)
        Text(LocalizedStringKey(sound.title))
          .font(
            Locale.current.identifier.hasPrefix("zh") ? .system(size: 16, weight: .thin) : .callout
          )
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .frame(maxWidth: maxWidth - 20)
          .foregroundColor(.primary)
        
        // Slider (not draggable)
        Slider(
          value: Binding(
            get: { Double(sound.volume) },
            set: { sound.volume = Float($0) }
          ), in: 0...1
        )
        .frame(width: 85)
        .tint(AudioManager.shared.isGloballyPlaying ? (sound.isSelected ? accentColor : .gray) : .gray)
        .disabled(!sound.isSelected)
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 10)
      .frame(width: maxWidth)
      .offset(calculateDodgeOffset(for: index))
      .zIndex(draggedIndex == index ? 1 : 0)
      .animation(.easeInOut(duration: 0.3), value: draggedIndex)
      .animation(.easeInOut(duration: 0.3), value: hoveredIndex)
      .onDrop(
        of: [.text],
        delegate: SoundDropDelegate(
          audioManager: AudioManager.shared,
          targetIndex: index,
          sounds: filteredSounds,
          draggedIndex: $draggedIndex,
          hoveredIndex: $hoveredIndex,
          cancelTimer: { draggedIndex = nil }
        )
      )
    }
    
    private var accentColor: Color {
      globalSettings.customAccentColor ?? .accentColor
    }
    
    private var iconColor: Color {
      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }
      return sound.isSelected ? accentColor : .gray
    }
    
    private var backgroundFill: Color {
      if !AudioManager.shared.isGloballyPlaying {
        return sound.isSelected ? Color.gray.opacity(0.2) : .clear
      }
      return sound.isSelected ? accentColor.opacity(0.2) : .clear
    }
    
    @ViewBuilder
    private var dropOverlay: some View {
      if hoveredIndex == index && draggedIndex != index {
        RoundedRectangle(cornerRadius: 50)
          .stroke(accentColor, lineWidth: 3)
          .background(
            RoundedRectangle(cornerRadius: 50)
              .fill(accentColor.opacity(0.2))
          )
          .overlay(
            VStack(spacing: 4) {
              Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(accentColor)
              Text("Drop here")
                .font(.caption)
                .foregroundColor(accentColor)
            }
          )
          .allowsHitTesting(false)
      }
    }
    
    private func calculateDodgeOffset(for index: Int) -> CGSize {
      guard let draggedIndex = draggedIndex,
            let hoveredIndex = hoveredIndex,
            draggedIndex != index else {
        return .zero
      }
      
      // If we're hovering over this item, no offset needed
      if hoveredIndex == index {
        return .zero
      }
      
      // Calculate if we need to dodge
      let isDraggedBeforeHovered = draggedIndex < hoveredIndex
      let isIndexBetween = isDraggedBeforeHovered
        ? (index > draggedIndex && index <= hoveredIndex)
        : (index < draggedIndex && index >= hoveredIndex)
      
      if isIndexBetween {
        // Dodge in the opposite direction of the drag
        return CGSize(width: isDraggedBeforeHovered ? -120 : 120, height: 0)
      }
      
      return .zero
    }
  }
#endif
