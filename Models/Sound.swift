//
//  Sound.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI
import AVFoundation
import Combine

/// Represents a single sound with its associated properties and playback controls.
class Sound: ObservableObject, Identifiable {
    let id = UUID()
    let title: String
    let systemIconName: String
    let fileName: String
    
    @Published var isSelected = false {
        didSet {
            UserDefaults.standard.set(isSelected, forKey: "\(fileName)_isSelected")
        }
    }
    
    @Published var volume: Float = 1.0 {
        didSet {
            guard volume >= 0 && volume <= 1 else {
                ErrorReporter.shared.report(AudioError.invalidVolume)
                volume = oldValue
                return
            }
            
            if player?.isPlaying == true {
                updateVolume()
            }
            UserDefaults.standard.set(volume, forKey: "\(fileName)_volume")
        }
    }

    var player: AVAudioPlayer?
    private let fileExtension = "mp3"
    private let fadeDuration: TimeInterval = 0.1
    private var fadeTimer: Timer?
    private var fadeStartVolume: Float = 0
    private var targetVolume: Float = 1.0
    private var globalSettingsObserver: AnyCancellable?
    private var isResetting = false

    init(title: String, systemIconName: String, fileName: String) {
        self.title = title
        self.systemIconName = systemIconName
        self.fileName = fileName
        
        // Restore saved volume
        self.volume = UserDefaults.standard.float(forKey: "\(fileName)_volume")
        if self.volume == 0 {
            self.volume = 1.0
        }
        
        // Restore selected state
        self.isSelected = UserDefaults.standard.bool(forKey: "\(fileName)_isSelected")
        
        // Observe global volume changes
        globalSettingsObserver = GlobalSettings.shared.$volume
            .sink { [weak self] _ in
                self?.updateVolume()
            }
        
        loadSound()
    }

    private func scaledVolume(_ linear: Float) -> Float {
        return pow(linear, 3)
    }
    
    private func updateVolume() {
        let scaledVol = scaledVolume(volume)
        let effectiveVolume = scaledVol * Float(GlobalSettings.shared.volume)
        player?.volume = effectiveVolume
    }

    private var loadedPlayer: AVAudioPlayer? {
        if player == nil {
            loadSound()
        }
        return player
    }
    
    private func loadSound() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            ErrorReporter.shared.report(AudioError.fileNotFound)
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume * Float(GlobalSettings.shared.volume)
            player?.numberOfLoops = -1
            player?.enableRate = false  // Disable rate/pitch adjustment
            player?.prepareToPlay()
        } catch {
            ErrorReporter.shared.report(AudioError.loadFailed(error))
        }
    }

    func play(completion: ((Result<Void, AudioError>) -> Void)? = nil) {
        updateVolume()  // Set correct volume before playing
        guard let player = player else {
            completion?(.failure(.fileNotFound))
            return
        }
        
        player.play()
        completion?(.success(()))
    }
    
    func pause(immediate: Bool = false) {
        if immediate {
            player?.pause()
            player?.volume = 0
        } else {
            fadeOut()
        }
    }

    private func fadeIn() {
        fadeTimer?.invalidate()
        fadeStartVolume = 0
        targetVolume = volume * Float(GlobalSettings.shared.volume)
        
        player?.volume = fadeStartVolume

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let newVolume = self.player?.volume ?? 0
            if newVolume < self.targetVolume {
                self.player?.volume = min(newVolume + (self.targetVolume / 10), self.targetVolume)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func fadeOut() {
        fadeTimer?.invalidate()
        fadeStartVolume = player?.volume ?? 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let newVolume = self.player?.volume ?? 0
            if newVolume > 0 {
                self.player?.volume = max(newVolume - (self.fadeStartVolume / 10), 0)
            } else {
                self.player?.pause()
                timer.invalidate()
            }
        }
    }
    
    func toggle() {
        let wasSelected = isSelected
        isSelected.toggle()
        
        if isSelected && !wasSelected {  // Only when turning ON
            // If we selected a new sound and the app is paused, start playing
            if !AudioManager.shared.isGloballyPlaying {
                AudioManager.shared.togglePlayback()
            } else {
                play()
            }
        } else {
            pause()
        }
    }

    deinit {
        fadeTimer?.invalidate()
        player?.stop()
        player = nil
        globalSettingsObserver?.cancel()
    }
}
