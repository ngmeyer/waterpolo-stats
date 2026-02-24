import SwiftUI
import CoreData

// MARK: - Game Stats View

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
        NavigationStack {
            VStack(spacing: 0) {
                // Box score — scores by quarter
                BoxScoreView(game: viewModel.game)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // Compact period + clock bar
                HStack {
                    Label("Q\(viewModel.game.period)", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTime(viewModel.game.gameClock))
                        .font(.system(.title3, design: .monospaced).bold())

                    Spacer()

                    Text("Shot: \(String(format: "%.0f", viewModel.game.shotClock))s")
                        .font(.subheadline)
                        .foregroundColor(viewModel.game.shotClock <= 5 ? .red : .secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // Controls — only when game is live (no Start Game here)
                if viewModel.game.status == .inProgress || viewModel.game.status == .paused {
                    HStack(spacing: 20) {
                        Button {
                            if viewModel.isTimerRunning { viewModel.pauseGame() }
                            else { viewModel.resumeGame() }
                        } label: {
                            Image(systemName: viewModel.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(viewModel.isTimerRunning ? .blue : .green)
                        }

                        Divider().frame(height: 28)

                        Button("Next Quarter", action: viewModel.startNextPeriod)
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)

                        Divider().frame(height: 28)

                        Button("End Game") {
                            viewModel.endGame()
                            showSaveConfirmation = true
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))

                    Divider()
                }

                // Team selector
                Picker("Team", selection: $viewModel.selectedTeam) {
                    Text(viewModel.game.homeTeam.name).tag(GameViewModel.TeamType.home)
                    Text(viewModel.game.awayTeam.name).tag(GameViewModel.TeamType.away)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Player stats list
                PlayerStatsView(
                    players: viewModel.selectedTeam == .home
                        ? viewModel.game.homeTeam.players
                        : viewModel.game.awayTeam.players,
                    onPlayerSelected: { player in
                        viewModel.selectedPlayer = player
                        viewModel.showPlayerSelection = true
                    }
                )
            }
            .navigationTitle("Game Stats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { showExportOptions = true } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
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
                }
            }
            .sheet(isPresented: $showClubExport) {
                if let data = exportData,
                   let jsonString = String(data: data, encoding: .utf8) {
                    TextEditor(text: .constant(jsonString))
                        .font(.system(.body, design: .monospaced))
                        .padding()
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

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Box Score View

struct BoxScoreView: View {
    let game: GameSession

    /// Number of columns to display (at least 4 quarters).
    private var numCols: Int { max(game.period, 4) }

    private func colLabel(_ p: Int) -> String { p <= 4 ? "Q\(p)" : "OT\(p - 4)" }

    /// Per-period differential score. Returns nil for periods not yet played.
    private func diff(home: Bool, period: Int) -> Int? {
        if let entry = game.periodScores.first(where: { $0.period == period }) {
            // Completed period — differential from previous period's cumulative
            let cum = home ? entry.homeScore : entry.awayScore
            let prev: Int
            if period > 1, let prevEntry = game.periodScores.first(where: { $0.period == period - 1 }) {
                prev = home ? prevEntry.homeScore : prevEntry.awayScore
            } else {
                prev = 0
            }
            return cum - prev
        } else if period == game.period && game.isGameActive {
            // Current in-progress period — running goals since last completed period
            let prevCum = game.periodScores
                .sorted { $0.period > $1.period }
                .first
                .map { home ? $0.homeScore : $0.awayScore } ?? 0
            return (home ? game.homeScore : game.awayScore) - prevCum
        }
        return nil  // future period
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 110, alignment: .leading)
                ForEach(1...numCols, id: \.self) { p in
                    Text(colLabel(p))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                Text("F")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(width: 34)
            }
            .padding(.bottom, 6)

            Divider()

            // Home row
            BoxScoreRow(
                teamName: game.homeTeam.name,
                numCols: numCols,
                currentPeriod: game.period,
                total: game.homeScore,
                accent: .blue,
                score: { diff(home: true, period: $0) }
            )

            Divider()
                .padding(.horizontal)

            // Away row
            BoxScoreRow(
                teamName: game.awayTeam.name,
                numCols: numCols,
                currentPeriod: game.period,
                total: game.awayScore,
                accent: .orange,
                score: { diff(home: false, period: $0) }
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BoxScoreRow: View {
    let teamName: String
    let numCols: Int
    let currentPeriod: Int
    let total: Int
    let accent: Color
    let score: (Int) -> Int?

    var body: some View {
        HStack(spacing: 0) {
            Text(teamName)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 110, alignment: .leading)

            ForEach(1...numCols, id: \.self) { p in
                if let s = score(p) {
                    Text("\(s)")
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundColor(p == currentPeriod ? accent : .primary)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("—")
                        .font(.callout)
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity)
                }
            }

            Text("\(total)")
                .font(.system(.callout, design: .rounded).bold())
                .foregroundColor(accent)
                .frame(width: 34)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Player Stats (unchanged)

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
                Text("Period").font(.caption).foregroundColor(.secondary)
                Text("\(period)").font(.title2).fontWeight(.bold)
            }
            Spacer()
            VStack(alignment: .center) {
                Text("Game Clock").font(.caption).foregroundColor(.secondary)
                Text(formatTime(gameClock))
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(isGameActive ? .red : .primary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Shot Clock").font(.caption).foregroundColor(.secondary)
                Text(String(format: "%.1f", shotClock))
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(shotClock <= 5 ? .red : .primary)
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
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
                                Text(player.name).font(.subheadline)
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
                .font(.title2).fontWeight(.bold).padding(.top)

            VStack(spacing: 10) {
                ActionButton(title: "Goal", icon: "sportscourt", color: .green, action: onGoal)
                ActionButton(title: "Assist", icon: "hand.raised", color: .blue, action: onAssist)
                ActionButton(title: "Steal", icon: "hand.draw", color: .orange, action: onSteal)
                ActionButton(title: "Exclusion", icon: "xmark.octagon", color: .red, action: onExclusion)
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

#Preview {
    let home = GameTeam(name: "680 Red", players: [
        GamePlayer(number: 1, name: "Ian Meyer", isInGame: true, isGoalie: true),
        GamePlayer(number: 9, name: "Ryan Mack", isInGame: true),
    ], isHomeTeam: true)
    let away = GameTeam(name: "American River", players: [
        GamePlayer(number: 1, name: "Alex Brown", isInGame: true, isGoalie: true),
    ], isHomeTeam: false)
    var session = GameSession(
        homeTeam: home, awayTeam: away,
        period: 2, homeScore: 5, awayScore: 3,
        isGameActive: true, status: .inProgress
    )
    session.periodScores = [PeriodScore(period: 1, homeScore: 3, awayScore: 2)]
    return GameView()
        .environmentObject(GameViewModel(game: session))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
