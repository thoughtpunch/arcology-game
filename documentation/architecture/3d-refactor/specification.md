# Arcology: 3D Refactor Specification

> **Status:** APPROVED - Implementation Ready
> **Created:** 2026-01-26
> **Supersedes:** Previous 2D isometric rendering system
> **Epic:** arcology-3d (to be created)

---

## Overview

This document defines the complete migration from 2D isometric sprite-based rendering to full 3D with free camera rotation on a cubic grid. All rendering, camera, input, and terrain systems will be replaced.

**What changes:** Rendering, camera, input handling, terrain, block visuals
**What stays:** Game logic, economy, agents, menus, save/load format, simulation systems

---

## 1. The Cell: Foundational Unit

### 1.1 Definition

The **Cell** is the atomic unit of 3D space in Arcology. All blocks occupy one or more cells on an orthogonal grid. Each cell is a true cube.

```
THE CELL
========

Dimensions: 6m x 6m x 6m (Width x Depth x Height)
Imperial:   ~20ft x 20ft x 20ft

Footprint:  36 m² (388 sq ft)
Volume:     216 m³

Internal floors: 2 residential floors at 3m each
                 OR 1 double-height commercial/civic floor

            +---------------+
           /               /|
          /       6m      / |
         +---------------+  |
         |               |  | 6m
         |   1 CELL      |  |
         |               | /
         |               |/ 6m
         +---------------+
```

### 1.2 Why These Dimensions

| Dimension | Value | Rationale |
|-----------|-------|-----------|
| Width | 6m | Comfortable room width; fits studio layout |
| Depth | 6m | Square footprint for rotational symmetry |
| Height | 6m | True cube; fits 2 residential floors or 1 double-height space |

**Internal floor layout (residential mode, 2 floors at 3m each):**
```
+-------------------------------+
|  Slab: 150mm                  |  <- Concrete + steel deck
+-------------------------------+
|                               |
|  Usable: 2.5m                 |  <- Occupant space (upper floor)
|                               |
+-------------------------------+
|  Ceiling/Plenum: 350mm        |  <- HVAC, pipes, cables
+-------------------------------+  <- Internal floor slab
|  Slab: 150mm                  |
+-------------------------------+
|                               |
|  Usable: 2.5m                 |  <- Occupant space (lower floor)
|                               |
+-------------------------------+
|  Ceiling/Plenum: 350mm        |  <- HVAC, pipes, cables
+-------------------------------+
        TOTAL: 6.0m
```

**Internal layout (double-height mode, 1 floor):**
```
+-------------------------------+
|  Slab: 200mm                  |  <- Concrete + steel deck
+-------------------------------+
|                               |
|                               |
|  Usable: 5.4m                 |  <- Full double-height space
|                               |
|                               |
+-------------------------------+
|  Ceiling/Plenum: 400mm        |  <- HVAC, pipes, cables
+-------------------------------+
        TOTAL: 6.0m
```

### 1.3 Scale Reference

**Vertical Scale (1 cell = 6m = 2 internal floors):**

| Cells | Height | Internal Floors | Real-World Equivalent |
|-------|--------|-----------------|----------------------|
| 1 | 6m | 2 | Two-story rowhouse |
| 3 | 18m | 6 | Walk-up apartment |
| 5 | 30m | 10 | Mid-rise |
| 10 | 60m | 20 | High-rise |
| 17 | 102m | 34 | Skyscraper threshold |
| 30 | 180m | 60 | Skyscraper |
| 50 | 300m | 100 | Supertall |
| 70 | 420m | 140 | Megatall (Empire State scale) |
| 100 | 600m | 200 | True megatall |

**Horizontal Scale:**

| Cells | Span | Real-World Equivalent |
|-------|------|----------------------|
| 1 | 6m | One room |
| 5 | 30m | Large apartment building |
| 10 | 60m | Building wing |
| 20 | 120m | City block edge |
| 50 | 300m | Mega-complex |
| 100 | 600m | True arcology |

### 1.4 Residential Density Model

Each cell contains **2 internal floors** of 36 m² each. The block type determines how those floors subdivide into dwelling units:

