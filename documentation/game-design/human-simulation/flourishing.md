# Flourishing

[← Back to Human Simulation](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Flourishing is the computed score (0-100) measuring how well a resident's needs are met. It's the individual component of the win condition.

---

## Calculation

Flourishing uses Maslow hierarchy - lower needs gate higher ones:

```python
def calculate_flourishing(needs):
    if needs.survival < 50:
        return needs.survival * 0.3  # 0-15 range

    if needs.safety < 40:
        return 30 + (needs.safety - 40) * 0.5  # 15-30 range

    if needs.belonging < 30:
        return 50 + (needs.belonging - 30) * 0.5  # 30-50 range

    if needs.esteem < 30:
        return 60 + (needs.esteem - 30) * 0.4  # 50-60 range

    # All base needs met - purpose drives flourishing
    base = 70
    purpose_bonus = (needs.purpose - 50) * 0.6  # up to +30

    # Harmony bonus for ALL needs being high
    minimum_need = min(all_needs)
    harmony_bonus = max(0, (minimum_need - 70)) * 0.3  # up to +9

    return min(100, base + purpose_bonus + harmony_bonus)
```

---

## Flourishing Tiers

| Score | State | Visible Signs | Behavior |
|-------|-------|---------------|----------|
| 0-30 | Suffering | Withdrawn, sick, angry | Complaints, may leave |
| 30-50 | Struggling | Stressed, tired | Going through motions |
| 50-70 | Stable | Okay, routine | Reliable but not extra |
| 70-85 | Thriving | Happy, social | Contributes, attracts others |
| 85-100 | Flourishing | Radiantly alive | Creates value, inspires |

---

## Flight Risk

Residents may leave if conditions don't improve:

```
flight_risk = base_risk + dissatisfaction + opportunity - attachment

base_risk = ARCHETYPE_BASE[archetype]  // 5-20

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
```

### Flight Risk Thresholds

| Risk Level | Behavior |
|------------|----------|
| < 30 | Stable, unlikely to leave |
| 30-50 | Watchlist, may leave if worse |
| 50-70 | At risk, considering options |
| > 70 for 30 days | Begins looking |
| > 90 | Gives notice |

---

## Warning Signs

Player should see:
- Declining flourishing trend
- Increasing complaints
- Reduced social activity
- Visible unhappiness in portrait

```
UI INDICATOR:

Resident: Maria Chen
Flourishing: 72 → 65 → 58 ⚠️ DECLINING
[██████░░░░]

"I'm starting to wonder if there's
something better out there..."
```

---

## Improving Flourishing

### Quick Fixes
- Address unmet survival needs (food, health)
- Resolve outstanding complaints
- Improve home environment

### Structural Changes
- Reduce commute time
- Improve neighborhood safety
- Create social opportunities

### Community
- Events to build relationships
- Connect isolated residents
- Recognition for contributions

---

## Aggregate Flourishing

For AEI calculation:

```
individual_flourishing = (
    mean(all_residents.flourishing) -
    stdev(all_residents.flourishing) × 0.3  // penalize inequality
)
```

Inequality is penalized - a few flourishing residents and many suffering results in lower score than moderate flourishing for all.

---

## See Also

- [needs.md](./needs.md) - The five needs
- [agents.md](./agents.md) - Individual residents
- [relationships.md](./relationships.md) - Social factors
- [../dynamics/eudaimonia.md](../dynamics/eudaimonia.md) - Win condition (AEI)
- [../../ui/narrative.md](../../ui/narrative.md) - How flourishing is shown
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#flourishing-calculation) - Formula
