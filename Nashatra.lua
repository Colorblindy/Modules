local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| variables

local system = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Colorblindy/Modules/refs/heads/main/Modular.lua"))();
local AnimationTrack = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/MechaXYZ/modules/raw/main/Anitracker.lua"))()

local assets = nil
local anims = loadstring

--# player

local player:Player = owner
local character = player.Character
local humanoid = character:FindFirstChildOfClass"Humanoid"
local root = humanoid.RootPart or character:FindFirstChild("HumanoidRootPart")

local remote = Instance.new("RemoteEvent")
remote.Name = "Hotkey"
remote.Parent = character
NLS([[
    local UserInputService = game:GetService("UserInputService")
    local remote = ...

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.E then
            remote:FireServer("E")
        elseif input.KeyCode == Enum.KeyCode.R then
            remote:FireServer("R")
        elseif input.KeyCode == Enum.KeyCode.F then
            remote:FireServer("F")
        end
    end)
]], player.PlayerGui, remote)

--# model setups

local bunkerHillModel = Instance.new('Part')
bunkerHillModel.Name = 'BunkerHill'
bunkerHillModel.Locked = false
bunkerHillModel.Size = Vector3.new(0.699999988079071, 5.800000190734863, 0.8762998580932617)
bunkerHillModel.CanCollide = false
bunkerHillModel.CanTouch = false
bunkerHillModel.CanQuery = false
bunkerHillModel.Anchored = false
bunkerHillModel.CustomPhysicalProperties = nil
bunkerHillModel.Massless = true

do
    local mesh = Instance.new('SpecialMesh')
    mesh.MeshId = 'rbxassetid://117509129855610'
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.Scale = Vector3.new(1, 1.3094459772109985, 1)
    mesh.TextureId = 'rbxassetid://13909150665'
    mesh.Parent = bunkerHillModel
end

--# usage
local using = "None"

local bunkerHillDebounces = {
    deb = false,
    Q = false,
    E = false,
    F = false,
    M1Usage = 0
}
local bunkerCombo = 1

--# hitbox
local hits = {}
local hit = false

--# remote
local client = Instance.new("RemoteEvent")
client.Name = "Client"
client.Parent = character
NLS([[
    local client = ...

    client.OnClientEvent:Connect(function(case, special)
        if not special or typeof(special) ~= "table" then
            special = {special}
        end

        if case == "HitboxVisualize" then
            if owner:GetAttribute("HitboxDebug") then
                local hitbox = Instance.new("Part")
                hitbox.Material = "ForceField"
                hitbox.Anchored = true
                hitbox.Massless = true
                hitbox.CanQuery, hitbox.CanTouch, hitbox.CanCollide = false, false, false
                hitbox.Transparency = 0
                hitbox.Color = special[2] and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                for i, v in pairs(special[1]) do
                    hitbox[i] = v
                end

                hitbox.Name = "VISUALIZATION_"..game:GetService("HttpService"):GenerateGUID(false)..""
                hitbox.Parent = workspace

                game:GetService("Debris"):AddItem(hitbox, 3)
            end
        end
    end)
]], player.PlayerGui, client)

--|| function

function CreateTool(jointType : string, part0 : BasePart, part1 : BasePart, C0 : CFrame, C1 : CFrame)
    assert(jointType == "Weld" or jointType == "Motor6D" or jointType == "WeldConstraint", "Not a correct JointType.")

    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local joint = Instance.new(jointType)
    if not joint:IsA("WeldConstraint") then
        joint.Part0 = part0
        joint.Part1 = part1
        joint.C0 = C0
        joint.C1 = C1
    end
    joint.Parent = part1
    part1.Parent = tool
    
    return tool
end

function NewAnimation(animTrack, link : string)
    if animTrack then
        animTrack:setAnimation(link)
        animTrack:setRig(character)
        animTrack:Play()
    end
end

function CreateSounds(id : string, name : string, parent : Instance)
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Name = name
    sound.Volume = 1
    sound.Parent = parent
end

function GetSound(parent : Instance, name : string)
    return parent:FindFirstChild(name)
end

--# Effects

