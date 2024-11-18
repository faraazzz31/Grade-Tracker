//
//  Grade_TrackerApp.swift
//  Grade Tracker
//
//  Created by Faraaz Ahmed on 11/3/24.
//

import SwiftUI

@main
struct Grade_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Course") {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowAddCourse"),
                        object: nil
                    )
                }
                .keyboardShortcut("n")
            }
        }
    }
}
