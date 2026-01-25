# Overlays

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Toggle overlays to see specific systems visualized on the map.

---

## Available Overlays

| Overlay | Visualization | Keyboard |
|---------|---------------|----------|
| None | Normal view | 1 |
| Light | Yellow (bright) → Blue (dark) | 2 |
| Air Quality | Green (good) → Brown (bad) | 3 |
| Noise | Quiet (none) → Red waves (loud) | 4 |
| Safety/Crime | Green (safe) → Red (dangerous) | 5 |
| Vibes | Sparkle intensity | 6 |
| Connectivity | Green (connected) → Red (not) | 7 |
| Block Type | Color by category | 8 |
| Foot Traffic | Heatmap | 9 |

---

## Light Overlay

Shows effective light level:

```
100% light: Bright yellow
50% light:  Muted yellow
25% light:  Gray-blue
0% light:   Dark blue
```

Helps identify:
- Dark interiors needing light pipes
- Subterranean challenges
- Atrium effectiveness

---

## Air Quality Overlay

Shows air quality:

```
100% air: Fresh green
70% air:  Light green
40% air:  Yellow-brown
0% air:   Dark brown
```

Helps identify:
- HVAC coverage gaps
- Industrial pollution
- Ventilation needs

---

## Noise Overlay

Shows noise levels:

```
Quiet (0-20):     No indicator
Moderate (20-40): Light waves
Loud (40-60):     Orange waves
Very Loud (60+):  Red waves
```

Helps identify:
- Traffic noise from corridors
- Industrial/entertainment noise
- Residential quiet zones

---

## Safety Overlay

Shows crime/safety:

```
Safe (80-100):    Bright green
Moderate (50-80): Yellow-green
Risky (30-50):    Orange
Dangerous (0-30): Red
```

Helps identify:
- Security coverage gaps
- Dark/unsafe areas
- Crime propagation paths

---

## Vibes Overlay

Shows composite quality:

```
High vibes:   Bright sparkle/glow
Medium vibes: Moderate glow
Low vibes:    Dim
Very low:     Gray/dark
```

Helps identify:
- Premium areas for housing
- Areas needing improvement
- Green space effectiveness

---

## Connectivity Overlay

Shows path to entrance:

```
Connected:     Green
Not connected: Red
```

Helps identify:
- Disconnected blocks (no income)
- Missing corridors
- Dead-end areas

---

## Block Type Overlay

Colors by category:

| Category | Color |
|----------|-------|
| Residential | Blue |
| Commercial | Green |
| Industrial | Orange |
| Transit | Gray |
| Green | Dark Green |
| Civic | Purple |

Helps identify:
- Zone distribution
- Mixed-use areas
- Missing categories

---

## Foot Traffic Overlay

Heatmap of movement:

```
High traffic: Bright red/yellow
Medium:       Orange
Low:          Cool blue
None:         Gray
```

Helps identify:
- Main arteries
- Dead zones
- Commercial location quality

---

## Implementation

```gdscript
func show_overlay(type: OverlayType) -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var value = get_overlay_value(type, block)
        block.sprite.modulate = value_to_color(type, value)

func hide_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        block.sprite.modulate = Color.WHITE
```

---

## See Also

- [views.md](./views.md) - Display modes
- [../game-design/environment/](../game-design/environment/) - What overlays show
- [../architecture/milestones/milestone-10-overlays.md](../architecture/milestones/milestone-10-overlays.md) - Implementation
