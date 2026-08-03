--[[
    House Builder Example for BuilderKit
    ─────────────────────────────────────
    Demonstrates building a complete house structure from a JSON-like spec,
    including walls, roof, doors, windows, interior lighting, and terrain.

    Usage:
        Place this script in ServerScriptService.
        Ensure BuilderKit is in ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage:WaitForChild("BuilderKit"))

-- ── House Specification ────────────────────────────────────────

local HOUSE_SPEC = {
    width  = 16,
    depth  = 12,
    height = 8,
    position = { x = 0, y = 0, z = 0 },

    materials = {
        floor    = { material = "WoodPlanks",  color = "#8B5E3C" },
        wall      = { material = "Brick",       color = "#A0522D" },
        roof     = { material = "WoodPlanks",  color = "#4A3520" },
        door     = { material = "Wood",         color = "#654321" },
        window   = { material = "Glass",        color = "#87CEEB", transparency = 0.5 },
        foundation = { material = "Concrete",   color = "#707070" },
    },

    hasChimney  = true,
    hasInterior = true,
}

-- ── Build Functions ────────────────────────────────────────────

local function buildFoundation(spec)
    local p = spec.position
    local m = spec.materials.foundation
    return {
        type = "createPart",
        params = {
            name = "Foundation",
            position = { x = p.x, y = p.y - 0.5, z = p.z },
            size = { x = spec.width + 2, y = 1, z = spec.depth + 2 },
            material = m.material,
            color = m.color,
        }
    }
end

local function buildFloor(spec)
    local p = spec.position
    local m = spec.materials.floor
    return {
        type = "createPart",
        params = {
            name = "Floor",
            position = { x = p.x, y = p.y + 0.5, z = p.z },
            size = { x = spec.width, y = 1, z = spec.depth },
            material = m.material,
            color = m.color,
        }
    }
end

local function buildWalls(spec)
    local p = spec.position
    local m = spec.materials.wall
    local w, d, h = spec.width, spec.depth, spec.height
    local halfW, halfD = w / 2, d / 2

    return {
        { type = "createPart", params = { name = "WallNorth", position = { x = p.x, y = p.y + h / 2 + 1, z = p.z - halfD }, size = { x = w, y = h, z = 1 }, material = m.material, color = m.color } },
        { type = "createPart", params = { name = "WallSouth", position = { x = p.x, y = p.y + h / 2 + 1, z = p.z + halfD }, size = { x = w, y = h, z = 1 }, material = m.material, color = m.color } },
        { type = "createPart", params = { name = "WallWest",  position = { x = p.x - halfW, y = p.y + h / 2 + 1, z = p.z }, size = { x = 1, y = h, z = d }, material = m.material, color = m.color } },
        { type = "createPart", params = { name = "WallEast",  position = { x = p.x + halfW, y = p.y + h / 2 + 1, z = p.z }, size = { x = 1, y = h, z = d }, material = m.material, color = m.color } },
    }
end

local function buildDoor(spec)
    local p = spec.position
    local m = spec.materials.door
    local halfD = spec.depth / 2

    -- Door opening on the south wall
    return {
        type = "createPart",
        params = {
            name = "Door",
            position = { x = p.x, y = p.y + 3.5, z = p.z + halfD },
            size = { x = 3, y = 5, z = 1.1 },
            material = m.material,
            color = m.color,
        }
    }
end

local function buildWindows(spec)
    local p = spec.position
    local m = spec.materials.window
    local halfW, halfD = spec.width / 2, spec.depth / 2
    local t = m.transparency or 0.5

    return {
        { type = "createPart", params = { name = "WindowWest", position = { x = p.x - halfW, y = p.y + 5, z = p.z - 3 }, size = { x = 1.1, y = 3, z = 3 }, material = m.material, color = m.color, transparency = t } },
        { type = "createPart", params = { name = "WindowEast", position = { x = p.x + halfW, y = p.y + 5, z = p.z + 3 }, size = { x = 1.1, y = 3, z = 3 }, material = m.material, color = m.color, transparency = t } },
        { type = "createPart", params = { name = "WindowNorth1", position = { x = p.x - 4, y = p.y + 5, z = p.z - halfD }, size = { x = 3, y = 3, z = 1.1 }, material = m.material, color = m.color, transparency = t } },
        { type = "createPart", params = { name = "WindowNorth2", position = { x = p.x + 4, y = p.y + 5, z = p.z - halfD }, size = { x = 3, y = 3, z = 1.1 }, material = m.material, color = m.color, transparency = t } },
    }
end

local function buildRoof(spec)
    local p = spec.position
    local m = spec.materials.roof
    local halfW = spec.width / 2

    return {
        -- Left roof slope
        { type = "createWedge", params = {
            name = "RoofLeft",
            position = { x = p.x - halfW / 2, y = p.y + spec.height + 2, z = p.z },
            size = { x = halfW, y = 4, z = spec.depth + 2 },
            material = m.material, color = m.color,
            rotation = { x = 0, y = 0, z = 0 },
        } },
        -- Right roof slope (flipped)
        { type = "createWedge", params = {
            name = "RoofRight",
            position = { x = p.x + halfW / 2, y = p.y + spec.height + 2, z = p.z },
            size = { x = halfW, y = 4, z = spec.depth + 2 },
            material = m.material, color = m.color,
            rotation = { x = 0, y = 180, z = 0 },
        } },
    }
end

local function buildChimney(spec)
    local p = spec.position
    local halfW = spec.width / 2
    return {
        type = "createPart",
        params = {
            name = "Chimney",
            position = { x = p.x + halfW - 2, y = p.y + spec.height + 6, z = p.z - 2 },
            size = { x = 2, y = 6, z = 2 },
            material = "Cobblestone",
            color = "#4A4A4A",
        }
    }
end

local function buildInterior(spec)
    local p = spec.position
    return {
        -- Interior light
        { type = "addLight", params = {
            name = "InteriorLight",
            type = "Point",
            position = { x = p.x, y = p.y + spec.height - 1, z = p.z },
            range = spec.width,
            brightness = 3,
            color = "#FFE4B5",
        } },
        -- Hearth light (warm glow near chimney area)
        { type = "addLight", params = {
            name = "HearthGlow",
            type = "Point",
            position = { x = p.x + spec.width / 2 - 3, y = p.y + 2, z = p.z - 3 },
            range = 8,
            brightness = 4,
            color = "#FF6600",
        } },
    }
end

-- ── Main Build ─────────────────────────────────────────────────

local function buildHouse(spec)
    local commands = {}

    -- Foundation and floor
    table.insert(commands, buildFoundation(spec))
    table.insert(commands, buildFloor(spec))

    -- Walls
    for _, cmd in ipairs(buildWalls(spec)) do
        table.insert(commands, cmd)
    end

    -- Door
    table.insert(commands, buildDoor(spec))

    -- Windows
    for _, cmd in ipairs(buildWindows(spec)) do
        table.insert(commands, cmd)
    end

    -- Roof
    for _, cmd in ipairs(buildRoof(spec)) do
        table.insert(commands, cmd)
    end

    -- Chimney
    if spec.hasChimney then
        table.insert(commands, buildChimney(spec))
    end

    -- Interior details
    if spec.hasInterior then
        for _, cmd in ipairs(buildInterior(spec)) do
            table.insert(commands, cmd)
        end
    end

    -- Terrain patch around the house
    table.insert(commands, {
        type = "setTerrain",
        params = {
            position = { x = spec.position.x, y = spec.position.y - 1, z = spec.position.z },
            size = { x = spec.width + 10, y = 2, z = spec.depth + 10 },
            material = "Grass",
            action = "fill",
        }
    })

    return commands
end

-- ── Execute ────────────────────────────────────────────────────

print("🏠 Building house...")

local commands = buildHouse(HOUSE_SPEC)
print(string.format("Generated %d commands", #commands))

local results = BuilderKit.executeBatch(commands, function(current, total)
    if current % 5 == 0 then
        print(string.format("  Progress: %d/%d", current, total))
    end
end)

local successCount = 0
for _, r in ipairs(results) do
    if r.success then successCount += 1 end
end

print(string.format("🏠 House complete! %d/%d commands succeeded.", successCount, #results))

-- Group all parts into a model
BuilderKit.execute({
    type = "createGroup",
    params = {
        name = "House",
        partNames = (function()
            local names = {}
            for _, r in ipairs(results) do
                if r.success and r.result and typeof(r.result) == "Instance" then
                    table.insert(names, r.result.Name)
                end
            end
            return names
        end)(),
    }
})
