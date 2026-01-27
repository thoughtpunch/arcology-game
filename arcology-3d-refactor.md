# Arcology: 3D Refactor Addendum

**Version:** 1.0  
**Parent Document:** arcology-prd.md  
**Purpose:** Defines all changes required to convert Arcology from 2D isometric rendering to full 3D with free camera rotation on a cubic grid.

---

## Overview

This document supersedes the following sections of the main PRD:
- Section 1.1: Design Philosophy (art style only)
- Section 17: User Interface (view modes, camera, construction interface)
- Section 19.1-19.6: Technical Architecture (rendering portions)

All other sections (blocks, environment, agents, economy, transit, etc.) remain unchanged—they are rendering-agnostic.

---

## 1. The Cube: Foundational Unit

### 1.1 Definition

The **Cube** is the atomic unit of 3D space in Arcology. All blocks occupy one or more cubes on an orthogonal grid.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   THE CUBE                                                      │
│   ════════                                                      │
│                                                                 │
│   Dimensions: 6m × 6m × 3.5m (Width × Depth × Height)           │
│   Imperial:   ~20ft × 20ft × 11.5ft                             │
│                                                                 │
│   Floor Area: 36 m² (388 sq ft)                                 │
│   Volume:     126 m³                                            │
│                                                                 │
│   Usable Ceiling Height: ~2.7m (9 ft)                           │
│   Structure + MEP:       ~0.8m                                  │
│                                                                 │
│               ┌───────────────┐                                 │
│              ╱               ╱│                                 │
│             ╱       6m      ╱ │                                 │
│            ┌───────────────┐  │                                 │
│            │               │  │ 3.5m                            │
│            │   1 CUBE      │  │                                 │
│            │               │ ╱                                  │
│            │               │╱ 6m                                │
│            └───────────────┘                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Why These Dimensions

| Dimension | Value | Rationale |
|-----------|-------|-----------|
| Width | 6m | Comfortable room width; fits studio layout |
| Depth | 6m | Square footprint for rotational symmetry |
| Height | 3.5m | Standard efficient skyscraper floor-to-floor |

**Floor-to-floor breakdown:**
```
┌─────────────────────────────────┐
│░░░░░░ Slab: 200mm ░░░░░░░░░░░░░│  ← Concrete + steel deck
├─────────────────────────────────┤
│     Raised floor: 100mm         │  ← Cable routing (optional)
├─────────────────────────────────┤
│                                 │
│     Usable: 2.7m                │  ← Occupant space
│                                 │
├─────────────────────────────────┤
│     Ceiling: 100mm              │  ← Tiles/drywall
├─────────────────────────────────┤
│     Plenum: 400mm               │  ← HVAC, pipes, cables
└─────────────────────────────────┘
         TOTAL: 3.5m
```

### 1.3 Scale Reference

**Vertical Scale:**

| Floors | Height | Real-World Equivalent |
|--------|--------|----------------------|
| 1 | 3.5m | Single story |
| 5 | 17.5m | Walk-up apartment |
| 10 | 35m | Mid-rise |
| 20 | 70m | High-rise |
| 30 | 105m | Skyscraper threshold |
| 50 | 175m | Skyscraper |
| 80 | 280m | Supertall |
| 100 | 350m | Megatall (Empire State scale) |

**Horizontal Scale:**

| Cubes | Span | Real-World Equivalent |
|-------|------|----------------------|
| 1 | 6m | One room |
| 5 | 30m | Large apartment |
| 10 | 60m | Building wing |
| 20 | 120m | City block edge |
| 50 | 300m | Mega-complex |
| 100 | 600m | True arcology |

**Footprint Examples:**

| Grid | Dimensions | Area | Feel |
|------|------------|------|------|
| 5×5 | 30m × 30m | 900 m² | Small building |
| 10×10 | 60m × 60m | 3,600 m² | Large building |
| 20×20 | 120m × 120m | 14,400 m² | City block |
| 50×50 | 300m × 300m | 90,000 m² | Mega-complex |
| 100×100 | 600m × 600m | 360,000 m² | Arcology |

