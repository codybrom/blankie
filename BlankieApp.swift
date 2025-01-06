//
//  BlankieApp.swift
//  Blankie
//
//  Created by Cody Bromley on 12/30/24.
//

import SwiftUI
import SwiftData

@main
struct BlankieApp: App {
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var windowObserver = WindowObserver.shared
    @State private var showingAbout = false

    var body: some Scene {
        WindowGroup {
            ContentView(showingAbout: $showingAbout)
                .frame(minWidth: 320, minHeight: 275)
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Blankie")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
        }
        .defaultSize(width: 600, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(showingAbout: $showingAbout, hasWindow: $windowObserver.hasVisibleWindow)
        }

        MenuBarExtra("Blankie", systemImage: "waveform") {
            Button("Show Main Window") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("About Blankie") {
                NSApp.activate(ignoringOtherApps: true)
                showingAbout = true
            }

            Divider()

            Button("Quit Blankie") {
                NSApplication.shared.terminate(nil)
            }
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
            .frame(minWidth: 320, minHeight: 275)
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
