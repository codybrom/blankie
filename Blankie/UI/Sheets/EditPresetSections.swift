//
//  EditPresetSections.swift
//  Blankie
//
//  Created by Cody Bromley on 6/11/25.
//

import SwiftUI

// MARK: - Default Preset Section
extension EditPresetSheet {
  var defaultPresetSection: some View {
    Section("Preset Information") {
      LabeledContent("Name", value: "All Sounds")
      Text("The default preset cannot be modified")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Now Playing Section (Name, Creator & Artwork)
extension EditPresetSheet {
  var nowPlayingInfoSection: some View {
    Section("Now Playing") {
      // Name field
      LabeledContent("Name") {
        TextField("Required", text: $presetName)
          .multilineTextAlignment(.trailing)
          .onChange(of: presetName) { _, _ in
            applyChangesInstantly()
          }
      }

      // Creator field
      LabeledContent("Creator") {
        TextField("Optional", text: $creatorName)
          .multilineTextAlignment(.trailing)
          .onChange(of: creatorName) { _, _ in
            applyChangesInstantly()
          }
      }

      // Artwork field
      Button {
        showingImagePicker = true
      } label: {
        LabeledContent("Artwork") {
          artworkPreview
        }
      }
      .buttonStyle(.plain)
    }
    .onChange(of: artworkData) { _, _ in
      applyChangesInstantly()
    }
  }
}

// MARK: - Error Section
extension EditPresetSheet {
  @ViewBuilder
  var errorSection: some View {
    if let error = error {
      Section {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
      }
    }
  }
}

// MARK: - Basic Info Section (deprecated - use nowPlayingInfoSection)
extension EditPresetSheet {
  var basicInfoSection: some View {
    nowPlayingInfoSection
  }
}

// MARK: - Creator Section (deprecated - now part of nowPlayingInfoSection)
extension EditPresetSheet {
  var creatorSection: some View {
    EmptyView()
  }
}

// MARK: - Artwork Section (deprecated - now part of nowPlayingInfoSection)
extension EditPresetSheet {
  var artworkSection: some View {
    EmptyView()
  }
}

// MARK: - Artwork Preview
extension EditPresetSheet {
  @ViewBuilder
  var artworkPreview: some View {
    if let artworkData = artworkData {
      #if os(iOS) || os(visionOS)
        if let uiImage = UIImage(data: artworkData) {
          Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      #elseif os(macOS)
        if let nsImage = NSImage(data: artworkData) {
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      #endif
    } else {
      Text("Select Image")
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - Sounds Section
extension EditPresetSheet {
  var soundsSection: some View {
    Section {
      #if os(iOS)
        Button {
          showingSoundSelection = true
        } label: {
          LabeledContent("Sounds") {
            HStack {
              Text("\(selectedSounds.count) Selected")
                .foregroundStyle(.secondary)
              Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .imageScale(.small)
            }
          }
        }
        .buttonStyle(.plain)
      #else
        NavigationLink(
          destination: SoundSelectionView(
            selectedSounds: $selectedSounds, orderedSounds: orderedSounds)
        ) {
          LabeledContent("Sounds") {
            Text("\(selectedSounds.count) Selected")
              .foregroundStyle(.secondary)
          }
        }
      #endif
    }
    .onChange(of: selectedSounds) { _, _ in
      applyChangesInstantly()
    }
  }
}

// MARK: - Delete Section
extension EditPresetSheet {
  @ViewBuilder
  var deleteSection: some View {
    Section {
      Button(role: .destructive) {
        presetToDelete = preset
      } label: {
        HStack {
          Spacer()
          Text("Delete Preset")
          Spacer()
        }
      }
    }
  }
}
