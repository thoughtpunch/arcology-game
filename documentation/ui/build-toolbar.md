# Build Toolbar

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

The Build Toolbar is the primary interface for placing blocks in the 3D world. It provides categorized access to all buildable blocks, a ghost preview system for placement visualization, and face-snap placement where new blocks attach to the faces of existing geometry.

> **Reference:** [3D Refactor Specification §6](../architecture/3d-refactor/specification.md)

---

## Toolbar Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  BLOCK CATEGORIES                              PLACEMENT CONTROLS   │
│ ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐   ┌─────┬─────┬─────┐  │
│ │ RES │ COM │ IND │ TRA │ GRN │ CIV │ INF │   │ ROT │ VAR │ DEL │  │
│ │  1  │  2  │  3  │  4  │  5  │  6  │  7  │   │  R  │  V  │  X  │  │
│ └─────┴─────┴─────┴─────┴─────┴─────┴─────┘   └─────┴─────┴─────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Block Categories

| Category | Key | Icon | Color | Contents |
|----------|-----|------|-------|----------|
| Residential | 1 | House | Blue | Apartments, condos, dormitories |
| Commercial | 2 | Store | Green | Shops, restaurants, offices |
| Industrial | 3 | Gear | Orange | Workshops, factories, utilities |
| Transit | 4 | Arrow | Gray | Corridors, elevators, stairs |
| Green | 5 | Leaf | Dark Green | Parks, gardens, atriums |
| Civic | 6 | Column | Purple | Schools, clinics, community |
| Infrastructure | 7 | Bolt | Yellow | Power, water, HVAC, light pipes |

---

## Category Expansion

Clicking a category opens a flyout panel above the toolbar:

```
                    ┌─────────────────────────────────────┐
                    │  RESIDENTIAL                    [×] │
                    ├─────────────────────────────────────┤
                    │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
                    │  │ APT │ │ APT │ │CONDO│ │DORM │   │
                    │  │ SM  │ │ LG  │ │     │ │     │   │
                    │  │$500 │ │$800 │ │$1.2K│ │$400 │   │
                    │  └─────┘ └─────┘ └─────┘ └─────┘   │
                    │  ┌─────┐ ┌─────┐ ┌─────┐           │
                    │  │PENT │ │LOFT │ │ ... │           │
                    │  │HOUSE│ │     │ │     │           │
                    │  │$3K  │ │$1.5K│ │     │           │
                    │  └─────┘ └─────┘ └─────┘           │
                    └─────────────────────────────────────┘
```

### Flyout Contents

Each block tile shows:
- Block 3D thumbnail (rendered preview)
- Block name
- Construction cost
- Size indicator (if multi-cell)

---

## Block Selection States

| State | Visual | Description |
|-------|--------|-------------|
| Available | Normal | Can be built |
| Selected | Highlighted border | Currently selected for placement |
| Locked | Grayed + lock icon | Not yet unlocked (tech tree / milestone) |
| Unaffordable | Red tint | Not enough money |

---

## Face-Snap Placement Workflow

The 3D placement system uses **face snapping** — new blocks attach to the faces of existing geometry, Minecraft-style.

### Step-by-Step Flow

```
1. SELECT    →  Pick block type from toolbar
                Ghost preview appears at cursor

2. HOVER     →  Move cursor over existing blocks
                Raycast hits a block face
                Ghost snaps to the adjacent grid cell

3. ROTATE    →  Press R for 90° rotation around Y axis
                Ghost updates orientation

4. VALIDATE  →  Automatic validation with color feedback:
                🟢 Green  = valid placement
                🟡 Yellow = valid with warnings
                🔴 Red    = invalid (blocked/unsupported)

5. CLICK     →  Left-click to place
                Block instantiates, panels auto-generate
```

### Multi-Axis Building

Blocks can be placed in any direction by clicking the appropriate face:

| Face Clicked | Placement Direction | Use Case |
|-------------|---------------------|----------|
| TOP face | Build upward (Y+) | Adding floors |
| BOTTOM face | Build downward (Y-) | Excavation / sublevels |
| NORTH face | Build north (Z+) | Horizontal expansion |
| SOUTH face | Build south (Z-) | Horizontal expansion |
| EAST face | Build east (X+) | Horizontal expansion |
| WEST face | Build west (X-) | Horizontal expansion |

### Face Snapping Logic

```gdscript
func get_placement_position(hit_pos: Vector3, hit_normal: Vector3) -> Vector3i:
    # Get grid position of the block that was hit
    var hit_grid = world_to_grid(hit_pos - hit_normal * 0.1)

    # Get face direction as grid offset
    var face_offset = Vector3i(
        int(round(hit_normal.x)),
        int(round(hit_normal.y)),
        int(round(hit_normal.z))
    )

    # New block goes adjacent to hit face
    return hit_grid + face_offset
```

---

## Ghost Preview

