import Foundation
import CoreData

extension Season {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Season> {
        return NSFetchRequest<Season>(entityName: "Season")
    }

    /// Fetch all seasons sorted by year descending.
    @nonobjc public class func fetchAllSorted() -> NSFetchRequest<Season> {
        let request = NSFetchRequest<Season>(entityName: "Season")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Season.year, ascending: false)]
        return request
    }

    /// Fetch the currently active season.
    @nonobjc public class func fetchActive() -> NSFetchRequest<Season> {
        let request = NSFetchRequest<Season>(entityName: "Season")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        return request
    }
}

// MARK: - Generated accessors for games
extension Season {
    @objc(addGamesObject:)
    @NSManaged public func addToGames(_ value: Game)

    @objc(removeGamesObject:)
    @NSManaged public func removeFromGames(_ value: Game)

    @objc(addGames:)
    @NSManaged public func addToGames(_ values: NSSet)

    @objc(removeGames:)
    @NSManaged public func removeFromGames(_ values: NSSet)
}
