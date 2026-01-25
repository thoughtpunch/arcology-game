# Formulas Reference

All game calculations in one place.

---

## Permits

### Airspace Permit Cost

```
permit_cost = BASE_PERMIT × HEIGHT_MULTIPLIER[floor]

HEIGHT_MULTIPLIER:
  Floors 1-10:   1.0x
  Floors 11-20:  1.5x
  Floors 21-30:  2.0x
  Floors 31-50:  3.0x
  Floors 51-75:  5.0x
  Floors 76-100: 8.0x
  Floors 100+:   12.0x
```

### Excavation Permit Cost

```
permit_cost = BASE_EXCAVATION × DEPTH_MULTIPLIER[floor]

DEPTH_MULTIPLIER:
  Floors -1 to -3:   1.0x
  Floors -4 to -6:   1.5x
  Floors -7 to -10:  2.5x
  Floors -11 to -20: 4.0x
  Floors -20+:       6.0x
```

### Subterranean Penalties

```
For floor Z (where Z < 0):

light_penalty = min(100, |Z| × 20)        # -20% per floor, max -100%
air_penalty = min(60, |Z| × 10)           # -10% per floor, max -60%
vibes_penalty = 15 + (|Z| × 10)           # Base -15, then -10 per floor
crime_bonus = 10 + (|Z| × 5)              # Base +10, then +5 per floor
```

---

## Economy

### Residential Rent

```
base_rent = BLOCK_TYPE_BASE[type] × LEVEL_MULTIPLIER[level]

desirability = (
    sunlight × 0.20 +
    air_quality × 0.15 +
    quiet × 0.15 +
    safety × 0.15 +
    accessibility × 0.20 +
    vibes × 0.15
) / 100

rent = base_rent × desirability × demand_multiplier
```

### Commercial Revenue

```
revenue = base × level × (
    foot_traffic × 0.35 +
    accessibility × 0.20 +
    cluster_bonus × 0.15 +
    catchment_pop × 0.20 +
    vibes × 0.10
) × (1 - competition_penalty)
```

---

## Environment

### Effective Light

```
natural_light_score = natural_light_level  # 0-100
artificial_light_score = artificial_light_level × 0.35
piped_light_score = piped_light_level × efficiency  # 0.6-0.8

effective_light = max(natural, piped, artificial)
```

### Vibes

```
vibes = (
    effective_light × 0.25 +
    effective_air × 0.20 +
    greenery_proximity × 0.15 +
    aesthetics × 0.10 +
    quiet × 0.15 +
    safety × 0.15
) - subterranean_vibes_penalty  # if Z < 0
```

### Corridor Noise

```
traffic_noise = current_traffic × NOISE_PER_PERSON[corridor_type]

NOISE_PER_PERSON:
  Small (1×1):       0.8
  Medium (2×1):      0.5
  Large (3×2):       0.3
  Grand Promenade:   0.2

effective_noise = traffic_noise + sound_generators - acoustic_mitigation
effective_noise = max(0, effective_noise)  # floor at 0
```

### Noise Propagation

```
Noise received by adjacent blocks:

immediate_neighbor = corridor_noise × 0.80
one_block_away = corridor_noise × 0.40
two_blocks_away = corridor_noise × 0.15

Wall reduction:
  Solid wall: × 0.50
  Glass wall: × 0.80
  Open/void:  × 1.00

received_noise = corridor_noise × distance_factor × wall_factor
```

---

## Transit

### Corridor Capacity and Speed

```
saturation = current_traffic / base_capacity

Speed multiplier by saturation:
  0-50%:    1.0x (free flow)
  50-75%:   0.85x (crowded)
  75-90%:   0.6x (congested)
  90-100%:  0.4x (packed)
  >100%:    0.2x (gridlock)

effective_speed = base_speed × speed_multiplier(saturation)
```

### Pathfinding Edge Cost

```
edge_cost = (distance / effective_speed) × traversal_cost_modifier

Traversal cost modifiers (lower = preferred):
  Corridor (basic):     1.0
  Corridor (crowded):   1.3
  Atrium:              0.85
  Park/Garden:         0.9
  Food Hall:           0.95
  Industrial corridor: 1.3

Transit speed multipliers:
  Walking:              1.0x
  Stairs (up):          0.4x
  Stairs (down):        0.6x
  Conveyor (with):      2.0-2.5x
  Conveyor (against):   0.3x
  Elevator:             3.0-5.0x (plus wait time)
  Pneuma-Tube:          10.0x
```

---

## Human Simulation

### Flourishing Calculation

