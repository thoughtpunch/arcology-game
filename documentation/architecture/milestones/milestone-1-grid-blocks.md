# Milestone 1: Grid & Blocks

**Goal:** Place and remove blocks on a 3D grid

---

## Features

### Core
- Grid class: sparse 3D dictionary of blocks
- Block base class: position, type, sprite
- Block registry: load definitions from JSON

### Rendering
- Isometric camera setup
- Block sprites render at correct positions
- Y-sorting for depth (higher Z = behind)

### Input
- Click to place block
- Right-click to remove
- Simple block picker (just 3-4 types)

### Data
- blocks.json with 4 block types:
  - Corridor (1x1)
  - Residential (1x1)
  - Commercial (1x1)
  - Empty/Void

---

## Deliverable

You can build a little structure by clicking. Blocks stack. It looks isometric.

---

## Key Code

### grid.gd

```gdscript
class_name Grid
extends Node

signal block_placed(block: Block)
signal block_removed(block: Block)

var blocks: Dictionary = {}  # Vector3i -> Block

func set_block(pos: Vector3i, block: Block) -> void:
    blocks[pos] = block
    block_placed.emit(block)

func get_block(pos: Vector3i) -> Block:
    return blocks.get(pos)

func remove_block(pos: Vector3i) -> void:
    var block = blocks.get(pos)
    if block:
        blocks.erase(pos)
        block_removed.emit(block)

func world_to_grid(world_pos: Vector2, z_level: int) -> Vector3i:
    # Isometric conversion - see isometric-math.md
    pass

func grid_to_world(grid_pos: Vector3i) -> Vector2:
    # Isometric conversion - see isometric-math.md
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
    y -= grid_pos.z * FLOOR_HEIGHT
    return Vector2(x, y)
```

### block.gd

```gdscript
class_name Block
extends RefCounted

var grid_position: Vector3i
var block_type: String
var sprite: Sprite2D

func _init(type: String, pos: Vector3i):
    block_type = type
    grid_position = pos
```

### data/blocks.json

```json
{
  "corridor": {
    "name": "Corridor",
    "size": [1, 1, 1],
    "cost": 50,
    "category": "transit",
    "traversable": true,
    "sprite": "res://assets/sprites/blocks/corridor.png"
  },
  "residential_basic": {
    "name": "Basic Apartment",
    "size": [1, 1, 1],
    "cost": 500,
    "category": "residential",
    "capacity": 4,
    "sprite": "res://assets/sprites/blocks/residential_basic.png"
  },
  "commercial_basic": {
    "name": "Small Shop",
    "size": [1, 1, 1],
    "cost": 800,
    "category": "commercial",
    "sprite": "res://assets/sprites/blocks/commercial_basic.png"
  }
}
```

---

## Isometric Constants

```gdscript
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32
const FLOOR_HEIGHT: int = 24
```

See [isometric-math.md](../../quick-reference/isometric-math.md) for full conversion formulas.

---

## Acceptance Criteria

- [ ] Grid stores blocks by Vector3i position
- [ ] Click places selected block type
- [ ] Right-click removes block
- [ ] Blocks appear at correct isometric positions
- [ ] Blocks stack visually (higher Z appears in front of lower Y)
- [ ] Block definitions load from JSON
- [ ] At least 3 block types available
- [ ] Signals emit on place/remove
