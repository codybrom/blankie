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
}

struct SoundSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  let mode: SoundSheetMode

  @State private var soundName: String = ""
  @State private var selectedIcon: String = "waveform.circle"
  @State private var selectedFile: URL?
  @State private var isImporting = false
  @State private var importError: Error?
  @State private var showingError = false
  @State private var isProcessing = false

  private var sound: CustomSoundData? {
    switch mode {
    case .add:
      return nil
    case .edit(let sound):
      return sound
    }
  }

  private var title: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Edit Sound"
    }
  }

  private var buttonTitle: LocalizedStringKey {
    switch mode {
    case .add:
      return "Import Sound"
    case .edit:
      return "Save"
    }
  }

  private var progressMessage: LocalizedStringKey {
    switch mode {
    case .add:
      return "Importing sound..."
    case .edit:
      return "Saving changes..."
    }
  }

  init(mode: SoundSheetMode) {
    self.mode = mode

    switch mode {
    case .add:
      _soundName = State(initialValue: "")
      _selectedIcon = State(initialValue: "waveform.circle")
    case .edit(let sound):
      _soundName = State(initialValue: sound.title)
      _selectedIcon = State(initialValue: sound.systemIconName)
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
      VStack(alignment: .leading, spacing: 20) {
        // File selection (only for add mode)
        if case .add = mode {
          SoundFileSelector(
            selectedFile: $selectedFile,
            soundName: $soundName,
            isImporting: $isImporting
          )
        }

        // Name Input
        VStack(alignment: .leading, spacing: 8) {
          Text("Name", comment: "Display name field label")
            .font(.headline)
          TextField(text: $soundName) {
            Text("Enter a name for this sound", comment: "Sound name text field placeholder")
          }
          .textFieldStyle(.roundedBorder)
        }

        // Icon Selection
        SoundIconSelector(selectedIcon: $selectedIcon)
      }
      .padding(20)

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
    .frame(width: 450, height: mode.isAdd ? 580 : 520)
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
    ZStack {
      Color.black.opacity(0.3)
        .ignoresSafeArea()

      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.5)
        Text(progressMessage)
          .font(.headline)
      }
      .padding(24)
      .background(
        Group {
          #if os(macOS)
            Color(NSColor.windowBackgroundColor)
          #else
            Color(UIColor.systemBackground)
          #endif
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(radius: 20)
    }
  }

  // MARK: - Helper Methods

  private var isDisabled: Bool {
    let nameTrimmed = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    switch mode {
    case .add:
      return selectedFile == nil || nameTrimmed.isEmpty || isProcessing
    case .edit:
      return nameTrimmed.isEmpty || isProcessing
    }
  }

  private func performAction() {
    switch mode {
    case .add:
      importSound()
    case .edit(let sound):
      saveChanges(sound)
    }
  }

  private func importSound() {
    guard let selectedFile = selectedFile,
      !soundName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return
    }

    isProcessing = true

    // Capture values before Task to avoid sendability issues
    let file = selectedFile
    let title = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    let icon = selectedIcon

    Task.detached {
      let result = await CustomSoundManager.shared.importSound(
        from: file,
        title: title,
        iconName: icon
      )

      // Extract sendable values from the result
      let success: Bool
      let errorMessage: String?

      switch result {
      case .success:
        success = true
        errorMessage = nil
      case .failure(let error):
        success = false
        errorMessage = error.localizedDescription
      }

      await MainActor.run {
        isProcessing = false

        if success {
          dismiss()
        } else if let message = errorMessage {
          importError = NSError(
            domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
          showingError = true
        }
      }
    }
  }

  private func saveChanges(_ sound: CustomSoundData) {
    guard !soundName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    isProcessing = true

    // Update the sound data
    sound.title = soundName.trimmingCharacters(in: .whitespacesAndNewlines)
    sound.systemIconName = selectedIcon

    do {
      try modelContext.save()

      // Notify that a sound was updated
      NotificationCenter.default.post(name: .customSoundAdded, object: nil)

      // Dismiss the sheet
      dismiss()
    } catch {
      print("❌ SoundSheet: Failed to save changes: \(error)")
      isProcessing = false
    }
  }
}

// MARK: - Mode Extensions

extension SoundSheetMode {
  var isAdd: Bool {
    switch self {
    case .add:
      return true
    case .edit:
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
