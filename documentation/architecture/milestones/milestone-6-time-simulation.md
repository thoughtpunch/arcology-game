# Milestone 6: Time & Simulation Tick

**Goal:** Game has time, things happen over time

---

## Features

### Game Clock
- Pause / 1x / 2x / 3x speed
- Day/night cycle (visual only for now)
- Monthly tick (rent collection)

### Tick Architecture
- Hourly tick: light updates
- Daily tick: (placeholder)
- Monthly tick: economy

### UI
- Time display (Day X, Month Y)
- Speed controls
- Pause

---

## Deliverable

Watch time pass. See monthly rent deposits. Pause and resume.

---

## Implementation

### Game Clock

```gdscript
class_name GameClock
extends Node

signal hour_tick
signal day_tick
signal month_tick

enum Speed { PAUSED, NORMAL, FAST, FASTER }

var current_speed: Speed = Speed.NORMAL
var game_time: Dictionary = {
    "hour": 8,
    "day": 1,
    "month": 1,
    "year": 1
}

const SPEED_MULTIPLIERS = {
    Speed.PAUSED: 0.0,
    Speed.NORMAL: 1.0,
    Speed.FAST: 2.0,
    Speed.FASTER: 3.0
}

const SECONDS_PER_HOUR: float = 2.0  # Real seconds per game hour

var _hour_accumulator: float = 0.0

func _process(delta: float) -> void:
    if current_speed == Speed.PAUSED:
        return

    _hour_accumulator += delta * SPEED_MULTIPLIERS[current_speed]

    if _hour_accumulator >= SECONDS_PER_HOUR:
        _hour_accumulator -= SECONDS_PER_HOUR
        advance_hour()

func advance_hour() -> void:
    game_time.hour += 1
    hour_tick.emit()

    if game_time.hour >= 24:
        game_time.hour = 0
        advance_day()

func advance_day() -> void:
    game_time.day += 1
    day_tick.emit()

    if game_time.day > 30:  # Simplified: 30 days/month
        game_time.day = 1
        advance_month()

func advance_month() -> void:
    game_time.month += 1
    month_tick.emit()

    if game_time.month > 12:
        game_time.month = 1
        game_time.year += 1
```

### Speed Controls

```gdscript
func set_speed(speed: Speed) -> void:
    current_speed = speed

func pause() -> void:
    set_speed(Speed.PAUSED)

func resume() -> void:
    set_speed(Speed.NORMAL)

func toggle_pause() -> void:
    if current_speed == Speed.PAUSED:
        resume()
    else:
        pause()
```

### System Connections

```gdscript
# In main.gd or game_manager.gd
func _ready() -> void:
    GameClock.hour_tick.connect(_on_hour_tick)
    GameClock.day_tick.connect(_on_day_tick)
    GameClock.month_tick.connect(_on_month_tick)

func _on_hour_tick() -> void:
    LightSystem.update()  # Day/night variation

func _on_day_tick() -> void:
    pass  # Placeholder for daily updates

func _on_month_tick() -> void:
    Economy.process_month()
```

---

## UI Layout

```
┌─────────────────────────────────────────┐
│ Day 15, Month 3, Year 1    08:00        │
│ [⏸][▶][▶▶][▶▶▶]           Speed: 2x    │
└─────────────────────────────────────────┘
```

### Speed Button Implementation

```gdscript
func _on_pause_pressed() -> void:
    GameClock.set_speed(GameClock.Speed.PAUSED)
    update_speed_display()

func _on_normal_pressed() -> void:
    GameClock.set_speed(GameClock.Speed.NORMAL)
    update_speed_display()

func _on_fast_pressed() -> void:
    GameClock.set_speed(GameClock.Speed.FAST)
    update_speed_display()

func _on_faster_pressed() -> void:
    GameClock.set_speed(GameClock.Speed.FASTER)
    update_speed_display()

func update_speed_display() -> void:
    var speed_names = {
        GameClock.Speed.PAUSED: "Paused",
        GameClock.Speed.NORMAL: "1x",
        GameClock.Speed.FAST: "2x",
        GameClock.Speed.FASTER: "3x"
    }
    speed_label.text = "Speed: %s" % speed_names[GameClock.current_speed]
```

---

## Day/Night Visual (Optional)

```gdscript
func update_ambient_light() -> void:
    var hour = GameClock.game_time.hour

    # Simple day/night cycle
    var brightness: float
    if hour >= 6 and hour < 20:
        brightness = 1.0  # Day
    elif hour >= 20 or hour < 6:
        brightness = 0.6  # Night

    # Apply to world lighting
    world_modulate = Color(brightness, brightness, brightness * 1.1)
```

---

## Acceptance Criteria

- [ ] Time advances automatically
- [ ] Hour/day/month/year tracking works
- [ ] Pause button stops time
- [ ] Speed buttons change game speed
- [ ] Speed display shows current speed
- [ ] Monthly tick triggers rent collection
- [ ] Hourly tick triggers light updates
- [ ] UI shows current date and time
- [ ] Keyboard shortcuts for pause (Space) work
