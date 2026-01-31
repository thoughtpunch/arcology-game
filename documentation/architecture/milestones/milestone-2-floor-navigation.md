# Milestone 2: Floor Navigation & Visibility Modes

**Goal:** Explore the interior of a multi-story 3D structure using cutaway, x-ray, floor isolate, and section views.

---

## Overview

In a 3D city-builder where blocks enclose space, the player needs ways to see inside the structure. Simply orbiting the camera shows only exterior faces. This milestone implements four visibility modes that reveal interior spaces, each suited to different tasks.

**Key constraint:** These are shader-driven visibility effects using global uniforms, not scene tree manipulation. Blocks are never hidden/shown via `visible = false` — instead, the `block_material.gdshader` discards or fades fragments based on the active visibility mode and its parameters.

---

## Prerequisites

- **Milestone 1** (Grid & Blocks) — blocks exist, camera orbits, raycasting works
- `block_material.gdshader` — already has global uniform infrastructure for visibility modes (see Existing Foundation below)

---

## Existing Foundation

The block material shader (`shaders/block_material.gdshader`) already defines the global uniform interface:

```glsl
global uniform int visibility_mode;  // 0=normal, 1=cutaway, 2=xray, 3=isolate, 4=section
global uniform float cut_height;     // Y coordinate of cut plane
```

Cutaway mode (mode 1) is already implemented in the shader — fragments above `cut_height` are discarded, with a fade margin near the cut edge. The other modes (x-ray, isolate, section) have placeholder branches that need implementation.

---

## Visibility Modes

### Mode 0: Normal (Default)

Full 3D rendering. All blocks visible. Player sees exterior surfaces only (interior is occluded by surrounding geometry).

**Toggle:** Press `0` or `Escape` from any other mode

### Mode 1: Cutaway

Removes all geometry above a horizontal cut plane, revealing the interior at a specific Y level. Like slicing the building with a giant horizontal blade.

**Use case:** Floor plan editing, seeing room layouts, checking block adjacency on a specific level.

**Controls:**
| Action | Input |
|--------|-------|
| Toggle cutaway mode | `C` |
| Raise cut plane | `]` (right bracket) |
| Lower cut plane | `[` (left bracket) |
| Set cut to specific floor | Scroll while in cutaway mode |

**Shader behavior** (already implemented):
```glsl
if (visibility_mode == 1) {
    if (world_position.y > cut_height) {
        discard;
    }
    // Slight darkening near cut edge
    float dist_to_cut = cut_height - world_position.y;
    if (dist_to_cut < CUT_FADE_MARGIN && dist_to_cut > 0.0) {
        float fade = dist_to_cut / CUT_FADE_MARGIN;
        color.rgb *= mix(0.7, 1.0, fade);
    }
}
```

**Cut plane height:** Snaps to floor boundaries (multiples of `CELL_SIZE = 6.0`). The cut height is the **top** of the visible floor: `cut_height = (floor_number + 1) * CELL_SIZE`. This means at floor 0, the cut plane is at Y=6.0, showing everything at ground level.

**Visual treatment:**
- Clean horizontal slice — no jagged edges
- Cut edges get a subtle glow/outline to indicate the slice boundary
- Optional: ghost silhouette of removed floors (very faint wireframe above cut plane)

### Mode 2: X-Ray

Makes exterior walls semi-transparent while keeping interiors visible. The player sees through the building shell to the activity inside.

**Use case:** Monitoring interior activity while maintaining spatial awareness of the overall structure.

**Controls:**
| Action | Input |
|--------|-------|
| Toggle x-ray mode | `X` |
| Adjust transparency | `[` / `]` (decrease/increase opacity) |

**Shader implementation:**

```glsl
// Additional global uniforms needed:
global uniform float xray_opacity;    // 0.0 (fully transparent) to 1.0 (fully opaque)

if (visibility_mode == 2) {
    // Exterior detection: faces that are exposed to void/air
    // For now, use a per-instance uniform flag set by the game logic
    if (is_exterior) {
        final_alpha = xray_opacity;
    }
    // Interior blocks remain fully opaque
}
```

