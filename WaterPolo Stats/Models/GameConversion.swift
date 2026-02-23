import Foundation
import CoreData

// MARK: - GameSession ↔ Core Data

extension GameSession {

    // MARK: Save to Core Data (with completion handler for backward compatibility)

    /// Saves this GameSession to Core Data with async completion handler.
    @MainActor
    func saveToCoreData(context: NSManagedObjectContext, completion: ((Result<Game, Error>) -> Void)? = nil) {
        do {
            let game = try toCoreData(context: context)
            completion?(.success(game))
        } catch {
            completion?(.failure(error))
        }
    }

    // MARK: Save to Core Data (synchronous, throws)

    /// Saves this GameSession (including all roster entries) to Core Data.
    /// If a Game with the same `id` already exists it is updated in place.
    @MainActor
    func toCoreData(context: NSManagedObjectContext) throws -> Game {
        // Upsert: find existing or create new
        let gameEntity = fetchOrCreateGame(id: self.id, context: context)

        gameEntity.date          = self.startTime
        gameEntity.scheduledDate = self.scheduledDate
        gameEntity.location      = self.location.isEmpty ? nil : self.location
        gameEntity.venueAddress  = self.venueAddress.isEmpty ? nil : self.venueAddress
        gameEntity.tournamentRound = self.tournamentRound.isEmpty ? nil : self.tournamentRound
        gameEntity.gameType      = self.gameType.rawValue
        gameEntity.status        = self.status.rawValue

        // Resolve season if provided
        if let sid = self.seasonId {
            let seasonFetch = NSFetchRequest<Season>(entityName: "Season")
            seasonFetch.predicate = NSPredicate(format: "id == %@", sid as CVarArg)
            seasonFetch.fetchLimit = 1
            gameEntity.season   = try context.fetch(seasonFetch).first
            gameEntity.seasonId = sid
        }

        // Teams: match by existing relationship or leave nil (team management is separate)
        let homeId = self.homeTeam.id
        let tf1 = NSFetchRequest<Team>(entityName: "Team")
        tf1.predicate = NSPredicate(format: "id == %@", homeId as CVarArg)
        tf1.fetchLimit = 1
        if let team = try context.fetch(tf1).first {
            gameEntity.homeTeam   = team
            gameEntity.homeTeamId = homeId
        }

        let awayId = self.awayTeam.id
        let tf2 = NSFetchRequest<Team>(entityName: "Team")
        tf2.predicate = NSPredicate(format: "id == %@", awayId as CVarArg)
        tf2.fetchLimit = 1
        if let team = try context.fetch(tf2).first {
            gameEntity.awayTeam   = team
            gameEntity.awayTeamId = awayId
        }

        // Rosters
        try syncRosters(self.homeRoster + self.awayRoster,
                        to: gameEntity,
                        context: context)

        // Events
        for event in self.events {
            let eventEntity = createGameEventEntity(from: event,
                                                    game: gameEntity,
                                                    context: context)
            gameEntity.addToEvents(eventEntity)
        }

        try context.save()
        return gameEntity
    }

    // MARK: Load from Core Data

    /// Reconstructs a GameSession struct from a Core Data Game entity.
    @MainActor
    static func fromCoreData(game: Game) -> GameSession {
        // Build teams
        let homeGameTeam = GameTeam(
            id: game.homeTeam?.wrappedId ?? UUID(),
            name: game.homeTeamName,
            players: buildGamePlayers(from: game, homeTeam: true),
            isHomeTeam: true
        )
        let awayGameTeam = GameTeam(
            id: game.awayTeam?.wrappedId ?? UUID(),
            name: game.awayTeamName,
            players: buildGamePlayers(from: game, homeTeam: false),
            isHomeTeam: false
        )

        // Build roster entries
        let homeRoster = game.rostersArray
            .filter { $0.isHomeTeam }
            .compactMap { $0.toStruct() }

        let awayRoster = game.rostersArray
            .filter { !$0.isHomeTeam }
            .compactMap { $0.toStruct() }

        let gameStatus = GameStatus(rawValue: game.status ?? "") ?? .inProgress

        return GameSession(
            id: game.wrappedId,
            homeTeam: homeGameTeam,
            awayTeam: awayGameTeam,
            isGameActive: gameStatus == .inProgress,
            gameType: game.wrappedGameType,
            location: game.wrappedLocation,
            venueAddress: game.wrappedVenueAddress,
            tournamentRound: game.wrappedTournamentRound,
            scheduledDate: game.scheduledDate ?? game.date ?? Date(),
            status: gameStatus,
            homeRoster: homeRoster,
            awayRoster: awayRoster,
            seasonId: game.seasonId
        )
    }

    // MARK: - Private helpers

    @MainActor
    private func fetchOrCreateGame(id: UUID, context: NSManagedObjectContext) -> Game {
        let fetch = Game.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetch.fetchLimit = 1
        if let existing = try? context.fetch(fetch).first { return existing }
        let g = Game(context: context)
        g.id = id
        return g
    }