### 1.4 What Fits in 1 Cube

**Residential:**
```
STUDIO APARTMENT (36 m² / 388 sq ft)
┌────────────────────────────────┐
│ ┌─────┐          ┌──────────┐ │
│ │ WC  │          │ kitchen  │ │
│ │     │          │          │ │
│ └─────┘          └──────────┘ │
│ ┌─────┐                       │
│ │closet    ┌──────────┐       │
│ └─────┘    │   bed    │       │
│    ════    └──────────┘       │
│   couch              ◇ door   │
└────────────────────────────────┘
Comfortable studio: bed, bath, kitchenette, living nook
```

**Commercial:**
```
SMALL SHOP / CAFE (36 m²)
┌────────────────────────────────┐
│▓▓▓▓▓▓▓▓ storefront ▓▓▓▓▓▓▓▓▓▓│
│   ┌─────┐       ┌─────┐       │
│   │shelf│       │shelf│       │
│   └─────┘       └─────┘       │
│       ┌────────────┐    ┌───┐ │
│       │  counter   │    │stk│ │
│       └────────────┘    └───┘ │
│                    ◇ door     │
└────────────────────────────────┘
Boutique, coffee counter, small service business
```

**Transit:**
```
CORRIDOR SECTION
┌────────────────────────────────┐
│████████████████████████████████│  ← Wall 0.5m
│                                │
│      ← 5m clear width →        │  ← Walkable
│                                │
│████████████████████████████████│  ← Wall 0.5m
└────────────────────────────────┘
Generous corridor: 2-way traffic, benches, planters
```

**Office:**
```
OPEN OFFICE SEGMENT
┌────────────────────────────────┐
│  ┌────┐  ┌────┐  ┌────┐       │
│  │desk│  │desk│  │desk│       │
│  └────┘  └────┘  └────┘       │
│  ┌────┐  ┌────┐  ┌────┐       │
│  │desk│  │desk│  │desk│       │
│  └────┘  └────┘  └────┘       │
│                          ◇    │
└────────────────────────────────┘
6 workstations OR 2 private offices
```

### 1.5 Multi-Cube Prefabs

Blocks can span multiple cubes:

| Size (Cubes) | Dimensions | Examples |
|--------------|------------|----------|
| 1×1×1 | 6×6×3.5m | Studio, shop, corridor segment |
| 2×1×1 | 12×6×3.5m | 1BR apartment, restaurant, wide corridor |
| 2×2×1 | 12×12×3.5m | 2BR apartment, large shop, office suite |
| 3×2×1 | 18×12×3.5m | 3BR apartment, grocery, clinic |
| 1×1×2 | 6×6×7m | Double-height lobby segment |
| 2×2×2 | 12×12×7m | Grand lobby, elevator bank |
| 5×5×1 | 30×30×3.5m | Food hall, market hall |
| 5×5×3 | 30×30×10.5m | Indoor forest, atrium, arena section |

---

## 2. Grid Architecture

### 2.1 Coordinate System

```
Y (up)
│
│    Z (north)
│   ╱
│  ╱
│ ╱
└──────── X (east)

Origin (0,0,0) = Southwest corner of ground plane at grade
Positive Y = Above ground (building up)
Negative Y = Below ground (excavation)
```

### 2.2 Grid Position

Every cube in the world has an integer grid position:

```
GridPosition {
    x: int    // East-West (0 = origin, positive = east)
    y: int    // Vertical (0 = ground, positive = up, negative = down)
    z: int    // North-South (0 = origin, positive = north)
}
```

### 2.3 World ↔ Grid Conversion

