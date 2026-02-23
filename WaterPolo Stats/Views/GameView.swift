import SwiftUI

struct GameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: GameViewModel
    @State private var showSettings = false
    @State private var showExportOptions = false
    @State private var showMaxPrepsExport = false
    @State private var showClubExport = false
    @State private var showSaveConfirmation = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scoreboard
                HStack(spacing: 0) {
                    TeamScoreView(
                        team: viewModel.game.homeTeam,
                        score: viewModel.game.homeScore,
                        isSelected: viewModel.selectedTeam == .home,
                        action: { viewModel.selectedTeam = .home }
                    )
                    
                    TeamScoreView(
                        team: viewModel.game.awayTeam,
                        score: viewModel.game.awayScore,
                        isSelected: viewModel.selectedTeam == .away,
                        action: { viewModel.selectedTeam = .away }
                    )
                }
                .padding(.vertical)
                
                // Game Info
                GameInfoView(
                    period: viewModel.game.period,
                    gameClock: viewModel.game.gameClock,
                    shotClock: viewModel.game.shotClock,
                    isGameActive: viewModel.game.isGameActive
                )
                .padding()
                .background(Color(.systemGray6))
                
                // Action Buttons
                ActionButtonsView(
                    isGameActive: viewModel.game.isGameActive,
                    isTimerRunning: viewModel.isTimerRunning,
                    onStartGame: viewModel.startGame,
                    onPauseGame: viewModel.pauseGame,
                    onResumeGame: viewModel.resumeGame,
                    onEndGame: {
                        viewModel.endGame()
                        showSaveConfirmation = true
                    },
                    onNextPeriod: viewModel.startNextPeriod
                )
                .padding()
                
                // Player Stats
                PlayerStatsView(
                    players: viewModel.selectedTeam == .home ? 
                        viewModel.game.homeTeam.players : 
                        viewModel.game.awayTeam.players,
                    onPlayerSelected: { player in
                        viewModel.selectedPlayer = player
                        viewModel.showPlayerSelection = true
                    }
                )
                
                Spacer()
            }
            .navigationTitle("Water Polo Scorer")
            .navigationBarItems(
                leading: Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                },
                trailing: Button(action: { showExportOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            )
            .sheet(isPresented: $viewModel.showPlayerSelection) {
                if let player = viewModel.selectedPlayer {
                    PlayerActionSheet(
                        player: player,
                        onGoal: { viewModel.scoreGoal(for: viewModel.selectedTeam, player: player) },
                        onAssist: { viewModel.recordAssist(for: viewModel.selectedTeam, player: player) },
                        onSteal: { viewModel.recordSteal(for: viewModel.selectedTeam, player: player) },
                        onExclusion: { viewModel.recordExclusion(for: viewModel.selectedTeam, player: player) }
                    )
                }
            }
            .actionSheet(isPresented: $showExportOptions) {
                ActionSheet(
                    title: Text("Export Game Data"),
                    buttons: [
                        .default(Text("Export to MaxPreps")) {
                            exportData = viewModel.exportToMaxPreps()
                            showMaxPrepsExport = true
                        },
                        .default(Text("Export for Club Water Polo")) {
                            exportData = viewModel.exportToClubWaterPolo()
                            showClubExport = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsViewStandalone(isSunlightMode: .constant(false))
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showMaxPrepsExport) {
                if let data = exportData, 
                   let jsonString = String(data: data, encoding: .utf8) {
                    TextEditor(text: .constant(jsonString))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .navigationTitle("MaxPreps Export")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showMaxPrepsExport = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showClubExport) {
                if let data = exportData, 
                   let jsonString = String(data: data, encoding: .utf8) {
                    TextEditor(text: .constant(jsonString))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .navigationTitle("Club Water Polo Export")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showClubExport = false
                                }
                            }
                        }
                }
            }
            .alert("Save Game?", isPresented: $showSaveConfirmation) {
                Button("Save", role: .none) {
                    viewModel.saveGame(context: viewContext) { _ in }
                }
                Button("Don't Save", role: .cancel) { }
            } message: {
                Text("Would you like to save this game to your history?")
            }
        }
    }
}

