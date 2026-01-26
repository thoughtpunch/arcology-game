# Camera Controls

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Camera controls use a Cities Skylines-inspired interface with smooth movement, rotation, and a collapsible controls pane.

---

## Controls Pane

A collapsible panel in the bottom-right corner showing:

```
┌─────────────────────┐
│ CAMERA          [—] │
├─────────────────────┤
│      N              │
│    W ● E            │  <- Compass with rotation needle
│      S              │
├─────────────────────┤
│  [Q] Rotate [E]     │
├─────────────────────┤
│  [-]  100%  [+]     │  <- Zoom controls
├─────────────────────┤
│   [ISO]  [TOP]      │  <- View mode toggle
├─────────────────────┤
│ H: toggle | Scroll  │
└─────────────────────┘
```

Press **H** to collapse/expand the pane.

---

## Keyboard Shortcuts

### Camera Movement

| Key | Action |
|-----|--------|
| W / Up | Pan up |
| S / Down | Pan down |
| A / Left | Pan left |
| D / Right | Pan right |

### Camera Rotation

| Key | Action |
|-----|--------|
| Q | Rotate 90° counter-clockwise |
| E | Rotate 90° clockwise |
| Shift + Scroll | Rotate camera |

Four fixed angles: 0°, 90°, 180°, 270°

### Camera Zoom

| Key | Action |
|-----|--------|
| Scroll Up | Zoom in |
| Scroll Down | Zoom out |
| + / = | Zoom in |
| - | Zoom out |
| Home | Reset zoom to 100% |

Zoom range: 25% to 400%

### View Mode

| Key | Action |
|-----|--------|
| I | Isometric view |
| T | Top-down view |

### Pane Control

| Key | Action |
|-----|--------|
| H | Toggle camera controls pane |

---

## Mouse Controls

| Action | Effect |
|--------|--------|
| Scroll wheel | Zoom toward cursor |
| Middle-click drag | Pan camera |
| Right-click drag | Pan camera |
| Double left-click | Center on clicked position |
| Double middle-click | Reset zoom |

---

## Implementation

### Files

| File | Purpose |
|------|---------|
| `src/ui/camera_controls_pane.gd` | Collapsible controls UI |
| `src/core/camera_controller.gd` | Camera movement logic |

### Signals

```gdscript
# CameraController
signal camera_moved(position: Vector2)
signal camera_zoomed(zoom_level: float)
signal camera_rotated(angle: float)

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
- Mouse sensitivity
- All keybinds are rebindable

---

## See Also

- [hud-layout.md](./hud-layout.md) - Overall UI layout
- [../quick-reference/controls.md](../quick-reference/controls.md) - All keyboard shortcuts
