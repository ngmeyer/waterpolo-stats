import Foundation
import CoreData

@objc(GameEvent)
public class GameEvent: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var eventType: String?
    @NSManaged public var period: Int16
    @NSManaged public var periodTime: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var game: Game?
    @NSManaged public var player: Player?
    
    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedEventType: String { eventType ?? "unknown" }
    public var wrappedPeriodTime: String { periodTime ?? "00:00" }
    public var wrappedTimestamp: Date { timestamp ?? Date() }
    
    public var eventDescription: String {
        let playerName = player?.wrappedName ?? "Unknown Player"
        
        switch wrappedEventType {
        case "goal":
            return "\(playerName) scored a goal"
        case "assist":
            return "\(playerName) made an assist"
        case "steal":
            return "\(playerName) made a steal"
        case "exclusion":
            return "\(playerName) was excluded"
        case "turnover":
            return "\(playerName) turned over the ball"
        case "foul":
            return "\(playerName) committed a foul"
        default:
            return "\(playerName): \(wrappedEventType)"
        }
    }
}
