# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is an Xcode/SwiftUI project for iOS. Build and test via the command line:

```bash
# Build for simulator
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"WaterPolo StatsTests/WaterPolo_StatsTests" test
```

The primary development flow is through Xcode (open `WaterPolo Stats.xcodeproj`). The `windsurf-project/` folder is a reference/prototype and is NOT part of the active Xcode target — only files under `WaterPolo Stats/` are compiled.

## Architecture

### Dual-Model Pattern

The app uses two parallel model systems that serve different roles:

| Concept | In-Memory Struct (Active Gameplay) | Core Data Entity (Persistence) |
|---------|-----------------------------------|-------------------------------|
| Game | `GameSession` | `Game` |
| Team | `GameTeam` | `Team` |
| Player | `GamePlayer` | `Player` |
| Event | `GameEventRecord` | `GameEvent` |

**Why two models?** Structs are fast and mutable for real-time scoring (timers firing at 0.1s intervals). Core Data is used only when saving completed games for historical records.

The conversion layer lives in `Models/GameConversion.swift` — `GameSession.saveToCoreData()` writes the struct data to Core Data, and `GameSession.fromTeams()` initializes a new game session from saved Core Data teams.

### Data Flow

```
GameViewModel (ObservableObject)
    └── GameSession (struct) ← all real-time scoring, timers, events
         └── saveToCoreData() → Core Data when game ends
```

`GameViewModel` owns the timer (0.1s intervals via `Timer`), all game actions (goals, exclusions, etc.), and the `lastPlayerAction` for photo auto-tagging within 5 seconds.

### Navigation Structure

`ContentView` is a `TabView` with 4 tabs:
- **Tab 0 (Games)** — `GameListView`: historical Core Data games
- **Tab 1 (Score)** — `SimpleGameView`: default tab, outdoor-optimized live scoring
- **Tab 2 (Full Stats)** — `GameView` inside `NavigationView`: detailed stats view, receives `GameViewModel` as `environmentObject` from SimpleGameView
- **Tab 3 (Teams)** — `TeamListView`: Core Data team management

### Key Files

- `Models/GameStruct.swift` — All in-memory types: `GameSession`, `GameTeam`, `GamePlayer`, `GameEventRecord`, `GameActionRecord`, export structs (`MaxPrepsExport`, `ClubWaterPoloExport`)
- `ViewModels/GameViewModel.swift` — All game logic: timer, scoring, event recording, export, save
- `Views/SimpleGameView.swift` — Primary scoring UI; also defines `GameActionType`, `GameActionRecord`, and all supporting views (`ActionHistoryRow`, `PlayerRow`, `ActionPlayerPickerSheet`, `EditActionSheet`, `ImagePicker`, etc.)
- `Views/SunlightMode.swift` — Brightness detection + `\.isSunlightMode` environment key
- `Persistence.swift` — `PersistenceController` (singleton + preview); uses `NSPersistentCloudKitContainer` named `"WaterPoloScorekeeper"`
- `Models/GameConversion.swift` — `GameSession` extensions for Core Data round-trip

### Core Data Model

The `.xcdatamodeld` is named `WaterPoloScorekeeper` (not `WaterPolo_Stats`). Four entities: `Game`, `Team`, `Player`, `GameEvent`. The old Xcode-generated `WaterPolo_Stats.xcdatamodeld` has been deleted.

### Sunlight Mode

`SunlightMode.swift` defines an `\.isSunlightMode` environment value. Views read `@Environment(\.isSunlightMode)` to switch between high-contrast (pure black/white, larger fonts) and normal styling. `SimpleGameView` also has a local `manualSunlightMode` toggle that overrides auto-detection.

### Foul Tracking

Players foul out at 3 total fouls (`exclusions + penaltiesDrawn >= 3`). `GameViewModel.recordExclusion` and `recordPenalty` both increment `player.exclusions`; `recordExclusionDrawn` and `recordPenaltyDrawn` increment `player.exclusionsDrawn`/`penaltiesDrawn`. Foul-out fires a `foulOut` event and sets `player.isFouledOut = true`.

## Target Requirements

- iOS 15.0+, Swift 5.5+, Xcode 13+
- Primary device: iPhone (portrait + landscape), secondary: iPad
- Designed for outdoor use in bright sunlight — high contrast and large touch targets are requirements, not nice-to-haves
