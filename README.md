# BuilderKit

**A standalone Roblox building command executor for procedural and AI-driven construction.**

BuilderKit takes structured command tables and turns them into Roblox instances — parts, wedges, cylinders, spheres, terrain, lights, and groups. It is designed for AI agents, procedural generators, and any system that needs to build structures programmatically without writing ad-hoc Instance management code.

---

## Features

- **12 command types** — createPart, createWedge, createCylinder, createSphere, createSurface, createGroup, addLight, setTerrain, markUnfinished, deletePart, movePart, executeBatch
- **Batch execution** with deferred animation and progress callbacks
- **Flexible input format** — accept `{ type, params = {} }` envelopes or flat `{ type, name, position, ... }` commands
- **Rich property parsing** — hex colors, `{r,g,b}` tables, material name strings, degree-based rotation
- **CollectionService tagging** — all built parts are tagged for external system discovery (weather, damage, interaction)
- **Optional BuildAnimator integration** — if a BuildAnimator sibling module exists, batch builds get staggered cinematic reveals with no code changes
- **Zero hard dependencies** — works standalone, no external modules required
- **Clean container management** — all instances live under a single `workspace.BuilderKitBuilds` folder

---

## Installation

### With Rojo

1. Clone this repo into your project:
   ```bash
   git clone https://github.com/your-org/roblox-builder-kit.git
   ```
2. Copy or symlink `src/BuilderKit.lua` into your Rojo project's `ReplicatedStorage`.
3. Add to your `default.project.json`:
   ```json
   {
     "ReplicatedStorage": {
       "BuilderKit": { "$path": "roblox-builder-kit/src/BuilderKit.lua" }
     }
   }
   ```

### Manual

1. Download `src/BuilderKit.lua`.
2. In Roblox Studio, create a `ModuleScript` in `ReplicatedStorage`.
3. Name it `BuilderKit` and paste the contents.

---

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

-- Build a single part
BuilderKit.execute({
    type = "createPart",
    params = {
        name = "Floor",
        position = { x = 0, y = 0, z = 0 },
        size = { x = 20, y = 1, z = 20 },
        material = "WoodPlanks",
        color = "#8B4513"
    }
})

-- Build a batch of parts
BuilderKit.executeBatch({
    { type = "createPart", params = { name = "Wall1", position = { x = -10, y = 3, z = 0 }, size = { x = 1, y = 6, z = 20 }, material = "Brick", color = "#C0392B" } },
    { type = "createPart", params = { name = "Wall2", position = { x = 10, y = 3, z = 0 }, size = { x = 1, y = 6, z = 20 }, material = "Brick", color = "#C0392B" } },
    { type = "createPart", params = { name = "Roof",   position = { x = 0, y = 6.5, z = 0 }, size = { x = 22, y = 1, z = 22 }, material = "WoodPlanks", color = "#2C3E50" } },
})
```

---

## Full API Reference

### Core Functions

#### `BuilderKit.execute(command)`
Execute a single command.

- **command** `{ type: string, params?: table }` — The command to execute. If `params` is omitted, the command table itself is used as params.
- **Returns:** `result, errorString?`

```lua
local part, err = BuilderKit.execute({
    type = "createPart",
    params = { name = "Pillar", position = { x = 5, y = 10, z = 5 } }
})
```

#### `BuilderKit.executeBatch(commands, onProgress?, style?)`
Execute multiple commands sequentially with deferred animation.

- **commands** `{ table }` — Array of command tables.
- **onProgress** `function(current, total, result)?` — Optional progress callback.
- **style** `string?` — Optional animation style for BuildAnimator.
- **Returns:** `{ { index, type, success, result, error } }`

```lua
local results = BuilderKit.executeBatch(commands, function(current, total, result)
    print(string.format("Building... %d/%d", current, total))
end)
```

### Command Types

#### createPart

Create a new `Part` in the workspace.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | `"BuilderKitPart"` | Instance name |
| `position` | `{x,y,z}` | `{0,5,0}` | World position |
| `size` | `{x,y,z}` | `{4,1,4}` | Part dimensions |
| `material` | string | `"SmoothPlastic"` | Enum.Material name |
| `color` | string / table | gray | Hex `"#RRGGBB"` or `{r,g,b}` (0-255) |
| `shape` | string | — | `"Block"`, `"Ball"`, `"Cylinder"` |
| `anchored` | bool | `true` | Physics anchored state |
| `transparency` | number | `0` | 0–1 opacity |
| `rotation` | `{x,y,z}` | — | Rotation in degrees |
| `canCollide` | bool | `true` | Collision enabled |
| `reflectance` | number | `0` | 0–1 reflectance |

#### createWedge

Create a `WedgePart` for ramps and roofs. Same parameters as createPart (no `shape`).

#### createCylinder

Create a cylinder-shaped Part. Same parameters as createPart.

#### createSphere

Create a ball-shaped Part. Same parameters as createPart.

#### createSurface

Apply material/color/texture to an existing part.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Target part name |
| `material` | string | New material name |
| `color` | any | New color |
| `transparency` | number | New transparency |
| `texture` | string | Optional `rbxassetid://` Decal texture |
| `face` | string | Decal face: Front, Back, Top, Bottom, Left, Right |
| `decalName` | string | Name for the Decal instance |
| `decalColor` | any | Decal color |
| `decalTransparency` | number | Decal transparency |

