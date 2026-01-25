# Entertainment Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Entertainment blocks provide recreation, leisure, and cultural activities. They improve resident satisfaction and meet belonging/esteem needs.

---

## Sports & Fitness

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Gym | 2×2 | 6 | +Health, +Belonging |
| Sports Court | 2×2 | 2 | Recreation, team sports |
| Swimming Pool | 3×3 | 8 | Health, recreation |
| Arena | 6×6 | 50 | Major events, pro sports |
| Bowling Alley | 2×2 | 6 | Social activity |
| Ice Rink | 3×3 | 10 | Winter sports |

---

## Entertainment Venues

| Block | Size | Jobs | Notes |
|-------|------|------|-------|
| Cinema | 2×2 | 8 | Movies |
| Arcade | 1×1 | 4 | Youth entertainment |
| VR Lounge | 1×1 | 4 | Tech Level 2 |
| Nightclub | 2×2 | 10 | Night economy, **noise** |
| Comedy Club | 1×1 | 4 | +Belonging |
| Casino | 3×3 | 30 | High revenue |

---

## Relaxation & Leisure

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Spa | 2×2 | 8 | +Esteem, luxury |
| Sauna | 1×1 | 2 | Health |
| Social Club | 2×2 | 4 | +Belonging, +Esteem |
| Game Room | 1×1 | 2 | Casual social |
| Karaoke Bar | 1×1 | 3 | +Belonging, **noise** |

---

## Night Economy

Some entertainment thrives at night:

| Block | Peak Hours | Notes |
|-------|------------|-------|
| Nightclub | 22:00-04:00 | High noise, conflict with residential |
| Bar | 18:00-02:00 | Moderate noise |
| Casino | 24 hours | Constant activity |

### Noise Management

Night venues produce noise:
```
Nightclub: 60-80 noise level
Bar: 30-50 noise level
Karaoke: 40-60 noise level
```

Solutions:
- Place underground (natural soundproofing)
- Buffer zones between residential
- Acoustic upgrades to corridors

---

## Subterranean Entertainment

Works well underground:

| Block | Why Underground Works |
|-------|----------------------|
| Nightclub | Darkness is aesthetic, contains noise |
| Bar | Evening atmosphere |
| Arcade | No window needs |
| VR Lounge | Immersive environment |

---

## Arena Events

The Arena (mega-block) hosts periodic events:

| Event Type | Attendance | Revenue | Frequency |
|------------|------------|---------|-----------|
| Concert | 2,000-5,000 | High | Monthly |
| Sports Game | 1,500-3,000 | Medium | Weekly |
| Convention | 1,000-3,000 | Medium | Quarterly |
| Special Event | 5,000+ | Very High | Annual |

Events boost:
- Foot traffic
- Commercial revenue
- Community cohesion
- External visitors

---

## Needs Addressed

| Block Type | Primary Need | Secondary Need |
|------------|--------------|----------------|
| Gym/Sports | Health (Survival) | Belonging |
| Spa | Esteem | Survival |
| Social Club | Belonging | Esteem |
| Entertainment | Purpose | Belonging |

---

## See Also

- [commercial.md](./commercial.md) - Food and beverage venues
- [../human-simulation/needs.md](../human-simulation/needs.md) - Needs system
- [../environment/noise-system.md](../environment/noise-system.md) - Noise management
- [../transit/corridors.md](../transit/corridors.md) - Foot traffic
- [../economy/permits.md](../economy/permits.md) - Subterranean placement
