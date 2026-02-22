import Foundation
import CoreData

extension Player {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Player> {
        return NSFetchRequest<Player>(entityName: "Player")
    }

    /// Fetch players sorted by name.
    @nonobjc public class func fetchRequestSortedByName() -> NSFetchRequest<Player> {
        let request = NSFetchRequest<Player>(entityName: "Player")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Player.name, ascending: true)]
        return request
    }
}

// MARK: - Generated accessors for events
extension Player {
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
extension Player {
    @objc(addRostersObject:)
    @NSManaged public func addToRosters(_ value: GameRoster)

    @objc(removeRostersObject:)
    @NSManaged public func removeFromRosters(_ value: GameRoster)

    @objc(addRosters:)
    @NSManaged public func addToRosters(_ values: NSSet)

    @objc(removeRosters:)
    @NSManaged public func removeFromRosters(_ values: NSSet)
}
