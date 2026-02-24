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
        NavigationStack {
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

    private var iconColor: Color { .teamColor(named: team.teamColor) }
    private var iconLetter: String { String(team.displayName.prefix(1)).uppercased() }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(iconLetter)
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(team.displayName)
                    .font(.headline)

                if !team.wrappedLevel.isEmpty {
                    Text(team.wrappedLevel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Label("\(team.playersArray.count)", systemImage: "person.fill")
                    Label("\(team.allGames.count)", systemImage: "sportscourt.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Team classification enums (shared across Teams views)

enum NewTeamCategory: String, CaseIterable {
    case club = "Club"
    case highSchool = "High School"
    case college = "College"
}

enum ClubAgeGroup: String, CaseIterable {
    case u10 = "10U"; case u12 = "12U"; case u14 = "14U"
    case u16 = "16U"; case u18 = "18U"
}

enum ClubGender: String, CaseIterable {
    case boys = "Boys"; case girls = "Girls"; case coed = "CoEd"
}

enum HSLevel: String, CaseIterable {
    case varsity = "Varsity"; case jv = "JV"; case freshman = "Freshman"
}

enum HSGender: String, CaseIterable {
    case boys = "Boys"; case girls = "Girls"
}

enum CollegeGender: String, CaseIterable {
    case men = "Men"; case women = "Women"
}

// MARK: - Add Team View

struct AddTeamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // Club/School name comes first — it's the primary identifier
    @State private var orgName = ""
    // Optional team name / mascot (e.g. "Red", "Bears")
    @State private var teamSuffix = ""

    @State private var category: NewTeamCategory = .club
    @State private var ageGroup: ClubAgeGroup = .u16
    @State private var clubGender: ClubGender = .boys
    @State private var hsLevel: HSLevel = .varsity
    @State private var hsGender: HSGender = .boys
    @State private var collegeGender: CollegeGender = .men

    @State private var savedTeam: Team?
    @State private var navigateToRoster = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var levelString: String {
        switch category {
        case .club:       return "\(ageGroup.rawValue) \(clubGender.rawValue)"
        case .highSchool: return "\(hsLevel.rawValue) \(hsGender.rawValue)"
        case .college:    return collegeGender.rawValue
        }
    }

    /// The name that will appear as the row title: "680 Red", "Clayton Valley", etc.
    private var previewDisplayName: String {
        [orgName, teamSuffix].filter { !$0.isEmpty }.joined(separator: " ")
    }

    // Field labels vary by category
    private var orgFieldLabel: String {
        category == .club ? "Club Name" : "School Name"
    }
    private var orgFieldPlaceholder: String {
        switch category {
        case .club:       return "e.g. 680 Club"
        case .highSchool: return "e.g. Clayton Valley"
        case .college:    return "e.g. UC Berkeley"
        }
    }
    private var suffixFieldPlaceholder: String {
        switch category {
        case .club:       return "e.g. Red, Gold, Blue (optional)"
        case .highSchool: return "e.g. Eagles (optional)"
        case .college:    return "e.g. Bears (optional)"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Team Type")) {
                    Picker("Type", selection: $category) {
                        ForEach(NewTeamCategory.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Team Info")) {
                    // Club/School first
                    TextField(orgFieldPlaceholder, text: $orgName)
                    // Team name / mascot second (always optional)
                    TextField(suffixFieldPlaceholder, text: $teamSuffix)
                }

                Section(header: Text("Level")) {
                    switch category {
                    case .club:
                        Picker("Age Group", selection: $ageGroup) {
                            ForEach(ClubAgeGroup.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Gender", selection: $clubGender) {
                            ForEach(ClubGender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    case .highSchool:
                        Picker("Level", selection: $hsLevel) {
                            ForEach(HSLevel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Gender", selection: $hsGender) {
                            ForEach(HSGender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    case .college:
                        Picker("Gender", selection: $collegeGender) {
                            ForEach(CollegeGender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                    }
                }

                if !orgName.isEmpty {
                    Section(header: Text("Preview")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(previewDisplayName)
                                .font(.headline)
                            Text(levelString)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("New Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Add Roster") {
                        saveTeam()
                    }
                    .disabled(orgName.isEmpty)
                }
            }
            .navigationDestination(isPresented: $navigateToRoster) {
                if let team = savedTeam { TeamDetailView(team: team) }
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }

    private func saveTeam() {
        let newTeam = Team(context: viewContext)
        newTeam.id = UUID()
        newTeam.clubName = orgName
        newTeam.name = teamSuffix.isEmpty ? nil : teamSuffix
        newTeam.level = levelString
        newTeam.isActive = true
        newTeam.createdAt = Date()

        do {
            try viewContext.save()
            savedTeam = newTeam
            navigateToRoster = true
        } catch {
            errorMessage = "Failed to save team: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    TeamListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
