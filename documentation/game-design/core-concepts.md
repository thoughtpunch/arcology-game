# Core Concepts

[← Back to Game Design](./README.md) | [← Back to Documentation](../README.md)

---

## Grid Architecture

The world is a 3D voxel grid. Every structure = blocks snapped to grid.

```
Grid: 3D array of cells (orthogonal Y-up)
Each cell: 1 block or empty
Cell size: 6m x 6m x 6m (true cube)

Coordinate system: Vector3i(x, y, z)
  - x = east-west (positive = east)
  - y = vertical (0 = ground, positive = up, negative = excavation)
  - z = north-south (positive = north)
```

### The Cell

The **cell** is the atomic unit of space. Every block occupies one or more cells.

```
CELL DIMENSIONS
===============
Width:  6m (X axis)
Height: 6m (Y axis)
Depth:  6m (Z axis)

Internal floors: 2 residential floors at 3m each
                 OR 1 double-height commercial/civic floor

         +---------------+
        /               /|
       /       6m      / |
      +---------------+  |
      |               |  | 6m
      |   1 CELL      |  |
      |               | /
      |               |/ 6m
      +---------------+
```

### Cell Faces

Each cell has **6 faces** for adjacency, panel generation, and pathfinding connections:

| Face | Direction | Normal Vector | Notes |
|------|-----------|---------------|-------|
| TOP | Y+ | (0, 1, 0) | Roof/ceiling |
| BOTTOM | Y- | (0, -1, 0) | Floor |
| NORTH | Z+ | (0, 0, 1) | |
| SOUTH | Z- | (0, 0, -1) | |
| EAST | X+ | (1, 0, 0) | |
| WEST | X- | (-1, 0, 0) | |

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

### By Size (Cell Footprint)

| Size | Cells | Examples |
|------|-------|----------|
| Small | 1×1×1 | Basic apartment (2 units), corridor |
| Medium | 2×1×1 to 2×2×1 | Restaurant, clinic |
| Large | 3×2×1 to 4×4×1 | Grocery, office floor |
| Mega | 5×5×1+ | Food hall, arena, indoor forest |

Multi-cell blocks can extend vertically too (2×2×2 for grand lobbies, etc.).

---

## Structural Rules

### CNC-U Material

All blocks are made of **Carbonic Nano-Cement - Universal** (CNC-U):
- Load-bearing in all orientations
- No structural engineering required
- No support columns needed

### Cantilevers

Blocks can extend:
- **1-2 cells** unsupported horizontally
- Unlimited if another block is below

### Vertical Limits

- Maximum height determined by airspace permits
- Maximum depth determined by excavation permits
- See [economy/permits.md](./economy/permits.md)

---

## Emergent Envelope

The building exterior is auto-generated from block placement. The **envelope** is the 3D volume boundary of the structure.

```
ENVELOPE RULE:
Any cell face that borders "outside" (void at edge of structure)
automatically gets a panel mesh generated on that face.

This applies to all 6 face directions (TOP, BOTTOM, NORTH, SOUTH, EAST, WEST).
```

### Panels

Panels are **3D meshes** auto-generated on exterior-facing cell faces. They are not separate placed objects—they emerge from the boundary between occupied cells and void.

**How it works:**
1. Player places blocks
2. System detects which cell faces touch exterior/void
3. Panel meshes auto-generate on those faces
4. Player can upgrade panel materials per face

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
  Ground floor (Y=0): base crime pressure
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
- [../architecture/3d-refactor/specification.md](../architecture/3d-refactor/specification.md) - Full 3D architecture spec
