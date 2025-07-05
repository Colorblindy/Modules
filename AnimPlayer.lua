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

local owner:Player = owner
local NS = NS
local NLS = NLS
local NewScript = NewScript
local NewLocalScript = NewLocalScript
local printf, warnf = printf, warnf

-- Main stuff

local animHandler = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/MechaXYZ/modules/raw/main/Anitracker.lua"))()
local funcs = {}
do -- funcs
	--|| First Setup
    local soundStorage = {}

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

	local mainCase = Instance.new("BindableEvent")
	mainCase.Event:Connect(function(case, ...)
		if case == "ragdoll" then
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
			animTrack:setRig(target)
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

		--if owner and owner:FindFirstChild("Backpack") then
		--	tool.Parent = backpack
		--else
		--	warn("Owner or Backpack not found!")
		--end

		return tool
	end

	function funcs:damage(character:Model, target:Model, amount:number, special:{string})
		assert(character, "Character model will be needed.")
		assert(target, "Target character will be needed.")

		if not special or typeof(special) ~= "table" then
			special = {special}
		end
		
		local player = Players:GetPlayerFromCharacter(target)
		if not player then
			player = character
		end

		--|| in functions

		local function CreateHitBy(humanoid:Humanoid, duration:number)
			if humanoid:FindFirstChild("HitBy") then
				humanoid:FindFirstChild("HitBy"):Destroy()
			end

			local objectValue = Instance.new("ObjectValue")
			objectValue.Name = "HitBy"
			objectValue.Value = character
			objectValue.Parent = humanoid

			Debris:AddItem(objectValue, duration or 2)
		end

		local function GetAllResistance()
			local mainRes = character:GetAttribute("Resistance")
			local total = mainRes or 0

			for i, v in pairs(target:GetChildren()) do
				if v.Name == "Resistance" and v:IsA("NumberValue") then
					total += v.Value
				end
			end

			if total > 100 then
				total = 100
			end
			return total
		end

		local function GetAllStrength()
			local mainStrength = character:GetAttribute("Strength")
			local total = mainStrength or 1

			for i, v in pairs(character:GetChildren()) do
				if v.Name == "Strength" and v:IsA("NumberValue") then
					total += (v.Value/2)
				end
			end

			return total
		end

		--|| main

		local tHum:Humanoid = target:FindFirstChildOfClass("Humanoid")

		if tHum then
			local tRoot = tHum.RootPart or target:FindFirstChild("HumanoidRootPart")
			local newDamage = amount

			local protected = false
			local healing = false

			--#|| specials (before checks)
			if table.find(special, "MaxHP%") then -- damage based to maxhp percentage
				newDamage = tHum.MaxHealth * (newDamage/100)
			elseif table.find(special, "HP%") then -- damage based to hp percentage
				if tHum.Health < newDamage/5 then -- but ignore it if the target's hp goes below the set damage divided by 5
					newDamage = newDamage 
				else
					newDamage = tHum.Health * (newDamage/100)
				end
			end

			--#|| damage calculation

			--# strength calculation
			local strength = GetAllStrength()
			newDamage = newDamage * (strength or 1)

			--# resistance calculation / is healing checker
			if newDamage < 0 then
				healing = true
			else
				if not table.find(special, "IgnoreResistance") then -- check if damage will ignore defense
					local resist = GetAllResistance()
					local maximumResistance = 100
					local defenseDamage = newDamage * (1 - resist/maximumResistance)

					--# checks
					if table.find(special, "IgnoreGoodRES") then -- if the defense is above 0 = keep original damage
						if resist > 0 then
							defenseDamage = newDamage
						end
					end
					newDamage = defenseDamage

					if resist >= 100 then
						protected = true
					end
				end
			end

			--# check forcefield
			if target:FindFirstChild("ForceField") then
				newDamage = 0

				if not protected then
					protected = true
				end
			end

			--|| after checks

			--# get health regeneration
			if target:FindFirstChild("Health") then
				if not protected and not healing then
					local regen = target:FindFirstChild("Health")
					local decay:NumberValue = regen:FindFirstChild("Decay")

					if decay then
						decay.Value = 5
					end
				end
			end

			if tHum.Health <= 0 then
				newDamage = 0
			end
			tHum.Health -= newDamage
		end
	end

	-- Applies a BodyVelocity to the player's HumanoidRootPart to push them in a given direction
	function funcs:pushPlayer(target : Model, velocity : Vector3, force : Vector3, forceMultiplier : number, duration : number, ragdoll : number) : BodyVelocity
		local character = target --or owner.Character
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

						--NS([[
      --                      local target, dur = ...
      --                      if target == nil or dur == nil then
      --                          target = script.Parent
      --                          dur = target.RagdollDuration.Value
      --                      end

      --                      local humanoid = target:WaitForChild("Humanoid")
      --                      local root = (humanoid and humanoid.RootPart) or target:WaitForChild("HumanoidRootPart")

      --                      if humanoid and humanoid.Health > 0 then
      --                          humanoid.PlatformStand = true
      --                          while dur > 0 do
      --                              if humanoid.Health <= 0 then break end
      --                              if root and root.AssemblyLinearVelocity.Magnitude > 0.6 then
      --                                  task.wait()
      --                              else
      --                                  dur = dur - wait()
      --                              end
      --                              humanoid.PlatformStand = true
      --                          end

      --                          target.RagdollDuration:Destroy()
      --                          humanoid.PlatformStand = false
      --                      end
	  --                  ]], character, character, ragdollDuration)
	  					mainCase:Fire("ragdoll", character, ragdollDuration)
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
	function funcs:pushItem(item : Instance, velocity : Vector3, force : Vector3, forceMultiplier : number, duration : number) : BodyVelocity
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

			if duration > 0 or duration == nil then
				game:GetService("Debris"):AddItem(bodyVelocity, duration or 0.1)
			end
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
		local projConfig = ProjectileConfiguration()
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
					if v:HasTag("FuncHitbox") then continue end
					if not v.CanTouch then continue end
					if v.Locked then continue end

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
	function funcs:hitbox(character : Model, offset : CFrame, size : Vector3, shape : string | Enum.PartType, special:{string})
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
		--params.CollisionGroup = "PlayerPart"
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude

		hitbox.Parent = workspace

		local firstCheck = workspace:GetPartsInPart(hitbox, params)
		local parts = {}
		for i, v in pairs(firstCheck) do
			local part:BasePart = v

			table.insert(parts, part)
		end

		local models : {Model}, debrises : {Part} = GetTouched(parts, special)
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

local songs = {}
do -- songs
    local partsWithId = {}
    local awaitRef = {}

    songs.Songs = {
        Canyon = {
            ID = 0;
            Type = "Sound";
            Properties = {
                Pitch = 0.11999999731779099;
                Name = "Canyon";
                Volume = 1.5;
                SoundId = "rbxassetid://102327503362624";
                Looped = true;
                PlaybackSpeed = 0.11999999731779099;
            };
            Children = {
                {
                    ID = 1;
                    Type = "EqualizerSoundEffect";
                    Properties = {
                        MidGain = 10;
                        LowGain = 1;
                        HighGain = 10;
                    };
                    Children = {};
                };
            };
        };
        Mesmerizer = {
            ID = 0;
            Type = "Sound";
            Properties = {
                Pitch = 0.10999999940395355;
                Name = "Mesmerizer";
                Volume = 1.5;
                SoundId = "rbxassetid://128168174331151";
                Looped = true;
                PlaybackSpeed = 0.10999999940395355;
            };
            Children = {
                {
                    ID = 1;
                    Type = "EqualizerSoundEffect";
                    Properties = {
                        MidGain = 10;
                        LowGain = -10;
                        HighGain = -10;
                    };
                    Children = {};
                };
            };
        };
        Rockefeller = {
            ID = 0;
            Type = "Sound";
            Properties = {
                Pitch = 0.11999999731779099;
                Name = "Rockefeller";
                Volume = 1.5;
                SoundId = "rbxassetid://109228501173685";
                Looped = true;
                PlaybackSpeed = 0.11999999731779099;
            };
            Children = {
                {
                    ID = 1;
                    Type = "EqualizerSoundEffect";
                    Properties = {
                        MidGain = 10;
                        LowGain = 10;
                        HighGain = 1;
                    };
                    Children = {};
                };
            };
        };
    };

    function songs:Get(item, parent)
        local obj = Instance.new(item.Type)
        if (item.ID) then
            local awaiting = awaitRef[item.ID]
            if (awaiting) then
                awaiting[1][awaiting[2]] = obj
                awaitRef[item.ID] = nil
            else
                partsWithId[item.ID] = obj
            end
        end
        for p,v in pairs(item.Properties) do
            if (type(v) == "string") then
                local id = tonumber(v:match("^_R:(%w+)_$"))
                if (id) then
                    if (partsWithId[id]) then
                        v = partsWithId[id]
                    else
                        awaitRef[id] = {obj, p}
                        v = nil
                    end
                end
            end
            obj[p] = v
        end
        for _,c in pairs(item.Children) do
            songs:Get(c, obj)
        end
        obj.Parent = parent
        return obj
    end
end

local animations = require(128080079331424)

animHandler.lerpFactor = 0.6
animHandler.NoDisableTransition = true

--

local char = owner.Character
local inUse = nil

-- songs

local songList = songs.Songs

-- args

local name, speed, loop = ...

-- setup

if not inUse then
	inUse = animHandler.new()
else
	inUse:Destroy()
	task.wait()

	inUse = animHandler.new()
end

if char:GetAttribute("PlayingAnims") then
	if char.PrimaryPart:FindFirstChild("AnimSong") then
		char.PrimaryPart.AnimSong:Destroy()
	end
end
char:SetAttribute('PlayingAnims', true)	

-- anim

local getAnim = animations.GetAnimation(name or 'Mesmerizer')
local getSong = nil
if songList[name] then
	getSong = songs:Get(songList[name])
end

if not getAnim then
	return
end
if getSong then
	funcs:makeSound(getSong, char.PrimaryPart, {Name = "AnimSong"}, getSong.Looped)
end

if inUse then
	inUse:setAnimation(getAnim)
	inUse:setRig(char)
	inUse:Play(speed or 1)
	inUse.Looped = if loop and loop == false then false else true
end