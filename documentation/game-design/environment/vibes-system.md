# Vibes System

[← Back to Environment](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Vibes is a **composite score** representing overall quality and desirability. It combines multiple factors into one number.

---

## Vibes Calculation

```
vibes = (
    effective_light × 0.25 +
    effective_air × 0.20 +
    greenery_proximity × 0.15 +
    aesthetics × 0.10 +
    quiet × 0.15 +
    safety × 0.15
) - subterranean_vibes_penalty
```

| Factor | Weight | Source |
|--------|--------|--------|
| Light | 25% | [light-system.md](./light-system.md) |
| Air | 20% | [air-system.md](./air-system.md) |
| Greenery | 15% | Nearby green blocks |
| Aesthetics | 10% | Corridor upgrades, art |
| Quiet | 15% | Inverse of noise |
| Safety | 15% | [safety-system.md](./safety-system.md) |

---

## Subterranean Penalty

```
if Z < 0:
    vibes_penalty = 15 + (|Z| × 10)

Z = -1: -25 vibes
Z = -2: -35 vibes
Z = -3: -45 vibes
```

Underground areas are inherently less appealing.

---

## Greenery Proximity

Nearby green spaces boost vibes:

| Block | Vibes Radius | Vibes Bonus |
|-------|--------------|-------------|
| Planter | 1 block | +5 |
| Courtyard Garden | 3 blocks | +10 |
| Indoor Forest | 5 blocks | +20 |
| Rooftop Park | 4 blocks | +15 |
| Atrium (adjacent) | 1 block | +15 |

---

## Aesthetics

Corridor and block upgrades add aesthetics:

| Upgrade | Aesthetics Bonus |
|---------|------------------|
| Basic Lighting | +5 |
| Premium Lighting | +10 |
| Art Installation | +10 |
| Water Feature | +12 |
| Premium Flooring | +8 |
| Living Wall | +15 |

---

## Quiet Factor

```
quiet = 100 - noise_level

High noise = low quiet = lower vibes
Sound generators (music, fountains) add vibes despite adding noise
```

---

## Vibes Effects

### On Rent

```
desirability includes:
  vibes × 0.15

High vibes = higher rent potential
```

### On Satisfaction

Residents in high-vibes areas:
- Higher base satisfaction
- Slower satisfaction decay
- Lower flight risk

### On Commercial

Commercial blocks in high-vibes areas:
- More foot traffic
- Higher revenue
- Better clustering bonuses

---

## Vibes Tiers

| Vibes Level | Description |
|-------------|-------------|
| 80-100 | Premium - desirable, high rent |
| 60-80 | Pleasant - good quality |
| 40-60 | Acceptable - average |
| 20-40 | Unpleasant - low rent, dissatisfaction |
| 0-20 | Hostile - exodus risk |

---

## Improving Vibes

### Quick Wins
- Add planters (+5 each)
- Upgrade corridor lighting (+5)
- Install art (+10)

### Structural Changes
- Add atrium (light well) (+15)
- Build green space (+10-20)
- Improve HVAC coverage (+air = +vibes)

### Security
- Add security station (+safety = +vibes)
- Better lighting (+light, +safety = +vibes)

---

## Overlay Visualization

Vibes overlay shows sparkle/glow intensity:

```
High vibes (80+):  Bright sparkle
Medium (50-80):    Moderate glow
Low (20-50):       Dim
Very low (<20):    Dark/gray
```

---

## See Also

- [light-system.md](./light-system.md) - 25% of vibes
- [air-system.md](./air-system.md) - 20% of vibes
- [noise-system.md](./noise-system.md) - 15% (inverse) of vibes
- [safety-system.md](./safety-system.md) - 15% of vibes
- [../blocks/green.md](../blocks/green.md) - Green space bonuses
- [../economy/rent.md](../economy/rent.md) - Vibes affects rent
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#vibes) - Formula reference
