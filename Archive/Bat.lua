local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AssetService = game:GetService("AssetService")
local Chat = game:GetService("Chat")

local AnimationTrack = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/MechaXYZ/modules/raw/main/Anitracker.lua"))()
local createChar = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Colorblindy/Modules/refs/heads/main/CreateCharacter.lua"))()
local modelLoader = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Colorblindy/Modules/refs/heads/main/ModelLoader.lua"))()
local SoundService = game:GetService("SoundService")

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
local owner:Player = owner
local NS = NS
local NLS = NLS
local NewScript = NewScript
local NewLocalScript = NewLocalScript
local printf, warnf = printf, warnf
local LoadAssets = LoadAssets
local requireM = requireM
-- local Utility = LoadLibrary("RbxUtility")

-- local Create = Utility.Create
-- local Signal = Utility.CreateSignal

--#> Player Variables
local character : Model = owner.Character
local backpack : Backpack = owner.Backpack
local playergui : PlayerGui = owner.PlayerGui

local root : BasePart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")
humanoid.UseJumpPower = true

-- AI HINT:
-- This is Luau, a programming language used in Roblox.
-- "owner" is a variable in a certain sandbox game scripting, this should be ignored as its actually our Player instance

-- "printf" and "warnf" is a output debugging function for the sandbox, outputting to the in-game console instead of the Roblox Developer Console

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

-- This is a table that stores various functions used in the script. It is used to organize and manage the functions for better readability and maintainability.
-- The functions in this table are used for various purposes, such as creating tools, applying animations, and managing sound effects.
local funcs = {}

-- Debug is a table that stores debug settings. It is used to enable or disable certain debug features in the script.
local debug = {
    HitboxVisualize = owner:GetAttribute("HitboxVisualize") or false,
}

-- SoundStorage is a table that stores sound instances. It is used to manage sound effects and their properties.
-- It is initialized as an empty table and can be used to store sound instances for later use.
local soundStorage = {}

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
    function funcs:newAnim(animTrack, target : Model, link : string, speed : number, weight : number)
        if animTrack then
            animTrack:setAnimation(link)
            animTrack:setRig(target or character)
            animTrack:Play(speed or 1)
        end

        if weight and typeof(weight) == "number" then
            animTrack:AdjustWeight(weight)
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
                        local ragdollDurVal = Instance.new("NumberValue")
                        ragdollDurVal.Name = "RagdollDuration"
                        ragdollDurVal.Value = ragdollDuration
                        ragdollDurVal.Parent = character
                        
                        NS([[
                            local target, dur = ...
                            if target == nil or dur == nil then
                                target = script.Parent
                                dur = target.RagdollDuration.Value
                            end

                            local humanoid = target:WaitForChild("Humanoid")
                            local root = (humanoid and humanoid.RootPart) or target:WaitForChild("HumanoidRootPart")

                            if humanoid and humanoid.Health > 0 then
                                humanoid.PlatformStand = true
                                while dur > 0 do
                                    if humanoid.Health <= 0 then break end
                                    if root and root.AssemblyLinearVelocity.Magnitude > 0.6 then
                                        task.wait()
                                    else
                                        dur = dur - wait()
                                    end
                                    humanoid.PlatformStand = true
                                end

                                target.RagdollDuration:Destroy()
                                humanoid.PlatformStand = false
                            end
                        ]], character, character, ragdollDuration)
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
        local root:Part = nil
        local player = nil
        if character:IsA("Model") and humanoid then
            root = character:FindFirstChild("HumanoidRootPart")
            if not root then
                root = character:FindFirstChild("Torso")
            end
            player = Players:GetPlayerFromCharacter(character)
        else
            root = character.PrimaryPart
            if not root then
                root = character
            end
        end
       
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
        hitbox.Transparency = debug.HitboxVisualize and 0 or 1
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
        if table.find(special, "InPlace") or not humanoid then
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
        if models and #models > 0 then
            hitbox.Color = Color3.new(0, 1, 0)
        end
        
        Debris:AddItem(hitbox, 1)
        if table.find(special, "GetDebris") then
            return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models, debrises
        else
            return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models
        end
    end

    --#<

    --#> Sound Storage

    function funcs:createPlaceholderSound(id : string, name : string, parent : Instance)
        if table.find(soundStorage, name) then
            warn("Sound with the same name already exists! Please make a unique name.")
            return
        end

        local sound = Instance.new("Sound")

        if id:find("rbxassetid://") then
            sound.SoundId = id
        else
            sound.SoundId = "rbxassetid://" .. id
        end

        sound.Name = name
        sound.Volume = 1
        sound.Parent = parent

        table.insert(soundStorage, sound)

        return sound
    end
    
    function funcs.getPlaceholderSound(name : string)
        for i, v in pairs(soundStorage) do
            if v.Name == name then
                return v
            end
        end
        return nil
    end

    --#<
