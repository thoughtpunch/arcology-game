# Data Model

[← Back to Technical](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Core data structures for the Arcology game.

---

## Arcology (Root)

```gdscript
Arcology {
  grid: Dictionary  # Vector3i -> Block (sparse)
  blocks: Dictionary  # id -> Block

  vertical_bounds: {
    max_height: int,
    max_depth: int,
    permitted_height: int,
    permitted_depth: int,
  }

  infrastructure_networks: {
    power: Network,
    water: Network,
    light_pipes: Network
  }

  transit_graph: TransitGraph
  environment_cache: EnvironmentCache
  economy: EconomyState
  population: PopulationState
  scenario: ScenarioConfig
}
```

---

## Block

```gdscript
Block {
  id: int
  grid_position: Vector3i
  block_type: String

  # Visual
  node: Node3D           # Scene node (MeshInstance3D + StaticBody3D)
  occupied_cells: Array[Vector3i]  # All cells this block occupies

  # State
  connected: bool
  status: BlockStatus  # FUNCTIONING | DEGRADED | FAILING
  condition: int  # 0-100

  # Environment (cached)
  environment: {
    light: int,
    air: int,
    noise: int,
    safety: int,
    vibes: int
  }

  # Occupancy (residential/commercial)
  occupants: Array[Resident]
  capacity: int

  # Economics
  base_rent: int
  current_rent: int
  revenue: int
}
```

---

## Resident (Agent)

```gdscript
Resident {
  id: int
  name: String
  age: int
  archetype: String

  # Location
  home: Vector3i
  workplace: Vector3i

  # Personality (Big Five)
  openness: int
  conscientiousness: int
  extraversion: int
  agreeableness: int
  neuroticism: int

  # Needs (0-100 each)
  needs: {
    survival: int,
    safety: int,
    belonging: int,
    esteem: int,
    purpose: int
  }

  # State
  satisfaction: int
  flourishing: int  # computed
  flight_risk: int  # computed

  # History
  complaints: Array[Complaint]
  life_events: Array[Event]
  residence_duration: int  # months
}
```

---

## Relationship

```gdscript
Relationship {
  person_a: int  # resident id
  person_b: int  # resident id

  type: String  # family | romantic | friend | acquaintance | coworker | enemy
  strength: int  # 0-100
  trend: String  # improving | stable | deteriorating

  last_interaction: int  # timestamp
  shared_meals: int
  conflicts: int
}
```

---

## Transit Graph

```gdscript
TransitGraph {
  nodes: Dictionary  # Vector3i -> TransitNode
  edges: Dictionary  # Vector3i -> Array[TransitEdge]
}

TransitNode {
  position: Vector3i
  block_type: String
}

TransitEdge {
  from_pos: Vector3i
  to_pos: Vector3i
  cost: float
}
```

---

## Economy State

```gdscript
EconomyState {
  treasury: int
  monthly_income: int
  monthly_expenses: int

  loans: Array[Loan]

  income_breakdown: {
    residential: int,
    commercial: int,
    industrial: int,
    other: int
  }

  expense_breakdown: {
    power: int,
    water: int,
    security: int,
    transit: int,
    maintenance: int,
    debt: int
  }
}
```

---

## Game Clock

```gdscript
GameClock {
  game_time: {
    hour: int,
    day: int,
    month: int,
    year: int
  }

  speed: Speed  # PAUSED | NORMAL | FAST | FASTER
  seconds_per_hour: float
}
```

---

## Environment Cache

```gdscript
EnvironmentCache {
  light: Dictionary  # Vector3i -> int
  air: Dictionary  # Vector3i -> int
  noise: Dictionary  # Vector3i -> int
  safety: Dictionary  # Vector3i -> int

  dirty: bool
  dirty_positions: Array[Vector3i]
}
```

---

## See Also

- [simulation-tick.md](./simulation-tick.md) - Update frequencies
- [../architecture/patterns.md](../architecture/patterns.md) - Code patterns
- [../quick-reference/code-conventions.md](../quick-reference/code-conventions.md) - Naming conventions
