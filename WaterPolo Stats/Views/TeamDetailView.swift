import SwiftUI
import CoreData
import PhotosUI

// MARK: - Team Detail View
// Full player and roster management for a team

struct TeamDetailView: View {
    @ObservedObject var team: Team
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showAddPlayer = false
    @State private var showEditPlayer: Player?
    @State private var showEditTeam = false
    @State private var searchText = ""
    @State private var selectedFilter = 0
    @State private var sortOrder = 0 // 0 = number, 1 = name, 2 = goals
    
    var body: some View {
        List {
            // Team header
            TeamHeaderSection(team: team)
            
            // Filter/Sort controls
            FilterSortSection(
                selectedFilter: $selectedFilter,
                sortOrder: $sortOrder,
                searchText: $searchText
            )
            
            // Player roster
            Section(header: Text("Roster (\(filteredPlayers.count) players)")) {
                ForEach(filteredPlayers) { player in
                    NavigationLink(destination: PlayerCareerStatsView(player: player)) {
                        PlayerListRow(player: player)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            showEditPlayer = player
                        }
                        .tint(.blue)
                        
                        Button("Delete", role: .destructive) {
                            deletePlayer(player)
                        }
                    }
                }
            }
            
            // Quick stats
            Section(header: Text("Season Stats")) {
                StatSummaryRow(label: "Total Players", value: "\(team.playersArray.count)")
                StatSummaryRow(label: "Goals (All Games)", value: "\(totalGoals)")
                StatSummaryRow(label: "Assists (All Games)", value: "\(totalAssists)")
                StatSummaryRow(label: "Steals (All Games)", value: "\(totalSteals)")
                StatSummaryRow(label: "Exclusions (All Games)", value: "\(totalExclusions)")
            }
            
            // Recent games
            if !team.allGames.isEmpty {
                Section(header: Text("Recent Games (\(team.allGames.count))")) {
                    ForEach(team.allGames.prefix(5)) { game in
                        NavigationLink(destination: SavedGameDetailView(game: game)) {
                            GameHistoryRow(game: game, teamName: team.wrappedName)
                        }
                    }
                }
            }
        }
        .navigationTitle(team.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showEditTeam = true }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: { showAddPlayer = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(team: team)
        }
        .sheet(item: $showEditPlayer) { player in
            EditPlayerSheet(player: player)
        }
        .sheet(isPresented: $showEditTeam) {
            EditTeamSheet(team: team)
        }
    }
    
    private var filteredPlayers: [Player] {
        var players = team.playersArray
        
        // Filter by search
        if !searchText.isEmpty {
            players = players.filter { 
                $0.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                $0.wrappedNumber.contains(searchText)
            }
        }
        
        // Sort
        switch sortOrder {
        case 0: // By number
            players.sort { ($0.currentCapNumber ?? 0) < ($1.currentCapNumber ?? 0) }
        case 1: // By name
            players.sort { $0.wrappedName < $1.wrappedName }
        case 2: // By goals
            players.sort { $0.goals > $1.goals }
        default:
            break
        }
        
        return players
    }
    
    private var totalGoals: Int { team.playersArray.reduce(0) { $0 + $1.goals } }
    private var totalAssists: Int { team.playersArray.reduce(0) { $0 + $1.assists } }
    private var totalSteals: Int { team.playersArray.reduce(0) { $0 + $1.steals } }
    private var totalExclusions: Int { team.playersArray.reduce(0) { $0 + $1.exclusions } }
    
    private func deletePlayer(_ player: Player) {
        withAnimation {
            viewContext.delete(player)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting player: \(error)")
            }
        }
    }
}

// MARK: - Team Header Section

struct TeamHeaderSection: View {
    let team: Team

    @State private var avatarImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?

    private var iconColor: Color { .teamColor(named: team.teamColor) }
    private var iconLetter: String { String(team.displayName.prefix(1)).uppercased() }

    var body: some View {
        VStack(spacing: 12) {
            // Avatar circle — tap to pick a photo
            ZStack(alignment: .bottomTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    avatarCircle
                }
                .buttonStyle(.plain)

                // Camera badge overlay
                Image(systemName: "camera.fill")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(5)
                    .background(iconColor)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
            .contextMenu {
                if avatarImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        avatarImage = nil
                        TeamAvatarStore.shared.delete(for: team.wrappedId)
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        let square = cropToSquare(uiImage)
                        avatarImage = square
                        TeamAvatarStore.shared.save(square, for: team.wrappedId)
                    }
                }
            }

            // Display name ("680 Red") + level pill
            VStack(spacing: 6) {
                Text(team.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                if !team.wrappedLevel.isEmpty {
                    Text(team.wrappedLevel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(iconColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                        .background(iconColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // Stats chips
            HStack(spacing: 12) {
                StatChip(value: "\(team.playersArray.count)", label: "Players")
                StatChip(value: "\(team.allGames.count)", label: "Games")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .listRowBackground(Color.clear)
        .onAppear {
            avatarImage = TeamAvatarStore.shared.load(for: team.wrappedId)
        }
    }

    @ViewBuilder
    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 80, height: 80)
            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Text(iconLetter)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(iconColor)
            }
        }
    }

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - side) / 2,
            y: (image.size.height - side) / 2
        )
        guard let cgImage = image.cgImage?.cropping(
            to: CGRect(origin: origin, size: CGSize(width: side, height: side))
        ) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct StatChip: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Filter Sort Section

struct FilterSortSection: View {
    @Binding var selectedFilter: Int
    @Binding var sortOrder: Int
    @Binding var searchText: String
    
