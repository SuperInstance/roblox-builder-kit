--[[
    BuilderKit — Standalone Roblox Building Command Executor
    Version: 1.0.0
    License: MIT

    A self-contained module for programmatically constructing Roblox builds
    from structured command tables. Designed for AI-driven generation,
    procedural building, and batch construction with optional animation hooks.

    Supports: createPart, createWedge, createCylinder, createSphere,
              createSurface, createGroup, addLight, setTerrain,
              markUnfinished, deletePart, movePart, executeBatch

    Usage:
        local BuilderKit = require(path.to.BuilderKit)
        BuilderKit.execute({ type = "createPart", params = { ... } })
        BuilderKit.executeBatch({ { type = "createPart", ... }, ... })

    Animation Integration:
        If a BuildAnimator module is found as a sibling, BuilderKit will
        call it for staggered part reveals during executeBatch(). If no
        BuildAnimator is present, parts appear immediately — no hard dependency.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Terrain = workspace.Terrain

-- ── Configuration ──────────────────────────────────────────────

-- Tag applied to all BuilderKit-created parts so external systems
-- (weather, damage, interaction) can discover them.
local BUILT_TAG = "BuilderKitBuilt"

-- Container folder name in workspace for all BuilderKit instances.
local FOLDER_NAME = "BuilderKitBuilds"

-- Soft dependency: BuildAnimator (optional sibling module)
-- If present, batch builds get staggered cinematic reveals.
local BuildAnimator
do
    local ok, mod = pcall(function()
        return require(script.Parent:FindFirstChild("BuildAnimator"))
    end)
    if ok then BuildAnimator = mod end
end

-- ── Allowed terrain materials ──────────────────────────────────

local TERRAIN_MATERIALS = {
    Grass = true, Rock = true, Sand = true, Water = true, Snow = true,
    Mud = true, Slate = true, Ice = true, Ground = true, Asphalt = true,
    Basalt = true, CrackedLava = true, GlacialIce = true, LeafyGrass = true,
    Limestone = true, Marble = true, Pavement = true, Plaster = true,
    Salt = true, Sandstone = true, WoodPlanks = true,
}

-- ── Module Table ───────────────────────────────────────────────

local BuilderKit = {}

-- Tracks total parts created by this module instance.
BuilderKit.partsCreated = 0

-- ── Internal State ─────────────────────────────────────────────

local folderRef: Folder? = nil

-- Batch tracking
local batchCreatedParts: { BasePart } = {}
local inBatchMode = false

-- ── Helpers ────────────────────────────────────────────────────

local function ensureFolder(): Folder
    if not folderRef then
        folderRef = workspace:FindFirstChild(FOLDER_NAME)
        if not folderRef then
            folderRef = Instance.new("Folder")
            folderRef.Name = FOLDER_NAME
            folderRef.Parent = workspace
        end
    end
    return folderRef
end

local function findPartByName(name: string): Instance?
    local folder = ensureFolder()
    local part = folder:FindFirstChild(name)
    if part then return part end
    return workspace:FindFirstChild(name, true)
end

local function parseVector3(pos: { [string]: any }): Vector3
    return Vector3.new(
        pos.x or pos[1] or 0,
        pos.y or pos[2] or 0,
        pos.z or pos[3] or 0
    )
end

local function parseColor(color: any): Color3
    if typeof(color) == "Color3" then return color end
    if type(color) == "string" then
        local hex = color:gsub("#", "")
        local r = tonumber(hex:sub(1, 2), 16) or 255
        local g = tonumber(hex:sub(3, 4), 16) or 255
        local b = tonumber(hex:sub(5, 6), 16) or 255
        return Color3.fromRGB(r, g, b)
    end
    if type(color) == "table" then
        return Color3.fromRGB(
            color[1] or color.r or 255,
            color[2] or color.g or 255,
            color[3] or color.b or 255
        )
    end
    return Color3.fromRGB(180, 180, 180)
end

local function parseMaterial(mat: string?): Enum.Material
    if not mat then return Enum.Material.SmoothPlastic end
    local ok, result = pcall(function()
        return Enum.Material[mat]
    end)
    return ok and result or Enum.Material.SmoothPlastic
end

--[[
    Apply common BasePart properties. Used by all create* functions.
    Returns the part with all properties set and batch tracking applied.
]]
local function prepareBasePart(part: BasePart, params: { [string]: any }): BasePart
    part.Name = params.name or "BuilderKitPart"

    local targetPosition = parseVector3(params.position or { x = 0, y = 5, z = 0 })
    local targetSize = parseVector3(params.size or { x = 4, y = 1, z = 4 })
    local targetTransparency = params.transparency or 0

    part.Size = targetSize
    part.Material = parseMaterial(params.material)
    part.Color = parseColor(params.color)
    part.Anchored = if params.anchored ~= nil then params.anchored else true
    part.Transparency = targetTransparency

    -- Rotation in degrees {x, y, z}
    local rotation = params.rotation
    if type(rotation) == "table" then
        part.CFrame = CFrame.new(targetPosition)
            * CFrame.Angles(
                math.rad(rotation.x or rotation[1] or 0),
                math.rad(rotation.y or rotation[2] or 0),
                math.rad(rotation.z or rotation[3] or 0)
            )
    else
        part.Position = targetPosition
    end

    if params.canCollide ~= nil then
        part.CanCollide = params.canCollide
    end
    if params.reflectance ~= nil then
        part.Reflectance = params.reflectance
    end

    -- Pre-animation state: invisible and tiny for batch reveal
    if inBatchMode then
        part.Transparency = 1
        part.Size = Vector3.new(0.1, 0.1, 0.1)
    end

    BuilderKit.partsCreated += 1

    -- Tag for external system discovery
    CollectionService:AddTag(part, BUILT_TAG)

    -- Metadata attributes
    part:SetAttribute("BuildMaterial", params.material or "SmoothPlastic")
    part:SetAttribute("BuildTimestamp", os.time())

    if inBatchMode then
        part:SetAttribute("BA_TargetSizeX", targetSize.X)
        part:SetAttribute("BA_TargetSizeY", targetSize.Y)
        part:SetAttribute("BA_TargetSizeZ", targetSize.Z)
        part:SetAttribute("BA_TargetTransparency", targetTransparency)
        table.insert(batchCreatedParts, part)
    end

    return part
end

-- ── Command Implementations ────────────────────────────────────

--[[
    createPart — Create a new Part in the workspace.

    Parameters:
      - name        (string)        Instance name. Default "BuilderKitPart".
      - position    {x,y,z}         World position. Default {0,5,0}.
      - size        {x,y,z}         Part dimensions. Default {4,1,4}.
      - material    (string)        Enum.Material name. Default "SmoothPlastic".
      - color       (string|table)  Hex "#RRGGBB" or {r,g,b} 0-255.
      - shape       (string)        Optional: "Block", "Ball", "Cylinder".
      - anchored    (bool)          Default true.
      - transparency(number)        0–1. Default 0.
      - rotation    {x,y,z}         Rotation in degrees.
      - canCollide  (bool)          Default true.
      - reflectance (number)        0–1.

    Returns: BasePart
]]
function BuilderKit.createPart(params: { [string]: any }): BasePart
    local folder = ensureFolder()
    local part = Instance.new("Part")
    prepareBasePart(part, params)

    if params.shape then
        pcall(function()
            part.Shape = Enum.PartType[params.shape]
        end)
    end

    part.Parent = folder
    return part
end

--[[
    createWedge — Create a WedgePart for ramps, roofs, and angled surfaces.

    Same parameters as createPart (minus shape).
    Returns: WedgePart
]]
function BuilderKit.createWedge(params: { [string]: any }): WedgePart
    local folder = ensureFolder()
    local part = Instance.new("WedgePart")
    prepareBasePart(part, params)
    part.Parent = folder
    return part
end

--[[
    createCylinder — Create a cylindrical part for columns, pipes, and towers.

    Uses Part.Shape = Cylinder. Size X is the diameter axis.
    Same parameters as createPart.
    Returns: Part
]]
function BuilderKit.createCylinder(params: { [string]: any }): Part
    local folder = ensureFolder()
    local part = Instance.new("Part")
    pcall(function()
        part.Shape = Enum.PartType.Cylinder
    end)
    prepareBasePart(part, params)
    part.Parent = folder
    return part
end

--[[
    createSphere — Create a ball-shaped part for decorative elements.

    Uses Part.Shape = Ball.
    Same parameters as createPart.
    Returns: Part
]]
function BuilderKit.createSphere(params: { [string]: any }): Part
    local folder = ensureFolder()
    local part = Instance.new("Part")
    pcall(function()
        part.Shape = Enum.PartType.Ball
    end)
    prepareBasePart(part, params)
    part.Parent = folder
    return part
end

--[[
    createSurface — Apply material/color/texture to an existing part.

    Parameters:
      - name              (string)  Target part name.
      - material          (string)  New Enum.Material name.
      - color             (any)     New color (hex or {r,g,b}).
      - transparency      (number)  0–1.
      - texture           (string)  Optional rbxassetid:// for Decal.
      - face              (string)  Face for Decal: Front, Back, Top, etc.
      - decalName         (string)  Name for the Decal instance.
      - decalColor        (any)     Color for the Decal.
      - decalTransparency (number)  Decal transparency 0–1.

    Returns: BasePart (the modified part) or nil if not found.
]]
function BuilderKit.createSurface(params: { [string]: any }): BasePart?
    local part = findPartByName(params.name)
    if not part or not part:IsA("BasePart") then
        warn(string.format("[BuilderKit] createSurface: '%s' not found or not a BasePart", tostring(params.name)))
        return nil
    end

    if params.material then
        part.Material = parseMaterial(params.material)
    end
    if params.color then
        part.Color = parseColor(params.color)
    end
    if params.transparency ~= nil then
        part.Transparency = params.transparency
    end

    if params.texture then
        local face = params.face or "Front"
        local normalId = Enum.NormalId[face] or Enum.NormalId.Front
        local decal = Instance.new("Decal")
        decal.Name = params.decalName or "BuilderKitSurfaceDecal"
        decal.Texture = params.texture
        decal.Face = normalId
        decal.Color3 = if params.decalColor then parseColor(params.decalColor) else Color3.new(1, 1, 1)
        decal.Transparency = params.decalTransparency or 0
        decal.Parent = part
    end

    return part
end

--[[
    createGroup — Parent multiple existing parts under a Model.

    Parameters:
      - name      (string)   Model name.
      - partNames ({string}) Array of part names to include.

    Returns: Model
]]
function BuilderKit.createGroup(params: { [string]: any }): Model
    local folder = ensureFolder()
    local model = Instance.new("Model")
    model.Name = params.name or "BuilderKitGroup"
    model.Parent = folder

    for _, partName in ipairs(params.partNames or {}) do
        local part = findPartByName(partName)
        if part then
            part.Parent = model
        else
            warn(string.format("[BuilderKit] createGroup: part '%s' not found", tostring(partName)))
        end
    end

    local primary = model:FindFirstChildWhichIsA("BasePart")
    if primary then
        model.PrimaryPart = primary
    end

    return model
end

--[[
    addLight — Add a light source (Point, Spot, or Surface).

    Parameters:
      - name       (string)  Light instance name.
      - type       (string)  "Point", "Spot", or "Surface". Default "Point".
      - position   {x,y,z}   If set, creates an invisible carrier part.
      - range      (number)  Light range in studs. Default 16.
      - brightness (number)  Light brightness. Default 2.
      - color      (any)     Light color.
      - parent     (string)  Name of existing part to attach to.

    Returns: Light instance
]]
function BuilderKit.addLight(params: { [string]: any }): Instance
    local folder = ensureFolder()
    local lightType = (params.type or params.lightType or "Point"):gsub("Light$", "")

    local parent: Instance
    if params.parent then
        parent = findPartByName(params.parent) or folder
    elseif params.position then
        local carrier = Instance.new("Part")
        carrier.Name = (params.name or "Light") .. "Carrier"
        carrier.Size = Vector3.new(0.5, 0.5, 0.5)
        carrier.Position = parseVector3(params.position)
        carrier.Transparency = 1
        carrier.CanCollide = false
        carrier.Anchored = true
        carrier.Parent = folder
        parent = carrier
    else
        parent = folder
    end

    local light
    if lightType == "Spot" then
        light = Instance.new("SpotLight")
    elseif lightType == "Surface" then
        light = Instance.new("SurfaceLight")
    else
        light = Instance.new("PointLight")
    end

    light.Name = params.name or "BuilderKitLight"
    light.Range = params.range or 16
    light.Brightness = params.brightness or 2
    light.Color = parseColor(params.color or "#FFFFFF")
    light.Parent = parent

    return light
end

--[[
    setTerrain — Fill or clear terrain using FillBlock.

    Parameters:
      - position {x,y,z}  Center of the terrain fill.
      - size    {x,y,z}   Dimensions of the fill volume.
      - material (string)  Terrain material name (see TERRAIN_MATERIALS).
      - action   (string)  "fill" or "clear". Default "fill".

    Returns: boolean (true on success)
]]
function BuilderKit.setTerrain(params: { [string]: any }): boolean
    local size = parseVector3(params.size or { x = 16, y = 1, z = 16 })
    local center = parseVector3(params.position or { x = 0, y = 0, z = 0 })
    local action = params.action or "fill"
    local matName = params.material or "Grass"

    local material: Enum.Material
    if action == "clear" then
        material = Enum.Material.Air
    else
        if not TERRAIN_MATERIALS[matName] then
            warn(string.format("[BuilderKit] setTerrain: '%s' is not a valid terrain material, defaulting to Grass", matName))
            matName = "Grass"
        end
        material = parseMaterial(matName)
    end

    Terrain:FillBlock(CFrame.new(center), size, material)
    return true
end

--[[
    markUnfinished — Highlight a part as a deliberate gap for the player to complete.

    Sets semi-transparency, adds a SelectionBox highlight, and spawns
    a gentle particle shimmer so the unfinished piece draws attention.

    Parameters:
      - partName  (string)   Specific part to mark. If omitted, picks randomly.
      - partsList ({BasePart}) Array of parts to choose from.

    Returns: table with message string, or nil if no parts found.
]]
function BuilderKit.markUnfinished(params: { [string]: any }): { [string]: any }?
    local candidates: { BasePart } = {}

    if params.partName then
        local part = findPartByName(params.partName)
        if part and part:IsA("BasePart") then
            table.insert(candidates, part)
        end
    elseif type(params.partsList) == "table" and #params.partsList > 0 then
        for _, p in ipairs(params.partsList) do
            if typeof(p) == "Instance" and p:IsA("BasePart") then
                table.insert(candidates, p)
            end
        end
    else
        local folder = ensureFolder()
        for _, child in ipairs(folder:GetDescendants()) do
            if child:IsA("BasePart") then
                table.insert(candidates, child)
            end
        end
    end

    if #candidates == 0 then
        warn("[BuilderKit] markUnfinished: no build parts found")
        return nil
    end

    -- Prefer unmarked parts
    local part: BasePart
    local unmarked: { BasePart } = {}
    for _, p in ipairs(candidates) do
        if not p:GetAttribute("BuilderKit_Unfinished") then
            table.insert(unmarked, p)
        end
    end
    if #unmarked > 0 then
        part = unmarked[math.random(1, #unmarked)]
    else
        part = candidates[math.random(1, #candidates)]
    end

    part:SetAttribute("BuilderKit_Unfinished", true)
    part:SetAttribute("BuilderKit_OriginalTransparency", part.Transparency)
    CollectionService:AddTag(part, "BuilderKitUnfinished")
    part.Transparency = 0.5

    local highlight = Instance.new("SelectionBox")
    highlight.Name = "BuilderKitUnfinishedHighlight"
    highlight.Color3 = Color3.fromRGB(255, 180, 60)
    highlight.LineThickness = 0.05
    highlight.Adornee = part
    highlight.Parent = part

    local attachment = Instance.new("Attachment")
    attachment.Name = "UnfinishedAttachment"
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "BuilderKitUnfinishedParticles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 8
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Speed = NumberRange.new(0.2, 0.6)
    emitter.Size = NumberSequence.new(0.3, 0.8)
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 180, 60))
    emitter.Transparency = NumberSequence.new(0.3, 0.7)
    emitter.Parent = attachment

    local message = string.format("'%s' is left unfinished — your turn to complete it!", part.Name)
    return { type = "markUnfinished", message = message, partName = part.Name }
end

--[[
    deletePart — Remove a part by name.

    Parameters:
      - name (string) Part name to find and destroy.

    Returns: boolean
]]
function BuilderKit.deletePart(params: { [string]: any }): boolean
    local part = findPartByName(params.name)
    if part then
        part:Destroy()
        if BuilderKit.partsCreated > 0 then
            BuilderKit.partsCreated -= 1
        end
        return true
    end
    warn(string.format("[BuilderKit] deletePart: '%s' not found", params.name))
    return false
end

--[[
    movePart — Move a part to a new position.

    Parameters:
      - name     (string) Part name.
      - position {x,y,z}  New world position.

    Returns: boolean
]]
function BuilderKit.movePart(params: { [string]: any }): boolean
    local part = findPartByName(params.name)
    if part and part:IsA("BasePart") then
        part.Position = parseVector3(params.position)
        return true
    end
    warn(string.format("[BuilderKit] movePart: '%s' not found or not a BasePart", params.name))
    return false
end

-- ── Command Dispatcher ─────────────────────────────────────────

local commandMap: { [string]: ({ [string]: any }) -> any } = {
    createPart     = BuilderKit.createPart,
    createWedge    = BuilderKit.createWedge,
    createCylinder = BuilderKit.createCylinder,
    createSphere   = BuilderKit.createSphere,
    createSurface  = BuilderKit.createSurface,
    createGroup    = BuilderKit.createGroup,
    addLight       = BuilderKit.addLight,
    setTerrain     = BuilderKit.setTerrain,
    markUnfinished = BuilderKit.markUnfinished,
    deletePart     = BuilderKit.deletePart,
    movePart       = BuilderKit.movePart,
}

--[[
    execute — Execute a single command.

    @param command  A table with `type` and either `params` or flat fields.
    @return result, errorString?
]]
function BuilderKit.execute(command: { [string]: any }): (any, string?)
    if type(command) ~= "table" then
        return nil, "Command must be a table"
    end

    local cmdType = command.type
    if not cmdType then
        return nil, "Command missing 'type' field"
    end

    local handler = commandMap[cmdType]
    if not handler then
        return nil, string.format("Unknown command type: '%s'", cmdType)
    end

    local params = command.params
    if type(params) ~= "table" then
        params = command
    end

    local ok, result = pcall(handler, params)
    if not ok then
        local err = tostring(result)
        warn(string.format("[BuilderKit] '%s' failed: %s", cmdType, err))
        return nil, err
    end

    -- Animate single-part results outside batch mode
    if not inBatchMode and result and typeof(result) == "Instance" and result:IsA("BasePart") then
        if BuildAnimator and not result:GetAttribute("BA_TargetSizeX") then
            BuildAnimator.animatePart(result)
        end
    end

    return result, nil
end

--[[
    executeBatch — Execute multiple commands with deferred animation.

    During batch execution, created parts are collected and then passed
    to BuildAnimator.animateBatch() (if available) for staggered reveal.
    If no BuildAnimator is present, parts are simply parented visibly.

    @param commands   Array of command tables.
    @param onProgress Optional callback: (current, total, result) -> ().
    @param style      Optional animation style string for BuildAnimator.
    @return Array of { index, type, success, result, error } per command.
]]
function BuilderKit.executeBatch(
    commands: { { [string]: any } },
    onProgress: ((number, number, any) -> ())?,
    style: string?
): { { [string]: any } }
    local results: { { [string]: any } } = {}

    inBatchMode = true
    batchCreatedParts = {}

    for i, command in ipairs(commands) do
        local result, err = BuilderKit.execute(command)
        table.insert(results, {
            index = i,
            type = command.type,
            success = err == nil,
            result = result,
            error = err,
        })

        if onProgress then
            task.spawn(onProgress, i, #commands, result)
        end

        -- Throttle every 3 parts for responsiveness
        if i % 3 == 0 and i < #commands then
            task.wait(0.03)
        end
    end

    inBatchMode = false

    -- Animate collected parts if BuildAnimator is available
    if #batchCreatedParts > 0 then
        if BuildAnimator then
            BuildAnimator.animateBatch(batchCreatedParts, nil, nil, nil, style)
        else
            -- No animator — restore target size and transparency
            for _, part in ipairs(batchCreatedParts) do
                local sx = part:GetAttribute("BA_TargetSizeX") or 4
                local sy = part:GetAttribute("BA_TargetSizeY") or 1
                local sz = part:GetAttribute("BA_TargetSizeZ") or 4
                local tr = part:GetAttribute("BA_TargetTransparency") or 0
                part.Size = Vector3.new(sx, sy, sz)
                part.Transparency = tr
            end
        end

        table.clear(batchCreatedParts)
    end

    return results
end

--[[
    getFolder — Return the workspace folder containing all BuilderKit builds.
    Useful for external systems that want to scan or manipulate builds.
]]
function BuilderKit.getFolder(): Folder
    return ensureFolder()
end

--[[
    getBuiltParts — Return all BaseParts tagged with BuilderKitBuilt.
]]
function BuilderKit.getBuiltParts(): { Instance }
    return CollectionService:GetTagged(BUILT_TAG)
end

--[[
    clearAll — Destroy all instances in the BuilderKit folder.
    Resets partsCreated counter. Use for cleanup between builds.
]]
function BuilderKit.clearAll()
    local folder = ensureFolder()
    folder:ClearAllChildren()
    BuilderKit.partsCreated = 0
end

return BuilderKit
