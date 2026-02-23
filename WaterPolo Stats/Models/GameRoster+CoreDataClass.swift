import Foundation
import CoreData

/// A single roster slot in a game.
///
/// Mid-game cap swaps are represented by multiple GameRoster entries for the
/// same player: the exiting entry gets `exitedGameAt` set and a new entry is
/// inserted with a higher `rosterOrder` and the new `capNumber`.
@objc(GameRoster)
public class GameRoster: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var capNumber: Int16
    @NSManaged public var isGoalie: Bool
    @NSManaged public var isHomeTeam: Bool
    @NSManaged public var rosterOrder: Int16
    @NSManaged public var enteredGameAt: Date?
    @NSManaged public var exitedGameAt: Date?
    @NSManaged public var game: Game?
    @NSManaged public var player: Player?

    public var wrappedId: UUID { id ?? UUID() }

    /// True if this roster slot is still active (player has not exited the game).
    public var isActive: Bool { exitedGameAt == nil }

    /// The player's name, falling back gracefully when the relationship is not loaded.
    public var playerName: String { player?.wrappedName ?? "Unknown Player" }

    // MARK: - Conversion to struct

    func toStruct() -> GameRosterEntry? {
        guard let playerId = player?.id else { return nil }
        return GameRosterEntry(
            id: wrappedId,
            playerId: playerId,
            capNumber: Int(capNumber),
            isGoalie: isGoalie,
            isHomeTeam: isHomeTeam,
            rosterOrder: Int(rosterOrder),
            isActive: isActive,
            enteredAt: enteredGameAt ?? Date(),
            exitedAt: exitedGameAt
        )
    }
}
