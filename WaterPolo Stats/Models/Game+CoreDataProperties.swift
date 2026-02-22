import Foundation
import CoreData

extension Game {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }
}

// MARK: Generated accessors for events
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