A semi-transparent preview of the block being placed, rendered at the snap position.

### Ghost States

| State | Color | Meaning |
|-------|-------|---------|
| **Valid** | Green tint | All requirements met, placement allowed |
| **Warning** | Yellow tint | Placement allowed, but warnings present (blocks light, dead-end corridor, far from utilities) |
| **Invalid** | Red tint | Placement blocked (space occupied, exceeds cantilever, no structural support, prerequisites not met) |

### Ghost Rendering

- Semi-transparent shader (alpha ~0.5)
- Color tint based on validation state
- Shows block footprint on the grid
- Updates every frame as cursor moves
- Rotation previewed in real-time

---

## Placement Validation

Every placement is automatically validated before the player clicks:

```gdscript
func validate_placement(block_type: BlockType, grid_pos: Vector3i, rotation: int) -> PlacementResult:
    # Check if space is empty
    # Check structural support (vertically-supported column to ground)
    # Check cantilever limits (BFS to nearest supported column)
    # Check prerequisites (block type requirements)
    # Gather warnings (blocks light, dead-end, etc.)
```

### Validation Checks

| Check | Condition | Result |
|-------|-----------|--------|
| Space occupied | Another block at grid position | Red (invalid) |
| No support | No structural column to ground | Red (invalid) |
| Cantilever exceeded | Too far from supported column | Red (invalid) |
| Prerequisites unmet | Missing required adjacent blocks | Red (invalid) |
| Blocks light | Placement would shadow interior | Yellow (warning) |
| Dead-end corridor | No through-path | Yellow (warning) |
| Far from utilities | No nearby infrastructure | Yellow (warning) |

---

## Placement Controls

| Action | Input | Description |
|--------|-------|-------------|
| Place block | Left-click | Build at cursor position |
| Cancel | Right-click / Esc | Exit placement mode |
| Rotate 90° CW | R | Rotate around vertical (Y) axis |
| Rotate 90° CCW | Shift+R | Rotate counter-clockwise |
| Cycle variant | V | Cycle visual variants |
| Place & keep selected | Shift+Left-click | Place without exiting build mode |
| Drag-place | Hold Left-click + drag | Place continuous run (corridors) |

---

## Drag-to-Build (Corridors)

Corridors and similar linear blocks support drag placement:

1. Select corridor type
2. Click start position on a block face
3. Drag to end position — preview shows the full path
4. Release to build entire path

```
Start ──→──→──→──→ End
[COR][COR][COR][COR][COR]
```

**Routing rules:**
- Horizontal only (drag cannot change Y level)
- Manhattan routing (orthogonal paths only)
- Auto-corners at direction changes
- Auto-junctions where paths intersect existing corridors
- Shows total cost while dragging
- Escape to cancel, release to confirm

---

## Quick Build

Recently used blocks appear in a sidebar for fast access:

```
┌───────┐
│ QUICK │
├───────┤
│ [APT] │  ← Last placed
│ [COR] │
│ [ELV] │
│ [SHP] │
│ [---] │
└───────┘
```

- Shows last 5 unique blocks placed
- Click to select immediately
- Drag to reorder favorites

---

## Favorites

Players can pin frequently used blocks:

- Right-click block in flyout → "Add to Favorites"
- Favorites appear below Quick Build
- Maximum 10 favorites
- Persists between sessions

---

## Demolish Tool

Accessed via **X** key or toolbar button:

| Action | Input |
|--------|-------|
| Select demolish | X key |
| Demolish single | Left-click block |
| Demolish area | Drag-select multiple blocks |
| Cancel | Right-click / Esc |

Demolish shows:
- Refund amount (50% of build cost)
- Warning if block is occupied
- Confirmation dialog for expensive blocks
- Structural warning if removal would orphan adjacent blocks

---

## Cost Display

Tooltip when hovering or selecting a block type:

```
┌─────────────────────────┐
│  Small Apartment        │
│  ────────────────────   │
│  Cost: $500             │
│  Size: 1×1×1 (6m cube) │
│  Monthly: +$80 rent     │
│  Capacity: 2 residents  │
│  Needs: Light, Air      │
└─────────────────────────┘
```

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| B | Enter build mode |
| 1-7 | Open category |
| Esc | Close flyout / Cancel placement |
| R | Rotate block 90° CW |
| Shift+R | Rotate block 90° CCW |
| V | Cycle variant |
| X | Switch to demolish tool |
| Q | Select tool (exit build mode) |
| Shift+Click | Place without exiting mode |
| Ctrl+Z | Undo last placement |

---

## See Also

- [hud-layout.md](./hud-layout.md) — Toolbar position
- [controls.md](./controls.md) — Full input mapping table
- [../game-design/blocks/](../game-design/blocks/) — Block type specifications
- [../architecture/3d-refactor/specification.md](../architecture/3d-refactor/specification.md) — 3D spec §6 Block Placement System