| Block Type | Cells | Internal Layout | Unit Size | Units | Real-World Equivalent |
|------------|-------|-----------------|-----------|-------|-----------------------|
| Pod housing | 1x1x1 | 2 floors, 2 units/floor | 18 m² | 4 | Hong Kong micro-flat |
| Studio | 1x1x1 | 2 floors, 1 unit/floor | 36 m² | 2 | Comfortable studio |
| Apartment (1BR) | 1x1x1 | Duplex (both floors) | 72 m² | 1 | Generous 1BR |
| Family (2BR) | 2x1x1 | Duplex, double-wide | 144 m² | 1 | Spacious 2-3BR |
| Family (2BR) | 2x1x1 | 2 side-by-side duplexes | 72 m² | 2 | Two 1BR apartments |

**Key insight:** Same cell footprint, different density. The player chooses density vs. quality per block.

### 1.5 What Fits in 1 Cell

**Residential (36 m² footprint x 2 floors = 72 m² total):**
- 2 studio apartments (1 per floor), or
- 1 duplex apartment (spanning both floors)

**Commercial (36 m² footprint x 6m double-height):**
- Boutique, coffee counter, small service business
- Full 5.4m ceiling height for retail/dining

**Transit:**
- Generous corridor: 5m clear width, 2-way traffic, benches, planters
- Double-height atrium segment

**Office (36 m² footprint x 2 floors):**
- 2 floors x 6 workstations = 12 workstations, or
- 4 private offices across 2 floors

### 1.6 Multi-Cell Blocks

| Size (Cells) | Dimensions | Examples |
|--------------|------------|----------|
| 1x1x1 | 6x6x6m | Studio (2 units), apartment (1 unit), shop, corridor |
| 2x1x1 | 12x6x6m | Family apartment, restaurant, wide corridor |
| 2x2x1 | 12x12x6m | Large apartment, office suite, clinic |
| 3x2x1 | 18x12x6m | Grocery, large clinic, school wing |
| 2x2x2 | 12x12x12m | Grand lobby, elevator bank (4 internal floors) |
| 5x5x1 | 30x30x6m | Food hall, market hall |
| 5x5x2 | 30x30x12m | Indoor forest, atrium, arena section |

---

## 2. Grid Architecture

### 2.1 Coordinate System

```
Y (up)
|
|    Z (north)
|   /
|  /
| /
+-------- X (east)

Origin (0,0,0) = Southwest corner of ground plane at grade
Positive Y = Above ground (building up)
Negative Y = Below ground (excavation)
```

**BREAKING CHANGE from 2D:** In the old system, Z was floor level. In 3D, Y is vertical (up).

### 2.2 Grid Position

Every cube in the world has an integer grid position:

```gdscript
GridPosition {
    x: int    # East-West (0 = origin, positive = east)
    y: int    # Vertical (0 = ground, positive = up, negative = down)
    z: int    # North-South (0 = origin, positive = north)
}
```

### 2.3 World <-> Grid Conversion

```gdscript
const CELL_SIZE: float = 6.0     # meters (all axes — true cube)

func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * CELL_SIZE,
        grid_pos.y * CELL_SIZE,
        grid_pos.z * CELL_SIZE
    )

func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * CELL_SIZE + CELL_SIZE / 2,
        grid_pos.y * CELL_SIZE + CELL_SIZE / 2,
        grid_pos.z * CELL_SIZE + CELL_SIZE / 2
    )

func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CELL_SIZE)),
        int(floor(world_pos.y / CELL_SIZE)),
        int(floor(world_pos.z / CELL_SIZE))
    )
```

### 2.4 Cube Faces

Each cube has 6 faces for connection and panel generation:

