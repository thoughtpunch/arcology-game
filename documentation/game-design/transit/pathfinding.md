# Pathfinding

[← Back to Transit](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Pathfinding calculates routes through the arcology. Uses A* on a transit graph (not the voxel grid directly).

---

## Transit Graph

### Structure

```
TransitGraph {
  nodes: Map<Vector3i, TransitNode>
  edges: Map<Vector3i, Array<TransitEdge>>
}

TransitNode {
  position: Vector3i
  block_type: String
}

TransitEdge {
  from_pos: Vector3i
  to_pos: Vector3i
  cost: float  // Travel time
}
```

### Graph Building

1. Create nodes for all blocks
2. Create edges for connections
3. Calculate edge costs based on:
   - Distance
   - Transit type speed
   - Congestion
   - Traversal modifier

### Graph Update

Rebuild only when structure changes (block place/remove).

---

## A* Algorithm

```
func find_path(start, end) -> Array[Vector3i]:
    open_set = [start]
    came_from = {}
    g_score = {start: 0}
    f_score = {start: heuristic(start, end)}

    while open_set not empty:
        current = get_lowest_f(open_set, f_score)

        if current == end:
            return reconstruct_path(came_from, current)

        open_set.remove(current)

        for edge in edges[current]:
            neighbor = edge.to_pos
            tentative_g = g_score[current] + edge.cost

            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, end)
                if neighbor not in open_set:
                    open_set.add(neighbor)

    return []  // No path
```

### Heuristic

```
heuristic(a, b) = |a.x - b.x| + |a.y - b.y| + |a.z - b.z| * 2

Vertical distance weighted higher (elevators are bottleneck)
```

---

## Edge Costs

### Base Formula

```
edge_cost = (distance / effective_speed) × traversal_modifier
```

### Speed Multipliers

| Transit Type | Speed |
|--------------|-------|
| Walking | 1.0x |
| Stairs (up) | 0.4x |
| Stairs (down) | 0.6x |
| Elevator | 3.0-5.0x + wait |
| Conveyor (with flow) | 2.0-2.5x |
| Conveyor (against) | 0.3x |
| Pneuma-Tube | 10.0x |

### Traversal Modifiers

| Space Type | Modifier | Notes |
|------------|----------|-------|
| Corridor (clear) | 1.0 | Base |
| Corridor (crowded) | 1.3 | Congestion |
| Atrium | 0.85 | Pleasant |
| Park/Garden | 0.9 | Pleasant |
| Food Hall | 0.95 | Pleasant shortcut |
| Industrial corridor | 1.3 | Unpleasant |

Lower modifier = preferred.

---

## Elevator Wait Time

```
elevator_cost = vertical_distance / elevator_speed + estimated_wait

estimated_wait = f(
    floor_demand,
    elevator_capacity,
    num_cars,
    dispatch_algorithm,
    current_congestion
)
```

---

## Path Caching

Common paths are cached:
- Home → Work
- Home → Services
- Home → Entertainment

Cache invalidated on:
- Structure change
- Significant congestion change

---

## Commute Time Effects

| Commute | Satisfaction Effect |
|---------|---------------------|
| < 10 min | +2 |
| 10-20 min | 0 |
| 20-30 min | -2 |
| > 30 min | -5 |

---

## Implementation Notes

```gdscript
# Don't pathfind every frame
# Use lazy evaluation

var _path_cache: Dictionary = {}

func get_path(start: Vector3i, end: Vector3i) -> Array:
    var key = "%s->%s" % [start, end]
    if not _path_cache.has(key):
        _path_cache[key] = calculate_path(start, end)
    return _path_cache[key]

func invalidate_cache() -> void:
    _path_cache.clear()
```

---

## See Also

- [corridors.md](./corridors.md) - Horizontal transit costs
- [elevators.md](./elevators.md) - Vertical transit costs
- [../blocks/transit.md](../blocks/transit.md) - Transit blocks
- [../../architecture/milestones/milestone-8-pathfinding.md](../../architecture/milestones/milestone-8-pathfinding.md) - Implementation
- [../../architecture/performance.md](../../architecture/performance.md) - Optimization
