# Budget & Treasury

[← Back to Economy](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

The arcology has a treasury. Income comes from rent/revenue; expenses come from operations. Monthly cycle.

---

## Income Sources

| Source | Driver | Notes |
|--------|--------|-------|
| Residential Rent | Occupied blocks × desirability | Main income early game |
| Commercial Revenue | Foot traffic × location | Grows with population |
| Industrial Revenue | Production × market | Stable, lower margin |
| Commuter Fees | External workers | If jobs > residents |
| Visitor Spending | Hotel guests, tourists | Requires entertainment |
| Event Revenue | Arena, conventions | Periodic bursts |

---

## Expense Categories

| Category | Driver | Notes |
|----------|--------|-------|
| Power Operations | kW capacity | Scales with size |
| Water/Waste | Unit capacity | Scales with population |
| HVAC | Coverage area | Indoor space dependent |
| Security | Per station | More coverage = more cost |
| Transit Operations | Per elevator bank | Vertical expansion cost |
| Maintenance | % structure value | Never defer this! |
| Debt Service | Loan interest | If loans taken |

---

## Monthly Cycle

Each game month:

1. **Collect Income**
   - Rent from occupied residential
   - Revenue from functioning commercial/industrial
   - Other income sources

2. **Pay Expenses**
   - Operations costs
   - Maintenance (critical!)
   - Loan payments

3. **Calculate Net**
   - Positive: Treasury increases
   - Negative: Treasury decreases

4. **Check Bankruptcy**
   - If treasury negative for 6+ months → Game over

---

## Budget Panel

```
┌─────────────────────────────────────────┐
│ === MONTHLY BUDGET ===                  │
│                                         │
│ INCOME                                  │
│   Residential:  $12,400                 │
│   Commercial:   $8,200                  │
│   Industrial:   $3,600                  │
│   Other:        $1,100                  │
│   -----------                           │
│   Total:        $25,300                 │
│                                         │
│ EXPENSES                                │
│   Power:        $3,500                  │
│   Water/Waste:  $2,100                  │
│   Security:     $1,800                  │
│   Transit:      $2,400                  │
│   Maintenance:  $4,200                  │
│   Debt:         $0                      │
│   -----------                           │
│   Total:        $14,000                 │
│                                         │
│ NET: +$11,300                           │
│ Treasury: $87,500                       │
└─────────────────────────────────────────┘
```

---

## Loans

Can take loans for expansion:

| Loan Type | Amount | Interest | Term |
|-----------|--------|----------|------|
| Small | $10,000 | 5%/year | 5 years |
| Medium | $50,000 | 7%/year | 10 years |
| Large | $200,000 | 10%/year | 20 years |

Monthly payment = principal/months + interest/12

---

## Financial Health Indicators

| Indicator | Good | Warning | Critical |
|-----------|------|---------|----------|
| Net Income | Positive | Break-even | Negative |
| Maintenance Ratio | 100% | 80-99% | <80% |
| Reserves | 6+ months | 3-6 months | <3 months |
| Debt/Income | <30% | 30-50% | >50% |

---

## Starting Conditions

Default scenario:
- Starting Treasury: $10,000
- No loans
- Month length: 60 real seconds

Configurable in `data/balance.json`.

---

## See Also

- [rent.md](./rent.md) - How rent is calculated
- [permits.md](./permits.md) - Permit costs
- [../dynamics/entropy.md](../dynamics/entropy.md) - Maintenance importance
- [../../architecture/milestones/milestone-5-economy.md](../../architecture/milestones/milestone-5-economy.md) - Implementation
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - All formulas
