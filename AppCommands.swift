//
//  AppCommands.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//


import SwiftUI

struct AppCommands: Commands {
    @Binding var showingAbout: Bool
    @Binding var hasWindow: Bool
    
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Blankie") {
                showingAbout = true
            }
        }
        
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                if !hasWindow {
                    let controller = NSWindowController(
                        window: NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 600, height: 800),
                            styleMask: [.titled, .closable, .miniaturizable, .resizable],
                            backing: .buffered,
                            defer: false
                        )
                    )
                    controller.window?.center()
                    let hostingView = NSHostingView(rootView: ContentView(showingAbout: $showingAbout))
                    controller.window?.contentView = hostingView
                    controller.showWindow(nil)
                    hasWindow = true
                }
            }
            .disabled(hasWindow)
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
