//
//  PresetManager.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

class PresetManager: ObservableObject {
    static let shared = PresetManager()
    
    @Published private(set) var presets: [Preset] = []
    @Published var currentPreset: Preset?
    
    private let defaultPresetName = "Default"
    private let presetKey = "savedPresets"
    
    var hasCustomPresets: Bool {
        presets.count > 1
    }
    
    init() {
        loadPresets()
        if presets.isEmpty {
            createDefaultPreset()
        }
    }
    
    private func createDefaultPreset() {
        let defaultPreset = Preset(
            id: UUID(),
            name: defaultPresetName,
            soundStates: AudioManager.shared.sounds.map { sound in
                Preset.SoundState(
                    fileName: sound.fileName,
                    isSelected: sound.isSelected,
                    volume: sound.volume
                )
            },
            isDefault: true
        )
        presets = [defaultPreset]
        currentPreset = defaultPreset
        savePresets()
    }
    
    func saveNewPreset(name: String) {
        let newPreset = Preset(
            id: UUID(),
            name: name,
            soundStates: AudioManager.shared.sounds.map { sound in
                Preset.SoundState(
                    fileName: sound.fileName,
                    isSelected: sound.isSelected,
                    volume: sound.volume
                )
            },
            isDefault: false
        )
        presets.append(newPreset)
        currentPreset = newPreset
        savePresets()
    }
    
    func updatePreset(_ preset: Preset, newName: String) {
        print("Starting update - Current presets: \(presets.map { $0.name })")  // Debug print
        
        // First remove any existing preset with the same name if it exists
        presets.removeAll { $0.name == newName }
        
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            var updatedPreset = preset
            updatedPreset.name = newName
            presets[index] = updatedPreset
            
            if currentPreset?.id == preset.id {
                currentPreset = updatedPreset
            }
            
            print("After update - Current presets: \(presets.map { $0.name })")  // Debug print
            savePresets()
            objectWillChange.send()
        }
    }
    
    func deletePreset(_ preset: Preset) {
        guard !preset.isDefault else { return }
        presets.removeAll { $0.id == preset.id }
        if currentPreset?.id == preset.id {
            currentPreset = presets.first
        }
        savePresets()
    }
    
    func applyPreset(_ preset: Preset) {
        for state in preset.soundStates {
            if let sound = AudioManager.shared.sounds.first(where: { $0.fileName == state.fileName }) {
                sound.volume = state.volume
                sound.isSelected = state.isSelected
            }
        }
        currentPreset = preset
    }
    
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: presetKey)
        }
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetKey),
           let decoded = try? JSONDecoder().decode([Preset].self, from: data) {
            presets = decoded
            currentPreset = decoded.first
        }
    }
}
