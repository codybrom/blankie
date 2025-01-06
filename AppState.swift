//
//  AppState.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//

import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isAboutViewPresented = false

    private init() {}
}
