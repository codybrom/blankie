//
//  SoundCredit.swift
//  Blankie
//
//  Created by Cody Bromley on 1/2/25.
//

import SwiftUI


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
