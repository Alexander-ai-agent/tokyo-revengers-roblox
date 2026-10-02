-- GangSelectionUI.lua
-- Full-screen gang-selection GUI shown once on first join (gang == nil).
-- Place this in: src/client/GangSelectionUI.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GangData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GangData"))

local GangSelectionUI = {}

local player = Players.LocalPlayer

local function buildCard(gangKey, gangInfo, parent, onSelect)
	local card = Instance.new("Frame")
	card.Name = gangKey
	card.Size = UDim2.fromOffset(220, 150)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	card.BorderSizePixel = 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(1, 0, 0, 8)
	swatch.Position = UDim2.fromOffset(0, 0)
	swatch.BorderSizePixel = 0
	swatch.BackgroundColor3 = Color3.fromRGB(gangInfo.color[1], gangInfo.color[2], gangInfo.color[3])
	swatch.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -16, 0, 24)
	nameLabel.Position = UDim2.fromOffset(8, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = gangInfo.displayName
	nameLabel.Parent = card

	local cityLabel = Instance.new("TextLabel")
	cityLabel.Size = UDim2.new(1, -16, 0, 18)
	cityLabel.Position = UDim2.fromOffset(8, 42)
	cityLabel.BackgroundTransparency = 1
	cityLabel.Font = Enum.Font.SourceSansItalic
	cityLabel.TextSize = 14
	cityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	cityLabel.TextXAlignment = Enum.TextXAlignment.Left
	cityLabel.Text = gangInfo.homeCity
	cityLabel.Parent = card

	local loreLabel = Instance.new("TextLabel")
	loreLabel.Size = UDim2.new(1, -16, 0, 60)
	loreLabel.Position = UDim2.fromOffset(8, 62)
	loreLabel.BackgroundTransparency = 1
	loreLabel.Font = Enum.Font.SourceSans
	loreLabel.TextSize = 13
	loreLabel.TextWrapped = true
	loreLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	loreLabel.TextXAlignment = Enum.TextXAlignment.Left
	loreLabel.TextYAlignment = Enum.TextYAlignment.Top
	loreLabel.Text = gangInfo.loreBlurb
	loreLabel.Parent = card

	local selectButton = Instance.new("TextButton")
	selectButton.Size = UDim2.new(1, -16, 0, 26)
	selectButton.Position = UDim2.new(0, 8, 1, -32)
	selectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	selectButton.Font = Enum.Font.SourceSansBold
	selectButton.TextSize = 14
	selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selectButton.Text = "Select"
	selectButton.Parent = card

	selectButton.MouseButton1Click:Connect(function()
		onSelect(gangKey, card)
	end)

	return card
end

-- PUBLIC: Build and show the gang selection screen. Calls onJoined() once a gang is confirmed.
function GangSelectionUI.show(onJoined)
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		warn("[GangSelectionUI] Remotes folder never appeared")
		return
	end
	local joinGangRemote = remotes:WaitForChild("JoinGang", 10)
	if not joinGangRemote then
		warn("[GangSelectionUI] JoinGang remote never appeared")
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GangSelectionUI"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.fromOffset(0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 32
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "Choose Your Gang"
	title.Parent = background

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -40, 1, -160)
	scrollFrame.Position = UDim2.fromOffset(20, 80)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.CanvasSize = UDim2.fromScale(0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = background

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(220, 150)
	gridLayout.CellPadding = UDim2.fromOffset(16, 16)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = scrollFrame

	local confirmButton = Instance.new("TextButton")
	confirmButton.Size = UDim2.fromOffset(200, 44)
	confirmButton.Position = UDim2.new(0.5, -100, 1, -60)
	confirmButton.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	confirmButton.Font = Enum.Font.SourceSansBold
	confirmButton.TextSize = 20
	confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmButton.Text = "Confirm"
	confirmButton.AutoButtonColor = true
	confirmButton.Visible = false
	confirmButton.Parent = background

	local selectedGangKey = nil
	local selectedCard = nil

	local function onCardSelected(gangKey, card)
		if selectedCard then
			selectedCard.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end
		selectedGangKey = gangKey
		selectedCard = card
		card.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		confirmButton.Visible = true
	end

	for gangKey, gangInfo in pairs(GangData) do
		buildCard(gangKey, gangInfo, scrollFrame, onCardSelected)
	end

	confirmButton.MouseButton1Click:Connect(function()
		if not selectedGangKey then return end
		joinGangRemote:FireServer(selectedGangKey)
		screenGui:Destroy()
		if onJoined then
			onJoined(selectedGangKey)
		end
	end)
end

return GangSelectionUI
