# Elevators

[← Back to Transit](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Elevators are the core puzzle of vertical city design. Wait times, capacity, and dispatch algorithms affect resident satisfaction.

---

## Elevator Types

| Type | Range | Speed | Capacity | Tech Level |
|------|-------|-------|----------|------------|
| Stairs | ±3 floors | 0.5x | Low | 1 |
| Local Elevator | ±10 floors | 3.0x | 10/car | 1 |
| Express Elevator | ±30 floors | 5.0x | 20/car | 3 |
| Freight Elevator | Any | 2.0x | Freight only | 2 |
| Pneuma-Tube | Any direction | 10.0x | 2 | 4 |

---

## Elevator Banks

Multiple shafts serving same floors = elevator bank.

```
ElevatorBank {
  shafts: [Shaft]
  floors_served: [int]
  express_mode: bool
  express_stops: [int]

  average_wait_time: MovingAverage
  peak_hour_wait: float
  complaints_this_month: int
}
```

---

## Dispatch Algorithms

### Collective Control (Default)

```
- Car travels in one direction
- Stops at all requested floors
- Reverses when no more calls ahead

Pros: Simple, intuitive
Cons: Inefficient for tall buildings
```

### Destination Dispatch (Tech Level 3)

```
- Passengers enter destination before boarding
- System assigns optimal car
- Groups passengers going to similar floors

Pros: 20-30% efficiency gain
Cons: Feels impersonal
```

---

## Sky Lobby Pattern

For very tall buildings:

```
Express cars: Ground ↔ Sky Lobby only
Local cars: Serve floors around each sky lobby

Example (60 floors):
  Sky Lobby at Floor 30
  Express: 0 ↔ 30 (no stops)
  Local Bank A: Floors 0-30
  Local Bank B: Floors 30-60

Benefits:
  - Fewer elevator shafts needed
  - Faster long-distance travel
  - Transfer adds delay

Drawbacks:
  - Transfer time
  - Class resentment if separate
```

---

## Wait Time Psychology

### Perception Multipliers

Factors that **increase** perceived wait:

| Factor | Multiplier |
|--------|------------|
| No indicator | ×1.5 |
| Watching full cars pass | ×1.3 |
| Running late | ×1.4 |
| Uncomfortable lobby | ×1.25 |
| Alone | ×1.2 |

Factors that **decrease** perceived wait:

| Factor | Multiplier |
|--------|------------|
| Countdown display | ×0.7 |
| Pleasant lobby | ×0.8 |
| Friend present | ×0.75 |
| Distraction (art) | ×0.85 |
| Mirrors | ×0.9 |

### Frustration Model

```
perceived_wait = actual_wait × perception_multipliers
tolerance = f(personality.patience, time_of_day, urgency)

frustration += (perceived_wait - tolerance) × neuroticism / 100

if frustration > 50: show_annoyance()
if frustration > 80: generate_complaint()
if frustration > 100 for 5 days: flight_risk += 10
```

---

## Elevator Social Dynamics

### Encounters

```
When strangers share elevator:
  Base 2% acquaintance chance per ride
  +3% if similar archetype
  +5% if one initiates (extrovert)
  +10% if notable event (breakdown)

When friends share elevator:
  Relationship +2
  Conversation animation
  Nearby passengers: +1% acquaintance chance
```

---

## Elevator Failures

### Breakdown Triggers

| Condition | Daily Breakdown Chance |
|-----------|------------------------|
| < 40% | 5% |
| < 20% | 15% |
| < 10% | Guaranteed within week |

### Cascade Effects

| Timeline | Effect |
|----------|--------|
| Hour 1 | Wait times spike 2-3x |
| Hours 2-4 | Frustration, complaints |
| Day 1 | Productivity loss |
| Day 2+ | Flight risk increases |

### Recovery

- Repair time: 4-48 hours
- Trust recovery: weeks to months
- Memory persists: "The elevator that trapped me"

---

## See Also

- [corridors.md](./corridors.md) - Horizontal transit
- [pathfinding.md](./pathfinding.md) - Route calculation
- [../blocks/transit.md](../blocks/transit.md) - Transit blocks
- [../human-simulation/relationships.md](../human-simulation/relationships.md) - Elevator encounters
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#elevator-wait-time) - Wait time formula
