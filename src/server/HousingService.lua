-- HousingService.lua
-- Gang house spawn points and door access control.
-- Place this in: src/server/HousingService.lua

local Workspace = game:GetService("Workspace")

local HousingService = {}

-- STUB: one spawn position per gang HQ (matches houseIds[1] in GangService.Gangs).
-- Replace with real coordinates once the 3D builder places the actual houses.
local HOUSE_POSITIONS = {
	toman_hq = Vector3.new(0, 5, 0),
	blackdragon_hq = Vector3.new(250, 5, 0),
	moebius_hq = Vector3.new(500, 5, 0),
	valhalla_hq = Vector3.new(750, 5, 0),
	tenjiku_hq = Vector3.new(1000, 5, 0),
	brahman_hq = Vector3.new(1250, 5, 0),
	rokuhara_hq = Vector3.new(1500, 5, 0),
	bonten_hq = Vector3.new(0, 5, 250),
	kodoren_hq = Vector3.new(250, 5, 250),
	ragnarok_hq = Vector3.new(500, 5, 250),
	mizo_hq = Vector3.new(750, 5, 250),
	yotsuya_hq = Vector3.new(1000, 5, 250),
	s62_hq = Vector3.new(1250, 5, 250),
}

-- Locked doors, keyed by houseId: { part = Part, gangKey = string, connection = RBXScriptConnection }
local lockedDoors = {}

-- PUBLIC: Spawn position for a given houseId (nil if unknown).
function HousingService.getHouseSpawn(houseId)
	if not houseId then return nil end
	return HOUSE_POSITIONS[houseId]
end

-- PUBLIC: Teleport a player to their house spawn point.
function HousingService.assignHouse(player, houseId)
	local position = HousingService.getHouseSpawn(houseId)
	if not position then
		warn("[HousingService] No spawn position for houseId: " .. tostring(houseId))
		return false
	end

	local character = player.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	root.CFrame = CFrame.new(position)
	print(("[HousingService] Teleported %s to house %s"):format(player.Name, tostring(houseId)))
	return true
end

-- Create a stub trigger part at the house's spawn point if the 3D builder
-- hasn't placed a real door part named "<houseId>_Door" in Workspace yet.
local function getOrCreateDoorPart(houseId)
	local existing = Workspace:FindFirstChild(houseId .. "_Door")
	if existing then
		return existing
	end

	local position = HousingService.getHouseSpawn(houseId)
	if not position then return nil end

	local door = Instance.new("Part")
	door.Name = houseId .. "_Door"
	door.Size = Vector3.new(6, 8, 1)
	door.Anchored = true
	door.CanCollide = false
	door.Transparency = 0.5
	door.Color = Color3.fromRGB(120, 120, 120)
	door.Position = position + Vector3.new(0, 4, 10)
	door.Parent = Workspace
	return door
end

-- PUBLIC: Restrict a house's door so only members of gangKey may pass.
-- Non-members who touch the door are pushed back outside.
function HousingService.lockDoor(houseId, gangKey)
	-- Clean up any previous lock on this door first.
	local existingLock = lockedDoors[houseId]
	if existingLock and existingLock.connection then
		existingLock.connection:Disconnect()
	end

	local door = getOrCreateDoorPart(houseId)
	if not door then
		warn("[HousingService] Could not lock door for unknown houseId: " .. tostring(houseId))
		return false
	end

	local Players = game:GetService("Players")

	local connection = door.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local PlayerDataService = require(script.Parent.PlayerDataService)
		local playerGang = PlayerDataService.get(player, "gang")

		if playerGang ~= gangKey then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				-- Push the player back away from the door.
				local away = (root.Position - door.Position).Unit
				root.CFrame = CFrame.new(root.Position + away * 8)
			end
		end
	end)

	lockedDoors[houseId] = { part = door, gangKey = gangKey, connection = connection }
	print(("[HousingService] Locked door for house %s to gang %s"):format(houseId, gangKey))
	return true
end

return HousingService
