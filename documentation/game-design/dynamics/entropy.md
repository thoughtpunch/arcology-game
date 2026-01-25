# Entropy Systems

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Everything decays. Your job is to fight it. Entropy is the constant antagonist—not evil, just physics and time.

---

## Physical Entropy

### Building Decay

```
Every block has:
  condition: 0-100
  age: months since construction
  maintenance_debt: accumulated deferred maintenance

decay_rate = BASE_DECAY × use_intensity × environment_factor
```

### Use Intensity

| Traffic | Multiplier |
|---------|------------|
| Low (<50/day) | 1.0x |
| Medium (50-200/day) | 1.5x |
| High (200-500/day) | 2.0x |
| Very High (500+/day) | 3.0x |

### Environment Factor

| Condition | Multiplier |
|-----------|------------|
| Standard | 1.0x |
| Subterranean (moisture) | 1.3x |
| Near industrial (vibration) | 1.2x |
| Exterior-facing (weather) | 1.2x |

### Condition Effects

| Condition | State | Effects |
|-----------|-------|---------|
| 100-80 | Pristine | No penalties |
| 80-60 | Worn | Vibes -5, 5% breakdown |
| 60-40 | Degraded | Vibes -15, 15% breakdown, safety -10 |
| 40-20 | Failing | Vibes -30, 30% breakdown, safety -25 |
| 20-0 | Condemned | Unusable until repair |

### Maintenance System

```
ROUTINE MAINTENANCE:
  Cost: $/month per block
  Effect: Slows decay by 80%
  Skip it: Saves now, costs 3x later

REPAIR:
  Cost: $$ per condition point
  Effect: Restores condition
  Doesn't reset age

RENOVATION:
  Cost: $$$
  Effect: Full restore + upgrade, resets age
  Disruption: Block unusable during
```

---

## Social Entropy

Communities fragment without cultivation:

| Source | Effect |
|--------|--------|
| Turnover | -2 cohesion per 10% annual |
| Isolation | -1 cohesion per 100 isolated |
| Unresolved conflict | -5 cohesion per conflict |
| Inequality (Gini > 0.4) | -3 cohesion |
| Scale without structure | -2 per 10k without districts |
| Time | -1 cohesion/year baseline |

---

## Economic Entropy

Markets shift, industries die:

```
DEMAND SHIFTS:
  Every 5 years: major demand shift event

Examples:
  Year 5: "Remote work reduces office demand 20%"
  Year 12: "Competitor arcology opens; immigration drops 30%"
  Year 20: "Your industrial sector is obsolete"

OBSOLESCENCE:
  Old block types become less desirable
  Technology requirements increase
  "Vintage charm" bonus possible after 30+ years (if maintained)
```

---

## Knowledge Entropy

Institutional memory is fragile:

| Type | Description |
|------|-------------|
| How systems work | Informal knowledge |
| Who knows whom | Social knowledge |
| What's been tried | Historical knowledge |
| Unwritten rules | Cultural knowledge |

### Knowledge Loss Events

- Key resident leaves: expertise gone
- Long-time manager retires: memory gap
- Rapid turnover: nobody knows how things work
- No documentation: tribal knowledge only

---

## Fighting Entropy

### Physical
- Consistent maintenance budget (don't defer!)
- Quality construction (higher upfront, slower decay)
- Renovation cycles (rebuild before collapse)
- Redundant systems

### Social
- Community events
- New resident integration
- Conflict mediation
- Cross-group activities

### Economic
- Diversified economy
- Reserve funds
- Continuous adaptation
- Education/skills investment

### Knowledge
- Documentation systems
- Mentorship programs
- Institutional continuity
- Historical preservation

---

## See Also

- [human-nature.md](./human-nature.md) - Behavioral challenges
- [eudaimonia.md](./eudaimonia.md) - Win condition
- [../human-simulation/relationships.md](../human-simulation/relationships.md) - Social decay
- [../economy/budget.md](../economy/budget.md) - Maintenance costs
- [../../architecture/performance.md](../../architecture/performance.md) - Technical decay simulation
