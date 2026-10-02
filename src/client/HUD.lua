-- HUD.lua
-- Persistent HUD: money (top-left), gang + rank (top-right), wanted stars (bottom).
-- Place this in: src/client/HUD.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GangData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GangData"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local HUD = {}

local player = Players.LocalPlayer
local POLL_INTERVAL = 2

local function buildStarLabels(parent)
	local stars = {}
	for i = 1, Constants.MAX_WANTED do
		local star = Instance.new("TextLabel")
		star.Size = UDim2.fromOffset(28, 28)
		star.Position = UDim2.fromOffset((i - 1) * 30, 0)
		star.BackgroundTransparency = 1
		star.Font = Enum.Font.SourceSansBold
		star.TextSize = 26
		star.Text = "★"
		star.TextColor3 = Color3.fromRGB(90, 90, 90)
		star.Parent = parent
		stars[i] = star
	end
	return stars
end

local function setStars(stars, level)
	for i, star in ipairs(stars) do
		if i <= level then
			star.TextColor3 = Color3.fromRGB(230, 30, 30)
		else
			star.TextColor3 = Color3.fromRGB(90, 90, 90)
		end
	end
end

-- PUBLIC: Build and start the HUD. Safe to call once per client life.
function HUD.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		warn("[HUD] Remotes folder never appeared")
		return
	end
	local getPlayerData = remotes:WaitForChild("GetPlayerData", 10)
	local wantedChangedRemote = remotes:WaitForChild("WantedLevelChanged", 10)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Size = UDim2.fromOffset(200, 32)
	moneyLabel.Position = UDim2.fromOffset(16, 16)
	moneyLabel.BackgroundTransparency = 0.4
	moneyLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	moneyLabel.Font = Enum.Font.SourceSansBold
	moneyLabel.TextSize = 20
	moneyLabel.TextColor3 = Color3.fromRGB(80, 220, 100)
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Text = "$0"
	moneyLabel.Parent = screenGui

	local gangLabel = Instance.new("TextLabel")
	gangLabel.Size = UDim2.fromOffset(260, 32)
	gangLabel.Position = UDim2.new(1, -276, 0, 16)
	gangLabel.BackgroundTransparency = 0.4
	gangLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gangLabel.Font = Enum.Font.SourceSansBold
	gangLabel.TextSize = 18
	gangLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	gangLabel.TextXAlignment = Enum.TextXAlignment.Right
	gangLabel.Text = "No Gang"
	gangLabel.Parent = screenGui

	local starsFrame = Instance.new("Frame")
	starsFrame.Size = UDim2.fromOffset(30 * Constants.MAX_WANTED, 28)
	starsFrame.Position = UDim2.new(0.5, -(30 * Constants.MAX_WANTED) / 2, 1, -60)
	starsFrame.BackgroundTransparency = 1
	starsFrame.Parent = screenGui

	local stars = buildStarLabels(starsFrame)

	local function applyData(data)
		if not data then return end
		moneyLabel.Text = "$" .. tostring(data.money or 0)

		if data.gang and GangData[data.gang] then
			gangLabel.Text = ("%s — %s"):format(GangData[data.gang].displayName, tostring(data.gangRank or ""))
		else
			gangLabel.Text = "No Gang"
		end

		if data.wantedLevel then
			setStars(stars, data.wantedLevel)
		end
	end

	-- Initial fetch + real-time wanted updates
	local success, initialData = pcall(function()
		return getPlayerData:InvokeServer()
	end)
	if success then
		applyData(initialData)
	end

	if wantedChangedRemote then
		wantedChangedRemote.OnClientEvent:Connect(function(level)
			setStars(stars, level)
		end)
	end

	-- Fallback polling for money/rank (brief allows polling when no attribute stream exists)
	task.spawn(function()
		while screenGui.Parent do
			task.wait(POLL_INTERVAL)
			local ok, data = pcall(function()
				return getPlayerData:InvokeServer()
			end)
			if ok then
				applyData(data)
			end
		end
	end)
end

return HUD