function StudBlood(part : BasePart, count : number)
    task.spawn(function()
        for i = 1, count do
            local blood = Instance.new("Part")
            blood.Size = Vector3.one
            blood.CanQuery = false
            blood.CFrame = part.CFrame
            blood.Shape = "Ball"
            blood.Color = Color3.new(0.9, 0, 0)

            local blockmesh = Instance.new('SpecialMesh')
            blockmesh.MeshType = Enum.MeshType.Brick
            blockmesh.Scale = Vector3.new(1, 0.5, 1)
            blockmesh.Parent = blood

            blood.Parent = workspace
            blood.TopSurface = Enum.SurfaceType.Weld
            blood.BottomSurface = Enum.SurfaceType.Weld
            blood.Material = "Plastic"
            
            blood.AssemblyLinearVelocity = Vector3.new(
                math.random(-3, 3), 5, math.random(-3, 3)
            ) * 1.5
            blood.AssemblyAngularVelocity = Vector3.new(
                math.random(-2, 2), math.random(-2, 2), math.random(-2, 2)
            )
        
            Debris:AddItem(blood, 4)
        end
    end)
end


-- Make Hitbox
function BunkerHillHitbox(offset : CFrame | nil, size : Vector3, combo)
	local hitbox, model = system:Hitbox(character, offset, size, "Block", {})
	
	for i, target:Model in model do
        hit = true

		if not table.find(hits, target) then
			table.insert(hits, target)
			
			local fhum:Humanoid = target:FindFirstChildOfClass("Humanoid")
			local fplr = game.Players:GetPlayerFromCharacter(target)

            if fhum then
                if fhum.Health > 0 then
                    hit = true
                end
    
                local hroot = fhum.RootPart
    
                --|| hit variables
    
                local damage = 10
                local getCombo = combo
    
                if fhum.Health > 0 then
                    StudBlood(target.Torso, math.random(3, 14))
                end

                if getCombo ~= 3 then
                    system:Status(target, "stun", 1.5)
                    system:Damage(character, target, player, damage, {"MaxHP%"})
                else
                    for i, v:Instance in pairs(target:GetDescendants()) do
                        if v.Name == "StunPos" and v:IsA"BodyPosition" then
                            v:Destroy()
                        end
                    end
                    system:Velocity(target, root.CFrame.LookVector * 35, false, 0.2, 3, nil, nil)
                    system:Damage(character, target, player, damage + 15, {"MaxHP%"})
                end
            end
		end
	end
	
	client:FireClient(player, "HitboxVisualize", {hitbox, hit})
end

--|| main

--# make massless (for velocity usage)
for i, v:Instance in pairs(character:GetChildren()) do
    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
        v.Massless = true
    end
end

--# tool creation
local bunkerHill = CreateTool("Motor6D", character["Right Arm"], bunkerHillModel, CFrame.new(0, -0.950000048, -1.90734863e-06, -1, 7.10542736e-14, -4.43421748e-19, 1.9100593e-19, 5.23931752e-23, -1, -7.10542736e-14, -1, 5.23931752e-23), CFrame.new(-1.31450365e-13, -1.84999943, 5.76324107e-24, 1, -1.2166914e-40, 1.00966327e-18, -6.87701234e-41, 1, -2.51487241e-22, 1.00966327e-18, -2.51487241e-22, 1))
bunkerHill.Name = "Sword of Bunker Hill"
bunkerHill.ToolTip = "A worthy holder will know peace in death."
bunkerHill.Parent = player.Backpack

--# set up sounds
CreateSounds("rbxassetid://12222208", "SwordLunge", bunkerHillModel)
CreateSounds("rbxassetid://12222216", "SwordSlash", bunkerHillModel)
CreateSounds("rbxassetid://12222095", "JetBoots", root)

--# animation starter
AnimationTrack.NoDisableTransition = true
local anim = AnimationTrack.new()

bunkerHill.Equipped:Connect(function()
    using = "BunkerHill"
end)

bunkerHill.Unequipped:Connect(function()
    using = "None"
    bunkerHillDebounces.M1Usage += 1

    if bunkerCombo > 1 then
        bunkerCombo = 1
    end
end)

