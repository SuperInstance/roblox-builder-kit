-- examples/batch_build.lua
-- Building a complete structure from a template using BuilderKit.executeBatch().
-- Place in StarterPlayerScripts (LocalScript) or ServerScript.
--
-- Defines a complete "Watchtower" as a template (array of commands),
-- then builds it in a single batch call. Demonstrates:
--
--   • Using executeBatch for multi-command builds
--   • Progress callback during batch execution
--   • Mix of part types (walls, wedges, cylinders, lights)
--   • Terrain foundation under the tower
--   • Marking one part as "unfinished" for the player to complete
--   • How batch animation works (if BuildAnimator is present)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuilderKit = require(ReplicatedStorage:WaitForChild("BuilderKit"))

-- ============================================================
--  Template: Stone Watchtower
--  A complete 3-story watchtower with:
--    - Terrain foundation
--    - Stone walls (4 per floor × 3 floors)
--    - Wood floor slabs
--    - Window slits
--    - Spiral staircase (cylinders)
--    - Crenellated roof
--    - Interior lighting
--    - One "unfinished" section for the player to complete
-- ============================================================

local function createWatchtowerTemplate(centerX, centerY, centerZ)
    local template = {}

    -- Tower dimensions
    local radius = 6
    local wallThickness = 0.5
    local floorHeight = 5
    local numFloors = 3
    local wallH = floorHeight - 0.5

    -- Stone color palette
    local stoneColor = "#8C8478"
    local darkStone = "#6B6358"
    local woodColor = "#8B5E3C"
    local roofColor = "#5C4033"

    -- ── Terrain foundation ─────────────────────────────────
    table.insert(template, {
        type = "setTerrain",
        params = {
            position = { x = centerX, y = 0, z = centerZ },
            size = { x = radius * 2 + 4, y = 2, z = radius * 2 + 4 },
            material = "Rock",
            action = "fill",
        }
    })

    -- ── Foundation slab ────────────────────────────────────
    table.insert(template, {
        type = "createPart",
        params = {
            name = "WT_Foundation",
            position = { x = centerX, y = centerY + 0.5, z = centerZ },
            size = { x = radius * 2 + 1, y = 1, z = radius * 2 + 1 },
            material = "Concrete",
            color = stoneColor,
        }
    })

    -- ── For each floor: walls + floor + windows + lights ───
    for floor = 1, numFloors do
        local baseY = centerY + 1 + (floor - 1) * floorHeight

        -- Floor slab (wood)
        table.insert(template, {
            type = "createPart",
            params = {
                name = string.format("WT_Floor%d", floor),
                position = { x = centerX, y = baseY + 0.25, z = centerZ },
                size = { x = radius * 2 - 0.5, y = 0.5, z = radius * 2 - 0.5 },
                material = "WoodPlanks",
                color = woodColor,
            }
        })

        -- Four walls (with window slits on floor 2+)
        for wallIdx = 1, 4 do
            local angle = (wallIdx - 1) * math.pi / 2
            local wx = centerX + math.cos(angle) * radius
            local wz = centerZ + math.sin(angle) * radius

            local isNS = (wallIdx <= 2)  -- north/south walls
            local wallSize = isNS
                and { x = radius * 2, y = wallH, z = wallThickness }
                or  { x = wallThickness, y = wallH, z = radius * 2 }

            table.insert(template, {
                type = "createPart",
                params = {
                    name = string.format("WT_F%d_Wall%d", floor, wallIdx),
                    position = { x = wx, y = baseY + wallH / 2 + 0.5, z = wz },
                    size = wallSize,
                    material = "Slate",
                    color = floor == 1 and stoneColor or darkStone,
                }
            })

            -- Window slit (a thin part cutting into the wall — simulated with transparency)
            if floor >= 2 then
                table.insert(template, {
                    type = "createPart",
                    params = {
                        name = string.format("WT_F%d_Window%d", floor, wallIdx),
                        position = {
                            x = centerX + math.cos(angle) * (radius + 0.1),
                            y = baseY + wallH * 0.6,
                            z = centerZ + math.sin(angle) * (radius + 0.1),
                        },
                        size = { x = isNS and 2 or wallThickness + 0.2, y = 1.5, z = isNS and wallThickness + 0.2 or 2 },
                        material = "Glass",
                        color = "#4A6B8A",
                        transparency = 0.7,
                        canCollide = false,
                    }
                })
            end
        end

        -- Interior light
        table.insert(template, {
            type = "addLight",
            params = {
                name = string.format("WT_Light_F%d", floor),
                type = "Point",
                position = { x = centerX, y = baseY + floorHeight / 2, z = centerZ },
                range = 12,
                brightness = 2,
                color = "#FFD580",
            }
        })

        -- Spiral staircase step (cylinder)
        table.insert(template, {
            type = "createCylinder",
            params = {
                name = string.format("WT_Stairs_F%d", floor),
                position = {
                    x = centerX + math.cos(floor * 1.5) * 1.5,
                    y = baseY + 1,
                    z = centerZ + math.sin(floor * 1.5) * 1.5,
                },
                size = { x = 2, y = 0.5, z = 2 },  -- X is diameter
                material = "WoodPlanks",
                color = "#6B4423",
                rotation = { x = 0, y = 0, z = 90 },  -- rotate to be flat
            }
        })
    end

    -- ── Roof: crenellations ────────────────────────────────
    local roofY = centerY + 1 + numFloors * floorHeight
    local numMerlons = 10

    for i = 1, numMerlons do
        local angle = (i - 1) * (math.pi * 2 / numMerlons)
        table.insert(template, {
            type = "createPart",
            params = {
                name = string.format("WT_Merlon_%02d", i),
                position = {
                    x = centerX + math.cos(angle) * radius,
                    y = roofY + 0.75,
                    z = centerZ + math.sin(angle) * radius,
                },
                size = { x = 1.5, y = 1.5, z = 1.5 },
                material = "Slate",
                color = darkStone,
            }
        })
    end

    -- Roof floor (so you can stand on top)
    table.insert(template, {
        type = "createPart",
        params = {
            name = "WT_RoofFloor",
            position = { x = centerX, y = roofY, z = centerZ },
            size = { x = radius * 2 - 0.5, y = 0.5, z = radius * 2 - 0.5 },
            material = "WoodPlanks",
            color = roofColor,
        }
    })

    -- ── Flag pole on top ───────────────────────────────────
    table.insert(template, {
        type = "createPart",
        params = {
            name = "WT_FlagPole",
            position = { x = centerX, y = roofY + 4, z = centerZ },
            size = { x = 0.2, y = 8, z = 0.2 },
            material = "Metal",
            color = "#808080",
        }
    })

    -- Flag (red)
    table.insert(template, {
        type = "createPart",
        params = {
            name = "WT_Flag",
            position = { x = centerX + 1.5, y = roofY + 6, z = centerZ },
            size = { x = 3, y = 2, z = 0.05 },
            material = "Fabric",
            color = "#C04040",
            canCollide = false,
        }
    })

    -- Beacon light at the top
    table.insert(template, {
        type = "addLight",
        params = {
            name = "WT_Beacon",
            type = "Point",
            position = { x = centerX, y = roofY + 8, z = centerZ },
            range = 40,
            brightness = 5,
            color = "#FFCC40",
        }
    })

    return template
