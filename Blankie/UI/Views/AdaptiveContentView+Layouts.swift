//
//  AdaptiveContentView+Layouts.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI

#if os(iOS) || os(visionOS)
  extension AdaptiveContentView {
    // Split view layout for iPad/Mac
    var largeDeviceLayout: some View {
      NavigationSplitView(columnVisibility: $columnVisibility) {
        sidebarContent
      } detail: {
        mainSoundGridView
          .safeAreaInset(edge: .top, spacing: 0) {
            navigationHeader
          }
          .navigationTitle(navigationTitleText)
          .toolbar {
            ToolbarItem(placement: .primaryAction) {
              Button(action: {
                showingVolumeControls = true
              }) {
                Label("All Sounds", systemImage: "speaker.wave.2")
              }
            }
            ToolbarItem(placement: .primaryAction) {
              TimerButton()
            }
          }
      }
      .navigationSplitViewStyle(.balanced)
    }

    // Sidebar content for split view
    var sidebarContent: some View {
      SidebarContentView(
        showingPresetPicker: $showingPresetPicker,
        showingSettings: $showingSettings,
        showingAbout: $showingAbout,
        hideInactiveSounds: $hideInactiveSounds
      )
    }

    // iPhone layout
    var smallDeviceLayout: some View {
      NavigationView {
        ZStack {
          mainSoundGridView
            .safeAreaInset(edge: .top, spacing: 0) {
              Color.clear.frame(height: headerHeight)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
              VStack(spacing: 0) {
                statusIndicatorView

                HStack(spacing: 0) {
                  // Volume button or Exit Solo Mode button
                  Spacer()
                  if audioManager.soloModeSound != nil {
                    Button(action: {
                      withAnimation(.easeInOut(duration: 0.3)) {
                        audioManager.exitSoloMode()
                      }
                    }) {
                      Image(systemName: "headphones.slash")
                        .font(.system(size: 22))
                        .foregroundColor(globalSettings.customAccentColor ?? .accentColor)
                    }
                    .buttonStyle(.plain)
                  } else {
                    Button(action: {
                      showingVolumeControls.toggle()
                    }) {
                      Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                  }
                  Spacer()

                  // Play/Pause button
                  Spacer()
                  Button(action: {
                    if audioManager.hasSelectedSounds {
                      audioManager.togglePlayback()
                    }
                  }) {
                    ZStack {
                      Circle()
                        .fill(
                          audioManager.hasSelectedSounds
                            ? (globalSettings.customAccentColor?.opacity(0.2)
                              ?? Color.accentColor.opacity(0.2))
                            : Color.secondary.opacity(0.1)
                        )
                        .frame(width: 60, height: 60)

                      let imageName = audioManager.isGloballyPlaying ? "pause.fill" : "play.fill"
                      let xOffset: CGFloat = audioManager.isGloballyPlaying ? 0 : 2

                      Image(systemName: imageName)
                        .font(.system(size: 26))
                        .foregroundColor(
                          audioManager.hasSelectedSounds
                            ? (globalSettings.customAccentColor ?? .accentColor)
                            : .secondary
                        )
                        .offset(x: xOffset)
                    }
                  }
                  .buttonStyle(.plain)
                  .disabled(!audioManager.hasSelectedSounds)
                  Spacer()

                  // Menu button
                  Spacer()
                  playbackMenuButton
                  Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.regularMaterial, ignoresSafeAreaEdges: .bottom)
              }
            }

          // Custom navigation header overlay
          VStack(spacing: 0) {
            navigationHeader
            Spacer()
          }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        .onChange(of: audioManager.hasSelectedSounds) { oldValue, newValue in
          print("🎨 UI: hasSelectedSounds changed from \(oldValue) to \(newValue)")
          // Auto-pause when no sounds are selected
          if !newValue && audioManager.isGloballyPlaying {
            audioManager.setGlobalPlaybackState(false)
          }
        }
      }
    }

    // Main sound grid that's shared between layouts
    var mainSoundGridView: some View {
      Group {
        if let soloSound = audioManager.soloModeSound {
          // Solo mode: Show only the solo sound centered
          VStack {
            Spacer()
            DraggableSoundIcon(
              sound: soloSound,
              maxWidth: 280,
              index: 0,
              draggedIndex: .constant(nil),
              hoveredIndex: .constant(nil),
              onDragStart: {},
              onDrop: { _ in },
              onEditSound: { sound in
                soundToEdit = sound
              },
              onHideSound: { sound in
                sound.isHidden.toggle()
                // If hiding a sound that's currently playing, stop it
                if sound.isHidden && sound.isSelected {
                  sound.pause()
                }
                // If hiding the solo mode sound, exit solo mode
                if sound.isHidden && audioManager.soloModeSound?.id == sound.id {
                  audioManager.exitSoloMode()
                }
                // Update hasSelectedSounds to reflect changes in hidden sounds
                audioManager.updateHasSelectedSounds()
                soundsUpdateTrigger += 1
              }
            )
            .scaleEffect(1.5)
            .transition(
              .asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
              ))
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        } else {
          // Normal mode: Show all sounds in grid or empty state
          if filteredSounds.isEmpty {
            // Empty state - either no active sounds or all sounds hidden
            VStack(spacing: 20) {
              Spacer()

              VStack(spacing: 12) {
                Image(
                  systemName: audioManager.getVisibleSounds().isEmpty
                    ? "eye.slash.circle" : "speaker.slash.circle"
                )
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

                Text(
                  audioManager.getVisibleSounds().isEmpty ? "No Visible Sounds" : "No Active Sounds"
                )
                .font(.headline)
                .foregroundColor(.primary)
              }

              if audioManager.getVisibleSounds().isEmpty {
                // All sounds are hidden - button to manage sounds
                Button(action: {
                  showingSoundManagement = true
                }) {
                  Text("Manage Sounds")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(globalSettings.customAccentColor ?? .accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
              } else {
                // Some sounds are active but hidden by filter - button to show inactive
                Button(action: {
                  withAnimation {
                    hideInactiveSounds = false
                  }
                }) {
                  Text("Show Inactive Sounds")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(globalSettings.customAccentColor ?? .accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
              }

              Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
          } else {
            // Normal grid view
            ScrollView {
              LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(filteredSounds.enumerated()), id: \.element.id) { index, sound in
                  DraggableSoundIcon(
                    sound: sound,
                    maxWidth: columnWidth,
                    index: index,
                    draggedIndex: $draggedIndex,
                    hoveredIndex: $hoveredIndex,
                    onDragStart: {
                      draggedIndex = index
                      startDragResetTimer()
                    },
                    onDrop: { sourceIndex in
                      audioManager.moveVisibleSound(from: sourceIndex, to: index)
                      cancelDragResetTimer()
                    },
                    onEditSound: { sound in
                      soundToEdit = sound
                    },
                    onHideSound: { sound in
                      sound.isHidden.toggle()
                      // If hiding a sound that's currently playing, stop it
                      if sound.isHidden && sound.isSelected {
                        sound.pause()
                      }
                      // If hiding the solo mode sound, exit solo mode
                      if sound.isHidden && audioManager.soloModeSound?.id == sound.id {
                        audioManager.exitSoloMode()
                      }
                      // Update hasSelectedSounds to reflect changes in hidden sounds
                      audioManager.updateHasSelectedSounds()
                      soundsUpdateTrigger += 1
                    }
                  )
                }
              }
              .padding()
              .animation(.easeInOut, value: filteredSounds.count)
            }
            .transition(
              .asymmetric(
                insertion: .opacity,
                removal: .opacity
              ))
          }
        }
      }
      .animation(.easeInOut(duration: 0.3), value: audioManager.soloModeSound?.id)
    }
  }
#endif
