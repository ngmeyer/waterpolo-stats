import Foundation
import CoreData

@objc(Game)
public class Game: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var location: String?
    @NSManaged public var homeTeam: Team?
    @NSManaged public var awayTeam: Team?
    @NSManaged public var events: Set<GameEvent>?
    
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedDate: Date { date ?? Date() }
    public var wrappedLocation: String { location ?? "" }
    
    public var homeTeamName: String {
        homeTeam?.name ?? "Home Team"
    }
    
    public var awayTeamName: String {
        awayTeam?.name ?? "Away Team"
    }
    
    public var eventsArray: [GameEvent] {
        let set = events ?? []
        return set.sorted { $0.wrappedTimestamp < $1.wrappedTimestamp }
    }
}
