# Economy System

[← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

The economy is SimCity-style: income from rent/revenue, expenses from maintenance/utilities, monthly cycle.

---

## Contents

| Topic | Description | Link |
|-------|-------------|------|
| **Budget** | Income/expense management | [budget.md](./budget.md) |
| **Rent** | Residential and commercial | [rent.md](./rent.md) |
| **Permits** | Building permissions | [permits.md](./permits.md) |

---

## Quick Overview

### Income Sources

| Source | Driver |
|--------|--------|
| Residential Rent | Occupied units × quality |
| Commercial Revenue | Foot traffic × location |
| Industrial Revenue | Production capacity |
| Commuter Fees | External workers |
| Event Revenue | Arena, convention |

### Expense Categories

| Category | Driver |
|----------|--------|
| Power Operations | Per kW maintained |
| Water/Waste | Per unit capacity |
| HVAC | Per coverage area |
| Security | Per patrol station |
| Transit Operations | Per elevator bank |
| Maintenance | % of structure value |

---

## Monthly Budget Loop

```
Monthly Net = Σ(Income) - Σ(Expenses)

Positive → Treasury grows → Invest in expansion
Negative → Treasury drains → Cut costs or bankruptcy
```

---

## Key Formulas

### Residential Rent
```
rent = base_rent × desirability × demand_multiplier
```
See [rent.md](./rent.md) for details.

### Commercial Revenue
```
revenue = base × (traffic + accessibility + clustering) × (1 - competition)
```
See [rent.md](./rent.md) for details.

### Permit Costs
```
airspace_permit = base × height_multiplier
excavation_permit = base × depth_multiplier
```
See [permits.md](./permits.md) for details.

---

## See Also

- [../blocks/](../blocks/) - Block costs and revenue
- [../environment/](../environment/) - Affects desirability
- [../../architecture/milestones/milestone-5-economy.md](../../architecture/milestones/milestone-5-economy.md) - Implementation
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - All formulas
