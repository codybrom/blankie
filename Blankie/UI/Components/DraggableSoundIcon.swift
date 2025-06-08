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
    var onEnterEditMode: (() -> Void)?
    var isSoloMode: Bool = false
    var editMode: EditMode = .inactive
    @ObservedObject private var globalSettings = GlobalSettings.shared
    @State private var jiggleAnimation = false

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
        return 75
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
        return 70
      case .medium:
        return 85
      case .large:
        return maxWidth * 0.75
      }
    }

    private var borderWidth: CGFloat {
      switch globalSettings.iconSize {
      case .small: return 4
      case .medium: return 4
      case .large: return 6
      }
    }

    var body: some View {
      VStack(spacing: globalSettings.iconSize == .small ? 2 : 6) {
        // Icon area with drag gesture
        ZStack {
          Circle()
            .fill(backgroundFill)
            .frame(width: iconSize, height: iconSize)

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
            Circle()
              .trim(from: 0, to: max(0.01, sound.playbackProgress))  // Ensure minimum visibility
              .stroke(
                sound.customColor ?? accentColor,
                style: StrokeStyle(lineWidth: borderWidth, lineCap: .round)
              )
              .frame(width: borderSize, height: borderSize)
              .rotationEffect(.degrees(-90))
              .animation(.linear(duration: 0.1), value: sound.playbackProgress)
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

          Image(systemName: sound.systemIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize * innerIconScale, height: iconSize * innerIconScale)
            .foregroundColor(iconColor)

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
                // Haptic feedback for solo mode
                if GlobalSettings.shared.enableHaptics {
                  #if os(iOS)
                    print("🎯 HAPTIC: Solo mode button - medium impact")
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                  #endif
                }

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
            if pressing && GlobalSettings.shared.enableHaptics && editMode == .inactive {
              // Haptic feedback when context menu is about to appear
              #if os(iOS)
                print("🎯 HAPTIC: onLongPressGesture - light impact (context menu)")
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
              #endif
            }
          }, perform: {}
        )
        .if(editMode == .active) { view in
          view.onDrag {
            // Only provide haptic feedback when actually starting a new drag
            if draggedIndex != index {
              if GlobalSettings.shared.enableHaptics {
                #if os(iOS)
                  print("🎯 HAPTIC: onDrag start - light impact for index: \(index)")
                  let generator = UIImpactFeedbackGenerator(style: .light)
                  generator.impactOccurred()
                #endif
              }
              onDragStart()
            }

            return NSItemProvider(object: "\(index)" as NSString)
          } preview: {
            // Custom drag preview - just the icon without background
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
            .opacity(0.8)
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
        }

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
      }
      .opacity(draggedIndex == index ? 0.5 : (editMode == .active ? 0.85 : 1.0))
      .padding(.vertical, globalSettings.iconSize == .small ? 2 : 4)
      .padding(.horizontal, 10)
      .frame(width: maxWidth)
      .zIndex(draggedIndex == index ? 1 : 0)
      .animation(.easeInOut(duration: 0.3), value: draggedIndex)
      .animation(.easeInOut(duration: 0.3), value: hoveredIndex)
      .onAppear {
        if editMode == .active {
          startJiggle()
        }
      }
      .onChange(of: editMode) { _, newValue in
        if newValue == .active {
          startJiggle()
        } else {
          stopJiggle()
        }
      }
      .onDisappear {
        stopJiggle()
      }
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

  // MARK: - Helper Methods
  extension DraggableSoundIcon {
    private var accentColor: Color {
      globalSettings.customAccentColor ?? .accentColor
    }

    private var iconColor: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      let effectiveColor = sound.customColor ?? accentColor

      if isSoloMode {
        return effectiveColor  // Solo mode color
      }

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }
      return sound.isSelected ? effectiveColor : .gray
    }

    private var backgroundFill: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      let effectiveColor = sound.customColor ?? accentColor

      // In edit mode, always show a semi-transparent background
      if editMode == .active {
        return effectiveColor.opacity(0.25)
      }

      if isSoloMode {
        return effectiveColor.opacity(0.3)  // Solo mode background
      }

      if !AudioManager.shared.isGloballyPlaying {
        return sound.isSelected ? Color.gray.opacity(0.2) : .clear
      }
      return sound.isSelected ? effectiveColor.opacity(0.2) : .clear
    }

    private var isSliderEnabled: Bool {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      return isSoloMode || sound.isSelected
    }

    private var sliderTintColor: Color {
      let isSoloMode = AudioManager.shared.soloModeSound?.id == sound.id
      let effectiveColor = sound.customColor ?? accentColor

      if !AudioManager.shared.isGloballyPlaying {
        return .gray
      }

      if isSoloMode {
        return effectiveColor
      }

      return sound.isSelected ? effectiveColor : .gray
    }

    private func getSoundAuthor(for sound: Sound) -> String? {
      // Check if it's a custom sound first
      if isCustomSound(sound) {
        return "You"  // Custom sounds are created by the user
      }

      // For built-in sounds, get author from credits
      let credits = SoundCreditsManager.shared.credits
      return credits.first { $0.soundName == sound.fileName || $0.name == sound.title }?.author
    }

    private func isCustomSound(_ sound: Sound) -> Bool {
      return sound.isCustom
    }

    private func startJiggle() {
      // Add a small random delay for staggered effect
      let delay = Double.random(in: 0...0.2)

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation {
          jiggleAnimation = true
        }
      }
    }

    private func stopJiggle() {
      withAnimation {
        jiggleAnimation = false
      }
    }
  }

  // Helper extension for conditional view modifiers
  extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
      if condition {
        transform(self)
      } else {
        self
      }
    }
  }
#endif
