//
//  WaterPolo_StatsApp.swift
//  WaterPolo Stats
//
//  Created by Neal Meyer on 10/25/25.
//

import SwiftUI
import CoreData

@main
struct WaterPolo_StatsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
