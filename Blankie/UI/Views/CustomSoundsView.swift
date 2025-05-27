//
//  CustomSoundsView.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import SwiftData
import SwiftUI

struct CustomSoundsView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query private var customSounds: [CustomSoundData]
  @State private var showingImportSheet = false
  @State private var showingEditSheet = false
  @State private var selectedSound: CustomSoundData?
  @State private var showingDeleteConfirmation = false

  var body: some View {
    VStack(spacing: 0) {
      // Header with title and buttons
      HStack {
        Text("Custom Sounds", comment: "Custom sounds view title")
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
            Text("Done", comment: "Custom sounds done button")
          }
          .buttonStyle(.bordered)
        }
      }
      .padding()

      Divider()

      if customSounds.isEmpty {
        emptyStateView
      } else {
        customSoundsList
      }
    }
    .sheet(isPresented: $showingImportSheet) {
      ImportSoundSheet()
    }
    .sheet(isPresented: $showingEditSheet) {
      if let sound = selectedSound {
        EditSoundSheet(sound: sound)
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

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.circle")
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text("No Custom Sounds", comment: "Empty state title for custom sounds")
        .font(.title3.bold())

      Text(
        "Import your own sounds to personalize your mix.",
        comment: "Empty state description for custom sounds"
      )
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal)

      Button {
        showingImportSheet = true
      } label: {
        Text("Import Sound", comment: "Import sound button label")
          .padding(.horizontal)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .padding(.top, 8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var customSoundsList: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(customSounds) { sound in
          HStack {
            Image(systemName: sound.systemIconName)
              .font(.title2)
              .frame(width: 32)
              .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
              Text(sound.title)
                .fontWeight(.medium)
              Text(sound.originalFileName ?? sound.fileName)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
              Button {
                selectedSound = sound
                showingEditSheet = true
              } label: {
                Image(systemName: "pencil")
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .help("Edit Sound")

              Button {
                selectedSound = sound
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
              #if os(macOS)
                Color(NSColor.controlBackgroundColor).opacity(0.5)
              #else
                Color(UIColor.systemBackground).opacity(0.5)
              #endif
            }
          )
          .contentShape(Rectangle())
          .contextMenu {
            Button("Edit Sound", systemImage: "pencil") {
              selectedSound = sound
              showingEditSheet = true
            }

            Button("Delete Sound", systemImage: "trash", role: .destructive) {
              selectedSound = sound
              showingDeleteConfirmation = true
            }
          }

          if sound != customSounds.last {
            Divider()
              .padding(.leading, 60)
          }
        }
      }
      .padding(.vertical)
    }
    .background(
      Group {
        #if os(macOS)
          Color(NSColor.textBackgroundColor)
        #else
          Color(UIColor.systemBackground)
        #endif
      }
    )
  }

  private func deleteSound(_ sound: CustomSoundData) {
    let result = CustomSoundManager.shared.deleteCustomSound(sound)

    if case .failure(let error) = result {
      print("❌ CustomSoundsView: Failed to delete custom sound: \(error)")
    }
  }
}

#Preview {
  CustomSoundsView()
    .frame(width: 400, height: 500)
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