**Exterior detection strategy:**
- When a block is placed/removed, tag each remaining block as "exterior" or "interior" based on whether any of its faces are exposed to empty space (no adjacent block)
- Store as a per-block shader parameter: `block_material.set_shader_parameter("is_exterior", true/false)`
- A block is "exterior" if ANY of its 6 face-adjacent cells are empty
- Recompute on block place/remove (incremental — only check neighbors of the changed block)

**Transparency range:** Default `xray_opacity = 0.15` (nearly invisible shell). Adjustable from 0.0 to 0.5.

### Mode 3: Floor Isolate

Shows only a single floor level, hiding everything above and below. Like pulling a single floor out of a building model.

**Use case:** Focused floor plan editing, counting blocks on a specific level, precise placement without visual clutter.

**Controls:**
| Action | Input |
|--------|-------|
| Toggle isolate mode | `I` |
| Floor up | `Page Up` |
| Floor down | `Page Down` |

**Shader implementation:**

```glsl
// Additional global uniforms needed:
global uniform float isolate_floor_y;     // Y coordinate of isolated floor bottom
global uniform float isolate_floor_top;   // Y coordinate of isolated floor top (floor_y + CELL_SIZE)
global uniform float isolate_ghost_alpha; // Alpha for adjacent floors (0.0 = hidden, ~0.1 = faint ghost)

if (visibility_mode == 3) {
    if (world_position.y >= isolate_floor_y && world_position.y <= isolate_floor_top) {
        // Current floor — full visibility
    } else if (abs(world_position.y - isolate_floor_y) < CELL_SIZE * 2.0) {
        // Adjacent floors — faint ghost (optional)
        final_alpha = isolate_ghost_alpha;
    } else {
        // All other floors — hidden
        discard;
    }
}
```

**Floor boundaries:** `isolate_floor_y = floor_number * CELL_SIZE`. A "floor" in this context is one cell height (6m). The isolated range is `[floor_y, floor_y + CELL_SIZE]`.

**Adjacent floor ghosts:** Optionally show 1 floor above and below as faint translucent silhouettes (default `isolate_ghost_alpha = 0.08`). This gives spatial context without visual clutter. Can be toggled off entirely.

### Mode 4: Section (Vertical Slice)

A vertical cut plane showing a cross-section through the structure. Like an architectural section drawing.

**Use case:** Understanding vertical circulation (stairs, elevators), seeing how floors stack, checking structural continuity.

**Controls:**
| Action | Input |
|--------|-------|
| Toggle section mode | `V` |
| Rotate section plane | `[` / `]` (rotate around Y axis in 15-degree increments) |
| Move section plane | Scroll (translate along plane normal) |

**Shader implementation:**

```glsl
// Additional global uniforms needed:
global uniform vec3 section_plane_normal;  // Normal of the section plane (horizontal, e.g., (1,0,0))
global uniform float section_plane_offset; // Distance from origin along normal

if (visibility_mode == 4) {
    float dist = dot(world_position, section_plane_normal) - section_plane_offset;
    if (dist > 0.0) {
        discard;
    }
    // Fade near section edge
    if (dist > -CUT_FADE_MARGIN) {
        float fade = -dist / CUT_FADE_MARGIN;
        color.rgb *= mix(0.7, 1.0, fade);
    }
}
```

**Section plane:** Defined by a normal vector (always horizontal — Y component is 0) and an offset distance from the origin. The plane starts aligned with the camera's view direction. Rotating it with `[`/`]` spins it around the Y axis.

**Default orientation:** Section plane normal matches the camera's horizontal forward direction when activated. This gives a natural "slice from where you're looking" behavior.

---

## VisibilityController

A new script that manages the active visibility mode and its parameters, setting the global shader uniforms:

