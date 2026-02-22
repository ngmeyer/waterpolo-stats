import Foundation
import CoreData

@objc(Player)
public class Player: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var team: Team?
    @NSManaged public var events: Set<GameEvent>?
    
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedName: String { name ?? "Unknown Player" }
    public var wrappedNumber: String { number ?? "" }
    
    public var eventsArray: [GameEvent] {
        let set = events ?? []
        return set.sorted { $0.wrappedTimestamp < $1.wrappedTimestamp }
    }
    
    public var goals: Int {
        return eventsArray.filter { $0.eventType == "goal" }.count
    }
    
    public var assists: Int {
        return eventsArray.filter { $0.eventType == "assist" }.count
    }
    
    public var steals: Int {
        return eventsArray.filter { $0.eventType == "steal" }.count
    }
    
    public var exclusions: Int {
        return eventsArray.filter { $0.eventType == "exclusion" }.count
    }
}
