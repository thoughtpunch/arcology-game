# Transit Systems

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Transit systems move people through the arcology. Pathfinding, corridors, and elevators are the core puzzle of vertical city design.

---

## Contents

| Topic | Description | Link |
|-------|-------------|------|
| **Corridors** | Horizontal movement | [corridors.md](./corridors.md) |
| **Elevators** | Vertical movement | [elevators.md](./elevators.md) |
| **Pathfinding** | Route calculation | [pathfinding.md](./pathfinding.md) |

---

## Core Concepts

### Public vs Private Blocks

| Type | Pathfinding |
|------|-------------|
| Public | Routes THROUGH (corridors, food halls) |
| Private | Routes TO/FROM (apartments, shops) |

### Movement Speed

| Transit Type | Speed Multiplier |
|--------------|------------------|
| Walking | 1.0x |
| Stairs (up) | 0.4x |
| Stairs (down) | 0.6x |
| Elevator | 3.0-5.0x + wait |
| Conveyor (with flow) | 2.0-2.5x |
| Pneuma-Tube | 10.0x |

### Commute Time

Commute affects satisfaction:

| Commute | Effect |
|---------|--------|
| < 10 min | +2 satisfaction |
| 10-20 min | Neutral |
| 20-30 min | -2 satisfaction |
| > 30 min | -5 satisfaction |

---

## Transit Planning

### Vertical Strategy

```
Sky Lobby Pattern:
  Floors 0-30: Local elevators
  Floor 30: Sky Lobby (transfer point)
  Floors 30-60: Local elevators
  Express: Ground ↔ Floor 30 ↔ Floor 60
```

### Horizontal Strategy

```
Wide Main Corridors:
  - Grand Promenade for main arteries
  - Captures foot traffic for commercial
  - Less noise per person

Narrow Service Corridors:
  - Small corridors for utility/access
  - Lower capacity, less prominent
```

---

## See Also

- [../blocks/transit.md](../blocks/transit.md) - Transit block types
- [../environment/noise-system.md](../environment/noise-system.md) - Traffic noise
- [../human-simulation/agents.md](../human-simulation/agents.md) - Daily schedules
- [../../architecture/milestones/milestone-8-pathfinding.md](../../architecture/milestones/milestone-8-pathfinding.md) - Implementation