```gdscript
enum CubeFace {
    TOP,      # Y+ (roof/ceiling)
    BOTTOM,   # Y- (floor)
    NORTH,    # Z+
    SOUTH,    # Z-
    EAST,     # X+
    WEST      # X-
}

const FACE_NORMALS = {
    CubeFace.TOP:    Vector3(0, 1, 0),
    CubeFace.BOTTOM: Vector3(0, -1, 0),
    CubeFace.NORTH:  Vector3(0, 0, 1),
    CubeFace.SOUTH:  Vector3(0, 0, -1),
    CubeFace.EAST:   Vector3(1, 0, 0),
    CubeFace.WEST:   Vector3(-1, 0, 0),
}

const FACE_ADJACENT_OFFSET = {
    CubeFace.TOP:    Vector3i(0, 1, 0),
    CubeFace.BOTTOM: Vector3i(0, -1, 0),
    CubeFace.NORTH:  Vector3i(0, 0, 1),
    CubeFace.SOUTH:  Vector3i(0, 0, -1),
    CubeFace.EAST:   Vector3i(1, 0, 0),
    CubeFace.WEST:   Vector3i(-1, 0, 0),
}
```

---

## 3. Rendering Architecture

### 3.1 Engine & Pipeline

**Engine:** Godot 4.x with Vulkan/Forward+ renderer

**Rendering approach:**
- 3D meshes (not 2D sprites)
- PBR materials with stylization
- Real-time lighting with baked GI option
- Post-processing for visual style

### 3.2 Art Direction

**Target aesthetic:**
- Stylized realism (not photorealistic, not cartoon)
- Clean, readable silhouettes at all zoom levels
- Warm, optimistic color palette
- Subtle ambient occlusion for depth
- Soft edges, slight bevels

**Reference games:**
- Cities: Skylines (camera freedom, scale)
- Townscaper (cozy aesthetic, procedural charm)
- Two Point Hospital (readable interiors)
- The Sims 4 (build mode clarity)

**Avoid:**
- Minecraft (too blocky, no architectural detail)
- Photorealistic city builders (too serious)
- Mobile city games (too garish)

### 3.3 Block Mesh Structure

Each block type requires:

```gdscript
BlockVisuals {
    # Core geometry
    exterior_mesh: Mesh        # Outer shell
    interior_mesh: Mesh        # Furniture, fixtures (for cutaway)
    collision_mesh: Mesh       # Simplified for raycasting

    # Level of Detail
    lod_meshes: [Mesh]         # LOD0 (full) through LOD3 (distant)

    # Materials
    material: ShaderMaterial   # Supports overlays, damage, selection

    # Auto-generated panels (on exterior faces)
    panel_slots: {
        top: PanelType | null,
        bottom: PanelType | null,
        north: PanelType | null,
        south: PanelType | null,
        east: PanelType | null,
        west: PanelType | null,
    }

    # UI
    icon: Texture2D            # Menu icon
    thumbnail: Texture2D       # Tooltip preview
}
```

### 3.4 Level of Detail (LOD)

| Distance | LOD | Detail Level |
|----------|-----|--------------|
| 0-50m | LOD0 | Full detail, interior visible |
| 50-150m | LOD1 | Simplified exterior, no interior |
| 150-400m | LOD2 | Block silhouette only |
| 400m+ | LOD3 | Merged chunks, impostors |

### 3.5 Chunk System

Static geometry is merged into chunks for performance:

```
CHUNK SIZE: 8x8x8 cells (48m x 48m x 48m)

Per chunk:
  - Merge static opaque geometry -> single draw call
  - Separate mesh layers:
      1. Opaque exterior
      2. Transparent (glass panels)
      3. Interior (for cutaway rendering)
      4. Dynamic (doors, elevators, agents)
  - Rebuild only when blocks change in chunk
  - Frustum cull entire chunks
```

### 3.6 Panel Materials (3D)

Panels auto-generate on cube faces touching exterior/void:

| Material | Mesh Style | Shader Properties |
|----------|------------|-------------------|
| Solid (concrete) | Flat with subtle texture | Matte, AO in crevices |
| Glass | Framed panes | Reflective, slight blue tint, transparency |
| Metal | Brushed panels | Subtle reflection, visible seams |
| Solar | Grid of cells | Dark blue, subtle glow, animated shimmer |
| Garden | Organic foliage | Subsurface scattering, wind animation |
| Force Field | Flat plane | Animated energy shader, edge glow |

---

## 4. Camera System

