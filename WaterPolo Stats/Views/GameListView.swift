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
                    NavigationLink(destination: GameDetailView(game: game)) {
                        GameRow(game: game)
                    }
                }
                .onDelete(perform: deleteGames)
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGame = true }) {
                        Label("Add Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGame) {
                AddGameView()
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
        VStack(alignment: .leading) {
            HStack {
                Text(game.homeTeamName)
                    .font(.headline)
                Spacer()
                Text("vs")
                    .foregroundColor(.secondary)
                Spacer()
                Text(game.awayTeamName)
                    .font(.headline)
            }
            
            if let date = game.date {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let location = game.location, !location.isEmpty {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
