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
