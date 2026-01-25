# Milestone 2: Floor Navigation

**Goal:** Multiple floors, can switch between viewing them

---

## Features

- Floor selector UI (up/down buttons, floor indicator)
- Show current floor + 1-2 floors below (transparency)
- Hide floors above current view
- Blocks can be placed on any floor

### Camera
- Floor切り替え animates smoothly
- Optional: slice view (show cross-section)

---

## Deliverable

You can build a 5-story structure and navigate between floors.

---

## Implementation

### Floor Visibility

```gdscript
class_name FloorManager
extends Node

var current_floor: int = 0
var floors_below_visible: int = 2

func set_current_floor(floor: int) -> void:
    current_floor = floor
    update_visibility()

func update_visibility() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        if pos.z > current_floor:
            # Above current floor - hide
            block.sprite.visible = false
        elif pos.z == current_floor:
            # Current floor - full opacity
            block.sprite.visible = true
            block.sprite.modulate.a = 1.0
        elif pos.z >= current_floor - floors_below_visible:
            # Below but within visible range - fade
            block.sprite.visible = true
            var depth = current_floor - pos.z
            block.sprite.modulate.a = 1.0 - (depth * 0.3)
        else:
            # Too far below - hide
            block.sprite.visible = false
```

### Floor UI

```gdscript
# UI showing current floor and controls
func _on_up_pressed() -> void:
    FloorManager.set_current_floor(FloorManager.current_floor + 1)

func _on_down_pressed() -> void:
    FloorManager.set_current_floor(FloorManager.current_floor - 1)

func _process(_delta) -> void:
    floor_label.text = "Floor: %d" % FloorManager.current_floor
```

### Placement on Current Floor

When placing blocks, use `current_floor` as the Z coordinate:

```gdscript
func _on_click(screen_pos: Vector2) -> void:
    var grid_pos = Grid.screen_to_grid(screen_pos, FloorManager.current_floor)
    place_block(grid_pos)
```

---

## UI Layout

```
┌─────────────────────────────────┐
│ Floor: 3                [▲][▼]  │
├─────────────────────────────────┤
│                                 │
│         (game view)             │
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

## Acceptance Criteria

- [ ] Floor indicator shows current floor number
- [ ] Up/down buttons change current floor
- [ ] Floors above current are hidden
- [ ] Current floor is fully visible
- [ ] 1-2 floors below are visible with transparency
- [ ] Block placement uses current floor for Z
- [ ] Can build 5+ story structure
- [ ] Floor change animates smoothly (optional)
