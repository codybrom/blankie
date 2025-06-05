#!/usr/bin/env swift

import Foundation
import AVFoundation

// This script re-analyzes all built-in sounds and outputs updated JSON values
// Run from project root: swift scripts/reanalyze-sounds.swift

// MARK: - Data Structures

struct SoundData: Codable {
    let defaultOrder: Int
    let title: String
    let systemIconName: String
    let fileName: String
    let author: String?
    let authorUrl: String?
    let license: String
    let soundUrl: String?
    let soundName: String
    let description: String
    let note: String?
    let lufs: Float?
    let normalizationFactor: Float?
}

struct SoundsContainer: Codable {
    let sounds: [SoundData]
}

// MARK: - Audio Analysis (simplified version)

func analyzeLUFS(at url: URL) -> (lufs: Float, normalizationFactor: Float)? {
    do {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = UInt32(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create buffer for \(url.lastPathComponent)")
            return nil
        }
        
        try file.read(into: buffer)
        buffer.frameLength = frameCount
        
        // Simplified LUFS calculation - just using RMS as approximation
        var totalPower: Float = 0
        let channelCount = Int(format.channelCount)
        
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            
            var sum: Float = 0
            for i in 0..<Int(frameCount) {
                let sample = channelData[i]
                sum += sample * sample
            }
            
            let meanSquare = sum / Float(frameCount)
            let rms = sqrt(meanSquare)
            totalPower += rms * rms
        }
        
        // Convert to LUFS approximation
        let lufs = -0.691 + 10.0 * log10(totalPower)
        
        // Calculate normalization factor
        let targetLUFS: Float = -27.0
        let gainDB = targetLUFS - lufs
        let limitedGainDB = min(gainDB, 18.0) // Max 18dB gain
        let normalizationFactor = pow(10, limitedGainDB / 20)
        
        return (lufs: lufs, normalizationFactor: normalizationFactor)
    } catch {
        print("Error analyzing \(url.lastPathComponent): \(error)")
        return nil
    }
}

// MARK: - Main Script

func main() {
    // Load existing sounds.json
    let currentDir = FileManager.default.currentDirectoryPath
    let jsonPath = "\(currentDir)/Blankie/Resources/sounds.json"
    let soundsDir = "\(currentDir)/Blankie/Resources/Sounds"
    
    guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) else {
        print("Error: Could not read sounds.json at \(jsonPath)")
        exit(1)
    }
    
    let decoder = JSONDecoder()
    guard let container = try? decoder.decode(SoundsContainer.self, from: jsonData) else {
        print("Error: Could not decode sounds.json")
        exit(1)
    }
    
    print("Re-analyzing \(container.sounds.count) sounds...")
    print("Target LUFS: -27.0")
    print("Max Gain: 18.0 dB\n")
    
    var updatedSounds: [SoundData] = []
    
    for sound in container.sounds {
        print("Analyzing: \(sound.fileName)")
        
        // Find the actual file
        let extensions = ["m4a", "wav", "mp3", "aiff"]
        var fileURL: URL?
        
        for ext in extensions {
            let path = "\(soundsDir)/\(sound.fileName).\(ext)"
            if FileManager.default.fileExists(atPath: path) {
                fileURL = URL(fileURLWithPath: path)
                break
            }
        }
        
        guard let url = fileURL else {
            print("  ❌ File not found")
            updatedSounds.append(sound)
            continue
        }
        
        if let analysis = analyzeLUFS(at: url) {
            let oldLUFS = sound.lufs ?? 0
            let oldFactor = sound.normalizationFactor ?? 1
            
            print("  Old: LUFS: \(oldLUFS), Factor: \(oldFactor)")
            print("  New: LUFS: \(analysis.lufs), Factor: \(analysis.normalizationFactor)")
            
            let difference = analysis.lufs - oldLUFS
            if abs(difference) > 0.5 {
                print("  ⚠️  Significant difference: \(difference) dB")
            }
            
            // Create updated sound with new values
            let updatedSound = SoundData(
                defaultOrder: sound.defaultOrder,
                title: sound.title,
                systemIconName: sound.systemIconName,
                fileName: sound.fileName,
                author: sound.author,
                authorUrl: sound.authorUrl,
                license: sound.license,
                soundUrl: sound.soundUrl,
                soundName: sound.soundName,
                description: sound.description,
                note: sound.note,
                lufs: analysis.lufs,
                normalizationFactor: analysis.normalizationFactor
            )
            updatedSounds.append(updatedSound)
        } else {
            print("  ❌ Analysis failed")
            updatedSounds.append(sound)
        }
        
        print("")
    }
    
    // Output updated JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let updatedContainer = SoundsContainer(sounds: updatedSounds)
    
    do {
        let jsonData = try encoder.encode(updatedContainer)
        
        // Write to a new file
        let outputPath = "\(currentDir)/Blankie/Resources/sounds-updated.json"
        try jsonData.write(to: URL(fileURLWithPath: outputPath))
        
        print("\n✅ Updated sounds.json written to: sounds-updated.json")
        print("To apply changes, run:")
        print("  mv Blankie/Resources/sounds-updated.json Blankie/Resources/sounds.json")
    } catch {
        print("\n❌ Error writing updated JSON: \(error)")
    }
}

main()