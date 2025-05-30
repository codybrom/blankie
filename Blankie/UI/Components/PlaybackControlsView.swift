import SwiftUI

#if os(iOS) || os(visionOS)
  struct PlaybackControlsView: View {
    @Binding var showingVolumeControls: Bool
    @Binding var hideInactiveSounds: Bool

    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var globalSettings = GlobalSettings.shared

    var body: some View {
      VStack(spacing: 0) {
        Divider()

        HStack(spacing: 20) {
          // Volume button
          volumeButton

          // Timer button
          timerButton

          // Play/Pause button
          playPauseButton

          // Options button
          hideShowButton
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
      }
    }

    // Volume control button
    private var volumeButton: some View {
      Button(action: {
        showingVolumeControls.toggle()
      }) {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 22))
          .foregroundColor(.primary)
          .padding()
      }
    }

    // Play/pause button
    private var playPauseButton: some View {
      Button(action: {
        audioManager.togglePlayback()
      }) {
        ZStack {
          Circle()
            .fill(
              globalSettings.customAccentColor?.opacity(0.2) ?? Color.accentColor.opacity(0.2)
            )
            .frame(width: 60, height: 60)

          let imageName = audioManager.isGloballyPlaying ? "pause.fill" : "play.fill"
          let xOffset: CGFloat = audioManager.isGloballyPlaying ? 0 : 2

          Image(systemName: imageName)
            .font(.system(size: 26))
            .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
            .offset(x: xOffset)
        }
      }
    }

    // Hide/show inactive sounds button
    private var hideShowButton: some View {
      Button(action: {
        withAnimation {
          hideInactiveSounds.toggle()
        }
      }) {
        let iconName = hideInactiveSounds ? "eye.slash.fill" : "eye.fill"

        Image(systemName: iconName)
          .font(.system(size: 22))
          .foregroundColor(.primary)
          .padding()
      }
    }

    // Timer button
    private var timerButton: some View {
      CompactTimerButton()
        .padding()
    }
  }
#endif
