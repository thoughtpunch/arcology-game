# Controls Reference

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Complete reference for all keyboard shortcuts and mouse controls. All controls are rebindable in Settings.

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    ARCOLOGY CONTROLS                        │
├─────────────────────────────────────────────────────────────┤
│  CAMERA           │  GAME SPEED       │  TOOLS              │
│  WASD - Pan       │  Space - Pause    │  Q - Select         │
│  Scroll - Zoom    │  1 - Normal       │  B - Build          │
│  PgUp/Dn - Floor  │  2 - Fast         │  X - Demolish       │
│  1-4 - View mode  │  3 - Fastest      │  I - Info           │
├─────────────────────────────────────────────────────────────┤
│  OVERLAYS         │  PLACEMENT        │  GENERAL            │
│  ` - None         │  LClick - Place   │  Esc - Menu/Cancel  │
│  F1 - Light       │  RClick - Cancel  │  Tab - Cycle panels │
│  F2 - Air         │  R - Rotate       │  M - Minimap        │
│  F3 - Noise       │  V - Variant      │  H - Help           │
│  F4-F8 - More     │  Shift - Multi    │  F9 - Screenshot    │
└─────────────────────────────────────────────────────────────┘
```

---

## Camera Controls

### Pan (Move View)

| Action | Primary | Alternate |
|--------|---------|-----------|
| Pan Up | W | Up Arrow |
| Pan Down | S | Down Arrow |
| Pan Left | A | Left Arrow |
| Pan Right | D | Right Arrow |
| Pan (Mouse) | Middle-drag | Right-drag |
| Edge Pan | Mouse at screen edge | (Toggleable in settings) |

### Zoom

| Action | Primary | Alternate |
|--------|---------|-----------|
| Zoom In | Scroll Up | + / = |
| Zoom Out | Scroll Down | - |
| Zoom to Selection | Z | - |
| Reset Zoom | Home | - |

### Floor Navigation

| Action | Primary | Alternate |
|--------|---------|-----------|
| Floor Up | Page Up | E |
| Floor Down | Page Down | C |
| Go to Floor | Click floor selector | Type number |
| Top Floor | Ctrl+Page Up | - |
| Ground Floor | Ctrl+Page Down | - |

### View Modes

| View | Key |
|------|-----|
| Isometric (Default) | F1 |
| Top-Down | F2 |
| Side Cutaway | F3 |
| Planar Slice | F4 |

---

## Game Speed

| Speed | Key | Description |
|-------|-----|-------------|
| Pause | Space | Freeze time |
| Normal (1×) | 1 | Real-time |
| Fast (2×) | 2 | Double speed |
| Fastest (3×) | 3 | Triple speed |

---

## Tool Selection

| Tool | Key | Description |
|------|-----|-------------|
| Select | Q | Default cursor, click to inspect |
| Build | B | Open build toolbar |
| Demolish | X | Remove blocks |
| Info | I | Detailed inspection mode |
| Upgrade | U | Upgrade selected block |

---

## Building & Placement

### Selecting Blocks

| Action | Input |
|--------|-------|
| Open Residential | 1 (when build mode active) |
| Open Commercial | 2 |
| Open Industrial | 3 |
| Open Transit | 4 |
| Open Green | 5 |
| Open Civic | 6 |
| Open Infrastructure | 7 |
| Close Category | Esc or Right-click |

### Placing Blocks

| Action | Input |
|--------|-------|
| Place Block | Left-click |
| Cancel Placement | Right-click or Esc |
| Rotate 90° CW | R or Scroll Up |
| Rotate 90° CCW | Shift+R or Scroll Down |
| Cycle Variant | V |
| Place Multiple | Hold Left-click + drag |
| Place & Keep Selected | Shift+Left-click |

### Selection

| Action | Input |
|--------|-------|
| Select Object | Left-click |
| Add to Selection | Shift+Left-click |
| Box Select | Left-drag |
| Add Box Select | Shift+Left-drag |
| Select All (Same Type) | Ctrl+A |
| Clear Selection | Esc or Click empty |

---

## Overlays

