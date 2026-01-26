# Sidebars & Floating Menus

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Sidebars and floating menus provide quick access to tools, overlays, and information without leaving the main view.

---

## Left Sidebar

### Collapsed State (Default)

```
┌─────┐
│ [≡] │  Menu
├─────┤
│ [→] │  Select Tool
│ [🔨]│  Build
│ [💣]│  Demolish
│ [ℹ️] │  Info
│ [⬆️] │  Upgrade
├─────┤
│ --- │
│QUICK│
│ [1] │  Recent block 1
│ [2] │  Recent block 2
│ [3] │  Recent block 3
├─────┤
│ [⭐]│  Favorites
└─────┘
```

Width: 64px

### Expanded State (Hover or Pin)

```
┌─────────────────────┐
│ [≡] TOOLS           │
├─────────────────────┤
│ [→] Select      (Q) │
│ [🔨] Build      (B) │
│ [💣] Demolish   (X) │
│ [ℹ️] Info       (I) │
│ [⬆️] Upgrade    (U) │
├─────────────────────┤
│ QUICK BUILD         │
│ [APT] Small Apt     │
│ [COR] Corridor      │
│ [ELV] Elevator      │
├─────────────────────┤
│ FAVORITES       [+] │
│ [SHP] Shop          │
│ [PRK] Park          │
│ [CLN] Clinic        │
└─────────────────────┘
```

Width: 240px

### Behavior

| Action | Result |
|--------|--------|
| Hover on collapsed | Expands after 300ms |
| Click pin icon | Locks expanded |
| Click outside | Collapses (if unpinned) |
| Esc key | Collapses |

---

## Right Sidebar (Overlay Panel)

Floating toggle panel for data overlays.

### Collapsed (Icon Strip)

```
┌─────┐
│ [👁] │  Overlay toggle
├─────┤
│ [☀️] │  Light
│ [💨]│  Air
│ [🔊]│  Noise
│ [🛡️] │  Safety
│ [✨]│  Vibes
│ [🔗]│  Connect
│ [🏠]│  Zones
│ [👣]│  Traffic
└─────┘
```

### Expanded (With Labels)

```
┌─────────────────────┐
│ OVERLAYS        [×] │
├─────────────────────┤
│ ○ None          (1) │
│ ● Light         (2) │  ← Active
│ ○ Air Quality   (3) │
│ ○ Noise         (4) │
│ ○ Safety        (5) │
│ ○ Vibes         (6) │
│ ○ Connectivity  (7) │
│ ○ Block Type    (8) │
│ ○ Foot Traffic  (9) │
├─────────────────────┤
│ LEGEND              │
│ ████ Bright (80%+)  │
│ ████ Good (60-80%)  │
│ ████ Fair (40-60%)  │
│ ████ Poor (20-40%)  │
│ ████ Dark (<20%)    │
└─────────────────────┘
```

### Features

- Radio selection (one overlay at a time)
- Dynamic legend based on active overlay
- Keyboard shortcuts 1-9
- Remembers last used overlay

---

## Floor Navigator (Bottom Center)

Quick floor navigation widget:

```
        ┌───┐
        │ ▲ │  Page Up
        └───┘
┌───────────────────┐
│  ◀  │ Floor 12 │  ▶  │
└───────────────────┘
        ┌───┐
        │ ▼ │  Page Down
        └───┘
```

### Extended View (Click Floor Number)

```
┌─────────────────────┐
│ FLOOR SELECTOR      │
├─────────────────────┤
│ [30] Penthouse      │
│ [29]                │
│ [28]                │
│ ...                 │
│ [12] ← Current      │  Highlighted
│ ...                 │
│ [02]                │
│ [01] Ground         │
│ [B1] Basement       │
│ [B2] Sub-basement   │
└─────────────────────┘
```

### Floor Indicators

| Indicator | Meaning |
|-----------|---------|
| ● | Current floor |
| ◐ | Has activity (residents moving) |
| ⚠ | Has alerts |
| ∅ | Empty (no blocks) |

