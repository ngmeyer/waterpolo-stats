# CLAUDE.md — WaterPolo Stats

## Project Overview

**WaterPolo Stats** — iOS app for real-time water polo scorekeeping, designed for outdoor pool use in bright sunlight.

**Current State:** Phase 1.5 complete, ready for Ian's beta testing
**Target User:** Neal (stat keeper), not Ian (player)

---

## Quick Reference

**Build:**
```bash
xcodebuild -project "WaterPolo Stats.xcodeproj" -scheme "WaterPolo Stats" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Key Principle:** Designed for outdoor pools in bright sun — high contrast and large touch targets are requirements.

---

## Architecture

### Dual-Model Pattern
- **Structs** (`GameSession`, `GameTeam`, `GamePlayer`) — Fast, mutable for real-time scoring
- **Core Data** (`Game`, `Team`, `Player`) — Persistence for completed games
- **Conversion Layer** (`GameConversion.swift`) — Handles struct ↔ Core Data round-trip

### Navigation
```
ContentView (TabView)
├── Tab 0: Games — Historical games list
├── Tab 1: Score — SimpleGameView (outdoor-optimized)
├── Tab 2: Full Stats — Detailed statistics
└── Tab 3: Teams — Team management
```

### Key Files
- `Models/GameStruct.swift` — All in-memory types
- `ViewModels/GameViewModel.swift` — Game logic, timer, scoring
- `Views/SimpleGameView.swift` — Primary outdoor scoring UI
- `Views/SunlightMode.swift` — Brightness detection + high-contrast mode
- `Models/GameConversion.swift` — Core Data persistence

---

## Domain Knowledge

### Critical Rules
- **Cap numbers are per-game, not per-player** — Kyle can be #5 white, #11 dark
- **Same player, multiple caps** — Goalie starts #1, moves to field later
- **Multiple games active** — Pause morning game, score afternoon, resume later
- **Water polo year starts Aug 1** — Teams archive, players persist until 19+

### 680 Club Specifics
- Colors: Red, Blue, White (not A/B/C levels)
- Season: March 2026 start

---

## Claude Code / Aria Instructions

### When Starting Work
1. Read `DOMAIN_KNOWLEDGE.md` — Critical rules and edge cases
2. Read `PRODUCT_SPEC_V2.md` — Features and acceptance criteria
3. Check `.ai/memories/` for recent context

### Before Implementing
- Test on device or simulator in bright environment (SunlightMode verification)
- Ensure touch targets are thumb-sized (outdoor use with wet hands)
- Check timer accuracy (0.1s intervals, must be reliable)

### Code Standards
- Swift 5.5+, iOS 15.0+
- Dual-model pattern: structs for gameplay, Core Data for save
- `@unchecked Sendable` for Core Data concurrency
- Large fonts (72pt score, 48pt clock) for outdoor visibility

### Testing Approach
- Unit tests: `GameViewModel` logic, `GameConversion`
- Device testing: SunlightMode auto-detection, photo capture
- Ian beta testing: Real poolside usage feedback

---

## Current Status

**Phase 1.5 Complete ✅**
- Simple Mode (outdoor-optimized)
- Sunlight auto-detection
- Photo capture with auto-tagging
- Clean build, Core Data persistence

**Next:** Ian Beta Testing
- TestFlight distribution
- Real poolside testing
- Feedback iteration

**Phase 2 Ready** (after beta feedback)
- Game setup UI (assign caps per game)
- Handle mid-game swaps
- Player photos in roster
- Career stats per player

---

## Blockers

- None currently — ready for Ian's testing

---

## Resources

- **GitHub:** https://github.com/ngmeyer/waterpolo-stats
- **Discord:** #waterpolo-stats
- **Domain Knowledge:** `.ai/DOMAIN_KNOWLEDGE.md`
- **Product Spec:** `.ai/PRODUCT_SPEC_V2.md`
- **Session Memories:** `.ai/memories/`

---

*Last updated: 2026-02-21 (Phase 1.5 complete)*