#### createGroup

Parent existing parts under a Model.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Model name |
| `partNames` | `{string}` | Array of part names to include |

#### addLight

Add a PointLight, SpotLight, or SurfaceLight.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | `"BuilderKitLight"` | Instance name |
| `type` | string | `"Point"` | `"Point"`, `"Spot"`, `"Surface"` |
| `position` | `{x,y,z}` | — | If set, creates invisible carrier part |
| `range` | number | `16` | Range in studs |
| `brightness` | number | `2` | Brightness |
| `color` | any | white | Light color |
| `parent` | string | — | Existing part name to attach to |

#### setTerrain

Fill or clear terrain.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `position` | `{x,y,z}` | `{0,0,0}` | Center of fill |
| `size` | `{x,y,z}` | `{16,1,16}` | Fill dimensions |
| `material` | string | `"Grass"` | Terrain material (validated) |
| `action` | string | `"fill"` | `"fill"` or `"clear"` |

#### markUnfinished

Highlight a part as a deliberate gap. Sets semi-transparency, adds a SelectionBox and sparkle particles.

| Parameter | Type | Description |
|-----------|------|-------------|
| `partName` | string | Specific part to mark (optional) |
| `partsList` | `{BasePart}` | Parts to choose from (optional) |

Returns `{ message, partName }` or nil.

#### deletePart

Delete a part by name. Returns boolean.

#### movePart

Move a part to a new position. Returns boolean.

### Utility Functions

#### `BuilderKit.getFolder()`
Returns the `workspace.BuilderKitBuilds` folder.

#### `BuilderKit.getBuiltParts()`
Returns all parts tagged with `BuilderKitBuilt`.

#### `BuilderKit.clearAll()`
Destroys all instances in the BuilderKit folder and resets the counter.

---

## Color Parsing

BuilderKit accepts colors in three formats:

```lua
-- Hex string (preferred)
color = "#FF5733"

-- RGB table (0-255)
color = { 255, 87, 51 }
color = { r = 255, g = 87, b = 51 }

-- Roblox Color3 (pass-through)
color = Color3.fromRGB(255, 87, 51)
```

## Material Parsing

Materials are specified by their Roblox Enum name:

```lua
material = "SmoothPlastic"
material = "WoodPlanks"
material = "Neon"
material = "Ice"
```

Invalid material names fall back to `SmoothPlastic`.

## Rotation

Rotation is specified in degrees and applied as `CFrame.Angles`:

```lua
rotation = { x = 0, y = 45, z = 0 }  -- Rotate 45° on Y axis
```

---

## Animation Integration

BuilderKit has **optional** integration with a `BuildAnimator` module. If a sibling ModuleScript named `BuildAnimator` exists, batch builds automatically get:

- Staggered fade-in and scale-up with Back easing
- Particle burst effects per part
- Material-aware sound on landing

**Without BuildAnimator:** Parts appear immediately at full size. No errors, no dependency.

To add animation to your project, create a `BuildAnimator` ModuleScript next to `BuilderKit` with at minimum:

```lua
local BuildAnimator = {}

function BuildAnimator.animatePart(part)
    -- Your single-part animation logic
end

function BuildAnimator.animateBatch(parts, _, _, _, style)
    -- Your batch animation logic
end

return BuildAnimator
```

---

## Worked Examples

### Example 1: Build a House from JSON Spec

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

