# WaterPolo Stats - AI Development Folder

This folder contains all AI-generated documentation, specifications, and session memories for the WaterPolo Stats iOS app.

## Folder Structure

| File/Folder | Purpose |
|-------------|---------|
| `CLAUDE_CODE.md` | Guidance for Claude Code when working on this codebase |
| `PRODUCT_SPEC_V2.md` | Full product specification (v2.0) - use cases, design requirements |
| `SIMPLE_MODE_V2_SPEC.md` | Simple Mode detailed specification - outdoor scoring UI |
| `PRODUCT_ROADMAP.md` | Phased development roadmap (Phase 1-4) |
| `memories/` | Session-by-session development logs |

## Quick Reference

### For Claude Code Sessions
Read `CLAUDE_CODE.md` first - it contains:
- Build & test commands
- Architecture overview (dual-model pattern)
- Data flow diagrams
- Key files reference
- Target requirements

### For Understanding the Product
1. Start with `PRODUCT_SPEC_V2.md` - core use cases and design decisions
2. Review `SIMPLE_MODE_V2_SPEC.md` - detailed UI/UX for outdoor scoring
3. Check `PRODUCT_ROADMAP.md` - current phase and next steps

### For Historical Context
Browse `memories/` folder for session logs:
- `2026-02-21-claude-cleanup.md` - Architecture overhaul, Phase 1.5 complete

## Architecture at a Glance

```
┌─────────────────┐      ┌─────────────────┐
│  ACTIVE GAME    │      │   PERSISTENCE   │
│  (Structs)      │─────▶│  (Core Data)    │
│                 │ Save │                 │
│ • GameSession   │      │ • Game          │
│ • GameTeam      │      │ • Team          │
│ • GamePlayer    │      │ • Player        │
└─────────────────┘      │ • GameEvent     │
                         └─────────────────┘
```

Structs = Fast, mutable, in-memory (real-time scoring)
Core Data = Disk + CloudKit (historical records)

## Status (2026-02-21)

- ✅ Phase 1: Foundation (Architecture, build clean)
- ✅ Phase 1.5: Outdoor-Ready Simple Scorer
- ⏳ Ian beta testing
- 🔮 Phase 2: Team Management (next)

## GitHub

Repository: `ngmeyer/waterpolo-stats`
Main branch: `main`
