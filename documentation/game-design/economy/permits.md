# Permits & Building Rights

[← Back to Economy](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Building above or below ground requires permits. Costs escalate with height/depth.

---

## Airspace Permits

Permission to build at specific heights.

### Cost Formula

```
permit_cost = BASE_PERMIT × HEIGHT_MULTIPLIER[floor]

HEIGHT_MULTIPLIER:
  Floors 1-10:   1.0x
  Floors 11-20:  1.5x
  Floors 21-30:  2.0x
  Floors 31-50:  3.0x
  Floors 51-75:  5.0x
  Floors 76-100: 8.0x
  Floors 100+:   12.0x
```

### Example

If BASE_PERMIT = $1,000:

| Floor | Multiplier | Cost |
|-------|------------|------|
| 5 | 1.0x | $1,000 |
| 15 | 1.5x | $1,500 |
| 35 | 3.0x | $3,000 |
| 60 | 5.0x | $5,000 |
| 80 | 8.0x | $8,000 |

---

## Excavation Permits

Permission to dig below ground.

### Cost Formula

```
permit_cost = BASE_EXCAVATION × DEPTH_MULTIPLIER[floor]

DEPTH_MULTIPLIER:
  Floors -1 to -3:   1.0x
  Floors -4 to -6:   1.5x
  Floors -7 to -10:  2.5x
  Floors -11 to -20: 4.0x
  Floors -20+:       6.0x
```

---

## Subterranean Penalties

Building underground has environment penalties:

```
For floor Z (where Z < 0):

light_penalty = min(100, |Z| × 20)     // -20% per floor
air_penalty = min(60, |Z| × 10)        // -10% per floor
vibes_penalty = 15 + (|Z| × 10)        // -15 base, -10 per floor
crime_bonus = 10 + (|Z| × 5)           // +10 base, +5 per floor
```

### Subterranean Summary

| Depth | Light | Air | Vibes | Crime |
|-------|-------|-----|-------|-------|
| Z = -1 | -20% | -10% | -25 | +15% |
| Z = -2 | -40% | -20% | -35 | +20% |
| Z = -3 | -60% | -30% | -45 | +25% |
| Z = -5 | -100% | -50% | -65 | +35% |

---

## Subterranean-Optimized Blocks

Some blocks work well underground:

| Block | Why |
|-------|-----|
| Parking Garage | No light/air needs |
| Nightclub | Darkness is aesthetic |
| Data Center | Cool, secure |
| Warehouse | Storage doesn't need light |
| Water Treatment | Best at low point |
| Heavy Industrial | Contains noise/pollution |
| Mushroom Farm | No sunlight needed |

See [../blocks/industrial.md](../blocks/industrial.md#subterranean-optimization) for details.

---

## Permit Process

### Automatic

Permits are automatically acquired when placing blocks:
1. Calculate required permit cost
2. Check treasury
3. Deduct cost if affordable
4. Block is placed

### Permit Display

```
┌─────────────────────────────────────┐
│ Building on Floor 45                │
│                                     │
│ Permit Required: Airspace           │
│ Height Multiplier: 3.0x             │
│ Permit Cost: $3,000                 │
│                                     │
│ Block Cost: $500                    │
│ Total Cost: $3,500                  │
└─────────────────────────────────────┘
```

---

## See Also

- [budget.md](./budget.md) - Treasury management
- [../blocks/industrial.md](../blocks/industrial.md) - Underground blocks
- [../environment/](../environment/) - Subterranean penalties
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#subterranean-penalties) - Formulas
