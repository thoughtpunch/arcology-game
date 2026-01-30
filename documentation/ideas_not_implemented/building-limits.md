# Building Height, Volume & Infrastructure Limits

> **Status:** Idea
> **Created:** 2026-01-30
> **Related BEADS:** (to be created)

## Executive Summary

Track building height and volume as first-class metrics, display them in the HUD/debug panel, and eventually gate them behind infrastructure systems (HVAC, power, water, elevators). The arcology can only grow as tall and large as its support systems allow — like a real building.

## Problem Statement

Currently, there are no limits on how tall or how much you can build (aside from structural support rules). There's no feedback showing the player how big their structure is. In a real arcology:

- Taller buildings need elevators, stairwells, and pressurized air handling
- Larger volumes need more HVAC capacity, power generation, and water pumping
- Every floor added increases the load on ground-level infrastructure
- There's a natural tension between "build more" and "support what you have"

Without these constraints, there's no interesting decision-making around vertical growth.

## Product Requirements

### Phase 1: Display Only (immediate)

Show current building stats in the debug panel (F3) and eventually the HUD:

- **Height**: The Y-coordinate of the topmost occupied cell of any placed block (not ground). Displayed in cells and in-world units.
- **Volume**: Total number of cells occupied by placed blocks (not ground cells). This is the "built volume" of the structure.
- **Footprint**: Number of unique (x, z) columns that contain at least one placed block.

These are read-only stats — no limits enforced yet.

### Phase 2: Soft Limits (future)

Introduce capacity systems that gate growth:

| System | What It Limits | How It Works |
|--------|---------------|--------------|
| **Elevators / Stairs** | Max effective height | Without vertical transit, upper floors are unreachable. Residents won't live above floor N if there's no elevator shaft. |
| **HVAC** | Max enclosed volume | Air doesn't circulate itself. Large enclosed spaces need ducting. Unventilated rooms degrade health. |
| **Power** | Everything | Lights, elevators, HVAC, water pumps — all need power. Generator capacity is the master constraint. |
| **Water** | Habitable volume | Pumping water above ground level requires energy proportional to height. No water = no residents. |
| **Structural** | Height per gravity | Already planned in scenario-config.md — cantilever limits based on gravity. |

The player doesn't hit a hard wall. Instead, exceeding capacity causes **degradation**: lights flicker, air quality drops, elevators slow, water pressure drops. The building still stands, but quality of life suffers and residents leave.

### Phase 3: Infrastructure Blocks (future)

New block types that expand capacity:

- **Elevator Shaft** — increases max serviced height
- **HVAC Unit** — increases ventilated volume capacity
- **Generator** — increases power capacity
- **Water Tank / Pump** — increases water capacity per height tier
- **Solar Panel** — passive power (height-dependent efficiency)

Each infrastructure block has a capacity rating. Total capacity across all placed infrastructure blocks determines the limit.

### Formulas (Draft)

```
effective_height_limit = base_height + (elevator_count * floors_per_elevator)
effective_volume_limit = base_volume + (hvac_count * volume_per_hvac)
power_demand = f(volume, height, elevator_count, hvac_count, light_count)
power_supply = sum(generator.capacity for generator in placed_generators)
```

When `demand > supply`, systems degrade proportionally:
```
efficiency = clamp(supply / demand, 0.0, 1.0)
# At 0.5 efficiency: lights at half brightness, elevators at half speed, etc.
```

## Technical Plan

### Phase 1: Stats Tracking & Display

1. Add `_compute_building_stats() -> Dictionary` to `sandbox_main.gd`
   - Iterate `placed_blocks` to find max Y, total cell count, unique XZ columns
   - Return `{ "height": int, "volume": int, "footprint": int }`
2. Add info labels to the debug panel (F3): Height, Volume, Footprint
3. Update stats on every block place/remove (not every frame — event-driven)
4. Optionally show a compact "H: 5 | V: 42" in the main HUD

### Phase 2: Capacity System

1. Create `src/systems/capacity_system.gd`
   - Tracks demand vs. supply for each resource type
   - Emits signals when capacity is exceeded or restored
2. Infrastructure block types in `data/blocks.json` with capacity metadata
3. Wire capacity into environment quality (light, air, noise systems)

### Phase 3: UI & Feedback

1. Capacity bars in HUD (power, water, air, transit)
2. Warning overlays when systems are over capacity
3. Degradation visual effects (flickering lights, haze for bad air)

## Risks & Mitigations

- **Frustration**: Hard limits feel bad. Use soft degradation instead — the building works, just worse. Players learn to add infrastructure before expanding.
- **Complexity**: Phase 1 is pure display, zero gameplay impact. Infrastructure blocks can be added one system at a time.
- **Balance**: Infrastructure costs will need extensive playtesting. Start with generous limits.

## Open Questions

1. Should height be measured from ground level or from the lowest placed block?
2. Does digging down count as "height" (total vertical span)?
3. Should infrastructure blocks take up habitable space, creating a build-vs-support tension?
4. How do infrastructure systems interact with the scenario config gravity model?
5. Should there be a "building inspector" overlay that shows which areas are under-served?

## Next Steps

1. Create BEADS tickets for Phase 1 (display only)
2. Implement height/volume tracking in sandbox_main.gd
3. Defer Phase 2/3 until core game loop is further along
