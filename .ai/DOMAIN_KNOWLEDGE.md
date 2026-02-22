# WaterPolo Stats - Domain Knowledge & Data Model Requirements

## Critical Context from Neal (2026-02-21)

### 1. Club Structure (680 Club Example)
- **Team naming**: Colors (Red, Blue, White), not just A/B/C levels
- **Other clubs**: May use A/B/C or colors from their logos
- **Example**: Ian plays for "680 Club, 16U B - Level, Team Name: Red"

### 2. Cap Number Flexibility (CRITICAL)

#### Cap Numbers Change Frequently:
- Between games
- Between tournaments  
- Between home/away (same tournament)
- **Example**: Kyle is #5 when Away (white), #11 when Home (dark) because the #5 dark cap was broken

#### Mid-Game Cap Swaps:
- Goalie starts as #1 or #1A
- When moving to field, gets a different cap number
- Same player, different number within one game

### 3. Data Model Implication: Persistent Player ID

```
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────┐
│     PLAYER      │◄────►│   GAME_ROSTER       │◄────►│      GAME       │
│  (Persistent)   │      │ (Game-specific)     │      │                 │
├─────────────────┤      ├─────────────────────┤      ├─────────────────┤
│ playerId (UUID) │      │ rosterEntryId       │      │ gameId          │
│ name            │      │ gameId              │      │ date            │
│ dateOfBirth     │◄────►│ playerId            │      │ opponent        │
│ profilePhoto    │      │ capNumber           │      │ isHome          │
│ (NSCA Profile)  │      │ teamColor           │      │ status          │
│                 │      │ isGoalie            │      │                 │
└─────────────────┘      └─────────────────────┘      └─────────────────┘
```

**Key insight**: Player is persistent. Cap number is per-game (per-roster-entry).

### 4. Water Polo Calendar

#### Year Start: August 1
- Age ups happen on Aug 1 (USA Water Polo rules)
- Old team assignments **archive** on Aug 1
- Player remains active until 19+

#### Season Structure:
| Level | Season | Notes |
|-------|--------|-------|
| Boys HS | Fall | |
| Girls HS | Fall OR Winter | Varies by region |
| Club | Non-HS seasons | Fall, Winter, Spring, Summer |
| Younger players (U14) | 4 sessions | Fall, Winter, Spring, Summer |

### 5. Concurrent Games

**Use Case**: Tournament mornings
- Morning game gets paused (not finished)
- Start scoring afternoon game
- Later: resume morning game, finish scoring from video/paper stats

**Requirements**:
- Multiple games can be "in progress" simultaneously
- Game status: `in_progress`, `paused`, `completed`
- Paused games show in GameList but marked as incomplete
- Can resume scoring from where left off

### 6. Stats Rollup for Recruiting

**NSCA Profile**: Player stats roll up across:
- All teams (HS, Club)
- All seasons
- All years (until age 19+)

**Internal Team Records**: Separate rankings within specific team/season

## Updated Data Model

### New Entity: GameRoster
```swift
struct GameRoster {
    let id: UUID
    let gameId: UUID
    let playerId: UUID
    let capNumber: Int
    let teamColor: String  // "Red", "Blue", etc.
    let isGoalie: Bool
    let isHomeTeam: Bool
    
    // A player can appear twice in same game (mid-game swap)
    // Ex: Ian starts as goalie #1, moves to field #7
    let rosterOrder: Int  // 1, 2, 3... if same player has multiple entries
}
```

### Updated: Game
```swift
struct GameSession {
    let id: UUID
    let date: Date
    let opponent: String
    let isHome: Bool
    let teamColor: String  // "Red", "Blue", etc.
    let level: String      // "16U B"
    let club: String       // "680 Club"
    
    var status: GameStatus  // .inProgress, .paused, .completed
    var currentPeriod: Int
    var gameTime: TimeInterval
    var homeScore: Int
    var awayScore: Int
    
    var homeRoster: [GameRoster]
    var awayRoster: [GameRoster]
    var events: [GameEventRecord]
}

enum GameStatus: String, Codable {
    case inProgress = "in_progress"
    case paused = "paused"
    case completed = "completed"
}
```

### Updated: Player
```swift
struct Player {
    let id: UUID
    let name: String
    let dateOfBirth: Date?
    let profilePhoto: Data?
    let nscaId: String?  // For recruiting profile linking
    
    // Computed: All roster entries across all games
    // var careerStats: CareerStats { ... }
}
```

## UI Implications

### Game Setup Flow
1. Select/Create Game
2. Select Team (e.g., "680 Club 16U B Red")
3. Assign Players to Cap Numbers for THIS game
4. Allow "add player" from existing roster or create new
5. Allow duplicate players with different cap numbers (goalie swap scenario)

### Game List
```
┌─────────────────────────────────────┐
│ IN PROGRESS (2)                     │
│ • vs De La Salle (Paused)  Q3 5:42 │
│ • vs Miramonte (Active)    Q1 2:15 │
├─────────────────────────────────────┤
│ COMPLETED                           │
│ • vs Acalanes  ✅  12-8  (Feb 20)  │
└─────────────────────────────────────┘
```

### Player Stats View
```
┌─────────────────────────────────────┐
│ Ian Meyer - Career Stats            │
│ 680 Club 16U B Red | Clayton Valley │
├─────────────────────────────────────┤
│ 2025-26 Season (Age 16)             │
│ Games: 12 | Goals: 24 | Assists: 8  │
├─────────────────────────────────────┤
│ By Team:                            │
│ • 680 Red: 8 games, 18 goals        │
│ • CVHS: 4 games, 6 goals            │
├─────────────────────────────────────┤
│ Game History                        │
│ [List with cap numbers per game]    │
│ vs De La Salle - #7 - 3G 1A         │
│ vs Miramonte - #11 - 2G 2A          │
└─────────────────────────────────────┘
```

## Implementation Priority

### Phase 2 Updates (Team Management)
1. **Add GameRoster entity** - Link Player to Game with cap number
2. **Update GameSetup flow** - Assign cap numbers per game
3. **Handle mid-game swaps** - Allow same player, different cap
4. **Game status tracking** - in_progress/paused/completed
5. **Concurrent games** - Multiple active games in list

### Phase 2.5 (Calendar Awareness)
1. **Water polo year** - Aug 1 start date
2. **Auto-archive** teams on Aug 1
3. **Season tracking** - Fall HS, Winter Club, etc.
4. **Age calculation** - Based on Aug 1 cutoff

### Phase 3 (Recruiting Profile)
1. **Career stats rollup** - Across all teams/seasons
2. **NSCA export** - Profile format
3. **Team vs Career toggle** - View stats by context

## Notes
- Cap numbers are game-specific, not player-specific
- Same player can have multiple cap numbers in one game (goalie swap)
- Player identity is persistent across years
- Teams archive Aug 1, players stay active
- Multiple games can be active (paused) simultaneously
