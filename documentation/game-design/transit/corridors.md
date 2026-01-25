# Corridors

[← Back to Transit](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Corridors are the primary horizontal transit. They're PUBLIC blocks—pathfinding routes through them.

---

## Corridor Types

| Type | Size | Capacity | Speed | Cost |
|------|------|----------|-------|------|
| Small | 1×1 | 20/tick | 1.0x | $50 |
| Medium | 2×1 | 50/tick | 1.0x | $100 |
| Large | 3×2 | 150/tick | 1.1x | $300 |
| Grand Promenade | 5×2 | 400/tick | 1.2x | $800 |

Wider corridors = more capacity + faster + less noise per person.

---

## Junction Types

Corridors connect via junctions:

| Junction | Connects |
|----------|----------|
| Straight H | Left ↔ Right |
| Straight V | Up ↔ Down |
| Corner TL | Top ↔ Left |
| Corner TR | Top ↔ Right |
| Corner BL | Bottom ↔ Left |
| Corner BR | Bottom ↔ Right |
| T-Junction | Three directions |
| 4-Way | All four directions |

Auto-placed based on adjacent corridors.

---

## Capacity & Congestion

### Saturation

```
saturation = current_traffic / base_capacity
```

### Speed by Saturation

| Saturation | Speed | Description |
|------------|-------|-------------|
| 0-50% | 1.0x | Free flow |
| 50-75% | 0.85x | Crowded |
| 75-90% | 0.6x | Congested |
| 90-100% | 0.4x | Packed |
| >100% | 0.2x | Gridlock |

### Effective Speed

```
effective_speed = base_speed × speed_multiplier(saturation)
```

---

## Corridor Noise

Traffic creates noise:

```
traffic_noise = current_traffic × NOISE_PER_PERSON

NOISE_PER_PERSON by type:
  Small:          0.8
  Medium:         0.5
  Large:          0.3
  Grand Promenade: 0.2
```

Wider corridors produce less noise per person.

See [../environment/noise-system.md](../environment/noise-system.md) for propagation.

---

## Aesthetic Upgrades

| Upgrade | Vibes | Cost | Notes |
|---------|-------|------|-------|
| Basic Lighting | +5 | $100 | Required |
| Premium Lighting | +10 | $300 | Crime reduction |
| Planter Boxes | +8 | $200 | Small greenery |
| Living Wall | +15 | $500 | Vertical garden |
| Bench Seating | +5 | $150 | Rest stops |
| Water Feature | +12 | $400 | Fountain |
| Art Installation | +10 | $300 | Culture |
| Acoustic Panels | +3 | $250 | -20 noise |
| Premium Flooring | +8 | $200 | -5 noise |

---

## Utility Integration

Corridors can carry utilities:

| Upgrade | Adds | Cost |
|---------|------|------|
| Power Conduit | +50 power | $100 |
| Water Main | +25 water | $150 |
| Light Pipe | +1 light channel | $200 |
| Air Duct | +1 air channel | $100 |
| Data Trunk | +25 data | $75 |

Creates **Utility Corridor** = transit + infrastructure.

---

## Pathfinding Cost

```
edge_cost = (distance / effective_speed) × traversal_modifier

Traversal modifiers:
  Corridor (clear): 1.0
  Corridor (crowded): 1.3
  Industrial corridor: 1.3
```

Lower cost = preferred route.

---

## See Also

- [elevators.md](./elevators.md) - Vertical transit
- [pathfinding.md](./pathfinding.md) - Route calculation
- [../environment/noise-system.md](../environment/noise-system.md) - Traffic noise
- [../blocks/transit.md](../blocks/transit.md) - Transit block catalog
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#corridor-capacity-and-speed) - Formulas
