import SwiftUI
import CoreData

struct GameListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.date, ascending: false)],
        animation: .default)
    private var games: FetchedResults<Game>
    
    @State private var showingAddGame = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(games) { game in
                    NavigationLink(destination: SavedGameDetailView(game: game)) {
                        GameRow(game: game)
                    }
                }
                .onDelete(perform: deleteGames)
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGame = true }) {
                        Label("New Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGame) {
                NewGameSetupView()
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }

    private func deleteGames(offsets: IndexSet) {
        withAnimation {
            offsets.map { games[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                errorMessage = "Failed to delete game: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Error Alert Extension

struct GameRow: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Score row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.homeTeamName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(game.awayTeamName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(homeScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(awayScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            // Info row
            HStack {
                if let date = game.date {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
                
                Spacer()
                
                // Status badge
                StatusBadge(status: game.gameStatus)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if !game.wrappedLocation.isEmpty {
                Label(game.wrappedLocation, systemImage: "mappin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var homeScore: Int {
        game.eventsArray.filter { $0.wrappedEventType == "goal" && isHomePlayer($0.player) }.count
    }
    
    private var awayScore: Int {
        game.eventsArray.filter { $0.wrappedEventType == "goal" && !isHomePlayer($0.player) }.count
    }
    
    private func isHomePlayer(_ player: Player?) -> Bool {
        guard let player = player else { return false }
        return game.rostersArray.first { $0.player?.id == player.id }?.isHomeTeam ?? false
    }
}

struct StatusBadge: View {
    let status: GameStatus
    
    var body: some View {
        Text(status == .completed ? "Final" : "In Progress")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status == .completed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundColor(status == .completed ? .green : .orange)
            .cornerRadius(4)
    }
}

struct GameDetailView: View {
    let game: Game
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Game Details")
                .font(.title)
            
            List {
                Section(header: Text("Teams")) {
                    HStack {
                        Text("Home")
                        Spacer()
                        Text(game.homeTeamName)
                    }
                    HStack {
                        Text("Away")
                        Spacer()
                        Text(game.awayTeamName)
                    }
                }
                
                if let date = game.date {
                    Section(header: Text("Date")) {
                        Text(date, style: .date)
                    }
                }
                
                if let location = game.location, !location.isEmpty {
                    Section(header: Text("Location")) {
                        Text(location)
                    }
                }
            }
        }
    }
}

struct AddGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var homeTeamName = ""
    @State private var awayTeamName = ""
    @State private var location = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Names")) {
                    TextField("Home Team", text: $homeTeamName)
                    TextField("Away Team", text: $awayTeamName)
                }
                
                Section(header: Text("Game Details")) {
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Add Game")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newGame = Game(context: viewContext)
                    newGame.id = UUID()
                    newGame.date = Date()
                    newGame.location = location
                    
                    let homeTeam = Team(context: viewContext)
                    homeTeam.id = UUID()
                    homeTeam.name = homeTeamName.isEmpty ? "Home Team" : homeTeamName
                    
                    let awayTeam = Team(context: viewContext)
                    awayTeam.id = UUID()
                    awayTeam.name = awayTeamName.isEmpty ? "Away Team" : awayTeamName
                    
                    newGame.homeTeam = homeTeam
                    newGame.awayTeam = awayTeam
                    
                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        errorMessage = "Failed to save game: \(error.localizedDescription)"
                        showError = true
                    }
                }
            )
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }
}

#Preview {
    GameListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
