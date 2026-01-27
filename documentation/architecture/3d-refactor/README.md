# 3D Refactor Architecture

This directory contains the technical specification and architecture for the 3D rendering migration.

## Documents

- **[specification.md](./specification.md)** - Complete 3D refactor specification
  - The Cube (6m x 6m x 3.5m foundational unit)
  - Coordinate system (Y-up)
  - Camera system (free orbital + ortho snap)
  - Block rendering (meshes, LOD, chunks)
  - Visibility modes (cutaway, x-ray, floor isolate)
  - Placement system (face-snap, Minecraft-style)
  - Terrain and excavation
  - Performance targets

## Beads Epics

| Epic | ID | Description |
|------|-----|-------------|
| Main | arcology-do0 | Epic: 3D Refactor - Convert Arcology to Full 3D Rendering |
| Phase 0 | arcology-8s9 | Spike - Proof of Concept |
| Phase 1 | arcology-wb0 | Core 3D Scene Architecture |
| Phase 2 | arcology-fmy | 3D Camera System |
| Phase 3 | arcology-3yo | 3D Block Rendering System |
| Phase 4 | arcology-0r1 | 3D Input & Placement System |
| Phase 5 | arcology-9qx | Visibility Modes |
| Phase 6 | arcology-ivi | 3D Terrain System |
| Phase 7 | arcology-8fu | 3D Asset Pipeline |
| Phase 8 | arcology-dvi | Migration & Cleanup |

## Phase Dependencies

```
Phase 0 (Spike)
    ↓
Phase 1 (Scene)
    ↓
    ├── Phase 2 (Camera)
    │       ↓
    │   Phase 4 (Input) ←─┐
    │                     │
    ├── Phase 3 (Rendering)
    │       ↓             │
    │   Phase 5 (Visibility)
    │       ↓
    │   Phase 7 (Assets)
    │
    └── Phase 6 (Terrain)
            ↓
        Phase 8 (Migration)
```

## Quick Links

- Run `bd list --label 3d-refactor` to see all related tickets
- Run `bd ready` to see what's ready to work on
- See [specification.md](./specification.md) for full technical details
