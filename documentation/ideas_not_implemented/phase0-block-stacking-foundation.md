# Arcology Phase 0: Block Stacking Foundation

> **Version:** 0.3
> **Purpose:** Establish core 3D block placement mechanics before any game systems
> **Scope:** Digital LEGO — nothing more
> **Status:** ACTIVE — This is the current priority

---

## What This Is

A 3D sandbox where you can:

1. See a flat ground plane made of 6×6×6 meter grid cells
2. Pick blocks from a shape palette (various sizes)
3. Rotate blocks before placing (4 directions around Y-axis)
4. Place them by clicking on existing surfaces (blocks snap to grid)
5. Rotate the camera freely around your creation

That's it. No simulation, no UI beyond the palette, no saving, no agents, no economy. A child stacking blocks.

## What This Is NOT

Explicitly out of scope for Phase 0:

- ❌ Any game systems (environment, transit, agents, economy)
- ❌ Block behaviors, needs, or production
- ❌ Panels/exteriors/materials
- ❌ Permits, constraints, prerequisites
- ❌ Overlays, inspectors, menus
- ❌ Save/load
- ❌ Underground/excavation
- ❌ Internal unit subdivision (studios vs 1BR etc.)
- ❌ Isometric anything — this is a 3D game with a 3D camera

---

## The Cell: Foundational Unit

### Dimensions

```
THE CELL
════════

Dimensions: 6m × 6m × 6m (Width × Depth × Height)
            Literally cubic for grid simplicity

Floor Area: 36 m² per internal floor
Volume:     216 m³

Internal subdivision (for future reference, NOT Phase 0):
  - 2 floors at 3m each
  - Allows 2 studio units, or 1 duplex, etc.

              ┌───────────────┐
             ╱               ╱│
            ╱       6m      ╱ │
           ┌───────────────┐  │
           │               │  │ 6m
           │   1 CELL      │  │
           │               │ ╱
           │               │╱ 6m
           └───────────────┘
```

### Scale Reference

| Cells High | Height | Real-World Equivalent |
|------------|--------|----------------------|
| 1 | 6m | 2-story rowhouse |
| 5 | 30m | 10-story mid-rise |
| 10 | 60m | 20-story tower |
| 25 | 150m | Skyscraper |
| 50 | 300m | Eiffel Tower height |
| 100 | 600m | Supertall territory |

| Cells Wide | Span | Real-World Equivalent |
|------------|------|----------------------|
| 1 | 6m | One room/unit |
| 5 | 30m | Large building section |
| 10 | 60m | Building wing |
| 20 | 120m | City block edge |
| 100 | 600m | True arcology |

---

## Grid System

### Coordinate System

```
Y (up)
│
│    Z (north)
│   ╱
│  ╱
│ ╱
└──────── X (east)

Origin (0,0,0) = Southwest corner at ground level
Positive Y = Up (building up)
Negative Y = Down (future: excavation)
```

### Grid Position

Every cell has an integer position:

```gdscript
# Grid constants
const CELL_SIZE: float = 6.0  # 6 meters, cubic

func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE

func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE + Vector3.ONE * (CELL_SIZE / 2.0)

func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CELL_SIZE)),
        int(floor(world_pos.y / CELL_SIZE)),
        int(floor(world_pos.z / CELL_SIZE))
    )
```

---

## Two Systems: Occupancy vs Collision

Critical distinction: There are two separate concerns:

### 1. Grid Occupancy (Data)

A Dictionary tracking which grid cells are occupied by which block. This is the source of truth for "can I place here?"

```gdscript
# Grid occupancy — pure data, no physics
var cell_occupancy: Dictionary = {}  # Vector3i -> block_id (int)
var placed_blocks: Dictionary = {}   # block_id -> PlacedBlock

func is_cell_occupied(cell: Vector3i) -> bool:
    return cell_occupancy.has(cell)

func is_cell_buildable(cell: Vector3i) -> bool:
    # Must be above ground (Y >= 1) and empty
    return cell.y >= 1 and not is_cell_occupied(cell)
```

### 2. Raycast Collision (Physics)

StaticBody3D + CollisionShape3D on placed blocks and ground, used **ONLY** for:

- Mouse picking (what did I click on?)
- Determining which face was clicked (for adjacent placement)

