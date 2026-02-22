import SwiftUI
import CoreData

// MARK: - Player Career Stats View
// Show all stats for a player across all games/seasons

struct PlayerCareerStatsView: View {
    let player: Player
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Player header
                PlayerCareerHeader(player: player)
                
                // Career totals
                CareerTotalsSection(player: player)
                
                // Per season breakdown
                SeasonBreakdownSection(player: player)
                
                // Recent games
                RecentGamesSection(player: player)
            }
            .padding()
        }
        .navigationTitle("Career Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Header

struct PlayerCareerHeader: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Text(player.wrappedNumber)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 4) {
                Text(player.wrappedName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let team = player.team {
                    Text(team.wrappedName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Career Totals

struct CareerTotalsSection: View {
    let player: Player
    
    private var allEvents: [GameEvent] { player.eventsArray }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Career Totals")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CareerStatBox(value: goals, label: "Goals", color: .green)
                CareerStatBox(value: assists, label: "Assists", color: .blue)
                CareerStatBox(value: steals, label: "Steals", color: .purple)
                CareerStatBox(value: exclusions, label: "Exclusions", color: .red)
                CareerStatBox(value: gamesPlayed, label: "Games", color: .orange)
                CareerStatBox(doubleValue: goalsPerGame, label: "GPG", color: .cyan)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var goals: Int {
        allEvents.filter { $0.wrappedEventType == "goal" }.count
    }
    
    private var assists: Int {
        allEvents.filter { $0.wrappedEventType == "assist" }.count
    }
    
    private var steals: Int {
        allEvents.filter { $0.wrappedEventType == "steal" }.count
    }
    
    private var exclusions: Int {
        allEvents.filter { $0.wrappedEventType == "exclusion" }.count
    }
    
    private var gamesPlayed: Int {
        Set(allEvents.compactMap { $0.game?.wrappedId }).count
    }
    
    private var goalsPerGame: Double {
        gamesPlayed > 0 ? Double(goals) / Double(gamesPlayed) : 0
    }
}

struct CareerStatBox: View {
    let value: Int
    let doubleValue: Double?
    let label: String
    let color: Color
    
    init(value: Int, label: String, color: Color) {
        self.value = value
        self.doubleValue = nil
        self.label = label
        self.color = color
    }
    
    init(doubleValue: Double, label: String, color: Color) {
        self.value = 0
        self.doubleValue = doubleValue
        self.label = label
        self.color = color
    }
    
    var displayValue: String {
        if let doubleValue = doubleValue {
            return String(format: "%.1f", doubleValue)
        }
        return "\(value)"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(displayValue)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Season Breakdown

struct SeasonBreakdownSection: View {
    let player: Player
    
    private var seasonStats: [(season: Season, goals: Int, games: Int)] {
        let events = player.eventsArray
        let games = Set(events.compactMap { $0.game })
        
        let seasons = Set(games.compactMap { $0.season })
        
        return seasons.sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) }.map { season in
            let seasonGames = games.filter { $0.season?.id == season.id }
            let seasonEvents = events.filter { event in
                seasonGames.contains(where: { $0.id == event.game?.id })
            }
            let goals = seasonEvents.filter { $0.wrappedEventType == "goal" }.count
            
            return (season, goals, seasonGames.count)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Season")
                .font(.headline)
            
            if seasonStats.isEmpty {
                Text("No season data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(seasonStats, id: \.season.id) { stat in
                        HStack {
                            Text(stat.season.displayLabel)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Text("\(stat.games) games")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(stat.goals) goals")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
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

// MARK: - Recent Games

struct RecentGamesSection: View {
    let player: Player
    
    private var recentGames: [(game: Game, goals: Int)] {
        let allGames = Set(player.eventsArray.compactMap { $0.game })
        
        return allGames
            .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
            .prefix(5)
            .map { game in
                let goals = player.eventsArray.filter {
                    $0.game?.id == game.id && $0.wrappedEventType == "goal"
                }.count
                return (game, goals)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline)
            
            if recentGames.isEmpty {
                Text("No games played yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentGames, id: \.game.id) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("vs \(item.game.awayTeamName == player.team?.wrappedName ? item.game.homeTeamName : item.game.awayTeamName)")
                                    .font(.subheadline)
                                
                                if let date = item.game.date {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if item.goals > 0 {
                                Text("\(item.goals) goal\(item.goals == 1 ? "" : "s")")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            } else {
                                Text("No goals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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

// MARK: - Preview

struct PlayerCareerStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let player = Player(context: context)
        player.id = UUID()
        player.name = "Test Player"
        player.number = "12"
        
        return NavigationView {
            PlayerCareerStatsView(player: player)
        }
    }
}
