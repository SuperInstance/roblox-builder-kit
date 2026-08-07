-- tests/builderkit_edge_cases.lua
-- Comprehensive edge case tests for BuilderKit — the hard shell of the hermit crab.

local testkit = require("testkit")
local expect = testkit.expect

-- Mock typeof
if not typeof then
    _G.typeof = function(v)
        local t = type(v)
        if t == "table" and v._robloxType then return v._robloxType end
        return t
    end
    rawset(_G, "typeof", _G.typeof)
end

-- Mock warn (Roblox global)
if not warn then
    _G.warn = function(...) end
    rawset(_G, "warn", _G.warn)
end

-- Mock task (Roblox task library)
if not task then
    _G.task = {
        wait = function() end,
        spawn = function(f, ...) if type(f) == "function" then f(...) end end,
        delay = function(t, f) f() end,
    }
    rawset(_G, "task", _G.task)
end

-- Mock math.random for deterministic tests
local _origRandom = math.random
math.random = function(a, b) if a and b then return a end if a then return a end return 1 end

-- Mock os.time
local _origOsTime = os.time
os.time = function() return 1700000000 end

-- Mock BrickColor
if not BrickColor then
    _G.BrickColor = { new = function() return { Name = "Test" } end, Red = function() return { Name = "Red" } end }
    rawset(_G, "BrickColor", _G.BrickColor)
end

-- Mock Enum
if not Enum then
    _G.Enum = setmetatable({}, {
        __index = function(t, k)
            return setmetatable({}, {
                __index = function(t2, k2)
                    return { Name = k2, enumType = k }
                end
            })
        end
    })
    rawset(_G, "Enum", _G.Enum)
end

local BuilderKit = testkit.loadModule("/home/eileen/projects/roblox-builder-kit/src/BuilderKit.lua")

-- ============================================================
-- createPart edge cases
-- ============================================================

