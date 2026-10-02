-- init.server.luau
-- Server entry point: wires all services together and creates shared RemoteEvents.
-- Place this in: src/server/init.server.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.PlayerDataService)
local GangService = require(script.GangService)
local EconomyService = require(script.EconomyService)
local CombatService = require(script.CombatService)
local GangWarService = require(script.GangWarService)
local PoliceService = require(script.PoliceService)
local HousingService = require(script.HousingService)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

-- ============================================================
-- REMOTES
-- ============================================================
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local REMOTE_EVENTS = {
	"DealDamage",
	"OnRankUp",
	"WantedLevelChanged",
	"WarDeclared",
	"JoinGang",
	"LeaveGang",
	"DoMission",
	"RobBank",
	"PlayerKO", -- addition: drives the client-side KO screen fade
}

for _, name in ipairs(REMOTE_EVENTS) do
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = name
	remoteEvent.Parent = remotes
end

-- Addition: lets clients pull their own money/gang/rank/wanted without
-- requiring the server-only PlayerDataService module.
local getPlayerData = Instance.new("RemoteFunction")
getPlayerData.Name = "GetPlayerData"
getPlayerData.Parent = remotes

-- ============================================================
-- REMOTE WIRING
-- ============================================================

remotes.DealDamage.OnServerEvent:Connect(function(player, targetPlayer)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end
	CombatService.dealDamage(player, targetPlayer, Constants.BASE_MELEE_DAMAGE)
end)

remotes.JoinGang.OnServerEvent:Connect(function(player, gangKey)
	local ok = GangService.joinGang(player, gangKey)
	if ok then
		local houseId = PlayerDataService.get(player, "houseId")
		HousingService.assignHouse(player, houseId)
	end
end)

remotes.LeaveGang.OnServerEvent:Connect(function(player)
	GangService.leaveGang(player)
end)

remotes.DoMission.OnServerEvent:Connect(function(player, missionId)
	EconomyService.doMission(player, missionId)
end)

remotes.RobBank.OnServerEvent:Connect(function(player)
	EconomyService.robBank(player)
end)

getPlayerData.OnServerInvoke = function(player)
	local success, result = pcall(function()
		return {
			money = PlayerDataService.get(player, "money"),
			gang = PlayerDataService.get(player, "gang"),
			gangRank = PlayerDataService.get(player, "gangRank"),
			reputation = PlayerDataService.get(player, "reputation"),
			wantedLevel = PoliceService.getWanted(player),
		}
	end)
	if success then
		return result
	end
	warn("[init.server] GetPlayerData failed for " .. player.Name .. ": " .. tostring(result))
	return nil
end

-- ============================================================
-- PASSIVE INCOME LOOP
-- ============================================================
task.spawn(function()
	while true do
		task.wait(Constants.PASSIVE_INCOME_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local success, err = pcall(function()
				EconomyService.businessIncome(player)
			end)
			if not success then
				warn("[init.server] businessIncome failed for " .. player.Name .. ": " .. tostring(err))
			end
		end
	end
end)

print("[init.server] All services loaded and remotes wired.")
