# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build for simulator
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a single test class
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"WaterPolo StatsTests/WaterPolo_StatsTests" test
```

Primary development is through Xcode (`open "WaterPolo Stats.xcodeproj"`). Only files under `WaterPolo Stats/` are compiled — any `windsurf-project/` folder is a reference prototype and not part of the active target.

## Architecture

### Dual-Model Pattern

The app runs two parallel model systems:

| Concern | In-Memory Struct | Core Data Entity |
|---------|-----------------|-----------------|
| Game | `GameSession` | `Game` |
| Team | `GameTeam` | `Team` |
| Player | `GamePlayer` | `Player` |
| Event | `GameEventRecord` | `GameEvent` |

Structs are used during live gameplay (timers fire at 0.1s intervals — mutations must be fast). Core Data is written only on save via `GameSession.saveToCoreData()` in `Models/GameConversion.swift`.

### Navigation

`ContentView` is a `TabView`:
- **Tab 0 (Games)** — `GameListView`: historical Core Data games
- **Tab 1 (Score)** — `SimpleGameView`: default tab, outdoor-optimized live scoring
- **Tab 2 (Full Stats)** — `GameView` in a `NavigationView`, receives `GameViewModel` as `@EnvironmentObject` from `SimpleGameView`
- **Tab 3 (Teams)** — `TeamListView`: Core Data team management

### Key Files

- `Models/GameStruct.swift` — All in-memory types: `GameSession`, `GameTeam`, `GamePlayer`, `GameEventRecord`, `GameRosterEntry`, plus export structs (`MaxPrepsExport`, `ClubWaterPoloExport`)
- `ViewModels/GameViewModel.swift` — All game logic: timer, scoring, event recording, photo auto-tagging (within 5s of player action), save/export
- `Views/SimpleGameView.swift` — Primary scoring UI; also defines `GameActionType`, `GameActionRecord`, and all supporting sub-views
- `Views/SunlightMode.swift` — Brightness detection + `\.isSunlightMode` environment key
- `Persistence.swift` — `PersistenceController` singleton; uses `NSPersistentCloudKitContainer` named `"WaterPoloScorekeeper"` (not `WaterPolo_Stats`)
- `Models/GameConversion.swift` — `GameSession` extensions for Core Data round-trip

### Sunlight Mode

`SunlightMode.swift` defines an `\.isSunlightMode` environment value. Auto-detection fires when screen brightness exceeds 0.8; `SimpleGameView` also has a `manualSunlightMode` override. High-contrast mode uses pure black/white with 72pt scores and 48pt clock — required for outdoor poolside use with wet hands.

### Foul Tracking

Players foul out at 3 total fouls (`exclusions + penaltiesDrawn >= 3`). Both `recordExclusion` and `recordPenalty` in `GameViewModel` increment `player.exclusions`; `recordExclusionDrawn`/`recordPenaltyDrawn` increment the drawn counters. Foul-out fires a `.foulOut` event and sets `player.isFouledOut = true`.

## Domain Knowledge

**Cap numbers are per-game, not per-player.** The same player can be #5 in white caps and #11 in dark caps across games. `GameRosterEntry` links a player UUID to a cap number for one game.

**Mid-game cap swaps are valid.** A goalie starts as #1 and may move to field with a different cap — the same player appears twice in the game roster with different `GameRosterEntry` records (`rosterOrder > 1` for swaps).

**Multiple games can be active simultaneously.** A morning tournament game can be paused, a second game scored, then the first resumed. `GameStatus` is `.inProgress`, `.paused`, or `.completed`.

**Water polo year starts August 1.** Teams archive on Aug 1; players persist by UUID until age 19+.

## Target Requirements

- iOS 15.0+, Swift 5.5+, Xcode 13+
- Primary device: iPhone (portrait + landscape), secondary: iPad
- Outdoor-first design: high contrast and thumb-sized touch targets are hard requirements

## Extended Documentation

Deeper context lives in `.ai/`:
- `DOMAIN_KNOWLEDGE.md` — Water polo rules, edge cases, 680 Club specifics
- `PRODUCT_SPEC_V2.md` — Feature requirements and acceptance criteria
- `SIMPLE_MODE_V2_SPEC.md` — Detailed outdoor scoring UI spec
- `PRODUCT_ROADMAP.md` — Phase breakdown
