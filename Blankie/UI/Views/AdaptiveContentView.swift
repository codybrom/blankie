import SwiftUI

#if os(iOS) || os(visionOS)
  struct AdaptiveContentView: View {
    @Binding var showingAbout: Bool

    @StateObject var audioManager = AudioManager.shared
    @StateObject var globalSettings = GlobalSettings.shared
    @StateObject var presetManager = PresetManager.shared

    @State var showingListView = false
    @State var showingPresetPicker = false
    @State var hideInactiveSounds = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var draggedIndex: Int?
    @State var hoveredIndex: Int?
    @State var dragResetTimer: Timer?
    @State private var showingThemePicker = false
    @State var showingSoundManagement = false
    @State var showingViewSettings = false
    @State var showingTimer = false
    @State var soundToEdit: Sound?
    @State var soundsUpdateTrigger = 0
    @State var editMode: EditMode = .inactive
    @State var playPauseTrigger = 0
    @State var menuTrigger = 0

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
          .interactiveDismissDisabled()  // Prevent accidental dismissal
          .onAppear {
            print("🎵 AdaptiveContentView: SoundSheet appeared for '\(sound.title)'")
          }
          .onDisappear {
            print("🎵 AdaptiveContentView: SoundSheet disappeared for '\(sound.title)'")
          }
      }
      .onChange(of: soundToEdit) { oldValue, newValue in
        if let sound = newValue {
          print("🎵 AdaptiveContentView: SoundSheet will be presented for '\(sound.title)'")
        } else if let oldSound = oldValue {
          print("🎵 AdaptiveContentView: SoundSheet will be dismissed for '\(oldSound.title)'")
        }
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
        VStack(spacing: 0) {
          mainContentView

          // Status banners above bottom toolbar
          statusBanners
            .animation(.easeInOut(duration: 0.2), value: audioManager.soloModeSound?.id)
            .animation(.easeInOut(duration: 0.2), value: audioManager.hasSelectedSounds)
            .animation(.easeInOut(duration: 0.2), value: editMode)

          bottomToolbar
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
        if let soloSound = audioManager.soloModeSound, soundToEdit == nil,
          audioManager.previewModeSound == nil
        {
          // Solo mode view (only when no SoundSheet is presented and not in preview mode)
          soloModeView(for: soloSound)
            .onAppear {
              print(
                "🎵 AdaptiveContentView: Showing solo mode view for '\(soloSound.title)' (no SoundSheet open, no preview)"
              )
            }
        } else if let soloSound = audioManager.soloModeSound,
          soundToEdit != nil || audioManager.previewModeSound != nil
        {
          // Solo mode is active but SoundSheet is open or in preview mode, maintain normal layout
          Group {
            if audioManager.isQuickMix {
              QuickMixView()
            } else if showingListView && !isLargeDevice {
              listView
            } else if filteredSounds.isEmpty {
              emptyStateView
            } else {
              gridView
            }
          }
          .onAppear {
            if audioManager.previewModeSound != nil {
              print(
                "🎵 AdaptiveContentView: Solo mode active for '\(soloSound.title)' but preview mode active - maintaining normal layout"
              )
            } else {
              print(
                "🎵 AdaptiveContentView: Solo mode active for '\(soloSound.title)' but SoundSheet is open - maintaining normal layout"
              )
            }
          }
        } else if audioManager.isQuickMix {
          // Quick Mix mode view
          QuickMixView()
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
      .animation(
        .easeInOut(duration: 0.3),
        value: soundToEdit == nil && audioManager.previewModeSound == nil
          ? audioManager.soloModeSound?.id : nil
      )
      .animation(.easeInOut(duration: 0.3), value: audioManager.isQuickMix)
      .animation(.easeInOut(duration: 0.3), value: showingListView)
      .onChange(of: audioManager.soloModeSound) { oldValue, newValue in
        if let newSolo = newValue {
          print(
            "🎵 AdaptiveContentView: Solo mode started for '\(newSolo.title)' (SoundSheet open: \(soundToEdit != nil))"
          )
        } else if let oldSolo = oldValue {
          print(
            "🎵 AdaptiveContentView: Solo mode ended for '\(oldSolo.title)' (SoundSheet open: \(soundToEdit != nil))"
          )
        }
      }
    }

    // MARK: - Helper Views
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
