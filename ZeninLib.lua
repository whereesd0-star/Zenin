local Library = {}

function Library.new(opts)
	opts = opts or {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ZeninInternalUI") then
	PlayerGui.ZeninInternalUI:Destroy()
end

local CONFIG = {
	IconsUrl = "https://raw.githubusercontent.com/whereesd0-star/Icons/refs/heads/main/Icons.lua%20(3).txt",
	CacheFile = "zenin_lucide_icons.lua",
	TelegramLink = "",
	ToggleKey = Enum.KeyCode.RightShift,
}

-- ============================================================================
-- 1. LUCIDE ИКОНКИ
-- ============================================================================
local Icons
do
	local function Parse(src)
		if type(src) ~= "string" or #src < 200 then return nil end
		local fn = loadstring(src)
		if not fn then return nil end
		local ok, res = pcall(fn)
		if ok and type(res) == "table" and type(res["48px"]) == "table" then return res end
		return nil
	end
	local function Download(url)
		local ok, res = pcall(function() return game:HttpGet(url) end)
		if ok and type(res) == "string" and #res > 200 then return res end
		local req = (syn and syn.request) or (http and http.request) or http_request or request
		if req then
			local ok2, r = pcall(req, {Url = url, Method = "GET"})
			if ok2 and type(r) == "table" and type(r.Body) == "string" then return r.Body end
		end
		return nil
	end
	local cached
	if isfile and readfile then
		local ok, data = pcall(function()
			if isfile(CONFIG.CacheFile) then return readfile(CONFIG.CacheFile) end
		end)
		if ok then cached = data end
	end
	Icons = Parse(cached)
	if not Icons then
		local src = Download(CONFIG.IconsUrl)
		Icons = Parse(src)
		if Icons and writefile then pcall(writefile, CONFIG.CacheFile, src) end
	end
end

local function ResolveIcon(name)
	if not Icons then return nil end
	for _, sheet in ipairs({"48px", "256px"}) do
		local s = Icons[sheet]
		local e = s and s[name]
		if e then return e end
	end
	return nil
end

local function ApplyIcon(img, names)
	for _, name in ipairs(names) do
		local e = ResolveIcon(name)
		if e then
			img.Image = "rbxassetid://" .. tostring(e[1])
			img.ImageRectSize = Vector2.new(e[2][1], e[2][2])
			img.ImageRectOffset = Vector2.new(e[3][1], e[3][2])
			return true
		end
	end
	return false
end

-- ============================================================================
-- 2. ТЕМА + АКЦЕНТ (цвет и альфа)
-- ============================================================================
local Theme = {
	WindowBg = Color3.fromRGB(14, 14, 14),
	BarBg = Color3.fromRGB(18, 18, 18),
	BarLine = Color3.fromRGB(22, 22, 22),
	CardBg = Color3.fromRGB(18, 18, 18),
	BoxBg = Color3.fromRGB(22, 22, 22),
	BoxBorder = Color3.fromRGB(26, 26, 26),
	TileBg = Color3.fromRGB(22, 22, 22),
	DropdownBg = Color3.fromRGB(22, 22, 22),
	DropdownBorder = Color3.fromRGB(42, 42, 42),
	PopupBg = Color3.fromRGB(14, 14, 14),
	SliderTrack = Color3.fromRGB(22, 22, 22),
	ToggleOffBg = Color3.fromRGB(22, 22, 22),
	ToggleOffDot = Color3.fromRGB(44, 44, 44),
	TextWhite = Color3.fromRGB(255, 255, 255),
	TextGray = Color3.fromRGB(160, 160, 168),
	TextDim = Color3.fromRGB(88, 88, 96),
	NavGray = Color3.fromRGB(180, 180, 188),
	Accent = Color3.fromRGB(255, 89, 89),
	AccentAlpha = 1,
}

local TEXT = 11

local AccentListeners = {}
local function BindAccent(fn)
	table.insert(AccentListeners, fn)
	fn(Theme.Accent, Theme.AccentAlpha)
end
local function SetAccent(col, alpha)
	Theme.Accent = col
	if alpha then Theme.AccentAlpha = alpha end
	for _, fn in ipairs(AccentListeners) do
		pcall(fn, col, Theme.AccentAlpha)
	end
end

-- ============================================================================
-- 3. УТИЛИТЫ
-- ============================================================================
local WEIGHTS = {
	Regular = Enum.FontWeight.Regular,
	Medium = Enum.FontWeight.Medium,
	SemiBold = Enum.FontWeight.SemiBold,
	Bold = Enum.FontWeight.Bold,
}
local FontCache = {}
local function ApplyFont(obj, weight)
	local ok = pcall(function()
		local f = FontCache[weight]
		if not f then
			f = Font.new("rbxasset://fonts/families/Roboto.json", WEIGHTS[weight] or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			FontCache[weight] = f
		end
		obj.FontFace = f
	end)
	if not ok then
		obj.Font = (weight == "Bold" or weight == "SemiBold") and Enum.Font.GothamBold or Enum.Font.GothamMedium
	end
end

local function Create(class, props)
	local obj = Instance.new(class)
	local parent
	for k, v in pairs(props) do
		if k == "Parent" then
			parent = v
		elseif k == "Weight" then
			ApplyFont(obj, v)
		else
			obj[k] = v
		end
	end
	if parent then obj.Parent = parent end
	return obj
end

local function Corner(parent, r)
	return Create("UICorner", {CornerRadius = UDim.new(0, r), Parent = parent})
end

local function Stroke(parent, color, thickness, trans)
	return Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = trans or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Label(parent, text, o)
	o = o or {}
	return Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = o.Size or UDim2.new(1, 0, 1, 0),
		Position = o.Position or UDim2.new(),
		Text = text,
		TextColor3 = o.Color or Theme.TextGray,
		TextSize = o.TextSize or TEXT,
		Weight = o.Weight or "Medium",
		TextXAlignment = o.Align or Enum.TextXAlignment.Left,
		AutomaticSize = o.AutoX and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
		Parent = parent,
	})
end

local function CreateIcon(parent, names, size, pos, color)
	local img = Create("ImageLabel", {
		Size = UDim2.fromOffset(size, size),
		Position = pos or UDim2.new(0, 0, 0.5, -size / 2),
		BackgroundTransparency = 1,
		ImageColor3 = color or Theme.TextGray,
		ScaleType = Enum.ScaleType.Stretch,
		Parent = parent,
	})
	ApplyIcon(img, names)
	return img
end

