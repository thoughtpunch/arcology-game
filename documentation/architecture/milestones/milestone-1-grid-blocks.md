# Milestone 1: Grid & Blocks

**Goal:** Place and remove 3D blocks on a cubic cell grid with face-snap placement, ghost preview, and raycasting input.

---

## Overview

This milestone builds the foundational building system: a sparse 3D grid of 6m cubes, a block registry loaded from JSON, and a placement pipeline where the player clicks an existing block face to snap a new block into the adjacent cell. When complete, the player can build small structures by clicking, stacking blocks in all directions.

**Key constraint:** This is a 3D system. Blocks are rendered as meshes (not sprites), the camera orbits freely, and input uses physics raycasting against collision shapes — not screen-space coordinate math.

---

## Coordinate System

All spatial reasoning uses Godot's Y-up convention:

```
Y (up)
|
|    Z (north, -Z in Godot convention)
|   /
|  /
| /
+-------- X (east)

Origin (0,0,0) = Southwest corner of ground plane at grade
Positive Y = Above ground (building up)
Negative Y = Below ground (excavation)
```

**Grid positions** are always `Vector3i` — integer cell coordinates.
**World positions** are always `Vector3` — meters (grid_pos * CELL_SIZE).

---

## Features

### 1. Grid System (Sparse 3D Dictionary)

The grid is a sparse dictionary mapping `Vector3i` positions to block IDs. Empty cells have no entry. Ground cells use a sentinel value (`-1`) to distinguish them from player-placed blocks.

```gdscript
# Core state
var cell_occupancy: Dictionary = {}  # Vector3i -> int (block_id, or -1 for ground)
var placed_blocks: Dictionary = {}   # int -> PlacedBlock
```

**Why sparse:** Most of 3D space is empty. A dense array would waste memory. The dictionary gives O(1) lookup for any position.

#### Grid Constants

```gdscript
const CELL_SIZE: float = 6.0    # 6m per cell — true cube in all axes
const CHUNK_SIZE: int = 8       # 8×8×8 cells per chunk (future rendering optimization)
```

#### Coordinate Conversion (grid_utils.gd)

```gdscript
## Static grid constants and coordinate conversion utilities.

const CELL_SIZE: float = 6.0

static func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE

static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE + Vector3.ONE * (CELL_SIZE / 2.0)

static func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CELL_SIZE)),
        int(floor(world_pos.y / CELL_SIZE)),
        int(floor(world_pos.z / CELL_SIZE))
    )

static func get_occupied_cells(size: Vector3i, origin: Vector3i, rotation: int) -> Array[Vector3i]:
    var cells: Array[Vector3i] = []
    var effective_size := size
    if rotation == 90 or rotation == 270:
        effective_size = Vector3i(size.z, size.y, size.x)
    for x in range(effective_size.x):
        for y in range(effective_size.y):
            for z in range(effective_size.z):
                cells.append(origin + Vector3i(x, y, z))
    return cells
```

**Note:** `world_to_grid` uses `floor()` division, which handles negative coordinates correctly. For GDScript integer division of negatives, use `int(floor(v / CELL_SIZE))` — GDScript truncates toward zero, not toward negative infinity.

### 2. Cube Faces (face.gd)

Each cell has 6 faces used for placement targeting and panel generation:

```gdscript
enum Dir { TOP, BOTTOM, NORTH, SOUTH, EAST, WEST }

# Godot convention: NORTH = -Z, SOUTH = +Z, EAST = +X, WEST = -X
const _NORMALS := {
    Dir.TOP:    Vector3i( 0,  1,  0),
    Dir.BOTTOM: Vector3i( 0, -1,  0),
    Dir.NORTH:  Vector3i( 0,  0, -1),
    Dir.SOUTH:  Vector3i( 0,  0,  1),
    Dir.EAST:   Vector3i( 1,  0,  0),
    Dir.WEST:   Vector3i(-1,  0,  0),
}
```

Key face utilities:
- `from_normal(normal: Vector3) -> int` — classify a raycast hit normal into a Dir value
- `to_normal(face: int) -> Vector3i` — Dir enum → unit offset vector
- `rotate_cw(face: int, steps: int) -> int` — rotate horizontal face directions CW around Y axis
- `get_face_transform(face: int, cell_center: Vector3, cell_size: float) -> Transform3D` — position/orient a plane mesh on a cell face

### 3. Block Definition (Data-Driven)

