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
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
GENV.__RoCheeseGen = (GENV.__RoCheeseGen or 0) + 1
local GEN = GENV.__RoCheeseGen

local CFG = {
	W = 640,
	H = 480,
	MARGIN = 14,
	TOP = 84,
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
GENV.__RoCheeseDispose = function()
    if disposed then return end
    disposed = true
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, fn in ipairs(disposers) do pcall(fn) end
end

-- Versioned profiles: validate untrusted JSON before applying any values.
local DEFAULTS = { THEME = "Midnight", ACCENT = "Blue", ANIMATIONS = true }
DEFAULTS.AUTO = false
DEFAULTS.SOURCE, DEFAULTS.MODE, DEFAULTS.STYLE = "local", "elo", "legit"
DEFAULTS.ELO, DEFAULTS.NOISE, DEFAULTS.BLUNDER = 1500, 0.32, 0.06
DEFAULTS.DELAY_MIN, DEFAULTS.DELAY_MAX = 5, 10
DEFAULTS.SHOW_ARROW, DEFAULTS.HUMANIZE = true, true
local CONFIG_PATH = "rocheese_profiles_v2.json"
local store = GENV.__RoCheeseProfiles or { version = 2, active = 1, profiles = {} }
local configNotice = "Profiles: session memory"
if type(readfile) == "function" then
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_PATH)) end)
    if ok and type(data) == "table" and data.version == 2 and type(data.profiles) == "table" then
        store = data
        configNotice = "Profiles restored from disk"
    end
end
store.active = tostring(store.active or "1")
store.names = type(store.names) == "table" and store.names or {}
for id, profile in pairs(store.profiles) do
    if type(id) ~= "string" or type(profile) ~= "table" then
        store.profiles[id] = nil
    elseif type(store.names[id]) ~= "string" then
        store.names[id] = "Profile " .. id
    end
end
GENV.__RoCheeseProfiles = store
local function validated(data)
    local result = table.clone(DEFAULTS)
    if type(data) ~= "table" then return result end
    for key, default in pairs(DEFAULTS) do
        local value = data[key]
        if type(value) == type(default) then
            if type(value) ~= "number" or (value == value and math.abs(value) < math.huge) then
                result[key] = value
            end
        end
    end
    result.SOURCE = result.SOURCE == "vortex" and "vortex" or "local"
    result.MODE = result.MODE == "best" and "best" or "elo"
    result.STYLE = (result.STYLE == "legit" or result.STYLE == "raj") and result.STYLE or "custom"
    result.ELO = math.clamp(result.ELO, 100, 3200)
    result.NOISE = math.clamp(result.NOISE, 0, 1)
    result.BLUNDER = math.clamp(result.BLUNDER, 0, 1)
    result.DELAY_MIN = math.clamp(result.DELAY_MIN, 0, 19.5)
    result.DELAY_MAX = math.clamp(result.DELAY_MAX, result.DELAY_MIN + 0.5, 20)
    if result.THEME ~= "Midnight" and result.THEME ~= "Graphite" and result.THEME ~= "Pearl" then result.THEME = "Midnight" end
    if result.ACCENT ~= "Blue" and result.ACCENT ~= "Mint" and result.ACCENT ~= "Violet" and result.ACCENT ~= "Rose" then result.ACCENT = "Blue" end
    return result
end
local function applyConfig(data)
    for key, value in pairs(validated(data)) do RUNTIME[key] = value end
end
applyConfig(store.profiles[tostring(store.active)] or RUNTIME)
local function persistProfiles()
    if type(writefile) ~= "function" then return "Saved in session (no writefile)" end
    local ok = pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(store)) end)
    return ok and "Saved to disk" or "Disk write failed; saved in session"
end

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

-- gui -------------------------------------------------------------------------------------

