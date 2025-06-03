//
//  SoundSheet.swift
//  Blankie
//
//  Created by Cody Bromley on 5/28/25.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum SoundSheetMode {
  case add
  case edit(CustomSoundData)
  case customize(Sound)
}

struct SoundSheet: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext

  let mode: SoundSheetMode

  @State var soundName: String = ""
  @State var selectedIcon: String = "waveform.circle"
  @State var selectedColor: AccentColor?
  @State var selectedFile: URL?
  @State var isImporting = false
  @State var importError: Error?
  @State var showingError = false
  @State var isProcessing = false

  private var sound: CustomSoundData? {
    switch mode {
    case .add:
      return nil
    case .edit(let sound):
      return sound
    case .customize:
      return nil
    }
  }

  private var builtInSound: Sound? {
    switch mode {
    case .customize(let sound):
      return sound
    default:
      return nil
    }
  }

  private var title: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Edit Sound"
    case .customize:
      return "Customize Sound"
    }
  }

  private var buttonTitle: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Save"
    case .customize:
      return "Save"
    }
  }

  private var progressMessage: LocalizedStringKey {
    switch mode {
    case .add:
      return "Importing sound..."
    case .edit:
      return "Saving changes..."
    case .customize:
      return "Saving customization..."
    }
  }

  init(mode: SoundSheetMode, preselectedFile: URL? = nil) {
    self.mode = mode

    switch mode {
    case .add:
      let fileName = preselectedFile?.deletingPathExtension().lastPathComponent ?? ""
      _soundName = State(initialValue: fileName)
      _selectedIcon = State(initialValue: "waveform.circle")
      _selectedFile = State(initialValue: preselectedFile)
    case .edit(let sound):
      _soundName = State(initialValue: sound.title)
      _selectedIcon = State(initialValue: sound.systemIconName)
      // Load color customization if it exists
      let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
      if let colorName = customization?.customColorName,
        let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
      {
        _selectedColor = State(initialValue: color)
      }
    case .customize(let sound):
      let customization = SoundCustomizationManager.shared.getCustomization(for: sound.fileName)
      _soundName = State(initialValue: customization?.customTitle ?? sound.originalTitle)
      _selectedIcon = State(
        initialValue: customization?.customIconName ?? sound.originalSystemIconName)
      if let colorName = customization?.customColorName,
        let color = AccentColor.allCases.first(where: { $0.color?.toString == colorName })
      {
        _selectedColor = State(initialValue: color)
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 8) {
        Text(title)
          .font(.title2.bold())
      }
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      // Content
      SoundSheetForm(
        mode: mode,
        soundName: $soundName,
        selectedIcon: $selectedIcon,
        selectedFile: $selectedFile,
        isImporting: $isImporting,
        selectedColor: $selectedColor
      )

      Spacer()

      Divider()

      // Footer buttons
      HStack {
        Button("Cancel") {
          dismiss()
        }
        .buttonStyle(.bordered)
        .keyboardShortcut(.escape)

        Spacer()

        Button {
          performAction()
        } label: {
          Text(buttonTitle)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
        .keyboardShortcut(.return)
      }
      .padding()
    }
    .frame(width: 450, height: mode.isAdd ? 580 : 560)
    .fileImporter(
      isPresented: $isImporting,
      allowedContentTypes: [
        UTType.audio,
        UTType.mp3,
        UTType.wav,
        UTType.mpeg4Audio,
      ],
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let files):
        if let file = files.first {
          selectedFile = file
          // Extract filename (without extension) as default name
          if soundName.isEmpty {
            soundName = file.deletingPathExtension().lastPathComponent
          }
        }
      case .failure(let error):
        importError = error
        showingError = true
      }
    }
    .alert(
      Text("Import Error", comment: "Import error alert title"), isPresented: $showingError,
      presenting: importError
    ) { _ in
      Button("OK", role: .cancel) {}
    } message: { error in
      Text(error.localizedDescription)
    }
    .overlay {
      if isProcessing {
        processingOverlay
      }
    }
  }

  // MARK: - Processing Overlay

  private var processingOverlay: some View {
    SoundSheetProcessingOverlay(progressMessage: progressMessage)
  }

  // MARK: - Helper Methods

  private var isDisabled: Bool {
    let nameTrimmed = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    switch mode {
    case .add:
      return selectedFile == nil || nameTrimmed.isEmpty || isProcessing
    case .edit, .customize:
      return nameTrimmed.isEmpty || isProcessing
    }
  }
}

// MARK: - Mode Extensions

extension SoundSheetMode {
  var isAdd: Bool {
    switch self {
    case .add:
      return true
    case .edit, .customize:
      return false
    }
  }
}

// MARK: - Previews

#Preview("Add Mode") {
  SoundSheet(mode: .add)
}

#Preview("Edit Mode") {
  let previewSound = CustomSoundData(
    title: "Sample Sound",
    systemIconName: "waveform",
    fileName: "sample",
    fileExtension: "mp3"
  )

  return SoundSheet(mode: .edit(previewSound))
    .modelContainer(for: CustomSoundData.self, inMemory: true)
}
