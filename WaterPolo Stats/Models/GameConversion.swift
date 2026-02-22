import Foundation
import CoreData

// MARK: - Game Conversion
// Converts between GameSession (struct) and Game (Core Data)

extension GameSession {
    /// Saves this game session to Core Data
    /// - Parameters:
    ///   - context: The managed object context
    ///   - completion: Called when save completes with success/failure
    func saveToCoreData(context: NSManagedObjectContext, completion: ((Result<Game, Error>) -> Void)? = nil) {
        // Create game entity
        let gameEntity = Game(context: context)
        gameEntity.id = self.id
        gameEntity.date = self.startTime
        gameEntity.location = self.location
        
        // Create and save home team
        let homeTeamEntity = Team(context: context)
        homeTeamEntity.id = UUID()
        homeTeamEntity.name = self.homeTeam.name
        gameEntity.homeTeam = homeTeamEntity
        
        // Create home team players
        for gamePlayer in self.homeTeam.players {
            let playerEntity = createPlayerEntity(from: gamePlayer, team: homeTeamEntity, context: context)
            homeTeamEntity.addToPlayers(playerEntity)
        }
        
        // Create and save away team
        let awayTeamEntity = Team(context: context)
        awayTeamEntity.id = UUID()
        awayTeamEntity.name = self.awayTeam.name
        gameEntity.awayTeam = awayTeamEntity
        
        // Create away team players
        for gamePlayer in self.awayTeam.players {
            let playerEntity = createPlayerEntity(from: gamePlayer, team: awayTeamEntity, context: context)
            awayTeamEntity.addToPlayers(playerEntity)
        }
        
        // Create game events
        for event in self.events {
            let eventEntity = createGameEventEntity(from: event, game: gameEntity, context: context)
            gameEntity.addToEvents(eventEntity)
        }
        
        // Save context
        do {
            try context.save()
            completion?(.success(gameEntity))
        } catch {
            completion?(.failure(error))
        }
    }
    
    private func createPlayerEntity(from gamePlayer: GamePlayer, team: Team, context: NSManagedObjectContext) -> Player {
        let player = Player(context: context)
        player.id = UUID()
        player.name = gamePlayer.name
        player.number = String(gamePlayer.number)
        player.team = team
        return player
    }
    
    private func createGameEventEntity(from record: GameEventRecord, game: Game, context: NSManagedObjectContext) -> GameEvent {
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
}

// MARK: - Team Loading

extension GameSession {
    /// Creates a GameSession from saved Core Data teams
    /// - Parameters:
    ///   - homeTeam: Core Data home team
    ///   - awayTeam: Core Data away team
    ///   - gameType: Type of game
    ///   - gameLevel: Level of game
    /// - Returns: A new GameSession populated with team rosters
    static func fromTeams(
        homeTeam: Team,
        awayTeam: Team,
        gameType: GameType = .league,
        gameLevel: GameLevel = .girlsVarsity
    ) -> GameSession {
        // Convert Core Data players to GamePlayers
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
        
        // Create GameTeams
        let homeGameTeam = GameTeam(
            name: homeTeam.wrappedName,
            players: homePlayers,
            isHomeTeam: true
        )
        
        let awayGameTeam = GameTeam(
            name: awayTeam.wrappedName,
            players: awayPlayers,
            isHomeTeam: false
        )
        
        // Create and return GameSession
        return GameSession(
            homeTeam: homeGameTeam,
            awayTeam: awayGameTeam,
            gameType: gameType,
            gameLevel: gameLevel
        )
    }
}
