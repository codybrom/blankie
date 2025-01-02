//
//  ContentView.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var showingAbout: Bool
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var globalSettings = GlobalSettings.shared
    @ObservedObject private var appState = AppState.shared

    @State private var showingVolumePopover = false
    @State private var showingColorPicker = false
    @State private var showingShortcuts = false
    @State private var showingPreferences = false
    @State private var hideInactiveSounds = false
    @State private var showingNewPresetSheet = false
    @State private var presetName = ""
    @State private var showingNewPresetPopover = false
    
    var textColor: Color {
        audioManager.isGloballyPlaying ? .primary : .secondary
    }

    // Define constant sizes
    private let itemWidth: CGFloat = 120 // Total width including padding
    private let minimumSpacing: CGFloat = 10
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !audioManager.isGloballyPlaying {
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
                // Main content
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: calculateColumns(for: geometry.size.width),
                        spacing: minimumSpacing
                    ) {
                        ForEach(audioManager.sounds.filter { sound in
                            !hideInactiveSounds || sound.isSelected
                        }) { sound in
                            SoundIcon(sound: sound, maxWidth: itemWidth)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
                
                // App bar
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))
                    
                    HStack(spacing: 16) {
                        // Volume button with popover
                        Button(action: {
                            showingVolumePopover.toggle()
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .popover(isPresented: $showingVolumePopover, arrowEdge: .top) {
                            VolumePopoverView()
                        }
                        
                        // Play/Pause button
                        Button(action: {
                            audioManager.togglePlayback()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: audioManager.isGloballyPlaying ? "pause.fill" : "play.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                                    .offset(x: audioManager.isGloballyPlaying ? 0 : 2)
                            }
                        }
                        .buttonStyle(.borderless)
                        
                        Menu {
                            Button {
                                hideInactiveSounds.toggle()
                            } label: {
                                HStack {
                                    Text("Hide Inactive Sounds")
                                    if hideInactiveSounds {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .keyboardShortcut("h", modifiers: [.control, .command])
                            
                            Divider()

                            Button("Save as New Preset...") {
                                presetName = ""  // Reset preset name
                                showingNewPresetPopover.toggle()
                            }

                            Button("Add Sound (Coming Soon!)") {
                                // Implement add sound functionality
                            }
                            .keyboardShortcut("o", modifiers: .command)
                            .disabled(true)

                        } label: {
                            Text("⋮")  // vertical ellipsis
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .menuIndicator(.hidden)
                        .popover(isPresented: $showingNewPresetPopover, arrowEdge: .top) {

                            NewPresetSheet(presetName: $presetName, isPresented: $showingNewPresetPopover)
                        }

                        // Color picker menu
//                        Button(action: {
//                            showingColorPicker.toggle()
//                        }) {
//                            Image(systemName: "paintpalette.fill")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 20, height: 20)
//                                .foregroundColor(.primary)
//                        }
//                        .buttonStyle(.borderless)
//                        .popover(isPresented: $showingColorPicker) {
//                            ColorPickerView()
//                                .padding()
//                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.3))
                .background(.ultraThinMaterial)
            }
        }
        
        .ignoresSafeArea(.container, edges: .horizontal)
        .toolbar {
            if !PresetManager.shared.presets.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    PresetPicker()
                }
            }
            
            // Right-side menu icon only
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if #available(macOS 14.0, *) {
                        SettingsLink {
                            Text("Preferences...")
                        }
                        .keyboardShortcut(",", modifiers: .command)
                    } else {
                        Button("Preferences...") {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                        .keyboardShortcut(",", modifiers: .command)
                    }
                    
                    Button("Keyboard Shortcuts") {
                        showingShortcuts.toggle()
                    }
                    .keyboardShortcut("?", modifiers: [.command, .shift])
                    
                    
                    Button("About Blankie") {
                        showingAbout = true
                    }
                    
                    Divider()

                    Button("Quit Blankie") {
                        audioManager.pauseAll()
                        exit(0)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: audioManager.isGloballyPlaying)
        .sheet(isPresented: $showingShortcuts) {
            ShortcutsView()
                .background(.ultraThinMaterial)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $appState.isAboutViewPresented) {
            AboutView()
        }
        .onAppear {
            setupResetHandler()
            if !audioManager.isGloballyPlaying {
                NSApp.dockTile.badgeLabel = "⏸"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }

        }
        .onChange(of: audioManager.isGloballyPlaying) { isPlaying in
            if !isPlaying {
                NSApp.dockTile.badgeLabel = "⏸"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
        }
    }
 

    
    private func calculateColumns(for availableWidth: CGFloat) -> [GridItem] {
        let numberOfColumns = max(2, Int(availableWidth / (itemWidth + minimumSpacing)))
        return Array(repeating: GridItem(.fixed(itemWidth), spacing: minimumSpacing), count: numberOfColumns)
    }

    private func setupResetHandler() {
        audioManager.onReset = { @MainActor in
            showingVolumePopover = false
        }
    }
    
}

struct VolumePopoverView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var globalSettings = GlobalSettings.shared
    
    var accentColor: Color {
        globalSettings.customAccentColor ?? .accentColor
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Global Volume")
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { globalSettings.volume },
                        set: { globalSettings.setVolume($0) }
                    ),
                    in: 0...1
                )
                .frame(width: 200)
                .tint(accentColor)
            }

            // Only show middle divider if there are active sounds
            if audioManager.sounds.contains(where: \.isSelected) {
                Divider()
                
                // Active sound sliders
                ForEach(audioManager.sounds.filter(\.isSelected)) { sound in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sound.title)
                            .font(.caption)
                        
                        Slider(value: Binding(
                            get: { Double(sound.volume) },
                            set: { sound.volume = Float($0) }
                        ), in: 0...1)
                        .frame(width: 200)
                        .tint(accentColor)
                    }
                }
            }
            
            Divider()
            
            // Reset button
            Button("Reset Sounds") {
                audioManager.resetSounds()
            }
            .font(.caption)
        }
        .padding()
    }
}