```gdscript
# Raycast to find what the mouse is pointing at
func raycast_from_mouse() -> Dictionary:
    var camera = get_viewport().get_camera_3d()
    var mouse_pos = get_viewport().get_mouse_position()

    var from = camera.project_ray_origin(mouse_pos)
    var dir = camera.project_ray_normal(mouse_pos)
    var to = from + dir * 1000.0

    var space = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1  # Layer for blocks and ground

    var result = space.intersect_ray(query)

    if result:
        return {
            "hit": true,
            "position": result.position,
            "normal": result.normal,
            "collider": result.collider,
            # Calculate grid cell that was hit
            "grid_pos": world_to_grid(result.position - result.normal * 0.01)
        }

    return {"hit": false}
```

### Why Two Systems?

- **Occupancy** is cheap O(1) dictionary lookup. Use it for all "can I build?" checks.
- **Collision** is expensive physics queries. Use it ONLY for mouse interaction.
- **Never** use physics to check if a cell is occupied. Always use the dictionary.

---

## Block Definitions

### Block Data Structure

```gdscript
class_name BlockDefinition extends Resource

@export var id: String                    # "cube", "beam_3x1", etc.
@export var display_name: String          # "Cube", "Beam (3x1)", etc.
@export var size: Vector3i                # Cells occupied: Vector3i(3, 1, 1)
@export var mesh: Mesh                    # Visual mesh
@export var is_symmetric: bool = false    # If true, rotation has no visual effect
```

### Placed Block Instance

```gdscript
class_name PlacedBlock extends RefCounted

var id: int                               # Unique instance ID
var definition: BlockDefinition           # What type of block
var origin: Vector3i                      # Anchor cell (min corner)
var rotation: int                         # 0, 90, 180, 270 degrees
var occupied_cells: Array[Vector3i]       # All cells this block fills
var node: Node3D                          # Scene tree reference
```

### Shape Library (Phase 0)

| ID | Display Name | Size (X×Z×Y) | Description | Symmetric? |
|----|-------------|---------------|-------------|------------|
| cube | Cube | 1×1×1 | Basic full block | Yes |
| slab | Slab | 1×1×1 | Half-height (visual only, still 1 cell) | Yes |
| wedge | Wedge | 1×1×1 | Ramp/roof slope | No |
| beam_3 | Beam (3) | 3×1×1 | Horizontal beam, 3 long | No |
| plate_2x2 | Plate (2×2) | 2×2×1 | Flat floor section | Yes |
| wall_3x2 | Wall (3×2) | 3×1×2 | Tall wall section | No |
| column | Column | 1×1×2 | Vertical pillar, 2 high | Yes |
| platform_4x4 | Platform (4×4) | 4×4×1 | Large floor | Yes |

**Axis convention:**
- X = East-West (first number)
- Z = North-South (second number)
- Y = Up-Down (third number)

So "3×1×2" means 3 cells wide (X), 1 cell deep (Z), 2 cells tall (Y).

---

## Multi-Cell Occupancy

### Calculating Occupied Cells

When placing a block, calculate ALL cells it will occupy:

```gdscript
func get_occupied_cells(definition: BlockDefinition, origin: Vector3i, rotation: int) -> Array[Vector3i]:
    var cells: Array[Vector3i] = []
    var size = definition.size

    # Rotate size for 90 and 270 rotations (swap X and Z)
    var effective_size = size
    if rotation == 90 or rotation == 270:
        effective_size = Vector3i(size.z, size.y, size.x)

    # Generate all cells in the bounding box
    for x in range(effective_size.x):
        for y in range(effective_size.y):
            for z in range(effective_size.z):
                cells.append(origin + Vector3i(x, y, z))

    return cells
```

### Placement Validation

A block can ONLY be placed if ALL its cells are buildable:

```gdscript
func can_place_block(definition: BlockDefinition, origin: Vector3i, rotation: int) -> bool:
    var cells = get_occupied_cells(definition, origin, rotation)

    for cell in cells:
        if not is_cell_buildable(cell):
            return false

    return true
```

### Placing a Block

