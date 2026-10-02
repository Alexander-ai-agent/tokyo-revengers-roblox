-- PoliceService.lua
-- Wanted-level tracking, stub police NPCs, and auto-arrest at max wanted.
-- Place this in: src/server/PoliceService.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local PoliceService = {}

-- STUB: jail teleport position. Replace with the real jail spawn from the 3D builder.
local JAIL_SPAWN_POSITION = Vector3.new(0, 5, -500)

-- In-memory per-player state (not persisted — wanted level resets on rejoin)
local wantedLevels = {}
local policeNpcs = {}
local jailed = {}

local function fireWantedChanged(player, level)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("WantedLevelChanged")
	if evt then
		evt:FireClient(player, level)
	end
end

-- Stub NPC: a simple anchored dummy model standing near the player.
-- Replace with a real police NPC rig + AI once available.
local function spawnPoliceNpc(player)
	if policeNpcs[player.UserId] then return end
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local npc = Instance.new("Part")
	npc.Name = "PoliceNPC_Stub"
	npc.Size = Vector3.new(2, 5, 1)
	npc.Color = Color3.fromRGB(0, 60, 180)
	npc.Anchored = true
	npc.CanCollide = false
	npc.Position = root.Position + Vector3.new(10, 0, 0)

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(100, 30)
	label.StudsOffset = Vector3.new(0, 3, 0)
	label.AlwaysOnTop = true
	label.Parent = npc

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.Font = Enum.Font.SourceSansBold
	text.Text = "POLICE"
	text.Parent = label

	npc.Parent = Workspace
	policeNpcs[player.UserId] = npc
end

local function removePoliceNpc(player)
	local npc = policeNpcs[player.UserId]
	if npc then
		npc:Destroy()
		policeNpcs[player.UserId] = nil
	end
end

local function arrest(player)
	jailed[player.UserId] = true
	wantedLevels[player.UserId] = 0
	fireWantedChanged(player, 0)
	removePoliceNpc(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		root.CFrame = CFrame.new(JAIL_SPAWN_POSITION)
	end
	if humanoid then
		humanoid.WalkSpeed = 0
	end

	print(("[PoliceService] %s was arrested and jailed for %ds"):format(player.Name, Constants.JAIL_DURATION))

	task.delay(Constants.JAIL_DURATION, function()
		jailed[player.UserId] = nil
		if humanoid then
			humanoid.WalkSpeed = 16
		end
		print(("[PoliceService] %s was released from jail"):format(player.Name))
	end)
end

-- PUBLIC: Is this player currently serving jail time?
function PoliceService.isJailed(player)
	return jailed[player.UserId] == true
end

-- PUBLIC: Current wanted level (0-5 stars)
function PoliceService.getWanted(player)
	return wantedLevels[player.UserId] or 0
end

-- PUBLIC: Add wanted stars, clamped to MAX_WANTED. Handles NPC spawn / arrest thresholds.
function PoliceService.addWanted(player, stars)
	if jailed[player.UserId] then return end

	local current = wantedLevels[player.UserId] or 0
	local newLevel = math.clamp(current + stars, 0, Constants.MAX_WANTED)
	wantedLevels[player.UserId] = newLevel
	fireWantedChanged(player, newLevel)

	if newLevel >= Constants.POLICE_NPC_WANTED_THRESHOLD then
		spawnPoliceNpc(player)
	else
		removePoliceNpc(player)
	end

	if newLevel >= Constants.MAX_WANTED then
		arrest(player)
	end
end

-- PUBLIC: Clear a player's wanted level entirely.
function PoliceService.clearWanted(player)
	wantedLevels[player.UserId] = 0
	fireWantedChanged(player, 0)
	removePoliceNpc(player)
end

local function onPlayerAdded(player)
	wantedLevels[player.UserId] = 0
	jailed[player.UserId] = nil
end

local function onPlayerRemoving(player)
	removePoliceNpc(player)
	wantedLevels[player.UserId] = nil
	jailed[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

return PoliceService
