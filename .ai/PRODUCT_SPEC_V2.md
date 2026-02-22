# WaterPolo Stats - Product Specification v2.0

## Executive Summary

**Target User**: Neal (parent/stat keeper), not Ian (player)  
**Environment**: Outdoor pools, full summer sun, bright light  
**Primary Use**: Real-time game tracking with quick, easy controls

---

## Core Use Cases

### 1. Game Day Scoring (Primary)
**Scenario**: Neal is at Ian's game, sitting in the stands with iPad/iPhone

**Needs**:
- Start tracking quickly (minimal setup)
- See screen in bright sunlight (high contrast, large fonts)
- Pause/rollback clock frequently (refs stop clock often)
- Quick stat entry (goals, exclusions, timeouts)
- Take photos of key moments

### 2. Post-Game Export
**Scenario**: Game ended, want to share stats with other parents

**Needs**:
- Export to MaxPreps format
- Share via text/email
- Include photos in report
- Quick summary (score, key players)

### 3. Season Tracking
**Scenario**: Track Ian's progress over the season

**Needs**:
- View all games for the season
- Career stats (total goals, exclusions, etc.)
- Compare games
- Import games tracked on paper
- Download MaxPreps data

---

## Two-Mode Design

### Mode 1: Simple Scoring (Default)
**For**: Quick tally during active gameplay

**Screen Layout**:
```
┌─────────────────────────────────────┐
│  HOME 12        3rd        8 AWAY  │  ← Large score, period
├─────────────────────────────────────┤
│  ⏸️  5:42    🔴  12.3              │  ← Game clock, shot clock
├─────────────────────────────────────┤
│  [GOAL]  [EXCLUSION]  [TIMEOUT]    │  ← Big action buttons
├─────────────────────────────────────┤
│  Home Roster (scrollable)           │
│  #4 Ian - 2G 1E    [+G] [+E]       │  ← Quick player actions
│  #7 Alex - 1G 2E    [+G] [+E]       │
└─────────────────────────────────────┘
```

**Features**:
- Large, high-contrast UI for outdoor visibility
- One-tap stat entry
- Clock controls always visible (pause, +1 sec, -1 sec)
- Running tally only (no detailed event log)
- Photo button for quick camera access

### Mode 2: Full Stats (Switch to after each quarter)
**For**: Detailed stats entry, review, corrections

**Screen Layout**:
```
┌─────────────────────────────────────┐
│  Full Stats Mode          [Simple] │  ← Mode toggle
├─────────────────────────────────────┤
│  Q1  Q2  Q3  Q4  [Final]           │  ← Quarter selector
├─────────────────────────────────────┤
│  Player Stats Table                 │
│  Name    G   A   E   S   TO         │
│  Ian     2   1   0   3   1         │
│  Alex    1   0   1   2   0         │
├─────────────────────────────────────┤
│  [Edit Event Log]  [Export]         │
│  [Add Correction]  [Photos]         │
└─────────────────────────────────────┘
```

**Features**:
- Quarter-by-quarter breakdown
- Detailed event log with timestamps
- Ability to edit/correct entries
- Full player stats (goals, assists, exclusions, steals, timeouts)
- Photo gallery for the game

---

## Design Requirements

### Visual Design (High Priority)

