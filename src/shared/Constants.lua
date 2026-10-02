-- Constants.lua
-- Single source of truth for tunable values shared by server and client scripts.
-- Place this in: src/shared/Constants.lua

local Constants = {
	-- Economy
	STARTING_MONEY = 500,
	MISSION_COOLDOWN = 120,
	BANK_ROB_COOLDOWN = 60,
	ROBBERY_MIN_PAYOUT = 100,
	ROBBERY_MAX_PAYOUT = 500,
	ROBBERY_POLICE_CHANCE = 0.10,
	PASSIVE_INCOME_INTERVAL = 120,
	BUSINESS_INCOME_PER_TERRITORY = 20,

	-- Combat
	COMBAT_RANGE = 10,
	RESPAWN_DELAY = 5,
	KO_REP_REWARD = 25,
	KO_MONEY_STEAL = 10,
	BASE_MELEE_DAMAGE = 10,
	COMBAT_CLICK_COOLDOWN = 0.4,
	DAMAGE_LABEL_FADE_TIME = 0.8,

	-- Gang wars
	WAR_DURATION = 600,
	WAR_LOSER_REP_PENALTY = 50,

	-- Police
	MAX_WANTED = 5,
	JAIL_DURATION = 30,
	POLICE_NPC_WANTED_THRESHOLD = 3,
}

return Constants
