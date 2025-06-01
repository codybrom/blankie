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

    private var navigationTitleText: String {
      if let preset = presetManager.currentPreset {
        // Show "Blankie" instead of "Default" for the default preset
        if preset.isDefault {
          return "Blankie"
        }
        return preset.name
      }
      return "Blankie"
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
          .safeAreaInset(edge: .top, spacing: 0) {
            navigationHeader
          }
          .navigationTitle(navigationTitleText)
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
        ZStack {
          VStack(spacing: 0) {
            // Spacer for the header
            Color.clear
              .frame(height: headerHeight)

            mainSoundGridView
            playbackControlsView
          }

          // Custom navigation header overlay
          VStack(spacing: 0) {
            navigationHeader
            Spacer()
          }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
      }
    }

    // Navigation header with status indicators
    @ViewBuilder
    private var navigationHeader: some View {
      VStack(spacing: 0) {
        // Safe area extension
        if !isLargeDevice {
          Color.clear
            .frame(height: safeAreaTop)
        }
        // Title and controls
        HStack {
          if !isLargeDevice {
            Text(navigationTitleText)
              .font(.largeTitle)
              .fontWeight(.bold)
              .padding(.leading)
          }
          Spacer()

          if !isLargeDevice {
            HStack(spacing: 16) {
              TimerButton()
              menuButton
            }
            .padding(.trailing)
          }
        }
        .frame(height: isLargeDevice ? 0 : 44)
        // Status indicators
        statusIndicatorView
      }
      .background(
        isLargeDevice ? AnyShapeStyle(Color.clear) : AnyShapeStyle(Material.ultraThinMaterial)
      )
    }
    // Safe area insets helper
    private var safeAreaTop: CGFloat {
      #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
        {
          return window.safeAreaInsets.top
        }
      #endif
      return 0
    }
    // Header height for spacing
    private var headerHeight: CGFloat {
      var height: CGFloat = 44  // Title bar height
      if audioManager.soloModeSound != nil {
        height += 32  // Solo mode indicator height
      } else if !audioManager.isGloballyPlaying {
        height += 32  // Paused indicator height
      }
      return height + safeAreaTop
    }
    // Combined status indicator view
    @ViewBuilder
    private var statusIndicatorView: some View {
      VStack(spacing: 0) {
        if let soloSound = audioManager.soloModeSound {
          soloModeIndicator(for: soloSound)
            .transition(
              .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
              )
            )
        } else if !audioManager.isGloballyPlaying {
          pausedIndicator
            .transition(
              .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
              )
            )
        }
      }
      .animation(.easeInOut(duration: 0.2), value: audioManager.soloModeSound?.id)
      .animation(.easeInOut(duration: 0.2), value: audioManager.isGloballyPlaying)
    }

    // Paused indicator banner
    private var pausedIndicator: some View {
      HStack(spacing: 8) {
        Image(systemName: "pause.circle.fill")
          .font(.system(size: 16))
        Text("Playback Paused")
          .font(.system(.subheadline, design: .rounded, weight: .medium))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .foregroundStyle(.secondary)
    }

    // Solo mode indicator banner
    private func soloModeIndicator(for sound: Sound) -> some View {
      let accentColor = GlobalSettings.shared.customAccentColor ?? Color.accentColor

      return HStack(spacing: 8) {
        Image(systemName: "headphones.circle.fill")
          .font(.system(size: 16))
        Text("Solo Mode")
          .font(.system(.subheadline, design: .rounded, weight: .medium))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .foregroundStyle(accentColor)
      .overlay(alignment: .trailing) {
        // Exit button positioned on the right
        Button(action: {
          audioManager.exitSoloMode()
        }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(accentColor)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
      }
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
      Group {
        if let soloSound = audioManager.soloModeSound {
          // Solo mode: Show only the solo sound centered
          VStack {
            Spacer()
            DraggableSoundIcon(
              sound: soloSound,
              maxWidth: 200,
              index: 0,
              draggedIndex: .constant(nil),
              hoveredIndex: .constant(nil),
              onDragStart: {},
              onDrop: { _ in }
            )
            .scaleEffect(1.2)
            .transition(
              .asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
              ))
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        } else {
          // Normal mode: Show all sounds in grid
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
          .transition(
            .asymmetric(
              insertion: .opacity,
              removal: .opacity
            ))
        }
      }
      .animation(.easeInOut(duration: 0.3), value: audioManager.soloModeSound?.id)
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
        .onTapGesture {
          sound.toggle()
        }
        .contextMenu {
          Button(action: {
            // Haptic feedback for solo mode
            if GlobalSettings.shared.enableHaptics {
              #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
              #endif
            }

            withAnimation(.easeInOut(duration: 0.3)) {
              AudioManager.shared.toggleSoloMode(for: sound)
            }
          }) {
            Label("Solo Mode", systemImage: "headphones")
          }
        }
        .onLongPressGesture(
          minimumDuration: 0.0, maximumDistance: .infinity,
          pressing: { pressing in
            if pressing && GlobalSettings.shared.enableHaptics {
              // Haptic feedback when context menu is about to appear
              #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
              #endif
            }
          }, perform: {}
        )
        .onDrag {
          // Haptic feedback for drag start
          if GlobalSettings.shared.enableHaptics {
            #if os(iOS)
              let generator = UIImpactFeedbackGenerator(style: .light)
              generator.impactOccurred()
            #endif
          }

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
        .tint(sliderTintColor)
        .disabled(!isSliderEnabled)
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
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if isSoloMode {
        return accentColor  // Solo mode color
      }

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }
      return sound.isSelected ? accentColor : .gray
    }

    private var backgroundFill: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if isSoloMode {
        return accentColor.opacity(0.3)  // Solo mode background
      }

      if !AudioManager.shared.isGloballyPlaying {
        return sound.isSelected ? Color.gray.opacity(0.2) : .clear
      }
      return sound.isSelected ? accentColor.opacity(0.2) : .clear
    }

    private var isSliderEnabled: Bool {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      return isSoloMode || sound.isSelected
    }

    private var sliderTintColor: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }

      if isSoloMode {
        return accentColor
      }

      return sound.isSelected ? accentColor : .gray
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
        draggedIndex != index
      else {
        return .zero
      }

      // If we're hovering over this item, no offset needed
      if hoveredIndex == index {
        return .zero
      }

      // Calculate if we need to dodge
      let isDraggedBeforeHovered = draggedIndex < hoveredIndex
      let isIndexBetween =
        isDraggedBeforeHovered
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
