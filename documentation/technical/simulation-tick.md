# Simulation Tick Architecture

[← Back to Technical](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Different systems update at different frequencies for performance and gameplay.

---

## Update Frequencies

| System | Frequency | Notes |
|--------|-----------|-------|
| Rendering | Every frame | Visual only |
| Input | Every frame | Responsive |
| Environment | Hourly tick | Light, air, noise, safety |
| Foot Traffic | Hourly tick | Based on time-of-day |
| Tenant Decisions | Daily tick | Move in/out, happiness |
| Agent Full Sim | Daily tick | Notable residents only |
| Economy | Monthly tick | Rent collection, expenses |
| Population | Monthly tick | Births, deaths, migration |

---

## Game Clock

```gdscript
const SECONDS_PER_HOUR = 2.0  # Real seconds per game hour

var game_time = {
    hour: 8,
    day: 1,
    month: 1,
    year: 1
}

signal hour_tick
signal day_tick
signal month_tick

func _process(delta):
    if speed == PAUSED:
        return

    accumulator += delta * speed_multiplier

    if accumulator >= SECONDS_PER_HOUR:
        accumulator -= SECONDS_PER_HOUR
        advance_hour()

func advance_hour():
    game_time.hour += 1
    hour_tick.emit()

    if game_time.hour >= 24:
        game_time.hour = 0
        advance_day()

func advance_day():
    game_time.day += 1
    day_tick.emit()

    if game_time.day > 30:
        game_time.day = 1
        advance_month()

func advance_month():
    game_time.month += 1
    month_tick.emit()
```

---

## System Connections

```gdscript
func _ready():
    GameClock.hour_tick.connect(_on_hour)
    GameClock.day_tick.connect(_on_day)
    GameClock.month_tick.connect(_on_month)

func _on_hour():
    LightSystem.update()
    AirSystem.update()
    NoiseSystem.update()
    TrafficSystem.update()

func _on_day():
    for resident in notable_residents:
        resident.daily_update()
    PopulationManager.process_move_ins()
    PopulationManager.process_move_outs()

func _on_month():
    Economy.collect_rent()
    Economy.pay_expenses()
    Population.update_demographics()
    Entropy.apply_decay()
```

---

## Agent Update Batching

Not all agents update simultaneously:

```gdscript
const AGENTS_PER_FRAME = 50

var _agent_index = 0

func _process(_delta):
    # Update subset each frame
    var count = 0
    while count < AGENTS_PER_FRAME and _agent_index < agents.size():
        agents[_agent_index].tick()
        _agent_index += 1
        count += 1

    if _agent_index >= agents.size():
        _agent_index = 0  # Wrap around
```

---

## Spatial Partitioning

Only simulate visible areas in detail:

```gdscript
func update_agents():
    var camera_pos: Vector3 = camera.global_position
    var max_detail_dist: float = 500.0

    for agent in agents:
        var dist := camera_pos.distance_to(agent.world_position)
        if dist < max_detail_dist:
            agent.full_update()  # Detailed
        else:
            agent.statistical_update()  # Simplified
```

---

## Lazy Recalculation

Environment doesn't recalculate every frame:

```gdscript
var _dirty = false
var _dirty_positions = []

func mark_dirty(pos: Vector3i):
    _dirty = true
    _dirty_positions.append(pos)

func _on_hour():
    if _dirty:
        recalculate_dirty()
        _dirty = false
        _dirty_positions.clear()
```

---

## Notable vs Background

| Agent Type | Population | Simulation |
|------------|------------|------------|
| Notable | 100-500 | Full: needs, relationships, stories |
| Background | Rest | Statistical: aggregates only |

```gdscript
func promote_to_notable(agent):
    # When background agent becomes interesting
    notable_agents.append(agent)
    background_count -= 1

func demote_to_background(agent):
    # When notable is no longer interesting
    notable_agents.erase(agent)
    background_count += 1
```

---

## See Also

- [data-model.md](./data-model.md) - Data structures
- [../architecture/performance.md](../architecture/performance.md) - Optimization strategies
- [../architecture/milestones/milestone-6-time-simulation.md](../architecture/milestones/milestone-6-time-simulation.md) - Implementation
