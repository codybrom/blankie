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
    @State private var showingThemePicker = false
    @State private var showingSoundManagement = false
    @State private var soundToEdit: Sound?
    @State var soundsUpdateTrigger = 0

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Check if any sounds are selected (use AudioManager's published property)
    private var hasSelectedSounds: Bool {
      audioManager.hasSelectedSounds
    }

    private var navigationTitleText: String {
      // In solo mode, show the sound name
      if let soloSound = audioManager.soloModeSound {
        return soloSound.title
      }

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
      .sheet(item: $soundToEdit) { sound in
        SoundSheet(mode: .customize(sound))
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
          mainSoundGridView
            .safeAreaInset(edge: .top, spacing: 0) {
              Color.clear.frame(height: headerHeight)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
              VStack(spacing: 0) {
                statusIndicatorView

                HStack(spacing: 0) {
                  // Volume button or Exit Solo Mode button
                  Spacer()
                  if audioManager.soloModeSound != nil {
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
                  } else {
                    Button(action: {
                      showingVolumeControls.toggle()
                    }) {
                      Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                  }
                  Spacer()

                  // Play/Pause button
                  Spacer()
                  Button(action: {
                    if audioManager.hasSelectedSounds {
                      audioManager.togglePlayback()
                    }
                  }) {
                    ZStack {
                      Circle()
                        .fill(
                          audioManager.hasSelectedSounds
                            ? (globalSettings.customAccentColor?.opacity(0.2)
                              ?? Color.accentColor.opacity(0.2))
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
                            : .secondary
                        )
                        .offset(x: xOffset)
                    }
                  }
                  .buttonStyle(.plain)
                  .disabled(!audioManager.hasSelectedSounds)
                  Spacer()

                  // Menu button
                  Spacer()
                  playbackMenuButton
                  Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
              }
            }

          // Custom navigation header overlay
          VStack(spacing: 0) {
            navigationHeader
            Spacer()
          }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .onChange(of: audioManager.hasSelectedSounds) { oldValue, newValue in
          print("🎨 UI: hasSelectedSounds changed from \(oldValue) to \(newValue)")
          // Auto-pause when no sounds are selected
          if !newValue && audioManager.isGloballyPlaying {
            audioManager.setGlobalPlaybackState(false)
          }
        }
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
            Button(action: {
              showingPresetPicker = true
            }) {
              HStack(spacing: 8) {
                HStack(spacing: 6) {
                  if audioManager.soloModeSound != nil {
                    Image(systemName: "headphones.circle.fill")
                      .font(.system(size: 24))
                      .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                  }
                  Text(navigationTitleText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                }
                Image(systemName: "chevron.down")
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(.secondary)
              }
            }
            .buttonStyle(.plain)
            .padding(.leading)
          }
          Spacer()

          if !isLargeDevice {
            HStack(spacing: 16) {
              TimerButton()
            }
            .padding(.trailing)
          }
        }
        .frame(height: isLargeDevice ? 0 : 50)
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
      let height: CGFloat = 50  // Title bar height (fixed)
      return height + safeAreaTop
    }
    // Combined status indicator view
    @ViewBuilder
    private var statusIndicatorView: some View {
      VStack(spacing: 0) {
        if !audioManager.hasSelectedSounds {
          noSoundsSelectedIndicator
            .transition(.opacity)
            .onAppear {
              print("🎨 UI: No sounds selected banner appeared")
            }
            .onDisappear {
              print("🎨 UI: No sounds selected banner disappeared")
            }
        }
      }
      .animation(.easeInOut(duration: 0.2), value: audioManager.soloModeSound?.id)
      .animation(.easeInOut(duration: 0.2), value: audioManager.isGloballyPlaying)
      .animation(.easeInOut(duration: 0.2), value: audioManager.sounds.map(\.isSelected))
    }

    // No sounds selected indicator banner
    private var noSoundsSelectedIndicator: some View {
      HStack(spacing: 8) {
        Image(systemName: "speaker.slash.fill")
          .font(.system(size: 16))
        Text("No Sounds Selected")
          .font(.system(.subheadline, design: .rounded, weight: .medium))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .foregroundStyle(.secondary)
      .background(.regularMaterial)
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
              maxWidth: 280,
              index: 0,
              draggedIndex: .constant(nil),
              hoveredIndex: .constant(nil),
              onDragStart: {},
              onDrop: { _ in },
              onEditSound: { sound in
                soundToEdit = sound
              },
              onHideSound: { sound in
                sound.isHidden.toggle()
                // If hiding a sound that's currently playing, stop it
                if sound.isHidden && sound.isSelected {
                  sound.pause()
                }
                // If hiding the solo mode sound, exit solo mode
                if sound.isHidden && audioManager.soloModeSound?.id == sound.id {
                  audioManager.exitSoloMode()
                }
                // Update hasSelectedSounds to reflect changes in hidden sounds
                audioManager.updateHasSelectedSounds()
                soundsUpdateTrigger += 1
              }
            )
            .scaleEffect(1.5)
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
          // Normal mode: Show all sounds in grid or empty state
          if filteredSounds.isEmpty {
            // Empty state - either no active sounds or all sounds hidden
            VStack(spacing: 20) {
              Spacer()

              VStack(spacing: 12) {
                Image(
                  systemName: audioManager.getVisibleSounds().isEmpty
                    ? "eye.slash.circle" : "speaker.slash.circle"
                )
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

                Text(
                  audioManager.getVisibleSounds().isEmpty ? "No Visible Sounds" : "No Active Sounds"
                )
                .font(.headline)
                .foregroundColor(.primary)
              }

              if audioManager.getVisibleSounds().isEmpty {
                // All sounds are hidden - button to manage sounds
                Button(action: {
                  showingSoundManagement = true
                }) {
                  Text("Manage Sounds")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(globalSettings.customAccentColor ?? .accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
              } else {
                // Some sounds are active but hidden by filter - button to show inactive
                Button(action: {
                  withAnimation {
                    hideInactiveSounds = false
                  }
                }) {
                  Text("Show Inactive Sounds")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(globalSettings.customAccentColor ?? .accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
              }

              Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
          } else {
            // Normal grid view
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
                    },
                    onEditSound: { sound in
                      soundToEdit = sound
                    },
                    onHideSound: { sound in
                      sound.isHidden.toggle()
                      // If hiding a sound that's currently playing, stop it
                      if sound.isHidden && sound.isSelected {
                        sound.pause()
                      }
                      // If hiding the solo mode sound, exit solo mode
                      if sound.isHidden && audioManager.soloModeSound?.id == sound.id {
                        audioManager.exitSoloMode()
                      }
                      // Update hasSelectedSounds to reflect changes in hidden sounds
                      audioManager.updateHasSelectedSounds()
                      soundsUpdateTrigger += 1
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
      }
      .animation(.easeInOut(duration: 0.3), value: audioManager.soloModeSound?.id)
    }

    // Menu button for bottom toolbar
    private var playbackMenuButton: some View {
      Menu {
        // Exit Solo Mode option (only shown when in solo mode)
        if audioManager.soloModeSound != nil {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }) {
            Label("Exit Solo Mode", systemImage: "headphones.slash")
          }
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
        .disabled(
          audioManager.soloModeSound == nil
            && !hideInactiveSounds
            && audioManager.sounds.allSatisfy { $0.isSelected || $0.isHidden }
        )

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
          Label("Settings", systemImage: "gear")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 22))
          .foregroundColor(.primary)
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
    let onEditSound: (Sound) -> Void
    let onHideSound: (Sound) -> Void

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
          // If this sound is in solo mode, exit solo mode
          if AudioManager.shared.soloModeSound?.id == sound.id {
            withAnimation(.easeInOut(duration: 0.3)) {
              AudioManager.shared.exitSoloMode()
            }
          } else {
            // Normal behavior: toggle sound selection
            sound.toggle()
          }
        }
        .contextMenu {
          // Solo Mode - only show if not already in solo mode
          if AudioManager.shared.soloModeSound?.id != sound.id {
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

          // Hide Sound
          Button(action: {
            onHideSound(sound)
          }) {
            let labelText = sound.isHidden ? "Show Sound" : "Hide Sound"
            let iconName = sound.isHidden ? "eye" : "eye.slash"
            Label(labelText, systemImage: iconName)
          }

          // Edit Sound (all sounds can be edited/customized)
          Button(action: {
            onEditSound(sound)
          }) {
            Label("Edit Sound", systemImage: "pencil")
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

        // Title (not draggable) - hidden in solo mode since it's shown in navigation title
        if AudioManager.shared.soloModeSound == nil {
          Text(LocalizedStringKey(sound.title))
            .font(
              Locale.current.identifier.hasPrefix("zh")
                ? .system(size: 16, weight: .thin) : .callout
            )
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: maxWidth - 20)
            .foregroundColor(.primary)
        }

        // Slider (not draggable)
        Slider(
          value: Binding(
            get: { Double(sound.volume) },
            set: { sound.volume = Float($0) }
          ), in: 0...1
        )
        .frame(width: min(maxWidth * 0.7, 140))
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