local gui, panel, dot, lastEval
local rows, btns = {}, {}
local toggleAuto, playNow, copyPosition, refreshButtons, syncDelay, applyPreset, startBotGame
local setVisible, applyTheme, layoutPanel
local C_ACC = Color3.fromRGB(105, 166, 255)
local accents = {
    Blue = Color3.fromRGB(105, 166, 255),
    Mint = Color3.fromRGB(65, 194, 159),
    Violet = Color3.fromRGB(164, 127, 245),
    Rose = Color3.fromRGB(235, 117, 157),
}
local themeNames = {"Midnight", "Graphite", "Pearl"}
local accentNames = {"Blue", "Mint", "Violet", "Rose"}
local ZENIN_URL = "https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"

local function loadZenin()
    if type(loadstring) ~= "function" then return nil, "loadstring is unavailable" end
    local ok, result = pcall(function()
        local source = game:HttpGet(ZENIN_URL)
        if type(source) ~= "string" or source == "" then error("download returned an empty response", 0) end
        local chunk, compileError = loadstring(source)
        if type(chunk) ~= "function" then error("library compilation failed: " .. tostring(compileError), 0) end
        return chunk()
    end)
    if not ok then return nil, tostring(result) end
    if type(result) ~= "table" or type(result.CreateWindow) ~= "function" then
        return nil, "download did not return a ZeninLib library"
    end
    return result
end

local Library, libraryError = loadZenin()
if not Library then
    warn("[rocheese] ZeninLib could not be loaded from " .. ZENIN_URL .. ": " .. tostring(libraryError))
end

local function addTheme(name, tokens)
    if Library and type(Library.AddTheme) == "function" then
        pcall(function() Library:AddTheme(name, tokens) end)
    end
end

addTheme("Midnight", {
    WindowBg = Color3.fromRGB(17, 21, 32), CardBg = Color3.fromRGB(25, 31, 46),
    TileBg = Color3.fromRGB(35, 43, 62), DropdownBg = Color3.fromRGB(25, 31, 46),
    PopupBg = Color3.fromRGB(25, 31, 46), SliderTrack = Color3.fromRGB(35, 43, 62),
    ToggleOffBg = Color3.fromRGB(35, 43, 62), Text = Color3.fromRGB(240, 244, 255),
    ValueOff = Color3.fromRGB(163, 177, 200), ScrollTrack = Color3.fromRGB(25, 31, 46),
    WmBg = Color3.fromRGB(25, 31, 46),
})
addTheme("Graphite", {
    WindowBg = Color3.fromRGB(24, 24, 27), CardBg = Color3.fromRGB(33, 33, 38),
    TileBg = Color3.fromRGB(47, 47, 54), DropdownBg = Color3.fromRGB(33, 33, 38),
    PopupBg = Color3.fromRGB(33, 33, 38), SliderTrack = Color3.fromRGB(47, 47, 54),
    ToggleOffBg = Color3.fromRGB(47, 47, 54), Text = Color3.fromRGB(248, 248, 250),
    ValueOff = Color3.fromRGB(184, 184, 196), ScrollTrack = Color3.fromRGB(33, 33, 38),
    WmBg = Color3.fromRGB(33, 33, 38),
})
addTheme("Pearl", {
    WindowBg = Color3.fromRGB(236, 240, 247), CardBg = Color3.fromRGB(250, 252, 255),
    TileBg = Color3.fromRGB(222, 229, 240), DropdownBg = Color3.fromRGB(250, 252, 255),
    PopupBg = Color3.fromRGB(250, 252, 255), SliderTrack = Color3.fromRGB(222, 229, 240),
    ToggleOffBg = Color3.fromRGB(222, 229, 240), Text = Color3.fromRGB(26, 36, 53),
    ValueOff = Color3.fromRGB(77, 92, 116), ScrollTrack = Color3.fromRGB(222, 229, 240),
    WmBg = Color3.fromRGB(250, 252, 255),
})

local uiWindow, controls = nil, {}
local profilePicker, profileNamePicker, profileNotice
local profileSelection, profileIds = tostring(store.active), {}
local userScale, appliedScale = 1, nil

local function elementSet(element, value)
    if element and type(element.Set) == "function" then
        pcall(function() element:Set(value, true) end)
    end
end

