import SwiftUI
import PDFKit

// MARK: - Export Manager

class ExportManager {
    static let shared = ExportManager()
    
    // MARK: - Text Export (Parent Share)
    
    func generateTextSummary(game: GameSession) -> String {
        var lines: [String] = []
        
        // Header
        lines.append("🏐 \(game.homeTeam.name) \(game.homeScore), \(game.awayTeam.name) \(game.awayScore) (Final)")
        lines.append("")
        
        // Period scores
        if !game.periodScores.isEmpty {
            lines.append("📊 Period Scores:")
            for periodScore in game.periodScores {
                lines.append("   Q\(periodScore.period): \(periodScore.homeScore) - \(periodScore.awayScore)")
            }
            lines.append("")
        }
        
        // Top performers
        let allPlayers = game.homeTeam.players + game.awayTeam.players
        let goalLeaders = allPlayers.filter { $0.goals > 0 }.sorted { $0.goals > $1.goals }.prefix(3)
        
        if !goalLeaders.isEmpty {
            lines.append("⭐ Top Performers:")
            for player in goalLeaders {
                let team = game.homeTeam.players.contains(where: { $0.id == player.id }) ? game.homeTeam.name : game.awayTeam.name
                lines.append("   • \(player.name) (\(team)): \(player.goals) goal\(player.goals == 1 ? "" : "s")")
            }
            lines.append("")
        }
        
        // Team stats
        lines.append("📈 Team Stats:")
        lines.append("   \(game.homeTeam.name):")
        lines.append("      Goals: \(game.homeScore)")
        lines.append("      Exclusions: \(game.homeTeam.players.reduce(0) { $0 + $1.exclusions })")
        lines.append("   \(game.awayTeam.name):")
        lines.append("      Goals: \(game.awayScore)")
        lines.append("      Exclusions: \(game.awayTeam.players.reduce(0) { $0 + $1.exclusions })")
        lines.append("")
        
        // Full rosters
        lines.append("📝 Full Stats:")
        lines.append("")
        lines.append(formatTeamRoster(game.homeTeam))
        lines.append("")
        lines.append(formatTeamRoster(game.awayTeam))
        
        return lines.joined(separator: "\n")
    }
    
    private func formatTeamRoster(_ team: GameTeam) -> String {
        var lines: [String] = []
        lines.append("\(team.name):")
        lines.append(String(format: "%-4s %-20s %3s %3s %3s %3s", "#", "Name", "G", "A", "S", "E"))
        lines.append(String(repeating: "-", count: 40))
        
        for player in team.players.sorted(by: { $0.number < $1.number }) {
            lines.append(String(
                format: "%-4d %-20s %3d %3d %3d %3d",
                player.number,
                String(player.name.prefix(20)),
                player.goals,
                player.assists,
                player.steals,
                player.exclusions
            ))
        }
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - PDF Export
    
    func generatePDF(game: GameSession) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Water Polo Stats",
            kCGPDFContextAuthor: "Water Polo Stats App",
            kCGPDFContextTitle: "\(game.homeTeam.name) vs \(game.awayTeam.name)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612 // 8.5 inches
        let pageHeight: CGFloat = 792 // 11 inches
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 40
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "\(game.homeTeam.name) vs \(game.awayTeam.name)"
            title.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: titleAttributes)
            yPosition += 35
            
