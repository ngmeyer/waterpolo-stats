import Foundation
import CoreData

@objc(Team)
public class Team: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var clubName: String?
    @NSManaged public var level: String?
    @NSManaged public var teamColor: String?
    @NSManaged public var seasonYear: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var players: Set<Player>?
    @NSManaged public var homeGames: Set<Game>?
    @NSManaged public var awayGames: Set<Game>?

    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedName: String { name ?? "Unknown Team" }
    public var wrappedClubName: String { clubName ?? "" }
    public var wrappedLevel: String { level ?? "" }
    public var wrappedCreatedAt: Date { createdAt ?? Date() }

    /// "680 Red", "Clayton Valley", "UC Berkeley Bears", etc.
    /// Joins clubName + name; falls back gracefully if either is empty.
    public var displayName: String {
        let parts = [clubName ?? "", name ?? ""].filter { !$0.isEmpty }
        return parts.isEmpty ? "Unknown Team" : parts.joined(separator: " ")
    }

    public var playersArray: [Player] {
        let set = players ?? []
        return set.sorted { $0.wrappedName < $1.wrappedName }
    }

    public var allGames: [Game] {
        let homeGamesSet = homeGames ?? []
        let awayGamesSet = awayGames ?? []
        return Array(homeGamesSet.union(awayGamesSet)).sorted { $0.wrappedDate < $1.wrappedDate }
    }
}
