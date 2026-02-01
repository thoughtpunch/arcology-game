# Block Catalog

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Blocks are the atomic unit of construction. Every structure = blocks on a 3D grid.

---

## Block Categories

| Category | Purpose | Link |
|----------|---------|------|
| **Residential** | Housing for residents | [residential.md](./residential.md) |
| **Commercial** | Shops, restaurants, offices | [commercial.md](./commercial.md) |
| **Industrial** | Manufacturing, processing | [industrial.md](./industrial.md) |
| **Civic** | Government, education, healthcare | [civic.md](./civic.md) |
| **Entertainment** | Sports, leisure, culture | [entertainment.md](./entertainment.md) |
| **Transit** | Corridors, elevators, stairs | [transit.md](./transit.md) |
| **Infrastructure** | Power, water, HVAC | [infrastructure.md](./infrastructure.md) |
| **Green** | Parks, gardens, atriums | [green.md](./green.md) |

---

## Block Properties

Every block has:

### Needs
What the block requires to function:
- `power` - Electrical power units
- `water` - Water supply units
- `light_min` - Minimum light level (0-100)
- `air_min` - Minimum air quality (0-100)
- `path` - Must be connected to entrance

### Produces
What the block outputs:
- `rent` / `revenue` - Monthly income
- `jobs` - Employment capacity
- `vibes` - Quality improvement to area
- `noise` - Sound pollution
- Various resource radii

### Status
- **Functioning** - All needs met
- **Degraded** - Some needs unmet, reduced output
- **Failing** - Critical needs unmet, no output

---

## Mega-Blocks

Large special-purpose structures (5×5+ footprint):

| Mega-Block | Size | Primary Role |
|------------|------|--------------|
| Indoor Forest | 5×5×3 | Fresh air, vibes |
| Atrium | 3×3×5+ (void) | Natural light well |
| Grand Terminal | 5×5×2 | External transit |
| Arena | 6×6×3 | Entertainment events |
| Food Hall | 5×5×1 | PUBLIC food court |
| Medical Center | 5×5×2 | Healthcare |
| Sky Lobby | 4×4×2 | Transit hub |

---

## Public vs Private

| Type | Pathfinding | Examples |
|------|-------------|----------|
| Private | TO/FROM only | Apartments, shops |
| Public | THROUGH | Corridors, food halls |

---

## Adding New Block Types

1. Add to `data/blocks.json`:
```json
{
  "block_id": {
    "name": "Display Name",
    "size": [1, 1, 1],
    "cost": 500,
    "category": "residential",
    "traversable": false,
    "needs": { "power": 5, "light_min": 40 },
    "produces": { "rent_base": 100 },
    "mesh": "res://assets/models/blocks/block_id.tscn"
  }
}
```

2. Create 3D mesh in `assets/models/blocks/` (or use procedural geometry)

3. If special behavior needed, create script in `src/blocks/`

---

## See Also

- [../core-concepts.md](../core-concepts.md) - Grid and block fundamentals
- [../environment/](../environment/) - How environment affects blocks
- [../../architecture/milestones/milestone-9-block-types.md](../../architecture/milestones/milestone-9-block-types.md) - Implementation milestone
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - Rent and revenue formulas
