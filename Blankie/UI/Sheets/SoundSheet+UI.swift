//
//  SoundSheet+UI.swift
//  Blankie
//
//  Created by Cody Bromley on 6/9/25.
//

import SwiftUI

// MARK: - UI Components
extension SoundSheet {
  var macOSLayout: some View {
    SoundSheetMacOSLayout(
      mode: mode,
      isFilePreselected: isFilePreselected,
      soundName: $soundName,
      selectedIcon: $selectedIcon,
      selectedFile: $selectedFile,
      isImporting: $isImporting,
      selectedColor: $selectedColor,
      randomizeStartPosition: $randomizeStartPosition,
      normalizeAudio: $normalizeAudio,
      volumeAdjustment: $volumeAdjustment,
      loopSound: $loopSound,
      isPreviewing: $isPreviewing,
      previewSound: $previewSound,
      hasChanges: hasChanges,
      title: title,
      buttonTitle: buttonTitle,
      isDisabled: isDisabled,
      performAction: performAction,
      stopPreview: stopPreview,
      dismiss: dismiss
    )
  }

  var iOSLayout: some View {
    NavigationView {
      CleanSoundSheetForm(
        mode: mode,
        isFilePreselected: isFilePreselected,
        soundName: $soundName,
        selectedIcon: $selectedIcon,
        selectedFile: $selectedFile,
        isImporting: $isImporting,
        selectedColor: $selectedColor,
        randomizeStartPosition: $randomizeStartPosition,
        normalizeAudio: $normalizeAudio,
        volumeAdjustment: $volumeAdjustment,
        loopSound: $loopSound,
        isPreviewing: $isPreviewing,
        previewSound: $previewSound
      )
      .navigationTitle(title)
      #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
          leading: leadingNavigationButton,
          trailing: trailingNavigationButton
        )
      #endif
    }
    #if !os(macOS)
      .navigationViewStyle(.stack)
    #endif
  }

  @ViewBuilder
  var leadingNavigationButton: some View {
    if hasChanges {
      Button("Cancel") {
        if isPreviewing {
          stopPreview()
        }
        dismiss()
      }
    } else {
      Button("Done") {
        if isPreviewing {
          stopPreview()
        }
        dismiss()
      }
    }
  }

  @ViewBuilder
  var trailingNavigationButton: some View {
    if hasChanges {
      Button("Save") {
        performAction()
      }
      .disabled(isDisabled)
    }
  }

  func handleFileImport(result: Result<[URL], Error>) {
    switch result {
    case .success(let files):
      if let file = files.first {
        selectedFile = file
        if soundName.isEmpty {
          Task {
            if let metadataTitle = await CustomSoundManager.shared.extractMetadataTitle(from: file)
            {
              soundName = metadataTitle
            } else {
              soundName = file.deletingPathExtension().lastPathComponent
            }
          }
        }
      }
    case .failure(let error):
      importError = error
      showingError = true
    }
  }
}
