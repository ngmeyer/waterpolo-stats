import Foundation
import Combine
import CoreData

class GameViewModel: ObservableObject {
    @Published var game: GameSession
    @Published var selectedTeam: TeamType = .home
    @Published var selectedPlayer: GamePlayer?
    @Published var showPlayerSelection = false
    @Published var showEventSheet = false
    @Published var showSettings = false
    @Published var isTimerRunning = false
    
    @Published var periodJustEnded = false

    private var timer: Timer?
    private var lastUpdateTime: Date?
    
    enum TeamType {
        case home, away
    }
    
    init(game: GameSession? = nil) {
        // Create default teams with sample players so UI doesn't crash on empty arrays
        let homePlayers = [
            GamePlayer(number: 1, name: "Player 1", isInGame: true, isGoalie: true),
            GamePlayer(number: 2, name: "Player 2", isInGame: true),
            GamePlayer(number: 3, name: "Player 3", isInGame: true),
            GamePlayer(number: 4, name: "Player 4", isInGame: true),
            GamePlayer(number: 5, name: "Player 5", isInGame: true),
            GamePlayer(number: 6, name: "Player 6", isInGame: true),
            GamePlayer(number: 7, name: "Player 7", isInGame: true)
        ]
        let awayPlayers = [
            GamePlayer(number: 1, name: "Player 1", isInGame: true, isGoalie: true),
            GamePlayer(number: 2, name: "Player 2", isInGame: true),
            GamePlayer(number: 3, name: "Player 3", isInGame: true),
            GamePlayer(number: 4, name: "Player 4", isInGame: true),
            GamePlayer(number: 5, name: "Player 5", isInGame: true),
            GamePlayer(number: 6, name: "Player 6", isInGame: true),
            GamePlayer(number: 7, name: "Player 7", isInGame: true)
        ]
        let homeTeam = GameTeam(name: "Dark", players: homePlayers, isHomeTeam: true)
        let awayTeam = GameTeam(name: "Light", players: awayPlayers, isHomeTeam: false)
        self.game = game ?? GameSession(homeTeam: homeTeam, awayTeam: awayTeam)
    }
    
    // MARK: - Game Control
    
    func startGame() {
        game.isGameActive = true
        game.isPeriodActive = true
        isTimerRunning = true
        lastUpdateTime = Date()
        startTimer()
        recordEvent(type: .gameStart, team: .official)
    }
    
    func pauseGame() {
        isTimerRunning = false
        stopTimer()
    }
    
    func resumeGame() {
        isTimerRunning = true
        lastUpdateTime = Date()
        startTimer()
    }
    
    func endGame() {
        stopTimer()
        game.isGameActive = false
        game.isPeriodActive = false
        game.endTime = Date()
        recordEvent(type: .gameEnd, team: .official)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimers()
        }
        // Ensure timer runs on main thread (Timer.scheduledTimer does this by default,
        // but adding to common mode ensures it fires during UI tracking)
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimers() {
        guard isTimerRunning, let lastUpdate = lastUpdateTime else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdate)
        lastUpdateTime = now
        
        // Update game clock
        if game.gameClock > 0 {
            game.gameClock -= elapsed
            if game.gameClock <= 0 {
                game.gameClock = 0
                endPeriod()
            }
        }
        
