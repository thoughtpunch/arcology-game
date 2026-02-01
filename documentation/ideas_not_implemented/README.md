# Ideas Not Implemented

This folder contains design documents and technical plans for features that are being considered but have not yet been implemented.

## Purpose

- **Capture ideas** before they're forgotten
- **Plan big changes** before committing code
- **Enable review** and discussion of major architectural decisions
- **Track deferred features** for future consideration

## Documents

| Document | Description | Status |
|----------|-------------|--------|
| [scenario-config.md](./scenario-config.md) | Scenario/map config system: gravity, day cycle, structural rules, custom game mode | Idea |
| [building-limits.md](./building-limits.md) | Building height/volume tracking, infrastructure capacity limits (HVAC, power, water, elevators) | Idea |
| [phase0-block-stacking-foundation.md](./phase0-block-stacking-foundation.md) | Phase 0 block stacking sandbox design | **Implemented** — See [milestones/phase-0-sandbox.md](../architecture/milestones/phase-0-sandbox.md) |

## Workflow

1. **Create document** with problem statement, requirements, technical plan
2. **Review** with stakeholders (or self-review)
3. **Decide:** Approve → Create BEADS epic, or Reject → Archive with rationale
4. **Implement** following the plan
5. **Move document** to `documentation/architecture/` when complete

## Template

When adding a new idea document:

```markdown
# Feature Name

> **Status:** Idea / Under Review / Approved / Rejected / Implemented
> **Created:** YYYY-MM-DD
> **Related BEADS:** (if any)

## Executive Summary
One paragraph describing what and why.

## Problem Statement
What's wrong with the current state?

## Product Requirements
What should it do? User-facing behavior.

## Technical Plan
How will it be built? Architecture, components, migrations.

## Migration Plan (if applicable)
Phased approach to implementation.

## Risks & Mitigations
What could go wrong?

## Open Questions
What needs to be decided?

## Next Steps
What happens after this document is reviewed?
```