Block types are defined in `data/blocks.json` and loaded at runtime. No block type is hardcoded.

#### BlockDefinition Resource (block_definition.gd)

```gdscript
extends Resource

@export var id: String
@export var display_name: String
@export var size: Vector3i           # Cell dimensions (e.g., Vector3i(2, 1, 2) = 2 wide, 1 tall, 2 deep)
@export var color: Color             # Greybox color (assigned by category in registry)
@export var category: String         # "transit", "residential", "commercial", etc.
@export var traversability: String   # "public" or "private"
@export var ground_only: bool        # If true, can only be placed at Y=0 (entrance blocks)
@export var connects_horizontal: bool
@export var connects_vertical: bool
@export var capacity: int            # Resident capacity (residential blocks)
@export var jobs: int                # Job slots (commercial/industrial blocks)
```

#### BlockRegistry (block_registry.gd)

Loads `data/blocks.json` on `_init()`, creates `BlockDefinition` resources, assigns greybox colors by category:

```gdscript
# Category → greybox color mapping
var _category_colors: Dictionary = {
    "transit": Color(0.45, 0.55, 0.7),
    "residential": Color(0.45, 0.65, 0.45),
    "commercial": Color(0.75, 0.6, 0.35),
    "industrial": Color(0.55, 0.5, 0.45),
    "civic": Color(0.6, 0.5, 0.65),
    "infrastructure": Color(0.5, 0.55, 0.6),
    "green": Color(0.35, 0.6, 0.35),
    "entertainment": Color(0.7, 0.5, 0.55),
}
```

API: `get_definition(id)`, `get_all_definitions()`, `get_definitions_for_category(cat)`, `get_categories()`

#### PlacedBlock (placed_block.gd)

Runtime instance of a block in the world:

```gdscript
extends RefCounted

var id: int                          # Unique ID (auto-incrementing)
var definition: Resource             # BlockDefinition reference
var origin: Vector3i                 # Grid position of the block's origin corner
var rotation: int                    # 0, 90, 180, or 270 degrees around Y axis
var occupied_cells: Array[Vector3i]  # All cells this block occupies
var node: Node3D                     # Scene tree node for rendering/collision
```

#### data/blocks.json Format

```json
{
  "entrance": {
    "name": "Entrance",
    "category": "transit",
    "traversability": "public",
    "size": [1, 1, 1],
    "connects_horizontal": true,
    "connects_vertical": false,
    "ground_only": true
  },
  "corridor": {
    "name": "Corridor",
    "category": "transit",
    "traversability": "public",
    "size": [1, 1, 1],
    "connects_horizontal": true,
    "connects_vertical": false
  },
  "residential_basic": {
    "name": "Standard Housing",
    "category": "residential",
    "traversability": "private",
    "size": [1, 1, 1],
    "capacity": 2
  }
}
```

**Size convention:** `[x, y, z]` where x = east-west, y = vertical, z = north-south. A `[2, 1, 2]` block occupies a 12m × 6m × 12m footprint.

### 4. Block Rendering (3D Meshes)

Blocks are rendered as 3D `BoxMesh` geometry with `StandardMaterial3D`, not 2D sprites. Each placed block gets a Node3D subtree:

```
Block_<id> (Node3D)
├── MeshInstance3D        # BoxMesh with StandardMaterial3D (albedo = category color)
├── StaticBody3D          # For raycasting (collision_layer = 1)
│   └── CollisionShape3D  # BoxShape3D matching mesh size
└── Label3D               # Block name on top face (optional debug aid)
```

#### Mesh Generation

```gdscript
const BLOCK_INSET: float = 0.15  # Visual gap between adjacent blocks (per side)

func _create_mesh_for(definition: Resource, effective_size: Vector3i) -> Mesh:
    var box := BoxMesh.new()
    box.size = Vector3(effective_size) * CELL_SIZE - Vector3.ONE * BLOCK_INSET * 2.0
    return box
```

The `BLOCK_INSET` creates a subtle gap between adjacent blocks so they read as distinct objects rather than a merged blob.

#### Positioning

Blocks are positioned at the world-space corner of their origin cell. The mesh is offset to the center of the block's bounding box:

```gdscript
# Block node positioned at grid corner
root.position = grid_to_world(block.origin)

# Mesh offset to center
mesh_instance.position = Vector3(effective_size) * CELL_SIZE / 2.0
```

#### Collision for Mouse Picking

