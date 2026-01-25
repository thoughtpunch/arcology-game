# Green Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Green blocks provide natural elements: parks, gardens, and atriums. They improve air quality, vibes, and resident wellbeing.

---

## Green Spaces

| Block | Size | Needs | Produces |
|-------|------|-------|----------|
| Planter | 1×1 | Water, Light (any) | Vibes (+5), tiny air |
| Courtyard Garden | 2×2 | Water, Light (50%+) | Vibes (+10), air (small) |
| Indoor Forest | 5×5×3 | Water (high), Light (60%+) | Vibes (+20), air (large) |
| Rooftop Park | 3×3 | Water, Natural light | Vibes (+15), air |

---

## Atrium (Special)

**Size:** 3×3×5+ (vertical void)

An atrium is a **void** - empty space surrounded by structure:

```
Purpose:
- Brings natural light to interior
- Provides fresh air circulation
- Creates visual/social focal point
- Vibes bonus to adjacent blocks

NOT a block - it's ABSENCE of blocks
(Reserved space that blocks cannot occupy)
```

### Light Well Effect

```
Natural light travels down through atrium:
  Top: 100%
  Per floor down: -10%
  At floor 10: still 100% - (10 × 10%) = 0%

Interior-facing windows adjacent to atrium
get this light level.
```

---

## Indoor Forest (Mega-Block)

**Size:** 5×5×3 (3 floors tall)

Major green space for deep interiors:

```
Produces:
  Fresh Air: Large radius (20 blocks)
  Vibes: +20 to surrounding area
  Noise Reduction: -10 to adjacent blocks
  Biomass (waste processing)

Needs:
  Water: High (irrigation)
  Light: 60%+ (natural or piped)
  Path: Access for visitors

Cost: Very high construction + maintenance
```

---

## Benefits by Type

### Vibes Contribution

| Block | Vibes Radius | Vibes Strength |
|-------|--------------|----------------|
| Planter | 1 block | +5 |
| Courtyard Garden | 3 blocks | +10 |
| Indoor Forest | 5 blocks | +20 |
| Rooftop Park | 4 blocks | +15 |
| Atrium | Adjacent only | +15 |

### Air Quality Contribution

| Block | Air Radius | Air Quality |
|-------|------------|-------------|
| Planter | 1 block | +5 |
| Courtyard Garden | 2 blocks | +15 |
| Indoor Forest | 5 blocks | +30 |
| Rooftop Park | 3 blocks | +20 |

---

## Strategic Placement

### Interior Greening

Use green blocks to make deep interiors livable:

```
Problem: Interior block has 30% light, 40% air
Solution: Place Courtyard Garden within 3 blocks
Result: +15 air quality, +10 vibes
```

### Premium Views

Blocks facing green spaces get bonuses:
- Window onto atrium: +vibes
- Adjacent to park: +vibes, +air
- Penthouse with rooftop access: major premium

---

## Traversability

| Block | Traversable? |
|-------|--------------|
| Planter | No (decoration) |
| Courtyard Garden | Yes (pleasant shortcut) |
| Indoor Forest | Partially (paths through) |
| Rooftop Park | Yes |
| Atrium | N/A (void) |

---

## Maintenance

Green blocks require ongoing care:

| Block | Monthly Maintenance |
|-------|---------------------|
| Planter | $10 |
| Courtyard Garden | $50 |
| Indoor Forest | $500 |
| Rooftop Park | $200 |

Neglected green spaces lose effectiveness.

---

## See Also

- [../environment/vibes-system.md](../environment/vibes-system.md) - Vibes calculation
- [../environment/air-system.md](../environment/air-system.md) - Air quality
- [../environment/light-system.md](../environment/light-system.md) - Atrium light wells
- [../dynamics/entropy.md](../dynamics/entropy.md) - Maintenance decay
- [residential.md](./residential.md) - Premium housing near green
