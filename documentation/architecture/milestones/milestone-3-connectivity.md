# Milestone 3: Connectivity & Paths

**Goal:** Blocks know what they're connected to

---

## Features

### Core
- Adjacency detection (6 neighbors in 3D)
- Path connectivity: flood-fill from "entrance"
- Blocks track: connected_to_entrance (bool)

### Visual
- Unconnected blocks show warning icon
- Optional: connectivity overlay

### Corridors
- Corridor blocks connect horizontally
- Stairs connect ±1 floor
- Elevator shaft connects many floors (vertical stack)

### New Blocks
- Stairs (connects Z and Z+1)
- Elevator Shaft (vertical, connects all floors it spans)

---

## Deliverable

Build residential, connect with corridor to stairs. Game shows what's connected.

---

## Key Code

### Neighbor Finding

```gdscript
func get_neighbors(pos: Vector3i) -> Array[Vector3i]:
    return [
        pos + Vector3i(1, 0, 0),   # East
        pos + Vector3i(-1, 0, 0),  # West
        pos + Vector3i(0, 1, 0),   # South
        pos + Vector3i(0, -1, 0),  # North
        pos + Vector3i(0, 0, 1),   # Up
        pos + Vector3i(0, 0, -1),  # Down
    ]
```

### Connection Rules

```gdscript
func can_connect(from_pos: Vector3i, to_pos: Vector3i) -> bool:
    var from_block = get_block(from_pos)
    var to_block = get_block(to_pos)

    if not from_block or not to_block:
        return false

    var direction = to_pos - from_pos

    # Horizontal connection (corridors connect horizontally)
    if direction.z == 0:
        return from_block.is_traversable and to_block.is_traversable

    # Vertical connection (stairs/elevators only)
    if abs(direction.z) == 1:
        return (
            from_block.connects_vertical(direction.z) and
            to_block.connects_vertical(-direction.z)
        )

    return false
```

### Connectivity Calculation

```gdscript
func calculate_connectivity(entrance_pos: Vector3i) -> void:
    # Reset all blocks
    for pos in blocks:
        blocks[pos].connected = false

    # Flood fill from entrance
    var visited: Dictionary = {}
    var queue: Array[Vector3i] = [entrance_pos]

    while queue.size() > 0:
        var current = queue.pop_front()
        if visited.has(current):
            continue
        visited[current] = true

        var block = get_block(current)
        if block:
            block.connected = true
            for neighbor in get_neighbors(current):
                if not visited.has(neighbor) and can_connect(current, neighbor):
                    queue.append(neighbor)
```

### Block Types for Vertical Connection

```gdscript
# In Block class
func connects_vertical(direction: int) -> bool:
    match block_type:
        "stairs":
            return true  # Connects up and down
        "elevator_shaft":
            return true  # Connects up and down
        _:
            return false  # Regular blocks don't connect vertically
```

---

## Visual Feedback

### Unconnected Warning

```gdscript
func update_connection_visual(block: Block) -> void:
    if block.connected:
        block.warning_icon.visible = false
    else:
        block.warning_icon.visible = true
        # Show "not connected" icon
```

### Connectivity Overlay (Optional)

```gdscript
func show_connectivity_overlay() -> void:
    for pos in blocks:
        var block = blocks[pos]
        if block.connected:
            block.sprite.modulate = Color.GREEN
        else:
            block.sprite.modulate = Color.RED
```

---

## New Block Definitions

### data/blocks.json additions

```json
{
  "stairs": {
    "name": "Stairs",
    "size": [1, 1, 1],
    "cost": 200,
    "category": "transit",
    "traversable": true,
    "connects_vertical": true,
    "vertical_range": 1,
    "sprite": "res://assets/sprites/blocks/stairs.png"
  },
  "elevator_shaft": {
    "name": "Elevator Shaft",
    "size": [1, 1, 1],
    "cost": 500,
    "category": "transit",
    "traversable": true,
    "connects_vertical": true,
    "vertical_range": 10,
    "sprite": "res://assets/sprites/blocks/elevator.png"
  }
}
```

---

## Acceptance Criteria

- [ ] Blocks track `connected` boolean
- [ ] Flood-fill runs from designated entrance
- [ ] Corridors connect horizontally to adjacent corridors
- [ ] Stairs connect to floor above and below
- [ ] Elevator shafts connect all floors they span
- [ ] Unconnected blocks show warning icon
- [ ] Recalculation triggers on block place/remove
- [ ] Visual feedback clearly shows connected vs not
