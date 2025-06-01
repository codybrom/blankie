//
//  SoundManagementRow.swift
//  Blankie
//
//  Created by Cody Bromley on 6/1/25.
//

import SwiftUI

struct SoundManagementRow: View {
  let sound: Sound
  let isLast: Bool
  let onCustomize: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  @ObservedObject private var audioManager = AudioManager.shared

  private var isCustomSound: Bool {
    sound is CustomSound
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        soundIcon
        soundInfo
        Spacer()
        actionButtons
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background(backgroundView)
      .contentShape(Rectangle())
      .contextMenu {
        if isCustomSound {
          customSoundContextMenu
        }
      }

      if !isLast {
        Divider()
          .padding(.leading, 60)
      }
    }
  }

  private var soundIcon: some View {
    Image(systemName: sound.systemIconName)
      .font(.title2)
      .frame(width: 32)
      .foregroundStyle(sound.isHidden ? .secondary : .primary)
  }

  private var soundInfo: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(isCustomSound ? sound.title : LocalizedStringKey(sound.title))
          .fontWeight(.medium)
          .foregroundColor(sound.isHidden ? .secondary : .primary)

        if SoundCustomizationManager.shared.getCustomization(for: sound.fileName)?
          .hasCustomizations == true
        {
          Image(systemName: "slider.horizontal.3")
            .font(.caption2)
            .foregroundColor(.accentColor)
        }
      }

      Text(isCustomSound ? "Custom imported sound" : "Built-in sound")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  @ViewBuilder
  private var actionButtons: some View {
    if isCustomSound {
      customSoundActions
    } else {
      builtInSoundActions
    }
  }

  private var builtInSoundActions: some View {
    HStack(spacing: 8) {
      Button {
        onCustomize()
      } label: {
        Image(systemName: "slider.horizontal.3")
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Customize Sound")

      toggleVisibilityButton
    }
  }

  private var customSoundActions: some View {
    HStack(spacing: 8) {
      Button {
        onEdit()
      } label: {
        Image(systemName: "pencil")
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Edit Sound")

      toggleVisibilityButton

      Button {
        onDelete()
      } label: {
        Image(systemName: "trash")
          .foregroundColor(.red)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Delete Sound")
    }
  }

  private var toggleVisibilityButton: some View {
    Button {
      withAnimation {
        if sound.isHidden {
          audioManager.showSound(sound)
        } else {
          audioManager.hideSound(sound)
        }
      }
    } label: {
      Image(systemName: sound.isHidden ? "eye.slash" : "eye")
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(sound.isHidden ? "Show Sound" : "Hide Sound")
  }

  @ViewBuilder
  private var customSoundContextMenu: some View {
    Button("Edit Sound", systemImage: "pencil") {
      onEdit()
    }

    Button(
      sound.isHidden ? "Show Sound" : "Hide Sound",
      systemImage: sound.isHidden ? "eye" : "eye.slash"
    ) {
      withAnimation {
        if sound.isHidden {
          audioManager.showSound(sound)
        } else {
          audioManager.hideSound(sound)
        }
      }
    }

    Button("Delete Sound", systemImage: "trash", role: .destructive) {
      onDelete()
    }
  }

  @ViewBuilder
  private var backgroundView: some View {
    if sound.isHidden {
      hiddenSoundRowBackground
    } else if isCustomSound {
      customSoundRowBackground
    } else {
      Color.clear
    }
  }

  private var customSoundRowBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.3)
      #else
        Color(UIColor.secondarySystemBackground)
      #endif
    }
  }

  private var hiddenSoundRowBackground: some View {
    Group {
      #if os(macOS)
        Color(NSColor.controlBackgroundColor).opacity(0.5)
      #else
        Color(UIColor.systemBackground).opacity(0.5)
      #endif
    }
  }
}
