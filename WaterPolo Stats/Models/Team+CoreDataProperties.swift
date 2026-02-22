import Foundation
import CoreData

extension Team {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Team> {
        return NSFetchRequest<Team>(entityName: "Team")
    }

    /// Fetch active teams sorted by name.
    @nonobjc public class func fetchActiveTeams() -> NSFetchRequest<Team> {
        let request = NSFetchRequest<Team>(entityName: "Team")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Team.clubName, ascending: true),
            NSSortDescriptor(keyPath: \Team.name, ascending: true)
        ]
        return request
    }
}

// MARK: - Generated accessors for players
extension Team {
    @objc(addPlayersObject:)
    @NSManaged public func addToPlayers(_ value: Player)

    @objc(removePlayersObject:)
    @NSManaged public func removeFromPlayers(_ value: Player)

    @objc(addPlayers:)
    @NSManaged public func addToPlayers(_ values: NSSet)

    @objc(removePlayers:)
    @NSManaged public func removeFromPlayers(_ values: NSSet)
}

// MARK: - Generated accessors for homeGames
extension Team {
    @objc(addHomeGamesObject:)
    @NSManaged public func addToHomeGames(_ value: Game)

    @objc(removeHomeGamesObject:)
    @NSManaged public func removeFromHomeGames(_ value: Game)

    @objc(addHomeGames:)
    @NSManaged public func addToHomeGames(_ values: NSSet)

    @objc(removeHomeGames:)
    @NSManaged public func removeFromHomeGames(_ values: NSSet)
}

// MARK: - Generated accessors for awayGames
extension Team {
    @objc(addAwayGamesObject:)
    @NSManaged public func addToAwayGames(_ value: Game)

    @objc(removeAwayGamesObject:)
    @NSManaged public func removeFromAwayGames(_ value: Game)

    @objc(addAwayGames:)
    @NSManaged public func addToAwayGames(_ values: NSSet)

    @objc(removeAwayGames:)
    @NSManaged public func removeFromAwayGames(_ values: NSSet)
}