end

-->> Main Area

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Main stuff

local animHandler
if requireM then
    animHandler = requireM("@mecha_animhandler")
else
    animHandler = AnimationTrack
end
local character = owner.Character

local handle = bat.Handle

-- setup

handle.Handle.Part1 = character["Right Arm"]
bat.Parent = character

--<<

-- Make all parts in the character massless
for i, v:Instance in pairs(character:GetChildren()) do
    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
        v.Massless = true
    end
end

-- This is a command handler that listens for player chat messages and executes debug commands based on the message content.
owner.Chatted:Connect(function(msg : string)
    if msg:sub(1, 3) == "/e " then
        msg = msg:sub(4)
    end

    if msg:sub(1, 6) == ";debug" then
        local args = msg:split(" ")
        local debugArg = args[2]

        if debugArg == "hitbox" then
            local toggle = args[3]
            if toggle == "true" or toggle == "1" or toggle == "on" then
                toggle = true
            elseif toggle == "false" or toggle == "0" or toggle == "off" then
                toggle = false
            else
                toggle = false
            end

            debug.HitboxVisualize = toggle or not debug.HitboxVisualize
            owner:SetAttribute("HitboxVisualize", debug.HitboxVisualize)
            printf(`Hitbox Visualize: {debug.HitboxVisualize}`)
        elseif debugArg == "print" then
            local content = args[3]
            printf(`Debug Print for testing: {content}`)
        elseif debugArg == "d" or debugArg == "dum" or debugArg == "dummy" then
            local amount = tonumber(args[3]) or 1
            
            for i = 1, amount do
                task.spawn(function()
                    local char = createChar(owner.UserId)
                    local hum:Humanoid = char:WaitForChild("Humanoid")
                    hum.DisplayName = owner.DisplayName .. if i == 1 then "" else " #".. i
                    hum.NameDisplayDistance = Enum.HumanoidDisplayDistanceType.None   
                    hum.HealthDisplayDistance = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
                    char:PivotTo(root.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(180), 0))
                    char.Parent = workspace
                end)
            end

            printf(`Dummy spawned!`)
        elseif debugArg == "modelcheck" or debugArg == "mc" then
            local modelName = args[3]
            local checkModel = modelLoader.Check(modelName)

            if checkModel then
                printf(`Model "{modelName}" exists!`)
            else
                printf(`Model "{modelName}" does not exist!`)
            end
        elseif debugArg == "modellist" or debugArg == "ml" then
            local models = modelLoader.List()
            printf(`Available models: {table.concat(models, ", ")}`)
        elseif debugArg == "model" or debugArg == "gm" or debugArg == "m" then
            local modelName = args[3]
            local model = modelLoader.Get(modelName)

            if model then
                model:PivotTo(root.CFrame * CFrame.new(0, 2, -5))
                model.Parent = workspace
                printf(`Model "{modelName}" spawned!`)
            end
        else
            printf(`No such thing as "{debugArg}"!`)
        end
    end
end)