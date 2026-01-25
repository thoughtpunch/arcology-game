# Eudaimonia & Victory

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

The win condition is not profit, population, or efficiency. It's **eudaimonia**—human flourishing.

---

## Arcology Eudaimonia Index (AEI)

### Formula

```
AEI = (
    individual × 0.40 +
    community × 0.25 +
    sustainability × 0.20 +
    resilience × 0.15
)
```

### Components

| Component | Weight | Description |
|-----------|--------|-------------|
| Individual | 40% | Are residents thriving? |
| Community | 25% | Are they connected? |
| Sustainability | 20% | Is this built to last? |
| Resilience | 15% | Can it survive shocks? |

---

## Component Calculations

### Individual Flourishing

```
individual = (
    mean(all_residents.flourishing) -
    stdev(all_residents.flourishing) × 0.3  // penalize inequality
)
```

Inequality is penalized—a few thriving while many suffer is worse than moderate flourishing for all.

### Community Cohesion

```
community = cohesion_score
```

See [../human-simulation/relationships.md](../human-simulation/relationships.md#community-cohesion).

### Sustainability

```
sustainability = 100 - (
    maintenance_debt_ratio × 30 +
    budget_deficit_months × 10 +
    environmental_damage × 20 +
    knowledge_loss_index × 10
)
```

### Resilience

```
resilience = (
    backup_systems_coverage × 0.25 +
    financial_reserves_months × 0.25 +
    community_mutual_aid_score × 0.25 +
    economic_diversity_index × 0.25
) × 100
```

---

## AEI Dashboard

```
┌──────────────────────────────────────────────────┐
│  ARCOLOGY EUDAIMONIA INDEX: 72 (+2 this year)    │
├──────────────────────────────────────────────────┤
│                                                  │
│  FLOURISHING          COMMUNITY                  │
│  [████████░░] 68      [████████░░] 75            │
│  ↑ improving          → stable                   │
│                                                  │
│  SUSTAINABILITY       RESILIENCE                 │
│  [███████░░░] 71      [██████░░░░] 65            │
│  → stable             ↓ concerning               │
│                                                  │
├──────────────────────────────────────────────────┤
│  ALERTS:                                         │
│  ⚠ 12 residents at high flight risk              │
│  ⚠ Maintenance debt growing (now $240K)          │
│  ⚠ East Wing cohesion declining                  │
└──────────────────────────────────────────────────┘
```

---

## Victory Conditions

### Standard Victories

| Victory | Requirements | Difficulty |
|---------|--------------|------------|
| Sustainable Community | AEI > 70 for 20 years, Pop > 10k | Medium |
| Utopia | AEI > 85 for 30 years, Avg flourishing > 80 | Very Hard |
| Survivor | 50 years, AEI > 50, Never < 70% peak pop | Hard |

### Scenario Victories

| Victory | Requirements | Difficulty |
|---------|--------------|------------|
| Generation Ship | Viable pop 100 years, no immigration | Very Hard |
| Redemption | Inherit failing (AEI 25), raise to 60 in 10 years | Hard |
| Arcosanti (Sandbox) | No condition, just build and track | N/A |

---

## Failure States

| Failure | Trigger |
|---------|---------|
| Bankruptcy | Treasury negative 6+ months |
| Mass Exodus | Population < 50% of peak |
| Collapse | Critical infrastructure failure |
| Civil Breakdown | Cohesion < 10, violence |

These should be difficult to reach through normal play, but possible if warnings are ignored.

---

## Why Eudaimonia Matters

### The Game's Thesis

**Profit-maximizing leads to:**
- Squeezing residents
- Deferred maintenance
- Inequality, short-term thinking
- **Result: Collapse or dystopia**

**Population-maximizing leads to:**
- Overcrowding
- Insufficient infrastructure
- Lost community, anonymity
- **Result: Soul-less megastructure**

**Eudaimonia-maximizing requires:**
- Caring about individual lives
- Building community
- Long-term investment
- Fighting entropy
- Balancing competing needs
- **Result: A place worth living**

**The game teaches: What you optimize for matters.**

---

## See Also

- [../human-simulation/flourishing.md](../human-simulation/flourishing.md) - Individual flourishing
- [../human-simulation/relationships.md](../human-simulation/relationships.md) - Community cohesion
- [entropy.md](./entropy.md) - Sustainability threats
- [human-nature.md](./human-nature.md) - Behavioral challenges
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md#arcology-eudaimonia-index-aei) - AEI formula
