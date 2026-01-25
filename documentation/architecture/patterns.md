# Common Patterns

Reusable code patterns discovered during development.

---

## Grid Operations

### Sparse 3D Dictionary

Use `Dictionary` with `Vector3i` keys for O(1) lookup:

```gdscript
var blocks: Dictionary = {}  # Vector3i -> Block

func set_block(pos: Vector3i, block: Block) -> void:
    blocks[pos] = block

func get_block(pos: Vector3i) -> Block:
    return blocks.get(pos)

func has_block(pos: Vector3i) -> bool:
    return blocks.has(pos)
```

### Neighbor Iteration

```gdscript
const DIRECTIONS = [
    Vector3i(1, 0, 0),
    Vector3i(-1, 0, 0),
    Vector3i(0, 1, 0),
    Vector3i(0, -1, 0),
    Vector3i(0, 0, 1),
    Vector3i(0, 0, -1),
]

func for_each_neighbor(pos: Vector3i, callback: Callable) -> void:
    for dir in DIRECTIONS:
        var neighbor_pos = pos + dir
        callback.call(neighbor_pos)
```

---

## Signal-Based Architecture

### Event Emission

```gdscript
# In grid.gd
signal block_placed(block: Block)
signal block_removed(block: Block)
signal block_updated(block: Block)

func place_block(pos: Vector3i, type: String) -> Block:
    var block = create_block(type, pos)
    blocks[pos] = block
    block_placed.emit(block)
    return block
```

### System Subscription

```gdscript
# In light_system.gd
func _ready():
    Grid.block_placed.connect(_on_block_changed)
    Grid.block_removed.connect(_on_block_changed)

func _on_block_changed(block: Block) -> void:
    mark_dirty(block.grid_position)
```

---

## Lazy Recalculation

```gdscript
var _dirty: bool = false
var _dirty_positions: Array[Vector3i] = []

func mark_dirty(pos: Vector3i) -> void:
    _dirty = true
    if not _dirty_positions.has(pos):
        _dirty_positions.append(pos)

func _process(_delta: float) -> void:
    if _dirty:
        recalculate_dirty()
        _dirty = false
        _dirty_positions.clear()

func recalculate_dirty() -> void:
    for pos in _dirty_positions:
        recalculate_at(pos)
```

---

## Data Loading

### JSON Configuration

```gdscript
func load_json(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var json = JSON.new()
        var error = json.parse(file.get_as_text())
        if error == OK:
            return json.data
    return {}
```

### Block Registry Pattern

```gdscript
class_name BlockRegistry
extends Node

var _definitions: Dictionary = {}

func _ready():
    load_definitions()

func load_definitions() -> void:
    var data = load_json("res://data/blocks.json")
    for type_id in data:
        _definitions[type_id] = data[type_id]

func get_definition(type_id: String) -> Dictionary:
    return _definitions.get(type_id, {})

func get_all_types() -> Array:
    return _definitions.keys()
```

---

## Resource Cleanup

```gdscript
func remove_block(pos: Vector3i) -> void:
    var block = blocks.get(pos)
    if block:
        # Clean up visual resources
        if block.sprite:
            block.sprite.queue_free()
        if block.status_icon:
            block.status_icon.queue_free()

        # Remove from data structures
        blocks.erase(pos)

        # Emit signal
        block_removed.emit(block)
```

---

## Flood Fill

```gdscript
func flood_fill(start: Vector3i, condition: Callable) -> Array[Vector3i]:
    var result: Array[Vector3i] = []
    var visited: Dictionary = {}
    var queue: Array[Vector3i] = [start]

    while queue.size() > 0:
        var current = queue.pop_front()

        if visited.has(current):
            continue
        visited[current] = true

        if not condition.call(current):
            continue

        result.append(current)

        for dir in DIRECTIONS:
            var neighbor = current + dir
            if not visited.has(neighbor):
                queue.append(neighbor)

    return result
```

---

## Propagation Systems

### Value Spreading

```gdscript
func propagate_value(sources: Dictionary, falloff: float, max_distance: int) -> Dictionary:
    var result: Dictionary = {}
    var queue: Array = []

    # Initialize with sources
    for pos in sources:
        result[pos] = sources[pos]
        queue.append({"pos": pos, "value": sources[pos], "distance": 0})

    # BFS propagation
    while queue.size() > 0:
        var entry = queue.pop_front()
        var pos = entry.pos
        var value = entry.value
        var distance = entry.distance

        if distance >= max_distance:
            continue

        for dir in DIRECTIONS:
            var neighbor = pos + dir
            var new_value = value - falloff

            if new_value > result.get(neighbor, 0):
                result[neighbor] = new_value
                queue.append({
                    "pos": neighbor,
                    "value": new_value,
                    "distance": distance + 1
                })

    return result
```

---

## UI Helpers

### Panel Toggle

```gdscript
var _panel_visible: bool = false

func toggle_panel(panel: Control) -> void:
    _panel_visible = not _panel_visible
    panel.visible = _panel_visible

func show_panel(panel: Control) -> void:
    _panel_visible = true
    panel.visible = true

func hide_panel(panel: Control) -> void:
    _panel_visible = false
    panel.visible = false
```

### Tooltip Follow

```gdscript
func _process(_delta: float) -> void:
    if tooltip.visible:
        var mouse_pos = get_viewport().get_mouse_position()
        tooltip.position = mouse_pos + Vector2(15, 15)
```

---

## Testing Helpers

```gdscript
# Create test grid with known state
func create_test_grid(size: int) -> void:
    for x in range(size):
        for y in range(size):
            var pos = Vector3i(x, y, 0)
            Grid.set_block(pos, Block.new("corridor", pos))

# Assert block exists
func assert_block_at(pos: Vector3i, type: String) -> void:
    var block = Grid.get_block(pos)
    assert(block != null, "Expected block at %s" % pos)
    assert(block.block_type == type, "Expected type %s, got %s" % [type, block.block_type])
```
