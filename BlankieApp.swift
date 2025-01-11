//
//  BlankieApp.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftData
import SwiftUI

@main
struct BlankieApp: App {
  @StateObject private var audioManager = AudioManager.shared
  @StateObject private var windowObserver = WindowObserver.shared
  @State private var showingAbout = false
  @State private var showingShortcuts = false

  var body: some Scene {
    WindowGroup {
      WindowDefaults.defaultContentView(
        showingAbout: $showingAbout,
        showingShortcuts: $showingShortcuts
      )
    }
    .defaultSize(width: WindowDefaults.defaultWidth, height: WindowDefaults.defaultHeight)
    .windowToolbarStyle(.unified)
    .commands {
      AppCommands(showingAbout: $showingAbout, hasWindow: $windowObserver.hasVisibleWindow)
    }

    Settings {
      PreferencesView()
    }
  }
}

#if DEBUG
  struct BlankieApp_Previews: PreviewProvider {
    static var previews: some View {
      ContentView(showingAbout: .constant(false))
        .frame(minWidth: 400, minHeight: 275)
        .toolbar {
          ToolbarItem(placement: .principal) {
            Text("Blankie")
              .font(.system(size: 15, weight: .medium, design: .rounded))
              .foregroundStyle(.primary)
          }
        }
    }
  }
#endif
