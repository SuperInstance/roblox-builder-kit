-- examples/custom_commands.lua
-- Adding 5 new build commands to BuilderKit.
-- Place in StarterPlayerScripts (LocalScript) or ServerScript.
--
-- BuilderKit's command map is extensible. This example adds 5 custom
-- commands that can be called via execute() or executeBatch():
--   1. createStairs — procedural staircase
--   2. createArch — decorative archway
--   3. createPlatform — floating platform with support beams
--   4. addFire — lit campfire with light + particles
--   5. createSign — readable sign with text surface
--
-- Each command returns the created instance(s) and integrates with
-- BuilderKit's batch animation system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local BuilderKit = require(ReplicatedStorage:WaitForChild("BuilderKit"))

-- ============================================================
--  Custom Command 1: createStairs
--  Creates a procedural staircase from bottom to top.
-- ============================================================

local function createStairs(params)
    local folder = BuilderKit.getFolder()
    local steps = params.steps or 10
    local stepHeight = params.stepHeight or 1
    local stepWidth = params.stepWidth or 4
    local stepDepth = params.stepDepth or 1
    local startPos = Vector3.new(
        (params.position and params.position.x) or 0,
        (params.position and params.position.y) or 0,
        (params.position and params.position.z) or 0
    )
    local material = Enum.Material[params.material or "WoodPlanks"]
    local color = Color3.fromRGB(
        params.color and (params.color[1] or 140) or 140,
        params.color and (params.color[2] or 100) or 100,
        params.color and (params.color[3] or 60) or 60
    )

    local createdParts = {}

    for i = 1, steps do
        local step = Instance.new("Part")
        step.Name = (params.name or "Stairs") .. "_Step" .. i
        step.Size = Vector3.new(stepWidth, stepHeight, stepDepth * i)  -- each step extends further
        step.Position = startPos + Vector3.new(0, (i - 1) * stepHeight, stepDepth * (i - 1) / 2)
        step.Material = material
        step.Color = color
        step.Anchored = true
        step.Parent = folder
        CollectionService:AddTag(step, "BuilderKitBuilt")
        BuilderKit.partsCreated += 1
        table.insert(createdParts, step)
    end

    -- Group them
    local model = Instance.new("Model")
    model.Name = params.name or "Stairs"
    model.Parent = folder
    for _, p in ipairs(createdParts) do
        p.Parent = model
    end
    if createdParts[1] then
        model.PrimaryPart = createdParts[1]
    end

    return model
end

-- ============================================================
--  Custom Command 2: createArch
--  Creates a decorative archway from 3 parts (left post, right post, lintel).
-- ============================================================

local function createArch(params)
    local folder = BuilderKit.getFolder()
    local width = params.width or 6
    local height = params.height or 5
    local thickness = params.thickness or 1
    local pos = Vector3.new(
        (params.position and params.position.x) or 0,
        (params.position and params.position.y) or 0,
        (params.position and params.position.z) or 0
    )
    local material = Enum.Material[params.material or "Stone"]
    local color = Color3.fromRGB(150, 140, 130)

    local leftPost = Instance.new("Part")
    leftPost.Name = (params.name or "Arch") .. "_LeftPost"
    leftPost.Size = Vector3.new(thickness, height, thickness)
    leftPost.Position = pos + Vector3.new(-width/2 + thickness/2, height/2, 0)
    leftPost.Material = material
    leftPost.Color = color
    leftPost.Anchored = true
    leftPost.Parent = folder
    CollectionService:AddTag(leftPost, "BuilderKitBuilt")

    local rightPost = leftPost:Clone()
    rightPost.Name = (params.name or "Arch") .. "_RightPost"
    rightPost.Position = pos + Vector3.new(width/2 - thickness/2, height/2, 0)
    rightPost.Parent = folder

    local lintel = Instance.new("Part")
    lintel.Name = (params.name or "Arch") .. "_Lintel"
    lintel.Size = Vector3.new(width, thickness, thickness)
    lintel.Position = pos + Vector3.new(0, height + thickness/2, 0)
    lintel.Material = material
    lintel.Color = color
    lintel.Anchored = true
    lintel.Parent = folder
    CollectionService:AddTag(lintel, "BuilderKitBuilt")

    BuilderKit.partsCreated += 3
    return { leftPost, rightPost, lintel }
end

