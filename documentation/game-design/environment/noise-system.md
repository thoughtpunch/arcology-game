# Noise System

[← Back to Environment](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Noise affects sleep, concentration, and stress. It propagates from corridors, entertainment, and industrial blocks.

---

## Noise Sources

| Source | Noise Level | Notes |
|--------|-------------|-------|
| Corridor traffic | Variable | Based on foot traffic |
| Nightclub | 60-80 | Night hours |
| Industrial | 30-70 | Daytime |
| HVAC | 10-20 | Constant hum |
| Entertainment | 40-60 | Event-dependent |

---

## Corridor Noise

Traffic creates noise:

```
traffic_noise = current_traffic × NOISE_PER_PERSON[corridor_type]

NOISE_PER_PERSON:
  Small (1×1):       0.8
  Medium (2×1):      0.5
  Large (3×2):       0.3
  Grand Promenade:   0.2

Wider corridors = less noise per person
```

---

## Noise Propagation

Noise spreads to adjacent blocks with falloff:

```
immediate_neighbor = corridor_noise × 0.80
one_block_away = corridor_noise × 0.40
two_blocks_away = corridor_noise × 0.15

Wall reduction:
  Solid wall: × 0.50
  Glass wall: × 0.80
  Open/void:  × 1.00

received_noise = corridor_noise × distance_factor × wall_factor
```

---

## Noise Mitigation

### Acoustic Upgrades

| Upgrade | Noise Reduction | Cost |
|---------|-----------------|------|
| Acoustic Panels | -20 | $250 |
| Premium Flooring | -5 | $200 |
| Soundproof Walls | -30 | $400 |

### Green Buffers

Green blocks reduce noise:

| Block | Noise Reduction |
|-------|-----------------|
| Planter | -2 |
| Courtyard Garden | -8 |
| Indoor Forest | -15 |

### Underground Placement

Subterranean naturally isolates noise:
- Nightclubs work well underground
- Industrial contained below
- Less propagation to residential

---

## Noise Effects

| Noise Level | Effect |
|-------------|--------|
| 0-20 | Quiet - sleep bonus |
| 20-40 | Normal - no effect |
| 40-60 | Noisy - concentration penalty |
| 60-80 | Loud - sleep penalty, stress |
| 80+ | Extreme - health impact, complaints |

---

## Time-of-Day Sensitivity

Noise tolerance varies:

| Time | Tolerance |
|------|-----------|
| Day (08:00-22:00) | Normal |
| Night (22:00-08:00) | -20 threshold |

Night noise is worse because residents are trying to sleep.

---

## Sound Generators

Some corridor upgrades add pleasant noise:

| Upgrade | Noise Added | Vibes Added |
|---------|-------------|-------------|
| Nature Sounds | +5 | +10 |
| Ambient Music | +8 | +8 |
| Fountain | +10 | +15 |

These sounds improve vibes despite adding to noise level.

---

## Quiet Requirements

Some blocks need low noise:

| Block | Max Noise | Notes |
|-------|-----------|-------|
| Premium Housing | 30 | Sleep quality |
| Library | 20 | Concentration |
| Meditation Center | 15 | Serenity |
| Hospital | 40 | Patient rest |

Exceeding max noise = degraded function.

---

## Strategic Noise Management

```
Pattern: Buffer zones

Residential → Corridor (wide) → Commercial → Corridor → Industrial
    ↓
Low noise received because:
  - Commercial absorbs some noise
  - Wide corridors reduce per-person noise
  - Distance falloff from industrial
```

---

## See Also

- [air-system.md](./air-system.md) - Industrial pollution
- [vibes-system.md](./vibes-system.md) - Noise affects vibes
- [../blocks/entertainment.md](../blocks/entertainment.md) - Nightlife noise
- [../blocks/industrial.md](../blocks/industrial.md) - Industrial noise
- [../transit/corridors.md](../transit/corridors.md) - Traffic noise
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#corridor-noise) - Noise formulas