```gdscript
const CUBE_WIDTH: float = 6.0    # meters (X axis)
const CUBE_DEPTH: float = 6.0    # meters (Z axis)
const CUBE_HEIGHT: float = 3.5   # meters (Y axis)

func grid_to_world(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * CUBE_WIDTH,
        grid_pos.y * CUBE_HEIGHT,
        grid_pos.z * CUBE_DEPTH
    )

func grid_to_world_center(grid_pos: Vector3i) -> Vector3:
    return Vector3(
        grid_pos.x * CUBE_WIDTH + CUBE_WIDTH / 2,
        grid_pos.y * CUBE_HEIGHT + CUBE_HEIGHT / 2,
        grid_pos.z * CUBE_DEPTH + CUBE_DEPTH / 2
    )

func world_to_grid(world_pos: Vector3) -> Vector3i:
    return Vector3i(
        int(floor(world_pos.x / CUBE_WIDTH)),
        int(floor(world_pos.y / CUBE_HEIGHT)),
        int(floor(world_pos.z / CUBE_DEPTH))
    )
```

### 2.4 Cube Faces

Each cube has 6 faces for connection and panel generation:

```
        TOP (Y+)
           │
           │
    ┌──────┴──────┐
   ╱              ╱│
  ╱      ┌──────╱─┼─── NORTH (Z+)
 ╱       │     ╱  │
┌────────│────┐   │
│        │    │   │
│   WEST │    │ EAST (X+)
│  (X-)  │    │   │
│        └────│───┘
│             │  ╱
│             │ ╱
└─────────────┘╱
       │     ╱
       │    ╱ SOUTH (Z-)
       │
    BOTTOM (Y-)
```

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

```
VISUAL STYLE
════════════

Target aesthetic:
  - Stylized realism (not photorealistic, not cartoon)
  - Clean, readable silhouettes at all zoom levels
  - Warm, optimistic color palette
  - Subtle ambient occlusion for depth
  - Soft edges, slight bevels

Reference games:
  ✓ Cities: Skylines (camera freedom, scale)
  ✓ Townscaper (cozy aesthetic, procedural charm)
  ✓ Two Point Hospital (readable interiors)
  ✓ The Sims 4 (build mode clarity)
  
Avoid:
  ✗ Minecraft (too blocky, no architectural detail)
  ✗ Photorealistic city builders (too serious)
  ✗ Mobile city games (too garish)
```

### 3.3 Block Mesh Structure

Each block type requires:

```
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
CHUNK SIZE: 8×8×8 cubes (48m × 48m × 28m)

Per chunk:
  - Merge static opaque geometry → single draw call
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

The camera supports **free orbital** movement for exploration and **orthographic snap** views for precise building.

```
MODE 1: FREE CAMERA (Default)
═════════════════════════════
- Full 360° orbital rotation
- Perspective projection
- Smooth interpolated movement
- Use for: Exploration, admiring builds, following agents

MODE 2: ORTHO SNAP (Planning)
═════════════════════════════
- Snaps to 90° increments
- Orthographic projection (no perspective distortion)
- Grid overlay visible
- Use for: Precise placement, floor plans, sections
```

### 4.2 Camera Controls

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Orbit (rotate) | Middle-drag | Q/E | Right Stick |
| Pan | Shift+Middle / Edge scroll | WASD | Left Stick |
| Zoom | Scroll wheel | Z/X | Triggers |
| Tilt (pitch) | Middle-drag vertical | R/F | Right Stick Y |
| Reset view | Double-click middle | Home | R3 |
| Focus selection | — | F | Y |
| Toggle Free/Ortho | — | Tab | Back |

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

```
Corner widget for quick view switching:

        ┌─────────┐
       ╱   TOP   ╱│
      ╱         ╱ │
     ┌─────────┐  │
     │         │  │ EAST
     │  FRONT  │  │
     │ (SOUTH) │  │
     │         │ ╱
     └─────────┘╱

Interactions:
  - Click face → Snap to that ortho view
  - Click edge → Snap to 45° between two faces
  - Click corner → Snap to isometric
  - Drag cube → Free rotate (stays in ortho mode)
  - Double-click → Return to free camera
```

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

### 4.6 Camera Implementation

```gdscript
class_name ArcologyCamera extends Node3D

