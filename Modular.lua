local Chat = game:GetService("Chat")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Modular

do
	local system = {}

	--| variables

	--|| main

--[=====[<custom>
	Applies a status effect to a desired target.
	
	<md>
	**target**: The model to apply the status effect to.
	**case**: The type of status effect. See below.
	**duration**: The duration of the status effect.
	
	***Available status type***
	- `Stun`: Prevents the user from attacking, using Items, or calling Helpers. Forcefully slows the user down.
]=====]
function system:Status(target:Model, case:string, duration)
	case = case:lower()
	
	if target and not target:FindFirstChild("ForceField") then
		if case == "stun" then
			if target:FindFirstChild("StunLSBModule") then
				local stun = target:FindFirstChild("StunLSBModule")
				local getMax = stun:GetAttribute("Maximum")
				
				if duration >= getMax then
					stun:SetAttribute("Maximum", duration)
					stun.Value = duration
				end
			else
				local stun = Instance.new("NumberValue")
				stun.Name = "StunLSBModule"
				stun:SetAttribute("Maximum", duration)
				stun.Value = duration
				stun.Parent = target
				
				NS([[
					local stun, target:Model = ...

					local prim = target.PrimaryPart
					local pos = target:GetPivot()

					local bodyPos = Instance.new("BodyPosition")
					bodyPos.MaxForce = Vector3.one * 1e5
					bodyPos.D = 50
					bodyPos.P = 1e7
					bodyPos.Position = pos.Position
					bodyPos.Parent = prim

					stun.Destroying:Once(function()
						bodyPos:Destroy()
					end)

					while stun.Value > 0 do
						task.wait(1)
						stun.Value -= 1
					end

					stun:Destroy()
					bodyPos:Destroy()
				]], nil, stun, target)
			end
		end
	end
end

--[=====[<custom>
	Plays a sound with optional property modifications and parent assignment.
	
	<md>
	**sound**: The sound instance to clone and play.
	**parent**; The parent where the sound will be placed. Defaults to `SoundService`.
	**property**: A table of properties to modify on the cloned sound.
	**dontDestroy**: If `true`, the sound will not be destroyed after playing. Defaults to `false`.
	<cs>
	local sound = game.ReplicatedStorage.Sounds.Wind
	local properties = {
	    Volume = 0.5,
	    PlaybackSpeed = 1.2,
	    Looping = true
	}

	system.MakeSound(sound, game.Workspace, properties, true)
]=====]
	function system.MakeSound(sound : Sound, parent : Instance, property : {}, dontDestroy : boolean)
		local sfx = sound:Clone()

		--# apply set properties
		if typeof(property) == "table" then
			for i, v in pairs(property) do
				sfx[i] = v
			end
		end

		---

		sfx.Parent = parent or game.SoundService
		sfx:Play()

		if not dontDestroy then
			Debris:AddItem(sfx, sfx.TimeLength/sfx.PlaybackSpeed)
		end

		return sfx
	end

--[=====[<custom>
	Provides a simplified and flexible way to create smooth animation using Roblox’s TweenService.
	
	<md>
	**instance**: The object to animate.
	**number**: The duration of the tween in seconds.
	**property**: A table containing properties and their target values to animate.
	**style**: The easing style of the animation. Defaults to `Sine`.
	**direction**: The easing direction (`In`, `Out`, `InOut`). Defaults to `InOut`.
	<cs>
	local door = workspace.Door

	system.Tween(door, 3, {
	    Position = door.Position + Vector3.new(0, 5, 0),
	    Transparency = 0.5
	}, "Bounce", "In")
]=====]
	function system.Tween(instance : Instance, number : number, property : {}, style : string | Enum.EasingStyle, direction : string | Enum.EasingDirection)
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

	--# damaging
--[=====[<custom>
	Applies damage to a target character, factoring in strength, resistance, and special conditions. It also supports percentage-based damage, healing, and protection mechanics.
	
	<md>
	**character**: The attacking character.
	**target**: The character receiving damage. 
	**player** (optional): The player associated with the attack. Defaults to the attacker if not provided.
	**amount**: The base damage value to apply.
	**special** (optional): A table of special conditions that modify damage calculations. See below
	
	***Special conditions***
	- `MaxHP%`: Damage is calculated as a percentage of the target’s maximum health.
	- `HP%`: Damage is calculated as a percentage of the target’s current health.
	- `IgnoreResistance`: Ignores the target's resistance when calculating damage reduction.
	- `IgnoreGoodRES`: Prevents resistance from reducing damage if resistance is above 0.
	<cs>
	local attacker = script.Parent
	local target = hit.Parent

	system:Damage(attacker, target, nil, 25)
]=====]
	function system:Damage(character:Model, target:Model, player:Player, amount:number, special:{string})
		assert(character, "Character model will be needed.")
		assert(target, "Target character will be needed.")

		if not special or typeof(special) ~= "table" then
			special = {special}
		end
		if not player then
			player = Players:GetPlayerFromCharacter(target)
			if not player then
				player = character
			end
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

	--# velocity
