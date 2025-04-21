--[[
	ModelLoader.lua

	This module provides functionality to load and manage predefined 3D models (assets) in Roblox.
	It defines a set of asset constructors and exposes methods to check, list, and retrieve these models.

	Assets:
	- DTM: A complex model consisting of multiple parts, surface GUIs, image labels, and welds.

	Functions:
	- module.Check(name: string) -> boolean
		Checks if an asset with the given name exists in the module.
		@param name (string): The name of the asset to check.
		@return (boolean): True if the asset exists, otherwise nil.

	- module.List() -> table
		Returns a list of all available asset names.
		@return (table): Array of asset names (strings).

	- module.Get(name: string) -> Instance | nil
		Returns a new instance of the specified asset model.
		@param name (string): The name of the asset to retrieve.
		@return (Instance): The constructed model instance if found, otherwise warns and returns nil.

	Usage:
		local modelLoader = require(path.to.ModelLoader)
		if modelLoader.Check("DTM") then
			local dtmModel = modelLoader.Get("DTM")
			dtmModel.Parent = workspace
		end
]]

local modelLoader
local assetModule

do 
	local assets = {}
	
	assets.DTM = function()
		local DTM = Instance.new("Model")
		DTM.Name = "DTM"
		DTM.WorldPivot = CFrame.new(20.909984588623047, 2.5, -28.589984893798828)

		local Band = Instance.new("Part")
		Band.Name = "Band"
		Band.CFrame = CFrame.new(20.909984588623047, 2.5, -28.589984893798828)
		Band.BottomSurface = Enum.SurfaceType.Smooth
		Band.CanCollide = false
		Band.TopSurface = Enum.SurfaceType.Smooth
		Band.CanQuery = false
		Band.Color = Color3.fromRGB(17, 17, 17)
		Band.Size = Vector3.new(5.019999980926514, 1.7999999523162842, 5.019999980926514)
		Band.CanTouch = false
		Band.Parent = DTM

		local ImageText = Instance.new("SurfaceGui")
		ImageText.Name = "ImageText"
		ImageText.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ImageText.ClipsDescendants = true
		ImageText.LightInfluence = 1
		ImageText.MaxDistance = 1000
		ImageText.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		ImageText.Parent = Band

		local ImageLabel = Instance.new("ImageLabel")
		ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel.Size = UDim2.new(0.3585657, 0, 1, 0)
		ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel.BorderSizePixel = 0
		ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel.Image = "rbxassetid://113310478316780"
		ImageLabel.Parent = ImageText

		local ImageText1 = Instance.new("SurfaceGui")
		ImageText1.Name = "ImageText"
		ImageText1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ImageText1.Face = Enum.NormalId.Back
		ImageText1.ClipsDescendants = true
		ImageText1.LightInfluence = 1
		ImageText1.MaxDistance = 1000
		ImageText1.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		ImageText1.Parent = Band

		local ImageLabel1 = Instance.new("ImageLabel")
		ImageLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel1.Size = UDim2.new(0.3585657, 0, 1, 0)
		ImageLabel1.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel1.BackgroundTransparency = 1
		ImageLabel1.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel1.BorderSizePixel = 0
		ImageLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel1.Image = "rbxassetid://113310478316780"
		ImageLabel1.Parent = ImageText1

		local ImageText2 = Instance.new("SurfaceGui")
		ImageText2.Name = "ImageText"
		ImageText2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ImageText2.Face = Enum.NormalId.Right
		ImageText2.ClipsDescendants = true
		ImageText2.LightInfluence = 1
		ImageText2.MaxDistance = 1000
		ImageText2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		ImageText2.Parent = Band

		local ImageLabel2 = Instance.new("ImageLabel")
		ImageLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel2.Size = UDim2.new(0.3585657, 0, 1, 0)
		ImageLabel2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel2.BackgroundTransparency = 1
		ImageLabel2.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel2.BorderSizePixel = 0
		ImageLabel2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel2.Image = "rbxassetid://113310478316780"
		ImageLabel2.Parent = ImageText2

		local ImageText3 = Instance.new("SurfaceGui")
		ImageText3.Name = "ImageText"
		ImageText3.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ImageText3.Face = Enum.NormalId.Left
		ImageText3.ClipsDescendants = true
		ImageText3.LightInfluence = 1
		ImageText3.MaxDistance = 1000
		ImageText3.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		ImageText3.Parent = Band

		local ImageLabel3 = Instance.new("ImageLabel")
		ImageLabel3.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel3.Size = UDim2.new(0.3585657, 0, 1, 0)
		ImageLabel3.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel3.BackgroundTransparency = 1
		ImageLabel3.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel3.BorderSizePixel = 0
		ImageLabel3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel3.Image = "rbxassetid://113310478316780"
		ImageLabel3.Parent = ImageText3

		local Box = Instance.new("Part")
		Box.Name = "Box"
		Box.CFrame = CFrame.new(20.909984588623047, 2.5, -28.589984893798828)
		Box.BottomSurface = Enum.SurfaceType.Smooth
		Box.TopSurface = Enum.SurfaceType.Smooth
		Box.Color = Color3.fromRGB(239, 184, 56)
		Box.Size = Vector3.new(5, 5, 5)
		Box.Parent = DTM

		local Button = Instance.new("Weld")
		Button.Name = "Button"
		Button.C0 = CFrame.new(0, 2.8999991416931152, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0)
		Button.Parent = Box

		local Band1 = Instance.new("Weld")
		Band1.Name = "Band"
		Band1.Parent = Box

		local Button1 = Instance.new("Part")
		Button1.Name = "Button"
		Button1.CFrame = CFrame.new(20.909984588623047, 5.399999141693115, -28.589984893798828, 0, 0, 1, 1, 0, 0, 0, 1, 0)
		Button1.BottomSurface = Enum.SurfaceType.Smooth
		Button1.TopSurface = Enum.SurfaceType.Smooth
		Button1.Color = Color3.fromRGB(196, 40, 28)
		Button1.Size = Vector3.new(0.7999999523162842, 2.799999952316284, 2.5999999046325684)
		Button1.Shape = Enum.PartType.Cylinder
		Button1.Parent = DTM

		local ImageText4 = Instance.new("SurfaceGui")
		ImageText4.Name = "ImageText"
		ImageText4.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ImageText4.Face = Enum.NormalId.Right
		ImageText4.ClipsDescendants = true
		ImageText4.LightInfluence = 1
		ImageText4.MaxDistance = 1000
		ImageText4.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		ImageText4.PixelsPerStud = 1000
		ImageText4.Parent = Button1

		local ImageLabel4 = Instance.new("ImageLabel")
		ImageLabel4.AnchorPoint = Vector2.new(0.5, 0.5)
		ImageLabel4.Size = UDim2.new(1, 0, 1, 0)
		ImageLabel4.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageLabel4.BackgroundTransparency = 1
		ImageLabel4.Position = UDim2.new(0.5, 0, 0.5, 0)
		ImageLabel4.BorderSizePixel = 0
		ImageLabel4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageLabel4.ResampleMode = Enum.ResamplerMode.Pixelated
		ImageLabel4.Image = "rbxassetid://81872523754726"
		ImageLabel4.Parent = ImageText4

		ImageText.Adornee = Band

		ImageText1.Adornee = Band

		ImageText2.Adornee = Band

		ImageText3.Adornee = Band

		Button.Part1 = Button1
		Button.Part0 = Box

		Band1.Part1 = Band
		Band1.Part0 = Box

		ImageText4.Adornee = Button1

		DTM.PrimaryPart = Box

		return DTM
	end
	
	assetModule = assets
end

do 
	local module = {}
	local assets, names = assetModule, {}
	for i, v in pairs(assets) do
		table.insert(names, i)
	end

	function module.Check(name : string)
		if assets[name] then
			return true
		end
	end

	function module.List()
		return names
	end

	function module.Get(name : string)
		if assets[name] then
			return assets[name]()
		end
		
		return warnf("Cannot find the specified model.")
	end
	
	modelLoader = module
end

return modelLoader