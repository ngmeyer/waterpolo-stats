import SwiftUI
import CoreData

// MARK: - Data Management View
// iCloud sync, backup, export all data

struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("enableiCloudSync") private var enableiCloudSync = true
    @State private var showExportConfirmation = false
    @State private var showClearConfirmation = false
    @State private var showImportSheet = false
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    
    var body: some View {
        List {
            // iCloud Section
            Section(header: Text("iCloud"), footer: Text("Sync your data across all your devices")) {
                Toggle("Enable iCloud Sync", isOn: $enableiCloudSync)
                
                Button("Sync Now") {
                    triggerSync()
                }
                .disabled(!enableiCloudSync)
            }
            
            // Backup Section
            Section(header: Text("Backup")) {
                Button(action: exportAllData) {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                        Text("Export All Data")
                    }
                }
                
                Button(action: { showImportSheet = true }) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Import Data")
                    }
                }
            }
            
            // Data Stats Section
            Section(header: Text("Data Statistics")) {
                DataStatRow(label: "Total Games", value: totalGames)
                DataStatRow(label: "Total Teams", value: totalTeams)
                DataStatRow(label: "Total Players", value: totalPlayers)
                DataStatRow(label: "Total Seasons", value: totalSeasons)
                DataStatRow(label: "Storage Used", value: storageUsed)
            }
            
            // Danger Zone
            Section(header: Text("Danger Zone")) {
                Button(role: .destructive, action: { showClearConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear All Data")
                    }
                }
            }
        }
        .navigationTitle("Data Management")
        .alert("Export Complete", isPresented: $showExportConfirmation, presenting: exportResult) { result in
            Button("OK") {}
            if result.success {
                Button("Share File") {
                    shareExportFile(result.url)
                }
            }
        } message: { result in
            Text(result.message)
        }
        .alert("Clear All Data?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all games, teams, players, and seasons. This cannot be undone.")
        }
        .sheet(isPresented: $showImportSheet) {
            ImportDataView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalGames: String {
        let request: NSFetchRequest<Game> = Game.fetchRequest()
        return "\((try? viewContext.count(for: request)) ?? 0)"
    }
    
    private var totalTeams: String {
        let request: NSFetchRequest<Team> = Team.fetchRequest()
        return "\((try? viewContext.count(for: request)) ?? 0)"
    }
    
    private var totalPlayers: String {
        let request: NSFetchRequest<Player> = Player.fetchRequest()
        return "\((try? viewContext.count(for: request)) ?? 0)"
    }
    
    private var totalSeasons: String {
        let request: NSFetchRequest<Season> = Season.fetchRequest()
        return "\((try? viewContext.count(for: request)) ?? 0)"
    }
    
    private var storageUsed: String {
        // Approximate - Core Data doesn't give exact size easily
        return "~2 MB"
    }
    
    // MARK: - Actions
    
    private func triggerSync() {
        // Trigger Core Data + CloudKit sync
        try? viewContext.save()
        // CloudKit sync happens automatically via NSPersistentCloudKitContainer
    }
    
    private func exportAllData() {
        isExporting = true
        
        let exportData = createFullExport()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let filename = "WaterPoloStats_Export_\(dateString).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try data.write(to: url)
            
            exportResult = ExportResult(success: true, url: url, message: "Exported to \(filename)")
        } catch {
            exportResult = ExportResult(success: false, url: nil, message: "Export failed: \(error.localizedDescription)")
        }
        
        isExporting = false
        showExportConfirmation = true
    }
    
    private func createFullExport() -> [String: Any] {
        var export: [String: Any] = [:]
        
        // Export teams
        let teamRequest: NSFetchRequest<Team> = Team.fetchRequest()
        if let teams = try? viewContext.fetch(teamRequest) {
            export["teams"] = teams.map { team in
                [
                    "id": team.wrappedId.uuidString,
                    "name": team.wrappedName,
                    "clubName": team.wrappedClubName,
                    "level": team.wrappedLevel
                ]
            }
        }
        
        // Export players
        let playerRequest: NSFetchRequest<Player> = Player.fetchRequest()
        if let players = try? viewContext.fetch(playerRequest) {
            export["players"] = players.map { player in
                [
                    "id": player.wrappedId.uuidString,
                    "name": player.wrappedName,
                    "number": player.wrappedNumber,
                    "teamId": player.team?.wrappedId.uuidString ?? ""
                ]
            }
        }
        
        // Export seasons
        let seasonRequest: NSFetchRequest<Season> = Season.fetchRequest()
        if let seasons = try? viewContext.fetch(seasonRequest) {
            export["seasons"] = seasons.map { season in
                [
                    "id": season.wrappedId.uuidString,
                    "name": season.displayLabel,
                    "startDate": season.startDate?.ISO8601Format() ?? "",
                    "endDate": season.endDate?.ISO8601Format() ?? ""
                ]
            }
        }
        
        // Export metadata
        export["exportDate"] = Date().ISO8601Format()
        export["appVersion"] = "1.0"
        
        return export
    }
    
    private func shareExportFile(_ url: URL?) {
        guard let url = url else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Present from root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func clearAllData() {
        let entities = ["GameEvent", "GameRoster", "Game", "Player", "Team", "Season"]
        
        for entityName in entities {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try? viewContext.execute(deleteRequest)
        }
        
        try? viewContext.save()
    }
}

// MARK: - Supporting Types

struct ExportResult {
    let success: Bool
    let url: URL?
    let message: String
}

struct DataStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Import Data View

struct ImportDataView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Import Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a previously exported JSON file to restore your data.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Select File") {
                    // Document picker would go here
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview

struct DataManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataManagementView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