local function IsClickOrTouch(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function IsMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

-- Умное перетаскивание:
--  * порог 4px: простой клик по шапке не сдвигает окно, клики по кнопкам внутри шапки вообще не начинают драг
--  * плавное следование за курсором (экспоненциальное сглаживание, не зависит от FPS)
--  * окно нельзя утащить за экран: шапка всегда остаётся достижимой (MARGIN px), перекламп при смене размера экрана
--  * двойной клик по шапке возвращает окно на место (с анимацией)
--  * корректно работает с тачем и мышью, отслеживает именно тот палец/кнопку, что начали драг
--  * при удалении GUI все соединения отключаются (нет утечек при повторном запуске скрипта)
local function MakeDraggable(handle, target, opts)
	opts = opts or {}
	local MARGIN, THRESH, SMOOTH, DOUBLE = opts.Margin or 56, 4, 30, 0.3
	local home = target.Position
	local conns = {}
	local drag = {input = nil, started = false}
	local startMouse, startPos, startAbs = Vector2.new(), target.Position, Vector2.new()
	local goal, cur = Vector2.new(), Vector2.new()
	local stepConn, homeTween
	local lastClick = 0

	local function ScreenSize()
		local gui = target:FindFirstAncestorWhichIsA("ScreenGui")
		return gui and gui.AbsoluteSize or Vector2.new(1920, 1080)
	end
	local function ClampAbs(abs)
		local screen, size = ScreenSize(), target.AbsoluteSize
		return Vector2.new(
			math.clamp(abs.X, MARGIN - size.X, screen.X - MARGIN),
			math.clamp(abs.Y, 0, screen.Y - MARGIN)
		)
	end
	local function Apply(d)
		target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
	local function StopStep()
		if stepConn then stepConn:Disconnect() stepConn = nil end
	end
	local function StartStep()
		if stepConn then return end
		stepConn = RunService.RenderStepped:Connect(function(dt)
			cur = cur:Lerp(goal, 1 - math.exp(-dt * SMOOTH))
			if (goal - cur).Magnitude < 0.25 then cur = goal end
			Apply(cur)
			if cur == goal and not drag.input then StopStep() end
		end)
	end
	local function OverButton(pos)
		for _, d in ipairs(handle:GetDescendants()) do
			if d:IsA("GuiButton") and d.Visible then
				local p, sz = d.AbsolutePosition, d.AbsoluteSize
				if pos.X >= p.X and pos.X <= p.X + sz.X and pos.Y >= p.Y and pos.Y <= p.Y + sz.Y then
					return true
				end
			end
		end
		return false
	end
	local function GoHome()
		StopStep()
		if homeTween then homeTween:Cancel() end
		homeTween = TweenService:Create(target, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = home})
		homeTween:Play()
	end

	table.insert(conns, handle.InputBegan:Connect(function(input)
		if not IsClickOrTouch(input) or drag.input then return end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		if OverButton(pos) then return end
		if homeTween then homeTween:Cancel() homeTween = nil end
		drag.input, drag.started = input, false
		startMouse, startPos, startAbs = pos, target.Position, target.AbsolutePosition
		cur, goal = Vector2.new(), Vector2.new()
	end))

	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not drag.input then return end
		local isTouch = drag.input.UserInputType == Enum.UserInputType.Touch
		if isTouch then
			if input ~= drag.input then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - startMouse
		if not drag.started then
			if delta.Magnitude < THRESH then return end
			drag.started = true
		end
		goal = ClampAbs(startAbs + delta) - startAbs
		StartStep()
	end))

	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		local d = drag.input
		if not d then return end
		local isTouch = d.UserInputType == Enum.UserInputType.Touch
		local same = isTouch and (input == d) or ((not isTouch) and input.UserInputType == d.UserInputType)
		if not same then return end
		local wasDrag = drag.started
		drag.input, drag.started = nil, false
		if not wasDrag then
			local now = os.clock()
			if now - lastClick < DOUBLE then
				lastClick = 0
				GoHome()
			else
				lastClick = now
			end
		end
	end))

	-- перекламп при изменении размера экрана
	local gui = target:FindFirstAncestorWhichIsA("ScreenGui")
	if gui then
		table.insert(conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if drag.input then return end
			local abs = target.AbsolutePosition
			local diff = ClampAbs(abs) - abs
			if diff.Magnitude > 0.5 then
				local p = target.Position
				target.Position = UDim2.new(p.X.Scale, p.X.Offset + diff.X, p.Y.Scale, p.Y.Offset + diff.Y)
			end
		end))
	end

	handle.Destroying:Connect(function()
		StopStep()
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)
	end)
end

local function CreateZLogo(parent, size)
	local box = Create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent})
	local function bar(sz, ps, rot)
		return Create("Frame", {Size = sz, Position = ps, Rotation = rot or 0, BorderSizePixel = 0, Parent = box})
	end
	local t = bar(UDim2.new(0.84, 0, 0.19, 0), UDim2.new(0.08, 0, 0.08, 0))
	local d = bar(UDim2.new(1.04, 0, 0.19, 0), UDim2.new(-0.02, 0, 0.405, 0), -39)
	local b = bar(UDim2.new(0.84, 0, 0.19, 0), UDim2.new(0.08, 0, 0.73, 0))
	local parts = {t, d, b}
	BindAccent(function(c)
		for _, p in ipairs(parts) do p.BackgroundColor3 = c end
	end)
	return box, parts
end

-- ---- Шахматка (в оригинале квадратная, без скруглений) ----
local CHECK_LIGHT, CHECK_DARK = Color3.fromRGB(206, 206, 206), Color3.fromRGB(132, 132, 132)
-- w и h должны быть кратны sq
local function Checker(parent, x, y, w, h, sq)
	local base = Create("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = CHECK_LIGHT,
		BorderSizePixel = 0,
		Parent = parent,
	})
	for row = 0, h / sq - 1 do
		for col = 0, w / sq - 1 do
			if (row + col) % 2 == 1 then
				Create("Frame", {
					Size = UDim2.fromOffset(sq, sq),
					Position = UDim2.fromOffset(col * sq, row * sq),
					BackgroundColor3 = CHECK_DARK,
					BorderSizePixel = 0,
					Parent = base,
				})
			end
		end
	end
	return base
end

-- ============================================================================
-- 4. SCREEN GUI + WATERMARK
-- ============================================================================
local ScreenGui = Create("ScreenGui", {
	Name = "ZeninInternalUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = PlayerGui,
})

local WM_Fade = {}
local function Fade(obj, prop, base)
	table.insert(WM_Fade, {obj, prop, base})
end
local WM_Opacity = 1
local function SetWatermarkOpacity(a)
	WM_Opacity = a
	for _, e in ipairs(WM_Fade) do
		pcall(function() e[1][e[2]] = 1 - (1 - e[3]) * a end)
	end
end

local Watermark = Create("Frame", {
	Name = "Watermark",
	Size = UDim2.new(0, 0, 0, 26),
	AutomaticSize = Enum.AutomaticSize.X,
	Position = UDim2.fromOffset(8, 8),
	BackgroundColor3 = Color3.fromRGB(14, 14, 14),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Active = true,
	Parent = ScreenGui,
})
Fade(Watermark, "BackgroundTransparency", 0.1)
local WM_Corner = Corner(Watermark, 13)
local WM_Stroke = Stroke(Watermark, Color3.fromRGB(38, 38, 43), 1, 0.15)
Fade(WM_Stroke, "Transparency", 0.15)
MakeDraggable(Watermark, Watermark)

Create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = Watermark,
})
Create("UIPadding", {PaddingLeft = UDim.new(0, 11.5), PaddingRight = UDim.new(0, 15.5), Parent = Watermark})

local wmOrder = 0
local function nx() wmOrder = wmOrder + 1 return wmOrder end

local function WMSpacer(w)
	Create("Frame", {Size = UDim2.fromOffset(w, 1), BackgroundTransparency = 1, LayoutOrder = nx(), Parent = Watermark})
end
local function WMDivider()
	local d = Create("Frame", {
		Size = UDim2.fromOffset(1, 14),
		BackgroundColor3 = Color3.fromRGB(42, 42, 47),
		BorderSizePixel = 0,
		LayoutOrder = nx(),
		Parent = Watermark,
	})
	Fade(d, "BackgroundTransparency", 0)
end

local WM_IconGroups = {}
local function WMItem(names, tint, text)
	local grp = Create("Frame", {Size = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, LayoutOrder = nx(), Parent = Watermark})
	local ic = CreateIcon(grp, names, 12, UDim2.fromOffset(0, 0), tint)
	Fade(ic, "ImageTransparency", 0)
	table.insert(WM_IconGroups, grp)
	local lbl = Label(Watermark, text, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = Theme.TextWhite})
	lbl.LayoutOrder = nx()
	Fade(lbl, "TextTransparency", 0)
	return ic, lbl
end

local WM = {specs = {}, byId = {}, logoCfg = nil, header = nil, logo = nil}

local function MakeLogo(parent, size, cfg, fade)
	local holder = Create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent})
	local function track(obj, prop)
		if fade ~= false then Fade(obj, prop, 0) end
	end
	if type(cfg) == "table" and cfg.Image ~= nil then
		local img = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = type(cfg.Image) == "number" and ("rbxassetid://" .. cfg.Image) or tostring(cfg.Image),
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		})
		if cfg.Tint == "accent" then BindAccent(function(c) img.ImageColor3 = c end) end
		track(img, "ImageTransparency")
	elseif type(cfg) == "table" and cfg.Letter ~= nil then
		local letter = Create("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = string.sub(tostring(cfg.Letter), 1, 2),
			Font = Enum.Font.GothamBold,
			TextSize = math.floor(size * (cfg.Scale or 1.15)),
			TextColor3 = Theme.Accent,
			Parent = holder,
		})
		BindAccent(function(c) letter.TextColor3 = c end)
		track(letter, "TextTransparency")
	else
		local _, parts = CreateZLogo(holder, size)
		for _, part in ipairs(parts) do track(part, "BackgroundTransparency") end
	end
	return holder
