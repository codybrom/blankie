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
