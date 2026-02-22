import SwiftUI

// MARK: - Live Game Player Detail View
// Uses GamePlayer/GameTeam structs for real-time scoring

struct PlayerDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let player: GamePlayer
    let team: GameTeam
    let gameLog: [GameEventRecord]
    let viewModel: GameViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                WaterPoloColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Player Header
                    PlayerHeaderCard(player: player)
                        .padding()
                    
                    // Stats Grid
                    ScrollView {
                        VStack(spacing: 16) {
                            // Cumulative Stats
                            StatsGridView(player: player)
                            
                            // Foul Status
                            if player.isFouledOut {
                                FoulOutBanner()
                            } else {
                                FoulStatusView(player: player)
                            }
                            
                            // Game Log
                            GameLogSectionView(events: gameLog)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Player Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Player Header Card

struct PlayerHeaderCard: View {
    let player: GamePlayer
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Player #\(player.number)")
                        .font(.caption)
                        .foregroundColor(WaterPoloColors.textSecondary)
                    
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(WaterPoloColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if player.isGoalie {
                        HStack(spacing: 4) {
                            Image(systemName: "shield.fill")
                            Text("Goalie")
                        }
                        .font(.caption)
                        .foregroundColor(WaterPoloColors.secondary)
                    }
                    
                    if player.isFouledOut {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Fouled Out")
                        }
                        .font(.caption)
                        .foregroundColor(WaterPoloColors.danger)
                    }
                }
            }
        }
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Stats Grid View

struct StatsGridView: View {
    let player: GamePlayer
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cumulative Stats")
                .font(.headline)
                .foregroundColor(WaterPoloColors.textPrimary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                StatCard(
                    title: "Goals",
                    value: "\(player.goals)",
                    icon: "target.fill",
                    color: WaterPoloColors.success
                )
                
                StatCard(
                    title: "Assists",
                    value: "\(player.assists)",
                    icon: "hand.raised.fill",
                    color: WaterPoloColors.secondary
                )
                
                StatCard(
                    title: "Steals",
                    value: "\(player.steals)",
                    icon: "hand.draw.fill",
                    color: WaterPoloColors.warning
                )
                
                StatCard(
                    title: "Exclusions",
                    value: "\(player.exclusions)",
                    icon: "xmark.octagon.fill",
                    color: WaterPoloColors.danger
                )
                
                StatCard(
                    title: "Excl. Drawn",
                    value: "\(player.exclusionsDrawn)",
                    icon: "checkmark.circle.fill",
                    color: WaterPoloColors.success
                )
                
                StatCard(
                    title: "Penalties",
                    value: "\(player.penaltiesDrawn)",
                    icon: "exclamationmark.circle.fill",
                    color: WaterPoloColors.warning
                )
                
                StatCard(
                    title: "Sprints Won",
                    value: "\(player.sprintsWon)",
                    icon: "bolt.fill",
                    color: WaterPoloColors.secondary
                )
                
                StatCard(
                    title: "Sprints Lost",
                    value: "\(player.sprintsLost)",
                    icon: "bolt.slash.fill",
                    color: WaterPoloColors.textSecondary
                )
            }
        }
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(WaterPoloColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(WaterPoloColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(WaterPoloColors.surfaceVariant)
        .cornerRadius(8)
    }
}

// MARK: - Foul Status View

struct FoulStatusView: View {
    let player: GamePlayer
    
    var foulsRemaining: Int {
        3 - player.totalFouls
    }
    
    var statusColor: Color {
        switch foulsRemaining {
        case 3:
            return WaterPoloColors.success
        case 2:
            return WaterPoloColors.warning
        case 1:
            return WaterPoloColors.danger
        default:
            return WaterPoloColors.danger
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foul Status")
                        .font(.headline)
                        .foregroundColor(WaterPoloColors.textPrimary)
                    
                    Text("Fouls: \(player.totalFouls) / 3")
                        .font(.subheadline)
                        .foregroundColor(WaterPoloColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(foulsRemaining)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                    
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(WaterPoloColors.textSecondary)
                }
            }
            
            // Foul Progress
            ProgressView(value: Double(player.totalFouls), total: 3.0)
                .tint(statusColor)
        }
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Foul Out Banner

struct FoulOutBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Player Fouled Out")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("3 fouls reached - player must leave the game")
                    .font(.caption)
            }
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(WaterPoloColors.danger)
        .cornerRadius(12)
    }
}

