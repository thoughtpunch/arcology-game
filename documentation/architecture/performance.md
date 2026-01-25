# Performance Guidelines

## Targets

| Scale | Blocks | Population | Target FPS |
|-------|--------|------------|------------|
| Small | ~1,000 | ~5,000 | 60 |
| Medium | ~5,000 | ~25,000 | 60 |
| Large | ~20,000 | ~100,000 | 30+ |

---

## Core Strategies

### 1. Grid Lookup: O(1)

Use Dictionary with Vector3i keys:

```gdscript
var blocks: Dictionary = {}  # Vector3i -> Block

# O(1) lookup
func get_block(pos: Vector3i) -> Block:
    return blocks.get(pos)
```

### 2. Pathfinding: Pre-computed Graph

Don't pathfind on voxel grid. Build a transit graph:

```gdscript
# Build once, update on changes
func rebuild_graph() -> void:
    # Only rebuild when blocks change
    pass

# A* on simplified graph
func find_path(start: Vector3i, end: Vector3i) -> Array:
    # Use transit graph, not voxel grid
    pass
```

### 3. Environment: Dirty Regions

Don't recalculate entire grid every frame:

```gdscript
var _dirty_regions: Array[Rect2i] = []

func mark_region_dirty(center: Vector3i, radius: int) -> void:
    # Only recalculate affected area
    pass

func _process(_delta: float) -> void:
    if _dirty_regions.size() > 0:
        process_dirty_regions()
```

### 4. Rendering: View Culling

Only render visible blocks:

```gdscript
func update_visibility(camera_rect: Rect2) -> void:
    for pos in blocks:
        var screen_pos = grid_to_screen(pos)
        var visible = camera_rect.has_point(screen_pos)
        blocks[pos].sprite.visible = visible
```

### 5. Agents: Statistical Simulation

Not every agent needs full simulation:

```gdscript
const NOTABLE_AGENT_COUNT = 500

# Full simulation for notable agents
var notable_agents: Array[Agent] = []

# Statistical for rest
var population_stats: Dictionary = {}

func update_agents() -> void:
    # Full sim for notable
    for agent in notable_agents:
        agent.full_update()

    # Statistical for rest
    update_population_statistics()
```

---

## Update Frequencies

### Don't update everything every frame:

| System | Frequency | Notes |
|--------|-----------|-------|
| Rendering | Every frame | Visual only |
| Input | Every frame | Responsive |
| Environment | Hourly tick | Light, air, noise |
| Economy | Monthly tick | Rent, expenses |
| Pathfinding | On change | Rebuild graph |
| Agent full sim | Daily tick | Notable only |
| Population stats | Monthly tick | Aggregate |

### Tick Distribution

Spread updates across frames:

```gdscript
var _tick_accumulator: float = 0.0
var _updates_per_frame: int = 100

func _process(delta: float) -> void:
    _tick_accumulator += delta

    # Process subset each frame
    var start_index = _current_index
    var end_index = min(start_index + _updates_per_frame, total_items)

    for i in range(start_index, end_index):
        process_item(i)

    _current_index = end_index
    if _current_index >= total_items:
        _current_index = 0
```

---

## Memory Management

### Object Pooling

Reuse objects instead of creating/destroying:

```gdscript
var _sprite_pool: Array[Sprite2D] = []

func get_sprite() -> Sprite2D:
    if _sprite_pool.size() > 0:
        return _sprite_pool.pop_back()
    return Sprite2D.new()

func return_sprite(sprite: Sprite2D) -> void:
    sprite.visible = false
    _sprite_pool.append(sprite)
```

### Lazy Loading

Load assets only when needed:

```gdscript
var _texture_cache: Dictionary = {}

func get_texture(path: String) -> Texture2D:
    if not _texture_cache.has(path):
        _texture_cache[path] = load(path)
    return _texture_cache[path]
```

---

## Profiling

### Built-in Profiler

Use Godot's profiler to identify bottlenecks:

1. Run game
2. Open Debugger → Profiler
3. Look for high frame times

### Custom Timing

```gdscript
func expensive_operation() -> void:
    var start = Time.get_ticks_usec()

    # ... operation ...

    var elapsed = Time.get_ticks_usec() - start
    if elapsed > 1000:  # > 1ms
        print("Warning: operation took %d usec" % elapsed)
```

---

## Specific Optimizations

### Light System

- Cache results per block
- Only recalculate on structure change
- Use dirty regions, not full grid

### Pathfinding

- Pre-compute graph on structure change
- Cache common paths (home → work)
- Use A* with good heuristic

### Rendering

- Y-sorting via Godot's built-in
- View frustum culling
- Shader-based effects, not script

### Agents

- Notable agents: full simulation
- Background agents: statistical only
- Batch updates across frames

---

## Scaling Strategy

```
TARGET: 100,000 population at 30+ FPS

STRATEGY:

1. HIERARCHICAL SIMULATION
   - District level: aggregate flows
   - Building level: block interactions
   - Room level: individual agents (when viewed)

2. TEMPORAL BATCHING
   - Not all systems update every frame
   - Spread computation across frames
   - Priority queue based on visibility

3. SPATIAL CULLING
   - Only simulate visible areas in detail
   - Background areas: statistical approximation
   - "Catch up" simulation when area becomes visible

4. AGENT INSTANCING
   - 500 notable agents: full simulation
   - 99,500 background agents: statistical
   - Background contributes to aggregates only
   - Promote background to notable if relevant

5. CACHING
   - Pathfinding: pre-computed, invalidate on change
   - Environment: computed hourly, not per-frame
   - Social graph: lazy evaluation
```
