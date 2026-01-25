# Narrative Systems

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

The game tells stories through its systems. Players don't read cutscenes—they watch lives unfold.

---

## The Evening News

Regular digest of arcology events:

```
┌────────────────────────────────────────────────────┐
│  ARCOLOGY HERALD - Evening Edition                 │
│  Year 5, Month 8, Day 15                          │
├────────────────────────────────────────────────────┤
│  TOP STORIES:                                      │
│                                                    │
│  📈 Elevator Wait Times Hit Record High            │
│     Floors 20-30 averaging 8 minute waits          │
│                                                    │
│  🏠 New Restaurant Opens on Level 12               │
│     "Chen's Noodle House" replaces vacant shop    │
│                                                    │
│  ⚠️ East Wing Cohesion Declining                   │
│     Neighbor disputes up 40% this quarter         │
│                                                    │
├────────────────────────────────────────────────────┤
│  RESIDENT SPOTLIGHT: David Park                    │
│  "The morning commute is brutal, but I love       │
│   my neighbors."                                  │
└────────────────────────────────────────────────────┘
```

---

## Notable Resident Stories

### Life Events

| Event Type | Examples |
|------------|----------|
| Life Events | Moved in/out, job change, new friend |
| Milestones | Anniversary, flourishing hit 80+ |
| Conflicts | Dispute, noise complaint |
| Achievements | Started business, became leader |

### Story Presentation

```
┌─────────────────────────────────────────┐
│  RESIDENT UPDATE                        │
├─────────────────────────────────────────┤
│  [Portrait] Maria Chen                  │
│  Floor 47, Apt 3 | 2 years resident    │
│                                         │
│  "I did it! I finally opened my        │
│   restaurant on Level 12."             │
│                                         │
│  Flourishing: 72 → 81 ↑                │
│  Purpose need satisfied                 │
│                                         │
│  [Visit Restaurant] [Follow Maria]     │
└─────────────────────────────────────────┘
```

---

## Complaint System

How residents communicate problems:

```
Complaint {
  resident: person_id
  type: noise | safety | maintenance | service | neighbor | rent
  severity: minor | moderate | serious | urgent
  target: block_id | person_id | system
  status: new | acknowledged | in_progress | resolved | dismissed

  description: generated text
  underlying_need: which need affected
  resolution_options: [possible actions]
}
```

### Example Complaints

```
NOISE COMPLAINT (Moderate)
From: Robert Kim, Level 14, Apt B
"I can hear the nightclub through my floor
every night until 2am. I work early shifts."

Underlying need: Survival (sleep)
Resolution options:
  - Soundproof the nightclub ($2,000)
  - Offer Robert relocation
  - Restrict nightclub hours
  - Dismiss (not recommended)
```

---

## The Zoom-In Moment

Players can enter any block and see human scale:

### Residential Block
```
[Interior view: small apartment]
- Living area with couch, TV, plants
- Kitchen visible in corner
- Window showing arcology view

Resident: Maria Chen
Current mood: Content
Current activity: Making dinner

Stats:
  Light: 72%
  Air: 85%
  Noise: 28 (quiet)
```

### Restaurant
```
[Interior view: restaurant]
- Tables with diners
- Kitchen visible through pass
- Staff moving between tables

Capacity: 40 seats
Current: 28 occupied (70%)
Revenue today: $1,240

Notable diners:
  - Maria Chen + David Park (lunch)
```

---

## Time-Lapse Moments

Key moments to watch:

| Time | What Happens |
|------|--------------|
| Morning Rush (7:30-9:00) | Corridors fill, elevators queue |
| Lunch Rush (12:00-13:00) | Offices empty, restaurants fill |
| Evening (17:00-20:00) | Reverse commute, entertainment |
| Crisis | Fire alarm, power outage |

---

## Memory & Legacy

The arcology accumulates history:

```
ARCOLOGY TIMELINE:

Year 1: Founded with 500 residents
Year 3: Community cohesion crisis (recovered)
Year 7: Maria Chen opens restaurant
Year 8: Great Elevator Crisis
Year 15: Founder generation retiring
```

### Memorial System
- Residents who die are remembered
- Long-term residents get legacy markers
- Historical events commemorated

---

## See Also

- [../game-design/human-simulation/agents.md](../game-design/human-simulation/agents.md) - Notable residents
- [../game-design/human-simulation/flourishing.md](../game-design/human-simulation/flourishing.md) - Satisfaction tracking
- [../game-design/dynamics/human-nature.md](../game-design/dynamics/human-nature.md) - Conflict sources
- [overlays.md](./overlays.md) - Visual information
