import SwiftUI
import CoreData

// MARK: - New Game Flow
// Select teams from history or create new, then start game

struct NewGameSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var gameViewModel: GameViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.name, ascending: true)],
        animation: .default)
    private var teams: FetchedResults<Team>
    
    @State private var step = 0
    @State private var homeTeam: Team?
    @State private var awayTeam: Team?
    @State private var newTeamName = ""
    @State private var newTeamType = TeamType.club
    @State private var showCreateTeam = false
    @State private var selectingForHome = true
    
    enum TeamType: String, CaseIterable {
        case club = "Club"
        case highSchool = "High School"
        case college = "College"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress
                ProgressView(value: Double(step + 1), total: 3)
                    .padding()
                
                if step == 0 {
                    TeamSelectionStep(
                        title: "Select Home Team",
                        teams: Array(teams),
                        selectedTeam: $homeTeam,
                        onSelect: {
                            if awayTeam == nil {
                                step = 1
                            } else {
                                step = 2
                            }
                        },
                        onCreateNew: {
                            selectingForHome = true
                            showCreateTeam = true
                        }
                    )
                } else if step == 1 {
                    TeamSelectionStep(
                        title: "Select Away Team",
                        teams: Array(teams).filter { $0.id != homeTeam?.id },
                        selectedTeam: $awayTeam,
                        onSelect: {
                            step = 2
                        },
                        onCreateNew: {
                            selectingForHome = false
                            showCreateTeam = true
                        }
                    )
                } else {
                    GameReadyStep(
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        onStart: startGame,
                        onBack: { step = 0 }
                    )
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                CreateTeamSheet(
                    teamName: $newTeamName,
                    teamType: $newTeamType,
                    onSave: createTeam,
                    onCancel: { showCreateTeam = false }
                )
            }
        }
    }
    
    private func createTeam() {
        let team = Team(context: viewContext)
        team.id = UUID()
        team.name = newTeamName
        team.level = newTeamType.rawValue
        team.createdAt = Date()
        team.isActive = true
        
        try? viewContext.save()
        
        if selectingForHome {
            homeTeam = team
            if awayTeam == nil {
                step = 1
            } else {
                step = 2
            }
        } else {
            awayTeam = team
            step = 2
        }
        
        newTeamName = ""
        showCreateTeam = false
    }
    
    private func startGame() {
        guard let home = homeTeam, let away = awayTeam else { return }
        let session = GameSession(
            homeTeam: buildGameTeam(from: home, isHome: true),
            awayTeam: buildGameTeam(from: away, isHome: false)
        )
        gameViewModel.loadGame(session)
        presentationMode.wrappedValue.dismiss()
    }

    /// Converts a Core Data Team into an in-memory GameTeam with its roster.
    /// Falls back to numbered placeholders (1–7) if the team has no saved players.
    private func buildGameTeam(from team: Team, isHome: Bool) -> GameTeam {
        let players: [GamePlayer] = team.playersArray.compactMap { player in
            guard let capNum = Int(player.wrappedNumber), capNum > 0 else { return nil }
            return GamePlayer(
                number: capNum,
                name: player.wrappedName,
                isInGame: true,
                isGoalie: capNum == 1
            )
        }
        let finalPlayers = players.isEmpty
            ? (1...7).map { n in GamePlayer(number: n, name: "Player \(n)", isInGame: true, isGoalie: n == 1) }
            : players
        return GameTeam(id: team.wrappedId, name: team.wrappedName, players: finalPlayers, isHomeTeam: isHome)
    }
}

// MARK: - Team Selection Step

struct TeamSelectionStep: View {
    let title: String
    let teams: [Team]
    @Binding var selectedTeam: Team?
    let onSelect: () -> Void
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .padding()
            
            if teams.isEmpty {
                VStack(spacing: 16) {
                    Text("No teams yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Create New Team", action: onCreateNew)
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    Section {
                        Button(action: onCreateNew) {
                            Label("Create New Team", systemImage: "plus.circle")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Section(header: Text("Your Teams")) {
                        ForEach(teams) { team in
                            Button(action: {
                                selectedTeam = team
                                onSelect()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(team.wrappedName)
                                            .font(.headline)
                                        if !team.wrappedLevel.isEmpty {
                                            Text(team.wrappedLevel)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedTeam?.id == team.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Create Team Sheet

struct CreateTeamSheet: View {
    @Binding var teamName: String
    @Binding var teamType: NewGameSetupView.TeamType
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Name")) {
                    TextField("e.g., Clayton Valley", text: $teamName)
                }
                
                Section(header: Text("Team Type")) {
                    Picker("Type", selection: $teamType) {
                        ForEach(NewGameSetupView.TeamType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Team")
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel),
                trailing: Button("Save") {
                    onSave()
                }
                .disabled(teamName.isEmpty)
            )
        }
    }
}

// MARK: - Game Ready Step

struct GameReadyStep: View {
    let homeTeam: Team?
    let awayTeam: Team?
    let onStart: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Game Ready")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TeamBadge(name: homeTeam?.wrappedName ?? "Home", color: .blue)
                Text("VS")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                TeamBadge(name: awayTeam?.wrappedName ?? "Away", color: .orange)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onStart) {
                    Label("Start Game", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button("Change Teams", action: onBack)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct TeamBadge: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

// MARK: - Preview

struct NewGameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NewGameSetupView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