local function elementName(element, value)
    if element and type(element.SetName) == "function" then
        pcall(function() element:SetName(value) end)
    end
end

local function addReadout(section, key, text)
    local element = section:AddButton({Name = text, Callback = function() end})
    rows[key] = setmetatable({}, {
        __index = function(_, field) if field == "Text" then return text end end,
        __newindex = function(_, field, value)
            if field == "Text" then
                local nextText = tostring(value)
                if nextText ~= text then
                    text = nextText
                    elementName(element, text)
                end
            end
        end,
    })
    return rows[key]
end

local function setProfileNotice(text)
    if profileNotice then profileNotice.Text = tostring(text) end
end

local function refreshProfileOptions()
    if not profilePicker then return end
    local ids, options, byLabel, labels = {}, {}, {}, {}
    for id in pairs(store.profiles) do
        if type(id) == "string" then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b)
        local an = tostring(store.names[a] or ("Profile " .. a))
        local bn = tostring(store.names[b] or ("Profile " .. b))
        return an == bn and a < b or an < bn
    end)
    for _, id in ipairs(ids) do
        local label = tostring(store.names[id] or ("Profile " .. id)) .. " [" .. id:sub(1, 8) .. "]"
        table.insert(options, label)
        byLabel[label], labels[id] = id, label
    end
    profileIds = byLabel
    profilePicker:SetOptions(options, true)
    if labels[profileSelection] then
        profilePicker:Set(labels[profileSelection], true)
    elseif labels[tostring(store.active)] then
        profileSelection = tostring(store.active)
        profilePicker:Set(labels[profileSelection], true)
    elseif ids[1] then
        profileSelection = ids[1]
        profilePicker:Set(labels[profileSelection], true)
    else
        profileSelection = nil
    end

    local nameOptions, taken = {}, {}
    for id, name in pairs(store.names) do
        if id ~= profileSelection then taken[name] = true end
    end
    if profileSelection and store.names[profileSelection] then
        table.insert(nameOptions, store.names[profileSelection])
    end
    for i = 1, 50 do
        local name = "Profile " .. i
        if not taken[name] then table.insert(nameOptions, name) end
    end
    profileNamePicker:SetOptions(nameOptions, true)
    if nameOptions[1] then profileNamePicker:Set(nameOptions[1], true) end
    if #ids == 0 then
        setProfileNotice(configNotice .. " / no profiles yet")
    elseif not store.profiles[profileSelection] then
        setProfileNotice("Choose a profile or create one")
    end
end

