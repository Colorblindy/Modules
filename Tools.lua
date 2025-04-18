local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AssetService = game:GetService("AssetService")

local AnimationTrack = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/MechaXYZ/modules/raw/main/Anitracker.lua"))()

export type ProjectileConfiguration = {
	Speed: NumberValue,
	Direction: Vector3Value,
	ItemHost: ObjectValue,
	Detectable: BoolValue,
}

export type HitboxSpecial = {
    "ChangeName" | "InPlace" | "Static" | "GetDebris"
}

-- Starter Variables
local owner = owner
local NS = NS
local NLS = NLS
local NewScript = NewScript
local NewLocalScript = NewLocalScript

--#> Player Variables
local character : Model = owner.Character
local backpack : Backpack = owner.Backpack
local playergui : PlayerGui = owner.PlayerGui

local root : BasePart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")
humanoid.UseJumpPower = true

-- COPILOT HINT:
-- This is Luau, a programming language used in Roblox.
-- "owner" is a variable in a certain sandbox game scripting, this should be ignored as its actually our Player instance

-- "NLS", "NS" is a function in a certain sandbox game scripting, the full name is "NewLocalScript" and "NewScript"
-- "NLS" is used to create a LocalScript in runtime, and "NS" is used to create a Script in runtime
-- The first argument is the script source. Requires string, mainly uses [[]] for multiline string for better usage and readability
-- The second argument is the parent instance, if not provided, it will default to PlayerGui for NLS and workspace for NS
-- The third argument and so on is the so-called any argument, which is used to pass instance in the several arguments or more separately to the respective script
-- You can grab the passed instances by called ... in a variable.

-- Example:
--[[
NS("local player, item = owner, ...; print(item.Name, player.DisplayName)", workspace, item) -- This will pass the owner and item instance to the script
]]

-- Functions

local funcs = {}

