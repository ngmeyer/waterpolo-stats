import SwiftUI
import CoreData
import PhotosUI

// MARK: - Player Career Stats View

struct PlayerCareerStatsView: View {
    @ObservedObject var player: Player
    @State private var showEditPlayer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PlayerCareerHeader(player: player)
                CareerTotalsSection(player: player)
                SeasonBreakdownSection(player: player)
                RecentGamesSection(player: player)
            }
            .padding()
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditPlayer = true } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditPlayer) {
            EditPlayerSheet(player: player)
        }
    }
}

// MARK: - Header

struct PlayerCareerHeader: View {
    @ObservedObject var player: Player

    @State private var avatarImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    private var displayName: String {
        guard let n = player.name, !n.isEmpty else { return "Unnamed Player" }
        return n
    }

    private var isNamedPlayer: Bool {
        player.name?.isEmpty == false
    }

    private var initials: String {
        guard let n = player.name, !n.isEmpty else { return "" }
        let parts = n.trimmingCharacters(in: .whitespaces)
                     .components(separatedBy: .whitespaces)
                     .filter { !$0.isEmpty }
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(n.prefix(1)).uppercased()
    }

    private var capLabel: String {
        player.currentCapNumber.map { "#\($0)" } ?? "?"
    }

    /// All unique team names this player has been part of.
    private var allTeamNames: [String] {
        var names = Set<String>()
        if let t = player.team { names.insert(t.displayName) }
        for roster in player.rostersArray {
            guard let game = roster.game else { continue }
            let t = roster.isHomeTeam ? game.homeTeam : game.awayTeam
            if let name = t?.displayName, !name.isEmpty { names.insert(name) }
        }
        return Array(names).sorted()
    }

    var body: some View {
        VStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    avatarCircle
                }
                .buttonStyle(.plain)

                Image(systemName: "camera.fill")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
            .contextMenu {
                if avatarImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        avatarImage = nil
                        PlayerAvatarStore.shared.delete(for: player.wrappedId)
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let square = cropToSquare(uiImage)
                        avatarImage = square
                        PlayerAvatarStore.shared.save(square, for: player.wrappedId)
                    }
                }
            }

            // Name + team(s)
            VStack(spacing: 6) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isNamedPlayer ? .primary : .secondary)

                if allTeamNames.isEmpty {
                    Text("No team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if allTeamNames.count == 1 {
                    Text(allTeamNames[0])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(allTeamNames.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .onAppear {
            avatarImage = PlayerAvatarStore.shared.load(for: player.wrappedId)
        }
    }

    @ViewBuilder
    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 100, height: 100)

            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else if !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            } else {
                Text(capLabel)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
    }

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - side) / 2,
            y: (image.size.height - side) / 2
        )
        guard let cgImage = image.cgImage?.cropping(
            to: CGRect(origin: origin, size: CGSize(width: side, height: side))
        ) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
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

    private var goals: Int { allEvents.filter { $0.wrappedEventType == "goal" }.count }
    private var assists: Int { allEvents.filter { $0.wrappedEventType == "assist" }.count }
    private var steals: Int { allEvents.filter { $0.wrappedEventType == "steal" }.count }
    private var exclusions: Int { allEvents.filter { $0.wrappedEventType == "exclusion" }.count }
    private var gamesPlayed: Int { Set(allEvents.compactMap { $0.game?.wrappedId }).count }
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
        if let d = doubleValue { return String(format: "%.1f", d) }
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
            return (season, seasonEvents.filter { $0.wrappedEventType == "goal" }.count, seasonGames.count)
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
                                let myTeam = player.team?.displayName ?? ""
                                let opp = item.game.awayTeam?.displayName == myTeam
                                    ? (item.game.homeTeam?.displayName ?? "Home")
                                    : (item.game.awayTeam?.displayName ?? "Away")
                                Text("vs \(opp)")
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

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let player = Player(context: context)
    player.id = UUID()
    player.name = "Ian Meyer"
    player.number = "9"

    return NavigationStack {
        PlayerCareerStatsView(player: player)
    }
    .environment(\.managedObjectContext, context)
}
