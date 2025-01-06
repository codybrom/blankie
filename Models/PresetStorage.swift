//
//  PresetStorage.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import Foundation

struct PresetStorage {
    private static let defaults = UserDefaults.standard

    static let defaultPresetKey = "defaultPreset"
    static let customPresetsKey = "savedPresets"
    static let lastActivePresetIDKey = "lastActivePresetID"

    static func saveDefaultPreset(_ preset: Preset) {
        print("💾 PresetStorage: Saving default preset")
        if let data = try? JSONEncoder().encode(preset) {
            defaults.set(data, forKey: defaultPresetKey)
            print("💾 PresetStorage: Default preset saved successfully")
        } else {
            print("❌ PresetStorage: Failed to save default preset")
        }
    }

    static func loadDefaultPreset() -> Preset? {
        print("💾 PresetStorage: Loading default preset")
        guard let data = defaults.data(forKey: defaultPresetKey),
              let preset = try? JSONDecoder().decode(Preset.self, from: data) else {
            print("💾 PresetStorage: No default preset found")
            return nil
        }
        print("💾 PresetStorage: Default preset loaded successfully")
        return preset
    }

    static func saveCustomPresets(_ presets: [Preset]) {
        print("💾 PresetStorage: Saving \(presets.count) custom presets")
        if let data = try? JSONEncoder().encode(presets) {
            // Add debug logging before saving
            print("Saving presets:")
            presets.forEach { preset in
                print("  - '\(preset.name)':")
                print("    * Active sounds:")
                preset.soundStates
                    .filter { $0.isSelected }
                    .forEach { state in
                        print("      - \(state.fileName) (Volume: \(state.volume))")
                    }
            }
            UserDefaults.standard.set(data, forKey: customPresetsKey)
            print("💾 PresetStorage: Custom presets saved successfully")
        }
    }

    static func loadCustomPresets() -> [Preset] {
        print("💾 PresetStorage: Loading custom presets")
        if let data = UserDefaults.standard.data(forKey: customPresetsKey),
           let presets = try? JSONDecoder().decode([Preset].self, from: data) {
            print("💾 PresetStorage: Loaded \(presets.count) custom presets")
            // Add debug logging
            presets.forEach { preset in
                print("  - Loaded preset '\(preset.name)':")
                print("    * Active sounds:")
                preset.soundStates
                    .filter { $0.isSelected }
                    .forEach { state in
                        print("      - \(state.fileName) (Volume: \(state.volume))")
                    }
            }
            return presets
        }
        print("💾 PresetStorage: No custom presets found")
        return []
    }

    static func saveLastActivePresetID(_ id: UUID) {
        print("💾 PresetStorage: Saving last active preset ID: \(id)")
        defaults.set(id.uuidString, forKey: lastActivePresetIDKey)
    }

    static func loadLastActivePresetID() -> UUID? {
        print("💾 PresetStorage: Loading last active preset ID")
        guard let idString = defaults.string(forKey: lastActivePresetIDKey),
              let id = UUID(uuidString: idString) else {
            print("💾 PresetStorage: No last active preset ID found")
            return nil
        }
        print("💾 PresetStorage: Last active preset ID loaded: \(id)")
        return id
    }
}
