# Milestone 9: Multiple Block Types

**Goal:** Flesh out the block catalog

---

## New Blocks

| Block | Category | Notes |
|-------|----------|-------|
| Industrial | industrial | Cheap, generates jobs, noise |
| Office | commercial | Mid-tier, needs light |
| Restaurant | commercial | Needs foot traffic |
| Grocery | commercial | Provides food access radius |
| Park/Garden | green | Provides vibes |

## Block Properties

Each block type has: needs, produces, effects

---

## Deliverable

Build a diverse structure. See blocks succeed or fail based on environment.

---

## Implementation

### data/blocks.json Additions

```json
{
  "industrial_basic": {
    "name": "Light Industrial",
    "size": [1, 1, 1],
    "cost": 300,
    "category": "industrial",
    "traversable": false,
    "needs": {
      "power": 20,
      "path": true
    },
    "produces": {
      "jobs": 8,
      "revenue": 150,
      "noise": 40
    },
    "tolerates": {
      "light_min": 10
    },
    "sprite": "res://assets/sprites/blocks/industrial.png"
  },

  "office_basic": {
    "name": "Office Suite",
    "size": [1, 1, 1],
    "cost": 600,
    "category": "commercial",
    "traversable": false,
    "needs": {
      "power": 10,
      "light_min": 50,
      "path": true
    },
    "produces": {
      "jobs": 10,
      "revenue": 200
    },
    "sprite": "res://assets/sprites/blocks/office.png"
  },

  "restaurant": {
    "name": "Restaurant",
    "size": [1, 1, 1],
    "cost": 400,
    "category": "commercial",
    "traversable": false,
    "needs": {
      "power": 5,
      "light_min": 40,
      "path": true,
      "foot_traffic_min": 20
    },
    "produces": {
      "jobs": 4,
      "revenue": 180,
      "food_service": true,
      "vibes": 5
    },
    "sprite": "res://assets/sprites/blocks/restaurant.png"
  },

  "grocery": {
    "name": "Grocery Store",
    "size": [2, 2, 1],
    "cost": 1200,
    "category": "commercial",
    "traversable": false,
    "needs": {
      "power": 15,
      "light_min": 40,
      "path": true
    },
    "produces": {
      "jobs": 12,
      "revenue": 300,
      "food_access_radius": 10
    },
    "sprite": "res://assets/sprites/blocks/grocery.png"
  },

  "park_small": {
    "name": "Small Garden",
    "size": [1, 1, 1],
    "cost": 200,
    "category": "green",
    "traversable": true,
    "needs": {
      "light_min": 50,
      "water": 5
    },
    "produces": {
      "vibes": 15,
      "air_quality": 10,
      "noise_reduction": 5
    },
    "sprite": "res://assets/sprites/blocks/garden.png"
  }
}
```

### Block Status System

```gdscript
enum BlockStatus {
    FUNCTIONING,
    DEGRADED,
    FAILING
}

func evaluate_block_status(block: Block) -> BlockStatus:
    var definition = BlockRegistry.get_definition(block.block_type)
    var needs = definition.get("needs", {})

    # Check each need
    if needs.has("light_min"):
        if block.environment.light < needs.light_min:
            return BlockStatus.FAILING

    if needs.has("path") and not block.connected:
        return BlockStatus.FAILING

    if needs.has("foot_traffic_min"):
        if block.foot_traffic < needs.foot_traffic_min:
            return BlockStatus.DEGRADED

    return BlockStatus.FUNCTIONING
```

### Block Effects Application

```gdscript
func apply_block_effects() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        var definition = BlockRegistry.get_definition(block.block_type)
        var produces = definition.get("produces", {})

        if block.status == BlockStatus.FAILING:
            continue  # Failing blocks don't produce

        # Apply vibes to neighbors
        if produces.has("vibes"):
            apply_vibes_to_area(pos, produces.vibes)

        # Apply noise to neighbors
        if produces.has("noise"):
            apply_noise_to_area(pos, produces.noise)

        # Food access radius
        if produces.has("food_access_radius"):
            apply_food_access(pos, produces.food_access_radius)
```

---

## Visual Feedback

```gdscript
func update_block_visual(block: Block) -> void:
    match block.status:
        BlockStatus.FUNCTIONING:
            block.status_icon.visible = false
        BlockStatus.DEGRADED:
            block.status_icon.texture = preload("res://assets/ui/warning.png")
            block.status_icon.visible = true
        BlockStatus.FAILING:
            block.status_icon.texture = preload("res://assets/ui/error.png")
            block.status_icon.visible = true
```

---

## Block Picker UI

```
┌─────────────────────────────────────────┐
│ [Residential ▼]                         │
│ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │Basic│ │Prem │ │Family│               │
│ └─────┘ └─────┘ └─────┘                │
│                                         │
│ [Commercial ▼]                          │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐       │
│ │Shop │ │Office│ │Rest │ │Grocer│      │
│ └─────┘ └─────┘ └─────┘ └─────┘       │
└─────────────────────────────────────────┘
```

---

## Acceptance Criteria

- [ ] Industrial block works (low light tolerance)
- [ ] Office needs light > 50%
- [ ] Restaurant needs foot traffic
- [ ] Grocery provides food access radius
- [ ] Park provides vibes to area
- [ ] Blocks show status icons (functioning/degraded/failing)
- [ ] Block picker organized by category
- [ ] Block tooltip shows needs and status
- [ ] Revenue only generated when functioning
