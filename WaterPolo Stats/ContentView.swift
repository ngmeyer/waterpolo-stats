//
//  ContentView.swift
//  WaterPolo Stats
//
//  Created by Neal Meyer on 10/25/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 1  // Start on Simple Game tab
    @State private var useSimpleMode = true
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Games List (Historical)
            GameListView()
                .tabItem {
                    Label("Games", systemImage: "list.bullet")
                }
                .tag(0)
            
            // Tab 1: Live Scoring (Simple Mode - Default)
            SimpleGameView()
                .tabItem {
                    Label("Score", systemImage: "sportscourt.fill")
                }
                .tag(1)
            
            // Tab 2: Full Stats Mode
            NavigationView {
                GameView()
            }
            .tabItem {
                Label("Full Stats", systemImage: "chart.bar")
            }
            .tag(2)
            
            // Tab 3: Teams
            TeamListView()
                .tabItem {
                    Label("Teams", systemImage: "person.3")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
