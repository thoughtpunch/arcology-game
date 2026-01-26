# HUD Layout

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

The HUD (Heads-Up Display) organizes all UI elements around the game viewport. Design prioritizes clarity and minimal viewport obstruction.

---

## Screen Regions

```
┌─────────────────────────────────────────────────────────────────┐
│  TOP BAR                                                        │
│  [Menu] [Resources] [Date/Time] [Speed Controls] [Notifications]│
├───────┬─────────────────────────────────────────────────┬───────┤
│       │                                                 │       │
│  L    │                                                 │   R   │
│  E    │                                                 │   I   │
│  F    │              GAME VIEWPORT                      │   G   │
│  T    │                                                 │   H   │
│       │            (Isometric View)                     │   T   │
│  S    │                                                 │       │
│  I    │                                                 │   P   │
│  D    │                                                 │   A   │
│  E    │                                                 │   N   │
│  B    │                                                 │   E   │
│  A    │                                                 │   L   │
│  R    │                                                 │       │
│       │                                                 │       │
├───────┴─────────────────────────────────────────────────┴───────┤
│  BOTTOM BAR                                                     │
│  [Build Toolbar] [Floor Navigator] [View Mode] [Overlays]       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Region Specifications

### Top Bar (Fixed Height: 48px)

| Position | Element | Description |
|----------|---------|-------------|
| Left | Menu Button | Main menu access |
| Left-Center | Resources | Money, population, AEI score |
| Center | Date/Time | Current game date, time of day |
| Center-Right | Speed Controls | Pause, 1x, 2x, 3x buttons |
| Right | Notifications | Alert icons, news indicator |

```
┌────────────────────────────────────────────────────────────┐
│ [≡] │ $124,500  Pop: 2,847  AEI: 72 │ Y5 M3 D12 │ [▶ ▶▶ ▶▶▶] │ [!3]│
└────────────────────────────────────────────────────────────┘
```

### Left Sidebar (Collapsible, Width: 64px collapsed / 240px expanded)

Primary tool selection and quick actions:

| Section | Contents |
|---------|----------|
| Tools | Select, Demolish, Info, Upgrade |
| Quick Build | Recently used blocks |
| Favorites | Player-pinned blocks |

### Right Panel (Contextual, Width: 320px)

Shows context-sensitive information:

| Context | Panel Shown |
|---------|-------------|
| Nothing selected | AEI Dashboard summary |
| Block selected | Block Info Panel |
| Resident selected | Resident Info Panel |
| Multiple selected | Multi-select summary |

### Bottom Bar (Fixed Height: 80px)

| Position | Element | Width |
|----------|---------|-------|
| Left | Build Toolbar | Flexible |
| Center | Floor Navigator | 200px |
| Center-Right | View Mode Toggle | 160px |
| Right | Overlay Buttons | 200px |

```
┌────────────────────────────────────────────────────────────┐
│ [Res][Com][Ind][Tra][Grn][Civ][Inf] │ [▼]F12[▲] │ [ISO][TOP] │ [Overlays▼]│
└────────────────────────────────────────────────────────────┘
```

---

## Responsive Behavior

### Minimum Resolution: 1280x720

| Resolution | Adaptations |
|------------|-------------|
| 1280x720 | Compact mode, smaller fonts |
| 1920x1080 | Standard layout |
| 2560x1440+ | Expanded panels, more info visible |
| Ultrawide | Side panels can be wider |

### Panel Collapse Rules

- Right panel auto-hides when nothing selected (after 5s)
- Left sidebar collapses on viewport click
- Bottom bar always visible (core tools)
- Top bar always visible (critical info)

---

## Z-Order (Front to Back)

1. Modal dialogs (settings, confirmations)
2. Tooltips
3. Dropdown menus
4. Notification toasts
5. Floating panels (detached info panels)
6. Fixed HUD elements
7. Game viewport

---

## Color Scheme

| Element | Background | Text | Border |
|---------|------------|------|--------|
| Top Bar | `#1a1a2e` (dark blue) | `#ffffff` | None |
| Sidebars | `#16213e` (navy) | `#e0e0e0` | `#0f3460` |
| Bottom Bar | `#1a1a2e` | `#ffffff` | None |
| Panels | `#1a1a2e` @ 95% opacity | `#e0e0e0` | `#0f3460` |
| Buttons | `#0f3460` | `#ffffff` | `#e94560` on hover |
| Accent | `#e94560` (coral) | - | - |

---

## Animation & Transitions

| Action | Animation | Duration |
|--------|-----------|----------|
| Panel open | Slide in | 200ms ease-out |
| Panel close | Slide out | 150ms ease-in |
| Sidebar collapse | Width lerp | 150ms |
| Button hover | Background fade | 100ms |
| Notification appear | Slide down + fade | 300ms |
| Notification dismiss | Fade out | 200ms |

---

## Accessibility

- All buttons have keyboard shortcuts
- Tab navigation through UI elements
- High contrast mode option
- Scalable UI (75%, 100%, 125%, 150%)
- Screen reader labels on interactive elements
- Color-blind friendly overlay palettes

---

## See Also

- [build-toolbar.md](./build-toolbar.md) - Build menu details
- [sidebars.md](./sidebars.md) - Sidebar behavior
- [info-panels.md](./info-panels.md) - Panel specifications
- [controls.md](./controls.md) - Keyboard shortcuts
