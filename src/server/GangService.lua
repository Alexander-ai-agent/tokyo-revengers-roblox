-- GangService.lua
-- Handles gang joining, ranks, territory ownership, and gang rosters
-- Place this in: src/server/GangService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local GangService = {}

-- ============================================================
-- GANG DEFINITIONS
-- ============================================================
GangService.Gangs = {
	Toman = {
		displayName = "Tokyo Manji Gang",
		color = Color3.fromRGB(0, 0, 180),       -- dark blue
		homeCity = "Shibuya",
		houseIds = { "toman_hq", "toman_house_1", "toman_house_2" },
		ranks = { "Recruit", "Member", "Captain", "Vice-Captain", "Commander", "President" },
		repThresholds = { 0, 100, 300, 700, 1500, 3000 },
	},
	BlackDragon = {
		displayName = "Black Dragon",
		color = Color3.fromRGB(20, 20, 20),
		homeCity = "Yokohama",
		houseIds = { "blackdragon_hq", "blackdragon_house_1" },
		ranks = { "Recruit", "Member", "Officer", "Commander", "Leader" },
		repThresholds = { 0, 150, 400, 900, 2000 },
	},
	Moebius = {
		displayName = "Moebius",
		color = Color3.fromRGB(180, 0, 0),
		homeCity = "Ikebukuro",
		houseIds = { "moebius_hq" },
		ranks = { "Recruit", "Member", "Lieutenant", "Leader" },
		repThresholds = { 0, 100, 350, 1000 },
	},
	Valhalla = {
		displayName = "Valhalla",
		color = Color3.fromRGB(100, 0, 180),
		homeCity = "Roppongi",
		houseIds = { "valhalla_hq" },
		ranks = { "Recruit", "Member", "General", "King" },
		repThresholds = { 0, 120, 400, 1200 },
	},
	Tenjiku = {
		displayName = "Tenjiku",
		color = Color3.fromRGB(200, 140, 0),
		homeCity = "Yokohama",
		houseIds = { "tenjiku_hq", "tenjiku_house_1" },
		ranks = { "Recruit", "Member", "Officer", "Executive", "Emperor" },
		repThresholds = { 0, 200, 500, 1200, 2500 },
	},
	Brahman = {
		displayName = "Brahman",
		color = Color3.fromRGB(220, 180, 60),
		homeCity = "Odaiba",
		houseIds = { "brahman_hq" },
		ranks = { "Recruit", "Member", "Elder", "Senju" },
		repThresholds = { 0, 150, 500, 1500 },
	},
	RokuharaTandai = {
		displayName = "Rokuhara Tandai",
		color = Color3.fromRGB(0, 160, 80),
		homeCity = "Akihabara",
		houseIds = { "rokuhara_hq" },
		ranks = { "Recruit", "Member", "Captain", "Top Three", "Sovereign" },
		repThresholds = { 0, 100, 300, 800, 2000 },
	},
	Bonten = {
		displayName = "Bonten",
		color = Color3.fromRGB(60, 0, 60),
		homeCity = "Shinjuku",
		houseIds = { "bonten_hq", "bonten_penthouse" },
		ranks = { "Affiliate", "Member", "Executive", "Bonten" },
		repThresholds = { 0, 300, 800, 2000 },
	},
	KodoRengo = {
		displayName = "Kodo Rengo",
		color = Color3.fromRGB(180, 60, 0),
		homeCity = "Asakusa",
		houseIds = { "kodoren_hq" },
		ranks = { "Recruit", "Member", "Captain", "Regent", "Don" },
		repThresholds = { 0, 100, 350, 900, 2200 },
	},
	Ragnarok = {
		displayName = "Ragnarok",
		color = Color3.fromRGB(0, 80, 160),
		homeCity = "Shibuya",
		houseIds = { "ragnarok_hq" },
		ranks = { "Recruit", "Member", "Warrior", "Jarl", "King" },
		repThresholds = { 0, 120, 380, 950, 2100 },
	},
	MizoMiddleFive = {
		displayName = "Mizo Middle Five",
		color = Color3.fromRGB(0, 120, 200),
		homeCity = "Nerima",
		houseIds = { "mizo_hq" },
		ranks = { "Member", "Starter", "Captain", "Ace" },
		repThresholds = { 0, 80, 250, 600 },
	},
	YotsuyaKaidan = {
		displayName = "Yotsuya Kaidan",
		color = Color3.fromRGB(140, 0, 0),
		homeCity = "Yotsuya",
		houseIds = { "yotsuya_hq" },
		ranks = { "Recruit", "Ghost", "Wraith", "Specter", "Phantom" },
		repThresholds = { 0, 100, 300, 700, 1600 },
	},
	S62Generation = {
		displayName = "S-62 Generation",
		color = Color3.fromRGB(40, 40, 40),
		homeCity = "Kanto",
		houseIds = { "s62_hq" },
		ranks = { "Recruit", "Member", "Veteran", "Legend" },
		repThresholds = { 0, 200, 600, 1800 },
	},
}

