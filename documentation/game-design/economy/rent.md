# Rent & Revenue

[← Back to Economy](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Rent (residential) and revenue (commercial/industrial) are automatically calculated based on block quality and conditions. Players don't manually set prices.

---

## Residential Rent

### Formula

```
base_rent = BLOCK_TYPE_BASE × LEVEL_MULTIPLIER

desirability = (
    light × 0.20 +
    air × 0.15 +
    quiet × 0.15 +
    safety × 0.15 +
    accessibility × 0.20 +
    vibes × 0.15
) / 100

rent = base_rent × desirability × demand_multiplier
```

### Desirability Factors

| Factor | Weight | Source |
|--------|--------|--------|
| Light | 20% | [../environment/light-system.md](../environment/light-system.md) |
| Air | 15% | [../environment/air-system.md](../environment/air-system.md) |
| Quiet | 15% | Inverse of noise |
| Safety | 15% | [../environment/safety-system.md](../environment/safety-system.md) |
| Accessibility | 20% | Commute time to services |
| Vibes | 15% | [../environment/vibes-system.md](../environment/vibes-system.md) |

### Demand Multiplier

```
demand_multiplier = f(
    vacancy_rate,        // Low vacancy = high demand
    population_growth,   // Growing = high demand
    external_pressure    // Immigration pressure
)

Range: 0.5 (oversupply) to 1.5 (high demand)
```

### Base Rent by Type

| Block Type | Base Rent |
|------------|-----------|
| Budget Housing | $50 |
| Standard Housing | $100 |
| Premium Housing | $200 |
| Penthouse | $500 |
| Family Housing | $150 |

---

## Commercial Revenue

### Formula

```
revenue = base × level × (
    foot_traffic × 0.35 +
    accessibility × 0.20 +
    cluster_bonus × 0.15 +
    catchment_pop × 0.20 +
    vibes × 0.10
) × (1 - competition_penalty)
```

### Factors

| Factor | Weight | Description |
|--------|--------|-------------|
| Foot Traffic | 35% | People passing by per day |
| Accessibility | 20% | How easy to reach |
| Cluster Bonus | 15% | District effects |
| Catchment | 20% | Population within range |
| Vibes | 10% | Area quality |

### Clustering Effects

**Positive (District Bonuses):**
- 3+ restaurants = "dining district" (+20% each)
- Offices clustered = business ecosystem (+15%)
- Retail grouped = shopping destination (+20%)

**Negative (Competition):**
- Two groceries too close = split catchment (-30%)
- Identical shops adjacent = redundancy (-15%)

---

## Industrial Revenue

Simpler model:

```
revenue = base × capacity_utilization × market_demand

Factors:
  - Power availability
  - Freight access
  - Worker availability
  - External market conditions
```

More stable but lower margin than commercial.

---

## Revenue Requirements

Some blocks need minimum conditions:

| Block | Requirement |
|-------|-------------|
| Restaurant | Foot traffic ≥ 20 |
| Boutique | Foot traffic ≥ 20, vibes ≥ 50 |
| Office | Light ≥ 60 |
| Grocery | Catchment ≥ 500 |

Below requirement: Degraded status, reduced revenue.

---

## Displaying Projected Revenue

When placing a block, show:

```
┌─────────────────────────────────────┐
│ Placing: Restaurant                 │
│                                     │
│ Location Analysis:                  │
│   Foot Traffic: 45/day ✓            │
│   Vibes: 62 ✓                       │
│   Competition: Low ✓                │
│                                     │
│ Projected Revenue: $180/month       │
│ Construction Cost: $400             │
│ ROI: 2.2 months                     │
└─────────────────────────────────────┘
```

---

## See Also

- [budget.md](./budget.md) - Overall finances
- [../environment/](../environment/) - Affects desirability
- [../blocks/residential.md](../blocks/residential.md) - Housing types
- [../blocks/commercial.md](../blocks/commercial.md) - Commercial types
- [../transit/corridors.md](../transit/corridors.md) - Foot traffic
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#residential-rent) - Formulas
