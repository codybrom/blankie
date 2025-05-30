//
//  SoundManagementView.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import SwiftData
import SwiftUI

struct SoundManagementView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query private var customSoundData: [CustomSoundData]
  @ObservedObject private var audioManager = AudioManager.shared

  @State private var showingImportSheet = false
  @State private var showingEditSheet = false
  @State private var selectedSound: CustomSoundData?
  @State private var selectedBuiltInSound: Sound?
  @State private var showingDeleteConfirmation = false

  private var builtInSounds: [Sound] {
    audioManager.sounds.filter { !($0 is CustomSound) }.sorted { $0.customOrder < $1.customOrder }
  }

  private var customSounds: [Sound] {
    audioManager.sounds.filter { $0 is CustomSound }.sorted { $0.customOrder < $1.customOrder }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        headerView
        Divider()
        mainContentView
      }
      .navigationTitle("Sound Management")
      #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingImportSheet) {
        SoundSheet(mode: .add)
      }
      .sheet(isPresented: $showingEditSheet) {
        if let sound = selectedSound {
          SoundSheet(mode: .edit(sound))
        } else if let builtInSound = selectedBuiltInSound {
          SoundSheet(mode: .customize(builtInSound))
        }
      }
      .alert(
        Text("Delete Sound", comment: "Delete sound confirmation alert title"),
        isPresented: $showingDeleteConfirmation
      ) {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
          if let sound = selectedSound {
            deleteSound(sound)
          }
        }
      } message: {
        Text(
          "Are you sure you want to delete '\(selectedSound?.title ?? "this sound")'? This action cannot be undone.",
          comment: "Delete custom sound confirmation message"
        )
      }
    }
  }

  private var headerView: some View {
    HStack {
      Text("Sound Management", comment: "Sound management view title")
        .font(.title2.bold())

      Spacer()

      HStack(spacing: 12) {
        Button {
          showingImportSheet = true
        } label: {
          Label("Import Sound", systemImage: "plus")
        }
        .buttonStyle(.borderedProminent)

        Button {
          dismiss()
        } label: {
          Text("Done", comment: "Sound management done button")
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
  }

  private var mainContentView: some View {
    ScrollView {
      VStack(spacing: 0) {
        builtInSoundsSection
        customSoundsSection
      }
      .padding(.vertical)
    }
    .background(listBackground)
  }

  @ViewBuilder
  private var builtInSoundsSection: some View {
    let hiddenCount = builtInSounds.filter { $0.isHidden }.count
    sectionHeader(
      title: "Built-in Sounds",
      subtitle: hiddenCount > 0 ? "\(builtInSounds.count) sounds (\(hiddenCount) hidden)" : "\(builtInSounds.count) sounds"
    )

    ForEach(Array(builtInSounds.enumerated()), id: \.element.id) { index, sound in
      builtInSoundRow(sound: sound, isLast: index == builtInSounds.count - 1)
    }

    Divider()
      .padding(.vertical, 8)
  }

  private var customSoundsSection: some View {
    VStack(spacing: 0) {
      let hiddenCount = customSounds.filter { $0.isHidden }.count
      sectionHeader(
        title: "Custom Sounds",
        subtitle: customSounds.isEmpty ? "No custom sounds" : hiddenCount > 0 ? "\(customSounds.count) sounds (\(hiddenCount) hidden)" : "\(customSounds.count) sounds"
      )

      if customSounds.isEmpty {
        customSoundsEmptyState
      } else {
        ForEach(Array(customSounds.enumerated()), id: \.element.id) { index, sound in
          if let customSound = sound as? CustomSound {
            customSoundRow(sound: customSound, isLast: index == customSounds.count - 1)
          }
        }
      }
    }
  }

  private func builtInSoundRow(sound: Sound, isLast: Bool) -> some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: sound.systemIconName)
          .font(.title2)
          .frame(width: 32)
          .foregroundStyle(sound.isHidden ? .secondary : .primary)

        VStack(alignment: .leading, spacing: 2) {
          HStack {
            Text(LocalizedStringKey(sound.title))
              .fontWeight(.medium)
              .foregroundColor(sound.isHidden ? .secondary : .primary)

            if SoundCustomizationManager.shared.getCustomization(for: sound.fileName)?.hasCustomizations == true {
              Image(systemName: "slider.horizontal.3")
                .font(.caption2)
                .foregroundColor(.accentColor)
            }
          }

          Text("Built-in sound")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        HStack(spacing: 8) {
          Button {
            selectedBuiltInSound = sound
            selectedSound = nil
            showingEditSheet = true
          } label: {
            Image(systemName: "slider.horizontal.3")
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help("Customize Sound")

          Button {
            withAnimation {
              if sound.isHidden {
                audioManager.showSound(sound)
              } else {
                audioManager.hideSound(sound)
              }
            }
          } label: {
            Image(systemName: sound.isHidden ? "eye.slash" : "eye")
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help(sound.isHidden ? "Show Sound" : "Hide Sound")
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background(
        Group {
          if sound.isHidden {
            hiddenSoundRowBackground
          } else {
            Color.clear
          }
        }
      )
      .contentShape(Rectangle())

      if !isLast {
        Divider()
          .padding(.leading, 60)
      }
    }
  }

  private func customSoundRow(sound: CustomSound, isLast: Bool) -> some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: sound.systemIconName)
          .font(.title2)
          .frame(width: 32)
          .foregroundStyle(sound.isHidden ? .secondary : .primary)

        VStack(alignment: .leading, spacing: 2) {
          Text(sound.title)
            .fontWeight(.medium)
            .foregroundColor(sound.isHidden ? .secondary : .primary)
          Text("Custom imported sound")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        HStack(spacing: 8) {
          Button {
            selectedSound = sound.customSoundData
            selectedBuiltInSound = nil
            showingEditSheet = true
          } label: {
            Image(systemName: "pencil")
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help("Edit Sound")

          Button {
            withAnimation {
              if sound.isHidden {
                audioManager.showSound(sound)
              } else {
                audioManager.hideSound(sound)
              }
            }
          } label: {
            Image(systemName: sound.isHidden ? "eye.slash" : "eye")
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help(sound.isHidden ? "Show Sound" : "Hide Sound")

          Button {
            selectedSound = sound.customSoundData
            showingDeleteConfirmation = true
          } label: {
            Image(systemName: "trash")
              .foregroundColor(.red)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .help("Delete Sound")
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background(
        Group {
          if sound.isHidden {
            hiddenSoundRowBackground
          } else {
            customSoundRowBackground
          }
        }
      )
      .contentShape(Rectangle())
      .contextMenu {
        Button("Edit Sound", systemImage: "pencil") {
          selectedSound = sound.customSoundData
          selectedBuiltInSound = nil
          showingEditSheet = true
        }

        Button(sound.isHidden ? "Show Sound" : "Hide Sound", systemImage: sound.isHidden ? "eye" : "eye.slash") {
          withAnimation {
            if sound.isHidden {
              audioManager.showSound(sound)
            } else {
              audioManager.hideSound(sound)
            }
          }
        }

        Button("Delete Sound", systemImage: "trash", role: .destructive) {
          selectedSound = sound.customSoundData
          showingDeleteConfirmation = true
        }
      }

      if !isLast {
        Divider()
          .padding(.leading, 60)
      }
    }
  }

  private func sectionHeader(title: String, subtitle: String) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.headline)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .background(.regularMaterial)
  }

  private var customSoundsEmptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "waveform.circle")
        .font(.system(size: 32))
        .foregroundColor(.secondary)

      Text("No Custom Sounds", comment: "Empty state title for custom sounds")
        .font(.headline)

      Text(
        "Import your own sounds to personalize your mix.",
        comment: "Empty state description for custom sounds"
      )
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .font(.caption)

      Button {
        showingImportSheet = true
      } label: {
        Text("Import Sound", comment: "Import sound button label")
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.small)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .padding(.horizontal)
    .background(customSoundRowBackground)
  }

  private var hiddenSoundRowBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.3)
      #else
        Color(UIColor.secondarySystemBackground).opacity(0.5)
      #endif
    }
  }

  private var builtInSoundRowBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.3)
      #else
        Color(UIColor.systemBackground).opacity(0.3)
      #endif
    }
  }

  private var customSoundRowBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.5)
      #else
        Color(UIColor.systemBackground).opacity(0.5)
      #endif
    }
  }

  private var listBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.textBackgroundColor)
      #else
        Color(UIColor.systemBackground)
      #endif
    }
  }

  private func deleteSound(_ sound: CustomSoundData) {
    let result = CustomSoundManager.shared.deleteCustomSound(sound)

    if case .failure(let error) = result {
      print("❌ SoundManagementView: Failed to delete custom sound: \(error)")
    }
  }
}

#Preview {
  SoundManagementView()
    .frame(width: 400, height: 600)
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
