# Performance Guidelines

> Reference: [3d-refactor/specification.md](./3d-refactor/specification.md) Section 8

## Targets

| Scale | Blocks | Population | Target FPS |
|-------|--------|------------|------------|
| Small | ~2,000 | ~5,000 | 60 |
| Medium | ~10,000 | ~25,000 | 60 |
| Large | ~50,000 | ~100,000 | 30+ |
| Extreme | ~200,000 | ~500,000 | 30+ |

### Memory Budget

```
TARGET: 4GB VRAM, 8GB RAM

Per chunk (8x8x8 cells = 512 cells max):
  - Geometry: ~2MB average
  - Collision: ~0.5MB
  - Metadata: ~0.1MB

1000 chunks loaded:
  - Geometry: ~2GB VRAM
  - Collision: ~500MB RAM
  - Metadata: ~100MB RAM

Agent data (100k agents):
  - Core state: ~50MB
  - Pathfinding cache: ~100MB
  - Social graph: ~200MB
```

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

### 2. Chunk System (8x8x8 Cells)

Static geometry is merged per chunk to reduce draw calls:

```gdscript
const CHUNK_SIZE: int = 8  # 8x8x8 cells per chunk

func cell_to_chunk(cell: Vector3i) -> Vector3i:
    return Vector3i(cell.x >> 3, cell.y >> 3, cell.z >> 3)

# Per chunk:
#   - Merge static meshes into single MultiMesh or ArrayMesh
#   - One collision compound shape
#   - Rebuild only when blocks change within that chunk
#   - Frustum cull entire chunks (not individual blocks)
```

### 3. Level of Detail (LOD)

| Distance | LOD | Detail Level |
|----------|-----|-------------|
| 0-50m | LOD0 | Full detail, interior visible |
| 50-150m | LOD1 | Simplified exterior, no interior |
| 150-400m | LOD2 | Block silhouette only |
| 400m+ | LOD3 | Merged chunks, impostors |

### 4. Frustum & Occlusion Culling

Only render what the camera can see:

```gdscript
# Frustum culling: skip chunks outside camera frustum
# Built into Godot's rendering pipeline for VisualInstance3D nodes

# Occlusion culling: skip chunks fully behind solid geometry
# Use Godot's OccluderInstance3D for large solid structures
```

### 5. GPU Instancing

Use MultiMeshInstance3D for repeated block types:

```gdscript
# Blocks of the same type within a chunk share a single MultiMesh
var multi_mesh := MultiMesh.new()
multi_mesh.mesh = block_mesh
multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
multi_mesh.instance_count = count

for i in range(count):
    multi_mesh.set_instance_transform(i, transforms[i])
    multi_mesh.set_instance_color(i, colors[i])
```

### 6. Pathfinding: Pre-computed Graph

Don't pathfind on the voxel grid. Build a transit graph:

```gdscript
# Build once, update incrementally on changes
func rebuild_graph() -> void:
    # Only rebuild affected region when blocks change
    pass

# A* on simplified graph
func find_path(start: Vector3i, end: Vector3i) -> Array:
    # Use transit graph, not voxel grid
    pass
```

### 7. Environment: Dirty Regions

Don't recalculate the entire grid:

```gdscript
var _dirty_chunks: Array[Vector3i] = []

func mark_chunk_dirty(chunk_pos: Vector3i) -> void:
    if chunk_pos not in _dirty_chunks:
        _dirty_chunks.append(chunk_pos)

func _on_hour_tick() -> void:
    for chunk in _dirty_chunks:
        recalculate_environment(chunk)
    _dirty_chunks.clear()
```

### 8. Agents: Statistical Simulation

Not every agent needs full simulation:

```gdscript
const NOTABLE_AGENT_COUNT = 500

# Full simulation for notable agents
var notable_agents: Array[Agent] = []

# Statistical for rest
var population_stats: Dictionary = {}

func update_agents() -> void:
    for agent in notable_agents:
        agent.full_update()
    update_population_statistics()
```

---

## Update Frequencies

| System | Frequency | Notes |
|--------|-----------|-------|
| Rendering | Every frame | 3D scene, chunk meshes |
| Input | Every frame | Responsive |
| Environment | Hourly tick | Light, air, noise |
| Economy | Monthly tick | Rent, expenses |
| Pathfinding | On change | Rebuild affected graph region |
| Agent full sim | Daily tick | Notable only |
| Population stats | Monthly tick | Aggregate |

### Tick Distribution

Spread updates across frames:

```gdscript
var _updates_per_frame: int = 100

func _process(_delta: float) -> void:
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

Reuse Node3D instances instead of creating/destroying:

```gdscript
var _node_pool: Array[Node3D] = []

func get_block_node() -> Node3D:
    if _node_pool.size() > 0:
        return _node_pool.pop_back()
    return _create_new_block_node()

func return_block_node(node: Node3D) -> void:
    node.visible = false
    _node_pool.append(node)
```

### Async Streaming

Load/generate distant chunks in background:

```gdscript
# Use WorkerThreadPool or Godot's ResourceLoader.load_threaded_*
func _load_chunk_async(chunk_pos: Vector3i) -> void:
    WorkerThreadPool.add_task(func():
        var mesh := _generate_chunk_mesh(chunk_pos)
        call_deferred("_apply_chunk_mesh", chunk_pos, mesh)
    )
```

---

## Profiling

### Built-in Profiler

Use Godot's profiler to identify bottlenecks:

1. Run game
2. Open Debugger → Profiler
3. Look for high frame times
4. Monitor → Rendering tab for draw calls and VRAM

### Custom Timing

```gdscript
func expensive_operation() -> void:
    var start = Time.get_ticks_usec()

    # ... operation ...

    var elapsed = Time.get_ticks_usec() - start
    if elapsed > 1000:  # > 1ms
        push_warning("Operation took %d usec" % elapsed)
```

---

## Optimization Strategies (Summary)

1. **Frustum Culling** — Only render chunks in view
2. **Occlusion Culling** — Skip chunks fully behind solid geometry
3. **LOD System** — 4 levels based on distance (LOD0-LOD3)
4. **Chunk Merging** — Combine static geometry per 8x8x8 chunk
5. **GPU Instancing** — MultiMeshInstance3D for repeated elements
6. **Deferred Rendering** — Handle many lights efficiently
7. **Async Streaming** — Load/generate distant chunks in background
8. **Simulation LOD** — Full agent sim only for visible/nearby

---

## Scaling Strategy

```
TARGET: 500,000 population at 30+ FPS

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
   - Only render visible chunks in detail
   - Background areas: statistical approximation
   - "Catch up" simulation when area becomes visible

4. AGENT INSTANCING
   - 500 notable agents: full simulation
   - 99,500 background agents: statistical
   - Background contributes to aggregates only
   - Promote background to notable if relevant

5. CACHING
   - Pathfinding: pre-computed graph, invalidate on change
   - Environment: computed hourly, not per-frame
   - Social graph: lazy evaluation
   - Chunk meshes: rebuild only on block change
```
