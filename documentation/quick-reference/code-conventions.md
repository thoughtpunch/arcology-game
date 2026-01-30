# Code Conventions

## GDScript Style Guide

### Naming

```gdscript
# Classes: PascalCase with class_name declaration
class_name BlockRegistry
extends Node

# Functions/variables: snake_case with type hints
func get_block_at(pos: Vector3i) -> Block:
    return blocks.get(pos)

# Signals: past tense
signal block_placed(block: Block)
signal resident_moved_in(resident: Resident)

# Constants: UPPER_SNAKE_CASE
const CELL_SIZE: float = 6.0
const GROUND_SIZE: int = 100
const GROUND_DEPTH: int = 5
```

### Type Hints

Always use type hints for:
- Function parameters
- Function return types
- Class properties

```gdscript
# Good
func calculate_rent(block: Block, desirability: float) -> int:
    return int(block.base_rent * desirability)

# Bad
func calculate_rent(block, desirability):
    return block.base_rent * desirability
```

### Signals vs Polling

**Use signals, not polling:**

```gdscript
# GOOD - Signal-based updates
signal block_placed(block: Block)
signal block_removed(block: Block)

# In environment system
func _ready():
    Grid.block_placed.connect(_on_block_changed)
    Grid.block_removed.connect(_on_block_changed)

func _on_block_changed(block: Block):
    recalculate_light_for_area(block.grid_position)

# BAD - Polling
func _process(delta):
    if grid_changed:  # Don't do this
        recalculate_everything()
```

### System Independence

Systems shouldn't know about each other directly:

```gdscript
# BAD - Tight coupling
func calculate_rent():
    var light = LightSystem.get_light(position)  # Direct reference

# GOOD - Data on block
func calculate_rent():
    var light = block.environment.light  # Block caches its environment
```

### Lazy Recalculation

Don't recalculate everything every frame:

```gdscript
var _light_dirty: bool = false
var _dirty_blocks: Array[Vector3i] = []

func mark_dirty(pos: Vector3i):
    _light_dirty = true
    _dirty_blocks.append(pos)

func _process(delta):
    if _light_dirty:
        recalculate_dirty_blocks()
        _light_dirty = false
        _dirty_blocks.clear()
```

## Data-Driven Design

**Keep balance numbers OUT of code. Load from JSON:**

```json
// data/blocks.json
{
  "residential_basic": {
    "name": "Basic Apartment",
    "size": [1, 1, 1],
    "cost": 500,
    "category": "residential",
    "capacity": 4,
    "needs": {
      "power": 5,
      "light_min": 20
    },
    "produces": {
      "rent_base": 100
    },
    "sprite": "res://assets/sprites/blocks/residential_basic.png"
  }
}
```

```gdscript
# Load at runtime
var balance = load_json("res://data/balance.json")
var light_falloff = balance.light_falloff_per_floor
```

## Common Patterns

### Grid Position

Use `Vector3i` for grid positions:
- `x, y` = horizontal position
- `z` = floor level

```gdscript
var pos = Vector3i(5, 3, 2)  # x=5, y=3, floor=2
```

### Block Registry Pattern

```gdscript
class_name BlockRegistry

var _block_types: Dictionary = {}

func register(type_id: String, definition: Dictionary) -> void:
    _block_types[type_id] = definition

func get_definition(type_id: String) -> Dictionary:
    return _block_types.get(type_id, {})
```

### Resource Cleanup

```gdscript
func remove_block(pos: Vector3i) -> void:
    var block = blocks.get(pos)
    if block:
        block.sprite.queue_free()  # Don't forget cleanup
        blocks.erase(pos)
        block_removed.emit(block)
```

## File Organization

| Type | Location |
|------|----------|
| Core systems | `src/core/` |
| Block implementations | `src/blocks/` |
| Environment systems | `src/environment/` |
| Agent simulation | `src/agents/` |
| Transit/pathfinding | `src/transit/` |
| Economy | `src/economy/` |
| UI | `src/ui/` |
| Scenes | `scenes/` |
| Block sprites | `assets/sprites/blocks/` |
| UI sprites | `assets/sprites/ui/` |
| Data files | `data/` |

## Testing

Use GUT (Godot Unit Test) for tests:

```gdscript
# tests/test_grid.gd
extends GutTest

func test_neighbor_finding():
    var pos = Vector3i(5, 5, 0)
    var neighbors = Grid.get_neighbors(pos)
    assert_eq(neighbors.size(), 6)
    assert_has(neighbors, Vector3i(6, 5, 0))

func test_isometric_roundtrip():
    var original = Vector3i(10, 5, 2)
    var screen = Grid.grid_to_screen(original)
    var back = Grid.screen_to_grid(screen, 2)
    assert_eq(original, back)
```

## Gotchas

- Remember to call `queue_free()` on removed block sprites
- Godot 4 uses `Vector3i` not `Vector3` for integer positions
- Check `project.godot` exists before assuming project is initialized
- Y-sorting handles depth; use `y_sort_enabled` on parent node
