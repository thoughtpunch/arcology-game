# Infrastructure Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Infrastructure blocks provide essential services: power, water, HVAC, and light distribution.

---

## Power Generation

| Block | Size | Output | Needs | Notes |
|-------|------|--------|-------|-------|
| Power Plant (Fossil) | 3×3 | High | Water | Pollution, noise |
| Power Plant (Solar) | 2×2 | Variable | Natural light | Clean, requires roof/exterior |
| Power Plant (Nuclear) | 4×4 | Very High | Water | Tech Level 2, subterranean |
| Geothermal Plant | 3×3 | High | Deep placement | Mars essential |

### Power Requirements

Every block needs power:
```
power_available >= Σ(block.power_need)
```

Insufficient power = blocks fail.

---

## Water Systems

| Block | Size | Capacity | Notes |
|-------|------|----------|-------|
| Water Treatment | 3×3 | Base supply | Essential |
| Water Tower | 3×3 | Pressure boost | Required for high floors |
| Waste Processing | 2×2 | Waste disposal | Produces odor |

### Water Pressure

```
Floors 0-10:  Water Treatment sufficient
Floors 11-30: Need Water Tower
Floors 31+:   Need multiple Water Towers or pumping
```

---

## HVAC (Air)

| Block | Size | Coverage | Notes |
|-------|------|----------|-------|
| HVAC Central | 2×2 | Large radius | Main air processor |
| HVAC Vent | 1×1 | Small radius | Distribution point |

### Air Quality

Blocks need air:
- Exterior-facing: natural air
- Interior: requires HVAC coverage
- Deep interior: multiple vents needed

See [../environment/air-system.md](../environment/air-system.md) for details.

---

## Light Infrastructure

| Block | Size | Output | Needs |
|-------|------|--------|-------|
| Solar Collector | 1×1 | Piped Light + Power | Natural light |
| Light Pipe Junction | 1×1 | Distributes light | Piped light input |

### Light Distribution

```
Solar Collector (roof) → Light Pipe → Junction → Interior block
                                        ↓
                    Efficiency loss: 20-40% per segment
```

See [../environment/light-system.md](../environment/light-system.md) for details.

---

## Utility Distribution

### Utility Chase

```
Size: 1×1
Purpose: High-capacity utility routing
NOT traversable (pipes only)
Capacity: Power 100, Water 50, Data 50
```

### Utility Corridor

```
Size: 1×1
Purpose: Combined transit + utilities
Traversable (people walk through)
Capacity: Power 50, Water 25, Data 25
```

---

## Infrastructure Planning

### Minimum Requirements

For a functioning arcology:

| Service | Minimum |
|---------|---------|
| Power | 1× Power Plant |
| Water | 1× Water Treatment |
| Air | 1× HVAC Central |
| Light | Solar Collectors for interior |

### Scaling

| Population | Power Plants | Water Treatment | HVAC Central |
|------------|--------------|-----------------|--------------|
| <5,000 | 1 | 1 | 1-2 |
| 5,000-20,000 | 2-3 | 2 | 3-5 |
| 20,000-50,000 | 4-6 | 3-4 | 6-10 |
| 50,000+ | 8+ | 5+ | 12+ |

---

## Redundancy

Critical systems should have backups:

```
BACKUP SYSTEMS:
- Primary + backup power plant
- Multiple water sources
- Distributed HVAC (not single point of failure)

Failure cascade:
Power fails → HVAC fails → Air quality drops → Residents suffer
```

See [../dynamics/entropy.md](../dynamics/entropy.md) for failure mechanics.

---

## See Also

- [../environment/light-system.md](../environment/light-system.md) - Light distribution
- [../environment/air-system.md](../environment/air-system.md) - Air quality
- [transit.md](./transit.md) - Utility corridors
- [../dynamics/entropy.md](../dynamics/entropy.md) - Infrastructure decay
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - Power calculations
