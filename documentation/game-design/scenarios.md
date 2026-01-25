# Scenarios & World Settings

[← Back to Game Design](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Different scenarios provide different challenges: Earth urban, Earth remote, Mars colony, space station.

---

## Scenario Parameters

| Parameter | Earth Urban | Earth Remote | Mars | Space Station |
|-----------|-------------|--------------|------|---------------|
| Immigration | High | Medium | Rare ships | Zero/Rare |
| Emigration | High | Medium | Rare ships | Zero/Rare |
| Trade | Open | Limited | Critical | None |
| Starting Isolation | 20 | 50 | 85 | 95+ |
| Envelope | Optional | Important | Critical | Critical |
| External Environment | Survivable | Survivable | Lethal | Lethal |

---

## Earth Urban

Default scenario:
- Immigration/emigration based on desirability
- Open trade (imports/exports)
- Optional building envelope
- Day/night cycle affects light

### Challenges
- Competition from other housing
- External economic shocks
- Urban integration

---

## Earth Remote

Isolated but on Earth:
- Limited immigration
- Some import dependency
- Building envelope important for climate
- Self-sufficiency encouraged

### Challenges
- Attracting population
- Supply chain reliability
- Distance from services

---

## Mars Colony

Sealed habitat on Mars:
- Very rare immigration (ships)
- Complete envelope seal required
- Water recycling critical
- Dust storms threaten solar power

### Challenges
- Population sustainability (births = critical)
- Healthcare is life or death
- Power reliability during storms
- Complete self-sufficiency

### Special Rules
- No external air (100% HVAC)
- Force fields for views
- Geothermal power viable
- Mushroom farms important

---

## Space Station

Orbital habitat:
- Zero immigration (or extremely rare)
- Complete hull seal
- Artificial day/night cycle
- Rotation for gravity

### Challenges
- Population must be self-sustaining
- Hull breach = disaster
- Every resource must be recycled
- No external resupply

### Special Rules
- No natural light (artificial cycle for health)
- Cooling is the problem (not heating)
- "Down" determined by rotation

---

## Day/Night Cycle

| Period | Sun | Traffic Pattern |
|--------|-----|-----------------|
| Night (22:00-06:00) | None | Minimal, crime risk |
| Morning (06:00-09:00) | Rising | Commute surge |
| Midday (09:00-17:00) | Full | Work + lunch |
| Evening (17:00-22:00) | Setting | Reverse commute |

---

## Seasonal Cycle (Earth)

| Season | Day Length | Sun | Temperature |
|--------|-----------|-----|-------------|
| Summer | Long | High | Hot (cooling demand) |
| Winter | Short | Low | Cold (heating demand) |
| Spring/Fall | Medium | Medium | Mild |

---

## Tech Levels

Population unlocks advanced buildings:

| Level | Population | Key Unlocks |
|-------|------------|-------------|
| 1 (Settlement) | 0-2,000 | Basic housing, small commercial, stairs |
| 2 (Town) | 2,000-10,000 | University, vertical farms, express elevators |
| 3 (City) | 10,000-50,000 | Mega-blocks, medical center, sky lobbies |
| 4 (Metropolis) | 50,000+ | Advanced power, transit pods, prestige |

---

## Population Dynamics

```
population_change = (births - deaths) + (immigration - emigration)

births = pop × birth_rate × family_housing_ratio × happiness
deaths = pop × death_rate × (1 - healthcare_modifier)

immigration = external_demand × vacancy × desirability × transit
emigration = pop × (1 - satisfaction) × external_pull × transit
```

### Closed Scenarios

For Mars/Space:
```
immigration = 0 (or rare events)
emigration = 0 (or rare events)

Population depends entirely on births - deaths
Healthcare and family housing become CRITICAL
```

---

## Isolation Score

Measures self-containment:

| Score | Description |
|-------|-------------|
| 0-30 | Integrated district (porous) |
| 30-60 | Distinct but connected |
| 60-85 | Self-sufficient city-state |
| 85-100 | Closed system (space station) |

---

## See Also

- [dynamics/eudaimonia.md](./dynamics/eudaimonia.md) - Victory conditions by scenario
- [blocks/infrastructure.md](./blocks/infrastructure.md) - Power for different environments
- [human-simulation/agents.md](./human-simulation/agents.md) - Population dynamics
- [economy/budget.md](./economy/budget.md) - Trade and imports