end

local function MakeIcon(parent, spec, size, tint)
	if type(spec) == "table" then
		return CreateIcon(parent, spec, size, UDim2.fromOffset(0, 0), tint)
	end
	return Create("ImageLabel", {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Image = type(spec) == "number" and ("rbxassetid://" .. spec) or tostring(spec),
		ImageColor3 = tint,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
end

local function ClearWatermark()
	for _, child in ipairs(Watermark:GetChildren()) do
		if not (child:IsA("UICorner") or child:IsA("UIStroke") or child:IsA("UIListLayout")) then
			child:Destroy()
		end
	end
	table.clear(WM_IconGroups)
	table.clear(WM.byId)
	for i = #WM_Fade, 1, -1 do
		local ok, alive = pcall(function() return WM_Fade[i][1]:IsDescendantOf(ScreenGui) end)
		if not ok or not alive then table.remove(WM_Fade, i) end
	end
end

local function BuildWatermark(specs)
	ClearWatermark()
	WM.specs = specs
	for _, spec in ipairs(specs) do
		local kind = spec.Type or "Item"
		if kind == "Logo" then
			local logo = MakeLogo(Watermark, 10, WM.logoCfg, true)
			logo.LayoutOrder = nx()
			WM.logo = logo
		elseif kind == "Spacer" then
			WMSpacer(spec.Width or 8)
		elseif kind == "Divider" then
			WMDivider()
		elseif kind == "Item" then
			local accent = spec.Color == "accent"
			local tint = typeof(spec.Color) == "Color3" and spec.Color or Theme.TextGray
			local entry = {spec = spec}
			if spec.Icon ~= nil and spec.Icon ~= false then
				local grp = Create("Frame", {Size = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, LayoutOrder = nx(), Parent = Watermark})
				local ic = MakeIcon(grp, spec.Icon, 12, accent and Theme.Accent or tint)
				Fade(ic, "ImageTransparency", 0)
				if accent then BindAccent(function(c) ic.ImageColor3 = c end) end
				table.insert(WM_IconGroups, grp)
				entry.group, entry.icon = grp, ic
			end
			if spec.Text ~= nil then
				local lbl = Label(Watermark, tostring(spec.Text), {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = Theme.TextWhite})
				lbl.LayoutOrder = nx()
				Fade(lbl, "TextTransparency", 0)
				entry.label = lbl
			end
			if spec.Id ~= nil then WM.byId[tostring(spec.Id)] = entry end
		end
	end
	SetWatermarkOpacity(WM_Opacity)
end

local function NormalizeWatermark(list)
	local specs = {}
	for index, item in ipairs(list or {}) do
		if type(item) == "string" then
			specs[#specs + 1] = {Id = "text" .. index, Text = item}
		elseif type(item) == "table" then
			local copy = {}
			for key, value in pairs(item) do copy[key] = value end
			specs[#specs + 1] = copy
		end
	end
	return specs
end

local function DefaultWatermark(labels)
	labels = labels or {}
	return {
		{Type = "Logo"},
		{Type = "Spacer", Width = 10.5},
		{Type = "Divider"},
		{Type = "Spacer", Width = 3.7},
		{Id = "tag", Icon = {"tag"}, Color = "accent", Text = labels[1] or "zenin"},
		{Type = "Spacer", Width = 13},
		{Id = "globe", Icon = {"globe"}, Color = Color3.fromRGB(104, 122, 232), Text = labels[2] or "zenin.cc"},
		{Type = "Spacer", Width = 8.5},
		{Type = "Divider"},
		{Type = "Spacer", Width = 3.5},
		{Id = "detail", Icon = {"monitor"}, Color = Color3.fromRGB(205, 205, 210), Text = labels[3] or "internal"},
	}
end

WM.logoCfg = opts.Logo
local wmOpt = opts.Watermark
if type(wmOpt) == "table" and type(wmOpt[1]) == "table" then
	BuildWatermark(NormalizeWatermark(wmOpt))
else
	BuildWatermark(DefaultWatermark(type(wmOpt) == "table" and wmOpt or nil))
end

-- ============================================================================
-- 5. ОКНО: HEADER / BODY / BOTTOM (480 x 338)
-- ============================================================================
-- Слои внутри MainWin (ZIndexBehavior = Sibling):
--   2  страницы   4  Fader (анимация вкладок)   7-8 полоса прокрутки
--   6  BottomFade        10 BottomBar  30 PopupLayer (35 сам попап)
local WIN_W, WIN_H = 480, 338
local HEADER_H, BOTTOM_H = 36, 35
local BODY_H = WIN_H - HEADER_H - BOTTOM_H

local WindowHolder = Create("Frame", {
	Name = "WindowHolder",
	Size = UDim2.fromOffset(WIN_W, WIN_H),
	Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundTransparency = 1,
	Parent = ScreenGui,
})
local WindowScale = Create("UIScale", {Scale = 1, Parent = WindowHolder})

local MainWin = Create("Frame", {
	Name = "MainWin",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Theme.WindowBg,
	BorderSizePixel = 0,
	Active = true,
	Parent = WindowHolder,
})
Corner(MainWin, 8)

-- Header: свои скруглённые углы сверху + заливка снизу, чтобы острых углов не торчало
local Header = Create("Frame", {
	Size = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = Color3.new(1, 1, 1), -- цвет задаёт UIGradient ниже
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 8,
	Parent = MainWin,
})
Corner(Header, 8)
local HeaderFill = Create("Frame", {
	Size = UDim2.new(1, 0, 0, HEADER_H / 2),
	Position = UDim2.new(0, 0, 0, HEADER_H / 2),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	Parent = Header,
})
-- Градиент шапки как в оригинале: слева (под логотипом Z) шапка подкрашена акцентом (~7%),
-- и это плавно гаснет к ~16% ширины. Один и тот же градиент на шапке и на её нижней заливке,
-- поэтому скруглённые верхние углы и квадратный низ совпадают.
local HeaderGradients = {
	Create("UIGradient", {Parent = Header}),
	Create("UIGradient", {Parent = HeaderFill}),
}
BindAccent(function(c, alpha)
	local tint = Theme.BarBg:Lerp(c, 0.07 * (alpha or 1))
	local seq = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tint),
		ColorSequenceKeypoint.new(0.16, Theme.BarBg),
		ColorSequenceKeypoint.new(1, Theme.BarBg),
	})
	for _, g in ipairs(HeaderGradients) do g.Color = seq end
end)
Create("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = Theme.BarLine,
	BorderSizePixel = 0,
	Parent = Header,
})
MakeDraggable(Header, WindowHolder)

local hLogo = MakeLogo(Header, 10, opts.Logo, false)
hLogo.Position = UDim2.fromOffset(10, 13)
WM.header = hLogo

Label(Header, "Zenin Internal", {
	Position = UDim2.fromOffset(26, 0),
	Size = UDim2.new(0, 150, 1, 0),
	Color = Theme.TextWhite,
	Weight = "SemiBold",
})

Create("Frame", {
	Size = UDim2.fromOffset(1, 15),
	Position = UDim2.fromOffset(409, 10.5),
	BackgroundColor3 = Color3.fromRGB(34, 34, 38),
	BorderSizePixel = 0,
	Parent = Header,
})

local DocBtn = Create("TextButton", {
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.fromOffset(414, 6),
	BackgroundTransparency = 1,
	Text = "",
	Parent = Header,
})
CreateIcon(DocBtn, {"file-text"}, 12, UDim2.new(0.5, -6, 0.5, -6), Theme.NavGray)

local SetBtn = Create("TextButton", {
	Size = UDim2.fromOffset(26, 27),
	Position = UDim2.fromOffset(444.5, 4.5),
	BackgroundColor3 = Theme.TileBg,
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Parent = Header,
})
Corner(SetBtn, 5)
local GearIcon = CreateIcon(SetBtn, {"settings", "cog"}, 12, UDim2.new(0.5, -6, 0.5, -6), Theme.NavGray)

-- контейнер под-вкладок (прижат вправо к x=395)
local SubHolder = Create("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(0, 395, 0.5, 0),
	Size = UDim2.new(0, 0, 0, 26),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = Header,
})
Create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 5),
	Parent = SubHolder,
})

