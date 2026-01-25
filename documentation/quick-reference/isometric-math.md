# Isometric Math Reference

## Constants

```gdscript
const TILE_WIDTH: int = 64   # Horizontal tile size
const TILE_HEIGHT: int = 32  # Vertical tile size (2:1 ratio)
const FLOOR_HEIGHT: int = 24 # Visual height per Z level
```

## Grid to Screen Conversion

Convert a 3D grid position to 2D screen coordinates:

```gdscript
func grid_to_screen(grid_pos: Vector3i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
    y -= grid_pos.z * FLOOR_HEIGHT  # Higher Z = higher on screen
    return Vector2(x, y)
```

**Explanation:**
- `x` component: Difference of grid x/y determines horizontal position
- `y` component: Sum of grid x/y determines depth, minus floor offset

## Screen to Grid Conversion

Convert 2D screen coordinates back to 3D grid (requires known Z level):

```gdscript
func screen_to_grid(screen_pos: Vector2, z_level: int) -> Vector3i:
    # Adjust for current Z level
    var adjusted_y = screen_pos.y + z_level * FLOOR_HEIGHT

    var grid_x = (screen_pos.x / (TILE_WIDTH / 2) + adjusted_y / (TILE_HEIGHT / 2)) / 2
    var grid_y = (adjusted_y / (TILE_HEIGHT / 2) - screen_pos.x / (TILE_WIDTH / 2)) / 2

    return Vector3i(int(grid_x), int(grid_y), z_level)
```

**Note:** Z level must be known or determined separately (e.g., from current floor view).

## Neighbor Finding

Get all 6 neighbors of a 3D position:

```gdscript
func get_neighbors(pos: Vector3i) -> Array[Vector3i]:
    return [
        pos + Vector3i(1, 0, 0),   # +X
        pos + Vector3i(-1, 0, 0),  # -X
        pos + Vector3i(0, 1, 0),   # +Y
        pos + Vector3i(0, -1, 0),  # -Y
        pos + Vector3i(0, 0, 1),   # +Z (up)
        pos + Vector3i(0, 0, -1),  # -Z (down)
    ]
```

## Depth Sorting

For isometric rendering, sort by:
1. Z level (lower floors behind higher floors)
2. Y position (north tiles behind south tiles)
3. X position (west tiles behind east tiles)

```gdscript
func get_sort_key(pos: Vector3i) -> int:
    # Higher value = drawn later (in front)
    return pos.x + pos.y - pos.z * 1000
```

Or use Godot's built-in Y-sorting:
```gdscript
# On parent node
y_sort_enabled = true
```

## Visual Examples

### Coordinate System

```
Screen layout (looking at isometric view):

        North (-Y)
           ↑
    West ←   → East
   (-X)     ↓    (+X)
        South (+Y)

Grid position (5, 3, 0) appears:
- 5 tiles right from origin in X
- 3 tiles back in Y
- On floor 0
```

### Floor Stacking

```
Z=2  ╔═══╗
     ║   ║ ← 48 pixels above Z=0
Z=1  ╔═══╗
     ║   ║ ← 24 pixels above Z=0
Z=0  ╔═══╗
     ║   ║ ← Ground level
     ╚═══╝
```

## Common Operations

### Check if position is valid

```gdscript
func is_valid_position(pos: Vector3i, bounds: Dictionary) -> bool:
    return (
        pos.x >= 0 and pos.x < bounds.width and
        pos.y >= 0 and pos.y < bounds.depth and
        pos.z >= bounds.min_floor and pos.z <= bounds.max_floor
    )
```

### Get positions in radius

```gdscript
func get_positions_in_radius(center: Vector3i, radius: int) -> Array[Vector3i]:
    var positions: Array[Vector3i] = []
    for x in range(-radius, radius + 1):
        for y in range(-radius, radius + 1):
            for z in range(-radius, radius + 1):
                var pos = center + Vector3i(x, y, z)
                if pos != center:
                    positions.append(pos)
    return positions
```

### Manhattan distance

```gdscript
func manhattan_distance(a: Vector3i, b: Vector3i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
```

## Mouse Picking

To pick a tile from mouse click:

```gdscript
func pick_tile(mouse_pos: Vector2, camera: Camera2D, current_floor: int) -> Vector3i:
    # Convert screen position to world position
    var world_pos = camera.get_canvas_transform().affine_inverse() * mouse_pos

    # Convert to grid
    return screen_to_grid(world_pos, current_floor)
```
