//
//  SoundSheetBasicInfo.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

extension CleanSoundSheetForm {
  @ViewBuilder
  var basicInformationSection: some View {
    Section {
      // Name
      nameRow

      // Icon
      iconRow

      // Color (for customize and edit modes)
      switch mode {
      case .customize, .edit:
        ColorPickerRow(selectedColor: $selectedColor)
        aboutRow
      case .add:
        EmptyView()
      }
    }
  }

  @ViewBuilder
  var nameRow: some View {
    HStack {
      Text("Name", comment: "Display name field label")
      Spacer()
      HStack {
        TextField(text: $soundName) {
          Text("Sound Name", comment: "Sound name text field placeholder")
        }
        .multilineTextAlignment(.trailing)
        .textFieldStyle(.plain)
        #if os(iOS)
          .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
              Spacer()
              Button("Done") {
                UIApplication.shared.sendAction(
                  #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
              }
            }
          }
        #endif

        if !soundName.isEmpty {
          Button {
            soundName = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
              .imageScale(.small)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  var iconRow: some View {
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
  }

  @ViewBuilder
  var aboutRow: some View {
    if let currentSound = getCurrentSound() {
      NavigationLink(destination: SoundAboutSheet(sound: currentSound)) {
        HStack {
          Text("About & Sharing", comment: "About and sharing button label")
          Spacer()
        }
      }
    }
  }

  private func getCurrentSound() -> Sound? {
    switch mode {
    case .customize(let sound):
      return sound
    case .edit(let customSoundData):
      return AudioManager.shared.sounds.first { $0.customSoundDataID == customSoundData.id }
    case .add:
      return nil
    }
  }

  @ViewBuilder
  var previewSection: some View {
    Section {
      HStack {
        Button(action: {
          print("🎵 SoundSheetBasicInfo: Preview button tapped, isPreviewing: \(isPreviewing)")
          togglePreview()
          print("🎵 SoundSheetBasicInfo: After togglePreview(), isPreviewing: \(isPreviewing)")
        }) {
          Label(
            isPreviewing ? "Stop" : "Preview", systemImage: isPreviewing ? "stop.fill" : "play.fill"
          )
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .disabled(isDisappearing)
      }
    } header: {
      Text("Preview", comment: "Preview section header")
    }
  }

  @ViewBuilder
  var actionSection: some View {
    if shouldShowActionSection {
      Section {
        // Reset button for customized sounds
        if case .customize = mode {
          Button(action: { showingResetConfirmation = true }) {
            HStack {
              Text("Reset to Defaults")
                .foregroundColor(.accentColor)
            }
          }
        }

        // Delete button for custom sounds
        if case .customize(let sound) = mode, sound.isCustom {
          Button(action: { showingDeleteConfirmation = true }) {
            HStack {
              Text("Delete Sound")
                .foregroundColor(.red)
            }
          }
        }
      }
    }
  }

  private var shouldShowActionSection: Bool {
    switch mode {
    case .customize(let sound):
      return true || sound.isCustom  // Show for all customize mode
    default:
      return false
    }
  }

}
