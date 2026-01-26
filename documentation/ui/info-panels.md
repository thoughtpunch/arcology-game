# Info Panels

[← Back to UI](./README.md) | [← Back to Documentation](../README.md)

---

## Overview

Info panels display detailed information about selected objects. They appear in the right sidebar when the player clicks on blocks, residents, or other game elements.

---

## Block Info Panel

Displayed when a block is selected.

### Layout

```
┌─────────────────────────────────┐
│ BLOCK INFO                  [×] │
├─────────────────────────────────┤
│ ┌───────┐  Small Apartment      │
│ │ SPRITE│  Floor 12, Pos (4,7)  │
│ │       │  ────────────────     │
│ └───────┘  Status: Occupied     │
├─────────────────────────────────┤
│ OCCUPANTS                       │
│ ┌─┐ Maria Chen (Flourishing: 72)│
│ └─┘ Click to view profile       │
├─────────────────────────────────┤
│ ENVIRONMENT                     │
│ Light    ████████░░  82%        │
│ Air      █████████░  91%        │
│ Noise    ██░░░░░░░░  24         │
│ Safety   ███████░░░  68%        │
│ Vibes    ██████░░░░  63%        │
├─────────────────────────────────┤
│ ECONOMICS                       │
│ Rent         $120/month         │
│ Desirability  0.76              │
│ Maintenance  $15/month          │
│ Net Income   $105/month         │
├─────────────────────────────────┤
│ ACTIONS                         │
│ [Upgrade] [Demolish] [Details]  │
└─────────────────────────────────┘
```

### Data Fields

| Section | Fields |
|---------|--------|
| Header | Name, position, status |
| Occupants | List of residents (if applicable) |
| Environment | Light, air, noise, safety, vibes bars |
| Economics | Rent, desirability, maintenance, net |
| Actions | Context-appropriate buttons |

### Block Statuses

| Status | Color | Description |
|--------|-------|-------------|
| Occupied | Green | Has residents/business |
| Vacant | Yellow | Empty, available |
| Under Construction | Blue | Being built |
| Damaged | Orange | Needs repair |
| Condemned | Red | Uninhabitable |

---

## Resident Info Panel

Displayed when a resident is selected.

### Layout

```
┌─────────────────────────────────┐
│ RESIDENT INFO               [×] │
├─────────────────────────────────┤
│ ┌───────┐  Maria Chen           │
│ │PORTRAIT│  Age: 34             │
│ │       │  Resident: 2 years    │
│ └───────┘  Floor 12, Apt 3      │
├─────────────────────────────────┤
│ FLOURISHING               72 ▲  │
│ ██████████████░░░░░░           │
├─────────────────────────────────┤
│ NEEDS                           │
│ Survival   █████████░  92%  ✓   │
│ Safety     ████████░░  78%  ✓   │
│ Belonging  ██████░░░░  64%  ~   │
│ Esteem     █████░░░░░  52%  ~   │
│ Purpose    ███████░░░  71%  ✓   │
├─────────────────────────────────┤
│ CURRENT ACTIVITY                │
│ 🍳 Making dinner at home        │
│ Next: Sleep (10:00 PM)          │
├─────────────────────────────────┤
│ RELATIONSHIPS              [▼]  │
│ 👤 David Park - Friend          │
│ 👤 James Liu - Coworker         │
│ 👤 Sarah Kim - Neighbor         │
├─────────────────────────────────┤
│ EMPLOYMENT                      │
│ 💼 Chen's Noodle House (Owner)  │
│    Floor 8, Income: $2,400/mo   │
├─────────────────────────────────┤
│ ACTIONS                         │
│ [Follow] [History] [Complaints] │
└─────────────────────────────────┘
```

### Needs Display

| Symbol | Meaning |
|--------|---------|
| ✓ | Need satisfied (>70%) |
| ~ | Need partially met (40-70%) |
| ✗ | Need unmet (<40%) |

### Notable vs Statistical

Only "Notable" residents (500 individuals) have full profiles. Statistical residents show:

```
┌─────────────────────────────────┐
│ STATISTICAL RESIDENT        [×] │
├─────────────────────────────────┤
│ Generic Resident                │
│ (1 of ~2,300 similar)           │
├─────────────────────────────────┤
│ AGGREGATE STATS                 │
│ Avg Flourishing: 68             │
│ Avg Rent Paid: $95/mo           │
│ Common Complaints: Noise        │
└─────────────────────────────────┘
```

---

## Budget Panel

Accessed via top bar or B key.

### Layout