```gdscript
## Manages block visibility modes and their shader parameters.
class_name VisibilityController
extends Node

enum Mode { NORMAL, CUTAWAY, XRAY, ISOLATE, SECTION }

const CELL_SIZE: float = 6.0

var current_mode: Mode = Mode.NORMAL
var cut_floor: int = 5           # Current cutaway floor level
var xray_opacity: float = 0.15  # X-ray exterior transparency
var isolate_floor: int = 0      # Floor isolate target floor
var isolate_ghost_alpha: float = 0.08
var section_angle: float = 0.0  # Section plane angle (degrees around Y)
var section_offset: float = 0.0 # Section plane distance from origin

signal mode_changed(mode: Mode)
signal parameters_changed()

func set_mode(mode: Mode) -> void:
    current_mode = mode
    RenderingServer.global_shader_parameter_set("visibility_mode", int(mode))
    _apply_parameters()
    mode_changed.emit(mode)

func cycle_mode() -> void:
    set_mode(Mode.values()[(current_mode + 1) % Mode.size()])

func toggle_mode(mode: Mode) -> void:
    if current_mode == mode:
        set_mode(Mode.NORMAL)
    else:
        set_mode(mode)

func adjust_cut_floor(delta: int) -> void:
    cut_floor = maxi(cut_floor + delta, 0)
    _apply_parameters()

func adjust_xray_opacity(delta: float) -> void:
    xray_opacity = clampf(xray_opacity + delta, 0.0, 0.5)
    _apply_parameters()

func adjust_isolate_floor(delta: int) -> void:
    isolate_floor = maxi(isolate_floor + delta, 0)
    _apply_parameters()

func adjust_section_angle(delta_degrees: float) -> void:
    section_angle = fmod(section_angle + delta_degrees, 360.0)
    _apply_parameters()

func adjust_section_offset(delta: float) -> void:
    section_offset += delta
    _apply_parameters()

func _apply_parameters() -> void:
    match current_mode:
        Mode.CUTAWAY:
            var cut_y := float(cut_floor + 1) * CELL_SIZE
            RenderingServer.global_shader_parameter_set("cut_height", cut_y)
        Mode.XRAY:
            RenderingServer.global_shader_parameter_set("xray_opacity", xray_opacity)
        Mode.ISOLATE:
            var floor_y := float(isolate_floor) * CELL_SIZE
            RenderingServer.global_shader_parameter_set("isolate_floor_y", floor_y)
            RenderingServer.global_shader_parameter_set("isolate_floor_top", floor_y + CELL_SIZE)
            RenderingServer.global_shader_parameter_set("isolate_ghost_alpha", isolate_ghost_alpha)
        Mode.SECTION:
            var angle_rad := deg_to_rad(section_angle)
            var normal := Vector3(cos(angle_rad), 0.0, sin(angle_rad))
            RenderingServer.global_shader_parameter_set("section_plane_normal", normal)
            RenderingServer.global_shader_parameter_set("section_plane_offset", section_offset)
    parameters_changed.emit()
```

**Global shader parameters** are set via `RenderingServer.global_shader_parameter_set()`. These must also be registered in `project.godot`:

```ini
[shader_globals]
visibility_mode={type="int", value=0}
cut_height={type="float", value=30.0}
xray_opacity={type="float", value=0.15}
isolate_floor_y={type="float", value=0.0}
isolate_floor_top={type="float", value=6.0}
isolate_ghost_alpha={type="float", value=0.08}
section_plane_normal={type="vec3", value=Vector3(1, 0, 0)}
section_plane_offset={type="float", value=0.0}
```

---

## Input Mapping

