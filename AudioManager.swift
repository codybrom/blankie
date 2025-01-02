//
//  AudioManager.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//


import SwiftUI
import AVFoundation
import Combine
import MediaPlayer

// First, declare the Error types and ErrorReporter at the top
enum AudioError: Error, LocalizedError {
    case fileNotFound
    case loadFailed(Error)
    case playbackFailed(Error)
    case invalidVolume
    case systemAudioError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file could not be found"
        case .loadFailed(let error):
            return "Failed to load audio: \(error.localizedDescription)"
        case .playbackFailed(let error):
            return "Playback failed: \(error.localizedDescription)"
        case .invalidVolume:
            return "Invalid volume level specified"
        case .systemAudioError(let message):
            return "System audio error: \(message)"
        }
    }
}

class ErrorReporter: ObservableObject {
    static let shared = ErrorReporter()
    @Published var lastError: Error?
    
    func report(_ error: Error) {
        DispatchQueue.main.async {
            self.lastError = error
            #if DEBUG
            print("Error reported: \(error.localizedDescription)")
            #endif
        }
    }
}

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

// AudioManager class
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    var onReset: (() -> Void)?
    
    @Published var sounds: [Sound] = []
    @Published var isGloballyPlaying: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.set(self.isGloballyPlaying, forKey: "isGloballyPlaying")
                
                if self.isGloballyPlaying {
                    self.playSelected()
                } else {
                    self.pauseAll()
                }
            }
        }
    }
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var nowPlayingInfo: [String: Any] = [:]

    private init() {
        loadSounds()
        loadSavedState()
        setupMediaControls()
        setupNowPlaying()
        setupNotificationObservers()
        
        // Handle autoplay behavior
        if !GlobalSettings.shared.alwaysStartPaused {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let hasSelectedSounds = self.sounds.contains { $0.isSelected }
                self.isGloballyPlaying = hasSelectedSounds
                if hasSelectedSounds {
                    self.updateNowPlayingInfo()
                }
            }
        }
    }

    private func loadSounds() {
        sounds = [
            Sound(title: "Rain",         systemIconName: "cloud.rain",         fileName: "rain"),
            Sound(title: "Storm",        systemIconName: "cloud.bolt.rain",    fileName: "storm"),
            Sound(title: "Wind",         systemIconName: "wind",               fileName: "wind"),
            Sound(title: "Waves",        systemIconName: "water.waves",        fileName: "waves"),
            Sound(title: "Stream",       systemIconName: "humidity",           fileName: "stream"),
            Sound(title: "Birds",        systemIconName: "bird",               fileName: "birds"),
            Sound(title: "Summer Night", systemIconName: "moon.stars.fill",    fileName: "summer-night"),
            Sound(title: "Train",        systemIconName: "tram.fill",          fileName: "train"),
            Sound(title: "Boat",         systemIconName: "sailboat.fill",      fileName: "boat"),
            Sound(title: "City",         systemIconName: "building.2",         fileName: "city"),
            Sound(title: "Coffee Shop",  systemIconName: "cup.and.saucer.fill", fileName: "coffee-shop"),
            Sound(title: "Fireplace",    systemIconName: "fireplace",          fileName: "fireplace"),
            Sound(title: "Pink Noise",   systemIconName: "waveform.path",      fileName: "pink-noise"),
            Sound(title: "White Noise",  systemIconName: "waveform",           fileName: "white-noise"),
        ]
    }

    private func setupMediaControls() {
        // Remove all previous handlers
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        
        // Add handlers
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayback()
            return .success
        }
    }
    
    private func playSelected() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for sound in self.sounds where sound.isSelected {
                sound.play()
            }
            self.updateNowPlayingInfo()
        }
    }

    private func loadSavedState() {
        guard let state = UserDefaults.standard.array(forKey: "soundState") as? [[String: Any]] else {
            return
        }
        
        for savedState in state {
            guard let fileName = savedState["fileName"] as? String,
                  let sound = sounds.first(where: { $0.fileName == fileName }) else {
                continue
            }
            
            sound.isSelected = savedState["isSelected"] as? Bool ?? false
            sound.volume = savedState["volume"] as? Float ?? 1.0
        }
    }
    
    private func setupNowPlaying() {
        // Set up now playing info
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"
        
//        // Optional: Add artwork
//        if let image = NSImage(named: "AppIcon"), // Use your app icon or custom artwork
//           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
//            let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
//                NSImage(cgImage: cgImage, size: size)
//            }
//            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
//        }
        
        updatePlaybackState()
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Ambient Sounds"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Blankie"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isGloballyPlaying ? 1.0 : 0.0
        
        // Add app icon as artwork
        if let image = NSImage(named: "AppIcon"),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
                NSImage(cgImage: cgImage, size: size)
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    
    private func updatePlaybackState() {
        // Update playback state
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isGloballyPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0 // Infinite for ambient sounds
        
        // Update the now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppTermination()
        }
    }
    
    private func handleAppTermination() {
        cleanup()
    }
    
    private func cleanup() {
        pauseAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func pauseAll() {
        for sound in sounds {
            sound.pause()
        }
        updateNowPlayingInfo() // Add this line
    }

    func saveState() {
        let state = sounds.map { sound in
            [
                "id": sound.id.uuidString,
                "fileName": sound.fileName,
                "isSelected": sound.isSelected,
                "volume": sound.volume
            ]
        }
        UserDefaults.standard.set(state, forKey: "soundState")
    }

    
    /// Toggles the playback state of all selected sounds
    /// - Parameter completion: Optional completion handler
    public func togglePlayback(completion: ((Result<Void, AudioError>) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isGloballyPlaying.toggle()
            self.updateNowPlayingInfo()
            completion?(.success(()))
        }
    }

    func resetSounds() {
        // First pause all sounds immediately
        sounds.forEach { sound in
            sound.pause(immediate: true)
        }
        
        isGloballyPlaying = false
        
        // Reset all sounds
        sounds.forEach { sound in
            sound.volume = 1.0
            sound.isSelected = false
        }
        
        // Reset global volume using the setter method
        GlobalSettings.shared.setVolume(1.0)
        
        // Call the reset callback
        onReset?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanup()
    }
}

struct AudioErrorHandler: ViewModifier {
    @ObservedObject private var errorReporter = ErrorReporter.shared
    @State private var showingError = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: errorReporter.lastError != nil) { hasError in
                showingError = hasError
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorReporter.lastError = nil
                }
            } message: {
                if let error = errorReporter.lastError {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func handleAudioErrors() -> some View {
        self.modifier(AudioErrorHandler())
    }
}




