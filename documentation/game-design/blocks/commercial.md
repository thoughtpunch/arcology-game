# Commercial Blocks

[← Back to Blocks](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Commercial blocks provide jobs, services, and revenue. They serve residents and visitors.

---

## Retail

| Block | Size | Jobs | Revenue | Needs |
|-------|------|------|---------|-------|
| Small Shop | 1×1 | 2 | $150 | Power, Light, Path, Traffic (10+) |
| Boutique | 1×1 | 3 | $200 | Power, Light (60%+), Traffic (20+) |
| Department Store | 3×3 | 30 | $800 | Power, Light, Freight, Traffic (50+) |
| Grocery | 2×2 | 12 | $300 | Power, Light, Path, Freight |
| Pharmacy | 1×1 | 4 | $180 | Power, Light, Clinic nearby |
| Hardware Store | 1×1 | 4 | $150 | Power, Freight |
| Bookstore | 1×1 | 2 | $100 | Power, Light | +Purpose |

---

## Food & Beverage

| Block | Size | Jobs | Revenue | Needs |
|-------|------|------|---------|-------|
| Restaurant | 1×1 | 4 | $180 | Power, Light, Water, Traffic (20+) |
| Cafe | 1×1 | 2 | $100 | Power, Light, Traffic (15+) |
| Bar | 1×1 | 3 | $120 | Power, Light |
| Nightclub | 2×2 | 10 | $350 | Power (high), Air | Produces noise |
| Fast Food | 1×1 | 4 | $150 | Power, Water, Freight |

### Food Hall (Mega-Block)

```
Size: 5×5×1
Traversability: PUBLIC (people walk through!)
Jobs: 50+
Revenue: Variable (captures through-traffic)
Vibes: +20

SPECIAL: Routes through it, not around it.
Place between zones to capture commuter traffic.
```

---

## Office & Professional

| Block | Size | Jobs | Revenue | Needs |
|-------|------|------|---------|-------|
| Office Suite | 1×1 | 10 | $200 | Power, Light (60%+), Air, Data |
| Coworking Space | 2×2 | 20 | $350 | Power, Light (60%+), Air, Data |
| Law Office | 1×1 | 6 | $250 | Power, Light, Data |
| Medical Office | 1×1 | 4 | $200 | Power, Light, Water |
| Clinic | 2×2 | 6 | $300 | Power, Light, Air, Water |

---

## Services

| Block | Size | Jobs | Revenue | Notes |
|-------|------|------|---------|-------|
| Hair Salon | 1×1 | 3 | $100 | +Belonging |
| Gym | 2×2 | 6 | $200 | +Health, +Belonging |
| Spa | 2×2 | 8 | $350 | +Esteem, luxury |
| Bank Branch | 1×1 | 4 | $180 | Financial access |
| Hotel | 3×3 | 25 | $600 | Visitor housing |

---

## Revenue Calculation

```
revenue = base × level × (
    foot_traffic × 0.35 +
    accessibility × 0.20 +
    cluster_bonus × 0.15 +
    catchment_pop × 0.20 +
    vibes × 0.10
) × (1 - competition_penalty)
```

See [../../quick-reference/formulas.md](../../quick-reference/formulas.md#commercial-revenue) for full formula.

---

## Clustering Effects

### Positive (District Bonuses)
- 3+ restaurants nearby = "dining district" (+20% each)
- Offices near offices = business ecosystem bonus
- Retail clusters = shopping destination effect

### Negative (Competition)
- Two groceries too close = split catchment
- Identical shops adjacent = redundancy penalty

---

## Foot Traffic Requirements

Some blocks need minimum foot traffic to function:

| Block | Minimum Traffic |
|-------|-----------------|
| Small Shop | 10/day |
| Restaurant | 20/day |
| Boutique | 20/day |
| Department Store | 50/day |

Blocks below threshold: **Degraded** status, reduced revenue.

---

## See Also

- [residential.md](./residential.md) - Where customers live
- [transit.md](./transit.md) - How traffic flows
- [../transit/corridors.md](../transit/corridors.md) - Foot traffic system
- [../economy/rent.md](../economy/rent.md) - Revenue mechanics
- [../environment/](../environment/) - Environment requirements
