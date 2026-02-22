# WaterPolo Stats - Simple Mode v2 Requirements

## Updated Simple Mode Layout

### Horizontal/Landscape Layout (Primary)
```
┌─────────────────────────────────────────────────────────────────┐
│  HOME          SCOREBOARD           AWAY                        │
│  ┌─────┐      ┌─────────────┐      ┌─────┐                     │
│  │Team │      │   12 - 8    │      │Team │                     │
│  │Name │      │   Q3 5:42   │      │Name │                     │
│  │     │      │   Shot: 12  │      │     │                     │
│  └─────┘      │ [⏸] [←] [→]│      └─────┘                     │
│               └─────────────┘                                   │
├─────────────────────────────────────────────────────────────────┤
│  [GOAL]  [ASSIST]  [EXCLUSION]  [PENALTY]  [TIMEOUT]  [STEAL]   │
├─────────────────────────────────────────────────────────────────┤
│  ACTION HISTORY (Scrollable)                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Q3 5:42 | Goal #4 Ian (Assist #7 Alex) Field Goal      │ ✏️ │
│  │ Q3 4:15 | Exclusion #8 Mike (20s)                      │ ✏️ │
│  │ Q3 3:30 | Penalty #12 Tom (5M Shot Awarded)            │ ✏️ │
│  │ Q2 6:20 | Goal #7 Alex (5M Penalty Shot)               │ ✏️ │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Basic vs Advanced Scoring Toggle
- **Top of screen**: Toggle switch "Basic / Advanced"
- **Can switch mid-game** - stats are preserved
- **Basic shows**: Goals, Exclusions, Penalties, Timeouts
- **Advanced adds**: Assists, Steals, 5M Drawn, Shot Type

## Action Types

### Goals
- **Field Goal** (default)
- **5M Penalty Shot** (swipe or long press to select)
- **Tracks**: Scorer, Assister (if applicable)

### Exclusions vs Penalties
| Type | Effect | Power Play | Player Foul Count |
|------|--------|------------|-------------------|
| **Exclusion** | Player out 20s | Yes - 6v5 | +1 foul |
| **Penalty** | 5M shot awarded | No - stays 6v6 | +1 foul |

### Other Actions
- **Assist** - Track who passed for goal
- **Steal** - Defensive takeaway
- **5M Drawn** - Offensive player draws penalty
- **Timeout** - Team timeout
- **Block** - Goalie block (Advanced)
- **Turnover** - Lost possession (Advanced)

## Action History / Scorebook

### Display
- Scrollable list at bottom
- Most recent at top
- Shows: Period | Time | Action | Player | Details

### Edit Mode
- Tap any row → Edit sheet opens
- Can change:
  - Time (adjust minutes/seconds)
  - Player cap number
  - Action type (Goal ↔ Penalty Shot)
  - Add/remove assist
  - Delete action

## Thumb-Friendly Layout

### Button Placement (Landscape)
```
┌─────────────────────────────────────────────────────────────┐
│  [HOME TEAM]        [SCORE]         [AWAY TEAM]            │
│                      [CLOCK]                                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │  GOAL   │  │ EXCLUSION│  │ PENALTY │  │ TIMEOUT │      │
│  │  (Left  │  │  (Left  │  │ (Right) │  │ (Right) │      │
│  │  Thumb) │  │  Thumb) │  │         │  │         │      │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
│                                                             │
│  [ACTION HISTORY SCROLLS HERE]                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Model Updates

### GameAction (New)
```swift
struct GameAction: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let period: Int
    let gameTime: TimeInterval
    let actionType: ActionType
    let team: TeamType
    let playerNumber: Int
    let secondaryPlayerNumber: Int? // For assists
    let details: ActionDetails
    
    enum ActionType: String, Codable {
        case goal, exclusion, penalty, timeout, steal, assist
        case fiveMeterDrawn, block, turnover
    }
    
    struct ActionDetails: Codable {
        let isFiveMeterShot: Bool? // For goals
        let exclusionDuration: Int? // 20 or null
        let isPenaltyFoul: Bool? // true = 5M shot, false = exclusion
    }
}
```

## Implementation Priority

1. **Horizontal Layout** - Redesign for landscape
2. **Action History List** - Bottom scrollable list
3. **Edit Action Sheet** - Tap to edit any action
4. **Basic/Advanced Toggle** - Top toggle switch
5. **Penalty vs Exclusion** - Distinguish in UI
6. **Goal Types** - Field goal vs 5M shot
7. **Assists** - Track secondary player
8. **Advanced Stats** - Steals, 5M drawn, etc.

## Testing Checklist

- [ ] Horizontal layout works on iPhone
- [ ] Horizontal layout works on iPad
- [ ] All buttons reachable by thumbs
- [ ] Action history scrolls smoothly
- [ ] Tap to edit works
- [ ] Can change time on actions
- [ ] Can change player on actions
- [ ] Basic/Advanced toggle works mid-game
- [ ] Penalty vs Exclusion tracked correctly
- [ ] Goal types (field vs 5M) recorded
- [ ] Assists tracked and displayed