```gdscript
var next_block_id: int = 1

func place_block(definition: BlockDefinition, origin: Vector3i, rotation: int) -> PlacedBlock:
    # Validate first
    if not can_place_block(definition, origin, rotation):
        return null

    # Create the placed block record
    var block = PlacedBlock.new()
    block.id = next_block_id
    next_block_id += 1
    block.definition = definition
    block.origin = origin
    block.rotation = rotation
    block.occupied_cells = get_occupied_cells(definition, origin, rotation)

    # Mark all cells as occupied
    for cell in block.occupied_cells:
        cell_occupancy[cell] = block.id

    # Create visual node
    block.node = create_block_node(definition, origin, rotation)
    block_container.add_child(block.node)

    # Store in tracking dict
    placed_blocks[block.id] = block

    return block
```

### Removing a Block

```gdscript
func remove_block(block_id: int) -> void:
    if not placed_blocks.has(block_id):
        return

    var block = placed_blocks[block_id]

    # Free all cells
    for cell in block.occupied_cells:
        cell_occupancy.erase(cell)

    # Remove visual
    block.node.queue_free()

    # Remove from tracking
    placed_blocks.erase(block_id)


func remove_block_at_cell(cell: Vector3i) -> void:
    if cell_occupancy.has(cell):
        remove_block(cell_occupancy[cell])
```

---

## Rotation

### Rotation Model

Blocks rotate around the **Y axis** (vertical) in 90-degree increments:

```
ROTATION VALUES:

      N (0°)
        |
  W ----+----> E
 (270°) |    (90°)
        v
      S (180°)
```

### Rotation State

```gdscript
var current_rotation: int = 0  # 0, 90, 180, 270

func rotate_cw() -> void:
    current_rotation = (current_rotation + 90) % 360

func rotate_ccw() -> void:
    current_rotation = (current_rotation + 270) % 360  # Same as -90
```

### Multi-Cell Rotation

When a non-square block rotates, its footprint changes:

```
3×1×1 BEAM ROTATION:

  0° (North):       90° (East):
  ■ ■ ■             ■
                     ■
                     ■

  Cells at origin (0,0,0):
  0°:  (0,0,0), (1,0,0), (2,0,0)
  90°: (0,0,0), (0,0,1), (0,0,2)
```

### Applying Rotation to Node

```gdscript
func create_block_node(definition: BlockDefinition, origin: Vector3i, rotation: int) -> Node3D:
    var root = Node3D.new()

    # Mesh
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = definition.mesh
    root.add_child(mesh_instance)

    # Collision for raycasting
    var static_body = StaticBody3D.new()
    static_body.collision_layer = 1

    var collision = CollisionShape3D.new()
    var box = BoxShape3D.new()

    # Size based on rotated dimensions
    var effective_size = definition.size
    if rotation == 90 or rotation == 270:
        effective_size = Vector3i(definition.size.z, definition.size.y, definition.size.x)

    box.size = Vector3(effective_size) * CELL_SIZE
    collision.shape = box
    collision.position = Vector3(effective_size) * CELL_SIZE / 2.0

    static_body.add_child(collision)
    root.add_child(static_body)

    # Position and rotate
    root.global_position = grid_to_world(origin)
    root.rotation_degrees.y = rotation

    # Store block ID for later lookup when clicked
    root.set_meta("block_id", -1)  # Set properly after creation

    return root
```

---

## Ghost Preview

### Ghost Block

A semi-transparent preview showing where the block will be placed:

```gdscript
var ghost_node: Node3D
var ghost_mesh: MeshInstance3D
var ghost_valid_material: StandardMaterial3D  # Green, transparent
var ghost_invalid_material: StandardMaterial3D  # Red, transparent

func setup_ghost():
    ghost_node = Node3D.new()
    ghost_mesh = MeshInstance3D.new()
    ghost_node.add_child(ghost_mesh)
    add_child(ghost_node)
    ghost_node.visible = false

    # Materials
    ghost_valid_material = StandardMaterial3D.new()
    ghost_valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ghost_valid_material.albedo_color = Color(0.2, 0.8, 0.2, 0.5)

    ghost_invalid_material = StandardMaterial3D.new()
    ghost_invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ghost_invalid_material.albedo_color = Color(0.8, 0.2, 0.2, 0.5)

func update_ghost():
    var hit = raycast_from_mouse()

    if not hit.hit:
        ghost_node.visible = false
        return

    # Calculate placement position (adjacent to clicked face)
    var normal_offset = Vector3i(
        int(round(hit.normal.x)),
        int(round(hit.normal.y)),
        int(round(hit.normal.z))
    )
    var place_origin = hit.grid_pos + normal_offset

    # Update ghost mesh to match current selection
    ghost_mesh.mesh = current_definition.mesh

    # Position and rotate
    ghost_node.global_position = grid_to_world(place_origin)
    ghost_node.rotation_degrees.y = current_rotation

    # Check validity and set material
    var can_place = can_place_block(current_definition, place_origin, current_rotation)
    ghost_mesh.material_override = ghost_valid_material if can_place else ghost_invalid_material

    ghost_node.visible = true
```

