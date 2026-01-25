# Human Simulation

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Arcology simulates individual humans with needs, personalities, relationships, and daily routines. This is the heart of the game.

---

## Contents

| Topic | Description | Link |
|-------|-------------|------|
| **Agents** | Individual residents | [agents.md](./agents.md) |
| **Needs** | Five-tier need hierarchy | [needs.md](./needs.md) |
| **Relationships** | Social connections | [relationships.md](./relationships.md) |
| **Flourishing** | Success metric | [flourishing.md](./flourishing.md) |

---

## Core Concepts

### Notable vs Background

Not every resident gets full simulation:

| Type | Count | Simulation |
|------|-------|------------|
| **Notable** | 100-500 | Full: needs, relationships, stories |
| **Background** | Rest | Statistical: contribute to aggregates |

Notable residents:
- Have detailed stories
- Appear in news feed
- Can be followed and watched
- Serve as emotional anchors

### Maslow Hierarchy

Lower needs must be met before higher ones matter:

```
PURPOSE     ← Only matters if esteem is met
ESTEEM      ← Only matters if belonging is met
BELONGING   ← Only matters if safety is met
SAFETY      ← Only matters if survival is met
SURVIVAL    ← Foundation (food, shelter, health)
```

### Daily Simulation

Residents follow schedules:

```
06:30  Wake up
07:30  Commute to work
08:00  Work
12:00  Lunch
17:30  Leave work
18:30  Home or social activity
23:00  Sleep
```

Each action affects needs and creates interaction opportunities.

---

## Key Metrics

| Metric | Range | Description |
|--------|-------|-------------|
| Satisfaction | 0-100 | Current happiness |
| Flourishing | 0-100 | Overall wellbeing |
| Flight Risk | 0-100 | Likelihood to leave |

---

## See Also

- [../environment/](../environment/) - How environment affects residents
- [../economy/rent.md](../economy/rent.md) - Rent affects affordability
- [../dynamics/entropy.md](../dynamics/entropy.md) - Social entropy
- [../dynamics/human-nature.md](../dynamics/human-nature.md) - Behavioral challenges
- [../../ui/narrative.md](../../ui/narrative.md) - Storytelling systems
