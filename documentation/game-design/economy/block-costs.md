# Block Construction Costs

[← Back to Economy](./README.md) | [← Back to Game Design](../README.md) | [← Back to Documentation](../../README.md)

---

## Overview

Block costs are the primary currency sink. Building is the main way players spend money, balanced against ongoing rent/revenue income.

---

## Design Philosophy

### Meaningful Construction

Every block placement should feel **significant**. Costs enforce thoughtful building:

- **Early game**: Limited funds force prioritization
- **Mid game**: Expansion requires planning
- **Late game**: Mega-projects require saving

### No Undo Safety Net

Unlike SimCity's bulldoze-refund, demolished blocks return **0%** of cost. This encourages:

- Planning before building
- Living with mistakes
- Treating the arcology as permanent

---

## Cost Tiers

| Tier | Cost Range | Examples |
|------|------------|----------|
| **Basic** | $50-200 | Corridors, basic utilities |
| **Standard** | $200-800 | Apartments, small shops, stairs |
| **Premium** | $800-2,000 | Large apartments, restaurants, elevators |
| **Luxury** | $2,000-5,000 | Penthouses, anchor stores |
| **Mega** | $5,000-50,000 | Atriums, arenas, medical centers |

---

## Cost by Category

### Transit ($50-500)

| Block | Cost | Rationale |
|-------|------|-----------|
| Corridor | $50 | Cheapest block; connective tissue |
| Stairs | $200 | Vertical access, basic |
| Entrance | $500 | Critical infrastructure, limited |
| Elevator Shaft | $500 | Per floor, adds up |

### Residential ($300-3,000)

| Block | Cost | Capacity | $/Person |
|-------|------|----------|----------|
| Basic Apartment | $500 | 4 | $125 |
| Standard Apartment | $800 | 4 | $200 |
| Large Apartment | $1,200 | 6 | $200 |
| Luxury Apartment | $2,500 | 4 | $625 |
| Penthouse | $5,000 | 2 | $2,500 |

### Commercial ($500-3,000)

| Block | Cost | Jobs | $/Job |
|-------|------|------|-------|
| Small Shop | $800 | 2 | $400 |
| Restaurant | $1,500 | 4 | $375 |
| Office | $1,200 | 8 | $150 |
| Anchor Store | $3,000 | 12 | $250 |

### Industrial ($400-2,000)

| Block | Cost | Jobs | Notes |
|-------|------|------|-------|
| Workshop | $400 | 2 | Small-scale |
| Factory | $1,200 | 8 | Standard |
| Processing Plant | $2,000 | 12 | High output |

### Infrastructure ($200-1,500)

| Block | Cost | Coverage | Notes |
|-------|------|----------|-------|
| Power Node | $500 | 8 blocks radius | Essential |
| Water Pump | $400 | 12 blocks radius | Basic need |
| HVAC Unit | $600 | 6 blocks radius | Comfort |
| Light Pipe | $200 | 4 blocks down | Interior lighting |

### Green ($300-5,000)

| Block | Cost | Radius | Benefit |
|-------|------|--------|---------|
| Planter Box | $300 | 2 | Minor vibes |
| Small Garden | $800 | 4 | Vibes + air |
| Indoor Forest | $5,000 | 8 | Major vibes + air |

### Civic ($1,000-10,000)

| Block | Cost | Notes |
|-------|------|-------|
| Clinic | $2,000 | Basic healthcare |
| School | $3,000 | Education |
| Library | $1,500 | Culture |
| Medical Center | $10,000 | Full healthcare |

---

## Cost Balancing Formulas

### Construction Cost

```
cost = base_cost × size_multiplier × tier_multiplier

size_multiplier = width × depth × height
tier_multiplier = 1.0 (basic) to 3.0 (luxury)
```

### Payback Period

Target: 12-24 months for residential, 6-12 months for commercial.

```
payback_months = construction_cost / monthly_net_income

For residential:
  monthly_net = rent - maintenance - utilities

For commercial:
  monthly_net = revenue - maintenance - utilities - wages
```

### Maintenance Cost

Monthly upkeep = 1-3% of construction cost.

```
maintenance = construction_cost × maintenance_rate

maintenance_rate:
  - Basic blocks: 1%
  - Standard blocks: 2%
  - Complex blocks: 3%
```

---

## Special Cost Rules

### Height Premium

Blocks above floor 10 cost +5% per additional floor:

```
height_premium = max(0, (floor - 10) × 0.05)
final_cost = base_cost × (1 + height_premium)
```

### Foundation Requirement

Ground floor (Z=0) blocks have +20% cost for foundation:

```
if floor == 0:
  cost *= 1.2
```

### Bulk Discount

Placing 5+ of the same block in one action gives -10% discount:

```
if count >= 5:
  cost_per_block *= 0.9
```

---

## Economy Integration

### Starting Treasury

Default: $100,000 (configurable in `data/balance.json`)

This allows:
- ~100 basic corridors OR
- ~20 standard apartments OR
- ~10 commercial spaces OR
- Mix of the above

### Income vs Cost Balance

Target ratios:
- First residential block should generate rent to cover corridor costs in ~3 months
- Commercial should break even in ~6 months
- Player should reach sustainable income within 10-15 blocks

---

## Data Location

Block costs are defined in `data/blocks.json`:

```json
{
  "block_id": {
    "name": "Block Name",
    "cost": 500,
    "maintenance_rate": 0.02,
    ...
  }
}
```

Balance values in `data/balance.json`:

```json
{
  "starting_treasury": 100000,
  "height_premium_start": 10,
  "height_premium_rate": 0.05,
  "bulk_discount_threshold": 5,
  "bulk_discount_rate": 0.10
}
```

---

## See Also

- [budget.md](./budget.md) - Treasury and monthly cycle
- [rent.md](./rent.md) - Income from blocks
- [../blocks/](../blocks/) - Block catalog
- [../../quick-reference/formulas.md](../../quick-reference/formulas.md) - All formulas
- [../../architecture/milestones/milestone-5-economy.md](../../architecture/milestones/milestone-5-economy.md) - Implementation
