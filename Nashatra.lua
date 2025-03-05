local system = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Colorblindy/Modules/refs/heads/main/Modular.lua"))();
local AnimationTrack = loadstring(game:GetService("HttpService"):GetAsync("https://github.com/MechaXYZ/modules/raw/main/Anitracker.lua"))()

--|| variables

local assets = nil
local anims = loadstring

--# player

local player:Player = owner
local character = player.Character

local remote = Instance.new("RemoteEvent")
remote.Name = "Hotkey"

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

--|| main

local bunkerHill = CreateTool("Motor6D", character["Right Arm"], bunkerHillModel, CFrame.new(0, -0.950000048, -1.90734863e-06, -1, 7.10542736e-14, -4.43421748e-19, 1.9100593e-19, 5.23931752e-23, -1, -7.10542736e-14, -1, 5.23931752e-23), CFrame.new(-1.31450365e-13, -1.84999943, 5.76324107e-24, 1, -1.2166914e-40, 1.00966327e-18, -6.87701234e-41, 1, -2.51487241e-22, 1.00966327e-18, -2.51487241e-22, 1))

bunkerHill.Name = "Sword of Bunker Hill"
bunkerHill.ToolTip = "A worthy holder will know peace in death."
bunkerHill.Parent = player.Backpack