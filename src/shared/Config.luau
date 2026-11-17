-- Brainrot Bonanza — shared config.
-- Every number the server and the client agree on lives here.

local Config = {}

-- Map layout (studs). The conveyor runs along X at z = 0.
Config.MAP_HALF = 100
Config.CONVEYOR_Z = 0
Config.CONVEYOR_FROM_X = -70
Config.CONVEYOR_TO_X = 70
Config.CONVEYOR_WIDTH = 10
Config.CONVEYOR_SPEED = 4 -- studs per second the brainrots walk
Config.CONVEYOR_MAX = 12 -- most brainrots on the lane at once
Config.SPAWN_INTERVAL = 4 -- seconds between spawn attempts
Config.SPAWN_POS = Vector3.new(0, 1, 85)

-- 8 base plots: 4 north (z = -60), 4 south (z = 60).
Config.BASES = {
	{ name = "Red", id = 1, center = Vector3.new(-70, 0, -60), color = Color3.fromRGB(255, 80, 80) },
	{ name = "Orange", id = 2, center = Vector3.new(-25, 0, -60), color = Color3.fromRGB(255, 170, 0) },
	{ name = "Blue", id = 3, center = Vector3.new(20, 0, -60), color = Color3.fromRGB(80, 200, 255) },
	{ name = "Purple", id = 4, center = Vector3.new(65, 0, -60), color = Color3.fromRGB(170, 90, 255) },
	{ name = "Green", id = 5, center = Vector3.new(-70, 0, 60), color = Color3.fromRGB(90, 255, 140) },
	{ name = "Pink", id = 6, center = Vector3.new(-25, 0, 60), color = Color3.fromRGB(255, 120, 200) },
	{ name = "Yellow", id = 7, center = Vector3.new(20, 0, 60), color = Color3.fromRGB(255, 255, 90) },
	{ name = "White", id = 8, center = Vector3.new(65, 0, 60), color = Color3.fromRGB(255, 255, 255) },
}
Config.BASE_SIZE = Vector3.new(26, 1, 18)
Config.BASE_SLOTS = 8 -- brainrots a base can hold

-- Brainrot catalogue. income = cash per second, cost = buy price.
-- color = body colour, accent = head/accessory colour.
Config.BRAINROTS = {
	{ name = "Noobini Pizzanini", rarity = "Common", income = 1, cost = 25, color = Color3.fromRGB(255, 220, 130), accent = Color3.fromRGB(200, 60, 60) },
	{ name = "Chimpanzini Bananini", rarity = "Common", income = 2, cost = 50, color = Color3.fromRGB(255, 235, 90), accent = Color3.fromRGB(120, 80, 40) },
	{ name = "Tung Tung Tung Sahur", rarity = "Rare", income = 5, cost = 150, color = Color3.fromRGB(150, 110, 70), accent = Color3.fromRGB(90, 60, 35) },
	{ name = "Tralalero Tralala", rarity = "Rare", income = 8, cost = 300, color = Color3.fromRGB(90, 160, 255), accent = Color3.fromRGB(255, 255, 255) },
	{ name = "Bombardiro Crocodilo", rarity = "Epic", income = 15, cost = 750, color = Color3.fromRGB(90, 200, 90), accent = Color3.fromRGB(60, 60, 60) },
	{ name = "Lirili Larila", rarity = "Epic", income = 20, cost = 1200, color = Color3.fromRGB(255, 180, 220), accent = Color3.fromRGB(255, 120, 180) },
	{ name = "Ballerina Cappuccina", rarity = "Legendary", income = 40, cost = 3000, color = Color3.fromRGB(255, 220, 240), accent = Color3.fromRGB(180, 120, 90) },
	{ name = "Cappuccino Assassino", rarity = "Legendary", income = 60, cost = 5000, color = Color3.fromRGB(120, 80, 50), accent = Color3.fromRGB(40, 40, 40) },
	{ name = "Trippi Troppi", rarity = "Mythic", income = 120, cost = 12000, color = Color3.fromRGB(255, 150, 60), accent = Color3.fromRGB(255, 220, 90) },
	{ name = "La Vaca Saturno Saturnita", rarity = "Mythic", income = 200, cost = 25000, color = Color3.fromRGB(200, 220, 255), accent = Color3.fromRGB(255, 200, 60) },
	{ name = "Garamararamaraman", rarity = "Secret", income = 500, cost = 75000, color = Color3.fromRGB(160, 60, 220), accent = Color3.fromRGB(255, 215, 0) },
	{ name = "Los Tralaleritos", rarity = "Secret", income = 1000, cost = 200000, color = Color3.fromRGB(255, 60, 60), accent = Color3.fromRGB(90, 200, 255) },
}