-- ============================================================
--  Custom Command 3: createPlatform
--  Creates a floating platform with support pillars at each corner.
-- ============================================================

local function createPlatform(params)
    local folder = BuilderKit.getFolder()
    local size = params.size or { x = 12, y = 0.5, z = 12 }
    local pillarDepth = params.pillarDepth or 8
    local pos = Vector3.new(
        (params.position and params.position.x) or 0,
        (params.position and params.position.y) or 10,
        (params.position and params.position.z) or 0
    )

    local platSize = Vector3.new(size.x or 12, size.y or 0.5, size.z or 12)
    local platform = BuilderKit.createPart({
        name = (params.name or "Platform") .. "_Top",
        position = { x = pos.X, y = pos.Y, z = pos.Z },
        size = { x = platSize.X, y = platSize.Y, z = platSize.Z },
        material = params.material or "SmoothPlastic",
        color = params.color or { 100, 150, 200 },
    })

    -- Support pillars at 4 corners
    local pillars = {}
    local halfW, halfD = platSize.X / 2 - 0.5, platSize.Z / 2 - 0.5
    for _, corner in ipairs({ {1,1}, {1,-1}, {-1,1}, {-1,-1} }) do
        local pillar = BuilderKit.createPart({
            name = (params.name or "Platform") .. "_Pillar",
            position = {
                x = pos.X + corner[1] * halfW,
                y = pos.Y - pillarDepth / 2,
                z = pos.Z + corner[2] * halfD,
            },
            size = { x = 1, y = pillarDepth, z = 1 },
            material = "Wood",
            color = { 100, 70, 40 },
        })
        table.insert(pillars, pillar)
    end

    return platform
end

-- ============================================================
--  Custom Command 4: addFire
--  Creates a campfire: stone ring + neon fire core + light + particles.
-- ============================================================

local function addFire(params)
    local folder = BuilderKit.getFolder()
    local pos = Vector3.new(
        (params.position and params.position.x) or 0,
        (params.position and params.position.y) or 0,
        (params.position and params.position.z) or 0
    )

    local name = params.name or "Campfire"

    -- Stone ring
    local stones = {}
    for i = 1, 6 do
        local angle = (i - 1) * math.pi / 3
        local stone = Instance.new("Part")
        stone.Name = name .. "_Stone" .. i
        stone.Size = Vector3.new(0.8, 0.5, 0.8)
        stone.Position = pos + Vector3.new(math.cos(angle) * 0.8, 0.25, math.sin(angle) * 0.8)
        stone.Material = Enum.Material.Rock
        stone.Color = Color3.fromRGB(70, 65, 60)
        stone.Anchored = true
        stone.Parent = folder
        CollectionService:AddTag(stone, "BuilderKitBuilt")
        table.insert(stones, stone)
    end

    -- Fire core (neon orange)
    local fire = Instance.new("Part")
    fire.Name = name .. "_Fire"
    fire.Size = Vector3.new(0.6, 1.0, 0.6)
    fire.Position = pos + Vector3.new(0, 0.5, 0)
    fire.Material = Enum.Material.Neon
    fire.Color = Color3.fromRGB(255, 100, 20)
    fire.Anchored = true
    fire.Parent = folder
    CollectionService:AddTag(fire, "BuilderKitBuilt")

    -- PointLight
    local light = Instance.new("PointLight")
    light.Name = name .. "_Light"
    light.Range = 16
    light.Brightness = 4
    light.Color = Color3.fromRGB(255, 140, 40)
    light.Parent = fire

    -- Particle emitter (fire effect)
    local attachment = Instance.new("Attachment")
    attachment.Parent = fire

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = name .. "_Particles"
    emitter.Texture = "rbxasset://textures/particles/fire_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 20)),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 2.0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    emitter.Lifetime = NumberRange.new(0.3, 0.8)
    emitter.Speed = NumberRange.new(1, 3)
    emitter.Rate = 20
    emitter.Parent = attachment

    BuilderKit.partsCreated += 7
    return fire
end

-- ============================================================
--  Custom Command 5: createSign
--  Creates a readable signpost with a text surface.
-- ============================================================