enum Mode { FREE, ORTHO }
enum OrthoView { TOP, NORTH, EAST, SOUTH, WEST, BOTTOM, ISO }

var mode: Mode = Mode.FREE
var ortho_view: OrthoView = OrthoView.TOP

# Free camera state
var target: Vector3 = Vector3.ZERO
var distance: float = 100.0
var azimuth: float = 45.0       # Horizontal rotation (degrees)
var elevation: float = 45.0     # Vertical tilt (degrees)

# Ortho state
var ortho_size: float = 50.0
var floor_focus: int = 0

# Smoothing targets
var _target_target: Vector3
var _target_distance: float
var _target_azimuth: float
var _target_elevation: float
var _target_ortho_size: float

const LERP_SPEED: float = 10.0

@onready var camera: Camera3D = $Camera3D

func _ready():
    _target_target = target
    _target_distance = distance
    _target_azimuth = azimuth
    _target_elevation = elevation
    _target_ortho_size = ortho_size
    _update_camera_transform()

func _process(delta: float):
    # Smooth interpolation
    target = target.lerp(_target_target, delta * LERP_SPEED)
    distance = lerpf(distance, _target_distance, delta * LERP_SPEED)
    azimuth = lerp_angle(deg_to_rad(azimuth), deg_to_rad(_target_azimuth), delta * LERP_SPEED)
    azimuth = rad_to_deg(azimuth)
    elevation = lerpf(elevation, _target_elevation, delta * LERP_SPEED)
    ortho_size = lerpf(ortho_size, _target_ortho_size, delta * LERP_SPEED)
    
    _update_camera_transform()

func _update_camera_transform():
    if mode == Mode.FREE:
        camera.projection = Camera3D.PROJECTION_PERSPECTIVE
        camera.fov = 60.0
        
        var rad_az = deg_to_rad(azimuth)
        var rad_el = deg_to_rad(elevation)
        
        var offset = Vector3(
            sin(rad_az) * cos(rad_el),
            sin(rad_el),
            cos(rad_az) * cos(rad_el)
        ) * distance
        
        camera.global_position = target + offset
        camera.look_at(target, Vector3.UP)
    else:
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = ortho_size
        
        var pos: Vector3
        var rot: Vector3
        
        match ortho_view:
            OrthoView.TOP:
                pos = target + Vector3(0, distance, 0)
                rot = Vector3(-90, 0, 0)
            OrthoView.BOTTOM:
                pos = target + Vector3(0, -distance, 0)
                rot = Vector3(90, 0, 0)
            OrthoView.NORTH:
                pos = target + Vector3(0, 0, -distance)
                rot = Vector3(0, 180, 0)
            OrthoView.SOUTH:
                pos = target + Vector3(0, 0, distance)
                rot = Vector3(0, 0, 0)
            OrthoView.EAST:
                pos = target + Vector3(distance, 0, 0)
                rot = Vector3(0, 90, 0)
            OrthoView.WEST:
                pos = target + Vector3(-distance, 0, 0)
                rot = Vector3(0, -90, 0)
            OrthoView.ISO:
                var iso_dir = Vector3(1, 1, 1).normalized()
                pos = target + iso_dir * distance
                camera.global_position = pos
                camera.look_at(target, Vector3.UP)
                return
        
        camera.global_position = pos
        camera.rotation_degrees = rot

# Public API

func orbit(delta_azimuth: float, delta_elevation: float):
    _target_azimuth = fmod(_target_azimuth + delta_azimuth, 360.0)
    _target_elevation = clampf(_target_elevation + delta_elevation, MIN_ELEVATION, MAX_ELEVATION)

func zoom(factor: float):
    if mode == Mode.FREE:
        _target_distance = clampf(_target_distance * factor, MIN_DISTANCE, MAX_DISTANCE)
    else:
        _target_ortho_size = clampf(_target_ortho_size * factor, MIN_ORTHO_SIZE, MAX_ORTHO_SIZE)

