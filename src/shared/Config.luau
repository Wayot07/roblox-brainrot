-- Brainrot Bonanza — shared numbers.
-- One module both the server and the client require. It holds the map
-- geometry, the eight base plots, the brainrot catalogue, the spawn odds,
-- the mutation table, and every tuning knob (steal, rebirth, tsunami).
-- Change a number here and both sides of the game agree on it.

local Config = {}

-- ------------------------------------------------------------------ map
-- The world is a square. The conveyor is a straight lane along X at z = 0;
-- brainrots enter at the west end and walk east until bought or despawned.
Config.MAP_HALF = 100
Config.CONVEYOR_Z = 0
Config.CONVEYOR_FROM_X = -70
Config.CONVEYOR_TO_X = 70
Config.CONVEYOR_WIDTH = 10
Config.CONVEYOR_SPEED = 4
Config.CONVEYOR_MAX = 12
Config.SPAWN_INTERVAL = 4
Config.SPAWN_POS = Vector3.new(0, 1, 85)

-- ----------------------------------------------------------------- bases
-- Eight plots in two rows of four. North row sits at z = -60, south at z = 60.
-- Each plot is 26 wide by 18 deep and holds up to BASE_SLOTS brainrots.
Config.BASES = {
	{ id = 1, name = "Red", center = Vector3.new(-70, 0, -60), color = Color3.fromRGB(255, 80, 80) },
	{ id = 2, name = "Orange", center = Vector3.new(-25, 0, -60), color = Color3.fromRGB(255, 170, 0) },
	{ id = 3, name = "Blue", center = Vector3.new(20, 0, -60), color = Color3.fromRGB(80, 200, 255) },
	{ id = 4, name = "Purple", center = Vector3.new(65, 0, -60), color = Color3.fromRGB(170, 90, 255) },
	{ id = 5, name = "Green", center = Vector3.new(-70, 0, 60), color = Color3.fromRGB(90, 255, 140) },
	{ id = 6, name = "Pink", center = Vector3.new(-25, 0, 60), color = Color3.fromRGB(255, 120, 200) },
	{ id = 7, name = "Yellow", center = Vector3.new(20, 0, 60), color = Color3.fromRGB(255, 255, 90) },
	{ id = 8, name = "White", center = Vector3.new(65, 0, 60), color = Color3.fromRGB(255, 255, 255) },
}
Config.BASE_SIZE = Vector3.new(26, 1, 18)
Config.BASE_SLOTS = 8

-- -------------------------------------------------------------- brainrots
-- income is cash per second; cost is the buy price. color is the body,
-- accent is the head. Two brainrots per rarity, six rarities in all.
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

-- Odds that a spawn lands on each rarity (weights, not percents).
Config.RARITY_WEIGHTS = {
	Common = 40,
	Rare = 28,
	Epic = 16,
	Legendary = 10,
	Mythic = 4,
	Secret = 2,
}

-- Mutations roll on spawn. mult multiplies the brainrot's income.
Config.MUTATIONS = {
	{ name = "Normal", weight = 88, mult = 1, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", weight = 8, mult = 3, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 3, mult = 5, color = Color3.fromRGB(140, 230, 255) },
	{ name = "Rainbow", weight = 1, mult = 10, color = Color3.fromRGB(255, 90, 200) },
}

-- Label colours per rarity, for the name tags and the collection list.
Config.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(90, 180, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 60, 90),
	Secret = Color3.fromRGB(255, 215, 0),
}

-- ----------------------------------------------------------------- steal
-- Hold E for STEAL_HOLD seconds on someone else's brainrot to lift it,
-- then carry it home. While carrying you walk slower, and a slap makes
-- you drop it. STEAL_COOLDOWN gates how often one player can steal.
Config.STEAL_HOLD = 3
Config.STEAL_COOLDOWN = 30
Config.CARRY_SPEED = 10
Config.NORMAL_SPEED = 16
Config.SLAP_RANGE = 12
Config.SLAP_COOLDOWN = 2
Config.SLAP_KNOCKBACK = 45

-- --------------------------------------------------------------- rebirth
-- Rebirth wipes cash and brainrots and raises the income multiplier.
-- cost = BASE_COST * GROWTH ^ rebirths; income x MULT per rebirth.
Config.REBIRTH_BASE_COST = 10000
Config.REBIRTH_GROWTH = 5
Config.REBIRTH_MULT = 1.25

-- ------------------------------------------------------------------ wave
-- Every WAVE_INTERVAL seconds the tsunami warns, then sweeps the map.
-- Caught outside your own base (or the spawn safe zone) and you are
-- flung back to spawn, dropping anything you carry.
Config.WAVE_INTERVAL = 90
Config.WAVE_WARNING = 10
Config.WAVE_SWEEP = 8
Config.WAVE_FROM_X = -120
Config.WAVE_TO_X = 120

-- Cash a brand-new player starts with.
Config.START_CASH = 100

-- ---------------------------------------------------------------- helpers

-- Short cash: $850, $1.2K, $3.4M.
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

-- Weighted pick: roll a rarity by RARITY_WEIGHTS, then a random brainrot
-- of that rarity.
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

-- Roll one mutation from the MUTATIONS table.
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
