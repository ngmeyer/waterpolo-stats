import Foundation
import CoreData

@objc(Game)
public class Game: NSManagedObject, Identifiable, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var location: String?
    @NSManaged public var status: String?
    @NSManaged public var homeTeamId: UUID?
    @NSManaged public var awayTeamId: UUID?
    @NSManaged public var seasonId: UUID?
    @NSManaged public var homeTeam: Team?
    @NSManaged public var awayTeam: Team?
    @NSManaged public var season: Season?
    @NSManaged public var events: Set<GameEvent>?
    @NSManaged public var rosters: Set<GameRoster>?

    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedDate: Date { date ?? Date() }
    public var wrappedLocation: String { location ?? "" }

    public var gameStatus: GameStatus {
        get { GameStatus(rawValue: status ?? "") ?? .inProgress }
        set { status = newValue.rawValue }
    }

    public var homeTeamName: String { homeTeam?.name ?? "Home Team" }
    public var awayTeamName: String { awayTeam?.name ?? "Away Team" }

    public var eventsArray: [GameEvent] {
        let set = events ?? []
        return set.sorted { $0.wrappedTimestamp < $1.wrappedTimestamp }
    }

    /// All roster entries for this game, sorted by team then rosterOrder.
    public var rostersArray: [GameRoster] {
        let set = rosters ?? []
        return set.sorted {
            if $0.isHomeTeam != $1.isHomeTeam { return $0.isHomeTeam }
            return $0.rosterOrder < $1.rosterOrder
        }
    }

    /// Active roster entries only (exitedGameAt == nil).
    public var activeHomeRosters: [GameRoster] {
        rostersArray.filter { $0.isHomeTeam && $0.exitedGameAt == nil }
    }

    public var activeAwayRosters: [GameRoster] {
        rostersArray.filter { !$0.isHomeTeam && $0.exitedGameAt == nil }
    }
}