func pan(screen_delta: Vector2):
    var right = camera.global_transform.basis.x
    var forward: Vector3
    
    if mode == Mode.ORTHO and ortho_view == OrthoView.TOP:
        forward = Vector3(0, 0, -1)
    else:
        forward = -camera.global_transform.basis.z
        forward.y = 0
        forward = forward.normalized()
    
    var pan_speed = (ortho_size if mode == Mode.ORTHO else distance) * 0.002
    _target_target += right * screen_delta.x * pan_speed
    _target_target += forward * screen_delta.y * pan_speed

func focus_on(world_pos: Vector3):
    _target_target = world_pos

func snap_to_ortho(view: OrthoView):
    mode = Mode.ORTHO
    ortho_view = view

func return_to_free():
    mode = Mode.FREE

func toggle_mode():
    if mode == Mode.FREE:
        mode = Mode.ORTHO
        _snap_to_nearest_ortho()
    else:
        mode = Mode.FREE

func _snap_to_nearest_ortho():
    # Find closest ortho view to current free camera angle
    var views = [
        [0, 90, OrthoView.TOP],
        [0, -90, OrthoView.BOTTOM],
        [180, 0, OrthoView.NORTH],
        [0, 0, OrthoView.SOUTH],
        [90, 0, OrthoView.EAST],
        [-90, 0, OrthoView.WEST],
    ]
    
    var best = OrthoView.TOP
    var best_diff = INF
    
    for v in views:
        var diff = abs(fmod(azimuth - v[0] + 180, 360) - 180) + abs(elevation - v[1])
        if diff < best_diff:
            best_diff = diff
            best = v[2]
    
    ortho_view = best
```

---

## 5. Visibility Modes

Since blocks enclose space, players need ways to see inside the structure.

### 5.1 Cutaway Mode

Removes all geometry above a horizontal cut plane:

```
CUTAWAY CONTROLS:
  Toggle: C key
  Adjust height: [ and ] keys, or drag cut plane
  
VISUAL:
  - Clean horizontal slice
  - Cut edges show subtle glow/outline
  - Interior floors and walls visible below cut
  - Optional: ghost silhouette of removed floors

          Before                    Cutaway at Floor 2
    ┌───────────────┐              
    │   Floor 3    │                    (hidden)
    ├───────────────┤           ═══════════════════ cut plane
    │   Floor 2    │              ┌ ─ ─ ─ ─ ─ ─ ─┐
    ├───────────────┤              │   Floor 2    │ ← interior visible
    │   Floor 1    │              ├───────────────┤
    └───────────────┘              │   Floor 1    │
                                   └───────────────┘
```

### 5.2 X-Ray Mode

Makes exterior walls transparent while keeping interiors solid:

```
X-RAY CONTROLS:
  Toggle: X key
  Transparency slider: 0-100%

VISUAL:
  - Exterior panels become translucent/wireframe
  - Interior blocks remain fully opaque
  - Good for seeing structure + activity simultaneously
```

### 5.3 Floor Isolate Mode

Shows only a single floor, hiding all others:

```
FLOOR ISOLATE CONTROLS:
  Toggle: I key
  Select floor: Page Up/Down, or click floor selector widget

VISUAL:
  - Selected floor fully visible
  - Adjacent floors shown as faint ghosts (optional)
  - Other floors completely hidden
```

### 5.4 Section Mode

Vertical slice showing cross-section:

```
SECTION CONTROLS:
  Toggle: V key
  Define section line: Click two points in top-down view
  
VISUAL:
  - Everything on one side of section line hidden
  - Clean cut face shows room interiors
  - Like an architectural section drawing
```

### 5.5 Visibility Implementation

```gdscript
class_name VisibilityController extends Node

enum Mode { NORMAL, CUTAWAY, XRAY, ISOLATE, SECTION }

var mode: Mode = Mode.NORMAL
var cut_height: float = 100.0      # World Y for cutaway
var xray_opacity: float = 0.3      # 0-1 for x-ray
var isolated_floor: int = 0        # Floor index for isolate
var section_plane: Plane           # For section mode

