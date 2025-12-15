//
//  AI_Live_Trainer_SystemApp.swift
//  AI Live Trainer System
//
//  Created on 2025
//

import SwiftUI
import SwiftData

@main
struct AI_Live_Trainer_SystemApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutModel.self,
            WorkoutSession.self,
            UserStats.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

