import SwiftUI
import CoreData

// MARK: - Season List View

struct SeasonListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Season.startDate, ascending: false)],
        animation: .default)
    private var seasons: FetchedResults<Season>
    
    @State private var showAddSeason = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(seasons) { season in
                    NavigationLink(destination: SeasonDetailView(season: season)) {
                        SeasonRow(season: season)
                    }
                }
                .onDelete(perform: deleteSeasons)
            }
            .navigationTitle("Seasons")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSeason = true }) {
                        Label("Add Season", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSeason) {
                AddSeasonView()
            }
            .overlay {
                if seasons.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Seasons Yet",
                        message: "Create a season to start organizing your games",
                        buttonTitle: "Create Season",
                        buttonAction: { showAddSeason = true }
                    )
                }
            }
        }
    }
    
    private func deleteSeasons(offsets: IndexSet) {
        withAnimation {
            offsets.map { seasons[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

// MARK: - Season Row

struct SeasonRow: View {
    let season: Season
    
    private var games: [Game] { season.gamesArray }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(season.displayLabel)
                    .font(.headline)
                
                Spacer()
                
                Text("\(games.count) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !games.isEmpty {
                Text("\(games.count) games played")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Season Detail View

struct SeasonDetailView: View {
    let season: Season
    
    var body: some View {
        List {
            Section(header: Text("Games")) {
                ForEach(season.gamesArray) { game in
                    NavigationLink(destination: SavedGameDetailView(game: game)) {
                        Text("\(game.homeTeamName) vs \(game.awayTeamName)")
                    }
                }
            }
        }
        .navigationTitle(season.displayLabel)
    }
}

// MARK: - Add Season View

struct AddSeasonView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var year = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Season Year"),
                        footer: Text("Water polo season runs Aug 1 - Jul 31. Select the year the season starts.")) {
                    Picker("Year", selection: $year) {
                        ForEach((2020...2030).reversed(), id: \.self) { y in
                            Text("\(y)-\(String(y + 1).suffix(2))").tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section {
                    Button("Create Season") {
                        let season = Season(context: viewContext)
                        season.id = UUID()
                        season.year = Int16(year)
                        
                        let dates = Season.makeDates(year: year)
                        season.startDate = dates.start
                        season.endDate = dates.end
                        season.isActive = true
                        
                        try? viewContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("New Season")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct SeasonListView_Previews: PreviewProvider {
    static var previews: some View {
        SeasonListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
