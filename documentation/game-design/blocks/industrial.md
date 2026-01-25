# Industrial Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Industrial blocks produce goods, provide jobs, and generate revenue. They often create noise and pollution but tolerate low-quality environments.

---

## Manufacturing

| Block | Size | Jobs | Revenue | Produces |
|-------|------|------|---------|----------|
| Light Manufacturing | 2×2 | 20 | $300 | Goods, Noise |
| Heavy Manufacturing | 3×3 | 50 | $600 | Goods, Pollution, Noise |
| Electronics Factory | 2×2 | 25 | $450 | Electronics, Low Noise |
| Textile Mill | 2×2 | 30 | $350 | Textiles, Noise |
| Metal Fabrication | 2×2 | 15 | $400 | Metal Parts, Noise |
| 3D Print Farm | 2×2 | 10 | $350 | Custom Goods |

---

## Maker & Fabrication

| Block | Size | Jobs | Notes |
|-------|------|------|-------|
| Maker Space | 2×2 | 4 | +Purpose, community innovation |
| Fab Lab | 2×2 | 8 | Prototyping, Tech Level 2 |
| Repair Shop | 1×1 | 3 | Reduces waste |
| Craft Workshop | 1×1 | 2 | +Purpose, artisan goods |
| Woodworking Shop | 1×1 | 3 | Furniture, low noise |

---

## Processing & Storage

| Block | Size | Jobs | Notes |
|-------|------|------|-------|
| Warehouse | 2×2 | 4 | Storage, freight distribution |
| Cold Storage | 2×2 | 4 | Food preservation |
| Data Center | 2×2 | 10 | High power, produces heat |
| Recycling Center | 2×2 | 15 | Resource recovery |
| Waste Processing | 2×2 | 10 | Odor, essential |

---

## Food Production

| Block | Size | Jobs | Notes |
|-------|------|------|-------|
| Vertical Farm | 2×2 | 10 | Raw food, fresh air |
| Hydroponics Bay | 1×1 | 4 | Compact farming |
| Mushroom Farm | 2×2 | 6 | No light needed! |
| Aquaculture Tank | 2×2 | 8 | Protein source |
| Food Processing | 2×2 | 15 | Converts raw → processed |

---

## Subterranean Optimization

Industrial blocks work well underground:

| Block | Why Subterranean Works |
|-------|----------------------|
| Warehouse | No light/air needs |
| Data Center | Cool temperatures, security |
| Heavy Manufacturing | Noise/pollution contained |
| Mushroom Farm | Doesn't need sunlight |
| Recycling Center | Processes waste, no residents |

---

## Negative Effects

### Noise Generation

| Source | Noise Level | Radius |
|--------|-------------|--------|
| Light Manufacturing | 40 | 3 blocks |
| Heavy Manufacturing | 70 | 5 blocks |
| Fabrication | 30 | 2 blocks |

### Pollution

| Source | Pollution Level |
|--------|-----------------|
| Heavy Manufacturing | High |
| Chemical Plant | Very High |
| Plastics Factory | Medium |

Pollution affects air quality in radius.

---

## Worker Housing Synergy

Industrial needs nearby housing for workers:

- **Worker Housing** tolerates industrial noise
- Short commutes = happier workers
- Create industrial districts with mixed-use buffers

---

## See Also

- [residential.md](./residential.md) - Worker housing
- [infrastructure.md](./infrastructure.md) - Power requirements
- [../environment/noise-system.md](../environment/noise-system.md) - Noise propagation
- [../environment/air-system.md](../environment/air-system.md) - Pollution effects
- [../economy/permits.md](../economy/permits.md) - Subterranean permits
