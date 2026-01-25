# Relationships & Social Networks

[← Back to Human Simulation](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Community is not automatic. Relationships must form, be maintained, and can decay or break.

---

## Relationship Model

```
Relationship {
  person_a: resident_id
  person_b: resident_id

  type: family | romantic | friend | acquaintance | coworker | neighbor | enemy
  strength: 0-100
  trend: improving | stable | deteriorating

  history: [Interaction]
  last_interaction: timestamp

  shared_meals: int
  conflicts: int
  helped_during_crisis: bool
}
```

---

## Relationship Formation

### Acquaintance Formation

| Context | Chance |
|---------|--------|
| Neighbors (adjacent apartments) | 30%/month |
| Coworkers (same workplace) | 50%/month |
| Elevator encounter | 2%/ride |
| Same food hall table | 5%/meal |
| Same community event | 15%/event |

### Acquaintance → Friend

Requires:
- 5+ positive interactions
- Compatibility score > 50
- No major conflicts

### Compatibility

```
compatibility = f(
  similar_age (±10 years): +20
  similar_archetype: +15
  complementary_traits: +10 to +30
  shared_interests: +20
  opposite_schedules: -30
)
```

---

## Relationship Maintenance

### Decay

```
No interaction in 30 days: strength -10
No interaction in 90 days: strength -30
If strength < 20: relationship dissolves
```

### Strengthening

| Event | Strength Change |
|-------|-----------------|
| Positive interaction | +3 to +5 |
| Shared meal | +3 |
| Event together | +5 |
| Helped during crisis | +20 |
| Conflict resolved well | +10 |

### Damage

| Event | Strength Change |
|-------|-----------------|
| Minor conflict | -10 |
| Major conflict | -30 |
| Betrayal | -50 to -80 |
| Unresolved conflict | -5/week |

---

## Relationship Effects

### On Belonging Need

| Factor | Belonging Effect |
|--------|------------------|
| Each friend in building | +5 (diminishing after 5) |
| Best friend | +15 |
| Romantic partner | +20 |
| Family member | +10 |
| Enemy in building | -10 safety, -5 belonging |

### On Other Needs

| Factor | Effect |
|--------|--------|
| Respected by neighbors | +1/day esteem |
| Community leader | +5/day esteem |
| Mentoring someone | +3/day purpose |
| Being mentored | +2/day purpose |

---

## Community Cohesion

Aggregate health of all relationships:

```
cohesion = f(
  average_relationship_strength,
  relationship_density,      // connections per person
  cross_group_connections,   // bridges between clusters
  conflict_rate,
  turnover_rate
)
```

### Cohesion Effects

| Level | Description | Effects |
|-------|-------------|---------|
| 80-100 | Tight Community | Mutual aid, crime suppressed, collective action |
| 60-80 | Friendly | Pleasant connections, some mutual aid |
| 40-60 | Cordial | Polite but distant, cliques form |
| 20-40 | Fragmented | Isolated individuals, tribal conflicts |
| 0-20 | Hostile | Active conflicts, violence, mass exodus |

### Cohesion Decay Sources

| Source | Monthly Effect |
|--------|----------------|
| Turnover | -2 per 10% annual rate |
| Isolated residents | -1 per 100 people |
| Active conflicts | -5 per conflict |
| Inequality (Gini > 0.4) | -3 |
| Scale without districts | -2 per 10k |
| Natural decay | -1 baseline |

---

## Community Events

Player-initiated events build connections:

| Event | Cost | Attendance | Cohesion Effect |
|-------|------|------------|-----------------|
| Block Party | $500 | 50-200 | +5, acquaintance boost |
| Art Show | $1,000 | 100-300 | +3, +vibes |
| Festival | $5,000 | 500-2,000 | +10, major formation |
| Town Hall | $200 | 50-150 | +2, surfaces complaints |
| Workshop | $300 | 20-50 | +3 among attendees |
| Sports League | $1,000/season | 50-200 | +5, regular structure |

---

## Elevator Social Dynamics

Shared elevator rides create interaction:

```
When strangers share elevator:
  Base 2% acquaintance chance per ride
  +3% if similar archetype
  +5% if one initiates (extrovert)
  +10% if notable event (breakdown)

When friends share elevator:
  Relationship +2
  Nearby passengers: +1% acquaintance chance
```

---

## See Also

- [agents.md](./agents.md) - Who has relationships
- [needs.md](./needs.md) - Belonging need
- [flourishing.md](./flourishing.md) - Social effects on flourishing
- [../dynamics/entropy.md](../dynamics/entropy.md) - Social entropy
- [../dynamics/human-nature.md](../dynamics/human-nature.md) - Tribalism
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#community-cohesion) - Cohesion formula