-- ============================================================
-- TERRITORY  (which gang currently owns which city zone)
-- Map: zoneId -> gangKey (string)
-- ============================================================
local territory = {
	Shibuya     = "Toman",
	Yokohama    = "BlackDragon",
	Ikebukuro   = "Moebius",
	Roppongi    = "Valhalla",
	Odaiba      = "Brahman",
	Akihabara   = "RokuharaTandai",
	Shinjuku    = "Bonten",
	Asakusa     = "KodoRengo",
	Nerima      = "MizoMiddleFive",
	Yotsuya     = "YotsuyaKaidan",
	Kanto       = "S62Generation",
}

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================

-- Pick the first available houseId for this gang
local function assignHouse(gangKey)
	local gang = GangService.Gangs[gangKey]
	if not gang then return nil end
	-- For now return the first house; later you can track occupancy
	return gang.houseIds[1]
end

-- Calculate rank from reputation
local function calcRank(gangKey, reputation)
	local gang = GangService.Gangs[gangKey]
	if not gang then return "Recruit" end
	local rankName = gang.ranks[1]
	for i, threshold in ipairs(gang.repThresholds) do
		if reputation >= threshold then
			rankName = gang.ranks[i]
		end
	end
	return rankName
end

-- ============================================================
-- PUBLIC API
-- ============================================================

-- Join a gang. Returns true/false + reason string.
function GangService.joinGang(player, gangKey)
	if not GangService.Gangs[gangKey] then
		return false, "Unknown gang: " .. tostring(gangKey)
	end

	local currentGang = PlayerDataService.get(player, "gang")
	if currentGang then
		return false, "Already in gang: " .. currentGang
	end

	local houseId = assignHouse(gangKey)
	PlayerDataService.set(player, "gang", gangKey)
	PlayerDataService.set(player, "gangRank", GangService.Gangs[gangKey].ranks[1])
	PlayerDataService.set(player, "houseId", houseId)
	PlayerDataService.set(player, "reputation", 0)

	print(("[GangService] %s joined %s | House: %s"):format(player.Name, gangKey, tostring(houseId)))
	return true, "Joined " .. GangService.Gangs[gangKey].displayName
end

-- Leave current gang (keeps money, resets gang fields)
function GangService.leaveGang(player)
	local currentGang = PlayerDataService.get(player, "gang")
	if not currentGang then
		return false, "Not in a gang"
	end
	PlayerDataService.set(player, "gang", nil)
	PlayerDataService.set(player, "gangRank", "Recruit")
	PlayerDataService.set(player, "houseId", nil)
	PlayerDataService.set(player, "reputation", 0)
	print(("[GangService] %s left %s"):format(player.Name, currentGang))
	return true, "Left gang"
end

-- Add reputation and auto-promote if threshold crossed
function GangService.addReputation(player, amount)
	local gangKey = PlayerDataService.get(player, "gang")
	if not gangKey then return end

	PlayerDataService.increment(player, "reputation", amount)
	local newRep = PlayerDataService.get(player, "reputation")
	local newRank = calcRank(gangKey, newRep)
	local oldRank = PlayerDataService.get(player, "gangRank")

	if newRank ~= oldRank then
		PlayerDataService.set(player, "gangRank", newRank)
		print(("[GangService] %s promoted to %s in %s"):format(player.Name, newRank, gangKey))
		-- Fire promotion event to client (RemoteEvent wired up in init.server.luau)
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if remotes then
			local evt = remotes:FindFirstChild("OnRankUp")
			if evt then evt:FireClient(player, gangKey, newRank) end
		end
	end
end

-- Get territory owner for a zone
function GangService.getTerritoryOwner(zoneId)
	return territory[zoneId]
end

-- Set territory owner (called by war system)
function GangService.setTerritoryOwner(zoneId, gangKey)
	territory[zoneId] = gangKey
	print(("[GangService] Territory %s now owned by %s"):format(zoneId, tostring(gangKey)))
end

-- Get all zones owned by a gang
function GangService.getGangTerritories(gangKey)
	local zones = {}
	for zone, owner in pairs(territory) do
		if owner == gangKey then
			table.insert(zones, zone)
		end
	end
	return zones
end

-- Get a player's full gang info (convenience)
function GangService.getGangInfo(player)
	local gangKey = PlayerDataService.get(player, "gang")
	if not gangKey then return nil end
	return {
		key      = gangKey,
		data     = GangService.Gangs[gangKey],
		rank     = PlayerDataService.get(player, "gangRank"),
		rep      = PlayerDataService.get(player, "reputation"),
		houseId  = PlayerDataService.get(player, "houseId"),
	}
end

return GangService
