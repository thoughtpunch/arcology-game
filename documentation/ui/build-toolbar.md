# Build Toolbar

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

The Build Toolbar is the primary interface for placing blocks. Located at the bottom of the screen, it provides categorized access to all buildable blocks.

---

## Toolbar Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  BLOCK CATEGORIES                              PLACEMENT CONTROLS   │
│ ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐   ┌─────┬─────┬─────┐  │
│ │ RES │ COM │ IND │ TRA │ GRN │ CIV │ INF │   │ ROT │ VAR │ DEL │  │
│ │  1  │  2  │  3  │  4  │  5  │  6  │  7  │   │  R  │  V  │  X  │  │
│ └─────┴─────┴─────┴─────┴─────┴─────┴─────┘   └─────┴─────┴─────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Block Categories

| Category | Key | Icon | Color | Contents |
|----------|-----|------|-------|----------|
| Residential | 1 | House | Blue | Apartments, condos, dormitories |
| Commercial | 2 | Store | Green | Shops, restaurants, offices |
| Industrial | 3 | Gear | Orange | Workshops, factories, utilities |
| Transit | 4 | Arrow | Gray | Corridors, elevators, stairs |
| Green | 5 | Leaf | Dark Green | Parks, gardens, atriums |
| Civic | 6 | Column | Purple | Schools, clinics, community |
| Infrastructure | 7 | Bolt | Yellow | Power, water, HVAC, light pipes |

---

## Category Expansion

Clicking a category opens a flyout panel above the toolbar:

```
                    ┌─────────────────────────────────────┐
                    │  RESIDENTIAL                    [×] │
                    ├─────────────────────────────────────┤
                    │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐   │
                    │  │ APT │ │ APT │ │CONDO│ │DORM │   │
                    │  │ SM  │ │ LG  │ │     │ │     │   │
                    │  │$500 │ │$800 │ │$1.2K│ │$400 │   │
                    │  └─────┘ └─────┘ └─────┘ └─────┘   │
                    │  ┌─────┐ ┌─────┐ ┌─────┐           │
                    │  │PENT │ │LOFT │ │ ... │           │
                    │  │HOUSE│ │     │ │     │           │
                    │  │$3K  │ │$1.5K│ │     │           │
                    │  └─────┘ └─────┘ └─────┘           │
                    └─────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│ ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐                         │
│ │[RES]│ COM │ IND │ TRA │ GRN │ CIV │ INF │   (Category selected)   │
```

### Flyout Contents

Each block tile shows:
- Block sprite (preview)
- Block name
- Construction cost
- Size indicator (if multi-tile)

---

## Block Selection States

| State | Visual | Description |
|-------|--------|-------------|
| Available | Normal | Can be built |
| Selected | Highlighted border | Currently selected |
| Locked | Grayed + lock icon | Not yet unlocked |
| Unaffordable | Red tint | Not enough money |
| Invalid placement | Red ghost | Cannot place here |

---

## Placement Mode

After selecting a block:

### Ghost Preview
- Semi-transparent block follows cursor
- Green tint = valid placement
- Red tint = invalid placement
- Shows footprint on grid

### Placement Controls

| Action | Input | Description |
|--------|-------|-------------|
| Place block | Left click | Build at cursor |
| Cancel | Right click / Esc | Exit placement mode |
| Rotate | R / Mouse wheel | Rotate 90° |
| Variant | V | Cycle visual variants |
| Drag-place | Hold left click | Place multiple (corridors) |

### Placement Validation

Block placement checks:
- [ ] Space is empty (or demolishable)
- [ ] Connected to transit network
- [ ] Player has funds
- [ ] Floor supports block type
- [ ] No floating blocks (gravity check)

---

## Quick Build

Recently used blocks appear in left sidebar for fast access:

```
┌───────┐
│ QUICK │
├───────┤
│ [APT] │  ← Last placed
│ [COR] │
│ [ELV] │
│ [SHP] │
│ [---] │
└───────┘
```

- Shows last 5 unique blocks placed
- Click to select immediately
- Drag to reorder favorites

---

## Favorites

Players can pin frequently used blocks:

- Right-click block in flyout → "Add to Favorites"
- Favorites appear below Quick Build
- Maximum 10 favorites
- Persists between sessions

---

## Multi-Block Placement

### Drag Building (Corridors, Walls)

Hold left-click and drag to place continuous runs:

```
Start → → → → End
[COR][COR][COR][COR][COR]
```

- Shows total cost while dragging
- Release to confirm
- Escape to cancel

### Blueprint Mode (Future)

For complex repeated structures:
- Save selection as blueprint
- Place blueprint as single unit
- Useful for standard floor layouts

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| 1-7 | Open category |
| Esc | Close flyout / Cancel placement |
| R | Rotate block |
| V | Cycle variant |
| X | Switch to demolish tool |
| Q | Select tool (exit build mode) |
| Shift+Click | Place without exiting mode |
| Ctrl+Z | Undo last placement |

---

## Cost Display

When hovering or selecting:

```
┌─────────────────────────┐
│  Small Apartment        │
│  ────────────────────   │
│  Cost: $500             │
│  Size: 1×1×1            │
│  Monthly: +$80 rent     │
│  Capacity: 2 residents  │
│  Needs: Light, Air      │
└─────────────────────────┘
```

---

## Demolish Tool

Accessed via X key or toolbar button:

| Action | Input |
|--------|-------|
| Select demolish | X key |
| Demolish single | Left click |
| Demolish area | Drag select |
| Cancel | Right click / Esc |

Demolish shows:
- Refund amount (50% of build cost)
- Warning if occupied
- Confirmation for expensive blocks

---

## See Also

- [hud-layout.md](./hud-layout.md) - Toolbar position
- [controls.md](./controls.md) - Full shortcut list
- [../game-design/blocks/](../game-design/blocks/) - Block specifications
