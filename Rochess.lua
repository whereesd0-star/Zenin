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
local function rankContinuations(startFen, moves, skipUci)
	local engine = buildEngine(startFen, moves)
	if not engine then
		return nil
	end
	local scored = {}
	for _, mv in engine:legalMoves() do
		local uci = engine:moveToUci(mv)
		if not skipUci or string.lower(uci) ~= string.lower(skipUci) then
			local child = buildEngine(startFen, moves)
			local ok = pcall(function()
				child:playUci(uci)
			end)
			if ok then
				local success, cres = pcall(Bot.analyse, child:getFen(), {}, CFG.CHILD_SECONDS, CFG.CHILD_DEPTH)
                if not success then cres = nil end
				table.insert(scored, {
					uci = uci,
					san = engine:moveToSan(mv),
					score = tonumber(cres and cres.score) or 0,
				})
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
	if not session or session.over then
		return false, "no game"
	end
	if not session:isMyTurn() then
		return false, "not your turn"
	end
	local from = Engine.algToIndex64(uci:sub(1, 2))
	local to = Engine.algToIndex64(uci:sub(3, 4))
	if not from or not to then
		return false, "bad uci"
	end
	local promo = CFG.PROMO[uci:sub(5, 5)] or 0
	local before = #session.ucis
	tapInput()
	local ok = false
	pcall(function()
		-- same call a square click makes: local apply + packed move to the server
		ok = App.onBoardMove(from, to, promo, nil)
	end)
	if not ok or #session.ucis == before then
		pcall(function()
			App.playMove(uci)
		end)
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
	if not RUNTIME.AUTO then
		return
	end
	if session.over or not session:isMyTurn() then
		return
	end
	if session.viewPly ~= ply or S.busy or not S.best then
		return
	end
	local now = os.clock()
	if now < S.thinkAt then
		return
	end
	local uci = pickMove(session)
	if type(uci) ~= "string" then
		return
	end
	task.spawn(function()
		if not alive() then
			return
		end
		if App.session == session and not session.over and session:isMyTurn() then
			playUci(uci)
		end
	end)
end

-- gui -------------------------------------------------------------------------------------

