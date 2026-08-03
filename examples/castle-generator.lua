--[[
    Castle Generator Example for BuilderKit
    ────────────────────────────────────────
    Procedurally generates a medieval castle with:
    - Central keep tower with multiple floors
    - Four corner towers connected by curtain walls
    - Gatehouse with archway
    - Courtyard terrain (paved)
    - Wall merlons (crenellations)
    - Banner lights at each tower

    Configuration is table-driven — change CASTLE_CONFIG to resize,
    recolor, or add/remove features.

    Usage:
        Place this script in ServerScriptService.
        Ensure BuilderKit is in ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage:WaitForChild("BuilderKit"))

-- ── Configuration ──────────────────────────────────────────────

local CASTLE_CONFIG = {
    center = { x = 0, y = 0, z = 0 },
    courtyardSize = 40,        -- Courtyard dimensions (studs)
    towerRadius   = 5,         -- Corner tower radius
    towerHeight   = 28,        -- Corner tower height
    towerFloors   = 4,         -- Number of interior floors per tower
    keepRadius    = 8,         -- Central keep radius
    keepHeight    = 40,        -- Central keep height
    keepFloors    = 5,         -- Central keep floors
    wallHeight    = 14,        -- Curtain wall height
    wallThickness = 2,         -- Curtain wall thickness
    merlonSize    = { x = 2, y = 2, z = 2 }, -- Crenellation teeth

    palette = {
        stone    = { material = "Cobblestone", color = "#696969" },
        floor    = { material = "WoodPlanks",  color = "#8B5E3C" },
        roof     = { material = "Slate",        color = "#2F2F4F" },
        gate     = { material = "Wood",         color = "#3E2723" },
        banner   = { material = "Neon",         color = "#DC143C" },
        pavement = "Pavement",
    },
}

-- ── Helper: Generate a cylinder tower ──────────────────────────

local function buildTower(name, cx, cz, radius, height, floors, palette)
    local commands = {}
    local floorHeight = height / floors

    for floor = 1, floors do
        local y = (floor - 1) * floorHeight + floorHeight / 2
        local m = (floor == floors) and palette.roof or palette.stone

        table.insert(commands, {
            type = "createCylinder",
            params = {
                name = string.format("%s_F%d", name, floor),
                position = { x = cx, y = y, z = cz },
                size = { x = radius * 2, y = floorHeight, z = radius * 2 },
                material = m.material,
                color = m.color,
            }
        })

        -- Interior floor (wood)
        if floor < floors then
            table.insert(commands, {
                type = "createPart",
                params = {
                    name = string.format("%s_Floor%d", name, floor),
                    position = { x = cx, y = y - floorHeight / 2 + 0.5, z = cz },
                    size = { x = radius * 1.6, y = 1, z = radius * 1.6 },
                    material = palette.floor.material,
                    color = palette.floor.color,
                }
            })
        end
    end

    -- Banner on top
    table.insert(commands, {
        type = "createPart",
        params = {
            name = name .. "_Banner",
            position = { x = cx, y = height + 3, z = cz },
            size = { x = 1, y = 4, z = 1 },
            material = palette.banner.material,
            color = palette.banner.color,
        }
    })

    -- Light at the top
    table.insert(commands, {
        type = "addLight",
        params = {
            name = name .. "_Light",
            type = "Point",
            position = { x = cx, y = height - 2, z = cz },
            range = radius * 4,
            brightness = 2,
            color = "#FFE4B5",
        }
    })

    return commands
end

-- ── Helper: Generate curtain walls with crenellations ──────────

local function buildWall(name, x1, z1, x2, z2, height, thickness, palette, merlonSize)
    local commands = {}
    local dx, dz = x2 - x1, z2 - z1
    local length = math.sqrt(dx * dx + dz * dz)
    local angle = math.deg(math.atan2(dz, dx))

    -- Main wall
    table.insert(commands, {
        type = "createPart",
        params = {
            name = name,
            position = { x = (x1 + x2) / 2, y = height / 2, z = (z1 + z2) / 2 },
            size = { x = length, y = height, z = thickness },
            material = palette.stone.material,
            color = palette.stone.color,
            rotation = { x = 0, y = angle, z = 0 },
        }
    })

    -- Crenellations (merlons) along the top
    local merlonCount = math.floor(length / (merlonSize.x * 2))
    local spacing = length / merlonCount

    for i = 0, merlonCount - 1 do
        local t = (i + 0.5) / merlonCount
        local mx = x1 + dx * t
        local mz = z1 + dz * t
        table.insert(commands, {
            type = "createPart",
            params = {
                name = string.format("%s_Merlon%d", name, i),
                position = { x = mx, y = height + merlonSize.y / 2, z = mz },
                size = merlonSize,
                material = palette.stone.material,
                color = palette.stone.color,
            }
        })
    end

    return commands
end

-- ── Helper: Gatehouse ──────────────────────────────────────────

local function buildGatehouse(cx, cz, facing, height, palette)
    local commands = {}
    local gateWidth = 5
    local gateDepth = 4

    -- Left pillar
    table.insert(commands, {
        type = "createPart",
        params = {
            name = "GateLeftPillar",
            position = { x = cx - gateWidth / 2 - 1, y = height / 2, z = cz },
            size = { x = 2, y = height, z = gateDepth },
            material = palette.stone.material,
            color = palette.stone.color,
        }
    })

    -- Right pillar
    table.insert(commands, {
        type = "createPart",
        params = {
            name = "GateRightPillar",
            position = { x = cx + gateWidth / 2 + 1, y = height / 2, z = cz },
            size = { x = 2, y = height, z = gateDepth },
            material = palette.stone.material,
            color = palette.stone.color,
        }
    })

    -- Arch top
    table.insert(commands, {
        type = "createPart",
        params = {
            name = "GateArch",
            position = { x = cx, y = height + 1, z = cz },
            size = { x = gateWidth + 4, y = 2, z = gateDepth },
            material = palette.stone.material,
            color = palette.stone.color,
        }
    })

    -- Gate door
    table.insert(commands, {
        type = "createPart",
        params = {
            name = "GateDoor",
            position = { x = cx, y = height / 2 - 1, z = cz },
            size = { x = gateWidth, y = height - 2, z = 1 },
            material = palette.gate.material,
            color = palette.gate.color,
        }
    })

    return commands
end

-- ── Main Castle Generation ─────────────────────────────────────

local function generateCastle(config)
    local commands = {}
    local c = config.center
    local half = config.courtyardSize / 2
    local p = config.palette

    -- Corner tower positions
    local corners = {
        { x = c.x - half, z = c.z - half, name = "TowerNW" },
        { x = c.x + half, z = c.z - half, name = "TowerNE" },
        { x = c.x - half, z = c.z + half, name = "TowerSW" },
        { x = c.x + half, z = c.z + half, name = "TowerSE" },
    }

    -- Build corner towers
    for _, corner in ipairs(corners) do
        for _, cmd in ipairs(buildTower(corner.name, corner.x, corner.z,
            config.towerRadius, config.towerHeight, config.towerFloors, p)) do
            table.insert(commands, cmd)
        end
    end

    -- Build curtain walls between corner towers
    local wallPairs = {
        { corners[1], corners[2], "WallNorth" },
        { corners[2], corners[4], "WallEast"  },
        { corners[4], corners[3], "WallSouth" },
        { corners[3], corners[1], "WallWest"  },
    }

    for _, pair in ipairs(wallPairs) do
        for _, cmd in ipairs(buildWall(pair[3],
            pair[1].x, pair[1].z, pair[2].x, pair[2].z,
            config.wallHeight, config.wallThickness, p, config.merlonSize)) do
            table.insert(commands, cmd)
        end
    end

    -- Gatehouse on the south wall
    for _, cmd in ipairs(buildGatehouse(c.x, c.z + half, "South", config.wallHeight + 2, p)) do
        table.insert(commands, cmd)
    end

    -- Central keep
    for _, cmd in ipairs(buildTower("Keep", c.x, c.z,
        config.keepRadius, config.keepHeight, config.keepFloors, p)) do
        table.insert(commands, cmd)
    end

    -- Courtyard terrain (paved)
    table.insert(commands, {
        type = "setTerrain",
        params = {
            position = { x = c.x, y = c.y, z = c.z },
            size = { x = config.courtyardSize, y = 1, z = config.courtyardSize },
            material = p.pavement,
            action = "fill",
        }
    })

    -- Foundation terrain (ground)
    table.insert(commands, {
        type = "setTerrain",
        params = {
            position = { x = c.x, y = c.y - 2, z = c.z },
            size = { x = config.courtyardSize + 20, y = 2, z = config.courtyardSize + 20 },
            material = "Grass",
            action = "fill",
        }
    })

    return commands
end

-- ── Execute ────────────────────────────────────────────────────

print("🏰 Generating castle...")

local commands = generateCastle(CASTLE_CONFIG)
print(string.format("Generated %d build commands", #commands))

local results = BuilderKit.executeBatch(commands, function(current, total)
    local pct = math.floor(current / total * 100)
    if current % 10 == 0 then
        print(string.format("  Castle progress: %d%% (%d/%d)", pct, current, total))
    end
end)

local successCount = 0
for _, r in ipairs(results) do
    if r.success then successCount += 1 end
end

print(string.format("🏰 Castle generation complete! %d/%d commands succeeded.", successCount, #commands))
print(string.format("   Corner towers: 4 | Curtain walls: 4 | Central keep: 1 | Gatehouse: 1"))
print(string.format("   Total parts: %d", BuilderKit.partsCreated))
