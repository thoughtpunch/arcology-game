# Light System

[← Back to Environment](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Light is infrastructure. Natural light is harvested from exterior and distributed to interior through windows and light pipes.

---

## Light Sources

| Source | Quality | Notes |
|--------|---------|-------|
| Direct Sky (roof) | 100% | Only at top surface |
| Exterior Window | 70-90% | Penetrates 1-2 blocks deep |
| Atrium | 80-85% | Carries light to interior-facing blocks |
| Piped Light | 60-80% | Via light pipe network |
| Artificial Light | 35% effective | Always available, low quality |

---

## Natural Light Calculation

### Depth from Exterior

```
For interior blocks:

light_level = 100 - (depth_from_exterior × 20)

Where:
  depth = 0: exterior-facing (window) = 100%
  depth = 1: one block in = 80%
  depth = 2: two blocks in = 60%
  depth = 5+: 0% natural light
```

### Subterranean Penalty

```
Below grade (Z < 0):
  light_penalty = min(100, |Z| × 20)

At Z = -3: 60% penalty (max 40% natural light)
At Z = -5: 100% penalty (no natural light possible)
```

---

## Light Pipes

### Network

```
Solar Collector (roof) → Light Pipe → Junction → Interior block

Components:
1. Solar Collector - harvests light
2. Light Pipe - transfers light
3. Junction - distributes to multiple destinations
```

### Efficiency

```
piped_light = source_light × (efficiency ^ segments)

efficiency = 0.80 (20% loss per segment)

Example:
  Source: 100
  Segments: 3
  Result: 100 × 0.8³ = 51.2%
```

---

## Effective Light

The final light value uses the best available source:

```
effective_light = max(
    natural_light_score,
    piped_light_score,
    artificial_light_score × 0.35
)
```

Artificial light is always available but only 35% as effective.

---

## Light Requirements

### By Block Type

| Block Type | Light Minimum | Notes |
|------------|---------------|-------|
| Budget Housing | Any | Tolerates darkness |
| Standard Housing | 50% | Basic requirement |
| Premium Housing | 70% | High quality |
| Penthouse | 90% | Top tier |
| Office | 60% | Productivity |
| Restaurant | 40% | Ambiance |
| Industrial | 10% | Low requirement |

Blocks below minimum: **Failing** status.

---

## Atrium Light Wells

Atriums (vertical voids) bring light to interior:

```
Atrium spanning floors 5-15:

Floor 15 (top):    100% light at edge
Floor 10 (middle): 50% light at edge
Floor 5 (bottom):  0% light at edge

Falloff: 10% per floor down
```

Blocks with windows facing atrium receive this light level.

---

## Day/Night Cycle

Natural light varies with time:

| Time | Natural Light Multiplier |
|------|--------------------------|
| 06:00-09:00 | 0.5 → 1.0 (rising) |
| 09:00-17:00 | 1.0 (full) |
| 17:00-20:00 | 1.0 → 0.5 (setting) |
| 20:00-06:00 | 0.0 (night) |

At night: only piped/artificial light available.

---

## Formulas Reference

```
# Natural light from exterior
natural_light = 100 - (depth_from_exterior × 20) - subterranean_penalty

# Piped light
piped_light = source_light × (0.8 ^ segments)

# Effective light
effective_light = max(natural, piped, artificial × 0.35)

# Subterranean penalty
if Z < 0:
    penalty = min(100, abs(Z) × 20)
```

See [../../quick-reference/formulas.md](../../quick-reference/formulas.md#effective-light) for complete formula.

---

## See Also

- [air-system.md](./air-system.md) - Air quality
- [vibes-system.md](./vibes-system.md) - Uses light in calculation
- [../blocks/infrastructure.md](../blocks/infrastructure.md) - Solar collectors, light pipes
- [../blocks/green.md](../blocks/green.md) - Atriums
- [../../architecture/milestones/milestone-4-light.md](../../architecture/milestones/milestone-4-light.md) - Implementation