local function buildGui()
    if not Library then return false end
    local ok, err = pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        uiWindow = Library:CreateWindow({
            Title = "RoCheese", Logo = "R", GuiName = "RoCheesePanel", Parent = playerGui,
            Theme = RUNTIME.THEME, Accent = accents[RUNTIME.ACCENT] or accents.Blue,
            Configs = false, MouseWheel = true,
            Watermark = {Title = "RoCheese", Site = "ZeninLib", Detail = "Chess analysis"},
        })
        if type(uiWindow) ~= "table" or type(uiWindow.AddTab) ~= "function" then
            error("ZeninLib CreateWindow returned an invalid window", 0)
        end
        gui = playerGui:FindFirstChild("RoCheesePanel")
        if not gui then error("ZeninLib did not create its ScreenGui", 0) end
        panel = gui:FindFirstChild("Window")
        if not panel then error("ZeninLib did not create its window frame", 0) end

        local overview = uiWindow:AddTab({Name = "Overview"})
        local summary = overview:AddSection({Name = "Live status", Side = "Left"})
        rows.title = addReadout(summary, "title", "ROCHEESE / CHESS ENGINE")
        rows.eval = addReadout(summary, "eval", "Evaluation: —")
        rows.best = addReadout(summary, "best", "Best move: —")
        rows.status = addReadout(summary, "status", "Status: starting")
        rows.game = addReadout(summary, "game", "Game: no game")
        rows.rest = addReadout(summary, "rest", "Moves: —")
        rows.rating = addReadout(summary, "rating", "Rating: " .. tostring(RUNTIME.ELO))
        local actions = overview:AddSection({Name = "Actions", Side = "Right"})
        btns.play = actions:AddButton({Name = "PLAY BEST NOW", Callback = function() if playNow then playNow() end end})
        btns.copy = actions:AddButton({Name = "COPY POSITION + MOVES", Callback = function() if copyPosition then copyPosition() end end})
        btns.botgame = actions:AddButton({Name = "BOT GAME / PRACTICE", Callback = function() if startBotGame then startBotGame() end end})
        btns.arrows = actions:AddButton({Name = "ARROWS", Callback = function()
            RUNTIME.SHOW_ARROW = not RUNTIME.SHOW_ARROW
            if not RUNTIME.SHOW_ARROW then clearArrows() end
            refreshButtons()
        end})
        btns.auto = actions:AddButton({Name = "AUTOPLAY", Callback = function() if toggleAuto then toggleAuto() end end})
        actions:AddButton({Name = "TOGGLE MENU", Callback = function() if uiWindow then setVisible(not uiWindow:IsVisible()) end end})

        local engine = uiWindow:AddTab({Name = "Engine"})
        local presets = engine:AddSection({Name = "Presets", Side = "Left"})
        btns.legit = presets:AddButton({Name = "LEGIT / HUMAN", Callback = function() if applyPreset then applyPreset("legit") end end})
        btns.raj = presets:AddButton({Name = "RAJ / FAST", Callback = function() if applyPreset then applyPreset("raj") end end})
        local engineSettings = engine:AddSection({Name = "Engine settings", Side = "Right"})
        controls.source = engineSettings:AddDropdown({Name = "Analysis source", Options = {"local", "vortex"}, Default = RUNTIME.SOURCE, Callback = function(value)
            RUNTIME.SOURCE, RUNTIME.STYLE, S.ply = value, "custom", -1
            refreshButtons()
        end})
        controls.mode = engineSettings:AddDropdown({Name = "Move selection", Options = {"elo", "best"}, Default = RUNTIME.MODE, Callback = function(value)
            RUNTIME.MODE, RUNTIME.STYLE = value, "custom"
            refreshButtons()
        end})
        controls.elo = engineSettings:AddSlider({Name = "Target ELO", Min = 100, Max = 3200, Step = 100, Default = RUNTIME.ELO, Callback = function(value)
            RUNTIME.ELO, RUNTIME.STYLE = math.clamp(value, 100, 3200), "custom"
            refreshButtons()
        end})
        controls.noise = engineSettings:AddSlider({Name = "Move noise", Min = 0, Max = 1, Step = 0.01, Decimals = 2, Default = RUNTIME.NOISE, Callback = function(value)
            RUNTIME.NOISE, RUNTIME.STYLE = math.clamp(value, 0, 1), "custom"
            refreshButtons()
        end})
        controls.blunder = engineSettings:AddSlider({Name = "Blunder chance", Min = 0, Max = 1, Step = 0.01, Decimals = 2, Default = RUNTIME.BLUNDER, Callback = function(value)
            RUNTIME.BLUNDER, RUNTIME.STYLE = math.clamp(value, 0, 1), "custom"
            refreshButtons()
        end})

        local automation = uiWindow:AddTab({Name = "Automation"})
        local timing = automation:AddSection({Name = "Move timing", Side = "Left"})
        controls.delayMin = timing:AddSlider({Name = "Minimum delay", Min = CFG.DELAY_MIN, Max = CFG.DELAY_MAX, Step = CFG.DELAY_STEP, Decimals = 1, Suffix = " s", Default = RUNTIME.DELAY_MIN, Callback = function(value)
            RUNTIME.DELAY_MIN = math.min(19.5, math.floor(value / CFG.DELAY_STEP + 0.5) * CFG.DELAY_STEP)
            if RUNTIME.DELAY_MAX - RUNTIME.DELAY_MIN < CFG.DELAY_STEP then RUNTIME.DELAY_MAX = RUNTIME.DELAY_MIN + CFG.DELAY_STEP end
            RUNTIME.STYLE = "custom"
            syncDelay(); refreshButtons()
        end})
        controls.delayMax = timing:AddSlider({Name = "Maximum delay", Min = CFG.DELAY_MIN, Max = CFG.DELAY_MAX, Step = CFG.DELAY_STEP, Decimals = 1, Suffix = " s", Default = RUNTIME.DELAY_MAX, Callback = function(value)
            RUNTIME.DELAY_MAX = math.clamp(math.floor(value / CFG.DELAY_STEP + 0.5) * CFG.DELAY_STEP, CFG.DELAY_STEP, CFG.DELAY_MAX)
            if RUNTIME.DELAY_MAX - RUNTIME.DELAY_MIN < CFG.DELAY_STEP then RUNTIME.DELAY_MIN = math.max(0, RUNTIME.DELAY_MAX - CFG.DELAY_STEP) end
            RUNTIME.STYLE = "custom"
            syncDelay(); refreshButtons()
        end})
        syncDelay = function()
            elementSet(controls.delayMin, RUNTIME.DELAY_MIN)
            elementSet(controls.delayMax, RUNTIME.DELAY_MAX)
        end
        btns.humanize = timing:AddToggle({Name = "Humanize input", Default = RUNTIME.HUMANIZE, Callback = function(value)
            RUNTIME.HUMANIZE = value == true
            refreshButtons()
        end})
        btns.autoToggle = timing:AddToggle({Name = "Autoplay", Default = RUNTIME.AUTO, Callback = function(value)
            if (value == true) ~= RUNTIME.AUTO and toggleAuto then toggleAuto() end
        end})
        btns.arrowToggle = timing:AddToggle({Name = "Show move arrows", Default = RUNTIME.SHOW_ARROW, Callback = function(value)
            RUNTIME.SHOW_ARROW = value == true
            if not RUNTIME.SHOW_ARROW then clearArrows() end
            refreshButtons()
        end})

        local appearance = uiWindow:AddTab({Name = "Appearance"})
        local display = appearance:AddSection({Name = "Display", Side = "Left"})
        controls.theme = display:AddDropdown({Name = "Theme", Options = themeNames, Default = RUNTIME.THEME, Callback = function(value)
            RUNTIME.THEME, RUNTIME.STYLE = value, "custom"
            applyTheme()
        end})
        controls.accent = display:AddDropdown({Name = "Accent", Options = accentNames, Default = RUNTIME.ACCENT, Callback = function(value)
            RUNTIME.ACCENT, RUNTIME.STYLE = value, "custom"
            applyTheme()
        end})
        btns.animations = display:AddToggle({Name = "Animate scaling", Default = RUNTIME.ANIMATIONS, Callback = function(value)
            RUNTIME.ANIMATIONS = value == true
            refreshButtons()
        end})
        controls.scale = display:AddSlider({Name = "Window scale", Min = 0.5, Max = 1.25, Step = 0.05, Decimals = 2, Default = 1, Callback = function(value)
            userScale = value
            layoutPanel()
        end})
        local shortcuts = appearance:AddSection({Name = "Keyboard shortcuts", Side = "Right"})
        shortcuts:AddButton({Name = "END — toggle autoplay", Callback = function() if toggleAuto then toggleAuto() end end})
        shortcuts:AddButton({Name = "HOME — toggle arrows", Callback = function()
            RUNTIME.SHOW_ARROW = not RUNTIME.SHOW_ARROW
            if not RUNTIME.SHOW_ARROW then clearArrows() end
            refreshButtons()
        end})
        shortcuts:AddButton({Name = "PAGE UP / + — menu", Callback = function() if uiWindow then setVisible(not uiWindow:IsVisible()) end end})
        shortcuts:AddButton({Name = "PAGE DOWN — source", Callback = function()
            RUNTIME.SOURCE = RUNTIME.SOURCE == "local" and "vortex" or "local"
            RUNTIME.STYLE, S.ply = "custom", -1
            refreshButtons()
        end})
        shortcuts:AddButton({Name = "INSERT — copy position", Callback = function() if copyPosition then copyPosition() end end})

        local profiles = uiWindow:AddTab({Name = "Profiles"})
        local profileSection = profiles:AddSection({Name = "Saved profiles", Side = "Left"})
        profilePicker = profileSection:AddDropdown({Name = "Select profile", Options = {}, AllowNone = true, Placeholder = "No profiles", Callback = function(label)
            profileSelection = profileIds[label]
            if profileSelection then
                setProfileNotice("Selected " .. tostring(store.names[profileSelection] or profileSelection) .. " — choose an action")
                refreshProfileOptions()
            end
        end})
        profileNamePicker = profileSection:AddDropdown({Name = "Rename as", Options = {}, AllowNone = true, Placeholder = "Choose a profile name"})
        controls.profileStatus = profileSection:AddButton({Name = "Profiles: " .. configNotice, Callback = function() end})
        profileNotice = setmetatable({}, {
            __newindex = function(_, field, value)
                if field == "Text" then elementName(controls.profileStatus, "Profiles: " .. tostring(value)) end
            end,
        })
        profileSection:AddButton({Name = "CREATE PROFILE", Callback = function()
            local used = {}
            for _, name in pairs(store.names) do used[name] = true end
            local name
            for i = 1, 50 do
                local candidate = "Profile " .. i
                if not used[candidate] then name = candidate; break end
            end
            local idOk, id = pcall(function() return HttpService:GenerateGUID(false) end)
            if not idOk then id = tostring(os.clock()) .. "-" .. tostring(math.random(100000, 999999)) end
            id = tostring(id)
            if not name then
                name = "Profile " .. id:sub(1, 8)
                local suffix = 2
                while used[name] do
                    name = "Profile " .. id:sub(1, 8) .. " (" .. suffix .. ")"
                    suffix = suffix + 1
                end
            end
            store.profiles[id], store.names[id] = validated(RUNTIME), name
            profileSelection, store.active = id, id
            setProfileNotice(persistProfiles())
            refreshProfileOptions()
        end})
        profileSection:AddButton({Name = "RENAME SELECTED", Callback = function()
            if not profileSelection or not store.profiles[profileSelection] then setProfileNotice("Select a profile first"); return end
            local name = profileNamePicker:Get()
            if type(name) ~= "string" or name == "" then setProfileNotice("Choose a profile name"); return end
            for id, existing in pairs(store.names) do
                if id ~= profileSelection and existing == name then setProfileNotice("That profile name is already in use"); return end
            end
            store.names[profileSelection] = name
            setProfileNotice(persistProfiles())
            refreshProfileOptions()
        end})
        profileSection:AddButton({Name = "SAVE CURRENT SETTINGS", Callback = function()
            if not profileSelection or not store.profiles[profileSelection] then setProfileNotice("Create or select a profile first"); return end
            store.profiles[profileSelection], store.active = validated(RUNTIME), profileSelection
            setProfileNotice(persistProfiles())
            refreshProfileOptions()
        end})
        profileSection:AddButton({Name = "LOAD SELECTED", Callback = function()
            if not profileSelection or not store.profiles[profileSelection] then setProfileNotice("Select a profile first"); return end
            applyConfig(store.profiles[profileSelection])
            store.active = profileSelection
            S.ply = -1
            clearArrows()
            syncDelay()
            applyTheme()
            refreshButtons()
            setProfileNotice("Loaded " .. tostring(store.names[profileSelection] or profileSelection) .. " / " .. persistProfiles())
        end})
        local pendingDelete
        profileSection:AddButton({Name = "DELETE SELECTED (confirm twice)", Callback = function()
            if not profileSelection or not store.profiles[profileSelection] then setProfileNotice("Select a profile first"); return end
            if pendingDelete ~= profileSelection then
                pendingDelete = profileSelection
                setProfileNotice("Press DELETE again within 3 seconds to confirm")
                task.delay(3, function() pendingDelete = nil end)
                return
            end
            store.profiles[profileSelection], store.names[profileSelection] = nil, nil
            if tostring(store.active) == profileSelection then store.active = "" end
            pendingDelete, profileSelection = nil, nil
            setProfileNotice(persistProfiles())
            refreshProfileOptions()
        end})
        profileSection:AddButton({Name = "RESET CURRENT SETTINGS", Callback = function()
            applyConfig(DEFAULTS)
            S.ply = -1
            clearArrows()
            syncDelay()
            applyTheme()
            refreshButtons()
            setProfileNotice("Defaults applied; saved profiles were not changed")
        end})

        refreshProfileOptions()
        syncDelay()
        applyTheme()
        layoutPanel()
        setVisible(RUNTIME.UI_VISIBLE ~= false)
        uiWindow:OnUnload(function()
            gui, panel = nil, nil
            GENV.__RoCheeseDispose()
        end)
        local createdWindow = uiWindow
        cleanup(function()
            if createdWindow then pcall(function() createdWindow:Destroy() end) end
            if uiWindow == createdWindow then uiWindow = nil end
            gui, panel = nil, nil
        end)
        local camera = workspace.CurrentCamera
        if camera then connect(camera:GetPropertyChangedSignal("ViewportSize"), layoutPanel) end
    end)
    if not ok then
        warn("[rocheese] ZeninLib GUI initialization failed: " .. tostring(err))
        if uiWindow then pcall(function() uiWindow:Destroy() end) end
        uiWindow, gui, panel = nil, nil, nil
        return false
    end
    return true