Every placed block has a `StaticBody3D` with `collision_layer = 1` and a `BoxShape3D` matching the block's dimensions. This allows `PhysicsRayQueryParameters3D` raycasting to detect which block (and which face) the player is hovering.

Block identity is stored as metadata: `static_body.set_meta("block_id", block.id)`

### 5. Input: Raycasting

All mouse interaction uses 3D physics raycasting — no screen-to-grid coordinate math.

```gdscript
func _raycast_from_mouse() -> Dictionary:
    var viewport := get_viewport()
    var camera := viewport.get_camera_3d()
    var mouse_pos := viewport.get_mouse_position()
    var from := camera.project_ray_origin(mouse_pos)
    var dir := camera.project_ray_normal(mouse_pos)
    var to := from + dir * 2000.0

    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1  # Only hit blocks and ground

    var result := space.intersect_ray(query)

    if result:
        return {
            "hit": true,
            "position": result.position,
            "normal": result.normal,
            "collider": result.collider,
            "grid_pos": world_to_grid(result.position - result.normal * 0.01),
            "face": Face.from_normal(result.normal),
        }
    return {"hit": false}
```

**Key detail:** `result.position - result.normal * 0.01` nudges the hit point slightly into the block that was hit, ensuring `world_to_grid()` returns the correct cell (not the empty cell adjacent to the face).

### 6. Face-Snap Placement

Blocks are placed by clicking on an existing block's face. The new block snaps into the adjacent cell:

```gdscript
# From raycast hit:
var normal_offset := Vector3i(
    int(round(hit.normal.x)),
    int(round(hit.normal.y)),
    int(round(hit.normal.z))
)
var place_origin: Vector3i = hit.grid_pos + normal_offset
```

- Click **TOP** face → new block goes above (Y+1)
- Click **BOTTOM** face → new block goes below (Y-1)
- Click **NORTH/SOUTH/EAST/WEST** face → new block goes horizontally adjacent

#### Placement Validation

Before placing, validate:

1. **Space is empty:** No existing block occupies any of the target cells
2. **Build zone:** All target cells are within the defined build zone boundaries
3. **Ground-only blocks:** Entrance blocks must be at Y=0
4. **Support:** The block must be face-adjacent to an existing placed block (or on ground for entrances)
5. **Entrance-first:** The first block placed must be an entrance

```gdscript
func can_place_block(definition: Resource, origin: Vector3i, rot: int) -> bool:
    # Must place entrance first
    if not _has_entrance and definition.id != "entrance":
        return false
    # Ground-only constraint
    if definition.ground_only and origin.y != 0:
        return false
    # Check all occupied cells
    var cells := get_occupied_cells(definition.size, origin, rot)
    for cell in cells:
        if is_cell_occupied(cell):
            return false
        if not is_in_build_zone(cell.x, cell.z):
            return false
    # Support check
    if not _is_supported(cells, definition):
        return false
    return true
```

#### Support Rules

- **Entrance blocks:** Must have ground (occupancy `-1`) directly below at least one cell
- **All other blocks:** Must be face-adjacent (6 directions) to at least one placed block (ground does NOT count as support for non-entrance blocks)

### 7. Ghost Preview

A semi-transparent ghost block follows the cursor, showing where the next block will be placed:

```
GhostBlock (Node3D)
├── MeshInstance3D          # Same mesh as target block, with ghost shader
└── Label3D × 5            # Face direction labels (N, S, E, W, Top)
```

**Ghost shader** (`shaders/ghost_preview.gdshader`): Renders the block semi-transparent with a green tint (valid placement) or red tint (invalid placement). Controlled by a `is_valid` shader parameter.

**Update loop** (every frame):
1. Raycast from mouse position
2. Compute `place_origin` from hit face
3. Rebuild mesh if definition or rotation changed (cached to avoid per-frame rebuilds)
4. Set `ghost_node.global_position` to `grid_to_world(place_origin)`
5. Run `can_place_block()` → set shader `is_valid` parameter

### 8. Rotation

Blocks rotate in 90° increments around the vertical (Y) axis:

- `,` key → rotate counter-clockwise
- `.` key → rotate clockwise

Rotation affects multi-cell blocks by swapping X/Z dimensions:

```gdscript
var effective_size := definition.size
if rotation == 90 or rotation == 270:
    effective_size = Vector3i(size.z, size.y, size.x)
```

