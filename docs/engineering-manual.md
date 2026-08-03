# BuilderKit Engineering Manual

*Architecture, design decisions, and internals for contributors and advanced users.*

---

## Overview

BuilderKit is a **command executor** for Roblox building. It accepts structured command tables — dictionaries with a `type` field and parameters — and translates them into Roblox instances in the workspace.

The module is a single Lua file (`src/BuilderKit.lua`, ~500 lines) with **zero hard dependencies**. It is designed to be:

1. **Self-contained** — no external modules required to operate
2. **Extensible** — new command types are added by registering a handler in `commandMap`
3. **Animation-aware** — batch execution hooks into an optional `BuildAnimator` for cinematic reveals
4. **Externally discoverable** — all parts are CollectionService-tagged

---

## Architecture

### Module Structure

```
BuilderKit (ModuleScript)
├── Configuration constants (BUILT_TAG, FOLDER_NAME, TERRAIN_MATERIALS)
├── Optional dependency resolution (BuildAnimator)
├── Internal helpers
│   ├── ensureFolder() — lazy-create workspace container
│   ├── findPartByName() — search folder then workspace
│   ├── parseVector3() — {x,y,z} or {[1],[2],[3]} → Vector3
│   ├── parseColor() — hex string | RGB table | Color3 → Color3
│   ├── parseMaterial() — string → Enum.Material
│   └── prepareBasePart() — apply common properties + batch tracking
├── Command implementations (createPart, createWedge, ...)
├── Command dispatcher (commandMap + execute)
├── Batch executor (executeBatch)
└── Utility functions (getFolder, getBuiltParts, clearAll)
```

### Data Flow

```
Command Table → execute() → commandMap[type] → handler(params) → Instance
                     ↓
              (batch mode?) → collect for deferred animation
                     ↓
              BuildAnimator.animateBatch() [if available]
```

---

## Command Dispatch Pattern

The core design is a **dispatch table** — a dictionary mapping command type strings to handler functions:

```lua
local commandMap = {
    createPart     = BuilderKit.createPart,
    createWedge    = BuilderKit.createWedge,
    createCylinder = BuilderKit.createCylinder,
    -- ...
}
```

The `execute()` function:

1. Validates the command is a table with a `type` field
2. Looks up the handler in `commandMap`
3. Extracts `params` (supports both `{ type, params = {} }` and flat `{ type, name, ... }`)
4. Wraps the handler call in `pcall` for error isolation
5. If not in batch mode and the result is a BasePart, triggers single-part animation

### Adding New Commands

To register a new command type:

```lua
function BuilderKit.createTruss(params)
    local folder = ensureFolder()
    local part = Instance.new("TrussPart")
    prepareBasePart(part, params)
    part.Parent = folder
    return part
end

commandMap.createTruss = BuilderKit.createTruss
```

The command is immediately available via `execute({ type = "createTruss", ... })`.

---

## Property Parsing

### Color Parsing

BuilderKit supports three input formats for maximum flexibility:

| Input | Parsing | Example |
|-------|---------|---------|
| Hex string | Strip `#`, parse 2-char substrings as hex → `Color3.fromRGB` | `"#FF5733"` |
| RGB table | Read `[1]`/`r`, `[2]`/`g`, `[3]`/`b` → `Color3.fromRGB` | `{ 255, 87, 51 }` |
| Color3 | Pass-through | `Color3.fromRGB(255, 87, 51)` |

Fallback: `Color3.fromRGB(180, 180, 180)` (neutral gray).

### Material Parsing

Uses `pcall(Enum.Material[name])` for safe lookup. Invalid names fall back to `SmoothPlastic`.

### Terrain Material Validation

Terrain materials are validated against a whitelist (`TERRAIN_MATERIALS`) because `Enum.Material` contains many entries that are not valid terrain materials. Invalid terrain materials default to `Grass` with a warning.

---

## Batch Execution

### How It Works

1. `executeBatch()` sets `inBatchMode = true`
2. All `createPart`/`createWedge`/`createCylinder`/`createSphere` calls during batch mode:
   - Create the part normally
   - Set initial state to invisible (`Transparency = 1`) and tiny (`Size = 0.1, 0.1, 0.1`)
   - Store target size/transparency in attributes (`BA_TargetSizeX`, etc.)
   - Append to `batchCreatedParts` list
3. After all commands execute, `inBatchMode = false`
4. If `BuildAnimator` exists: call `animateBatch(batchCreatedParts, ..., style)`
5. If no animator: restore target size/transparency from stored attributes
6. Clear the tracking list

### Throttling

Every 3 commands, `task.wait(0.03)` yields to prevent main thread blocking on large batches. This creates a subtle "construction" pacing even without animation.

### Progress Callbacks

```lua
BuilderKit.executeBatch(commands, function(current, total, result)
    -- Update UI, fire network events, etc.
end)
```

The callback is `task.spawn`'d so it never blocks execution.

---

## Container Management

All BuilderKit instances live under `workspace.BuilderKitBuilds` (a `Folder`). This ensures:

- **Clean workspace** — non-BuilderKit instances are untouched
- **Easy cleanup** — `clearAll()` empties the folder
- **Scoped search** — `findPartByName` checks the folder first for performance

