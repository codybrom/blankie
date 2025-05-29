//
//  TimerButton.swift
//  Blankie
//
//  Created by Cody Bromley on 1/29/25.
//

import SwiftUI

struct TimerButton: View {
  @StateObject private var timerManager = TimerManager.shared
  @State private var showingTimerView = false

  var body: some View {
    Button(action: {
      showingTimerView = true
    }) {
      Image(systemName: "timer")
        .fontWeight(timerManager.isTimerActive ? .bold : .regular)
        .foregroundStyle(timerManager.isTimerActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }
    .buttonStyle(.borderless)
    #if os(macOS)
      .popover(isPresented: $showingTimerView, arrowEdge: .bottom) {
        TimerView()
      }
    #else
      .sheet(isPresented: $showingTimerView) {
        TimerSheetView()
        .presentationDetents([.medium, .large])
      }
    #endif
  }
}

struct CompactTimerButton: View {
  @StateObject private var timerManager = TimerManager.shared
  @State private var showingTimerView = false

  var body: some View {
    Button(action: {
      showingTimerView = true
    }) {
      ZStack {
        Image(systemName: "timer")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 20, height: 20)
          .fontWeight(timerManager.isTimerActive ? .bold : .regular)
          .foregroundStyle(timerManager.isTimerActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))

        if timerManager.isTimerActive {
          Circle()
            .fill(.tint)
            .frame(width: 8, height: 8)
            .offset(x: 8, y: -8)
        }
      }
    }
    .buttonStyle(.borderless)
    #if os(macOS)
      .popover(isPresented: $showingTimerView, arrowEdge: .bottom) {
        TimerView()
      }
    #else
      .sheet(isPresented: $showingTimerView) {
        TimerSheetView()
        .presentationDetents([.medium, .large])
      }
    #endif
  }
}
