# Overlays

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Overlays visualize game system data directly on the 3D arcology. In the 3D world, overlays are rendered as **heat maps on block faces and surfaces** rather than flat tile tints. Data values map to color gradients applied via material shaders, giving a true volumetric read of conditions throughout the structure.

> Overlays work with all [visibility modes](./views.md) — cutaway, x-ray, floor isolate, and section views all display overlay data on visible surfaces.

---

## Available Overlays

| Overlay | Key | Alt Key | Visualization |
|---------|-----|---------|---------------|
| None (Normal) | ` | — | Standard 3D rendering |
| Light | F1 | Alt+1 | Yellow (bright) → Blue (dark) on block faces |
| Air Quality | F2 | Alt+2 | Green (good) → Brown (bad) on block faces |
| Noise | F3 | Alt+3 | Cool blue (quiet) → Red (loud) on block faces |
| Safety | F4 | Alt+4 | Green (safe) → Red (dangerous) on block faces |
| Vibes | F5 | Alt+5 | Bright glow (high) → Dim gray (low) |
| Connectivity | F6 | Alt+6 | Green (connected) → Red (disconnected) |
| Block Type | F7 | Alt+7 | Solid color by category |
| Foot Traffic | F8 | Alt+8 | Heat map on corridor/transit surfaces |

---

## 3D Overlay Rendering

### How Overlays Work in 3D

Unlike 2D tile tints, 3D overlays are applied **per-face** on block meshes using shader material overrides:

```
  2D (old):                     3D (new):
  ┌───┬───┬───┐               ┌─────────┐
  │ 🟡│ 🟢│ 🔴│  flat tint    │╱ 🟡top ╱│  face-by-face
  ├───┼───┼───┤       →       │🟢front  │🔴side   heat map
  │ 🟢│ 🟡│ 🟢│               │         │
  └───┴───┴───┘               └─────────┘
```

Each block face can show a different overlay value (e.g., a block's north face might get more light than its south face). This provides richer spatial data than flat per-cell coloring.

### Shader Approach

```gdscript
# Overlay values are written to a per-face uniform on the block's material
# The shader interpolates between the overlay color ramp based on the value

func apply_overlay(block: Node3D, overlay_type: OverlayType) -> void:
    var values = get_face_values(block, overlay_type)
    var material = block.get_overlay_material()
    material.set_shader_parameter("overlay_colors", values)
    material.set_shader_parameter("overlay_intensity", 1.0)

func clear_overlay(block: Node3D) -> void:
    var material = block.get_overlay_material()
    material.set_shader_parameter("overlay_intensity", 0.0)
