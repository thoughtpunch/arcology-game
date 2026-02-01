# 3D Grid Math Reference

> Canonical implementations: `src/game/grid_utils.gd` and `src/game/face.gd`

## Constants

```gdscript
const CELL_SIZE: float = 6.0    # 6 meters per cell (true cube)
const CHUNK_SIZE: int = 8       # 8x8x8 cells per chunk
```

## Coordinate System

Godot Y-up convention:

```
      +Y (up)
       |
       |
       +-----> +X (east)
      /
     /
   +Z (south)
```

- **X** = East (+) / West (-)
- **Y** = Up (+) / Down (-)
- **Z** = South (+) / North (-)

Grid positions use `Vector3i`. World positions use `Vector3`.

## Grid <-> World Conversion

```gdscript
# Grid (integer cells) -> World (meters)
static func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE

# Grid -> World center (middle of cell)
static func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(grid_pos) * CELL_SIZE + Vector3.ONE * (CELL_SIZE / 2.0)

# World (meters) -> Grid (integer cells)
static func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CELL_SIZE)),
        int(floor(world_pos.y / CELL_SIZE)),
        int(floor(world_pos.z / CELL_SIZE))
    )
```

## Face Directions

Each cell has 6 faces. See `src/game/face.gd`:

```gdscript
enum Dir { TOP, BOTTOM, NORTH, SOUTH, EAST, WEST }
```

| Face | Normal | Direction |
|------|--------|-----------|
| TOP | `(0, 1, 0)` | +Y |
| BOTTOM | `(0, -1, 0)` | -Y |
| NORTH | `(0, 0, -1)` | -Z |
| SOUTH | `(0, 0, 1)` | +Z |
| EAST | `(1, 0, 0)` | +X |
| WEST | `(-1, 0, 0)` | -X |

### Face Utilities

```gdscript
# Classify a raycast normal into a face direction
Face.from_normal(normal: Vector3) -> int

# Get the unit normal for a face
Face.to_normal(face: int) -> Vector3i

# Rotate a horizontal face CW by N 90-degree steps
Face.rotate_cw(face: int, steps: int) -> int

# Get Transform3D to position a plane on a cell face
Face.get_face_transform(face: int, cell_center: Vector3, cell_size: float) -> Transform3D
```

## Occupied Cells (Multi-Cell Blocks)

Blocks can span multiple cells. Rotation swaps X and Z:

```gdscript
static func get_occupied_cells(size: Vector3i, origin: Vector3i, rotation: int) -> Array[Vector3i]:
    var effective_size := size
    if rotation == 90 or rotation == 270:
        effective_size = Vector3i(size.z, size.y, size.x)

    var cells: Array[Vector3i] = []
    for x in range(effective_size.x):
        for y in range(effective_size.y):
            for z in range(effective_size.z):
                cells.append(origin + Vector3i(x, y, z))
    return cells
```

## Neighbor Finding

```gdscript
func get_neighbors(pos: Vector3i) -> Array[Vector3i]:
    return [
        pos + Vector3i(1, 0, 0),   # East
        pos + Vector3i(-1, 0, 0),  # West
        pos + Vector3i(0, 1, 0),   # Up
        pos + Vector3i(0, -1, 0),  # Down
        pos + Vector3i(0, 0, 1),   # South
        pos + Vector3i(0, 0, -1),  # North
    ]
```

## Common Operations

### Manhattan Distance

```gdscript
func manhattan_distance(a: Vector3i, b: Vector3i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
```

### Position Validity

```gdscript
func is_valid_position(pos: Vector3i, bounds: Dictionary) -> bool:
    return (
        pos.x >= 0 and pos.x < bounds.width and
        pos.z >= 0 and pos.z < bounds.depth and
        pos.y >= bounds.min_y and pos.y <= bounds.max_y
    )
```

### Raycast from Camera

```gdscript
var from := camera.project_ray_origin(screen_pos)
var dir := camera.project_ray_normal(screen_pos)
var to := from + dir * 2000.0
var query := PhysicsRayQueryParameters3D.create(from, to)
query.collision_mask = 0b11  # Layer 1 (terrain) + Layer 2 (blocks)
var result := space_state.intersect_ray(query)
```

## Chunks

Cells are grouped into 8x8x8 chunks for rendering optimization:

```gdscript
func cell_to_chunk(cell: Vector3i) -> Vector3i:
    return Vector3i(
        cell.x >> 3,  # divide by 8, floor
        cell.y >> 3,
        cell.z >> 3
    )
```
