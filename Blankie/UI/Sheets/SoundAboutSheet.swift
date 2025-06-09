//
//  SoundAboutSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftData
import SwiftUI

struct SoundAboutSheet: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext
  @ObservedObject private var creditsManager = SoundCreditsManager.shared

  let sound: Sound

  @State private var editableCredits = EditableCredits()
  @State private var allowOthersToEdit = true
  @State private var allowOthersToReshare = true
  @State private var selectedLicense: License?

  var body: some View {
    Form {
      // Credits Section
      Section(header: Text("Credits")) {
        if sound.isCustom {
          editableCreditsView
        } else {
          builtInCreditsView
        }
      }

      if sound.isCustom {
        // Permissions Section (Custom Sounds Only)
        permissionsSection
      }

      // Combined Details Section
      detailsSection
    }
    .navigationTitle("About \(sound.title)")
    #if !os(macOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .onAppear {
      loadEditableCredits()
      // Ensure sound metadata is loaded
      if sound.channelCount == nil {
        sound.loadSound()
      }
    }
  }

  private var editableCreditsView: some View {
    Group {
      // Original Work Title
      HStack {
        Text("Original Work")
        Spacer()
        TextField("Title", text: $editableCredits.soundName)
          .multilineTextAlignment(.trailing)
          .textFieldStyle(.plain)
          .foregroundColor(.secondary)
      }

      // Author/Creator
      HStack {
        Text("Author")
        Spacer()
        TextField("Author name", text: $editableCredits.author)
          .multilineTextAlignment(.trailing)
          .textFieldStyle(.plain)
          .foregroundColor(.secondary)
      }

      // Source URL
      HStack {
        Text("Source URL")
        Spacer()
        TextField("https://...", text: $editableCredits.sourceUrl)
          .multilineTextAlignment(.trailing)
          .textFieldStyle(.plain)
          .foregroundColor(.secondary)
          #if !os(macOS)
            .keyboardType(.URL)
          #endif
      }

      // License
      Picker("License", selection: $selectedLicense) {
        Text("None").tag(nil as License?)
        ForEach(License.allCases, id: \.self) { license in
          Text(license.linkText).tag(license as License?)
        }
      }

      // Custom License Details
      if selectedLicense == .custom {
        VStack(alignment: .leading, spacing: 8) {
          Text("License Details")
          TextField(
            "Describe the license terms", text: $editableCredits.customLicenseText, axis: .vertical
          )
          .textFieldStyle(.plain)
          .foregroundColor(.secondary)
          .lineLimit(3...6)

          HStack {
            Text("License URL")
            Spacer()
            TextField("https://...", text: $editableCredits.customLicenseUrl)
              .multilineTextAlignment(.trailing)
              .textFieldStyle(.plain)
              .foregroundColor(.secondary)
              #if !os(macOS)
                .keyboardType(.URL)
              #endif
          }
        }
      }
    }
    .onChange(of: editableCredits) { _, _ in
      saveCredits()
    }
    .onChange(of: selectedLicense) { _, _ in
      saveCredits()
    }
  }

  private var builtInCreditsView: some View {
    Group {
      if let soundCredit = creditsManager.credits.first(where: { $0.name == sound.title }) {
        // Original Work
        HStack {
          Text("Original Work")
          Spacer()
          if let url = soundCredit.soundUrl {
            Link(soundCredit.soundName, destination: url)
              .foregroundColor(.accentColor)
          } else {
            Text(soundCredit.soundName)
              .foregroundColor(.secondary)
          }
        }

        // Author
        HStack {
          Text("Author")
          Spacer()
          Text(soundCredit.author)
            .foregroundColor(.secondary)
        }

        // License
        HStack {
          Text("License")
          Spacer()
          if let url = soundCredit.license.url {
            Link(soundCredit.license.linkText, destination: url)
              .foregroundColor(.accentColor)
          } else {
            Text(soundCredit.license.linkText)
              .foregroundColor(.secondary)
          }
        }
      }
    }
  }

  // MARK: - Permissions Section

  @ViewBuilder
  private var permissionsSection: some View {
    Section(
      header: Text("Sharing Permissions"),
      footer: Text(
        "In a future update these settings will allow you to control if others can edit a sound's credits or export this sound as a part of a preset."
      )
    ) {
      Toggle("Allow others to edit this sound", isOn: $allowOthersToEdit)
      Toggle("Allow others to re-share this sound", isOn: $allowOthersToReshare)
    }
  }

  // MARK: - Combined Details Section

  @ViewBuilder
  private var detailsSection: some View {
    Section(header: Text("Details")) {
      // Added date for custom sounds
      if sound.isCustom {
        HStack {
          Text("Added")
          Spacer()
          Text(
            DateFormatter.localizedString(
              from: sound.dateAdded ?? Date(), dateStyle: .medium, timeStyle: .none)
          )
          .foregroundColor(.secondary)
        }
      }

      // Duration
      if let duration = sound.duration {
        HStack {
          Text("Duration")
          Spacer()
          Text(getDurationText(from: duration))
            .foregroundColor(.secondary)
        }
      }

      // Channels
      if let channels = sound.channelCount {
        HStack {
          Text("Channels")
          Spacer()
          Text(getChannelsText(from: channels))
            .foregroundColor(.secondary)
        }
      }

      // Format and File Size only for custom sounds
      if sound.isCustom {
        HStack {
          Text("Format")
          Spacer()
          Text(sound.fileExtension.uppercased())
            .foregroundColor(.secondary)
        }

        if let fileSize = sound.fileSize {
          HStack {
            Text("File Size")
            Spacer()
            Text(getFileSizeText(from: fileSize))
              .foregroundColor(.secondary)
          }
        }
      }

      // LUFS
      if let lufs = sound.lufs {
        HStack {
          Text("LUFS")
          Spacer()
          Text(String(format: "%.1f", lufs))
            .foregroundColor(.secondary)
        }
      }

      // Normalization Factor with Gain on same line
      if let normalizationFactor = sound.normalizationFactor {
        let gainDB = 20 * log10(normalizationFactor)
        HStack {
          Text("Normalization Factor")
          Spacer()
          Text(String(format: "%.2fx (%+.1fdB)", normalizationFactor, gainDB))
            .foregroundColor(.secondary)
        }
      }
    }
  }

  // MARK: - Helper Methods

  private func getChannelsText(from channels: Int) -> String {
    switch channels {
    case 1:
      return "Mono"
    case 2:
      return "Stereo"
    default:
      return "\(channels) (Multichannel)"
    }
  }

  private func getDurationText(from duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  private func getFileSizeText(from fileSize: Int64) -> String {
    let formatter = ByteCountFormatter()
    return formatter.string(fromByteCount: fileSize)
  }

  private func loadEditableCredits() {
    // Load existing credits for custom sounds
    if sound.isCustom {
      // Try to load from CustomSoundData first
      if let customSoundDataID = sound.customSoundDataID,
        let customSoundData = try? modelContext.fetch(
          FetchDescriptor<CustomSoundData>(
            predicate: #Predicate { $0.id == customSoundDataID }
          )
        ).first
      {
        // Use ID3 title first, then fall back to original filename
        editableCredits.soundName =
          customSoundData.id3Title ?? customSoundData.originalFileName ?? ""

        // Use ID3 artist first, then fall back to creditAuthor
        editableCredits.author = customSoundData.creditAuthor ?? customSoundData.id3Artist ?? ""

        // Use creditSourceUrl first, then fall back to ID3 URL
        editableCredits.sourceUrl = customSoundData.creditSourceUrl ?? customSoundData.id3Url ?? ""

        // Convert license type string to License enum
        if !customSoundData.creditLicenseType.isEmpty,
          let license = License(rawValue: customSoundData.creditLicenseType)
        {
          selectedLicense = license
        } else {
          selectedLicense = nil
        }

        editableCredits.customLicenseText = customSoundData.creditCustomLicenseText ?? ""
        editableCredits.customLicenseUrl = customSoundData.creditCustomLicenseUrl ?? ""
        allowOthersToEdit = customSoundData.allowOthersToEdit
        allowOthersToReshare = customSoundData.allowOthersToReshare
      }
    }
  }

  private func saveCredits() {
    // Save credits to CustomSoundData
    if sound.isCustom,
      let customSoundDataID = sound.customSoundDataID
    {

      do {
        let customSoundData = try modelContext.fetch(
          FetchDescriptor<CustomSoundData>(
            predicate: #Predicate { $0.id == customSoundDataID }
          )
        ).first

        if let data = customSoundData {
          // Update with new credit information
          data.originalFileName =
            editableCredits.soundName.isEmpty ? data.originalFileName : editableCredits.soundName
          data.creditAuthor = editableCredits.author.isEmpty ? nil : editableCredits.author
          data.creditSourceUrl = editableCredits.sourceUrl.isEmpty ? nil : editableCredits.sourceUrl
          data.creditLicenseType = selectedLicense?.rawValue ?? ""
          data.creditCustomLicenseText =
            editableCredits.customLicenseText.isEmpty ? nil : editableCredits.customLicenseText
          data.creditCustomLicenseUrl =
            editableCredits.customLicenseUrl.isEmpty ? nil : editableCredits.customLicenseUrl
          data.allowOthersToEdit = allowOthersToEdit
          data.allowOthersToReshare = allowOthersToReshare

          try modelContext.save()
        }
      } catch {
        print("Error saving credits: \(error)")
      }
    }
  }

}

// MARK: - Supporting Models

struct EditableCredits: Equatable {
  var soundName = ""
  var author = ""
  var sourceUrl = ""
  var customLicenseText = ""
  var customLicenseUrl = ""
}

// MARK: - Previews

#Preview("Built-in Sound") {
  let sound = Sound(
    title: "Rain",
    systemIconName: "cloud.rain",
    fileName: "rain",
    fileExtension: "m4a",
    defaultOrder: 1,
    lufs: -23.0,
    normalizationFactor: 1.0
  )

  SoundAboutSheet(sound: sound)
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}

#Preview("Custom Sound") {
  let customData = CustomSoundData(
    title: "My Custom Sound",
    systemIconName: "waveform.circle",
    fileName: "custom_sound",
    fileExtension: "m4a"
  )

  let sound = Sound(
    title: "My Custom Sound",
    systemIconName: "waveform.circle",
    fileName: "custom_sound",
    fileExtension: "m4a",
    isCustom: true,
    customSoundDataID: customData.id
  )

  SoundAboutSheet(sound: sound)
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