end

refreshButtons = function()
    if not uiWindow then return end
    elementName(btns.auto, RUNTIME.AUTO and "AUTOPLAY / ON" or "AUTOPLAY / OFF")
    elementName(btns.legit, RUNTIME.STYLE == "legit" and "✓ LEGIT / HUMAN" or "LEGIT / HUMAN")
    elementName(btns.raj, RUNTIME.STYLE == "raj" and "✓ RAJ / FAST" or "RAJ / FAST")
    elementName(btns.arrows, RUNTIME.SHOW_ARROW and "ARROWS / ON" or "ARROWS / OFF")
    elementSet(btns.autoToggle, RUNTIME.AUTO)
    elementSet(btns.arrowToggle, RUNTIME.SHOW_ARROW)
    elementSet(btns.humanize, RUNTIME.HUMANIZE)
    elementSet(btns.animations, RUNTIME.ANIMATIONS)
    elementSet(controls.source, RUNTIME.SOURCE)
    elementSet(controls.mode, RUNTIME.MODE)
    elementSet(controls.elo, RUNTIME.ELO)
    elementSet(controls.noise, RUNTIME.NOISE)
    elementSet(controls.blunder, RUNTIME.BLUNDER)
    elementSet(controls.theme, RUNTIME.THEME)
    elementSet(controls.accent, RUNTIME.ACCENT)
    if rows.rating then rows.rating.Text = "Rating: " .. tostring(RUNTIME.ELO) end
