//
//  PresetError.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//


//
//  PresetError.swift
//  Blankie
//
//  Created by Cody Bromley on 1/5/25.
//

import Foundation

enum PresetError: LocalizedError {
    case invalidPreset
    case saveFailed
    case loadFailed
    case defaultPresetMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidPreset:
            return "The preset is invalid or corrupted"
        case .saveFailed:
            return "Failed to save preset"
        case .loadFailed:
            return "Failed to load preset"
        case .defaultPresetMissing:
            return "Default preset is missing"
        }
    }
}
