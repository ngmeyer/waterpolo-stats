import SwiftUI
import CoreData

struct TeamListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.name, ascending: true)],
        animation: .default)
    private var teams: FetchedResults<Team>

    @State private var showingAddTeam = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            List {
                ForEach(teams) { team in
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        VStack(alignment: .leading) {
                            Text(team.wrappedName)
                                .font(.headline)
                            Text("\(team.playersArray.count) players")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteTeams)
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTeam = true }) {
                        Label("Add Team", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }

    private func deleteTeams(offsets: IndexSet) {
        withAnimation {
            offsets.map { teams[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                errorMessage = "Failed to delete team: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

struct TeamDetailView: View {
    let team: Team

    var body: some View {
        VStack {
            Text(team.wrappedName)
                .font(.title)

            List {
                Section(header: Text("Players")) {
                    ForEach(team.playersArray) { player in
                        Text(player.wrappedName)
                    }
                }
            }
        }
    }
}

struct AddTeamView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var teamName = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Team Name", text: $teamName)
            }
            .navigationTitle("Add Team")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let newTeam = Team(context: viewContext)
                    newTeam.id = UUID()
                    newTeam.name = teamName

                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        errorMessage = "Failed to save team: \(error.localizedDescription)"
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
    TeamListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
