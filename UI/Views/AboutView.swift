//
//  AboutView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct AboutView: View {
  @ObservedObject private var creditsManager = SoundCreditsManager.shared
  @Environment(\.dismiss) private var dismiss
  @State private var isSoundCreditsExpanded = false
  @State private var isLicenseExpanded = false

  private let appVersion =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Header with Close button
        HStack {
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
              .imageScale(.large)
          }
          .buttonStyle(.plain)
          .help("Close")
          .keyboardShortcut(.defaultAction)
        }
        .padding(.bottom, -8)

        // App Icon
        if let appIcon = NSApplication.shared.applicationIconImage {
          Image(nsImage: appIcon)
            .resizable()
            .frame(width: 128, height: 128)
        }

        // App Info Section
        VStack(spacing: 8) {
          Text("Blankie")
            .font(.system(size: 24, weight: .medium, design: .rounded))

          Text("Version \(appVersion) (\(buildNumber))")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }

        // Links Section
        HStack(spacing: 16) {
          HStack(spacing: 4) {
            Image(systemName: "globe")
            LinkWithTooltip(
              title: "blankie.rest",
              destination: URL(string: "https://blankie.rest")!
            )
          }

          LinkWithTooltip(
            destination: URL(string: "https://github.com/codybrom/blankie")!
          ) {
            HStack(spacing: 4) {
              Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
              Text("Star on GitHub")
            }
          }
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            LinkWithTooltip(
              title: "Report an Issue",
              destination: URL(string: "https://github.com/codybrom/blankie/issues")!
            )
          }
        }
        .font(.system(size: 12))

        inspirationSection

        Divider()
          .padding(.horizontal, 40)

        // Developer Section with Report Issue
        VStack(spacing: 16) {
          developerSection
        }

        Text("© 2025 Cody Bromley. All rights reserved.")
          .font(.caption)

        // Credits and License Section
        VStack(spacing: 12) {
          ExpandableSection(
            title: "Sound Credits",
            isExpanded: $isSoundCreditsExpanded,
            onExpand: {
              // Close other section when this one opens
              isLicenseExpanded = false
            }
          ) {
            VStack(alignment: .leading, spacing: 4) {
              ForEach(creditsManager.credits, id: \.name) { credit in
                CreditRow(credit: credit)
              }
            }
          }

          ExpandableSection(
            title: "Software License",
            isExpanded: $isLicenseExpanded,
            onExpand: {
              // Close other section when this one opens
              isSoundCreditsExpanded = false
            }
          ) {
            softwareLicenseSection
          }
        }
      }
      .padding(20)
    }
    .frame(width: 480, height: 650)
  }

  private var developerSection: some View {
    VStack(spacing: 4) {
      Text("Developed By")
        .font(.system(size: 13, weight: .bold))

      VStack(spacing: 8) {
        Text("Cody Bromley")
          .font(.system(size: 13))

        HStack(spacing: 8) {

          LinkWithTooltip(
            title: "Website",
            destination: URL(string: "https://www.codybrom.com")!
          )

          Text("•")
            .foregroundStyle(.secondary)

          LinkWithTooltip(
            title: "GitHub",
            destination: URL(string: "https://github.com/codybrom")!
          )

        }
        .foregroundColor(.accentColor)
        .font(.system(size: 12))
      }

    }
    .frame(maxWidth: .infinity)
  }

  private var inspirationSection: some View {
    HStack(spacing: 4) {
      Text("Inspired by")
        .font(.system(size: 12))
        .italic()

      LinkWithTooltip(
        title: "Blanket",
        destination: URL(string: "https://github.com/rafaelmardojai/blanket")!
      )
      .foregroundColor(.accentColor)
      Text("by Rafael Mardojai CM")
    }
    .font(.system(size: 12))
    .italic()
  }

  private var soundCreditsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Sound Credits")
        .font(.system(size: 13, weight: .bold))

      VStack(alignment: .leading, spacing: 4) {
        ForEach(creditsManager.credits, id: \.name) { credit in
          CreditRow(credit: credit)
        }
      }
    }
  }

  struct ExpandableSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let onExpand: () -> Void
    let content: Content
    @State private var isHovering = false

    init(
      title: String,
      isExpanded: Binding<Bool>,
      onExpand: @escaping () -> Void,
      @ViewBuilder content: () -> Content
    ) {
      self.title = title
      self._isExpanded = isExpanded
      self.onExpand = onExpand
      self.content = content()
    }

    var body: some View {
      GroupBox {
        VStack(spacing: 0) {
          // Header Button
          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              if !isExpanded {
                onExpand()  // Close other sections
              }
              isExpanded.toggle()
            }
          }) {
            HStack {
              Text(title)
                .font(.system(size: 13, weight: .bold))
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .imageScale(.small)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .onHover { hovering in
            isHovering = hovering
            if hovering {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }

          // Expanded Content
          if isExpanded {
            Divider()
              .padding(.horizontal, -8)

            content
              .padding(.top, 12)
              .padding(.horizontal, 4)
          }
        }
      }
    }
  }

  struct CreditRow: View {
    let credit: SoundCredit

    var body: some View {
      HStack(alignment: .top, spacing: 0) {
        Text("• ")
        Group {
          if let soundUrl = credit.soundUrl {
            HStack(spacing: 2) {
              LinkWithTooltip(
                title: credit.name,
                destination: soundUrl
              )
              .foregroundColor(.accentColor)
            }
            .foregroundColor(.accentColor)
          } else {
            Text(credit.name)
          }
        }
        Text(" by ")
        Text(credit.author)
        if let editor = credit.editor {
          Text(", edited by ")
          Text(editor)
        }
        Text(" (")
        if let url = credit.license.url {
          HStack(spacing: 2) {
            LinkWithTooltip(
              title: credit.license.linkText,
              destination: url
            )
          }
          .foregroundColor(.accentColor)
        } else {
          Text(credit.license.linkText)
        }
        Text(")")
      }
      .font(.system(size: 12))
    }
  }
}

private var softwareLicenseSection: some View {
  VStack(alignment: .leading, spacing: 8) {
    Text(
      "This application comes with absolutely no warranty. This program is free software: you can redistribute it and/or modify it under the terms of the MIT License."
    )
    .font(.system(size: 12))
    Text(
      "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
    )
    .font(.system(size: 12))
    Text(
      "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
    )
    .font(.system(size: 12))
    Link(
      "See the MIT License for details.",
      destination: URL(string: "https://opensource.org/licenses/MIT")!
    )
    .pointingHandCursor()
    .foregroundColor(.accentColor)
    .font(.system(size: 12))
  }
}

struct LinkWithTooltip<Label: View>: View {
  let destination: URL
  let label: Label

  init(destination: URL, @ViewBuilder label: () -> Label) {
    self.destination = destination
    self.label = label()
  }

  // Convenience init for simple text links
  init(title: String, destination: URL) where Label == Text {
    self.destination = destination
    self.label = Text(title)
  }

  var body: some View {
    Link(destination: destination) {
      label
    }
    .pointingHandCursor()
    .help(destination.absoluteString)
  }
}

#Preview {
  AboutView()
    .onAppear {
      AudioManager.shared.setPlaybackState(false, forceUpdate: true)
    }
}