signal mode_changed(new_mode: Mode)
signal cut_height_changed(height: float)

func set_mode(new_mode: Mode):
    mode = new_mode
    _update_shader_globals()
    emit_signal("mode_changed", new_mode)

func set_cut_height(height: float):
    cut_height = height
    _update_shader_globals()
    emit_signal("cut_height_changed", height)

func _update_shader_globals():
    # Set global shader parameters
    RenderingServer.global_shader_parameter_set("visibility_mode", mode)
    RenderingServer.global_shader_parameter_set("cut_height", cut_height)
    RenderingServer.global_shader_parameter_set("xray_opacity", xray_opacity)
    RenderingServer.global_shader_parameter_set("isolated_floor", isolated_floor)
    RenderingServer.global_shader_parameter_set("section_plane", section_plane)
```

**Cutaway Shader (simplified):**

```glsl
// In block fragment shader
uniform int visibility_mode;
uniform float cut_height;
uniform float xray_opacity;

void fragment() {
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Cutaway: discard above cut plane
    if (visibility_mode == 1 && world_pos.y > cut_height) {
        discard;
    }
    
    // X-Ray: make exterior transparent
    if (visibility_mode == 2 && is_exterior_face) {
        ALPHA = xray_opacity;
    }
    
    // Normal rendering
    ALBEDO = albedo_color.rgb;
}
```

---

## 6. Block Placement System

### 6.1 Snap Placement (Minecraft-style)

Blocks snap to the grid by clicking on existing block faces:

```
PLACEMENT FLOW:

1. SELECT block type from menu
   └─> Ghost preview appears at cursor

2. HOVER over existing geometry
   └─> Raycast hits block face
   └─> Ghost snaps to adjacent grid cell (face normal direction)
   └─> Position indicator shows grid coordinates

3. ROTATE with R key
   └─> 90° increments around vertical axis
   └─> Some blocks have 2 or 4 meaningful rotations

4. VALIDATE automatically
   └─> Green = valid placement
   └─> Yellow = valid but warning (e.g., "blocks light")
   └─> Red = invalid (blocked, no support, etc.)

5. CLICK to place
   └─> Block instantiates
   └─> Panels auto-generate on exterior faces
   └─> Connections lock to neighbors
```

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

```
BUILDING IN ANY DIRECTION:

Click TOP face    → Build upward (Y+)
Click BOTTOM face → Build downward (Y-) / dig
Click SIDE faces  → Build horizontally

        ┌───┐ ← Click top: new block above
        │   │
  ┌───┐─┤ A ├─┌───┐
  │   │ │   │ │   │
  └───┘─┤   ├─└───┘
   ↑    │   │    ↑
 Click  └───┘  Click side: new block adjacent
 side     ↓
       Click bottom: new block below (dig)
```

### 6.4 Ghost Preview States

```
GHOST VISUAL STATES:

GREEN (Valid):
  ╔═══╗
  ║   ║   Placement allowed
  ╚═══╝   All requirements met

YELLOW (Warning):
  ╔═══╗
  ║ ! ║   Placement allowed, but:
  ╚═══╝   - "Will block light to floors below"
          - "Corridor dead-ends here"
          - "Far from utilities"

RED (Invalid):
  ╔═══╗
  ║ ✗ ║   Placement blocked:
  ╚═══╝   - Space occupied
          - Exceeds cantilever limit
          - No structural support
          - Prerequisites not met
```

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

func _has_structural_support(pos: Vector3i, block_type: BlockType) -> bool:
    # Ground level always supported
    if pos.y == 0:
        return true
    
    # Check for block below
    var below = pos + Vector3i(0, -1, 0)
    if grid.has_block_at(below):
        return true
    
    # Check for adjacent blocks (for cantilever)
    for offset in [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]:
        var adjacent = pos + offset
        if grid.has_block_at(adjacent):
            var adj_block = grid.get_block_at(adjacent)
            if adj_block.supports_cantilever:
                return true
    
    return false
```

