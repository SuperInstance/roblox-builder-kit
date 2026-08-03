# BuilderKit User Guide

*A beginner-friendly tutorial for building structures in Roblox with BuilderKit.*

---

## What is BuilderKit?

BuilderKit is a Lua module that helps you build things in Roblox **programmatically** — by writing code instead of placing parts by hand. Instead of dragging parts around in Studio, you write simple instructions like "create a 4×1×4 wood plank at position (0, 5, 0)" and BuilderKit does the rest.

It's especially useful for:
- **AI-generated builds** — an AI creates a list of parts and BuilderKit places them
- **Procedural generation** — code generates structures like towers, castles, or forests
- **Batch building** — place 100 parts in one call with progress tracking

---

## Installation

### Option A: Rojo (Recommended)

If you use [Rojo](https://rojo.space/) for your project:

1. Clone or download this repository.
2. In your `default.project.json`, reference `BuilderKit.lua`:

```json
{
  "ReplicatedStorage": {
    "BuilderKit": { "$path": "../roblox-builder-kit/src/BuilderKit.lua" }
  }
}
```

3. Run `rojo serve` and sync into Studio.

### Option B: Manual Copy

1. Open `src/BuilderKit.lua` from this repo.
2. In Roblox Studio, right-click `ReplicatedStorage` in the Explorer.
3. Insert → ModuleScript.
4. Rename it to `BuilderKit`.
5. Paste the file contents.

---

## Your First Build

Create a `Script` in `ServerScriptService` and paste:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage:WaitForChild("BuilderKit"))

-- Create a single part
BuilderKit.execute({
    type = "createPart",
    params = {
        name = "MyFirstBlock",
        position = { x = 0, y = 5, z = 0 },
        size = { x = 4, y = 4, z = 4 },
        material = "Neon",
        color = "#00FF00"
    }
})
```

Press **Play** in Studio. You should see a glowing green cube floating at position (0, 5, 0).

---

## Understanding Commands

Every BuilderKit action uses the same format:

```lua
{
    type = "commandName",      -- What to do
    params = {                  -- How to do it
        name = "PartName",
        position = { x = 0, y = 0, z = 0 },
        -- ...more properties
    }
}
```

You can also write commands "flat" (without the `params` wrapper):

```lua
{ type = "createPart", name = "MyBlock", position = { x = 0, y = 5, z = 0 } }
```

Both formats work identically.

---

## Common Property Types

### Position

```lua
position = { x = 10, y = 5, z = -3 }
-- or use numbered keys:
position = { 10, 5, -3 }
```

### Size

```lua
size = { x = 4, y = 1, z = 4 }    -- 4 studs wide, 1 tall, 4 deep
```

### Color

```lua
color = "#FF5733"              -- Hex color (recommended)
color = { 255, 87, 51 }        -- RGB (0-255)
color = { r = 255, g = 87, b = 51 }
```

Find hex colors at [htmlcolorcodes.com](https://htmlcolorcodes.com/).

### Material

```lua
material = "WoodPlanks"
material = "Brick"
material = "Neon"
material = "Ice"
material = "Grass"
```

Use any name from the [Roblox Material enum](https://create.roblox.com/docs/reference/engine/enums/Enum.Material). If you misspell it, BuilderKit falls back to `SmoothPlastic`.

---

## Building Multiple Things

Use `executeBatch()` to build many parts at once:

```lua
BuilderKit.executeBatch({
    { type = "createPart", params = { name = "Step1", position = { x = 0, y = 1, z = 0 }, size = { x = 4, y = 1, z = 4 }, material = "Slate", color = "#888888" } },
    { type = "createPart", params = { name = "Step2", position = { x = 0, y = 2, z = 3 }, size = { x = 4, y = 1, z = 4 }, material = "Slate", color = "#888888" } },
    { type = "createPart", params = { name = "Step3", position = { x = 0, y = 3, z = 6 }, size = { x = 4, y = 1, z = 4 }, material = "Slate", color = "#888888" } },
})
```

You can also track progress:

```lua
BuilderKit.executeBatch(commands, function(current, total)
    print(string.format("Progress: %d out of %d", current, total))
end)
```

---

## Part Types

| Command | Creates | Best For |
|---------|---------|----------|
| `createPart` | Standard Part | Floors, walls, platforms |
| `createWedge` | WedgePart | Ramps, roofs, diagonal surfaces |
| `createCylinder` | Cylinder Part | Columns, pillars, pipes |
| `createSphere` | Ball Part | Decoration, orbs, domes |

### Example: Building a Column

```lua
BuilderKit.execute({
    type = "createCylinder",
    params = {
        name = "MarbleColumn",
        position = { x = 10, y = 10, z = 0 },
        size = { x = 4, y = 20, z = 4 },
        material = "Marble",
        color = "#F5F5DC"
    }
})
```

---

## Adding Lights

```lua
BuilderKit.execute({
    type = "addLight",
    params = {
        name = "TorchLight",
        type = "Point",
        position = { x = 5, y = 8, z = 5 },
        range = 20,
        brightness = 3,
        color = "#FF6600"
    }
})
```

Light types: `"Point"` (all directions), `"Spot"` (cone), `"Surface"` (from a face).

---

## Modifying and Deleting Parts

### Change appearance

```lua
BuilderKit.execute({
    type = "createSurface",
    params = {
        name = "MyFirstBlock",
        material = "Neon",
        color = "#FF0000"
    }
})
```

### Move a part

```lua
BuilderKit.execute({
    type = "movePart",
    params = { name = "MyFirstBlock", position = { x = 20, y = 5, z = 0 } }
})
```

### Delete a part

```lua
BuilderKit.execute({
    type = "deletePart",
    params = { name = "MyFirstBlock" }
})
```

---

## Terrain

Fill terrain (ground):

```lua
BuilderKit.execute({
    type = "setTerrain",
    params = {
        position = { x = 0, y = 0, z = 0 },
        size = { x = 100, y = 4, z = 100 },
        material = "Grass",
        action = "fill"
    }
})
```

Clear terrain:

```lua
BuilderKit.execute({
    type = "setTerrain",
    params = {
        position = { x = 0, y = 0, z = 0 },
        size = { x = 50, y = 10, z = 50 },
        action = "clear"
    }
})
```

Valid terrain materials: Grass, Rock, Sand, Water, Snow, Mud, Slate, Ice, Ground, Asphalt, Basalt, CrackedLava, GlacialIce, LeafyGrass, Limestone, Marble, Pavement, Plaster, Salt, Sandstone, WoodPlanks.

---

## Grouping Parts

Organize parts into a Model:

```lua
-- First create some parts
BuilderKit.executeBatch({
    { type = "createPart", params = { name = "Chair1", position = { x = 0, y = 1, z = 0 }, size = { x = 2, y = 2, z = 2 }, material = "Wood", color = "#8B4513" } },
    { type = "createPart", params = { name = "Chair2", position = { x = 5, y = 1, z = 0 }, size = { x = 2, y = 2, z = 2 }, material = "Wood", color = "#8B4513" } },
})

