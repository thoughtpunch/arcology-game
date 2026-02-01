# Visibility Modes

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Because blocks in the 3D arcology enclose interior space, players need dedicated visibility modes to see inside the structure. Four modes let players slice, peel, isolate, or x-ray the building to inspect its internals.

> **Reference:** [3D Refactor Specification §5](../architecture/3d-refactor/specification.md)

---

## Mode Summary

| Mode | Key | Description | Best For |
|------|-----|-------------|----------|
| **Normal** | N | Full 3D rendering, no clipping | Exterior views, overview |
| **Cutaway** | C | Horizontal cut plane removes geometry above | Inspecting a specific floor level |
| **X-Ray** | X | Exterior walls become transparent | Seeing activity + structure simultaneously |
| **Floor Isolate** | I | Shows only a single floor, hides all others | Detailed floor plan editing |
| **Section** | V | Vertical slice showing cross-section | Vertical infrastructure planning |

---

## Normal Mode (Default)

Standard 3D rendering with no visibility tricks:

- Full exterior and interior geometry rendered
- Standard LOD and chunk culling
- All overlays can be active
- Toggle back to normal with **N** from any visibility mode

---

## Cutaway Mode

Removes all geometry above a horizontal cut plane, revealing the interior below:

```
  BEFORE (normal)          AFTER (cutaway at floor 5)
  ┌─────────────┐
  │ Floor 8     │
  │ Floor 7     │
  │ Floor 6     │         ╔═══════════════╗  ← Cut plane (glowing edge)
  │ Floor 5     │    →    ║ Floor 5       ║  ← Interior visible
  │ Floor 4     │         ║ Floor 4       ║
  │ Floor 3     │         ║ Floor 3       ║
  └─────────────┘         ╚═══════════════╝
```

### Controls

| Action | Input |
|--------|-------|
| Toggle cutaway | C |
| Raise cut plane | ] |
| Lower cut plane | [ |
| Drag cut plane | Click and drag the cut-plane edge |
| Set to specific floor | Ctrl+[ or Ctrl+] to snap to floor boundaries |

### Visual Details

- Clean horizontal slice through geometry
- Cut edges show a subtle glow/outline to indicate the cut boundary
- Interior floors, walls, and furniture visible below the cut
- Optional: ghost silhouette of removed floors (toggled in settings)

---

## X-Ray Mode

Makes exterior walls transparent while keeping interiors solid, letting the player see activity inside the building without losing structural context:

```
  BEFORE (normal)          AFTER (x-ray)
  ┌─────────────┐         ┌ · · · · · · · ┐
  │ ████████████│         │ ○ furniture    │  ← Interiors visible
  │ ████████████│    →    │ ● agents       │  ← Agents visible
  │ ████████████│         │ ○ fixtures     │
  └─────────────┘         └ · · · · · · · ┘
                           ↑ Walls translucent
```

### Controls

| Action | Input |
|--------|-------|
| Toggle x-ray | X |
| Increase transparency | Shift+X or scroll while in x-ray |
| Decrease transparency | Ctrl+X or scroll while in x-ray |

### Visual Details

- Transparency slider: 0% (opaque) to 100% (invisible exterior)
- Default transparency: 70%
- Interior meshes (furniture, fixtures) render at full opacity
- Agent models always render at full opacity
- Structure silhouette remains visible for spatial awareness

---

## Floor Isolate Mode

Shows only a single floor, hiding all other floors entirely:

```
  BEFORE (normal)          AFTER (isolate floor 5)

  ┌─────────────┐
  │ Floor 8     │
  │ Floor 7     │               (hidden)
  │ Floor 6     │
  │ Floor 5     │    →    ┌─────────────┐  ← Selected floor, full detail
  │ Floor 4     │         └─────────────┘
  │ Floor 3     │               (hidden)
  └─────────────┘
```

### Controls

| Action | Input |
|--------|-------|
| Toggle floor isolate | I |
| Floor up | Page Up |
| Floor down | Page Down |
| Select specific floor | Click floor selector widget |

### Visual Details

- Selected floor rendered at full detail (top-down or perspective)
- Adjacent floors shown as faint ghosts (optional, toggle in settings)
- Floor selector widget appears on-screen showing floor number
- Grid overlay automatically enabled in this mode

---

## Section Mode

Creates a vertical slice through the arcology, showing a cross-section like an architectural section drawing:

```
  BEFORE (normal)          AFTER (section)

  ┌─────────────┐         │ F8 │░░░░░░░│
  │             │         │ F7 │░░░░░░░│
  │             │    →    │ F6 │░░░░░░░│  ← Cut face visible
  │             │         │ F5 │░░░░░░░│
  │             │         │ F4 │░░░░░░░│
  └─────────────┘         │ F3 │░░░░░░░│
                           ↑ Interior  ↑ Cut surface (shaded)
```

### Controls

| Action | Input |
|--------|-------|
| Toggle section mode | V |
| Move section plane | Arrow keys or drag |
| Rotate section axis | Shift+V (cycles N-S, E-W, NE-SW, NW-SE) |
| Define section line | Click two points in top-down view |

### Visual Details

- Vertical slice through the entire structure
- Cut surface rendered with cross-hatch or shaded fill
- Like an architectural section drawing
- Interior rooms, floors, and vertical infrastructure (elevators, stairs, pipes) visible
- Useful for planning vertical circulation and infrastructure

---

## Mode Combinations

Some visibility modes can be combined:

| Combination | Effect |
|-------------|--------|
| Cutaway + X-Ray | Cut plane removes upper floors; remaining exterior is translucent |
| Cutaway + Overlays | Overlay data shown on visible (below cut) blocks only |
| X-Ray + Overlays | Heat maps visible through translucent exterior |
| Floor Isolate + Overlays | Full overlay detail on isolated floor |

Section mode is exclusive — it overrides other visibility modes while active.

---

## Implementation

### Files

| File | Purpose |
|------|---------|
| `src/rendering/visibility_manager.gd` | Controls active visibility mode, coordinates shaders |
| `src/rendering/cut_plane.gd` | Cutaway plane position and rendering |
| `src/rendering/xray_shader.tres` | X-ray transparency shader |
| `src/ui/floor_selector.gd` | Floor isolate widget |

### Signals

```gdscript
# VisibilityManager
signal visibility_mode_changed(mode: String)  # "normal", "cutaway", "xray", "isolate", "section"
signal cut_plane_moved(height: float)
signal xray_transparency_changed(value: float)
signal isolated_floor_changed(floor: int)
signal section_plane_moved(position: Vector3, normal: Vector3)
```

---

## See Also

- [camera-controls.md](./camera-controls.md) — Camera system (works with all visibility modes)
- [overlays.md](./overlays.md) — Data overlays (combinable with visibility modes)
- [controls.md](./controls.md) — Full input mapping table
- [../architecture/3d-refactor/specification.md](../architecture/3d-refactor/specification.md) — 3D spec §5 Visibility Modes
