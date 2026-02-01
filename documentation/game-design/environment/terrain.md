# Terrain System

[← Back to Environment](./README.md) | [← Back to Documentation](../../README.md)

---

## Overview

The terrain is the base layer beneath the arcology grid. It provides visual context for the scenario and defines the "ground" at Z=0.

**Key principle:** Terrain is decorative and scenario-themed, not gameplay-affecting (blocks placed on Z=0 replace terrain visuals).

---

## Terrain Components

### 1. Base Plane

The ground surface rendered beneath all blocks:

| Scenario | Base Color | Texture |
|----------|------------|---------|
| Earth Urban | `#4a7c4e` grass green | Subtle noise/grass |
| Earth Remote | `#5d8a5f` meadow green | Grass with wildflowers |
| Mars | `#8b4513` rust red | Rocky, dusty |
| Space Station | Transparent | PNG starfield background |

### 2. Decoration Sprites

Random scatter of environmental objects:

| Category | Sizes | Examples |
|----------|-------|----------|
| Vegetation | 1x1 | Trees, bushes, flowers |
| Rocks | 1x1, 2x2 | Boulders, rock clusters |
| Water | Irregular | Rivers, ponds |
| Debris | 1x1 | Mars rocks, space junk |

### 3. Background Layer

Behind the terrain plane (for parallax/depth):

| Scenario | Background |
|----------|------------|
| Earth | Sky gradient, distant mountains |
| Mars | Orange sky, distant craters |
| Space | Starfield PNG, distant planets |

---

## Scenario Themes

### Earth (Default)

```
Base: Green grass plane with subtle height variation
Decorations:
  - Trees (1x1): oak, pine, deciduous mix
  - Rocks (1x1): small boulders, stones
  - Rocks (2x2): large boulder formations
  - River: winding water feature (impassable until bridged)
  - Bushes, flowers, grass tufts
Background: Blue sky gradient
```

### Mars Colony

```
Base: Rust-red rocky plane
Decorations:
  - Rocks (1x1, 2x2, 3x3): Martian boulders
  - Craters: shallow depressions
  - Dust dunes: wind-shaped formations
  - NO vegetation (until greenhouse blocks)
Background: Orange-pink sky, distant mountains
```

### Space Station

```
Base: Transparent (no ground plane)
Decorations: None (pure void)
Background: High-res starfield PNG
  - Optional: distant Earth, Moon, or planets
  - Optional: subtle nebula colors
```

---

## Technical Implementation

### Terrain Layer

```gdscript
# Terrain renders BELOW the block grid
# Z-index: -1000 (always behind blocks)

class_name Terrain
extends Node2D

var theme: String = "earth"  # "earth", "mars", "space"
var decorations: Array[TerrainDecoration] = []

func _ready():
    z_index = -1000
    load_theme(theme)
```

### Decoration Placement

Decorations are placed procedurally at scene load:

```gdscript
# Scatter algorithm (simplified)
func scatter_decorations(density: float, area: Rect2i):
    var rng = RandomNumberGenerator.new()
    rng.seed = world_seed  # Deterministic per-world

    for x in range(area.position.x, area.end.x):
        for y in range(area.position.y, area.end.y):
            if rng.randf() < density:
                var type = pick_weighted_type(rng)
                place_decoration(Vector2i(x, y), type)
```

### Grid Interaction

When a block is placed at Z=0:
- Decorations at that grid position are hidden/removed
- Base plane shows through if block has transparency

When a block is removed from Z=0:
- Decorations can optionally regenerate (or stay cleared)

---

## Decoration Sprites

### File Structure

```
assets/sprites/terrain/
├── earth/
│   ├── tree_oak.png
│   ├── tree_pine.png
│   ├── rock_small.png
│   ├── rock_large.png      # 2x2
│   ├── bush.png
│   ├── flowers.png
│   └── river_tiles/
│       ├── straight.png
│       ├── corner.png
│       └── end.png
├── mars/
│   ├── rock_small.png
│   ├── rock_medium.png
│   ├── rock_large.png      # 2x2
│   ├── crater_small.png
│   └── dune.png
└── backgrounds/
    ├── earth_sky.png
    ├── mars_sky.png
    └── space_stars.png
```

