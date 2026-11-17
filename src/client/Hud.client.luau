-- Brainrot Bonanza — client.
-- Builds every screen the player sees and keeps it live: the start screen,
-- the top bar (cash, income, brainrots, rebirths, wave timer), the
-- collection panel, the leaderboard, the rebirth and slap buttons, the
-- tsunami banner and the toast notifications.
--
-- The server pushes state through three RemoteEvents:
--   Stats  — a snapshot once a second
--   Notify — one toast message
--   Wave   — tsunami phase changes ("warning" / "sweep" / "clear")
-- The client answers through Rebirth and Slap, plus the F key for slapping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StatsEvent = ReplicatedStorage:WaitForChild("Stats")
local RebirthEvent = ReplicatedStorage:WaitForChild("Rebirth")
local SlapEvent = ReplicatedStorage:WaitForChild("Slap")
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")
local WaveEvent = ReplicatedStorage:WaitForChild("Wave")

-- ------------------------------------------------------------- builders
-- Tiny helpers so every widget below reads the same way.
local function make(className, name, parent)
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function paintButton(btn, color)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.BorderSizePixel = 0
	local corner = make("UICorner", "Corner", btn)
	corner.CornerRadius = UDim.new(0, 8)
end

local function paintLabel(label, size, color)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = size
	label.TextScaled = false
end

local function rounded(frame, radius)
	local corner = make("UICorner", "Corner", frame)
	corner.CornerRadius = UDim.new(0, radius)
end

-- ------------------------------------------------------------------ root
local gui = make("ScreenGui", "BrainrotGui", playerGui)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- ----------------------------------------------------------- start screen
local startScreen = make("Frame", "StartScreen", gui)
startScreen.Size = UDim2.fromScale(1, 1)
startScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 35)
startScreen.BorderSizePixel = 0

local title = make("TextLabel", "Title", startScreen)
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.12, 0)
title.Size = UDim2.new(0.8, 0, 0.14, 0)
paintLabel(title, 56, Color3.fromRGB(255, 215, 0))
title.Text = "BRAINROT BONANZA"

local subtitle = make("TextLabel", "Subtitle", startScreen)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 0.27, 0)
subtitle.Size = UDim2.new(0.8, 0, 0.06, 0)
paintLabel(subtitle, 22, Color3.fromRGB(180, 220, 255))
subtitle.Text = "Collect meme brainrots. Earn cash every second. Steal. Rebirth. Survive the tsunami."

local howto = make("TextLabel", "HowTo", startScreen)
howto.AnchorPoint = Vector2.new(0.5, 0)
howto.Position = UDim2.new(0.5, 0, 0.36, 0)
howto.Size = UDim2.new(0.7, 0, 0.3, 0)
paintLabel(howto, 20, Color3.fromRGB(230, 230, 230))
howto.TextWrapped = true
howto.Text = "HOW TO PLAY\n\n"
	.. "1. Brainrots walk down the middle conveyor — press E to BUY one.\n"
	.. "2. It moves to your base and earns cash every second.\n"
	.. "3. Hold E on another player's brainrot to STEAL it, then dash\n"
	.. "   home before they SLAP you (F key).\n"
	.. "4. REBIRTH when you are rich: reset for a permanent income boost.\n"
	.. "5. When the TSUNAMI warning sounds, run to your base or get flung!"

local playButton = make("TextButton", "PlayButton", startScreen)
playButton.AnchorPoint = Vector2.new(0.5, 0)
playButton.Position = UDim2.new(0.5, 0, 0.72, 0)
playButton.Size = UDim2.new(0.3, 0, 0.09, 0)
playButton.Text = "PLAY"
paintButton(playButton, Color3.fromRGB(60, 200, 90))

playButton.MouseButton1Click:Connect(function()
	startScreen.Visible = false
end)

