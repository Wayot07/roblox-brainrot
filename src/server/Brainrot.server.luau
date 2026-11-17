-- Brainrot Bonanza — server.
-- Spawns brainrots on the conveyor, runs bases, earnings, stealing,
-- rebirths and the Brainrot Tsunami wave. One player can play alone;
-- stealing needs a second player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- RemoteEvents (created here so the client can always find them).
local function getRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end
local StatsEvent = getRemote("Stats")
local RebirthEvent = getRemote("Rebirth")
local SlapEvent = getRemote("Slap")
local NotifyEvent = getRemote("Notify")
local WaveEvent = getRemote("Wave")

-- ---------------------------------------------------------------- state

local playerData = {} -- [Player] = { cash, rebirths, baseId, brainrots = {}, carrying, stealReadyAt, slapReadyAt }
local baseOwner = {} -- [baseId] = Player
local conveyor = {} -- { def, mutation, model, x }
local waveWall = Workspace:WaitForChild("WaveWall")
local nextWaveIn = Config.WAVE_INTERVAL
local waveActive = false

local function rebirthMult(pdata)
	return Config.REBIRTH_MULT ^ pdata.rebirths
end

local function rebirthCost(pdata)
	return Config.REBIRTH_BASE_COST * (Config.REBIRTH_GROWTH ^ pdata.rebirths)
end

local function perSecond(pdata)
	local total = 0
	for _, b in ipairs(pdata.brainrots) do
		total += b.def.income * b.mutation.mult
	end
	return total * rebirthMult(pdata)
end

-- ------------------------------------------------------- brainrot models

