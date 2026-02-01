# Residential Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Residential blocks provide housing for residents. They generate rent and are affected by environment quality.

---

## Standard Housing

| Block | Size | Capacity | Base Rent | Needs |
|-------|------|----------|-----------|-------|
| Budget Housing | 1×1 | 4 | $50 | Power, Air (any), Light (any), Path |
| Standard Housing | 1×1 | 2 | $100 | Power, Air, Light (50%+), Path, Water |
| Premium Housing | 1×1 | 1 | $200 | Power, Fresh Air, Light (70%+), Path, Water |
| Penthouse | 2×2 | 1 | $500 | Power, Fresh Air, Light (90%+), Top floor, Quiet |
| Family Housing | 2×2 | 2 families | $150 | Power, Air, Light (60%+), School access |

---

## Specialized Housing

| Block | Size | Capacity | Notes |
|-------|------|----------|-------|
| Studio Apartment | 1×1 | 6 | High density, low rent |
| Dormitory | 2×2 | 20 | Requires university |
| Senior Housing | 2×2 | 8 | Requires clinic access |
| Artist Loft | 1×1 | 2 | +Purpose, tolerates rough conditions |
| Worker Housing | 1×1 | 4 | Very low rent, near industrial |
| Bunker Housing | 1×1 | 8 | Emergency, subterranean viable |

---

## Communal Living

| Block | Size | Capacity | Special |
|-------|------|----------|---------|
| Co-Housing | 2×2 | 6 | +Belonging bonus |
| Commune | 3×3 | 12 | +Belonging, +Purpose |
| Boarding House | 2×2 | 10 | Shared facilities, low rent |

---

## Rent Calculation

```
base_rent = BLOCK_TYPE_BASE × LEVEL_MULTIPLIER

desirability = (
    light × 0.20 +
    air × 0.15 +
    quiet × 0.15 +
    safety × 0.15 +
    accessibility × 0.20 +
    vibes × 0.15
) / 100

actual_rent = base_rent × desirability × demand_multiplier
```

See [../../quick-reference/formulas.md](../../quick-reference/formulas.md#residential-rent) for full formula.

---

## Occupancy

Residents move in if:
- Block is connected to entrance
- Light level meets minimum
- Unit has vacancy

Residents leave if:
- Satisfaction drops below threshold
- Flight risk exceeds limit
- Better housing available elsewhere

---

## Environment Effects

| Factor | Effect on Rent | Effect on Satisfaction |
|--------|----------------|----------------------|
| Light > 70% | +20% rent | +10 satisfaction |
| Light < 40% | -30% rent | -15 satisfaction |
| Noise > 50 | -15% rent | -10 satisfaction |
| Safety < 40 | -25% rent | -20 satisfaction |
| Vibes > 70 | +15% rent | +5 satisfaction |

---

## Subterranean Housing

Housing below grade suffers penalties:

| Depth (Y-level) | Light Penalty | Vibes Penalty | Crime Risk |
|-----------------|---------------|---------------|------------|
| Y = -1 | -20% | -25 | +15% |
| Y = -2 | -40% | -35 | +20% |
| Y = -3 | -60% | -45 | +25% |
| Deeper | -100% | -55+ | +30%+ |

**Bunker Housing** tolerates these conditions with reduced expectations.

---

## See Also

- [commercial.md](./commercial.md) - Where residents work and shop
- [../human-simulation/needs.md](../human-simulation/needs.md) - Resident needs
- [../human-simulation/flourishing.md](../human-simulation/flourishing.md) - Satisfaction and happiness
- [../economy/rent.md](../economy/rent.md) - Full rent mechanics
- [../environment/](../environment/) - Light, air, noise, safety systems
