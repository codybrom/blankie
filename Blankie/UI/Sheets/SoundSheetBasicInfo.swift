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
  var resetSection: some View {
    if case .customize(let sound) = mode {
      Section {
        Button(action: {
          resetToDefaults(for: sound)
        }) {
          HStack {
            Image(systemName: "arrow.counterclockwise")
            Text("Reset to Defaults")
          }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
      } footer: {
        Text("Reset all customizations for this sound")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }

  @ViewBuilder
  var previewSection: some View {
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
}