local houseSpec = {
    { type = "createPart", params = { name = "Floor",   position = { x = 0, y = 0, z = 0 },  size = { x = 12, y = 1, z = 10 }, material = "WoodPlanks", color = "#8B5E3C" } },
    { type = "createPart", params = { name = "WallN",   position = { x = 0, y = 4, z = -5 }, size = { x = 12, y = 8, z = 1 },  material = "Brick",      color = "#A0522D" } },
    { type = "createPart", params = { name = "WallS",   position = { x = 0, y = 4, z = 5 },  size = { x = 12, y = 8, z = 1 },  material = "Brick",      color = "#A0522D" } },
    { type = "createPart", params = { name = "WallW",   position = { x = -6, y = 4, z = 0 }, size = { x = 1, y = 8, z = 10 }, material = "Brick",      color = "#A0522D" } },
    { type = "createPart", params = { name = "WallE",   position = { x = 6, y = 4, z = 0 },  size = { x = 1, y = 8, z = 10 }, material = "Brick",      color = "#A0522D" } },
    { type = "createWedge", params = { name = "RoofL",  position = { x = -3, y = 9, z = 0 }, size = { x = 8, y = 4, z = 12 }, material = "WoodPlanks", color = "#4A3520", rotation = { x = 0, y = 0, z = 45 } } },
    { type = "createWedge", params = { name = "RoofR",  position = { x = 3, y = 9, z = 0 },  size = { x = 8, y = 4, z = 12 }, material = "WoodPlanks", color = "#4A3520", rotation = { x = 0, y = 0, z = -45 } } },
    { type = "addLight",   params = { name = "CeilingLight", type = "Point", position = { x = 0, y = 7, z = 0 }, range = 20, brightness = 3, color = "#FFE4B5" } },
}

BuilderKit.executeBatch(houseSpec, function(current, total)
    print(string.format("House progress: %d/%d", current, total))
end)
```

### Example 2: Procedural Tower Generator

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

local function buildTower(x, z, floors, floorHeight, radius)
    local commands = {}
    local palette = { "#3498DB", "#E74C3C", "#2ECC71", "#F39C12", "#9B59B6" }

    for floor = 1, floors do
        local y = (floor - 1) * floorHeight + floorHeight / 2
        local color = palette[(floor - 1) % #palette + 1]

        table.insert(commands, {
            type = "createCylinder",
            params = {
                name = string.format("Tower_%d_F%d", x, floor),
                position = { x = x, y = y, z = z },
                size = { x = radius * 2, y = floorHeight, z = radius * 2 },
                material = "SmoothPlastic",
                color = color,
            }
        })
    end

    -- Spire on top
    table.insert(commands, {
        type = "createPart",
        params = {
            name = string.format("Tower_%d_Spire", x),
            position = { x = x, y = floors * floorHeight + 4, z = z },
            size = { x = 1, y = 8, z = 1 },
            material = "Neon",
            color = "#FFFF00",
        }
    })

    return commands
end

-- Build three towers of varying heights
local allCommands = {}
for _, spec in ipairs({ { x = 0, z = 0, floors = 5 }, { x = 30, z = 10, floors = 8 }, { x = -25, z = 15, floors = 3 } }) do
    for _, cmd in ipairs(buildTower(spec.x, spec.z, spec.floors, 4, 6)) do
        table.insert(allCommands, cmd)
    end
end

BuilderKit.executeBatch(allCommands)
```

### Example 3: Staggered Construction Animation

```lua
-- Requires BuildAnimator sibling module for full effect.
-- Without it, parts still appear correctly but without animation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

local function buildWithAnimation()
    local commands = {}

    -- Build a staircase
    for i = 1, 20 do
        table.insert(commands, {
            type = "createPart",
            params = {
                name = "Step" .. i,
                position = { x = i * 2, y = i, z = 0 },
                size = { x = 4, y = 1, z = 4 },
                material = "Slate",
                color = "#7F8C8D",
            }
        })
    end

    -- Execute with progress tracking
    BuilderKit.executeBatch(commands, function(current, total)
        if current % 5 == 0 then
            print(string.format("🏗️ Building staircase: %d/%d steps", current, total))
        end
    end, "cascade")

    print("✅ Staircase complete!")
end

buildWithAnimation()
```

### Example 4: Material Palette System

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