// MARK: - Subviews

struct TeamScoreView: View {
    let team: GameTeam
    let score: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
            )
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GameInfoView: View {
    let period: Int
    let gameClock: TimeInterval
    let shotClock: TimeInterval
    let isGameActive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(period)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                Text("Game Clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTime(gameClock))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isGameActive ? .red : .primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Shot Clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", shotClock))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(shotClock <= 5 ? .red : .primary)
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ActionButtonsView: View {
    let isGameActive: Bool
    let isTimerRunning: Bool
    let onStartGame: () -> Void
    let onPauseGame: () -> Void
    let onResumeGame: () -> Void
    let onEndGame: () -> Void
    let onNextPeriod: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            if !isGameActive {
                Button(action: onStartGame) {
                    Text("Start Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            } else {
                HStack(spacing: 10) {
                    if isTimerRunning {
                        Button(action: onPauseGame) {
                            Image(systemName: "pause.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: onResumeGame) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: onNextPeriod) {
                        Text("Next Period")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onEndGame) {
                        Text("End Game")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}

struct PlayerStatsView: View {
    let players: [GamePlayer]
    let onPlayerSelected: (GamePlayer) -> Void
    
    var body: some View {
        List {
            Section(header: Text("Players")) {
                ForEach(players) { player in
                    Button(action: { onPlayerSelected(player) }) {
                        HStack {
                            Text("\(player.number)")
                                .font(.headline)
                                .frame(width: 30, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Text(player.name)
                                    .font(.subheadline)
                                
                                HStack(spacing: 15) {
                                    StatView(icon: "sportscourt", value: "\(player.goals)")
                                    StatView(icon: "hand.raised", value: "\(player.assists)")
                                    StatView(icon: "hand.draw", value: "\(player.steals)")
                                    StatView(icon: "xmark.octagon", value: "\(player.exclusions)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if player.isGoalie {
                                Image(systemName: "shield.lefthalf.filled")
                                    .foregroundColor(.blue)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct StatView: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
            Text(value)
        }
    }
}

struct PlayerActionSheet: View {
    let player: GamePlayer
    let onGoal: () -> Void
    let onAssist: () -> Void
    let onSteal: () -> Void
    let onExclusion: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(player.number) - \(player.name)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(spacing: 10) {
                ActionButton(
                    title: "Goal",
                    icon: "sportscourt",
                    color: .green,
                    action: onGoal
                )
                
                ActionButton(
                    title: "Assist",
                    icon: "hand.raised",
                    color: .blue,
                    action: onAssist
                )
                
                ActionButton(
                    title: "Steal",
                    icon: "hand.draw",
                    color: .orange,
                    action: onSteal
                )
                
                ActionButton(
                    title: "Exclusion",
                    icon: "xmark.octagon",
                    color: .red,
                    action: onExclusion
                )
            }
            .padding()
            
            Spacer()
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(10)
        }
    }
}

// MARK: - Preview

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        let homeTeam = GameTeam(
            name: "Home Team",
            players: [
                GamePlayer(number: 1, name: "John Doe", isInGame: true, isGoalie: true),
                GamePlayer(number: 2, name: "Jane Smith", isInGame: true),
                GamePlayer(number: 3, name: "Mike Johnson", isInGame: true)
            ],
            isHomeTeam: true
        )
        
        let awayTeam = GameTeam(
            name: "Away Team",
            players: [
                GamePlayer(number: 1, name: "Alex Brown", isInGame: true, isGoalie: true),
                GamePlayer(number: 2, name: "Sarah Wilson", isInGame: true),
                GamePlayer(number: 3, name: "Chris Davis", isInGame: true)
            ],
            isHomeTeam: false
        )
        
        let game = GameSession(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: 1,
            gameClock: 420.0,
            shotClock: 30.0,
            homeScore: 5,
            awayScore: 3,
            isGameActive: true
        )
        
        GameView()
            .environmentObject(GameViewModel(game: game))
    }
}
