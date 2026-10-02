-- GangData.lua
-- Plain display-only data for all 13 gangs. No game logic, no service requires.
-- Keys match GangService.Gangs exactly so UI can be driven off this table alone.
-- Place this in: src/shared/GangData.lua

local GangData = {
	Toman = {
		displayName = "Tokyo Manji Gang",
		color = { 0, 0, 180 },
		homeCity = "Shibuya",
		loreBlurb = "Tokyo's most legendary crew — brotherhood over everything in Shibuya's back alleys.",
	},
	BlackDragon = {
		displayName = "Black Dragon",
		color = { 20, 20, 20 },
		homeCity = "Yokohama",
		loreBlurb = "Yokohama's old guard — ruthless tacticians who never forget a grudge.",
	},
	Moebius = {
		displayName = "Moebius",
		color = { 180, 0, 0 },
		homeCity = "Ikebukuro",
		loreBlurb = "Ikebukuro brawlers who settle every dispute with their fists first.",
	},
	Valhalla = {
		displayName = "Valhalla",
		color = { 100, 0, 180 },
		homeCity = "Roppongi",
		loreBlurb = "Roppongi's warband — strength decides who leads and who kneels.",
	},
	Tenjiku = {
		displayName = "Tenjiku",
		color = { 200, 140, 0 },
		homeCity = "Yokohama",
		loreBlurb = "Yokohama's richest syndicate — money and muscle in equal measure.",
	},
	Brahman = {
		displayName = "Brahman",
		color = { 220, 180, 60 },
		homeCity = "Odaiba",
		loreBlurb = "Odaiba's quiet power — elders who move the city from the shadows.",
	},
	RokuharaTandai = {
		displayName = "Rokuhara Tandai",
		color = { 0, 160, 80 },
		homeCity = "Akihabara",
		loreBlurb = "Akihabara's elite enforcers — precision over chaos.",
	},
	Bonten = {
		displayName = "Bonten",
		color = { 60, 0, 60 },
		homeCity = "Shinjuku",
		loreBlurb = "Shinjuku's untouchable top — once you're in, there's no out.",
	},
	KodoRengo = {
		displayName = "Kodo Rengo",
		color = { 180, 60, 0 },
		homeCity = "Asakusa",
		loreBlurb = "Asakusa's street legends — loyalty tested in every turf war.",
	},
	Ragnarok = {
		displayName = "Ragnarok",
		color = { 0, 80, 160 },
		homeCity = "Shibuya",
		loreBlurb = "Shibuya's rising storm — young, hungry, and done waiting their turn.",
	},
	MizoMiddleFive = {
		displayName = "Mizo Middle Five",
		color = { 0, 120, 200 },
		homeCity = "Nerima",
		loreBlurb = "Nerima's school-age legends — small crew, big reputation.",
	},
	YotsuyaKaidan = {
		displayName = "Yotsuya Kaidan",
		color = { 140, 0, 0 },
		homeCity = "Yotsuya",
		loreBlurb = "Yotsuya's night-dwellers — they move like rumors, strike like ghosts.",
	},
	S62Generation = {
		displayName = "S-62 Generation",
		color = { 40, 40, 40 },
		homeCity = "Kanto",
		loreBlurb = "Kanto's forgotten veterans — the generation that started it all.",
	},
}

return GangData
