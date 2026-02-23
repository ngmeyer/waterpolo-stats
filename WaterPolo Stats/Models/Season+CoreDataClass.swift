import Foundation
import CoreData

/// A water polo season: Aug 1 of `year` through Jul 31 of `year+1`.
@objc(Season)
public class Season: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var year: Int16         // e.g. 2025 = Aug 2025 - Jul 2026
    @NSManaged public var startDate: Date?    // Aug 1 of year
    @NSManaged public var endDate: Date?      // Jul 31 of year+1
    @NSManaged public var isActive: Bool
    @NSManaged public var games: Set<Game>?

    public var wrappedId: UUID { id ?? UUID() }
    public var wrappedStartDate: Date { startDate ?? Date() }
    public var wrappedEndDate: Date { endDate ?? Date() }

    /// Human-readable label, e.g. "2025-26".
    public var displayLabel: String {
        let y = Int(year)
        return "\(y)-\(String(y + 1).suffix(2))"
    }

    public var gamesArray: [Game] {
        let set = games ?? []
        return set.sorted { $0.wrappedDate < $1.wrappedDate }
    }

    // MARK: - Factory

    /// Build dates for a water polo season starting Aug 1 of `year`.
    static func makeDates(year: Int) -> (start: Date, end: Date) {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let start = cal.date(from: DateComponents(year: year, month: 8, day: 1))!
        let end   = cal.date(from: DateComponents(year: year + 1, month: 7, day: 31))!
        return (start, end)
    }

    /// Returns true if `date` falls within this season.
    func contains(date: Date) -> Bool {
        guard let s = startDate, let e = endDate else { return false }
        return date >= s && date <= e
    }
}
