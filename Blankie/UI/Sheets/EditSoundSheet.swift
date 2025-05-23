//
//  EditSoundSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 5/22/25.
//

import SwiftData
import SwiftUI

struct EditSoundSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @Bindable var sound: CustomSoundData

  @State private var editedName: String
  @State private var editedIcon: String
  @State private var isProcessing = false

  // Popular SF Symbols for sounds
  private let popularSoundIcons = [
    "waveform.circle", "speaker.wave.2", "music.note", "ears", "waveform",
    "leaf", "drop", "wind", "flame", "bolt", "cloud.rain",
    "cloud.bolt.rain", "beach.umbrella", "tornado", "umbrella",
    "bubbles.and.sparkles", "light.max", "bird", "water.waves",
    "snowflake", "camera", "tv", "fireplace", "train.side.front.car",
    "seal", "airplane", "car", "clock", "bed.double", "fan",
  ]

  init(sound: CustomSoundData) {
    self.sound = sound
    _editedName = State(initialValue: sound.title)
    _editedIcon = State(initialValue: sound.systemIconName)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Sound Name", text: $editedName)
        } header: {
          Text("Display Name")
        }

        Section {
          LazyVGrid(
            columns: [
              GridItem(.adaptive(minimum: 44))
            ], spacing: 10
          ) {
            ForEach(popularSoundIcons, id: \.self) { iconName in
              Button {
                editedIcon = iconName
              } label: {
                Image(systemName: iconName)
                  .font(.system(size: 24))
                  .frame(width: 44, height: 44)
                  .background(editedIcon == iconName ? Color.accentColor.opacity(0.2) : Color.clear)
                  .clipShape(RoundedRectangle(cornerRadius: 8))
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(
                        editedIcon == iconName ? Color.accentColor : Color.clear, lineWidth: 2)
                  )
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.vertical, 8)
        } header: {
          Text("Icon")
        }
      }
      .navigationTitle("Edit Sound")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveChanges()
          }
          .disabled(
            editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
        }
      }
      .overlay {
        if isProcessing {
          ProgressView("Saving...")
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 10)
        }
      }
    }
    .frame(width: 400, height: 500)
  }

  private func saveChanges() {
    guard !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    isProcessing = true

    // Update the sound data
    sound.title = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    sound.systemIconName = editedIcon

    do {
      try modelContext.save()

      // Notify that a sound was updated
      NotificationCenter.default.post(name: .customSoundAdded, object: nil)

      // Dismiss the sheet
      dismiss()
    } catch {
      print("❌ EditSoundSheet: Failed to save changes: \(error)")
      isProcessing = false
    }
  }
}

#Preview {
  // Create a sample sound for preview
  let previewSound = CustomSoundData(
    title: "Sample Sound",
    systemIconName: "waveform",
    fileName: "sample",
    fileExtension: "mp3"
  )

  return EditSoundSheet(sound: previewSound)
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
