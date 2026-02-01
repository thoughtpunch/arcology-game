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
const CELL_SIZE: float = 6.0    # 6m per cell (true cube)
const CHUNK_SIZE: int = 8       # 8×8×8 cells per chunk
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
    "mesh": "res://assets/models/blocks/residential_basic.glb"
  }
}
```

```gdscript
# Load at runtime
var balance = load_json("res://data/balance.json")
var light_falloff = balance.light_falloff_per_floor
```

## Common Patterns

### Grid Position (Y-Up)

Use `Vector3i` for grid positions:
- `x` = East-West (positive = east)
- `y` = Vertical / Up-Down (positive = up, 0 = ground)
- `z` = North-South (positive = south)

```gdscript
var pos = Vector3i(5, 2, 3)  # x=5 (east), y=2 (2 floors up), z=3 (south)
```

See [3d-grid-math.md](./3d-grid-math.md) for full conversion functions.

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
        block.node.queue_free()  # Don't forget to free the 3D node
        blocks.erase(pos)
        block_removed.emit(block)
```

## File Organization

| Type | Location |
|------|----------|
| Core systems | `src/game/` |
| Block implementations | `src/blocks/` |
| Environment systems | `src/environment/` |
| Agent simulation | `src/agents/` |
| Transit/pathfinding | `src/transit/` |
| Economy | `src/economy/` |
| UI | `src/ui/` |
| Scenes | `scenes/` |
| Block models | `assets/models/blocks/` |
| Shaders | `shaders/` |
| Data files | `data/` |

## Testing

### GdUnit4 Tests (Preferred)

Use GdUnit4 for new tests with fluent assertions:

```gdscript
# test/core/test_grid_gdunit.gd
class_name TestGrid
extends GdUnitTestSuite

const __source = 'res://src/game/grid.gd'

func test_neighbor_finding() -> void:
    var pos = Vector3i(5, 2, 3)
    var neighbors = Grid.get_neighbors(pos)
    assert_int(neighbors.size()).is_equal(6)
    assert_array(neighbors).contains([Vector3i(6, 2, 3)])  # East neighbor

func test_grid_to_world_conversion() -> void:
    var grid_pos = Vector3i(2, 3, 1)
    var world_pos = GridUtils.grid_to_world(grid_pos)
    assert_vector(world_pos).is_equal(Vector3(12.0, 18.0, 6.0))

func test_world_to_grid_conversion() -> void:
    var world_pos = Vector3(15.0, 20.0, 8.0)
    var grid_pos = GridUtils.world_to_grid(world_pos)
    assert_vector(grid_pos).is_equal(Vector3i(2, 3, 1))
```

### SceneTree Tests (Simple/Headless)

For lightweight headless tests without a framework:

```gdscript
# test/core/test_placement.gd
extends SceneTree

func _init() -> void:
    print("=== Placement Tests ===")

    # POSITIVE - verify correct behavior
    var grid = {}
    var pos = Vector3i(3, 0, 4)
    grid[pos] = {"type": "corridor"}
    assert(grid.has(pos), "Should store block at position")
    assert(grid[pos].type == "corridor", "Should retrieve correct block type")

    # NEGATIVE - verify error handling
    assert(not grid.has(Vector3i(0, 0, 0)), "Empty position should return false")

    print("All tests passed!")
    quit()
```

### Test Requirements

- **Positive assertions** — verify the happy path works
- **Negative assertions** — verify edge cases and invalid input are handled
- **Both unit and integration tests** for system interactions
- Run with: `godot --headless --script test/<category>/test_<feature>.gd`

## Gotchas

- Call `queue_free()` on removed block nodes (MeshInstance3D, StaticBody3D, etc.)
- Godot 4 uses `Vector3i` not `Vector3` for integer grid positions
- Coordinate system is Y-up: `x` = east, `y` = up, `z` = south (NOT z = floor level)
- Check `project.godot` exists before assuming project is initialized
- AutoLoad scripts must NOT have `class_name` — access via `get_node("/root/AutoloadName")`
- `auto_free()` returns Variant — use explicit typing to avoid strict mode warnings
- Floor division for negative grid coords: GDScript truncates toward zero, use `int(floor(x))` instead
- Block node structure: child[0] = MeshInstance3D (with material_override), child[1] = StaticBody3D (with block_id meta)