```
┌─────────────────────────────────────────┐
│ BUDGET                          [×] [⚙]│
├─────────────────────────────────────────┤
│ BALANCE           $124,500              │
│ Monthly Net        +$2,400              │
├─────────────────────────────────────────┤
│ INCOME                    $18,200/mo    │
│ ├─ Residential Rent       $12,400       │
│ ├─ Commercial Rent         $4,200       │
│ ├─ Industrial Lease        $1,200       │
│ └─ Permits & Fees            $400       │
├─────────────────────────────────────────┤
│ EXPENSES                  $15,800/mo    │
│ ├─ Maintenance             $4,200       │
│ ├─ Utilities               $3,800       │
│ ├─ Staff Wages             $5,200       │
│ ├─ Security                $1,800       │
│ └─ Debt Service              $800       │
├─────────────────────────────────────────┤
│ TRENDS                      [3M][6M][1Y]│
│     ▁▂▃▄▅▆▇█▇▆▅▆▇█          Income      │
│     ▂▂▃▃▄▄▅▅▆▆▇▇██          Expenses    │
├─────────────────────────────────────────┤
│ PROJECTIONS                             │
│ Next month: +$2,600 (estimate)          │
│ Construction pending: -$12,000          │
│ Loans available: $50,000                │
│                                         │
│ [Take Loan] [View History] [Export]     │
└─────────────────────────────────────────┘
```

### Features

- Expandable categories (click to see details)
- Time range toggle for trends
- Color coding (green income, red expenses)
- Warning indicators for negative trends

---

## AEI Dashboard

The Arcology Excellence Index - your win condition.

### Layout

```
┌─────────────────────────────────────────┐
│ AEI DASHBOARD                   [×] [?] │
├─────────────────────────────────────────┤
│           OVERALL AEI                   │
│              72                         │
│     ████████████████░░░░               │
│     Target: 80 for Bronze              │
├─────────────────────────────────────────┤
│ COMPONENTS                              │
│                                         │
│ Individual Wellbeing (40%)      68      │
│ ████████████████░░░░░░░░               │
│ Avg flourishing, needs met              │
│                                         │
│ Community Cohesion (25%)        74      │
│ █████████████████░░░░░░                │
│ Relationships, civic participation      │
│                                         │
│ Sustainability (20%)            71      │
│ ████████████████░░░░░░░                │
│ Resource efficiency, environment        │
│                                         │
│ Resilience (15%)                78      │
│ ██████████████████░░░░                 │
│ Emergency readiness, diversity          │
├─────────────────────────────────────────┤
│ ACHIEVEMENTS                            │
│ ✓ First 100 residents                   │
│ ✓ Positive cash flow                    │
│ ○ Reach AEI 80 (8 points away)         │
│ ○ 10 flourishing residents             │
├─────────────────────────────────────────┤
│ [Detailed Breakdown] [History]          │
└─────────────────────────────────────────┘
```

### AEI Tiers

| Tier | Score | Reward |
|------|-------|--------|
| Bronze | 80 | New block types unlocked |
| Silver | 90 | Advanced systems |
| Gold | 95 | Endgame content |
| Platinum | 99 | Bragging rights |

---

## Multi-Select Panel

When multiple blocks are selected (Shift+Click or drag):

```
┌─────────────────────────────────┐
│ MULTI-SELECT (12 blocks)    [×] │
├─────────────────────────────────┤
│ SELECTION                       │
│ 8× Small Apartment              │
│ 3× Corridor                     │
│ 1× Elevator                     │
├─────────────────────────────────┤
│ AGGREGATE                       │
│ Total Value     $15,200         │
│ Monthly Income    $640          │
│ Avg Light          74%          │
│ Avg Safety         82%          │
├─────────────────────────────────┤
│ ACTIONS                         │
│ [Upgrade All] [Demolish All]    │
│ [Select Similar] [Clear]        │
└─────────────────────────────────┘
```

---

## Empty State

When nothing is selected:

```
┌─────────────────────────────────┐
│ QUICK STATS                     │
├─────────────────────────────────┤
│ Population       2,847          │
│ Avg Flourishing    68           │
│ Monthly Net    +$2,400          │
│ AEI Score          72           │
├─────────────────────────────────┤
│ ALERTS                          │
│ ⚠ 3 noise complaints            │
│ ⚠ Elevator 2 at capacity        │
├─────────────────────────────────┤
│ Click any block or resident     │
│ to see detailed information.    │
└─────────────────────────────────┘
```

---

## Panel Behavior

### Opening/Closing
- Click object to open relevant panel
- Click [×] or press Esc to close
- Click elsewhere to close (configurable)
- Panels replace each other (one at a time by default)

### Pinning
- Click pin icon to keep panel open
- Pinned panels stack vertically
- Maximum 3 pinned panels

### Scrolling
- Panels scroll if content exceeds height
- Sections collapsible to save space

---

## See Also

- [hud-layout.md](./hud-layout.md) - Panel positioning
- [sidebars.md](./sidebars.md) - Sidebar interactions
- [../game-design/economy/budget.md](../game-design/economy/budget.md) - Budget details
- [../game-design/human-simulation/flourishing.md](../game-design/human-simulation/flourishing.md) - AEI formula
