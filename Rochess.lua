local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Chess = ReplicatedStorage:WaitForChild("Chess")
local Client = ReplicatedStorage:WaitForChild("ChessClient")

local function req(mod)
	return require(mod)
end

local Engine = req(Chess:WaitForChild("Engine"))
local Bot = req(Chess:WaitForChild("Bot"))
local VortexBot = req(Chess:WaitForChild("VortexBot"))
local App = req(Client:WaitForChild("App"))

local GENV = type(getgenv) == "function" and getgenv() or _G
-- Teleport auto-relaunch (executor support required). Added without changing existing code.
do
    local queue = (type(queue_on_teleport) == "function" and queue_on_teleport)
        or (type(syn) == "table" and type(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
        or (type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)
    if queue then
        local source = nil
        if type(readfile) == "function" and type(isfile) == "function" and isfile("rochess-1.txt") then
            source = 'loadstring(readfile("rochess-1.txt"))()'
        elseif type(GENV.__RoCheeseTeleportSource) == "string" then
            source = GENV.__RoCheeseTeleportSource
        end
        if source then
            pcall(queue, source)
        else
            warn("[rocheese] Teleport autorun: save script as rochess-1.txt in executor workspace or set getgenv().__RoCheeseTeleportSource to a loader")
        end
    end
end

if type(GENV.__RoCheeseDispose) == "function" then
    pcall(GENV.__RoCheeseDispose)
end
GENV.__RoCheeseGen = (GENV.__RoCheeseGen or 0) + 1
local GEN = GENV.__RoCheeseGen

local CFG = {
	DEPTH = 16,
	SECONDS = 0.8,
	CHILD_DEPTH = 8,
	CHILD_SECONDS = 0.06,
	VK_SHIFT = 160,
	PROMO = { q = 5, r = 4, b = 3, n = 2 },
	ARROW_1 = Color3.fromRGB(129, 182, 76),
	ARROW_2 = Color3.fromRGB(96, 156, 240),
	ARROW_3 = Color3.fromRGB(240, 200, 70),
	DELAY_MIN = 0,
	DELAY_MAX = 20,
	DELAY_STEP = 0.5,
}

local PRESETS = {
	legit = {
		label = "LEGIT",
		source = "local",
		mode = "elo",
		elo = 1500,
		noise = 0.32,
		blunder = 0.06,
		delayMin = 5,
		delayMax = 10,
	},
	raj = {
		label = "RAJ",
		source = "vortex",
		mode = "best",
		elo = 1800,
		noise = 0,
		blunder = 0,
		delayMin = 0.5,
		delayMax = 1.5,
	},
}

local RUNTIME = GENV.__RoCheese or {}
RUNTIME.SHOW_ARROW = RUNTIME.SHOW_ARROW ~= false
RUNTIME.AUTO = RUNTIME.AUTO == true
RUNTIME.HUMANIZE = RUNTIME.HUMANIZE ~= false
RUNTIME.SOURCE = RUNTIME.SOURCE == "vortex" and "vortex" or "local"
RUNTIME.MODE = RUNTIME.MODE == "best" and "best" or "elo"
RUNTIME.ELO = tonumber(RUNTIME.ELO) or 1500
RUNTIME.NOISE = tonumber(RUNTIME.NOISE) or 0.32
RUNTIME.BLUNDER = tonumber(RUNTIME.BLUNDER) or 0.06
RUNTIME.DELAY_MIN = math.clamp(tonumber(RUNTIME.DELAY_MIN) or 5, CFG.DELAY_MIN, CFG.DELAY_MAX)
RUNTIME.DELAY_MAX = math.clamp(tonumber(RUNTIME.DELAY_MAX) or 10, CFG.DELAY_MIN, CFG.DELAY_MAX)
RUNTIME.STYLE = RUNTIME.STYLE == "raj" and "raj" or (RUNTIME.STYLE == "legit" and "legit" or "custom")
RUNTIME.ELO = math.clamp(RUNTIME.ELO, 100, 3200)
RUNTIME.NOISE = math.clamp(RUNTIME.NOISE, 0, 1)
RUNTIME.BLUNDER = math.clamp(RUNTIME.BLUNDER, 0, 1)
RUNTIME.DELAY_MIN = math.min(RUNTIME.DELAY_MIN, CFG.DELAY_MAX - CFG.DELAY_STEP)
RUNTIME.DELAY_MAX = math.max(RUNTIME.DELAY_MAX, RUNTIME.DELAY_MIN + CFG.DELAY_STEP)
GENV.__RoCheese = RUNTIME

local ARROW_KEYS = { "rc1", "rc2", "rc3" }

local S = {
	ply = -1,
	sessionId = nil,
	best = nil,
	san = nil,
	score = 0,
	depth = 0,
	second = nil,
	third = nil,
	secondSan = nil,
	thirdSan = nil,
	busy = false,
	autoAt = 0,
	thinkAt = 0,
	status = "loading",
}
GENV.__RoCheeseState = S

local connections = {}
local disposers = {}
local disposed = false
local function alive()
    return not disposed and GENV.__RoCheeseGen == GEN
end
local function cleanup(fn)
    table.insert(disposers, fn)
end
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function dispose()
    if disposed then return end
    disposed = true
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, fn in ipairs(disposers) do pcall(fn) end
end
GENV.__RoCheeseDispose = dispose

-- board ------------------------------------------------------------------------------------

local function clearArrows()
	local board = App.board
	if not board or type(board.setArrow) ~= "function" then
		return
	end
	for _, key in ARROW_KEYS do
		pcall(function()
			board:setArrow(key, nil)
			board:setTint(key, nil)
		end)
	end
	-- older build of this script used a single arrow key
	pcall(function()
		board:setArrow("rocheese", nil)
		board:setTint("rocheese", nil)
	end)
end

local function drawArrow(key, uci, color, tint)
	local board = App.board
	if not board then
		return
	end
	local from = Engine.algToIndex64(uci:sub(1, 2))
	local to = Engine.algToIndex64(uci:sub(3, 4))
	if not from or not to then
		return
	end
	pcall(function()
		board:setArrow(key, from, to, color, 0.12)
		if tint then
			board:setTint(key, to, color, 0.26)
		end
	end)
end

-- engine ----------------------------------------------------------------------------------

local function buildEngine(startFen, moves)
	local engine = Engine.new(startFen)
	for _, uci in ipairs(moves) do
		local mv = engine:moveFromUci(uci)
		if not mv then
			return nil
		end
		engine:play(mv)
	end
	return engine
end

local function sanOf(engine, uci)
	if not engine or not uci then
		return nil
	end
	local want = string.lower(uci)
	for _, mv in engine:legalMoves() do
		local u = engine:moveToUci(mv)
		if u and string.lower(u) == want then
			return engine:moveToSan(mv)
		end
	end
	return nil
end

local function analyseBest(startFen, moves)
	if RUNTIME.SOURCE == "vortex" then
		local ok, res = pcall(VortexBot.analyse, startFen, moves, CFG.SECONDS, CFG.DEPTH)
		if ok and type(res) == "table" and res.best then
			return res
		end
	end
	local ok, res = pcall(Bot.analyse, startFen, moves, CFG.SECONDS, CFG.DEPTH)
	if ok and type(res) == "table" then
		return res
	end
	return nil
end

-- ranks every continuation of the position, so the 2nd and 3rd arrows have a real order
local function rankContinuations(startFen, moves, skipUci, isCurrent)
	local engine = buildEngine(startFen, moves)
	if not engine then
		return nil
	end
	local scored = {}
	for _, mv in engine:legalMoves() do
		if isCurrent and not isCurrent() then return nil end
		local uci = engine:moveToUci(mv)
		if not skipUci or string.lower(uci) ~= string.lower(skipUci) then
			local child = buildEngine(startFen, moves)
			local ok = pcall(function()
				child:playUci(uci)
			end)
			if ok then
				local success, cres = pcall(Bot.analyse, child:getFen(), {}, CFG.CHILD_SECONDS, CFG.CHILD_DEPTH)
				local score = success and type(cres) == "table" and tonumber(cres.score)
				if score and score == score and math.abs(score) < math.huge then
					table.insert(scored, {
						uci = uci,
						san = engine:moveToSan(mv),
						score = score,
					})
				end
			end
		end
	end
	table.sort(scored, function(a, b)
		local whiteToMove = engine:getFen():match("%s(w)%s") ~= nil
        return (whiteToMove and a.score > b.score) or (not whiteToMove and a.score < b.score)
	end)
	return scored
end

local function pickMove(session)
	if RUNTIME.MODE == "elo" then
		local ok, uci = pcall(Bot.think, session.startFen, table.clone(session.ucis), {
			rating = RUNTIME.ELO,
			noise = RUNTIME.NOISE,
			blunder = RUNTIME.BLUNDER,
			time = 0.6,
			depth = 14,
		})
		if ok and type(uci) == "string" then
			return uci
		end
	end
	return S.best
end

-- playing ---------------------------------------------------------------------------------

local function tapInput()
	if not RUNTIME.HUMANIZE then
		return
	end
	if type(keyclick) ~= "function" then
		return
	end
	if type(isrbxactive) == "function" and not isrbxactive() then
		return
	end
	pcall(keyclick, CFG.VK_SHIFT)
end

local function playUci(uci)
	local session = App.session
	if not alive() or not session or session.over then
		return false, "no game"
	end
	if not session:isMyTurn() or session.viewPly ~= #session.ucis then
		return false, "not at your live turn"
	end
	if type(uci) ~= "string" then return false, "bad uci" end
	uci = string.lower(uci)
	if not uci:match("^[a-h][1-8][a-h][1-8][qrbn]?$") then
		return false, "bad uci"
	end
	local valid, san = pcall(function()
		return sanOf(buildEngine(session.startFen, session.ucis), uci)
	end)
	if not valid or not san then return false, "illegal move" end
	local from = Engine.algToIndex64(uci:sub(1, 2))
	local to = Engine.algToIndex64(uci:sub(3, 4))
	if not from or not to then return false, "bad uci" end
	local before = #session.ucis
	tapInput()
	local ok, result = pcall(function()
		if type(App.onBoardMove) == "function" then
			return App.onBoardMove(from, to, CFG.PROMO[uci:sub(5, 5)] or 0, nil)
		end
		return App.playMove(uci)
	end)
	-- Never call both handlers: the first may already have sent the move.
	if not ok then return false, "move handler failed" end
	if result == false or App.session ~= session or #session.ucis <= before then
		return false, "move not confirmed"
	end
	return true, uci
end

local function humanDelay()
	local lo = math.min(RUNTIME.DELAY_MIN, RUNTIME.DELAY_MAX)
	local hi = math.max(RUNTIME.DELAY_MIN, RUNTIME.DELAY_MAX)
	if hi - lo < 0.2 then
		return lo
	end
	return lo + math.random() * (hi - lo)
end

local function autopilotTick(session, ply)
	if not RUNTIME.AUTO or S.playPending or S.busy or not S.best then return end
	if session.over or not session:isMyTurn() or session.viewPly ~= ply then return end
	if os.clock() < math.max(S.thinkAt, S.autoAt) then return end
	local moves = table.concat(session.ucis, " ")
	local analysisId = S.analysisId
	S.playPending = true
	task.spawn(function()
		local ok, err = pcall(function()
			local uci = pickMove(session)
			if alive() and RUNTIME.AUTO and App.session == session
				and S.analysisId == analysisId and table.concat(session.ucis, " ") == moves then
				local played, message = playUci(uci)
				if not played then S.status = message end
			end
		end)
		S.playPending = false
		S.autoAt = os.clock() + 1
		if not ok and alive() then S.status = "autoplay failed" end
	end)
end

-- ui --------------------------------------------------------------------------------------

local ZENIN_URL = "https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"
local SOURCE_LABELS = { ["local"] = "Local", vortex = "Vortex" }
local SOURCE_KEYS = { Local = "local", Vortex = "vortex" }
local MODE_LABELS = { elo = "Rating", best = "Best move" }
local MODE_KEYS = { Rating = "elo", ["Best move"] = "best" }
local STYLE_LABELS = { legit = "Legit", raj = "Raj", custom = "Custom" }

local Window
local ui, shown = {}, {}
local lastEval
local toggleAuto, playNow, copyPosition, startBotGame, applyPreset, syncControls

local function loadZenin()
	if type(loadstring) ~= "function" then
		return nil, "loadstring is unavailable"
	end
	local ok, result = pcall(function()
		local chunk, err = loadstring(game:HttpGet(ZENIN_URL))
		if type(chunk) ~= "function" then
			error(tostring(err), 0)
		end
		return chunk()
	end)
	if not ok then
		return nil, tostring(result)
	end
	if type(result) ~= "table" or type(result.CreateWindow) ~= "function" then
		return nil, "not a ZeninLib module"
	end
	return result
end

-- Programmatic updates are silent so they do not re-enter control callbacks.
local function setControl(key, value)
	local el = ui[key]
	if el and el:Get() ~= value then
		el:Set(value, true)
	end
end

syncControls = function()
	if not Window then
		return
	end
	setControl("auto", RUNTIME.AUTO)
	setControl("arrows", RUNTIME.SHOW_ARROW)
	setControl("humanize", RUNTIME.HUMANIZE)
	setControl("preset", STYLE_LABELS[RUNTIME.STYLE])
	setControl("source", SOURCE_LABELS[RUNTIME.SOURCE])
	setControl("mode", MODE_LABELS[RUNTIME.MODE])
	setControl("elo", RUNTIME.ELO)
	setControl("noise", math.floor(RUNTIME.NOISE * 100 + 0.5))
	setControl("blunder", math.floor(RUNTIME.BLUNDER * 100 + 0.5))
	setControl("delayMin", RUNTIME.DELAY_MIN)
	setControl("delayMax", RUNTIME.DELAY_MAX)
	local rated = RUNTIME.MODE == "elo"
	for _, key in ipairs({ "elo", "noise", "blunder" }) do
		ui[key]:SetEnabled(rated)
	end
end

-- Any manual engine or timing change leaves the named preset.
local function custom(apply)
	return function(value)
		apply(value)
		RUNTIME.STYLE = "custom"
		syncControls()
	end
end

local function setDelayMin(value)
	RUNTIME.DELAY_MIN = math.clamp(value, CFG.DELAY_MIN, CFG.DELAY_MAX - CFG.DELAY_STEP)
	RUNTIME.DELAY_MAX = math.max(RUNTIME.DELAY_MAX, RUNTIME.DELAY_MIN + CFG.DELAY_STEP)
end

local function setDelayMax(value)
	RUNTIME.DELAY_MAX = math.clamp(value, CFG.DELAY_MIN + CFG.DELAY_STEP, CFG.DELAY_MAX)
	RUNTIME.DELAY_MIN = math.min(RUNTIME.DELAY_MIN, RUNTIME.DELAY_MAX - CFG.DELAY_STEP)
end

local function setArrows(value)
	RUNTIME.SHOW_ARROW = value == true
	if not RUNTIME.SHOW_ARROW then
		clearArrows()
	end
	syncControls()
end

local function setSource(source)
	RUNTIME.SOURCE = source
	S.ply = -1
end

local function buildUi()
	local Library, err = loadZenin()
	if not Library then
		warn("[rocheese] failed to load ZeninLib: " .. err)
		return false
	end

	Window = Library:CreateWindow({
		Title = "RoCheese",
		Logo = "R",
		GuiName = "RoCheese",
		ToggleKey = Enum.KeyCode.PageUp,
		Configs = true,
		ConfigFolder = "RoCheese",
		Watermark = { Title = "rocheese", Site = "chess", Detail = "roblox" },
	})

	local main = Window:AddTab({ Name = "Main", Icon = "crown" })
	do
		local analysis = main:AddSection({ Name = "Analysis", Side = "Left" })
		ui.best = analysis:AddCardButton({
			Name = "Waiting for game",
			Description = "Best move",
			Icon = "crown",
			ButtonText = "Play",
			Callback = function()
				playNow()
			end,
		})
		ui.game = analysis:AddCardButton({
			Name = "Loading",
			Description = "No game",
			Icon = "swords",
			ButtonText = "Copy",
			Callback = function()
				copyPosition()
			end,
		})

		local controls = main:AddSection({ Name = "Controls", Side = "Right" })
		ui.auto = controls:AddToggle({
			Name = "Autoplay",
			Default = RUNTIME.AUTO,
			Flag = "RC_Auto",
			Callback = function(value)
				if value ~= RUNTIME.AUTO then
					toggleAuto()
				end
			end,
		})
		ui.arrows = controls:AddToggle({
			Name = "Move Arrows",
			Default = RUNTIME.SHOW_ARROW,
			Flag = "RC_Arrows",
			Callback = setArrows,
		})
		ui.preset = controls:AddDropdown({
			Name = "Preset",
			Options = { "Legit", "Raj", "Custom" },
			Default = STYLE_LABELS[RUNTIME.STYLE],
			Callback = function(value)
				if value == "Custom" then
					RUNTIME.STYLE = "custom"
				else
					applyPreset(string.lower(value))
				end
			end,
		})
		controls:AddButton({
			Name = "Start Practice Game",
			Callback = function()
				startBotGame()
			end,
		})
	end

	local engine = Window:AddTab({ Name = "Engine", Icon = "cpu" })
	do
		local search = engine:AddSection({ Name = "Search", Side = "Left" })
		ui.source = search:AddDropdown({
			Name = "Analysis Source",
			Options = { "Local", "Vortex" },
			Default = SOURCE_LABELS[RUNTIME.SOURCE],
			Flag = "RC_Source",
			Callback = custom(function(value)
				setSource(SOURCE_KEYS[value] or "local")
			end),
		})
		ui.mode = search:AddDropdown({
			Name = "Move Choice",
			Options = { "Rating", "Best move" },
			Default = MODE_LABELS[RUNTIME.MODE],
			Flag = "RC_Mode",
			Callback = custom(function(value)
				RUNTIME.MODE = MODE_KEYS[value] or "elo"
			end),
		})

		local strength = engine:AddSection({ Name = "Strength", Side = "Right" })
		ui.elo = strength:AddSlider({
			Name = "Rating",
			Min = 100,
			Max = 3200,
			Step = 50,
			Default = RUNTIME.ELO,
			Flag = "RC_Elo",
			Callback = custom(function(value)
				RUNTIME.ELO = value
			end),
		})
		ui.noise = strength:AddSlider({
			Name = "Noise",
			Min = 0,
			Max = 100,
			Default = math.floor(RUNTIME.NOISE * 100 + 0.5),
			Suffix = "%",
			Flag = "RC_Noise",
			Callback = custom(function(value)
				RUNTIME.NOISE = value / 100
			end),
		})
		ui.blunder = strength:AddSlider({
			Name = "Blunder Chance",
			Min = 0,
			Max = 100,
			Default = math.floor(RUNTIME.BLUNDER * 100 + 0.5),
			Suffix = "%",
			Flag = "RC_Blunder",
			Callback = custom(function(value)
				RUNTIME.BLUNDER = value / 100
			end),
		})
	end

	local automation = Window:AddTab({ Name = "Automation", Icon = "timer" })
	do
		local timing = automation:AddSection({ Name = "Think Time", Side = "Left" })
		ui.delayMin = timing:AddSlider({
			Name = "Minimum",
			Min = CFG.DELAY_MIN,
			Max = CFG.DELAY_MAX - CFG.DELAY_STEP,
			Step = CFG.DELAY_STEP,
			Default = RUNTIME.DELAY_MIN,
			Suffix = " s",
			Flag = "RC_DelayMin",
			Callback = custom(setDelayMin),
		})
		ui.delayMax = timing:AddSlider({
			Name = "Maximum",
			Min = CFG.DELAY_MIN + CFG.DELAY_STEP,
			Max = CFG.DELAY_MAX,
			Step = CFG.DELAY_STEP,
			Default = RUNTIME.DELAY_MAX,
			Suffix = " s",
			Flag = "RC_DelayMax",
			Callback = custom(setDelayMax),
		})

		local input = automation:AddSection({ Name = "Input", Side = "Right" })
		ui.humanize = input:AddToggle({
			Name = "Humanize Input",
			Default = RUNTIME.HUMANIZE,
			Flag = "RC_Humanize",
			Callback = function(value)
				RUNTIME.HUMANIZE = value == true
			end,
		})
	end

	local about = Window.Settings:AddSection({ Name = "RoCheese", Side = "Right" })
	about:AddCardButton({
		Name = "Unload",
		Description = "Close the menu and stop RoCheese",
		Icon = "power",
		ButtonText = "Unload",
		Callback = function()
			dispose()
		end,
	})

	local window = Window
	window:OnUnload(function()
		if Window == window then
			Window = nil
		end
		dispose()
	end)
	cleanup(function()
		window:Destroy()
	end)

	syncControls()
	Window:Notify({
		Title = "RoCheese",
		Content = "PageUp menu · End autoplay · Home arrows · PageDown source · Insert copy",
		Duration = 6,
	})
	return true
end

-- actions ---------------------------------------------------------------------------------

toggleAuto = function()
	RUNTIME.AUTO = not RUNTIME.AUTO
	S.thinkAt = os.clock() + (RUNTIME.AUTO and humanDelay() or 0)
	S.status = RUNTIME.AUTO and "autopilot on" or "autopilot off"
	syncControls()
end

playNow = function()
	local session = App.session
	if not session then S.status = "no game running"; return end
	if S.playPending or os.clock() < S.autoAt then return end
	if S.busy or not S.best then S.status = "engine still thinking"; return end
	local position = session.startFen .. "|" .. table.concat(session.ucis, " ")
	if S.session ~= session or S.positionKey ~= position then
		S.status = "waiting for current analysis"; return
	end
	local analysisId = S.analysisId
	S.playPending = true
	local success, err = pcall(function()
		local uci = pickMove(session)
		if not alive() or App.session ~= session or S.analysisId ~= analysisId
			or session.startFen .. "|" .. table.concat(session.ucis, " ") ~= position then
			return
		end
		local ok, message = playUci(uci)
		S.status = ok and ("played " .. message) or message
	end)
	S.playPending = false
	S.autoAt = os.clock() + 1
	if not success then S.status = "move selection failed" end
end

copyPosition = function()
	local session = App.session
	if not session then
		S.status = "no game running"
		return
	end
	local fen = session.engine:getFen()
	local sans = table.concat(session.sans, " ")
	local ok = type(setclipboard) == "function" and pcall(setclipboard, fen .. "\n" .. sans)
	S.status = ok and "fen + moves copied" or "clipboard unavailable"
end

startBotGame = function()
	local ok, err = pcall(function()
		App.startBotGame("jasper", "white")
	end)
	S.status = ok and "practice game started" or ("bot game failed: " .. tostring(err))
end

applyPreset = function(name)
	local preset = PRESETS[name]
	if not preset then
		return
	end
	RUNTIME.STYLE = name
	RUNTIME.SOURCE = preset.source
	RUNTIME.MODE = preset.mode
	RUNTIME.ELO = preset.elo
	RUNTIME.NOISE = preset.noise
	RUNTIME.BLUNDER = preset.blunder
	RUNTIME.DELAY_MIN = preset.delayMin
	RUNTIME.DELAY_MAX = preset.delayMax
	S.ply = -1
	S.status = name .. " preset"
	syncControls()
end

local setDelay = function(lo, hi)
	lo = math.clamp(tonumber(lo) or RUNTIME.DELAY_MIN, CFG.DELAY_MIN, CFG.DELAY_MAX)
	hi = math.clamp(tonumber(hi) or RUNTIME.DELAY_MAX, CFG.DELAY_MIN, CFG.DELAY_MAX)
	if hi < lo then
		lo, hi = hi, lo
	end
	RUNTIME.DELAY_MIN = math.min(19.5, math.floor(lo / CFG.DELAY_STEP + 0.5) * CFG.DELAY_STEP)
	RUNTIME.DELAY_MAX = math.floor(hi / CFG.DELAY_STEP + 0.5) * CFG.DELAY_STEP
	if RUNTIME.DELAY_MAX - RUNTIME.DELAY_MIN < CFG.DELAY_STEP then
		RUNTIME.DELAY_MAX = RUNTIME.DELAY_MIN + CFG.DELAY_STEP
	end
	RUNTIME.STYLE = "custom"
	syncControls()
end

-- hotkeys ---------------------------------------------------------------------------------

local function onKey(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then
		return
	end
	local code = input.KeyCode
	if code == Enum.KeyCode.End then
		toggleAuto()
	elseif code == Enum.KeyCode.Home then
		setArrows(not RUNTIME.SHOW_ARROW)
	elseif code == Enum.KeyCode.Equals or code == Enum.KeyCode.KeypadPlus then
		-- PageUp is handled by ZeninLib's ToggleKey.
		if Window then
			Window:Toggle()
		end
	elseif code == Enum.KeyCode.PageDown then
		setSource(RUNTIME.SOURCE == "local" and "vortex" or "local")
		RUNTIME.STYLE = "custom"
		syncControls()
	elseif code == Enum.KeyCode.Insert then
		copyPosition()
	end
end

local prevConn = GENV.__RoCheeseConn
if prevConn then
	pcall(function()
		prevConn:Disconnect()
	end)
end
local conn = connect(UserInputService.InputBegan, onKey)
GENV.__RoCheeseConn = conn
cleanup(function()
	conn:Disconnect()
end)

-- eval bar -------------------------------------------------------------------------------
-- the game already ships a chess-style eval bar next to the board, it is just never
-- switched on during a normal game. Feeding it our score wakes it up.
local GAME_KINDS = {
	bot = true,
	online = true,
	puzzle = true,
	rush = true,
}

local function pushEval()
	local session = App.session
	local kind = session and session.kind
	if not session or not kind or not GAME_KINDS[kind] then
		lastEval = nil
		return
	end
	if S.busy or not S.best then
		return
	end
	local score = S.score
	if lastEval == score then
		return
	end
	lastEval = score
	local mate = nil
	if math.abs(score) >= 29900 then
		mate = math.max(1, math.floor((30000 - math.abs(score)) / 100 + 0.5))
	end
	pcall(function()
		App.setEval(score, mate)
	end)
end

-- ui refresh ------------------------------------------------------------------------------

local function formatClock(ms)
	if type(ms) ~= "number" then
		return "-"
	end
	ms = math.max(0, ms)
	local total = math.floor(ms / 1000)
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

local function evalText(score)
	local abs = math.abs(score)
	if abs >= 29900 then
		local moves = math.max(1, math.floor((30000 - abs) / 100 + 0.5))
		return string.format("M%d %s", moves, score > 0 and "white" or "black")
	end
	local pawns = score / 100
	return string.format("%s%.2f", pawns >= 0 and "+" or "", pawns)
end

local function setCard(key, name, description)
	local card = ui[key]
	if not card then
		return
	end
	local cache = shown[key] or {}
	shown[key] = cache
	if cache.name ~= name then
		cache.name = name
		card:SetName(name)
	end
	if cache.description ~= description then
		cache.description = description
		card:SetDescription(description)
	end
end

local function refreshUi(session, ply)
	if not session then
		setCard("best", "Waiting for game", "Best move")
		setCard("game", S.status, "No game")
	elseif S.busy or not S.best then
		setCard("best", "Thinking...", "Best move")
	else
		local alternatives = {}
		for _, san in ipairs({ S.secondSan or S.second, S.thirdSan or S.third }) do
			table.insert(alternatives, san)
		end
		local detail = string.format("Depth %d", S.depth)
		if #alternatives > 0 then
			detail = detail .. "  ·  then " .. table.concat(alternatives, ", ")
		end
		setCard("best", string.format("%s   %s", S.san or S.best, evalText(S.score)), detail)
	end

	if session then
		local side = session.myColor == 1 and (session.white and session.white.display or "White")
			or (session.black and session.black.display or "Black")
		local clocks = ""
		if session.clocks and session.myColor then
			clocks = string.format("  ·  %s / %s",
				formatClock(session.clocks[session.myColor]),
				formatClock(session.clocks[-session.myColor]))
		end
		local status = session.kind == "idle" and "No game - start one or use Practice" or S.status
		setCard("game", status, string.format("%s  ·  ply %d%s", side, ply, clocks))
	end

	pushEval()
end

-- main loop -------------------------------------------------------------------------------

if not buildUi() then
	dispose()
	return
end
S.status = "ready"

GENV.__RoCheese.api = {
	auto = toggleAuto,
	play = playNow,
	copy = copyPosition,
	delay = setDelay,
	preset = applyPreset,
	state = function()
		return {
			ply = S.ply,
			best = S.best,
			san = S.san,
			second = S.second,
			third = S.third,
			score = S.score,
			depth = S.depth,
			status = S.status,
			auto = RUNTIME.AUTO,
			style = RUNTIME.STYLE,
			source = RUNTIME.SOURCE,
			mode = RUNTIME.MODE,
			delayMin = RUNTIME.DELAY_MIN,
			delayMax = RUNTIME.DELAY_MAX,
		}
	end,
}

task.spawn(function()
	while alive() do
		local session = App.session
		local ply = session and #session.ucis or -1
		local sid = session and session.id or nil
		local positionKey = session and (session.startFen .. "|" .. table.concat(session.ucis, " ")) or nil

		if session ~= S.session then
			S.session = session
			S.sessionId = sid
            S.ply = -1
			lastEval = nil
			pcall(function()
				Bot.clearTT()
			end)
		end

		if not session then
			S.analysisId = (S.analysisId or 0) + 1
			S.ply, S.positionKey, S.best, S.second, S.third = -1, nil, nil, nil, nil
			S.busy = false
			S.status = "waiting for game"
			clearArrows()
		end

		if session and (ply ~= S.ply or positionKey ~= S.positionKey) then
			S.analysisId = (S.analysisId or 0) + 1
			S.positionKey = positionKey
			S.busy = false
			S.ply = ply
			-- a new position means a fresh think time, exactly like a human
			S.thinkAt = os.clock() + humanDelay()
			S.best = nil
			S.san = nil
			S.second = nil
			S.third = nil
			S.secondSan = nil
			S.thirdSan = nil
			clearArrows()
			if not S.busy then
				S.busy = true
				local startFen = session.startFen
				local moves = table.clone(session.ucis)
				local wantPly = ply
				local analysisId = S.analysisId
				local source = RUNTIME.SOURCE
				local function isCurrent()
					return alive() and S.analysisId == analysisId and RUNTIME.SOURCE == source and App.session == session
						and session.startFen .. "|" .. table.concat(session.ucis, " ") == positionKey
				end

				task.spawn(function()
					-- main search: the best move and the eval
					local success, res = pcall(analyseBest, startFen, moves)
					if not isCurrent() then
						return
					end
					S.busy = false
					local live = App.session
					if live ~= session or not live or #live.ucis ~= wantPly then
						S.ply = -1
						return
					end
					if not success or type(res) ~= "table" or type(res.best) ~= "string" then
						S.status = "engine failed"
						return
					end
					local legal, san = pcall(function()
						return sanOf(buildEngine(startFen, moves), res.best)
					end)
					if not legal or not san then S.status = "engine returned an illegal move"; return end
					S.best = res.best
					S.score = tonumber(res.score) or 0
					S.depth = tonumber(res.depth) or 0
					S.status = "engine ready"
					S.san = san

					-- second pass: rank the continuations for the 2nd and 3rd arrows
					task.spawn(function()
						local rankedOk, ranked = pcall(rankContinuations, startFen, moves, res.best, isCurrent)
						if not rankedOk or not isCurrent() then
							return
						end
						local live2 = App.session
						if live2 ~= session or not live2 or #live2.ucis ~= wantPly or not ranked then
							return
						end
						S.second = ranked[1] and ranked[1].uci or nil
						S.secondSan = ranked[1] and ranked[1].san or nil
						S.third = ranked[2] and ranked[2].uci or nil
						S.thirdSan = ranked[2] and ranked[2].san or nil
					end)
				end)
			end
		end

		if session then
			local live = RUNTIME.SHOW_ARROW and session.viewPly == ply and not session.over
			if live then
				if S.best then
					drawArrow(ARROW_KEYS[1], S.best, CFG.ARROW_1, true)
				end
				if S.second then
					drawArrow(ARROW_KEYS[2], S.second, CFG.ARROW_2, false)
				end
				if S.third then
					drawArrow(ARROW_KEYS[3], S.third, CFG.ARROW_3, false)
				end
			else
				clearArrows()
			end
			autopilotTick(session, ply)
		end

		refreshUi(session, ply)
		task.wait(0.12)
	end
end)

cleanup(clearArrows)

print("[rocheese] ready - STYLE LEGIT/RAJ, DELAY min/max, AUTOPLAY; arrows: green best / blue second / yellow third")
