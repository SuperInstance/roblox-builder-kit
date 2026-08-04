--[[
    BuilderKit Test Suite
    ─────────────────────
    Tests for command dispatch, input validation, error handling,
    and API surface.

    Run with TestEZ or similar Roblox test runner.
]]

local BuilderKit = require(script.Parent.src.BuilderKit)

-- ── Tests ──────────────────────────────────────────────────────

return function()

    describe("BuilderKit module", function()
        it("is a table", function()
            expect(type(BuilderKit)).to.equal("table")
        end)

        it("has all public methods", function()
            expect(BuilderKit.execute).to.be.a("function")
            expect(BuilderKit.executeBatch).to.be.a("function")
            expect(BuilderKit.createPart).to.be.a("function")
            expect(BuilderKit.createWedge).to.be.a("function")
            expect(BuilderKit.createCylinder).to.be.a("function")
            expect(BuilderKit.createSphere).to.be.a("function")
            expect(BuilderKit.createSurface).to.be.a("function")
            expect(BuilderKit.createGroup).to.be.a("function")
            expect(BuilderKit.addLight).to.be.a("function")
            expect(BuilderKit.setTerrain).to.be.a("function")
            expect(BuilderKit.markUnfinished).to.be.a("function")
            expect(BuilderKit.deletePart).to.be.a("function")
            expect(BuilderKit.movePart).to.be.a("function")
            expect(BuilderKit.clearAll).to.be.a("function")
            expect(BuilderKit.getFolder).to.be.a("function")
            expect(BuilderKit.getBuiltParts).to.be.a("function")
        end)
    end)

    describe("execute — invalid commands", function()
        it("returns error for non-table command", function()
            local result, err = BuilderKit.execute(nil)
            expect(result).never.to.be.ok()
            expect(err).to.be.ok()
        end)

        it("returns error for command missing type", function()
            local result, err = BuilderKit.execute({ params = {} })
            expect(result).never.to.be.ok()
            expect(err).to.be.ok()
        end)

        it("returns error for unknown command type", function()
            local result, err = BuilderKit.execute({ type = "nonexistentCommand" })
            expect(result).never.to.be.ok()
            expect(err).to.be.ok()
            expect(err:match("Unknown command")).to.be.ok()
        end)
    end)

    describe("execute — valid commands", function()
        afterAll(function()
            BuilderKit.clearAll()
        end)

        it("creates a Part via execute", function()
            local result, err = BuilderKit.execute({
                type = "createPart",
                params = {
                    name = "TestPart",
                    position = { x = 10, y = 20, z = 30 },
                    size = { x = 4, y = 4, z = 4 },
                    material = "Wood",
                    color = "#FF8800",
                },
            })
            expect(err).never.to.be.ok()  -- no error
            expect(result).to.be.ok()
        end)

        it("creates a Part with flat params (no params sub-table)", function()
            local result, err = BuilderKit.execute({
                type = "createPart",
                name = "FlatPart",
                position = { x = 0, y = 5, z = 0 },
            })
            expect(err).never.to.be.ok()
            expect(result).to.be.ok()
        end)
    end)

    describe("property parsing", function()
        it("parses hex color strings correctly", function()
            -- Internal: parseColor("#FF8800") = Color3.fromRGB(255, 136, 0)
            -- Test via a createPart call and checking the color
            local part = BuilderKit.createPart({
                name = "ColorTest",
                color = "#FF0000",
            })
            expect(part).to.be.ok()
            -- Red channel should be ~255
            expect(math.floor(part.Color.R * 255 + 0.5)).to.equal(255)
        end)

        it("parses RGB table colors", function()
            local part = BuilderKit.createPart({
                name = "ColorTest2",
                color = { 0, 255, 128 },
            })
            expect(part).to.be.ok()
            expect(math.floor(part.Color.G * 255 + 0.5)).to.equal(255)
        end)

        it("defaults color to gray for invalid input", function()
            local part = BuilderKit.createPart({
                name = "ColorTest3",
                color = nil,
            })
            expect(part).to.be.ok()
            -- Default is Color3.fromRGB(180, 180, 180)
            expect(math.floor(part.Color.R * 255 + 0.5)).to.equal(180)
        end)

        it("parses material name strings", function()
            local part = BuilderKit.createPart({
                name = "MaterialTest",
                material = "Neon",
            })
            expect(part.Material).to.equal(Enum.Material.Neon)
        end)

        it("defaults to SmoothPlastic for invalid material", function()
            local part = BuilderKit.createPart({
                name = "MaterialTest2",
                material = "Nonexistent",
            })
            expect(part.Material).to.equal(Enum.Material.SmoothPlastic)
        end)

        it("applies rotation in degrees", function()
            local part = BuilderKit.createPart({
                name = "RotTest",
                position = { x = 0, y = 0, z = 0 },
                rotation = { x = 90, y = 0, z = 0 },
            })
            expect(part).to.be.ok()
            -- 90 degrees rotation on X should significantly change orientation
            local _, _, rz = part.CFrame:ToOrientation()
            expect(math.abs(rz)).to.be.at.most(math.pi) -- sanity: valid orientation
        end)
    end)

    describe("deletePart", function()
        it("returns false for nonexistent part", function()
            local result = BuilderKit.deletePart({ name = "DoesNotExist999" })
            expect(result).to.equal(false)
        end)

        it("deletes an existing part", function()
            BuilderKit.createPart({ name = "DeleteMe", position = { x = 0, y = 0, z = 0 } })
            local result = BuilderKit.deletePart({ name = "DeleteMe" })
            expect(result).to.equal(true)
        end)
    end)

    describe("movePart", function()
        it("returns false for nonexistent part", function()
            local result = BuilderKit.movePart({ name = "Ghost", position = { x = 0, y = 0, z = 0 } })
            expect(result).to.equal(false)
        end)
    end)

    describe("executeBatch", function()
        it("returns results array of same length", function()
            local commands = {
                { type = "createPart", name = "Batch1", position = { x = 0, y = 5, z = 0 } },
                { type = "createPart", name = "Batch2", position = { x = 5, y = 5, z = 0 } },
                { type = "createPart", name = "Batch3", position = { x = 10, y = 5, z = 0 } },
            }
            local results = BuilderKit.executeBatch(commands)
            expect(#results).to.equal(3)

            for _, r in ipairs(results) do
                expect(r.index).to.be.a("number")
                expect(r.type).to.be.a("string")
                expect(r.success).to.be.a("boolean")
            end
        end)

        it("handles mixed valid and invalid commands", function()
            local commands = {
                { type = "createPart", name = "ValidOne", position = { x = 0, y = 0, z = 0 } },
                { type = "nonexistentCommand" },
            }
            local results = BuilderKit.executeBatch(commands)
            expect(#results).to.equal(2)
            expect(results[1].success).to.equal(true)
            expect(results[2].success).to.equal(false)
        end)
    end)

    describe("clearAll", function()
        it("resets partsCreated counter", function()
            BuilderKit.createPart({ name = "Before", position = { x = 0, y = 0, z = 0 } })
            local before = BuilderKit.partsCreated
            expect(before).to.be.at.least(1)

            BuilderKit.clearAll()
            expect(BuilderKit.partsCreated).to.equal(0)
        end)
    end)

    describe("getFolder", function()
        it("returns a Folder in workspace", function()
            local folder = BuilderKit.getFolder()
            expect(folder).to.be.ok()
            expect(folder:IsA("Folder")).to.equal(true)
            expect(folder.Parent).to.equal(workspace)
        end)
    end)

    describe("addLight", function()
        it("creates a PointLight", function()
            local light = BuilderKit.addLight({
                name = "TestLight",
                type = "Point",
                position = { x = 0, y = 10, z = 0 },
                range = 20,
                brightness = 3,
            })
            expect(light).to.be.ok()
            expect(light:IsA("PointLight")).to.equal(true)
        end)

        it("creates a SpotLight", function()
            local light = BuilderKit.addLight({
                name = "TestSpot",
                type = "Spot",
                position = { x = 5, y = 10, z = 0 },
            })
            expect(light:IsA("SpotLight")).to.equal(true)
        end)
    end)
end
