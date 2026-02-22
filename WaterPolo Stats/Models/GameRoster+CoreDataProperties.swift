import Foundation
import CoreData

extension GameRoster {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameRoster> {
        return NSFetchRequest<GameRoster>(entityName: "GameRoster")
    }

    /// Fetch all active roster entries for a specific game.
    @nonobjc public class func fetchActiveRoster(for game: Game) -> NSFetchRequest<GameRoster> {
        let request = NSFetchRequest<GameRoster>(entityName: "GameRoster")
        request.predicate = NSPredicate(
            format: "game == %@ AND exitedGameAt == nil", game
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GameRoster.isHomeTeam, ascending: false),
            NSSortDescriptor(keyPath: \GameRoster.rosterOrder, ascending: true)
        ]
        return request
    }

    /// Fetch all roster entries (including history) for a player in a game.
    @nonobjc public class func fetchHistory(
        for player: Player,
        in game: Game
    ) -> NSFetchRequest<GameRoster> {
        let request = NSFetchRequest<GameRoster>(entityName: "GameRoster")
        request.predicate = NSPredicate(format: "player == %@ AND game == %@", player, game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GameRoster.rosterOrder, ascending: true)
        ]
        return request
    }
}
