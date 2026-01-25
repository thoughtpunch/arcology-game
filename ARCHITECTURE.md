# Arcology: Architecture & Implementation Guide

> For Claude Code / iterative AI-assisted development

## Philosophy

**Build the smallest playable thing first, then layer complexity.**

Each milestone should be a working game you can play, just with fewer features. Never have a "big bang" integration. The PRD is the *destination*—this doc is the *path*.

---

## Tech Stack Decisions

| Layer | Choice | Why |
|-------|--------|-----|
| Engine | Godot 4.x | Open source, great 2D/isometric, GDScript is easy |
| Primary Language | GDScript | Fast iteration, Godot-native |
| Performance-Critical | C# or GDExtension | Only if/when needed |
| Data Format | JSON (saves), Resources (runtime) | Human-readable, Godot-native |
| Art Pipeline | Aseprite → PNG → Godot Import | Industry standard for pixel art |

---

## Project Structure

```
arcology/
├── project.godot
├── CLAUDE.md                    # Context for AI assistants
├── ARCHITECTURE.md              # This file
│
├── src/
│   ├── core/
│   │   ├── grid.gd              # 3D voxel grid management
│   │   ├── block.gd             # Base block class
│   │   ├── block_registry.gd    # Block type definitions
│   │   └── game_clock.gd        # Time simulation
│   │
│   ├── blocks/                  # Block type implementations
│   │   ├── residential.gd
│   │   ├── commercial.gd
│   │   ├── corridor.gd
│   │   └── ...
│   │
│   ├── environment/
│   │   ├── light_system.gd
│   │   ├── air_system.gd
│   │   ├── noise_system.gd
│   │   └── safety_system.gd
│   │
│   ├── agents/
│   │   ├── resident.gd
│   │   ├── needs.gd
│   │   ├── relationships.gd
│   │   └── population_manager.gd
│   │
│   ├── transit/
│   │   ├── pathfinder.gd
│   │   ├── transit_graph.gd
│   │   └── elevator.gd
│   │
│   ├── economy/
│   │   ├── budget.gd
│   │   ├── rent_calculator.gd
│   │   └── commerce.gd
│   │
│   └── ui/
│       ├── hud.gd
│       ├── build_menu.gd
│       ├── overlays/
│       └── panels/
│
├── scenes/
│   ├── main.tscn
│   ├── arcology.tscn            # The main game world
│   ├── blocks/                  # Block scenes
│   └── ui/                      # UI scenes
│
├── assets/
│   ├── sprites/
│   │   ├── blocks/              # Isometric block sprites
│   │   ├── ui/
│   │   └── portraits/
│   ├── audio/
│   └── fonts/
│
├── data/
│   ├── blocks.json              # Block definitions
│   ├── scenarios.json
│   └── balance.json             # Tuning numbers
│
└── tests/
    └── ...
```

---

## Iteration Milestones

### Milestone 0: Skeleton (1-2 days)
**Goal:** Empty Godot project that runs

```
✓ Project created with folder structure
✓ Main scene loads
✓ Can see a placeholder sprite
✓ Basic input handling (camera pan/zoom)
```

**Deliverable:** You can run the game and move a camera around an empty space.

---

### Milestone 1: Grid & Blocks (3-5 days)
**Goal:** Place and remove blocks on a 3D grid

```
Core:
  - Grid class: sparse 3D dictionary of blocks
  - Block base class: position, type, sprite
  - Block registry: load definitions from JSON

Rendering:
  - Isometric camera setup
  - Block sprites render at correct positions
  - Y-sorting for depth (higher Z = behind)

Input:
  - Click to place block
  - Right-click to remove
  - Simple block picker (just 3-4 types)

Data:
  - blocks.json with 4 block types:
    - Corridor (1x1)
    - Residential (1x1)
    - Commercial (1x1)
    - Empty/Void
```

**Deliverable:** You can build a little structure by clicking. Blocks stack. It looks isometric.

**Key Code:**

```gdscript
# grid.gd
class_name Grid

var blocks: Dictionary = {}  # Vector3i -> Block

func set_block(pos: Vector3i, block: Block) -> void:
    blocks[pos] = block
    
func get_block(pos: Vector3i) -> Block:
    return blocks.get(pos)
    
func remove_block(pos: Vector3i) -> void:
    blocks.erase(pos)

func world_to_grid(world_pos: Vector2) -> Vector3i:
    # Isometric conversion
    pass

func grid_to_world(grid_pos: Vector3i) -> Vector2:
    # Isometric conversion  
    pass
```