### 4.1 Two Camera Modes

**MODE 1: FREE CAMERA (Default)**
- Full 360° orbital rotation
- Perspective projection
- Smooth interpolated movement
- Use for: Exploration, admiring builds, following agents

**MODE 2: ORTHO SNAP (Planning)**
- Snaps to 90° increments
- Orthographic projection (no perspective distortion)
- Grid overlay visible
- Use for: Precise placement, floor plans, sections

### 4.2 Camera Controls

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Orbit (rotate) | Middle-drag | Q/E | Right Stick |
| Pan | Shift+Middle / Edge scroll | WASD | Left Stick |
| Zoom | Scroll wheel | Z/X | Triggers |
| Tilt (pitch) | Middle-drag vertical | R/F | Right Stick Y |
| Reset view | Double-click middle | Home | R3 |
| Focus selection | - | F | Y |
| Toggle Free/Ortho | - | Tab | Back |

### 4.3 Orthographic Views

Press number keys or click View Cube to snap:

| Key | View | Camera Position | Use Case |
|-----|------|-----------------|----------|
| 1 | Top-Down | Above, looking down | Floor plans |
| 2 | North | South of target, looking north | Front elevation |
| 3 | East | West of target, looking east | Side elevation |
| 4 | South | North of target, looking south | Back elevation |
| 5 | West | East of target, looking west | Side elevation |
| 6 | Bottom | Below, looking up | Ceiling/underground |
| 7 | Isometric | 45° angle, still orthographic | Overview |
| 0 | Free | Return to perspective mode | Exploration |

### 4.4 View Cube Widget

Corner widget for quick view switching:
- Click face -> Snap to that ortho view
- Click edge -> Snap to 45° between two faces
- Click corner -> Snap to isometric
- Drag cube -> Free rotate (stays in ortho mode)
- Double-click -> Return to free camera

### 4.5 Camera Constraints

```gdscript
# Distance limits
const MIN_DISTANCE: float = 10.0      # ~2 cubes, interior detail
const MAX_DISTANCE: float = 2000.0    # Entire arcology visible

# Angle limits (free mode)
const MIN_ELEVATION: float = 5.0      # Nearly horizontal
const MAX_ELEVATION: float = 89.0     # Nearly top-down

# Ortho size limits
const MIN_ORTHO_SIZE: float = 20.0    # ~3 cubes visible
const MAX_ORTHO_SIZE: float = 500.0   # Large overview

# Collision
# Camera soft-collides with geometry (pushes back, never clips inside)
```

---

## 5. Visibility Modes

Since blocks enclose space, players need ways to see inside the structure.

### 5.1 Cutaway Mode

Removes all geometry above a horizontal cut plane:
- Toggle: C key
- Adjust height: [ and ] keys, or drag cut plane
- Clean horizontal slice
- Cut edges show subtle glow/outline
- Interior floors and walls visible below cut
- Optional: ghost silhouette of removed floors

### 5.2 X-Ray Mode

Makes exterior walls transparent while keeping interiors solid:
- Toggle: X key
- Transparency slider: 0-100%
- Good for seeing structure + activity simultaneously

### 5.3 Floor Isolate Mode

Shows only a single floor, hiding all others:
- Toggle: I key
- Select floor: Page Up/Down, or click floor selector widget
- Adjacent floors shown as faint ghosts (optional)

### 5.4 Section Mode

Vertical slice showing cross-section:
- Toggle: V key
- Define section line: Click two points in top-down view
- Like an architectural section drawing

---

## 6. Block Placement System

### 6.1 Snap Placement (Minecraft-style)

Blocks snap to the grid by clicking on existing block faces:

1. SELECT block type from menu -> Ghost preview appears at cursor
2. HOVER over existing geometry -> Raycast hits block face -> Ghost snaps to adjacent grid cell
3. ROTATE with R key -> 90° increments around vertical axis
4. VALIDATE automatically:
   - Green = valid placement
   - Yellow = valid but warning (e.g., "blocks light")
   - Red = invalid (blocked, no support, etc.)
5. CLICK to place -> Block instantiates, panels auto-generate, connections lock

