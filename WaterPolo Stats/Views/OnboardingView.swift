import SwiftUI

// MARK: - Onboarding Flow
// First-launch experience for setting up teams and starting a game

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var homeTeam = GameTeam(name: "Dark Caps", isHomeTeam: true)
    @State private var awayTeam = GameTeam(name: "Light Caps", isHomeTeam: false)
    @State private var gameLocation = ""
    @State private var selectedGameType: GameSession.GameType = .league
    @State private var selectedGameLevel: GameSession.GameLevel = .boysVarsity
    
    let onComplete: (GameSession) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .padding()
                
                // Step content
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    
                    TeamSetupStepView(
                        homeTeam: $homeTeam,
                        awayTeam: $awayTeam
                    )
                    .tag(1)
                    
                    RosterSetupStepView(
                        homeTeam: $homeTeam,
                        awayTeam: $awayTeam
                    )
                    .tag(2)
                    
                    GameDetailsStepView(
                        location: $gameLocation,
                        gameType: $selectedGameType,
                        gameLevel: $selectedGameLevel
                    )
                    .tag(3)
                    
                    ReadyStepView(
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        location: gameLocation
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: nextAction) {
                        HStack {
                            Text(isLastStep ? "Start Game" : "Next")
                            Image(systemName: isLastStep ? "play.fill" : "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canProceed ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(!canProceed)
                    .padding()
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        // Create default game and dismiss
                        let session = GameSession(
                            homeTeam: GameTeam(name: "Dark", isHomeTeam: true),
                            awayTeam: GameTeam(name: "Light", isHomeTeam: false)
                        )
                        onComplete(session)
                    }
                }
            }
        }
    }
    
    private var totalSteps: Int { 5 }
    private var isLastStep: Bool { currentStep == totalSteps - 1 }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !homeTeam.name.isEmpty && !awayTeam.name.isEmpty
        case 2: return !homeTeam.players.isEmpty && !awayTeam.players.isEmpty
        case 3: return true
        case 4: return true
        default: return false
        }
    }
    
    private func nextAction() {
        if isLastStep {
            // Create game session and complete
            let session = GameSession(
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                gameType: selectedGameType,
                gameLevel: selectedGameLevel,
                location: gameLocation
            )
            onComplete(session)
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Water Polo Stats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track games, analyze stats, share with your team")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "sportscourt.fill", text: "Real-time game scoring")
                FeatureRow(icon: "chart.bar.fill", text: "Detailed player statistics")
                FeatureRow(icon: "square.and.arrow.up.fill", text: "Export to MaxPreps & share")
                FeatureRow(icon: "photo.fill", text: "Photo capture with auto-tagging")
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Step 2: Team Setup

struct TeamSetupStepView: View {
    @Binding var homeTeam: GameTeam
    @Binding var awayTeam: GameTeam
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Enter Team Names")
                    .font(.headline)
                    .padding(.top)
                
                // Home Team
                VStack(alignment: .leading, spacing: 8) {
                    Label("Home Team", systemImage: "house.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Team Name", text: $homeTeam.name)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Away Team
                VStack(alignment: .leading, spacing: 8) {
                    Label("Away Team", systemImage: "airplane")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Team Name", text: $awayTeam.name)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Quick presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Presets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        PresetButton(title: "Dark / Light") {
                            homeTeam.name = "Dark Caps"
                            awayTeam.name = "Light Caps"
                        }
                        
                        PresetButton(title: "Blue / White") {
                            homeTeam.name = "Blue Team"
                            awayTeam.name = "White Team"
                        }
                        
                        PresetButton(title: "Red / Black") {
                            homeTeam.name = "Red Team"
                            awayTeam.name = "Black Team"
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

// MARK: - Step 3: Roster Setup

struct RosterSetupStepView: View {
    @Binding var homeTeam: GameTeam
    @Binding var awayTeam: GameTeam
    @State private var editingHomeTeam = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Team selector
            Picker("Team", selection: $editingHomeTeam) {
                Text(homeTeam.name).tag(true)
                Text(awayTeam.name).tag(false)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Roster editor
            if editingHomeTeam {
                RosterEditor(team: $homeTeam)
            } else {
                RosterEditor(team: $awayTeam)
            }
        }
    }
}

struct RosterEditor: View {
    @Binding var team: GameTeam
    @State private var newPlayerNumber = ""
    @State private var newPlayerName = ""
    @State private var isGoalie = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Current roster list
            List {
                Section(header: Text("Roster (\(team.players.count) players)")) {
                    ForEach(team.players) { player in
                        HStack {
                            Text("#\(player.number)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                                .frame(width: 40)
                            
                            Text(player.name)
                            
                            Spacer()
                            
                            if player.isGoalie {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        team.players.remove(atOffsets: indexSet)
                    }
                }
            }
            .listStyle(.plain)
            
            // Add player form
            VStack(spacing: 12) {
                Text("Add Player")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    TextField("#", text: $newPlayerNumber)
                        .keyboardType(.numberPad)
                        .frame(width: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Player Name", text: $newPlayerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle("Goalie", isOn: $isGoalie)
                        .frame(width: 80)
                }
                
                Button(action: addPlayer) {
                    Label("Add to Roster", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canAdd ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!canAdd)
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
    private var canAdd: Bool {
        !newPlayerNumber.isEmpty && !newPlayerName.isEmpty
    }
    
    private func addPlayer() {
        guard let number = Int(newPlayerNumber) else { return }
        
        let player = GamePlayer(
            number: number,
            name: newPlayerName,
            isInGame: true,
            isGoalie: isGoalie
        )
        
        team.players.append(player)
        
        // Reset form
        newPlayerNumber = ""
        newPlayerName = ""
        isGoalie = false
    }
}

// MARK: - Step 4: Game Details

struct GameDetailsStepView: View {
    @Binding var location: String
    @Binding var gameType: GameSession.GameType
    @Binding var gameLevel: GameSession.GameLevel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Game Details")
                    .font(.headline)
                    .padding(.top)
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Label("Location", systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Pool / Venue Name", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Game Type
                VStack(alignment: .leading, spacing: 8) {
                    Label("Game Type", systemImage: "trophy.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Type", selection: $gameType) {
                        ForEach(GameSession.GameType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Game Level
                VStack(alignment: .leading, spacing: 8) {
                    Label("Level", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Level", selection: $gameLevel) {
                        ForEach(GameSession.GameLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Period length info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Period Length")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("\(Int(gameLevel.periodLength / 60)) minutes")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(gameLevel.defaultMaxTimeouts) timeouts per team")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Step 5: Ready

struct ReadyStepView: View {
    let homeTeam: GameTeam
    let awayTeam: GameTeam
    let location: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Checkmark animation
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("You're Ready!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Game summary
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Matchup")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(homeTeam.name) vs \(awayTeam.name)")
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rosters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(homeTeam.players.count) vs \(awayTeam.players.count) players")
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                
                if !location.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(location)
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Text("Tap Start Game when you're ready to begin scoring")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView { session in
            print("Game ready: \(session.homeTeam.name) vs \(session.awayTeam.name)")
        }
    }
}