```gdscript
# block.gd
class_name Block

var grid_position: Vector3i
var block_type: String
var sprite: Sprite2D

func _init(type: String, pos: Vector3i):
    block_type = type
    grid_position = pos
```

---

### Milestone 2: Floor Navigation (3-5 days)
**Goal:** Multiple floors, can switch between viewing them

```
Features:
  - Floor selector UI (up/down buttons, floor indicator)
  - Show current floor + 1-2 floors below (transparency)
  - Hide floors above current view
  - Blocks can be placed on any floor

Camera:
  - Floor切り替え animates smoothly
  - Optional: slice view (show cross-section)
```

**Deliverable:** You can build a 5-story structure and navigate between floors.

---

### Milestone 3: Connectivity & Paths (5-7 days)
**Goal:** Blocks know what they're connected to

```
Core:
  - Adjacency detection (6 neighbors in 3D)
  - Path connectivity: flood-fill from "entrance"
  - Blocks track: connected_to_entrance (bool)

Visual:
  - Unconnected blocks show warning icon
  - Optional: connectivity overlay

Corridors:
  - Corridor blocks connect horizontally
  - Stairs connect ±1 floor
  - Elevator shaft connects many floors (vertical stack)
  
New Blocks:
  - Stairs (connects Z and Z+1)
  - Elevator Shaft (vertical, connects all floors it spans)
```

**Deliverable:** Build residential, connect with corridor to stairs. Game shows what's connected.

**Key Code:**

```gdscript
# In grid.gd or separate connectivity.gd

func get_neighbors(pos: Vector3i) -> Array[Vector3i]:
    return [
        pos + Vector3i(1, 0, 0),
        pos + Vector3i(-1, 0, 0),
        pos + Vector3i(0, 1, 0),
        pos + Vector3i(0, -1, 0),
        pos + Vector3i(0, 0, 1),
        pos + Vector3i(0, 0, -1),
    ]

func calculate_connectivity(entrance_pos: Vector3i) -> void:
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
            for neighbor in get_connected_neighbors(current):
                if not visited.has(neighbor):
                    queue.append(neighbor)
```

---

### Milestone 4: Environment - Light (3-5 days)
**Goal:** Blocks have light levels, affects gameplay

```
Light System:
  - Exterior faces get natural light (100%)
  - Light decreases with distance from exterior
  - Top floor = full light
  - Each floor down = -20% (simple version)

Visual:
  - Light overlay (yellow gradient)
  - Dark blocks visually dimmer

Gameplay Hook:
  - Residential shows "Light: 80%" in tooltip
  - (No consequences yet, just display)
```

**Deliverable:** Build down, see it get darker. Toggle light overlay.

---

### Milestone 5: Basic Economy (3-5 days)
**Goal:** Money exists, blocks cost money, residential generates rent

```
Economy:
  - Treasury (starting money)
  - Blocks have construction cost
  - Residential generates rent per game-tick
  - Simple monthly cycle

UI:
  - Money display
  - "Can't afford" feedback
  - Monthly income/expense summary

Balance:
  - Start with $10,000
  - Corridor: $50
  - Residential: $500, generates $100/month
  - Commercial: $800, generates $200/month (if connected)
```

**Deliverable:** Start with money, spend it building, watch rent come in. Can go bankrupt.

---

### Milestone 6: Time & Simulation Tick (3-5 days)
**Goal:** Game has time, things happen over time

```
Game Clock:
  - Pause / 1x / 2x / 3x speed
  - Day/night cycle (visual only for now)
  - Monthly tick (rent collection)
  
Tick Architecture:
  - Hourly tick: light updates
  - Daily tick: (placeholder)
  - Monthly tick: economy

UI:
  - Time display (Day X, Month Y)
  - Speed controls
  - Pause
```

**Deliverable:** Watch time pass. See monthly rent deposits. Pause and resume.

---

### Milestone 7: Simple Residents (5-7 days)
**Goal:** People exist and live in residential blocks

```
Residents:
  - Each residential block has occupancy (0-4 people)
  - Residents have names (generated)
  - Residents have satisfaction (0-100)
  
Population:
  - New residents move in if vacancy exists
  - Residents leave if satisfaction too low
  - Population counter

Satisfaction (Simple):
  - Based on light level only
  - Light > 60% = satisfied
  - Light < 40% = unhappy

UI:
  - Population counter
  - Click block to see residents
  - Simple resident list
```