-- Group them
BuilderKit.execute({
    type = "createGroup",
    params = { name = "ChairSet", partNames = { "Chair1", "Chair2" } }
})
```

---

## Cleaning Up

```lua
-- Delete everything BuilderKit created
BuilderKit.clearAll()

-- See how many parts exist
print("Parts created:", BuilderKit.partsCreated)

-- Get all built parts
local parts = BuilderKit.getBuiltParts()
```

---

## Tips for Beginners

1. **Start small** — build one part, test, then add more.
2. **Use descriptive names** — `"FrontWall"` is better than `"Part3"`.
3. **Comment your code** — note what each section builds.
4. **Test in Studio** — press Play frequently to see results.
5. **Position carefully** — Y is up/down, X is left/right, Z is forward/backward. The center of the world is (0, 0, 0).
6. **Batch for performance** — `executeBatch()` is better than calling `execute()` 50 times in a loop.

---

## Next Steps

- Read the **[Full API Reference](../README.md#full-api-reference)** for all parameters
- Try the **[examples](../examples/)** — house builder and castle generator
- Check the **[Engineering Manual](./engineering-manual.md)** for architecture details

---

## Troubleshooting

**"Unknown command type"** — Check that your `type` field matches exactly (case-sensitive).

**Part not appearing** — Check the position. Y = 0 might be inside the ground. Try Y = 5.

**Wrong color** — Make sure hex strings start with `#` and have 6 digits: `#FF5733`, not `FF573` or `#FF5`.

**"Part not found"** in createSurface/movePart/deletePart — The name must match exactly. BuilderKit searches the BuilderKit folder first, then the whole workspace.

**Need help?** Open an issue on GitHub.
