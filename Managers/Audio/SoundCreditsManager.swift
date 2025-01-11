//
//  SoundCreditsManager.swift
//  Blankie
//
//  Created by Cody Bromley on 1/10/25.
//

import SwiftUI

class SoundCreditsManager: ObservableObject {
    static let shared = SoundCreditsManager()
    @Published private(set) var credits: [SoundCredit] = []
    @Published private(set) var loadError: Error?
    
    private init() {
        loadCredits()
    }
    
    private func loadCredits() {
        guard let url = Bundle.main.url(forResource: "sounds", withExtension: "json") else {
            print("Error: sounds.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(SoundsContainer.self, from: data)
            
            DispatchQueue.main.async {
                self.credits = container.sounds.map { sound in
                    SoundCredit(
                        name: sound.title,
                        author: sound.author,
                        license: License(rawValue: sound.license.lowercased()) ?? .cc0,
                        editor: sound.editor,
                        soundUrl: URL(string: sound.soundUrl)
                    )
                }
            }
        } catch {
            print("Error loading sounds.json: \(error)")
            loadError = error
        }
    }
}