Ghost face labels rotate with the block so the player can see which direction each face points.

### 9. Block Removal

- **Right-click** a placed block → remove it
- **Right-click** ground → excavate the top ground cell (exposes the layer below)

#### Structural Integrity on Removal

Before removing a block, check if removal would disconnect other blocks from an entrance (orphaning them). Uses BFS from each neighbor through placed blocks to verify entrance reachability.

```gdscript
func _would_orphan_blocks(block_id: int) -> bool:
    # If this is the only entrance and other blocks exist, reject
    # For each neighbor block, BFS to verify it can still reach an entrance
    ...
```

If removal would orphan blocks, it is rejected with a warning message.

### 10. Ground System

The ground is a grid of destructible cells below Y=0:

- **Y=0:** Build surface (where entrances are placed)
- **Y=-1 through Y=-N:** Ground strata layers (rendered as `MultiMeshInstance3D` per layer)
- Each layer has a distinct color (strata visualization)
- Right-clicking ground removes the topmost cell at that column
- Cannot remove ground if it would unseat an entrance block above it
- A `StaticBody3D` collision slab covers the full ground area for raycasting

### 11. Placement Animation

Blocks animate on place and remove:

**Place:** Scale from 0.01 → 1.0 with `TRANS_BACK` easing + drop from above + emission flash
**Remove:** Scale to 0.0 + drop slightly + `queue_free()`

A procedural click/thud audio plays on placement (no audio files needed).

---

## Input Summary

| Action | Input | Description |
|--------|-------|-------------|
| Place block | Left-click | Face-snap place at cursor position |
| Rapid-fire place | Hold left-click + sweep | Continuous placement (10 blocks/sec, one per cell) |
| Remove block | Right-click tap | Remove block or excavate ground |
| Rotate CW | `.` | Rotate selection 90° clockwise |
| Rotate CCW | `,` | Rotate selection 90° counter-clockwise |
| Select block | 1-9 | Select block from current palette category |
| Cycle category | Tab / Shift+Tab | Next/previous block category |
| Focus | Double-click / F | Center camera on clicked position |
| Toggle UI | `` ` `` | Show/hide palette and HUD |

---

## Data Files

### data/blocks.json

Must contain at minimum these block types for Milestone 1:

| ID | Category | Size | Purpose |
|----|----------|------|---------|
| `entrance` | transit | 1×1×1 | Required first block, ground_only=true |
| `corridor` | transit | 1×1×1 | Basic public connector |
| `stairs` | transit | 1×1×1 | Vertical connector |
| `residential_standard` | residential | 1×1×1 | Basic housing (capacity: 2) |
| `commercial_shop` | commercial | 1×1×1 | Basic commerce (jobs: 2) |

Additional block types are welcome but not required for this milestone.

---

## Scene Structure

```
Phase0Sandbox (Node3D)
├── WorldEnvironment
├── DirectionalLight3D (Sun)
├── OrbitalCamera (Camera3D wrapper)
├── Ground (Node3D)
│   ├── MultiMeshInstance3D × N (ground strata layers)
│   └── StaticBody3D (ground collision slab)
├── BlockContainer (Node3D)
│   └── Block_<id> (Node3D) × placed blocks
├── GhostBlock (Node3D)
│   ├── MeshInstance3D (ghost mesh + shader)
│   └── Label3D × 5 (face labels)
├── FaceHighlight (MeshInstance3D, PlaneMesh on hovered face)
├── GridOverlay (MeshInstance3D per Y-level, shader-based grid lines)
└── UI (CanvasLayer)
    ├── ShapePalette (block picker)
    ├── FaceLabel (hovered face info)
    ├── WarningLabel (placement rejection messages)
    ├── ControlsLabel (keybinding hints)
    ├── BuildingStatsHUD (block count, height, volume, footprint)
    └── EntrancePrompt ("Place your entrance to begin building")
