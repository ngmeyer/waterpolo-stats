import SwiftUI

struct LandscapeGameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = GameViewModel()
    @State private var showSettings = false
    @State private var showGameLog = false
    @State private var showPlayerDetail: GamePlayer?
    @State private var showSaveConfirmation = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ZStack {
            // Background
            WaterPoloColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with game info
                GameHeaderView(
                    period: viewModel.game.period,
                    gameClock: viewModel.game.gameClock,
                    shotClock: viewModel.game.shotClock,
                    isGameActive: viewModel.game.isGameActive
                )
                .padding()
                .background(WaterPoloColors.surface)
                .shadow(radius: 2)
                
                // Main scoring area - Side by side teams
                HStack(spacing: 16) {
                    // Home Team
                    TeamScoringPanel(
                        team: viewModel.game.homeTeam,
                        score: viewModel.game.homeScore,
                        isSelected: viewModel.selectedTeam == .home,
                        teamType: .home,
                        onTeamTap: { viewModel.selectedTeam = .home },
                        onPlayerTap: { player in
                            showPlayerDetail = player
                        },
                        onGoal: { player in
                            viewModel.scoreGoal(for: .home, player: player)
                        },
                        onExclusion: { player in
                            viewModel.recordExclusion(for: .home, player: player)
                        },
                        onPenalty: { player in
                            viewModel.recordPenalty(for: .home, player: player)
                        },
                        onSprintWon: { player in
                            viewModel.recordSprintWon(for: .home, player: player)
                        }
                    )
                    
                    // Center Control Panel
                    GameControlPanel(
                        isGameActive: viewModel.game.isGameActive,
                        isTimerRunning: viewModel.isTimerRunning,
                        onStartGame: viewModel.startGame,
                        onPauseGame: viewModel.pauseGame,
                        onResumeGame: viewModel.resumeGame,
                        onEndGame: {
                            viewModel.endGame()
                            showSaveConfirmation = true
                        },
                        onNextPeriod: viewModel.startNextPeriod,
                        onSettings: { showSettings = true },
                        onGameLog: { showGameLog = true }
                    )
                    
                    // Away Team
                    TeamScoringPanel(
                        team: viewModel.game.awayTeam,
                        score: viewModel.game.awayScore,
                        isSelected: viewModel.selectedTeam == .away,
                        teamType: .away,
                        onTeamTap: { viewModel.selectedTeam = .away },
                        onPlayerTap: { player in
                            showPlayerDetail = player
                        },
                        onGoal: { player in
                            viewModel.scoreGoal(for: .away, player: player)
                        },
                        onExclusion: { player in
                            viewModel.recordExclusion(for: .away, player: player)
                        },
                        onPenalty: { player in
                            viewModel.recordPenalty(for: .away, player: player)
                        },
                        onSprintWon: { player in
                            viewModel.recordSprintWon(for: .away, player: player)
                        }
                    )
                }
                .padding()
            }
        }
        .sheet(item: $showPlayerDetail) { player in
            PlayerDetailView(
                player: player,
                team: viewModel.selectedTeam == .home ? viewModel.game.homeTeam : viewModel.game.awayTeam,
                gameLog: viewModel.getPlayerGameLog(
                    playerNumber: player.number,
                    team: viewModel.selectedTeam
                ),
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showGameLog) {
            GameLogView(
                events: viewModel.getGameLog(),
                homeTeamName: viewModel.game.homeTeam.name,
                awayTeamName: viewModel.game.awayTeam.name,
                onAdjustTime: { eventId, newTime in
                    viewModel.adjustEventTime(eventId: eventId, newGameTime: newTime)
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewStandalone(isSunlightMode: .constant(false))
                .environmentObject(viewModel)
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

// MARK: - Header View

struct GameHeaderView: View {
    let period: Int
    let gameClock: TimeInterval
    let shotClock: TimeInterval
    let isGameActive: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Period")
                    .font(.caption)
                    .foregroundColor(WaterPoloColors.textSecondary)
                Text("\(period)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(WaterPoloColors.textPrimary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .center, spacing: 4) {
                Text("Game Clock")
                    .font(.caption)
                    .foregroundColor(WaterPoloColors.textSecondary)
                Text(formatTime(gameClock))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(isGameActive ? WaterPoloColors.danger : WaterPoloColors.textPrimary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Shot Clock")
                    .font(.caption)
                    .foregroundColor(WaterPoloColors.textSecondary)
                Text(String(format: "%.1f", shotClock))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(shotClock <= 5 ? WaterPoloColors.danger : WaterPoloColors.textPrimary)
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Team Scoring Panel

struct TeamScoringPanel: View {
    let team: GameTeam
    let score: Int
    let isSelected: Bool
    let teamType: GameViewModel.TeamType
    let onTeamTap: () -> Void
    let onPlayerTap: (GamePlayer) -> Void
    let onGoal: (GamePlayer) -> Void
    let onExclusion: (GamePlayer) -> Void
    let onPenalty: (GamePlayer) -> Void
    let onSprintWon: (GamePlayer) -> Void
    
    var teamColor: Color {
        teamType == .home ? WaterPoloColors.homeTeam : WaterPoloColors.awayTeam
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Team Header
            VStack(spacing: 8) {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(teamColor)
            .cornerRadius(12)
            .onTapGesture(perform: onTeamTap)
            
            // Players List
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(team.players) { player in
                        PlayerQuickActionRow(
                            player: player,
                            onTap: { onPlayerTap(player) },
                            onGoal: { onGoal(player) },
                            onExclusion: { onExclusion(player) },
                            onPenalty: { onPenalty(player) },
                            onSprintWon: { onSprintWon(player) }
                        )
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? teamColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Player Quick Action Row

struct PlayerQuickActionRow: View {
    let player: GamePlayer
    let onTap: () -> Void
    let onGoal: () -> Void
    let onExclusion: () -> Void
    let onPenalty: () -> Void
    let onSprintWon: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Player Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("#\(player.number)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(WaterPoloColors.textSecondary)
                        
                        Text(player.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(WaterPoloColors.textPrimary)
                        
                        if player.isGoalie {
                            Image(systemName: "shield.fill")
                                .font(.caption)
                                .foregroundColor(WaterPoloColors.secondary)
                        }
                        
                        if player.isFouledOut {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(WaterPoloColors.danger)
                        }
                    }
                    
                    // Stats Row
                    HStack(spacing: 8) {
                        StatBadge(icon: "target", value: "\(player.goals)")
                        StatBadge(icon: "hand.raised", value: "\(player.assists)")
                        StatBadge(icon: "xmark.octagon", value: "\(player.exclusions)")
                        StatBadge(icon: "exclamationmark.circle", value: "\(player.penaltiesDrawn)")
                    }
                    .font(.caption2)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 6) {
                    ActionCircleButton(
                        icon: "target.fill",
                        color: WaterPoloColors.success,
                        size: 32,
                        action: onGoal
                    )
                    
                    ActionCircleButton(
                        icon: "xmark.octagon.fill",
                        color: WaterPoloColors.danger,
                        size: 32,
                        action: onExclusion
                    )
                    
                    ActionCircleButton(
                        icon: "exclamationmark.circle.fill",
                        color: WaterPoloColors.warning,
                        size: 32,
                        action: onPenalty
                    )
                    
                    ActionCircleButton(
                        icon: "bolt.fill",
                        color: WaterPoloColors.secondary,
                        size: 32,
                        action: onSprintWon
                    )
                    
                    Button(action: onTap) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(WaterPoloColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(WaterPoloColors.surfaceVariant)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(8)
            .background(WaterPoloColors.surfaceVariant)
            .cornerRadius(8)
        }
    }
}

// MARK: - Action Circle Button

struct ActionCircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .fontWeight(.semibold)
        }
        .foregroundColor(WaterPoloColors.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(WaterPoloColors.background)
        .cornerRadius(4)
    }
}

// MARK: - Game Control Panel

struct GameControlPanel: View {
    let isGameActive: Bool
    let isTimerRunning: Bool
    let onStartGame: () -> Void
    let onPauseGame: () -> Void
    let onResumeGame: () -> Void
    let onEndGame: () -> Void
    let onNextPeriod: () -> Void
    let onSettings: () -> Void
    let onGameLog: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Control Buttons
            VStack(spacing: 10) {
                if !isGameActive {
                    ControlButton(
                        title: "Start Game",
                        icon: "play.fill",
                        color: WaterPoloColors.success,
                        action: onStartGame
                    )
                } else {
                    if isTimerRunning {
                        ControlButton(
                            title: "Pause",
                            icon: "pause.fill",
                            color: WaterPoloColors.warning,
                            action: onPauseGame
                        )
                    } else {
                        ControlButton(
                            title: "Resume",
                            icon: "play.fill",
                            color: WaterPoloColors.success,
                            action: onResumeGame
                        )
                    }
                    
                    ControlButton(
                        title: "Next Period",
                        icon: "forward.fill",
                        color: WaterPoloColors.secondary,
                        action: onNextPeriod
                    )
                    
                    ControlButton(
                        title: "End Game",
                        icon: "stop.fill",
                        color: WaterPoloColors.danger,
                        action: onEndGame
                    )
                }
            }
            
            Divider()
            
            // Info Buttons
            VStack(spacing: 10) {
                ControlButton(
                    title: "Game Log",
                    icon: "list.bullet",
                    color: WaterPoloColors.primary,
                    action: onGameLog
                )
                
                ControlButton(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: WaterPoloColors.textSecondary,
                    action: onSettings
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: 140)
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

struct LandscapeGameView_Previews: PreviewProvider {
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
            gameType: .league,
            gameLevel: .girlsVarsity
        )
        
        LandscapeGameView()
            .environmentObject(GameViewModel(game: game))
    }
}
