# Phase 0: Block Stacking Sandbox

> **Status:** In Progress
> **Location:** `src/game/`, `scenes/main.tscn`

## Overview

A fully functional 3D block-placing sandbox. The foundation for all future gameplay. Everything is built procedurally in code from a single root Node3D.

## What Works

### Building
- Place/remove blocks on a 3D grid (`CELL_SIZE = 6.0` world units)
- **21 block types** across **8 categories** with real dimensions from game design docs
- **Entrance-first building:** Must place an Entrance block before any other block
- **Single-structure connectivity:** All blocks must be face-adjacent to the structure (connected back to an entrance via BFS)
- Rotation with `,`/`.` (90-degree steps)
- Rapid-fire placement (hold LMB + sweep)
- Ghost preview with valid/invalid shader feedback
- Face highlight on hovered surface (cyan pulsing quad)
- Face direction labels on ghost block (N/S/E/W/Top, rotate with block)
- **Top-face name labels:** Each placed block displays its `display_name` on the top face via Label3D

### Block Categories (21 blocks)

| Category | Blocks | Color |
|----------|--------|-------|
| **Transit** (5) | Entrance, Corridor, Medium Corridor, Stairs, Elevator Shaft | Slate blue (Entrance: Gold) |
| **Residential** (4) | Budget Housing, Standard Housing, Premium Housing, Family Housing (2x2) | Soft green |
| **Commercial** (3) | Small Shop, Restaurant, Office Suite | Warm amber |
| **Industrial** (1) | Light Manufacturing (2x2) | Concrete grey |
| **Civic** (3) | Security Station, School (2x2), Clinic (2x2) | Purple-grey |
| **Infrastructure** (2) | Power Plant, HVAC Vent | Steel |
| **Green** (2) | Planter, Courtyard Garden (2x2) | Forest green |
| **Entertainment** (1) | Gym (2x2) | Warm rose |

### Entrance Rules
- Entrance is the anchor point for all building — must be placed first
- Entrance blocks are `ground_only` — must be at y=0 with ground beneath
- All other blocks require face-adjacency to an existing placed block (ground alone is not support)
- Removing the only entrance is rejected if other blocks exist
- Removing any block is rejected if it would disconnect neighbors from an entrance
- Gold prompt "Place your entrance to begin building" shown until first entrance placed
- Future entrance types: Grand Terminal (5x5x2), subway (underground), helipad, space elevator

### Ground
- 100x100 grid with 5 diggable strata layers (grass, soil, clay, rock, bedrock)
- Right-click to dig (top layer removed, bedrock indestructible)
- Grid overlay on ground surface at each exposed level
- Build zone: 20x20 cells centered in the grid
- Digging beneath an entrance is rejected if it would remove the entrance's only ground support

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
- **Category-tabbed palette** (bottom center): 8 category tabs colored by category, block buttons below
  - Tab / Shift+Tab: cycle categories
  - 1-9: select block within current category
  - Click tab to switch category, click block button to select
- Face label (top-left: face direction + rotation + block name)
- Controls hint (bottom-left)
- Compass markers (N/S/E/W Label3D at build zone edges)
- **Building stats HUD** (top-right): Blocks, Height, Volume, Footprint — visible when blocks are placed
- Warning labels (center-top, fade animation) with contextual messages:
  - "Place an entrance first!"
  - "Entrances must be placed at ground level"
  - "Cannot remove the only entrance"
  - "Cannot remove: would disconnect blocks from entrance"

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

### Scenario System
- Scenario picker shown at launch — choose from 3 modes before world builds
- **Blank Slate:** Open terrain with distant mountain ridgeline + river, no city skyline, warmer sky
- **Megastructure:** City skyline with 300 buildings in 3 rings (current default behavior)
- **Custom Game:** Full parameter editor with sliders/checkboxes for all tunable settings
- `ScenarioConfig` (RefCounted) holds all parameters; factory methods for each preset
- Reset Scenario (ESC → Reset) reloads scene and shows picker again

### Environment
- ProceduralSky with day/dawn/dusk/night color palettes
- DirectionalLight3D sun with time-of-day rotation
- Fog (configurable density, default 0.001)
- Skyline: configurable building count in 3 rings (near/mid/far) with aerial perspective
- Mountains: 60 hexagonal cones scattered at 500-1200 units from center (Blank Slate / Custom)
- River: translucent blue plane at ground level, configurable width and angle (Blank Slate / Custom)
- Sky/lighting/fog colors all configurable via scenario config

### Debug Logging
- All setup steps log completion with details
- Every mouse click, key press logged
- Placement/removal attempts logged with success/failure reasons
- `push_warning()` for error conditions (missing blocks, out-of-range operations)
- `OS.is_debug_build()` gating on all `_log()` calls

## File Map

| File | Purpose |
|------|---------|
| `src/game/sandbox_main.gd` | Main scene script (builds entire scene tree) |
| `src/game/scenario_config.gd` | Scenario parameters (RefCounted data class) |
| `src/game/scenario_picker.gd` | Scenario selection UI (3 presets + custom editor) |
| `src/game/orbital_camera.gd` | Camera with orbit/pan/zoom/history |
| `src/game/block_registry.gd` | Loads block definitions from JSON, category colors and ordering |
| `src/game/block_definition.gd` | Block type data (size, color, category, traversability, etc.) |
| `src/game/placed_block.gd` | Instance of a placed block |
| `src/game/grid_utils.gd` | Grid <-> world coordinate conversion |
| `src/game/face.gd` | Face direction enum + utilities |
| `src/game/shape_palette.gd` | Category-tabbed block selection UI |
| `src/game/sandbox_pause_menu.gd` | Pause menu with reset/exit |
| `src/game/sandbox_debug_panel.gd` | Extensible F3 debug panel |
| `src/game/sandbox_help_overlay.gd` | F1 controls reference |
| `shaders/ghost_preview.gdshader` | Ghost block transparency shader |
| `shaders/face_highlight.gdshader` | Face highlight with pulse |
| `shaders/grid_overlay.gdshader` | Ground grid lines |
| `data/blocks.json` | Block type definitions (21 blocks, 8 categories) |
| `scenes/main.tscn` | Scene file (just root Node3D) |

## Grid System

- **Coordinate system:** Godot Y-up (X = east/west, Z = north/south, Y = up/down)
- **Grid origin:** World (0, 0, 0) = grid (0, 0, 0)
- **Cell size:** 6.0 world units per cell in each axis
- **Ground:** y = -1 through y = -5 (5 strata layers)
- **Building:** y = 0 and above
- **Occupancy:** `Dictionary<Vector3i, int>` — cell -> block_id (ground = -1)

## Connectivity Model

- **Entrance blocks** are the anchor points. They sit on ground (y=0, ground beneath).
- **All other blocks** must be face-adjacent to an existing placed block (not ground).
- **BFS connectivity check:** On removal, BFS from each neighbor through placed blocks to verify they can still reach an entrance.
- This aligns with `Block.connected: bool` from `technical/data-model.md`.
- Future: residents only move in if block is connected to entrance (from `game-design/blocks/residential.md`).
