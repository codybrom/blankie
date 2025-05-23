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
        Text("Custom Sounds")
          .font(.title2.bold())

        Spacer()

        HStack(spacing: 12) {
          Button {
            showingImportSheet = true
          } label: {
            Label("Import Sound", systemImage: "plus")
          }
          .buttonStyle(.borderedProminent)

          Button("Done") {
            dismiss()
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
    .alert("Delete Sound", isPresented: $showingDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let sound = selectedSound {
          deleteSound(sound)
        }
      }
    } message: {
      Text(
        "Are you sure you want to delete \"\(selectedSound?.title ?? "this sound")\"? This cannot be undone."
      )
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "waveform.circle")
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text("No Custom Sounds")
        .font(.title3.bold())

      Text("Import your own sounds to personalize your mix.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button {
        showingImportSheet = true
      } label: {
        Text("Import Sound")
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
              .help("Edit sound")

              Button {
                selectedSound = sound
                showingDeleteConfirmation = true
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .help("Delete sound")
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 12)
          .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
          .contentShape(Rectangle())
          .contextMenu {
            Button("Edit", systemImage: "pencil") {
              selectedSound = sound
              showingEditSheet = true
            }

            Button("Delete", systemImage: "trash", role: .destructive) {
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
    .background(Color(NSColor.textBackgroundColor))
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