### 6.6 Drag-to-Build (Corridors)

Corridors can be placed by dragging a path:

```
CORRIDOR DRAG PLACEMENT:

1. Select corridor type
2. Click start position
3. Drag to end position
4. Preview shows:
   - Path of corridor segments
   - Auto-corners at turns
   - Auto-junctions at intersections
5. Release to build entire path

Routing rules:
  - Horizontal paths only (same Y level)
  - Manhattan routing (no diagonals)
  - Prefers straight lines
  - Auto-detects existing corridors for connections
```

---

## 7. Input Handling (3D)

### 7.1 Raycasting for Selection

```gdscript
class_name InputHandler extends Node

@onready var camera: Camera3D = get_viewport().get_camera_3d()

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

func get_block_at_cursor() -> Block:
    var hit = get_world_position_at_cursor()
    if hit.hit:
        return grid.get_block_at(hit.grid_pos)
    return null

func get_placement_ghost_position() -> Dictionary:
    var hit = get_world_position_at_cursor()
    if not hit.hit:
        return {"valid": false}
    
    var place_pos = hit.grid_pos + _normal_to_grid_offset(hit.normal)
    
    return {
        "valid": true,
        "grid_pos": place_pos,
        "world_pos": grid_to_world_center(place_pos),
        "face_hit": _normal_to_face(hit.normal)
    }

func _normal_to_grid_offset(normal: Vector3) -> Vector3i:
    return Vector3i(
        int(round(normal.x)),
        int(round(normal.y)),
        int(round(normal.z))
    )

func _normal_to_face(normal: Vector3) -> CubeFace:
    if normal.y > 0.5: return CubeFace.TOP
    if normal.y < -0.5: return CubeFace.BOTTOM
    if normal.z > 0.5: return CubeFace.NORTH
    if normal.z < -0.5: return CubeFace.SOUTH
    if normal.x > 0.5: return CubeFace.EAST
    return CubeFace.WEST
```

### 7.2 Input Mapping

```gdscript
# project.godot input map

# Camera
"camera_orbit" → Middle Mouse Button
"camera_pan" → Shift + Middle Mouse Button
"camera_zoom_in" → Mouse Wheel Up
"camera_zoom_out" → Mouse Wheel Down
"camera_rotate_left" → Q
"camera_rotate_right" → E
"camera_tilt_up" → R
"camera_tilt_down" → F
"camera_reset" → Home
"camera_focus" → F (context: has selection)
"camera_toggle_mode" → Tab

# Ortho views
"view_top" → Numpad 7 / 1
"view_front" → Numpad 1 / 2
"view_right" → Numpad 3 / 3
"view_back" → Numpad 9 / 4
"view_left" → Numpad 7 / 5
"view_bottom" → Ctrl + Numpad 7 / 6
"view_iso" → Numpad 5 / 7
"view_free" → Numpad 0 / 0

# Visibility
"visibility_cutaway" → C
"visibility_xray" → X
"visibility_isolate" → I
"visibility_section" → V
"cut_plane_up" → ]
"cut_plane_down" → [
"floor_up" → Page Up
"floor_down" → Page Down

# Building
"place_block" → Left Mouse Button
"cancel_placement" → Right Mouse Button / Escape
"rotate_block" → R (context: placing)
"delete_block" → Delete / Backspace
"pick_block" → Middle Mouse Button (context: hovering block)

# Selection
"select" → Left Mouse Button
"select_add" → Shift + Left Mouse Button
"select_box" → Left Mouse Drag
"deselect_all" → Escape
```

---

## 8. Performance Targets

### 8.1 Scale Targets

| Scale | Grid Size | Blocks | Population | Target FPS |
|-------|-----------|--------|------------|------------|
| Small | 20×20×20 | ~2,000 | ~5,000 | 60 |
| Medium | 40×40×40 | ~10,000 | ~25,000 | 60 |
| Large | 80×80×60 | ~50,000 | ~100,000 | 60 |
| Mega | 120×120×100 | ~200,000 | ~300,000 | 30+ |

