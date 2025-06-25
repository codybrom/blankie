//
//  SharedModifiers.swift
//  Blankie
//
//  Created by Cody Bromley on 6/17/25.
//

import SwiftUI

/// Shared view modifiers for all platforms
struct SharedAppModifiers: ViewModifier {
  let appSetup: AppSetup
  let globalSettings: GlobalSettings
  @StateObject private var audioFileImporter = AudioFileImporter.shared

  func body(content: Content) -> some View {
    content
      .onAppear {
        Task { @MainActor in
          appSetup.setupManagers()
        }
      }
      .accentColor(globalSettings.customAccentColor ?? .accentColor)
      .onOpenURL { url in
        audioFileImporter.handleIncomingFile(url)
      }
      .sheet(isPresented: $audioFileImporter.showingSoundSheet) {
        SoundSheet(mode: .add, preselectedFile: audioFileImporter.fileToImport)
          .onDisappear {
            audioFileImporter.clearImport()
          }
      }
  }
}

extension View {
  func sharedAppModifiers(appSetup: AppSetup, globalSettings: GlobalSettings) -> some View {
    modifier(SharedAppModifiers(appSetup: appSetup, globalSettings: globalSettings))
  }
}