do

    --|| First Setup

    -- SoundCase is a BindableEvent that allows for sound events to be fired and connected to. It can be used to play or delete sounds based on the case provided.
    -- It is connected to a function that waits for the sound to load, then plays or deletes it based on the case provided.
    local soundCase = Instance.new("BindableEvent")
    soundCase.Event:Connect(function(case : string, sfx)
        repeat task.wait() until sfx.IsLoaded
        task.wait(0.1)
        if case == "delete" then
            Debris:AddItem(sfx, sfx.TimeLength/sfx.PlaybackSpeed)
        elseif case == "play" then
            sfx:Play()
        end
    end)

    --|| Main Functions

    -- Creates welding between two parts, with optional properties for the weld
    -- Optionally, you can pick between Motor6D, Weld, or WeldConstraint
    function funcs:jointParts(part1 : BasePart, part2 : BasePart, weldType : string, c0_and_c1 : {CFrame})
        assert(part1 and part2, "Both parts are required for welding!")
        assert(part1:IsA("BasePart") and part2:IsA("BasePart"), "Both parts must be instances!")
        assert(weldType == "Motor6D" or weldType == "Weld" or weldType == "WeldConstraint", "Invalid weld type!")
        
        local weld = Instance.new(weldType or "WeldConstraint")
        weld.Name = `{part1.Name}_to_{part2.Name}`
        weld.Part0 = part1
        weld.Part1 = part2
        
        if weldType ~= "WeldConstraint" then
            weld.C0 = (c0_and_c1 and c0_and_c1[1]) or CFrame.new()
            weld.C1 = (c0_and_c1 and c0_and_c1[2]) or CFrame.new()
        end

        weld.Parent = part1
        
        return weld
    end

    -- Creates a new animation track with AnimationTrack module and sets its properties
    function funcs:newAnim(animTrack, target : Model, link : string, speed : number)
        if animTrack then
            animTrack:setAnimation(link)
            animTrack:setRig(target or character)
            animTrack:Play(speed or 1)
        end
    end

    -- Creates a Tool instance, parents it to the player's Backpack, and returns it
    function funcs:createTool(model : BasePart, toolName : string, tooltip : string, grip : CFrame, handle : boolean, droppable : boolean)
        local tool = Instance.new("Tool")
        tool.Name = toolName
        tool.ToolTip = tooltip
        tool.Grip = grip
        tool.RequiresHandle = handle
        tool.CanBeDropped = droppable

        if model then
            model.Parent = tool
        end

        if owner and owner:FindFirstChild("Backpack") then
            tool.Parent = backpack
        else
            warn("Owner or Backpack not found!")
        end

        return tool
    end

    -- Applies a BodyVelocity to the player's HumanoidRootPart to push them in a given direction
    function funcs:pushPlayer(target : Model, velocity : Vector3, force : Vector3, forceMultiplier : number, duration : number, ragdoll : number)
        local character = target or owner.Character
        if not (character and character:IsA("Model") and character:FindFirstChildOfClass("Humanoid")) then
            warn("Invalid character: must be a Model with Humanoid!")
            return
        end

        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = velocity
            bodyVelocity.MaxForce = force * (forceMultiplier or 1e5)
            bodyVelocity.Parent = hrp

            if ragdoll then
                local isNumber = type(ragdoll) == "number"
                local isBool = type(ragdoll) == "boolean"
                local shouldRagdoll = (isNumber and ragdoll > 0) or (isBool and ragdoll)
            
                if shouldRagdoll then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local ragdollDuration = isNumber and ragdoll or 1
                        
                        NLS([[
                            local target, dur = ...
                            local humanoid = target:WaitForChild("Humanoid")
                            local root = humanoid and (humanoid.RootPart or target:WaitForChild("HumanoidRootPart"))

                            if humanoid and humanoid.Health > 0 then
                                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                                while dur > 0 do
                                    if humanoid.Health <= 0 then break end
                                    if root and root.AssemblyLinearVelocity.Magnitude > 0.6 then
                                        task.wait()
                                    else
                                        dur = dur - wait()
                                    end
                                end

                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                            end
                        ]], nil, character, ragdollDuration)
                    end
                end
            end            

            Debris:AddItem(bodyVelocity, duration or 0.1)
            return bodyVelocity
        else
            warn("Character or HumanoidRootPart not found!")
        end
    end

    -- Applies BodyVelocity to an item to push it in a given direction, can be used on models if it has a PrimaryPart
    function funcs:pushItem(item : Instance, velocity : Vector3, force : Vector3, forceMultiplier : number, duration : number)
        if not item or (not item:IsA("BasePart") and not (item:IsA("Model") and item.PrimaryPart)) then
            warn("Invalid item: must be a BasePart or Model with PrimaryPart!")
            return
        end
        if item:IsA("Model") and item:FindFirstAncestorOfClass("Humanoid") then
            warn("Item cannot be a character!")
            return
        end

        local primaryPart = item:IsA("Model") and item.PrimaryPart or item
        if primaryPart then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = velocity
            bodyVelocity.MaxForce = force * (forceMultiplier or 1e5)
            bodyVelocity.Parent = primaryPart

            game:GetService("Debris"):AddItem(bodyVelocity, duration or 0.1)
            return bodyVelocity
        else
            warn("Pushable instance not found!")
        end
    end

    -- Creates a sound instance, applies properties, and parents it to the specified parent or SoundService
    function funcs:makeSound(sound : Sound, parent : Instance, property : {}, dontDestroy : boolean)
        local sfx = sound:Clone()
    
        --# apply set properties
        if typeof(property) == "table" then
            for i, v in pairs(property) do
                sfx[i] = v
            end
        end
    
        ---
    
        sfx.Parent = parent or game.SoundService
        if RunService:IsClient() then
            local plr = Players.LocalPlayer
            if sfx:IsDescendantOf(plr.PlayerGui) then
                sfx.Parent = game.SoundService
            end
    
            soundCase:Fire("play", sfx)
        else
            sfx:Play()
        end
    
        if not dontDestroy then
            soundCase:Fire("delete", sfx)
        end
        
        return sfx
    end

    -- Applies a tween to an instance with a given duration, property, style, and direction
    function funcs:tween(instance : Instance, number : number, property : {}, style : string | Enum.EasingStyle, direction : string | Enum.EasingDirection)
		local selectedstyle = style or Enum.EasingStyle.Sine
		local selecteddirect = direction or Enum.EasingDirection.InOut

		if typeof(style) == "string" then
			selectedstyle = Enum.EasingStyle[tostring(style)]
		end
		if typeof(direction) == "string" then
			selecteddirect = Enum.EasingDirection[tostring(direction)]
		end

		local tween = game.TweenService:Create(instance, TweenInfo.new(number, selectedstyle, selecteddirect), property)
		tween:Play()

		tween.Completed:Once(function()
			tween:Cancel()
			tween:Destroy()
		end)

		return tween
	end

    --#> Projectile

    -- Creates a new projectile configuration and sets its properties
    function SafeCheckConfig(value : ValueBase, default : any)
        if value then
            value.Value = default
        end
    end

    -- Creates a new projectile configuration instance with default properties
    function ProjectileConfiguration()
        local ProjectileConfiguration = Instance.new("Configuration")
        ProjectileConfiguration.Name = "ProjectileConfiguration"

        local Speed = Instance.new("NumberValue")
        Speed.Name = "Speed"
        Speed.Parent = ProjectileConfiguration

        local Direction = Instance.new("Vector3Value")
        Direction.Name = "Direction"
        Direction.Parent = ProjectileConfiguration

        local ItemHost = Instance.new("ObjectValue")
        ItemHost.Name = "ItemHost"
        ItemHost.Parent = ProjectileConfiguration

        local Detectable = Instance.new("BoolValue")
        Detectable.Name = "Detectable"
        Detectable.Value = true
        Detectable.Parent = ProjectileConfiguration

        return ProjectileConfiguration
    end

    -- Make projectile, cloning the set model and applying BodyVelocity to it
    function funcs:projectile(character : Instance, projectileItem : BasePart, setPos : Vector3, offset : Vector3, speed : number, direction:Vector3, rotation:CFrame, stare:Vector3, gravity:number)
        if not projectileItem then
            warn("Projectile item not found!")
            return
        end
        if not projectileItem:IsA("BasePart") then
            warn("Projectile item is not a BasePart!")
            return
        end

        local player:Player
        if typeof(character) == "Instance" and character:IsA("Player") then
            player = character
            character = player.Character
        elseif Players:GetPlayerFromCharacter(character) then
            player = Players:GetPlayerFromCharacter(character)
        else
            player = character
        end

        if not gravity then gravity = 0 end

        --# make config
        local projConfig:ProjectileConfiguration = ProjectileConfiguration()
        SafeCheckConfig(projConfig.Speed, type(speed) == "number" and speed or 0)
        SafeCheckConfig(projConfig.Direction, typeof(direction) == "Vector3" and direction or Vector3.zero)
        SafeCheckConfig(projConfig.ItemHost, character)
        SafeCheckConfig(projConfig.Detectable, true)

        --# position set
        local pos = setPos + (offset or Vector3.new(0,0,0))
        local dir = projConfig.Direction.Value
        local lookAt = stare or dir
        local cfr = CFrame.new(pos, lookAt)

        if rotation then cfr *= rotation end

        local projectile = projectileItem:Clone()
        projConfig.Parent = projectile
        projectile.AssemblyLinearVelocity = dir * projConfig.Speed.Value
        projectile.CFrame = cfr

        local vectorForce = Instance.new("VectorForce")
        local attachment = Instance.new("Attachment")
        vectorForce.Name = "Force"
        attachment.Name = "A0"
        vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
        vectorForce.Attachment0 = attachment

        local downForce = -projectile:GetMass() * workspace.Gravity
        local force = -downForce * gravity + (1 - gravity)
        vectorForce.Force = Vector3.new(0, force, 0)
        attachment.Parent = projectile
        vectorForce.Parent = projectile

        projectile.Parent = workspace
        return projectile, projConfig
    end

    --#<

    -- Creates a mesh part with a given content, texture, size, and parent
    function funcs:createMesh(content : string, texture : string | Color3, size : Vector3, parent : Instance)
        local mesh = AssetService:CreateMeshPartAsync(content, {CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition})
        mesh.Size = size
        
        if texture then
            if typeof(texture) == "Color3" then
                mesh.Color = texture
            elseif typeof(texture) == "string" then
                if texture:find("rbxassetid://") then
                    mesh.TextureID = texture
                else
                    mesh.TextureID = "rbxassetid://" .. texture
                end
            end
        end

        mesh.Parent = parent
        return mesh
    end

    --#> Hitbox

    -- Gets touched parts from a list of parts and returns humanoid models and debris items
    function GetTouched(list : {BasePart}, special:{string})
        assert(list, "List is needed for GetTouched Modular method as it gets touched from bounding hitbox")
        if #list == 0 then return {}, {} end
        
        if not special or typeof(special) ~= "table" then
            special = {special}
        end
        
        --|| variable
        local humanoidModel, debrisItem = {}, {}
        
        --# get parts
        for i, v in list do
            local model = v:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if not humanoid then continue end
                
                local find = table.find(humanoidModel, model)
                if find then continue end
                
                table.insert(humanoidModel, model)
            end
        end
        
        --# get debris item
        if table.find(special, "GetDebris") then
            for i, v in list do 
                if v:IsDescendantOf(workspace) then
                    local projectileConfig:Configuration = v:FindFirstChild("ProjectileConfiguration")
                    
                    local host:ObjectValue = projectileConfig:FindFirstChild("ItemHost")
                    if not host then continue end
                    
                    local detectable:BoolValue = projectileConfig:FindFirstChild("Detectable")
                    if not detectable or detectable.Value == false then continue end
    
                    local findDebris = table.find(debrisItem, v)
                    if findDebris then continue end
    
                    table.insert(debrisItem, v)
                end
            end		
        end
        
        --# return
        return humanoidModel, debrisItem
    end

    -- Creates a hitbox part with a given size, shape, and special properties
    function funcs:hitbox(character : Model, offset : CFrame, size : Vector3, shape : string | Enum.PartType, special:HitboxSpecial)
        assert(size, "Size will be needed.")
        assert(typeof(size) == "Vector3" or type(size) == "number", "Size parameter should be Vector3 or number.")
        
        if not special or typeof(special) ~= "table" then
            special = {special}
        end
        if not offset or typeof(offset) ~= "CFrame" then
            offset = CFrame.new()
        end
        
        if type(size) == "number" then
            size = Vector3.one() * size
        end
        
        --# get player + root + humanoid
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root:Part = character:FindFirstChild("HumanoidRootPart")
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            player = character
        end
        
        --# make part
        local hitbox = Instance.new("Part")
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.CanTouch = false
        
        hitbox.Massless = true
        hitbox.Material = Enum.Material.ForceField
        hitbox.Transparency = 1
        hitbox.Color = Color3.new(1, 0, 0)
        hitbox.Name = `HITBOX_{HttpService:GenerateGUID(false)}`
        if table.find(special, "ChangeName") then
            if special.HitboxName then
                hitbox.Name = special.HitboxName
            end
        end
        
        hitbox.Shape = shape or "Block"
        hitbox.Size = size
        
        local pos = nil
        if table.find(special, "InPlace") then
            pos = root.CFrame * offset
        else
            pos = (root.CFrame * CFrame.new(0, 0, -size.Z/2)) * offset
        end
        
        if not table.find(special, "Static") then
            if root.AssemblyLinearVelocity.Magnitude > 0 then
                pos *= CFrame.new((root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)).Unit * 2.5)
            end
        end
        
        hitbox.CFrame = pos
        
        --# bounding
        
        local params = OverlapParams.new()
        params.CollisionGroup = "PlayerPart"
        params.FilterDescendantsInstances = {character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        
        hitbox.Parent = workspace
        
        local firstCheck = workspace:GetPartsInPart(hitbox, params)
        local parts = {}
        for i, v in pairs(firstCheck) do
            local part:BasePart = v
            
            table.insert(parts, part)
        end
        
        local models : Model, debrises : Part = GetTouched(parts, special)
        
        Debris:AddItem(hitbox, 1)
        if table.find(special, "GetDebris") then
            return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models, debrises
        else
            return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models
        end
    end

    --#<
end

--|| Start

--# tool list
local toolList = {
    ["crucifix"] = {
        ToolTip = "when faith endures",
        Grip = CFrame.new(),
        Handle = false,
        Droppable = false,
        
        Tool = nil :: Tool,
        Model = nil :: BasePart,

        ModelInfo = {
            Type = "MeshPart",
            Mesh = "rbxassetid://88034374571727",
            Size = Vector3.new(1.98, 0.31, 1.06),
            Texture = nil,

            -- # mesh properties
            Name = "Cross",
            CanCollide = false,
            CanTouch = false,
            Anchored = false,
            Massless = true,
            CanQuery = false,
        }
    }
}

for i, v in pairs(toolList) do
    local model = nil
    if v.ModelInfo then
        if v.ModelInfo.Type == "MeshPart" then
            model = funcs:createMesh(v.ModelInfo.Mesh, v.ModelInfo.Texture, v.ModelInfo.Size, nil)
            for i2, v2 in pairs(v.ModelInfo) do
                pcall(function()
                    model[i2] = v2
                end)
            end
        end
    end
    
    local tool = funcs:createTool(model, i, v.ToolTip, v.Grip, v.Handle, v.Droppable)
    v.Tool = tool
    v.Model = model
end

--|| >> Main Tool Functions <<

do -- crucifix
    local crucifix = toolList["crucifix"]
    local tool = crucifix.Tool
    local model = crucifix.Model
    model.Parent = nil

    local cruxAnim = AnimationTrack.new()
    cruxAnim.NoDisableTransition = true
    cruxAnim.lerpFactor = 1

    --#> Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "Cross"
    hl.FillTransparency = 0.3
    hl.OutlineTransparency = 0
    hl.Adornee = model
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    hl.Parent = model

    --#> Weld
    funcs:jointParts(character["Right Arm"], model, "Weld", {CFrame.new(0, -1, -0.36499977111816406, -4.371138828673793e-08, 0, -1, -4.371138828673793e-08, -1, 1.910685465164705e-15, -1, 4.371138828673793e-08, 4.371138828673793e-08)})

    --#> Texturing
    local faceEnum, maxNumber = Enum.NormalId:GetEnumItems(), #Enum.NormalId:GetEnumItems()
    for i = 1, maxNumber do
        local tex = Instance.new("Texture")
        tex.Transparency = 0.9
        tex.Color3 = Color3.new(0, 0, 0)
        tex.Texture = (i == 3 and "rbxassetid://102276212148593") or "rbxassetid://15702060640"
        tex.Face = faceEnum[i]
        tex.OffsetStudsV = 0
        tex.StudsPerTileV = (i == 3 and 0.05) or 10
        tex.StudsPerTileU = (i == 3 and 10) or 0.05
        tex.Parent = model
    end

    --#> Random Crucifix
    local rand = Random.new():NextInteger(1, 3)
    model.Material = Enum.Material.Metal
    if rand == 1 then
        model.BrickColor = BrickColor.new("Gold")
    elseif rand == 2 then
        model.Color = Color3.fromRGB(207, 207, 207)
        tool.ToolTip = "when faith... endures?"
    elseif rand == 3 then
        model.BrickColor = BrickColor.new("Burnt Sienna")
        model.Material = Enum.Material.Wood
        tool.ToolTip = "losing faith..."
    end
    
    hl.FillColor, hl.OutlineColor = model.Color, model.Color

    --#> Activate (Hold)
    local holding = false
    local hits = {}

    tool.Activated:Connect(function()
        if not holding then
            holding = true
            
            model.Parent = tool
            cruxAnim.Looped = true
            funcs:newAnim(cruxAnim, character, "https://pastebin.com/raw/gBL8K0HC")
            humanoid.WalkSpeed -= 12
            humanoid.JumpPower -= 50

            task.spawn(function()
                while holding do
                    table.clear(hits)

                    local hitbox, models = funcs:hitbox(character, CFrame.new(0, 0, 0), Vector3.new(7, 6, 7.11), "Block")

                    for i, v in models do
                        if table.find(hits, v) then continue end
                        table.insert(hits, v)

                        local humanoid = v:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local damage = (rand == 3 and 3) or (rand == 2 and 5) or 8;
                            local newdamage = humanoid.MaxHealth * (damage/100)
                            humanoid.Health -= newdamage
                        end
                    end

                    task.wait(0.1)
                end
            end)

            repeat task.wait() until holding == false
            cruxAnim.Looped = false
            humanoid.WalkSpeed += 12
            humanoid.JumpPower += 50

            model.Parent = nil
            cruxAnim:Stop()
        end
    end)

    tool.Deactivated:Connect(function()
        if holding then
            holding = false
        end
    end)

    tool.Unequipped:Connect(function()
        if holding then
            holding = false
        end
    end)
end