-- EconomyService.lua
-- Money, bank robbery, missions, and gang business income.
-- Place this in: src/server/EconomyService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local GangService = require(script.Parent.GangService)
local PoliceService = require(script.Parent.PoliceService)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local EconomyService = {}

-- ============================================================
-- MISSIONS
-- ============================================================
local MISSIONS = {
	delivery_run = { name = "Delivery Run", reward = 150 },
	street_fight = { name = "Street Fight", reward = 200 },
	steal_car = { name = "Steal a Car", reward = 300 },
	protect_territory = { name = "Protect Territory", reward = 250 },
	escort_member = { name = "Escort a Member", reward = 180 },
	intimidate_rival = { name = "Intimidate a Rival", reward = 220 },
	collect_debt = { name = "Collect a Debt", reward = 170 },
	scout_enemy_turf = { name = "Scout Enemy Turf", reward = 190 },
	smuggle_goods = { name = "Smuggle Goods", reward = 280 },
	recruit_member = { name = "Recruit a New Member", reward = 120 },
}

-- ============================================================
-- INTERNAL COOLDOWN STATE (per player, in-memory only)
-- ============================================================
local lastRobTime = {}
local lastMissionTime = {}

local function now()
	return os.clock()
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Add money to a player. Always succeeds.
function EconomyService.giveMoney(player, amount)
	if amount <= 0 then return end
	PlayerDataService.increment(player, "money", amount)
end

-- Remove money from a player. Returns false if they can't afford it.
function EconomyService.takeMoney(player, amount)
	if amount <= 0 then return true end
	local current = PlayerDataService.get(player, "money") or 0
	if current < amount then
		return false
	end
	PlayerDataService.increment(player, "money", -amount)
	return true
end

-- Rob the bank: 60s cooldown per player, random payout, 10% chance of a police alert.
function EconomyService.robBank(player)
	local last = lastRobTime[player.UserId]
	local timeNow = now()
	if last and (timeNow - last) < Constants.BANK_ROB_COOLDOWN then
		local remaining = math.ceil(Constants.BANK_ROB_COOLDOWN - (timeNow - last))
		return false, "Bank is on cooldown for " .. remaining .. "s"
	end

	lastRobTime[player.UserId] = timeNow

	local payout = math.random(Constants.ROBBERY_MIN_PAYOUT, Constants.ROBBERY_MAX_PAYOUT)
	EconomyService.giveMoney(player, payout)

	local gotCaught = math.random() < Constants.ROBBERY_POLICE_CHANCE
	if gotCaught then
		PoliceService.addWanted(player, 1)
	end

	print(("[EconomyService] %s robbed the bank for $%d%s"):format(
		player.Name,
		payout,
		gotCaught and " (police alerted!)" or ""
	))

	return true, payout, gotCaught
end

-- Complete a mission by id. Enforces a shared cooldown between missions.
function EconomyService.doMission(player, missionId)
	local mission = MISSIONS[missionId]
	if not mission then
		return false, "Unknown mission: " .. tostring(missionId)
	end

	local last = lastMissionTime[player.UserId]
	local timeNow = now()
	if last and (timeNow - last) < Constants.MISSION_COOLDOWN then
		local remaining = math.ceil(Constants.MISSION_COOLDOWN - (timeNow - last))
		return false, "Missions are on cooldown for " .. remaining .. "s"
	end

	lastMissionTime[player.UserId] = timeNow
	EconomyService.giveMoney(player, mission.reward)

	print(("[EconomyService] %s completed mission '%s' for $%d"):format(player.Name, mission.name, mission.reward))
	return true, mission.reward
end

-- Passive income based on how many territories the player's gang controls.
function EconomyService.businessIncome(player)
	local gangKey = PlayerDataService.get(player, "gang")
	if not gangKey then return end

	local territories = GangService.getGangTerritories(gangKey)
	local income = #territories * Constants.BUSINESS_INCOME_PER_TERRITORY
	if income <= 0 then return end

	EconomyService.giveMoney(player, income)
end

return EconomyService
