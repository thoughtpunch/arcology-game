# Civic Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Civic blocks provide essential services: government, education, healthcare, safety, and community spaces.

---

## Government & Administration

| Block | Size | Jobs | Unlocks |
|-------|------|------|---------|
| Admin Center | 2×2 | 30 | Population cap increase |
| City Hall | 3×3 | 50 | Major decisions, events |
| Courthouse | 2×2 | 20 | Dispute resolution |
| Post Office | 1×1 | 4 | Mail services |

---

## Emergency Services

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Security Station | 1×1 | 4 | Safety radius |
| Police HQ | 2×2 | 20 | Large safety radius, station boost |
| Fire Station | 2×2 | 10 | Fire safety radius |
| Emergency Clinic | 2×2 | 15 | Crisis response |

### Safety System

Security stations reduce crime in radius:

```
Safety provided = base_coverage × (1 - distance/max_range)

Stacking: Multiple stations overlap, diminishing returns
```

See [../environment/safety-system.md](../environment/safety-system.md) for details.

---

## Education

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Daycare | 2×2 | 10 | Family support |
| School | 2×2 | 15 | Education radius, enables Family Housing |
| High School | 3×3 | 30 | Secondary education |
| University | 4×4 | 100 | Unlocks Tech Level 2, research |
| Trade School | 2×2 | 20 | Skilled workforce |
| Library | 2×2 | 8 | Education, +Purpose, quiet space |

### Education Chain

```
Daycare → School → High School → University/Trade School
```

Each level enables:
- More specialized housing
- Higher skill workers
- Tech level unlocks

---

## Healthcare

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Clinic | 2×2 | 6 | Healthcare radius |
| Hospital | 4×4 | 100 | Major healthcare |
| Mental Health Center | 2×2 | 15 | Crisis support |
| Senior Center | 2×2 | 6 | Elderly care, +Purpose |

### Healthcare Coverage

Residents need healthcare access:
- Within radius of Clinic: basic care
- Within radius of Hospital: advanced care
- No coverage: health declines, satisfaction drops

---

## Religious & Spiritual

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Chapel | 1×1 | 1 | +Belonging, +Purpose (small) |
| Church/Temple/Mosque | 2×2 | 4 | +Belonging, +Purpose (large) |
| Meditation Center | 1×1 | 2 | +Purpose, stress reduction |
| Interfaith Center | 3×3 | 6 | Multi-faith, diversity support |
| Funeral Home | 1×1 | 3 | Death services, memorial |

---

## Community & Culture

| Block | Size | Jobs | Effect |
|-------|------|------|--------|
| Community Center | 2×2 | 6 | +Belonging, event space |
| Cultural Center | 2×2 | 8 | Culture, diversity |
| Museum | 3×3 | 15 | Culture, education, tourism |
| Art Gallery | 2×2 | 6 | Culture, +Purpose, +Vibes |
| Theater | 3×3 | 20 | Entertainment, culture |

---

## Civic Block Strategy

### Essential Services
Every arcology needs:
- 1+ Security Station (safety)
- 1+ Clinic (healthcare)
- 1+ School (if families)
- Admin Center (governance)

### Community Building
For high cohesion:
- Community centers enable events
- Cultural centers support diversity
- Religious buildings provide belonging

---

## See Also

- [residential.md](./residential.md) - Housing that needs services
- [../human-simulation/needs.md](../human-simulation/needs.md) - How services meet needs
- [../environment/safety-system.md](../environment/safety-system.md) - Security system
- [../dynamics/human-nature.md](../dynamics/human-nature.md) - Community dynamics
- [../human-simulation/relationships.md](../human-simulation/relationships.md) - Social networks
