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
    @State private var selectedTab = 0
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
        // Auto-navigate when a game is loaded or ends
        .onChange(of: gameViewModel.game.status) { _, newStatus in
            switch newStatus {
            case .ready, .inProgress:
                selectedTab = 1
            case .completed:
                if selectedTab == 1 || selectedTab == 2 { selectedTab = 0 }
            case .paused:
                break
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            GameListView()
                .environmentObject(gameViewModel)
                .tabItem { Label("Games", systemImage: "list.bullet") }
                .tag(0)

            if hasActiveGame {
                SimpleGameView()
                    .environmentObject(gameViewModel)
                    .tabItem { Label("Score", systemImage: "sportscourt.fill") }
                    .tag(1)

                GameView()
                    .environmentObject(gameViewModel)
                    .tabItem { Label("Full Stats", systemImage: "chart.bar") }
                    .tag(2)
            }

            TeamListView()
                .tabItem { Label("Teams", systemImage: "person.3") }
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
