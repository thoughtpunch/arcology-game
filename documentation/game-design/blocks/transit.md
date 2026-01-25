# Transit Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Transit blocks enable movement through the arcology: corridors, elevators, stairs, and specialized transit.

---

## Corridors

| Type | Size | Capacity | Speed | Cost |
|------|------|----------|-------|------|
| Small | 1×1 | 20 | 1.0x | $50 |
| Medium | 2×1 | 50 | 1.0x | $100 |
| Large | 3×2 | 150 | 1.1x | $300 |
| Grand Promenade | 5×2 | 400 | 1.2x | $800 |

All corridors are **PUBLIC** - pathfinding routes through them.

See [../transit/corridors.md](../transit/corridors.md) for full details.

---

## Corridor Junctions

| Type | Connects |
|------|----------|
| Straight | Left-Right or Up-Down |
| Corner | Two perpendicular directions |
| T-Junction | Three directions |
| 4-Way | All four directions |

---

## Vertical Transit

| Block | Floors | Speed | Capacity | Cost |
|-------|--------|-------|----------|------|
| Stairs | ±3 | 0.5x | Low | $200 |
| Elevator (Local) | ±10 | 3.0x | 10/car | $500/floor |
| Elevator (Express) | ±30 | 5.0x | 20/car | $800/floor |
| Freight Elevator | Any | 2.0x | Freight | $600/floor |

### Elevator Banks

Multiple elevators serving same floors = elevator bank.
- Shared dispatching
- Reduced wait times
- See [../transit/elevators.md](../transit/elevators.md)

---

## Special Transit

| Block | Speed | Capacity | Notes |
|-------|-------|----------|-------|
| Moving Walkway | 2.0x | High | Horizontal only |
| Escalator | 1.5x | High | Diagonal (30-45°) |
| Pneuma-Tube | 10.0x | 2 | Tech Level 4, any direction |

---

## Sky Lobby

**Size:** 4×4×2 (mega-block)

Transit hub enabling express elevators:

```
Sky Lobby at Floor 30:
- Local elevators: Floors 0-30
- Express elevators: Ground ↔ Floor 30
- Local elevators: Floors 30-60

Reduces total elevator shafts needed.
```

---

## Grand Terminal

**Size:** 5×5×2 (mega-block)

External connection point:

- Ground-level entrance to arcology
- Massive foot traffic
- Commercial opportunity
- Security checkpoint recommended

---

## Pathfinding Costs

| Transit Type | Cost Modifier |
|--------------|---------------|
| Corridor (clear) | 1.0 |
| Corridor (crowded) | 1.3 |
| Stairs (up) | 2.5 |
| Stairs (down) | 1.6 |
| Elevator (with wait) | Variable |
| Conveyor (with flow) | 0.5 |

Lower cost = preferred route.

See [../transit/pathfinding.md](../transit/pathfinding.md) for algorithm details.

---

## Utility Integration

Corridors can carry utilities:

| Upgrade | Adds |
|---------|------|
| Power Conduit | +50 power capacity |
| Water Main | +25 water capacity |
| Light Pipe | +1 light channel |
| Air Duct | +1 air channel |

Creates utility corridor = transit + infrastructure.

---

## See Also

- [../transit/corridors.md](../transit/corridors.md) - Full corridor mechanics
- [../transit/elevators.md](../transit/elevators.md) - Elevator simulation
- [../transit/pathfinding.md](../transit/pathfinding.md) - Route calculation
- [infrastructure.md](./infrastructure.md) - Power, water, HVAC
- [../../architecture/milestones/milestone-8-pathfinding.md](../../architecture/milestones/milestone-8-pathfinding.md) - Implementation
