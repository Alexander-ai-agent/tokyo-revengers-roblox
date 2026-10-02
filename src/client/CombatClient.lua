-- CombatClient.lua
-- Click-to-attack input handling and cosmetic damage numbers.
-- Server validates and applies all real damage; this script only sends intent.
-- Place this in: src/client/CombatClient.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CombatClient = {}

local player = Players.LocalPlayer

local function showDamageNumber(targetCharacter, amount)
	local head = targetCharacter:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 30)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.Text = "-" .. tostring(amount)
	label.Parent = billboard

	local tween = TweenService:Create(label, TweenInfo.new(Constants.DAMAGE_LABEL_FADE_TIME), {
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

-- PUBLIC: Start listening for melee click input.
function CombatClient.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		warn("[CombatClient] Remotes folder never appeared")
		return
	end
	local dealDamageRemote = remotes:WaitForChild("DealDamage", 10)
	if not dealDamageRemote then
		warn("[CombatClient] DealDamage remote never appeared")
		return
	end

	local mouse = player:GetMouse()
	local lastClickTime = 0

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local now = os.clock()
		if now - lastClickTime < Constants.COMBAT_CLICK_COOLDOWN then return end
		lastClickTime = now

		local target = mouse.Target
		if not target then return end

		local character = target:FindFirstAncestorOfClass("Model")
		if not character then return end
		if not character:FindFirstChildOfClass("Humanoid") then return end

		local targetPlayer = Players:GetPlayerFromCharacter(character)
		if not targetPlayer or targetPlayer == player then return end

		dealDamageRemote:FireServer(targetPlayer)
		showDamageNumber(character, Constants.BASE_MELEE_DAMAGE)
	end)
end

return CombatClient