            // Final score
            let scoreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.systemBlue
            ]
            let score = "\(game.homeScore) - \(game.awayScore)"
            score.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: scoreAttributes)
            yPosition += 50
            
            // Game info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.darkGray
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateText = "Date: \(dateFormatter.string(from: game.startTime))"
            dateText.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: infoAttributes)
            yPosition += 20
            
            if !game.location.isEmpty {
                let locationText = "Location: \(game.location)"
                locationText.draw(at: CGPoint(x: 40, y: yPosition), withAttributes: infoAttributes)
                yPosition += 20
            }
            
            yPosition += 20
            
            // Period scores
            if !game.periodScores.isEmpty {
                let sectionAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                "Period Scores".draw(at: CGPoint(x: 40, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 25
                
                let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray
                ]
                
                // Header
                "Period".draw(at: CGPoint(x: 40, y: yPosition), withAttributes: tableHeaderAttributes)
                game.homeTeam.name.draw(at: CGPoint(x: 150, y: yPosition), withAttributes: tableHeaderAttributes)
                game.awayTeam.name.draw(at: CGPoint(x: 300, y: yPosition), withAttributes: tableHeaderAttributes)
                yPosition += 20
                
                let tableDataAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                for periodScore in game.periodScores {
                    "Q\(periodScore.period)".draw(at: CGPoint(x: 40, y: yPosition), withAttributes: tableDataAttributes)
                    "\(periodScore.homeScore)".draw(at: CGPoint(x: 150, y: yPosition), withAttributes: tableDataAttributes)
                    "\(periodScore.awayScore)".draw(at: CGPoint(x: 300, y: yPosition), withAttributes: tableDataAttributes)
                    yPosition += 18
                }
                
                yPosition += 20
            }
            
            // Team stats
            drawTeamStats(context: context, team: game.homeTeam, isHome: true, startY: &yPosition, pageRect: pageRect)
            
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = 40
            }
            
            drawTeamStats(context: context, team: game.awayTeam, isHome: false, startY: &yPosition, pageRect: pageRect)
        }
        
        return data
    }
    
    private func drawTeamStats(context: UIGraphicsPDFRendererContext, team: GameTeam, isHome: Bool, startY: inout CGFloat, pageRect: CGRect) {
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]
        
        team.name.draw(at: CGPoint(x: 40, y: startY), withAttributes: sectionAttributes)
        startY += 25
        
        // Table header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        
        let headers = ["#", "Name", "G", "A", "S", "E", "SW", "SL"]
        let columnWidths: [CGFloat] = [30, 180, 30, 30, 30, 30, 30, 30]
        var xPosition: CGFloat = 40
        
        for (index, header) in headers.enumerated() {
            header.draw(at: CGPoint(x: xPosition, y: startY), withAttributes: headerAttributes)
            xPosition += columnWidths[index]
        }
        startY += 20
        
        // Divider line
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 40, y: startY - 5))
        line.addLine(to: CGPoint(x: pageRect.width - 40, y: startY - 5))
        line.lineWidth = 0.5
        UIColor.lightGray.setStroke()
        line.stroke()
        
        // Player rows
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        for player in team.players.sorted(by: { $0.number < $1.number }) {
            if startY > pageRect.height - 50 {
                context.beginPage()
                startY = 40
            }
            
            xPosition = 40
            let values = [
                "\(player.number)",
                player.name,
                "\(player.goals)",
                "\(player.assists)",
                "\(player.steals)",
                "\(player.exclusions)",
                "\(player.sprintsWon)",
                "\(player.sprintsLost)"
            ]
            
            for (index, value) in values.enumerated() {
                value.draw(at: CGPoint(x: xPosition, y: startY), withAttributes: dataAttributes)
                xPosition += columnWidths[index]
            }
            
            startY += 16
        }
        
        startY += 20
    }
    
    // MARK: - MaxPreps Export (JSON)
    
    func generateMaxPrepsJSON(game: GameSession) -> Data? {
        let export = MaxPrepsExport(
            gameId: game.id.uuidString,
            homeTeam: createTeamExport(team: game.homeTeam, score: game.homeScore),
            awayTeam: createTeamExport(team: game.awayTeam, score: game.awayScore),
            gameDate: game.startTime,
            location: game.location,
            gameType: game.gameType.rawValue,
            gameLevel: game.gameLevel.rawValue,
            periods: game.periodScores.map { periodScore in
                MaxPrepsExport.PeriodExport(
                    periodNumber: periodScore.period,
                    homeScore: periodScore.homeScore,
                    awayScore: periodScore.awayScore
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(export)
    }
    
    private func createTeamExport(team: GameTeam, score: Int) -> MaxPrepsExport.TeamExport {
        let players = team.players.map { player in
            MaxPrepsExport.PlayerExport(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions
            )
        }
        
        return MaxPrepsExport.TeamExport(
            name: team.name,
            score: score,
            players: players
        )
    }
    
    // MARK: - Club Water Polo Export
    
    func generateClubExport(game: GameSession) -> Data? {
        let homePlayerStats = game.homeTeam.players.map { player in
            ClubWaterPoloExport.PlayerStats(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions,
                sprintsWon: player.sprintsWon,
                saves: player.isGoalie ? 0 : nil,
                goalsAllowed: player.isGoalie ? 0 : nil
            )
        }
        
        let awayPlayerStats = game.awayTeam.players.map { player in
            ClubWaterPoloExport.PlayerStats(
                number: player.number,
                name: player.name,
                goals: player.goals,
                assists: player.assists,
                steals: player.steals,
                exclusions: player.exclusions,
                sprintsWon: player.sprintsWon,
                saves: player.isGoalie ? 0 : nil,
                goalsAllowed: player.isGoalie ? 0 : nil
            )
        }
        
        let export = ClubWaterPoloExport(
            gameId: game.id.uuidString,
            date: game.startTime,
            homeTeam: game.homeTeam.name,
            awayTeam: game.awayTeam.name,
            gameType: game.gameType.rawValue,
            gameLevel: game.gameLevel.rawValue,
            location: game.location,
            finalScore: "\(game.homeScore) - \(game.awayScore)",
            periodScores: game.periodScores.map { "\($0.homeScore) - \($0.awayScore)" },
            homeRoster: homePlayerStats,
            awayRoster: awayPlayerStats
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(export)
    }
}

// MARK: - Export Sheet View

struct ExportSheetView: View {
    let game: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Parent Share Section
                Section(header: Text("Quick Share")) {
                    Button(action: shareTextSummary) {
                        ExportRow(
                            icon: "message.fill",
                            title: "Text Summary",
                            subtitle: "Share via Messages, WhatsApp, etc.",
                            color: .green
                        )
                    }
                    
                    Button(action: sharePDF) {
                        ExportRow(
                            icon: "doc.fill",
                            title: "PDF Report",
                            subtitle: "Full stats with formatting",
                            color: .red
                        )
                    }
                }
                
                // MaxPreps Section
                Section(header: Text("MaxPreps")) {
                    Button(action: shareMaxPrepsJSON) {
                        ExportRow(
                            icon: "arrow.up.doc.fill",
                            title: "MaxPreps JSON",
                            subtitle: "Upload to MaxPreps.com",
                            color: .blue
                        )
                    }
                    
                    Button(action: copyMaxPrepsJSON) {
                        ExportRow(
                            icon: "doc.on.doc.fill",
                            title: "Copy JSON to Clipboard",
                            subtitle: "For manual upload",
                            color: .gray
                        )
                    }
                }
                
                // Club Water Polo Section
                Section(header: Text("Club Water Polo")) {
                    Button(action: shareClubExport) {
                        ExportRow(
                            icon: "arrow.up.doc.fill",
                            title: "Club Export JSON",
                            subtitle: "For club water polo systems",
                            color: .orange
                        )
                    }
                }
                
                // CSV Export
                Section(header: Text("Data Export")) {
                    Button(action: exportCSV) {
                        ExportRow(
                            icon: "tablecells.fill",
                            title: "CSV Spreadsheet",
                            subtitle: "Import into Excel or Sheets",
                            color: .purple
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Export Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("JSON copied to clipboard")
            }
        }
    }
    
    private func shareTextSummary() {
        let text = ExportManager.shared.generateTextSummary(game: game)
        shareItems = [text]
        showShareSheet = true
    }
    
    private func sharePDF() {
        guard let pdfData = ExportManager.shared.generatePDF(game: game) else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.homeTeam.name)_vs_\(game.awayTeam.name).pdf")
        try? pdfData.write(to: tempURL)
        
        shareItems = [tempURL]
        showShareSheet = true
    }
    
    private func shareMaxPrepsJSON() {
        guard let jsonData = ExportManager.shared.generateMaxPrepsJSON(game: game) else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.homeTeam.name)_vs_\(game.awayTeam.name)_maxpreps.json")
        try? jsonData.write(to: tempURL)
        
        shareItems = [tempURL]
        showShareSheet = true
    }
    
    private func copyMaxPrepsJSON() {
        guard let jsonData = ExportManager.shared.generateMaxPrepsJSON(game: game),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        UIPasteboard.general.string = jsonString
        showCopiedAlert = true
    }
    
    private func shareClubExport() {
        guard let jsonData = ExportManager.shared.generateClubExport(game: game) else { return }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.homeTeam.name)_vs_\(game.awayTeam.name)_club.json")
        try? jsonData.write(to: tempURL)
        
        shareItems = [tempURL]
        showShareSheet = true
    }
    
    private func exportCSV() {
        let csv = generateCSV()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(game.homeTeam.name)_vs_\(game.awayTeam.name).csv")
        try? csv.write(to: tempURL, atomically: true, encoding: .utf8)
        
        shareItems = [tempURL]
        showShareSheet = true
    }
    
    private func generateCSV() -> String {
        var lines: [String] = []
        lines.append("Team,Player #,Player Name,Goals,Assists,Steals,Exclusions,Sprints Won,Sprints Lost")
        
        for player in game.homeTeam.players {
            lines.append("\(game.homeTeam.name),\(player.number),\(player.name),\(player.goals),\(player.assists),\(player.steals),\(player.exclusions),\(player.sprintsWon),\(player.sprintsLost)")
        }
        
        for player in game.awayTeam.players {
            lines.append("\(game.awayTeam.name),\(player.number),\(player.name),\(player.goals),\(player.assists),\(player.steals),\(player.exclusions),\(player.sprintsWon),\(player.sprintsLost)")
        }
        
        return lines.joined(separator: "\n")
    }
}

struct ExportRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct ExportSheetView_Previews: PreviewProvider {
    static var previews: some View {
        let homeTeam = GameTeam(
            name: "Clayton Valley",
            players: [
                GamePlayer(number: 1, name: "Ian Meyer", isInGame: true, isGoalie: true, goals: 0),
                GamePlayer(number: 4, name: "Alex Chen", isInGame: true, goals: 3),
                GamePlayer(number: 7, name: "Jordan Smith", isInGame: true, goals: 2)
            ],
            isHomeTeam: true
        )
        
        let awayTeam = GameTeam(
            name: "De La Salle",
            players: [
                GamePlayer(number: 1, name: "Sam Wilson", isInGame: true, isGoalie: true, goals: 0),
                GamePlayer(number: 5, name: "Chris Davis", isInGame: true, goals: 2)
            ],
            isHomeTeam: false
        )
        
        let game = GameSession(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: 4,
            gameClock: 0,
            shotClock: 0,
            homeScore: 12,
            awayScore: 8,
            isGameActive: false,
            isPeriodActive: false
        )
        
        ExportSheetView(game: game)
    }
}
