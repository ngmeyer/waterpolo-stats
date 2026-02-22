# WaterPolo Stats - Product Roadmap

## Architecture Overview

### Dual-Model Design Pattern

The app uses a **dual-model architecture** optimized for real-time sports scoring:

```
┌─────────────────────────────────────────────────────────────────┐
│                     ACTIVE GAMEPLAY                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │ GameSession │───▶│  GameTeam   │───▶│ GamePlayer  │          │
│  │  (Struct)   │    │  (Struct)   │    │  (Struct)   │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
│         │                                                    │
│         │ Fast, mutable, in-memory                          │
│         │ No Core Data overhead                             │
│         ▼                                                    │
│  ┌─────────────────────────────────────┐                     │
│  │      GameViewModel                  │                     │
│  │  - Real-time timer                  │                     │
│  │  - Score tracking                   │                     │
│  │  - Event recording                  │                     │
│  └─────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Game Ends
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PERSISTENCE LAYER                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐          │
│  │    Game     │───▶│    Team     │───▶│   Player    │          │
│  │(Core Data)  │    │(Core Data)  │    │(Core Data)  │          │
│  └─────────────┘    └─────────────┘    └─────────────┘          │
│         │                                                    │
│         │ Event-sourced persistence                          │
│         │ Queryable, syncable, historical                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────┐                     │
│  │      GameListView / StatsView       │                     │
│  │  - Historical data                  │
│  │  - Career stats                     │
│  │  - Team management                  │\n│  └─────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

### Why Two Models?

| Aspect | Structs (Active) | Core Data (Historical) |
|--------|-----------------|------------------------|
| **Performance** | No context overhead | Fetch/save overhead |
| **Mutability** | Direct property changes | Context + save required |
| **Threading** | Simple @MainActor | Context threading rules |
| **Persistence** | Memory only | Disk + CloudKit |
| **Querying** | Linear search | NSPredicate, sorting |
| **Sync** | Manual (WebSocket ready) | CloudKit |

### Type Reference

| Concept | Struct (Active) | Core Data (Persistence) |
|---------|-----------------|-------------------------|
| Game | `GameSession` | `Game` |
| Team | `GameTeam` | `Team` |
| Player | `GamePlayer` | `Player` |
| Event | `GameEventRecord` | `GameEvent` |

---

## ✅ Phase 1: Foundation (COMPLETE - Feb 20, 2026)

**Goal:** Fix architecture boundaries, stable build, basic scoring

### 1.1 Architecture Fixes ✅
- [x] Fix type mismatches between struct and Core Data
- [x] Add conversion layer (GameSession ↔ Game) - `GameConversion.swift`
- [x] Separate PlayerDetailView to use struct types
- [x] Add game save functionality

**Files Added/Modified:**
- `GameConversion.swift` - Conversion between struct and Core Data models
- `GameViewModel.swift` - Added `saveGame()` method
- `GameView.swift` - Added save confirmation alert
- `LandscapeGameView.swift` - Added save confirmation alert

### 1.2 Core Features ✅
- [x] Real-time game clock + shot clock
- [x] Period management
- [x] Player stats (goals, assists, steals, exclusions, penalties, sprints)
- [x] 3-foul foul-out tracking
- [x] Game event log
- [x] Export to MaxPreps format
- [x] Export to Club Water Polo format

### 1.3 UI Polish ✅
- [x] Portrait scoring view
- [x] Landscape scoring view
- [ ] iPad optimization (Phase 2)
- [ ] Dark mode support (Phase 2)

### 1.4 Build Status ✅
- [x] Clean build (0 errors, 0 warnings)
- [x] Swift 5.5+ compatible
- [x] iOS 15.0+ compatible

---\n
## ✅ Phase 1.5: Outdoor-Ready Simple Scorer (COMPLETE - Feb 21, 2026)

**Goal**: Basic scoring that works in bright sun with high efficiency

### 1.5.1 Simple Mode UI ✅
- [x] Create `SimpleGameView` with large fonts (72pt score, 48pt clock)
- [x] High contrast layout (Black/White or Blue/Orange)
- [x] Always-visible clock controls (Pause, +/- 1s)
- [x] One-tap action buttons (Goal, Exclusion, Timeout)
- [x] Quick player roster list

### 1.5.2 Sunlight Mode ✅
- [x] Auto-brightness detection (`SunlightMode.swift`)
- [x] Manual toggle button
- [x] Extreme contrast styling (pure black/white)

### 1.5.3 Photo Capture ✅
- [x] Floating camera button
- [x] `ImagePicker` integration
- [x] Save to Photos library
- [x] Auto-tagging logic (within 5s of player action)

### 1.5.4 App Integration ✅
- [x] Set Simple Mode as default in `ContentView`
- [x] Add toggle to switch to Full Mode
- [x] Update `GameViewModel` to support photo tagging

---

## Phase 2: Team Management (Next)

**Goal:** Full team roster management, season tracking

### 2.1 Team Roster
- [ ] Player photos
- [ ] Jersey numbers
- [ ] Positions (goalie, field player)
- [ ] Import roster from CSV/MaxPreps

### 2.2 Season Organization
- [ ] Season entity (2024-2025, etc.)
- [ ] Tournament tracking
- [ ] League standings

### 2.3 Statistics
- [ ] Career stats per player
- [ ] Team stats over time
- [ ] Advanced metrics (shooting %, exclusion efficiency)

### 2.4 UI Polish
- [ ] iPad optimization
- [ ] Dark mode support

---

## Phase 3: Real-Time Collaboration (Future)

**Goal:** Multiple scorers, live updates, spectator view

### 3.1 Architecture Prep
The dual-model design makes this possible:
- `GameSession` can be serialized to JSON for WebSocket transport
- Structs are Sendable (thread-safe for networking)
- Core Data remains the source of truth

### 3.2 Collaboration Modes
```
┌────────────────────────────────────────────────────────────┐
│                 COLLABORATION ARCHITECTURE                 │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   Scorer A (iPad)          Server          Scorer B (iPhone)│
│   ┌──────────┐          ┌────────┐         ┌──────────┐   │\n│   │GameSession│◄────────►│ WebSocket       │GameSession│   │
│   │  (local)  │   JSON   │ Sync   │  JSON   │  (local)  │   │
│   └──────────┘          └────────┘         └──────────┘   │
│        │                                        │         │
│        │ Game End                               │ Game End │
│        ▼                                        ▼         │
│   ┌──────────┐                              ┌──────────┐  │
│   │   Save   │                              │   Save   │  │
│   │  to CD   │                              │  to CD   │  │
│   └──────────┘                              └──────────┘  │
│                                                            │
│   Spectator View (Web/iPhone)                              │
│   ┌─────────────────────────────────┐                     │
│   │  Read-only GameSession stream   │                     │
│   │  Live scoreboard                │                     │
│   └─────────────────────────────────┘                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 3.3 Features
- [ ] WebSocket sync layer
- [ ] Conflict resolution (who has edit priority?)
- [ ] Spectator mode (read-only)
- [ ] Live scoreboard web view
- [ ] Parent notification ("Ian just scored!")