```python
def calculate_flourishing(needs):
    # Maslow hierarchy: lower needs gate higher ones

    if needs.survival < 50:
        return needs.survival × 0.3  # 0-15 range

    if needs.safety < 40:
        return 30 + (needs.safety - 40) × 0.5  # 15-30 range

    if needs.belonging < 30:
        return 50 + (needs.belonging - 30) × 0.5  # 30-50 range

    if needs.esteem < 30:
        return 60 + (needs.esteem - 30) × 0.4  # 50-60 range

    # All base needs met—purpose drives flourishing
    base = 70
    purpose_bonus = (needs.purpose - 50) × 0.6  # up to +30

    # Harmony bonus for all needs being high
    minimum_need = min(all_needs)
    harmony_bonus = max(0, (minimum_need - 70)) × 0.3  # up to +9

    return min(100, base + purpose_bonus + harmony_bonus)
```

### Flight Risk

```
flight_risk = base_risk + dissatisfaction + opportunity - attachment

base_risk = ARCHETYPE_BASE[archetype]  # 5-20 depending on type

dissatisfaction = (
    (100 - flourishing) × 0.5 +
    (declining_trend ? 20 : 0) +
    unresolved_complaints × 5
)

opportunity = (
    external_job_market × 0.3 +
    better_housing_available × 0.3
)

attachment = (
    friends_in_building × 5 +
    family_in_building × 15 +
    years_of_residence × 3 +
    community_involvement × 10
)

flight_risk = clamp(flight_risk, 0, 100)
```

### Population Change

```
births = pop × birth_rate × family_housing_ratio × happiness
deaths = pop × death_rate × (1 - healthcare_modifier)

immigration = pressure × vacancy × desirability × transit
emigration = pop × (1 - satisfaction) × pull × transit

net_change = (births - deaths) + (immigration - emigration)
```

---

## Community

### Community Cohesion

```
cohesion = (
    average_relationship_strength × 0.25 +
    relationship_density × 0.20 +      # connections per person
    cross_group_bridges × 0.20 +       # links between different groups
    inverse_conflict_rate × 0.15 +
    inverse_turnover_rate × 0.20
) × 100

Decay sources (monthly):
  Turnover: -2 per 10% annual turnover rate
  Isolated residents: -1 per 100 isolated people
  Active conflicts: -5 per unresolved conflict
  Inequality (Gini > 0.4): -3
  Scale without structure: -2 per 10k without districts
  Natural decay: -1 baseline
```

### Relationship Dynamics

```
FORMATION:
  acquaintance_chance = base_chance × compatibility × frequency

  base_chance:
    Neighbors: 0.30/month
    Coworkers: 0.50/month
    Elevator encounter: 0.02/ride
    Shared event: 0.15/event

MAINTENANCE:
  No interaction 30 days: -10 strength
  No interaction 90 days: -30 strength
  Positive interaction: +3 to +5
  Shared meal: +3
  Helped in crisis: +20
  Conflict: -10 to -50

DISSOLUTION:
  strength < 20: relationship ends
  friendship → acquaintance if strength < 40
```

---

## Victory Metrics

### Arcology Eudaimonia Index (AEI)

```
AEI = (
    individual × 0.40 +
    community × 0.25 +
    sustainability × 0.20 +
    resilience × 0.15
)

individual = (
    mean(all_flourishing) -
    stdev(all_flourishing) × 0.3  # penalize inequality
)

community = cohesion_score

sustainability = 100 - (
    maintenance_debt_ratio × 30 +
    budget_deficit_months × 10 +
    environmental_damage × 20 +
    knowledge_loss_index × 10
)

resilience = (
    backup_systems_coverage × 0.25 +
    financial_reserves_months × 0.25 +
    mutual_aid_score × 0.25 +
    economic_diversity × 0.25
) × 100
```

---

## Elevator

### Wait Time

```
base_wait = f(floor_demand, elevator_capacity, num_cars, dispatch_algorithm)

perceived_wait = base_wait × perception_multipliers

Perception multipliers (multiplicative):
  No indicator:           × 1.5
  Watching full cars:     × 1.3
  Running late:           × 1.4
  Uncomfortable lobby:    × 1.25
  Alone:                  × 1.2

  Countdown display:      × 0.7
  Pleasant lobby:         × 0.8
  Friend present:         × 0.75
  Distraction (art):      × 0.85
  Mirrors:                × 0.9

frustration_delta = (perceived_wait - tolerance) × neuroticism / 100
```

### Force Field Power

```
force_field_power_draw = panels × 10 units

Failure thresholds:
  100-75% power: Normal operation
  75-50% power:  Flicker warning
  50-25% power:  Weakening, air leak risk
  <25% power:    Collapse, decompression
```
