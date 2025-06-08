//
//  ProgressBorderView.swift
//  Blankie
//
//  Created by Cody Bromley on 6/8/25.
//

import SwiftUI

struct ProgressBorderView: View {
  let iconSize: CGFloat
  let borderWidth: CGFloat
  let playbackProgress: Double
  let color: Color

  var body: some View {
    Circle()
      .trim(from: 0, to: playbackProgress)
      .stroke(
        color,
        style: StrokeStyle(
          lineWidth: borderWidth,
          lineCap: .round
        )
      )
      .frame(width: iconSize, height: iconSize)
      .rotationEffect(.degrees(-90))
      .animation(.linear(duration: 0.1), value: playbackProgress)
  }
}
