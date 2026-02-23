import Foundation

// MARK: - Game Status

/// Lifecycle state of a persisted game.
public enum GameStatus: String, Codable {
    case ready      = "ready"       // configured, clock not yet started
    case inProgress = "in_progress" // clock running
    case paused     = "paused"
    case completed  = "completed"
}

// MARK: - GameRosterEntry

/// A single roster slot for one game.  Multiple entries per player model cap swaps.
public struct GameRosterEntry: Identifiable, Codable {
    public let id: UUID
    public let playerId: UUID
    public let capNumber: Int
    public let isGoalie: Bool
    public let isHomeTeam: Bool
    public let rosterOrder: Int    // 1 = original slot; >1 = swap
    public var isActive: Bool      // false when exitedAt is set
    public var enteredAt: Date
    public var exitedAt: Date?

    public init(
        id: UUID = UUID(),
        playerId: UUID,
        capNumber: Int,
        isGoalie: Bool,
        isHomeTeam: Bool,
        rosterOrder: Int = 1,
        isActive: Bool = true,
        enteredAt: Date = Date(),
        exitedAt: Date? = nil
    ) {
        self.id = id
        self.playerId = playerId
        self.capNumber = capNumber
        self.isGoalie = isGoalie
        self.isHomeTeam = isHomeTeam
        self.rosterOrder = rosterOrder
        self.isActive = isActive
        self.enteredAt = enteredAt
        self.exitedAt = exitedAt
    }
}

// MARK: - In-Memory Models for Real-Time Scoring
// These structs are used for active game scoring and are NOT persisted to Core Data
// They are separate from the Core Data entities (Game, Team, Player, GameEvent)

struct PeriodScore: Identifiable, Codable {
    let id: UUID
    let period: Int
    let homeScore: Int   // cumulative at end of this period
    let awayScore: Int   // cumulative at end of this period