| Key | Action | Context |
|-----|--------|---------|
| `C` | Toggle cutaway mode | Global |
| `X` | Toggle x-ray mode | Global |
| `I` | Toggle floor isolate mode | Global |
| `V` | Toggle section mode | Global |
| `0` or `Escape` | Return to normal mode | While in any visibility mode |
| `[` | Mode-specific: lower cut / decrease opacity / rotate section left | While in a visibility mode |
| `]` | Mode-specific: raise cut / increase opacity / rotate section right | While in a visibility mode |
| `Page Up` | Floor up (isolate mode) | While in isolate mode |
| `Page Down` | Floor down (isolate mode) | While in isolate mode |
| `Scroll` | Adjust parameter (cut height / section offset) | While in cutaway or section mode |

**Note:** `[` and `]` are overloaded — they control FOV in normal camera mode (see orbital_camera.gd) and visibility parameters in visibility modes. The `VisibilityController` should consume the input when a non-normal mode is active.

---

## UI Elements

### Visibility Mode Indicator

A small HUD element showing the active mode and its current parameter:

```
CUTAWAY  Floor 3  [up/down to adjust]
```

```
X-RAY  Opacity: 15%  [left/right adjust]
```

```
ISOLATE  Floor 2  [PgUp/PgDn]
```

```
SECTION  Angle: 45 deg  [left/right rotate]
```

Position: Top-center of screen, below any warning labels. Semi-transparent background, mode-specific accent color.

### Floor Selector Widget (Isolate Mode)

When in isolate mode, a vertical slider appears on the left edge showing all floor levels with the current floor highlighted:

```
  5
  4
  3  <-- current (highlighted)
  2  (ghost)
  1
  0
 -1  (underground)
```

Click a floor number to jump to it. Drag to scrub through floors.

---

## Block Material Integration

All placed blocks must use `block_material.gdshader` (or a derivative) instead of bare `StandardMaterial3D` to participate in visibility modes. This means changing block creation in `sandbox_main.gd`:

**Current** (Milestone 1):
```gdscript
var mat := StandardMaterial3D.new()
mat.albedo_color = definition.color
mesh_instance.material_override = mat
```

**Updated** (Milestone 2):
```gdscript
var shader := preload("res://shaders/block_material.gdshader")
var mat := ShaderMaterial.new()
mat.shader = shader
mat.set_shader_parameter("albedo_color", definition.color)
mesh_instance.material_override = mat
```

This is the **only required change** to existing Milestone 1 code. Everything else in this milestone is additive.

---

## Camera Interaction

Visibility modes work with all camera modes (free orbital, orthographic snap). Some combinations are particularly useful:

| Camera Mode | Visibility Mode | Use Case |
|-------------|----------------|----------|
| Top-down ortho (Numpad 7) | Cutaway | Floor plan view at specific level |
| Side ortho (Numpad 1/3) | Section | Architectural cross-section |
| Free perspective | X-ray | General interior monitoring |
| Top-down ortho | Isolate | Single-floor editing with no vertical distraction |

The camera does not need to move or change when visibility modes activate — they operate purely through shader effects.

---

## Deliverable

The player can build a 5+ story structure and explore its interior using four distinct visibility modes. Cutaway slices horizontally, x-ray makes the shell transparent, isolate shows a single floor, and section cuts vertically. Each mode has intuitive controls for adjusting its parameters.

---

## Acceptance Criteria

- [ ] Four visibility modes work: cutaway, x-ray, isolate, section
- [ ] `C` toggles cutaway mode; `[`/`]` adjust cut height by one floor
- [ ] Cutaway cleanly removes geometry above the cut plane
- [ ] `X` toggles x-ray mode; exterior blocks become semi-transparent
- [ ] Exterior/interior block classification updates when blocks are placed or removed
- [ ] `I` toggles floor isolate mode; `Page Up`/`Page Down` change floor
- [ ] Isolate mode shows only the target floor (adjacent floors as faint ghosts, optional)
- [ ] `V` toggles section mode; `[`/`]` rotate the section plane
- [ ] Section mode produces a clean vertical slice through the structure
- [ ] All visibility modes use global shader uniforms (no scene tree manipulation)
- [ ] Returning to normal mode (`0` or `Escape`) restores full visibility
- [ ] HUD indicator shows active mode and current parameter
- [ ] Modes work with both perspective and orthographic camera
- [ ] Placed blocks use `block_material.gdshader` instead of bare `StandardMaterial3D`
- [ ] Can navigate a 5+ story structure and see interior spaces clearly

