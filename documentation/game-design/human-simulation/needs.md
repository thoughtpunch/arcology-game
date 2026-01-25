# Human Needs

[← Back to Human Simulation](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Every resident has five core needs (Maslow-inspired hierarchy). Lower needs must be met before higher ones matter.

---

## The Five Needs

```
PURPOSE (top)     → Meaning, growth, contribution
ESTEEM            → Respect, recognition, status
BELONGING         → Relationships, community, love
SAFETY            → Security, stability, predictability
SURVIVAL (base)   → Food, water, shelter, health
```

---

## Need Definitions

### Survival (Foundation)

**What:** Food, water, shelter, health, physical comfort

**Met by:**
- Housing (shelter)
- Grocery access (food)
- Healthcare access (health)
- HVAC (temperature)
- Clean air

**Failure:** Illness, physical decline, death

### Safety (Security)

**What:** Physical security, stability, predictability

**Met by:**
- Low crime / security coverage
- Stable housing (secure lease)
- Emergency services
- Predictable environment

**Failure:** Anxiety, hypervigilance, flight

### Belonging (Connection)

**What:** Relationships, community, love, acceptance

**Met by:**
- Friendships
- Family nearby
- Community spaces
- Events and activities

**Failure:** Loneliness, isolation, depression

### Esteem (Recognition)

**What:** Respect, recognition, status, achievement

**Met by:**
- Meaningful work
- Contributions valued
- Nice home relative to peers
- Community respect

**Failure:** Insecurity, resentment, status competition

### Purpose (Meaning)

**What:** Growth, meaning, contribution, self-actualization

**Met by:**
- Fulfilling work
- Creative expression
- Learning/growing
- Community impact

**Failure:** Emptiness, existential drift, apathy

---

## Needs Dynamics

Needs fluctuate based on daily experience:

### Survival Needs

| Factor | Effect |
|--------|--------|
| Good air quality | +1/day |
| Food access nearby | +1/day |
| Healthcare when sick | +3/day |
| Poor air quality | -2/day |
| No food access | -1/day |
| Illness without care | -5/day |

### Safety Needs

| Factor | Effect |
|--------|--------|
| Low crime in area | +1/day |
| Stable housing | +1/day |
| Witnessed crime | -10 (event) |
| Rent increase notice | -15 (event) |
| Neighbor conflict | -5/day |

### Belonging Needs

| Factor | Effect |
|--------|--------|
| Friend interaction | +2/interaction |
| Community event | +5 (event) |
| Romantic relationship | +3/day |
| Ate alone today | -1 |
| No friends in 7 days | -5 |
| Friend moved away | -20 (event) |

### Esteem Needs

| Factor | Effect |
|--------|--------|
| Work recognition | +5 (event) |
| Respected by neighbors | +1/day |
| Nice home vs peers | +2/day |
| Passed over promotion | -15 (event) |
| Lives in "bad" area | -2/day |

### Purpose Needs

| Factor | Effect |
|--------|--------|
| Work aligns with values | +2/day |
| Learning/growing | +2/day |
| Community contribution | +3 (event) |
| Dead-end job | -2/day |
| No growth in 6 months | -5 (event) |

---

## Hierarchy Effect

Lower needs gate higher ones:

```python
def calculate_flourishing(needs):
    if needs.survival < 50:
        return needs.survival * 0.3  # 0-15 range (surviving)

    if needs.safety < 40:
        return 30 + (needs.safety - 40) * 0.5  # 15-30 range (anxious)

    if needs.belonging < 30:
        return 50 + (needs.belonging - 30) * 0.5  # 30-50 range (lonely)

    if needs.esteem < 30:
        return 60 + (needs.esteem - 30) * 0.4  # 50-60 range (insecure)

    # All base needs met - purpose drives flourishing
    base = 70
    purpose_bonus = (needs.purpose - 50) * 0.6  # up to +30
    return min(100, base + purpose_bonus)
```

See [flourishing.md](./flourishing.md) for full calculation.

---

## Block Contributions

How blocks help meet needs:

| Need | Contributing Blocks |
|------|---------------------|
| Survival | Housing, Grocery, Clinic, HVAC |
| Safety | Security Station, Lighting, Fire Station |
| Belonging | Community Center, Cafe, Events |
| Esteem | Premium Housing, Office, Recognition |
| Purpose | Maker Space, Library, Meaningful Work |

---

## See Also

- [agents.md](./agents.md) - Who has needs
- [flourishing.md](./flourishing.md) - How needs become flourishing
- [relationships.md](./relationships.md) - Belonging need
- [../blocks/civic.md](../blocks/civic.md) - Blocks that meet needs
- [../environment/safety-system.md](../environment/safety-system.md) - Safety need
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#flourishing-calculation) - Formulas