    init(id: UUID = UUID(), period: Int, homeScore: Int, awayScore: Int) {
        self.id = id
        self.period = period
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

struct GameSession: Identifiable, Codable {
    let id: UUID
    var homeTeam: GameTeam
    var awayTeam: GameTeam
    var period: Int
    var gameClock: TimeInterval
    var shotClock: TimeInterval
    var homeScore: Int
    var awayScore: Int
    var isGameActive: Bool
    var isPeriodActive: Bool
    var startTime: Date
    var endTime: Date?
    var events: [GameEventRecord]
    var actions: [GameActionRecord]
    var gameType: GameType
    var gameLevel: GameLevel
    var location: String
    var notes: String
    var homeTimeoutsRemaining: Int
    var awayTimeoutsRemaining: Int
    var maxTimeoutsPerTeam: Int
    var overtimePeriodLength: TimeInterval
    var maxOvertimePeriods: Int
    var periodScores: [PeriodScore]

    // MARK: - New roster fields
    var status: GameStatus
    var homeRoster: [GameRosterEntry]
    var awayRoster: [GameRosterEntry]
    var seasonId: UUID?

    /// Water polo always has 4 regulation quarters
    static let regularPeriods = 4

    var isLastPeriod: Bool {
        period >= Self.regularPeriods + maxOvertimePeriods
    }

    // MARK: - Roster helpers

    /// All roster entries for a given side (both active and historical).
    func allRoster(home: Bool) -> [GameRosterEntry] {
        home ? homeRoster : awayRoster
    }

    /// Currently active roster entries for a side.
    func activeRoster(home: Bool) -> [GameRosterEntry] {
        allRoster(home: home).filter { $0.isActive }
    }

    /// Active roster entries for a player (should be 0 or 1).
    func activeEntries(for playerId: UUID) -> [GameRosterEntry] {
        (homeRoster + awayRoster).filter { $0.playerId == playerId && $0.isActive }
    }

    // MARK: - Cap swap

    /// Records a cap swap: exits the player's current slot and opens a new one.
    /// - Parameters:
    ///   - playerId: The player being swapped.
    ///   - newCapNumber: Their new cap number.
    ///   - isGoalie: Whether they are now a goalie.
    ///   - at: Timestamp for the swap (defaults to now).
    /// - Returns: Updated copy of the session with the swap applied.
    func applyingCapSwap(
        playerId: UUID,
        newCapNumber: Int,
        isGoalie: Bool,
        at date: Date = Date()
    ) -> GameSession {
        var copy = self
        let isHome = homeRoster.contains { $0.playerId == playerId && $0.isActive }

        // Exit existing active slot
        if isHome {
            copy.homeRoster = homeRoster.map { entry in
                guard entry.playerId == playerId && entry.isActive else { return entry }
                var e = entry
                e.exitedAt = date
                e.isActive = false
                return e
            }
        } else {
            copy.awayRoster = awayRoster.map { entry in
                guard entry.playerId == playerId && entry.isActive else { return entry }
                var e = entry
                e.exitedAt = date
                e.isActive = false
                return e
            }
        }

        // Calculate next rosterOrder for this player
        let existing = (homeRoster + awayRoster).filter { $0.playerId == playerId }
        let nextOrder = (existing.map { $0.rosterOrder }.max() ?? 0) + 1

        let newEntry = GameRosterEntry(
            playerId: playerId,
            capNumber: newCapNumber,
            isGoalie: isGoalie,
            isHomeTeam: isHome,
            rosterOrder: nextOrder,
            isActive: true,
            enteredAt: date
        )

        if isHome {
            copy.homeRoster.append(newEntry)
        } else {
            copy.awayRoster.append(newEntry)
        }

        return copy
    }

    enum GameType: String, Codable, CaseIterable {
        case league    = "League"
        case nonLeague = "Non-League"
        case tournament = "Tournament"
        case scrimmage = "Scrimmage"
    }

    enum GameLevel: String, Codable, CaseIterable {
        // High School - Girls
        case girlsVarsity = "Girls Varsity"
        case girlsJV = "Girls JV"

        // High School - Boys
        case boysVarsity = "Boys Varsity"
        case boysJV = "Boys JV"

        // Club - Coed
        case u10Coed = "U10 Coed"
        case u12Coed = "U12 Coed"
        case u14Coed = "U14 Coed"

        // Club - Girls
        case u12Girls = "U12 Girls"
        case u14Girls = "U14 Girls"
        case u16Girls = "U16 Girls"
        case u18Girls = "U18 Girls"
        case u19Girls = "U19 Girls"

        // Club - Boys
        case u12Boys = "U12 Boys"
        case u14Boys = "U14 Boys"
        case u16Boys = "U16 Boys"
        case u18Boys = "U18 Boys"
        case u19Boys = "U19 Boys"

        var category: String {
            switch self {
            case .girlsVarsity, .girlsJV: return "High School - Girls"
            case .boysVarsity, .boysJV: return "High School - Boys"
            case .u10Coed, .u12Coed, .u14Coed: return "Club - Coed"
            case .u12Girls, .u14Girls, .u16Girls, .u18Girls, .u19Girls: return "Club - Girls"
            case .u12Boys, .u14Boys, .u16Boys, .u18Boys, .u19Boys: return "Club - Boys"
            }
        }

        var isHighSchool: Bool { category.contains("High School") }
        var isClub: Bool { category.contains("Club") }
        var isGirls: Bool { category.contains("Girls") }
        var isBoys: Bool { category.contains("Boys") }
        var isCoed: Bool { category.contains("Coed") }

        /// Period length in seconds
        var periodLength: TimeInterval {
            switch self {
            case .girlsVarsity, .girlsJV, .boysVarsity, .boysJV:
                return 420.0 // 7 min - NFHS High School
            case .u16Girls, .u16Boys, .u18Girls, .u18Boys, .u19Girls, .u19Boys:
                return 480.0 // 8 min - Senior club
            case .u14Coed, .u14Girls, .u14Boys:
                return 360.0 // 6 min - U14
            case .u10Coed, .u12Coed, .u12Girls, .u12Boys:
                return 300.0 // 5 min - Youth
            }
        }

        /// Default timeouts per team: NFHS (high school) = 3, USAWP (club) = 2
        var defaultMaxTimeouts: Int { isHighSchool ? 3 : 2 }
    }

    init(
        id: UUID = UUID(),
        homeTeam: GameTeam,
        awayTeam: GameTeam,
        period: Int = 1,
        gameClock: TimeInterval = 420.0,
        shotClock: TimeInterval = 30.0,
        homeScore: Int = 0,
        awayScore: Int = 0,
        isGameActive: Bool = false,
        isPeriodActive: Bool = false,
        gameType: GameType = .league,
        gameLevel: GameLevel = .girlsVarsity,
        location: String = "",
        notes: String = "",
        maxTimeoutsPerTeam: Int? = nil,
        overtimePeriodLength: TimeInterval = 180.0,
        maxOvertimePeriods: Int = 2,
        status: GameStatus = .inProgress,
        homeRoster: [GameRosterEntry] = [],
        awayRoster: [GameRosterEntry] = [],
        seasonId: UUID? = nil
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.period = period
        self.gameClock = gameClock
        self.shotClock = shotClock
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.isGameActive = isGameActive
        self.isPeriodActive = isPeriodActive
        self.startTime = Date()
        self.gameType = gameType
        self.gameLevel = gameLevel
        self.location = location
        self.notes = notes
        self.events = []
        self.actions = []
        self.periodScores = []
        let resolvedMax = maxTimeoutsPerTeam ?? gameLevel.defaultMaxTimeouts
        self.maxTimeoutsPerTeam = resolvedMax
        self.homeTimeoutsRemaining = resolvedMax
        self.awayTimeoutsRemaining = resolvedMax
        self.overtimePeriodLength = overtimePeriodLength
        self.maxOvertimePeriods = maxOvertimePeriods
        self.status = status
        self.homeRoster = homeRoster
        self.awayRoster = awayRoster
        self.seasonId = seasonId
    }
}

struct GameTeam: Identifiable, Codable {
    let id: UUID
    var name: String
    var players: [GamePlayer]
    var coach: String
    var isHomeTeam: Bool

    init(id: UUID = UUID(), name: String, players: [GamePlayer] = [], coach: String = "", isHomeTeam: Bool) {
        self.id = id
        self.name = name
        self.players = players
        self.coach = coach
        self.isHomeTeam = isHomeTeam
    }
}

struct GamePlayer: Identifiable, Codable {
    let id: UUID
    var number: Int
    var name: String
    var isInGame: Bool
    var isGoalie: Bool
    var goals: Int
    var assists: Int
    var steals: Int
    var exclusions: Int
    var exclusionsDrawn: Int
    var penaltiesDrawn: Int
    var sprintsWon: Int
    var sprintsLost: Int
    var isFouledOut: Bool

    init(
        id: UUID = UUID(),
        number: Int,
        name: String,
        isInGame: Bool = false,
        isGoalie: Bool = false,
        goals: Int = 0,
        assists: Int = 0,
        steals: Int = 0,
        exclusions: Int = 0,
        exclusionsDrawn: Int = 0,
        penaltiesDrawn: Int = 0,
        sprintsWon: Int = 0,
        sprintsLost: Int = 0,
        isFouledOut: Bool = false
    ) {
        self.id = id
        self.number = number
        self.name = name
        self.isInGame = isInGame
        self.isGoalie = isGoalie
        self.goals = goals
        self.assists = assists
        self.steals = steals
        self.exclusions = exclusions
        self.exclusionsDrawn = exclusionsDrawn
        self.penaltiesDrawn = penaltiesDrawn
        self.sprintsWon = sprintsWon
        self.sprintsLost = sprintsLost
        self.isFouledOut = isFouledOut
    }

    var totalFouls: Int { exclusions + penaltiesDrawn }
    var canReceiveFoul: Bool { totalFouls < 3 && !isFouledOut }
}

struct GameEventRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let period: Int
    let gameTime: TimeInterval
    let eventType: EventType
    let team: TeamType
    let playerNumber: Int?
    let additionalInfo: [String: String]?

    enum EventType: String, Codable {
        case goal, shot, exclusion, exclusionDrawn, penalty, penaltyDrawn
        case sprintWon, sprintLost, steal, assist, timeout
        case periodStart, periodEnd, gameStart, gameEnd, foulOut
    }

    enum TeamType: String, Codable {
        case home, away, official
    }
}


// MARK: - MaxPreps Export
struct MaxPrepsExport: Codable {
    let gameId: String
    let homeTeam: TeamExport
    let awayTeam: TeamExport
    let gameDate: Date
    let location: String
    let gameType: String
    let gameLevel: String
    let periods: [PeriodExport]

    struct TeamExport: Codable {
        let name: String
        let score: Int
        let players: [PlayerExport]
    }

    struct PlayerExport: Codable {
        let number: Int
        let name: String
        let goals: Int
        let assists: Int
        let steals: Int
        let exclusions: Int
    }

    struct PeriodExport: Codable {
        let periodNumber: Int
        let homeScore: Int
        let awayScore: Int
    }
}

// MARK: - Club Water Polo Export
struct ClubWaterPoloExport: Codable {
    let gameId: String
    let date: Date
    let homeTeam: String
    let awayTeam: String
    let gameType: String
    let gameLevel: String
    let location: String
    let finalScore: String
    let periodScores: [String]
    let homeRoster: [PlayerStats]
    let awayRoster: [PlayerStats]

    struct PlayerStats: Codable {
        let number: Int
        let name: String
        let goals: Int
        let assists: Int
        let steals: Int
        let exclusions: Int
        let sprintsWon: Int
        let saves: Int?
        let goalsAllowed: Int?
    }
}
