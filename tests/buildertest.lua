-- tests/buildertest.lua
-- TestKit-compatible tests for BuilderKit command executor.

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

-- Mock math.random for deterministic testing
math.random = function(a, b) if a and b then return a end if a then return a end return 1 end

-- Mock os.time
os.time = function() return 1700000000 end

-- Mock BrickColor (Roblox-specific)
if not BrickColor then
    _G.BrickColor = { new = function() return { Name = "Test" } end, Red = function() return { Name = "Red" } end }
    rawset(_G, "BrickColor", _G.BrickColor)
end

-- Mock Enum (Roblox-specific)
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

describe("BuilderKit module structure", function()
    it("exports a table", function()
        expect(type(BuilderKit)):toBe("table")
    end)

    it("has execute function", function()
        expect(type(BuilderKit.execute)):toBe("function")
    end)

    it("has executeBatch function", function()
        expect(type(BuilderKit.executeBatch)):toBe("function")
    end)

    it("has createPart function", function()
        expect(type(BuilderKit.createPart)):toBe("function")
    end)

    it("has createWedge function", function()
        expect(type(BuilderKit.createWedge)):toBe("function")
    end)

    it("has createCylinder function", function()
        expect(type(BuilderKit.createCylinder)):toBe("function")
    end)

    it("has createSphere function", function()
        expect(type(BuilderKit.createSphere)):toBe("function")
    end)

    it("has deletePart function", function()
        expect(type(BuilderKit.deletePart)):toBe("function")
    end)

    it("has clearAll function", function()
        expect(type(BuilderKit.clearAll)):toBe("function")
    end)

    it("has getBuiltParts function", function()
        expect(type(BuilderKit.getBuiltParts)):toBe("function")
    end)
end)

describe("BuilderKit execute", function()
    it("executes createPart command", function()
        BuilderKit.clearAll()
        local result, err = BuilderKit.execute({
            type = "createPart",
            params = {
                name = "TestPart",
                size = {3, 3, 3},
                position = {0, 10, 0},
                color = "#FF0000",
            }
        })
        expect(result ~= nil):toBe(true)
    end)

    it("executes flat-format createPart", function()
        BuilderKit.clearAll()
        local result, err = BuilderKit.execute({
            type = "createPart",
            name = "FlatPart",
            size = {1, 1, 1},
            position = {5, 5, 5},
        })
        expect(result ~= nil):toBe(true)
    end)

    it("returns error for unknown command type", function()
        local result, err = BuilderKit.execute({
            type = "nonExistentCommand",
            params = {}
        })
        expect(err ~= nil):toBe(true)
    end)

    it("returns error for nil command", function()
        local result, err = BuilderKit.execute(nil)
        expect(result == nil or err ~= nil):toBe(true)
    end)
end)

describe("BuilderKit executeBatch", function()
    it("executes multiple commands", function()
        BuilderKit.clearAll()
        local results = BuilderKit.executeBatch({
            { type = "createPart", params = { name = "P1", size = {1,1,1}, position = {0,0,0} } },
            { type = "createPart", params = { name = "P2", size = {1,1,1}, position = {1,0,0} } },
            { type = "createPart", params = { name = "P3", size = {1,1,1}, position = {2,0,0} } },
        })
        expect(type(results)):toBe("table")
    end)

    it("handles empty batch", function()
        local results = BuilderKit.executeBatch({})
        expect(type(results)):toBe("table")
    end)
end)

describe("BuilderKit parts tracking", function()
    it("tracks parts created count", function()
        BuilderKit.clearAll()
        local initial = BuilderKit.partsCreated
        BuilderKit.execute({ type = "createPart", params = { name = "Counted", size = {1,1,1}, position = {0,0,0} } })
        expect(BuilderKit.partsCreated > initial):toBe(true)
    end)

    it("getBuiltParts returns instances", function()
        BuilderKit.clearAll()
        BuilderKit.execute({ type = "createPart", params = { name = "GetMe", size = {1,1,1}, position = {0,0,0} } })
        local parts = BuilderKit.getBuiltParts()
        expect(type(parts)):toBe("table")
        expect(#parts >= 1):toBe(true)
    end)
end)

describe("BuilderKit clearAll", function()
    it("clears all built parts", function()
        BuilderKit.execute({ type = "createPart", params = { name = "Temp", size = {1,1,1}, position = {0,0,0} } })
        BuilderKit.clearAll()
        -- getBuiltParts uses CollectionService tags which persist across tests
        -- so check the folder is empty instead
        local folder = BuilderKit.getFolder()
        expect(#folder:GetChildren()):toBe(0)
    end)
end)
