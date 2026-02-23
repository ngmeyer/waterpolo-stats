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
    @StateObject private var gameViewModel = GameViewModel()
    @State private var selectedTab = 3   // default to Games tab
    @State private var showOnboarding = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var hasActiveGame: Bool {
        let s = gameViewModel.game.status
        return s == .ready || s == .inProgress || s == .paused
    }

    var body: some View {
        ZStack {
            mainContent

            if showOnboarding {
                OnboardingView { game in
                    showOnboarding = false
                    hasCompletedOnboarding = true
                    gameViewModel.loadGame(game)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        // Auto-navigate and persist when game status changes
        .onChange(of: gameViewModel.game.status) { _, newStatus in
            switch newStatus {
            case .ready:
                selectedTab = 0   // jump to Score tab as soon as game is configured
            case .inProgress:
                selectedTab = 0
                // Persist immediately so the game shows in the Games list
                gameViewModel.game.saveToCoreData(context: viewContext)
            case .completed:
                if selectedTab == 0 || selectedTab == 1 { selectedTab = 3 }  // back to Games
            case .paused:
                break
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            if hasActiveGame {
                SimpleGameView()
                    .environmentObject(gameViewModel)
                    .tabItem { Label("Score", systemImage: "sportscourt.fill") }
                    .tag(0)

                GameView()
                    .environmentObject(gameViewModel)
                    .tabItem { Label("Game Stats", systemImage: "chart.bar") }
                    .tag(1)
            }

            TeamListView()
                .tabItem { Label("Teams", systemImage: "person.3") }
                .tag(2)

            GameListView()
                .environmentObject(gameViewModel)
                .tabItem { Label("Games", systemImage: "list.bullet") }
                .tag(3)

            SeasonListView()
                .tabItem { Label("Seasons", systemImage: "calendar") }
                .tag(4)

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(5)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
