//
//  DraggableSoundIcon.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  // Custom draggable sound icon that only applies drag gesture to the icon area
  struct DraggableSoundIcon: View {
    @ObservedObject var sound: Sound
    let maxWidth: CGFloat
    let index: Int
    @Binding var draggedIndex: Int?
    @Binding var hoveredIndex: Int?
    let onDragStart: () -> Void
    let onDrop: (Int) -> Void
    let onEditSound: (Sound) -> Void
    let onHideSound: (Sound) -> Void
    var isSoloMode: Bool = false

    @ObservedObject private var globalSettings = GlobalSettings.shared
    @State private var isDraggingIcon = false

    private var filteredSounds: [Sound] {
      AudioManager.shared.getVisibleSounds()
    }

    private var iconSize: CGFloat {
      // Solo mode has fixed larger size
      if isSoloMode {
        return 200
      }

      // Normal mode uses settings
      switch globalSettings.iconSize {
      case .small:
        return 75  // Increased from 65 to 75
      case .medium:
        return 100
      case .large:
        return maxWidth * 0.85
      }
    }

    private var innerIconScale: CGFloat {
      return 0.64
    }

    private var sliderWidth: CGFloat {
      switch globalSettings.iconSize {
      case .small:
        return 70  // Increased from 65 to 70
      case .medium:
        return 85
      case .large:
        return maxWidth * 0.75
      }
    }

    var body: some View {
      VStack(spacing: globalSettings.iconSize == .small ? 4 : 8) {
        // Icon area with drag gesture
        ZStack {
          Circle()
            .fill(backgroundFill)
            .frame(width: iconSize, height: iconSize)

          Image(systemName: sound.systemIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize * innerIconScale, height: iconSize * innerIconScale)
            .foregroundColor(iconColor)
        }
        .frame(width: iconSize, height: iconSize)
        .contentShape(Circle())
        .scaleEffect(draggedIndex == index ? 0.85 : 1.0)
        .opacity(draggedIndex == index ? 0.5 : 1.0)
        .overlay(dropOverlay)
        .onTapGesture {
          // If this sound is in solo mode, exit solo mode
          if AudioManager.shared.soloModeSound?.id == sound.id {
            withAnimation(.easeInOut(duration: 0.3)) {
              AudioManager.shared.exitSoloMode()
            }
          } else {
            // Normal behavior: toggle sound selection
            sound.toggle()
          }
        }
        .contextMenu {
          // Solo Mode - only show if not already in solo mode
          if AudioManager.shared.soloModeSound?.id != sound.id {
            Button(action: {
              // Haptic feedback for solo mode
              if GlobalSettings.shared.enableHaptics {
                #if os(iOS)
                  let generator = UIImpactFeedbackGenerator(style: .medium)
                  generator.impactOccurred()
                #endif
              }

              withAnimation(.easeInOut(duration: 0.3)) {
                AudioManager.shared.toggleSoloMode(for: sound)
              }
            }) {
              Label("Solo Mode", systemImage: "headphones")
            }
          }

          // Hide Sound
          Button(action: {
            onHideSound(sound)
          }) {
            let labelText = sound.isHidden ? "Show Sound" : "Hide Sound"
            let iconName = sound.isHidden ? "eye" : "eye.slash"
            Label(labelText, systemImage: iconName)
          }

          // Edit Sound (all sounds can be edited/customized)
          Button(action: {
            onEditSound(sound)
          }) {
            Label("Edit Sound", systemImage: "pencil")
          }
        }
        .onLongPressGesture(
          minimumDuration: 0.0, maximumDistance: .infinity,
          pressing: { pressing in
            if pressing && GlobalSettings.shared.enableHaptics {
              // Haptic feedback when context menu is about to appear
              #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
              #endif
            }
          }, perform: {}
        )
        .onDrag {
          // Haptic feedback for drag start
          if GlobalSettings.shared.enableHaptics {
            #if os(iOS)
              let generator = UIImpactFeedbackGenerator(style: .light)
              generator.impactOccurred()
            #endif
          }

          onDragStart()
          return NSItemProvider(object: "\(index)" as NSString)
        }

        // Title (not draggable) - hidden in solo mode since it's shown in navigation title
        if AudioManager.shared.soloModeSound == nil {
          Group {
            if globalSettings.showSoundNames {
              Text(LocalizedStringKey(sound.title))
                .font(
                  globalSettings.iconSize == .small
                    ? .caption2.weight(
                      Locale.current.scriptCategory == .standard ? .regular : .thin)
                    : .callout.weight(Locale.current.scriptCategory == .standard ? .regular : .thin)
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            } else {
              Color.clear  // Spacer to maintain consistent height
            }
          }
          .frame(maxWidth: maxWidth - 20, minHeight: 32)  // Fixed min height for 2 lines
        }

        // Slider (not draggable) - hide in solo mode
        if !isSoloMode {
          Slider(
            value: Binding(
              get: { Double(sound.volume) },
              set: { sound.volume = Float($0) }
            ), in: 0...1
          )
          .frame(width: sliderWidth)
          .tint(sliderTintColor)
          .disabled(!isSliderEnabled)
        }
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 10)
      .frame(width: maxWidth)
      .offset(calculateDodgeOffset(for: index))
      .zIndex(draggedIndex == index ? 1 : 0)
      .animation(.easeInOut(duration: 0.3), value: draggedIndex)
      .animation(.easeInOut(duration: 0.3), value: hoveredIndex)
      .onDrop(
        of: [.text],
        delegate: SoundDropDelegate(
          audioManager: AudioManager.shared,
          targetIndex: index,
          sounds: filteredSounds,
          draggedIndex: $draggedIndex,
          hoveredIndex: $hoveredIndex,
          cancelTimer: { draggedIndex = nil }
        )
      )
    }

    private var accentColor: Color {
      globalSettings.customAccentColor ?? .accentColor
    }

    private var iconColor: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if isSoloMode {
        return accentColor  // Solo mode color
      }

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }
      return sound.isSelected ? accentColor : .gray
    }

    private var backgroundFill: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if isSoloMode {
        return accentColor.opacity(0.3)  // Solo mode background
      }

      if !AudioManager.shared.isGloballyPlaying {
        return sound.isSelected ? Color.gray.opacity(0.2) : .clear
      }
      return sound.isSelected ? accentColor.opacity(0.2) : .clear
    }

    private var isSliderEnabled: Bool {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      return isSoloMode || sound.isSelected
    }

    private var sliderTintColor: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }

      if isSoloMode {
        return accentColor
      }

      return sound.isSelected ? accentColor : .gray
    }

    @ViewBuilder
    private var dropOverlay: some View {
      if hoveredIndex == index && draggedIndex != index {
        RoundedRectangle(cornerRadius: 50)
          .stroke(accentColor, lineWidth: 3)
          .background(
            RoundedRectangle(cornerRadius: 50)
              .fill(accentColor.opacity(0.2))
          )
          .overlay(
            VStack(spacing: 4) {
              Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(accentColor)
              Text("Drop here")
                .font(.caption)
                .foregroundColor(accentColor)
            }
          )
          .allowsHitTesting(false)
      }
    }

    private func calculateDodgeOffset(for index: Int) -> CGSize {
      guard let draggedIndex = draggedIndex,
        let hoveredIndex = hoveredIndex,
        draggedIndex != index
      else {
        return .zero
      }

      // If we're hovering over this item, no offset needed
      if hoveredIndex == index {
        return .zero
      }

      // Calculate if we need to dodge
      let isDraggedBeforeHovered = draggedIndex < hoveredIndex
      let isIndexBetween =
        isDraggedBeforeHovered
        ? (index > draggedIndex && index <= hoveredIndex)
        : (index < draggedIndex && index >= hoveredIndex)

      if isIndexBetween {
        // Dodge in the opposite direction of the drag
        return CGSize(width: isDraggedBeforeHovered ? -120 : 120, height: 0)
      }

      return .zero
    }
  }
#endif