---

## Phase 4: Platform Expansion

**Goal:** Web app, Apple Watch, integrations

### 4.1 Web Companion
- [ ] React web app for scorekeeping
- [ ] Parent/spectator view
- [ ] Coach dashboard

### 4.2 Apple Watch
- [ ] Quick score entry
- [ ] Shot clock on wrist
- [ ] Haptic feedback for period end

### 4.3 Integrations
- [ ] MaxPreps direct upload
- [ ] GameChanger integration
- [ ] Hudl video tagging

---

## Technical Debt & Maintenance

### Ongoing
- [ ] Unit tests for GameViewModel
- [ ] UI tests for scoring flow
- [ ] Performance testing (1000+ events)
- [ ] Accessibility audit

### Swift 6 Migration
- [ ] Full Sendable conformance
- [ ] Actor isolation review
- [ ] Strict concurrency checking

---

## Monetization Options

| Model | Pros | Cons |
|-------|------|------|
| **Free + Pro** | Easy adoption | Feature gating complexity |
| **Team Subscription** | Predictable revenue | Sales overhead |
| **Pay Per Tournament** | Low barrier | Hard to track |
| **School District License** | Big contracts | Long sales cycle |

**Recommendation:** Start free, add Pro for collaboration features (Phase 3+)

---

## Success Metrics

| Phase | Metric | Target |
|-------|--------|--------|
| 1 ✅ | Stable build, Ian uses it | 0 crashes |
| 1.5 ✅ | Outdoor usability | 100% visible in sun |
| 2 | Teams using it | 10 teams |
| 3 | Collaboration sessions | 100 games |
| 4 | Revenue | $1K MRR |

---

## Next Steps

1. **This week:** Ian beta testing Phase 1 & 1.5
2. **Next week:** Gather feedback, iterate
3. **Month 1:** Start Phase 2 development
4. **Month 2-3:** Complete Phase 2
5. **Month 4+:** Phase 3 planning

---

## File Structure

```
WaterPolo Stats/
├── Models/
│   ├── Game+CoreDataClass.swift
│   ├── GameStruct.swift              # GameSession, GameTeam, GamePlayer
│   ├── GameConversion.swift          # ✅ Conversion layer
│   └── ...
├── ViewModels/
│   └── GameViewModel.swift           # ✅ Added photo tagging
├── Views/
│   ├── ContentView.swift             # ✅ Simple Mode default
│   ├── SimpleGameView.swift          # ✅ NEW: Outdoor scoring
│   ├── SunlightMode.swift            # ✅ NEW: Brightness detection
│   ├── GameView.swift                # Full Stats Mode
│   └── ...
```

---

*Document Version: 1.2*
*Last Updated: February 21, 2026*
*Phase 1.5 Status: ✅ COMPLETE*
