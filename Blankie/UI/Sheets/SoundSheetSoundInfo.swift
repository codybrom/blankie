//
//  SoundSheetSoundInfo.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

extension CleanSoundSheetForm {
  @ViewBuilder
  var soundInformationSection: some View {
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
          normalizationInfoRows(normInfo)
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
  }

  @ViewBuilder
  func normalizationInfoRows(_ normInfo: NormalizationInfo) -> some View {
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
}
