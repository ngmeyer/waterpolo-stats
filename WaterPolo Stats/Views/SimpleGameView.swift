import SwiftUI
import UIKit

// MARK: - Simple Game View v2
// Landscape-optimized with action history and edit capabilities

struct SimpleGameView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = GameViewModel()

    // UI State
    @State private var showSaveConfirmation = false
    @State private var showFullMode = false
    @State private var showingActionSheet: GameActionType?
    @State private var selectedPlayerForAction: GamePlayer?
    @State private var isAdvancedMode = false
    @State private var showTimeoutTeamPicker = false
    @State private var showSettings = false

    // Editing
    @State private var editingAction: GameActionRecord?

    // Period summary (shown when clock hits 0)
    @State private var showPeriodSummary = false

    // Sunlight mode — local state drives styling directly
    @State private var manualSunlightMode = false
    private var isSunlightMode: Bool { manualSunlightMode }
    
    // Photo
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage?
    
    // Orientation
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                Group {
                    if orientation.isLandscape || UIDevice.current.userInterfaceIdiom == .pad {
                        landscapeLayout
                    } else {
                        portraitLayout
                    }
                }
                
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $capturedImage, onCapture: savePhoto)
        }
        .sheet(isPresented: $showFullMode) {
            GameView().environmentObject(viewModel)
        }
        .sheet(item: $showingActionSheet) { actionType in
            ActionPlayerPickerSheet(
                actionType: actionType,
                homeTeamName: viewModel.game.homeTeam.name,
                homePlayers: viewModel.game.homeTeam.players,
                awayTeamName: viewModel.game.awayTeam.name,
                awayPlayers: viewModel.game.awayTeam.players,
                initialTeam: viewModel.selectedTeam,
                onSelect: { team, player, secondaryPlayer, isFiveM in
                    recordAction(actionType, team: team, player: player, secondaryPlayer: secondaryPlayer, isFiveMeterShot: isFiveM)
                }
            )
        }
        .sheet(item: $editingAction) { action in
            EditActionSheet(
                action: action,
                onSave: { updatedAction in
                    updateAction(updatedAction)
                },
                onDelete: {
                    deleteAction(action)
                }
            )
        }
        .sheet(isPresented: $showPeriodSummary) {
            PeriodSummarySheet(
                game: viewModel.game,
                onStartNextPeriod: {
                    showPeriodSummary = false
                    viewModel.startNextPeriod()
                },
                onEndGame: {
                    showPeriodSummary = false
                    viewModel.endGame()
                    showSaveConfirmation = true
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewStandalone(isSunlightMode: $manualSunlightMode)
                .environmentObject(viewModel)
        }
        .onChange(of: viewModel.periodJustEnded) { _, justEnded in
            if justEnded {
                showPeriodSummary = true
                viewModel.periodJustEnded = false
            }
        }
        .alert("Save Game?", isPresented: $showSaveConfirmation) {
            Button("Save", role: .none) {
                viewModel.saveGame(context: viewContext) { _ in }
            }
            Button("Don't Save", role: .cancel) { }
        } message: {
            Text("Save this game to history?")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
    
    // MARK: - Layouts
    
    private var landscapeLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Home Team
                teamPanel(team: viewModel.game.homeTeam, isHome: true)
                    .frame(width: geometry.size.width * 0.25)

                // Center: Scoreboard & History
                VStack(spacing: 0) {
                    scoreboardSection
                    clockSection
                    actionHistorySection
                }
                .frame(width: geometry.size.width * 0.50)

                // Right: Away Team
                teamPanel(team: viewModel.game.awayTeam, isHome: false)
                    .frame(width: geometry.size.width * 0.25)
            }
        }
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            scoreHeader
            clockSection
            actionButtons
            actionHistorySection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
            bottomControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Components
    
    private var scoreboardSection: some View {
        HStack(spacing: 40) {
            // Home Team
            VStack(spacing: 4) {
                Text(viewModel.game.homeTeam.name.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                Text("\(viewModel.game.homeScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }

            // Period & Clock
            VStack(spacing: 4) {
                Text("Q\(viewModel.game.period)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(textColor)
                Text(formatTime(viewModel.game.gameClock))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(textColor)
            }

            // Away Team
            VStack(spacing: 4) {
                Text(viewModel.game.awayTeam.name.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                Text("\(viewModel.game.awayScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }
        }
        .padding()
        .background(backgroundColor)
    }
    
    private var scoreHeader: some View {
        HStack(spacing: 0) {
            // Home Team
            VStack(spacing: 4) {
                Text(viewModel.game.homeTeam.name.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                Text("\(viewModel.game.homeScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)

            // Center: clock + settings/camera + timeout row
            VStack(spacing: 6) {
                // Camera + Clock + Settings
                HStack(spacing: 8) {
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showImagePicker = true
                        }
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    Text(formatTime(viewModel.game.gameClock))
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundColor(textColor)
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }

                // Timeout counts + button
                HStack(spacing: 6) {
                    VStack(spacing: 1) {
                        Text("\(viewModel.game.homeTimeoutsRemaining)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(homeTeamColor)
                        Text("left")
                            .font(.system(size: 9))
                            .foregroundColor(secondaryTextColor)
                    }

                    Button(action: { showTimeoutTeamPicker = true }) {
                        Text("TIMEOUT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(6)
                    }
                    .disabled(!viewModel.game.isPeriodActive)
                    .opacity(viewModel.game.isPeriodActive ? 1.0 : 0.4)
                    .confirmationDialog("Which team called timeout?", isPresented: $showTimeoutTeamPicker, titleVisibility: .visible) {
                        Button(viewModel.game.homeTeam.name) { recordTimeout(team: .home) }
                        Button(viewModel.game.awayTeam.name) { recordTimeout(team: .away) }
                        Button("Cancel", role: .cancel) { }
                    }

                    VStack(spacing: 1) {
                        Text("\(viewModel.game.awayTimeoutsRemaining)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(awayTeamColor)
                        Text("left")
                            .font(.system(size: 9))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .frame(width: 160)

            // Away Team
            VStack(spacing: 4) {
                Text(viewModel.game.awayTeam.name.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                Text("\(viewModel.game.awayScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var homeTeamColor: Color { .blue }
    private var awayTeamColor: Color { .orange }

    private var selectionBackground: Color {
        isSunlightMode ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2)
    }
    
    // MARK: - Clock Section

    private var clockSection: some View {
        HStack(spacing: 0) {
            // Left slot: Q period (advanced) or invisible spacer (basic)
            Group {
                if isAdvancedMode {
                    Text("Q\(viewModel.game.period)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textColor)
                } else {
                    Color.clear
                }
            }
            .frame(width: 44)

            Spacer()

            // Clock adjusters — no play button (Start is in bottom bar)
            HStack(spacing: 12) {
                ClockButton(icon: "minus.circle", action: { adjustClock(by: -1) })
                ClockButton(icon: "plus.circle", action: { adjustClock(by: 1) })
            }

            Spacer()

            // Right slot: shot clock (advanced) or invisible spacer (basic)
            // Long-press to reset shot clock
            Group {
                if isAdvancedMode {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Shot")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                        Text(viewModel.game.shotClock > 0 ? "\(Int(viewModel.game.shotClock))" : "—")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(viewModel.game.shotClock <= 5 && viewModel.game.shotClock > 0 ? .red : textColor)
                    }
                    .onLongPressGesture(minimumDuration: 0.4) {
                        viewModel.resetShotClock()
                    }
                } else {
                    Color.clear
                }
            }
            .frame(width: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(cardBackground)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Inactive period banner
            if !viewModel.game.isPeriodActive {
                Text(viewModel.game.isGameActive ? "Start next quarter to record actions" : "Start game to record actions")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .padding(.horizontal)
            }

            // Action Grid - Row 1 (Always visible)
            HStack(spacing: 12) {
                SimpleActionButton(
                    icon: "sportscourt.fill",
                    label: "GOAL",
                    color: .green,
                    action: { showingActionSheet = .goal }
                )

                SimpleActionButton(
                    icon: "xmark.octagon.fill",
                    label: "EXCLUSION",
                    color: .red,
                    action: { showingActionSheet = .exclusion }
                )

                SimpleActionButton(
                    icon: "exclamationmark.triangle.fill",
                    label: "PENALTY",
                    color: .orange,
                    action: { showingActionSheet = .penalty }
                )
            }
            .padding(.horizontal)

            // Action Grid - Row 2 (Advanced options only)
            if isAdvancedMode {
                HStack(spacing: 12) {
                    SimpleActionButton(
                        icon: "hand.tap.fill",
                        label: "STEAL",
                        color: .purple,
                        action: { showingActionSheet = .steal }
                    )

                    SimpleActionButton(
                        icon: "shield.fill",
                        label: blockSaveLabel,
                        color: .blue,
                        action: { showingActionSheet = .block }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .disabled(!viewModel.game.isPeriodActive)
        .opacity(viewModel.game.isPeriodActive ? 1.0 : 0.4)
    }
    
    private var actionHistorySection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Game Log")
                    .font(.headline)
                    .foregroundColor(textColor)
                Spacer()
                Text("Tap to edit")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // List — plain style preserves custom row styling; onDelete enables swipe-to-delete
            if viewModel.game.actions.isEmpty {
                Text("No actions yet")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .padding()
                Spacer()
            } else {
                List {
                    ForEach(viewModel.game.actions) { action in
                        ActionHistoryRow(
                            action: action,
                            onTap: { editingAction = action },
                            isSunlightMode: isSunlightMode
                        )
                        .listRowBackground(cardBackground)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { indexSet in
                        viewModel.game.actions.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.plain)
                .background(cardBackground)
            }
        }
        .background(cardBackground)
    }
    
    private func teamPanel(team: GameTeam, isHome: Bool) -> some View {
        VStack(spacing: 8) {
            // Team Name
            Text(team.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(textColor)
                .lineLimit(1)
                .padding(.horizontal, 4)
            
            // Select Team Button
            Button(action: { viewModel.selectedTeam = isHome ? .home : .away }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.selectedTeam == (isHome ? .home : .away) 
                        ? (isHome ? Color.blue : Color.orange).opacity(0.3)
                        : Color.clear)
                    .frame(height: 8)
            }
            
            // Player List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(team.players) { player in
                        PlayerRow(
                            player: player,
                            isSelected: viewModel.selectedPlayer?.id == player.id,
                            onTap: { viewModel.selectedPlayer = player },
                            isSunlightMode: isSunlightMode
                        )
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(cardBackground)
    }
    
    private var bottomControls: some View {
        HStack {
            // Game Control
            if !viewModel.game.isGameActive {
                // Not started yet
                Button(action: viewModel.startGame) {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                }
                .buttonStyle(ControlButtonStyle(color: .green, isSunlightMode: isSunlightMode))
            } else if viewModel.game.isPeriodActive {
                // Period in progress — Pause or Resume
                if viewModel.isTimerRunning {
                    Button(action: viewModel.pauseGame) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.headline)
                    }
                    .buttonStyle(ControlButtonStyle(color: .orange, isSunlightMode: isSunlightMode))
                } else {
                    Button(action: viewModel.resumeGame) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.headline)
                    }
                    .buttonStyle(ControlButtonStyle(color: .green, isSunlightMode: isSunlightMode))
                }
            } else {
                // Period ended (clock ran out) — summary sheet is primary path;
                // these buttons are a fallback if sheet is dismissed
                if viewModel.game.isLastPeriod {
                    Button(action: {
                        viewModel.endGame()
                        showSaveConfirmation = true
                    }) {
                        Label("End Game", systemImage: "flag.checkered")
                            .font(.subheadline)
                    }
                    .buttonStyle(ControlButtonStyle(color: .red, isSunlightMode: isSunlightMode))
                } else {
                    Button(action: { showPeriodSummary = true }) {
                        Label("Next Q", systemImage: "forward.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(ControlButtonStyle(color: .blue, isSunlightMode: isSunlightMode))
                }
            }
            
            Spacer()

            // Center: Advanced toggle
            VStack(spacing: 2) {
                Text(isAdvancedMode ? "Advanced" : "Basic")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                Toggle("", isOn: $isAdvancedMode)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Spacer()
            
            // Right: Shot Clock Reset (advanced) or Full Stats (basic)
            if isAdvancedMode {
                Button(action: resetShotClock) {
                    VStack(spacing: 2) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.title3)
                        Text("Shot Clk")
                            .font(.caption2)
                    }
                    .foregroundColor(textColor)
                }
                .frame(width: 60)
            } else {
                Button(action: { showFullMode = true }) {
                    VStack(spacing: 2) {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                        Text("Stats")
                            .font(.caption2)
                    }
                    .foregroundColor(textColor)
                }
                .frame(width: 60)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(cardBackground)
    }
    
    // MARK: - Helpers
    
    // Sun mode = bright white (outdoor/sunlight); Moon mode = dark background (indoor)
    private var backgroundColor: Color {
        isSunlightMode ? .white : Color(red: 0.08, green: 0.08, blue: 0.10)
    }

    private var cardBackground: Color {
        isSunlightMode ? Color.gray.opacity(0.08) : Color(red: 0.14, green: 0.14, blue: 0.18)
    }

    private var textColor: Color {
        isSunlightMode ? .black : .white
    }

    private var secondaryTextColor: Color {
        isSunlightMode ? Color.black.opacity(0.55) : Color.white.opacity(0.60)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func adjustClock(by seconds: TimeInterval) {
        viewModel.game.gameClock = max(0, viewModel.game.gameClock + seconds)
    }
    
    private func toggleTimer() {
        if viewModel.isTimerRunning {
            viewModel.pauseGame()
        } else {
            if viewModel.game.isGameActive {
                viewModel.resumeGame()
            } else {
                viewModel.startGame()
            }
        }
    }
    
    private func resetShotClock() {
        viewModel.resetShotClock()
    }

    private func recordTimeout(team: GameViewModel.TeamType) {
        let action = GameActionRecord(
            id: UUID(),
            timestamp: Date(),
            period: viewModel.game.period,
            gameTime: viewModel.game.gameClock,
            actionType: .timeout,
            team: team,
            playerNumber: 0,
            secondaryPlayerNumber: nil,
            isFiveMeterShot: nil,
            isPenaltyFoul: nil
        )
        viewModel.game.actions.append(action)
        viewModel.callTimeout(team: team)
        // Timeout pauses both game clock and shot clock
        if viewModel.isTimerRunning {
            viewModel.pauseGame()
        }
    }

    private var blockSaveLabel: String {
        if let selected = viewModel.selectedPlayer, selected.isGoalie {
            return "SAVE"
        }
        return "BLOCK/SAVE"
    }
    
    private func recordAction(_ type: GameActionType, team: GameViewModel.TeamType, player: GamePlayer, secondaryPlayer: GamePlayer?, isFiveMeterShot: Bool = false) {
        // Record the action for history
        let action = GameActionRecord(
            id: UUID(),
            timestamp: Date(),
            period: viewModel.game.period,
            gameTime: viewModel.game.gameClock,
            actionType: type,
            team: team,
            playerNumber: player.number,
            secondaryPlayerNumber: secondaryPlayer?.number,
            isFiveMeterShot: isFiveMeterShot,
            isPenaltyFoul: type == .penalty
        )
        viewModel.game.actions.append(action)

        // Actually perform the game action
        let opposingTeam: GameViewModel.TeamType = team == .home ? .away : .home
        switch type {
        case .goal:
            viewModel.scoreGoal(for: team, player: player)
            if let assistPlayer = secondaryPlayer {
                viewModel.recordAssist(for: team, player: assistPlayer)
            }
            // Auto-pause on goal; reset shot clock
            if viewModel.isTimerRunning { viewModel.pauseGame() }
            viewModel.resetShotClock()
        case .exclusion:
            viewModel.recordExclusion(for: team, player: player)
            // Exclusion resets shot clock only
            viewModel.resetShotClock()
        case .penalty:
            viewModel.recordPenalty(for: team, player: player)
            if let drawn = secondaryPlayer {
                viewModel.recordPenaltyDrawn(for: opposingTeam, player: drawn)
            }
            // Auto-pause on penalty; reset shot clock
            if viewModel.isTimerRunning { viewModel.pauseGame() }
            viewModel.resetShotClock()
        case .steal:
            viewModel.recordSteal(for: team, player: player)
        case .assist:
            viewModel.recordAssist(for: team, player: player)
        case .timeout:
            viewModel.callTimeout(team: team)
        case .fiveMeterDrawn, .block, .turnover:
            break
        }
        
        viewModel.recordPlayerAction(player, action: type.rawValue)
    }
    
    private func updateAction(_ action: GameActionRecord) {
        if let index = viewModel.game.actions.firstIndex(where: { $0.id == action.id }) {
            viewModel.game.actions[index] = action
        }
    }
    
    private func deleteAction(_ action: GameActionRecord) {
        viewModel.game.actions.removeAll { $0.id == action.id }
    }
    
    private func savePhoto(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

// MARK: - Supporting Types

enum GameActionType: String, CaseIterable, Identifiable, Codable {
    case goal, assist, exclusion, penalty, steal, fiveMeterDrawn, timeout, block, turnover
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .goal: return "Goal"
        case .assist: return "Assist"
        case .exclusion: return "Exclusion"
        case .penalty: return "Penalty"
        case .steal: return "Steal"
        case .fiveMeterDrawn: return "5M Drawn"
        case .timeout: return "Timeout"
        case .block: return "Block"
        case .turnover: return "Turnover"
        }
    }
}

struct GameActionRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let period: Int
    let gameTime: TimeInterval
    let actionType: GameActionType
    let team: String 
    let playerNumber: Int
    let secondaryPlayerNumber: Int?
    let isFiveMeterShot: Bool?
    let isPenaltyFoul: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, period, gameTime, actionType, team, playerNumber, secondaryPlayerNumber, isFiveMeterShot, isPenaltyFoul
    }
    
    init(id: UUID, timestamp: Date, period: Int, gameTime: TimeInterval, actionType: GameActionType, team: GameViewModel.TeamType, playerNumber: Int, secondaryPlayerNumber: Int?, isFiveMeterShot: Bool?, isPenaltyFoul: Bool?) {
        self.id = id
        self.timestamp = timestamp
        self.period = period
        self.gameTime = gameTime
        self.actionType = actionType
        self.team = team == .home ? "home" : "away"
        self.playerNumber = playerNumber
        self.secondaryPlayerNumber = secondaryPlayerNumber
        self.isFiveMeterShot = isFiveMeterShot
        self.isPenaltyFoul = isPenaltyFoul
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        period = try container.decode(Int.self, forKey: .period)
        gameTime = try container.decode(TimeInterval.self, forKey: .gameTime)
        actionType = try container.decode(GameActionType.self, forKey: .actionType)
        team = try container.decode(String.self, forKey: .team)
        playerNumber = try container.decode(Int.self, forKey: .playerNumber)
        secondaryPlayerNumber = try container.decodeIfPresent(Int.self, forKey: .secondaryPlayerNumber)
        isFiveMeterShot = try container.decodeIfPresent(Bool.self, forKey: .isFiveMeterShot)
        isPenaltyFoul = try container.decodeIfPresent(Bool.self, forKey: .isPenaltyFoul)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(period, forKey: .period)
        try container.encode(gameTime, forKey: .gameTime)
        try container.encode(actionType, forKey: .actionType)
        try container.encode(team, forKey: .team)
        try container.encode(playerNumber, forKey: .playerNumber)
        try container.encodeIfPresent(secondaryPlayerNumber, forKey: .secondaryPlayerNumber)
        try container.encodeIfPresent(isFiveMeterShot, forKey: .isFiveMeterShot)
        try container.encodeIfPresent(isPenaltyFoul, forKey: .isPenaltyFoul)
    }
    
    var teamType: GameViewModel.TeamType {
        return team == "home" ? .home : .away
    }
}

extension GameActionRecord {
    // Legacy helper if needed, but primary init is now in struct
}

// MARK: - Supporting Views

// Moved to separate file to avoid conflict or renamed here
struct SimpleActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct ClockButton: View {
    let icon: String
    let action: () -> Void
    var isPrimary: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isPrimary ? 28 : 20, weight: .bold))
                .foregroundColor(isPrimary ? .white : .primary)
                .frame(width: isPrimary ? 64 : 50, height: 50)
                .background(isPrimary ? Color.blue : Color(.systemGray5))
                .cornerRadius(12)
        }
    }
}

struct ActionHistoryRow: View {
    let action: GameActionRecord
    let onTap: () -> Void
    let isSunlightMode: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Period & Time
                Text("Q\(action.period) \(formatTime(action.gameTime))")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(isSunlightMode ? Color.black.opacity(0.55) : Color.white.opacity(0.60))
                    .frame(width: 90, alignment: .leading)

                // Action Icon
                Image(systemName: iconForAction(action.actionType))
                    .foregroundColor(colorForAction(action.actionType))
                    .frame(width: 24)

                // Details
                Text(detailsText)
                    .font(.system(size: 14))
                    .foregroundColor(isSunlightMode ? .black : .white)
                    .lineLimit(1)

                Spacer()

                // Edit indicator
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(isSunlightMode ? Color.black.opacity(0.4) : Color.white.opacity(0.40))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSunlightMode ? Color.gray.opacity(0.15) : Color(red: 0.20, green: 0.20, blue: 0.24))
            .cornerRadius(8)
        }
    }
    
    private var detailsText: String {
        if action.actionType == .timeout {
            return "\(action.team.capitalized) Timeout"
        }
        var text = "#\(action.playerNumber)"
        if let secondary = action.secondaryPlayerNumber {
            if action.actionType == .penalty {
                text += " (Drawn by #\(secondary))"
            } else {
                text += " (Assist #\(secondary))"
            }
        }
        if action.isFiveMeterShot == true {
            text += " - 5M Shot"
        }
        if action.isPenaltyFoul == true {
            text += " - Penalty"
        }
        return text
    }
    
    private func iconForAction(_ type: GameActionType) -> String {
        switch type {
        case .goal: return "sportscourt.fill"
        case .assist: return "hand.raised.fill"
        case .exclusion: return "xmark.octagon.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        case .steal: return "hand.tap.fill"
        case .fiveMeterDrawn: return "arrow.right.circle.fill"
        case .timeout: return "pause.circle.fill"
        case .block: return "shield.fill"
        case .turnover: return "arrow.2.circlepath"
        }
    }
    
    private func colorForAction(_ type: GameActionType) -> Color {
        switch type {
        case .goal: return .green
        case .assist: return .blue
        case .exclusion: return .red
        case .penalty: return .orange
        case .steal: return .purple
        case .fiveMeterDrawn: return .cyan
        case .timeout: return .yellow
        case .block: return .indigo
        case .turnover: return .gray
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlayerRow: View {
    let player: GamePlayer
    let isSelected: Bool
    let onTap: () -> Void
    let isSunlightMode: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("#\(player.number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSunlightMode ? .black : .white)
                    .frame(width: 36)

                Text(player.name)
                    .font(.system(size: 14))
                    .foregroundColor(isSunlightMode ? .black : .white)
                    .lineLimit(1)

                Spacer()

                // Stats
                HStack(spacing: 8) {
                    Text("G:\(player.goals)")
                        .font(.caption)
                        .foregroundColor(isSunlightMode ? Color.black.opacity(0.6) : Color.white.opacity(0.60))
                    Text("E:\(player.exclusions)")
                        .font(.caption)
                        .foregroundColor(player.exclusions >= 3 ? .red : (isSunlightMode ? Color.black.opacity(0.6) : Color.white.opacity(0.60)))
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.blue.opacity(0.25) : Color.clear)
            .cornerRadius(6)
        }
    }
}

struct ControlButtonStyle: ButtonStyle {
    let color: Color
    let isSunlightMode: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Sheets

struct ActionPlayerPickerSheet: View {
    let actionType: GameActionType
    let homeTeamName: String
    let homePlayers: [GamePlayer]
    let awayTeamName: String
    let awayPlayers: [GamePlayer]
    let initialTeam: GameViewModel.TeamType
    let onSelect: (GameViewModel.TeamType, GamePlayer, GamePlayer?, Bool) -> Void

    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTeam: GameViewModel.TeamType
    @State private var selectedPlayer: GamePlayer?
    @State private var secondaryPlayer: GamePlayer?
    @State private var isFiveMeterShot = false

    init(actionType: GameActionType,
         homeTeamName: String,
         homePlayers: [GamePlayer],
         awayTeamName: String,
         awayPlayers: [GamePlayer],
         initialTeam: GameViewModel.TeamType,
         onSelect: @escaping (GameViewModel.TeamType, GamePlayer, GamePlayer?, Bool) -> Void) {
        self.actionType = actionType
        self.homeTeamName = homeTeamName
        self.homePlayers = homePlayers
        self.awayTeamName = awayTeamName
        self.awayPlayers = awayPlayers
        self.initialTeam = initialTeam
        self.onSelect = onSelect
        _selectedTeam = State(initialValue: initialTeam)
    }

    private var currentTeamName: String { selectedTeam == .home ? homeTeamName : awayTeamName }
    private var currentPlayers: [GamePlayer] { selectedTeam == .home ? homePlayers : awayPlayers }
    private var opposingTeamName: String { selectedTeam == .home ? awayTeamName : homeTeamName }
    private var opposingPlayers: [GamePlayer] { selectedTeam == .home ? awayPlayers : homePlayers }

    private var sortedPlayers: [GamePlayer] {
        if actionType == .block {
            return currentPlayers.filter { $0.isGoalie } + currentPlayers.filter { !$0.isGoalie }
        }
        return currentPlayers
    }

    private let gridColumns = [GridItem(.adaptive(minimum: 76), spacing: 8)]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: iconForType(actionType))
                                .font(.largeTitle)
                                .foregroundColor(colorForType(actionType))
                            Text(actionType == .block ? "BLOCK / SAVE" : actionType.label.uppercased())
                                .font(.system(size: 32, weight: .bold))
                        }
                    }
                    .padding(.top)

                    // Team Switcher
                    Picker("Team", selection: $selectedTeam) {
                        Text(homeTeamName).tag(GameViewModel.TeamType.home)
                        Text(awayTeamName).tag(GameViewModel.TeamType.away)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTeam) { _, _ in
                        selectedPlayer = nil
                        secondaryPlayer = nil
                    }

                    // Primary Player Selection
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(actionType == .penalty ? "Committed by (\(currentTeamName))" : "Select Player")
                                .font(.headline)
                            if actionType == .block {
                                Text("· Goalies shown first")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: gridColumns, spacing: 8) {
                            ForEach(sortedPlayers) { player in
                                PlayerCapButton(
                                    player: player,
                                    isSelected: selectedPlayer?.id == player.id,
                                    onTap: { selectedPlayer = player }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Goal: 5M toggle + optional assist picker
                    if actionType == .goal {
                        Toggle("5M Penalty Shot", isOn: $isFiveMeterShot)
                            .padding(.horizontal)

                        if !isFiveMeterShot {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Assist (Optional)")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVGrid(columns: gridColumns, spacing: 8) {
                                    ForEach(currentPlayers.filter { $0.id != selectedPlayer?.id }) { player in
                                        PlayerCapButton(
                                            player: player,
                                            isSelected: secondaryPlayer?.id == player.id,
                                            onTap: {
                                                secondaryPlayer = secondaryPlayer?.id == player.id ? nil : player
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Penalty: split — "Drawn by" from opposing team
                    if actionType == .penalty {
                        Divider().padding(.horizontal)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                    .foregroundColor(.green)
                                Text("Drawn by (\(opposingTeamName))")
                                    .font(.headline)
                                Text("· Optional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(opposingPlayers) { player in
                                    PlayerCapButton(
                                        player: player,
                                        isSelected: secondaryPlayer?.id == player.id,
                                        onTap: {
                                            secondaryPlayer = secondaryPlayer?.id == player.id ? nil : player
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Confirm Button
                    Button(action: {
                        if let player = selectedPlayer {
                            onSelect(selectedTeam, player, secondaryPlayer, isFiveMeterShot)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Record Action")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPlayer != nil ? colorForType(actionType) : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(selectedPlayer == nil)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func iconForType(_ type: GameActionType) -> String {
        switch type {
        case .goal: return "sportscourt.fill"
        case .assist: return "hand.raised.fill"
        case .exclusion: return "xmark.octagon.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        case .steal: return "hand.tap.fill"
        case .fiveMeterDrawn: return "arrow.right.circle.fill"
        case .timeout: return "pause.circle.fill"
        case .block: return "shield.fill"
        case .turnover: return "arrow.2.circlepath"
        }
    }

    private func colorForType(_ type: GameActionType) -> Color {
        switch type {
        case .goal: return .green
        case .assist: return .blue
        case .exclusion: return .red
        case .penalty: return .orange
        case .steal: return .purple
        case .fiveMeterDrawn: return .cyan
        case .timeout: return .yellow
        case .block: return .indigo
        case .turnover: return .gray
        }
    }
}

struct PlayerCapButton: View {
    let player: GamePlayer
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text("#\(player.number)")
                    .font(.system(size: 24, weight: .bold))
                Text(player.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 80, height: 70)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .cornerRadius(12)
        }
    }
}

struct EditActionSheet: View {
    let action: GameActionRecord
    let onSave: (GameActionRecord) -> Void
    let onDelete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var gameTime: TimeInterval
    @State private var playerNumber: String
    @State private var secondaryPlayerNumber: String
    @State private var isFiveMeterShot: Bool
    @State private var isPenaltyFoul: Bool
    
    init(action: GameActionRecord, onSave: @escaping (GameActionRecord) -> Void, onDelete: @escaping () -> Void) {
        self.action = action
        self.onSave = onSave
        self.onDelete = onDelete
        _gameTime = State(initialValue: action.gameTime)
        _playerNumber = State(initialValue: String(action.playerNumber))
        _secondaryPlayerNumber = State(initialValue: action.secondaryPlayerNumber.map(String.init) ?? "")
        _isFiveMeterShot = State(initialValue: action.isFiveMeterShot ?? false)
        _isPenaltyFoul = State(initialValue: action.isPenaltyFoul ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    HStack {
                        Text("Game Time")
                        Spacer()
                        Text(formatTime(gameTime))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Stepper("Adjust Time", value: $gameTime, in: 0...600, step: 1)
                }
                
                Section("Player") {
                    TextField("Player Number", text: $playerNumber)
                        .keyboardType(.numberPad)
                    
                    if action.actionType == .goal {
                        TextField("Assist (optional)", text: $secondaryPlayerNumber)
                            .keyboardType(.numberPad)
                        Toggle("5M Penalty Shot", isOn: $isFiveMeterShot)
                    }
                    
                    if action.actionType == .penalty {
                        Toggle("Awarded 5M Shot", isOn: $isPenaltyFoul)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        var updatedAction = action
                        updatedAction = GameActionRecord(
                            id: action.id,
                            timestamp: action.timestamp,
                            period: action.period,
                            gameTime: gameTime,
                            actionType: action.actionType,
                            team: action.teamType,
                            playerNumber: Int(playerNumber) ?? action.playerNumber,
                            secondaryPlayerNumber: Int(secondaryPlayerNumber),
                            isFiveMeterShot: isFiveMeterShot,
                            isPenaltyFoul: isPenaltyFoul
                        )
                        onSave(updatedAction)
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Button("Delete Action", role: .destructive) {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Edit Action")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Period Summary Sheet

struct PeriodSummarySheet: View {
    let game: GameSession
    let onStartNextPeriod: () -> Void
    let onEndGame: () -> Void

    private var completedPeriod: Int { game.period }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Score banner
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text(game.homeTeam.name.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("\(game.homeScore)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Q\(completedPeriod) Final")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("–")
                            .font(.system(size: 36, weight: .bold))
                    }

                    VStack(spacing: 2) {
                        Text(game.awayTeam.name.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text("\(game.awayScore)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 16)
                .background(Color(.systemGray6))

                // Q-by-Q breakdown + period stats
                List {
                    if !game.periodScores.isEmpty {
                        Section("Quarter Scores") {
                            HStack {
                                Text("Quarter")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(game.homeTeam.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .center)
                                Text(game.awayTeam.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                                    .frame(width: 50, alignment: .center)
                            }

                            ForEach(game.periodScores) { ps in
                                let q = periodScore(for: ps.period)
                                HStack {
                                    Text("Q\(ps.period)")
                                        .font(.body.weight(ps.period == completedPeriod ? .bold : .regular))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(q.home)")
                                        .frame(width: 50, alignment: .center)
                                    Text("\(q.away)")
                                        .frame(width: 50, alignment: .center)
                                }
                            }

                            HStack {
                                Text("Total")
                                    .font(.body.weight(.bold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(game.homeScore)")
                                    .font(.body.weight(.bold))
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .center)
                                Text("\(game.awayScore)")
                                    .font(.body.weight(.bold))
                                    .foregroundColor(.orange)
                                    .frame(width: 50, alignment: .center)
                            }
                        }
                    }

                    Section("Q\(completedPeriod) Stats") {
                        statRow("Goals",
                                home: periodCount(.goal, team: "home"),
                                away: periodCount(.goal, team: "away"))
                        statRow("Exclusions",
                                home: periodCount(.exclusion, team: "home"),
                                away: periodCount(.exclusion, team: "away"))
                        statRow("Penalties",
                                home: periodCount(.penalty, team: "home"),
                                away: periodCount(.penalty, team: "away"))
                        statRow("Steals",
                                home: periodCount(.steal, team: "home"),
                                away: periodCount(.steal, team: "away"))
                    }

                    Section("Game Totals") {
                        statRow("Goals",
                                home: game.actions.filter { $0.actionType == .goal && $0.team == "home" }.count,
                                away: game.actions.filter { $0.actionType == .goal && $0.team == "away" }.count)
                        statRow("Exclusions",
                                home: game.actions.filter { $0.actionType == .exclusion && $0.team == "home" }.count,
                                away: game.actions.filter { $0.actionType == .exclusion && $0.team == "away" }.count)
                        statRow("Penalties",
                                home: game.actions.filter { $0.actionType == .penalty && $0.team == "home" }.count,
                                away: game.actions.filter { $0.actionType == .penalty && $0.team == "away" }.count)
                        statRow("Steals",
                                home: game.actions.filter { $0.actionType == .steal && $0.team == "home" }.count,
                                away: game.actions.filter { $0.actionType == .steal && $0.team == "away" }.count)
                    }
                }
                .listStyle(.insetGrouped)

                // Primary action button pinned to bottom
                VStack(spacing: 0) {
                    Divider()
                    if game.isLastPeriod {
                        Button(action: onEndGame) {
                            Label("End Game & Save", systemImage: "flag.checkered")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding()
                    } else {
                        Button(action: onStartNextPeriod) {
                            Label("Start Q\(completedPeriod + 1)", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding()
                    }
                }
            }
            .navigationTitle("Q\(completedPeriod) Complete")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Score this quarter only (delta from previous cumulative)
    private func periodScore(for period: Int) -> (home: Int, away: Int) {
        guard let current = game.periodScores.first(where: { $0.period == period }) else {
            return (0, 0)
        }
        let prevHome = game.periodScores.first(where: { $0.period == period - 1 })?.homeScore ?? 0
        let prevAway = game.periodScores.first(where: { $0.period == period - 1 })?.awayScore ?? 0
        return (current.homeScore - prevHome, current.awayScore - prevAway)
    }

    private func periodCount(_ type: GameActionType, team: String) -> Int {
        game.actions.filter { $0.period == completedPeriod && $0.actionType == type && $0.team == team }.count
    }

    @ViewBuilder
    private func statRow(_ label: String, home: Int, away: Int) -> some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(home)")
                .foregroundColor(.blue)
                .frame(width: 50, alignment: .center)
            Text("\(away)")
                .foregroundColor(.orange)
                .frame(width: 50, alignment: .center)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onCapture: ((UIImage) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onCapture?(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct SimpleGameView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleGameView()
    }
}