-- --------------------------------------------------------------- top bar
local topBar = make("Frame", "TopBar", gui)
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 8)
topBar.Size = UDim2.new(0.95, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
topBar.BackgroundTransparency = 0.25
topBar.BorderSizePixel = 0
rounded(topBar, 8)

-- One read-out in the top bar. x and width are fractions of the bar.
local function topReadout(name, x, width, color)
	local label = make("TextLabel", name, topBar)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(x, 0, 0.5, 0)
	label.Size = UDim2.new(width, 0, 0.8, 0)
	paintLabel(label, 18, color)
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

local cashLabel = topReadout("Cash", 0.01, 0.22, Color3.fromRGB(120, 255, 120))
local perSecLabel = topReadout("PerSec", 0.24, 0.16, Color3.fromRGB(255, 215, 0))
local brainrotLabel = topReadout("Brainrots", 0.41, 0.16, Color3.fromRGB(140, 220, 255))
local rebirthLabel = topReadout("Rebirths", 0.58, 0.14, Color3.fromRGB(255, 150, 255))
local waveLabel = topReadout("Wave", 0.73, 0.26, Color3.fromRGB(255, 120, 120))

-- ------------------------------------------------------- collection panel
local collection = make("Frame", "Collection", gui)
collection.AnchorPoint = Vector2.new(0, 0)
collection.Position = UDim2.new(0.01, 0, 0.12, 0)
collection.Size = UDim2.new(0.24, 0, 0.5, 0)
collection.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
collection.BackgroundTransparency = 0.25
collection.BorderSizePixel = 0
rounded(collection, 8)

local collectionTitle = make("TextLabel", "Title", collection)
collectionTitle.Position = UDim2.new(0, 0, 0, 0)
collectionTitle.Size = UDim2.new(1, 0, 0, 30)
paintLabel(collectionTitle, 18, Color3.fromRGB(255, 215, 0))
collectionTitle.Text = "MY BRAINROTS"

local collectionList = make("ScrollingFrame", "List", collection)
collectionList.Position = UDim2.new(0, 4, 0, 34)
collectionList.Size = UDim2.new(1, -8, 1, -38)
collectionList.BackgroundTransparency = 1
collectionList.ScrollBarThickness = 4
collectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
collectionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
make("UIListLayout", "Layout", collectionList).Padding = UDim.new(0, 4)

-- Rebuild the collection rows from the server's list snapshot.
local function refreshCollection(list)
	for _, child in ipairs(collectionList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if #list == 0 then
		local empty = make("TextLabel", "Empty", collectionList)
		empty.Size = UDim2.new(1, 0, 0, 24)
		paintLabel(empty, 15, Color3.fromRGB(180, 180, 180))
		empty.Text = "No brainrots yet — buy one off the conveyor!"
		empty.TextWrapped = true
		return
	end
	for _, entry in ipairs(list) do
		local row = make("TextLabel", "Row", collectionList)
		row.Size = UDim2.new(1, 0, 0, 24)
		paintLabel(row, 15, Config.RARITY_COLORS[entry.rarity] or Color3.fromRGB(255, 255, 255))
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = "• " .. entry.name .. "  (" .. entry.mutation .. ")  $" .. tostring(entry.income) .. "/s"
	end
end

-- ----------------------------------------------------------- leaderboard
local board = make("Frame", "Leaderboard", gui)
board.AnchorPoint = Vector2.new(1, 0)
board.Position = UDim2.new(0.99, 0, 0.12, 0)
board.Size = UDim2.new(0.2, 0, 0.4, 0)
board.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
board.BackgroundTransparency = 0.25
board.BorderSizePixel = 0
rounded(board, 8)

local boardTitle = make("TextLabel", "Title", board)
boardTitle.Position = UDim2.new(0, 0, 0, 0)
boardTitle.Size = UDim2.new(1, 0, 0, 30)
paintLabel(boardTitle, 18, Color3.fromRGB(255, 215, 0))
boardTitle.Text = "TOP PLAYERS"

local boardList = make("Frame", "List", board)
boardList.Position = UDim2.new(0, 4, 0, 34)
boardList.Size = UDim2.new(1, -8, 1, -38)
boardList.BackgroundTransparency = 1
make("UIListLayout", "Layout", boardList).Padding = UDim.new(0, 4)

-- Top 8 players by cash, read live from leaderstats.
local function refreshBoard()
	for _, child in ipairs(boardList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local rows = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		local ls = pl:FindFirstChild("leaderstats")
		local cash = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
		table.insert(rows, { name = pl.DisplayName, cash = cash })
	end
	table.sort(rows, function(a, b)
		return a.cash > b.cash
	end)
	for i, row in ipairs(rows) do
		if i > 8 then
			break
		end
		local line = make("TextLabel", "Row", boardList)
		line.Size = UDim2.new(1, 0, 0, 22)
		paintLabel(line, 15, i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(230, 230, 230))
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Text = tostring(i) .. ". " .. row.name .. " — " .. Config.formatCash(row.cash)
	end
end

-- --------------------------------------------------------- action buttons
local rebirthButton = make("TextButton", "RebirthButton", gui)
rebirthButton.AnchorPoint = Vector2.new(1, 1)
rebirthButton.Position = UDim2.new(0.99, 0, 0.98, 0)
rebirthButton.Size = UDim2.new(0.2, 0, 0.07, 0)
rebirthButton.Text = "REBIRTH"
paintButton(rebirthButton, Color3.fromRGB(170, 90, 220))

local slapButton = make("TextButton", "SlapButton", gui)
slapButton.AnchorPoint = Vector2.new(0, 1)
slapButton.Position = UDim2.new(0.01, 0, 0.98, 0)
slapButton.Size = UDim2.new(0.14, 0, 0.07, 0)
slapButton.Text = "SLAP (F)"
paintButton(slapButton, Color3.fromRGB(220, 80, 60))

-- Shown while carrying a stolen brainrot.
local carryingLabel = make("TextLabel", "Carrying", gui)
carryingLabel.AnchorPoint = Vector2.new(0.5, 1)
carryingLabel.Position = UDim2.new(0.5, 0, 0.9, 0)
carryingLabel.Size = UDim2.new(0.5, 0, 0.06, 0)
paintLabel(carryingLabel, 20, Color3.fromRGB(255, 120, 120))
carryingLabel.Text = ""
carryingLabel.Visible = false

-- ------------------------------------------------------------ wave banner
local waveBanner = make("Frame", "WaveBanner", gui)
waveBanner.AnchorPoint = Vector2.new(0.5, 0)
waveBanner.Position = UDim2.new(0.5, 0, 0.09, 0)
waveBanner.Size = UDim2.new(0.6, 0, 0.07, 0)
waveBanner.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
waveBanner.BorderSizePixel = 0
waveBanner.Visible = false
rounded(waveBanner, 8)

local waveText = make("TextLabel", "Text", waveBanner)
waveText.Size = UDim2.new(1, 0, 1, 0)
paintLabel(waveText, 22, Color3.fromRGB(255, 255, 255))
waveText.Text = ""

-- ---------------------------------------------------------- notifications
local notifyLabel = make("TextLabel", "Notify", gui)
notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
notifyLabel.Position = UDim2.new(0.5, 0, 0.2, 0)
notifyLabel.Size = UDim2.new(0.6, 0, 0.05, 0)
paintLabel(notifyLabel, 20, Color3.fromRGB(255, 255, 255))
notifyLabel.Text = ""
notifyLabel.Visible = false

local notifyUntil = 0
local function notify(text)
	notifyLabel.Text = text
	notifyLabel.Visible = true
	notifyUntil = os.clock() + 4
end

-- ---------------------------------------------------------------- events
rebirthButton.MouseButton1Click:Connect(function()
	RebirthEvent:FireServer()
end)

slapButton.MouseButton1Click:Connect(function()
	SlapEvent:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		SlapEvent:FireServer()
	end
end)

-- The once-a-second snapshot drives every readout.
StatsEvent.OnClientEvent:Connect(function(s)
	cashLabel.Text = "Cash: " .. Config.formatCash(s.cash)
	perSecLabel.Text = "+" .. Config.formatCash(s.perSec) .. "/s"
	brainrotLabel.Text = "Brainrots: " .. tostring(s.brainrots) .. "/8"
	rebirthLabel.Text = "Rebirths: " .. tostring(s.rebirths) .. " (x" .. string.format("%.2f", s.mult) .. ")"
	if s.waveActive then
		waveLabel.Text = "TSUNAMI NOW!"
	else
		waveLabel.Text = "Wave in " .. tostring(math.ceil(s.waveIn)) .. "s"
	end
	rebirthButton.Text = "REBIRTH — " .. Config.formatCash(s.rebirthCost)
	carryingLabel.Visible = s.carrying
	if s.carrying then
		carryingLabel.Text = "CARRYING A STOLEN BRAINROT — DASH TO YOUR BASE!"
	end
	if s.list then
		refreshCollection(s.list)
	end
end)

NotifyEvent.OnClientEvent:Connect(notify)

WaveEvent.OnClientEvent:Connect(function(state, seconds)
	if state == "warning" then
		waveBanner.Visible = true
		waveText.Text = "🌊 BRAINROT TSUNAMI IN " .. tostring(seconds) .. "s — DASH TO YOUR BASE!"
	elseif state == "sweep" then
		waveBanner.Visible = true
		waveText.Text = "🌊 TSUNAMI! STAY IN YOUR BASE!"
	else
		waveBanner.Visible = false
	end
end)

-- Refresh the leaderboard and clear stale toasts on a loop.
task.spawn(function()
	while true do
		task.wait(2)
		refreshBoard()
		if notifyLabel.Visible and os.clock() > notifyUntil then
			notifyLabel.Visible = false
		end
	end
end)

refreshBoard()
