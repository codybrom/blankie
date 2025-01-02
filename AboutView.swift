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
                Image(systemName: "square.and.arrow.up.right")
                    .font(.system(size: 8))
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
            Image(systemName: "square.and.arrow.up.right")
                .font(.system(size: 8))
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

// Sound credit model
struct SoundCredit {
    let name: String
    let author: String
    let license: License
    let editor: String?
    let soundUrl: URL?
    
    var attributionText: String {
        let text = "\""
        return text
    }
}

enum License {
    case cc0
    case ccBy
    case ccBySa
    case ccBy3
    case publicDomain
    
    var linkText: String {
        switch self {
        case .cc0: return "CC0"
        case .ccBy: return "CC BY"
        case .ccBySa: return "CC BY-SA"
        case .ccBy3: return "CC BY 3.0"
        case .publicDomain: return "Public Domain"
        }
    }
    
    var url: URL? {
        switch self {
        case .cc0: return URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")
        case .ccBy: return URL(string: "https://creativecommons.org/licenses/by/4.0/")
        case .ccBySa: return URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")
        case .ccBy3: return URL(string: "https://creativecommons.org/licenses/by/3.0/")
        case .publicDomain: return URL(string: "https://wiki.creativecommons.org/wiki/Public_domain")
        }
    }
}

// Sound credits data
let soundCredits: [SoundCredit] = [
    SoundCredit(name: "Birds", author: "kvgarlic", license: .cc0, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/kvgarlic/sounds/156826/")),
    SoundCredit(name: "Boat", author: "Falcet", license: .cc0, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/Falcet/sounds/439365/")),
    SoundCredit(name: "City", author: "gezortenplotz", license: .ccBy, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/gezortenplotz/sounds/44796/")),
    SoundCredit(name: "Coffee Shop", author: "stephan", license: .publicDomain, editor: nil,
                soundUrl: URL(string: "https://soundbible.com/1664-Restaurant-Ambiance.html")),
    SoundCredit(name: "Fireplace", author: "ezwa", license: .publicDomain, editor: nil,
                soundUrl: URL(string: "https://soundbible.com/1543-Fireplace.html")),
    SoundCredit(name: "Pink noise", author: "Omegatron", license: .ccBySa, editor: nil,
                soundUrl: URL(string: "https://es.wikipedia.org/wiki/Archivo:Pink_noise.ogg")),
    SoundCredit(name: "Rain", author: "alex36917", license: .ccBy, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/alex36917/sounds/524605/")),
    SoundCredit(name: "Summer night", author: "Lisa Redfern", license: .publicDomain, editor: nil,
                soundUrl: URL(string: "https://soundbible.com/2083-Crickets-Chirping-At-Night.html")),
    SoundCredit(name: "Storm", author: "Digifish music", license: .ccBy, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/digifishmusic/sounds/41739/")),
    SoundCredit(name: "Stream", author: "gluckose", license: .cc0, editor: nil,
                soundUrl: URL(string: "https://freesound.org/people/gluckose/sounds/333987/")),
    SoundCredit(name: "Train", author: "SDLx", license: .ccBy3, editor: nil,
                soundUrl: URL(string: "https://freesound.org/people/SDLx/sounds/259988/")),
    SoundCredit(name: "Waves", author: "Luftrum", license: .ccBy, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/Luftrum/sounds/48412/")),
    SoundCredit(name: "White noise", author: "Jorge Stolfi", license: .ccBySa, editor: nil,
                soundUrl: URL(string: "https://commons.wikimedia.org/w/index.php?title=File%3AWhite-noise-sound-20sec-mono-44100Hz.ogg")),
    SoundCredit(name: "Wind", author: "felix.blume", license: .cc0, editor: "Porrumentzio",
                soundUrl: URL(string: "https://freesound.org/people/felix.blume/sounds/217506/"))
]

private var softwareLicenseSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("This application comes with absolutely no warranty. This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation.")
            .font(.system(size: 12))
        Link("See the GNU General Public License, version 3 or later for details.", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.en.html")!)
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