        // Update shot clock if needed
        if game.shotClock > 0 {
            game.shotClock -= elapsed
            if game.shotClock <= 0 {
                game.shotClock = 0
                // Handle shot clock violation
                recordEvent(type: .shot, team: selectedTeam == .home ? .home : .away,
                           playerNumber: nil, info: ["type": "shot_clock_violation"])
            }
        }
    }
    
    // MARK: - Game Actions
    
    func scoreGoal(for team: TeamType, player: GamePlayer) {
        if team == .home {
            game.homeScore += 1
            updatePlayerStats(team: team, playerNumber: player.number) { player in
                player.goals += 1
            }
        } else {
            game.awayScore += 1
            updatePlayerStats(team: team, playerNumber: player.number) { player in
                player.goals += 1
            }
        }
        
        recordEvent(type: .goal, 
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
        
        // Reset shot clock after goal
        resetShotClock()
        
        // Record action for photo tagging
        recordPlayerAction(player, action: "Goal")
    }
    
    func recordExclusion(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.exclusions += 1
            if player.exclusions >= 3 {
                player.isFouledOut = true
                recordEvent(type: .foulOut,
                           team: team == .home ? .home : .away,
                           playerNumber: player.number)
            }
        }
        
        recordEvent(type: .exclusion,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
                   
        // Record action for photo tagging
        recordPlayerAction(player, action: "Exclusion")
    }
    
    func recordExclusionDrawn(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.exclusionsDrawn += 1
            if player.exclusionsDrawn + player.penaltiesDrawn >= 3 {
                player.isFouledOut = true
                recordEvent(type: .foulOut,
                           team: team == .home ? .home : .away,
                           playerNumber: player.number)
            }
        }
        
        recordEvent(type: .exclusionDrawn,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordPenalty(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.exclusions += 1
            if player.exclusions >= 3 {
                player.isFouledOut = true
                recordEvent(type: .foulOut,
                           team: team == .home ? .home : .away,
                           playerNumber: player.number)
            }
        }
        
        recordEvent(type: .penalty,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordPenaltyDrawn(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.penaltiesDrawn += 1
            if player.exclusionsDrawn + player.penaltiesDrawn >= 3 {
                player.isFouledOut = true
                recordEvent(type: .foulOut,
                           team: team == .home ? .home : .away,
                           playerNumber: player.number)
            }
        }
        
        recordEvent(type: .penaltyDrawn,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordSprintWon(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.sprintsWon += 1
        }
        
        recordEvent(type: .sprintWon,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordSprintLost(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.sprintsLost += 1
        }
        
        recordEvent(type: .sprintLost,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordSteal(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.steals += 1
        }
        
        recordEvent(type: .steal,
                   team: team == .home ? .home : .away,
                   playerNumber: player.number)
    }
    
    func recordAssist(for team: TeamType, player: GamePlayer) {
        updatePlayerStats(team: team, playerNumber: player.number) { player in
            player.assists += 1
        }
    }
    
    func callTimeout(team: TeamType) {
        if team == .home {
            game.homeTimeoutsRemaining = max(0, game.homeTimeoutsRemaining - 1)
        } else {
            game.awayTimeoutsRemaining = max(0, game.awayTimeoutsRemaining - 1)
        }
        recordEvent(type: .timeout,
                   team: team == .home ? .home : .away)
    }
    
    // MARK: - Period Management
    
    func startNextPeriod() {
        game.period += 1
        game.gameClock = game.gameLevel.periodLength
        game.isPeriodActive = true
        resetShotClock()
        recordEvent(type: .periodStart, team: .official)
    }

    func endPeriod() {
        game.isPeriodActive = false
        stopTimer()
        isTimerRunning = false
        game.periodScores.append(
            PeriodScore(period: game.period, homeScore: game.homeScore, awayScore: game.awayScore)
        )
        recordEvent(type: .periodEnd, team: .official)
        periodJustEnded = true
    }
    
    // MARK: - Shot Clock
    
    func resetShotClock() {
        game.shotClock = 30.0
    }
    
    func startShotClock() {
        if game.shotClock <= 0 {
            game.shotClock = 30.0
        }
    }
    
    // MARK: - Player Management
    
    func updatePlayerStats(team: TeamType, playerNumber: Int, update: (inout GamePlayer) -> Void) {
        if team == .home {
            if let index = game.homeTeam.players.firstIndex(where: { $0.number == playerNumber }) {
                update(&game.homeTeam.players[index])
            }
        } else {
            if let index = game.awayTeam.players.firstIndex(where: { $0.number == playerNumber }) {
                update(&game.awayTeam.players[index])
            }
        }
    }
    
    // MARK: - Event Recording
    
    private func recordEvent(type: GameEventRecord.EventType, 
                            team: GameEventRecord.TeamType,
                            playerNumber: Int? = nil,
                            info: [String: String]? = nil) {
        let event = GameEventRecord(
            id: UUID(),
            timestamp: Date(),
            period: game.period,
            gameTime: 420.0 - game.gameClock,
            eventType: type,
            team: team,
            playerNumber: playerNumber,
            additionalInfo: info
        )
        game.events.append(event)
    }
    
    // MARK: - Game Log Management
    
    func adjustEventTime(eventId: UUID, newGameTime: TimeInterval) {
        if let index = game.events.firstIndex(where: { $0.id == eventId }) {
            let event = game.events[index]
            // Create a new event with adjusted time
            game.events[index] = GameEventRecord(
                id: event.id,
                timestamp: event.timestamp,
                period: event.period,
                gameTime: newGameTime,
                eventType: event.eventType,
                team: event.team,
                playerNumber: event.playerNumber,
                additionalInfo: event.additionalInfo
            )
        }
    }
    
    func getGameLog() -> [GameEventRecord] {
        return game.events.sorted { $0.gameTime > $1.gameTime }
    }
    
    func getPlayerGameLog(playerNumber: Int, team: TeamType) -> [GameEventRecord] {
        return game.events
            .filter { $0.playerNumber == playerNumber && 
                     ($0.team == (team == .home ? .home : .away)) }
            .sorted { $0.gameTime > $1.gameTime }
    }
    
    // MARK: - Export Functions
    
    func exportToMaxPreps() -> Data? {
        let export = MaxPrepsExport(
            gameId: game.id.uuidString,
            homeTeam: createTeamExport(team: game.homeTeam, score: game.homeScore),
            awayTeam: createTeamExport(team: game.awayTeam, score: game.awayScore),
            gameDate: game.startTime,
            location: game.location,
            gameType: game.gameType.rawValue,
            gameLevel: game.gameLevel.rawValue,
            periods: createPeriodExports()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(export)
    }
    
    private func createTeamExport(team: GameTeam, score: Int) -> MaxPrepsExport.TeamExport {
        let players = team.players.map { player in
            MaxPrepsExport.PlayerExport(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions
            )
        }

        return MaxPrepsExport.TeamExport(
            name: team.name,
            score: score,
            players: players
        )
    }
    
    private func createPeriodExports() -> [MaxPrepsExport.PeriodExport] {
        // This is a simplified version - in a real app, you'd track period scores
        return [
            MaxPrepsExport.PeriodExport(
                periodNumber: 1,
                homeScore: game.homeScore,
                awayScore: game.awayScore
            )
        ]
    }
    
    func exportToClubWaterPolo() -> Data? {
        let homePlayerStats = game.homeTeam.players.map { player in
            ClubWaterPoloExport.PlayerStats(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions,
                sprintsWon: 0,
                saves: player.isGoalie ? 0 : nil,
                goalsAllowed: player.isGoalie ? 0 : nil
            )
        }
        
        let awayPlayerStats = game.awayTeam.players.map { player in
            ClubWaterPoloExport.PlayerStats(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions,
                sprintsWon: 0,
                saves: player.isGoalie ? 0 : nil,
                goalsAllowed: player.isGoalie ? 0 : nil
            )
        }
        
        let export = ClubWaterPoloExport(
            gameId: game.id.uuidString,
            date: game.startTime,
            homeTeam: game.homeTeam.name,
            awayTeam: game.awayTeam.name,
            gameType: game.gameType.rawValue,
            gameLevel: game.gameLevel.rawValue,
            location: game.location,
            finalScore: "\(game.homeScore) - \(game.awayScore)",
            periodScores: ["\(game.homeScore) - \(game.awayScore)"],
            homeRoster: homePlayerStats,
            awayRoster: awayPlayerStats
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(export)
    }
    
    // MARK: - Reset Game
    
    func resetGame() {
        stopTimer()
        let homeTeam = GameTeam(name: "Dark", isHomeTeam: true)
        let awayTeam = GameTeam(name: "Light", isHomeTeam: false)
        game = GameSession(homeTeam: homeTeam, awayTeam: awayTeam)
        selectedTeam = .home
        selectedPlayer = nil
        isTimerRunning = false
        lastUpdateTime = nil
    }
    
    // MARK: - Photo Capture
    
    @Published var lastPlayerAction: (player: GamePlayer, action: String, time: Date)?
    
    func recordPlayerAction(_ player: GamePlayer, action: String) {
        lastPlayerAction = (player: player, action: action, time: Date())
    }
    
    func getPlayerForPhoto() -> GamePlayer? {
        // Return player if photo taken within 5 seconds of their action
        guard let lastAction = lastPlayerAction else { return nil }
        let timeSinceAction = Date().timeIntervalSince(lastAction.time)
        return timeSinceAction < 5.0 ? lastAction.player : nil
    }
    
    // MARK: - Save Game
    
    @Published var isSaving = false
    @Published var saveError: String?
    
    func saveGame(context: NSManagedObjectContext, completion: ((Bool) -> Void)? = nil) {
        isSaving = true
        saveError = nil
        
        game.saveToCoreData(context: context) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false
                switch result {
                case .success:
                    completion?(true)
                case .failure(let error):
                    self?.saveError = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        stopTimer()
    }
}
