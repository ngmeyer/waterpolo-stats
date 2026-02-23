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
    @ObservedObject var persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if persistenceController.isReady {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .transition(.opacity)
            } else {
                splashView
            }
        }
    }

    private var splashView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            Text("Water Polo Stats")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
