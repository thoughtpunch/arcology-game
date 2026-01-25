# Safety System

[← Back to Environment](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Safety (inverse of crime) affects resident security needs and rent. Crime propagates from sources; security suppresses it.

---

## The Crime Doesn't Climb Rule

```
Crime pressure decreases with height:
  Ground floor (Z=0): base crime pressure
  Each floor up: -5% propagation chance

Result: Upper floors naturally safer
Creates organic social stratification
```

---

## Crime Sources

| Source | Crime Pressure |
|--------|----------------|
| Exterior entrance | Base pressure |
| Vacancy | +10 per vacant block |
| Darkness (light < 20) | +15 |
| Subterranean (Z < 0) | +5 per floor down |
| No security coverage | +20 |

---

## Crime Propagation

Crime spreads like a cellular automata:

```
Each tick:
  For each block with crime > 0:
    For each neighbor:
      if random() < propagation_chance:
        neighbor.crime += spillover

propagation_chance = base_chance × direction_modifier

direction_modifier:
  Horizontal: 1.0
  Downward:   1.2 (crime flows down)
  Upward:     0.5 (crime resists climbing)
```

---

## Security Coverage

Security stations suppress crime:

| Block | Coverage Radius | Suppression |
|-------|-----------------|-------------|
| Security Station | 10 blocks | -50 crime |
| Police HQ | 20 blocks | -80 crime |
| Security Checkpoint | 3 blocks | Blocks propagation |

### Coverage Calculation

```
security_effect = base_suppression × (1 - distance/max_radius)

Multiple stations stack with diminishing returns.
```

---

## Crime Effects

| Safety Level | Crime Effect |
|--------------|--------------|
| 80-100 | Safe - residents feel secure |
| 60-80 | Moderate - occasional concern |
| 40-60 | Risky - anxiety, some leave |
| 20-40 | Dangerous - fear, exodus |
| 0-20 | No-go zone - collapse |

---

## Safety Factors

### Positive (Increase Safety)

| Factor | Safety Bonus |
|--------|--------------|
| Security station nearby | +20-50 |
| Good lighting | +10 |
| High foot traffic | +10 |
| Upper floors | +5 per floor |
| Community cohesion > 70 | +10 |

### Negative (Decrease Safety)

| Factor | Safety Penalty |
|--------|----------------|
| Darkness | -15 |
| Vacancy | -10 |
| Underground | -5 per floor |
| No security | -20 |
| Low cohesion | -10 |

---

## Access Control

Checkpoints can block crime propagation:

```
Security Checkpoint:
  - Verifies access rights
  - Blocks crime inflow (80%)
  - Slight traffic delay

Placement strategy:
  - At zone boundaries
  - Between safe/risky areas
  - Elevator lobbies
```

See [../blocks/civic.md](../blocks/civic.md) for security blocks.

---

## Subterranean Crime

Underground areas are crime-prone:

```
Z = -1: +15% crime base
Z = -2: +20% crime base
Z = -3: +25% crime base

Mitigation:
  - Extra security stations
  - Good lighting
  - Access control
  - Design: put industrial (not residential) underground
```

---

## Crime Events

Random crime events can occur:

| Event | Trigger | Effect |
|-------|---------|--------|
| Break-in attempt | Low safety block | Stress, complaints |
| Witnessed crime | Very low safety | Major stress, flight risk |
| Vandalism | Crime > 60 | Damage, maintenance cost |

Events generate complaints and news.

---

## Safety in Rent

Safety affects desirability:

```
desirability includes:
  safety × 0.15

Low safety = lower rent potential
High safety = premium possible
```

---

## See Also

- [light-system.md](./light-system.md) - Lighting affects crime
- [vibes-system.md](./vibes-system.md) - Safety in vibes calculation
- [../blocks/civic.md](../blocks/civic.md) - Security blocks
- [../human-simulation/needs.md](../human-simulation/needs.md) - Safety need
- [../economy/rent.md](../economy/rent.md) - Rent calculation
- [../../quick-reference/glossary.md](../../quick-reference/glossary.md) - Term: "Crime Doesn't Climb"