-- Spawn weights per rarity (out of 100).
Config.RARITY_WEIGHTS = {
	Common = 40,
	Rare = 28,
	Epic = 16,
	Legendary = 10,
	Mythic = 4,
	Secret = 2,
}

-- Mutations: roll (out of 100), income multiplier, label colour.
Config.MUTATIONS = {
	{ name = "Normal", weight = 88, mult = 1, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", weight = 8, mult = 3, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 3, mult = 5, color = Color3.fromRGB(140, 230, 255) },
	{ name = "Rainbow", weight = 1, mult = 10, color = Color3.fromRGB(255, 90, 200) },
}

-- Rarity colours for labels.
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(90, 180, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 60, 90),
	Secret = Color3.fromRGB(255, 215, 0),
}

-- Steal rules.
Config.STEAL_HOLD = 3 -- seconds holding the prompt to steal
Config.STEAL_COOLDOWN = 30 -- seconds between steals per player
Config.CARRY_SPEED = 10 -- WalkSpeed while carrying a stolen brainrot
Config.NORMAL_SPEED = 16
Config.SLAP_RANGE = 12 -- studs
Config.SLAP_COOLDOWN = 2 -- seconds
Config.SLAP_KNOCKBACK = 45 -- studs/sec fling

-- Rebirth: cost = BASE * GROWTH ^ rebirths, income x MULT per rebirth.
Config.REBIRTH_BASE_COST = 10000
Config.REBIRTH_GROWTH = 5
Config.REBIRTH_MULT = 1.25

-- Brainrot Tsunami wave.
Config.WAVE_INTERVAL = 90 -- seconds between waves
Config.WAVE_WARNING = 10 -- seconds of warning before the sweep
Config.WAVE_SWEEP = 8 -- seconds the wall takes to cross the map
Config.WAVE_FROM_X = -120
Config.WAVE_TO_X = 120

-- Starting cash for a new player.
Config.START_CASH = 100

-- Format cash: 1.2K / 3.4M.
function Config.formatCash(n)
	n = math.floor(n)
	if n >= 1000000 then
		return string.format("$%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("$%.1fK", n / 1000)
	else
		return "$" .. tostring(n)
	end
end

-- Pick a brainrot definition by rarity weight.
function Config.pickBrainrot()
	local total = 0
	for _, w in pairs(Config.RARITY_WEIGHTS) do
		total += w
	end
	local roll = math.random(1, total)
	local acc = 0
	local rarity = "Common"
	for name, w in pairs(Config.RARITY_WEIGHTS) do
		acc += w
		if roll <= acc then
			rarity = name
			break
		end
	end
	local pool = {}
	for _, b in ipairs(Config.BRAINROTS) do
		if b.rarity == rarity then
			table.insert(pool, b)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation.
function Config.rollMutation()
	local roll = math.random(1, 100)
	local acc = 0
	for _, m in ipairs(Config.MUTATIONS) do
		acc += m.weight
		if roll <= acc then
			return m
		end
	end
	return Config.MUTATIONS[1]
end

return Config
