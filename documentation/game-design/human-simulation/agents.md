# Agents (Residents)

[← Back to Human Simulation](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Agents are individual simulated residents. They have identity, personality, needs, and daily routines.

---

## Agent Properties

```
Resident {
  // Identity
  id: unique
  name: string
  age: int
  portrait: generated image

  // Location
  home: block_id
  workplace: block_id (if employed)

  // Personality (Big Five)
  openness: 0-100
  conscientiousness: 0-100
  extraversion: 0-100
  agreeableness: 0-100
  neuroticism: 0-100

  // Current State
  needs: {survival, safety, belonging, esteem, purpose}
  satisfaction: 0-100
  mood: happy | content | stressed | unhappy | miserable

  // History
  complaints: [Complaint]
  life_events: [Event]
  residence_duration: months

  // Trajectory
  flourishing: 0-100 (computed)
  flight_risk: 0-100
}
```

---

## Archetypes

New residents arrive with context based on archetype:

### Young Professional (age 22-35)
```
Seeking: career growth, excitement, social life
Needs emphasis: purpose, belonging
Tolerates: small spaces, noise, crowds
Base traits: low neuroticism, high openness
Flight risk if: career stalls, no friends after 6 months
```

### Family (2 adults, 1-3 children)
```
Seeking: safety, schools, space, stability
Needs emphasis: safety, belonging (for kids)
Requires: family housing, school access
Base traits: high conscientiousness
Flight risk if: crime rises, schools decline
```

### Retiree (age 60+)
```
Seeking: quiet, healthcare, community
Needs emphasis: safety, belonging, purpose
Requires: healthcare access, low noise
Base traits: varied, high conscientiousness
Flight risk if: isolated, health declines
```

### Artist/Creative (age 20-50)
```
Seeking: cheap space, inspiration, community
Needs emphasis: purpose, esteem
Tolerates: rough conditions, subterranean
Base traits: high openness, variable neuroticism
Flight risk if: priced out, scene dies
```

### Entrepreneur (age 25-45)
```
Seeking: opportunity, networking, status
Needs emphasis: esteem, purpose
Wants: prestigious address, talent access
Base traits: low agreeableness, high openness
Flight risk if: business fails
```

---

## Notable Residents

100-500 residents get full simulation and appear in stories:

```
NOTABLE RESIDENT PROFILE:

Maria Chen
Age: 34 | Young Professional | Floor 47, Apt 3
Workplace: Tech startup, Floor 22
Residence: 2 years, 4 months

Flourishing: 72 (Stable)
[████████░░]

Current Status: Content but commute-frustrated

Key Relationships:
  - David Park (friend, coworker) - Strength: 78
  - Lisa Chen (sister, Floor 31) - Strength: 92
  - No romantic partner

Recent Events:
  - Complained about elevator wait (3 weeks ago)
  - Attended community art show (2 weeks ago)

Trajectory: Stable
Flight Risk: 12% (low)
```

---

## Daily Simulation

Residents follow schedules that play out in real-time:

### Typical Weekday (Young Professional)

| Time | Activity | Needs Affected |
|------|----------|----------------|
| 06:30 | Wake up | - |
| 07:00 | Breakfast | Survival (+) |
| 07:30 | Commute | Stress if long |
| 08:00 | Arrive at work | Purpose (+/-) |
| 12:00 | Lunch | Survival, Belonging if social |
| 17:30 | Leave work | - |
| 18:30 | Home or social | Belonging (+) if social |
| 23:00 | Sleep | Survival (+) |

### Weekend
- More variance
- Social activities
- Shopping, recreation
- Visiting friends

---

## Personality Effects

Big Five traits affect behavior:

| Trait | High | Low |
|-------|------|-----|
| Openness | Seeks novelty, tolerates change | Prefers routine, resists change |
| Conscientiousness | Reliable, organized | Flexible, spontaneous |
| Extraversion | Needs social interaction | Needs alone time |
| Agreeableness | Cooperative, avoids conflict | Competitive, confrontational |
| Neuroticism | Sensitive to stress | Resilient, calm |

---

## Portrait Generation

Procedural pixel art (16-bit style):
- Parameters: skin tone, hair style/color, age markers
- Expression changes based on flourishing level
- Recognizable individuals, not generic avatars

---

## See Also

- [needs.md](./needs.md) - The five human needs
- [relationships.md](./relationships.md) - Social connections
- [flourishing.md](./flourishing.md) - Success measurement
- [../../ui/narrative.md](../../ui/narrative.md) - How agents appear in stories
- [../../architecture/milestones/milestone-7-residents.md](../../architecture/milestones/milestone-7-residents.md) - Implementation
