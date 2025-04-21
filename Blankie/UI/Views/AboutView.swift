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
          .help(NSLocalizedString("Close", comment: "Close about window button"))
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
          Text(NSLocalizedString("Blankie", comment: "App name"))
            .font(.system(size: 24, weight: .medium, design: .rounded))

          Text(
            String(
              format: NSLocalizedString("Version %@ (%@)", comment: "Version string"), appVersion,
              buildNumber)
          )
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
              Text(NSLocalizedString("Star on GitHub", comment: "Star on GitHub label"))
            }
          }
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            LinkWithTooltip(
              title: NSLocalizedString("Report an Issue", comment: "Report an issue label"),
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

        Text("© 2025 ")
          .font(.caption)
          + Text(
            NSLocalizedString(
              "Cody Bromley and contributors. All rights reserved.", comment: "Copyright notice")
          )
          .font(.caption)

        // Credits and License Section
        VStack(spacing: 12) {
          ExpandableSection(
            title: NSLocalizedString(
              "Sound Credits", comment: "Expandable section title: Sound Credits"),
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
            title: NSLocalizedString(
              "Software License", comment: "Expandable section title: Software License"),
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
      Text(NSLocalizedString("Developed By", comment: "Developed by label"))
        .font(.system(size: 13, weight: .bold))

      VStack(spacing: 8) {
        Text(NSLocalizedString("Cody Bromley", comment: "Developer name"))
          .font(.system(size: 13))

        HStack(spacing: 8) {

          LinkWithTooltip(
            title: NSLocalizedString("Website", comment: "Website link label"),
            destination: URL(string: "https://www.codybrom.com")!
          )

          Text("•")
            .foregroundStyle(.secondary)

          LinkWithTooltip(
            title: NSLocalizedString("GitHub", comment: "GitHub link label"),
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
    let author = "Rafael Mardojai CM"
    let formatString = NSLocalizedString(
      "Inspired by <project> by %@", comment: "Inspired by <project> by <author>")
    let parts = formatString.components(separatedBy: "<project>")
    return HStack(spacing: 4) {
      if parts.count == 2 {
        Text(parts[0])
          .font(.system(size: 12))
          .italic()
          .foregroundColor(.primary)
        LinkWithTooltip(
          title: "Blanket",
          destination: URL(string: "https://github.com/rafaelmardojai/blanket")!
        )
        .foregroundColor(.accentColor)
        Text(String(format: parts[1], author))
          .font(.system(size: 12))
          .italic()
          .foregroundColor(.primary)
      } else {
        // Fallback for unexpected localization format
        Text(
          String(
            format: NSLocalizedString(
              "Inspired by %@ by %@", comment: "Inspired by <project> by <author>"),
            "Blanket", author)
        )
        .font(.system(size: 12))
        .italic()
        .foregroundColor(.primary)
      }
    }
    .font(.system(size: 12))
    .italic()
  }

  private var soundCreditsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(NSLocalizedString("Sound Credits", comment: "Sound credits section title"))
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
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {

          Text(credit.name)
            .fontWeight(.bold)
          Text("—")
            .foregroundStyle(.secondary)
          if let soundUrl = credit.soundUrl {
            LinkWithTooltip(
              title: credit.soundName,
              destination: soundUrl
            )
            .foregroundColor(.accentColor)
          } else {
            Text(credit.soundName)
              .foregroundStyle(.secondary)
          }
        }

        // Attribution line
        HStack(spacing: 4) {
          Text(NSLocalizedString("By", comment: "Attribution by label"))
            .foregroundStyle(.secondary)
          Text(credit.author)
          if let editor = credit.editor {
            Text("•")
              .foregroundStyle(.secondary)
            Text(NSLocalizedString("Edited by", comment: "Attribution edited by label"))
              .foregroundStyle(.secondary)
            Text(editor)
          }
          if let licenseUrl = credit.license.url {
            Text("•")
              .foregroundStyle(.secondary)
            LinkWithTooltip(
              title: credit.license.linkText,
              destination: licenseUrl
            )
            .foregroundColor(.accentColor)
          }
        }
      }
      .font(.system(size: 12))
      .padding(.vertical, 4)
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
