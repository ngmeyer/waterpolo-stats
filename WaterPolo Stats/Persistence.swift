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
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "WaterPoloScorekeeper")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Alias for compatibility with windsurf-project code
typealias DataController = PersistenceController