end

-- ============================================================
--  Build the watchtower
-- ============================================================

task.wait(2)

-- Clear previous builds
BuilderKit.clearAll()
print("[Batch Build] Cleared previous builds")

-- Generate the template
local template = createWatchtowerTemplate(0, 0, 0)
print(string.format("[Batch Build] Template: %d commands", #template))

-- Build progress tracking
local progressLog = {}
local startTime = os.clock()

-- Execute the batch with progress callback
local results = BuilderKit.executeBatch(
    template,
    function(current, total, result)
        -- Progress callback fires after each command
        local pct = math.floor(current / total * 100)
        local cmdType = template[current].type
        table.insert(progressLog, string.format("  [%d/%d] %d%% — %s", current, total, pct, cmdType))

        -- Print milestone updates
        if current == math.floor(total * 0.25) then
            print(string.format("[Batch Build] 25%% complete (%d/%d commands)", current, total))
        elseif current == math.floor(total * 0.5) then
            print(string.format("[Batch Build] 50%% complete (%d/%d commands)", current, total))
        elseif current == math.floor(total * 0.75) then
            print(string.format("[Batch Build] 75%% complete (%d/%d commands)", current, total))
        end
    end
)

local elapsed = os.clock() - startTime

-- ============================================================
--  Results summary
-- ============================================================

local successCount = 0
local failCount = 0
for _, r in ipairs(results) do
    if r.success then
        successCount += 1
    else
        failCount += 1
        print(string.format("  ❌ Command %d failed: %s — %s",
            r.index, r.type, r.error))
    end
end

print(string.format("\n[Batch Build] ═════════════════════════════════"))
print(string.format("[Batch Build] Watchtower complete!"))
print(string.format("[Batch Build]   Commands executed: %d", #template))
print(string.format("[Batch Build]   Successful: %d | Failed: %d", successCount, failCount))
print(string.format("[Batch Build]   Parts created: %d", BuilderKit.partsCreated))
print(string.format("[Batch Build]   Time: %.2fs", elapsed))
print(string.format("[Batch Build] ═════════════════════════════════"))

-- ============================================================
--  Mark one part as unfinished (for player to complete)
-- ============================================================

local unfinishedResult = BuilderKit.execute({
    type = "markUnfinished",
    params = {
        partName = nil,  -- pick randomly
    }
})

if unfinishedResult then
    print(string.format("[Batch Build] 🔨 %s", unfinishedResult.message))
end

print("\n[Batch Build] The watchtower has one section left unfinished.")
print("[Batch Build] The player must complete it to proceed.")
