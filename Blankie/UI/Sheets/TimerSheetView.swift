//
//  TimerSheetView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/7/25.
//

import SwiftUI

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
            .background(.tint)
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
            .background(.tint)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .disabled(timerManager.selectedHours == 0 && timerManager.selectedMinutes == 0)
      }
    }
  }
#endif
