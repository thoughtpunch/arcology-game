# Arcology: Product Requirements Document

**Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Design Phase

---

## Executive Summary

Arcology is a 3D isometric city-builder where players cultivate human flourishing within self-contained megastructures—vertical cities that must balance density, livability, community, and sustainability against the constant forces of entropy and human nature.

Inspired by SimCity's zoning and economy, SimTower's vertical transit obsession, Oxygen Not Included's environmental simulation, and Paolo Soleri's Arcosanti vision, Arcology creates emergent urbanism where every resident is a real person with needs, relationships, and a story.

The core fantasy: **Cultivate human flourishing against entropy and human nature in a self-contained world.**

### Design North Star

The game asks: *Can you design a space where humans flourish, despite entropy constantly pulling everything toward disorder, and human nature constantly pulling toward selfishness, tribalism, and short-term thinking?*

This isn't about profit maximization or population growth. The win condition is **eudaimonia**—residents living meaningful, connected, flourishing lives.

### Core Differentiators

- **"Crime doesn't climb"** — Safety naturally stratifies by elevation, creating organic social geography
- **Light as infrastructure** — Sunlight is harvested, piped, and distributed like power; it's a routable resource
- **Environmental propagation** — Air quality, sound, and safety flow through the structure based on physics, not magic radius
- **Scenario flexibility** — The same core systems support Earth arcologies, Mars colonies, and space stations

### Target Platform

- **Engine:** Godot 4.x (recommended for 2D/isometric, open source, strong community)
- **Art Style:** 16-bit isometric, inspired by classic Fallout, SimCity 2000
- **Platforms:** PC (Steam), Mac, Linux; potential mobile port for tablet

---

## Table of Contents

