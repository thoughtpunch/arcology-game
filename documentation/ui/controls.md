# Controls Reference

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Complete reference for all keyboard, mouse, and controller inputs in the 3D arcology. All controls are rebindable in Settings > Controls.

> **Reference:** [3D Refactor Specification §4, §5, §6, §7](../architecture/3d-refactor/specification.md)

---

## Quick Reference Card

```
┌───────────────────────────────────────────────────────────────────┐
│                      ARCOLOGY 3D CONTROLS                         │
├───────────────────────────────────────────────────────────────────┤
│  CAMERA              │  VISIBILITY         │  TOOLS               │
│  WASD - Pan          │  C - Cutaway        │  Q - Select          │
│  Mid-drag - Orbit    │  X - X-Ray          │  B - Build           │
│  Scroll - Zoom       │  I - Floor Isolate  │  X - Demolish        │
│  Q/E - Orbit L/R     │  V - Section        │  R - Rotate block    │
│  R/F - Tilt U/D      │  N - Normal         │  Shift+Click - Multi │
│  Tab - Free/Ortho    │  [ ] - Cut height   │                      │
│  1-7 - Ortho views   │                     │                      │
│  0 - Free camera     │                     │                      │
├───────────────────────────────────────────────────────────────────┤
│  OVERLAYS            │  GAME SPEED         │  GENERAL             │
│  F1-F8 - Overlays    │  Space - Pause      │  Esc - Menu/Cancel   │
│  ` - Clear overlay   │  , - Normal         │  Tab - Free/Ortho    │
│  Alt+1-8 - Alt keys  │  . - Fast           │  H - Camera pane     │
│                      │  / - Fastest        │  Ctrl+S - Save       │
└───────────────────────────────────────────────────────────────────┘
```

---

## Camera Controls

### Orbit (Rotate View)

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Orbit left/right | Middle-drag horizontal | Q / E | Right Stick X |
| Tilt up/down | Middle-drag vertical | R / F | Right Stick Y |
| Reset view | Double-click middle | Home | R3 |
| Focus on selection | — | F | Y |

### Pan (Move View)

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Pan north | — | W / Up Arrow | Left Stick Up |
| Pan south | — | S / Down Arrow | Left Stick Down |
| Pan west | — | A / Left Arrow | Left Stick Left |
| Pan east | — | D / Right Arrow | Left Stick Right |
| Pan (free) | Shift+Middle-drag | — | — |
| Edge pan | Mouse at screen edge | — | — |

**Speed modifiers (keyboard pan only):**

| Modifier | Effect |
|----------|--------|
| Shift + WASD | Fast pan |
| Ctrl + WASD | Slow pan |

### Zoom

| Action | Mouse | Keyboard | Controller |
|--------|-------|----------|------------|
| Zoom in | Scroll up | Z | Right Trigger |
| Zoom out | Scroll down | X | Left Trigger |
| Reset zoom | — | Home | — |

### Camera Mode

| Action | Keyboard | Controller |
|--------|----------|------------|
| Toggle Free/Ortho | Tab | Back |
| Snap to Top-Down | 1 | — |
| Snap to North | 2 | — |
| Snap to East | 3 | — |
| Snap to South | 4 | — |
| Snap to West | 5 | — |
| Snap to Bottom | 6 | — |
| Snap to Isometric | 7 | — |
| Return to Free | 0 | — |

### Camera Bookmarks

| Action | Key |
|--------|-----|
| Save bookmark | Ctrl+1 through Ctrl+9 |
| Recall bookmark | Alt+1 through Alt+9 (when not in overlay mode) |
| Undo camera (go back) | Backspace |

---

## Visibility Modes

| Mode | Key | Description |
|------|-----|-------------|
| Normal | N | Full 3D rendering, nothing hidden |
| Cutaway | C | Remove geometry above a horizontal cut plane |
| X-Ray | X | Make exterior walls transparent |
| Floor Isolate | I | Show only one floor |
| Section | V | Vertical cross-section slice |

### Cutaway Controls

| Action | Key |
|--------|-----|
| Toggle cutaway | C |
| Raise cut plane | ] |
| Lower cut plane | [ |
| Snap to floor | Ctrl+] / Ctrl+[ |

### X-Ray Controls

| Action | Key |
|--------|-----|
| Toggle x-ray | X |
| Increase transparency | Shift+X |
| Decrease transparency | Ctrl+X |

### Floor Isolate Controls

| Action | Key |
|--------|-----|
| Toggle floor isolate | I |
| Floor up | Page Up |
| Floor down | Page Down |

### Section Controls

| Action | Key |
|--------|-----|
| Toggle section | V |
| Move section plane | Arrow keys (while section active) |
| Rotate section axis | Shift+V |

---

## Building & Placement

### Tool Selection

| Tool | Key | Description |
|------|-----|-------------|
| Select | Q | Default cursor, click to inspect |
| Build | B | Open build toolbar |
| Demolish | X | Remove blocks (context: not in x-ray) |
| Upgrade | U | Upgrade selected block |

### Selecting Block Types

| Action | Key |
|--------|-----|
| Open Residential | 1 (when build mode active) |
| Open Commercial | 2 |
| Open Industrial | 3 |
| Open Transit | 4 |
| Open Green | 5 |
| Open Civic | 6 |
| Open Infrastructure | 7 |
| Close Category | Esc or Right-click |

### Placing Blocks (Face-Snap)

| Action | Input |
|--------|-------|
| Place block | Left-click on ghost preview |
| Cancel placement | Right-click or Esc |
| Rotate 90° CW | R |
| Rotate 90° CCW | Shift+R |
| Cycle variant | V |
| Place & keep selected | Shift+Left-click |
| Drag-place (corridors) | Hold Left-click + drag |

### Ghost Preview Colors

| Color | Meaning |
|-------|---------|
| Green | Valid placement |
| Yellow | Valid with warnings |
| Red | Invalid (blocked, unsupported, etc.) |

### Selection

| Action | Input |
|--------|-------|
| Select block | Left-click |
| Add to selection | Ctrl+Left-click |
| Box select | Left-drag on empty space |
| Add box select | Ctrl+Left-drag |
| Select all same type | Ctrl+A |
| Clear selection | Esc or click empty space |

> **Note:** Shift is reserved for camera speed modifiers. Use Ctrl for selection modifiers.

---

## Overlays

| Overlay | Primary Key | Alt Key |
|---------|-------------|---------|
| None (Normal View) | ` (backtick) | — |
| Light | F1 | Alt+1 |
| Air Quality | F2 | Alt+2 |
| Noise | F3 | Alt+3 |
| Safety | F4 | Alt+4 |
| Vibes | F5 | Alt+5 |
| Connectivity | F6 | Alt+6 |
| Block Type | F7 | Alt+7 |
| Foot Traffic | F8 | Alt+8 |

