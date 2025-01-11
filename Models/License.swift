//
//  License.swift
//  Blankie
//
//  Created by Cody Bromley on 1/10/25.
//

import Foundation

enum License: String {
    case cc0 = "cc0"
    case ccBy = "ccby"
    case ccBySa = "ccbysa"
    case ccBy3 = "ccby3"
    case publicDomain = "publicdomain"

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
