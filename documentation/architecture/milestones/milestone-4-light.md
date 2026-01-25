# Milestone 4: Environment - Light

**Goal:** Blocks have light levels, affects gameplay

---

## Features

### Light System
- Exterior faces get natural light (100%)
- Light decreases with distance from exterior
- Top floor = full light
- Each floor down = -20% (simple version)

### Visual
- Light overlay (yellow gradient)
- Dark blocks visually dimmer

### Gameplay Hook
- Residential shows "Light: 80%" in tooltip
- (No consequences yet, just display)

---

## Deliverable

Build down, see it get darker. Toggle light overlay.

---

## Light Sources

| Source | Quality | Notes |
|--------|---------|-------|
| Direct Sky (roof/top floor) | 100% | Only at top surface |
| Exterior Window | 70-90% | Penetrates 1-2 blocks deep |
| Atrium (mega-block void) | 80-85% | Carries light to interior-facing blocks |

## Simple Implementation

For Milestone 4, use a simplified model:

```gdscript
class_name LightSystem
extends Node

const LIGHT_FALLOFF_PER_FLOOR: int = 20

func calculate_light(pos: Vector3i) -> int:
    var block = Grid.get_block(pos)
    if not block:
        return 0

    # Check if top floor (nothing above)
    var above = pos + Vector3i(0, 0, 1)
    if not Grid.get_block(above):
        return 100  # Direct sky

    # Check exterior faces
    var exterior_light = check_exterior_light(pos)
    if exterior_light > 0:
        return exterior_light

    # Interior - calculate based on distance from top
    var top_z = find_highest_floor()
    var depth = top_z - pos.z
    return max(0, 100 - (depth * LIGHT_FALLOFF_PER_FLOOR))

func check_exterior_light(pos: Vector3i) -> int:
    # Check if any adjacent face is exterior (not blocked)
    var directions = [
        Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
        Vector3i(0, 1, 0), Vector3i(0, -1, 0),
    ]

    for dir in directions:
        var adjacent = pos + dir
        if not Grid.get_block(adjacent):
            # This face is exterior - gets window light
            return 80  # Window light
    return 0  # Interior
```

---

## Light Overlay

```gdscript
func show_light_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var light = calculate_light(pos)

        # Yellow gradient based on light level
        var yellow = Color(1, 1, 0.5)  # Bright
        var dark = Color(0.2, 0.2, 0.3)  # Dark
        block.sprite.modulate = dark.lerp(yellow, light / 100.0)

func hide_light_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        block.sprite.modulate = Color.WHITE
```

---

## Block Light Storage

```gdscript
# In Block class
var environment: Dictionary = {
    "light": 0,
    "air": 0,
    "noise": 0,
    "safety": 0,
    "vibes": 0
}
```

---

## Recalculation Triggers

```gdscript
func _ready():
    Grid.block_placed.connect(_on_grid_changed)
    Grid.block_removed.connect(_on_grid_changed)

func _on_grid_changed(_block: Block) -> void:
    # Recalculate light for affected area
    recalculate_all_light()

func recalculate_all_light() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        block.environment.light = calculate_light(pos)
```

---

## UI: Light Tooltip

```gdscript
func show_block_info(block: Block) -> void:
    info_label.text = """
    %s
    Light: %d%%
    """ % [block.display_name, block.environment.light]
```

---

## Acceptance Criteria

- [ ] Top floor blocks have 100% light
- [ ] Interior blocks have reduced light
- [ ] Exterior-facing blocks get window light
- [ ] Light decreases with depth
- [ ] Light overlay toggle shows gradient
- [ ] Block tooltip shows light percentage
- [ ] Light recalculates on block changes
- [ ] Darker blocks visually appear dimmer
