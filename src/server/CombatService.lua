-- CombatService.lua
-- Server-authoritative melee combat, KO handling, and respawn at gang house.
-- Place this in: src/server/CombatService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local GangService = require(script.Parent.GangService)
local GangWarService = require(script.Parent.GangWarService)
local HousingService = require(script.Parent.HousingService)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CombatService = {}

local MAX_KO_HEALTH = 100

-- In-memory per-player combat state (not persisted)
local koHealth = {}
local isKnockedOut = {}

local function fireToClient(remoteName, player, ...)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild(remoteName)
	if evt then
		evt:FireClient(player, ...)
	end
end

local function resetCombatState(player, character)
	koHealth[player.UserId] = MAX_KO_HEALTH
	isKnockedOut[player.UserId] = false

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Keep Roblox's own death/respawn out of the picture; our KO system owns health.
		humanoid.MaxHealth = math.huge
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end

local function respawnAtGangHouse(player)
	local houseId = PlayerDataService.get(player, "houseId")
	if houseId then
		HousingService.assignHouse(player, houseId)
	end

	local character = player.Character
	if character then
		resetCombatState(player, character)
	end

	fireToClient("PlayerKO", player, false)
	print(("[CombatService] %s respawned after KO"):format(player.Name))
end

local function onKO(victim, attacker)
	isKnockedOut[victim.UserId] = true

	local humanoid = victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	GangService.addReputation(attacker, Constants.KO_REP_REWARD)

	local victimMoney = PlayerDataService.get(victim, "money") or 0
	local stolen = math.min(Constants.KO_MONEY_STEAL, victimMoney)
	if stolen > 0 then
		PlayerDataService.increment(victim, "money", -stolen)
		PlayerDataService.increment(attacker, "money", stolen)
	end

	GangWarService.handleKO(attacker, victim)

	fireToClient("PlayerKO", victim, true)
	print(("[CombatService] %s was KO'd by %s"):format(victim.Name, attacker.Name))

	task.delay(Constants.RESPAWN_DELAY, function()
		if victim.Parent then
			respawnAtGangHouse(victim)
		end
	end)
end

-- PUBLIC: Server-authoritative damage application.
-- Validates range before applying; never trusts a client-supplied outcome.
function CombatService.dealDamage(attacker, victim, damage)
	if not attacker or not victim or attacker == victim then return end
	if isKnockedOut[victim.UserId] then return end

	local attackerChar = attacker.Character
	local victimChar = victim.Character
	if not attackerChar or not victimChar then return end

	local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	local victimRoot = victimChar:FindFirstChild("HumanoidRootPart")
	if not attackerRoot or not victimRoot then return end

	local distance = (attackerRoot.Position - victimRoot.Position).Magnitude
	if distance > Constants.COMBAT_RANGE then
		return
	end

	local current = koHealth[victim.UserId] or MAX_KO_HEALTH
	local newHealth = math.max(0, current - damage)
	koHealth[victim.UserId] = newHealth

	if newHealth <= 0 and not isKnockedOut[victim.UserId] then
		onKO(victim, attacker)
	end
end

local function onCharacterAdded(player, character)
	resetCombatState(player, character)
end

local function onPlayerAdded(player)
	koHealth[player.UserId] = MAX_KO_HEALTH
	isKnockedOut[player.UserId] = false
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	koHealth[player.UserId] = nil
	isKnockedOut[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

return CombatService