**Deliverable:** Build residential, people move in. Build underground, people are unhappy and leave.

---

### Milestone 8: Pathfinding & Commute (5-7 days)
**Goal:** Residents travel to destinations

```
Transit Graph:
  - Build node graph from blocks
  - Nodes: rooms, corridors, elevator stops
  - Edges: walking connections

Pathfinding:
  - A* on transit graph
  - Cost = distance (simple)

Residents:
  - Residential blocks have "home"
  - Commercial blocks are "work"
  - Residents path from home to work (if commercial exists)
  - Commute time affects satisfaction

Visual:
  - Optional: show paths
  - Optional: show little resident sprites walking
```

**Deliverable:** Build home + corridor + work. See commute time. Long commute = unhappy.

---

### Milestone 9: Multiple Block Types (3-5 days)
**Goal:** Flesh out the block catalog

```
New Blocks:
  - Industrial (cheap, generates jobs, noise)
  - Office (mid-tier, needs light)
  - Restaurant (needs foot traffic)
  - Grocery (provides food access radius)
  - Park/Garden (provides vibes)

Block Properties:
  - Each block type has: needs, produces, effects
  - Load from blocks.json

Simple Dependencies:
  - Restaurant needs: foot_traffic > 10
  - Office needs: light > 50%
  - Industrial: tolerates darkness
```

**Deliverable:** Build a diverse structure. See blocks succeed or fail based on environment.

---

### Milestone 10: Overlays & Info (3-5 days)
**Goal:** Player can see what's happening

```
Overlays:
  - Light (yellow gradient)
  - Connectivity (green = connected, red = not)
  - Block type (color by category)

Info Panel:
  - Click block to see details
  - Shows: type, light, connected, occupancy, revenue

Budget Panel:
  - Monthly breakdown
  - Income by source
  - Expenses by category
```

**Deliverable:** Toggle overlays. Click for info. Understand your arcology.

---

## After Milestone 10: You Have a Game!

At this point you have a playable city builder. Subsequent milestones add depth:

| Milestone | Feature | Complexity |
|-----------|---------|------------|
| 11 | Air quality system | Medium |
| 12 | Noise propagation | Medium |
| 13 | Safety/crime system | Medium |
| 14 | Vibes composite score | Easy |
| 15 | Resident needs (5-tier) | Medium |
| 16 | Relationships & social | Hard |
| 17 | Elevator wait times | Medium |
| 18 | Multiple scenarios | Easy |
| 19 | Save/Load | Medium |
| 20 | Entropy/decay | Medium |
| 21 | Notable residents & stories | Hard |
| 22 | AEI win condition | Easy |

---

## Data-Driven Design

Keep balance numbers OUT of code. Load from JSON:

```json
// data/blocks.json
{
  "residential_basic": {
    "name": "Basic Apartment",
    "size": [1, 1, 1],
    "cost": 500,
    "category": "residential",
    "capacity": 4,
    "needs": {
      "power": 5,
      "light_min": 20
    },
    "produces": {
      "rent_base": 100
    },
    "sprite": "res://assets/sprites/blocks/residential_basic.png"
  },
  "corridor": {
    "name": "Corridor",
    "size": [1, 1, 1],
    "cost": 50,
    "category": "transit",
    "traversable": true,
    "needs": {
      "power": 1
    },
    "sprite": "res://assets/sprites/blocks/corridor.png"
  }
}
```

```json
// data/balance.json
{
  "economy": {
    "starting_money": 10000,
    "month_length_seconds": 60
  },
  "environment": {
    "light_falloff_per_floor": 20,
    "min_light_for_residential": 40
  },
  "population": {
    "move_in_threshold": 30,
    "move_out_threshold": 20
  }
}
```

---

## Isometric Math Cheat Sheet

```gdscript
# Standard isometric projection (2:1 ratio)
const TILE_WIDTH = 64
const TILE_HEIGHT = 32
const FLOOR_HEIGHT = 24  # Visual height per Z level

func grid_to_screen(grid_pos: Vector3i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2)
    var y = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2)
    y -= grid_pos.z * FLOOR_HEIGHT  # Higher Z = higher on screen
    return Vector2(x, y)

func screen_to_grid(screen_pos: Vector2, z_level: int) -> Vector3i:
    # Adjust for current Z level
    var adjusted_y = screen_pos.y + z_level * FLOOR_HEIGHT
    
    var grid_x = (screen_pos.x / (TILE_WIDTH / 2) + adjusted_y / (TILE_HEIGHT / 2)) / 2
    var grid_y = (adjusted_y / (TILE_HEIGHT / 2) - screen_pos.x / (TILE_WIDTH / 2)) / 2
    
    return Vector3i(int(grid_x), int(grid_y), z_level)
```

