import SwiftUI

#if os(iOS) || os(visionOS)
  struct AdaptiveContentView: View {
    @Binding var showingAbout: Bool

    @StateObject var audioManager = AudioManager.shared
    @StateObject var globalSettings = GlobalSettings.shared
    @StateObject var presetManager = PresetManager.shared

    @State var showingListView = false
    @State private var showingPresetPicker = false
    @State var hideInactiveSounds = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var draggedIndex: Int?
    @State var hoveredIndex: Int?
    @State var dragResetTimer: Timer?
    @State private var showingThemePicker = false
    @State var showingSoundManagement = false
    @State private var showingViewSettings = false
    @State private var showingTimer = false
    @State var soundToEdit: Sound?
    @State var soundsUpdateTrigger = 0
    @State var editMode: EditMode = .inactive

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
      Group {
        if isLargeDevice {
          iPadLayout
        } else {
          iPhoneLayout
        }
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
      .sheet(isPresented: $showingViewSettings) {
        ViewSettingsSheet(
          isPresented: $showingViewSettings,
          showingListView: $showingListView,
          hideInactiveSounds: $hideInactiveSounds
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
      }
      .sheet(isPresented: $showingThemePicker) {
        ThemePickerSheet(isPresented: $showingThemePicker)
      }
      .sheet(isPresented: $showingSoundManagement) {
        SoundManagementView()
      }
      .sheet(isPresented: $showingTimer) {
        TimerSheetView()
          .presentationDetents([.medium, .large])
      }
      .modifier(AudioErrorHandler())
      .onAppear {
        showingListView = globalSettings.showingListView
      }
    }

    // MARK: - Layouts

    @ViewBuilder
    private var iPadLayout: some View {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        SidebarContentView(
          showingPresetPicker: $showingPresetPicker,
          showingAbout: $showingAbout,
          hideInactiveSounds: $hideInactiveSounds,
          showingViewSettings: $showingViewSettings,
          showingSoundManagement: $showingSoundManagement
        )
      } detail: {
        NavigationStack {
          mainContentView
            .navigationTitle(navigationTitle)
            .toolbar {
              ToolbarItem(placement: .primaryAction) {
                TimerButton()
              }
            }
        }
      }
      .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var iPhoneLayout: some View {
      NavigationStack {
        ZStack(alignment: .bottom) {
          mainContentView
            .safeAreaInset(edge: .bottom) {
              bottomToolbar
            }

          // Status banners overlay
          VStack {
            statusBanners
              .animation(.easeInOut(duration: 0.2), value: audioManager.soloModeSound?.id)
              .animation(.easeInOut(duration: 0.2), value: audioManager.hasSelectedSounds)
              .animation(.easeInOut(duration: 0.2), value: editMode)
            Spacer()
          }
        }
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            presetButton
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            TimerButton()
          }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.regularMaterial, for: .navigationBar)
      }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
      Group {
        if let soloSound = audioManager.soloModeSound {
          // Solo mode view
          soloModeView(for: soloSound)
        } else if showingListView && !isLargeDevice {
          // List view for iPhone
          listView
        } else if filteredSounds.isEmpty {
          // Empty state
          emptyStateView
        } else {
          // Grid view
          gridView
        }
      }
      .animation(.easeInOut(duration: 0.3), value: audioManager.soloModeSound?.id)
      .animation(.easeInOut(duration: 0.3), value: showingListView)
    }

    // MARK: - Helper Views

    private var navigationTitle: String {
      if let soloSound = audioManager.soloModeSound {
        return soloSound.title
      }

      if audioManager.isCarPlayQuickMix {
        return "Quick Mix"
      }

      if let preset = presetManager.currentPreset {
        return preset.isDefault ? "Blankie" : preset.name
      }

      return "Blankie"
    }

    private var presetButton: some View {
      Button(action: {
        showingPresetPicker = true
      }) {
        HStack(spacing: 4) {
          if audioManager.soloModeSound != nil {
            Image(systemName: "headphones.circle.fill")
              .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          } else if audioManager.isCarPlayQuickMix {
            Image(systemName: "car.circle.fill")
              .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          }
          Text(navigationTitle)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          Image(systemName: "chevron.down")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }

    private var bottomToolbar: some View {
      VStack(spacing: 0) {
        HStack(spacing: 0) {
          // Grid/List toggle
          Spacer()
          Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
              showingListView.toggle()
            }
          }) {
            Image(systemName: showingListView ? "list.bullet" : "square.grid.3x3")
              .font(.system(size: 22))
              .foregroundColor(.primary)
              .contentTransition(.symbolEffect(.replace))
          }
          .buttonStyle(.plain)
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
        .background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
      }
    }

    private var playPauseButton: some View {
      Button(action: {
        if audioManager.hasSelectedSounds {
          if globalSettings.enableHaptics {
            #if os(iOS)
              let generator = UIImpactFeedbackGenerator(style: .light)
              generator.impactOccurred()
            #endif
          }
          audioManager.togglePlayback()
        }
      }) {
        ZStack {
          Circle()
            .fill(
              audioManager.hasSelectedSounds
                ? (globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                : Color.secondary.opacity(0.1)
            )
            .frame(width: 60, height: 60)

          Image(systemName: audioManager.isGloballyPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 26))
            .foregroundColor(
              audioManager.hasSelectedSounds
                ? (globalSettings.customAccentColor ?? .accentColor)
                : .secondary
            )
            .contentTransition(
              .symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating)
            )
            .offset(x: audioManager.isGloballyPlaying ? 0 : 2)
        }
      }
      .buttonStyle(.plain)
      .disabled(!audioManager.hasSelectedSounds)
    }

    private var menuButton: some View {
      Menu {
        if audioManager.soloModeSound != nil {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }) {
            Label("Exit Solo Mode", systemImage: "headphones.slash")
          }
        }

        if audioManager.isCarPlayQuickMix {
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitCarPlayQuickMix()
            }
          }) {
            Label("Exit Quick Mix", systemImage: "car.slash")
          }
        }

        Section {
          Button(action: {
            showingAbout = true
          }) {
            Label("About Blankie", systemImage: "info.circle")
          }
        }

        Button(action: {
          showingViewSettings = true
        }) {
          Label("View Settings", systemImage: "slider.horizontal.3")
        }

        Button(action: {
          showingSoundManagement = true
        }) {
          Label("Sound Settings", systemImage: "waveform")
        }

        Button(action: {
          withAnimation {
            editMode = editMode == .active ? .inactive : .active
          }
        }) {
          Label(
            editMode == .active ? "Done Reordering" : "Reorder Sounds",
            systemImage: editMode == .active ? "checkmark.circle" : "arrow.up.arrow.down"
          )
        }

        Button(action: {
          showingTimer = true
        }) {
          Label("Timer", systemImage: "timer")
        }
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: 22))
          .foregroundColor(.primary)
      }
    }

    // MARK: - Status Banners

    @ViewBuilder
    private var statusBanners: some View {
      if audioManager.soloModeSound != nil && editMode == .inactive {
        // Solo mode banner
        HStack(spacing: 12) {
          Image(systemName: "headphones.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          Text("Solo Mode")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          Button("Exit") {
            withAnimation(.easeInOut(duration: 0.3)) {
              audioManager.exitSoloMode()
            }
          }
          .font(.system(.subheadline, weight: .medium))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else if editMode == .active && !isLargeDevice {
        // Reorder mode banner
        HStack(spacing: 12) {
          Image(systemName: "arrow.up.arrow.down.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          Text("Drag to Reorder")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          Button("Done") {
            withAnimation(.easeInOut(duration: 0.3)) {
              editMode = .inactive
            }
          }
          .font(.system(.subheadline, weight: .medium))
          .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
          .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      } else if !audioManager.hasSelectedSounds && editMode == .inactive {
        // No sounds selected banner
        HStack(spacing: 12) {
          Image(systemName: "speaker.slash.fill")
            .font(.system(size: 16))
          Text("No Sounds Selected")
            .font(.system(.subheadline, design: .rounded, weight: .medium))

          Spacer()

          if showingListView && !isLargeDevice {
            Button(action: {
              withAnimation(.easeInOut(duration: 0.3)) {
                editMode = editMode == .active ? .inactive : .active
              }
            }) {
              Text(editMode == .active ? "Done" : "Reorder")
                .font(.system(.subheadline, weight: .medium))
                .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
            }
            .buttonStyle(.plain)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .foregroundStyle(.secondary)
        .background(.regularMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }

    // MARK: - Helper Properties

    var hasSelectedSounds: Bool {
      audioManager.hasSelectedSounds
    }

    func enterEditMode() {
      editMode = .active

      if globalSettings.enableHaptics {
        #if os(iOS)
          let generator = UIImpactFeedbackGenerator(style: .medium)
          generator.impactOccurred()
        #endif
      }
    }

    func exitEditMode() {
      editMode = .inactive
    }
  }

  struct AdaptiveContentView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        AdaptiveContentView(showingAbout: .constant(false))
          .previewDevice("iPhone 14")
          .previewDisplayName("iPhone")

        AdaptiveContentView(showingAbout: .constant(false))
          .previewDevice("iPad Pro (11-inch)")
          .previewDisplayName("iPad")
      }
    }
  }
#endif
