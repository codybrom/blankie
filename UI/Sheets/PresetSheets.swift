//
//  PresetSheets.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

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