end

layoutPanel = function()
    if not panel or not panel.Parent or not uiWindow then return end
    RUNTIME.UI_VISIBLE = uiWindow:IsVisible()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local fit = math.clamp(math.min((viewport.X - 24) / 480, (viewport.Y - 24) / 338), 0.3, 1.25)
    local scale = math.min(userScale, fit)
    if appliedScale ~= scale then
        uiWindow:SetScale(scale, RUNTIME.ANIMATIONS)
        appliedScale = scale
    end
end

local function shiftPanel(dx, dy)
    if not panel then return end
    panel.Position = panel.Position + UDim2.fromOffset(dx, dy)
    layoutPanel()
end

applyTheme = function()
    if not uiWindow then return end
    C_ACC = accents[RUNTIME.ACCENT] or accents.Blue
    uiWindow:SetTheme(RUNTIME.THEME)
    uiWindow:SetAccent(C_ACC)
    elementSet(controls.theme, RUNTIME.THEME)
    elementSet(controls.accent, RUNTIME.ACCENT)
    refreshButtons()
end

setVisible = function(value)
    RUNTIME.UI_VISIBLE = value == true
    if uiWindow then uiWindow:SetVisible(RUNTIME.UI_VISIBLE) end
end

-- actions ---------------------------------------------------------------------------------

