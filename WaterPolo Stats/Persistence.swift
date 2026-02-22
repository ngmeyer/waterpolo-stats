//
//  Persistence.swift
//  WaterPolo Stats
//
//  Created by Neal Meyer on 10/25/25.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample teams
        let homeTeam = Team(context: viewContext)
        homeTeam.id = UUID()
        homeTeam.name = "Home Team"
        
        let awayTeam = Team(context: viewContext)
        awayTeam.id = UUID()
        awayTeam.name = "Away Team"
        
        // Create sample game
        let game = Game(context: viewContext)
        game.id = UUID()
        game.date = Date()
        game.location = "Pool"
        game.homeTeam = homeTeam
        game.awayTeam = awayTeam
        
        do {
            try viewContext.save()
        } catch {
            // Preview context - log error but don't crash
            print("Preview setup error: \(error.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "WaterPoloScorekeeper")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { [weak self] (_, error) in
            if let error = error as NSError? {
                // Log error but don't crash in production
                print("Core Data store error: \(error), \(error.userInfo)")
                
                #if DEBUG
                fatalError("Core Data error (debug): \(error)")
                #endif
            }
            self?.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
}

// Alias for compatibility
typealias DataController = PersistenceController
