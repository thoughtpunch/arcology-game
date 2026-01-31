# CLAUDE.md - Arcology Project Guide

> **For AI assistants (Claude Code, etc.) working on this project**

## MANDATORY: Session Start Greeting

**On the FIRST user message of every session, you MUST greet the user with a status summary.** The SessionStart hook feeds you ticket status via a system reminder — the user CANNOT see this output. You are the only one who sees it. You must relay it.

Your first response must always begin with:

```
Hey Dan! Here's where we are:

**In-progress:** <list any in-progress tickets from the hook output, or "None">
**Ready to work:** <count from hook output> ticket(s)

<If there's an in-progress ticket, add a 1-sentence summary of what it is>
```

Then respond to whatever the user actually said.

**Why this matters:** The session-start hook runs automatically but its output is only visible to you (the AI). Dan has no status bar, no progress indicator, no way to know what you know. This greeting is his only window into the session state. Never skip it.

---

## MANDATORY: Beads Ticket Workflow

**Every piece of work MUST follow this workflow. No exceptions.**

Every change is traceable. Every commit links to a ticket. Every ticket links to its predecessors.
This creates an audit trail so any future agent or human can trace from a commit back to the original design decision (RCA-able).

### The 6-Step Workflow

```
SCAN -> CLAIM/CREATE -> DO -> UPDATE -> CLOSE -> COMMIT
```

**1. SCAN** — Find related tickets before starting anything:
```bash
./scripts/hooks/scan-tickets.sh "keyword1" "keyword2"
bd search "relevant term"
bd list --status in_progress   # Check what's already claimed
```

**2. CLAIM or CREATE** — Every piece of work needs a ticket:
```bash
# Claim an existing ticket:
bd update <id> --status in_progress

# Or create a new one:
bd create "Description of work" -t task -p 2

# If related to a closed ticket, create a linked follow-up:
bd create "Follow-up to arcology-xyz - Description" -t task -p 2 --deps "discovered-from:arcology-xyz"
bd comments add arcology-xyz "Superseded by arcology-abc - <reason>"
```

**3. DO** — Implement the work.

**4. UPDATE** — Add a chain-of-thought comment before closing:
```bash
bd comments add <id> "## What was done
- <change 1>
- <change 2>
- Files: <list>

## Left undone / deferred
- <or 'None'>

## Gotchas
- <anything surprising>"
```

**5. CLOSE** — Close the ticket:
```bash
bd close <id> --reason "Completed"
```

**6. COMMIT** — Commit with ticket ID in the message, then back-link:
```bash
git commit -m "feat: arcology-xyz - Short description"
SHA=$(git rev-parse HEAD)
bd comments add <id> "Commit: $SHA"
```

### Worklog Chain Rules

- **Related to existing ticket (even closed)?** Create a NEW ticket linked via `--deps "discovered-from:<id>"`. This preserves the chain: original decision -> implementation -> follow-up.
- **Brand new work?** Create a fresh ticket. It starts a new chain.
- **Never orphan work.** Every commit traces to a ticket.

### Quick Reference: bd Commands

| Action | Command |
|--------|---------|
| Search | `bd search "keyword"` |
| Ready work | `bd ready` |
| Claim | `bd update <id> --status in_progress` |
| Create | `bd create "Title" -t task -p 2` |
| Comment | `bd comments add <id> "text"` |
| Close | `bd close <id> --reason "Done"` |
| Sync | `./scripts/hooks/bd-sync-rich.sh` |
| Show | `bd show <id>` |
| List in-progress | `bd list --status in_progress` |

---

## Quick Start