--[=====[<custom>
	Applies a velocity force to a character or part, optionally allowing vertical movement, bypassing knockback resistance, and triggering ragdoll effects.
	
	<md>
	**characterOrPart**: The `Model` or `Part` to apply velocity to.
	**velocity**: The velocity to apply.
	**yForce** (optional): Allows the force to be applied upwards if set to `true`.
	**duration** (optional): How long the force is applied to the target.
	**ragdollTime** (optional): Duration of ragdoll effect (if applicable).
	**bypass** (optional): If `true`, bypasses anti-knockback checks.
	**forceRewrite** (optional): Used for ragdoll system; determines whether ragdoll duration should be forcibly rewritten.
	<cs>
	local character = script.Parent
	
	system:Velocity(character, Vector3.new(50, 0, 50), true, 0.2, 2, false, false)
]=====]
	function system:Velocity(characterOrPart:Model | Part, velocity:Vector3, yForce : boolean, duration:number, ragdollTime:number, bypass:boolean, forceRewrite:boolean)
		assert(characterOrPart, "A character or a Part is needed for this operation")
		assert(characterOrPart:IsA("Part") or characterOrPart:IsA("Model"), "Velocity::Argument 1 should be Part or Model")
		assert(velocity, "Velocity is needed for this operation")

		local root = nil
		if characterOrPart:IsA("Part") then
			root = characterOrPart
		elseif characterOrPart:IsA("Model") then
			root = characterOrPart:FindFirstChild("HumanoidRootPart") or characterOrPart.PrimaryPart
		end

		local antiKnockback = characterOrPart:GetAttribute("Antiknockback")

		--# check


		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = (Vector3.one * 1e7) * Vector3.new(1, 0, 1)
		bodyVelocity.Velocity = velocity
		if yForce then
			bodyVelocity.MaxForce += Vector3.new(0, 1e7, 0)
		end

		--# bypasser/anti check
		if (antiKnockback or characterOrPart:FindFirstChild("ForceField")) and not bypass then
			bodyVelocity.MaxForce *= 0
		end

		--# ragdoll
		if ragdollTime and ragdollTime > 0 then
			if characterOrPart:IsA("Model") then
				NS([[
				local character, duration = ...
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = humanoid.RootPart or character:FindFirstChild("HumanoidRootPart")
				
				--|| main
				
				humanoid.PlatformStand = true
				
				while true do
					if root.AssemblyLinearVelocity.Magnitude > 0.3 then 
						task.wait()
						continue 
					end

					task.wait(1)
					duration -= 1
					if duration <= 0 then break end
				end
				
				humanoid.PlatformStand = false
				]], characterOrPart, characterOrPart, ragdollTime)
			end
		end
		--# parent
		bodyVelocity.Parent = root
		Debris:AddItem(bodyVelocity, duration or 0.1)

		return bodyVelocity
	end

	--# hitbox

--[=====[<custom>
	Processes a list of parts and determines which humanoid models and debris items have been touched by a hitbox. It helps identify entities affected by an attack, area effect, or collision.

	<md>
	**list**: A list of parts detected within the hitbox.
	**special**: A table of special conditions modifying detection behavior based on the special conditions given from the `system:Hitbox` method.
]=====]
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
				local host = v:IsDescendantOf(workspace)
				if host then
					local host = v:FindFirstAncestor("ItemHost")
					if not host then continue end

					local findDebris = table.find(debrisItem, v)
					if findDebris then continue end

					table.insert(debrisItem, v)
				end
			end		
		end

		--# return
		return humanoidModel, debrisItem
	end