| Overlay | Key |
|---------|-----|
| None (Normal View) | ` (backtick) |
| Light | F1 |
| Air Quality | F2 |
| Noise | F3 |
| Safety | F4 |
| Vibes | F5 |
| Connectivity | F6 |
| Block Type | F7 |
| Foot Traffic | F8 |

*Note: Overlay keys may conflict with View Mode keys. Configure in settings.*

**Alternative Overlay Keys:**

| Overlay | Alt Key |
|---------|---------|
| Light | Alt+1 |
| Air Quality | Alt+2 |
| Noise | Alt+3 |
| Safety | Alt+4 |
| Vibes | Alt+5 |
| Connectivity | Alt+6 |
| Block Type | Alt+7 |
| Foot Traffic | Alt+8 |

---

## Panels & UI

| Action | Key |
|--------|-----|
| Toggle Budget Panel | $ |
| Toggle AEI Dashboard | Y |
| Toggle Left Sidebar | [ |
| Toggle Right Panel | ] |
| Cycle Info Panels | Tab |
| Close Current Panel | Esc |
| Pin Panel | P (when panel focused) |
| Detach Panel | Shift+Drag header |

---

## General

| Action | Key |
|--------|-----|
| Pause Menu | Esc |
| Quick Save | Ctrl+S |
| Quick Load | Ctrl+L |
| Undo | Ctrl+Z |
| Redo | Ctrl+Y / Ctrl+Shift+Z |
| Toggle Minimap | M |
| Screenshot | F9 |
| Toggle UI | F10 |
| Toggle Full Screen | F11 / Alt+Enter |
| Help | H / F12 |

---

## Mouse Controls

### Left Mouse Button

| Context | Action |
|---------|--------|
| On block | Select block |
| On resident | Select resident |
| On empty space | Deselect |
| In build mode | Place block |
| Drag on empty | Box select |
| Shift+Click | Add to selection |

### Right Mouse Button

| Context | Action |
|---------|--------|
| Anywhere | Cancel current action |
| On block | Context menu |
| Drag | Pan camera |

### Middle Mouse Button

| Context | Action |
|---------|--------|
| Click | Reset view |
| Drag | Pan camera |

### Scroll Wheel

| Context | Action |
|---------|--------|
| Normal | Zoom in/out |
| In build mode | Rotate block |
| Shift+Scroll | Change floor |
| Over slider | Adjust value |

---

## Context Menus (Right-Click)

### On Block

```
┌─────────────────────┐
│ Small Apartment     │
├─────────────────────┤
│ View Details    (I) │
│ Upgrade         (U) │
│ Demolish        (X) │
│ ─────────────────── │
│ Select Similar      │
│ Add to Favorites    │
└─────────────────────┘
```

### On Resident

```
┌─────────────────────┐
│ Maria Chen          │
├─────────────────────┤
│ View Profile    (I) │
│ Follow              │
│ View Home           │
│ View Workplace      │
│ ─────────────────── │
│ View Complaints     │
│ View Relationships  │
└─────────────────────┘
```

### On Empty Space

```
┌─────────────────────┐
│ Floor 12            │
├─────────────────────┤
│ Build Here      (B) │
│ Paste               │
│ ─────────────────── │
│ View Floor Stats    │
└─────────────────────┘
```

---

## Accessibility Shortcuts

| Action | Key |
|--------|-----|
| Increase UI Scale | Ctrl++ |
| Decrease UI Scale | Ctrl+- |
| Reset UI Scale | Ctrl+0 |
| Toggle High Contrast | Ctrl+H |
| Read Selection Aloud | Ctrl+R |
| Slow Mode (0.5×) | 0 |

---

## Gamepad Support (Future)

| Control | Button |
|---------|--------|
| Pan Camera | Left Stick |
| Cursor | Right Stick |
| Select/Place | A |
| Cancel | B |
| Open Build | X |
| Demolish | Y |
| Floor Up | RB |
| Floor Down | LB |
| Speed Controls | D-Pad |
| Pause Menu | Start |
| Quick Menu | Select |

---

## Customization

All controls can be rebound in Settings → Controls.

### Rebinding Process
1. Navigate to Settings → Controls
2. Click [Rebind] next to action
3. Press desired key
4. Press Esc to cancel

### Conflict Resolution
- Warning shown if key already bound
- Option to swap bindings
- Option to unbind conflicting action

### Profiles
- Save multiple control profiles
- Quick switch via dropdown
- Import/Export profiles

---

## See Also

- [menus.md](./menus.md) - Settings menu details
- [hud-layout.md](./hud-layout.md) - UI layout
- [build-toolbar.md](./build-toolbar.md) - Build controls