---

## Camera

### Orbital Camera

```gdscript
class_name OrbitalCamera extends Node3D

@export var target: Vector3 = Vector3.ZERO
@export var distance: float = 30.0
@export var min_distance: float = 10.0
@export var max_distance: float = 200.0
@export var azimuth: float = 45.0      # Horizontal angle (degrees)
@export var elevation: float = 30.0    # Vertical angle (degrees)
@export var min_elevation: float = 5.0
@export var max_elevation: float = 85.0

@onready var camera: Camera3D = $Camera3D

func _ready():
    _update_camera()

func _process(_delta):
    _update_camera()

func _update_camera():
    var rad_az = deg_to_rad(azimuth)
    var rad_el = deg_to_rad(elevation)

    var offset = Vector3(
        sin(rad_az) * cos(rad_el),
        sin(rad_el),
        cos(rad_az) * cos(rad_el)
    ) * distance

    camera.global_position = target + offset
    camera.look_at(target, Vector3.UP)

func _unhandled_input(event):
    # Orbit with middle mouse drag
    if event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
            if Input.is_key_pressed(KEY_SHIFT):
                # Pan
                _pan(event.relative)
            else:
                # Orbit
                azimuth -= event.relative.x * 0.3
                elevation += event.relative.y * 0.3
                elevation = clamp(elevation, min_elevation, max_elevation)

    # Zoom with scroll wheel
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            distance = max(min_distance, distance * 0.9)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            distance = min(max_distance, distance * 1.1)

func _pan(screen_delta: Vector2):
    var right = camera.global_transform.basis.x
    var forward = -camera.global_transform.basis.z
    forward.y = 0
    forward = forward.normalized()

    var pan_speed = distance * 0.002
    target += right * screen_delta.x * pan_speed
    target += forward * screen_delta.y * pan_speed
```

---

## Ground Plane

### Ground Setup

The ground is a visual grid at Y=0 with collision for raycasting. Blocks go at Y>=1.

```gdscript
func create_ground(size: int = 20):
    # size x size grid of cells
    var ground = Node3D.new()
    ground.name = "Ground"

    # Visual: grid plane
    var mesh_instance = MeshInstance3D.new()
    var plane_mesh = PlaneMesh.new()
    plane_mesh.size = Vector2(size * CELL_SIZE, size * CELL_SIZE)
    mesh_instance.mesh = plane_mesh
    mesh_instance.position = Vector3(size * CELL_SIZE / 2.0, 0, size * CELL_SIZE / 2.0)

    # Ground material with grid lines
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.3, 0.35)
    mesh_instance.material_override = material

    ground.add_child(mesh_instance)

    # Collision for raycasting
    var static_body = StaticBody3D.new()
    static_body.collision_layer = 1

    var collision = CollisionShape3D.new()
    var box = BoxShape3D.new()
    box.size = Vector3(size * CELL_SIZE, 0.1, size * CELL_SIZE)
    collision.shape = box
    collision.position = Vector3(size * CELL_SIZE / 2.0, -0.05, size * CELL_SIZE / 2.0)

    static_body.add_child(collision)
    ground.add_child(static_body)

    # Mark as ground for special handling
    static_body.set_meta("is_ground", true)

    add_child(ground)
```

---

## Input Handling

### Main Input Handler

```gdscript
func _unhandled_input(event):
    # Left click: place block
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            try_place_block()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            try_remove_block()

    # R: rotate
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_R:
            if event.shift_pressed:
                rotate_ccw()
            else:
                rotate_cw()
            update_ghost()

func try_place_block():
    var hit = raycast_from_mouse()
    if not hit.hit:
        return

    var normal_offset = Vector3i(
        int(round(hit.normal.x)),
        int(round(hit.normal.y)),
        int(round(hit.normal.z))
    )
    var place_origin = hit.grid_pos + normal_offset

    place_block(current_definition, place_origin, current_rotation)

func try_remove_block():
    var hit = raycast_from_mouse()
    if not hit.hit:
        return

    # Don't remove ground
    if hit.collider.has_meta("is_ground"):
        return

    # Find block at this cell
    if cell_occupancy.has(hit.grid_pos):
        remove_block(cell_occupancy[hit.grid_pos])
```