local function createSign(params)
    local folder = BuilderKit.getFolder()
    local pos = Vector3.new(
        (params.position and params.position.x) or 0,
        (params.position and params.position.y) or 0,
        (params.position and params.position.z) or 0
    )
    local name = params.name or "Sign"
    local text = params.text or ""

    -- Post
    local post = Instance.new("Part")
    post.Name = name .. "_Post"
    post.Size = Vector3.new(0.2, 4, 0.2)
    post.Position = pos + Vector3.new(0, 2, 0)
    post.Material = Enum.Material.Wood
    post.Color = Color3.fromRGB(80, 50, 30)
    post.Anchored = true
    post.Parent = folder
    CollectionService:AddTag(post, "BuilderKitBuilt")

    -- Sign board
    local board = Instance.new("Part")
    board.Name = name .. "_Board"
    board.Size = Vector3.new(3, 1.5, 0.1)
    board.Position = pos + Vector3.new(0, 3.5, 0)
    board.Material = Enum.Material.WoodPlanks
    board.Color = Color3.fromRGB(140, 100, 60)
    board.Anchored = true
    board.Parent = folder
    CollectionService:AddTag(board, "BuilderKitBuilt")

    -- Text surface
    if text and #text > 0 then
        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.Parent = board

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 20
        textLabel.TextColor3 = Color3.fromRGB(60, 40, 20)
        textLabel.Parent = surfaceGui
    end

    BuilderKit.partsCreated += 2
    return board
end

-- ============================================================
--  Register custom commands with BuilderKit
-- ============================================================

-- Access the internal command map and add our commands
-- (In a real project, you'd add these in the BuilderKit source,
-- or use a registration API. Here we patch the map directly.)

local commandMap = {
    createStairs   = createStairs,
    createArch     = createArch,
    createPlatform = createPlatform,
    addFire        = addFire,
    createSign     = createSign,
}

-- Monkey-patch BuilderKit.execute to handle new command types
local originalExecute = BuilderKit.execute
BuilderKit.execute = function(command)
    if type(command) ~= "table" then
        return originalExecute(command)
    end

    local cmdType = command.type
    local handler = commandMap[cmdType]

    if handler then
        local params = command.params or command
        local ok, result = pcall(handler, params)
        if not ok then
            warn(string.format("[CustomCommands] '%s' failed: %s", cmdType, tostring(result)))
            return nil, tostring(result)
        end
        return result, nil
    end

    -- Fall back to original execute for built-in commands
    return originalExecute(command)
end

print("[Custom Commands] Registered 5 new commands:")
print("  - createStairs: procedural staircase")
print("  - createArch: decorative archway")
print("  - createPlatform: floating platform with pillars")
print("  - addFire: campfire with light + particles")
print("  - createSign: readable signpost with text")

-- ============================================================
--  Demo: execute all 5 custom commands
-- ============================================================

task.wait(2)

-- Clear any previous builds
BuilderKit.clearAll()

print("\n[Custom Commands] Building demo scene...\n")

-- 1. Stairs going up a hill
BuilderKit.execute({
    type = "createStairs",
    params = {
        name = "Hillside_Stairs",
        position = { x = 0, y = 0, z = 0 },
        steps = 8,
        stepHeight = 1.5,
        stepWidth = 5,
        stepDepth = 1.5,
        material = "Cobblestone",
    }
})
print("✓ Created staircase")

-- 2. Archway at the top
BuilderKit.execute({
    type = "createArch",
    params = {
        name = "Gate_Arch",
        position = { x = 0, y = 12, z = 7 },
        width = 7,
        height = 6,
        material = "Marble",
    }
})
print("✓ Created archway")

-- 3. Platform beyond the arch
BuilderKit.execute({
    type = "createPlatform",
    params = {
        name = "Lookout_Platform",
        position = { x = 0, y = 14, z = 20 },
        size = { x = 14, y = 0.5, z = 14 },
        material = "SmoothPlastic",
        color = { 120, 100, 80 },
        pillarDepth = 6,
    }
})
print("✓ Created lookout platform")

-- 4. Campfire on the platform
BuilderKit.execute({
    type = "addFire",
    params = {
        name = "Lookout_Fire",
        position = { x = 0, y = 14.5, z = 20 },
    }
})
print("✓ Created campfire")

-- 5. Sign at the bottom
BuilderKit.execute({
    type = "createSign",
    params = {
        name = "Trail_Sign",
        position = { x = 0, y = 0, z = -3 },
        text = "↑ Lookout Point\n  8 steps",
    }
})
print("✓ Created trail sign")

print(string.format("\n[Custom Commands] Scene complete! %d parts created.", BuilderKit.partsCreated))
