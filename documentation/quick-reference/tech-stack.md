# Tech Stack

## Core Technologies

| Layer | Choice | Why |
|-------|--------|-----|
| Engine | Godot 4.x | Open source, Vulkan renderer, native 3D with GDScript |
| Renderer | Vulkan / Forward+ | Modern PBR pipeline, real-time lighting |
| Primary Language | GDScript | Fast iteration, Godot-native |
| Performance-Critical | C# or GDExtension | Only if/when needed |
| Data Format | JSON (configs/saves), Resources (runtime) | Human-readable, Godot-native |
| Art Pipeline | Procedural geometry + PBR materials | BoxMesh, ArrayMesh, ShaderMaterial |

## Art Specifications

- **Style:** Stylized realism (not photorealistic, not cartoon)
- **Geometry:** 3D meshes — procedural (BoxMesh, ArrayMesh) and authored
- **Cell dimensions:** 6m × 6m × 6m cubes (CELL_SIZE = 6.0)
- **Materials:** PBR with stylization via ShaderMaterial
- **Lighting:** Real-time with baked GI option
- **Post-processing:** Subtle ambient occlusion, soft edges, slight bevels
- **Color palette:** Warm, optimistic, readable silhouettes at all zoom levels
- **Inspiration:** Cities: Skylines (scale), Townscaper (aesthetic), Two Point Hospital (readable interiors)

## Rendering Architecture

### Block Mesh Structure

Each block type has:
- **Exterior mesh** — Outer shell geometry
- **Interior mesh** — Furniture/fixtures (visible in cutaway)
- **Collision mesh** — Simplified for raycasting
- **LOD meshes** — LOD0 (full) through LOD3 (distant)
- **ShaderMaterial** — Supports overlays, damage, selection states
- **Panel slots** — Per-face (TOP/BOTTOM/NORTH/SOUTH/EAST/WEST) auto-generated panels

### Level of Detail (LOD)

| Distance | LOD | Detail |
|----------|-----|--------|
| 0–50m | LOD0 | Full detail, interior visible |
| 50–150m | LOD1 | Simplified exterior, no interior |
| 150–400m | LOD2 | Block silhouette only |
| 400m+ | LOD3 | Merged chunks, impostors |

### Chunk System

Blocks are grouped into **8×8×8 cell chunks** (48m × 48m × 48m) for rendering:
- Static opaque geometry merged into single draw calls
- Separate mesh layers: opaque exterior, transparent (glass), interior (cutaway), dynamic (doors/agents)
- Chunks rebuild only when blocks change within them
- Frustum culling applied per chunk

### Panel Materials

Panels auto-generate on cube faces touching exterior/void:

| Material | Style | Shader Properties |
|----------|-------|-------------------|
| Concrete | Flat with subtle texture | Matte, AO in crevices |
| Glass | Framed panes | Reflective, slight blue tint, transparency |
| Metal | Brushed panels | Subtle reflection, visible seams |
| Solar | Grid of cells | Dark blue, subtle glow, animated shimmer |
| Garden | Organic foliage | Subsurface scattering, wind animation |
| Force Field | Flat plane | Animated energy shader, edge glow |

### Shaders

Custom shaders in `shaders/`:
- `block_material.gdshader` — Base block PBR material
- `ghost_preview.gdshader` — Translucent placement preview
- `face_highlight.gdshader` — Highlighted face on hover
- `grid_overlay.gdshader` — Ground grid visualization

## Target Platforms

- **Primary:** PC (Steam), Mac, Linux
- **Potential:** Tablet (mobile port)

## Project Structure

```
arcology/
├── project.godot
├── CLAUDE.md                    # Context for AI assistants
│
├── src/
│   ├── phase0/                  # Block stacking sandbox (current)
│   │   ├── sandbox_main.gd      # Sandbox entry point
│   │   ├── grid_utils.gd        # 3D grid math (grid↔world)
│   │   ├── block_registry.gd    # Block type definitions
│   │   ├── block_definition.gd  # Block data class
│   │   ├── placed_block.gd      # Placed block instance
│   │   ├── face.gd              # CubeFace enum & utilities
│   │   ├── orbital_camera.gd    # Free orbital + ortho snap camera
│   │   ├── scenario_config.gd   # Scenario rules (gravity, limits)
│   │   ├── shape_palette.gd     # Block shape selection
│   │   └── sandbox_*.gd         # Debug panel, help, pause menu
│   ├── core/                    # Grid, blocks, placement, game state
│   ├── rendering/               # 3D block rendering, chunk manager
│   ├── blocks/                  # Block type implementations
│   ├── environment/             # Light, air, noise, safety
│   ├── agents/                  # Residents, needs, behavior trees
│   ├── transit/                 # Pathfinding, elevators
│   ├── economy/                 # Budget, rent
│   └── ui/                      # HUD, overlays, menus, panels
│
├── scenes/
│   ├── main.tscn                # Entry scene
│   └── main.tscn      # Sandbox scene (current)
│
├── shaders/
│   ├── block_material.gdshader  # Block PBR material
│   ├── ghost_preview.gdshader   # Placement ghost
│   ├── face_highlight.gdshader  # Face hover highlight
│   └── grid_overlay.gdshader    # Ground grid
│
├── assets/
│   ├── audio/
│   └── fonts/
│
├── data/
│   ├── blocks.json              # Block definitions
│   ├── balance.json             # Tuning numbers
│   └── scenarios/               # Scenario presets
│
├── test/                        # Unit and integration tests
│
└── documentation/               # Wiki-style knowledge base
```

## Dependencies

- **Godot 4.x** — Engine (Vulkan/Forward+ renderer)
- **GUT** — Godot Unit Testing (optional, for tests)

## Performance Targets

| Scale | Blocks | Population | Target FPS |
|-------|--------|------------|------------|
| Small | ~1,000 | ~5,000 | 60 |
| Medium | ~5,000 | ~25,000 | 60 |
| Large | ~20,000 | ~100,000 | 30+ |