---

## Common Patterns

### Signal-Based Updates

Don't poll. Use signals:

```gdscript
# block.gd
signal block_placed(block: Block)
signal block_removed(block: Block)
signal block_updated(block: Block)

# environment/light_system.gd
func _ready():
    Grid.block_placed.connect(_on_block_changed)
    Grid.block_removed.connect(_on_block_changed)
    
func _on_block_changed(block: Block):
    recalculate_light_for_area(block.grid_position)
```

### System Independence

Systems shouldn't know about each other directly:

```gdscript
# BAD - tight coupling
func calculate_rent():
    var light = LightSystem.get_light(position)  # Direct reference
    
# GOOD - data on block
func calculate_rent():
    var light = block.environment.light  # Block caches its environment
```

### Lazy Recalculation

Don't recalculate everything every frame:

```gdscript
var _light_dirty: bool = false
var _dirty_blocks: Array[Vector3i] = []

func mark_dirty(pos: Vector3i):
    _light_dirty = true
    _dirty_blocks.append(pos)

func _process(delta):
    if _light_dirty:
        recalculate_dirty_blocks()
        _light_dirty = false
        _dirty_blocks.clear()
```

---

## Testing Strategy

Prioritize these test types:

1. **Grid math tests**: Isometric conversion, neighbor finding
2. **Connectivity tests**: Flood fill, path finding
3. **Economy tests**: Rent calculation, bankruptcy
4. **Balance tests**: Can a player actually succeed?

```gdscript
# tests/test_grid.gd
extends GutTest

func test_neighbor_finding():
    var pos = Vector3i(5, 5, 0)
    var neighbors = Grid.get_neighbors(pos)
    assert_eq(neighbors.size(), 6)
    assert_has(neighbors, Vector3i(6, 5, 0))
    
func test_isometric_roundtrip():
    var original = Vector3i(10, 5, 2)
    var screen = Grid.grid_to_screen(original)
    var back = Grid.screen_to_grid(screen, 2)
    assert_eq(original, back)
```

---

## Performance Guidelines

**Don't optimize prematurely, but keep these in mind:**

| System | Target | Strategy |
|--------|--------|----------|
| Grid lookup | O(1) | Dictionary with Vector3i keys |
| Pathfinding | <10ms for typical path | Pre-computed graph, A* |
| Light propagation | <50ms full recalc | Dirty regions, incremental |
| Rendering | 60fps at 1000 blocks | Shader-based, view culling |
| Agents | 30fps at 10K agents | Statistical simulation for most |

---

## When Stuck

1. **Simplify**: Cut the feature in half. Then half again.
2. **Hardcode first**: Get it working with magic numbers, then data-drive it.
3. **Visual debug**: Add debug drawing for whatever's broken.
4. **Check the PRD**: The answer might be there.
5. **Playtest**: Sometimes the "bug" is actually fine.

---

## Quick Reference: Block Properties

Every block should define:

```gdscript
class_name Block

# Identity
var block_type: String
var display_name: String
var category: String  # residential, commercial, industrial, civic, transit, green

# Position
var grid_position: Vector3i

# Size (most are 1x1x1)
var size: Vector3i = Vector3i(1, 1, 1)

# Traversability
var is_traversable: bool = false  # Can people walk through?
var is_public: bool = false       # Can pathfinding route THROUGH (not just to)?

# Environment (calculated by systems)
var environment := {
    "light": 0,
    "air": 0,
    "noise": 0,
    "safety": 0,
    "vibes": 0
}

# Connectivity
var connected_to_entrance: bool = false

# Economics
var construction_cost: int
var monthly_revenue: int
var monthly_expense: int

# Occupancy (if applicable)
var capacity: int = 0
var occupants: Array = []
```

---

## Next Steps After Reading This

1. Create empty Godot 4 project with folder structure
2. Implement Milestone 0 (skeleton)
3. Implement Milestone 1 (grid & blocks)
4. Keep going!

**Remember: A working game with 5 block types beats a perfect engine with no game.**

---

*Last updated: January 2025*
