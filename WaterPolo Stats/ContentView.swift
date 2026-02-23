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
    @State private var selectedTab = 0  // Start on Games List
    @State private var useSimpleMode = true
    @State private var showOnboarding = false
    @State private var onboardingGame: GameSession?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            mainContent
            
            if showOnboarding {
                OnboardingView { game in
                    onboardingGame = game
                    showOnboarding = false
                    hasCompletedOnboarding = true
                    // TODO: Start game with this session
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
    
    private var mainContent: some View {
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
            
            // Tab 4: Seasons
            SeasonListView()
                .tabItem {
                    Label("Seasons", systemImage: "calendar")
                }
                .tag(4)
            
            // Tab 5: Settings
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(5)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