toggleAuto = function()
	RUNTIME.AUTO = not RUNTIME.AUTO
	S.thinkAt = os.clock() + (RUNTIME.AUTO and humanDelay() or 0)
	S.status = RUNTIME.AUTO and "autopilot on" or "autopilot off"
	refreshButtons()
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
	if syncDelay then
		syncDelay()
	end
	refreshButtons()
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
	if syncDelay then
		syncDelay()
	end
	refreshButtons()
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
		RUNTIME.SHOW_ARROW = not RUNTIME.SHOW_ARROW
		if not RUNTIME.SHOW_ARROW then
			clearArrows()
		end
		refreshButtons()
	elseif code == Enum.KeyCode.PageUp or code == Enum.KeyCode.Equals or code == Enum.KeyCode.KeypadPlus then
        if setVisible then setVisible(uiWindow and not uiWindow:IsVisible() or false) end
	elseif code == Enum.KeyCode.PageDown then
		RUNTIME.SOURCE = RUNTIME.SOURCE == "local" and "vortex" or "local"
		RUNTIME.STYLE = "custom"
		S.ply = -1
		refreshButtons()
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

-- panel refresh ---------------------------------------------------------------------------

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

local function refreshPanel(session, ply)
	if not panel or not panel.Parent then
		return
	end

	rows.title.Text = "ROCHESS ENGINE"
	rows.status.Text = S.status
	rows.eval.Text = session
		and (S.busy and "EVAL ...      DEPTH ..." or string.format("EVAL %s      DEPTH %d", evalText(S.score), S.depth))
		or "EVAL -      DEPTH 0"
	if S.busy then
		rows.best.Text = "1 thinking..."
		rows.rest.Text = ""
	else
		rows.best.Text = S.best and string.format("1  %s   (%s)", S.san or "?", S.best) or "1  -"
		local parts = {}
		if S.second then
			table.insert(parts, string.format("2  %s", S.secondSan or S.second))
		end
		if S.third then
			table.insert(parts, string.format("3  %s", S.thirdSan or S.third))
		end
		rows.rest.Text = table.concat(parts, "     ")
	end
	local myClock, oppClock = "-", "-"
	if session and session.clocks and session.myColor then
		myClock = formatClock(session.clocks[session.myColor])
		oppClock = formatClock(session.clocks[-session.myColor])
	end
	rows.game.Text = session
		and string.format("%s | ply %d | clock %s/%s",
			session.myColor == 1 and (session.white and session.white.display or "white")
				or (session.black and session.black.display or "black"),
			ply,
			myClock,
			oppClock)
		or "no game"

	if session and session.kind == "idle" then
		rows.status.Text = "no game running - press BOT GAME or Play in the game"
	end

	if dot then
		if S.busy then
			dot.BackgroundColor3 = C_ACC
		elseif S.best then
			dot.BackgroundColor3 = CFG.ARROW_1
		else
			dot.BackgroundColor3 = Color3.fromRGB(200, 80, 70)
		end
	end

	pushEval()
end

-- main loop -------------------------------------------------------------------------------

if not buildGui() then
    GENV.__RoCheeseDispose()
    return
end
refreshButtons()
S.status = "ready / + to toggle"

GENV.__RoCheese.api = {
	auto = toggleAuto,
	play = playNow,
	copy = copyPosition,
	move = shiftPanel,
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
		if gui and gui.Parent ~= LocalPlayer:FindFirstChild("PlayerGui") then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then pcall(function() gui.Parent = playerGui end) end
        end
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

		refreshPanel(session, ply)
		layoutPanel()
		task.wait(0.12)
	end
end)

cleanup(clearArrows)

print("[rocheese] ready - STYLE LEGIT/RAJ, DELAY min/max, AUTOPLAY; arrows: green best / blue second / yellow third")
