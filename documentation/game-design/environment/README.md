# Environment Systems

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Environment systems calculate quality-of-life values for every block. These affect rent, satisfaction, and gameplay.

---

## The Five Environment Properties

| Property | Range | Affects |
|----------|-------|---------|
| [Light](./light-system.md) | 0-100 | Desirability, mood, plants |
| [Air](./air-system.md) | 0-100 | Health, comfort |
| [Noise](./noise-system.md) | 0-100 | Sleep, concentration, stress |
| [Safety](./safety-system.md) | 0-100 | Security needs, rent |
| [Vibes](./vibes-system.md) | 0-100 | Composite desirability |
| [Terrain](./terrain.md) | N/A | Base map layer (decorative) |

---

## How Environment Works

### Per-Block Calculation

Every block caches its environment values:

```gdscript
block.environment = {
    "light": 75,
    "air": 80,
    "noise": 25,
    "safety": 90,
    "vibes": 72
}
```

### Recalculation Triggers

Environment recalculates when:
- Block placed or removed
- Infrastructure changes
- Periodic update (hourly)

### Propagation

Values spread from sources:

```
Source → Falloff → Received Value

Light: Sky/windows → -20%/floor → Interior light
Air: HVAC/exterior → -10%/block → Interior air
Noise: Corridors/machines → -15dB/block → Nearby blocks
Safety: Security → -5%/block → Coverage area
```

---

## Quick Links

| System | Source | Calculation |
|--------|--------|-------------|
| [Light](./light-system.md) | Sky, windows, pipes | Depth from exterior |
| [Air](./air-system.md) | HVAC, exterior | Coverage radius |
| [Noise](./noise-system.md) | Traffic, machines | Propagation with walls |
| [Safety](./safety-system.md) | Security stations | Crime suppression |
| [Vibes](./vibes-system.md) | Composite | Weighted average |

---

## Environment Overlay

Toggle overlays to visualize:

| Overlay | Color Scheme |
|---------|--------------|
| Light | Yellow (bright) → Blue (dark) |
| Air | Green (fresh) → Brown (stale) |
| Noise | Quiet (none) → Red waves (loud) |
| Safety | Green (safe) → Red (dangerous) |
| Vibes | Sparkle intensity |

See [../../ui/overlays.md](../../ui/overlays.md) for implementation.

---

## Subterranean Penalties

All environment values suffer below grade:

| Depth | Light | Air | Vibes | Crime |
|-------|-------|-----|-------|-------|
| Z = -1 | -20% | -10% | -25 | +15% |
| Z = -2 | -40% | -20% | -35 | +20% |
| Z = -3 | -60% | -30% | -45 | +25% |

See [../../quick-reference/formulas.md](../../quick-reference/formulas.md#subterranean-penalties) for exact formulas.

---

## See Also

- [../blocks/](../blocks/) - Block needs and produces
- [../economy/rent.md](../economy/rent.md) - How environment affects rent
- [../human-simulation/needs.md](../human-simulation/needs.md) - How environment affects residents
- [../../architecture/milestones/milestone-4-light.md](../../architecture/milestones/milestone-4-light.md) - Light implementation
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - All formulas
