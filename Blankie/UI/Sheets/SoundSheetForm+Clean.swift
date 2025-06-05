//
//  SoundSheetForm+Clean.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import SwiftUI

struct CleanSoundSheetForm: View {
  let mode: SoundSheetMode
  @Binding var soundName: String
  @Binding var selectedIcon: String
  @Binding var selectedFile: URL?
  @Binding var isImporting: Bool
  @Binding var selectedColor: AccentColor?
  @Binding var randomizeStartPosition: Bool
  @Binding var normalizeAudio: Bool
  @Binding var volumeAdjustment: Float
  @Binding var isPreviewing: Bool
  @Binding var previewSound: Sound?

  @ObservedObject private var globalSettings = GlobalSettings.shared
  @State private var showingIconPicker = false

  var body: some View {
    NavigationStack {
      Form {
        // File selection (only for add mode)
        if case .add = mode {
          Section {
            SoundFileSelector(
              selectedFile: $selectedFile,
              soundName: $soundName,
              isImporting: $isImporting
            )
          }
        }

        // Basic Information
        Section {
          // Name
          HStack {
            Text("Name", comment: "Display name field label")
            Spacer()
            TextField(text: $soundName) {
              Text("Sound Name", comment: "Sound name text field placeholder")
            }
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.plain)
          }

          // Icon
          Button {
            showingIconPicker = true
          } label: {
            HStack {
              Text("Icon", comment: "Icon selection label")
              Spacer()
              Image(systemName: selectedIcon)
                .font(.title3)
                .foregroundStyle(.tint)
              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
          }
          .buttonStyle(.plain)

          // Color (for customize and edit modes)
          switch mode {
          case .customize, .edit:
            ColorPickerRow(selectedColor: $selectedColor)
          case .add:
            EmptyView()
          }
        }

        // Audio Processing
        Section(header: Text("Audio", comment: "Audio options section header")) {
          Toggle(isOn: $randomizeStartPosition) {
            Text(
              "Randomize Start Position",
              comment: "Toggle label for randomizing sound start position"
            )
          }
          .tint(globalSettings.customAccentColor ?? .accentColor)

          Toggle(isOn: $normalizeAudio) {
            VStack(alignment: .leading, spacing: 2) {
              Text(
                "Sound Check",
                comment: "Toggle label for Sound Check (audio normalization)"
              )
              Text(
                "Sound Check adjusts the loudness between different sounds to play at the same volume.",
                comment: "Description for Sound Check toggle"
              )
              .font(.caption)
              .foregroundColor(.secondary)
            }
          }
          .tint(globalSettings.customAccentColor ?? .accentColor)

          // Volume Adjustment (only visible when normalization is OFF)
          if !normalizeAudio {
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Text("Volume Adjustment", comment: "Volume adjustment field label")
                Spacer()
                Text(volumePercentageText)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              HStack {
                Text("-50%", comment: "Volume decrease label")
                  .font(.caption)
                  .foregroundColor(.secondary)

                Slider(value: $volumeAdjustment, in: 0.5...8.0, step: 0.01)
                  .tint(globalSettings.customAccentColor ?? .accentColor)

                Text("+700%", comment: "Volume increase label")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }

        // Sound Information Section
        if let soundInfo = getSoundInfo() {
          Section(header: Text("Sound Information", comment: "Sound information section header")) {
            // Channels
            HStack {
              Text("Channels", comment: "Audio channels label")
              Spacer()
              Text(soundInfo.channelsText)
                .foregroundColor(.secondary)
            }

            // Duration
            HStack {
              Text("Duration", comment: "Audio duration label")
              Spacer()
              Text(soundInfo.durationText)
                .foregroundColor(.secondary)
            }

            // File Size
            HStack {
              Text("File Size", comment: "File size label")
              Spacer()
              Text(soundInfo.fileSizeText)
                .foregroundColor(.secondary)
            }

            // File Format
            HStack {
              Text("Format", comment: "File format label")
              Spacer()
              Text(soundInfo.formatText)
                .foregroundColor(.secondary)
            }

            // Normalization Data (if available)
            if let normInfo = getNormalizationInfo() {
              // LUFS (if available)
              if let lufs = normInfo.lufs {
                HStack {
                  Text("Loudness (LUFS)", comment: "Audio LUFS loudness label")
                  Spacer()
                  Text(lufs)
                    .foregroundColor(.secondary)
                }
              }

              // Peak Level (if available)
              if let peak = normInfo.peak {
                HStack {
                  Text("Peak Level", comment: "Audio peak level label")
                  Spacer()
                  Text(peak)
                    .foregroundColor(.secondary)
                }
              }

              // Normalization Factor
              HStack {
                Text("Normalization Factor", comment: "Audio normalization factor label")
                Spacer()
                Text(normInfo.factor)
                  .foregroundColor(.secondary)
              }

              // Normalization Gain in dB
              HStack {
                Text("Normalization Gain", comment: "Audio normalization gain label")
                Spacer()
                Text(normInfo.gain)
                  .foregroundColor(.secondary)
              }
            }

            // Credited Author (if available)
            if let author = soundInfo.creditedAuthor {
              HStack {
                Text("Author", comment: "Sound author label")
                Spacer()
                Text(author)
                  .foregroundColor(.secondary)
              }
            }

            // Description (if available)
            if let description = soundInfo.description {
              VStack(alignment: .leading, spacing: 4) {
                Text("Description", comment: "Sound description label")
                Text(description)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }

        // Preview Section
        Section {
          Button(action: togglePreview) {
            HStack {
              Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
              Text(isPreviewing ? "Stop Preview" : "Preview Sound")
            }
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
          .frame(maxWidth: .infinity)
        }
      }
      .sheet(isPresented: $showingIconPicker) {
        NavigationStack {
          IconPickerView(selectedIcon: $selectedIcon)
        }
      }
    }
    #if os(macOS)
      .frame(minHeight: 500)
    #endif
  }
}

struct ColorPickerRow: View {
  @Binding var selectedColor: AccentColor?
  @ObservedObject private var globalSettings = GlobalSettings.shared

  var currentColor: Color {
    if let selectedColor = selectedColor, let color = selectedColor.color {
      return color
    }
    return globalSettings.customAccentColor ?? .accentColor
  }

  var body: some View {
    NavigationLink(destination: ColorPickerPage(selectedColor: $selectedColor)) {
      HStack {
        Text("Color", comment: "Color picker label")
        Spacer()
        Circle()
          .fill(currentColor)
          .frame(width: 20, height: 20)
      }
    }
  }
}

struct ColorPickerPage: View {
  @Binding var selectedColor: AccentColor?
  @ObservedObject private var globalSettings = GlobalSettings.shared
  @Environment(\.dismiss) private var dismiss

  private let columns = [
    GridItem(.adaptive(minimum: 44))
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LazyVGrid(columns: columns, spacing: 16) {
          // Default option - use theme color
          Button(action: {
            selectedColor = nil
            dismiss()
          }) {
            VStack {
              ZStack {
                Circle()
                  .fill(globalSettings.customAccentColor ?? .accentColor)
                  .frame(width: 44, height: 44)

                if selectedColor == nil {
                  Image(systemName: "checkmark")
                    .foregroundColor(.white)
                }
              }

              Text("Theme", comment: "Theme color option")
                .font(.caption)
            }
          }
          .buttonStyle(.plain)

          // Color options
          ForEach(AccentColor.allCases.dropFirst(), id: \.self) { colorOption in
            Button(action: {
              selectedColor = colorOption
              dismiss()
            }) {
              VStack {
                ZStack {
                  Circle()
                    .fill(colorOption.color ?? .accentColor)
                    .frame(width: 44, height: 44)

                  if selectedColor == colorOption {
                    Image(systemName: "checkmark")
                      .foregroundColor(.white)
                  }
                }

                Text(colorOption.name)
                  .font(.caption)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
      }
    }
    .navigationTitle("Color")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
  }
}

// MARK: - Helper Extensions

extension CleanSoundSheetForm {
  var textColorForCurrentTheme: Color {
    let color = globalSettings.customAccentColor ?? .accentColor
    #if os(macOS)
      if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
        let brightness =
          (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
          + (0.114 * nsColor.blueComponent)
        return brightness > 0.5 ? .black : .white
      } else {
        return .white
      }
    #else
      return .white
    #endif
  }

  func textColorForAccentColor(_ accentColor: AccentColor) -> Color {
    guard let color = accentColor.color else { return .white }
    #if os(macOS)
      if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
        let brightness =
          (0.299 * nsColor.redComponent) + (0.587 * nsColor.greenComponent)
          + (0.114 * nsColor.blueComponent)
        return brightness > 0.5 ? .black : .white
      } else {
        return .white
      }
    #else
      return .white
    #endif
  }

  var volumePercentageText: String {
    let percentage = Int((volumeAdjustment - 1.0) * 100)
    if percentage > 0 {
      return "+\(percentage)%"
    } else if percentage < 0 {
      return "\(percentage)%"
    } else {
      return "0%"
    }
  }

  func togglePreview() {
    if isPreviewing {
      stopPreview()
    } else {
      startPreview()
    }
  }

  func startPreview() {
    // This will be implemented in the parent view
    isPreviewing = true
  }

  func stopPreview() {
    // This will be implemented in the parent view
    isPreviewing = false
  }

  func updatePreviewVolume() {
    // This will be implemented in the parent view
  }

  struct NormalizationInfo {
    let lufs: String?
    let peak: String?
    let gain: String
    let factor: String
  }

  func getNormalizationInfo() -> NormalizationInfo? {
    switch mode {
    case .edit(let customSound):
      var lufsStr: String?
      var peakStr: String?
      var normFactor: Float = 1.0

      // Get LUFS if available
      if let lufs = customSound.detectedLUFS {
        lufsStr = String(format: "%.1f LUFS", lufs)
        normFactor =
          customSound.normalizationFactor
          ?? AudioAnalyzer.calculateLUFSNormalizationFactor(lufs: lufs)
      }

      // Get peak level
      if let peakLevel = customSound.detectedPeakLevel {
        let percentage = Int(peakLevel * 100)
        peakStr = "\(percentage)%"
        if normFactor == 1.0 {
          normFactor = AudioAnalyzer.calculateNormalizationFactor(peakLevel: peakLevel)
        }
      }

      let gainDB = 20 * log10(normFactor)
      return NormalizationInfo(
        lufs: lufsStr,
        peak: peakStr,
        gain: String(format: "%+.1fdB", gainDB),
        factor: String(format: "%.2fx", normFactor)
      )

    case .customize(let sound):
      var lufsStr: String?

      if let lufs = sound.lufs {
        lufsStr = String(format: "%.1f LUFS", lufs)
      }

      let normFactor = sound.normalizationFactor ?? 1.0
      let gainDB = 20 * log10(normFactor)

      return NormalizationInfo(
        lufs: lufsStr,
        peak: nil,
        gain: String(format: "%+.1fdB", gainDB),
        factor: String(format: "%.2fx", normFactor)
      )

    case .add:
      return nil
    }
  }

  struct SoundInfo {
    let channelsText: String
    let durationText: String
    let fileSizeText: String
    let formatText: String
    let creditedAuthor: String?
    let description: String?
  }

  func getSoundInfo() -> SoundInfo? {
    switch mode {
    case .edit(let customSound):
      if let sound = AudioManager.shared.sounds.first(where: {
        $0.customSoundDataID == customSound.id
      }) {
        // Ensure metadata is loaded
        if sound.channelCount == nil {
          sound.loadSound()
        }

        let channelsText: String
        if let channels = sound.channelCount {
          switch channels {
          case 1:
            channelsText = "Mono"
          case 2:
            channelsText = "Stereo"
          default:
            channelsText = "\(channels) (Multichannel)"
          }
        } else {
          channelsText = "Unknown"
        }

        let durationText: String
        if let duration = sound.duration {
          let minutes = Int(duration) / 60
          let seconds = Int(duration) % 60
          durationText = String(format: "%d:%02d", minutes, seconds)
        } else {
          durationText = "Unknown"
        }

        let fileSizeText: String
        if let fileSize = sound.fileSize {
          let formatter = ByteCountFormatter()
          fileSizeText = formatter.string(fromByteCount: fileSize)
        } else {
          fileSizeText = "Unknown"
        }

        let formatText = sound.fileFormat ?? "Unknown"

        // For custom sounds, there's no author or description from credits
        return SoundInfo(
          channelsText: channelsText,
          durationText: durationText,
          fileSizeText: fileSizeText,
          formatText: formatText,
          creditedAuthor: nil,
          description: nil
        )
      }
    case .customize(let sound):
      // Ensure metadata is loaded
      if sound.channelCount == nil {
        sound.loadSound()
      }

      let channelsText: String
      if let channels = sound.channelCount {
        switch channels {
        case 1:
          channelsText = "Mono"
        case 2:
          channelsText = "Stereo"
        default:
          channelsText = "\(channels) (Multichannel)"
        }
      } else {
        channelsText = "Unknown"
      }

      let durationText: String
      if let duration = sound.duration {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        durationText = String(format: "%d:%02d", minutes, seconds)
      } else {
        durationText = "Unknown"
      }

      let fileSizeText: String
      if let fileSize = sound.fileSize {
        let formatter = ByteCountFormatter()
        fileSizeText = formatter.string(fromByteCount: fileSize)
      } else {
        fileSizeText = "Unknown"
      }

      let formatText = sound.fileFormat ?? "Unknown"

      // Get credits and description if available
      let creditedAuthor = SoundCreditsManager.shared.getAuthor(for: sound.originalTitle)
      let description = SoundCreditsManager.shared.getDescription(for: sound.originalTitle)

      return SoundInfo(
        channelsText: channelsText,
        durationText: durationText,
        fileSizeText: fileSizeText,
        formatText: formatText,
        creditedAuthor: creditedAuthor,
        description: description
      )
    case .add:
      return nil
    }
    return nil
  }
}
