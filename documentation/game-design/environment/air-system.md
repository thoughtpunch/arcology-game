# Air System

[← Back to Environment](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Air quality affects health and comfort. Exterior-facing blocks get natural air; interior blocks need HVAC coverage.

---

## Air Sources

| Source | Quality | Coverage |
|--------|---------|----------|
| Exterior (windows/vents) | 100% | Adjacent to outside |
| HVAC Central | 90% | Large radius |
| HVAC Vent | 80% | Small radius |
| Green Space | +10-30% | Bonus to area |
| Atrium | 85% | Circulates naturally |

---

## Air Quality Calculation

### Exterior Blocks

```
If block has exterior-facing panel:
  air_quality = 100 (fresh air)
```

### Interior Blocks

```
air_quality = HVAC_coverage + green_bonus - consumption - subterranean_penalty

Where:
  HVAC_coverage = Σ(nearby HVAC × distance_falloff)
  green_bonus = Σ(nearby green spaces × contribution)
  consumption = population_density × 0.5
  subterranean_penalty = |Z| × 10 (if Z < 0)
```

---

## HVAC System

### HVAC Central

```
Coverage radius: 20 blocks
Air quality provided: 90%
Falloff: 2% per block distance
Power requirement: High
```

### HVAC Vent

```
Coverage radius: 5 blocks
Air quality provided: 80%
Falloff: 5% per block distance
Power requirement: Low
Requires: Connection to HVAC Central
```

### Distribution Pattern

```
HVAC Central at position (0,0,0):

Distance 0:  90%
Distance 5:  80%
Distance 10: 70%
Distance 15: 60%
Distance 20: 50%
Beyond 20:   0%
```

---

## Green Space Contribution

Green blocks improve air quality:

| Block | Air Radius | Air Bonus |
|-------|------------|-----------|
| Planter | 1 block | +5% |
| Courtyard Garden | 2 blocks | +15% |
| Indoor Forest | 5 blocks | +30% |
| Rooftop Park | 3 blocks | +20% |

Stacks with HVAC coverage.

---

## Air Requirements

| Block Type | Air Minimum | Notes |
|------------|-------------|-------|
| Budget Housing | 30% | Tolerates poor air |
| Standard Housing | 50% | Basic requirement |
| Premium Housing | 70% | Fresh air required |
| Office | 50% | Productivity |
| Industrial | 30% | Lower standard |
| Hospital | 80% | Clean air critical |

---

## Subterranean Air

Below grade air is harder:

```
Z = 0:  No penalty
Z = -1: -10% air quality
Z = -2: -20% air quality
Z = -3: -30% air quality

Compensation: More HVAC vents needed underground
```

---

## Air Quality Effects

| Air Level | Effect |
|-----------|--------|
| 80-100% | Fresh - health bonus |
| 60-80% | Good - no penalty |
| 40-60% | Acceptable - slight discomfort |
| 20-40% | Poor - health penalty, complaints |
| 0-20% | Dangerous - illness, exodus |

---

## Industrial Pollution

Industrial blocks reduce air quality:

| Block | Pollution Radius | Air Reduction |
|-------|------------------|---------------|
| Light Manufacturing | 3 blocks | -10% |
| Heavy Manufacturing | 5 blocks | -20% |
| Chemical Plant | 8 blocks | -30% |

Counteract with:
- HVAC ventilation
- Distance buffer
- Green space barriers

---

## See Also

- [light-system.md](./light-system.md) - Related environment system
- [noise-system.md](./noise-system.md) - Industrial effects
- [vibes-system.md](./vibes-system.md) - Uses air in calculation
- [../blocks/infrastructure.md](../blocks/infrastructure.md) - HVAC blocks
- [../blocks/green.md](../blocks/green.md) - Air-producing blocks
- [../blocks/industrial.md](../blocks/industrial.md) - Pollution sources
