# Milestone 8: Pathfinding & Commute

**Goal:** Residents travel to destinations

---

## Features

### Transit Graph
- Build node graph from blocks
- Nodes: rooms, corridors, elevator stops
- Edges: walking connections

### Pathfinding
- A* on transit graph
- Cost = distance (simple)

### Residents
- Residential blocks have "home"
- Commercial blocks are "work"
- Residents path from home to work (if commercial exists)
- Commute time affects satisfaction

### Visual
- Optional: show paths
- Optional: show little resident sprites walking

---

## Deliverable

Build home + corridor + work. See commute time. Long commute = unhappy.

---

## Implementation

### Transit Graph

```gdscript
class_name TransitGraph
extends RefCounted

var nodes: Dictionary = {}  # Vector3i -> TransitNode
var edges: Dictionary = {}  # Vector3i -> Array[TransitEdge]

class TransitNode:
    var position: Vector3i
    var block_type: String

class TransitEdge:
    var from_pos: Vector3i
    var to_pos: Vector3i
    var cost: float  # Travel time

func rebuild_from_grid() -> void:
    nodes.clear()
    edges.clear()

    # Create nodes for all blocks
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var node = TransitNode.new()
        node.position = pos
        node.block_type = block.block_type
        nodes[pos] = node

    # Create edges for connections
    for pos in nodes:
        edges[pos] = []
        for neighbor_pos in Grid.get_neighbors(pos):
            if Grid.can_connect(pos, neighbor_pos):
                var edge = TransitEdge.new()
                edge.from_pos = pos
                edge.to_pos = neighbor_pos
                edge.cost = calculate_edge_cost(pos, neighbor_pos)
                edges[pos].append(edge)

func calculate_edge_cost(from: Vector3i, to: Vector3i) -> float:
    var from_block = Grid.get_block(from)
    var to_block = Grid.get_block(to)

    var base_cost = 1.0  # 1 unit of time per block

    # Vertical movement is slower (stairs)
    if to.z != from.z:
        if to_block.block_type == "stairs":
            base_cost = 3.0  # Stairs are slow
        elif to_block.block_type == "elevator_shaft":
            base_cost = 0.5  # Elevators are fast

    return base_cost
```

### A* Pathfinding

```gdscript
func find_path(start: Vector3i, end: Vector3i) -> Array[Vector3i]:
    if not nodes.has(start) or not nodes.has(end):
        return []

    var open_set: Array[Vector3i] = [start]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start: 0.0}
    var f_score: Dictionary = {start: heuristic(start, end)}

    while open_set.size() > 0:
        # Get node with lowest f_score
        var current = get_lowest_f(open_set, f_score)

        if current == end:
            return reconstruct_path(came_from, current)

        open_set.erase(current)

        for edge in edges.get(current, []):
            var neighbor = edge.to_pos
            var tentative_g = g_score[current] + edge.cost

            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, end)
                if not open_set.has(neighbor):
                    open_set.append(neighbor)

    return []  # No path found

func heuristic(a: Vector3i, b: Vector3i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z) * 2.0

func reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
    var path: Array[Vector3i] = [current]
    while came_from.has(current):
        current = came_from[current]
        path.push_front(current)
    return path
```

### Commute Calculation

```gdscript
func calculate_commute_time(home: Vector3i, work: Vector3i) -> float:
    var path = TransitGraph.find_path(home, work)
    if path.is_empty():
        return INF  # No path

    var total_cost = 0.0
    for i in range(path.size() - 1):
        for edge in TransitGraph.edges[path[i]]:
            if edge.to_pos == path[i + 1]:
                total_cost += edge.cost
                break

    return total_cost
```

### Satisfaction Impact

```gdscript
func update_satisfaction() -> void:
    for resident in residents.values():
        var block = Grid.get_block(resident.home)

        # Find nearest workplace
        var work = find_nearest_commercial(resident.home)
        if work:
            var commute = calculate_commute_time(resident.home, work)
            resident.commute_time = commute

            # Commute affects satisfaction
            if commute < 10:
                resident.satisfaction += 2  # Short commute bonus
            elif commute > 30:
                resident.satisfaction -= 5  # Long commute penalty
```

---

## Visual: Path Display (Optional)

```gdscript
func show_path(path: Array[Vector3i]) -> void:
    path_line.clear_points()
    for pos in path:
        var screen_pos = Grid.grid_to_world(pos)
        path_line.add_point(screen_pos)
```

---

## Acceptance Criteria

- [ ] Transit graph built from grid
- [ ] A* pathfinding works
- [ ] Residents assigned to workplaces
- [ ] Commute time calculated from path
- [ ] Long commute reduces satisfaction
- [ ] Short commute increases satisfaction
- [ ] No path = infinite commute (unhappy)
- [ ] Graph rebuilds on block changes
- [ ] Path visualization available (optional)