bunkerHill.Activated:Connect(function()
    if bunkerHillDebounces.deb then return end
    bunkerHillDebounces.deb = true

    bunkerHillDebounces.M1Usage += 1

    local comboGet = bunkerCombo
    local m1Usage = bunkerHillDebounces.M1Usage
    local extraCD = 0

    anim:Stop()
    NewAnimation(anim, "https://raw.githubusercontent.com/Colorblindy/Modules/refs/heads/main/Animations/Nashatra/Combo" .. bunkerCombo .. ".lua")

      --# events
      task.delay(.25, function()
        if m1Usage == bunkerHillDebounces.M1Usage then
            local frame = 10
            if comboGet == 3 then
                frame = 17
                system:Velocity(character, root.CFrame.LookVector * 40, nil, nil, nil, true, nil)
                system.MakeSound(GetSound(bunkerHillModel, "SwordLunge"), bunkerHillModel)
            else
                system:Velocity(character, root.CFrame.LookVector * 20, nil, nil, nil, true, nil)
                system.MakeSound(GetSound(bunkerHillModel, "SwordSlash"), bunkerHillModel)
            end

            --# hitbox
            hits = {}
            hit = false

            for i = 1, frame do
                if bunkerHillDebounces.M1Usage == m1Usage then
                    BunkerHillHitbox(nil, Vector3.new(6, 6, 6), comboGet)
                end

                task.wait()
            end
        end
    end)

    --# combo reset
    task.delay(0.9, function()
        if bunkerHillDebounces.M1Usage == m1Usage then
            bunkerCombo = 1
        end
    end)

    --# debounce and combo main
    local secondDelay = 0.55
    if comboGet < 3 then
        bunkerCombo += 1
    else
        bunkerCombo = 1
        secondDelay = 1.25
    end

    task.delay(secondDelay, function()
        bunkerHillDebounces.deb = false
    end)
end)

--# hotkey

remote.OnServerEvent:Connect(function(plr, key)
    print(using, key)
    if using == "None" then
        return
    end

    if key == "E" then
        if using == "BunkerHill" then
            if bunkerHillDebounces.E then return end
            bunkerHillDebounces.E = true

            local velo:BodyVelocity = system:Velocity(character, Vector3.new(0, 8, 0), true, 6, nil, true, nil)
            system.MakeSound(GetSound(root, "JetBoots"), root, {Volume = 1})
            local exhaust = task.spawn(function()
                while true do
                    local part = Instance.new("Part")
                    part.Anchored = false
                    part.CanCollide = true
                    part.CanQuery = false
                    part.Size = Vector3.new(1, 1, 1)
                    part.Color = Color3.new(1, 0.5, 0)
                    part.Shape = Enum.PartType.Cylinder
                    part.Material = "Plastic"

                    part.TopSurface = Enum.SurfaceType.Studs
                    part.BottomSurface = Enum.SurfaceType.Studs

                    part.CFrame = root.CFrame * CFrame.new(0, -3.1, 0)
                    part.Parent = workspace

                    part.AssemblyLinearVelocity = Vector3.new(
                        math.random(-7, 7), 0, math.random(-7, 7)
                    ) * 1.5
                    part.AssemblyAngularVelocity = Vector3.new(
                        math.random(-10, 10), math.random(-10, 10), math.random(-10, 10)
                    )

                    NS([[
                        local StudBlood, system = ...
                        local part = script.Parent
                        
                        part.Touched:Connect(function(hit)
                            if hit.Parent == owner.Character or part:GetAttribute("RunOut") then
                                return
                            end

                            if hit.Parent:IsA("Model") and hit.Parent:FindFirstChildOfClass("Humanoid") then
                                part.CanTouch = false

                                local fhum:Humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
                                local fplr = game.Players:GetPlayerFromCharacter(hit.Parent)
                                
                                if fhum then
                                    if fhum.Health > 0 then
                                        StudBlood(fhum.RootPart, math.random(3, 10))
                                    end

                                    system:Damage(owner.Character, hit.Parent, owner, 10, {"MaxHP%"}) 
                                end
                            end
                        end)
                    ]], part, StudBlood, system)

                    task.delay(3, function()
                        part:SetAttribute("RunOut", true)
                        part.Color = Color3.new(0, 0, 0)
                    end)
                    Debris:AddItem(part, 3.5)

                    task.wait(0.04)
                end
            end)

            task.delay(6, function()
                task.cancel(exhaust)
            end)

            task.wait(9)
            bunkerHillDebounces.E = false
        end
    elseif key == "R" then
        if using == "BunkerHill" then
            
        end
    elseif key == "F" then
        if using == "BunkerHill" then
            
        end
    end
end)