--[=====[<custom>
	Generates a temporary hitbox around a character, detecting entities within its bounds. It supports custom offsets, sizes, and shapes, and includes optional special behaviors.

	<md>
	**character**: The character model generating the hitbox.
	**offset**: Adjusts the hitbox's position relative to the character.
	**size**: Defines the hitbox's dimensions. If a `number` is given, the hitbox will be a cube of that size.
	**shape**: Shape of the hitbox (`Block`, `Ball`, `Cylinder`, etc.)
	**special**: A table of special conditions modifying hitbox behavior. See below.
	
	***Special conditions***
	- `ChangeName`: Allows renaming the hitbox. If `special.HitboxName` is set, it will use that name.
	- `InPlace`: Keeps the hitbox fixed at the character's position instead of moving forward.
	- `Static`: Prevents velocity prediction, keeping the hitbox at the exact offset.
	- `GetDebris`: Returns debris items detected in the hitbox range.
	<cs>
	local character = workspace.Meatloaferss
	local data, models, debris = system:Hitbox(character, nil, 7, "Block", {"GetDebris"})
	for _, model in pairs(models) do
    print("Hit model:", model.Name)
	end
	for _, item in pairs(debris) do
    print("Detected debris:", item.Name)
	end
]=====]
	function system:Hitbox(character : Model, offset : CFrame, size : Vector3, shape : string | Enum.PartType, special:{string})
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
		local root:Part = humanoid.RootPart or character:FindFirstChild("HumanoidRootPart")
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
			pos = root:GetPivot() * offset
		else
			pos = (root:GetPivot() * CFrame.new(0, 0, -size.Z/2)) * offset
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

		local parts = workspace:GetPartsInPart(hitbox, params)
		local models : Model, debrises : Part = GetTouched(parts, special)

		Debris:AddItem(hitbox, 1)
		if table.find(special, "GetDebris") then
			return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models, debrises
		else
			return {Size = size, Shape = shape, CFrame = hitbox.CFrame}, models
		end
	end


    function system:Help(functionName : string)
        if system[functionName] then
            local value = nil
			if functionName == "Velocity" then
				value = [[
                Example:
                local character = script.Parent
	
	            system:Velocity(character, Vector3.new(50, 0, 50), true, 0.2, 2, false, false)
                ]]
            elseif functionName == "Hitbox" then
                value = [[
                <b>Special conditions</b>
                - <u>ChangeName</u>: Allows renaming the hitbox. If `special.HitboxName` is set, it will use that name.
                - <u>InPlace</u>: Keeps the hitbox fixed at the character's position instead of moving forward.
                - <u>Static</u>: Prevents velocity prediction, keeping the hitbox at the exact offset.
                - <u>GetDebris</u>: Returns debris items detected in the hitbox range.
                
                Example:
                local character = workspace.Meatloaferss
                local data, models, debris = system:Hitbox(character, nil, 7, "Block", {"GetDebris"})

                for _, model in pairs(models) do
                print("Hit model:", model.Name)
                end
                for _, item in pairs(debris) do
                print("Detected debris:", item.Name)
                end
                ]]
            elseif functionName == "Damage" then
                value = [[
                <b>Special conditions</b>
                - <u>MaxHP%</u>: Damage is calculated as a percentage of the target’s maximum health.
                - <u>HP%</u>: Damage is calculated as a percentage of the target’s current health.
                - <u>IgnoreResistance</u>: Ignores the target's resistance when calculating damage reduction.
                - <u>IgnoreGoodRES</u>: Prevents resistance from reducing damage if resistance is above 0.
                
                Example:
                local attacker = script.Parent
                local target = hit.Parent

                system:Damage(attacker, target, nil, 25)
                ]]
            elseif functionName == "Tween" then
                value = [[
                Example:
                local door = workspace.Door

                system.Tween(door, 3, {
                    Position = door.Position + Vector3.new(0, 5, 0),
                    Transparency = 0.5
                }, "Bounce", "In")
                ]]
			elseif functionName == "Status" then
				value = [[
				<b>Available status type<b>
				- <u>Stun</u>: Prevents the user from attacking, using Items, or calling Helpers. Forcefully slows the user down.
				
				Example:
                local target = hit.Parent

                system:Status(target, "stun", 2)
				]]
            elseif functionName == "MakeSound" then
                value = [[
                Example:
                local sound = game.ReplicatedStorage.Sounds.Wind
                local properties = {
                    Volume = 0.5,
                    PlaybackSpeed = 1.2,
                    Looping = true
                }

                system.MakeSound(sound, game.Workspace, properties, true)
                ]]
            else
                value = [[Help is used to show how a method works. Like what you're seeing right now.]]
            end

            printf(value)
        else
            print("Can't find the method, here's a list:")
            for i, v in system do
                print(i)
            end
		end
    end

	Modular = system
end

return Modular