#### Light Mode (Default for outdoor)
- **Background**: White (#FFFFFF) or very light gray
- **Text**: Black (#000000) - maximum contrast
- **Accent**: Bright red for clock, blue for home, dark blue for away
- **Score**: Minimum 72pt font
- **Clock**: Minimum 48pt font
- **Buttons**: Large touch targets (min 60x60pt)

#### Dark Mode (For indoor evening games)
- **Background**: True black (#000000) for OLED
- **Text**: White (#FFFFFF)
- **Same accent colors**

#### Outdoor/Sunlight Mode (Special)
- Extreme contrast mode
- Black and white only
- Even larger fonts
- Simplified layout (hide non-essential UI)

### Clock Controls (Critical)

The game clock needs these controls ALWAYS VISIBLE:

```
[◀️ -1s] [⏸️ Pause] [▶️ Resume] [+1s ▶️]
```

**Clock Features**:
- Tap clock to edit time directly
- Swipe left/right to adjust by 1 second
- Double-tap to pause/resume
- Visual indicator when clock is running (green) vs paused (red)

### Quick Actions

**Simple Mode Bottom Sheet** (swipe up):
```
┌─────────────────────────────────────┐
│  ⚡ QUICK ACTIONS                   │
├─────────────────────────────────────┤
│  [📷 Take Photo]  [🔄 Sync Clock]   │
│  [📝 Add Note]    [⚠️ Flag Play]    │
│  [🏃 Substitution]                  │
└─────────────────────────────────────┘
```

---

## Photo Integration

### Camera Access
- Floating photo button (bottom right corner)
- Quick tap takes photo, saves to Photos app
- Long press opens camera preview

### Photo Metadata
- Auto-tag with game, period, timestamp
- Optional: Tag player if photo taken right after player action

### Photo Usage
1. **Save to Photos**: Always happens
2. **Attach to Game**: Optional, selected photos appear in game report
3. **Share**: Export with game stats

---

## Data Model Updates

### GameSession Additions
```swift
struct GameSession {
    // Existing fields...
    
    // NEW: Quarter-by-quarter tracking
    var quarterStats: [QuarterStats]  // Index 0 = Q1, etc.
    
    // NEW: Photos
    var photos: [GamePhoto]
    
    // NEW: Clock history for corrections
    var clockEvents: [ClockEvent]
}

struct QuarterStats {
    let quarter: Int
    var homeScore: Int
    var awayScore: Int
    var playerStats: [PlayerQuarterStats]
}

struct GamePhoto {
    let id: UUID
    let localIdentifier: String  // Photos library reference
    let timestamp: Date
    let period: Int
    let playerNumber: Int?  // Optional: associated player
    let caption: String?
}

struct ClockEvent {
    let timestamp: Date
    let type: ClockEventType  // .started, .paused, .adjusted, .periodEnd
    let gameTime: TimeInterval
}
```

---

## Season/Historical Features

### Team Season View
```
┌─────────────────────────────────────┐
│  Clayton Valley 2025 Season         │
├─────────────────────────────────────┤
│  Record: 8-4-1  |  4th in League    │
├─────────────────────────────────────┤
│  [Schedule]  [Roster]  [Stats]      │
├─────────────────────────────────────┤
│  Recent Games                       │
│  ✅ Win vs De La Salle  12-8        │
│  ❌ Loss vs Miramonte   9-11        │
│  ✅ Win vs Acalanes     15-7        │
├─────────────────────────────────────┤
│  [➕ Add Game]  [📥 Import]         │
└─────────────────────────────────────┘
```

### Manual Import
- Add game from paper stats
- Form: Date, Opponent, Score, Player Stats
- Auto-calculate totals

### MaxPreps Integration
- Download existing games
- Upload new games
- Sync player rosters

---

## Export Formats

### 1. Parent Share (Text/Message)
```
Clayton Valley 12, De La Salle 8 (Final)

Top Performers:
• Ian Meyer: 4 goals, 2 steals
• Alex Chen: 3 goals, 1 assist

Full stats: [link]
```

### 2. MaxPreps Export (JSON)
Existing format, enhanced with photos

### 3. PDF Report
- Game summary
- Player stats table
- Embedded photos
- Shareable

---

## Revised Phase Plan

### Phase 1.5: Outdoor-Ready Simple Scorer (NEW)
**Goal**: Basic scoring that works in bright sun

- [ ] Simple mode UI (large fonts, high contrast)
- [ ] Clock controls (pause, +/- 1 sec)
- [ ] Basic stats (goals, exclusions, timeouts)
- [ ] Photo capture
- [ ] Light/Dark mode toggle
- [ ] Sunlight mode (extreme contrast)

### Phase 2: Full Stats & Season
**Goal**: Complete tracking and historical view

- [ ] Full stats mode
- [ ] Quarter-by-quarter tracking
- [ ] Season view
- [ ] Manual game import
- [ ] MaxPreps integration

### Phase 3: Sharing & Export
**Goal**: Share with other parents

- [ ] PDF export
- [ ] Parent-friendly text export
- [ ] Photo inclusion in exports
- [ ] Team sharing (multiple parents)

---

## Design Decisions (Locked)

### Device Strategy
- **Primary**: iPhone (most users have in pocket)
- **Secondary**: iPad Pro version (Neal can bring if faster)
- **Requirement**: No standard keyboards during gameplay - must be quick-tap only

### Sunlight Mode
- **Default**: Auto-detect brightness
- **Settings**: Manual override always available
- **Trigger**: Brightness > 80% = auto-enable sunlight mode

### Clock Strategy
- **Mode**: Run independently
- **Reason**: Ref clock is closed system
- **Controls**: Always visible pause/adjust

### Photo Tagging
- **Mode**: Auto-tag enabled
- **Logic**: Photo taken within 5 seconds of player action = auto-tag that player
- **Fallback**: Manual tagging available

### Multi-User Workflow
- **Scenario**: Multiple parents tracking different stats
  - Parent A: Goals, Assists
  - Parent B: Fouls, Timeouts, Clock
- **Sync**: Real-time collaboration (optional Phase 3)
- **Export**: PDF to GroupMe, WhatsApp, etc.

---

## UI Patterns for Speed

### No Keyboards During Game
- All inputs: Pickers, buttons, swipe gestures
- Clock adjustment: Tap to edit, +/- buttons, swipe
- Player selection: Tap jersey number (not name entry)

### iPhone Layout
```
Screen split:
┌────────────────┐
│ SCORE  | CLOCK │  ← 30% of screen
├────────────────┤
│ ACTION BUTTONS │  ← 20% of screen
├────────────────┤
│ PLAYER ROSTER  │  ← 40% of screen
├────────────────┤
│ [📷] Controls  │  ← 10% of screen
└────────────────┘
```

### iPad Layout
```
Landscape split:
┌──────────┬──────────┐
│  HOME    │   AWAY   │  ← Teams side-by-side
│  SCORE   │  SCORE   │
│  PLAYERS │  PLAYERS │
├──────────┴──────────┤
│   CLOCK & CONTROLS  │  ← Center bottom
└─────────────────────┘
```

---

## Immediate Next Steps

1. **iPhone Simple Mode**: Primary target, outdoor-optimized
2. **Sunlight Auto-Mode**: Brightness detection
3. **Quick Clock Controls**: Always visible, no keyboards
4. **Floating Photo Button**: Auto-tag enabled
5. **iPad Layout**: Side-by-side team view

---

*Document Version: 2.1*
*Decisions Locked: February 20, 2026*  
*Last Updated: February 20, 2026*  
*Target: Phase 1.5 completion before season starts*