| Action | Input |
|--------|-------|
| Cycle overlays | Ctrl+Tab |
| Adjust intensity | Shift+Scroll (while overlay active) |

---

## Game Speed

| Speed | Key | Description |
|-------|-----|-------------|
| Pause | Space | Freeze time |
| Normal (1x) | , | Real-time |
| Fast (2x) | . | Double speed |
| Fastest (3x) | / | Triple speed |

---

## Panels & UI

| Action | Key |
|--------|-----|
| Toggle Budget Panel | $ |
| Toggle AEI Dashboard | Y |
| Toggle Left Sidebar | [ |
| Toggle Right Panel | ] |
| Cycle Info Panels | Tab (when panel focused) |
| Close Current Panel | Esc |
| Pin Panel | P (when panel focused) |
| Detach Panel | Shift+Drag header |
| Toggle Camera Pane | H |

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
| Help | F12 |

---

## Mouse Controls (Full Reference)

### Left Mouse Button

| Context | Action |
|---------|--------|
| On block | Select block |
| On agent | Select agent |
| On empty space | Deselect all |
| In build mode, on block face | Place block (face-snap) |
| In build mode, drag | Drag-place corridor |
| Shift+Click in build mode | Place & keep block selected |
| Ctrl+Click | Add to selection |
| Ctrl+Drag on empty | Box-add to selection |

### Right Mouse Button

| Context | Action |
|---------|--------|
| Anywhere | Cancel current action |
| On block | Context menu |
| On agent | Agent context menu |

### Middle Mouse Button

| Context | Action |
|---------|--------|
| Drag | Orbit camera (horizontal + vertical) |
| Shift+Drag | Pan camera |
| Double-click | Reset view |

### Scroll Wheel

| Context | Action |
|---------|--------|
| Normal | Zoom in/out |
| In build mode | Rotate block (R shortcut alternative) |
| Shift+Scroll | Overlay intensity (when overlay active) |

---

## Controller Support

| Action | Button |
|--------|--------|
| Pan Camera | Left Stick |
| Orbit Camera | Right Stick |
| Select / Place | A |
| Cancel | B |
| Open Build Menu | X |
| Demolish | Y |
| Zoom In | Right Trigger |
| Zoom Out | Left Trigger |
| Floor Up | RB |
| Floor Down | LB |
| Speed Controls | D-Pad |
| Toggle Free/Ortho | Back |
| Pause Menu | Start |

---

## Context Menus (Right-Click)

### On Block

```
┌─────────────────────────┐
│ Small Apartment          │
├─────────────────────────┤
│ View Details         (I) │
│ Upgrade              (U) │
│ Demolish             (X) │
│ ──────────────────────── │
│ Select Similar           │
│ Add to Favorites         │
└─────────────────────────┘
```

### On Agent

```
┌─────────────────────────┐
│ Maria Chen               │
├─────────────────────────┤
│ View Profile         (I) │
│ Follow                   │
│ View Home                │
│ View Workplace           │
│ ──────────────────────── │
│ View Complaints          │
│ View Relationships       │
└─────────────────────────┘
```

### On Empty Space

```
┌─────────────────────────┐
│ Grid Position (5, 3, 12) │
├─────────────────────────┤
│ Build Here           (B) │
│ Paste                    │
│ ──────────────────────── │
│ View Floor Stats         │
└─────────────────────────┘
```

---

## Accessibility

| Action | Key |
|--------|-----|
| Increase UI Scale | Ctrl++ |
| Decrease UI Scale | Ctrl+- |
| Reset UI Scale | Ctrl+0 |
| Toggle High Contrast | Ctrl+H |
| Read Selection Aloud | Ctrl+R |
| Slow Mode (0.5x) | 0 |

---

## Customization

All controls can be rebound in Settings > Controls.

### Rebinding Process
1. Navigate to Settings > Controls
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

- [camera-controls.md](./camera-controls.md) — Camera system details
- [views.md](./views.md) — Visibility mode details
- [build-toolbar.md](./build-toolbar.md) — Build system details
- [overlays.md](./overlays.md) — Overlay system details
- [menus.md](./menus.md) — Settings menu
- [hud-layout.md](./hud-layout.md) — UI layout