-- Bottom bar
local BottomBar = Create("Frame", {
	Size = UDim2.new(1, 0, 0, BOTTOM_H),
	Position = UDim2.new(0, 0, 1, -BOTTOM_H),
	BackgroundColor3 = Theme.BarBg,
	BorderSizePixel = 0,
	ZIndex = 10,
	Parent = MainWin,
})
Corner(BottomBar, 8)
Create("Frame", {
	Size = UDim2.new(1, 0, 0, BOTTOM_H / 2),
	BackgroundColor3 = Theme.BarBg,
	BorderSizePixel = 0,
	Parent = BottomBar,
})
Create("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = Theme.BarLine,
	BorderSizePixel = 0,
	Parent = BottomBar,
})

-- затухание контента над нижним баром
local BottomFade = Create("Frame", {
	Size = UDim2.new(1, 0, 0, 41),
	Position = UDim2.fromOffset(0, HEADER_H + BODY_H - 41),
	BackgroundColor3 = Theme.WindowBg,
	BorderSizePixel = 0,
	ZIndex = 6,
	Parent = MainWin,
})
Create("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.85, 0.08),
		NumberSequenceKeypoint.new(1, 0),
	}),
	Parent = BottomFade,
})

-- Fader: перекрывает тело окна и плавно гаснет при смене вкладки
local Fader = Create("Frame", {
	Size = UDim2.new(1, 0, 0, BODY_H),
	Position = UDim2.fromOffset(0, HEADER_H),
	BackgroundColor3 = Theme.WindowBg,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Active = false,
	ZIndex = 4,
	Parent = MainWin,
})

-- слой попапов
local PopupLayer = Create("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 30,
	Parent = MainWin,
})
local ActivePopup = nil
local PopupConns = {}

local Pages = {}
-- Прокрутка контента возможна ТОЛЬКО через полосу справа (как в оригинале),
-- поэтому ScrollingEnabled у страниц всегда false. Функция оставлена для совместимости.
local function SetScrollLock(lock) end

local function ClosePopup()
	for _, c in ipairs(PopupConns) do c:Disconnect() end
	table.clear(PopupConns)
	if ActivePopup then
		ActivePopup:Destroy()
		ActivePopup = nil
	end
	PopupLayer.Visible = false
	SetScrollLock(false)
end

local ClickOutside = Create("TextButton", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "",
	ZIndex = 30,
	Parent = PopupLayer,
})
ClickOutside.MouseButton1Click:Connect(ClosePopup)

-- ============================================================================
-- 6. СТРАНИЦЫ, СКРОЛЛ (своя квадратная полоса, как в оригинале), КОЛОНКИ, КАРТОЧКИ
-- ============================================================================
local BarW = 6
local BAR_RIGHT = WIN_W - 8 -- правый край полосы (x = 472), как в оригинале
local TRK_TOP, TRK_BOT = 9, 10 -- отступы дорожки от шапки и от нижнего бара
local TRK_LEN = BODY_H - TRK_TOP - TRK_BOT
local TRACK_COL = Color3.fromRGB(18, 18, 18)
local THUMB_COL = Color3.fromRGB(22, 22, 22)
local THUMB_HOVER = Color3.fromRGB(30, 30, 30)
local THUMB_DRAG = Color3.fromRGB(40, 40, 40)

local function NewPage(key)
	local scroll = Create("ScrollingFrame", {
		Size = UDim2.fromOffset(WIN_W, BODY_H),
		Position = UDim2.fromOffset(0, HEADER_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		ScrollBarThickness = 0, -- штатного скроллбара нет, рисуем свой
		ScrollBarImageTransparency = 1, -- на всякий случай: даже если Roblox покажет штатный, он невидим
		TopImage = "",
		MidImage = "",
		BottomImage = "",
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ScrollingEnabled = false, -- колесо/тач по контенту не листают, только полоса
		ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = MainWin,
	})

	-- hit-зона шире полосы (удобнее попадать), поверх BottomFade
	local hit = Create("Frame", {
		BackgroundTransparency = 1,
		Active = true,
		Visible = false,
		ZIndex = 7,
		Parent = MainWin,
	})
	local track = Create("Frame", {
		BackgroundColor3 = TRACK_COL,
		BorderSizePixel = 0,
		ZIndex = 7,
		Parent = hit,
	})
	local thumb = Create("Frame", {
		BackgroundColor3 = THUMB_COL,
		BorderSizePixel = 0,
		ZIndex = 8,
		Parent = track,
	})

	local page = {scroll = scroll, canvas = 0, key = key}
	local dragging, hovering, grabOff = false, false, 0

	local function ThumbColor()
		local c = dragging and THUMB_DRAG or (hovering and THUMB_HOVER or THUMB_COL)
		TweenService:Create(thumb, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = c}):Play()
	end

	function page.Update()
		local maxS = page.canvas - BODY_H
		local show = scroll.Visible and maxS > 1
		hit.Visible = show
		if not show then return end
		hit.Size = UDim2.fromOffset(BarW + 8, TRK_LEN)
		hit.Position = UDim2.fromOffset(BAR_RIGHT - BarW - 4, HEADER_H + TRK_TOP)
		track.Size = UDim2.new(0, BarW, 1, 0)
		track.Position = UDim2.fromOffset(4, 0)
		local th = math.clamp(TRK_LEN * BODY_H / page.canvas, 20, TRK_LEN)
		local frac = math.clamp(scroll.CanvasPosition.Y / maxS, 0, 1)
		thumb.Size = UDim2.new(1, 0, 0, th)
		thumb.Position = UDim2.fromOffset(0, frac * (TRK_LEN - th))
	end
	function page.SetCanvas(h)
		page.canvas = h
		scroll.CanvasSize = UDim2.fromOffset(0, h)
		page.Update()
	end
	function page.Show(b)
		scroll.Visible = b
		page.Update()
	end

	local function SetFromMouse(mouseY)
		local maxS = page.canvas - BODY_H
		if maxS <= 1 then return end
		local sc = WindowScale.Scale
		local th = thumb.AbsoluteSize.Y / sc
		local travel = TRK_LEN - th
		if travel <= 0 then return end
		local top = (mouseY - hit.AbsolutePosition.Y) / sc - grabOff
		local frac = math.clamp(top / travel, 0, 1)
		scroll.CanvasPosition = Vector2.new(0, frac * maxS)
		page.Update()
	end

	hit.InputBegan:Connect(function(input)
		if IsClickOrTouch(input) then
			dragging = true
			local sc = WindowScale.Scale
			local ty, th = thumb.AbsolutePosition.Y, thumb.AbsoluteSize.Y
			if input.Position.Y >= ty and input.Position.Y <= ty + th then
				grabOff = (input.Position.Y - ty) / sc -- схватили ползунок: держим точку захвата
				ThumbColor()
				SetFromMouse(input.Position.Y)
			else
				-- клик по дорожке, как у обычного скроллбара: листаем на страницу в сторону клика
				dragging = false
				local maxS = page.canvas - BODY_H
				if maxS > 1 then
					local dir = (input.Position.Y < ty) and -1 or 1
					local target = math.clamp(scroll.CanvasPosition.Y + dir * BODY_H * 0.9, 0, maxS)
					TweenService:Create(scroll, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CanvasPosition = Vector2.new(0, target),
					}):Play()
				end
			end
		end
	end)
	-- ползунок всегда следует за реальным положением контента
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(page.Update)
	hit.MouseEnter:Connect(function() hovering = true ThumbColor() end)
	hit.MouseLeave:Connect(function() hovering = false ThumbColor() end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and IsMove(input) then SetFromMouse(input.Position.Y) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and IsClickOrTouch(input) then
			dragging = false
			ThumbColor()
		end
	end)

	Pages[key] = page
	return page
end

local function UpdateAllBars()
	for _, p in pairs(Pages) do p.Update() end
end

local function NewCol(page, x, w)
	return {page = page, x = x, w = w, y = 9}
end

local function NewHost(frame, startY)
	return {frame = frame, y = startY or 0, first = true}
end

-- помещает элемент высотой h, gap = отступ сверху (по умолчанию 5)
local function Place(host, h, gap)
	if host.first then
		host.first = false
	else
		host.y = host.y + (gap or 5)
	end
	local y = host.y
	host.y = host.y + h
	return y
