import Foundation
import CoreData

extension Game {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    /// Fetch all games with a given status.
    @nonobjc public class func fetchRequest(status: GameStatus) -> NSFetchRequest<Game> {
        let request = NSFetchRequest<Game>(entityName: "Game")
        request.predicate = NSPredicate(format: "status == %@", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Game.date, ascending: false)]
        return request
    }
}

// MARK: - Generated accessors for events
extension Game {
    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: GameEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: GameEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)
}

// MARK: - Generated accessors for rosters
extension Game {
    @objc(addRostersObject:)
    @NSManaged public func addToRosters(_ value: GameRoster)

    @objc(removeRostersObject:)
    @NSManaged public func removeFromRosters(_ value: GameRoster)

    @objc(addRosters:)
    @NSManaged public func addToRosters(_ values: NSSet)

    @objc(removeRosters:)
    @NSManaged public func removeFromRosters(_ values: NSSet)
}