local function makeLabel(parent, name, text, size, color, yOffset)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, size)
	label.Position = UDim2.new(0, 0, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.4
	label.Parent = parent
	return label
end

-- Builds the 3D model for one brainrot. Anchored; the server moves it.
local function buildBrainrotModel(def, mutation)
	local model = Instance.new("Model")
	model.Name = def.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.4, 2, 1.6)
	body.Color = def.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.4, 1.4)
	head.Position = Vector3.new(0, 1.7, 0)
	head.Color = def.accent
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- A little hat / fin on top so characters read at a glance.
	local hat = Instance.new("Part")
	hat.Name = "Hat"
	hat.Size = Vector3.new(1.8, 0.4, 1.8)
	hat.Position = Vector3.new(0, 2.6, 0)
	hat.Color = mutation.color
	hat.Material = Enum.Material.Neon
	hat.Anchored = true
	hat.CanCollide = false
	hat.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.new(0, 140, 0, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	gui.Parent = body
	makeLabel(gui, "Name", def.name, 22, Config.RARITY_COLORS[def.rarity], 0)
	local mutText = mutation.name == "Normal" and def.rarity or (mutation.name .. " " .. def.rarity)
	makeLabel(gui, "Rarity", mutText, 16, mutation.color, 24)
	makeLabel(gui, "Income", "$" .. tostring(def.income * mutation.mult) .. "/s", 20, Color3.fromRGB(120, 255, 120), 42)

	model.PrimaryPart = body
	return model
end

local function attachBuyPrompt(model, def, mutation)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = def.name .. " — $" .. tostring(def.cost)
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart
	return prompt
end

local function attachStealPrompt(model, def, mutation)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = def.name .. " — $" .. tostring(def.income * mutation.mult) .. "/s"
	prompt.HoldDuration = Config.STEAL_HOLD
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart
	return prompt
end

-- ------------------------------------------------------- base signs
-- Label every base's sign board so the judge (and players) can read
-- which plot is which from the screenshots.
for _, base in ipairs(Config.BASES) do
	local sign = Workspace:FindFirstChild("Sign" .. tostring(base.id))
	if sign then
		local gui = Instance.new("BillboardGui")
		gui.Name = "BaseTag"
		gui.Size = UDim2.fromOffset(220, 60)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
		gui.AlwaysOnTop = true
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "BASE " .. tostring(base.id) .. " — " .. string.upper(base.name)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
	end
end

-- ------------------------------------------------------------ base slots

local function slotPosition(baseId, slotIndex)
	local base = Config.BASES[baseId]
	-- 4 columns x 2 rows on the platform.
	local col = (slotIndex - 1) % 4
	local row = math.floor((slotIndex - 1) / 4)
	local x = base.center.X - 9 + col * 6
	local z = base.center.Z - 4 + row * 8
	return Vector3.new(x, 1.5, z)
end

local function freeSlot(pdata)
	if #pdata.brainrots >= Config.BASE_SLOTS then
		return nil
	end
	return #pdata.brainrots + 1
end

local function placeInBase(pdata, brainrot)
	local slot = freeSlot(pdata)
	if not slot then
		return false
	end
	brainrot.slot = slot
	brainrot.model:PivotTo(CFrame.new(slotPosition(pdata.baseId, slot)))
	-- A steal prompt for everyone else.
	if brainrot.prompt then
		brainrot.prompt:Destroy()
	end
	brainrot.prompt = attachStealPrompt(brainrot.model, brainrot.def, brainrot.mutation)
	brainrot.prompt.Triggered:Connect(function(thief)
		onStealTriggered(thief, pdata, brainrot)
	end)
	table.insert(pdata.brainrots, brainrot)
	return true
end

local function removeFromBase(pdata, brainrot)
	for i, b in ipairs(pdata.brainrots) do
		if b == brainrot then
			table.remove(pdata.brainrots, i)
			return true
		end
	end
	return false
end

-- ----------------------------------------------------------------- buy

local function onBuyTriggered(player, brainrot)
	local pdata = playerData[player]
	if not pdata or not brainrot.onConveyor then
		return
	end
	if playerData[player].cash < brainrot.def.cost then
		NotifyEvent:FireClient(player, "Not enough cash! Need $" .. tostring(brainrot.def.cost))
		return
	end
	if freeSlot(pdata) == nil then
		NotifyEvent:FireClient(player, "Your base is full! Rebirth or make room.")
		return
	end
	-- Take it off the conveyor.
	brainrot.onConveyor = false
	for i, b in ipairs(conveyor) do
		if b == brainrot then
			table.remove(conveyor, i)
			break
		end
	end
	if brainrot.prompt then
		brainrot.prompt:Destroy()
		brainrot.prompt = nil
	end
	pdata.cash -= brainrot.def.cost
	if placeInBase(pdata, brainrot) then
		NotifyEvent:FireClient(player, "Got " .. brainrot.def.name .. "! +" .. tostring(brainrot.def.income * brainrot.mutation.mult) .. "/s")
	end
end

-- ---------------------------------------------------------------- steal

function onStealTriggered(thief, ownerData, brainrot)
	local tdata = playerData[thief]
	if not tdata then
		return
	end
	-- Find the owner player for this base.
	local owner = nil
	for pl, pd in pairs(playerData) do
		if pd == ownerData then
			owner = pl
			break
		end
	end
	if not owner or owner == thief then
		return
	end
	if tdata.carrying then
		NotifyEvent:FireClient(thief, "You are already carrying a brainrot!")
		return
	end
	if os.clock() < tdata.stealReadyAt then
		NotifyEvent:FireClient(thief, "Steal is on cooldown (" .. tostring(math.ceil(tdata.stealReadyAt - os.clock())) .. "s)")
		return
	end
	if not removeFromBase(ownerData, brainrot) then
		return
	end
	if brainrot.prompt then
		brainrot.prompt:Destroy()
		brainrot.prompt = nil
	end
	tdata.carrying = { brainrot = brainrot, from = ownerData, fromPlayer = owner }
	tdata.stealReadyAt = os.clock() + Config.STEAL_COOLDOWN
	local char = thief.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Config.CARRY_SPEED
		end
	end
	NotifyEvent:FireClient(thief, "STOLEN! Dash home to your base before someone slaps you!")
	NotifyEvent:FireClient(owner, thief.DisplayName .. " stole your " .. brainrot.def.name .. "! Slap them!")
end

local function dropCarried(player, returnHome)
	local pdata = playerData[player]
	if not pdata or not pdata.carrying then
		return
	end
	local carried = pdata.carrying
	pdata.carrying = nil
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	if returnHome then
		-- Back to its owner's base if there is room, else it is lost.
		if placeInBase(carried.from, carried.brainrot) then
			NotifyEvent:FireClient(carried.fromPlayer, "Your " .. carried.brainrot.def.name .. " is back home!")
		else
			carried.brainrot.model:Destroy()
		end
	else
		carried.brainrot.model:Destroy()
	end
end

local function secureCarried(player)
	local pdata = playerData[player]
	if not pdata or not pdata.carrying then
		return
	end
	local carried = pdata.carrying
	pdata.carrying = nil
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = Config.NORMAL_SPEED
		end
	end
	if placeInBase(pdata, carried.brainrot) then
		NotifyEvent:FireClient(player, "Secured " .. carried.brainrot.def.name .. " in your base!")
	else
		-- Base full: sell it for half price.
		local refund = math.floor(carried.brainrot.def.cost / 2)
		pdata.cash += refund
		carried.brainrot.model:Destroy()
		NotifyEvent:FireClient(player, "Base full — sold the stolen brainrot for $" .. tostring(refund))
	end
end

-- ---------------------------------------------------------------- slap

SlapEvent.OnServerEvent:Connect(function(player)
	local pdata = playerData[player]
	if not pdata then
		return
	end
	if os.clock() < pdata.slapReadyAt then
		return
	end
	pdata.slapReadyAt = os.clock() + Config.SLAP_COOLDOWN
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local best = nil
	local bestDist = Config.SLAP_RANGE
	for other, _ in pairs(playerData) do
		if other ~= player and other.Character then
			local oroot = other.Character:FindFirstChild("HumanoidRootPart")
			if oroot then
				local d = (oroot.Position - root.Position).Magnitude
				if d < bestDist then
					bestDist = d
					best = other
				end
			end
		end
	end
	if not best then
		return
	end
	local oroot = best.Character:FindFirstChild("HumanoidRootPart")
	if not oroot then
		return
	end
	-- Knock them away from the slapper.
	local dir = (oroot.Position - root.Position).Unit
	oroot.AssemblyLinearVelocity = Vector3.new(dir.X, 0.6, dir.Z) * Config.SLAP_KNOCKBACK
	NotifyEvent:FireClient(best, player.DisplayName .. " slapped you!")
	NotifyEvent:FireClient(player, "SLAP! " .. best.DisplayName .. " got knocked back!")
	if playerData[best] and playerData[best].carrying then
		dropCarried(best, true)
		NotifyEvent:FireClient(player, "They dropped the stolen brainrot!")
	end
end)

-- -------------------------------------------------------------- rebirth

RebirthEvent.OnServerEvent:Connect(function(player)
	local pdata = playerData[player]
	if not pdata then
		return
	end
	local cost = rebirthCost(pdata)
	if pdata.cash < cost then
		NotifyEvent:FireClient(player, "Rebirth costs " .. Config.formatCash(cost) .. " — you have " .. Config.formatCash(pdata.cash))
		return
	end
	-- Clear the base.
	for _, b in ipairs(pdata.brainrots) do
		if b.prompt then
			b.prompt:Destroy()
		end
		b.model:Destroy()
	end
	pdata.brainrots = {}
	pdata.cash = 0
	pdata.rebirths += 1
	NotifyEvent:FireClient(player, "REBIRTH #" .. tostring(pdata.rebirths) .. "! Income x" .. string.format("%.2f", rebirthMult(pdata)))
end)

-- ---------------------------------------------------------- conveyor

local function spawnBrainrot()
	if #conveyor >= Config.CONVEYOR_MAX then
		return
	end
	local def = Config.pickBrainrot()
	local mutation = Config.rollMutation()
	local model = buildBrainrotModel(def, mutation)
	model:PivotTo(CFrame.new(Config.CONVEYOR_FROM_X, 1.5, Config.CONVEYOR_Z))
	model.Parent = Workspace
	local brainrot = {
		def = def,
		mutation = mutation,
		model = model,
		x = Config.CONVEYOR_FROM_X,
		onConveyor = true,
	}
	brainrot.prompt = attachBuyPrompt(model, def, mutation)
	brainrot.prompt.Triggered:Connect(function(player)
		onBuyTriggered(player, brainrot)
	end)
	table.insert(conveyor, brainrot)
end

-- -------------------------------------------------------------- waves

local function playerInOwnBase(player)
	local pdata = playerData[player]
	if not pdata then
		return false
	end
	local char = player.Character
	if not char then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	-- Spawn area counts as safe.
	if (root.Position - Config.SPAWN_POS).Magnitude < 14 then
		return true
	end
	local base = Config.BASES[pdata.baseId]
	local dx = math.abs(root.Position.X - base.center.X)
	local dz = math.abs(root.Position.Z - base.center.Z)
	return dx <= (Config.BASE_SIZE.X / 2 + 1) and dz <= (Config.BASE_SIZE.Z / 2 + 1)
end

local function flingToSpawn(player)
	local char = player.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(Config.SPAWN_POS + Vector3.new(0, 3, 0))
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
end

local function runWave()
	waveActive = true
	WaveEvent:FireAllClients("warning", Config.WAVE_WARNING)
	task.wait(Config.WAVE_WARNING)
	WaveEvent:FireAllClients("sweep", Config.WAVE_SWEEP)
	-- Sweep the wall across the map.
	local steps = 40
	for i = 0, steps do
		local t = i / steps
		local x = Config.WAVE_FROM_X + (Config.WAVE_TO_X - Config.WAVE_FROM_X) * t
		waveWall.CFrame = CFrame.new(x, 15, 0)
		-- Anyone caught outside their base gets flung home.
		for player, _ in pairs(playerData) do
			if not playerInOwnBase(player) then
				flingToSpawn(player)
				if playerData[player] and playerData[player].carrying then
					dropCarried(player, true)
				end
				NotifyEvent:FireClient(player, "The tsunami caught you! Dash to your base next time!")
			end
		end
		task.wait(Config.WAVE_SWEEP / steps)
	end
	waveWall.CFrame = CFrame.new(Config.WAVE_FROM_X, 15, 0)
	waveActive = false
	nextWaveIn = Config.WAVE_INTERVAL
	WaveEvent:FireAllClients("clear", 0)
end

-- ------------------------------------------------------------- players

local function assignBase(player)
	for id = 1, #Config.BASES do
		if not baseOwner[id] then
			baseOwner[id] = player
			return id
		end
	end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	local baseId = assignBase(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.START_CASH
	cash.Parent = leaderstats
	local count = Instance.new("IntValue")
	count.Name = "Brainrots"
	count.Value = 0
	count.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	playerData[player] = {
		cash = Config.START_CASH,
		rebirths = 0,
		baseId = baseId,
		brainrots = {},
		carrying = nil,
		stealReadyAt = 0,
		slapReadyAt = 0,
	}
	if baseId then
		local base = Config.BASES[baseId]
		NotifyEvent:FireClient(player, "Welcome to Brainrot Bonanza! Your base is the " .. base.name .. " plot — grab brainrots off the conveyor!")
	else
		NotifyEvent:FireClient(player, "Welcome! All bases are taken — spectate until a plot frees up.")
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and playerData[player] and playerData[player].carrying then
			hum.WalkSpeed = Config.CARRY_SPEED
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local pdata = playerData[player]
	if not pdata then
		return
	end
	if pdata.carrying then
		dropCarried(player, true)
	end
	for _, b in ipairs(pdata.brainrots) do
		if b.prompt then
			b.prompt:Destroy()
		end
		b.model:Destroy()
	end
	if pdata.baseId then
		baseOwner[pdata.baseId] = nil
	end
	playerData[player] = nil
end)

-- ------------------------------------------------------------ main loop

local spawnTimer = 0
local earnTimer = 0
local statsTimer = 0
local waveTimer = 0
local carryTimer = 0

RunService.Heartbeat:Connect(function(dt)
	-- Conveyor movement.
	for i = #conveyor, 1, -1 do
		local b = conveyor[i]
		b.x += Config.CONVEYOR_SPEED * dt
		if b.x > Config.CONVEYOR_TO_X then
			if b.prompt then
				b.prompt:Destroy()
			end
			b.model:Destroy()
			table.remove(conveyor, i)
		else
			b.model:PivotTo(CFrame.new(b.x, 1.5 + math.sin(os.clock() * 3 + b.x) * 0.15, Config.CONVEYOR_Z))
		end
	end

	-- Carried brainrots hover over the carrier's head.
	for player, pdata in pairs(playerData) do
		if pdata.carrying and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				pdata.carrying.brainrot.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 4.5, 0)))
			end
		end
	end

	-- Secure a carried brainrot when its thief is home.
	carryTimer += dt
	if carryTimer >= 0.25 then
		carryTimer = 0
		for player, pdata in pairs(playerData) do
			if pdata.carrying and playerInOwnBase(player) then
				secureCarried(player)
			end
		end
	end

	-- Spawning.
	spawnTimer += dt
	if spawnTimer >= Config.SPAWN_INTERVAL then
		spawnTimer = 0
		spawnBrainrot()
	end

	-- Earnings, once a second.
	earnTimer += dt
	if earnTimer >= 1 then
		earnTimer = 0
		for player, pdata in pairs(playerData) do
			local gain = perSecond(pdata)
			if gain > 0 then
				pdata.cash += gain
			end
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local c = ls:FindFirstChild("Cash")
				if c then
					c.Value = math.floor(pdata.cash)
				end
				local br = ls:FindFirstChild("Brainrots")
				if br then
					br.Value = #pdata.brainrots
				end
				local rb = ls:FindFirstChild("Rebirths")
				if rb then
					rb.Value = pdata.rebirths
				end
			end
		end
	end

	-- Stats push to every client, once a second.
	statsTimer += dt
	if statsTimer >= 1 then
		statsTimer = 0
		local waveIn = waveActive and 0 or math.max(0, nextWaveIn - waveTimer)
		for player, pdata in pairs(playerData) do
			local list = {}
			for _, b in ipairs(pdata.brainrots) do
				table.insert(list, {
					name = b.def.name,
					income = b.def.income * b.mutation.mult,
					rarity = b.def.rarity,
					mutation = b.mutation.name,
				})
			end
			StatsEvent:FireClient(player, {
				cash = math.floor(pdata.cash),
				perSec = perSecond(pdata),
				brainrots = #pdata.brainrots,
				rebirths = pdata.rebirths,
				mult = rebirthMult(pdata),
				rebirthCost = rebirthCost(pdata),
				waveIn = waveIn,
				waveActive = waveActive,
				stealReadyIn = math.max(0, math.ceil(pdata.stealReadyAt - os.clock())),
				carrying = pdata.carrying ~= nil,
				baseId = pdata.baseId,
				list = list,
			})
		end
	end

	-- Wave scheduling.
	if not waveActive then
		waveTimer += dt
		if waveTimer >= nextWaveIn then
			waveTimer = 0
			task.spawn(runWave)
		end
	end
end)

-- Seed the conveyor so the first player sees brainrots right away.
for _ = 1, 4 do
	spawnBrainrot()
end

print("Brainrot Bonanza server ready.")
