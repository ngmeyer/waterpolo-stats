import SwiftUI

struct SettingsViewStandalone: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: GameViewModel
    @Binding var isSunlightMode: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Display")) {
                    Toggle(isSunlightMode ? "Day Mode (Sunlight)" : "Night Mode (Indoor)", isOn: $isSunlightMode)
                }

                Section(header: Text("Game Type & Level")) {
                    Picker("Game Type", selection: $viewModel.game.gameType) {
                        ForEach(GameSession.GameType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Picker("Game Level", selection: $viewModel.game.gameLevel) {
                        ForEach(GameSession.GameLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }

                Section(header: Text("Game Details")) {
                    TextField("Location", text: $viewModel.game.location)
                    TextField("Notes", text: $viewModel.game.notes)
                }

                Section(header: Text("Team Settings")) {
                    TextField("Dark Caps Name", text: $viewModel.game.homeTeam.name)
                    TextField("Light Caps Name", text: $viewModel.game.awayTeam.name)
                    TextField("Dark Coach", text: $viewModel.game.homeTeam.coach)
                    TextField("Light Coach", text: $viewModel.game.awayTeam.coach)
                }

                Section(header: Text("Overtime & Timeouts")) {
                    Stepper("Timeouts per Team: \(viewModel.game.maxTimeoutsPerTeam)",
                            value: $viewModel.game.maxTimeoutsPerTeam, in: 0...5)

                    Stepper("\(viewModel.game.homeTeam.name) Remaining: \(viewModel.game.homeTimeoutsRemaining)",
                            value: $viewModel.game.homeTimeoutsRemaining,
                            in: 0...max(1, viewModel.game.maxTimeoutsPerTeam))

                    Stepper("\(viewModel.game.awayTeam.name) Remaining: \(viewModel.game.awayTimeoutsRemaining)",
                            value: $viewModel.game.awayTimeoutsRemaining,
                            in: 0...max(1, viewModel.game.maxTimeoutsPerTeam))

                    Stepper("OT Periods: \(viewModel.game.maxOvertimePeriods)",
                            value: $viewModel.game.maxOvertimePeriods, in: 0...4)

                    Picker("OT Period Length", selection: $viewModel.game.overtimePeriodLength) {
                        Text("3 min").tag(TimeInterval(180))
                        Text("4 min").tag(TimeInterval(240))
                        Text("5 min").tag(TimeInterval(300))
                    }
                }

                Section {
                    Button("Reset Game Data") {
                        viewModel.resetGame()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsViewStandalone(isSunlightMode: .constant(false))
        .environmentObject(GameViewModel())
}
