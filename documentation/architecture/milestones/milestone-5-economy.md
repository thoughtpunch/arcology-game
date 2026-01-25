# Milestone 5: Basic Economy

**Goal:** Money exists, blocks cost money, residential generates rent

---

## Features

### Economy
- Treasury (starting money)
- Blocks have construction cost
- Residential generates rent per game-tick
- Simple monthly cycle

### UI
- Money display
- "Can't afford" feedback
- Monthly income/expense summary

### Balance
- Start with $10,000
- Corridor: $50
- Residential: $500, generates $100/month
- Commercial: $800, generates $200/month (if connected)

---

## Deliverable

Start with money, spend it building, watch rent come in. Can go bankrupt.

---

## Implementation

### Economy Manager

```gdscript
class_name Economy
extends Node

signal money_changed(amount: int)
signal monthly_report(income: int, expenses: int)

var treasury: int = 10000

func can_afford(cost: int) -> bool:
    return treasury >= cost

func spend(amount: int) -> bool:
    if can_afford(amount):
        treasury -= amount
        money_changed.emit(treasury)
        return true
    return false

func earn(amount: int) -> void:
    treasury += amount
    money_changed.emit(treasury)
```

### Block Costs

```gdscript
func place_block(type: String, pos: Vector3i) -> bool:
    var definition = BlockRegistry.get_definition(type)
    var cost = definition.cost

    if not Economy.can_afford(cost):
        show_feedback("Can't afford: $%d needed" % cost)
        return false

    Economy.spend(cost)
    # ... create and place block
    return true
```

### Rent Collection

```gdscript
func collect_monthly_rent() -> int:
    var total_rent = 0

    for pos in Grid.blocks:
        var block = Grid.get_block(pos)
        if block.category == "residential" and block.connected:
            total_rent += calculate_rent(block)
        elif block.category == "commercial" and block.connected:
            total_rent += calculate_revenue(block)

    return total_rent

func calculate_rent(block: Block) -> int:
    # Simple version: base rent only
    # Later: multiply by desirability
    return block.base_rent
```

### Monthly Cycle

```gdscript
func _on_month_end() -> void:
    var income = collect_monthly_rent()
    var expenses = calculate_expenses()
    var net = income - expenses

    Economy.earn(income)
    Economy.spend(expenses)

    monthly_report.emit(income, expenses)

    if Economy.treasury < 0:
        handle_bankruptcy()
```

---

## data/blocks.json Updates

```json
{
  "corridor": {
    "cost": 50,
    "monthly_expense": 5
  },
  "residential_basic": {
    "cost": 500,
    "rent_base": 100
  },
  "commercial_basic": {
    "cost": 800,
    "revenue_base": 200
  }
}
```

---

## data/balance.json

```json
{
  "economy": {
    "starting_money": 10000,
    "month_length_seconds": 60
  }
}
```

---

## UI Layout

```
┌─────────────────────────────────────────┐
│ Treasury: $10,000    Month 1           │
├─────────────────────────────────────────┤
│ Income: $500/mo    Expenses: $100/mo    │
│ Net: +$400/mo                           │
└─────────────────────────────────────────┘
```

---

## Acceptance Criteria

- [ ] Game starts with $10,000
- [ ] Block placement costs money
- [ ] Can't place if insufficient funds
- [ ] "Can't afford" feedback shown
- [ ] Residential generates rent monthly
- [ ] Commercial generates revenue monthly
- [ ] Only connected blocks generate income
- [ ] Money display updates in real-time
- [ ] Monthly summary shows income/expense
- [ ] Treasury can go negative (bankruptcy state)
