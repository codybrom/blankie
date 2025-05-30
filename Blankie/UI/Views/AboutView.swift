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
    Group {
      #if os(iOS)
        NavigationView {
          aboutContent
            .navigationTitle("About Blankie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
              ToolbarItem(placement: .primaryAction) {
                Button("Done") { dismiss() }
              }
            }
        }
      #else
        aboutContent
          .frame(width: 480, height: 650)
      #endif
    }
  }

  private var aboutContent: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Header with Close button (macOS only)
        #if os(macOS)
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
        #endif

        // App Icon
        Group {
          #if os(iOS)
            if let aboutIcon = UIImage(named: "AboutIcon") {
              Image(uiImage: aboutIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .cornerRadius(20)
            }
          #elseif os(macOS)
            if let appIcon = NSApplication.shared.applicationIconImage {
              Image(nsImage: appIcon)
                .resizable()
                .frame(width: 128, height: 128)
            }
          #endif
        }

        // App Info Section
        VStack(spacing: 8) {
          Text(verbatim: "Blankie")
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

        InspirationSection()

        Divider()
          .padding(.horizontal, 40)

        // Developer Section
        DeveloperSection()

        // Contributor Section (when needed)
        if !contributors.isEmpty {
          Divider()
            .padding(.horizontal, 40)
          ContributorSection(contributors: contributors)
        }

        // Translator Section (if available)
        if !translators.isEmpty {
          Divider()
            .padding(.horizontal, 40)
          TranslatorSection(translators: translators)
        }

        Divider()
          .padding(.horizontal, 40)

        Text(verbatim: "© 2025 ")
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
            SoftwareLicenseSection()
          }
        }
      }
      .padding(20)
    }
    .onAppear {
      loadCredits()
    }
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

}

#Preview {
  AboutView()
    .onAppear {
      AudioManager.shared.setPlaybackState(false, forceUpdate: true)
    }
}
