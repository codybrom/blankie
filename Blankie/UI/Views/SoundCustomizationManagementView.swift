//
//  SoundCustomizationManagementView.swift
//  Blankie
//
//  Created by Cody Bromley on 5/30/25.
//

import SwiftUI

struct SoundCustomizationManagementView: View {
  @StateObject private var customizationManager = SoundCustomizationManager.shared
  @StateObject private var audioManager = AudioManager.shared
  @State private var showingResetAllConfirmation = false

  var body: some View {
    List {
      if customizationManager.hasAnyCustomizations {
        Section {
          ForEach(customizedSounds, id: \.fileName) { sound in
            SoundCustomizationRow(sound: sound)
          }
        } header: {
          Text("Customized Sounds")
        } footer: {
          Text(
            "Reset all customizations using the \"Reset All\" button in the top left."
          )
        }
      } else {
        ContentUnavailableView(
          "No Customizations",
          systemImage: "slider.horizontal.3",
          description: Text(
            "You haven't customized any sounds yet. Long press on any built-in sound and select \"Customize Sound\" to get started."
          )
        )
      }
    }
    .navigationTitle("Sound Customizations")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        if customizationManager.hasAnyCustomizations {
          Button("Reset All", role: .destructive) {
            showingResetAllConfirmation = true
          }
        }
      }
    }
    .alert(
      "Reset All Customizations",
      isPresented: $showingResetAllConfirmation
    ) {
      Button("Cancel", role: .cancel) {}
      Button("Reset All", role: .destructive) {
        customizationManager.resetAllCustomizations()
      }
    } message: {
      Text(
        "Are you sure you want to reset all sound customizations? This will restore all sound names and icons to their defaults. This action cannot be undone."
      )
    }
  }

  private var customizedSounds: [Sound] {
    let customizedFileNames = customizationManager.customizedSounds
    return audioManager.sounds.filter { sound in
      customizedFileNames.contains(sound.fileName) && !(sound is CustomSound)
    }
  }
}

struct SoundCustomizationRow: View {
  let sound: Sound
  @StateObject private var customizationManager = SoundCustomizationManager.shared
  @State private var showingCustomizationSheet = false
  @State private var showingResetConfirmation = false

  var body: some View {
    HStack(spacing: 12) {
      // Icon comparison
      HStack(spacing: 8) {
        // Original icon
        VStack(spacing: 4) {
          Image(systemName: sound.originalSystemIconName)
            .font(.title2)
            .foregroundColor(.secondary)
            .frame(width: 32, height: 32)

          Text("Original")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Image(systemName: "arrow.right")
          .font(.caption)
          .foregroundColor(.secondary)

        // Custom icon
        VStack(spacing: 4) {
          Image(systemName: sound.systemIconName)
            .font(.title2)
            .foregroundColor(.primary)
            .frame(width: 32, height: 32)

          Text("Custom")
            .font(.caption2)
            .foregroundColor(.primary)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        // Title comparison
        if sound.originalTitle != sound.title {
          VStack(alignment: .leading, spacing: 2) {
            Text(sound.originalTitle)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .strikethrough()

            Text(sound.title)
              .font(.subheadline)
              .fontWeight(.medium)
          }
        } else {
          Text(sound.title)
            .font(.subheadline)
            .fontWeight(.medium)
        }

        // Show what's customized
        HStack(spacing: 8) {
          if let customization = customizationManager.getCustomization(for: sound.fileName) {
            if customization.customTitle != nil {
              Label("Name", systemImage: "textformat")
                .font(.caption2)
                .foregroundColor(.accentColor)
            }

            if customization.customIconName != nil {
              Label("Icon", systemImage: "photo")
                .font(.caption2)
                .foregroundColor(.accentColor)
            }
          }
        }
      }

      Spacer()

      // Action buttons
      HStack(spacing: 8) {
        Button("Edit") {
          showingCustomizationSheet = true
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.2))
        .cornerRadius(6)

        Button("Reset") {
          showingResetConfirmation = true
        }
        .font(.caption)
        .foregroundColor(.red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.red.opacity(0.1))
        .cornerRadius(6)
      }
    }
    .sheet(isPresented: $showingCustomizationSheet) {
      SoundSheet(mode: .customize(sound))
    }
    .alert(
      "Reset \(sound.originalTitle)",
      isPresented: $showingResetConfirmation
    ) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        customizationManager.resetCustomizations(for: sound.fileName)
      }
    } message: {
      Text(
        "This will reset this sound's name and icon to their defaults. This action cannot be undone."
      )
    }
  }
}

#if DEBUG
  #Preview {
    NavigationView {
      SoundCustomizationManagementView()
    }
  }
#endif