// MARK: - Game Log Section

struct GameLogSectionView: View {
    let events: [GameEventRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Log")
                .font(.headline)
                .foregroundColor(WaterPoloColors.textPrimary)
            
            if events.isEmpty {
                Text("No events recorded")
                    .font(.caption)
                    .foregroundColor(WaterPoloColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(events) { event in
                        GameLogEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(WaterPoloColors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Game Log Event Row

struct GameLogEventRow: View {
    let event: GameEventRecord
    
    var eventIcon: String {
        switch event.eventType {
        case .goal:
            return "target.fill"
        case .shot:
            return "circle.fill"
        case .assist:
            return "hand.raised.fill"
        case .steal:
            return "hand.draw.fill"
        case .exclusion:
            return "xmark.octagon.fill"
        case .exclusionDrawn:
            return "checkmark.circle.fill"
        case .penalty:
            return "exclamationmark.circle.fill"
        case .penaltyDrawn:
            return "exclamationmark.circle.fill"
        case .sprintWon:
            return "bolt.fill"
        case .sprintLost:
            return "bolt.slash.fill"
        case .timeout:
            return "pause.circle.fill"
        case .periodStart:
            return "play.circle.fill"
        case .periodEnd:
            return "stop.circle.fill"
        case .gameStart:
            return "play.fill"
        case .gameEnd:
            return "stop.fill"
        case .foulOut:
            return "xmark.circle.fill"
        }
    }
    
    var eventColor: Color {
        switch event.eventType {
        case .goal:
            return WaterPoloColors.success
        case .exclusion, .penalty, .foulOut:
            return WaterPoloColors.danger
        case .exclusionDrawn, .penaltyDrawn:
            return WaterPoloColors.success
        case .sprintWon:
            return WaterPoloColors.secondary
        case .gameStart, .periodStart:
            return WaterPoloColors.secondary
        default:
            return WaterPoloColors.textSecondary
        }
    }
    
    var eventLabel: String {
        switch event.eventType {
        case .goal:
            return "Goal"
        case .shot:
            return "Shot"
        case .assist:
            return "Assist"
        case .steal:
            return "Steal"
        case .exclusion:
            return "Exclusion"
        case .exclusionDrawn:
            return "Exclusion Drawn"
        case .penalty:
            return "Penalty"
        case .penaltyDrawn:
            return "Penalty Drawn"
        case .sprintWon:
            return "Sprint Won"
        case .sprintLost:
            return "Sprint Lost"
        case .timeout:
            return "Timeout"
        case .periodStart:
            return "Period Start"
        case .periodEnd:
            return "Period End"
        case .gameStart:
            return "Game Start"
        case .gameEnd:
            return "Game End"
        case .foulOut:
            return "Fouled Out"
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: eventIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(eventColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(eventLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(WaterPoloColors.textPrimary)
                
                Text("Period \(event.period)")
                    .font(.caption)
                    .foregroundColor(WaterPoloColors.textSecondary)
            }
            
            Spacer()
            
            Text(formatTime(event.gameTime))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(WaterPoloColors.textSecondary)
        }
        .padding(8)
        .background(WaterPoloColors.surfaceVariant)
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct PlayerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let player = GamePlayer(
            number: 2,
            name: "Jane Smith",
            isInGame: true,
            goals: 5,
            assists: 2,
            steals: 1,
            exclusions: 1,
            exclusionsDrawn: 2,
            penaltiesDrawn: 0,
            sprintsWon: 3,
            sprintsLost: 1
        )
        
        let team = GameTeam(
            name: "Home Team",
            players: [player],
            isHomeTeam: true
        )
        
        let game = GameSession(
            homeTeam: team,
            awayTeam: GameTeam(name: "Away Team", isHomeTeam: false)
        )
        
        PlayerDetailView(
            player: player,
            team: team,
            gameLog: [],
            viewModel: GameViewModel(game: game)
        )
    }
}
