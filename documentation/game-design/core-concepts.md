# Core Concepts

[← Back to Game Design](./README.md) | [← Back to Documentation](../README.md)

---

## Grid Architecture

The world is a 3D voxel grid. Every structure = blocks snapped to grid.

```
Grid: 3D array of cells
Each cell: 1 block or empty
Coordinate system: Vector3i(x, y, z)
  - x, y = horizontal position
  - z = floor level (0 = ground, positive = up, negative = down)
```

### Rectilinear Design

All blocks are axis-aligned rectangles. No diagonal blocks (except escalators).

This enables:
- Simple pathfinding
- Easy adjacency calculations
- Clean visual style

---

## Block Types

### By Traversability

| Type | Pathfinding | Examples |
|------|-------------|----------|
| **Private** | Routes TO/FROM | Apartments, shops, offices |
| **Public** | Routes THROUGH | Corridors, atriums, food halls |

### By Size

| Size | Footprint | Examples |
|------|-----------|----------|
| Small | 1×1 | Basic apartment, corridor |
| Medium | 2×2 | Restaurant, clinic |
| Large | 3×3 to 4×4 | Grocery, office floor |
| Mega | 5×5+ | Food hall, arena, indoor forest |

---

## Structural Rules

### CNC-U Material

All blocks are made of **Carbonic Nano-Cement - Universal** (CNC-U):
- Load-bearing in all orientations
- No structural engineering required
- No support columns needed

### Cantilevers

Blocks can extend:
- **1-2 blocks** unsupported horizontally
- Unlimited if another block is below

### Vertical Limits

- Maximum height determined by airspace permits
- Maximum depth determined by excavation permits
- See [economy/permits.md](./economy/permits.md)

---

## Emergent Envelope

The building exterior is auto-generated from block placement:

```
ENVELOPE RULE:
Any block face that borders "outside" (void at edge of structure)
automatically gets a panel.
```

### Panel Materials

| Material | Light | Air | Sound | Cost | Notes |
|----------|-------|-----|-------|------|-------|
| Solid Wall | 0% | 0% | -50dB | Base | Default |
| Window | 70% | 0% | -30dB | +50% | Exterior-facing |
| Glass Wall | 85% | 0% | -20dB | +100% | Premium |
| Vent Panel | 0% | 100% | -10dB | +25% | Air exchange |
| Force Field | 95% | 100%* | 0dB | +500% | Mars/Space only |

---

## Public vs Private Blocks

### Private Blocks

- **Destination only** - agents walk TO them, not THROUGH
- Examples: apartments, shops, offices
- Have occupants/tenants
- Generate rent/revenue

### Public Blocks

- **Traversable** - agents can walk THROUGH
- Examples: corridors, atriums, food halls
- Capture foot traffic
- No direct rent (but enable other blocks)

### Food Hall Example

The Food Hall is a **public mega-block**:
- Agents route through it (shortcut)
- Captures through-traffic for food sales
- Pleasant to traverse (low pathfinding cost)

---

## Environment Properties

Every block has environment values (0-100):

| Property | Source | Affects |
|----------|--------|---------|
| Light | Sky, windows, light pipes | Desirability, mood |
| Air | HVAC, exterior, atriums | Health, comfort |
| Noise | Traffic, machinery, entertainment | Sleep, productivity |
| Safety | Security, lighting, crime | Security needs |
| Vibes | Composite quality score | Rent, satisfaction |

See [environment/](./environment/) for details.

---

## The Five Human Needs

Residents have five core needs (Maslow hierarchy):

```
PURPOSE     → meaning, growth
ESTEEM      → respect, status
BELONGING   → relationships
SAFETY      → security
SURVIVAL    → food, shelter, health
```

**Lower needs must be met before higher ones matter.**

See [human-simulation/needs.md](./human-simulation/needs.md) for details.

---

## Crime Doesn't Climb

Upper floors are naturally safer:

```
Crime pressure decreases with height:
  Ground floor: base crime pressure
  Each floor up: -5% crime propagation chance

Result: crime concentrates on lower floors unless
security measures are in place.
```

This creates organic social geography.

See [environment/safety-system.md](./environment/safety-system.md) for details.

---

## Light Is Infrastructure

Natural light is a valuable resource:
- Harvested at roof/exterior via solar collectors
- Distributed via light pipes
- Deep interiors NEED light infrastructure

See [environment/light-system.md](./environment/light-system.md) for details.

---

## See Also

- [blocks/](./blocks/) - Block catalog
- [environment/](./environment/) - Environment systems
- [human-simulation/](./human-simulation/) - Agent simulation
- [transit/](./transit/) - Pathfinding and movement
- [../quick-reference/glossary.md](../quick-reference/glossary.md) - Term definitions
