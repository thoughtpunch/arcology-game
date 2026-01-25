# View Modes

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Players can view the arcology from multiple perspectives.

---

## View Types

| View | Description |
|------|-------------|
| **Isometric 3D** | Default; full structure with depth |
| **Planar Slice** | Single floor, top-down |
| **Side Cutaway** | Vertical cross-section |
| **Top-Down** | Birds-eye, all floors collapsed |

---

## Isometric 3D (Default)

The standard view:
- Shows multiple floors
- Y-sorting handles depth
- Current floor + 2 below visible
- Floors above current hidden

### Controls
- WASD / Arrows: Pan camera
- Scroll wheel: Zoom
- Floor buttons: Change level

---

## Planar Slice

Top-down view of single floor:
- No depth perspective
- Good for detailed layout
- Shows all blocks on current floor
- Walls shown as lines

---

## Side Cutaway

Vertical cross-section:
- Shows floor stacking
- Good for elevator/vertical planning
- Select which axis (X or Y) to slice

---

## Top-Down

Collapsed birds-eye:
- All floors overlaid
- Good for overall structure
- Uses transparency for overlap
- Zone coloring helps

---

## Floor Visibility

In isometric view:

| Floor Relative to Current | Visibility |
|---------------------------|------------|
| Above | Hidden |
| Current | Full opacity |
| Current - 1 | 70% opacity |
| Current - 2 | 40% opacity |
| Below - 2 | Hidden |

---

## Camera Controls

| Action | Input |
|--------|-------|
| Pan | WASD, Arrow keys, Middle-drag |
| Zoom | Scroll wheel |
| Floor up | Page Up, + |
| Floor down | Page Down, - |
| View mode | 1-4 keys |

---

## See Also

- [overlays.md](./overlays.md) - Info layers
- [narrative.md](./narrative.md) - Storytelling UI
- [../architecture/milestones/milestone-2-floor-navigation.md](../architecture/milestones/milestone-2-floor-navigation.md) - Floor nav implementation
