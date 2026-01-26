# User Interface

[← Back to Documentation](../README.md)

---

## Overview

The UI provides players with everything they need to understand, monitor, and control their arcology. Design principles: clarity, minimal viewport obstruction, and data-rich feedback.

---

## Contents

### Layout & Structure

| Topic | Description | Link |
|-------|-------------|------|
| **HUD Layout** | Screen regions, element positioning | [hud-layout.md](./hud-layout.md) |
| **Sidebars** | Floating menus, overlay toggles | [sidebars.md](./sidebars.md) |

### Building & Tools

| Topic | Description | Link |
|-------|-------------|------|
| **Build Toolbar** | Block picker, categories, placement | [build-toolbar.md](./build-toolbar.md) |
| **Controls** | Keyboard & mouse reference | [controls.md](./controls.md) |

### Information Display

| Topic | Description | Link |
|-------|-------------|------|
| **Info Panels** | Block, resident, budget, AEI panels | [info-panels.md](./info-panels.md) |
| **Overlays** | Data visualization layers | [overlays.md](./overlays.md) |
| **Views** | Camera modes and perspectives | [views.md](./views.md) |

### Menus & Narrative

| Topic | Description | Link |
|-------|-------------|------|
| **Menus** | Main menu, pause, settings, save/load | [menus.md](./menus.md) |
| **Narrative** | News feed, stories, complaints | [narrative.md](./narrative.md) |

---

## Quick Reference

### Screen Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  TOP BAR: Menu | Resources | Date/Time | Speed | Notifications  │
├───────┬─────────────────────────────────────────────────┬───────┤
│ LEFT  │                                                 │ RIGHT │
│ SIDE  │              GAME VIEWPORT                      │ PANEL │
│ BAR   │                                                 │       │
├───────┴─────────────────────────────────────────────────┴───────┤
│  BOTTOM BAR: Build Toolbar | Floor Nav | View Mode | Overlays   │
└─────────────────────────────────────────────────────────────────┘
```

### Main UI Elements

| Element | Purpose | Key |
|---------|---------|-----|
| Floor Navigator | Switch viewing level | PgUp/PgDn |
| Build Toolbar | Select blocks to place | B, then 1-7 |
| Info Panel | Block/resident details | I |
| Budget Panel | Financial overview | $ |
| AEI Dashboard | Win condition progress | Y |
| Time Controls | Pause, speed | Space, 1-3 |
| Overlays | Toggle info layers | F1-F8 |
| News Feed | Events and stories | N |

### Essential Shortcuts

| Action | Key |
|--------|-----|
| Pause | Space |
| Select Tool | Q |
| Build Mode | B |
| Demolish | X |
| Undo | Ctrl+Z |
| Quick Save | Ctrl+S |
| Escape/Cancel | Esc |

---

## Design Principles

1. **Clarity First** - Information should be immediately understandable
2. **Minimal Obstruction** - Maximize viewport visibility
3. **Progressive Disclosure** - Details on demand, not all at once
4. **Consistent Feedback** - Every action has visible response
5. **Accessible** - Colorblind modes, scalable UI, rebindable keys

---

## See Also

- [../architecture/milestones/milestone-10-overlays.md](../architecture/milestones/milestone-10-overlays.md) - Overlay implementation
- [../game-design/](../game-design/) - What the UI displays
- [../quick-reference/](../quick-reference/) - Formulas and conventions
