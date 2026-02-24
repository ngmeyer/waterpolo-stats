import SwiftUI
import CoreData

// MARK: - Game Detail View
// Full stats breakdown for saved games

struct SavedGameDetailView: View {
    let game: Game
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var selectedTab = 0
    
    // Convert Core Data game to GameSession for export
    private var gameSession: GameSession {
        GameSession.fromCoreData(game)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Score header
                ScoreHeaderView(game: game)
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Summary").tag(0)
                    Text("\(game.homeTeamName)").tag(1)
                    Text("\(game.awayTeamName)").tag(2)
                    Text("Timeline").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        GameSummaryView(game: game)
                    case 1:
                        TeamStatsView(team: game.homeTeam, events: homeTeamEvents)
                    case 2:
                        TeamStatsView(team: game.awayTeam, events: awayTeamEvents)
                    case 3:
                        GameTimelineView(events: game.eventsArray)
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showExportSheet = true }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Game", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheetView(game: gameSession)
        }
        .alert("Delete Game?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteGame()
            }
        } message: {
            Text("This will permanently delete this game and all its stats.")
        }
    }
    
    private var homeTeamEvents: [GameEvent] {
        game.eventsArray.filter { event in
            guard let player = event.player,
                  let rosterEntries = game.rostersArray.filter({ $0.player?.id == player.id }).first else { return false }
            return rosterEntries.isHomeTeam
        }
    }
    
    private var awayTeamEvents: [GameEvent] {
        game.eventsArray.filter { event in
            guard let player = event.player,
                  let rosterEntries = game.rostersArray.filter({ $0.player?.id == player.id }).first else { return false }
            return !rosterEntries.isHomeTeam
        }
    }
    
    private func deleteGame() {
        viewContext.delete(game)
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Score Header

struct ScoreHeaderView: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 16) {
            // Final score
            HStack(spacing: 24) {
                // Home team
                VStack(spacing: 8) {
                    Text(game.homeTeamName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("\(homeScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                
                // VS
                VStack(spacing: 4) {
                    Text("VS")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if game.gameStatus == .completed {
                        Text("Final")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("In Progress")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                // Away team
                VStack(spacing: 8) {
                    Text(game.awayTeamName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("\(awayScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Game info
            HStack(spacing: 16) {
                Label(game.wrappedDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !game.wrappedLocation.isEmpty {
                    Label(game.wrappedLocation, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var homeScore: Int {
        game.eventsArray.filter { $0.wrappedEventType == "goal" && isHomePlayer($0.player) }.count
    }
    
    private var awayScore: Int {
        game.eventsArray.filter { $0.wrappedEventType == "goal" && !isHomePlayer($0.player) }.count
    }
    
    private func isHomePlayer(_ player: Player?) -> Bool {
        guard let player = player else { return false }
        return game.rostersArray.first { $0.player?.id == player.id }?.isHomeTeam ?? false
    }
}

// MARK: - Game Summary

struct GameSummaryView: View {
    let game: Game
    
    var body: some View {
        VStack(spacing: 20) {
            // Period scores (calculated from events)
            PeriodScoresSection(game: game)
            
            // Team comparison
            TeamComparisonSection(game: game)
            
            // Top performers
            TopPerformersSection(game: game)
            
            // Game stats
            GameStatsSection(game: game)
        }
    }
}

struct PeriodScoresSection: View {
    let game: Game
    
    private var periodScores: [(period: Int, homeScore: Int, awayScore: Int)] {
        // Get all unique periods from events
        let periods = Set(game.eventsArray.map { Int($0.period) }).sorted()
        
        return periods.map { period in
            let periodEvents = game.eventsArray.filter { Int($0.period) == period }
            
            let homeGoals = periodEvents.filter { event in
                event.wrappedEventType == "goal" && isHomePlayer(event.player)
            }.count
            
            let awayGoals = periodEvents.filter { event in
                event.wrappedEventType == "goal" && !isHomePlayer(event.player)
            }.count
            
            return (period, homeGoals, awayGoals)
        }
    }
    
    private func isHomePlayer(_ player: Player?) -> Bool {
        guard let player = player else { return false }
        return game.rostersArray.first { $0.player?.id == player.id }?.isHomeTeam ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Period Scores")
                .font(.headline)
            
            if periodScores.isEmpty {
                Text("No period data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(periodScores, id: \.period) { period in
                        HStack {
                            Text("Q\(period.period)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            HStack(spacing: 24) {
                                Text("\(period.homeScore)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                
                                Text("\(period.awayScore)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TeamComparisonSection: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team Comparison")
                .font(.headline)
            
            ComparisonRow(
                label: "Goals",
                homeValue: homeStats.goals,
                awayValue: awayStats.goals
            )
            
            ComparisonRow(
                label: "Exclusions",
                homeValue: homeStats.exclusions,
                awayValue: awayStats.exclusions
            )
            
            ComparisonRow(
                label: "Steals",
                homeValue: homeStats.steals,
                awayValue: awayStats.steals
            )
            
            ComparisonRow(
                label: "Penalties",
                homeValue: homeStats.penalties,
                awayValue: awayStats.penalties
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var homeStats: TeamStats {
        calculateStats(for: true)
    }
    
    private var awayStats: TeamStats {
        calculateStats(for: false)
    }
    
    private func calculateStats(for isHome: Bool) -> TeamStats {
        let rosterIds = game.rostersArray.filter { $0.isHomeTeam == isHome }.compactMap { $0.player?.id }
        let events = game.eventsArray.filter { event in
            rosterIds.contains(event.player?.id ?? UUID())
        }
        
        return TeamStats(
            goals: events.filter { $0.wrappedEventType == "goal" }.count,
            exclusions: events.filter { $0.wrappedEventType == "exclusion" }.count,
            steals: events.filter { $0.wrappedEventType == "steal" }.count,
            penalties: events.filter { $0.wrappedEventType == "penalty" }.count
        )
    }
}

struct TeamStats {
    let goals: Int
    let exclusions: Int
    let steals: Int
    let penalties: Int
}

struct ComparisonRow: View {
    let label: String
    let homeValue: Int
    let awayValue: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 24) {
                Text("\(homeValue)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(homeValue > awayValue ? .bold : .regular)
                    .foregroundColor(homeValue > awayValue ? .blue : .primary)
                    .frame(width: 40)
                
                Text("\(awayValue)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(awayValue > homeValue ? .bold : .regular)
                    .foregroundColor(awayValue > homeValue ? .orange : .primary)
                    .frame(width: 40)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TopPerformersSection: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performers")
                .font(.headline)
            
            // Get all players with their stats
            let playerStats = getPlayerStats()
            
            if playerStats.isEmpty {
                Text("No goals recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(playerStats.prefix(3)) { stat in
                        HStack {
                            HStack(spacing: 4) {
                                Text("#\(stat.playerNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(stat.playerName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text(stat.teamName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(stat.goals) G")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .frame(width: 50, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getPlayerStats() -> [PlayerStat] {
        var stats: [PlayerStat] = []
        
        // Aggregate by player
        var playerEvents: [UUID: [GameEvent]] = [:]
        for event in game.eventsArray where event.wrappedEventType == "goal" {
            if let playerId = event.player?.id {
                playerEvents[playerId, default: []].append(event)
            }
        }
        
        for (playerId, events) in playerEvents {
            guard let roster = game.rostersArray.first(where: { $0.player?.id == playerId }),
                  let player = roster.player else { continue }
            
            stats.append(PlayerStat(
                playerId: playerId,
                playerName: player.wrappedName,
                playerNumber: roster.capNumber,
                teamName: roster.isHomeTeam ? game.homeTeamName : game.awayTeamName,
                goals: events.count
            ))
        }
        
        return stats.sorted { $0.goals > $1.goals }
    }
}

struct PlayerStat: Identifiable {
    let id = UUID()
    let playerId: UUID
    let playerName: String
    let playerNumber: Int16
    let teamName: String
    let goals: Int
}

struct GameStatsSection: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Info")
                .font(.headline)
            
            InfoRow(label: "Status", value: game.gameStatus == .completed ? "Completed" : "In Progress")
            InfoRow(label: "Date", value: game.wrappedDate.formatted(date: .abbreviated, time: .shortened))
            
            if !game.wrappedLocation.isEmpty {
                InfoRow(label: "Location", value: game.wrappedLocation)
            }
            
            InfoRow(label: "Total Events", value: "\(game.eventsArray.count)")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Team Stats View

struct TeamStatsView: View {
    let team: Team?
    let events: [GameEvent]
    
    var body: some View {
        VStack(spacing: 20) {
            if let team = team {
                // Player stats table
                PlayerStatsTable(team: team, events: events)
                
                // Event breakdown
                EventBreakdownView(events: events)
            } else {
                Text("Team data not available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PlayerStatsTable: View {
    let team: Team
    let events: [GameEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Player Stats")
                .font(.headline)
            
            // Header
            HStack {
                Text("Player")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Group {
                    Text("G").frame(width: 30)
                    Text("A").frame(width: 30)
                    Text("S").frame(width: 30)
                    Text("E").frame(width: 30)
                }
                .font(.caption)
                .fontWeight(.medium)
            }
            .foregroundColor(.secondary)
            
            Divider()
            
            // Player rows
            ForEach(getPlayerStats()) { stat in
                HStack {
                    HStack(spacing: 4) {
                        Text("#\(stat.number)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stat.name)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Group {
                        Text("\(stat.goals)").frame(width: 30)
                        Text("\(stat.assists)").frame(width: 30)
                        Text("\(stat.steals)").frame(width: 30)
                        Text("\(stat.exclusions)").frame(width: 30)
                    }
                    .font(.system(.body, design: .monospaced))
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getPlayerStats() -> [PlayerGameStat] {
        team.playersArray.map { player in
            let playerEvents = events.filter { $0.player?.id == player.id }
            
            return PlayerGameStat(
                id: player.wrappedId,
                name: player.wrappedName,
                number: player.currentCapNumber.map { Int16($0) } ?? 0,
                goals: playerEvents.filter { $0.wrappedEventType == "goal" }.count,
                assists: playerEvents.filter { $0.wrappedEventType == "assist" }.count,
                steals: playerEvents.filter { $0.wrappedEventType == "steal" }.count,
                exclusions: playerEvents.filter { $0.wrappedEventType == "exclusion" }.count
            )
        }.sorted { $0.number < $1.number }
    }
}

struct PlayerGameStat: Identifiable {
    let id: UUID
    let name: String
    let number: Int16
    let goals: Int
    let assists: Int
    let steals: Int
    let exclusions: Int
}

struct EventBreakdownView: View {
    let events: [GameEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Breakdown")
                .font(.headline)
            
            let breakdown = getEventBreakdown()
            
            HStack(spacing: 16) {
                EventCountBox(count: breakdown.goals, label: "Goals", color: .green)
                EventCountBox(count: breakdown.assists, label: "Assists", color: .blue)
                EventCountBox(count: breakdown.steals, label: "Steals", color: .purple)
                EventCountBox(count: breakdown.exclusions, label: "Excl.", color: .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getEventBreakdown() -> EventBreakdown {
        EventBreakdown(
            goals: events.filter { $0.wrappedEventType == "goal" }.count,
            assists: events.filter { $0.wrappedEventType == "assist" }.count,
            steals: events.filter { $0.wrappedEventType == "steal" }.count,
            exclusions: events.filter { $0.wrappedEventType == "exclusion" }.count
        )
    }
}

struct EventBreakdown {
    let goals: Int
    let assists: Int
    let steals: Int
    let exclusions: Int
}

struct EventCountBox: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Game Timeline View

struct GameTimelineView: View {
    let events: [GameEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Timeline")
                .font(.headline)
            
            if events.isEmpty {
                Text("No events recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(events.sorted(by: { $0.wrappedTimestamp < $1.wrappedTimestamp }).enumerated()), id: \.element.id) { index, event in
                        TimelineEventRow(
                            event: event,
                            isLast: index == events.count - 1
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TimelineEventRow: View {
    let event: GameEvent
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Timeline line and dot
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                    
                Circle()
                    .fill(eventColor)
                    .frame(width: 10, height: 10)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(height: 50)
            
            // Event content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.wrappedEventType.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let player = event.player {
                        Text("• #\(player.wrappedNumber) \(player.wrappedName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Q\(event.period) • \(event.wrappedPeriodTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var eventColor: Color {
        switch event.wrappedEventType {
        case "goal": return .green
        case "exclusion": return .red
        case "assist": return .blue
        case "steal": return .purple
        default: return .gray
        }
    }
}

// MARK: - Extension to convert Core Data Game to GameSession

extension GameSession {
    static func fromCoreData(_ game: Game) -> GameSession {
        // Convert rosters to GamePlayers
        let homePlayers = game.activeHomeRosters.map { roster -> GamePlayer in
            GamePlayer(
                id: roster.wrappedId,
                number: Int(roster.capNumber),
                name: roster.playerName,
                isInGame: true,
                isGoalie: roster.isGoalie
            )
        }
        
        let awayPlayers = game.activeAwayRosters.map { roster -> GamePlayer in
            GamePlayer(
                id: roster.wrappedId,
                number: Int(roster.capNumber),
                name: roster.playerName,
                isInGame: true,
                isGoalie: roster.isGoalie
            )
        }
        
        let homeTeam = GameTeam(
            id: game.homeTeam?.wrappedId ?? UUID(),
            name: game.homeTeamName,
            players: homePlayers,
            isHomeTeam: true
        )
        
        let awayTeam = GameTeam(
            id: game.awayTeam?.wrappedId ?? UUID(),
            name: game.awayTeamName,
            players: awayPlayers,
            isHomeTeam: false
        )
        
        return GameSession(
            id: game.wrappedId,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: Int(game.eventsArray.map { $0.period }.max() ?? 1),
            gameClock: 0,
            shotClock: 0,
            homeScore: 0, // Will be calculated from events
            awayScore: 0,
            isGameActive: game.gameStatus == .inProgress,
            isPeriodActive: false,
            gameType: .league,
            gameLevel: .boysVarsity,
            location: game.wrappedLocation,
            status: game.gameStatus,
            homeRoster: [],
            awayRoster: []
        )
    }
}

// MARK: - Preview

struct SavedGameDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // This would need a Core Data context for preview
        Text("Preview requires Core Data context")
    }
}
