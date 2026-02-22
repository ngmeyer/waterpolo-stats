import Foundation
import CoreData

@objc(Team)
public class Team: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var players: Set<Player>?
    @NSManaged public var homeGames: Set<Game>?
    @NSManaged public var awayGames: Set<Game>?
    
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedName: String { name ?? "Unknown Team" }
    
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
