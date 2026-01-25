# Architecture & Implementation Guide

> Build the smallest playable thing first, then layer complexity.

Each milestone should be a working game you can play, just with fewer features. Never have a "big bang" integration.

---

## Milestones Overview

| # | Milestone | Goal | Complexity |
|---|-----------|------|------------|
| 0 | [Skeleton](./milestones/milestone-0-skeleton.md) | Empty project that runs | Setup |
| 1 | [Grid & Blocks](./milestones/milestone-1-grid-blocks.md) | Place/remove blocks | Foundation |
| 2 | [Floor Navigation](./milestones/milestone-2-floor-navigation.md) | Multiple floors, UI | Foundation |
| 3 | [Connectivity](./milestones/milestone-3-connectivity.md) | Blocks know connections | Foundation |
| 4 | [Light](./milestones/milestone-4-light.md) | Light propagation | Environment |
| 5 | [Economy](./milestones/milestone-5-economy.md) | Money, rent, costs | Economy |
| 6 | [Time](./milestones/milestone-6-time-simulation.md) | Game clock, ticks | Simulation |
| 7 | [Residents](./milestones/milestone-7-residents.md) | People exist | Agents |
| 8 | [Pathfinding](./milestones/milestone-8-pathfinding.md) | Routes, commutes | Transit |
| 9 | [Block Types](./milestones/milestone-9-block-types.md) | Full catalog | Content |
| 10 | [Overlays](./milestones/milestone-10-overlays.md) | Info visualization | UI |

**After Milestone 10: You have a playable game!**

---

## Post-Core Milestones (11-22)

| # | Feature | Complexity |
|---|---------|------------|
| 11 | Air quality system | Medium |
| 12 | Noise propagation | Medium |
| 13 | Safety/crime system | Medium |
| 14 | Vibes composite | Easy |
| 15 | Resident needs (5-tier) | Medium |
| 16 | Relationships & social | Hard |
| 17 | Elevator wait times | Medium |
| 18 | Multiple scenarios | Easy |
| 19 | Save/Load | Medium |
| 20 | Entropy/decay | Medium |
| 21 | Notable residents & stories | Hard |
| 22 | AEI win condition | Easy |

---

## Key Principles

### Data-Driven Design

Keep balance numbers OUT of code:

```json
// data/balance.json
{
  "economy": {
    "starting_money": 10000,
    "month_length_seconds": 60
  },
  "environment": {
    "light_falloff_per_floor": 20
  }
}
```

### Signal-Based Updates

Don't poll. Use signals:

```gdscript
signal block_placed(block: Block)
signal block_removed(block: Block)

func _ready():
    Grid.block_placed.connect(_on_block_changed)
```

### System Independence

Systems shouldn't directly reference each other:

```gdscript
# GOOD - Data on block
var light = block.environment.light

# BAD - Direct coupling
var light = LightSystem.get_light(position)
```

---

## Quick Links

- [Patterns](./patterns.md) - Reusable code patterns
- [Performance](./performance.md) - Optimization guidelines
- [../quick-reference/](../quick-reference/) - Fast lookups