end

local function AddCard(col, title, h, contentTop)
	local card = Create("Frame", {
		Size = UDim2.fromOffset(col.w, h),
		Position = UDim2.fromOffset(col.x, col.y),
		BackgroundColor3 = Theme.CardBg,
		BorderSizePixel = 0,
		Parent = col.page.scroll,
	})
	Corner(card, 6)
	if title then
		Label(card, title, {
			Position = UDim2.fromOffset(9, 8),
			Size = UDim2.new(1, -18, 0, 14),
			Color = Theme.TextWhite,
			Weight = "SemiBold",
		})
	end
	col.y = col.y + h + 9
	local content = Create("Frame", {
		Size = UDim2.new(1, -18, 1, -contentTop),
		Position = UDim2.fromOffset(9, contentTop),
		BackgroundTransparency = 1,
		Parent = card,
	})
	return NewHost(content, 0)
end

-- вложенная рамка внутри карточки (Back Camera / Interpolation)
local function AddBox(host, h, startY, gap)
	local y = Place(host, h, gap)
	local box = Create("Frame", {
		Size = UDim2.new(1, 0, 0, h),
		Position = UDim2.fromOffset(0, y),
		BackgroundColor3 = Theme.BoxBg,
		BorderSizePixel = 0,
		Parent = host.frame,
	})
	Corner(box, 5)
	Stroke(box, Theme.BoxBorder, 1)
	local inner = Create("Frame", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.fromOffset(9, 0),
		BackgroundTransparency = 1,
		Parent = box,
	})
	return NewHost(inner, startY or 0)
end

-- ============================================================================
-- 7. КОМПОНЕНТЫ (с поддержкой disabled)
-- ============================================================================
local function Dropdown(host, labelText, iconNames, defaultVal, options, callback, opts)
	opts = opts or {}
	local y = Place(host, 25, opts.gap)
	local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Parent = host.frame})
	local leftPad, icon = 0, nil
	if iconNames then
		icon = CreateIcon(row, iconNames, 12, UDim2.new(0, -1.5, 0.5, -6), Theme.TextGray)
		leftPad = 14
	end
	local lbl = Label(row, labelText, {Position = UDim2.fromOffset(leftPad, 0), Size = UDim2.new(0.5, -leftPad, 1, 0)})

	local btn = Create("TextButton", {
		Size = UDim2.new(0.5, 0, 0, 25),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Theme.DropdownBg,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(btn, 5)
	local bs = Stroke(btn, Theme.DropdownBorder, 1)
	local valLbl = Label(btn, defaultVal, {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -24, 1, 0), Color = Theme.TextWhite})
	local chev = CreateIcon(btn, {"chevron-down"}, 12, UDim2.new(1, -17, 0.5, -6), Theme.TextGray)

	local ctl, enabled, current = {}, true, defaultVal
	local function Apply()
		lbl.TextColor3 = enabled and Theme.TextGray or Theme.TextDim
		valLbl.TextColor3 = enabled and Theme.TextWhite or Color3.fromRGB(110, 110, 110)
		bs.Color = enabled and Theme.DropdownBorder or Color3.fromRGB(28, 28, 28)
		chev.ImageColor3 = enabled and Theme.TextGray or Theme.TextDim
		if icon then icon.ImageColor3 = enabled and Theme.TextGray or Theme.TextDim end
	end
	function ctl.SetEnabled(b) enabled = b Apply() end
	function ctl.Get() return current end
	function ctl.Set(v, silent)
		for _, o in ipairs(options) do
			if o == v then
				current = v
				valLbl.Text = v
				if not silent and callback then callback(v) end
				return
			end
		end
	end

	btn.MouseButton1Click:Connect(function()
		if not enabled then return end
		if ActivePopup then ClosePopup() return end
		PopupLayer.Visible = true
		local sc = WindowScale.Scale
		local rel = (btn.AbsolutePosition - MainWin.AbsolutePosition) / sc
		local w = btn.AbsoluteSize.X / sc
		local itemH = 21
		local totalH = #options * itemH + 8
		local py = math.clamp(rel.Y + 12.5 - totalH / 2, 6, WIN_H - 6 - totalH)

		local popup = Create("Frame", {
			Size = UDim2.fromOffset(w, 0),
			Position = UDim2.fromOffset(rel.X, py),
			BackgroundColor3 = Theme.PopupBg,
			ClipsDescendants = true,
			Active = true,
			ZIndex = 35,
			Parent = PopupLayer,
		})
		Corner(popup, 5)
		Stroke(popup, Theme.DropdownBorder, 1)
		local list = Create("Frame", {Size = UDim2.new(1, 0, 0, totalH - 8), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Parent = popup})
		Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
		for _, opt in ipairs(options) do
			local sel = (opt == current)
			local ob = Create("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH),
				BackgroundTransparency = 1,
				Text = opt,
				TextColor3 = sel and Theme.Accent or Theme.TextWhite,
				TextSize = TEXT,
				Weight = sel and "SemiBold" or "Medium",
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				Parent = list,
			})
			Create("UIPadding", {PaddingLeft = UDim.new(0, 7), Parent = ob})
			ob.MouseButton1Click:Connect(function()
				current = opt
				current = opt
				valLbl.Text = opt
				if callback then callback(opt) end
				ClosePopup()
			end)
		end
		ActivePopup = popup
		TweenService:Create(popup, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(w, totalH)}):Play()
	end)
	Apply()
	return ctl
end

