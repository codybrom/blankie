//
//  SoundSheet+Helpers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Helper Properties
extension SoundSheet {

  var sound: CustomSoundData? {
    switch mode {
    case .add:
      return nil
    case .edit(let sound):
      return sound
    case .customize:
      return nil
    }
  }

  var builtInSound: Sound? {
    switch mode {
    case .customize(let sound):
      return sound
    default:
      return nil
    }
  }

  var title: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Edit Sound"
    case .customize:
      return "Customize Sound"
    }
  }

  var buttonTitle: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Save"
    case .customize:
      return "Save"
    }
  }

  var progressMessage: LocalizedStringKey {
    switch mode {
    case .add:
      return "Importing sound..."
    case .edit:
      return "Saving changes..."
    case .customize:
      return "Saving customization..."
    }
  }

  var isDisabled: Bool {
    let nameTrimmed = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    switch mode {
    case .add:
      return selectedFile == nil || nameTrimmed.isEmpty || isProcessing
    case .edit:
      return nameTrimmed.isEmpty || isProcessing
    case .customize:
      return isProcessing
    }
  }

  var processingOverlay: some View {
    SoundSheetProcessingOverlay(progressMessage: progressMessage)
  }
}
