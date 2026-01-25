# Milestone 7: Simple Residents

**Goal:** People exist and live in residential blocks

---

## Features

### Residents
- Each residential block has occupancy (0-4 people)
- Residents have names (generated)
- Residents have satisfaction (0-100)

### Population
- New residents move in if vacancy exists
- Residents leave if satisfaction too low
- Population counter

### Satisfaction (Simple)
- Based on light level only
- Light > 60% = satisfied
- Light < 40% = unhappy

### UI
- Population counter
- Click block to see residents
- Simple resident list

---

## Deliverable

Build residential, people move in. Build underground, people are unhappy and leave.

---

## Implementation

### Resident Class

```gdscript
class_name Resident
extends RefCounted

var id: int
var name: String
var home: Vector3i  # Block position
var satisfaction: int = 50

static var _next_id: int = 0
static var _first_names: Array = ["Alex", "Maria", "David", "Sarah", "James", "Emma"]
static var _last_names: Array = ["Chen", "Kim", "Garcia", "Singh", "Johnson", "Park"]

func _init(home_pos: Vector3i):
    id = _next_id
    _next_id += 1
    home = home_pos
    name = generate_name()

static func generate_name() -> String:
    var first = _first_names[randi() % _first_names.size()]
    var last = _last_names[randi() % _last_names.size()]
    return "%s %s" % [first, last]
```

### Population Manager

```gdscript
class_name PopulationManager
extends Node

signal resident_moved_in(resident: Resident)
signal resident_moved_out(resident: Resident)

var residents: Dictionary = {}  # id -> Resident
var population: int = 0

func _ready():
    GameClock.day_tick.connect(_on_day_tick)

func _on_day_tick() -> void:
    process_move_ins()
    process_move_outs()
    update_satisfaction()

func process_move_ins() -> void:
    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        if block.category != "residential":
            continue
        if not block.connected:
            continue

        var vacancy = block.capacity - block.occupants.size()
        if vacancy > 0 and should_someone_move_in(block):
            var resident = Resident.new(pos)
            add_resident(resident, block)

func should_someone_move_in(block: Block) -> bool:
    # Simple: 20% chance per day per vacancy if light > 30%
    return block.environment.light > 30 and randf() < 0.2

func add_resident(resident: Resident, block: Block) -> void:
    residents[resident.id] = resident
    block.occupants.append(resident)
    population += 1
    resident_moved_in.emit(resident)

func process_move_outs() -> void:
    for resident in residents.values():
        if resident.satisfaction < 20:
            if randf() < 0.3:  # 30% chance to leave when very unhappy
                remove_resident(resident)

func remove_resident(resident: Resident) -> void:
    var block = Grid.get_block(resident.home)
    if block:
        block.occupants.erase(resident)
    residents.erase(resident.id)
    population -= 1
    resident_moved_out.emit(resident)

func update_satisfaction() -> void:
    for resident in residents.values():
        var block = Grid.get_block(resident.home)
        if not block:
            continue

        var light = block.environment.light

        # Satisfaction moves toward target based on light
        var target_satisfaction: int
        if light >= 60:
            target_satisfaction = 80
        elif light >= 40:
            target_satisfaction = 50
        else:
            target_satisfaction = 20

        # Gradual change
        if resident.satisfaction < target_satisfaction:
            resident.satisfaction += 5
        elif resident.satisfaction > target_satisfaction:
            resident.satisfaction -= 5

        resident.satisfaction = clamp(resident.satisfaction, 0, 100)
```

### Block Occupancy

```gdscript
# In Block class
var capacity: int = 0
var occupants: Array[Resident] = []

func is_full() -> bool:
    return occupants.size() >= capacity
```

---

## UI: Population Display

```
┌─────────────────────────────────────────┐
│ Population: 47                          │
└─────────────────────────────────────────┘
```

### Block Info Panel

```gdscript
func show_residential_info(block: Block) -> void:
    var text = "%s\n" % block.display_name
    text += "Light: %d%%\n" % block.environment.light
    text += "Occupancy: %d/%d\n\n" % [block.occupants.size(), block.capacity]

    if block.occupants.size() > 0:
        text += "Residents:\n"
        for resident in block.occupants:
            var mood = "😊" if resident.satisfaction > 60 else ("😐" if resident.satisfaction > 30 else "😢")
            text += "  %s %s\n" % [mood, resident.name]

    info_panel.text = text
```

---

## Acceptance Criteria

- [ ] Residents have names
- [ ] Residents track satisfaction (0-100)
- [ ] Residential blocks have capacity
- [ ] Residents move into connected residential
- [ ] Move-in rate affected by light level
- [ ] Satisfaction based on light level
- [ ] Unhappy residents leave
- [ ] Population counter displays correctly
- [ ] Click block shows resident list
- [ ] Mood indicators show satisfaction level
