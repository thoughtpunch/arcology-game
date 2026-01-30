# Scenario / Map Configuration System

> **Status:** Idea
> **Created:** 2026-01-30
> **Related BEADS:** (to be created)

## Executive Summary

A data-driven scenario configuration system that defines the physics, environment, and structural rules for each game session. Enables a "custom game" mode where players can tune all parameters (gravity, day length, light intensity, build zone, structural limits). Scenario configs are JSON resources that can be shared, edited, and loaded at game start.

## Problem Statement

Currently, all game parameters (gravity behavior, build zone size, structural rules, lighting) are hardcoded in `sandbox_main.gd`. There's no way to:
- Play with different gravity settings (zero-g space station vs. lunar vs. Earth)
- Adjust day/night cycle length or disable it
- Change build zone dimensions or shape
- Modify structural rules (cantilever limits, max height)
- Create custom challenge scenarios
- Share scenarios between players

## Product Requirements

### Core Config Properties

**Physics & Structure:**
- `gravity`: float (0.0 = zero-g, 0.16 = lunar, 1.0 = Earth) — affects cantilever rules
- `max_cantilever`: int — max unsupported lateral extension in cells (function of gravity: `floor(2 / gravity)`, infinite at zero-g)
- `max_build_height`: int — vertical build limit in cells (-1 = unlimited)
- `structural_integrity`: bool — whether blocks need support at all

**Environment:**
- `day_length_minutes`: float — real-time minutes per full day cycle (0 = static time)
- `default_time_of_day`: float — starting hour (0-24)
- `sun_energy`: float — base sun intensity
- `ambient_energy`: float — base ambient light

**Build Zone:**
- `build_zone_origin`: Vector2i
- `build_zone_size`: Vector2i
- `ground_depth`: int — layers of diggable ground
- `ground_type`: String — terrain preset ("grass", "desert", "lunar", "space_platform")

**Game Mode:**
- `mode`: String — "sandbox" (free build), "scenario" (objectives), "custom" (all params exposed)
- `starting_blocks`: Dictionary — block type → count (-1 = unlimited)
- `objectives`: Array — scenario win conditions (future)

### User-Facing Behavior

1. **New Game screen** shows scenario picker (built-in presets + custom)
2. **Custom mode** exposes all parameters via UI sliders/inputs
3. **In-game debug panel** (F3) shows current scenario values
4. **Scenario presets:** Earth Standard, Lunar Colony, Zero-G Station, Creative (no limits)

### Gravity Model — Simple Cantilever Physics

Blocks are made of CNC-U material (strong, but not infinitely so). Every block has a finite ability to support lateral extension without a vertical column beneath it. Gravity is the key variable.

**Core rule:** A block can only be placed if every cell in it is within `max_cantilever` horizontal cells of a **vertically-supported column** — a column of blocks that traces an unbroken vertical path down to ground (or an anchor in zero-g).

**"Cantilever distance"** = the shortest horizontal (Manhattan) distance from a cell to the nearest vertically-supported column. If that distance exceeds `max_cantilever`, placement is rejected.

```
max_cantilever = floor(BASE_CANTILEVER / gravity)
```

Where `BASE_CANTILEVER = 2` (the Earth-gravity limit). This gives:

| Gravity | Setting | max_cantilever | What it feels like |
|---------|---------|---------------|-------------------|
| 0.0 | Zero-G | infinite | Build in any direction. No vertical support needed. Blocks must still connect to an anchor. |
| 0.16 | Lunar | 12 cells | Very generous. Wide platforms, long bridges. |
| 0.38 | Mars | 5 cells | Moderate. Need occasional columns. |
| 1.0 | Earth | 2 cells | Strict. Cantilever max 2 blocks out. Overhangs need support. |
| 2.0 | High-G | 1 cell | Almost no cantilever. Vertical columns everywhere. |

**Visual example (Earth gravity, side view):**
```
        [X]          ← 2 cells from column = OK (max_cantilever = 2)
      [X][X]         ← 1 cell from column = OK
   [X][X][X]         ← column (vertically supported)
   [X][X][X]
===ground======

      [!]            ← 3 cells out = REJECTED
    [X][X]
   [X][X][X]         ← column
===ground======
```

**Zero-g special case:** When gravity = 0, there is no "ground." Instead, the scenario defines one or more **anchor points** (e.g., a station core, docking port). Every block must be reachable via a connected path from an anchor. No cantilever limit applies — you can build in any direction — but logistics costs (air, power, transit time) still scale with distance from infrastructure.

**What "vertically supported" means:** A cell is vertically supported if there exists a continuous column of occupied cells below it all the way to ground (or an anchor in zero-g). A single gap breaks the support chain. This means removing a lower block can invalidate the support for everything above AND everything cantilevered off of it.

## Technical Plan

### Phase 1: ScenarioConfig Resource
- Create `src/data/scenario_config.gd` as a Godot Resource
- Define all properties with sensible defaults matching current hardcoded values
- Load from JSON files in `data/scenarios/`
- `sandbox_main.gd` reads config instead of hardcoded values

### Phase 2: Structural Rules Engine
- Refactor `_is_supported()` to check cantilever distance, not just adjacency
- For each cell in a block, compute shortest horizontal Manhattan distance to a vertically-supported column (BFS downward to ground)
- Reject placement if any cell exceeds `max_cantilever`
- Refactor `_would_orphan_blocks()` to re-check cantilever distances after removal
- Add max height enforcement in `is_cell_buildable()`
- Zero-g mode: replace ground-connectivity check with anchor-connectivity check

### Phase 3: Environment from Config
- Wire day length into a time-of-day system (auto-advance based on `day_length_minutes`)
- Apply sun/ambient energy from config
- Ground type selects terrain colors/material

### Phase 4: Custom Game UI
- New Game screen with scenario selection
- Custom mode parameter editor
- Save/load custom scenarios to user data

## Risks & Mitigations

- **Performance:** Cantilever BFS on every placement could be expensive for large structures. Mitigate with caching and incremental updates.
- **Complexity creep:** Start with gravity + cantilever only, defer objectives and game modes.
- **Balance:** Zero-g "no limits" mode needs alternative constraints (maintenance cost, pathfinding time) to stay interesting.

## Open Questions

1. Should zero-g mode still require connectivity to an anchor, or truly allow floating blocks?
2. How does gravity interact with the "crime doesn't climb" mechanic?
3. Should scenarios be versioned for save-game compatibility?
4. Do we want procedural terrain generation as part of scenario config?

## Next Steps

1. Create BEADS epic for scenario config system
2. Implement Phase 1 (ScenarioConfig resource) as first ticket
3. Refactor structural integrity as Phase 2
