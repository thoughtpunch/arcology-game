# Camera Controls

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

The 3D camera system provides full orbital control around the player's arcology. Two camera modes serve different purposes: **Free Camera** for exploration and **Ortho Snap** for precision building.

> **Reference:** [3D Refactor Specification §4](../architecture/3d-refactor/specification.md)

---

## Camera Modes

### Free Camera (Default)

The primary exploration mode with full perspective projection:

- Full 360° orbital rotation around a focus point
- Perspective projection with depth
- Smooth interpolated movement (lerp-based)
- Use for: Exploration, admiring builds, following agents

### Ortho Snap (Planning)

Precision mode for building and layout:

- Snaps to 90° increments (top, N/S/E/W, bottom, isometric)
- Orthographic projection (no perspective distortion)
- Grid overlay visible automatically
- Use for: Precise block placement, floor plans, section views

Toggle between modes with **Tab** (keyboard) or **Back** (controller).

---

## Controls Pane

A collapsible panel in the bottom-right corner:

```
┌───────────────────────────┐
│ CAMERA                [—] │
├───────────────────────────┤
│      N                    │
│    W ● E    ← Compass     │
│      S                    │
├───────────────────────────┤
│  [Free]  [Ortho]  Tab     │
├───────────────────────────┤
│  [-]  Zoom Level  [+]     │
├───────────────────────────┤
│  ┌─────┐                  │
│  │View │  ← View Cube     │
│  │Cube │    (click faces)  │
│  └─────┘                  │
├───────────────────────────┤
│ H: toggle pane            │
└───────────────────────────┘
```

Press **H** to collapse/expand the pane.

---

## Camera Controls Table

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Orbit (rotate) | Middle-drag | Q / E | Right Stick |
| Pan | Shift+Middle / Edge scroll | WASD | Left Stick |
| Zoom | Scroll wheel | Z / X | Triggers |
| Tilt (pitch) | Middle-drag vertical | R / F | Right Stick Y |
| Reset view | Double-click middle | Home | R3 |
| Focus selection | — | F | Y |
| Toggle Free/Ortho | — | Tab | Back |

### Speed Modifiers

| Modifier | Effect |
|----------|--------|
| Shift + WASD | Fast pan |
| Ctrl + WASD | Slow pan |

> **Note:** Alt+LMB is consumed by orbital camera. Ctrl/Shift are safe as mouse-click modifiers for selection operations.

---

## Orthographic Views

Press number keys or click the View Cube widget to snap to predefined views:

| Key | View | Camera Position | Use Case |
|-----|------|-----------------|----------|
| 1 | Top-Down | Above, looking down | Floor plans |
| 2 | North | South of target, looking north | Front elevation |
| 3 | East | West of target, looking east | Side elevation |
| 4 | South | North of target, looking south | Back elevation |
| 5 | West | East of target, looking west | Side elevation |
| 6 | Bottom | Below, looking up | Ceiling / underground |
| 7 | Isometric | 45° angle, orthographic | Overview |
| 0 | Free | Return to perspective mode | Exploration |

---

## View Cube Widget

A corner widget (top-right of viewport) for quick view switching:

```
    ┌─────┐
   /  TOP /│
  ┌─────┐ │
  │     │E│  ← Click any face to snap to that ortho view
  │  N  │/   ← Click edge for 45° between two faces
  └─────┘    ← Click corner for isometric
             ← Drag cube to free-rotate (stays ortho)
             ← Double-click to return to free camera
```

| Interaction | Result |
|-------------|--------|
| Click face | Snap to that orthographic view |
| Click edge | Snap to 45° between the two adjacent faces |
| Click corner | Snap to isometric view |
| Drag cube | Free rotate (remains in ortho mode) |
| Double-click | Return to free camera (perspective) |

---

## Camera Constraints

```gdscript
# Distance limits
const MIN_DISTANCE: float = 10.0      # ~2 cells, interior detail
const MAX_DISTANCE: float = 2000.0    # Entire arcology visible

# Elevation angle limits (free mode)
const MIN_ELEVATION: float = 5.0      # Nearly horizontal
const MAX_ELEVATION: float = 89.0     # Nearly top-down

# Ortho size limits
const MIN_ORTHO_SIZE: float = 20.0    # ~3 cells visible
const MAX_ORTHO_SIZE: float = 500.0   # Large overview

# Collision: camera soft-collides with geometry
# (pushes back, never clips inside blocks)
```

---

## Camera Bookmarks

Save and recall camera positions for quick navigation:

| Action | Key |
|--------|-----|
| Save bookmark | Ctrl+1 through Ctrl+9 |
| Recall bookmark | 1-9 (when not in build mode) |

Bookmarks store full camera state: position, rotation, projection mode, and zoom level. Recalling a bookmark pushes the current view onto a history stack (undo with Backspace).

---

## Implementation

### Files

| File | Purpose |
|------|---------|
| `src/game/camera_3d_controller.gd` | Orbital camera logic (orbit, pan, zoom, tilt) |
| `src/ui/camera_controls_pane.gd` | Collapsible controls UI |
| `src/ui/view_cube.gd` | View Cube widget |

### Signals

```gdscript
# Camera3DController
signal camera_moved(position: Vector3)
signal camera_zoomed(distance: float)
signal camera_rotated(yaw: float, pitch: float)
signal camera_mode_changed(mode: String)  # "free" or "ortho"
signal camera_view_changed(view_name: String)  # "top", "north", etc.

# CameraControlsPane
signal rotation_requested(direction: int)
signal zoom_requested(direction: int)
signal zoom_reset_requested
signal view_mode_changed(mode: String)
signal pane_toggled(visible: bool)
```

### Settings

Camera settings are configurable in Settings > Controls:
- Invert scroll zoom
- Invert orbit vertical
- Mouse sensitivity (orbit, pan, zoom)
- Edge scroll toggle and speed
- All keybinds are rebindable

---

## See Also

- [hud-layout.md](./hud-layout.md) — Overall UI layout
- [views.md](./views.md) — Visibility modes (cutaway, x-ray, etc.)
- [controls.md](./controls.md) — Full input mapping table
- [../architecture/3d-refactor/specification.md](../architecture/3d-refactor/specification.md) — 3D spec §4 Camera System