### Sprite Dimensions

| Size | Pixels | Grid Cells |
|------|--------|------------|
| 1x1 | 64x64 | 1 cell |
| 2x2 | 128x96 | 4 cells |
| 3x3 | 192x128 | 9 cells |

Note: Heights vary (trees taller than rocks) but footprint matches grid.

---

## River System

Rivers are special terrain features:

```
Properties:
  - Impassable at Z=0 (must be bridged)
  - Can be covered by blocks (becomes underground)
  - Provides water for nearby blocks
  - Visual: animated water tiles

Placement:
  - Pre-defined path per map seed
  - Crosses map edge-to-edge
  - Width: 1-2 tiles
```

---

## Data Schema

```json
// data/terrain.json
{
  "themes": {
    "earth": {
      "base_color": "#4a7c4e",
      "base_texture": "grass_noise",
      "decorations": [
        {"type": "tree_oak", "weight": 0.3, "size": [1, 1]},
        {"type": "tree_pine", "weight": 0.2, "size": [1, 1]},
        {"type": "rock_small", "weight": 0.2, "size": [1, 1]},
        {"type": "rock_large", "weight": 0.1, "size": [2, 2]},
        {"type": "bush", "weight": 0.15, "size": [1, 1]},
        {"type": "flowers", "weight": 0.05, "size": [1, 1]}
      ],
      "decoration_density": 0.08,
      "has_river": true,
      "background": "earth_sky.png"
    },
    "mars": {
      "base_color": "#8b4513",
      "base_texture": "rocky_dust",
      "decorations": [
        {"type": "rock_small", "weight": 0.4, "size": [1, 1]},
        {"type": "rock_medium", "weight": 0.3, "size": [1, 1]},
        {"type": "rock_large", "weight": 0.2, "size": [2, 2]},
        {"type": "crater_small", "weight": 0.1, "size": [1, 1]}
      ],
      "decoration_density": 0.12,
      "has_river": false,
      "background": "mars_sky.png"
    },
    "space": {
      "base_color": null,
      "base_texture": null,
      "decorations": [],
      "decoration_density": 0,
      "has_river": false,
      "background": "space_stars.png"
    }
  }
}
```

---

## Rendering Order

```
Layer stack (back to front):
1. Background (sky/stars)     z_index: -2000
2. Terrain base plane         z_index: -1000
3. Terrain decorations        z_index: -500 to -100
4. Grid blocks (Y-sorted)     z_index: 0+
5. UI overlays                z_index: 1000+
```

---

## Underground (Z < 0)

Below grade, the terrain is **solid earth/rock** that must be excavated:

### Excavation Rules

```
Z = 0:  Surface (grass, decorations)
Z = -1: Topsoil (easy dig, cheap)
Z = -2: Subsoil (moderate dig)
Z = -3: Bedrock (hard dig, expensive)
Z < -3: Deep rock (requires permits)
```

### Visual Representation

When viewing underground floors:
- Unexcavated cells show as solid rock/earth tiles
- Excavated cells show as empty (block can be placed)
- Cross-section view shows layers

### Underground Terrain Sprites

| Depth | Earth | Mars |
|-------|-------|------|
| Z = -1 | Brown soil | Red regolith |
| Z = -2 | Clay/rock mix | Orange rock |
| Z = -3+ | Gray bedrock | Dark basalt |

### Excavation Cost

See [economy/permits.md](../economy/permits.md#excavation) for costs.

```
excavation_cost = base_cost × depth_multiplier × hardness
depth_multiplier = 1.5 ^ abs(z)
```

---

## Future Considerations

- **Terraforming (Mars):** Greenhouse blocks gradually add vegetation
- **Seasons (Earth):** Snow in winter, fall colors
- **Destruction:** Meteor impacts, erosion over time
- **Underwater cities:** Ocean floor terrain (future scenario)

---

## See Also

- [scenarios.md](../scenarios.md) - Scenario parameters
- [../../quick-reference/3d-grid-math.md](../../quick-reference/3d-grid-math.md) - 3D grid coordinates
- [../../architecture/milestones/](../../architecture/milestones/) - Implementation phases