### 6.2 Face Snapping Logic

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

### 6.3 Multi-Axis Building

- Click TOP face -> Build upward (Y+)
- Click BOTTOM face -> Build downward (Y-) / dig
- Click SIDE faces -> Build horizontally

### 6.4 Ghost Preview States

- **GREEN (Valid):** Placement allowed, all requirements met
- **YELLOW (Warning):** Placement allowed, but warnings (blocks light, dead-end corridor, far from utilities)
- **RED (Invalid):** Placement blocked (space occupied, exceeds cantilever, no structural support, prerequisites not met)

### 6.5 Placement Validation

```gdscript
func validate_placement(block_type: BlockType, grid_pos: Vector3i, rotation: int) -> PlacementResult:
    var result = PlacementResult.new()

    # Check if space is empty
    if grid.has_block_at(grid_pos):
        result.valid = false
        result.reason = "Space is occupied"
        return result

    # Check structural support
    if not _has_structural_support(grid_pos, block_type):
        result.valid = false
        result.reason = "No structural support"
        return result

    # Check cantilever limits
    if _exceeds_cantilever(grid_pos):
        result.valid = false
        result.reason = "Exceeds cantilever limit"
        return result

    # Check prerequisites
    var prereq_result = _check_prerequisites(block_type, grid_pos)
    if not prereq_result.met:
        result.valid = false
        result.reason = prereq_result.reason
        return result

    # Check for warnings
    result.valid = true
    result.warnings = _gather_warnings(block_type, grid_pos)

    return result
```

### 6.6 Drag-to-Build (Corridors)

Corridors can be placed by dragging a path:
1. Select corridor type
2. Click start position
3. Drag to end position
4. Preview shows path with auto-corners and auto-junctions
5. Release to build entire path

Routing rules: Horizontal only, Manhattan routing, prefers straight lines

---

## 7. Input Handling (3D)

### 7.1 Raycasting for Selection

```gdscript
func get_world_position_at_cursor() -> Dictionary:
    var mouse_pos = get_viewport().get_mouse_position()
    var from = camera.project_ray_origin(mouse_pos)
    var dir = camera.project_ray_normal(mouse_pos)
    var to = from + dir * 2000.0

    var space = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = COLLISION_MASK_BLOCKS | COLLISION_MASK_TERRAIN

    var result = space.intersect_ray(query)

    if result:
        return {
            "hit": true,
            "position": result.position,
            "normal": result.normal,
            "collider": result.collider,
            "grid_pos": world_to_grid(result.position - result.normal * 0.1)
        }

    return {"hit": false}
```

### 7.2 Input Mapping

See full input mapping in implementation tickets.

---

## 8. Performance Targets

### 8.1 Scale Targets

| Scale | Grid Size | Blocks | Population | Target FPS |
|-------|-----------|--------|------------|------------|
| Small | 20x20x20 | ~2,000 | ~5,000 | 60 |
| Medium | 40x40x40 | ~10,000 | ~25,000 | 60 |
| Large | 80x80x60 | ~50,000 | ~100,000 | 60 |
| Mega | 120x120x100 | ~200,000 | ~300,000 | 30+ |

### 8.2 Optimization Strategies

1. **Frustum Culling** - Only render chunks in view
2. **Occlusion Culling** - Skip chunks fully behind solid geometry
3. **LOD System** - 4 levels based on distance
4. **Chunk Merging** - Combine static geometry per chunk
5. **Instancing** - GPU instancing for repeated elements
6. **Deferred Rendering** - Handle many lights efficiently
7. **Async Streaming** - Load/generate distant chunks in background
8. **Simulation LOD** - Full agent sim only for visible/nearby

### 8.3 Memory Budget