-- UI: ordinary Frames keep text colors independent of background styling.
local gui, panel, dot, lastEval
local rows, btns = {}, {}
local dragged = false
local toggleAuto, playNow, copyPosition, refreshButtons, syncDelay, applyPreset, startBotGame
local setVisible, applyTheme, layoutPanel
local C_BG = Color3.fromRGB(17, 21, 32)
local C_IDLE = Color3.fromRGB(35, 42, 60)
local C_ON = Color3.fromRGB(39, 107, 101)
local C_RAJ = Color3.fromRGB(113, 66, 99)
local C_TXT = Color3.fromRGB(240, 244, 255)
local C_DIM = Color3.fromRGB(161, 173, 195)
local C_ACC = Color3.fromRGB(126, 177, 255)
local themes = {
    Midnight = {bg=Color3.fromRGB(17,21,32), card=Color3.fromRGB(25,31,46), button=Color3.fromRGB(35,43,62), text=Color3.fromRGB(240,244,255), dim=Color3.fromRGB(163,177,200)},
    Graphite = {bg=Color3.fromRGB(24,24,27), card=Color3.fromRGB(33,33,38), button=Color3.fromRGB(47,47,54), text=Color3.fromRGB(248,248,250), dim=Color3.fromRGB(184,184,196)},
    Pearl = {bg=Color3.fromRGB(236,240,247), card=Color3.fromRGB(250,252,255), button=Color3.fromRGB(222,229,240), text=Color3.fromRGB(26,36,53), dim=Color3.fromRGB(77,92,116)},
}
local accents = {Blue=Color3.fromRGB(105,166,255), Mint=Color3.fromRGB(65,194,159), Violet=Color3.fromRGB(164,127,245), Rose=Color3.fromRGB(235,117,157)}
local themed, activeTweens = {}, setmetatable({}, {__mode="k"})
local pages, nav = {}, {}
local currentPage = "Overview"
local opening = false
local function animate(object, props, seconds)
    if activeTweens[object] then activeTweens[object]:Cancel() end
    local tween = TweenService:Create(object, TweenInfo.new(RUNTIME.ANIMATIONS and (seconds or 0.2) or 0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    activeTweens[object] = tween
    tween:Play()
    return tween
end
local function role(object, property, name)
    table.insert(themed, {object, property, name})
    return object
end
local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = object
end
local function frame(parent, x, y, w, h, colorRole)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.Position, f.Size = UDim2.fromOffset(x,y), UDim2.fromOffset(w,h)
    f.Parent = parent
    if colorRole then role(f,"BackgroundColor3",colorRole) else f.BackgroundTransparency = 1 end
    corner(f,12)
    return f
end
local function label(parent,x,y,w,h,text,size,colorRole)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Position, t.Size = UDim2.fromOffset(x,y), UDim2.fromOffset(w,h)
    t.Text, t.TextSize = text, size or 13
    t.Font = Enum.Font.GothamMedium
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = parent
    role(t,"TextColor3",colorRole or "text")
    return t
end
local function button(parent,x,y,w,text,callback)
    local b = Instance.new("TextButton")
    b.Position, b.Size = UDim2.fromOffset(x,y), UDim2.fromOffset(w,34)
    b.Text, b.TextSize, b.Font = text, 12, Enum.Font.GothamBold
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.AutoButtonColor, b.BorderSizePixel = false, 0
    b.Parent = parent
    corner(b,9)
    role(b,"BackgroundColor3","button")
    role(b,"TextColor3","text")
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Transparency = 1
    stroke.Parent = b
    role(stroke,"Color","accent")
    b.MouseEnter:Connect(function() animate(stroke,{Transparency=0.2},0.14) end)
    b.MouseLeave:Connect(function() animate(stroke,{Transparency=1},0.22) end)
    b.Activated:Connect(callback)
    return b
end
local function setBtn(b,on,text,onColor)
    if not b then return end
    b.Text = text
    local theme = themes[RUNTIME.THEME] or themes.Midnight
    animate(b,{BackgroundColor3=on and (onColor or C_ON) or theme.button})
    b.TextColor3 = on and Color3.fromRGB(255,255,255) or theme.text
end
local function page(name, subtitle)
    local p = frame(panel,160,76,456,344)
    p.Visible = false
    label(p,0,0,456,28,name,22)
    label(p,0,31,456,22,subtitle,11,"dim")
    pages[name] = p
    return p
end
local function showPage(name)
    currentPage = name
    for key,p in pairs(pages) do
        if activeTweens[p] then activeTweens[p]:Cancel() end
        p.Visible = key == name
        if p.Visible then
            p.Position = UDim2.fromOffset(170,76)
            animate(p,{Position=UDim2.fromOffset(160,76)},0.24)
        end
    end
    for key,b in pairs(nav) do setBtn(b,key==name,b.Text) end
end
local function buildGui()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("RoCheesePanel")
    if old then old:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "RoCheesePanel", false, true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    panel = frame(gui,30,80,640,480,"bg")
    panel.Name, panel.Active = "Panel", true
    panel.ClipsDescendants = true
    corner(panel,18)
    local scale = Instance.new("UIScale")
    scale.Name, scale.Parent = "ResponsiveScale", panel
    local outline = Instance.new("UIStroke")
    outline.Transparency, outline.Parent = 0.55, panel
    role(outline,"Color","accent")
    -- No UIGradient on a CanvasGroup: it tinted every descendant in the old UI.
    local rail = frame(panel,0,0,140,480,"card")
    label(rail,18,18,108,28,"RO / CHESS",15,"accent")
    label(rail,18,44,108,18,"ENGINE STUDIO",9,"dim")
    for i,name in ipairs({"Overview","Engine","Automation","Appearance","Configs"}) do
        nav[name] = button(rail,10,88+(i-1)*44,120,name,function() showPage(name) end)
    end
    label(rail,18,408,110,18,"AURORA / 03",10,"accent")
    label(rail,18,430,110,30,"Luau • 4:3",11,"dim")
    rows.title = label(panel,160,20,370,26,"ROCHESS ENGINE",15)
    rows.title.Active = true
    dot = frame(panel,548,28,8,8,"accent")
    corner(dot,8)
    button(panel,574,16,42,"×",function() setVisible(false) end)
    rows.status = label(panel,160,442,455,20,"Ready",11,"dim")
    local overview = page("Overview","Position, evaluation and quick actions")
    local evaluation = frame(overview,0,68,456,132,"card")
    label(evaluation,16,10,420,16,"LIVE POSITION",10,"accent")
    rows.eval = label(evaluation,16,34,420,30,"EVAL —",20)
    rows.best = label(evaluation,16,72,420,24,"1 —",15)
    rows.rest = label(evaluation,16,100,420,22,"",12,"dim")
    rows.game = label(overview,0,210,456,24,"No game",11,"dim")
    btns.play = button(overview,0,246,222,"PLAY NOW",function() playNow() end)
    btns.copy = button(overview,234,246,222,"COPY FEN",function() copyPosition() end)
    btns.botgame = button(overview,0,290,222,"BOT GAME / PRACTICE",function() startBotGame() end)
    btns.arrows = button(overview,234,290,222,"ARROWS",function()
        RUNTIME.SHOW_ARROW = not RUNTIME.SHOW_ARROW
        clearArrows(); refreshButtons()
    end)
    local engine = page("Engine","Presets, search source and move selection")
    label(engine,0,66,456,20,"PLAY STYLE",10,"accent")
    btns.legit = button(engine,0,92,222,"LEGIT",function() applyPreset("legit") end)
    btns.raj = button(engine,234,92,222,"RAJ",function() applyPreset("raj") end)
    label(engine,0,138,456,20,"ENGINE SOURCE",10,"accent")
    btns.engineLocal = button(engine,0,164,222,"LOCAL",function() RUNTIME.SOURCE="local"; RUNTIME.STYLE="custom"; S.ply=-1; refreshButtons() end)
    btns.engineVortex = button(engine,234,164,222,"VORTEX",function() RUNTIME.SOURCE="vortex"; RUNTIME.STYLE="custom"; S.ply=-1; refreshButtons() end)
    label(engine,0,210,456,20,"MOVE SELECTION",10,"accent")
    btns.best = button(engine,0,236,222,"BEST",function() RUNTIME.MODE="best"; RUNTIME.STYLE="custom"; refreshButtons() end)
    btns.elo = button(engine,234,236,222,"ELO",function() RUNTIME.MODE="elo"; RUNTIME.STYLE="custom"; refreshButtons() end)
    local rating = label(engine,54,288,160,34,"",13)
    button(engine,0,288,42,"−",function() RUNTIME.ELO=math.max(100,RUNTIME.ELO-100); RUNTIME.STYLE="custom"; refreshButtons() end)
    button(engine,222,288,42,"+",function() RUNTIME.ELO=math.min(3200,RUNTIME.ELO+100); RUNTIME.STYLE="custom"; refreshButtons() end)
    rows.rating = rating
    local automation = page("Automation","Autoplay timing and input options")
    btns.auto = button(automation,0,70,456,"AUTOPLAY",function() toggleAuto() end)
    local delayValues = {}
    for i,key in ipairs({"DELAY_MIN","DELAY_MAX"}) do
        local y=128+(i-1)*56
        label(automation,0,y,170,34,i==1 and "Minimum delay" or "Maximum delay",13)
        button(automation,196,y,42,"−",function()
            if key=="DELAY_MIN" then RUNTIME[key]=math.max(0,RUNTIME[key]-0.5)
            else RUNTIME[key]=math.max(RUNTIME.DELAY_MIN+0.5,RUNTIME[key]-0.5) end
            RUNTIME.STYLE="custom"; syncDelay(); refreshButtons()
        end)
        delayValues[key]=label(automation,254,y,118,34,"",14)
        button(automation,414,y,42,"+",function()
            if key=="DELAY_MIN" then RUNTIME[key]=math.min(RUNTIME.DELAY_MAX-0.5,RUNTIME[key]+0.5)
            else RUNTIME[key]=math.min(20,RUNTIME[key]+0.5) end
            RUNTIME.STYLE="custom"; syncDelay(); refreshButtons()
        end)
    end
    syncDelay = function()
        for key,l in pairs(delayValues) do l.Text=string.format("%.1f sec",RUNTIME[key]) end
    end
    btns.humanize=button(automation,0,250,456,"HUMANIZE",function() RUNTIME.HUMANIZE=not RUNTIME.HUMANIZE; refreshButtons() end)
    label(automation,0,302,456,26,"End: autoplay  /  Home: arrows  /  +: panel",11,"dim")
    local appearance=page("Appearance","Personalize the panel; save your look in a config")
    label(appearance,0,66,456,20,"COLOR THEME",10,"accent")
    for i,name in ipairs({"Midnight","Graphite","Pearl"}) do
        button(appearance,(i-1)*156,94,144,name,function() RUNTIME.THEME=name; applyTheme() end)
    end
    label(appearance,0,142,456,20,"ACCENT COLOR",10,"accent")
    for i,name in ipairs({"Blue","Mint","Violet","Rose"}) do
        button(appearance,(i-1)*117,170,105,name,function() RUNTIME.ACCENT=name; applyTheme() end)
    end
    btns.animations=button(appearance,0,226,456,"ANIMATIONS",function() RUNTIME.ANIMATIONS=not RUNTIME.ANIMATIONS; refreshButtons() end)
    label(appearance,0,282,456,48,"640 × 480 • scales to your screen\nDrag the header to move the panel",12,"dim").TextWrapped=true
    local configs=page("Configs","Select, create, rename and save named configurations")
    local list = Instance.new("ScrollingFrame")
    list.Position, list.Size = UDim2.fromOffset(0,68), UDim2.fromOffset(210,236)
    list.BackgroundTransparency, list.BorderSizePixel = 1, 0
    list.ScrollBarThickness = 3
    list.CanvasSize = UDim2.fromOffset(0,0)
    list.Parent = configs
    local input = Instance.new("TextBox")
    input.Position,input.Size=UDim2.fromOffset(226,68),UDim2.fromOffset(230,34)
    input.PlaceholderText="Config name…"
    input.Text=""
    input.ClearTextOnFocus=false
    input.TextSize,input.Font=12,Enum.Font.GothamMedium
    input.BorderSizePixel=0
    input.Parent=configs
    corner(input,8)
    role(input,"BackgroundColor3","button"); role(input,"TextColor3","text"); role(input,"PlaceholderColor3","dim")
    local notice=label(configs,0,312,456,30,configNotice,11,"dim")
    local selected=tostring(store.active)
    local profileButtons={}
    local rebuild
    local function cleanName()
        local name=input.Text:match("^%s*(.-)%s*$")
        if #name==0 or #name>48 or name:find("[%c]") then notice.Text="Use a name of 1–48 bytes"; return nil end
        for id,n in pairs(store.names) do
            if id~=selected and n==name then notice.Text="That name already exists"; return nil end
        end
        return name
    end
    rebuild=function()
        for _,b in ipairs(profileButtons) do b:Destroy() end
        profileButtons={}
        local ids={}
        for id in pairs(store.profiles) do table.insert(ids,id) end
        table.sort(ids,function(a,b) return (store.names[a] or a)<(store.names[b] or b) end)
        for i,id in ipairs(ids) do
            local b=button(list,0,(i-1)*42,200,store.names[id] or ("Profile "..id),function()
                selected=id; input.Text=store.names[id] or ("Profile "..id)
                notice.Text="Selected: "..input.Text.." — press LOAD"
                rebuild()
            end)
            -- The dynamic list is recolored directly; discard obsolete theme records.
            for _=1,3 do table.remove(themed) end
            setBtn(b,id==selected,b.Text)
            table.insert(profileButtons,b)
        end
        list.CanvasSize=UDim2.fromOffset(0,#ids*42)
    end
    button(configs,226,114,110,"CREATE",function()
        local name=cleanName(); if not name then return end
        for _,n in pairs(store.names) do if n==name then notice.Text="That name already exists"; return end end
        local id=HttpService:GenerateGUID(false)
        store.profiles[id],store.names[id]=validated(RUNTIME),name
        selected,store.active=id,id
        notice.Text=persistProfiles(); rebuild()
    end)
    button(configs,346,114,110,"RENAME",function()
        if not store.profiles[selected] then notice.Text="Select a config first"; return end
        local name=cleanName(); if not name then return end
        store.names[selected]=name; notice.Text=persistProfiles(); rebuild()
    end)
    button(configs,226,158,110,"SAVE",function()
        if not store.profiles[selected] then notice.Text="Create or select a config first"; return end
        store.profiles[selected],store.active=validated(RUNTIME),selected
        notice.Text=persistProfiles(); rebuild()
    end)
    button(configs,346,158,110,"LOAD",function()
        if not store.profiles[selected] then notice.Text="Select a config first"; return end
        applyConfig(store.profiles[selected]); store.active=selected
        S.ply=-1; clearArrows(); syncDelay(); applyTheme()
        notice.Text="Loaded: "..(store.names[selected] or selected).." / "..persistProfiles()
        rebuild()
    end)
    local pendingDelete
    button(configs,226,202,230,"DELETE SELECTED",function()
        if not store.profiles[selected] then notice.Text="Select a config first"; return end
        if pendingDelete~=selected then
            pendingDelete=selected; notice.Text="Press DELETE again to confirm"
            task.delay(3,function() pendingDelete=nil end); return
        end
        store.profiles[selected],store.names[selected]=nil,nil
        pendingDelete=nil
        if tostring(store.active)==selected then store.active="" end
        selected=""; input.Text=""; notice.Text=persistProfiles(); rebuild()
    end)
    button(configs,226,246,230,"RESET CURRENT SETTINGS",function()
        applyConfig(DEFAULTS); S.ply=-1; clearArrows(); syncDelay(); applyTheme()
        notice.Text="Defaults applied; saved configs unchanged"; rebuild()
    end)
    applyTheme=function()
        local t=themes[RUNTIME.THEME] or themes.Midnight
        t.accent=accents[RUNTIME.ACCENT] or accents.Blue
        C_ACC,C_TXT,C_DIM,C_BG,C_IDLE=t.accent,t.text,t.dim,t.bg,t.button
        for _,item in ipairs(themed) do
            if item[1].Parent then item[1][item[2]]=t[item[3]] end
        end
        refreshButtons(); showPage(currentPage); rebuild()
    end
    local reopen=button(gui,16,80,44,"+",function() setVisible(true) end)
    reopen.BackgroundColor3=C_BG; reopen.TextColor3=C_ACC
    local visibilityToken=0
    local restingPosition
    setVisible=function(value)
        visibilityToken+=1
        local token=visibilityToken
        RUNTIME.UI_VISIBLE=value
        if activeTweens[panel] then activeTweens[panel]:Cancel() end
        if opening and restingPosition then panel.Position=restingPosition end
        opening=false
        layoutPanel()
        local target=panel.Position
        restingPosition=target
        reopen.Visible=not value
        if value then
            panel.Visible=true
            panel.Position=target+UDim2.fromOffset(0,12)
            opening=true
            animate(panel,{Position=target},0.24)
        else
            opening=true
            animate(panel,{Position=target+UDim2.fromOffset(0,12)},0.18)
        end
        task.delay(0.25,function()
            if alive() and token==visibilityToken then panel.Visible=value; panel.Position=target; opening=false end
        end)
    end
    local dragging,dragInput,dragStart,origin=false,nil,nil,nil
    rows.title.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType==Enum.UserInputType.MouseButton1 or inputObject.UserInputType==Enum.UserInputType.Touch then
            if activeTweens[panel] then activeTweens[panel]:Cancel() end
            opening=false; visibilityToken+=1
            dragging=true; dragInput=inputObject; dragged=true
            dragStart=inputObject.Position; origin=panel.Position
        end
    end)
    connect(UserInputService.InputChanged,function(inputObject)
        if not dragging then return end
        if inputObject.UserInputType==Enum.UserInputType.MouseMovement or inputObject==dragInput then
            local delta=inputObject.Position-dragStart
            panel.Position=origin+UDim2.fromOffset(delta.X,delta.Y)
            layoutPanel()
        end
    end)
    connect(UserInputService.InputEnded,function(inputObject)
        if inputObject==dragInput or inputObject.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    syncDelay(); applyTheme(); setVisible(RUNTIME.UI_VISIBLE~=false)
    cleanup(function() if gui then gui:Destroy(); gui=nil; panel=nil end end)
end
refreshButtons=function()
    if not btns.auto then return end
    setBtn(btns.auto,RUNTIME.AUTO,RUNTIME.AUTO and "AUTOPLAY / ON" or "AUTOPLAY / OFF")
    setBtn(btns.legit,RUNTIME.STYLE=="legit","LEGIT / HUMAN",C_ON)
    setBtn(btns.raj,RUNTIME.STYLE=="raj","RAJ / FAST",C_RAJ)
    setBtn(btns.best,RUNTIME.MODE=="best","BEST MOVE")
    setBtn(btns.elo,RUNTIME.MODE=="elo","ELO / "..RUNTIME.ELO)
    setBtn(btns.engineLocal,RUNTIME.SOURCE=="local","LOCAL")
    setBtn(btns.engineVortex,RUNTIME.SOURCE=="vortex","VORTEX")
    setBtn(btns.arrows,RUNTIME.SHOW_ARROW,RUNTIME.SHOW_ARROW and "ARROWS / ON" or "ARROWS / OFF")
    setBtn(btns.humanize,RUNTIME.HUMANIZE,RUNTIME.HUMANIZE and "HUMANIZE INPUT / ON" or "HUMANIZE INPUT / OFF")
    setBtn(btns.animations,RUNTIME.ANIMATIONS,RUNTIME.ANIMATIONS and "ANIMATIONS / ON" or "ANIMATIONS / OFF")
    rows.rating.Text="Rating: "..RUNTIME.ELO
end
layoutPanel=function()
    if not panel or not panel.Parent or opening then return end
    local cam=workspace.CurrentCamera
    local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
    local scale=math.max(0.1,math.min(1,(vp.X-24)/640,(vp.Y-24)/480))
    panel.ResponsiveScale.Scale=scale
    local width,height=640*scale,480*scale
    local x=dragged and panel.Position.X.Offset or vp.X-width-24
    local y=dragged and panel.Position.Y.Offset or (vp.Y-height)/2
    panel.Position=UDim2.fromOffset(math.clamp(x,0,math.max(0,vp.X-width)),math.clamp(y,0,math.max(0,vp.Y-height)))
end
local function shiftPanel(dx,dy)
    if not panel then return end
    dragged=true
    panel.Position=panel.Position+UDim2.fromOffset(dx,dy)
    layoutPanel()
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
	if not session then
		S.status = "no game running"
		return
	end
	if S.busy or not S.best then
		S.status = "engine still thinking"
		return
	end
	local uci = pickMove(session)
	if type(uci) ~= "string" then
		S.status = "no move available"
		return
	end
	local ok, err = playUci(uci)
	S.status = ok and ("played " .. tostring(err)) or tostring(err)
end

copyPosition = function()
	local session = App.session
	if not session then
		S.status = "no game running"
		return
	end
	local fen = session.engine:getFen()
	local sans = table.concat(session.sans, " ")
	pcall(setclipboard, fen .. "\n" .. sans)
	S.status = "fen + moves copied"
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
        if setVisible then setVisible(not (RUNTIME.UI_VISIBLE ~= false)) end
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

buildGui()
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

		if session and sid ~= S.sessionId then
			S.sessionId = sid
            S.ply = -1
			lastEval = nil
			pcall(function()
				Bot.clearTT()
			end)
		end

		if session and ply ~= S.ply then
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

				task.spawn(function()
					-- main search: the best move and the eval
					local res = analyseBest(startFen, moves)
					if not alive() then
						return
					end
					S.busy = false
					local live = App.session
					if live ~= session or not live or #live.ucis ~= wantPly then
						S.ply = -1
						return
					end
					if type(res) ~= "table" then
						S.status = "engine failed"
						return
					end
					S.best = res.best
					S.score = tonumber(res.score) or 0
					S.depth = tonumber(res.depth) or 0
					S.status = "engine ready"
					local engine = buildEngine(startFen, moves)
					S.san = sanOf(engine, res.best)

					-- second pass: rank the continuations for the 2nd and 3rd arrows
					task.spawn(function()
						local ranked = rankContinuations(startFen, moves, res.best)
						if not alive() then
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