struct ColorPickerView: View {
    @ObservedObject var globalSettings = GlobalSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appearance")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation {
                        globalSettings.setAppearance(mode)
                    }
                }) {
                    HStack {
                        Image(systemName: mode.icon)
                            .frame(width: 16, height: 16)
                        
                        Text(mode.rawValue)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if globalSettings.appearance == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
            
            Divider()
                .padding(.vertical, 8)

            Text("Accent Color")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(AccentColor.allCases, id: \.self) { color in
                Button(action: {
                    globalSettings.setAccentColor(color.color)
                }) {
                    HStack {
                        Circle()
                            .fill(color.color ?? .accentColor)
                            .frame(width: 16, height: 16)
                        
                        Text(color.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if (color == .system && globalSettings.customAccentColor == nil) ||
                           (color.color == globalSettings.customAccentColor) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

        }
        .frame(width: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(showingAbout: .constant(false))
                .frame(width: 600, height: 400)
        }
        .previewDisplayName("Blankie")
    }
}

enum AccentColor: CaseIterable {
    case system
    case red
    case pink
    case orange
    case brown
    case yellow
    case green
    case mint
    case teal
    case cyan
    case blue
    case indigo
    case purple
    
    var name: String {
        switch self {
        case .system: return "System"
        case .red: return "Red"
        case .pink: return "Pink"
        case .orange: return "Orange"
        case .brown: return "Brown"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .mint: return "Mint"
        case .teal: return "Teal"
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .indigo: return "Indigo"
        case .purple: return "Purple"
        }
    }
    
    var color: Color? {
        switch self {
        case .system: return nil
        case .red: return .red
        case .pink: return .pink
        case .orange: return .orange
        case .brown: return .brown
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        }
    }
}

struct ShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let shortcuts: [(String, String)] = [
        ("⏯", "Play/Pause Sounds"),
//        ("⌘ O", "Add Custom Sound"),
        ("⌘ W", "Close Window"),
        ("⌘ ,", "Preferences"),
        ("⌘ ⇧ ?", "Keyboard Shortcuts"),
        ("⌘ Q", "Quit")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with close button
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            // Shortcuts list
            VStack(spacing: 12) {
                ForEach(shortcuts, id: \.0) { shortcut in
                    HStack {
                        Text(shortcut.1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(shortcut.0)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
    }
}


struct PresetPicker: View {
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var showingPresetPopover = false
    @State private var showingEditSheet = false
    @State private var selectedPreset: Preset?
    @State private var presetName = ""
    
    var body: some View {
        if presetManager.hasCustomPresets {
            Button {
                showingPresetPopover.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(presetManager.currentPreset?.name ?? "Default")
                        .fontWeight(.bold)
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPresetPopover, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                // Default preset
                Button(action: {
                    presetManager.applyPreset(presetManager.presets[0])
                    showingPresetPopover = false
                }) {
                    HStack {
                        Text("Default")
                        Spacer()
                        if presetManager.currentPreset?.id == presetManager.presets[0].id {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Custom presets
                ForEach(presetManager.presets.dropFirst()) { preset in
                    Divider()
                    HStack(spacing: 8) {
                        Text(preset.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                presetManager.applyPreset(preset)
                                showingPresetPopover = false
                            }
                        
                        Button {
                            selectedPreset = preset
                            presetName = preset.name
                            showingPresetPopover = false
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            presetManager.deletePreset(preset)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))
        }
            .sheet(isPresented: $showingEditSheet) {
                if let preset = selectedPreset {
                    EditPresetSheet(preset: preset, presetName: $presetName, isPresented: $showingEditSheet)
                }
            }
        }
    }
}

struct NewPresetSheet: View {
    @Binding var presetName: String
    @Binding var isPresented: Bool
    @ObservedObject private var presetManager = PresetManager.shared
    
    var body: some View {
        VStack {
            Text("New Preset")
                .font(.headline)
            
            TextField("Preset Name", text: $presetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Save") {
                    if !presetName.isEmpty {
                        presetManager.saveNewPreset(name: presetName)
                        isPresented = false
                    }
                }
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct EditPresetSheet: View {
    let preset: Preset
    @Binding var presetName: String
    @Binding var isPresented: Bool
    @ObservedObject private var presetManager = PresetManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Preset")
                .font(.headline)
            
            TextField("Preset Name", text: $presetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Save") {
                    if !presetName.isEmpty {
                        presetManager.updatePreset(preset, newName: presetName)
                        isPresented = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

