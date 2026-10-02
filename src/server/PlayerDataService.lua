-- PlayerDataService.lua
-- Handles loading, saving, and accessing player data (money, gang, house, rank)
-- Place this in: src/server/PlayerDataService.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataService = {}

-- DataStore key prefix
local DATA_STORE_NAME = "PlayerData_v1"
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- In-memory cache of loaded profiles
local profiles = {}

-- Default data template for new players
local function getDefaultData()
	return {
		money = 500,           -- starting cash
		gang = nil,            -- nil until player chooses a gang
		gangRank = "Recruit",  -- rank within the gang
		houseId = nil,         -- assigned house (set on first gang join)
		reputation = 0,        -- used for rank progression
		inventory = {},        -- cosmetics/items owned
		createdAt = os.time(),
	}
end

-- Load a player's data from DataStore
local function loadData(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success then
		if data then
			-- Merge with defaults so new fields are always present
			local defaults = getDefaultData()
			for k, v in pairs(defaults) do
				if data[k] == nil then
					data[k] = v
				end
			end
			return data
		else
			-- Brand new player
			return getDefaultData()
		end
	else
		warn("[PlayerDataService] Failed to load data for " .. player.Name .. ": " .. tostring(data))
		return getDefaultData() -- fail safe: give defaults rather than error
	end
end

-- Save a player's data to DataStore
local function saveData(player)
	local profile = profiles[player.UserId]
	if not profile then return end

	local key = "Player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, profile)
	end)

	if not success then
		warn("[PlayerDataService] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

-- PUBLIC: Get a player's loaded profile (returns nil if not loaded yet)
function PlayerDataService.getProfile(player)
	return profiles[player.UserId]
end

-- PUBLIC: Update a specific field in a player's profile
-- Usage: PlayerDataService.set(player, "money", 1000)
function PlayerDataService.set(player, key, value)
	local profile = profiles[player.UserId]
	if not profile then
		warn("[PlayerDataService] Tried to set data before profile loaded for " .. player.Name)
		return
	end
	profile[key] = value
end

-- PUBLIC: Increment a numeric field
-- Usage: PlayerDataService.increment(player, "money", 250)
function PlayerDataService.increment(player, key, amount)
	local profile = profiles[player.UserId]
	if not profile then return end
	if type(profile[key]) ~= "number" then
		warn("[PlayerDataService] Cannot increment non-number field: " .. key)
		return
	end
	profile[key] = profile[key] + amount
end

-- PUBLIC: Get a specific field
-- Usage: PlayerDataService.get(player, "money")
function PlayerDataService.get(player, key)
	local profile = profiles[player.UserId]
	if not profile then return nil end
	return profile[key]
end

-- Called when a player joins
local function onPlayerAdded(player)
	local data = loadData(player)
	profiles[player.UserId] = data
	print("[PlayerDataService] Loaded profile for " .. player.Name .. " | Gang: " .. tostring(data.gang) .. " | Money: " .. data.money)
end

-- Called when a player leaves
local function onPlayerRemoving(player)
	saveData(player)
	profiles[player.UserId] = nil
	print("[PlayerDataService] Saved and unloaded profile for " .. player.Name)
end

-- Auto-save every 60 seconds (protects against crashes)
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

-- Hook up events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game if script loads late (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

return PlayerDataService