---

## View Mode Toggle

Switch between view perspectives:

```
┌─────────────────────────────┐
│ [ISO] [TOP] [SIDE] [SLICE]  │
└─────────────────────────────┘
```

| Button | View | Key |
|--------|------|-----|
| ISO | Isometric 3D | F1 |
| TOP | Top-down | F2 |
| SIDE | Side cutaway | F3 |
| SLICE | Planar slice | F4 |

---

## Speed Controls (Top Bar)

```
┌─────────────────────────┐
│ [⏸] [▶] [▶▶] [▶▶▶]      │
│      1x   2x    3x      │
└─────────────────────────┘
```

| Button | Speed | Key |
|--------|-------|-----|
| ⏸ | Paused | Space |
| ▶ | Normal (1x) | 1 |
| ▶▶ | Fast (2x) | 2 |
| ▶▶▶ | Fastest (3x) | 3 |

Visual feedback:
- Current speed button highlighted
- Clock icon animates faster at higher speeds
- Paused shows pulsing pause icon

---

## Notification Tray (Top Right)

```
┌─────┐
│ [!3]│  ← Badge shows count
└─────┘
```

### Expanded (Click)

```
┌─────────────────────────────────┐
│ NOTIFICATIONS               [×] │
├─────────────────────────────────┤
│ ⚠ Elevator 3 at capacity       │
│   Floor 12-15 wait times high   │
│   [View] [Dismiss]         2m   │
├─────────────────────────────────┤
│ 📰 New resident: Maria Chen     │
│   Moved into Floor 8, Apt 2     │
│   [View Profile]           15m  │
├─────────────────────────────────┤
│ ✅ Budget surplus this month    │
│   +$2,400 net income            │
│   [View Budget]            1h   │
└─────────────────────────────────┘
```

### Notification Types

| Icon | Type | Priority |
|------|------|----------|
| 🔴 | Emergency | High (auto-pause) |
| ⚠ | Warning | Medium |
| 📰 | News | Low |
| ✅ | Positive | Low |
| ℹ️ | Info | Lowest |

---

## Mini-Map (Optional, Bottom Right)

Toggle with M key:

```
┌─────────────────┐
│ ┌─────────────┐ │
│ │   ▓▓▓▓▓     │ │
│ │  ▓█████▓    │ │  ← Structure outline
│ │ ▓███████▓   │ │
│ │  ▓█████▓    │ │
│ │   ▓▓▓▓▓     │ │
│ │      □      │ │  ← Viewport position
│ └─────────────┘ │
│ Floor 12    [×] │
└─────────────────┘
```

- Click to jump to location
- Shows current floor outline
- Red dots for alerts
- Green dots for selected items

---

## Floating Windows

Panels can be detached and repositioned:

### Detaching
- Drag panel header to detach
- Double-click header to re-dock
- Shift+Click to open as floating

### Floating Panel Features

```
┌─────────────────────────┬───┐
│ Block Info          [-][×]│
├─────────────────────────────┤
│ (Panel content)             │
│                             │
└─────────────────────────────┘
```

- Draggable by title bar
- Minimize button [-]
- Close button [×]
- Resizable (drag edges)
- Remember positions between sessions

---

## Tooltips

Hover over any element for contextual help:

```
                    ┌─────────────────────────┐
                    │ Light Overlay           │
                    │ ──────────────────────  │
                    │ Shows light levels      │
                    │ Yellow = bright         │
                    │ Blue = dark             │
                    │                         │
[☀️] ←───────────────│ Shortcut: 2             │
                    └─────────────────────────┘
```

### Tooltip Timing
- Appear after 500ms hover
- Disappear on mouse move
- Instant for keyboard focus

---

## See Also

- [hud-layout.md](./hud-layout.md) - Overall screen layout
- [overlays.md](./overlays.md) - Overlay details
- [views.md](./views.md) - View mode details
- [controls.md](./controls.md) - All keyboard shortcuts
