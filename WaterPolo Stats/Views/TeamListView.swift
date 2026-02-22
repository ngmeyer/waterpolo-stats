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
                        TeamListRow(team: team)
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

struct TeamListRow: View {
    let team: Team
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.3.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(team.wrappedName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(team.playersArray.count)", systemImage: "person.fill")
                        .font(.caption)
                    
                    Label("\(team.allGames.count)", systemImage: "sportscourt.fill")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
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
