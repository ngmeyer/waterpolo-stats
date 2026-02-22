import SwiftUI

struct GameLogView: View {
    @Environment(\.presentationMode) var presentationMode
    let events: [GameEventRecord]
    let homeTeamName: String
    let awayTeamName: String
    let onAdjustTime: (UUID, TimeInterval) -> Void
    
    @State private var selectedEvent: GameEventRecord?
    @State private var adjustedTime: String = ""
    @State private var showTimeAdjustment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                WaterPoloColors.background
                    .ignoresSafeArea()
                
                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(WaterPoloColors.textSecondary)
                        
                        Text("No Events Yet")
                            .font(.headline)
                            .foregroundColor(WaterPoloColors.textPrimary)
                        
                        Text("Game events will appear here as they occur")
                            .font(.caption)
                            .foregroundColor(WaterPoloColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(events) { event in
                                GameLogEventCard(
                                    event: event,
                                    homeTeamName: homeTeamName,
                                    awayTeamName: awayTeamName,
                                    onTap: {
                                        selectedEvent = event
                                        adjustedTime = String(format: "%.1f", event.gameTime)
                                        showTimeAdjustment = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Game Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showTimeAdjustment) {
                if let event = selectedEvent {
                    TimeAdjustmentSheet(
                        event: event,
                        adjustedTime: $adjustedTime,
                        onSave: {
                            if let newTime = TimeInterval(adjustedTime) {
                                onAdjustTime(event.id, newTime)
                                showTimeAdjustment = false
                            }
                        },
                        onCancel: {
                            showTimeAdjustment = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Game Log Event Card

struct GameLogEventCard: View {
    let event: GameEventRecord
    let homeTeamName: String
    let awayTeamName: String
    let onTap: () -> Void
    
    var teamName: String {
        event.team == .home ? homeTeamName : (event.team == .away ? awayTeamName : "Official")
    }
    
    var eventIcon: String {
        switch event.eventType {
        case .goal:
            return "target.fill"
        case .shot:
            return "circle.fill"
        case .assist:
            return "hand.raised.fill"
        case .steal:
            return "hand.draw.fill"
        case .exclusion:
            return "xmark.octagon.fill"
        case .exclusionDrawn:
            return "checkmark.circle.fill"
        case .penalty:
            return "exclamationmark.circle.fill"
        case .penaltyDrawn:
            return "exclamationmark.circle.fill"
        case .sprintWon:
            return "bolt.fill"
        case .sprintLost:
            return "bolt.slash.fill"
        case .timeout:
            return "pause.circle.fill"
        case .periodStart:
            return "play.circle.fill"
        case .periodEnd:
            return "stop.circle.fill"
        case .gameStart:
            return "play.fill"
        case .gameEnd:
            return "stop.fill"
        case .foulOut:
            return "xmark.circle.fill"
        }
    }
    
    var eventColor: Color {
        switch event.eventType {
        case .goal:
            return WaterPoloColors.success
        case .exclusion, .penalty, .foulOut:
            return WaterPoloColors.danger
        case .exclusionDrawn, .penaltyDrawn:
            return WaterPoloColors.success
        case .sprintWon:
            return WaterPoloColors.secondary
        case .gameStart, .periodStart:
            return WaterPoloColors.secondary
        default:
            return WaterPoloColors.textSecondary
        }
    }
    
    var eventLabel: String {
        switch event.eventType {
        case .goal:
            return "Goal"
        case .shot:
            return "Shot"
        case .assist:
            return "Assist"
        case .steal:
            return "Steal"
        case .exclusion:
            return "Exclusion"
        case .exclusionDrawn:
            return "Exclusion Drawn"
        case .penalty:
            return "Penalty"
        case .penaltyDrawn:
            return "Penalty Drawn"
        case .sprintWon:
            return "Sprint Won"
        case .sprintLost:
            return "Sprint Lost"
        case .timeout:
            return "Timeout"
        case .periodStart:
            return "Period Start"
        case .periodEnd:
            return "Period End"
        case .gameStart:
            return "Game Start"
        case .gameEnd:
            return "Game End"
        case .foulOut:
            return "Fouled Out"
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Event Icon
                    Image(systemName: eventIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(eventColor)
                        .frame(width: 32, height: 32)
                        .background(eventColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(eventLabel)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(WaterPoloColors.textPrimary)
                            
                            if let playerNumber = event.playerNumber {
                                Text("#\(playerNumber)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(WaterPoloColors.textSecondary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(teamName)
                                .font(.caption)
                                .foregroundColor(WaterPoloColors.textSecondary)
                            
                            Text("•")
                                .foregroundColor(WaterPoloColors.textSecondary)
                            
                            Text("Period \(event.period)")
                                .font(.caption)
                                .foregroundColor(WaterPoloColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Time
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(event.gameTime))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(WaterPoloColors.textPrimary)
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(WaterPoloColors.textSecondary)
                    }
                }
                .padding()
                .background(WaterPoloColors.surface)
                .cornerRadius(12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Time Adjustment Sheet

struct TimeAdjustmentSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let event: GameEventRecord
    @Binding var adjustedTime: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var eventLabel: String {
        switch event.eventType {
        case .goal:
            return "Goal"
        case .exclusion:
            return "Exclusion"
        case .penalty:
            return "Penalty"
        case .sprintWon:
            return "Sprint Won"
        default:
            return event.eventType.rawValue
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                WaterPoloColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Event Info
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(WaterPoloColors.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(eventLabel)
                                    .font(.headline)
                                    .foregroundColor(WaterPoloColors.textPrimary)
                                
                                if let playerNumber = event.playerNumber {
                                    Text("Player #\(playerNumber)")
                                        .font(.caption)
                                        .foregroundColor(WaterPoloColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(WaterPoloColors.surface)
                        .cornerRadius(12)
                    }
                    
                    // Time Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adjust Game Time")
                            .font(.headline)
                            .foregroundColor(WaterPoloColors.textPrimary)
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Original Time")
                                    .font(.caption)
                                    .foregroundColor(WaterPoloColors.textSecondary)
                                
                                Text(formatTime(event.gameTime))
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .foregroundColor(WaterPoloColors.textSecondary)
                            }
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(WaterPoloColors.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("New Time (seconds)")
                                    .font(.caption)
                                    .foregroundColor(WaterPoloColors.textSecondary)
                                
                                TextField("0.0", text: $adjustedTime)
                                    .font(.system(.title3, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(WaterPoloColors.surfaceVariant)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(WaterPoloColors.surface)
                    .cornerRadius(12)
                    
                    // Help Text
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(WaterPoloColors.warning)
                        
                        Text("Enter the time in seconds to match the official clock")
                            .font(.caption)
                            .foregroundColor(WaterPoloColors.textSecondary)
                    }
                    .padding()
                    .background(WaterPoloColors.warning.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(WaterPoloColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(WaterPoloColors.surfaceVariant)
                                .cornerRadius(8)
                        }
                        
                        Button(action: onSave) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(WaterPoloColors.secondary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Adjust Event Time")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct GameLogView_Previews: PreviewProvider {
    static var previews: some View {
        let events = [
            GameEventRecord(
                id: UUID(),
                timestamp: Date(),
                period: 1,
                gameTime: 120.0,
                eventType: .goal,
                team: .home,
                playerNumber: 2,
                additionalInfo: nil
            ),
            GameEventRecord(
                id: UUID(),
                timestamp: Date(),
                period: 1,
                gameTime: 95.0,
                eventType: .exclusion,
                team: .away,
                playerNumber: 5,
                additionalInfo: nil
            )
        ]
        
        GameLogView(
            events: events,
            homeTeamName: "Home Team",
            awayTeamName: "Away Team",
            onAdjustTime: { _, _ in }
        )
    }
}
