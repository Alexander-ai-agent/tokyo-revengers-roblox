-- GangWarService.lua
-- Gang war sessions: declaration, territory-kill scoring, and resolution.
-- Place this in: src/server/GangWarService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GangService = require(script.Parent.GangService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local GangWarService = {}

-- STUB: approximate zone center for each territory city, used only to guess which
-- zone a KO happened in. Replace with real Region3/part-based zones once the
-- 3D builder places actual territory boundaries.
local ZONE_POSITIONS = {
	Shibuya = Vector3.new(5000, 5, 0),
	Yokohama = Vector3.new(5300, 5, 0),
	Ikebukuro = Vector3.new(5600, 5, 0),
	Roppongi = Vector3.new(5900, 5, 0),
	Odaiba = Vector3.new(5000, 5, 300),
	Akihabara = Vector3.new(5300, 5, 300),
	Shinjuku = Vector3.new(5600, 5, 300),
	Asakusa = Vector3.new(5900, 5, 300),
	Nerima = Vector3.new(5000, 5, 600),
	Yotsuya = Vector3.new(5300, 5, 600),
	Kanto = Vector3.new(5600, 5, 600),
}

-- Active wars keyed by "attackerGang_defenderGang" -> { attacker, defender, score, endsAt }
local activeWars = {}

local function warKey(attackerGang, defenderGang)
	return attackerGang .. "_" .. defenderGang
end

local function findActiveWar(gangA, gangB)
	return activeWars[warKey(gangA, gangB)] or activeWars[warKey(gangB, gangA)]
end

-- Best-guess zone for a world position: nearest stub zone center.
local function getZoneAt(position)
	local closestZone, closestDist = nil, math.huge
	for zone, center in pairs(ZONE_POSITIONS) do
		local dist = (position - center).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestZone = zone
		end
	end
	return closestZone
end

local function applyWarResult(war)
	local attackerScore = war.score
	local winnerGang, loserGang

	-- Attacker needs at least one scored point to take the win; ties favor the defender.
	if attackerScore > 0 then
		winnerGang, loserGang = war.attacker, war.defender
	else
		winnerGang, loserGang = war.defender, war.attacker
	end

	local loserHomeCity = GangService.Gangs[loserGang] and GangService.Gangs[loserGang].homeCity
	if loserHomeCity then
		GangService.setTerritoryOwner(loserHomeCity, winnerGang)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerDataService.get(player, "gang") == loserGang then
			GangService.addReputation(player, -Constants.WAR_LOSER_REP_PENALTY)
		end
	end

	print(("[GangWarService] War %s vs %s ended. Winner: %s (score %d)"):format(
		war.attacker, war.defender, winnerGang, attackerScore
	))
end

-- PUBLIC: Start a war between two gangs. Auto-resolves after Constants.WAR_DURATION.
function GangWarService.declareWar(attackerGang, defenderGang)
	if not GangService.Gangs[attackerGang] or not GangService.Gangs[defenderGang] then
		return false, "Unknown gang in war declaration"
	end
	if attackerGang == defenderGang then
		return false, "A gang cannot declare war on itself"
	end
	if findActiveWar(attackerGang, defenderGang) then
		return false, "A war between these gangs is already active"
	end

	local key = warKey(attackerGang, defenderGang)
	activeWars[key] = {
		attacker = attackerGang,
		defender = defenderGang,
		score = 0,
		endsAt = os.clock() + Constants.WAR_DURATION,
	}

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local evt = remotes:FindFirstChild("WarDeclared")
		if evt then
			evt:FireAllClients(
				attackerGang,
				defenderGang,
				GangService.Gangs[attackerGang].displayName,
				GangService.Gangs[defenderGang].displayName
			)
		end
	end

	print(("[GangWarService] %s declared war on %s"):format(attackerGang, defenderGang))

	task.delay(Constants.WAR_DURATION, function()
		local war = activeWars[key]
		if war then
			activeWars[key] = nil
			applyWarResult(war)
		end
	end)

	return true
end

-- PUBLIC: Manually end a war early and apply the result immediately.
function GangWarService.endWar(attackerGang, defenderGang)
	local key = warKey(attackerGang, defenderGang)
	local war = activeWars[key]
	if not war then
		return false, "No active war between these gangs"
	end

	activeWars[key] = nil
	applyWarResult(war)
	return true
end

-- PUBLIC: Called by CombatService after a KO. Scores a point for the attacker's gang
-- if the KO happened inside the defender's territory during an active war.
function GangWarService.handleKO(attacker, victim)
	local attackerGang = PlayerDataService.get(attacker, "gang")
	local victimGang = PlayerDataService.get(victim, "gang")
	if not attackerGang or not victimGang or attackerGang == victimGang then
		return
	end

	local war = findActiveWar(attackerGang, victimGang)
	if not war or war.attacker ~= attackerGang or war.defender ~= victimGang then
		return
	end

	local character = victim.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local zone = getZoneAt(root.Position)
	if zone and GangService.getTerritoryOwner(zone) == victimGang then
		war.score += 1
		print(("[GangWarService] %s scored in %s. %s vs %s score: %d"):format(
			attacker.Name, zone, war.attacker, war.defender, war.score
		))
	end
end

return GangWarService