local function Toggle(host, labelText, default, callback, opts)
	opts = opts or {}
	local y = Place(host, 21, opts.gap)
	local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 21), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Parent = host.frame})
	local lbl = Label(row, labelText, {Size = UDim2.new(0.75, 0, 1, 0)})
	local sw = Create("TextButton", {
		Size = UDim2.fromOffset(26, 14),
		Position = UDim2.new(1, -26, 0.5, -7),
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(sw, 7)
	local dot = Create("Frame", {Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Parent = sw})
	Corner(dot, 4)

	local ctl, enabled, state = {}, true, default
	local function Apply(animate)
		local bg, bgT, dotC, dotPos
		if state then
			bg, bgT = Theme.Accent, 1 - Theme.AccentAlpha * (enabled and 1 or 0.45)
			dotC, dotPos = Color3.new(1, 1, 1), UDim2.new(1, -11, 0.5, -4)
		else
			bg = enabled and Theme.ToggleOffBg or Color3.fromRGB(19, 19, 19)
			bgT = 0
			dotC = enabled and Theme.ToggleOffDot or Color3.fromRGB(32, 32, 32)
			dotPos = UDim2.new(0, 3, 0.5, -4)
		end
		lbl.TextColor3 = (not enabled) and Theme.TextDim or (state and Theme.TextWhite or Theme.TextGray)
		ApplyFont(lbl, state and "SemiBold" or "Medium")
		if animate then
			local ti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
			TweenService:Create(dot, ti, {Position = dotPos, BackgroundColor3 = dotC}):Play()
			TweenService:Create(sw, ti, {BackgroundColor3 = bg, BackgroundTransparency = bgT}):Play()
		else
			dot.Position, dot.BackgroundColor3 = dotPos, dotC
			sw.BackgroundColor3, sw.BackgroundTransparency = bg, bgT
		end
	end
	BindAccent(function() Apply(false) end)

	function ctl.SetEnabled(b) enabled = b Apply(false) end
	function ctl.Get() return state end
	function ctl.Set(v, silent)
		state = v and true or false
		Apply(true)
		if not silent and callback then callback(state) end
	end
	sw.MouseButton1Click:Connect(function()
		if not enabled then return end
		state = not state
		Apply(true)
		if callback then callback(state) end
	end)
	return ctl
end

local function Slider(host, labelText, minV, maxV, defV, fmt, callback, opts)
	opts = opts or {}
	local extraTop = opts.extraTop or 0
	local step = opts.step or 1
	local current = defV
	local y = Place(host, 28 + extraTop, opts.gap)
	local box = Create("Frame", {Size = UDim2.new(1, 0, 0, 28 + extraTop), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Parent = host.frame})
	local lbl = Label(box, labelText, {Position = UDim2.fromOffset(0, extraTop), Size = UDim2.new(0.65, 0, 0, 15)})
	local valLbl = Label(box, fmt(defV), {
		Position = UDim2.new(0.65, 0, 0, extraTop),
		Size = UDim2.new(0.35, 0, 0, 15),
		Align = Enum.TextXAlignment.Right,
	})
	local hit = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, extraTop + 12.5),
		BackgroundTransparency = 1,
		Active = true,
		Parent = box,
	})
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 0.5, -2),
		BackgroundColor3 = Theme.SliderTrack,
		BorderSizePixel = 0,
		Parent = hit,
	})
	Corner(track, 2)
	local R = 5.5
	local fill = Create("Frame", {BorderSizePixel = 0, Parent = track})
	Corner(fill, 2)
	local knob = Create("Frame", {
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Color3.fromRGB(14, 14, 14),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	Corner(knob, 4)
	local ks = Stroke(knob, Color3.fromRGB(246, 246, 249), 2)

	local ctl, enabled = {}, true
	local function Layout(p)
		fill.Size = UDim2.new(p, R * (1 - 2 * p), 1, 0)
		knob.Position = UDim2.new(p, R * (1 - 2 * p) - 3.5, 0.5, -3.5)
	end
	Layout((defV - minV) / (maxV - minV))

	local function Apply()
		lbl.TextColor3 = enabled and Theme.TextGray or Theme.TextDim
		valLbl.TextColor3 = enabled and Theme.TextGray or Theme.TextDim
		fill.BackgroundTransparency = 1 - Theme.AccentAlpha * (enabled and 1 or 0.45)
		ks.Color = enabled and Color3.fromRGB(246, 246, 249) or Color3.fromRGB(150, 150, 156)
	end
	BindAccent(function(c) fill.BackgroundColor3 = c Apply() end)
	function ctl.SetEnabled(b) enabled = b Apply() end
	function ctl.Get() return current end
	function ctl.Set(v, silent)
		local val = math.clamp(math.floor(v / step + 0.5) * step, minV, maxV)
		current = val
		Layout((val - minV) / (maxV - minV))
		valLbl.Text = fmt(val)
		if not silent and callback then callback(val) end
	end

	local dragging = false
	local function Update(input)
		local sc = WindowScale.Scale
		local left = track.AbsolutePosition.X + R * sc
		local width = track.AbsoluteSize.X - 2 * R * sc
		local p = math.clamp((input.Position.X - left) / width, 0, 1)
		local val = math.floor((minV + (maxV - minV) * p) / step + 0.5) * step
		val = math.clamp(val, minV, maxV)
		current = val
		Layout((val - minV) / (maxV - minV))
		valLbl.Text = fmt(val)
		if callback then callback(val) end
	end
	hit.InputBegan:Connect(function(input)
		if enabled and IsClickOrTouch(input) then
			dragging = true
			SetScrollLock(true)
			Update(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and IsMove(input) then Update(input) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and IsClickOrTouch(input) then
			dragging = false
			SetScrollLock(false)
		end
	end)
	return ctl
end

-- COLOR PICKER: SV + Hue + Alpha
-- Модалка ВСЕГДА лежит внутри тела окна (не залезает на шапку/нижний бар),
-- у всех интерактивных зон отдельные hit-фреймы с высоким ZIndex.
local function ColorPicker(host, labelText, opts)
	opts = opts or {}
	local y = Place(host, 25, opts.gap)
	local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 25), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1, Parent = host.frame})
	CreateIcon(row, {"palette"}, 12, UDim2.new(0, -1.5, 0.5, -6), Theme.TextGray)
	Label(row, labelText, {Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.7, -14, 1, 0)})

	local circle = Create("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -18, 0.5, -9),
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(circle, 9)
	BindAccent(function(c) circle.BackgroundColor3 = c end)

	local h, s, v = Theme.Accent:ToHSV()
	local a = 1 - Theme.AccentAlpha -- 0 = верх полоски (непрозрачный)

	circle.MouseButton1Click:Connect(function()
		if ActivePopup then ClosePopup() return end
		PopupLayer.Visible = true

		local MW, MH = 208, 184
		local SV, BW, BH = 144, 16, 144
		local HX, AX = 160, 184

		local sc = WindowScale.Scale
		local rel = (circle.AbsolutePosition - MainWin.AbsolutePosition) / sc
		local mx = math.clamp(rel.X + 18 + 13, 6, WIN_W - MW - 6)
		local my = math.clamp(rel.Y + 9 - MH / 2, HEADER_H + 6, WIN_H - BOTTOM_H - 6 - MH)

		local modal = Create("Frame", {
			Size = UDim2.fromOffset(MW, MH),
			Position = UDim2.fromOffset(mx, my),
			BackgroundColor3 = Color3.fromRGB(14, 14, 14),
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 35,
			Parent = PopupLayer,
		})
		Corner(modal, 6)
		Stroke(modal, Color3.fromRGB(26, 26, 26), 1)

		-- SV
		local svBox = Create("Frame", {
			Size = UDim2.fromOffset(SV, SV),
			Position = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel = 0,
			Parent = modal,
		})
				local wL = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = svBox})
				Create("UIGradient", {
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Parent = wL,
		})
		local bL = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3, Parent = svBox})
				Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
			Parent = bL,
		})
		local cursor = Create("Frame", {
			Size = UDim2.fromOffset(9, 9),
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = svBox,
		})
		Corner(cursor, 5)
		Stroke(cursor, Color3.fromRGB(245, 245, 245), 1.5)
		local svHit = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = svBox})

		-- Hue
		local hueBar = Create("Frame", {
			Size = UDim2.fromOffset(BW, BH),
			Position = UDim2.fromOffset(HX, 8),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = modal,
		})
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Parent = hueBar,
		})
		local hueHit = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = hueBar})

		-- Alpha: шахматка со скруглёнными углами + градиент цвета поверх
		local alphaBar = Checker(modal, AX, 8, BW, BH, 8)
		local alphaTint = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = alphaBar})
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Parent = alphaTint,
		})
		local alphaHit = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = alphaBar})

		-- маркеры-треугольники по бокам полосок
		-- Маркер = прямоугольный равнобедренный треугольник 3x6.
		-- Ромб (квадрат под 45°) с центром на ребре обрезается рамкой 3x6: остаётся ровно половина-треугольник.
		local function Marker(x, pointRight)
			local clip = Create("Frame", {
				Size = UDim2.fromOffset(3, 6),
				Position = UDim2.fromOffset(x, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				ZIndex = 10,
				Parent = modal,
			})
			Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(4.2426, 4.2426),
				Position = pointRight and UDim2.fromOffset(0, 3) or UDim2.fromOffset(3, 3),
				Rotation = 45,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 10,
				Parent = clip,
			})
			return clip
		end
		local hueL, hueR = Marker(HX, true), Marker(HX + BW - 3, false)
		local alL, alR = Marker(AX, true), Marker(AX + BW - 3, false)

		-- нижняя строка: превью цвета (шахматка 24x12), HEX, альфа в процентах
		local swatchBg = Checker(modal, 8, 162, 24, 12, 6)
		local swatch = Create("Frame", {Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 5, Parent = swatchBg})
		local hexLbl = Label(modal, "", {Position = UDim2.fromOffset(40, 158), Size = UDim2.fromOffset(90, 20), TextSize = 10})
		local alphaLbl = Label(modal, "", {Position = UDim2.fromOffset(MW - 78, 158), Size = UDim2.fromOffset(70, 20), TextSize = 10, Align = Enum.TextXAlignment.Right})

		local function Refresh()
			local col = Color3.fromHSV(h, s, v)
			local alpha = 1 - a
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cursor.Position = UDim2.new(s, -4.5, 1 - v, -4.5)
			cursor.BackgroundColor3 = col
			alphaTint.BackgroundColor3 = col
			swatch.BackgroundColor3 = col
			swatch.BackgroundTransparency = 1 - alpha
			local hy = 8 + h * BH - 3
			hueL.Position = UDim2.fromOffset(HX, hy)
			hueR.Position = UDim2.fromOffset(HX + BW - 3, hy)
			local ay = 8 + a * BH - 3
			alL.Position = UDim2.fromOffset(AX, ay)
			alR.Position = UDim2.fromOffset(AX + BW - 3, ay)
			hexLbl.Text = string.format("#%02X%02X%02X", math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5))
			alphaLbl.Text = math.floor(alpha * 100 + 0.5) .. "%"
		end
		Refresh()

		local mode = nil
		local function Process(inp)
			if mode == "SV" then
				s = math.clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
			elseif mode == "H" then
				h = math.clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
			elseif mode == "A" then
				a = math.clamp((inp.Position.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 0.92)
			else
				return
			end
			Refresh()
			SetAccent(Color3.fromHSV(h, s, v), 1 - a)
		end
		local function Begin(m)
			return function(i)
				if IsClickOrTouch(i) then
					mode = m
					SetScrollLock(true)
					Process(i)
				end
			end
		end
		svHit.InputBegan:Connect(Begin("SV"))
		hueHit.InputBegan:Connect(Begin("H"))
		alphaHit.InputBegan:Connect(Begin("A"))

		table.insert(PopupConns, UserInputService.InputChanged:Connect(function(i)
			if mode and IsMove(i) then Process(i) end
		end))
		table.insert(PopupConns, UserInputService.InputEnded:Connect(function(i)
			if IsClickOrTouch(i) then mode = nil end
		end))
		ActivePopup = modal
	end)
