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
  @State private var contributors: [String] = []
  @State private var translators: [String: [String]] = [:]

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
          Text("Blankie", comment: "App name")
            .font(.system(size: 24, weight: .medium, design: .rounded))

          Text(
            LocalizedStringKey("Version \(appVersion) (\(buildNumber))"),
            comment: "Version string"
          )
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
        }

        // Links Section
        HStack(spacing: 16) {
          HStack(spacing: 4) {
            Image(systemName: "globe")
            Link("blankie.rest", destination: URL(string: "https://blankie.rest")!)
              .handCursor()
          }

          Link(destination: URL(string: "https://github.com/codybrom/blankie")!) {
            HStack(spacing: 4) {
              Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
              Text("Star on GitHub", comment: "Star on GitHub label")
            }
          }
          .handCursor()

          HStack(spacing: 4) {
            Link(destination: URL(string: "https://github.com/codybrom/blankie/issues")!) {
              HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(.orange)
                Text("Report an Issue", comment: "Report an issue label")
              }
            }

          }
          .handCursor()

        }
        .font(.system(size: 12))

        inspirationSection

        Divider()
          .padding(.horizontal, 40)

        // Developer Section
        developerSection

        // Contributor Section (when needed)
        if !contributors.isEmpty {
          Divider()
            .padding(.horizontal, 40)
          contributorSection
        }

        // Translator Section (if available)
        if !translators.isEmpty {
          Divider()
            .padding(.horizontal, 40)
          translatorSection
        }

        Divider()
          .padding(.horizontal, 40)

        Text("© 2025 ")
          .font(.caption)
          + Text(
            "Cody Bromley and contributors. All rights reserved.", comment: "Copyright notice"
          )
          .font(.caption)

        // Credits and License Section
        VStack(spacing: 12) {
          ExpandableSection(
            title: "Sound Credits",
            comment: "Expandable section title: Sound Credits",
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
            comment: "Expandable section title: Software License",
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
    .onAppear {
      loadCredits()
    }
  }

  private var developerSection: some View {
    VStack(spacing: 4) {
      Text("Developed By", comment: "Developed by label")
        .font(.system(size: 13, weight: .bold))

      VStack(spacing: 8) {
        Text("Cody Bromley", comment: "Developer name")
          .font(.system(size: 13))

        HStack(spacing: 8) {

          Link(destination: URL(string: "https://www.codybrom.com")!) {
            Text("Website", comment: "Website link label")
          }
          .foregroundColor(.accentColor)
          .handCursor()

          Text("•")
            .foregroundStyle(.secondary)

          Link(destination: URL(string: "https://github.com/codybrom")!) {
            Text("GitHub", comment: "GitHub link label")
          }
          .foregroundColor(.accentColor)
          .handCursor()

        }
        .foregroundColor(.accentColor)
        .font(.system(size: 12))
      }

    }
    .frame(maxWidth: .infinity)
  }

  struct Credits: Codable {
    let contributors: [String]
    let translators: [String: [String]]
  }

  private func loadCredits() {
    guard let url = Bundle.main.url(forResource: "credits", withExtension: "json") else {
      print("Unable to find credits.json in bundle")
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      let credits = try decoder.decode(Credits.self, from: data)
      self.contributors = credits.contributors
      self.translators = credits.translators
    } catch {
      print("Error loading credits: \(error)")
    }
  }

  private var contributorSection: some View {
    VStack(spacing: 8) {  // Standardized spacing
      Text("Contributors", comment: "Contributors section title")
        .font(.system(size: 13, weight: .bold))
        .padding(.bottom, 4)  // Add some space between title and content

      HStack(spacing: 0) {
        ForEach(contributors.indices, id: \.self) { index in
          Text(contributors[index])
            .font(.system(size: 13))

          if index < contributors.count - 1 {
            Text(", ")
              .font(.system(size: 13))
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, 4)  // Consistent bottom padding
  }

  private var translatorSection: some View {
    VStack(spacing: 8) {  // Standardized spacing
      Text("Translations", comment: "Translations section title")
        .font(.system(size: 13, weight: .bold))
        .padding(.bottom, 4)  // Same spacing after title

      // Filter out languages without translators
      let translatedLanguages = translators.filter { !$0.value.isEmpty }.keys.sorted()
      let isOddCount = translatedLanguages.count % 2 != 0

      // Split languages for grid and potential last item
      let gridLanguages = isOddCount ? Array(translatedLanguages.dropLast()) : translatedLanguages
      let lastLanguage = isOddCount ? translatedLanguages.last : nil

      VStack(spacing: 20) {
        // Two-column grid for even items
        if !gridLanguages.isEmpty {
          LazyVGrid(columns: [GridItem(.fixed(150)), GridItem(.fixed(150))], spacing: 20) {
            ForEach(gridLanguages, id: \.self) { language in
              if let translatorList = translators[language], !translatorList.isEmpty {
                VStack(spacing: 4) {
                  Text(language)
                    .font(.system(size: 12, weight: .medium))
                    .italic()
                    .foregroundStyle(.secondary)

                  Text(translatorList.joined(separator: ", "))
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 150, alignment: .center)
              }
            }
          }
          .frame(maxWidth: .infinity)
        }

        // Centered last item if odd count
        if let lastLanguage = lastLanguage,
          let translatorList = translators[lastLanguage], !translatorList.isEmpty
        {
          VStack(spacing: 4) {
            Text(lastLanguage)
              .font(.system(size: 12, weight: .medium))
              .italic()
              .foregroundStyle(.secondary)

            Text(translatorList.joined(separator: ", "))
              .font(.system(size: 13))
              .multilineTextAlignment(.center)
              .lineLimit(3)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(width: 150, alignment: .center)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom, 4)  // Consistent bottom padding
  }

  private var inspirationSection: some View {
    let projectURL = URL(string: "https://github.com/rafaelmardojai/blanket")!

    return Link(destination: projectURL) {
      Text(LocalizedStringKey("Inspired by Blanket by Rafael Mardojai CM"))
        .font(.system(size: 12))
        .italic()
        .tint(.accentColor)
        .handCursor()
    }
  }

  private var soundCreditsSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Sound Credits", comment: "Sound credits section title")
        .font(.system(size: 13, weight: .bold))

      VStack(alignment: .leading, spacing: 4) {
        ForEach(creditsManager.credits, id: \.name) { credit in
          CreditRow(credit: credit)
        }
      }
    }
  }

  private var softwareLicenseSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(
        "This application comes with absolutely no warranty. This program is free software: you can redistribute it and/or modify it under the terms of the MIT License.",
        comment: "License and warranty explainer text"
      )
      .font(.system(size: 12))
      Text(
        "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:",
        comment: "MIT License Section 1"
      )
      .font(.system(size: 12))
      Text(
        "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.",
        comment: "MIT License Section 2"
      )
      .font(.system(size: 12))
      Text(
        "THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.",
        comment: "MIT License Section 3"
      )
      .font(.system(size: 12))
      Link(
        "Learn more about the MIT License",
        destination: URL(string: "https://opensource.org/licenses/MIT")!
      )
      .foregroundColor(.accentColor)
      .font(.system(size: 12))
      .handCursor()
      .onHover { hovering in
        hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
      }
    }
  }

  struct ExpandableSection<Content: View>: View {
    let title: String
    let comment: String
    @Binding var isExpanded: Bool
    let onExpand: () -> Void
    let content: Content
    @State private var isHovering = false

    init(
      title: String,
      comment: String,
      isExpanded: Binding<Bool>,
      onExpand: @escaping () -> Void,
      @ViewBuilder content: () -> Content
    ) {
      self.title = title
      self.comment = comment
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
        // First row with name and sound name
        soundNameView

        // Attribution line
        attributionView
      }
      .font(.system(size: 12))
      .padding(.vertical, 4)
    }

    // Extracted view for the sound name line
    private var soundNameView: some View {
      HStack(spacing: 4) {
        Text(credit.name)
          .fontWeight(.bold)

        Text(" — ")
          .foregroundStyle(.secondary)

        if let soundUrl = credit.soundUrl {
          // With link case
          Text(credit.soundName)
            .foregroundColor(.accentColor)
            .underline()
            .onTapGesture {
              NSWorkspace.shared.open(soundUrl)
            }
            .handCursor()
        } else {
          // Without link case
          Text(credit.soundName)
            .foregroundStyle(.secondary)
        }
      }
    }

    // Extracted view for the attribution line
    private var attributionView: some View {
      HStack(spacing: 4) {
        Text("By", comment: "Attribution by label")
          .foregroundStyle(.secondary)
        Text(credit.author)

        if let editor = credit.editor {
          Text("•").foregroundStyle(.secondary)
          Text("Edited by", comment: "Attribution edited by label")
            .foregroundStyle(.secondary)
          Text(editor)
        }

        if let licenseUrl = credit.license.url {
          Text("•").foregroundStyle(.secondary)
          Link(credit.license.linkText, destination: licenseUrl)
            .help(licenseUrl.absoluteString)
            .foregroundColor(.accentColor)
            .handCursor()
        }
      }
    }
  }
}

struct HandCursorOnHover: ViewModifier {
  func body(content: Content) -> some View {
    #if os(macOS)
      content.onHover { hovering in
        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
      }
    #else
      content
    #endif
  }
}

extension View {
  func handCursor() -> some View {
    self.modifier(HandCursorOnHover())
  }
}

#Preview {
  AboutView()
    .onAppear {
      AudioManager.shared.setPlaybackState(false, forceUpdate: true)
    }
}
