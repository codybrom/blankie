//
//  MainMenu.swift
//  Blankie
//
//  Created by Cody Bromley on 1/1/25.
//


import SwiftUI

class MainMenu: NSObject {
    static func customize(showingAbout: Binding<Bool>) {
        guard let mainMenu = NSApp.mainMenu,
              let applicationMenu = mainMenu.items.first?.submenu else {
            return
        }
        
        // Find and modify the About item
        if let aboutItem = applicationMenu.items.first(where: { $0.identifier?.rawValue == "about" }) {
            aboutItem.target = nil
            aboutItem.action = #selector(NSApplication.sendAction(_:to:from:))
            aboutItem.target = NSApp
            aboutItem.action = #selector(trigger)
            
            // Store the binding in a way that's accessible to the selector
            UserDefaults.standard.set(true, forKey: "UseCustomAbout")
        }
    }
    
    @objc static func trigger() {
        if UserDefaults.standard.bool(forKey: "UseCustomAbout") {
            NotificationCenter.default.post(name: .showCustomAbout, object: nil)
        }
    }
}

extension Notification.Name {
    static let showCustomAbout = Notification.Name("ShowCustomAbout")
}
