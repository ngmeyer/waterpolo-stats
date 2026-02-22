import Foundation
import CoreData

extension Player {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Player> {
        return NSFetchRequest<Player>(entityName: "Player")
    }
}

// MARK: Generated accessors for events
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
