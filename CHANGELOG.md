# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-04

### Added
- **12 command types:** createPart, createWedge, createCylinder, createSphere, createSurface, createGroup, addLight, setTerrain, markUnfinished, deletePart, movePart, executeBatch
- **Batch execution** with deferred animation and progress callbacks
- **Flexible input format** — `{ type, params = {} }` envelopes or flat `{ type, name, position, ... }` commands
- **Rich property parsing** — hex colors (`#RRGGBB`), `{r,g,b}` tables, material name strings, degree-based rotation
- **CollectionService tagging** — all built parts tagged `BuilderKitBuilt` for external discovery
- **Optional BuildAnimator integration** — if present as sibling, batch builds get cinematic reveals
- **Workspace container** — all instances under `workspace.BuilderKitBuilds`
- **Terrain support** — FillBlock with 20+ material types, plus clear/air mode
- **markUnfinished** — visual highlight system with SelectionBox and ParticleEmitter
- Engineering manual and user guide
- Two example scripts: house builder, castle generator
- MIT license