-- Define palettes as reusable presets
local Palettes = {
    Medieval = {
        wall     = { material = "Cobblestone", color = "#696969" },
        floor    = { material = "WoodPlanks",  color = "#8B4513" },
        roof     = { material = "Slate",        color = "#2F4F4F" },
        accent   = { material = "Neon",         color = "#FFD700" },
    },
    SciFi = {
        wall     = { material = "Metal",        color = "#C0C0C0" },
        floor    = { material = "DiamondPlate",  color = "#B0B0B0" },
        roof     = { material = "ForceField",    color = "#00CED1" },
        accent   = { material = "Neon",         color = "#00FF00" },
    },
    Nature = {
        wall     = { material = "Wood",          color = "#556B2F" },
        floor    = { material = "Grass",         color = "#3CB371" },
        roof     = { material = "LeafyGrass",   color = "#2E8B57" },
        accent   = { material = "Neon",         color = "#FF69B4" },
    },
}

local function buildWithPalette(paletteName, x, z)
    local p = Palettes[paletteName]
    if not p then error("Unknown palette: " .. paletteName) end

    BuilderKit.executeBatch({
        { type = "createPart", params = { name = paletteName .. "_Floor", position = { x = x, y = 0, z = z }, size = { x = 16, y = 1, z = 16 }, material = p.floor.material, color = p.floor.color } },
        { type = "createPart", params = { name = paletteName .. "_WallN", position = { x = x, y = 4, z = z - 8 }, size = { x = 16, y = 8, z = 1 }, material = p.wall.material, color = p.wall.color } },
        { type = "createPart", params = { name = paletteName .. "_WallW", position = { x = x - 8, y = 4, z = z }, size = { x = 1, y = 8, z = 16 }, material = p.wall.material, color = p.wall.color } },
        { type = "createWedge", params = { name = paletteName .. "_Roof", position = { x = x, y = 9, z = z }, size = { x = 18, y = 4, z = 18 }, material = p.roof.material, color = p.roof.color } },
        { type = "addLight", params = { name = paletteName .. "_Glow", type = "Point", position = { x = x, y = 7, z = z }, range = 25, brightness = 4, color = p.accent.color } },
    })
    print("Built with palette: " .. paletteName)
end

buildWithPalette("Medieval", 0, 0)
buildWithPalette("SciFi", 40, 0)
buildWithPalette("Nature", 80, 0)
```

### Example 5: Integration with External AI Command Generation

```lua
-- This example shows how an AI or external system can generate BuilderKit
-- command tables (e.g. via HTTP) and execute them through BuilderKit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local BuilderKit = require(ReplicatedStorage.BuilderKit)

local AI_ENDPOINT = "https://your-ai-service.com/generate-build"

local function buildFromAI(prompt)
    -- Request a build specification from the AI service
    local response = request({
        Url = AI_ENDPOINT,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({ prompt = prompt }),
    })

    local data = HttpService:JSONDecode(response.Body)
    -- Expected format: { commands = { { type = "createPart", params = { ... } }, ... } }

    if not data.commands then
        warn("AI service returned no commands")
        return
    end

    -- Execute the AI-generated commands
    local results = BuilderKit.executeBatch(data.commands, function(current, total)
        print(string.format("AI build progress: %d/%d", current, total))
    end)

    -- Report results
    local successCount = 0
    for _, r in ipairs(results) do
        if r.success then successCount += 1 end
    end
    print(string.format("AI build complete: %d/%d commands succeeded", successCount, #results))

    return results
end

-- Example usage:
-- buildFromAI("A medieval watchtower with a wooden roof")
```

---

## Project Structure

```
roblox-builder-kit/
├── src/
│   └── BuilderKit.lua        — The module (single file, no dependencies)
├── examples/
│   ├── house-builder.lua     — Complete house construction example
│   └── castle-generator.lua  — Procedural castle generation
├── docs/
│   ├── engineering-manual.md — Architecture and internals
│   └── user-guide.md         — Beginner tutorial
├── default.project.json      — Rojo project file
├── LICENSE                   — MIT
└── README.md                 — This file
```

---

## CollectionService Tags

BuilderKit applies the following tags for external system discovery:

| Tag | Applied To | Purpose |
|-----|-----------|---------|
| `BuilderKitBuilt` | All created BaseParts | Discover all BuilderKit-managed parts |
| `BuilderKitUnfinished` | Parts marked by markUnfinished | Highlight deliberate gaps |

---

## License

MIT — see [LICENSE](LICENSE).