end

-- ============================================================================
-- ============================================================================
-- 8. НАВИГАЦИЯ (вкладки / sub-вкладки / страницы) + ПУБЛИЧНЫЙ API
-- ============================================================================
local TI_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TILE_ON, TILE_OFF = UDim2.fromOffset(94, 27), UDim2.fromOffset(80, 23)
local TAB_W = 102

local Nav = {main = nil, sub = {}}
local MainTabs = {}
local TabByName = {}
local AccentIcons = {}
local DetailMode = "Product Type"
local LastSubKey = nil
local CurrentKey = nil
local HasSettings = false

local NavHolder = Create("Frame", {
	Size = UDim2.fromOffset(0, BOTTOM_H),
	Position = UDim2.new(0.5, 0, 0, 0),
	BackgroundTransparency = 1,
	Parent = BottomBar,
})
Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = NavHolder})

local function LayoutNavHolder()
	local width = TAB_W * #MainTabs
	NavHolder.Size = UDim2.fromOffset(width, BOTTOM_H)
	NavHolder.Position = UDim2.new(0.5, -width / 2, 0, 0)
end

local function RefreshAccentIcons()
	for _, ic in ipairs(AccentIcons) do
		if ic.Parent then
			ic.ImageColor3 = Theme.Accent
			ic.ImageTransparency = 1 - Theme.AccentAlpha
		end
	end
end
BindAccent(RefreshAccentIcons)

local function ApplyNavVisuals(instant)
	for _, t in ipairs(MainTabs) do
		local active = (Nav.main == t.name)
		local tileTransparency = active and 0 or 1
		local tileSize = active and TILE_ON or TILE_OFF
		local labelColor = active and Theme.TextWhite or Theme.NavGray
		if instant then
			t.tile.BackgroundTransparency = tileTransparency
			t.tile.Size = tileSize
			t.label.TextColor3 = labelColor
		else
			TweenService:Create(t.tile, TI_FAST, {BackgroundTransparency = tileTransparency, Size = tileSize}):Play()
			TweenService:Create(t.label, TI_FAST, {TextColor3 = labelColor}):Play()
		end
		t.icon.ImageColor3 = Theme.NavGray
		t.icon.ImageTransparency = 0
		if active then table.insert(AccentIcons, t.icon) end
	end
	local gearActive = (Nav.main == "settings")
	if instant then
		SetBtn.BackgroundTransparency = gearActive and 0 or 1
	else
		TweenService:Create(SetBtn, TI_FAST, {BackgroundTransparency = gearActive and 0 or 1}):Play()
	end
	GearIcon.ImageColor3 = Theme.NavGray
	GearIcon.ImageTransparency = 0
	if gearActive then table.insert(AccentIcons, GearIcon) end
end

local function BuildSubTabs()
	for _, ch in ipairs(SubHolder:GetChildren()) do
		if ch:IsA("GuiObject") then ch:Destroy() end
	end
	local tab = TabByName[Nav.main]
	if not tab or #tab.subs == 0 then return end
	local selected = Nav.sub[Nav.main]
	local subKey = Nav.main .. "/" .. tostring(selected)
	local animate = (LastSubKey ~= nil and LastSubKey ~= subKey)
	LastSubKey = subKey
	for i, d in ipairs(tab.subs) do
		local active = (selected == d.id)
		local b = Create("TextButton", {
			Size = active and UDim2.new(0, 0, 0, 26) or UDim2.fromOffset(26, 26),
			AutomaticSize = active and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
			BackgroundColor3 = Theme.TileBg,
			BackgroundTransparency = active and (animate and 1 or 0) or 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = SubHolder,
		})
		Corner(b, 5)
		if active then
			if animate then TweenService:Create(b, TI_FAST, {BackgroundTransparency = 0}):Play() end
			Create("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 8), Parent = b})
			Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				Parent = b,
			})
			local ic = Create("ImageLabel", {Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, LayoutOrder = 1, Parent = b})
			ApplyIcon(ic, d.icon)
			table.insert(AccentIcons, ic)
			local lb = Label(b, d.text, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = Theme.TextWhite})
			lb.LayoutOrder = 2
			if animate then
				lb.TextTransparency = 1
				TweenService:Create(lb, TI_FAST, {TextTransparency = 0}):Play()
			end
		else
			local ic = CreateIcon(b, d.icon, 12, UDim2.new(0.5, -6, 0.5, -6), Theme.NavGray)
			ic.ImageColor3 = Theme.NavGray
		end
		b.MouseButton1Click:Connect(function()
			Nav.sub[Nav.main] = d.id
			RefreshNav()
		end)
	end
end

local function PageKey()
	if Nav.main == "settings" then return "settings" end
	local tab = TabByName[Nav.main]
	if tab and #tab.subs > 0 then return Nav.main .. "/" .. tostring(Nav.sub[Nav.main]) end
	return Nav.main
end

local SwitchToken = 0
local ActiveTweens = {}

local function CancelTweens()
	for _, t in ipairs(ActiveTweens) do t:Cancel() end
	table.clear(ActiveTweens)
end

local function ShowPage(key, animate)
	SwitchToken = SwitchToken + 1
	local token = SwitchToken
	CancelTweens()

	local function Swap()
		for k, p in pairs(Pages) do
			if k ~= key then p.Show(false) end
		end
		local p = Pages[key]
		if not p then return end
		p.scroll.CanvasPosition = Vector2.new(0, 0)
		p.Show(true)
		if animate then
			p.scroll.Position = UDim2.fromOffset(0, HEADER_H + 12)
			Fader.BackgroundTransparency = 0
			local t1 = TweenService:Create(p.scroll, TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, HEADER_H)})
			local t2 = TweenService:Create(Fader, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
			table.insert(ActiveTweens, t1)
			table.insert(ActiveTweens, t2)
			t1:Play()
			t2:Play()
		else
			p.scroll.Position = UDim2.fromOffset(0, HEADER_H)
			Fader.BackgroundTransparency = 1
		end
	end

	if not animate then
		Swap()
		return
	end

	local out = TweenService:Create(Fader, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 0})
	table.insert(ActiveTweens, out)
	out.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then return end
		if token ~= SwitchToken then return end
		Swap()
	end)
	out:Play()
end

local function RefreshNav()
	ClosePopup()
	table.clear(AccentIcons)
	local key = PageKey()
	if key ~= CurrentKey then
		ShowPage(key, CurrentKey ~= nil)
		CurrentKey = key
	end
	ApplyNavVisuals(false)
	BuildSubTabs()
	RefreshAccentIcons()
end

SetBtn.MouseButton1Click:Connect(function()
	Nav.main = "settings"
	RefreshNav()
end)

-- ---------------------------------------------------------------- страницы --
local PageMT = {}
PageMT.__index = PageMT
local ColMT = {}
ColMT.__index = ColMT
local HostMT = {}
HostMT.__index = HostMT

local function WrapHost(raw)
	return setmetatable({raw = raw}, HostMT)
end