```
TARGET: 4GB VRAM, 8GB RAM

Per chunk (8x8x8 cubes):
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

## 9. Terrain System

### 9.1 Ground Plane

The world has a destructible/mineable terrain at and below Y=0:

- Y > 0: Air (buildable, requires structure below)
- Y = 0: Ground surface (natural starting point)
- Y < 0: Underground (must excavate to access)

Underground is solid until excavated. Excavation creates empty cubes that can be built in.

### 9.2 Excavation

Players can dig underground by excavating terrain cubes.

### 9.3 Terrain Rendering

- Above ground: Empty (sky)
- Ground level: Surface mesh (grass, concrete, etc.)
- Below ground (not excavated): Solid earth
- Below ground (excavated): Empty space for building
- Underground walls auto-generate on excavated faces

---

## 10. User Stories (3D-Specific)

| ID | Story |
|----|-------|
| US-3D-1 | As a player, I want to freely rotate the camera 360° around my arcology to view it from any angle. |
| US-3D-2 | As a player, I want to snap to orthographic top/side views for precise floor plan editing. |
| US-3D-3 | As a player, I want a cutaway mode that removes floors above my view so I can see inside the building. |
| US-3D-4 | As a player, I want to place blocks by clicking on existing block faces, Minecraft-style. |
| US-3D-5 | As a player, I want a ghost preview showing exactly where my block will snap before I place it. |
| US-3D-6 | As a player, I want clear visual feedback (green/yellow/red) on whether my placement is valid. |
| US-3D-7 | As a player, I want to rotate blocks in 90° increments before placing them. |
| US-3D-8 | As a player, I want to drag-draw corridors as a connected path rather than placing each segment individually. |
| US-3D-9 | As a player, I want X-ray mode to see activity inside my building while maintaining spatial awareness of the structure. |
| US-3D-10 | As a player, I want smooth camera movement with keyboard and mouse that feels responsive and intuitive. |
| US-3D-11 | As a player, I want to excavate underground to create subterranean spaces. |
| US-3D-12 | As a player, I want the game to run at 60fps even with a large arcology. |

---

## 11. Glossary (3D Terms)

| Term | Definition |
|------|------------|
| **Cell** | The fundamental 6m x 6m x 6m unit of space (true cube); contains 2 internal residential floors or 1 double-height space |
| **Grid Position** | Integer (x, y, z) coordinates in cell units |
| **Face** | One of 6 sides of a cell (top, bottom, north, south, east, west) |
| **Chunk** | 8x8x8 cell region for rendering optimization (48m x 48m x 48m) |
| **LOD** | Level of Detail; simplified meshes for distant objects |
| **Cutaway** | Visibility mode removing geometry above a plane |
| **X-Ray** | Visibility mode making exteriors transparent |
| **Ghost** | Semi-transparent preview of block being placed |
| **Snap** | Automatic alignment of blocks to grid |
| **Ortho View** | Orthographic camera with no perspective distortion |
| **Free Camera** | Perspective camera with full orbital control |
| **Panel** | Auto-generated surface on exterior-facing cube faces |
| **Excavation** | Removing terrain to create buildable underground space |

---

## 12. Migration Impact

### 12.1 Files to Delete/Replace

| Current File | Action | Replacement |
|--------------|--------|-------------|
| src/game/block_renderer.gd | DELETE | src/rendering/block_renderer_3d.gd |
| src/game/camera_controller.gd | DELETE | src/game/camera_3d_controller.gd |
| src/game/input_handler.gd | MODIFY | Update for 3D raycasting |
| src/game/terrain.gd | DELETE | src/rendering/terrain_3d.gd |
| assets/sprites/blocks/* | ARCHIVE | assets/models/blocks/* |
| scenes/main.tscn | REPLACE | Node3D-based scene |

### 12.2 Files to Keep (Unchanged)

| File | Reason |
|------|--------|
| src/game/grid.gd | Pure data, no rendering |
| src/game/game_state.gd | Pure logic |
| src/game/block_registry.gd | Block definitions (add mesh refs) |
| src/ui/* | CanvasLayer stays 2D |
| src/economy/* | Pure logic |
| src/agents/* | Pure logic |
| data/*.json | Data files unchanged |

### 12.3 Coordinate Migration

**OLD (2D):** Vector3i(x, y, z) where z = floor level
**NEW (3D):** Vector3i(x, y, z) where y = vertical (floor), z = depth

Migration script needed for save files.

---

*End of 3D Refactor Specification*
