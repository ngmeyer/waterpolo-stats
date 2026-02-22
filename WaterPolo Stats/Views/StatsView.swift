import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.date, ascending: false)],
        animation: .default)
    private var games: FetchedResults<Game>
    
    var body: some View {
        NavigationView {
            VStack {
                if games.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text("No Games Yet")
                            .font(.headline)
                        
                        Text("Game statistics will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        Section(header: Text("Game Summary")) {
                            HStack {
                                Text("Total Games")
                                Spacer()
                                Text("\(games.count)")
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Section(header: Text("Recent Games")) {
                            ForEach(games.prefix(10)) { game in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(game.homeTeamName)
                                        Spacer()
                                        Text("vs")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(game.awayTeamName)
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    
                                    if let date = game.wrappedDate as Date? {
                                        Text(date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