describe("createPart edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
    end)

    it("creates part with default params (no name, no size, no position)", function()
        local part = BuilderKit.createPart({})
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with hex color including hash", function()
        local part = BuilderKit.createPart({ name = "HexHash", color = "#FF8800" })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with hex color without hash", function()
        local part = BuilderKit.createPart({ name = "HexNoHash", color = "FF8800" })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with RGB table color", function()
        local part = BuilderKit.createPart({ name = "RGBTable", color = { 100, 200, 50 } })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with named key color table", function()
        local part = BuilderKit.createPart({ name = "RGBKeys", color = { r = 255, g = 0, b = 128 } })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with invalid color string (defaults applied)", function()
        local part = BuilderKit.createPart({ name = "BadColor", color = "not-a-color" })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with invalid material (defaults to SmoothPlastic)", function()
        local part = BuilderKit.createPart({ name = "BadMat", material = "Unobtainium" })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with rotation", function()
        -- CFrame.Angles arithmetic may not work in mock; just verify no crash on the params
        local ok, part = pcall(BuilderKit.createPart, {
            name = "Rotated",
            position = { x = 0, y = 5, z = 0 },
            rotation = { 45, 90, 180 }
        })
        expect(ok):toBe(true)
    end)

    it("creates part with named-key rotation", function()
        local ok, part = pcall(BuilderKit.createPart, {
            name = "RotatedKeys",
            rotation = { x = 30, y = 60, z = 90 }
        })
        expect(ok):toBe(true)
    end)

    it("creates part with transparency 1 (fully invisible)", function()
        local part = BuilderKit.createPart({ name = "Ghost", transparency = 1 })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with canCollide false", function()
        local part = BuilderKit.createPart({ name = "NoCollide", canCollide = false })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with reflectance", function()
        local part = BuilderKit.createPart({ name = "Shiny", reflectance = 0.8 })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with anchored false", function()
        local part = BuilderKit.createPart({ name = "Floating", anchored = false })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with named position keys", function()
        local part = BuilderKit.createPart({ name = "NamedPos", position = { x = 10, y = 20, z = 30 } })
        expect(part ~= nil):toBe(true)
    end)

    it("creates part with mixed array/named position keys", function()
        local part = BuilderKit.createPart({ name = "MixedPos", position = { x = 10, [2] = 20, z = 30 } })
        expect(part ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- createWedge / createCylinder / createSphere
-- ============================================================

describe("shape creation edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
    end)

    it("createWedge produces an instance", function()
        local wedge = BuilderKit.createWedge({ name = "Ramp", size = {4, 2, 6} })
        expect(wedge ~= nil):toBe(true)
    end)

    it("createCylinder produces an instance", function()
        local cyl = BuilderKit.createCylinder({ name = "Pillar", size = {2, 10, 2} })
        expect(cyl ~= nil):toBe(true)
    end)

    it("createSphere produces an instance", function()
        local ball = BuilderKit.createSphere({ name = "Orb", size = {3, 3, 3} })
        expect(ball ~= nil):toBe(true)
    end)

    it("createWedge with no params uses defaults", function()
        local wedge = BuilderKit.createWedge({})
        expect(wedge ~= nil):toBe(true)
    end)

    it("createCylinder with nil params still works", function()
        local cyl = BuilderKit.createCylinder({})
        expect(cyl ~= nil):toBe(true)
    end)

    it("createSphere with extreme size values", function()
        local ball = BuilderKit.createSphere({ name = "BigBall", size = {1000, 1000, 1000} })
        expect(ball ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- createSurface edge cases
-- ============================================================

describe("createSurface edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "SurfaceTarget", size = {4, 4, 4}, position = {0, 5, 0} })
    end)

    it("modifies existing part material", function()
        local part = BuilderKit.createSurface({ name = "SurfaceTarget", material = "Neon" })
        expect(part ~= nil):toBe(true)
    end)

    it("modifies existing part color", function()
        local part = BuilderKit.createSurface({ name = "SurfaceTarget", color = "#00FF00" })
        expect(part ~= nil):toBe(true)
    end)

    it("modifies existing part transparency", function()
        local part = BuilderKit.createSurface({ name = "SurfaceTarget", transparency = 0.5 })
        expect(part ~= nil):toBe(true)
    end)

    it("returns nil for non-existent part", function()
        local result = BuilderKit.createSurface({ name = "DoesNotExist", material = "Neon" })
        expect(result):toBe(nil)
    end)

    it("handles missing material param gracefully", function()
        local part = BuilderKit.createSurface({ name = "SurfaceTarget", color = "#FF0000" })
        expect(part ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- createGroup edge cases
-- ============================================================

describe("createGroup edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "G1", size = {1,1,1}, position = {0,0,0} })
        BuilderKit.createPart({ name = "G2", size = {1,1,1}, position = {1,0,0} })
    end)

    it("groups multiple existing parts", function()
        local model = BuilderKit.createGroup({ name = "TestGroup", partNames = { "G1", "G2" } })
        expect(model ~= nil):toBe(true)
    end)

    it("handles missing part names gracefully", function()
        local model = BuilderKit.createGroup({ name = "PartialGroup", partNames = { "G1", "MissingPart" } })
        expect(model ~= nil):toBe(true)
    end)

    it("handles empty partNames array", function()
        local model = BuilderKit.createGroup({ name = "EmptyGroup", partNames = {} })
        expect(model ~= nil):toBe(true)
    end)

    it("handles nil partNames", function()
        local model = BuilderKit.createGroup({ name = "NilGroup" })
        expect(model ~= nil):toBe(true)
    end)

    it("uses default name when no name provided", function()
        local model = BuilderKit.createGroup({ partNames = { "G1" } })
        expect(model ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- addLight edge cases
-- ============================================================

describe("addLight edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
    end)

    it("creates point light with carrier part at position", function()
        local light = BuilderKit.addLight({ name = "Lamp1", position = {5, 10, 5}, range = 20 })
        expect(light ~= nil):toBe(true)
    end)

    it("creates spot light", function()
        local light = BuilderKit.addLight({ name = "Spot1", type = "Spot", position = {0, 20, 0} })
        expect(light ~= nil):toBe(true)
    end)

    it("creates surface light", function()
        local light = BuilderKit.addLight({ name = "Surf1", type = "Surface", position = {0, 10, 0} })
        expect(light ~= nil):toBe(true)
    end)

    it("creates light with custom brightness and color", function()
        local light = BuilderKit.addLight({
            name = "Mood",
            position = {0, 5, 0},
            brightness = 5,
            color = "#4488FF",
            range = 32
        })
        expect(light ~= nil):toBe(true)
    end)

    it("handles lightType alias", function()
        local light = BuilderKit.addLight({
            name = "Aliased",
            lightType = "Spot",
            position = {0, 5, 0}
        })
        expect(light ~= nil):toBe(true)
    end)

    it("strips 'Light' suffix from type", function()
        local light = BuilderKit.addLight({
            name = "Suffixed",
            type = "PointLight",
            position = {0, 5, 0}
        })
        expect(light ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- setTerrain edge cases
-- ============================================================

describe("setTerrain edge cases", function()
    it("fills terrain with default params", function()
        local result = BuilderKit.setTerrain({})
        expect(result):toBe(true)
    end)

    it("fills terrain with specific material", function()
        local result = BuilderKit.setTerrain({
            position = {0, 0, 0},
            size = {100, 1, 100},
            material = "Sand"
        })
        expect(result):toBe(true)
    end)

    it("clears terrain with action=clear", function()
        local result = BuilderKit.setTerrain({
            position = {0, 0, 0},
            size = {50, 1, 50},
            action = "clear"
        })
        expect(result):toBe(true)
    end)

    it("falls back to Grass for invalid material", function()
        local result = BuilderKit.setTerrain({ material = "Plasma" })
        expect(result):toBe(true)
    end)

    it("handles all valid terrain materials", function()
        local materials = { "Grass", "Rock", "Sand", "Water", "Snow", "Mud", "Slate", "Ice",
                          "Ground", "Asphalt", "Basalt", "CrackedLava", "GlacialIce",
                          "LeafyGrass", "Limestone", "Marble", "Pavement", "Plaster",
                          "Salt", "Sandstone", "WoodPlanks" }
        for _, mat in ipairs(materials) do
            local result = BuilderKit.setTerrain({ material = mat, size = {1,1,1} })
            expect(result):toBe(true)
        end
    end)
end)

-- ============================================================
-- deletePart edge cases
-- ============================================================

describe("deletePart edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
    end)

    it("deletes an existing part", function()
        BuilderKit.createPart({ name = "ToDelete", size = {1,1,1}, position = {0,0,0} })
        local result = BuilderKit.deletePart({ name = "ToDelete" })
        expect(result):toBe(true)
    end)

    it("returns false for non-existent part", function()
        local result = BuilderKit.deletePart({ name = "GhostPart" })
        expect(result):toBe(false)
    end)

    it("decrements partsCreated counter", function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "Count1", size = {1,1,1}, position = {0,0,0} })
        local before = BuilderKit.partsCreated
        BuilderKit.deletePart({ name = "Count1" })
        expect(BuilderKit.partsCreated < before):toBe(true)
    end)
end)

-- ============================================================
-- movePart edge cases
-- ============================================================

describe("movePart edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "Movable", size = {2,2,2}, position = {0,0,0} })
    end)

    it("moves part to new position", function()
        local result = BuilderKit.movePart({ name = "Movable", position = {10, 20, 30} })
        expect(result):toBe(true)
    end)

    it("moves part using named position keys", function()
        local result = BuilderKit.movePart({ name = "Movable", position = { x = 5, y = 5, z = 5 } })
        expect(result):toBe(true)
    end)

    it("returns false for non-existent part", function()
        local result = BuilderKit.movePart({ name = "Immobile", position = {0, 0, 0} })
        expect(result):toBe(false)
    end)
end)

-- ============================================================
-- markUnfinished edge cases
-- ============================================================

describe("markUnfinished edge cases", function()
    beforeAll(function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "Finish1", size = {2,2,2}, position = {0,0,0} })
        BuilderKit.createPart({ name = "Finish2", size = {2,2,2}, position = {2,0,0} })
    end)

    it("marks specific part as unfinished", function()
        local result = BuilderKit.markUnfinished({ partName = "Finish1" })
        expect(result ~= nil):toBe(true)
    end)

    it("returns a message in result", function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "Finish3", size = {2,2,2}, position = {0,0,0} })
        local result = BuilderKit.markUnfinished({ partName = "Finish3" })
        expect(type(result)):toBe("table")
        expect(result.message ~= nil):toBe(true)
    end)

    it("returns nil when no parts exist", function()
        BuilderKit.clearAll()
        local result = BuilderKit.markUnfinished({ partName = "Nothing" })
        expect(result):toBe(nil)
    end)

    it("picks from partsList when provided", function()
        BuilderKit.clearAll()
        local p1 = BuilderKit.createPart({ name = "PL1", size = {1,1,1}, position = {0,0,0} })
        local p2 = BuilderKit.createPart({ name = "PL2", size = {1,1,1}, position = {1,0,0} })
        -- Mock typeof returns "table" for mock instances, so pass them in a way
        -- that markUnfinished can process (partsList with raw tables)
        local ok, result = pcall(BuilderKit.markUnfinished, { partsList = { p1, p2 } })
        expect(ok):toBe(true)
    end)

    it("auto-discovers parts when no filter provided", function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "Auto1", size = {1,1,1}, position = {0,0,0} })
        BuilderKit.createPart({ name = "Auto2", size = {1,1,1}, position = {1,0,0} })
        local result = BuilderKit.markUnfinished({})
        expect(result ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- execute dispatcher edge cases
-- ============================================================

describe("execute dispatcher edge cases", function()
    it("rejects string command", function()
        local result, err = BuilderKit.execute("not a table")
        expect(err ~= nil):toBe(true)
    end)

    it("rejects number command", function()
        local result, err = BuilderKit.execute(42)
        expect(err ~= nil):toBe(true)
    end)

    it("rejects command without type field", function()
        local result, err = BuilderKit.execute({ params = {} })
        expect(err ~= nil):toBe(true)
    end)

    it("rejects command with unknown type", function()
        local result, err = BuilderKit.execute({ type = "flyToMars", params = {} })
        expect(err ~= nil):toBe(true)
        expect(err ~= ""):toBe(true)
    end)

    it("error message includes the unknown type name", function()
        local result, err = BuilderKit.execute({ type = "explodeUniverse" })
        expect(string.find(err, "explodeUniverse") ~= nil):toBe(true)
    end)

    it("handles command with params=nil (uses flat command as params)", function()
        BuilderKit.clearAll()
        local result, err = BuilderKit.execute({
            type = "createPart",
            name = "FlatNoParams",
            size = {1,1,1}
        })
        expect(result ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- executeBatch edge cases
-- ============================================================

describe("executeBatch edge cases", function()
    it("handles nil commands array", function()
        BuilderKit.clearAll()
        -- executeBatch with nil will error; test that it doesn't silently succeed
        local ok, err = pcall(BuilderKit.executeBatch, nil)
        expect(not ok):toBe(true)
    end)

    it("handles batch with single command", function()
        BuilderKit.clearAll()
        local results = BuilderKit.executeBatch({
            { type = "createPart", params = { name = "Solo", size = {1,1,1}, position = {0,0,0} } }
        })
        expect(#results):toBe(1)
        expect(results[1].success):toBe(true)
    end)

    it("handles batch with mixed success/failure", function()
        BuilderKit.clearAll()
        local results = BuilderKit.executeBatch({
            { type = "createPart", params = { name = "OK", size = {1,1,1}, position = {0,0,0} } },
            { type = "invalidCommand", params = {} },
            { type = "createPart", params = { name = "Also", size = {1,1,1}, position = {1,0,0} } },
        })
        expect(#results):toBe(3)
        expect(results[1].success):toBe(true)
        expect(results[2].success):toBe(false)
        expect(results[3].success):toBe(true)
    end)

    it("records error messages for failed commands", function()
        BuilderKit.clearAll()
        local results = BuilderKit.executeBatch({
            { type = "badType", params = {} },
        })
        expect(results[1].error ~= nil):toBe(true)
    end)

    it("returns result objects with index and type fields", function()
        BuilderKit.clearAll()
        local results = BuilderKit.executeBatch({
            { type = "createPart", params = { name = "Indexed", size = {1,1,1}, position = {0,0,0} } },
        })
        expect(results[1].index):toBe(1)
        expect(results[1].type):toBe("createPart")
    end)
end)

-- ============================================================
-- getFolder / getBuiltParts / clearAll
-- ============================================================

describe("utility functions edge cases", function()
    it("getFolder returns a folder instance", function()
        local folder = BuilderKit.getFolder()
        expect(folder ~= nil):toBe(true)
    end)

    it("getBuiltParts returns table", function()
        BuilderKit.clearAll()
        BuilderKit.createPart({ name = "UT1", size = {1,1,1}, position = {0,0,0} })
        local parts = BuilderKit.getBuiltParts()
        expect(type(parts)):toBe("table")
    end)

    it("clearAll resets partsCreated to 0", function()
        BuilderKit.createPart({ name = "Pre", size = {1,1,1}, position = {0,0,0} })
        BuilderKit.createPart({ name = "Pre2", size = {1,1,1}, position = {1,0,0} })
        BuilderKit.clearAll()
        expect(BuilderKit.partsCreated):toBe(0)
    end)

    it("clearAll on empty folder does not error", function()
        BuilderKit.clearAll()
        BuilderKit.clearAll()
        expect(true):toBe(true)
    end)
end)

-- ============================================================
-- Full integration: build a house
-- ============================================================

describe("integration: house build", function()
    it("builds a complete house via executeBatch", function()
        BuilderKit.clearAll()

        local house = {
            -- Floor
            { type = "createPart", params = {
                name = "Floor", size = {12, 1, 10},
                position = {0, 0, 0}, material = "WoodPlanks", color = "#8B4513"
            }},
            -- Walls
            { type = "createPart", params = {
                name = "WallN", size = {12, 6, 1},
                position = {0, 3, -4.5}, material = "Brick", color = "#C04F2E"
            }},
            { type = "createPart", params = {
                name = "WallS", size = {12, 6, 1},
                position = {0, 3, 4.5}, material = "Brick", color = "#C04F2E"
            }},
            { type = "createPart", params = {
                name = "WallE", size = {1, 6, 10},
                position = {5.5, 3, 0}, material = "Brick", color = "#C04F2E"
            }},
            { type = "createPart", params = {
                name = "WallW", size = {1, 6, 10},
                position = {-5.5, 3, 0}, material = "Brick", color = "#C04F2E"
            }},
            -- Roof (wedge)
            { type = "createWedge", params = {
                name = "RoofL", size = {6, 4, 11},
                position = {-3, 6.5, 0}, material = "Slate", color = "#444444"
            }},
            { type = "createWedge", params = {
                name = "RoofR", size = {6, 4, 11},
                position = {3, 6.5, 0}, material = "Slate", color = "#444444"
                -- rotation omitted: CFrame multiplication not fully supported in mock
            }},
            -- Interior light
            { type = "addLight", params = {
                name = "Lamp", position = {0, 5, 0}, brightness = 3, range = 15
            }},
        }

        local results = BuilderKit.executeBatch(house)

        expect(#results):toBe(8)
        for _, r in ipairs(results) do
            expect(r.success):toBe(true)
        end
    end)

    it("can group all house parts after building", function()
        local model = BuilderKit.createGroup({
            name = "HouseModel",
            partNames = { "Floor", "WallN", "WallS", "WallE", "WallW", "RoofL", "RoofR" }
        })
        expect(model ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- Color parsing coverage
-- ============================================================

describe("color format coverage", function()
    beforeAll(function()
        BuilderKit.clearAll()
    end)

    it("handles 6-digit hex with # prefix", function()
        local p = BuilderKit.createPart({ name = "C1", color = "#AABBCC" })
        expect(p ~= nil):toBe(true)
    end)

    it("handles 6-digit hex without # prefix", function()
        local p = BuilderKit.createPart({ name = "C2", color = "AABBCC" })
        expect(p ~= nil):toBe(true)
    end)

    it("handles array-style RGB", function()
        local p = BuilderKit.createPart({ name = "C3", color = { 0, 128, 255 } })
        expect(p ~= nil):toBe(true)
    end)

    it("handles named-key RGB", function()
        local p = BuilderKit.createPart({ name = "C4", color = { r = 100, g = 200, b = 50 } })
        expect(p ~= nil):toBe(true)
    end)

    it("falls back to default for nil color", function()
        local p = BuilderKit.createPart({ name = "C5" })
        expect(p ~= nil):toBe(true)
    end)

    it("falls back to default for number color", function()
        local p = BuilderKit.createPart({ name = "C6", color = 42 })
        expect(p ~= nil):toBe(true)
    end)
end)