### 8.2 Optimization Strategies

```
1. FRUSTUM CULLING
   - Only render chunks in view
   - Use chunk bounding boxes for fast rejection

2. OCCLUSION CULLING  
   - Skip chunks fully behind solid geometry
   - GPU occlusion queries or software rasterizer

3. LOD SYSTEM
   - 4 LOD levels based on distance
   - LOD3 uses impostors/merged chunks

4. CHUNK MERGING
   - Combine static geometry per chunk
   - Rebuild only changed chunks

5. INSTANCING
   - GPU instancing for repeated elements
   - Agents, furniture, windows, panels

6. DEFERRED RENDERING
   - Handle many lights efficiently
   - Reduce overdraw for complex scenes

7. ASYNC STREAMING
   - Load/generate distant chunks in background
   - Never stall main thread for loading

8. SIMULATION LOD
   - Full agent sim only for visible/nearby
   - Statistical sim for distant areas
```

### 8.3 Memory Budget

```
TARGET: 4GB VRAM, 8GB RAM

Per chunk (8×8×8 cubes):
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

```
TERRAIN LAYERS:

Y > 0:  Air (buildable, requires structure below)
Y = 0:  Ground surface (natural starting point)
Y < 0:  Underground (must excavate to access)

Underground is solid until excavated.
Excavation creates empty cubes that can be built in.
```

### 9.2 Excavation

```gdscript
func excavate(grid_pos: Vector3i) -> bool:
    # Can only excavate at or below ground
    if grid_pos.y > 0:
        return false
    
    # Check if already excavated
    if grid.is_excavated(grid_pos):
        return false
    
    # Check excavation permit
    if not permits.can_excavate(grid_pos.y):
        return false
    
    # Perform excavation
    grid.set_excavated(grid_pos, true)
    terrain_mesh.update_chunk(grid_pos)
    
    # Excavated space can now be built in
    return true
```

### 9.3 Terrain Rendering

```
TERRAIN VISUALIZATION:

Above ground: Empty (sky)
Ground level: Surface mesh (grass, concrete, etc.)
Below ground (not excavated): Solid earth
Below ground (excavated): Empty space for building

Underground walls auto-generate on excavated faces
adjacent to non-excavated terrain.
```

---

## 10. User Stories (3D-Specific)

> **US-3D-1:** As a player, I want to freely rotate the camera 360° around my arcology to view it from any angle.

> **US-3D-2:** As a player, I want to snap to orthographic top/side views for precise floor plan editing.

> **US-3D-3:** As a player, I want a cutaway mode that removes floors above my view so I can see inside the building.

> **US-3D-4:** As a player, I want to place blocks by clicking on existing block faces, Minecraft-style.

> **US-3D-5:** As a player, I want a ghost preview showing exactly where my block will snap before I place it.

> **US-3D-6:** As a player, I want clear visual feedback (green/yellow/red) on whether my placement is valid.

> **US-3D-7:** As a player, I want to rotate blocks in 90° increments before placing them.

> **US-3D-8:** As a player, I want to drag-draw corridors as a connected path rather than placing each segment individually.

> **US-3D-9:** As a player, I want X-ray mode to see activity inside my building while maintaining spatial awareness of the structure.

> **US-3D-10:** As a player, I want smooth camera movement with keyboard and mouse that feels responsive and intuitive.

> **US-3D-11:** As a player, I want to excavate underground to create subterranean spaces.

> **US-3D-12:** As a player, I want the game to run at 60fps even with a large arcology.

---

## 11. Glossary (3D Terms)

| Term | Definition |
|------|------------|
| **Cube** | The fundamental 6m×6m×3.5m unit of space |
| **Grid Position** | Integer (x, y, z) coordinates in cube units |
| **Face** | One of 6 sides of a cube (top, bottom, north, south, east, west) |
| **Chunk** | 8×8×8 cube region for rendering optimization |
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

*End of 3D Refactor Addendum*
