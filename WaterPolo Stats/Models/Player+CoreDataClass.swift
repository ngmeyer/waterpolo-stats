import Foundation
import CoreData

@objc(Player)
public class Player: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var profilePhoto: Data?
    @NSManaged public var nscaId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var team: Team?
    @NSManaged public var events: Set<GameEvent>?
    @NSManaged public var rosters: Set<GameRoster>?

    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedName: String { name ?? "Unknown Player" }
    public var wrappedNumber: String { number ?? "" }
    public var wrappedCreatedAt: Date { createdAt ?? Date() }

    public var eventsArray: [GameEvent] {
        let set = events ?? []
        return set.sorted { $0.wrappedTimestamp < $1.wrappedTimestamp }
    }

    public var rostersArray: [GameRoster] {
        let set = rosters ?? []
        return set.sorted { ($0.enteredGameAt ?? Date.distantPast) < ($1.enteredGameAt ?? Date.distantPast) }
    }

    // MARK: - Career stats (computed from all events)

    public var goals: Int {
        eventsArray.filter { $0.eventType == "goal" }.count
    }

    public var assists: Int {
        eventsArray.filter { $0.eventType == "assist" }.count
    }

    public var steals: Int {
        eventsArray.filter { $0.eventType == "steal" }.count
    }

    public var exclusions: Int {
        eventsArray.filter { $0.eventType == "exclusion" }.count
    }

    /// Cap number: uses most recent game roster entry if available, otherwise falls back to stored number.
    public var currentCapNumber: Int? {
        if let fromRoster = rostersArray.last.map({ Int($0.capNumber) }) {
            return fromRoster
        }
        return number.flatMap { Int($0) }
    }
}
