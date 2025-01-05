//
//  PresetEmptyState.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//


import SwiftUI

struct PresetEmptyState: View {
    @Binding var showingNewPresetSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Custom Presets")
                .font(.headline)
            
            Text("Save your current sound configuration as a preset to quickly access it later.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingNewPresetSheet = true
            } label: {
                Label("Create Preset", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: 250)
    }
}