**Part I: Foundation**
1. [Core Concepts](#1-core-concepts)
2. [Vertical Expansion](#2-vertical-expansion-digging--building-permits)
3. [The Block System](#3-the-block-system)

**Part II: Environmental Systems**
4. [Environmental Systems](#4-environmental-systems)
5. [Infrastructure Systems](#5-infrastructure-systems)
6. [Transit & Pathfinding](#6-transit--pathfinding)

**Part III: Human Simulation**
7. [Human Agents](#7-human-agents)
8. [Needs & Flourishing](#8-needs--flourishing)
9. [Social Networks](#9-social-networks)

**Part IV: Dynamics**
10. [Entropy Systems](#10-entropy-systems)
11. [Human Nature](#11-human-nature)
12. [Eudaimonia & Victory](#12-eudaimonia--victory)

**Part V: Economy & World**
13. [Economy & Budget](#13-economy--budget)
14. [Population & Demographics](#14-population--demographics)
15. [Scenarios & World Settings](#15-scenarios--world-settings)

**Part VI: Experience**
16. [Progression & Unlocks](#16-progression--unlocks)
17. [User Interface](#17-user-interface)
18. [Narrative Systems](#18-narrative-systems)

**Part VII: Technical**
19. [Technical Architecture](#19-technical-architecture)

**Appendices:**
- [Appendix A: Complete Block Catalog](#appendix-a-complete-block-catalog)
- [Appendix B: Formulas Reference](#appendix-b-formulas-reference)
- [Appendix C: Glossary](#appendix-c-glossary)

---

## 1. Core Concepts

### 1.1 Design Philosophy

The arcology is a **3D voxel grid** where each cell (block) can contain structures. Players don't micromanage individuals—they design systems and watch emergence happen.

**Key tensions the game creates:**
- Density vs. livability (more floors = less light below)
- Accessibility vs. quiet (transit brings foot traffic and noise)
- Cost vs. quality (artificial light works, but humans prefer the sun)
- Growth vs. sustainability (expansion strains infrastructure)

### 1.2 Grid Architecture

The arcology is built on a **rectilinear voxel grid**. All blocks align orthogonally with no rotation except 90°.

**Grid Rules:**
- All blocks snap to orthogonal grid positions
- No 45° angles for standard blocks
- Corridors connect at 90° corners only (corner blocks handle turns)
- Exceptions: Escalators (30-45° angle), Pneuma-tubes (any direction)

**Corner and Junction Blocks:**

```
STRAIGHT:   ━━━━    (horizontal)
            ┃       (vertical)
            
CORNERS:    ┏━      ━┓      (top-left, top-right)
            ┗━      ━┛      (bottom-left, bottom-right)

T-JUNCTION: ┳  ┻  ┣  ┫

4-WAY:      ╋
```

Each junction type is a distinct block with proper sprites and pathfinding connections.

### 1.3 The Emergent Envelope

Rather than drawing an envelope separately, **the skin auto-generates on any block face touching "outside."** Players place blocks like Minecraft or LEGO, and exterior panels appear automatically.

**How it works:**
- Each block has 6 faces (top, bottom, north, south, east, west)
- Interior faces (adjacent to another block) = no panel, just interior
- Exterior faces (adjacent to void/outside) = panel auto-generates
- Players can customize panel material on exterior faces

**Panel Materials:**

| Material | Light | Air | Sound | Thermal | Access | Power | Cost | Scenarios |
|----------|-------|-----|-------|---------|--------|-------|------|-----------|
| Solid (concrete/metal) | 0% | 0% | -80% | Insulated | None | 0 | Low | All |
| Glass/Transparent | 90% | 0% | -40% | Poor | None | 0 | Medium | All |
| Mesh/Louver | 60% | 80% | -20% | None | None | 0 | Medium | Earth only |
| Solar Panel | 0% (harvests) | 0% | -60% | Insulated | None | Generates | High | All |
| Garden (roof only) | 70% | 50% | -40% | Good | None | 0 | High | Earth only |
| Void (open) | 100% | 100% | 0% | None | Full | 0 | Free | Earth only |
| Force Field | 95% | 0% | -20% | Partial | Full | High draw | Very High | Mars/Space |

**Force Fields (Mars/Space scenarios):**

Force fields permit light and physical access while maintaining atmospheric seal:

```
FORCE FIELD PANEL
Tech Level: 3+
Scenarios: Mars, Space Station, Advanced Earth

Light transmission: 95% (slight shimmer effect)
Air transmission: 0% (perfect seal)
Sound transmission: -20% (hum of the field)
Access: Full (people, vehicles can pass through)

Power draw: 10 units per panel (continuous)
Failure mode: Power loss = decompression event

Visual: Subtle blue/purple shimmer, edge glow
```

**Force Field Use Cases:**
- Hangar bays (ships enter without airlock cycling)
- Observation decks with unobstructed views
- Loading docks maintaining atmosphere
- "Open air" rooftop parks in sealed environments

**Emergent Block Types:**

| "Special" Element | Actually Is |
|-------------------|-------------|
| Helipad | 1×1 block, void roof + walls (Earth) or force field (Mars) |
| Rooftop Garden | Block with garden-type roof panel |
| Solar Collector | Block with solar roof panel |
| Balcony | Residential block with one void wall panel |
| Observatory | Block with glass walls + glass roof |
| Skylight | Block below has glass roof panel |

**User Stories:**

> **US-1.4:** As a player, I want blocks to automatically create exterior walls/roof when facing outside, without manually drawing an envelope.

> **US-1.5:** As a player, I want to customize panel materials (glass, solid, solar) on exterior faces to control light, air, and aesthetics.

> **US-1.6:** As a player on Mars/Space, I want force fields to give me "open" feeling spaces while maintaining life support seal.

> **US-1.7:** As a player, I want a helipad to just be a block with open panels, not a special unique element.

### 1.4 Structural Rules (Carbonic Nano-Cement)

All blocks are constructed from **Carbonic Nano-Cement with Embedded Unobtainium (CNC-U)**—an advanced composite material that allows every block to act as a load-bearing structural member. This simplifies construction: players don't need to worry about columns, beams, or load paths for most builds.

**Why This Works (In-Universe):**
- CNC-U has exceptional compressive AND tensile strength
- Embedded unobtainium fibers distribute loads in all directions
- Each block bonds molecularly to adjacent blocks
- The material self-heals minor cracks over time
- Standard blocks can support 50+ floors of vertical load

**Cantilever Rules (Earth/Mars Gravity):**

In scenarios with significant gravity, unsupported horizontal extensions are limited:

| Extension Type | Max Cantilever | Notes |
|----------------|----------------|-------|
| Standard Block | 1 unit | Any block can extend 1 unit into void |
| Reinforced Block | 2 units | Upgrade option, costs 2x |
| Skybridge | 10 units | Special block type, must anchor both ends |
| Balcony | 1 unit | Residential with void wall panel |
| Observation Deck | 2 units | Glass-enclosed, reinforced |

```
VALID CANTILEVER (1 unit):
  [Block][Block][Block]
               └──[Block] ← supported by adjacent block

VALID CANTILEVER (2 units, reinforced):
  [Block][Block][Block]
               └──[Reinforced][Reinforced]

INVALID (3+ units without support):
  [Block][Block][Block]
               └──[Block][Block][Block] ← COLLAPSE!

VALID SKYBRIDGE:
  [Block]                    [Block]
        └──[Bridge][Bridge][Bridge]┘
           anchored both ends
```

**Low/Zero Gravity Scenarios:**

In space stations and low-gravity environments, cantilever restrictions are removed:
- Any block can extend in any direction
- Still requires path connectivity for construction access
- Structural integrity becomes about hull pressure, not gravity loads

**Collapse Events:**

If a player somehow creates an invalid cantilever (through demolition or damage):
- Warning appears: "Structural instability detected"
- 24-hour grace period to add support
- After grace period: collapse event (blocks fall, damage below, casualties possible)
- Collapsed blocks leave debris that must be cleared

**User Stories:**

> **US-1.8:** As a player, I want to build without worrying about structural engineering for normal construction.

> **US-1.9:** As a player, I want clear feedback when I'm creating an unsupported cantilever that will collapse.

> **US-1.10:** As a player on a space station, I want to build in any direction without gravity restrictions.

---

## 2. Vertical Expansion (Digging & Building Permits)

### 2.1 The Ground Plane

Every map has a **ground plane at Z=0**. This is where external connections exist (Grand Terminal, ground-level entry). The arcology can expand in two directions:

- **Above grade (Z > 0):** Building upward into airspace
- **Below grade (Z < 0):** Digging downward into subterranean levels

Both directions require **permits** that cost money, with costs scaling based on depth/height.

### 2.2 Map Vertical Limits

Each scenario defines vertical boundaries:

| Scenario | Max Height | Max Depth | Notes |
|----------|-----------|-----------|-------|
| Urban Arcology | +50 floors | -10 floors | Zoning limits height; subway/utilities limit depth |
| Remote Arcology | +100 floors | -20 floors | Fewer restrictions |
| Mars Colony | +30 floors | -50 floors | Dig into rock for radiation shielding |
| Space Station | ±20 floors | ±20 floors | Symmetrical; no "ground" concept |
| Pyramid Arcology | +200 floors | -5 floors | Height is the point; limited digging |

### 2.3 Airspace Permits (Building Up)

Building above grade requires **airspace permits** with escalating costs:

```
permit_cost = BASE_PERMIT × HEIGHT_MULTIPLIER[floor]

HEIGHT_MULTIPLIER:
  Floors 1-10:   1.0x
  Floors 11-20:  1.5x
  Floors 21-30:  2.0x
  Floors 31-50:  3.0x
  Floors 51-75:  5.0x
  Floors 76-100: 8.0x
  Floors 100+:   12.0x
```

**Structural considerations (optional complexity):**
- Taller buildings may require reinforced lower floors
- Or simply: permit cost abstracts all structural requirements

**Benefits of height:**
- More natural light (closer to sky)
- Better air quality (above pollution, natural ventilation)
- Higher safety (crime doesn't climb)
- Premium vibes (views, prestige)
- Solar collection efficiency

### 2.4 Excavation Permits (Digging Down)

Digging below grade requires **excavation permits** with escalating costs:

```
permit_cost = BASE_EXCAVATION × DEPTH_MULTIPLIER[floor]

DEPTH_MULTIPLIER:
  Floors -1 to -3:   1.0x
  Floors -4 to -6:   1.5x
  Floors -7 to -10:  2.5x
  Floors -11 to -20: 4.0x
  Floors -20+:       6.0x
```

Excavation is generally cheaper than airspace (digging is easier than building tall), but the resulting space is less desirable.

### 2.5 Subterranean Penalties

Every level below grade has **inherent penalties** that must be mitigated:

| Depth | Light Penalty | Air Penalty | Vibes Penalty | Crime Bonus |
|-------|--------------|-------------|---------------|-------------|
| Z = -1 | -20% | -10% | -15 | +10 |
| Z = -2 | -40% | -20% | -25 | +15 |
| Z = -3 | -60% | -30% | -35 | +20 |
| Z = -4 to -6 | -80% | -40% | -45 | +25 |
| Z = -7 to -10 | -95% | -50% | -55 | +30 |
| Z = -10+ | -100% (no natural light possible) | -60% | -65 | +35 |

**What this means:**
- **Light:** Natural light cannot penetrate below ~Z=-3 even with skylights. Deep levels require artificial or piped light exclusively.
- **Air:** Fresh air doesn't circulate down; requires HVAC or vertical shafts.
- **Vibes:** Humans inherently dislike being underground; requires heavy aesthetic investment.
- **Crime:** Isolation + darkness = crime magnet; requires security investment.

### 2.6 Subterranean Mitigation Strategies

To make below-grade levels habitable/productive:

| Strategy | Effect | Cost |
|----------|--------|------|
| Light wells / Atriums punching down | Brings natural light to depth -3 max | Lost buildable volume |
| Light pipes from roof | 40-60% effective light at any depth | Infrastructure investment |
| High-quality artificial lighting | 35% effective (max) | Power cost |
| HVAC with fresh air intake | Restores air quality to 70-80% | Power + infrastructure |
| Indoor gardens (subterranean) | +Air, +Vibes in radius | Water + artificial light cost |
| Premium finishes / Aesthetics | +10-20 Vibes | Construction cost |
| Security stations | Crime suppression radius | Operating cost |
| High foot traffic design | Natural crime deterrent | Layout constraints |

### 2.7 Ideal Uses by Elevation

The permit costs and environmental factors create natural zoning:

**Upper Floors (Z > 20):**
- Premium/luxury residential (sun, views, safety, vibes)
- Executive offices (prestige)
- Rooftop parks, solar collectors
- Observation decks, high-end entertainment

**Mid Floors (Z = 5-20):**
- Standard residential
- General offices
- Retail, restaurants
- Schools, clinics
- Sky lobbies

**Ground Level (Z = 0):**
- Grand Terminal, main entry
- High-traffic retail
- Security checkpoints
- Lobbies

**Shallow Subterranean (Z = -1 to -3):**
- Parking (if vehicles exist)
- Storage, warehousing
- Light industrial
- Budget retail (discount stores)
- Transit stations (subway-style)
- Nightclubs, entertainment (no windows needed)

**Deep Subterranean (Z = -4 to -10):**
- Heavy industrial (noise/pollution contained)
- Power plants (especially nuclear)
- Water treatment
- Data centers (cool, secure)
- Warehousing, freight logistics
- Budget/subsidized housing (with heavy mitigation)

**Very Deep (Z < -10):**
- Specialized industrial
- Emergency bunkers
- Resource extraction (Mars scenario)
- Generally inhospitable for habitation

### 2.8 The Vertical Economy

This creates interesting economic dynamics:

**Land value gradient:**
```
Premium ← [Upper floors] ← [Mid floors] ← [Ground] → [Shallow sub] → [Deep sub] → Cheap
```

**Development strategies:**

1. **Luxury tower:** Invest heavily in airspace permits; build premium residential up top, let high rents pay for the permits.

2. **Industrial basement:** Dig cheap subterranean levels for industry; pollution and noise contained underground; revenue from exports.

3. **Balanced arcology:** Mix of heights; use underground for infrastructure/industrial, ground for commercial, upper for residential.

4. **Bunker mentality (Mars/Space):** Dig deep for radiation protection; accept subterranean penalties as survival cost.

### 2.9 Permit Purchase Interface

**User Stories:**

> **US-2.9.1:** As a player, I want to see my current vertical boundaries (how high I can build, how deep I can dig) clearly displayed.

> **US-2.9.2:** As a player, I want to purchase permits floor-by-floor or in batches, seeing the escalating costs.

> **US-2.9.3:** As a player, I want to understand why upper floors cost more (permits) but generate more rent (premium space).

> **US-2.9.4:** As a player, I want excavation to feel like a strategic choice—cheap space but requires investment to make usable.

> **US-2.9.5:** As a player, I want the permit system to create tension between "build up expensive but premium" vs "dig down cheap but challenging."

> **US-2.9.6:** As a player, I want scenario-specific vertical limits that make sense (Mars = dig deep for protection; Urban = height limits from zoning).

### 2.10 Vertical Expansion UI

**Vertical Profile View:**
```
┌─────────────────────────────────────────────┐
│ VERTICAL PROFILE                            │
├─────────────────────────────────────────────┤
│ MAX HEIGHT: +50        [Purchase +5: §500K] │
│                                             │
│ +50 ░░░░░░░░░░░░░░░░░░░░ (limit)           │
│ +40 ░░░░░░░░░░░░░░░░░░░░ (permitted)       │
│ +30 ████░░░░░░░░░░░░░░░░ (built)           │
│ +20 ████████████░░░░░░░░                    │
│ +10 ████████████████████                    │
│   0 ████████████████████ ← GROUND          │
│ -10 ████████░░░░░░░░░░░░                    │
│ -20 ░░░░░░░░░░░░░░░░░░░░ (permitted)       │
│ -30 ░░░░░░░░░░░░░░░░░░░░ (limit)           │
│                                             │
│ MAX DEPTH: -30         [Purchase -5: §200K] │
├─────────────────────────────────────────────┤
│ ████ = Built   ░░░░ = Permitted/Available   │
└─────────────────────────────────────────────┘
```

**Subterranean Warning Overlay:**
When placing blocks below grade, show:
- Current depth penalties
- Mitigation requirements
- Projected viability score

---

## 3. The Block System

### 3.1 Block Fundamentals

A **block** is the atomic unit of construction. Everything in the arcology is made of blocks.

**Block Sizes:**

| Size | Footprint | Examples |
|------|-----------|----------|
| Small | 1×1×1 | Apartment, shop, corridor, utility closet |
| Medium | 2×2×1 or 2×2×2 | Restaurant, clinic, small office floor |
| Large | 3×3×2 or 4×4×2 | Grocery, school, transit hub |
| Mega | 5×5×3+ | Indoor forest, arena, atrium (special rules) |

**Block Data Model:**

```
Block {
  id: unique identifier
  type: residential | commercial | industrial | civic | infrastructure | green | transit
  size: small | medium | large | mega
  level: 1-5 (upgrade tier)
  allocation: player-placed | zoned
  
  // Computed from environment
  sunlight: 0-100
  air_quality: 0-100
  safety: 0-100
  vibes: 0-100
  accessibility: 0-100
  noise: 0-100 (negative factor)
  
  // Economic
  occupancy: vacant | occupied
  rent: calculated from above
  maintenance_cost: per month
}
```

### 3.2 Block Schema: Needs / Preconditions / Produces / Unlocks

Every block type has four key attributes:

| Attribute | Description |
|-----------|-------------|
| **Needs** | Resources consumed continuously; block fails/degrades without them |
| **Preconditions** | Requirements that must exist before placement |
| **Produces** | Resources or effects generated continuously |
| **Unlocks** | Other blocks, features, or achievements enabled by this block |

**User Stories:**

> **US-3.1:** As a player, I want to see exactly what a block needs before I place it, so I don't build something that immediately fails.

> **US-3.2:** As a player, I want to understand what a block produces so I can plan my infrastructure networks.

> **US-3.3:** As a player, I want blocks to visually indicate their status (powered, occupied, failing) without needing to open menus.

> **US-3.4:** As a player, I want to upgrade existing blocks to higher quality tiers rather than demolishing and rebuilding.

> **US-3.5:** As a player, I want to zone areas for automatic development (like SimCity) rather than placing every single block manually.

### 3.3 Zoning Mechanic

Players can designate areas as **zoned** for a category (residential, commercial, industrial). Tenants automatically fill zoned blocks if:

- The zone is connected (power, water, path access)
- Environmental quality meets tenant threshold
- There's demand (population wants housing, businesses want storefronts)

**Tenant Matching:**

| Tenant Type | Requirements | Rent Multiplier |
|-------------|--------------|-----------------|
| Luxury Residential | Sunlight > 70, Vibes > 80, Safety > 70 | 5x |
| Standard Residential | Sunlight > 40, Vibes > 50, Safety > 50 | 2x |
| Budget Residential | Sunlight > 20, Vibes > 30 | 1x |
| Premium Office | Accessibility > 80, Light > 60 | 4x |
| Standard Office | Accessibility > 60 | 2x |
| Retail | Foot Traffic > 50, Accessibility > 50 | Variable |
| Industrial | Freight Access, tolerates low vibes | 0.5x |

**User Stories:**

> **US-3.6:** As a player, I want to paint zones across multiple blocks quickly so I don't click hundreds of times.

> **US-3.7:** As a player, I want to see why a zoned area isn't filling (missing power? too dark? no demand?) so I can fix the problem.

> **US-3.8:** As a player, I want tenant types to naturally stratify based on my design—penthouses should attract luxury tenants without me forcing it.

### 3.4 Block Traversability (Public vs Private)

Blocks have a fundamental traversability property that affects pathfinding:

| Type | Pathfinding Role | Example | Real-World Analog |
|------|------------------|---------|-------------------|
| **Public (Traversable)** | Route THROUGH as shortcut | Food Hall, Atrium, Park, Mall | Shopping mall concourse |
| **Private (Destination)** | Route TO/FROM only | Restaurant, Apartment, Office | Individual store |

**Public Blocks (Route Through):**

| Block | Entry Points | Traversal Speed | Cost Modifier |
|-------|--------------|-----------------|---------------|
| Corridor | 2-4 | 1.0 | 1.0 |
| Atrium | 2-4 | 1.0 | 0.85 (pleasant) |
| Food Hall | 3-4 | 0.9 | 0.95 |
| Market Hall | 2-4 | 0.85 | 0.9 |
| Mall/Galleria | 2-4 | 0.85 | 0.9 |
| Park/Garden (interior) | 2-4 | 0.8 | 0.85 |
| Indoor Forest | 2-4 | 0.7 | 0.8 |
| Lobby | 2-4 | 1.0 | 1.0 |
| Sky Lobby | 2-4 | 1.0 | 1.0 |
| Plaza | 2-4 | 1.0 | 0.9 |

**Private Blocks (Destination Only):**

| Block | Entry Points | Notes |
|-------|--------------|-------|
| All Residential | 1 | Home is private |
| Restaurant | 1 | Dining destination |
| Cafe | 1 | Seating destination |
| Bar | 1 | Destination |
| Office Suite | 1 | Work destination |
| Retail Shop | 1 | Shopping destination |
| Grocery | 1-2 | Shopping destination |
| Clinic | 1 | Service destination |
| All Industrial | 1-2 (freight) | Work destination |

**Pathfinding Cost Calculation:**

```
edge_cost = (distance / traversal_speed) × cost_modifier

Lower cost = preferred route
Agents will detour through an Atrium even if slightly longer
  because the cost_modifier makes it "cheaper"
```

**User Stories:**

> **US-3.9:** As a player, I want public spaces (Food Hall, Atrium) to naturally attract foot traffic because people route through them.

> **US-3.10:** As a player, I want private spaces (apartments, restaurants) to be destinations, not shortcuts.

### 3.5 Build Constraints and Prerequisites

Each block type has **adjacency rules** that govern placement:

```
Block {
  constraints: {
    can_build_above: true | false | [list of types]
    can_build_below: true | false | [list of types]
    can_build_adjacent: true | false | [list of types]
    requires_below: true | [list of types]  // structural support
    clearance_above: int  // floors that must be empty
    clearance_radius: int // horizontal blocks that must be empty
    max_stack: int  // how many can stack vertically
    must_touch_exterior: bool  // needs outside wall
    must_touch_ground: bool  // Z=0 only
  }
}
```

**Example Constraints:**

| Block | Key Constraints | Why |
|-------|-----------------|-----|
| Helipad | `can_build_above: false`, `clearance_above: 5`, `must_touch_exterior: true` | Flight path clearance |
| Rooftop Garden | `can_build_above: false`, `roof_panel: garden` | Needs sky |
| Atrium | `can_build_above: [atrium]`, `can_build_adjacent: true` | Vertical void |
| Elevator Shaft | `can_build_above: [elevator, sky_lobby]`, `max_stack: 30` | Must be continuous |
| Solar Collector | `roof_panel: solar`, `must_touch_exterior: true` | Needs sun |
| Heavy Industrial | `requires_below: true`, `clearance_radius: 1` from residential | Buffer |
| Grand Terminal | `must_touch_ground: true`, `must_touch_exterior: true` | External access |
| Penthouse | `can_build_above: false` | Top floor only |
| Water Tower | `can_build_above: false` | Pressure mechanics |

**Placement Validation UI:**
- Green ghost = valid placement
- Red ghost = invalid, with tooltip explaining why
- Yellow ghost = valid but warning (e.g., "This will block light to floors below")

**User Stories:**

> **US-3.11:** As a player, I want to see why I can't place a block somewhere (clearance issue? missing prerequisite?).

> **US-3.12:** As a player, I want the game to prevent me from building a helipad with something above it.

### 3.6 Expanded Block Data Model

```
Block {
  id: unique identifier
  type: string
  tags: [transit, utility, residential, commercial, food, public, private, mega, ...]
  size: small | medium | large | mega
  level: 1-5 (upgrade tier)
  allocation: player-placed | zoned
  
  // Panels (auto-generated on exterior faces)
  panels: {
    top: panel_material | null (if interior face)
    bottom: panel_material | null
    north: panel_material | null
    south: panel_material | null
    east: panel_material | null
    west: panel_material | null
  }
  
  // Traversability
  traversability: public | private
  entry_points: {north: bool, south: bool, east: bool, west: bool}
  traversal_speed: float  // 1.0 = normal
  traversal_cost_modifier: float  // lower = preferred route
  
  // Build Constraints
  constraints: {
    can_build_above: bool | [types]
    can_build_below: bool | [types]
    requires_below: bool | [types]
    clearance_above: int
    clearance_radius: int
    must_touch_exterior: bool
    must_touch_ground: bool
  }
  
  // Computed from environment
  sunlight: 0-100
  air_quality: 0-100
  safety: 0-100
  vibes: 0-100
  accessibility: 0-100
  noise: 0-100 (negative factor)
  
  // Resource needs
  needs: {power: int, water: int, light: int, air: int, ...}
  
  // What this block is receiving
  receiving: {power: int, water: int, light: int, air: int, ...}
  
  // Status
  status: functioning | degraded | failing
  occupancy: vacant | occupied
  rent: calculated
  maintenance_cost: per month
}
```

---

## 4. Environmental Systems

### 4.1 Light System

Light is the game's signature resource. It propagates from sources, attenuates through space, and can be **routed as infrastructure**.

**Light Sources:**

| Source | Quality | Notes |
|--------|---------|-------|
| Direct Sky (roof/top floor) | 100% | Only available at top surface |
| Exterior Window | 70-90% | Penetrates 1-2 blocks deep |
| Atrium (mega-block void) | 80-85% | Carries light to interior-facing blocks |
| Skylight | 70-80% | Roof penetration for floor directly below |
| Light Pipe (fiber optic) | 60-80% | Routes harvested sunlight deep into structure |
| Solar-to-LED Conversion | 40-50% | Collected sun powers full-spectrum LEDs |
| Pure Artificial | 25-35% effective | Electric lights, no sun input |

**Light Pipe Infrastructure:**

Players can build **solar collectors** on the roof that feed into a **light pipe network**. Light pipes route natural light deep into the structure, losing efficiency with distance and bends.

```
[Roof Solar Collector] → 100% light harvested
       ↓ (vertical pipe)
[Junction - Floor 15] → 90% efficiency
       ↓        → [Horizontal branch to interior office]
[Junction - Floor 5] → 75% efficiency
       ↓
[Deep Interior - Floor 1] → 65% effective light
```

Blocks receiving piped natural light get **better happiness than pure artificial** but less than direct windows.

**User Stories:**

> **US-4.1:** As a player, I want to see a light overlay showing which blocks get natural light vs artificial so I can optimize placement.

> **US-4.2:** As a player, I want building additional floors above to visibly darken the floors below, creating real tradeoffs.

> **US-4.3:** As a player, I want to invest in light pipe infrastructure to make deep interior spaces livable without just accepting unhappy residents.

> **US-4.4:** As a player, I want the light budget displayed somewhere—how much I'm harvesting, distributing, and where deficits exist.

> **US-4.5:** As a player, I want atriums (vertical voids) to carry light downward, making them valuable despite "wasting" buildable space.

### 4.2 Air Quality System

Air quality propagates from sources and degrades with distance, population density, and pollution sources.

**Air Sources:**

| Source | Quality | Radius/Effect |
|--------|---------|---------------|
| Exterior Opening | 100% (fresh) | Limited penetration |
| Indoor Forest/Garden (mega) | 100% (fresh) | Large radius, actively scrubs CO2 |
| HVAC Central | 70-80% (processed) | Large radius, requires power |
| HVAC Vent | 60-70% (processed) | Small radius, extends HVAC reach |
| Plants/Greenery (small) | +10-20% local | Adjacency bonus |

**Air Degradation:**

- Distance from fresh air source
- Population density (people consume air quality)
- Industrial blocks (pollution source)
- Fires, disasters (temporary severe degradation)

**User Stories:**

> **US-4.6:** As a player, I want to see an air quality overlay showing fresh vs stale areas.

> **US-4.7:** As a player, I want indoor forests to be functionally necessary for deep arcologies, not just aesthetic.

> **US-4.8:** As a player, I want HVAC to extend my habitable zone but never fully replace fresh air quality.

### 4.3 Sound/Noise System

Noise propagates from sources, attenuates with distance, and is blocked/reduced by walls.

**Noise Sources:**

| Source | Noise Level | Notes |
|--------|-------------|-------|
| Industrial Block | High (60-80) | Constant |
| Transit Hub | Medium-High (40-60) | Constant, higher at rush hour |
| Arena/Entertainment | Very High (80+) | During events only |
| High Foot Traffic Corridor | Medium (30-50) | Time-of-day variable |
| Restaurant/Bar | Low-Medium (20-40) | Evening peak |
| Foot Traffic | Variable | See traffic noise model below |

**Foot Traffic Noise Model:**

Corridors generate noise proportional to their traffic load:

```
traffic_noise = current_traffic × NOISE_PER_PERSON[corridor_type]

NOISE_PER_PERSON:
  Small corridor (1×1):    0.8 (echoes in tight space)
  Medium corridor (2×1):   0.5 (standard)
  Large corridor (3×2):    0.3 (dispersed, high ceiling absorbs)
  Grand Promenade (5×2):   0.2 (very dispersed)
```

| Corridor Type | Max Capacity | At Full Capacity Noise |
|---------------|--------------|------------------------|
| Small | 20 people | 16 |
| Medium | 50 people | 25 |
| Large | 150 people | 45 |
| Grand Promenade | 400 people | 80 |

**Noise Propagation to Adjacent Blocks:**

```
Corridor noise affects neighbors:

[Residential] [CORRIDOR: noise 40] [Residential]
    ↑                                    ↑
 Receives 80%                      Receives 80%

Propagation by distance:
  Immediate neighbor: 80% of corridor noise
  One block away: 40%
  Two blocks away: 15%

Wall type affects propagation:
  Solid wall: 50% reduction
  Glass wall: 20% reduction
  Open/void: 0% reduction
```

**Noise Mitigation:**

| Upgrade | Noise Reduction | Vibes | Cost | Notes |
|---------|-----------------|-------|------|-------|
| Acoustic Ceiling Panels | -15 | +3 | §200 | Absorbs echo |
| Acoustic Wall Panels | -10 | +2 | §150 | Side absorption |
| Carpet/Soft Flooring | -10 | +5 | §200 | Muffles footsteps |
| Plants/Greenery | -5 | +8 | §200 | Natural absorption |
| Living Wall | -10 | +15 | §500 | Significant absorption |
| Water Feature | -5 (masks) | +12 | §400 | White noise masking |
| High Ceiling (Large+ corridors) | -10 | +10 | Built-in | Sound disperses up |

**Sound Generators (Add Noise + Add Vibes):**

| Upgrade | Noise Added | Vibes Added | Cost | Notes |
|---------|-------------|-------------|------|-------|
| Nature Sounds | +5 | +10 | §150 | Birds, water, forest |
| Ambient Music | +8 | +8 | §200 | Background music |
| Fountain (active) | +10 | +15 | §400 | Active water feature |
| Street Performer Spot | +15 | +12 | §100 | Designated busker zone |

**Effective Noise Calculation:**

```
effective_noise = (
    traffic_noise
    + sound_generators_noise
    - acoustic_mitigation
)
// Floor at 0 (can't go negative)
effective_noise = max(0, effective_noise)
```

**User Stories:**

> **US-4.9:** As a player, I want residential blocks adjacent to noisy areas to show reduced desirability.

> **US-4.10:** As a player, I want to see noise overlay to identify problem areas.

> **US-4.11:** As a player, I want buffer zones (corridors, commercial) between industrial/transit and residential to be a valid design strategy.

> **US-4.18:** As a player, I want to add nature sounds or music to corridors for vibes, understanding it adds some noise.

> **US-4.19:** As a player, I want larger corridors to generate less noise per person than cramped hallways.

### 4.4 Safety/Crime System

**"Crime doesn't climb."** This is a core design principle.

**Crime Propagation:**

- Flows easily **horizontally**
- Flows easily **downward**
- Resists flowing **upward**
- Amplified by: darkness, vacancy, low foot traffic, distance from security
- Blocked by: security checkpoints, access control, high foot traffic, lighting

**Natural Safety Gradient:**

| Level | Natural Safety | Why |
|-------|---------------|-----|
| Basement/Sub | Very Low | Hidden, dark, escape routes |
| Ground Floor | Low | Public access, street crime enters |
| Low Floors (1-5) | Medium-Low | Easy stair access |
| Mid Floors (6-15) | Medium | Elevator-dependent |
| Upper Floors (16+) | High | Hard to reach, nowhere to flee |
| Penthouse | Very High | Single access point, visible |

**Security Infrastructure:**

| Block | Effect |
|-------|--------|
| Security Station | Safety radius, patrol dispatch |
| Security Checkpoint | Blocks crime propagation upward at that point |
| Cameras | Extends coverage cheaply but less effectively |
| Good Lighting | Reduces crime attraction |
| High Foot Traffic | "Eyes on the street" effect |

**User Stories:**

> **US-4.12:** As a player, I want crime to naturally concentrate in dark, isolated, low-level areas without me scripting it.

> **US-4.13:** As a player, I want upper floors to feel naturally safer, creating real value for height.

> **US-4.14:** As a player, I want security checkpoints to create "safe zones" that crime can't easily penetrate.

> **US-4.15:** As a player, I want vacancy and darkness to create crime feedback loops—abandoned areas get worse, forcing intervention.

### 4.5 Vibes/Aesthetics System

"Vibes" is a composite quality-of-life score:

```
vibes = (
    effective_light × 0.25 +
    effective_air × 0.20 +
    greenery_proximity × 0.15 +
    aesthetics × 0.10 +
    quiet × 0.15 +          // inverse of noise
    safety × 0.15
)
```

**Vibes Boosters:**

- Proximity to parks/gardens/greenery
- Art installations (decorative blocks)
- High-quality neighboring blocks
- Views (exterior-facing, atrium-facing)
- Water features

**User Stories:**

> **US-4.16:** As a player, I want a "vibes" overlay that shows me the overall desirability map of my arcology.

> **US-4.17:** As a player, I want to understand why a block has low vibes so I can improve it.

---

## 5. Infrastructure Systems

### 5.1 Power System

Power is a **network resource**—blocks are either connected to the grid or not, and the grid has capacity limits.

**Power Generation:**

| Block | Output | Needs | Notes |
|-------|--------|-------|-------|
| Solar Array | Variable | Natural Light | Clean, depends on sun/season |
| Fossil Plant | High | Water | Pollution, noise |
| Nuclear Plant | Very High | Water | Clean but expensive, late-game |
| Geothermal | Medium-High | — | Scenario-dependent (Mars) |

**Power Distribution:**

- Blocks adjacent to powered blocks receive power (Fallout Shelter model)
- Or: Blocks connected via corridors/structure receive power
- Grid has **capacity limits** based on generation
- Exceeding capacity = brownouts (degraded function, not hard failure)

**User Stories:**

> **US-5.1:** As a player, I want power to flow through connected structures without manually drawing every wire.

> **US-5.2:** As a player, I want to see my power budget (generation vs consumption) clearly.

> **US-5.3:** As a player, I want brownouts to degrade my arcology (HVAC slows, lights dim) rather than instant failure.

> **US-5.4:** As a player, I want seasonal/day-night variation in solar output to create planning challenges.

### 5.2 Water System

Water is a **network resource** with pressure considerations for height.

**Water Infrastructure:**

| Block | Function |
|-------|----------|
| Water Treatment | Generates water supply for arcology |
| Water Main | Distributes water horizontally |
| Water Tower/Reservoir | Provides pressure for upper floors |
| Pumping Station | Boosts pressure for extreme height |

**Water Rules:**

- Water flows through connected structures
- Pressure drops with height
- Upper floors need reservoirs/pumping or lose pressure
- Low pressure = sanitation issues, habitability drops

**User Stories:**

> **US-5.5:** As a player, I want water to flow through my structure without manual pipe-laying.

> **US-5.6:** As a player, I want building higher to require water infrastructure investment (towers, pumps).

> **US-5.7:** As a player, I want to see a water pressure overlay showing where supply is adequate vs struggling.

### 5.3 HVAC/Air Processing System

HVAC extends habitable zone into areas without natural fresh air.

**HVAC Infrastructure:**

| Block | Function |
|-------|----------|
| HVAC Central | Major air processing, large radius |
| HVAC Vent | Extends HVAC reach, small radius |
| Air Duct | Routes HVAC through structure (optional complexity) |

**HVAC Rules:**

- HVAC provides "processed air" (70-80% quality vs fresh)
- Deep interior is uninhabitable without HVAC or indoor forests
- HVAC requires power; power failure = air quality collapse

**User Stories:**

> **US-5.8:** As a player, I want HVAC coverage shown as an overlay so I can find gaps.

> **US-5.9:** As a player, I want power failures to cascade into air quality crises in deep areas.

### 5.4 Utility Infrastructure (Distribution Networks)

The key insight: **low-capacity flows through adjacency, high-capacity needs dedicated infrastructure.**

**Automatic Low-Capacity Distribution:**

Adjacent blocks share small amounts of resources automatically (wiring in walls, pipes in floors):

| Resource | Auto-flow Capacity | Notes |
|----------|-------------------|-------|
| Power | 10 units | Enough for 2-3 small residential/commercial |
| Water | 5 units | Enough for 1-2 residential |
| Data | 5 units | Basic connectivity |
| Light | 0 | Doesn't penetrate walls (needs pipes) |
| Air | 0 | Doesn't penetrate walls (needs ducts) |

When blocks exceed auto-flow capacity, they show warning icons and require dedicated utility infrastructure.

**Utility Block Types:**

| Block | Size | Tags | Utility Capacity | Transit | Notes |
|-------|------|------|------------------|---------|-------|
| Utility Chase | 1×1 | [utility] | Power: 100, Water: 50, Data: 50, Light Pipe: 1, Air Duct: 1 | None | Pipes only, no walking |
| Utility Corridor | 1×1 | [utility, transit] | Power: 50, Water: 25, Data: 25, Light Pipe: 1, Air Duct: 1 | Walk | Dual purpose |

**Corridor Utility Upgrades:**

Basic corridors can be upgraded to carry utilities:

```
BASIC CORRIDOR → UTILITY CORRIDOR

Upgrade options (additive, stackable):
  [+] Add Power Conduit (+50 capacity, §100)
  [+] Add Water Main (+25 capacity, §150)  
  [+] Add Light Pipe (+1 channel, §200)
  [+] Add Air Duct (+1 channel, §100)
  [+] Add Data Trunk (+25 capacity, §75)

Visual changes: pipes visible in ceiling, floor gratings
```

**Capacity Flow Example:**

```
[Power Plant: 500 units]
      ↓
[Utility Chase: 100 cap] ← bottleneck if demand > 100
      ↓
[Junction] → [Utility Corridor: 50 cap] → [Office Wing]
      ↓
[Auto-flow to adjacent: 10 cap each] → [Residential]
```

**Failure Modes:**

| Situation | Consequence |
|-----------|-------------|
| Power demand > supply at block | Block dims, reduced function (50%) |
| Power demand > utility capacity | Upstream blocks also affected (cascade) |
| Water pressure insufficient | Sanitation warning, habitability drops |
| No light pipe to interior | Artificial light only (35% effective) |
| No air duct to deep interior | Air quality drops, eventually uninhabitable |

**User Stories:**

> **US-5.10:** As a player, I want auto-flow to handle small buildings but need to invest in utility corridors for high-demand areas.

> **US-5.11:** As a player, I want to upgrade existing corridors to carry utilities without rebuilding them.

> **US-5.12:** As a player, I want to see utility capacity overlays showing bottlenecks in my distribution network.

---

## 6. Transit & Pathfinding

### 6.1 Transit Philosophy

Vertical movement is **expensive and competitive** (SimTower insight). Horizontal movement is relatively cheap. Transit placement defines your arcology's economic geography.

**Two fundamental movement modes:**
- **Continuous flow**: Walk on/off anywhere (corridors, stairs) or ride a surface (escalators, walkways)
- **Discrete vehicle**: Get in, travel, get out at stops (elevators, pneuma-tubes)

### 6.2 Corridor System

Corridors are the arteries of the arcology. All corridors are **1 unit deep** (placed in chains like roads). They vary in width × height.

**Corridor Dimensions:**

| Type | Width | Height | Footprint | Capacity | Speed | Cost |
|------|-------|--------|-----------|----------|-------|------|
| Small | 1 | 1 | 1×1×1 | 20 people | 1.0x | §50 |
| Medium | 2 | 1 | 2×1×1 | 50 people | 1.0x | §100 |
| Large | 3 | 2 | 3×2×1 | 150 people | 1.1x | §300 |
| Grand Promenade | 5 | 2 | 5×2×1 | 400 people | 1.2x | §800 |

**Corridor Junction Blocks:**

All corridors are rectilinear (90° angles only). Junction types:

```
STRAIGHT:   ━━━━    (horizontal)
            ┃       (vertical)
            
CORNERS:    ┏━      ━┓      (top-left, top-right)
            ┗━      ━┛      (bottom-left, bottom-right)

T-JUNCTION: ┳  ┻  ┣  ┫

4-WAY:      ╋
```

Each junction is a distinct block with matching capacity to adjacent straight segments.

**Placement (Click-Drag):**
1. Tap corridor type from menu
2. Tap starting point on grid
3. Drag to endpoint (preview shows corridor chain)
4. Release to confirm and build

**Corridor Usage:**

| Type | Best For |
|------|----------|
| Small | Service corridors, back hallways, budget builds |
| Medium | Standard residential/office hallways |
| Large | Commercial zones, transit connections |
| Grand Promenade | Main arteries, flagship public spaces |

### 6.3 Corridor Capacity and Speed Degradation

As corridors fill up, movement slows:

```
SATURATION → SPEED MULTIPLIER

0-50%:    1.0x (free flow)
50-75%:   0.85x (getting crowded)
75-90%:   0.6x (congested)
90-100%:  0.4x (packed)
>100%:    0.2x (gridlock, spillover)

effective_speed = base_speed × speed_multiplier(saturation)
```

**Visual Indicators:**

```
[░░░░░░░░░░] 0-50%    "Quiet"     (green)
[▒▒▒▒▒▒░░░░] 50-75%   "Busy"      (yellow)  
[▓▓▓▓▓▓▓░░░] 75-90%   "Crowded"   (orange)
[██████████] 90-100%  "Packed"    (red)
[██████████] >100%    "Gridlock"  (flashing red)
```

### 6.4 Corridor Aesthetic Upgrades

Corridors can be enhanced with aesthetic and functional upgrades:

**Visual/Vibes Upgrades:**

| Upgrade | Vibes | Air | Noise | Cost | Notes |
|---------|-------|-----|-------|------|-------|
| Basic Lighting | +5 | — | — | §100 | Required for safety |
| Premium Lighting | +10 | — | — | §300 | Reduces crime further |
| Planter Boxes | +8 | +5 | -5 | §200 | Small greenery |
| Living Wall | +15 | +15 | -10 | §500 | Vertical garden |
| Bench Seating | +5 | — | +5 | §150 | Rest stops |
| Water Feature | +12 | +5 | +10 | §400 | Aesthetic fountain |
| Art Installation | +10 | — | — | §300 | Culture bonus |
| Premium Flooring | +8 | — | -5 | §200 | Carpet/tile upgrade |
| Skylights | +15 | — | — | §400 | Natural light (roof only) |
| Retail Kiosk | +5 | — | +10 | §500 | Small revenue source |
| Vending Machines | +3 | — | +5 | §200 | Small revenue |

**Example Upgrade Combinations:**

```
PLEASANT CORRIDOR: Planters + Bench + Good Lighting
  Vibes: +18, Cost: §450

GARDEN CORRIDOR: Living Wall + Water Feature + Premium Lighting
  Vibes: +37, Air: +20, Cost: §1,200

QUIET CORRIDOR: Acoustic Panels + Premium Flooring + Soft Lighting
  Vibes: +16, Noise: -25, Cost: §750
```

### 6.5 Vertical Transit (Stairs, Escalators, Elevators)

**Stairs:**
- Range: ±3 floors
- Speed: 0.5x (slow, adds fatigue)
- Capacity: Low
- Power: 0
- Placement: Connects two floors

**Escalators (Conveyor - Vertical):**
- Range: ±2 floors per segment
- Speed: 1.5x
- Capacity: High (continuous flow)
- Power: 3 units/block
- Special: Can angle 30-45° (exception to rectilinear rule)
- Placement: Click start, click end (auto-fills diagonal)

**Moving Walkway (Conveyor - Horizontal):**
- Range: Up to 20 blocks horizontal
- Speed: 2.0x
- Capacity: High (continuous flow)
- Power: 2 units/block
- Placement: Click start, click end (auto-fills straight line)

**Conveyor Model (Escalators + Walkways):**
```
Behavior: Continuous belt moving people from A to B
- Bidirectional (two lanes or reversible)
- Can walk against direction (0.5x speed)
- No wait time (step on and go)
- High throughput
- People skip intermediate blocks (point-to-point)
```

**Elevators (Local):**
- Range: ±10 floors
- Speed: 3.0x
- Capacity: Medium (10 people/car)
- Power: 10 units/floor
- Wait time: Function of demand and car count
- Placement: Place on one floor, extend shaft up/down

**Elevators (Express):**
- Range: ±30 floors
- Speed: 5.0x
- Capacity: High
- Power: 15 units/floor
- Precondition: Requires Sky Lobby
- Config: Can skip floors (express stops only)

**Freight Elevator:**
- Capacity: Goods only (no passengers)
- Speed: 2.0x
- Purpose: Industrial logistics
- Keeps freight separate from passenger traffic

### 6.6 Pneuma-Tube Network (Late Game)

```
PNEUMA-TUBE
Tech Level: 4 (late game unlock)
Behavior: High-speed capsule transit, ANY direction
Capacity: 1-2 people per capsule
Speed: 10x (fastest in game)
Power: 50 units per station + 5 per tube segment

Unique properties:
  - Routes horizontally, vertically, OR diagonally
  - Point-to-point only (no intermediate stops)
  - No wait time (capsule always available)
  - Very expensive to build and operate
  - Prestige/vibes bonus (futuristic!)
```

**Placement:**
1. Place Station A
2. Place Station B
3. System auto-routes tube OR player draws path
4. Can curve around obstacles

**Pneuma-Tube vs Express Elevator:**

| Factor | Express Elevator | Pneuma-Tube |
|--------|------------------|-------------|
| Direction | Vertical only | Any |
| Capacity | High (10+ per car) | Low (2 max) |
| Wait time | Yes (queuing) | No (instant) |
| Stops | Multi-stop | Point-to-point |
| Power | Medium | Very High |
| Best for | Mass transit | VIP/urgent travel |

### 6.7 Transit Block Summary

| Block | Tags | Orientation | Flow Type | Speed | Capacity | Tech |
|-------|------|-------------|-----------|-------|----------|------|
| Corridor | [transit] | Horizontal | Walk | 1.0x | By size | 1 |
| Stairs | [transit, vertical] | Vertical ±3 | Walk | 0.5x | Low | 1 |
| Moving Walkway | [transit, conveyor] | Horizontal | Ride | 2.0x | High | 2 |
| Escalator | [transit, conveyor, vertical] | Diagonal | Ride | 1.5x | High | 2 |
| Elevator (Local) | [transit, vehicle, vertical] | Vertical ±10 | Vehicle | 3.0x | Medium | 1 |
| Elevator (Express) | [transit, vehicle, vertical] | Vertical ±30 | Vehicle | 5.0x | High | 3 |
| Freight Elevator | [transit, freight, vertical] | Vertical | Vehicle | 2.0x | Freight | 2 |
| Pneuma-Tube | [transit, vehicle] | Any | Vehicle | 10.0x | 2 | 4 |
| Sky Lobby | [transit, hub] | Hub | — | — | Hub | 3 |

### 6.8 Foot Traffic Model

Every trip creates traffic along the path:

**Daily Patterns:**
```
06:00-09:00: 1.5x (morning commute)
09:00-12:00: 0.8x (working hours)
12:00-14:00: 1.3x (lunch rush)
14:00-17:00: 0.7x (afternoon lull)
17:00-20:00: 1.4x (evening commute + dinner)
20:00-22:00: 0.9x (entertainment)
22:00-06:00: 0.2x (night, minimal)
```

**Traffic Calculation:**
```
Traffic on corridor = Σ(all routes using this corridor)

Example:
  500 residents in Zone A
  80% work in Commercial Zone B
  Route goes through Corridor X
  
  Morning traffic on X ≈ 400 people
```

**Traffic Affects:**
- Retail revenue (more eyeballs = more sales)
- Noise levels (busy corridors are loud)
- Safety (high traffic = "eyes on the street")
- Speed (overcrowded = slow movement)
- Residential desirability (too much traffic = unpleasant)

**Bottleneck Detection:**
```
BOTTLENECK: saturation > 90% for sustained period

Consequences:
  - Commute times increase
  - Accessibility scores drop
  - Adjacent blocks suffer (noise, crowding)
  
Alert: "Traffic bottleneck on Level 5 East Corridor"
Suggest: "Upgrade to Large corridor or add parallel route"
```

### 6.9 Pathfinding Model

Don't pathfind on the voxel grid—build a **node graph**:

```
Room A (residential)
  ↔ Corridor B (cost: distance/speed × modifier)
  ↔ Elevator Bank C (cost: travel + wait time)
  ↔ Corridor D
  ↔ Workplace E
  
Total commute = Σ(edge costs)
```

**Edge Cost Calculation:**
```
edge_cost = (distance / effective_speed) × traversal_cost_modifier

effective_speed = base_speed × congestion_modifier

Pathfinding prefers:
  - Lower cost edges
  - Pleasant public spaces (low cost_modifier)
  - Uncongested routes
```

**Speed Multipliers:**

| Transit | Base Speed | Notes |
|---------|------------|-------|
| Corridor (walk) | 1.0 | Baseline |
| Stairs (up) | 0.4 | Slow + fatigue |
| Stairs (down) | 0.6 | Faster |
| Conveyor (with) | 2.0-2.5 | Walking + belt |
| Conveyor (against) | 0.3 | Fighting belt |
| Elevator | 3.0-5.0 | Plus wait time |
| Pneuma-Tube | 10.0 | No wait |

**User Stories:**

> **US-6.1:** As a player, I want to place corridors by clicking and dragging like roads in SimCity.

> **US-6.2:** As a player, I want larger corridors to handle more foot traffic without slowing down.

> **US-6.3:** As a player, I want to add aesthetic upgrades to corridors that improve vibes and reduce noise.

> **US-6.4:** As a player, I want to see foot traffic as a heatmap overlay so I can identify bottlenecks.

> **US-6.5:** As a player, I want escalators and moving walkways as high-capacity alternatives to stairs and walking.

> **US-6.6:** As a player, I want pneuma-tubes as a late-game premium transit option for VIP routes.

> **US-6.7:** As a player, I want restaurants near offices to thrive at lunch and restaurants near residential to thrive at dinner.

> **US-6.8:** As a player, I want corner and junction blocks to connect corridor segments at 90° angles.

---

## 7. Human Agents

The soul of Arcology is its people. Not "population: 50,000" but thousands of individual humans with names, faces, needs, relationships, and stories. You're not managing statistics—you're cultivating lives.

### 7.1 Agent Model

Every resident is a fully simulated agent:

```
Resident {
  // Identity
  id: unique
  name: generated
  age: int
  portrait: generated (pixel art, procedural)
  archetype: young_professional | family | retiree | artist | entrepreneur
  
  // Location
  home: block_id
  workplace: block_id (or null if retired/child/unemployed)
  
  // Psychological State (Maslow-inspired)
  needs: {
    survival: 0-100     // food, water, shelter, health
    safety: 0-100       // physical security, stability
    belonging: 0-100    // relationships, community, love
    esteem: 0-100       // respect, recognition, status
    purpose: 0-100      // meaning, growth, contribution
  }
  
  // Personality (Big Five)
  traits: {
    introversion: 0-100   // how they recharge
    openness: 0-100       // tolerance for change
    conscientiousness: 0-100  // reliability
    agreeableness: 0-100  // cooperation vs competition
    neuroticism: 0-100    // stress response
  }
  
  // Social Graph
  relationships: Map<person_id, Relationship>
  
  // Daily Life
  schedule: DailySchedule
  current_activity: Activity
  current_location: block_id
  
  // History
  complaints: [Complaint]
  life_events: [Event]
  residence_duration: months
  
  // Trajectory
  flourishing: 0-100 (computed)
  satisfaction_trend: improving | stable | declining
  flight_risk: 0-100
}
```

### 7.2 Resident Archetypes

New residents arrive with context based on their archetype:

**Young Professional (age 22-35)**
```
Seeking: career growth, excitement, social life
Needs emphasis: purpose, belonging
Tolerates: small spaces, noise, crowds
Base traits: low neuroticism, high openness
Flight risk if: career stalls, no friends after 6 months
```

**Family (2 adults, 1-3 children)**
```
Seeking: safety, schools, space, stability
Needs emphasis: safety, belonging (for kids)
Requires: family housing, school access
Base traits: high conscientiousness, moderate agreeableness
Flight risk if: crime rises, schools decline, not enough space
```

**Retiree (age 60+)**
```
Seeking: quiet, healthcare, community
Needs emphasis: safety, belonging, purpose (avoiding uselessness)
Requires: healthcare access, low noise
Base traits: varied, often high conscientiousness
Flight risk if: isolated, health declines with no care
```

**Artist/Creative (age 20-50)**
```
Seeking: cheap space, inspiration, community of creators
Needs emphasis: purpose, esteem (recognition)
Tolerates: rough conditions, noise, subterranean
Base traits: high openness, variable neuroticism
Flight risk if: priced out by gentrification, scene dies
```

**Entrepreneur (age 25-45)**
```
Seeking: opportunity, networking, status
Needs emphasis: esteem, purpose
Wants: prestigious address, access to talent
Base traits: low agreeableness, high openness
Flight risk if: business fails, better opportunity elsewhere
```

### 7.3 Human Generator

```python
def generate_resident(archetype, background):
    resident = Resident()
    
    # Identity
    resident.name = generate_name(background.culture)
    resident.age = sample_age(archetype)
    resident.portrait = generate_portrait(resident.age, background.culture)
    
    # Personality from archetype baseline + variance
    base = ARCHETYPE_BASELINES[archetype]
    resident.traits = {
        trait: clamp(base[trait] + random.gauss(0, 15), 0, 100)
        for trait in TRAIT_LIST
    }
    
    # Background modifiers
    if background.trauma:
        resident.traits.neuroticism += 20
    if background.strong_community:
        resident.traits.agreeableness += 15
    if background.competitive_field:
        resident.traits.agreeableness -= 10
    
    # Initial needs based on archetype and what they're seeking
    resident.needs = initial_needs(archetype)
    
    return resident
```

**Portrait Generation:**
- Procedural pixel art (16-bit style)
- Parameters: skin tone, hair style/color, age markers, expression
- Expression changes based on current flourishing level
- Recognizable individuals, not generic avatars

### 7.4 Daily Simulation

Every resident has a schedule that plays out in real-time:

```
TYPICAL WEEKDAY (Young Professional):

06:30  Wake up (home)
07:00  Morning routine, breakfast (home or cafe)
07:30  Commute begins
       → Walk to elevator
       → Wait for elevator (FRUSTRATION POINT)
       → Ride elevator
       → Walk to workplace
08:00  Arrive at work
       → If commute > 20 min: stress +5
       → If commute < 10 min: satisfaction +2
12:00  Lunch
       → Go to restaurant/food hall OR eat at desk
       → If eats alone 5+ days: belonging -3
       → If eats with friend: belonging +2
13:00  Back to work
17:30  Leave work
18:30  Home OR social activity
       → 30% chance: visit friend
       → 20% chance: go to entertainment
       → 50% chance: go home
19:00  Dinner
21:00  Evening activity
       → Introverts: home, recharge
       → Extroverts: social, entertainment
23:00  Sleep

WEEKEND:
  - More variance
  - Social activities
  - Shopping, recreation
  - Visiting friends
```

### 7.5 Notable Residents

Not every resident needs equal attention. The game highlights **100-500 "notable" residents** who:

- Have detailed stories and arcs
- Appear in the news feed
- Can be followed and watched
- Represent different parts of the arcology
- Serve as emotional anchors for the player

```
NOTABLE RESIDENT PROFILE:

Maria Chen
Age: 34 | Young Professional | Floor 47, Apt 3
Workplace: Tech startup, Floor 22
Residence: 2 years, 4 months

Flourishing: 72 (Stable)
[████████░░] 

Current Status: Content but commute-frustrated

Key Relationships:
  - David Park (friend, coworker) - Strength: 78
  - Lisa Chen (sister, Floor 31) - Strength: 92
  - No romantic partner

Recent Events:
  - Complained about elevator wait (3 weeks ago)
  - Attended community art show (2 weeks ago)
  - Had lunch with David 4 times this month

Trajectory: Stable
Flight Risk: 12% (low)

"I love my apartment and the view, but the morning
commute is killing me. If it gets worse, I might
have to move closer to work—or find a new job."
```

**User Stories:**

> **US-7.1:** As a player, I want to see individual residents with names, faces, and stories, not just population statistics.

> **US-7.2:** As a player, I want to follow a resident through their day and see how my design affects their life.

> **US-7.3:** As a player, I want notable residents to become familiar faces whose flourishing I care about.

> **US-7.4:** As a player, I want residents to have different personalities that affect how they respond to conditions.

---

## 8. Needs & Flourishing

### 8.1 The Needs Model (Maslow-Inspired)

Every resident has five core needs that must be met for flourishing:

```
SURVIVAL (Foundation)
  What: Food, water, shelter, health, physical comfort
  Met by: Housing, groceries, healthcare, HVAC, clean air
  Failure: Illness, physical decline, death
  
SAFETY (Security)
  What: Physical security, stability, predictability
  Met by: Low crime, stable housing, emergency services
  Failure: Anxiety, hypervigilance, flight
  
BELONGING (Connection)
  What: Relationships, community, love, acceptance
  Met by: Friendships, family, community spaces, events
  Failure: Loneliness, isolation, depression
  
ESTEEM (Recognition)
  What: Respect, recognition, status, achievement
  Met by: Meaningful work, contributions valued, nice home
  Failure: Insecurity, resentment, status competition
  
PURPOSE (Meaning)
  What: Growth, meaning, contribution, self-actualization
  Met by: Fulfilling work, creative expression, community impact
  Failure: Emptiness, existential drift, apathy
```

### 8.2 Needs Dynamics

Needs fluctuate based on daily experience:

```
SURVIVAL NEEDS:
  + Good air quality in home/work: +1/day
  + Access to food (grocery nearby): +1/day
  + Healthcare available when sick: +3/day (when sick)
  + Comfortable temperature: +1/day
  - Poor air quality: -2/day
  - Long distance to food: -1/day
  - Illness without healthcare: -5/day
  - Extreme temperature: -3/day

SAFETY NEEDS:
  + Low crime in home area: +1/day
  + Stable housing (secure lease): +1/day
  + Predictable environment: +1/day
  - Crime in area: -3/day
  - Witnessed crime: -10 (event)
  - Rent increase notice: -15 (event)
  - Neighbor conflict: -5/day (ongoing)

BELONGING NEEDS:
  + Regular interaction with friends: +2/interaction
  + Positive interaction with neighbors: +1/interaction
  + Community event attended: +5 (event)
  + Romantic relationship: +3/day
  - Ate alone today: -1
  - No friend interaction in 7 days: -5
  - Conflict with neighbor: -8 (event)
  - Friend moved away: -20 (event)

ESTEEM NEEDS:
  + Recognition at work: +5 (event)
  + Respected by neighbors: +1/day
  + Nice home relative to peers: +2/day
  + Contribution valued: +3 (event)
  - Passed over for promotion: -15 (event)
  - Lives in "bad" area: -2/day
  - Work feels meaningless: -3/day

PURPOSE NEEDS:
  + Work aligns with values: +2/day
  + Learning/growing: +2/day
  + Contributing to community: +3 (event)
  + Creative expression: +2/day
  - Dead-end job: -2/day
  - No growth in 6 months: -5 (event)
  - Feels useless: -3/day
```

### 8.3 Flourishing Calculation

Flourishing isn't a simple average—it requires **all needs above threshold** (Maslow hierarchy):

```python
def calculate_flourishing(person):
    needs = person.needs
    
    # Lower needs must be met before higher ones contribute
    if needs.survival < 50:
        return needs.survival * 0.3  # Barely surviving
    
    if needs.safety < 40:
        return 30 + (needs.safety - 40) * 0.5  # Anxious
    
    if needs.belonging < 30:
        return 50 + (needs.belonging - 30) * 0.5  # Lonely
    
    if needs.esteem < 30:
        return 60 + (needs.esteem - 30) * 0.4  # Insecure
    
    # All base needs met—purpose drives flourishing
    base = 70
    purpose_bonus = (needs.purpose - 50) * 0.6
    
    # Bonus for ALL needs being high (harmony)
    all_high = min(needs.survival, needs.safety, needs.belonging, 
                   needs.esteem, needs.purpose)
    harmony_bonus = max(0, (all_high - 70)) * 0.3
    
    return min(100, base + purpose_bonus + harmony_bonus)
```

### 8.4 Flourishing Tiers

| Score | State | Visible Signs | Behavior |
|-------|-------|---------------|----------|
| 0-30 | Suffering | Withdrawn, sick, angry | Complaints, may leave, spreads negativity |
| 30-50 | Struggling | Stressed, tired, isolated | Going through motions, flight risk |
| 50-70 | Stable | Okay, routine, few complaints | Reliable but not contributing extra |
| 70-85 | Thriving | Happy, social, productive | Contributes to community, attracts others |
| 85-100 | Flourishing | Radiantly alive, inspiring | Creates value, mentors others, magnetic |

### 8.5 Flight Risk

Residents may leave if conditions don't improve:

```
flight_risk = base_risk(archetype) + 
              dissatisfaction_factor + 
              opportunity_factor - 
              attachment_factor

dissatisfaction_factor = 
    (100 - flourishing) * 0.5 +
    (declining_trend ? 20 : 0) +
    unresolved_complaints * 5

opportunity_factor =
    external_job_market * 0.3 +
    better_housing_available * 0.3

attachment_factor =
    friends_in_building * 5 +
    family_in_building * 15 +
    years_of_residence * 3 +
    community_involvement * 10

IF flight_risk > 70 for 30 days:
    resident begins looking to leave
IF flight_risk > 90:
    resident gives notice
```

**User Stories:**

> **US-8.1:** As a player, I want to see why a resident is struggling (which need is unmet) so I can address it.

> **US-8.2:** As a player, I want flourishing to require more than just physical needs—community and purpose matter.

> **US-8.3:** As a player, I want residents at risk of leaving to be flagged so I can intervene.

> **US-8.4:** As a player, I want to understand that a resident with high survival but low belonging is still not flourishing.

---

## 9. Social Networks

Community is not automatic. Relationships must form, be maintained, and can decay or break.

### 9.1 Relationship Model

```
Relationship {
  person_a: resident_id
  person_b: resident_id
  
  type: family | romantic | friend | acquaintance | coworker | neighbor | enemy
  strength: 0-100
  trend: improving | stable | deteriorating
  
  history: [Interaction]
  last_interaction: timestamp
  
  // Specific to type
  shared_meals: int
  conflicts: int
  helped_during_crisis: bool
}
```

### 9.2 Relationship Formation

```
ACQUAINTANCE FORMATION:

Neighbors (adjacent apartments):
  - 30% chance per month of acknowledgment
  - Increased by: shared elevator waits, community events
  - Decreased by: opposite schedules, conflict

Coworkers (same workplace):
  - 50% chance per month of acquaintance
  - Increased by: shared projects, lunch together
  
Random Encounters:
  - Same elevator wait: 2% chance per encounter
  - Same food hall table: 5% chance
  - Same community event: 15% chance

FRIENDSHIP FORMATION:

Acquaintance → Friend requires:
  - 5+ positive interactions
  - Compatibility score > 50
  - No major conflicts

Compatibility = f(
  similar_age: ±10 years = +20
  similar_archetype: +15
  complementary_traits: +10 to +30
  shared_interests: +20
  opposite_schedules: -30
)
```

### 9.3 Relationship Maintenance

```
RELATIONSHIP DECAY:
  - No interaction in 30 days: strength -10
  - No interaction in 90 days: strength -30
  - If strength < 20: relationship downgrades or dissolves

RELATIONSHIP STRENGTHENING:
  - Positive interaction: +3 to +5
  - Shared meal: +3
  - Attended event together: +5
  - Helped during crisis: +20
  - Conflict resolved well: +10

RELATIONSHIP DAMAGE:
  - Minor conflict: -10
  - Major conflict: -30
  - Betrayal/serious offense: -50 to -80
  - Unresolved conflict: -5/week ongoing
```

### 9.4 Relationship Effects on Needs

```
BELONGING EFFECTS:

Each friend in building: +5 belonging (diminishing after 5)
Best friend: +15 belonging
Romantic partner: +20 belonging
Family member: +10 belonging
Enemy in building: -10 safety, -5 belonging

ESTEEM EFFECTS:

Respected by neighbors: +1/day per positive relationship
Known troublemaker: -2/day esteem
Community leader: +5/day esteem

PURPOSE EFFECTS:

Mentoring someone: +3/day purpose
Being mentored: +2/day purpose
Collaborative project: +5/day purpose
```

### 9.5 Community Cohesion

The aggregate health of all relationships:

```
community_cohesion = f(
  average_relationship_strength,
  relationship_density,  // connections per person
  cross_group_connections,  // bridges between clusters
  conflict_rate,
  turnover_rate
)

COHESION EFFECTS:

80-100 (Tight Community):
  -。。。。。。。。。。。。。residents help each other during crises
  -。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。new residents welcomed and integrated
  - 。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。crime naturally suppressed
  - 。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。collective action possible

60-80 (Friendly):
  - 。。。。。。。。。。。。。pleasant but not deep connections
  - 。。。。。。。。。。。。。people know their neighbors
  - 。。。。。。。。。。。。。some mutual aid

40-60 (Cordial):
  - 。。。。。。。。。。。。。polite but distant
  - 。。。。。。。。。。。。。cliques form
  - 。。。。。。。。。。。。。limited cross-group interaction

20-40 (Fragmented):
  - 。。。。。。。。。。。。。isolated individuals
  - 。。。。。。。。。。。。。tribal conflicts
  - 。。。。。。。。。。。。。crime rises
  - 。。。。。。。。。。。。。blame and resentment

0-20 (Hostile):
  - 。。。。。。。。。。。。。active conflicts
  - 。。。。。。。。。。。。。violence incidents
  - 。。。。。。。。。。。。。mass exodus
```

### 9.6 Community Events

Player-initiated events that build connections:

| Event | Cost | Attendance | Effect |
|-------|------|------------|--------|
| Block Party | §500 | 50-200 | +5 cohesion, acquaintance formation boost |
| Art Show | §1,000 | 100-300 | +3 cohesion, +5 vibes, attracts artists |
| Festival | §5,000 | 500-2,000 | +10 cohesion, major acquaintance formation |
| Town Hall | §200 | 50-150 | +2 cohesion, surfaces complaints constructively |
| Workshop | §300 | 20-50 | +3 cohesion among attendees, skill sharing |
| Sports League | §1,000/season | 50-200 | +5 cohesion, regular interaction structure |

**User Stories:**

> **US-9.1:** As a player, I want to see the social network of my arcology—who knows whom.

> **US-9.2:** As a player, I want to host community events that build connections between residents.

> **US-9.3:** As a player, I want to identify isolated residents who need help connecting.

> **US-9.4:** As a player, I want to see when conflicts are brewing between residents or groups.

> **US-9.5:** As a player, I want community cohesion to affect crime, mutual aid, and collective resilience.

---

## 10. Entropy Systems

Everything decays. Your job is to fight it. Entropy is the constant antagonist—not evil, just physics and time.

### 10.1 Physical Entropy

```
BUILDING DECAY MODEL:

Every block has:
  condition: 0-100
  age: months since construction
  maintenance_debt: accumulated deferred maintenance

decay_rate = BASE_DECAY × use_intensity × environment_factor

USE INTENSITY:
  Low traffic (<50/day): 1.0x
  Medium traffic (50-200/day): 1.5x
  High traffic (200-500/day): 2.0x
  Very high traffic (500+/day): 3.0x

ENVIRONMENT FACTOR:
  Standard: 1.0x
  Subterranean (moisture): 1.3x
  Near industrial (vibration): 1.2x
  Exterior-facing (weather): 1.2x
  Near water features: 1.1x
```

**Condition Effects:**

| Condition | State | Effects |
|-----------|-------|---------|
| 100-80 | Pristine | No penalties |
| 80-60 | Worn | Vibes -5, occasional breakdowns (5%/month) |
| 60-40 | Degraded | Vibes -15, frequent breakdowns (15%/month), safety -10 |
| 40-20 | Failing | Vibes -30, constant problems (30%/month), safety -25 |
| 20-0 | Condemned | Unusable until major repair |

**Maintenance System:**

```
ROUTINE MAINTENANCE:
  Cost: §/month per block (scales with size)
  Effect: Slows decay by 80%
  Skip it: Saves money now, costs 3x more later

REPAIR:
  Cost: §§ per condition point restored
  Effect: Restores condition, doesn't reset age
  
RENOVATION:
  Cost: §§§
  Effect: Full restore + upgrade tier, resets age
  Disruption: Block unusable during renovation
```

### 10.2 Social Entropy

Communities fragment without cultivation:

```
COHESION DECAY SOURCES:

Turnover:
  - New residents don't know anyone
  - -2 cohesion per 10% annual turnover
  
Isolation:
  - Residents who never interact with neighbors
  - -1 cohesion per 100 isolated residents

Conflict:
  - Unresolved disputes poison the well
  - -5 cohesion per active conflict
  
Inequality:
  - Visible wealth gaps breed resentment
  - -3 cohesion if Gini coefficient > 0.4

Scale without Structure:
  - Too large without community subdivisions
  - -2 cohesion per 10k population without districts

Time:
  - Relationships naturally fade without maintenance
  - -1 cohesion per year baseline
```

### 10.3 Economic Entropy

Markets shift, industries die, nothing lasts forever:

```
DEMAND SHIFTS:
  - Every 5 years: major demand shift event
  - Office demand: fluctuates with broader economy
  - Retail demand: erodes as e-commerce grows
  - Industrial demand: automation pressure

EXAMPLES:
  Year 5: "Remote work trend reduces office demand by 20%"
  Year 12: "New competitor arcology opens; immigration drops 30%"
  Year 20: "Your industrial sector is now obsolete"

OBSOLESCENCE:
  - Old block types become less desirable over time
  - Technology requirements increase
  - "Vintage charm" bonus possible after 30+ years (if maintained)

INEQUALITY SPIRAL:
  - Success breeds success: premium areas appreciate
  - Failure breeds failure: declining areas accelerate decline
  - Without intervention: bifurcation into luxury/slum
```

### 10.4 Knowledge Entropy

Institutional memory is fragile:

```
KNOWLEDGE TYPES:
  - How systems work (informal knowledge)
  - Who knows whom (social knowledge)
  - What's been tried before (historical knowledge)
  - Unwritten social contracts (cultural knowledge)

KNOWLEDGE LOSS EVENTS:
  - Key resident leaves: takes expertise with them
  - Long-time manager retires: institutional memory gap
  - Rapid turnover: nobody knows how things work
  - No documentation: everything is tribal knowledge

EFFECTS OF KNOWLEDGE LOSS:
  - Problems that were "solved" resurface
  - New residents repeat old mistakes
  - Conflicts re-emerge from forgotten history
  - Systems drift from design intent
  - Maintenance becomes harder (nobody knows the quirks)
```

### 10.5 Fighting Entropy

The player's tools against decay:

```
PHYSICAL:
  - Consistent maintenance budget (don't defer!)
  - Quality construction (higher upfront, slower decay)
  - Renovation cycles (rebuild before collapse)
  - Redundant systems (backups for critical infrastructure)

SOCIAL:
  - Community events (build and maintain connections)
  - New resident integration programs
  - Conflict mediation before escalation
  - Cross-group activities (prevent tribal isolation)

ECONOMIC:
  - Diversified economy (don't depend on one sector)
  - Reserve funds (buffer for shocks)
  - Continuous adaptation (evolve with market)
  - Investment in education/skills (stay competitive)

KNOWLEDGE:
  - Documentation systems
  - Mentorship programs (knowledge transfer)
  - Institutional continuity (key people stay)
  - Historical preservation (remember what worked)
```

**User Stories:**

> **US-10.1:** As a player, I want to see my maintenance debt growing if I skimp on upkeep.

> **US-10.2:** As a player, I want buildings to visibly age and degrade without maintenance.

> **US-10.3:** As a player, I want economic shocks that force me to adapt my arcology.

> **US-10.4:** As a player, I want to feel the loss when a key community member leaves.

---

## 11. Human Nature

Your residents will undermine themselves and each other. This is not a bug—it's the human condition, and navigating it is the game.

### 11.1 NIMBYism

```
NIMBY DYNAMIC:

Every resident wants:
  - Good things near them (parks, transit, shops)
  - Bad things far from them (industrial, nightclubs, density)

When you place something "undesirable":
  - Nearby residents complain
  - Even if it's good for the arcology overall
  - Even if they themselves use it
  - Complaints scale with proximity and severity

NIMBY TRIGGERS:
  Industrial: "Not next to MY home"
  Nightclub: "Too loud for this neighborhood"
  Budget housing: "Will lower property values"
  Homeless shelter: "Attracts undesirables"
  Transit hub: "Too much traffic"
  
GAMEPLAY IMPLICATION:
  You cannot please everyone.
  Good urban design requires hard choices.
  Buffer zones and gradual transitions help.
  Some complaints are valid; some are selfish.
```

### 11.2 Tribalism

```
NATURAL DIVISIONS FORM:

By Floor: Upper vs lower (class proxy)
By Zone: East wing vs west wing (territory)
By Tenure: Old-timers vs newcomers (who belongs)
By Type: Families vs singles (lifestyle)
By Class: Luxury vs budget (economic)

TRIBAL DYNAMICS:

In-group behavior:
  - Trust, cooperation, friendship
  - Defend group members
  - Share resources

Out-group behavior:
  - Suspicion, competition
  - Blame for problems
  - Resist integration

CONFLICT TRIGGERS:
  - Shared resources (elevator allocation, parking)
  - Noise across boundaries
  - Perceived unfairness ("they get better maintenance")
  - Status competition
  - Scapegoating during crises

WITHOUT INTERVENTION:
  - Tribes calcify
  - Conflicts escalate
  - Segregation increases
  - Community cohesion collapses
```

### 11.3 Short-Term Thinking

```
RESIDENTS WANT IMMEDIATE GRATIFICATION:

They want: low rent NOW
You need: reserves for maintenance

They want: more parking NOW
You could: use that space for park (long-term value)

They want: no construction NOW
You need: to expand for future sustainability

They oppose: any short-term inconvenience
Even if: it improves things long-term

APPROVAL DYNAMICS:
  - Approval ratings reflect short-term happiness
  - Long-term investments tank short-term approval
  - Deferred maintenance is invisible until it fails
  - Future residents can't vote

LEADERSHIP TENSION:
  Sometimes being a good steward means being unpopular.
  The game should make this tension felt.
```

### 11.4 Tragedy of the Commons

```
SHARED SPACES SUFFER:

Corridors: Everyone uses, no one owns → quality degrades
Community gardens: Initial enthusiasm fades → neglect
Shared amenities: Overused, under-maintained
Public spaces: Nobody's responsibility → everybody's problem

DYNAMICS:
  Individual incentive: Use the resource, let others maintain it
  Collective result: Resource degrades
  
Without structure: "Someone else will handle it"
Result: Nobody handles it

SOLUTIONS (gameplay):
  - Clear ownership/responsibility assignments
  - Funded maintenance for public spaces
  - Community investment mechanisms
  - Social pressure (reputation systems)
  - Accept higher costs for shared resources
```

### 11.5 Status Competition

```
HUMANS COMPARE THEMSELVES TO NEIGHBORS:

Upward comparison:
  - Living below someone "better off": esteem -
  - Seeing neighbor's nicer apartment: dissatisfaction +
  - "Keeping up with the Joneses": financial stress

Downward comparison:
  - Living above someone "worse off": esteem +
  - But also: guilt for some personalities
  
Visible inequality:
  - Luxury penthouse visible from budget apartment: resentment
  - Same corridor, vastly different units: tension
  - "Why do THEY get that?"

DESIGN IMPLICATIONS:
  - Pure meritocratic stratification creates resentment
  - Mixed-income areas have tension but build community
  - Hidden vs visible inequality matters
  - Non-economic status helps (community respect, contribution recognition)
```

### 11.6 Implications for Design

```
THE GAME SHOULD:

1. Make NIMBY complaints visible and frequent
   - So players understand the tradeoffs
   - And learn that some complaints should be overridden

2. Show tribal dynamics emerging naturally
   - So players see the need for cross-group connection
   - And experience the cost of letting tribes calcify

3. Punish short-term thinking eventually
   - Deferred maintenance should bite hard
   - Reserve funds should matter
   - Long-term investments should pay off

4. Demonstrate tragedy of the commons
   - Shared spaces should degrade without investment
   - Players should feel the cost of neglect

5. Surface status competition
   - So players understand inequality's social cost
   - And consider whether to segregate or integrate
```

**User Stories:**

> **US-11.1:** As a player, I want NIMBY complaints when I place undesirable things, teaching me about tradeoffs.

> **US-11.2:** As a player, I want to see tribal divisions emerge naturally so I understand the need for community-building.

> **US-11.3:** As a player, I want to feel the tension between short-term approval and long-term sustainability.

> **US-11.4:** As a player, I want shared spaces to degrade if I don't invest in them.

---

## 12. Eudaimonia & Victory

The win condition is not profit, population, or efficiency. It's **eudaimonia**—human flourishing.

### 12.1 Arcology Eudaimonia Index (AEI)

```
AEI = f(
  individual_flourishing,  // Are residents thriving?
  community_cohesion,      // Are they connected?
  sustainability,          // Is this built to last?
  resilience              // Can it survive shocks?
)

CALCULATION:

individual = (
  mean(all_residents.flourishing) - 
  stdev(all_residents.flourishing) * 0.3  // penalize inequality
)

community = cohesion_score

sustainability = 100 - (
  maintenance_debt_ratio * 30 +
  budget_deficit_months * 10 +
  environmental_damage * 20 +
  knowledge_loss_index * 10
)

resilience = f(
  backup_systems_coverage,
  financial_reserves_months,
  community_mutual_aid_score,
  economic_diversity_index
)

AEI = (
  individual * 0.40 +
  community * 0.25 +
  sustainability * 0.20 +
  resilience * 0.15
)
```

### 12.2 AEI Dashboard

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
│  POPULATION: 12,847                              │
│  Flourishing: 4,102 | Stable: 6,891 |            │
│  Struggling: 1,854                               │
│                                                  │
│  ALERTS:                                         │
│  ⚠ 12 residents at high flight risk             │
│  ⚠ Maintenance debt growing (now §240K)         │
│  ⚠ East Wing cohesion declining                 │
│  ⚠ 3 unresolved neighbor conflicts              │
└──────────────────────────────────────────────────┘
```

### 12.3 Victory Conditions

**Standard Victories:**

```
"SUSTAINABLE COMMUNITY" (Standard)
  - Maintain AEI > 70 for 20 years
  - No major crises (mass exodus, bankruptcy, collapse)
  - Population > 10,000
  - Difficulty: Medium
  
"UTOPIA" (Hard)
  - Maintain AEI > 85 for 30 years
  - Average flourishing > 80
  - Community cohesion > 80
  - Zero residents in "suffering" state
  - Difficulty: Very Hard
  
"SURVIVOR" (Endurance)
  - Survive 50 years of increasing entropy
  - Maintain AEI > 50 throughout
  - Never drop below 70% peak population
  - Difficulty: Hard
```

**Scenario Victories:**

```
"GENERATION SHIP" (Space/Mars)
  - Maintain viable population for 100 years
  - No external immigration possible
  - End with higher AEI than start
  - Difficulty: Very Hard
  
"REDEMPTION" (Challenge)
  - Inherit failing arcology (AEI 25)
  - Raise to AEI 60 within 10 years
  - Without mass displacement of original residents
  - Difficulty: Hard
  
"ARCOSANTI" (Sandbox)
  - No victory condition
  - Just build and cultivate
  - Track statistics and milestones
  - For players who want to experiment
```

### 12.4 Failure States

```
BANKRUPTCY:
  Treasury negative for 6+ months
  Cannot make payroll or maintenance
  Arcology enters receivership

MASS EXODUS:
  Population drops below 50% of peak
  Death spiral of declining services
  
COLLAPSE:
  Critical infrastructure failure
  Cascade of system breakdowns
  Uninhabitable sections
  
CIVIL BREAKDOWN:
  Community cohesion below 10
  Violence incidents
  No-go zones form
  
Note: These should be difficult to reach through
normal play, but possible if player ignores warnings.
```

### 12.5 Why Eudaimonia Matters

```
THE GAME'S THESIS:

Profit-maximizing leads to:
  - Squeezing residents
  - Deferred maintenance
  - Inequality
  - Short-term thinking
  Result: Eventual collapse or dystopia

Population-maximizing leads to:
  - Overcrowding
  - Insufficient infrastructure
  - Lost community
  - Anonymity and isolation
  Result: Soul-less megastructure

Eudaimonia-maximizing requires:
  - Caring about individual lives
  - Building community
  - Long-term investment
  - Fighting entropy
  - Balancing competing needs
  Result: A place worth living

The game teaches: What you optimize for matters.
```

**User Stories:**

> **US-12.1:** As a player, I want the win condition to be human flourishing, not profit or population.

> **US-12.2:** As a player, I want the AEI dashboard to show me how well my residents are really doing.

> **US-12.3:** As a player, I want different victory conditions for different playstyles.

> **US-12.4:** As a player, I want to feel the difference between a profitable arcology and a flourishing one.

---

## 13. Economy & Budget

### 13.1 Economic Model (SimCity-style)

**Income Sources:**

| Source | Driver |
|--------|--------|
| Residential Rent | Occupied residential blocks × quality-adjusted rent |
| Commercial Rent | Occupied commercial blocks × foot traffic modifier |
| Industrial Rent | Occupied industrial blocks (low but stable) |
| Commuter Fees | Workers who live outside but work inside |
| Visitor Spending | Hotel guests, tourists, external shoppers |
| Event Revenue | Arena, convention center bookings |
| Exports | Goods produced internally, sold externally |

**Expense Categories:**

| Category | Driver |
|----------|--------|
| Power Operations | Per kW capacity maintained |
| Water/Waste | Per unit of capacity |
| HVAC | Per unit of coverage |
| Security | Per patrol station |
| Transit Operations | Per elevator bank, transit hub |
| Maintenance | Flat % of total structure value |
| Debt Service | Interest on loans |

**Budget Loop:**

```
Monthly Net = Σ(Income) - Σ(Expenses)

Positive → Treasury grows → Invest in expansion
Negative → Treasury drains → Cut costs or bankruptcy
```

### 13.2 Rent Calculation

**Residential Rent:**

```
base_rent = BLOCK_TYPE_BASE × LEVEL_MULTIPLIER

desirability = (
    sunlight × 0.20 +
    air_quality × 0.15 +
    quiet × 0.15 +
    safety × 0.15 +
    accessibility × 0.20 +
    vibes × 0.15
) / 100

rent = base_rent × desirability × demand_multiplier
```

**Commercial Revenue:**

```
revenue = base × level × (
    foot_traffic × 0.35 +
    accessibility × 0.20 +
    cluster_bonus × 0.15 +
    catchment_population × 0.20 +
    vibes × 0.10
) × (1 - competition_penalty)
```

### 13.3 Clustering Effects

**Positive Clustering (District Bonuses):**

- 3+ restaurants nearby = "dining district" (+20% revenue each)
- Offices near offices = business ecosystem bonus
- Retail clusters = shopping destination effect

**Negative Clustering (Competition):**

- Two groceries too close = split catchment, both suffer
- Identical shops adjacent = redundancy penalty

**User Stories:**

> **US-7.1:** As a player, I want to see my monthly budget breakdown clearly (income by type, expenses by type).

> **US-7.2:** As a player, I want to take loans for expansion with clear interest costs.

> **US-7.3:** As a player, I want rent to automatically adjust based on block quality—I shouldn't manually set prices.

> **US-7.4:** As a player, I want clustering bonuses to encourage district-building (entertainment district, business district).

> **US-7.5:** As a player, I want to see projected revenue when placing a commercial block based on its location.

---

## 14. Population & Demographics

### 14.1 Three Population Types

| Type | Lives | Works | Characteristics |
|------|-------|-------|-----------------|
| **Residents** | Inside | Inside | Full citizens; pay rent, use all services, 24/7 presence |
| **Commuters-In** | Outside | Inside | Daytime only; support commercial, no residential rent |
| **Commuters-Out** | Inside | Outside | Pay residential rent; less internal commercial spending |

**Why This Matters:**

- **Residents** generate full economic activity and population growth (births)
- **Commuters-In** support daytime economy but leave at night (crime risk in empty areas)
- **Commuters-Out** fill housing but don't support internal jobs; vulnerable to external transit quality

### 14.2 Population Dynamics

```
population_change = (births - deaths) + (immigration - emigration)

births = residential_population × birth_rate × family_housing_ratio × happiness_factor
deaths = population × death_rate × healthcare_modifier

immigration = external_demand × housing_vacancy × desirability × transit_capacity  
emigration = population × (1 - satisfaction) × external_pull × transit_capacity
```

**For Closed Scenarios (Space Station, Mars):**

```
immigration = 0 (or rare: "rescue pod arrives")
emigration = 0 (or rare: "shuttle departure")

Population depends entirely on births - deaths
Healthcare and family housing become CRITICAL
```

### 14.3 Isolation Score

Measures how self-contained vs externally connected the arcology is:

```
isolation_score = f(
    external_transit_capacity,
    import_dependency,
    export_volume,
    commuter_ratio
)

0-30:   Integrated district (porous boundary)
30-60:  Distinct but connected (campus)
60-85:  Self-sufficient city-state
85-100: Closed system (space station)
```

**User Stories:**

> **US-8.1:** As a player, I want to see population breakdown by type (residents, commuters-in, commuters-out).

> **US-8.2:** As a player, I want family housing + schools to drive birth rate so I can grow population organically.

> **US-8.3:** As a player, I want poor conditions to cause emigration, providing feedback on my failures.

> **US-8.4:** As a player in a closed scenario (space station), I want population to depend entirely on births—making healthcare critical.

---

## 15. Scenarios & World Settings

### 15.1 Scenario Parameters

| Parameter | Earth Urban | Earth Remote | Mars Colony | Space Station |
|-----------|-------------|--------------|-------------|---------------|
| Immigration | High | Medium | Rare ships | Zero/Rare |
| Emigration | High | Medium | Rare ships | Zero/Rare |
| Trade | Open | Limited | Critical imports | None |
| Starting Isolation | 20 | 50 | 85 | 95+ |
| Envelope | Optional | Important | Critical (sealed) | Critical (hull) |
| External Environment | Survivable | Survivable | Lethal | Lethal |

### 15.2 Day/Night Cycle

| Period | Sun | Traffic Pattern |
|--------|-----|-----------------|
| Night (22:00-06:00) | None | Minimal; crime risk in empty areas |
| Morning (06:00-09:00) | Rising | Commute surge |
| Midday (09:00-17:00) | Full | Work + lunch traffic |
| Evening (17:00-22:00) | Setting | Reverse commute, entertainment |

### 15.3 Seasonal Cycle (Earth)

| Season | Day Length | Sun Intensity | Temperature | Notes |
|--------|-----------|---------------|-------------|-------|
| Summer | Long | High | Hot | More natural light, cooling demand |
| Winter | Short | Low | Cold | Less natural light, heating demand |
| Spring/Fall | Medium | Medium | Mild | Balanced |

### 15.4 Mars Considerations

- Always cold (constant heating demand)
- Solar varies with dust storms
- Dust storm season = potential blackout event (survival scenario)
- No external air ever; 100% sealed envelope
- Water recycling critical

### 15.5 Space Station Considerations

- Artificial 24-hour light cycle for health
- Constant solar (if positioned well) but cooling is the problem
- Complete seal; hull breach = disaster event
- Rotation for gravity affects "down" direction
- No external resupply (or rare)

**User Stories:**

> **US-9.1:** As a player, I want to choose from scenario presets (Earth/Mars/Space) with appropriate starting conditions.

> **US-9.2:** As a player on Mars, I want dust storms to threaten my solar power and create survival tension.

> **US-9.3:** As a player on a space station, I want population sustainability to be my core challenge—no immigration bailout.

> **US-9.4:** As a player, I want seasonal variation to affect my power/light/heating balance through the year.

---

## 16. Progression & Unlocks

### 16.1 Tech Levels

| Level | Population | Key Unlocks |
|-------|------------|-------------|
| 1 (Settlement) | 0-2,000 | Basic housing, small commercial, stairs, local elevators |
| 2 (Town) | 2,000-10,000 | University, vertical farms, express elevators, HVAC central |
| 3 (City) | 10,000-50,000 | Mega-blocks, medical center, full transit, sky lobbies |
| 4 (Metropolis) | 50,000+ | Advanced power, transit pods, prestige buildings |

### 16.2 Block Unlock Chains

**Vertical Expansion:**
```
Water Tower → Elevator Bank → Sky Lobby → Express Elevator → High-rise viable
```

**Deep Interior:**
```
Solar Collector → Light Pipes → Indoor Forest → Deep Residential viable
```

**Food Independence:**
```
Water + Power → Vertical Farm → Food Processing → Grocery → Food security
```

**Population Growth:**
```
School → Family Housing → Births → Organic growth
```

**Safety:**
```
Security Station → Police HQ → Checkpoints → "Crime doesn't climb" enforcement
```

### 16.3 Achievements/Milestones

| Milestone | Requirement |
|-----------|-------------|
| Village | 500 population |
| Town | 2,000 population |
| City | 10,000 population |
| Metropolis | 50,000 population |
| Arcology | 100,000 population + isolation > 70 |
| Utopia | 100,000+ population + avg happiness > 80 |
| Survivor (Mars/Space) | 10 years without collapse |
| Self-Sufficient | Isolation score 100 |

**User Stories:**

> **US-10.1:** As a player, I want buildings to unlock based on population/tech level so there's progression.

> **US-10.2:** As a player, I want to see what I need to unlock the next tier of buildings.

> **US-10.3:** As a player, I want milestones and achievements to give me goals beyond "more population."

---

## 17. User Interface

### 17.1 View Modes

Players can view the arcology from multiple perspectives:

| View | Description |
|------|-------------|
| Isometric 3D | Default; full structure with depth |
| Planar Slice | Single floor, top-down |
| Side Cutaway | Vertical cross-section |
| Top-Down | Birds-eye, all floors collapsed |

**User Stories:**

> **US-11.1:** As a player, I want to switch between view modes quickly to understand my 3D structure.

> **US-11.2:** As a player, I want to slice through floors to see the interior without exterior blocking my view.

> **US-11.3:** As a player, I want side-view cutaway to understand my vertical organization.

### 17.2 Overlay Layers

Toggle overlays to see specific systems:

| Overlay | Visualization |
|---------|---------------|
| Sunlight | Yellow gradient (bright → dark) |
| Air Quality | Blue/green (good) → brown (bad) |
| Safety/Crime | Green (safe) → red (dangerous) |
| Noise | Quiet (none) → loud (red waves) |
| Vibes | Sparkle/glow intensity |
| Power | Connected (lit) vs disconnected (dim) |
| Water | Pressure gradient |
| Foot Traffic | Heatmap |
| Accessibility | Distance gradient from services |
| Zoning | Color by zone type |

**User Stories:**

> **US-11.4:** As a player, I want to toggle environment overlays to diagnose problems.

> **US-11.5:** As a player, I want overlays to be visually distinct and readable at a glance.

### 17.3 Information Panels

**Block Inspector:**
- Type, level, occupancy
- Current tenants (if any)
- Environmental scores (light, air, safety, vibes)
- Rent/revenue
- Problems/warnings

**Budget Panel:**
- Monthly income breakdown
- Monthly expense breakdown
- Net cash flow
- Treasury balance
- Loan status

**Population Panel:**
- Total population by type
- Birth/death rate
- Immigration/emigration rate
- Happiness distribution
- Employment stats

**Infrastructure Panel:**
- Power: generation, consumption, headroom
- Water: supply, demand, pressure issues
- Light: harvested, distributed, deficit
- Air: coverage, quality issues

**User Stories:**

> **US-11.6:** As a player, I want to click any block and see all relevant information in one panel.

> **US-11.7:** As a player, I want the budget panel to show trends over time, not just current month.

> **US-11.8:** As a player, I want warnings/alerts when systems are failing or approaching limits.

### 17.4 Construction Interface

**Block Placement:**
1. Select block type from categorized menu
2. See ghost preview with placement validity
3. See "needs met" checklist (power ✓, water ✓, path ✓)
4. See projected rent/revenue for this location
5. Click to place

**Zone Painting:**
1. Select zone type (residential, commercial, industrial)
2. Paint across multiple blocks
3. Zoned areas auto-fill based on demand and quality

**User Stories:**

> **US-17.9:** As a player, I want to see if a block placement will succeed before I commit.

> **US-17.10:** As a player, I want to paint zones quickly without tedious clicking.

---

## 18. Narrative Systems

The game tells stories through its systems. Players don't read cutscenes—they watch lives unfold and feel the consequences of their decisions.

### 18.1 The Evening News

A regular digest that surfaces what's happening in your arcology:

```
┌────────────────────────────────────────────────────┐
│  ARCOLOGY HERALD - Evening Edition                 │
│  Year 5, Month 8, Day 15                          │
├────────────────────────────────────────────────────┤
│                                                    │
│  TOP STORIES:                                      │
│                                                    │
│  📈 Elevator Wait Times Hit Record High            │
│     Floors 20-30 averaging 8 minute waits          │
│     Residents frustrated, 3 complaints filed      │
│                                                    │
│  🏠 New Restaurant Opens on Level 12               │
│     "Chen's Noodle House" replaces vacant shop    │
│     Owner Maria Chen: "Finally my dream!"         │
│                                                    │
│  ⚠️ East Wing Cohesion Declining                   │
│     Neighbor disputes up 40% this quarter         │
│     Community organizers concerned                │
│                                                    │
│  🎉 Block Party Success on Level 8                 │
│     200 residents attended, 15 new friendships    │
│                                                    │
├────────────────────────────────────────────────────┤
│  RESIDENT SPOTLIGHT: David Park                    │
│  "The morning commute is brutal, but I love       │
│   my neighbors. We have dinner together every     │
│   Thursday. That's why I stay."                   │
├────────────────────────────────────────────────────┤
│  UPCOMING:                                         │
│  - VIP Inspector arriving in 14 days              │
│  - Current Rating: ★★★☆☆ (3/5)                   │
│  - Maintenance scheduled: Level 3 water pipes     │
└────────────────────────────────────────────────────┘
```

### 18.2 Notable Resident Stories

The game tracks and surfaces stories about notable residents:

**Story Types:**

```
LIFE EVENTS:
  - Moved in / Moved out
  - Got promoted / Lost job
  - Made a new friend / Lost a friend
  - Started dating / Got married / Broke up
  - Had a child
  - Health event (illness, recovery)
  - Started a business
  - Retirement
  - Death (natural causes, at end of lifespan)

MILESTONE MOMENTS:
  - 1 year anniversary in arcology
  - Flourishing reached 80+
  - Formed 5th friendship
  - Became community leader
  - Complaint resolved positively

CONFLICT EVENTS:
  - Dispute with neighbor
  - Noise complaint (filed or received)
  - Rent concern
  - Considering leaving
```

**Story Presentation:**

```
┌─────────────────────────────────────────┐
│  RESIDENT UPDATE                        │
├─────────────────────────────────────────┤
│  [Portrait] Maria Chen                  │
│  Floor 47, Apt 3 | 2 years resident    │
│                                         │
│  "I did it! I finally opened my        │
│   restaurant on Level 12. After 18     │
│   months of saving and planning, Chen's│
│   Noodle House is open for business."  │
│                                         │
│  Flourishing: 72 → 81 ↑                │
│  Purpose need satisfied                 │
│                                         │
│  [Visit Restaurant] [Follow Maria]     │
└─────────────────────────────────────────┘
```

### 18.3 Complaint System

Complaints are how residents communicate problems:

```
Complaint {
  resident: person_id
  type: noise | safety | maintenance | service | neighbor | rent | other
  severity: minor | moderate | serious | urgent
  target: block_id | person_id | system
  filed_date: timestamp
  status: new | acknowledged | in_progress | resolved | dismissed
  
  description: generated text
  underlying_need: which need is affected
  resolution_options: [possible actions]
}
```

**Example Complaints:**

```
NOISE COMPLAINT (Moderate)
From: Robert Kim, Level 14, Apt B
"I can hear the nightclub through my floor every 
night until 2am. I work early shifts. I haven't 
slept properly in weeks."

Underlying need: Survival (sleep), Safety (stability)
Resolution options:
  - Soundproof the nightclub ceiling (§2,000)
  - Offer Robert relocation assistance
  - Restrict nightclub hours
  - Dismiss complaint (not recommended)

---

SAFETY COMPLAINT (Serious)  
From: Linda Torres, Level 2
"There was another break-in attempt in our corridor
last week. Third one this month. We need more 
security down here."

Underlying need: Safety
Resolution options:
  - Add security station nearby (§5,000 + §500/mo)
  - Increase patrol frequency (§200/mo)
  - Improve lighting (§1,000)
  - Install cameras (§800)
```

### 18.4 The Zoom-In Moment

Players can enter any block and see the human scale:

**Residential Block:**
```
[Interior view: small apartment]
- Living area with couch, TV, plants
- Kitchen visible in corner
- Window showing arcology view (or artificial light)
- Resident present (if home): reading, cooking, watching TV

Stats overlay:
  Light: 72% (natural, window-facing)
  Air: 85% (good ventilation)
  Noise: 28 (quiet)
  Condition: 89% (well-maintained)
  
  Resident: Maria Chen
  Current mood: Content
  Current activity: Making dinner
```

**Elevator Interior:**
```
[Interior view: elevator car]
- Capacity: 12
- Current occupants: 8
- Floor indicator: 23, going up
- Wait time display: 2:34

Passengers:
  - 3 heading to Level 30 (work)
  - 2 heading to Level 45 (home)
  - 2 heading to Level 50 (penthouse)
  - 1 heading to Level 28 (visiting friend)

Mood indicators visible on passengers
Some chatting, some on phones, one looking annoyed
```

**Restaurant:**
```
[Interior view: restaurant]
- Tables with diners (varying fullness by time)
- Kitchen visible through pass
- Staff moving between tables

Stats overlay:
  Capacity: 40 seats
  Current: 28 occupied (70%)
  Wait list: 4 parties
  Revenue today: §1,240
  
  Notable diners:
  - Maria Chen + David Park (regular lunch)
  - Business meeting, Table 7
```

### 18.5 Time-Lapse Moments

Key moments to watch unfold:

**Morning Rush (7:30-9:00):**
- Watch corridors fill
- See elevator queues grow
- Track commute times
- Feel the system strain (or flow smoothly)

**Lunch Rush (12:00-13:00):**
- Watch offices empty
- See restaurants fill
- Track where people eat (alone vs together)
- Watch Food Hall capture traffic

**Evening Transition (17:00-20:00):**
- Reverse commute
- Entertainment venues open
- Families gather
- Night shift starts

**Crisis Moments:**
- Fire alarm: watch evacuation flow
- Power outage: see cascade effects
- Elevator breakdown: watch frustration spread

### 18.6 Memory and Legacy

The arcology accumulates history:

```
ARCOLOGY TIMELINE:

Year 1: Founded with 500 residents
Year 2: First expansion (Floors 11-20)
Year 3: Community cohesion crisis (recovered)
Year 5: Population reaches 10,000
Year 7: Maria Chen opens restaurant
Year 8: Great Elevator Crisis of Year 8
Year 10: First resident born in arcology reaches adulthood
Year 15: Founder generation begins retiring
Year 20: Original residents becoming minority
...
```

**Memorial System:**
- Residents who die are remembered
- Long-term residents get legacy markers
- Historical events are commemorated
- "This corridor named for Elena Vasquez, 40-year resident"

**User Stories:**

> **US-18.1:** As a player, I want a news digest that tells me what's happening in my arcology in human terms.

> **US-18.2:** As a player, I want to follow individual residents and see their stories unfold.

> **US-18.3:** As a player, I want complaints to surface real problems with actionable solutions.

> **US-18.4:** As a player, I want to zoom into any block and see the human-scale experience.

> **US-18.5:** As a player, I want to watch key moments (rush hour, lunch) unfold in real-time.

> **US-18.6:** As a player, I want my arcology to accumulate history and memory.

---

## 19. Technical Architecture

### 19.1 Data Model Overview

```
Arcology {
  grid: 3D array of Block references (sparse)
  blocks: Map<id, Block>
  
  // Vertical bounds
  vertical_bounds: {
    max_height: int,         // Maximum Z above grade
    max_depth: int,          // Maximum Z below grade (negative)
    permitted_height: int,   // Currently permitted height
    permitted_depth: int,    // Currently permitted depth
  }
  
  infrastructure_networks: {
    power: Network,
    water: Network,
    light_pipes: Network
  }
  transit_graph: Graph<Node, Edge>
  environment_cache: {
    light: 3D array,
    air: 3D array,
    noise: 3D array,
    safety: 3D array
  }
  economy: EconomyState
  population: PopulationState
  scenario: ScenarioConfig
}
```

### 19.2 Simulation Tick Architecture

Different systems update at different frequencies:

| System | Update Frequency | Notes |
|--------|-----------------|-------|
| Environment (light, air, noise) | Every game-hour | Propagation calculations |
| Crime/Safety | Every game-hour | Propagation + decay |
| Foot Traffic | Every game-hour | Based on time-of-day patterns |
| Tenant Decisions | Every game-day | Move in/out, happiness updates |
| Economy | Every game-month | Rent collection, expenses |
| Population | Every game-month | Births, deaths, migration |

### 19.3 Pathfinding Optimization

- Pre-compute **node graph** from room/corridor connectivity
- Recalculate only when structure changes
- Edge weights (travel time) update based on elevator congestion
- Cache common paths (residential → commercial centers)

### 19.4 Environmental Propagation

**Light:**
- Raycast from sky/windows (can be simplified to depth calculation)
- Light pipe network: graph traversal with efficiency loss
- Cache results; invalidate on structure change

**Air:**
- Diffusion model from sources
- Population density affects consumption
- Update propagation each tick, not full recalculation

**Crime:**
- Cellular automata with directional bias (resists upward)
- Sources: darkness, vacancy, existing crime
- Sinks: security, lighting, foot traffic

### 19.5 Performance Targets

| Scale | Blocks | Population | Target FPS |
|-------|--------|------------|------------|
| Small | ~1,000 | ~5,000 | 60 |
| Medium | ~5,000 | ~25,000 | 60 |
| Large | ~20,000 | ~100,000 | 30+ |

### 19.6 Save/Load

- Serialize arcology state to JSON or binary format
- Support autosave at configurable intervals
- Support multiple save slots per scenario

### 19.7 Agent Simulation Architecture

The human simulation is the most computationally intensive system:

```
AGENT UPDATE FREQUENCY:

Every game-minute:
  - Current location update
  - Activity state machine
  - Elevator/transit waiting

Every game-hour:
  - Needs decay/recovery
  - Social interaction checks
  - Mood calculation
  
Every game-day:
  - Relationship maintenance
  - Complaint generation
  - Flight risk calculation
  - Schedule planning for next day

Every game-week:
  - Major life decisions
  - Friendship formation/decay
  - Long-term trajectory
```

**Performance Optimization:**

```
AGENT BATCHING:
  - Not all agents update simultaneously
  - Spread updates across game ticks
  - Priority queue: visible agents update more often
  
SPATIAL PARTITIONING:
  - Agents grouped by location
  - Only simulate interactions within proximity
  - Skip detailed sim for isolated agents
  
NOTABLE vs BACKGROUND AGENTS:
  - 100-500 "notable" agents: full simulation
  - Remaining population: statistical simulation
  - Notable agents surface to player
  - Background agents affect aggregates only

LOD SYSTEM:
  - Zoomed out: aggregate flows only
  - Zoomed in: individual agents visible
  - Detail level affects simulation granularity
```

### 19.8 Elevator Simulation Deep Dive

The elevator is the core puzzle of the game—it deserves detailed simulation:

```
ElevatorBank {
  id: unique
  shafts: [Shaft]
  floors_served: [int]
  express_mode: bool
  express_stops: [int]  // if express mode
  
  // Real-time metrics
  average_wait_time: MovingAverage
  peak_hour_wait: float
  daily_trips: int
  complaints_this_month: int
}

Shaft {
  id: unique
  cars: [Car]  // usually 1, can be 2 for double-deck
  
  // Configuration
  speed: slow | medium | fast | express
  capacity: 8 | 12 | 16 | 20
  
  // State
  maintenance_condition: 0-100
  breakdown_risk: float
}

Car {
  shaft: shaft_id
  current_floor: float  // fractional during movement
  direction: up | down | idle
  passengers: [Agent]
  destination_queue: [int]  // floors to visit
  
  // Dispatch
  mode: collective | destination_dispatch
  assigned_calls: [Call]
}

Call {
  origin_floor: int
  destination_floor: int  // if destination dispatch
  direction: up | down    // if collective
  caller: agent_id
  wait_start: timestamp
}
```

**Dispatch Algorithms:**

```
COLLECTIVE CONTROL (Simple):
  - Default for early game
  - Car travels in one direction
  - Stops at all requested floors in that direction
  - Reverses when no more calls ahead
  
  Pros: Simple, intuitive
  Cons: Inefficient for tall buildings

DESTINATION DISPATCH (Tech Level 3):
  - Passengers enter destination before boarding
  - System assigns optimal car
  - Groups passengers going to similar floors
  
  Pros: 20-30% efficiency gain
  Cons: Feels impersonal, learning curve

EXPRESS WITH SKY LOBBY:
  - Express cars only stop at sky lobbies
  - Local cars serve floors around each sky lobby
  - Requires transfer for long trips
  
  Pros: Fast for long vertical travel
  Cons: Transfer time, class resentment if separate
```

**Wait Time Psychology:**

```
PERCEIVED vs ACTUAL WAIT:

Factors that increase perceived wait:
  - No indicator: +50%
  - Watching full cars pass: +30%
  - Running late: +40%
  - Uncomfortable lobby: +25%
  - Standing alone: +20%
  
Factors that decrease perceived wait:
  - Countdown display: -30%
  - Pleasant waiting area: -20%
  - Friend to chat with: -25%
  - Distraction (art, screens): -15%
  - Mirrors (feeling observed): -10%

FRUSTRATION MODEL:
  actual_wait = time_in_queue
  perceived_wait = actual_wait × perception_multipliers
  tolerance = f(personality.patience, time_of_day, urgency)
  
  frustration += (perceived_wait - tolerance) × personality.neuroticism / 10
  
  if frustration > 50: show_annoyance()
  if frustration > 80: generate_complaint()
  if frustration > 100 for 5 days: flight_risk += 10
```

**Elevator Social Dynamics:**

```
ELEVATOR ENCOUNTERS:

When strangers share elevator:
  - Base 2% chance of acquaintance per ride
  - +3% if similar archetype
  - +5% if one initiates conversation (extrovert)
  - +10% if notable event (breakdown, long wait)

When acquaintances share elevator:
  - Relationship +1 per shared ride
  - Brief greeting animation

When friends share elevator:
  - Relationship +2
  - Conversation animation
  - Nearby passengers: +1% acquaintance chance (social proof)

When enemies share elevator:
  - Awkward silence animation
  - Stress +5 for both
  - Others notice tension
```

**Elevator Failure Cascades:**

```
BREAKDOWN EVENT:

Trigger:
  maintenance_condition < 40: 5% daily chance
  maintenance_condition < 20: 15% daily chance
  maintenance_condition < 10: guaranteed within week

Immediate effects:
  - Passengers trapped (if occupied): major stress event
  - Shaft capacity: -100%
  - Other shafts in bank: +50% load
  
Cascade:
  Hour 1: Wait times spike 2-3x
  Hour 2-4: Frustration spreads, complaints surge
  Day 1: Productivity loss, missed appointments
  Day 2+: Flight risk increases, reputation damage
  
Recovery:
  - Repair time: 4-48 hours depending on severity
  - Trust recovery: weeks to months
  - "The elevator that trapped me" memory persists
```

### 19.9 Performance Scaling Strategy

```
TARGET: 100,000 population at 30+ FPS

STRATEGY:

1. HIERARCHICAL SIMULATION
   - District level: aggregate flows
   - Building level: block interactions
   - Room level: individual agents (when viewed)
   
2. TEMPORAL BATCHING
   - Not all systems update every frame
   - Spread computation across frames
   - Priority queue based on visibility
   
3. SPATIAL CULLING
   - Only simulate visible areas in detail
   - Background areas: statistical approximation
   - "Catch up" simulation when area becomes visible
   
4. AGENT INSTANCING
   - 500 notable agents: full simulation
   - 99,500 background agents: statistical
   - Background contributes to aggregates only
   - Promote background to notable if relevant
   
5. CACHING
   - Pathfinding: pre-computed, invalidate on change
   - Environment: computed hourly, not per-frame
   - Social graph: lazy evaluation
```

**User Stories:**

> **US-19.1:** As a developer, I want environmental systems to update efficiently without recalculating the entire grid every tick.

> **US-19.2:** As a developer, I want the pathfinding graph to be separate from the voxel grid for performance.

> **US-19.3:** As a developer, I want to be able to profile which systems are causing slowdown at scale.

> **US-19.4:** As a player, I want the game to autosave so I don't lose progress.

> **US-19.5:** As a developer, I want the elevator simulation to feel deep and consequential without becoming a separate minigame.

> **US-19.6:** As a developer, I want 100K population to be playable on mid-range hardware.

---

## Appendix A: Complete Block Catalog

### A.1 Infrastructure Blocks

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Power Plant (Fossil) | Large | Water, Path | Pop 500 | Power (high), Pollution, Noise | Powered blocks |
| Power Plant (Solar) | Medium | Natural Light, Path | None | Power (variable) | Sustainable energy |
| Power Plant (Nuclear) | Large | Water, Path | Pop 10K, Tech 2 | Power (very high) | Deep arcology |
| Water Treatment | Large | Power, Path | Pop 200 | Water supply | Water network |
| Water Tower | Large | Water, Power | Height placement | Water pressure (upper floors) | High-rise |
| HVAC Central | Medium | Power, Water, Path | Pop 1K | Processed Air (large radius) | Deep interior |
| HVAC Vent | Small | Power, HVAC connection | HVAC Central exists | Processed Air (small radius) | Local air |
| Solar Collector | Small | Natural Light | Roof placement | Piped Light, Power (small) | Light network |
| Light Pipe Junction | Small | Piped Light input | Solar Collector exists | Piped Light distribution | Interior light |
| Waste Processing | Medium | Power, Water, Path | Pop 500 | Removes Waste, Biomass | Sanitation |

### A.2 Transit Blocks

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Corridor | Small | Light, Air | Path connection | Path, Foot Traffic route | Connectivity |
| Stairs | Small | Light | Connects 2 floors | Vertical path (±3 floors, slow) | Basic vertical |
| Elevator (Local) | Small | Power | Pop 200 | Vertical path (±10 floors) | Mid-rise |
| Elevator (Express) | Medium | Power | Pop 5K, Sky Lobby | Vertical path (±30 floors, fast) | High-rise |
| Sky Lobby | Large | Power, Light, Air, Path | Pop 5K | Transit hub, Foot Traffic | Express elevators |
| Grand Terminal | Mega | Power, Light, Air, Water | Pop 10K | External connection, massive traffic | External transit |
| Freight Elevator | Medium | Power | Industrial exists | Freight path | Interior industrial |

### A.3 Residential Blocks

**Standard Housing:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Budget Housing | Small | Power, Air (any), Light (any), Path | None | Housing (4 units), low Rent | Population |
| Standard Housing | Small | Power, Air, Light (50%+), Path, Water | Pop 500 | Housing (2 units), medium Rent | Stable pop |
| Premium Housing | Small | Power, Fresh Air, Natural Light (70%+), Path, Water | Pop 2K | Housing (1 unit), high Rent | Wealthy pop |
| Penthouse | Medium | Power, Fresh Air, Natural Light (90%+), Path, Water, Quiet | Top floor, Pop 5K | Housing (1 unit), very high Rent | Elite |
| Family Housing | Medium | Power, Air, Light (60%+), Path, Water, School access | School exists | Housing (2 family units), Births | Pop growth |

**Specialized Housing:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Studio Apartment | Small | Power, Air, Light (40%+), Path | None | Housing (6 units), low Rent | Density |
| Dormitory | Medium | Power, Air, Light (50%+), Path, Water | University | Housing (20 units), very low Rent | Student housing |
| Senior Housing | Medium | Power, Air, Light (60%+), Path, Water, Clinic access | Pop 3K | Housing (8 units), assisted living | Elderly support |
| Artist Loft | Small | Power, Air, Light (60%+), Path | Pop 2K | Housing (2 units), Purpose (+), low Rent | Creative community |
| Worker Housing | Small | Power, Air, Path | Industrial exists | Housing (4 units), very low Rent | Industrial support |
| Bunker Housing | Small | Power, Air | None | Housing (8 units), emergency/low Rent | Crisis housing |

**Communal Living:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Co-Housing | Medium | Power, Air, Light (50%+), Path, Water | Pop 1K | Housing (6 units), Belonging (+) | Community |
| Commune | Large | Power, Air, Light (50%+), Path, Water | Pop 2K | Housing (12 units), Belonging (++), Purpose (+) | Alternative living |
| Boarding House | Medium | Power, Air, Light (40%+), Path, Water | Pop 500 | Housing (10 units), low Rent, shared facilities | Budget density |

### A.4 Commercial Blocks

**Retail:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Small Shop | Small | Power, Light, Air, Path, Foot Traffic (10+) | Demand | Service Jobs (2), Retail | Commerce |
| Boutique | Small | Power, Light (60%+), Air, Path, Foot Traffic (20+) | Pop 2K | Service Jobs (3), Premium Retail, Vibes | Upscale shopping |
| Department Store | Large | Power, Light, Air, Path, Freight, Foot Traffic (50+) | Pop 5K | Service Jobs (30), Major Retail | Shopping destination |
| Grocery | Medium | Power, Light, Air, Path, Water, Freight | Pop 500 | Service Jobs (8), Food Access radius | Residential viability |
| Pharmacy | Small | Power, Light, Air, Path | Pop 1K, Clinic | Service Jobs (4), Medicine Access | Healthcare support |
| Hardware Store | Small | Power, Light, Path, Freight | Pop 1K | Service Jobs (4), Repair supplies | Maintenance support |
| Electronics Shop | Small | Power, Light, Air, Path | Pop 2K | Service Jobs (3), Tech retail | Consumer electronics |
| Bookstore | Small | Power, Light, Air, Path | Pop 1K | Service Jobs (2), Culture, Purpose (+) | Literary community |

**Food & Beverage:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Restaurant | Small | Power, Light, Air, Path, Water, Foot Traffic (20+) | Food supply | Service Jobs (4), Food service, Vibes | Dining |
| Cafe | Small | Power, Light, Air, Path, Foot Traffic (15+) | Demand | Service Jobs (2), Vibes, Third place | Social gathering |
| Bar | Small | Power, Light, Air, Path | Pop 1K | Service Jobs (3), Night economy, Vibes | Entertainment |
| Nightclub | Medium | Power (high), Air, Path, Sound | Pop 3K | Service Jobs (10), Entertainment, Noise | Night economy |
| Fast Food | Small | Power, Water, Path, Freight | Pop 500 | Service Jobs (4), Quick meals | Budget dining |

**Office & Professional:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Office Suite | Small | Power, Light (60%+), Air, Path, Data | Pop 1K | Office Jobs (10), Rent | White collar |
| Coworking Space | Medium | Power, Light (60%+), Air, Path, Data | Pop 2K | Flexible Office (20), Belonging (+) | Remote workers |
| Law Office | Small | Power, Light, Air, Path, Data | Pop 3K | Professional Jobs (6), Legal services | Business support |
| Medical Office | Small | Power, Light, Air, Path, Water | Pop 2K | Healthcare Jobs (4), Specialist care | Healthcare tier 2 |
| Dental Clinic | Small | Power, Light, Air, Path, Water | Pop 2K | Healthcare Jobs (3), Dental care | Healthcare |
| Clinic | Medium | Power, Light, Air, Path, Water | Pop 1K | Service Jobs (6), Healthcare radius | Health coverage |
| Accounting Firm | Small | Power, Light, Air, Path, Data | Pop 2K | Professional Jobs (5), Financial services | Business support |

**Services:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Hair Salon | Small | Power, Light, Air, Path, Water | Pop 500 | Service Jobs (3), Grooming, Belonging (+) | Personal care |
| Gym/Fitness | Medium | Power, Light, Air, Path, Water | Pop 1K | Service Jobs (6), Health (+), Belonging (+) | Wellness |
| Spa | Medium | Power, Light (60%+), Air, Path, Water | Pop 3K | Service Jobs (8), Luxury, Esteem (+) | Premium wellness |
| Laundromat | Small | Power, Water, Path | Pop 500 | Service Jobs (2), Laundry service | Residential support |
| Dry Cleaner | Small | Power, Path | Pop 1K | Service Jobs (2), Premium laundry | Business district |
| Bank Branch | Small | Power, Light, Air, Path, Data | Pop 2K | Service Jobs (4), Financial access | Economic infrastructure |
| Post Office | Small | Power, Light, Path | Pop 1K | Service Jobs (4), Mail/Package | Logistics |
| Hotel | Large | Power, Light, Air, Path, Water | Pop 5K | Service Jobs (25), Visitor housing, Tourism | External visitors |

### A.5 Industrial Blocks

**Manufacturing:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Light Manufacturing | Medium | Power, Path, Freight | Pop 1K | Labor Jobs (20), Goods, Noise | Exports |
| Heavy Manufacturing | Large | Power (high), Water, Path, Freight | Pop 5K | Labor Jobs (50), Goods, Pollution | Major exports |
| Electronics Factory | Medium | Power (high), Path, Freight, Data | Tech 2 | Skilled Jobs (25), Electronics, low Noise | Tech goods |
| Textile Mill | Medium | Power, Water, Path, Freight | Pop 2K | Labor Jobs (30), Textiles, Noise | Clothing supply |
| Plastics Factory | Medium | Power, Water, Path, Freight | Pop 3K | Labor Jobs (20), Plastics, Pollution | Component supply |
| Metal Fabrication | Medium | Power (high), Path, Freight | Pop 2K | Skilled Jobs (15), Metal Parts, Noise | Construction supply |
| Chemical Plant | Large | Power (high), Water (high), Path, Freight | Tech 2, Pop 5K | Skilled Jobs (20), Chemicals, Pollution | Pharmaceuticals |
| Pharmaceutical Lab | Medium | Power, Water, Path, Data | Tech 3, Chemical Plant | Skilled Jobs (30), Medicine | Healthcare boost |
| 3D Print Farm | Medium | Power (high), Path, Data, Freight | Tech 2 | Skilled Jobs (10), Custom Goods | On-demand manufacturing |
| Assembly Line | Large | Power, Path, Freight | Manufacturing exists | Labor Jobs (40), Finished Goods | Export boost |

**Maker & Fabrication:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Maker Space | Medium | Power, Light, Air, Path | Pop 1K | Purpose (+), Creativity, 4 jobs | Community innovation |
| Fab Lab | Medium | Power (high), Path, Data | Tech 2, Pop 2K | Prototyping, Skilled Jobs (8), Purpose (+) | Startup incubation |
| Repair Shop | Small | Power, Path | Pop 500 | Repair services, 3 jobs | Reduces waste |
| Craft Workshop | Small | Power, Light, Air, Path | Pop 500 | Artisan Goods, 2 jobs, Purpose (+) | Cultural goods |
| Ceramics Studio | Small | Power, Water, Path | Pop 1K | Art Goods, 2 jobs, Purpose (+) | Art scene |
| Woodworking Shop | Small | Power, Path, Freight | Pop 500 | Furniture, 3 jobs, Noise (low) | Custom furnishing |
| Metal Shop | Small | Power (high), Path | Pop 1K | Metal Art/Parts, 2 jobs, Noise | Custom metalwork |

**Processing & Storage:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Warehouse | Medium | Power, Path, Freight | Commercial exists | Storage, Freight distribution | Supply chain |
| Cold Storage | Medium | Power (high), Path, Freight | Food supply | Food preservation, 4 jobs | Extended food life |
| Data Center | Medium | Power (high), Cooling, Path, Data | Pop 5K | Data capacity, Office Jobs (10), Heat | Tech economy |
| Server Vault | Small | Power (high), Path, Data | Data Center | Secure data storage, 2 jobs | High security data |
| Recycling Center | Medium | Power, Water, Path, Freight | Pop 3K | Resource recovery, Labor Jobs (15) | Waste reduction |
| Waste Processing | Medium | Power, Water, Path | Pop 2K | Waste disposal, Labor Jobs (10), Odor | Sanitation |
| Water Treatment | Large | Power, Path | Pop 500 | Clean Water supply, 8 jobs | Water network |

**Food Production:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Vertical Farm | Medium | Power, Water, Light | Pop 2K | Labor Jobs (10), Raw Food, Fresh Air | Food independence |
| Hydroponics Bay | Small | Power, Water, Light | Pop 1K | Raw Food (small), 4 jobs | Compact farming |
| Mushroom Farm | Medium | Power, Water, Path | Pop 1K | Food (no light needed), 6 jobs | Subterranean food |
| Aquaculture Tank | Medium | Power, Water (high), Path | Pop 2K | Protein source, 8 jobs | Fish/seafood |
| Food Processing | Medium | Power, Water, Path, Raw Food | Vertical Farm | Labor Jobs (15), Processed Food | Food chain |
| Brewery/Distillery | Medium | Power, Water, Path, Freight | Pop 3K | Beverages, 8 jobs, Entertainment boost | Social venues |
| Bakery (Industrial) | Medium | Power, Water, Path, Freight | Food Processing | Baked Goods, 10 jobs, Vibes (+) | Retail bakeries |

### A.6 Civic Blocks

**Government & Administration:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Admin Center | Medium | Power, Light, Air, Path, Data | Pop 5K | Governance, Jobs (30) | Pop cap increase |
| City Hall | Large | Power, Light (60%+), Air, Path, Data | Pop 10K | Governance (large), Jobs (50), Events | Major decisions |
| Courthouse | Medium | Power, Light (60%+), Air, Path, Data | Pop 10K | Legal services, Jobs (20) | Dispute resolution |
| Post Office | Small | Power, Light, Path | Pop 1K | Mail services, Jobs (4) | Communication |

**Emergency Services:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Security Station | Small | Power, Path | Pop 500 | Safety radius, Security Jobs (4) | Crime control |
| Police HQ | Medium | Power, Path, Data | Pop 5K | Safety (large radius), Jobs (20) | Station boost |
| Fire Station | Medium | Power, Path, Water | Pop 2K | Fire safety radius, Jobs (10) | Disaster response |
| Emergency Clinic | Medium | Power, Light, Air, Path, Water | Pop 3K | Emergency care, Jobs (15) | Crisis response |
| Dispatch Center | Small | Power, Data | Security Station, Fire Station | Coordination, Jobs (6) | Response time boost |

**Education:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Daycare | Medium | Power, Light (60%+), Air, Path, Water | Pop 1K | Childcare radius, 10 jobs | Family support |
| School | Medium | Power, Light (60%+), Air, Path, Water | Pop 1K | Education radius, Jobs (15) | Family housing |
| High School | Large | Power, Light (60%+), Air, Path, Water, Data | Pop 5K, School | Secondary ed, Jobs (30) | Youth development |
| University | Large | Power, Light, Air, Path, Water, Data | Pop 10K, School | Education (large), Jobs (100), Research | Tech Level 2 |
| Trade School | Medium | Power, Light, Air, Path | Pop 3K | Skilled training, Jobs (20) | Industrial workforce |
| Library | Medium | Power, Light (60%+), Air, Path, Data | Pop 2K | Education, Purpose, Quiet space, 8 jobs | Research bonus |

**Healthcare:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Clinic | Medium | Power, Light, Air, Path, Water | Pop 1K | Healthcare radius, Jobs (6) | Health coverage |
| Hospital | Large | Power (high), Light, Air, Path, Water, Data | Pop 10K | Major healthcare, Jobs (100) | Advanced care |
| Mental Health Center | Medium | Power, Light (60%+), Air, Path | Pop 5K | Mental health services, Jobs (15) | Crisis support |
| Senior Center | Medium | Power, Light, Air, Path, Water | Pop 5K | Elderly care, Purpose, Jobs (6) | Retiree support |
| Rehabilitation Center | Medium | Power, Light, Air, Path, Water | Pop 5K | Recovery services, Jobs (12) | Wellness |

**Religious & Spiritual:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Chapel | Small | Power, Light, Air, Path | Pop 500 | Belonging (+), Purpose (+), 1 job | Community |
| Church | Medium | Power, Light (60%+), Air, Path | Pop 2K | Belonging (large), Purpose (large), 4 jobs | Weddings, funerals |
| Temple | Medium | Power, Light (60%+), Air, Path | Pop 2K | Belonging (large), Purpose (large), 4 jobs | Cultural anchor |
| Mosque | Medium | Power, Light (60%+), Air, Path, Water | Pop 2K | Belonging (large), Purpose (large), 4 jobs | Community center |
| Synagogue | Medium | Power, Light (60%+), Air, Path | Pop 2K | Belonging (large), Purpose (large), 4 jobs | Cultural anchor |
| Meditation Center | Small | Power, Light, Air, Path, Quiet | Pop 1K | Purpose (+), Stress reduction, 2 jobs | Wellness |
| Interfaith Center | Large | Power, Light (60%+), Air, Path | Pop 5K | Multi-faith services, Belonging (++), 6 jobs | Diversity support |
| Funeral Home | Small | Power, Light, Air, Path | Pop 5K | Death services, Belonging (grief), 3 jobs | Memorial system |

**Community & Culture:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Community Center | Medium | Power, Light, Air, Path, Water | Pop 1K | Belonging (large), Event space, 6 jobs | Community events |
| Cultural Center | Medium | Power, Light (60%+), Air, Path | Pop 3K | Culture, Belonging, Purpose, 8 jobs | Diversity |
| Museum | Large | Power, Light (60%+), Air, Path | Pop 5K | Culture, Education, Tourism, 15 jobs | Heritage |
| Art Gallery | Medium | Power, Light (60%+), Air, Path | Pop 3K | Culture, Purpose, Vibes, 6 jobs | Art scene |
| Theater | Large | Power (high), Light, Air, Path | Pop 5K | Entertainment, Culture, 20 jobs | Performing arts |
| Concert Hall | Large | Power (high), Light, Air, Path, Sound | Pop 10K | Entertainment, Culture, 25 jobs | Major events |
| Counseling Office | Small | Power, Light, Air, Path | Pop 2K | Mental health radius, 2 jobs | Crisis support |

### A.7 Entertainment & Recreation

**Sports & Fitness:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Gym | Medium | Power, Light, Air, Path, Water | Pop 1K | Health (+), Belonging (+), 6 jobs | Fitness |
| Sports Court | Medium | Power, Light, Air, Path | Pop 2K | Recreation, Belonging, 2 jobs | Team sports |
| Swimming Pool | Large | Power, Water (high), Air, Path | Pop 3K | Health, Recreation, 8 jobs | Aquatics |
| Arena | Mega | Power (high), Light, Air, Path | Pop 10K | Major events, Entertainment, 50 jobs | Pro sports |
| Bowling Alley | Medium | Power, Light, Air, Path | Pop 2K | Recreation, Belonging, 6 jobs | Social activity |
| Ice Rink | Large | Power (high), Water, Path | Pop 5K | Recreation, Entertainment, 10 jobs | Winter sports |

**Entertainment:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Cinema | Medium | Power, Air, Path | Pop 2K | Entertainment, 8 jobs | Movies |
| Arcade | Small | Power, Light, Air, Path | Pop 1K | Entertainment, Youth, 4 jobs | Gaming |
| VR Lounge | Small | Power (high), Air, Path, Data | Tech 2 | Entertainment, 4 jobs | Future gaming |
| Nightclub | Medium | Power (high), Air, Path, Sound | Pop 3K | Night economy, Entertainment, Noise, 10 jobs | Nightlife |
| Comedy Club | Small | Power, Light, Air, Path | Pop 2K | Entertainment, Belonging, 4 jobs | Social |
| Casino | Large | Power (high), Light, Air, Path | Pop 10K | Entertainment, Revenue, 30 jobs | Gambling |

**Relaxation & Leisure:**

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Spa | Medium | Power, Light (60%+), Air, Path, Water | Pop 3K | Luxury, Esteem (+), 8 jobs | Premium wellness |
| Sauna | Small | Power (high), Water, Path | Pop 2K | Health, Relaxation, 2 jobs | Wellness |
| Massage Parlor | Small | Power, Light, Air, Path | Pop 2K | Relaxation, Health, 4 jobs | Wellness |
| Social Club | Medium | Power, Light, Air, Path | Pop 3K | Belonging, Esteem, 4 jobs | Networking |
| Game Room | Small | Power, Light, Air, Path | Pop 1K | Recreation, Belonging, 2 jobs | Casual social |
| Karaoke Bar | Small | Power, Light, Air, Path, Sound | Pop 2K | Entertainment, Belonging, Noise, 3 jobs | Nightlife |

### A.8 Security & Access Control

**Security Infrastructure:**

| Block | Size | Needs | Preconditions | Function | Notes |
|-------|------|-------|---------------|----------|-------|
| Security Checkpoint | Small | Power, Path, Data | Security Station | Access control, ID verification | Blocks crime propagation |
| Security Gate | Small | Power, Path | Pop 500 | Controlled access point | Configurable rules |
| Blast Door | Small | Power (high) | Tech 2 | Emergency seal, high security | Mars/Space essential |
| Turnstile Bank | Small | Power, Path | Pop 1K | High-throughput access control | Commercial areas |
| Mantrap/Airlock | Medium | Power (high), Path | Tech 2 | Double-door security | High-security zones |
| Guard Booth | Small | Power, Path | Security Station | Manned checkpoint, 2 jobs | Visual deterrent |
| Watchtower | Small | Power, Path | Pop 2K | Extended sight radius, 1 job | Perimeter security |
| Armory | Small | Power, Path, Data | Police HQ | Weapon storage, security supply | Emergency response |

**Defensive Systems:**

| Block | Size | Needs | Preconditions | Function | Notes |
|-------|------|-------|---------------|----------|-------|
| Sentry Turret | Small | Power (high), Data | Tech 3, Police HQ | Automated defense | Lethal, last resort |
| Stun Turret | Small | Power, Data | Tech 2, Security Station | Non-lethal deterrent | Incapacitates intruders |
| Surveillance Hub | Medium | Power (high), Data | Pop 5K | Camera network control, 4 jobs | Crime detection boost |
| Drone Bay (Security) | Medium | Power, Path, Data | Tech 2 | Security drone dispatch | See Drones section |

**Access Control Rules:**

Gates and checkpoints can be configured with conditions:

```
ACCESS RULE TYPES:

Residency-Based:
  - "Residents of Sector B only"
  - "Floors 40+ residents only"
  - "Building residents only"

Clearance-Based:
  - "Security clearance Level 2+"
  - "Staff only"
  - "VIP access"

Time-Based:
  - "Open 06:00-22:00"
  - "Curfew after midnight"
  - "Weekdays only"

Conditional:
  - "Employment in this sector"
  - "Valid visitor pass"
  - "Emergency personnel always"

Combined:
  - "Residents OR clearance Level 3"
  - "Staff during day, residents only at night"
```

**Access Control Effects:**

| Setting | Crime Effect | Traffic Effect | Social Effect |
|---------|--------------|----------------|---------------|
| Open | None | Free flow | None |
| Resident-Only | -30% crime inflow | Slight delay | Excludes visitors |
| Staff-Only | -50% crime inflow | Moderate delay | Creates "zones" |
| High-Security | -80% crime inflow | Significant delay | Isolation risk |
| Locked | -100% crime inflow | Blocked | Severe isolation |

### A.9 Drones & Robots

Automated units that supplement human workers:

**Patrol & Security:**

| Unit | Size | Needs | Preconditions | Function | Notes |
|------|------|-------|---------------|----------|-------|
| Security Drone | — | Drone Bay, Power | Tech 2 | Patrols corridors, crime deterrent | Extends safety radius |
| Guard Bot | — | Robot Bay, Power | Tech 3 | Stationary/patrol guard duty | Replaces 1 security job |
| Surveillance Drone | — | Drone Bay, Power | Tech 2 | Mobile camera, tracks incidents | Crime detection |

**Maintenance & Repair:**

| Unit | Size | Needs | Preconditions | Function | Notes |
|------|------|-------|---------------|----------|-------|
| Repair Drone | — | Drone Bay, Power | Tech 2 | Fixes minor damage automatically | Reduces maintenance cost |
| Cleaning Bot | — | Robot Bay, Power | Tech 2 | Maintains corridor cleanliness | +Vibes, -maintenance |
| Inspection Drone | — | Drone Bay, Power | Tech 2 | Detects problems early | Prevents breakdowns |

**Logistics & Service:**

| Unit | Size | Needs | Preconditions | Function | Notes |
|------|------|-------|---------------|----------|-------|
| Delivery Drone | — | Drone Bay, Power | Tech 2 | Small package delivery | Reduces foot traffic |
| Cargo Bot | — | Robot Bay, Power, Freight | Tech 2 | Heavy goods transport | Industrial logistics |
| Service Bot | — | Robot Bay, Power | Tech 3 | Basic customer service | Supplements retail staff |

**Drone/Robot Infrastructure:**

| Block | Size | Needs | Preconditions | Produces | Notes |
|-------|------|-------|---------------|----------|-------|
| Drone Bay | Medium | Power (high), Path, Data | Tech 2 | Drone capacity (10), 2 jobs | Dispatch & charging |
| Robot Bay | Medium | Power (high), Path, Freight | Tech 2 | Robot capacity (5), 4 jobs | Storage & maintenance |
| Charging Station | Small | Power (high) | Drone/Robot Bay | Extends drone range | Distributed charging |
| Drone Corridor | Small | Power, Path | Drone Bay | Dedicated drone transit | Faster drone movement |

**Drone Behavior:**

```
PATROL MODE:
  - Follows assigned route
  - Deters crime in radius (like security camera)
  - Reports incidents to Security Station
  - Returns to bay for charging

RESPONSE MODE:
  - Dispatched to incidents
  - Arrives faster than human security
  - Can track/follow suspects
  - Cannot make arrests (alerts humans)

MAINTENANCE MODE:
  - Patrols assigned blocks
  - Detects condition drops early
  - Performs minor repairs (condition +5)
  - Major repairs still need human crew
```

**Robot vs Human Tradeoffs:**

| Factor | Robots/Drones | Human Workers |
|--------|---------------|---------------|
| Cost | High upfront, low ongoing | Low upfront, ongoing wages |
| Reliability | 24/7, no breaks | Shifts, sick days, vacations |
| Flexibility | Limited to programming | Adaptable, creative |
| Social | No relationships | Builds community |
| Vibes | Slightly sterile (-2) | Human presence (+2) |
| Crime Response | Detection only | Full response |
| Resident Comfort | Some find unsettling | Familiar, trustworthy |

### A.10 Green Blocks

| Block | Size | Needs | Preconditions | Produces | Unlocks |
|-------|------|-------|---------------|----------|---------|
| Planter | Small | Water, Light (any) | None | Vibes (small), tiny Fresh Air | Aesthetics |
| Courtyard Garden | Medium | Water, Light (50%+) | Path | Vibes (medium), Fresh Air (small) | Interior green |
| Indoor Forest | Mega | Water (high), Light (60%+), Path | Pop 5K | Fresh Air (large), Vibes (large), Biomass | Deep interior |
| Rooftop Park | Large | Water, Natural Light | Roof | Fresh Air, Vibes (large), Traffic | Penthouse value |
| Atrium | Mega | None (void) | Structural | Natural Light (down), Fresh Air, Vibes | Interior daylight |

### A.11 Mega-Blocks Summary

| Mega-Block | Size | Primary Role | Key Outputs |
|------------|------|--------------|-------------|
| Indoor Forest | 5×5×3 | Environmental | Fresh Air, Vibes, Noise reduction |
| Atrium | 3×3×5+ (void) | Light well | Natural Light to interior, Vibes |
| Grand Terminal | 5×5×2 | External transit | Massive foot traffic, External connection |
| Arena/Stadium | 6×6×3 | Entertainment | Event revenue, Periodic traffic |
| Galleria/Mall | 5×5×2 | Commercial | Shopping destination, Retail slots |
| Medical Center | 5×5×2 | Healthcare | Health coverage, Reduces deaths |
| Sky Lobby | 4×4×2 | Transit hub | Elevator transfer, Commercial node |
| Market Hall | 4×4×1 | Food/Services | Daily traffic, Service hub |

### A.12 Subterranean-Optimized Blocks

These blocks are designed to work well below grade, either tolerating or benefiting from subterranean placement:

| Block | Size | Why Subterranean Works | Notes |
|-------|------|----------------------|-------|
| Parking Garage | Large | No light/air needs for vehicles | Frees surface for habitation |
| Nightclub/Bar | Medium | Darkness is aesthetic; soundproofing natural | Evening economy driver |
| Data Center | Medium | Cool temperatures, security from isolation | High power need |
| Warehouse | Medium | Storage doesn't need light/vibes | Freight access required |
| Water Treatment | Large | No residents to complain about noise | Best at lowest point (gravity) |
| Power Plant (Nuclear) | Large | Containment, distance from residents | Radiation shielding from depth |
| Heavy Industrial | Large | Pollution/noise contained underground | Freight elevator required |
| Bunker Housing | Small | Accepts low vibes for low rent; emergency use | Mars/Space station staple |
| Mushroom Farm | Medium | Doesn't need sunlight; produces food | Alternative to vertical farm |
| Recycling Center | Medium | Processes waste into resources | Reduces waste export needs |
| Cold Storage | Medium | Naturally cool at depth | Food preservation |
| Server Vault | Small | Secure, cool, no window needs | Data backup, high security |
| Underground Transit Station | Large | Connects to external subway/transit | Major foot traffic node |
| Geothermal Plant | Large | Requires deep placement | Mars scenario essential |

### A.13 Food Blocks

**Small Food (1×1):**

| Block | Size | Traversability | Needs | Produces | Notes |
|-------|------|----------------|-------|----------|-------|
| Food Cart | 1×1 | Private | Power, Water, Path, Foot Traffic | Food service, 2 jobs | Mobile feel, cheap |
| Cafe | 1×1 | Private | Power, Water, Light, Air, Path | Food service, 4 jobs, +Vibes radius | Coffee, light food |
| Fast Food | 1×1 | Private | Power, Water, Light, Air, Path, Freight | Food service, 6 jobs | High turnover |
| Bar | 1×1 | Private | Power, Water, Light, Air, Path | Drinks, 4 jobs | Evening peak, night economy |

**Medium Food (2×2):**

| Block | Size | Traversability | Needs | Produces | Notes |
|-------|------|----------------|-------|----------|-------|
| Restaurant | 2×2 | Private | Power, Water, Light (60%+), Air, Path | Food service, 10 jobs, +Vibes | Sit-down dining |
| Bakery | 2×2 | Private | Power, Water, Light, Air, Path, Freight | Food production + retail, 8 jobs | Makes + sells |
| Grocery (small) | 2×2 | Private | Power, Water, Light, Air, Path, Freight | Food access radius, 12 jobs | Convenience store |

**Large Food (3×3 to 4×4):**

| Block | Size | Traversability | Needs | Produces | Notes |
|-------|------|----------------|-------|----------|-------|
| Grocery (full) | 3×3 | Private | Power, Water, Light, Air, Path, Freight | Large food access radius, 25 jobs | Supermarket |
| Restaurant (upscale) | 3×3 | Private | Power, Water, Light (70%+), Fresh Air, Path | Premium food, 15 jobs, high Vibes | Fine dining |

**Mega Food (Traversable):**

| Block | Size | Traversability | Needs | Produces | Notes |
|-------|------|----------------|-------|----------|-------|
| Food Hall | 5×5×1 | **PUBLIC** | Power (80), Water (40), Light (60%+), Air, Path (3+ entries) | 50+ vendor slots, massive traffic, Vibes (+20) | Routes through! |
| Market Hall | 4×4×1 | **PUBLIC** | Power (40), Water (30), Light (50%+), Air, Path (2+ entries) | Fresh food vendors, 30 jobs, Vibes (+15) | Daily traffic |

**Food Hall Detail:**

```
FOOD HALL
Size: 5×5×1 (or larger)
Tags: [commercial, food, public, mega]
Traversability: PUBLIC (people route through)

Why special:
  - Placed between zones, captures through-traffic
  - Morning: residents walk through to offices, some stop for coffee
  - Lunch: destination traffic from offices
  - Evening: through-traffic going home, dinner stops

Traversal: Speed 0.9x, Cost modifier 0.95 (pleasant shortcut)
Entry points: All 4 sides recommended
```

### A.14 Transit & Corridor Blocks

**Corridor Types:**

| Corridor | Width×Height | Footprint | Capacity | Base Speed | Cost | Noise/Person |
|----------|--------------|-----------|----------|------------|------|--------------|
| Small | 1×1 | 1×1×1 | 20 | 1.0x | §50 | 0.8 |
| Medium | 2×1 | 2×1×1 | 50 | 1.0x | §100 | 0.5 |
| Large | 3×2 | 3×2×1 | 150 | 1.1x | §300 | 0.3 |
| Grand Promenade | 5×2 | 5×2×1 | 400 | 1.2x | §800 | 0.2 |

**Corridor Junction Types (all corridor sizes):**

| Junction | Connects | Sprite Needed |
|----------|----------|---------------|
| Straight H | Left-Right | Horizontal straight |
| Straight V | Up-Down | Vertical straight |
| Corner TL | Top-Left | ┏ |
| Corner TR | Top-Right | ┓ |
| Corner BL | Bottom-Left | ┗ |
| Corner BR | Bottom-Right | ┛ |
| T-Junction Top | Left-Right-Down | ┳ |
| T-Junction Bottom | Left-Right-Up | ┻ |
| T-Junction Left | Up-Down-Right | ┣ |
| T-Junction Right | Up-Down-Left | ┫ |
| 4-Way | All directions | ╋ |

**Corridor Aesthetic Upgrades:**

| Upgrade | Vibes | Air | Noise Mod | Cost | Notes |
|---------|-------|-----|-----------|------|-------|
| Basic Lighting | +5 | — | — | §100 | Required |
| Premium Lighting | +10 | — | — | §300 | Crime reduction |
| Planter Boxes | +8 | +5 | -5 | §200 | Small greenery |
| Living Wall | +15 | +15 | -10 | §500 | Vertical garden |
| Bench Seating | +5 | — | +5 | §150 | Rest stops |
| Water Feature | +12 | +5 | +10 | §400 | Fountain |
| Art Installation | +10 | — | — | §300 | Culture |
| Acoustic Panels | +3 | — | -20 | §250 | Sound dampening |
| Premium Flooring | +8 | — | -5 | §200 | Carpet/tile |
| Skylights | +15 | — | — | §400 | Natural light |
| Retail Kiosk | +5 | — | +10 | §500 | Small revenue |
| Vending Machines | +3 | — | +5 | §200 | Small revenue |

**Sound Generator Upgrades (Add Noise + Add Vibes):**

| Upgrade | Noise Added | Vibes Added | Cost |
|---------|-------------|-------------|------|
| Nature Sounds | +5 | +10 | §150 |
| Ambient Music | +8 | +8 | §200 |
| Fountain (active) | +10 | +15 | §400 |
| Street Performer Spot | +15 | +12 | §100 |

**Conveyor Transit:**

| Block | Orientation | Max Length | Speed | Capacity | Power | Tech |
|-------|-------------|------------|-------|----------|-------|------|
| Moving Walkway | Horizontal | 20 blocks | 2.0x | High | 2/block | 2 |
| Escalator | Diagonal (30-45°) | 5 blocks | 1.5x | High | 3/block | 2 |

**Elevator Types:**

| Block | Range | Speed | Capacity | Power | Precondition | Tech |
|-------|-------|-------|----------|-------|--------------|------|
| Stairs | ±3 floors | 0.5x | Low | 0 | None | 1 |
| Elevator (Local) | ±10 floors | 3.0x | Medium (10/car) | 10/floor | Pop 200 | 1 |
| Elevator (Express) | ±30 floors | 5.0x | High | 15/floor | Sky Lobby | 3 |
| Freight Elevator | Any | 2.0x | Freight only | 20/floor | Industrial | 2 |
| Pneuma-Tube | Any direction | 10.0x | 2 max | 50/station + 5/segment | Pop 20K | 4 |

### A.15 Utility Blocks

| Block | Size | Tags | Utility Capacity | Transit | Cost |
|-------|------|------|------------------|---------|------|
| Utility Chase | 1×1 | [utility] | Power: 100, Water: 50, Data: 50, Light: 1, Air: 1 | None | §150 |
| Utility Corridor | 1×1 | [utility, transit] | Power: 50, Water: 25, Data: 25, Light: 1, Air: 1 | Walk | §200 |

**Corridor Utility Upgrades (additive):**

| Upgrade | Capacity Added | Cost |
|---------|----------------|------|
| Power Conduit | +50 power | §100 |
| Water Main | +25 water | §150 |
| Light Pipe | +1 light channel | §200 |
| Air Duct | +1 air channel | §100 |
| Data Trunk | +25 data | §75 |

---

## Appendix B: Formulas Reference

### B.1 Airspace Permit Cost

```
permit_cost = BASE_PERMIT × HEIGHT_MULTIPLIER[floor]

HEIGHT_MULTIPLIER:
  Floors 1-10:   1.0x
  Floors 11-20:  1.5x
  Floors 21-30:  2.0x
  Floors 31-50:  3.0x
  Floors 51-75:  5.0x
  Floors 76-100: 8.0x
  Floors 100+:   12.0x
```

### B.2 Excavation Permit Cost

```
permit_cost = BASE_EXCAVATION × DEPTH_MULTIPLIER[floor]

DEPTH_MULTIPLIER:
  Floors -1 to -3:   1.0x
  Floors -4 to -6:   1.5x
  Floors -7 to -10:  2.5x
  Floors -11 to -20: 4.0x
  Floors -20+:       6.0x
```

### B.3 Subterranean Penalties

```
For floor Z (where Z < 0):

light_penalty = min(100, |Z| × 20)        // -20% per floor, max -100%
air_penalty = min(60, |Z| × 10)           // -10% per floor, max -60%
vibes_penalty = 15 + (|Z| × 10)           // Base -15, then -10 per floor
crime_bonus = 10 + (|Z| × 5)              // Base +10, then +5 per floor
```

### B.4 Residential Rent

```
base_rent = BLOCK_TYPE_BASE[type] × LEVEL_MULTIPLIER[level]

desirability = (
    sunlight × 0.20 +
    air_quality × 0.15 +
    quiet × 0.15 +
    safety × 0.15 +
    accessibility × 0.20 +
    vibes × 0.15
) / 100

rent = base_rent × desirability × demand_multiplier
```

### B.5 Commercial Revenue

```
revenue = base × level × (
    foot_traffic × 0.35 +
    accessibility × 0.20 +
    cluster_bonus × 0.15 +
    catchment_pop × 0.20 +
    vibes × 0.10
) × (1 - competition_penalty)
```

### B.6 Effective Light

```
natural_light_score = natural_light_level  // 0-100
artificial_light_score = artificial_light_level × 0.35
piped_light_score = piped_light_level × efficiency  // 0.6-0.8

effective_light = max(natural, piped, artificial)
```

### B.7 Vibes

```
vibes = (
    effective_light × 0.25 +
    effective_air × 0.20 +
    greenery_proximity × 0.15 +
    aesthetics × 0.10 +
    quiet × 0.15 +
    safety × 0.15
) - subterranean_vibes_penalty  // if Z < 0
```

### B.8 Population Change

```
births = pop × birth_rate × family_housing_ratio × happiness
deaths = pop × death_rate × (1 - healthcare_modifier)

immigration = pressure × vacancy × desirability × transit
emigration = pop × (1 - satisfaction) × pull × transit

net_change = (births - deaths) + (immigration - emigration)
```

### B.9 Corridor Capacity and Speed

```
saturation = current_traffic / base_capacity

Speed multiplier by saturation:
  0-50%:    1.0x (free flow)
  50-75%:   0.85x (crowded)
  75-90%:   0.6x (congested)
  90-100%:  0.4x (packed)
  >100%:    0.2x (gridlock)

effective_speed = base_speed × speed_multiplier(saturation)
```

### B.10 Corridor Noise

```
traffic_noise = current_traffic × NOISE_PER_PERSON[corridor_type]

NOISE_PER_PERSON:
  Small (1×1):       0.8
  Medium (2×1):      0.5
  Large (3×2):       0.3
  Grand Promenade:   0.2

effective_noise = traffic_noise + sound_generators - acoustic_mitigation
effective_noise = max(0, effective_noise)  // floor at 0
```

### B.11 Noise Propagation

```
Noise received by adjacent blocks:

immediate_neighbor = corridor_noise × 0.80
one_block_away = corridor_noise × 0.40
two_blocks_away = corridor_noise × 0.15

Wall reduction:
  Solid wall: × 0.50
  Glass wall: × 0.80
  Open/void:  × 1.00

received_noise = corridor_noise × distance_factor × wall_factor
```

### B.12 Pathfinding Edge Cost

```
edge_cost = (distance / effective_speed) × traversal_cost_modifier

Traversal cost modifiers (lower = preferred):
  Corridor (basic):     1.0
  Corridor (crowded):   1.3
  Atrium:              0.85
  Park/Garden:         0.9
  Food Hall:           0.95
  Industrial corridor: 1.3

Transit speed multipliers:
  Walking:              1.0x
  Stairs (up):          0.4x
  Stairs (down):        0.6x
  Conveyor (with):      2.0-2.5x
  Conveyor (against):   0.3x
  Elevator:             3.0-5.0x (plus wait time)
  Pneuma-Tube:          10.0x
```

### B.13 Force Field Power

```
force_field_power_draw = panels × 10 units

Failure thresholds:
  100-75% power: Normal operation
  75-50% power:  Flicker warning
  50-25% power:  Weakening, air leak risk
  <25% power:    Collapse, decompression
```

### B.14 Flourishing Calculation

```
def calculate_flourishing(needs):
    # Maslow hierarchy: lower needs gate higher ones
    
    if needs.survival < 50:
        return needs.survival × 0.3  # 0-15 range
    
    if needs.safety < 40:
        return 30 + (needs.safety - 40) × 0.5  # 15-30 range
    
    if needs.belonging < 30:
        return 50 + (needs.belonging - 30) × 0.5  # 30-50 range
    
    if needs.esteem < 30:
        return 60 + (needs.esteem - 30) × 0.4  # 50-60 range
    
    # All base needs met—purpose drives flourishing
    base = 70
    purpose_bonus = (needs.purpose - 50) × 0.6  # up to +30
    
    # Harmony bonus for all needs being high
    minimum_need = min(all_needs)
    harmony_bonus = max(0, (minimum_need - 70)) × 0.3  # up to +9
    
    return min(100, base + purpose_bonus + harmony_bonus)
```

### B.15 Flight Risk

```
flight_risk = base_risk + dissatisfaction + opportunity - attachment

base_risk = ARCHETYPE_BASE[archetype]  // 5-20 depending on type

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

// Clamp to 0-100
flight_risk = clamp(flight_risk, 0, 100)

Thresholds:
  < 30: Stable, unlikely to leave
  30-50: Watchlist, may leave if things worsen
  50-70: At risk, actively considering alternatives
  > 70: High risk, will leave without intervention
```

### B.16 Community Cohesion

```
cohesion = (
    average_relationship_strength × 0.25 +
    relationship_density × 0.20 +      // connections per person
    cross_group_bridges × 0.20 +       // links between different areas/groups
    inverse_conflict_rate × 0.15 +
    inverse_turnover_rate × 0.20
) × 100

Decay sources (monthly):
  Turnover: -2 per 10% annual turnover rate
  Isolated residents: -1 per 100 isolated people
  Active conflicts: -5 per unresolved conflict
  Inequality (Gini > 0.4): -3
  Scale without structure: -2 per 10k without districts
  Natural decay: -1 baseline

Growth sources (monthly):
  Community events: +2 to +10 depending on attendance
  Conflict resolution: +3 per resolved
  New friendship formation: +0.5 per new friendship
  Cross-group activities: +2 per event
```

### B.17 Arcology Eudaimonia Index (AEI)

```
AEI = (
    individual × 0.40 +
    community × 0.25 +
    sustainability × 0.20 +
    resilience × 0.15
)

individual = (
    mean(all_flourishing) - 
    stdev(all_flourishing) × 0.3  // penalize inequality
)

community = cohesion_score

sustainability = 100 - (
    maintenance_debt_ratio × 30 +      // debt / structure value
    budget_deficit_months × 10 +       // months in deficit
    environmental_damage × 20 +
    knowledge_loss_index × 10
)

resilience = (
    backup_systems_coverage × 0.25 +   // % of critical systems with backup
    financial_reserves_months × 0.25 + // months of reserves
    mutual_aid_score × 0.25 +          // community self-help capacity
    economic_diversity × 0.25          // inverse concentration
) × 100
```

### B.18 Elevator Wait Time

```
base_wait = f(
    floor_demand[floor],
    elevator_capacity,
    num_cars,
    dispatch_algorithm
)

perceived_wait = base_wait × perception_multipliers

Perception multipliers (multiplicative):
  No indicator:           × 1.5
  Watching full cars:     × 1.3
  Running late:           × 1.4
  Uncomfortable lobby:    × 1.25
  Alone:                  × 1.2
  
  Countdown display:      × 0.7
  Pleasant lobby:         × 0.8
  Friend present:         × 0.75
  Distraction (art):      × 0.85
  Mirrors:                × 0.9

frustration_delta = (perceived_wait - tolerance) × neuroticism / 100
tolerance = base_tolerance × time_of_day_modifier × urgency_modifier
```

### B.19 Relationship Dynamics

```
FORMATION:
  acquaintance_chance = base_chance × compatibility × frequency
  
  base_chance:
    Neighbors: 0.30/month
    Coworkers: 0.50/month
    Elevator encounter: 0.02/ride
    Shared event: 0.15/event
  
  compatibility = (
    similar_age × 0.2 +
    similar_archetype × 0.15 +
    complementary_traits × 0.3 +
    shared_schedule × 0.2 +
    random × 0.15
  )

MAINTENANCE:
  No interaction 30 days: -10 strength
  No interaction 90 days: -30 strength
  Positive interaction: +3 to +5
  Shared meal: +3
  Helped in crisis: +20
  Conflict: -10 to -50
  
DISSOLUTION:
  strength < 20: relationship ends
  friendship → acquaintance if strength < 40
```

---

## Appendix C: Glossary

| Term | Definition |
|------|------------|
| **Above Grade** | Floors above the ground plane (Z > 0); requires airspace permits |
| **AEI (Arcology Eudaimonia Index)** | The primary success metric combining flourishing, community, sustainability, and resilience |
| **Agent** | An individual simulated resident with needs, personality, relationships, and daily schedule |
| **Airspace Permit** | Permission to build at a specific height; cost escalates with elevation |
| **Archetype** | Category of resident (Young Professional, Family, Retiree, Artist, Entrepreneur) affecting needs and behavior |
| **Arcology** | A self-contained megastructure combining architecture and ecology |
| **Attachment** | Factors keeping a resident in the arcology (friends, family, tenure, community involvement) |
| **Below Grade** | Floors below the ground plane (Z < 0); requires excavation permits |
| **Belonging** | Human need for relationships, community, love, and acceptance |
| **Block** | The atomic unit of construction in the game |
| **Cohesion** | Community-wide measure of social connectivity and trust (0-100) |
| **Commuter-In** | Person who lives outside but works inside the arcology |
| **Commuter-Out** | Person who lives inside but works outside the arcology |
| **Complaint** | Formal resident feedback about unmet needs or problems |
| **Conveyor** | Moving walkway (horizontal) or escalator (diagonal) transit |
| **Corner Block** | Junction block connecting corridors at 90° angles |
| **Corridor** | Transit block for foot traffic; comes in Small, Medium, Large, Grand Promenade sizes |
| **Destination Dispatch** | Advanced elevator algorithm grouping passengers by destination floor |
| **Envelope** | The outer boundary/shell; auto-generated from block panels facing outside |
| **Entropy** | The tendency of all systems (physical, social, economic) to decay without maintenance |
| **Esteem** | Human need for respect, recognition, status, and achievement |
| **Eudaimonia** | Human flourishing; the state of living well and fulfilling one's potential |
| **Excavation Permit** | Permission to dig to a specific depth; cost escalates with depth |
| **Flight Risk** | Probability (0-100) that a resident will leave the arcology |
| **Flourishing** | Computed score (0-100) measuring how well a resident's needs are met |
| **Food Hall** | Mega-block public food court; traversable, captures through-traffic |
| **Force Field** | Panel type for Mars/Space allowing light and access while maintaining seal |
| **Grand Promenade** | Largest corridor type (5×2); 400 capacity, flagship public space |
| **Ground Plane** | The Z=0 level where external connections exist |
| **Human Nature** | Built-in behavioral tendencies (NIMBYism, tribalism, short-term thinking) that challenge community |
| **Isolation Score** | Measure of self-sufficiency vs external connection (0-100) |
| **Junction Block** | Corridor block handling turns and intersections (corners, T, 4-way) |
| **Light Pipe** | Infrastructure that routes harvested sunlight into interior |
| **Mega-Block** | Large special-purpose structure (5×5+ footprint) |
| **Needs** | Five psychological requirements (Survival, Safety, Belonging, Esteem, Purpose) |
| **NIMBYism** | "Not In My Back Yard" - resident opposition to nearby undesirable development |
| **Notable Resident** | One of 100-500 fully-simulated residents with detailed stories surfaced to player |
| **Panel** | Auto-generated exterior surface on block faces; material affects light/air/sound |
| **Pathfinding Cost** | Calculated route preference based on distance, speed, and pleasantness |
| **Perceived Wait** | Psychological experience of waiting, modified by environment and personality |
| **Piped Light** | Natural light distributed through fiber optic infrastructure |
| **Pneuma-Tube** | Late-game transit; any direction, 2 capacity, 10x speed |
| **Private Block** | Destination-only block; pathfinding routes TO/FROM, not THROUGH |
| **Public Block** | Traversable block; pathfinding can route THROUGH (e.g., Food Hall, Atrium) |
| **Purpose** | Human need for meaning, growth, contribution, and self-actualization |
| **Rectilinear** | 90° angles only; no diagonal blocks except escalators and pneuma-tubes |
| **Relationship** | Connection between two residents with type, strength, and history |
| **Resilience** | Arcology's ability to survive and recover from shocks |
| **Safety** | Human need for physical security, stability, and predictability |
| **Saturation** | Corridor traffic as percentage of capacity; affects speed |
| **Sky Lobby** | Transit transfer point enabling express elevator service |
| **Sound Generator** | Corridor upgrade adding noise but also vibes (music, nature sounds) |
| **Subterranean** | Below ground level; suffers light, air, and vibes penalties |
| **Survival** | Human need for food, water, shelter, health, and physical comfort |
| **Sustainability** | Long-term viability considering maintenance, finances, and environment |
| **Tech Level** | Progression tier that unlocks advanced buildings |
| **Tragedy of the Commons** | Degradation of shared resources when individuals act selfishly |
| **Traversability** | Whether a block is public (route through) or private (destination only) |
| **Tribalism** | Formation of in-groups and out-groups leading to conflict |
| **Utility Chase** | Pipe-only block for high-capacity utility distribution |
| **Utility Corridor** | Corridor with added utility capacity (power, water, light pipes, air ducts) |
| **Vibes** | Composite quality-of-life / desirability score |
| **Zoning** | Designating areas for automatic tenant filling |

---

*End of Document*
