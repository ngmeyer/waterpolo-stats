import SwiftUI
import CoreData
import CoreLocation
import Combine

// MARK: - Location Manager

@MainActor
final class LocationFetcher: NSObject, ObservableObject {
    @Published var isFetching = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    var onResult: ((String, String) -> Void)?  // (venueName, address)

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isFetching = true
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            isFetching = false
            errorMessage = "Location access denied. Enable in Settings."
        }
    }
}

extension LocationFetcher: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isFetching = false
                if let p = placemarks?.first {
                    let street = [p.subThoroughfare, p.thoroughfare]
                        .compactMap { $0 }.joined(separator: " ")
                    let city    = p.locality ?? ""
                    let state   = p.administrativeArea ?? ""
                    let zip     = p.postalCode ?? ""
                    let address = [street, city, state, zip]
                        .filter { !$0.isEmpty }.joined(separator: ", ")
                    let venue = p.name ?? p.locality ?? ""
                    self.onResult?(venue, address)
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.isFetching = false
            self?.errorMessage = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            } else if status == .denied || status == .restricted {
                self.isFetching = false
                self.errorMessage = "Location access denied. Enable in Settings."
            }
        }
    }
}

// MARK: - New Game Setup View

struct NewGameSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var gameViewModel: GameViewModel

    // Teams
    @State private var homeTeam: Team?
    @State private var awayTeam: Team?
    @State private var showHomePicker = false
    @State private var showAwayPicker = false

    // Game details
    @State private var gameDate = Date()
    @State private var gameType: GameSession.GameType = .league
    @State private var tournamentRound = ""

    // Location
    @State private var venueName = ""
    @State private var venueAddress = ""
    @StateObject private var locationFetcher = LocationFetcher()

    private var canStart: Bool { homeTeam != nil && awayTeam != nil }

    var body: some View {
        NavigationStack {
            Form {
                teamsSection
                gameDetailsSection
                if gameType == .tournament {
                    tournamentSection
                }
                locationSection
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Game") { startGame() }
                        .disabled(!canStart)
                }
            }
            .sheet(isPresented: $showHomePicker) {
                TeamPickerSheet(
                    title: "Home Team",
                    excludeId: awayTeam?.id,
                    selected: $homeTeam
                )
            }
            .sheet(isPresented: $showAwayPicker) {
                TeamPickerSheet(
                    title: "Away Team",
                    excludeId: homeTeam?.id,
                    selected: $awayTeam
                )
            }
            .onAppear {
                locationFetcher.onResult = { venue, address in
                    if venueName.isEmpty { venueName = venue }
                    if venueAddress.isEmpty { venueAddress = address }
                }
            }
        }
    }

    // MARK: - Sections

    private var teamsSection: some View {
        Section("Teams") {
            TeamPickerRow(label: "Home", accentColor: .blue, team: homeTeam) {
                showHomePicker = true
            }
            TeamPickerRow(label: "Away", accentColor: .orange, team: awayTeam) {
                showAwayPicker = true
            }
        }
    }

    private var gameDetailsSection: some View {
        Section("Game Details") {
            DatePicker("Date & Time", selection: $gameDate,
                       displayedComponents: [.date, .hourAndMinute])

            Picker("Type", selection: $gameType) {
                ForEach(GameSession.GameType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
        }
    }

    private var tournamentSection: some View {
        Section {
            TextField("Round / Description", text: $tournamentRound)
        } header: {
            Text("Tournament")
        } footer: {
            Text("e.g. Round Robin, Day 2, Semi-Finals, Championship")
        }
    }

    private var locationSection: some View {
        Section("Location") {
            TextField("Venue Name", text: $venueName)
                .autocorrectionDisabled()
            TextField("Address", text: $venueAddress)
                .autocorrectionDisabled()

            if locationFetcher.isFetching {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Getting location…")
                        .foregroundColor(.secondary)
                }
            } else {
                Button {
                    locationFetcher.requestLocation()
                } label: {
                    Label("Use Current Location", systemImage: "location.fill")
                }
            }

            if let err = locationFetcher.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    private func startGame() {
        guard let home = homeTeam, let away = awayTeam else { return }
        let session = GameSession(
            homeTeam: buildGameTeam(from: home, isHome: true),
            awayTeam: buildGameTeam(from: away, isHome: false),
            gameType: gameType,
            location: venueName,
            venueAddress: venueAddress,
            tournamentRound: tournamentRound,
            scheduledDate: gameDate
        )
        gameViewModel.loadGame(session)
        dismiss()
    }

    private func buildGameTeam(from team: Team, isHome: Bool) -> GameTeam {
        let players: [GamePlayer] = team.playersArray.compactMap { player in
            guard let cap = Int(player.wrappedNumber), cap > 0 else { return nil }
            return GamePlayer(number: cap, name: player.wrappedName,
                              isInGame: true, isGoalie: cap == 1)
        }
        let finalPlayers = players.isEmpty
            ? (1...7).map { n in GamePlayer(number: n, name: "Player \(n)",
                                            isInGame: true, isGoalie: n == 1) }
            : players
        return GameTeam(id: team.wrappedId, name: team.displayName,
                        players: finalPlayers, isHomeTeam: isHome)
    }
}

// MARK: - Team Picker Row

struct TeamPickerRow: View {
    let label: String
    let accentColor: Color
    let team: Team?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
                if let team {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(team.displayName)
                            .foregroundColor(accentColor)
                            .fontWeight(.medium)
                        if !team.wrappedLevel.isEmpty {
                            Text(team.wrappedLevel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Select…")
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Team Picker Sheet

struct TeamPickerSheet: View {
    let title: String
    let excludeId: UUID?
    @Binding var selected: Team?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var search = ""
    @State private var showCreateTeam = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Team.name, ascending: true)],
        animation: .default)
    private var allTeams: FetchedResults<Team>

    private var filtered: [Team] {
        let base = allTeams.filter { $0.id != excludeId }
        guard !search.isEmpty else { return base }
        return base.filter {
            $0.displayName.localizedCaseInsensitiveContains(search) ||
            $0.wrappedLevel.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Create new team at the top
                Button {
                    showCreateTeam = true
                } label: {
                    Label("Create New Team", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }

                if filtered.isEmpty && !search.isEmpty {
                    Text("No teams match \"\(search)\"")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(filtered) { team in
                        Button {
                            selected = team
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.displayName)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    if !team.wrappedLevel.isEmpty {
                                        Text(team.wrappedLevel)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if selected?.id == team.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search teams")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateTeam) {
                QuickTeamCreateSheet { newTeam in
                    selected = newTeam
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Quick Team Create Sheet

struct QuickTeamCreateSheet: View {
    let onCreated: (Team) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var orgName = ""
    @State private var teamSuffix = ""
    @State private var category: NewTeamCategory = .club
    @State private var ageGroup: ClubAgeGroup = .u16
    @State private var clubGender: ClubGender = .boys
    @State private var hsLevel: HSLevel = .varsity
    @State private var hsGender: HSGender = .boys
    @State private var collegeGender: CollegeGender = .men
    @State private var selectedNumbers: Set<Int> = []

    private var levelString: String {
        switch category {
        case .club:       return "\(ageGroup.rawValue) \(clubGender.rawValue)"
        case .highSchool: return "\(hsLevel.rawValue) \(hsGender.rawValue)"
        case .college:    return collegeGender.rawValue
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team") {
                    TextField("Club / School Name", text: $orgName)
                    TextField("Team Name (optional)", text: $teamSuffix)
                }

                Section("Level") {
                    Picker("Type", selection: $category) {
                        ForEach(NewTeamCategory.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)

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

                Section {
                    CapNumberGrid(selected: $selectedNumbers)
                } header: {
                    HStack {
                        Text("Roster")
                        Spacer()
                        if !selectedNumbers.isEmpty {
                            Text("\(selectedNumbers.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    Text("Tap numbers to add players. Names can be added later.")
                }
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createTeam() }
                        .disabled(orgName.isEmpty)
                }
            }
        }
    }

    private func createTeam() {
        let team = Team(context: viewContext)
        team.id = UUID()
        team.clubName = orgName
        team.name = teamSuffix.isEmpty ? nil : teamSuffix
        team.level = levelString
        team.isActive = true
        team.createdAt = Date()

        for num in selectedNumbers.sorted() {
            let player = Player(context: viewContext)
            player.id = UUID()
            player.number = "\(num)"
            player.name = ""   // blank — user can fill in names from Team detail
            player.createdAt = Date()
            player.team = team
        }

        try? viewContext.save()
        onCreated(team)
        dismiss()
    }
}

// MARK: - Cap Number Grid

struct CapNumberGrid: View {
    @Binding var selected: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...40, id: \.self) { num in
                let isOn = selected.contains(num)
                Text("\(num)")
                    .font(.system(.footnote, design: .rounded).bold())
                    .frame(width: 34, height: 34)
                    .foregroundColor(isOn ? .white : .primary)
                    .background(Circle().fill(isOn ? Color.blue : Color(.systemGray5)))
                    .onTapGesture {
                        if isOn { selected.remove(num) } else { selected.insert(num) }
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NewGameSetupView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(GameViewModel())
}