---

## Test Plan

### Unit Tests (VisibilityController)

```gdscript
# Mode toggling
var vc := VisibilityController.new()
assert(vc.current_mode == VisibilityController.Mode.NORMAL)
vc.toggle_mode(VisibilityController.Mode.CUTAWAY)
assert(vc.current_mode == VisibilityController.Mode.CUTAWAY)
vc.toggle_mode(VisibilityController.Mode.CUTAWAY)
assert(vc.current_mode == VisibilityController.Mode.NORMAL)

# Cut floor adjustment
vc.set_mode(VisibilityController.Mode.CUTAWAY)
vc.cut_floor = 3
vc.adjust_cut_floor(1)
assert(vc.cut_floor == 4)
vc.adjust_cut_floor(-10)
assert(vc.cut_floor == 0)  # Clamped to 0

# X-ray opacity
vc.xray_opacity = 0.15
vc.adjust_xray_opacity(0.1)
assert(abs(vc.xray_opacity - 0.25) < 0.001)
vc.adjust_xray_opacity(0.5)
assert(abs(vc.xray_opacity - 0.5) < 0.001)  # Clamped to 0.5
```

### Integration Tests (shader behavior)

```gdscript
# Build a 3-story tower
place_entrance(Vector3i(5, 0, 5))
place_block("corridor", Vector3i(5, 1, 5))
place_block("corridor", Vector3i(5, 2, 5))

# Cutaway at floor 1 should hide floors 2+
visibility_controller.set_mode(Mode.CUTAWAY)
visibility_controller.cut_floor = 1
# Verify: cut_height global uniform == 12.0 (floor 1 top = 2 * 6.0)
var cut_h = RenderingServer.global_shader_parameter_get("cut_height")
assert(abs(cut_h - 12.0) < 0.1)

# Isolate floor 0 should show only ground-level blocks
visibility_controller.set_mode(Mode.ISOLATE)
visibility_controller.isolate_floor = 0
var floor_y = RenderingServer.global_shader_parameter_get("isolate_floor_y")
assert(abs(floor_y - 0.0) < 0.1)
var floor_top = RenderingServer.global_shader_parameter_get("isolate_floor_top")
assert(abs(floor_top - 6.0) < 0.1)
```

### Visual Tests (manual)

- Build a 5-story enclosed structure (corridors on all sides, floors above)
- Activate cutaway: verify interior is visible, cut edge is clean
- Scroll through floor levels: verify each floor's layout is readable
- Activate x-ray: verify exterior becomes transparent, interior stays solid
- Activate isolate: verify only one floor shows, others disappear
- Activate section: verify vertical slice reveals floor stacking
- Switch between modes rapidly: no visual artifacts or state leaks

---

## Implementation Order

1. **Register global shader parameters** in `project.godot` (`[shader_globals]` section)
2. **VisibilityController** — mode state machine, parameter management, `RenderingServer` calls
3. **Input handling** — connect `C`, `X`, `I`, `V`, `[`, `]`, `Page Up/Down` to controller
4. **Migrate block materials** — change block creation to use `block_material.gdshader`
5. **Cutaway polish** — already works in shader, add floor-snapping and smooth transitions
6. **X-ray implementation** — exterior detection logic, shader branch
7. **Floor isolate implementation** — shader branch, floor selector widget
8. **Section implementation** — shader branch, plane rotation/translation
9. **HUD indicator** — mode label, parameter display
10. **Test coverage** — unit tests for controller, integration tests for shader uniforms

---

*This document is the implementation spec for Milestone 2. For the rendering architecture context, see [3d-refactor/specification.md](../3d-refactor/specification.md) Section 5 (Visibility Modes). For the block material shader, see `shaders/block_material.gdshader`.*
