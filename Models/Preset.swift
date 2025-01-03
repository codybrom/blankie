//
//  Preset.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct Preset: Codable, Identifiable {
    let id: UUID
    var name: String
    var soundStates: [SoundState]
    var isDefault: Bool
    
    struct SoundState: Codable {
        let fileName: String
        let isSelected: Bool
        let volume: Float
    }
}
