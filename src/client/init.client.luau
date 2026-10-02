-- init.client.luau
-- Client entry point: waits for Remotes, then starts UI and combat input.
-- Place this in: src/client/init.client.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotes then
	warn("[init.client] ReplicatedStorage.Remotes never appeared within 10s; aborting client init.")
	return
end

local GangSelectionUI = require(script.GangSelectionUI)
local HUD = require(script.HUD)
local CombatClient = require(script.CombatClient)

local getPlayerData = remotes:WaitForChild("GetPlayerData", 10)

local function maybeShowGangSelection()
	if not getPlayerData then return end

	local success, data = pcall(function()
		return getPlayerData:InvokeServer()
	end)

	if success and data and not data.gang then
		GangSelectionUI.show()
	end
end

maybeShowGangSelection()
HUD.start()
CombatClient.start()

print("[init.client] Client scripts initialized.")
