//
//  AboutView.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        VStack(spacing: 20) {
            // Fixed header
            if let appIcon = NSApplication.shared.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 128, height: 128)
            }
            
            Text("Blankie")
                .font(.system(size: 24, weight: .medium, design: .rounded))
            
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                       
            
            inspirationSection

            developerSection
            
            Text("© 2025 Cody Bromley")
                .font(.caption)

            // GroupBox with internal scroll
            GroupBox {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        softwareLicenseSection
                        
                        Divider()
                        
                        soundCreditsSection
                        editingNoteSection
                    }
                    .frame(width: 400)
                    .padding(.vertical, 4)
                }
                .frame(height: 200) // Added fixed height
            }
            .frame(width: 440)
            
            reportIssueSection
            
            // Close button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 480, height: 650)
    }

    private var developerSection: some View {
        VStack(spacing: 4) {
            Text("Developed By")
                .font(.system(size: 13, weight: .bold))
            
            HStack(spacing: 2) {
                Link("Cody Bromley", destination: URL(string: "https://github.com/codybrom")!)
            }
            .foregroundColor(.accentColor)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var reportIssueSection: some View {
        HStack(spacing: 2) {
            Link("Report an Issue", destination: URL(string: "https://github.com/codybrom/blankie/issues")!)
        }
        .foregroundColor(.accentColor)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .font(.system(size: 12))
    }

    private var inspirationSection: some View {
            HStack(spacing: 4) {
                Text("Inspired by")
                    .font(.system(size: 12))
                    .italic()
        
                Link("Blanket", destination: URL(string: "https://github.com/rafaelmardojai/blanket")!)
                    .foregroundColor(.accentColor)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
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
                ForEach(soundCredits, id: \.name) { credit in
                    CreditRow(credit: credit)
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
                            Link(credit.name, destination: soundUrl)
                        }
                        .foregroundColor(.accentColor)
                        .onHover { inside in
                            if inside {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
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
                        Link(credit.license.linkText, destination: url)
                    }
                    .foregroundColor(.accentColor)
                    .onHover { inside in
                        if inside {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                } else {
                    Text(credit.license.linkText)
                }
                Text(")")
            }
            .font(.system(size: 12))
        }
    }

    
    private var editingNoteSection: some View {
        Text("Note: Sound editing involved optimizing audio levels and characteristics according to established guidelines for ambient sound playback.")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .italic()
    }
}

private var softwareLicenseSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("This application comes with absolutely no warranty. This program is free software: you can redistribute it and/or modify it under the terms of the MIT License.")
            .font(.system(size: 12))
        Link("See the MIT License for details.", destination: URL(string: "https://opensource.org/licenses/MIT")!)
        .foregroundColor(.accentColor)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .font(.system(size: 12))
    }
}

#Preview {
    AboutView()
}


