//
//  PresetPicker.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

struct PresetPicker: View {
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var showingPresetPopover = false
    @State private var showingNewPresetSheet = false
    @State private var newPresetName = ""
    @State private var error: Error?
    
    var body: some View {
        HStack {
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
            .disabled(presetManager.isLoading)
            .popover(isPresented: $showingPresetPopover, arrowEdge: .bottom) {
                if presetManager.isLoading {
                    PresetLoadingView()
                } else {
                    VStack(spacing: 0) {
                        PresetList(presetManager: presetManager, isPresented: $showingPresetPopover)
                            .frame(width: 200)
                        
                        Divider()
                        
                        Button(action: {
                            showingPresetPopover = false
                            showingNewPresetSheet = true
                        }) {
                            Label("New Preset", systemImage: "plus")
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewPresetSheet) {
            NewPresetSheet(
                presetName: $newPresetName,
                isPresented: $showingNewPresetSheet
            )
        }
    }
}

struct PresetList: View {
    @ObservedObject var presetManager: PresetManager
    @Binding var isPresented: Bool
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 0) {
            // Default preset
            PresetRow(preset: presetManager.presets[0], isPresented: $isPresented)
            
            if presetManager.hasCustomPresets {
                Divider()
                
                // Custom presets
                ForEach(presetManager.presets.dropFirst()) { preset in
                    PresetRow(preset: preset, isPresented: $isPresented)
                    if preset.id != presetManager.presets.last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
    }
}

struct PresetRow: View {
    let preset: Preset
    @Binding var isPresented: Bool
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var showingEditSheet = false
    @State private var presetName: String = ""
    @State private var error: Error?
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                do {
                    try presetManager.applyPreset(preset)
                    isPresented = false
                } catch {
                    self.error = error
                }
            }) {
                HStack {
                    Text(preset.name)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if presetManager.currentPreset?.id == preset.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            
            // Only show edit and delete buttons for non-default presets
            if !preset.isDefault {
                Button(action: {
                    presetName = preset.name
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Rename Preset")
                
                Button(action: {
                    presetManager.deletePreset(preset)
                }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete Preset")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .sheet(isPresented: $showingEditSheet) {
            EditPresetSheet(
                preset: preset,
                presetName: $presetName,
                isPresented: $showingEditSheet
            )
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
    }
}
