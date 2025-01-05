//
//  Preset.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct Preset: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var soundStates: [PresetState]
    let isDefault: Bool
    
    static func == (lhs: Preset, rhs: Preset) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.soundStates == rhs.soundStates &&
        lhs.isDefault == rhs.isDefault
    }
    
    func validate() -> Bool {
        // Check required sound states
        let requiredSounds = AudioManager.shared.sounds.map(\.fileName)
        let presetSounds = Set(soundStates.map(\.fileName))
        
        guard requiredSounds.allSatisfy(presetSounds.contains) else {
            print("❌ Preset: Missing required sounds")
            return false
        }
        
        // Validate volume ranges
        guard soundStates.allSatisfy({ $0.volume >= 0 && $0.volume <= 1 }) else {
            print("❌ Preset: Invalid volume range")
            return false
        }
        
        // Validate name
        guard !name.isEmpty else {
            print("❌ Preset: Empty name")
            return false
        }
        
        return true
    }
}