---

## Scene Structure

```
Phase0Sandbox (Node3D)
├── WorldEnvironment
│   └── Environment (sky, ambient light)
├── DirectionalLight3D (sun)
├── OrbitalCamera
│   └── Camera3D
├── Ground (generated)
│   ├── MeshInstance3D (visual plane)
│   └── StaticBody3D
│       └── CollisionShape3D
├── BlockContainer (Node3D — parent for all placed blocks)
├── GhostBlock (Node3D)
│   └── MeshInstance3D
└── UI (CanvasLayer)
    └── ShapePalette (HBoxContainer)
        └── [Buttons for each shape]
```

---

## File Structure

```
res://
├── scenes/
│   └── main.tscn
├── src/
│   └── phase0/
│       ├── sandbox_main.gd         # Main controller
│       ├── orbital_camera.gd       # Camera control
│       ├── block_definition.gd     # Resource class
│       ├── placed_block.gd         # Instance class
│       ├── grid_utils.gd           # Grid utilities
│       └── shape_palette.gd        # UI controller
├── resources/
│   └── blocks/
│       ├── cube.tres
│       ├── slab.tres
│       ├── wedge.tres
│       ├── beam_3.tres
│       ├── plate_2x2.tres
│       ├── wall_3x2.tres
│       ├── column.tres
│       └── platform_4x4.tres
└── materials/
    └── phase0/
        ├── ghost_valid.tres
        ├── ghost_invalid.tres
        ├── block_default.tres
        └── ground.tres
```

---

## Implementation Order

1. **Scene setup** — Empty 3D scene, environment, directional light
2. **Grid utilities** — Constants, coordinate conversion functions
3. **Camera** — Orbital camera with orbit/pan/zoom
4. **Ground plane** — Visual grid + collision at Y=0
5. **Block definition resource** — Create the data class
6. **Single 1×1×1 block** — Create cube definition and mesh
7. **Occupancy dictionary** — Track occupied cells
8. **Placement logic** — Click ground -> cube appears at Y=1
9. **Ghost preview** — Semi-transparent preview follows mouse
10. **Validation feedback** — Green ghost = valid, red = invalid
11. **Block removal** — Right-click deletes block, frees cells
12. **Rotation** — R key rotates, ghost updates
13. **Multi-cell block** — Add beam_3 (3×1×1), test occupancy across 3 cells
14. **Shape palette UI** — Buttons to select different shapes
15. **All shapes** — Implement full shape library
16. **Polish** — Edge cases, visual cleanup

---

## Success Criteria

Phase 0 is complete when:

- [ ] Scene launches with visible grid ground plane
- [ ] Camera orbits freely with middle-mouse drag
- [ ] Camera zooms with scroll wheel
- [ ] Camera pans with shift+middle-mouse drag
- [ ] Clicking ground places a 1×1×1 cube at Y=1
- [ ] Ghost preview shows where block will appear
- [ ] Ghost is green when placement is valid
- [ ] Ghost is red when placement overlaps existing block
- [ ] Can stack blocks vertically (click top face)
- [ ] Can place blocks horizontally adjacent (click side face)
- [ ] Right-click removes a block, cells become available
- [ ] R key rotates the ghost 90° clockwise
- [ ] 3×1×1 beam occupies 3 cells, can't overlap any of them
- [ ] Rotated beam changes which 3 cells it occupies
- [ ] All 8 shape types can be selected and placed
- [ ] Can build a simple structure using mixed block sizes

---

## Notes

**On preserving existing work:**
- This is a **new scene**: `main.tscn`
- Don't modify existing game scenes or scripts
- Can share utility code if it exists
- Once Phase 0 is solid, integrate learnings into main game

**On meshes:**
- Use `BoxMesh` for rectangular blocks
- Use `CSGPolygon3D` or custom meshes for wedges
- Keep it simple — colored boxes are fine

**On the wedge:**
- A wedge slopes from one edge to the opposite
- Make it visually obvious which way it faces
- The "front" is the low edge

---

*End of Phase 0 Specification v0.3*
