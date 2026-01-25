# Milestone 10: Overlays & Info

**Goal:** Player can see what's happening

---

## Features

### Overlays
- Light (yellow gradient)
- Connectivity (green = connected, red = not)
- Block type (color by category)

### Info Panel
- Click block to see details
- Shows: type, light, connected, occupancy, revenue

### Budget Panel
- Monthly breakdown
- Income by source
- Expenses by category

---

## Deliverable

Toggle overlays. Click for info. Understand your arcology.

---

## Implementation

### Overlay Manager

```gdscript
class_name OverlayManager
extends Node

enum OverlayType {
    NONE,
    LIGHT,
    CONNECTIVITY,
    BLOCK_TYPE
}

var current_overlay: OverlayType = OverlayType.NONE

func set_overlay(type: OverlayType) -> void:
    current_overlay = type
    refresh_overlay()

func refresh_overlay() -> void:
    match current_overlay:
        OverlayType.NONE:
            clear_overlay()
        OverlayType.LIGHT:
            show_light_overlay()
        OverlayType.CONNECTIVITY:
            show_connectivity_overlay()
        OverlayType.BLOCK_TYPE:
            show_type_overlay()

func clear_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        block.sprite.modulate = Color.WHITE

func show_light_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var light = block.environment.light / 100.0

        # Yellow gradient: dark blue -> bright yellow
        var dark = Color(0.2, 0.2, 0.4)
        var bright = Color(1.0, 1.0, 0.5)
        block.sprite.modulate = dark.lerp(bright, light)

func show_connectivity_overlay() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        if block.connected:
            block.sprite.modulate = Color(0.5, 1.0, 0.5)  # Green
        else:
            block.sprite.modulate = Color(1.0, 0.5, 0.5)  # Red

func show_type_overlay() -> void:
    var colors = {
        "residential": Color(0.5, 0.5, 1.0),  # Blue
        "commercial": Color(0.5, 1.0, 0.5),   # Green
        "industrial": Color(1.0, 0.8, 0.3),   # Orange
        "transit": Color(0.8, 0.8, 0.8),      # Gray
        "green": Color(0.3, 0.8, 0.3),        # Dark green
        "civic": Color(1.0, 0.5, 1.0),        # Purple
    }

    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var definition = BlockRegistry.get_definition(block.block_type)
        var category = definition.get("category", "other")
        block.sprite.modulate = colors.get(category, Color.WHITE)
```

### Overlay UI

```
┌─────────────────────────────────────────┐
│ Overlays: [None][Light][Connect][Type]  │
└─────────────────────────────────────────┘
```

```gdscript
func _on_none_pressed() -> void:
    OverlayManager.set_overlay(OverlayManager.OverlayType.NONE)

func _on_light_pressed() -> void:
    OverlayManager.set_overlay(OverlayManager.OverlayType.LIGHT)

func _on_connectivity_pressed() -> void:
    OverlayManager.set_overlay(OverlayManager.OverlayType.CONNECTIVITY)

func _on_type_pressed() -> void:
    OverlayManager.set_overlay(OverlayManager.OverlayType.BLOCK_TYPE)
```

### Block Info Panel

```gdscript
func show_block_info(block: Block) -> void:
    var definition = BlockRegistry.get_definition(block.block_type)

    var text = "=== %s ===\n\n" % definition.name

    # Basic info
    text += "Category: %s\n" % definition.category
    text += "Position: (%d, %d, %d)\n\n" % [
        block.grid_position.x,
        block.grid_position.y,
        block.grid_position.z
    ]

    # Environment
    text += "--- Environment ---\n"
    text += "Light: %d%%\n" % block.environment.light
    text += "Connected: %s\n\n" % ("Yes" if block.connected else "No")

    # Occupancy (if residential)
    if definition.category == "residential":
        text += "--- Occupancy ---\n"
        text += "%d / %d residents\n\n" % [
            block.occupants.size(),
            definition.get("capacity", 0)
        ]

    # Economics
    if block.status == BlockStatus.FUNCTIONING:
        var revenue = definition.get("produces", {}).get("revenue", 0)
        text += "--- Economics ---\n"
        text += "Revenue: $%d/month\n" % revenue
    else:
        text += "Status: %s\n" % BlockStatus.keys()[block.status]

    info_panel.text = text
```

### Budget Panel

```gdscript
func show_budget_panel() -> void:
    # Calculate income by source
    var residential_income = 0
    var commercial_income = 0
    var industrial_income = 0

    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        if block.status != BlockStatus.FUNCTIONING:
            continue

        var definition = BlockRegistry.get_definition(block.block_type)
        var revenue = definition.get("produces", {}).get("revenue", 0)

        match definition.category:
            "residential":
                residential_income += calculate_rent(block)
            "commercial":
                commercial_income += revenue
            "industrial":
                industrial_income += revenue

    var total_income = residential_income + commercial_income + industrial_income

    # Calculate expenses
    var maintenance = calculate_total_maintenance()
    var utilities = calculate_utilities()
    var total_expenses = maintenance + utilities

    # Display
    var text = """
=== MONTHLY BUDGET ===

INCOME
  Residential: $%d
  Commercial:  $%d
  Industrial:  $%d
  -----------
  Total:       $%d

EXPENSES
  Maintenance: $%d
  Utilities:   $%d
  -----------
  Total:       $%d

NET: $%d
""" % [
        residential_income, commercial_income, industrial_income, total_income,
        maintenance, utilities, total_expenses,
        total_income - total_expenses
    ]

    budget_panel.text = text
```

### Budget Panel UI Layout

```
┌─────────────────────────────────────────┐
│ === MONTHLY BUDGET ===                  │
│                                         │
│ INCOME                                  │
│   Residential: $2,400                   │
│   Commercial:  $1,800                   │
│   Industrial:  $600                     │
│   -----------                           │
│   Total:       $4,800                   │
│                                         │
│ EXPENSES                                │
│   Maintenance: $500                     │
│   Utilities:   $300                     │
│   -----------                           │
│   Total:       $800                     │
│                                         │
│ NET: +$4,000                            │
└─────────────────────────────────────────┘
```

---

## Keyboard Shortcuts

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_1:
                OverlayManager.set_overlay(OverlayManager.OverlayType.NONE)
            KEY_2:
                OverlayManager.set_overlay(OverlayManager.OverlayType.LIGHT)
            KEY_3:
                OverlayManager.set_overlay(OverlayManager.OverlayType.CONNECTIVITY)
            KEY_4:
                OverlayManager.set_overlay(OverlayManager.OverlayType.BLOCK_TYPE)
            KEY_B:
                toggle_budget_panel()
```

---

## Acceptance Criteria

- [ ] Light overlay shows gradient from dark to bright
- [ ] Connectivity overlay shows green/red for connected/not
- [ ] Block type overlay colors by category
- [ ] Overlay buttons toggle display
- [ ] Keyboard shortcuts (1-4) switch overlays
- [ ] Click block shows info panel
- [ ] Info panel shows all relevant block data
- [ ] Budget panel shows income breakdown
- [ ] Budget panel shows expense breakdown
- [ ] Net profit/loss displayed clearly

---

## After Milestone 10

**Congratulations! You have a playable city builder.**

The game now has:
- Block placement on 3D grid
- Multiple floors with navigation
- Connectivity system
- Light environment system
- Economy with rent/revenue
- Time simulation
- Residents with satisfaction
- Pathfinding and commutes
- Diverse block types
- Information overlays

Continue to milestones 11-22 for depth features.