**Read these in order:**
1. **This file** - High-level context (you're here)
2. **[documentation/](./documentation/README.md)** - Full wiki-style knowledge base
3. **[documentation/architecture/](./documentation/architecture/)** - Build milestones

**Quick lookups:**
- [documentation/INDEX.md](./documentation/INDEX.md) - Searchable A-Z index
- [documentation/quick-reference/](./documentation/quick-reference/) - Formulas, conventions, math

## What Is Arcology?

A **3D city-builder** where you build vertical megastructures and cultivate human flourishing. Think SimCity + SimTower + Dwarf Fortress.

**Core loop:** Build blocks → People move in → Meet their needs → Watch them flourish (or suffer)

**Win condition:** Not profit. Not population. **Eudaimonia** (human flourishing).

## The 30-Second Pitch

You fight two enemies:
- **Entropy**: Everything decays—buildings, relationships, knowledge
- **Human Nature**: NIMBYism, tribalism, short-term thinking

Your tools: Architecture, infrastructure, community spaces.

## Tech Stack

| What | Choice |
|------|--------|
| Engine | Godot 4.x |
| Language | GDScript (C# for performance-critical) |
| Art | 3D blocks (procedural geometry, placeholder) |
| Data | JSON configs, Godot Resources |

## Key Concepts (Memorize These)

### 1. Everything Is Blocks
The world is a 3D voxel grid. Every structure = blocks snapped to grid.

### 2. Public vs Private Blocks
- **Private** (apartment, restaurant): Pathfinding goes TO it
- **Public** (food hall, atrium, corridor): Pathfinding goes THROUGH it

### 3. Crime Doesn't Climb
Upper floors are naturally safer. This creates organic social geography.

### 4. Light Is Infrastructure
Sunlight is harvested and piped like electricity. Deep interiors need light pipes.

### 5. Five Human Needs
```
PURPOSE     → meaning, growth
ESTEEM      → respect, status  
BELONGING   → relationships
SAFETY      → security
SURVIVAL    → food, shelter, health
```
Lower needs must be met before higher ones matter.

## File Map

```
arcology/
├── CLAUDE.md              ← You are here (context)
├── documentation/         ← Wiki-style knowledge base
│   ├── README.md          ← Documentation entry point
│   ├── INDEX.md           ← Searchable A-Z index
│   ├── quick-reference/   ← Formulas, conventions, math
│   ├── architecture/      ← Build milestones (0-10+)
│   ├── game-design/       ← Blocks, environment, agents, economy
│   ├── technical/         ← Data model, simulation tick
│   ├── ui/                ← Views, overlays, narrative
│   └── agents/            ← AI agent instructions (Ralph)
├── src/                   ← Game code
├── scenes/                ← Godot scenes
├── assets/                ← Sprites, audio
└── data/                  ← JSON configs (blocks, balance)
```

## Current Development Phase

**Check [documentation/architecture/](./documentation/architecture/) for current milestone.**

Milestones 1-10 = Core game loop
Milestones 11-22 = Depth features

## Code Conventions

```gdscript
# Classes: PascalCase
class_name BlockRegistry

# Functions/variables: snake_case
func get_block_at(pos: Vector3i) -> Block:
    
# Signals: past tense
signal block_placed(block)
signal resident_moved_in(resident)

# Constants: UPPER_SNAKE
const CELL_SIZE = 6.0
```

## Common Tasks

### Adding a Block Type
1. Add to `data/blocks.json`
2. Create mesh or use procedural geometry in `src/phase0/`
3. If special behavior needed, create script in `src/blocks/`

### Adding an Environment System
1. Create `src/environment/{system}_system.gd`
2. Connect to `block_placed`/`block_removed` signals
3. Store calculated values on `block.environment.{property}`

### Adding UI
1. Create scene in `scenes/ui/`
2. Script in `src/ui/`
3. Connect to game signals, don't poll

## Data-Driven Philosophy

**Keep numbers out of code:**

```json
// data/balance.json
{
  "light_falloff_per_floor": 20,
  "residential_rent_base": 100
}
```

```gdscript
# Load at runtime
var balance = load_json("res://data/balance.json")
var falloff = balance.light_falloff_per_floor
```

## When You're Stuck

1. Check [documentation/architecture/](./documentation/architecture/) for the current milestone scope
2. Simplify—cut the feature in half
3. Hardcode first, data-drive later
4. Check [documentation/quick-reference/formulas.md](./documentation/quick-reference/formulas.md) for formulas
5. Ask: "Does this need to exist in Milestone N?"

## Key Formulas (Quick Reference)

```
rent = base_rent × desirability × demand

desirability = (light×0.2 + air×0.15 + quiet×0.15 + safety×0.15 + access×0.2 + vibes×0.15)

flourishing = f(survival, safety, belonging, esteem, purpose)
  // Lower needs gate higher ones

AEI = individual(40%) + community(25%) + sustainability(20%) + resilience(15%)
```

## Don't Forget

- [ ] **Every commit MUST reference a ticket ID** (e.g., `arcology-xyz`)
- [ ] **Every ticket MUST have a completion comment** before closing
- [ ] **Use `./scripts/hooks/bd-sync-rich.sh`** instead of bare `bd sync`
- [ ] Blocks are load-bearing (CNC-U material, no structural engineering needed)
- [ ] Cantilevers max 1-2 units in gravity scenarios
- [ ] All environment values propagate (not magic radius)
- [ ] Notable residents (500) get full sim; rest are statistical
- [ ] Overlays: light, air, noise, safety, traffic

---

**Now explore [documentation/](./documentation/README.md) for the full knowledge base.**