```

---

## Shaders

Three shaders are needed:

1. **`ghost_preview.gdshader`** — Semi-transparent block preview with green/red validity tint
2. **`face_highlight.gdshader`** — Animated highlight on the hovered block face
3. **`grid_overlay.gdshader`** — Procedural grid lines on the build zone ground plane

---

## Acceptance Criteria

- [ ] Grid stores blocks by `Vector3i` position in a sparse dictionary
- [ ] `grid_to_world()` and `world_to_grid()` convert correctly (CELL_SIZE = 6.0)
- [ ] Block definitions load from `data/blocks.json` at runtime
- [ ] At least 5 block types available (entrance, corridor, stairs, residential, commercial)
- [ ] Blocks render as 3D `BoxMesh` geometry with category-colored `StandardMaterial3D`
- [ ] Each placed block has a `StaticBody3D` + `CollisionShape3D` for raycasting
- [ ] Left-click on a block face places a new block in the adjacent cell (face-snap)
- [ ] Right-click removes a block (with structural integrity check)
- [ ] Ghost preview appears at the cursor showing where the block will be placed
- [ ] Ghost turns green for valid placement, red for invalid
- [ ] Blocks can be rotated in 90° increments with `,` / `.` keys
- [ ] Multi-cell blocks (e.g., 2×1×2) occupy all their cells and rotate correctly
- [ ] Entrance block must be placed first (at Y=0, on ground)
- [ ] Non-entrance blocks require face-adjacency to an existing block
- [ ] Block removal checks structural integrity (won't orphan disconnected blocks)
- [ ] Ground excavation works (right-click removes topmost ground cell)
- [ ] Placement and removal animations play
- [ ] Signals emit on place/remove (for future system hooks)
- [ ] Camera orbits freely around the structure

---

## Test Plan

### Unit Tests (grid_utils.gd)

```gdscript
# Positive
assert(grid_to_world(Vector3i(1, 2, 3)) == Vector3(6, 12, 18))
assert(grid_to_world_center(Vector3i(0, 0, 0)) == Vector3(3, 3, 3))
assert(world_to_grid(Vector3(7, 13, 19)) == Vector3i(1, 2, 3))

# Negative coordinates
assert(world_to_grid(Vector3(-1, -1, -1)) == Vector3i(-1, -1, -1))
assert(world_to_grid(Vector3(-6.1, 0, 0)) == Vector3i(-2, 0, 0))

# Multi-cell occupancy
assert(get_occupied_cells(Vector3i(2, 1, 1), Vector3i(5, 0, 5), 0).size() == 2)
assert(get_occupied_cells(Vector3i(2, 1, 2), Vector3i(0, 0, 0), 90).size() == 4)
```

### Unit Tests (face.gd)

```gdscript
# Normal classification
assert(from_normal(Vector3(0, 1, 0)) == Dir.TOP)
assert(from_normal(Vector3(0, 0, -1)) == Dir.NORTH)

# Rotation
assert(rotate_cw(Dir.NORTH, 1) == Dir.EAST)
assert(rotate_cw(Dir.TOP, 2) == Dir.TOP)  # Vertical faces unaffected
```

### Integration Tests (placement)

```gdscript
# Positive: place entrance on ground
assert(can_place_block(entrance_def, Vector3i(5, 0, 5), 0) == true)

# Negative: place non-entrance before entrance exists
assert(can_place_block(corridor_def, Vector3i(5, 0, 5), 0) == false)

# Negative: place on occupied cell
place_block(entrance_def, Vector3i(5, 0, 5), 0)
assert(can_place_block(corridor_def, Vector3i(5, 0, 5), 0) == false)

# Positive: place adjacent to existing block
assert(can_place_block(corridor_def, Vector3i(6, 0, 5), 0) == true)

# Negative: place without adjacency support
assert(can_place_block(corridor_def, Vector3i(10, 0, 10), 0) == false)

# Structural integrity: removing the only entrance with other blocks present
place_block(corridor_def, Vector3i(6, 0, 5), 0)
assert(_would_orphan_blocks(entrance_block_id) == true)
```

---

## Implementation Order

1. **grid_utils.gd** — Coordinate conversion (pure functions, easy to test)
2. **face.gd** — Face normals, classification, rotation
3. **block_definition.gd** — Resource class for block type data
4. **block_registry.gd** — Load `data/blocks.json`, assign colors
5. **placed_block.gd** — Runtime block instance
6. **Ground system** — Multi-layer ground with collision slab
7. **Block placement** — Raycasting → face-snap → validation → instantiation
8. **Ghost preview** — Shader + mesh following cursor
9. **Block removal** — With structural integrity BFS
10. **UI** — Shape palette, face label, warnings, stats HUD

---

*This document is the implementation spec for Milestone 1. It should be sufficient to build the feature without consulting other docs. For deeper context on cell dimensions and architectural rationale, see [3d-refactor/specification.md](../3d-refactor/specification.md) Sections 1-2.*