    var body: some View {
        Section {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search players...", text: $searchText)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Sort picker
            Picker("Sort by", selection: $sortOrder) {
                Text("Number").tag(0)
                Text("Name").tag(1)
                Text("Goals").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Player List Row

struct PlayerListRow: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            // Jersey number
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(player.currentCapNumber.map { "#\($0)" } ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Player info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.wrappedName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let dob = player.dateOfBirth {
                        Text(dob, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let nscaId = player.nscaId, !nscaId.isEmpty {
                        Text("ID: \(nscaId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.goals)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text("Goals")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.assists)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    Text("Assists")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.secondary)
            
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Summary Row

struct StatSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Game History Row

struct GameHistoryRow: View {
    let game: Game
    let teamName: String
    
    private var teamScore: Int {
        let isHome = game.homeTeamName == teamName
        let events = game.eventsArray.filter { event in
            guard let player = event.player,
                  let roster = game.rostersArray.first(where: { $0.player?.id == player.id }) else { return false }
            return roster.isHomeTeam == isHome && event.wrappedEventType == "goal"
        }
        return events.count
    }
    
    private var opponentScore: Int {
        let isHome = game.homeTeamName == teamName
        let events = game.eventsArray.filter { event in
            guard let player = event.player,
                  let roster = game.rostersArray.first(where: { $0.player?.id == player.id }) else { return false }
            return roster.isHomeTeam != isHome && event.wrappedEventType == "goal"
        }
        return events.count
    }
    
    private var opponentName: String {
        game.homeTeamName == teamName ? game.awayTeamName : game.homeTeamName
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(opponentName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let date = game.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(teamScore) - \(opponentScore)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                
                // Win/Loss indicator
                let result = teamScore > opponentScore ? "W" : (teamScore < opponentScore ? "L" : "T")
                Text(result)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(teamScore > opponentScore ? .green : (teamScore < opponentScore ? .red : .gray))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Player Sheet

struct AddPlayerSheet: View {
    let team: Team
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var number = ""
    @State private var dateOfBirth: Date?
    @State private var showDatePicker = false
    @State private var nscaId = ""
    @State private var savedCount = 0

    private var canSave: Bool { !name.isEmpty && !number.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Player Info")) {
                    TextField("Full Name", text: $name)

                    TextField("Cap Number", text: $number)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Additional Info")) {
                    Toggle("Add Date of Birth", isOn: $showDatePicker)

                    if showDatePicker {
                        DatePicker("Birth Date", selection: Binding(
                            get: { dateOfBirth ?? Date() },
                            set: { dateOfBirth = $0 }
                        ), displayedComponents: .date)
                    }

                    TextField("NCSA ID (optional)", text: $nscaId)
                }

                Section {
                    Button {
                        saveAndAddAnother()
                    } label: {
                        Label("Save & Add Another", systemImage: "person.badge.plus")
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle(savedCount == 0 ? "Add Player" : "Add Player (\(savedCount) saved)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlayer()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveAndAddAnother() {
        savePlayer()
        name = ""
        number = ""
        dateOfBirth = nil
        showDatePicker = false
        nscaId = ""
    }

    @discardableResult
    private func savePlayer() -> Bool {
        let player = Player(context: viewContext)
        player.id = UUID()
        player.name = name
        player.number = number
        player.dateOfBirth = dateOfBirth
        player.nscaId = nscaId.isEmpty ? nil : nscaId
        player.createdAt = Date()
        player.team = team

        do {
            try viewContext.save()
            savedCount += 1
            return true
        } catch {
            print("Error saving player: \(error)")
            return false
        }
    }
}

// MARK: - Edit Player Sheet

struct EditPlayerSheet: View {
    let player: Player
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String
    @State private var number: String
    @State private var dateOfBirth: Date?
    @State private var nscaId: String
    
    init(player: Player) {
        self.player = player
        _name = State(initialValue: player.wrappedName)
        _number = State(initialValue: player.wrappedNumber)
        _dateOfBirth = State(initialValue: player.dateOfBirth)
        _nscaId = State(initialValue: player.nscaId ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Player Info")) {
                    TextField("Full Name", text: $name)

                    TextField("Cap Number", text: $number)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Additional Info")) {
                    DatePicker("Birth Date", selection: Binding(
                        get: { dateOfBirth ?? Date() },
                        set: { dateOfBirth = $0 }
                    ), displayedComponents: .date)

                    TextField("NCSA ID", text: $nscaId)
                }

                Section {
                    Button("Delete Player", role: .destructive) {
                        deletePlayer()
                    }
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlayer()
                    }
                    .disabled(name.isEmpty || number.isEmpty)
                }
            }
        }
    }

    private func savePlayer() {
        player.name = name
        player.number = number
        player.dateOfBirth = dateOfBirth
        player.nscaId = nscaId.isEmpty ? nil : nscaId
        player.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving player: \(error)")
        }
    }

    private func deletePlayer() {
        viewContext.delete(player)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting player: \(error)")
        }
    }
}

// MARK: - Edit Team Sheet

struct EditTeamSheet: View {
    let team: Team
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var orgName: String
    @State private var teamSuffix: String
    @State private var category: NewTeamCategory
    @State private var ageGroup: ClubAgeGroup
    @State private var clubGender: ClubGender
    @State private var hsLevel: HSLevel
    @State private var hsGender: HSGender
    @State private var collegeGender: CollegeGender
    @State private var selectedColor: String
    @State private var showDeleteConfirm = false

    init(team: Team) {
        self.team = team
        let level = team.wrappedLevel
        let cat = Self.inferCategory(level)
        _orgName       = State(initialValue: team.wrappedClubName)
        _teamSuffix    = State(initialValue: team.name ?? "")
        _category      = State(initialValue: cat)
        _ageGroup      = State(initialValue: Self.inferAgeGroup(level))
        _clubGender    = State(initialValue: Self.inferClubGender(level))
        _hsLevel       = State(initialValue: Self.inferHSLevel(level))
        _hsGender      = State(initialValue: Self.inferHSGender(level))
        _collegeGender = State(initialValue: Self.inferCollegeGender(level))
        _selectedColor = State(initialValue: team.teamColor ?? "blue")
    }

    private var levelString: String {
        switch category {
        case .club:       return "\(ageGroup.rawValue) \(clubGender.rawValue)"
        case .highSchool: return "\(hsLevel.rawValue) \(hsGender.rawValue)"
        case .college:    return collegeGender.rawValue
        }
    }

    private var orgFieldLabel: String {
        category == .club ? "Club Name" : "School Name"
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
                Section(header: Text("Team Info")) {
                    TextField(orgFieldLabel, text: $orgName)
                    TextField(suffixFieldPlaceholder, text: $teamSuffix)
                }

                Section(header: Text("Competition Level")) {
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

                Section(header: Text("Team Color")) {
                    TeamColorPicker(selected: $selectedColor)
                }

                Section {
                    Button("Delete Team", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Team")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTeam() }.disabled(orgName.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete \"\(team.displayName)\"?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Team", role: .destructive) { deleteTeam() }
            } message: {
                Text("Players on this team will also be removed. Game history will remain.")
            }
        }
    }

    private func saveTeam() {
        team.clubName  = orgName
        team.name      = teamSuffix.isEmpty ? nil : teamSuffix
        team.level     = levelString
        team.teamColor = selectedColor
        try? viewContext.save()
        dismiss()
    }

    private func deleteTeam() {
        viewContext.delete(team)
        try? viewContext.save()
        dismiss()
    }

    // MARK: Level string inference (parses stored level back into picker values)

    private static func inferCategory(_ level: String) -> NewTeamCategory {
        if ClubAgeGroup.allCases.contains(where: { level.hasPrefix($0.rawValue) }) { return .club }
        if HSLevel.allCases.contains(where: { level.hasPrefix($0.rawValue) }) { return .highSchool }
        return .college
    }
    private static func inferAgeGroup(_ l: String) -> ClubAgeGroup {
        ClubAgeGroup.allCases.first { l.hasPrefix($0.rawValue) } ?? .u16
    }
    private static func inferClubGender(_ l: String) -> ClubGender {
        ClubGender.allCases.first { l.hasSuffix($0.rawValue) } ?? .boys
    }
    private static func inferHSLevel(_ l: String) -> HSLevel {
        HSLevel.allCases.first { l.hasPrefix($0.rawValue) } ?? .varsity
    }
    private static func inferHSGender(_ l: String) -> HSGender {
        HSGender.allCases.first { l.hasSuffix($0.rawValue) } ?? .boys
    }
    private static func inferCollegeGender(_ l: String) -> CollegeGender {
        CollegeGender.allCases.first { l == $0.rawValue } ?? .men
    }
}

// MARK: - Team Color Picker

struct TeamColorPicker: View {
    @Binding var selected: String

    private let palette: [(String, Color)] = [
        ("blue", .blue), ("red", .red), ("green", .green),
        ("orange", .orange), ("purple", .purple), ("teal", .teal),
        ("pink", .pink), ("indigo", .indigo), ("yellow", .yellow),
        ("gray", .gray)
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
            ForEach(palette, id: \.0) { name, color in
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.3), lineWidth: selected == name ? 3 : 0)
                                .padding(-2)
                        )
                    if selected == name {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture { selected = name }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

struct TeamDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let team = Team(context: context)
        team.id = UUID()
        team.name = "Sample Team"
        team.clubName = "680 Club"
        team.level = "16U Boys"
        
        return NavigationStack {
            TeamDetailView(team: team)
        }
        .environment(\.managedObjectContext, context)
    }
}
