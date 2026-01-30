# Phase 0: Block Stacking Sandbox

> **Status:** In Progress
> **Location:** `src/phase0/`, `scenes/phase0_sandbox.tscn`

## Overview

A fully functional 3D block-placing sandbox. The foundation for all future gameplay. Everything is built procedurally in code from a single root Node3D.

## What Works

### Building
- Place/remove blocks on a 3D grid (`CELL_SIZE = 6.0` world units)
- 6 block shapes: cube, beam_2, beam_3, plate_2x2, column, slab_3x3
- Rotation with `,`/`.` (90-degree steps)
- Rapid-fire placement (hold LMB + sweep)
- Structural integrity: blocks need face-adjacent support, removal rejects if it would orphan neighbors
- Ghost preview with valid/invalid shader feedback
- Face highlight on hovered surface (cyan pulsing quad)
- Face direction labels on ghost block (N/S/E/W/Top, rotate with block)

### Ground
- 100x100 grid with 5 diggable strata layers (grass, soil, clay, rock, bedrock)
- Right-click to dig (top layer removed, bedrock indestructible)
- Grid overlay on ground surface at each exposed level
- Build zone: 20x20 cells centered in the grid

### Camera (`orbital_camera.gd`)
- Right-click drag: orbit (azimuth + elevation)
- Middle-click drag: pan
- Scroll wheel: zoom (proportional to distance)
- WASD: pan horizontally (speed scales with zoom)
- Q/Space: up, E/C: down
- Speed modifiers: Shift (0.25x precision), Ctrl (3x boost), Shift+Ctrl (10x sprint)
- H: home, Z: level horizon, F: frame cursor, Backspace: history
- Numpad 1/3/7: front/right/top views, Numpad 5: orthographic toggle
- `[`/`]`: FOV adjustment
- Right-click tap vs drag distinguished by 4px threshold

### UI
- Shape palette (bottom center, click or 1-7 keys)
- Face label (top-left: face direction + rotation)
- Controls hint (bottom-left)
- Compass markers (N/S/E/W Label3D at build zone edges)
- Warning labels (center-top, fade animation)

### Debug Panel (F3)
- Time of Day slider (0-24h) with sun rotation, sky color, energy changes
- Sun Energy / Ambient Energy sliders
- FPS counter
- Stats: blocks placed, cells occupied, building height, volume, footprint
- Camera position
- Mouse grid position + face

### Help Overlay (F1 / ?)
- Full controls reference, organized by category
- ESC to close

### Pause Menu (ESC)
- Resume
- Reset Scenario (confirmation dialog, reloads scene)
- Options (placeholder, disabled)
- Exit to Main Menu (confirmation dialog)
- Quit to Desktop

### Environment
- ProceduralSky with day/dawn/dusk/night color palettes
- DirectionalLight3D sun with time-of-day rotation
- Fog (density 0.001)
- Skyline: 300 buildings in 3 rings (near/mid/far) with aerial perspective

### Debug Logging
- All setup steps log completion with details
- Every mouse click, key press logged
- Placement/removal attempts logged with success/failure reasons
- `push_warning()` for error conditions (missing blocks, out-of-range operations)
- `OS.is_debug_build()` gating on all `_log()` calls

## File Map

| File | Purpose |
|------|---------|
| `src/phase0/sandbox_main.gd` | Main scene script (builds entire scene tree) |
| `src/phase0/orbital_camera.gd` | Camera with orbit/pan/zoom/history |
| `src/phase0/block_registry.gd` | Loads block definitions from JSON |
| `src/phase0/block_definition.gd` | Block type data (size, color, id) |
| `src/phase0/placed_block.gd` | Instance of a placed block |
| `src/phase0/grid_utils.gd` | Grid ↔ world coordinate conversion |
| `src/phase0/face.gd` | Face direction enum + utilities |
| `src/phase0/shape_palette.gd` | Block selection UI |
| `src/phase0/sandbox_pause_menu.gd` | Pause menu with reset/exit |
| `src/phase0/sandbox_debug_panel.gd` | Extensible F3 debug panel |
| `src/phase0/sandbox_help_overlay.gd` | F1 controls reference |
| `shaders/ghost_preview.gdshader` | Ghost block transparency shader |
| `shaders/face_highlight.gdshader` | Face highlight with pulse |
| `shaders/grid_overlay.gdshader` | Ground grid lines |
| `data/blocks.json` | Block type definitions |
| `scenes/phase0_sandbox.tscn` | Scene file (just root Node3D) |

## Grid System

- **Coordinate system:** Godot Y-up (X = east/west, Z = north/south, Y = up/down)
- **Grid origin:** World (0, 0, 0) = grid (0, 0, 0)
- **Cell size:** 6.0 world units per cell in each axis
- **Ground:** y = -1 through y = -5 (5 strata layers)
- **Building:** y = 0 and above
- **Occupancy:** `Dictionary<Vector3i, int>` — cell → block_id (ground = -1)