```

### Overlay + Visibility Mode Interaction

| Visibility Mode | Overlay Behavior |
|----------------|-----------------|
| Normal | Overlay on all visible exterior faces |
| Cutaway | Overlay on faces below the cut plane; cut surfaces show overlay data for exposed interiors |
| X-Ray | Overlay visible through translucent exterior; interior faces show overlay at full intensity |
| Floor Isolate | Full overlay detail on the isolated floor only |
| Section | Overlay on the section cut face, showing cross-section data |

---

## Light Overlay

Shows effective light level on each block face:

| Value | Color | Meaning |
|-------|-------|---------|
| 100% | Bright yellow | Full sunlight / well-lit |
| 75% | Warm yellow | Good lighting |
| 50% | Muted yellow-gray | Dim |
| 25% | Gray-blue | Poor lighting |
| 0% | Dark blue | No light (deep interior) |

**Helps identify:**
- Dark interiors needing light pipes
- Subterranean areas with no sunlight access
- Atrium effectiveness (light propagation downward)
- Shadows cast by upper structure

---

## Air Quality Overlay

Shows air quality on block faces:

| Value | Color | Meaning |
|-------|-------|---------|
| 100% | Fresh green | Excellent ventilation |
| 75% | Light green | Good air |
| 50% | Yellow | Moderate, needs improvement |
| 25% | Yellow-brown | Poor air quality |
| 0% | Dark brown | Stale / toxic |

**Helps identify:**
- HVAC coverage gaps
- Industrial pollution spread
- Ventilation shaft effectiveness
- Sealed areas with no air flow

---

## Noise Overlay

Shows noise levels:

| Value | Color | Meaning |
|-------|-------|---------|
| 0-20 | No indicator | Quiet |
| 20-40 | Light blue waves | Moderate ambient noise |
| 40-60 | Orange waves | Loud |
| 60+ | Red pulsing waves | Very loud |

**Rendering:** Noise uses animated wave particles emanating from noise sources, in addition to face coloring. Louder = more intense waves.

**Helps identify:**
- Traffic noise from busy corridors
- Industrial / entertainment noise bleed
- Residential quiet zones
- Sound insulation effectiveness

---

## Safety Overlay

Shows crime/safety levels:

| Value | Color | Meaning |
|-------|-------|---------|
| 80-100 | Bright green | Very safe |
| 50-80 | Yellow-green | Moderate safety |
| 30-50 | Orange | Risky |
| 0-30 | Red | Dangerous |

**Helps identify:**
- Security coverage gaps
- Dark / unlit areas (crime risk factor)
- Upper-floor safety advantage (crime doesn't climb)
- Crime propagation paths through corridors

---

## Vibes Overlay

Shows composite environmental quality:

| Level | Visual | Meaning |
|-------|--------|---------|
| High | Bright glow + sparkle particles | Premium living area |
| Medium | Moderate glow | Average quality |
| Low | Dim | Below average |
| Very Low | Gray / dark | Unpleasant area |

**Helps identify:**
- Premium areas for high-rent housing
- Areas needing environmental improvement
- Green space and atrium effectiveness
- Overall desirability gradient

---

## Connectivity Overlay

Shows path connectivity to building entrance:

| State | Color | Meaning |
|-------|-------|---------|
| Connected | Green | Has valid path to entrance |
| Disconnected | Red | No path to entrance (no income) |

**Rendering:** In 3D, connected paths can optionally show animated directional arrows along the transit route.

**Helps identify:**
- Disconnected blocks (produce no income)
- Missing corridors / broken paths
- Dead-end areas
- Elevator shaft connectivity

---

## Block Type Overlay

Solid color by block category:

| Category | Color |
|----------|-------|
| Residential | Blue |
| Commercial | Green |
| Industrial | Orange |
| Transit | Gray |
| Green | Dark Green |
| Civic | Purple |
| Infrastructure | Yellow |

**Helps identify:**
- Zone distribution balance
- Mixed-use areas
- Missing categories (no civic on a floor, etc.)
- Transit network coverage

---

## Foot Traffic Overlay

Heat map showing agent movement density on corridor and transit surfaces:

| Density | Color | Meaning |
|---------|-------|---------|
| High | Bright red/yellow | Major artery |
| Medium | Orange | Moderate traffic |
| Low | Cool blue | Light use |
| None | Gray | Unused path |

**Rendering:** Heat map colors are applied to the **top face** (floor surface) of transit blocks. Optionally, animated flow lines show direction of traffic.

**Helps identify:**
- Main arteries and bottlenecks
- Dead zones (wasted transit space)
- Commercial location quality (foot traffic = customers)
- Elevator and stairwell utilization

---

## Overlay Controls

| Action | Input |
|--------|-------|
| Clear overlay (normal view) | ` (backtick) |
| Select overlay | F1-F8 or Alt+1 through Alt+8 |
| Cycle overlays | Ctrl+Tab |
| Overlay intensity | Shift+scroll while overlay active |

---

## Implementation

### Files

| File | Purpose |
|------|---------|
| `src/rendering/overlay_manager.gd` | Manages active overlay, coordinates shader parameters |
| `src/rendering/overlay_shader.tres` | Shared overlay shader (color ramp + intensity) |
| `src/ui/overlay_toolbar.gd` | Overlay selection UI |
| `src/environment/*_system.gd` | Data sources for each overlay type |

### Signals

```gdscript
# OverlayManager
signal overlay_changed(type: String)  # "none", "light", "air", etc.
signal overlay_intensity_changed(value: float)
```

---

## See Also

- [views.md](./views.md) — Visibility modes (work with overlays)
- [controls.md](./controls.md) — Full input mapping table
- [../game-design/environment/](../game-design/environment/) — Environment system details (data sources)