    /// Syncs the in-memory roster array to Core Data GameRoster entities.
    /// Handles mid-game cap swaps by matching on (playerId, rosterOrder).
    @MainActor
    private func syncRosters(
        _ entries: [GameRosterEntry],
        to game: Game,
        context: NSManagedObjectContext
    ) throws {
        for entry in entries {
            // Find existing roster entity for this (playerId, rosterOrder)
            let fetch = NSFetchRequest<GameRoster>(entityName: "GameRoster")
            fetch.predicate = NSPredicate(
                format: "game == %@ AND player.id == %@ AND rosterOrder == %d",
                game, entry.playerId as CVarArg, entry.rosterOrder
            )
            fetch.fetchLimit = 1

            let rosterEntity: GameRoster
            if let existing = try context.fetch(fetch).first {
                rosterEntity = existing
            } else {
                rosterEntity = GameRoster(context: context)
                rosterEntity.id = entry.id
                rosterEntity.game = game

                // Resolve or create player entity
                rosterEntity.player = try fetchOrCreatePlayer(
                    id: entry.playerId, context: context
                )
            }

            rosterEntity.capNumber   = Int16(entry.capNumber)
            rosterEntity.isGoalie    = entry.isGoalie
            rosterEntity.isHomeTeam  = entry.isHomeTeam
            rosterEntity.rosterOrder = Int16(entry.rosterOrder)
            rosterEntity.enteredGameAt = entry.enteredAt
            rosterEntity.exitedGameAt  = entry.exitedAt
        }
    }

    /// Fetches an existing Player by UUID or creates a minimal placeholder.
    @MainActor
    private func fetchOrCreatePlayer(
        id: UUID,
        context: NSManagedObjectContext
    ) throws -> Player {
        let fetch = NSFetchRequest<Player>(entityName: "Player")
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetch.fetchLimit = 1
        if let existing = try context.fetch(fetch).first { return existing }
        let p = Player(context: context)
        p.id = id
        p.createdAt = Date()
        p.updatedAt = Date()
        return p
    }

    /// Creates a GameEvent Core Data entity from a GameEventRecord struct.
    private func createGameEventEntity(
        from record: GameEventRecord,
        game: Game,
        context: NSManagedObjectContext
    ) -> GameEvent {
        let event = GameEvent(context: context)
        event.id = UUID()
        event.eventType = record.eventType.rawValue
        event.period = Int16(record.period)
        event.periodTime = formatTime(record.gameTime)
        event.timestamp = record.timestamp
        event.game = game
        return event
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Builds GamePlayer structs for a team from the game's roster + events.
    private static func buildGamePlayers(from game: Game, homeTeam: Bool) -> [GamePlayer] {
        let rosterEntries = game.rostersArray.filter { $0.isHomeTeam == homeTeam }
        // Deduplicate by player — keep the highest rosterOrder (latest swap)
        var seen: [UUID: GameRoster] = [:]
        for entry in rosterEntries {
            guard let pid = entry.player?.id else { continue }
            if let existing = seen[pid] {
                if entry.rosterOrder > existing.rosterOrder { seen[pid] = entry }
            } else {
                seen[pid] = entry
            }
        }

        return seen.values.compactMap { entry -> GamePlayer? in
            guard let player = entry.player else { return nil }
            return GamePlayer(
                id: player.wrappedId,
                number: Int(entry.capNumber),
                name: player.wrappedName,
                isInGame: entry.isActive,
                isGoalie: entry.isGoalie,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions
            )
        }.sorted { $0.number < $1.number }
    }
}

// MARK: - Team Loading (backward compatible)

extension GameSession {
    /// Creates a GameSession from saved Core Data teams (no roster entries).
    @MainActor
    static func fromTeams(
        homeTeam: Team,
        awayTeam: Team,
        gameType: GameType = .league,
        gameLevel: GameLevel = .girlsVarsity
    ) -> GameSession {
        let homePlayers = homeTeam.playersArray.map { coreDataPlayer -> GamePlayer in
            GamePlayer(
                number: Int(coreDataPlayer.wrappedNumber) ?? 0,
                name: coreDataPlayer.wrappedName,
                isInGame: false,
                isGoalie: false
            )
        }
        let awayPlayers = awayTeam.playersArray.map { coreDataPlayer -> GamePlayer in
            GamePlayer(
                number: Int(coreDataPlayer.wrappedNumber) ?? 0,
                name: coreDataPlayer.wrappedName,
                isInGame: false,
                isGoalie: false
            )
        }
        let homeGameTeam = GameTeam(
            id: homeTeam.wrappedId,
            name: homeTeam.wrappedName,
            players: homePlayers,
            isHomeTeam: true
        )
        let awayGameTeam = GameTeam(
            id: awayTeam.wrappedId,
            name: awayTeam.wrappedName,
            players: awayPlayers,
            isHomeTeam: false
        )
        return GameSession(
            homeTeam: homeGameTeam,
            awayTeam: awayGameTeam,
            gameType: gameType,
            gameLevel: gameLevel
        )
    }
}
