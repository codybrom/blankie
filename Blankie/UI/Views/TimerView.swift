//
//  TimerView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/29/25.
//

import SwiftUI

struct TimerView: View {
  @StateObject private var timerManager = TimerManager.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 20) {
      Text("Timer")
        .font(.title2)
        .fontWeight(.semibold)

      if timerManager.isTimerActive {
        activeTimerView
      } else {
        timerSelectionView
      }
    }
    .padding()
    .frame(width: 300, height: 350)
    #if os(macOS)
      .background(Color(NSColor.windowBackgroundColor))
    #endif
  }

  private var activeTimerView: some View {
    VStack(spacing: 25) {
      Text("Time Remaining")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text(timerManager.formatRemainingTime())
        .font(.system(size: 48, weight: .light, design: .rounded))
        .monospacedDigit()

      Text("Blankie will pause playback when timer expires")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button(action: {
        timerManager.stopTimer()
        dismiss()
      }) {
        Label("Cancel Timer", systemImage: "xmark.circle.fill")
          .frame(width: 140)
      }
      .controlSize(.large)
    }
  }

  private var timerSelectionView: some View {
    VStack(spacing: 20) {
      Text("Blankie will pause playback when timer expires")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      HStack(spacing: 20) {
        VStack {
          Text("Hours")
            .font(.caption)
            .foregroundColor(.secondary)
          Picker("Hours", selection: $timerManager.selectedHours) {
            ForEach(0...23, id: \.self) { hour in
              Text(verbatim: "\(hour)")
                .tag(hour)
            }
          }
          .labelsHidden()
          #if os(macOS)
            .frame(width: 60)
          #else
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
          #endif
        }

        Text(verbatim: ":")
          .font(.title2)

        VStack {
          Text("Minutes")
            .font(.caption)
            .foregroundColor(.secondary)
          Picker("Minutes", selection: $timerManager.selectedMinutes) {
            ForEach(0...59, id: \.self) { minute in
              Text(verbatim: String(format: "%02d", minute))
                .tag(minute)
            }
          }
          .labelsHidden()
          #if os(macOS)
            .frame(width: 60)
          #else
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
          #endif
        }
      }

      HStack(spacing: 20) {
        Button(action: {
          dismiss()
        }) {
          Text("Cancel")
            .frame(width: 100)
        }
        .controlSize(.large)
        .keyboardShortcut(.cancelAction)

        Button(action: {
          let totalSeconds = TimeInterval(
            timerManager.selectedHours * 3600 + timerManager.selectedMinutes * 60)
          if totalSeconds > 0 {
            timerManager.startTimer(duration: totalSeconds)
            dismiss()
          }
        }) {
          Label("Start Timer", systemImage: "timer")
            .frame(width: 140)
        }
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
        .disabled(timerManager.selectedHours == 0 && timerManager.selectedMinutes == 0)
      }
    }
  }
}

#if os(iOS) || os(visionOS)
  struct TimerSheetView: View {
    @StateObject private var timerManager = TimerManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
      NavigationView {
        VStack(spacing: 20) {
          if timerManager.isTimerActive {
            activeTimerContent
          } else {
            timerSelectionContent
          }
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
    }

    private var activeTimerContent: some View {
      VStack(spacing: 30) {
        Spacer()

        Text("Time Remaining")
          .font(.headline)
          .foregroundColor(.secondary)

        Text(timerManager.formatRemainingTime())
          .font(.system(size: 64, weight: .light, design: .rounded))
          .monospacedDigit()

        Text("Blankie will pause playback when timer expires")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)

        Spacer()

        Button(action: {
          timerManager.stopTimer()
        }) {
          Label("Cancel Timer", systemImage: "xmark.circle.fill")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(10)
        }
        .padding(.horizontal)
      }
    }

    private var timerSelectionContent: some View {
      VStack(spacing: 30) {
        Text("Blankie will pause playback when timer expires")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

        HStack(spacing: 30) {
          VStack {
            Text("Hours")
              .font(.caption)
              .foregroundColor(.secondary)
            Picker("Hours", selection: $timerManager.selectedHours) {
              ForEach(0...23, id: \.self) { hour in
                Text(verbatim: "\(hour)")
                  .tag(hour)
              }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 150)
            .labelsHidden()
          }

          Text(verbatim: ":")
            .font(.largeTitle)
            .padding(.top, 20)

          VStack {
            Text("Minutes")
              .font(.caption)
              .foregroundColor(.secondary)
            Picker("Minutes", selection: $timerManager.selectedMinutes) {
              ForEach(0...59, id: \.self) { minute in
                Text(verbatim: String(format: "%02d", minute))
                  .tag(minute)
              }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 150)
            .labelsHidden()
          }
        }

        Button(action: {
          let totalSeconds = TimeInterval(
            timerManager.selectedHours * 3600 + timerManager.selectedMinutes * 60)
          if totalSeconds > 0 {
            timerManager.startTimer(duration: totalSeconds)
            dismiss()
          }
        }) {
          Label("Start Timer", systemImage: "timer")
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .disabled(timerManager.selectedHours == 0 && timerManager.selectedMinutes == 0)
      }
    }
  }
#endif

struct TimerView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      #if os(macOS)
        TimerView()
          .previewDisplayName("macOS Timer")
      #else
        TimerSheetView()
          .previewDisplayName("iOS Timer")
      #endif
    }
  }
}