local function WrapPage(raw)
	return setmetatable({raw = raw, cols = {}}, PageMT)
end

function PageMT:Refresh()
	local height = 0
	for _, col in ipairs(self.cols) do height = math.max(height, col.y) end
	self.raw.SetCanvas(height)
end

function PageMT:Column(x, w)
	local col = NewCol(self.raw, x, w)
	table.insert(self.cols, col)
	return setmetatable({page = self, col = col}, ColMT)
end

function ColMT:Card(title, height, contentTop)
	local host = AddCard(self.col, title, height, contentTop or 30)
	self.page:Refresh()
	return WrapHost(host)
end

function HostMT:Toggle(label, default, callback, opts)
	return Toggle(self.raw, label, default, callback, opts)
end

function HostMT:Slider(label, minV, maxV, default, format, callback, opts)
	return Slider(self.raw, label, minV, maxV, default, format, callback, opts)
end

function HostMT:Dropdown(label, icons, default, options, callback, opts)
	return Dropdown(self.raw, label, icons, default, options, callback, opts)
end

function HostMT:ColorPicker(label, opts)
	return ColorPicker(self.raw, label, opts)
end

function HostMT:Box(height, startY, gap)
	return WrapHost(AddBox(self.raw, height, startY, gap))
end

local function Button(host, labelText, callback, opts)
	opts = opts or {}
	local y = Place(host, 25, opts.gap)
	local btn = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.fromOffset(0, y),
		BackgroundColor3 = Theme.DropdownBg,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = host.frame,
	})
	Corner(btn, 5)
	Stroke(btn, Theme.DropdownBorder, 1)
	Label(btn, labelText, {Color = Theme.TextWhite, Align = Enum.TextXAlignment.Center})
	local ctl = {}
	local enabled = true
	function ctl.SetEnabled(b)
		enabled = b
		btn.Active = b
	end
	btn.MouseButton1Click:Connect(function()
		if enabled and callback then callback() end
	end)
	return ctl
end

function HostMT:Button(label, callback, opts)
	return Button(self.raw, label, callback, opts)
end

function HostMT:Place(height, gap)
	return Place(self.raw, height, gap)
end

function HostMT:Frame()
	return self.raw.frame
end

-- ------------------------------------------------------------ вкладки API --
local MainTabMT = {}
MainTabMT.__index = MainTabMT

local function NewMainTab(name, icons)
	assert(type(name) == "string" and name ~= "", "Tab needs a Name")
	assert(TabByName[name] == nil, "Duplicate tab: " .. name)
	local index = #MainTabs + 1
	local btn = Create("TextButton", {
		Size = UDim2.new(0, TAB_W, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		LayoutOrder = index,
		Parent = NavHolder,
	})
	local tile = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = TILE_OFF,
		BackgroundColor3 = Theme.TileBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = btn,
	})
	Corner(tile, 5)
	local content = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = btn,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = content,
	})
	local ic = Create("ImageLabel", {Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ImageColor3 = Theme.NavGray, LayoutOrder = 1, Parent = content})
	ApplyIcon(ic, icons or {"circle"})
	local lbl = Label(content, name, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = Theme.NavGray})
	lbl.LayoutOrder = 2

	local tab = setmetatable({name = name, tile = tile, icon = ic, label = lbl, subs = {}}, MainTabMT)
	MainTabs[index] = tab
	TabByName[name] = tab
	LayoutNavHolder()

	btn.MouseButton1Click:Connect(function()
		Nav.main = name
		RefreshNav()
	end)
	return tab
end

function MainTabMT:Sub(opts)
	opts = opts or {}
	local subName = assert(opts.Name, "Sub tab needs a Name")
	local key = self.name .. "/" .. subName
	assert(Pages[key] == nil, "Duplicate sub tab: " .. key)
	table.insert(self.subs, {id = subName, icon = opts.Icon or {"circle"}, text = subName})
	if Nav.sub[self.name] == nil then Nav.sub[self.name] = subName end
	return WrapPage(NewPage(key))
end

function MainTabMT:Page()
	assert(#self.subs == 0, "Tab '" .. self.name .. "' has sub tabs, use :Sub()")
	return WrapPage(NewPage(self.name))
end

-- ---------------------------------------------------------------- окно API --
local Win = {}

function Win:Tab(opts)
	opts = opts or {}
	return NewMainTab(opts.Name, opts.Icons or opts.Icon)
end

function Win:Settings()
	HasSettings = true
	return WrapPage(NewPage("settings"))
end

function Win:Init()
	if Nav.main == nil then
		if HasSettings then Nav.main = "settings"
		elseif MainTabs[1] then Nav.main = MainTabs[1].name end
	end
	ApplyNavVisuals(true)
	RefreshNav()
end

function Win:SetAccent(color, alpha)
	SetAccent(color, alpha)
end

function Win:SetWatermarkOpacity(alpha)
	SetWatermarkOpacity(math.clamp(alpha, 0, 1))
end

function Win:SetWatermarkIcons(state)
	for _, group in ipairs(WM_IconGroups) do group.Visible = state == true end
end

function Win:SetWatermarkDetail(mode)
	DetailMode = mode
end

function Win:SetLogo(cfg)
	WM.logoCfg = cfg
	BuildWatermark(WM.specs)
	local pos = WM.header and WM.header.Position
	if WM.header then WM.header:Destroy() end
	WM.header = MakeLogo(Header, 10, cfg, false)
	if pos then WM.header.Position = pos end
	return self
end

function Win:SetWatermarkItems(list)
	BuildWatermark(NormalizeWatermark(list))
	return self
end

function Win:GetWatermarkItems()
	local copy = {}
	for index, spec in ipairs(WM.specs) do copy[index] = spec end
	return copy
end

function Win:SetWatermarkItem(id, changes)
	for _, spec in ipairs(WM.specs) do
		if spec.Id ~= nil and tostring(spec.Id) == tostring(id) then
			for key, value in pairs(changes or {}) do spec[key] = value end
			BuildWatermark(WM.specs)
			return true
		end
	end
	return false
end

function Win:SetWatermarkText(id, text)
	return self:SetWatermarkItem(id, {Text = text})
end

function Win:SetWatermarkVisible(state)
	Watermark.Visible = state == true
end

function Win:SetWatermarkPosition(x, y)
	Watermark.Position = UDim2.fromOffset(x, y)
end

function Win:SetWatermarkStyle(style)
	style = style or {}
	if style.Background ~= nil then Watermark.BackgroundColor3 = style.Background end
	if style.Stroke ~= nil then WM_Stroke.Color = style.Stroke end
	if style.Radius ~= nil then WM_Corner.CornerRadius = UDim.new(0, style.Radius) end
	return self
end

function Win:SetScrollbarWidth(width)
	BarW = math.clamp(math.floor(width + 0.5), 1, 14)
	UpdateAllBars()
end

function Win:SetUIScale(scale)
	TweenService:Create(WindowScale, TweenInfo.new(0.18), {Scale = scale}):Play()
end

function Win:SetVisible(state)
	WindowHolder.Visible = state == true
	if not state then ClosePopup() end
end

function Win:Toggle()
	self:SetVisible(not WindowHolder.Visible)
end

function Win:Destroy()
	ScreenGui:Destroy()
end

Win.Theme = Theme

-- ============================================================================
-- 10. LIVE ДАННЫЕ WATERMARK + ГОРЯЧАЯ КЛАВИША
-- ============================================================================
local fps = 60
RunService.RenderStepped:Connect(function(dt)
	if dt > 0 then fps = fps + (1 / dt - fps) * 0.1 end
end)

task.spawn(function()
	while ScreenGui.Parent do
		local txt = "internal"
		if DetailMode == "Time" then
			txt = os.date("%H:%M:%S")
		elseif DetailMode == "FPS" then
			txt = string.format("%d fps", math.floor(fps + 0.5))
		elseif DetailMode == "Ping" then
			local ok, ping = pcall(function()
				return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			txt = ok and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
		elseif DetailMode == "Version" then
			txt = "v2.4"
		end
		local detail = WM.byId.detail
		if detail and detail.label then detail.label.Text = txt end
		task.wait(0.25)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == CONFIG.ToggleKey then
		Win:Toggle()
	end
end)

return Win

end

return Library