The folder is lazily created on first use via `ensureFolder()`.

---

## CollectionService Integration

BuilderKit tags instances for external system discovery:

| Tag | Scope | Purpose |
|-----|-------|---------|
| `BuilderKitBuilt` | All BaseParts | Weather, damage, interaction systems |
| `BuilderKitUnfinished` | markUnfinished targets | Highlight deliberate gaps |

External systems query:
```lua
local builtParts = CollectionService:GetTagged("BuilderKitBuilt")
```

---

## BuildAnimator Integration (Optional)

BuilderKit checks for a sibling ModuleScript named `BuildAnimator` at require time:

```lua
local ok, mod = pcall(function()
    return require(script.Parent:FindFirstChild("BuildAnimator"))
end)
if ok then BuildAnimator = mod end
```

If found, two integration points are used:

1. **Single parts** (non-batch): `BuildAnimator.animatePart(part)` after `execute()`
2. **Batch parts**: `BuildAnimator.animateBatch(parts, nil, nil, nil, style)` after `executeBatch()`

If `BuildAnimator` is not present, batch-mode parts are restored to target size/transparency directly. The module is fully functional without it.

### Expected BuildAnimator API

```lua
BuildAnimator.animatePart(part: BasePart) -- Animate a single part
BuildAnimator.animateBatch(parts: { BasePart }, _, _, _, style: string?) -- Staggered batch reveal
```

---

## Marking Unfinished Parts

The `markUnfinished` command is a unique BuilderKit feature: it deliberately highlights one part as "unfinished" for the player to complete. This creates engagement and interactivity.

Behavior:
1. Collect candidate parts (from `partName`, `partsList`, or all descendants of the folder)
2. Prefer parts not already marked
3. Pick randomly from candidates
4. Apply visual treatment: `Transparency = 0.5`, SelectionBox highlight, sparkle ParticleEmitter
5. Tag with `BuilderKitUnfinished` and set `BuilderKit_Unfinished` attribute

---

## Attribute Schema

BuilderKit sets the following attributes on created parts:

| Attribute | Type | Description |
|-----------|------|-------------|
| `BuildMaterial` | string | Material name used at creation |
| `BuildTimestamp` | number | `os.time()` at creation |
| `BuilderKit_Unfinished` | boolean | Set by markUnfinished |
| `BuilderKit_OriginalTransparency` | number | Pre-mark transparency |
| `BA_TargetSizeX/Y/Z` | number | Batch animation target (batch mode only) |
| `BA_TargetTransparency` | number | Batch animation target (batch mode only) |

---

## Thread Safety

BuilderKit is designed for **server-side** execution. All Roblox APIs used (Instance.new, CFrame, Terrain:FillBlock, etc.) are server-safe. The module:

- Uses `pcall` around all command handlers
- Uses `task.spawn` for progress callbacks
- Uses `task.wait` for throttling (yields properly)
- Does not use `shared` or `_G`

---

## Performance Notes

- **`partsCreated` counter**: O(1) increment on each create, O(1) decrement on delete. No full-tree recount.
- **Folder search**: `findPartByName` checks the BuilderKit folder first (`FindFirstChild`, O(children)) before falling back to recursive workspace search.
- **Batch throttling**: `task.wait(0.03)` every 3 commands. For a 100-part batch, this adds ~1s of spread — intentional for animation pacing.
- **Terrain:FillBlock**: CFrame-based, no grid alignment needed. Efficient for large fills.

---

## Extending BuilderKit

### Custom Commands

```lua
-- Register a new command
function BuilderKit.spawnTree(params)
    local part = BuilderKit.createPart({
        name = params.name or "Tree",
        position = params.position,
        size = { x = 2, y = 10, z = 2 },
        material = "Wood",
        color = "#228B22",
    })
    -- Add foliage sphere
    BuilderKit.createSphere({
        name = (params.name or "Tree") .. "_Foliage",
        position = { x = params.position.x, y = (params.position.y or 0) + 8, z = params.position.z },
        size = { x = 8, y = 8, z = 8 },
        material = "Grass",
        color = "#2E8B57",
    })
    return part
end

commandMap.spawnTree = BuilderKit.spawnTree
```

### Custom Animators

Create a `BuildAnimator` ModuleScript as a sibling of `BuilderKit`. Implement `animatePart()` and `animateBatch()` with your custom tween/particle/sound logic. BuilderKit will automatically detect and use it.

---

## Design Decisions

### Why a command table, not a builder DSL?

Command tables are:
- **Serializable** — can be sent over HTTP, stored in JSON, generated by AI
- **Inspectable** — you can log, validate, and modify before execution
- **Batchable** — arrays of commands execute cleanly in sequence
- **Language-agnostic** — any system that produces Lua tables can drive builds

### Why no loadstring?

`loadstring` requires `ServerScriptService.LoadStringEnabled` which is off by default and a security risk. BuilderKit deliberately does not execute arbitrary code strings. The `addScript` command from the original Lucineer source was removed for this reason — Script.Source is only assignable in Studio.

### Why FillBlock instead of FillRegion?

`FillRegion` is deprecated. `FillBlock` takes a CFrame and Vector3, requiring no grid alignment. It is the modern, supported terrain API.
