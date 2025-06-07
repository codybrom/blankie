import SwiftUI

#if os(iOS) || os(visionOS)
  struct AdaptiveContentView: View {
    @Binding var showingAbout: Bool
    @Binding var showingSettings: Bool

    @StateObject var audioManager = AudioManager.shared
    @StateObject var globalSettings = GlobalSettings.shared
    @StateObject var presetManager = PresetManager.shared

    @State var showingListView = false
    @State var showingPresetPicker = false
    @State var hideInactiveSounds = false
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var draggedIndex: Int?
    @State var hoveredIndex: Int?
    @State var dragResetTimer: Timer?
    @State var showingAboutInMenu = false
    @State var showingThemePicker = false
    @State var showingSoundManagement = false
    @State var soundToEdit: Sound?
    @State var soundsUpdateTrigger = 0
    @State var editMode: EditMode = .inactive

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Check if any sounds are selected (use AudioManager's published property)
    var hasSelectedSounds: Bool {
      audioManager.hasSelectedSounds
    }

    // Edit mode helper functions
    func enterEditMode() {
      editMode = .active

      // Haptic feedback
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

    var navigationTitleText: String {
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
      .onAppear {
        // Initialize showingListView from GlobalSettings
        showingListView = globalSettings.showingListView
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
#endif
