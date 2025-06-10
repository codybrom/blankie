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
    var onEnterEditMode: (() -> Void)?
    var isSoloMode: Bool = false
    var editMode: EditMode = .inactive
    @ObservedObject var globalSettings = GlobalSettings.shared
    @State var jiggleAnimation = false

    private var filteredSounds: [Sound] {
      AudioManager.shared.getVisibleSounds()
    }

    @ViewBuilder
    private var iconView: some View {
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
    }

    var body: some View {
      VStack(spacing: globalSettings.iconSize == .small ? 2 : 6) {
        // Icon area with drag gesture
        ZStack {
          iconView

          // Progress border (inner border) - hide in edit mode
          if globalSettings.showProgressBorder && sound.isSelected
            && AudioManager.shared.isGloballyPlaying && editMode == .inactive
          {
            let borderSize = iconSize - borderWidth

            // Background track
            Circle()
              .stroke(Color.gray.opacity(0.3), lineWidth: borderWidth)
              .frame(width: borderSize, height: borderSize)

            // Progress indicator
            ProgressBorderView(
              iconSize: borderSize,
              borderWidth: borderWidth,
              playbackProgress: max(0.01, sound.playbackProgress),
              color: sound.customColor ?? accentColor
            )
          }

          // Dashed border in edit mode
          if editMode == .active {
            Circle()
              .stroke(
                Color.primary.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, dash: [5, 5])
              )
              .frame(width: iconSize, height: iconSize)
          }
        }
        .frame(width: iconSize, height: iconSize)
        .contentShape(Circle())
        .scaleEffect(draggedIndex == index ? 0.85 : 1.0)
        .overlay(dropOverlay)
        .rotationEffect(
          editMode == .active && jiggleAnimation
            ? .degrees(2.5)
            : .zero
        )
        .animation(
          editMode == .active && jiggleAnimation
            ? Animation.easeInOut(duration: 0.13).repeatForever(autoreverses: true)
            : nil,
          value: jiggleAnimation
        )
        .onTapGesture {
          // Disable tap when in edit mode
          guard editMode == .inactive else { return }

          // If this sound is in solo mode, exit solo mode
          if AudioManager.shared.soloModeSound?.id == sound.id {
            withAnimation(.easeInOut(duration: 0.3)) {
              AudioManager.shared.exitSoloMode()
            }
          } else {
            // If global playback is paused and this sound is already selected,
            // start global playback instead of deselecting the sound
            if !AudioManager.shared.isGloballyPlaying && sound.isSelected {
              AudioManager.shared.setGlobalPlaybackState(true)
            } else {
              // Normal behavior: toggle sound selection
              sound.toggle()
            }
          }
        }
        .contextMenu {
          // Disable context menu when in edit mode
          if editMode == .active {
            EmptyView()
          } else {
            // Title with credits
            Text(
              isCustomSound(sound)
                ? "\(sound.title) (Custom • Added By You)"
                : "\(sound.title) (Built-in\(getSoundAuthor(for: sound).map { " • By \($0)" } ?? ""))"
            )
            .font(.title2)
            .fontWeight(.bold)

            // Solo Mode - only show if not already in solo mode
            if AudioManager.shared.soloModeSound?.id != sound.id {
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  AudioManager.shared.toggleSoloMode(for: sound)
                }
              }) {
                Label("Solo", systemImage: "headphones")
              }
            }

            // Customize Sound
            Button(action: {
              onEditSound(sound)
            }) {
              Label("Customize", systemImage: "paintbrush")
            }

            Divider()

            // Reorder - only show when not already in edit mode
            if editMode == .inactive, let onEnterEditMode = onEnterEditMode {
              Button(action: {
                onEnterEditMode()
              }) {
                Label("Reorder", systemImage: "arrow.up.arrow.down")
              }
            }
          }
        }
        .onLongPressGesture(
          minimumDuration: 0.5, maximumDistance: .infinity,
          pressing: { pressing in
            // Only provide haptic feedback when not in edit mode
            if pressing && editMode == .inactive {
              provideHapticFeedback()
            }
          }, perform: {}
        )
        .onDrag {
          if editMode == .active {
            // Only provide haptic feedback when actually starting a new drag
            if draggedIndex != index {
              provideHapticFeedback()
              onDragStart()
            }

            return NSItemProvider(object: "\(index)" as NSString)
          } else {
            return NSItemProvider()
          }
        } preview: {
          if editMode == .active {
            // Custom drag preview - just the icon without background
            iconView
              .opacity(0.8)
          } else {
            EmptyView()
          }
        }
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

        // Title (not draggable) - hidden in solo mode since it's shown in navigation title
        if AudioManager.shared.soloModeSound == nil && globalSettings.showSoundNames {
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
            .frame(maxWidth: maxWidth - 20)  // Remove fixed min height for better spacing
            .padding(.top, 2)  // Add a tiny bit more space above text
        }

        // Slider (not draggable) - hide in solo mode and edit mode
        if !isSoloMode && editMode == .inactive {
          if !globalSettings.hideInactiveSoundSliders || sound.isSelected {
            VolumeSliderView(
              sound: sound,
              width: sliderWidth,
              tintColor: sliderTintColor,
              isEnabled: isSliderEnabled
            )
          }
        }
      }
      .opacity(draggedIndex == index ? 0.5 : (editMode == .active ? 0.85 : 1.0))
      .padding(.vertical, globalSettings.iconSize == .small ? 2 : 4)
      .padding(.horizontal, 10)
      .frame(width: maxWidth)
      .zIndex(draggedIndex == index ? 1 : 0)
      .animation(.easeInOut(duration: 0.3), value: draggedIndex)
      .animation(.easeInOut(duration: 0.3), value: hoveredIndex)
      .onAppear { handleJiggle() }
      .onChange(of: editMode) { _, _ in handleJiggle() }
      .onDisappear { stopJiggle() }
    }

    @ViewBuilder
    private var dropOverlay: some View {
      if hoveredIndex == index && draggedIndex != index && editMode == .active {
        RoundedRectangle(cornerRadius: 50)
          .stroke(accentColor, lineWidth: 3)
          .background(
            RoundedRectangle(cornerRadius: 50)
              .fill(accentColor.opacity(0.2))
          )
          .allowsHitTesting(false)
      }
    }

  }
#endif
