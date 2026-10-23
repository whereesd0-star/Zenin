local Zenin = {Version = "2.0.0"}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Draw order: the menu always sits above the notifications, and those above the watermark.
Zenin.Priority = {Window = 2147483647, Notify = 2147483646, Watermark = 2147483645}
Zenin.IconsUrl = "https://raw.githubusercontent.com/whereesd0-star/Icons/refs/heads/main/Icons.lua%20(3).txt"
Zenin.IconsCache = "zenin_lucide_icons.lua"
Zenin.ConfigFolder = "ZeninConfigs"
Zenin.Windows = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

----------------------------------------------------------------------
-- themes: every colour is a token; AddTheme merges over Dark
----------------------------------------------------------------------
local Themes = {}
Zenin.Themes = Themes

Themes.Dark = {
	Window = rgb(14, 14, 14), Bar = rgb(18, 18, 18), BarLine = rgb(22, 22, 22),
	Card = rgb(18, 18, 18), Field = rgb(22, 22, 22), FieldBorder = rgb(42, 42, 42),
	Tile = rgb(22, 22, 22), Popup = rgb(14, 14, 14), PopupBorder = rgb(26, 26, 26),
	Track = rgb(22, 22, 22), ToggleOff = rgb(22, 22, 22), ToggleDot = rgb(44, 44, 44),
	ToggleOffDisabled = rgb(19, 19, 19), ToggleDotDisabled = rgb(32, 32, 32),
	Text = rgb(255, 255, 255), TextSub = rgb(160, 160, 168), TextDim = rgb(88, 88, 96),
	Nav = rgb(180, 180, 188), Disabled = rgb(110, 110, 110), DisabledBorder = rgb(28, 28, 28),
	Divider = rgb(34, 34, 38), Knob = rgb(14, 14, 14), KnobRing = rgb(246, 246, 249), KnobRingOff = rgb(150, 150, 156),
	WmBg = rgb(14, 14, 14), WmStroke = rgb(38, 38, 43), WmDivider = rgb(42, 42, 47), WmIcon = rgb(205, 205, 210),
	ScrollTrack = rgb(18, 18, 18), ScrollThumb = rgb(22, 22, 22), ScrollHover = rgb(30, 30, 30), ScrollDrag = rgb(40, 40, 40),
	Danger = rgb(255, 92, 92), Shadow = rgb(0, 0, 0),
}

function Zenin.AddTheme(name, tokens)
	assert(type(name) == "string" and type(tokens) == "table", "AddTheme(name, tokens)")
	local merged = {}
	for key, value in pairs(Themes.Dark) do merged[key] = value end
	for key, value in pairs(tokens) do merged[key] = value end
	Themes[name] = merged
end

Zenin.AddTheme("Midnight", {
	Window = rgb(9, 10, 15), Bar = rgb(13, 14, 20), BarLine = rgb(20, 22, 31), Card = rgb(13, 14, 20),
	Field = rgb(17, 18, 26), FieldBorder = rgb(36, 39, 56), Tile = rgb(17, 18, 26), Popup = rgb(9, 10, 15),
	PopupBorder = rgb(24, 26, 37), Track = rgb(17, 18, 26), ToggleOff = rgb(17, 18, 26), ToggleDot = rgb(40, 43, 60),
	TextSub = rgb(150, 155, 176), Nav = rgb(170, 175, 197), Divider = rgb(30, 32, 46),
	WmBg = rgb(9, 10, 15), WmStroke = rgb(32, 35, 50), ScrollTrack = rgb(13, 14, 20), ScrollThumb = rgb(20, 22, 31),
})

Zenin.AddTheme("Light", {
	Window = rgb(234, 235, 239), Bar = rgb(248, 248, 250), BarLine = rgb(224, 225, 230), Card = rgb(248, 248, 250),
	Field = rgb(241, 242, 245), FieldBorder = rgb(210, 212, 219), Tile = rgb(236, 237, 241), Popup = rgb(250, 250, 252),
	PopupBorder = rgb(214, 216, 222), Track = rgb(220, 222, 228), ToggleOff = rgb(220, 222, 228), ToggleDot = rgb(168, 171, 180),
	Text = rgb(22, 23, 28), TextSub = rgb(104, 107, 118), TextDim = rgb(160, 163, 172), Nav = rgb(96, 99, 110),
	Divider = rgb(214, 216, 222), Knob = rgb(250, 250, 252), KnobRing = rgb(34, 35, 42), KnobRingOff = rgb(170, 173, 182),
	WmBg = rgb(250, 250, 252), WmStroke = rgb(214, 216, 222), WmDivider = rgb(206, 208, 215), WmIcon = rgb(96, 99, 110),
	ScrollTrack = rgb(240, 241, 244), ScrollThumb = rgb(214, 216, 222), ScrollHover = rgb(200, 202, 210), ScrollDrag = rgb(184, 187, 196),
})

----------------------------------------------------------------------
-- icons: Lucide sprite sheets, downloaded once and cached to disk
----------------------------------------------------------------------
local IconSet, IconsTried = nil, false

local function parseIcons(source)
	if type(source) ~= "string" or #source < 200 then return nil end
	local chunk = loadstring(source)
	if not chunk then return nil end
	local ok, result = pcall(chunk)
	if ok and type(result) == "table" and type(result["48px"]) == "table" then return result end
	return nil
end

local function httpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 200 then return body end
	local request = (syn and syn.request) or (http and http.request) or http_request or request
	if request then
		local ok2, response = pcall(request, {Url = url, Method = "GET"})
		if ok2 and type(response) == "table" and type(response.Body) == "string" then return response.Body end
	end
	return nil
end

-- Zenin.LoadIcons()                 downloads the default Lucide set (cached)
-- Zenin.LoadIcons("https://...")    another sprite-sheet URL
-- Zenin.LoadIcons({["48px"] = {...}}) a table you built yourself
function Zenin.LoadIcons(source, cacheFile)
	if type(source) == "table" then
		IconSet, IconsTried = source, true
		return IconSet
	end
	if IconSet then return IconSet end
	IconsTried = true
	local url = (type(source) == "string" and source) or Zenin.IconsUrl
	local cache = cacheFile or Zenin.IconsCache
	local cached
	if isfile and readfile then
		local ok, data = pcall(function() if isfile(cache) then return readfile(cache) end end)
		if ok then cached = data end
	end
	IconSet = parseIcons(cached)
	if not IconSet then
		local source2 = httpGet(url)
		IconSet = parseIcons(source2)
		if IconSet and writefile then pcall(writefile, cache, source2) end
	end
	return IconSet
end

local function resolveIcon(name)
	if not IconSet then return nil end
	for _, sheet in ipairs({"48px", "256px"}) do
		local s = IconSet[sheet]
		local entry = s and s[name]
		if entry then return entry end
	end
	return nil
end

-- names: a string or an array of names; the first one found wins
local function applyIcon(image, names)
	if type(names) == "string" then names = {names} end
	for _, name in ipairs(names or {}) do
		local entry = resolveIcon(name)
		if entry then
			image.Image = "rbxassetid://" .. tostring(entry[1])
			image.ImageRectSize = Vector2.new(entry[2][1], entry[2][2])
			image.ImageRectOffset = Vector2.new(entry[3][1], entry[3][2])
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- low-level helpers
----------------------------------------------------------------------
local FONT_WEIGHTS = {
	Regular = Enum.FontWeight.Regular, Medium = Enum.FontWeight.Medium,
	SemiBold = Enum.FontWeight.SemiBold, Bold = Enum.FontWeight.Bold,
}
local FontCache = {}

local function applyFont(object, weight)
	local ok = pcall(function()
		local face = FontCache[weight]
		if not face then
			face = Font.new("rbxasset://fonts/families/Roboto.json", FONT_WEIGHTS[weight] or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
			FontCache[weight] = face
		end
		object.FontFace = face
	end)
	if not ok then
		object.Font = (weight == "Bold" or weight == "SemiBold") and Enum.Font.GothamBold or Enum.Font.GothamMedium
	end
end

-- create("TextLabel", {Text = "x", Corner = 6, Stroke = {Color = c, Thickness = 1}, Parent = p})
local function create(class, props)
	local object = Instance.new(class)
	local parent, radius, stroke
	for key, value in pairs(props or {}) do
		if key == "Parent" then parent = value
		elseif key == "Corner" then radius = value
		elseif key == "Stroke" then stroke = value
		elseif key == "Weight" then applyFont(object, value)
		else object[key] = value end
	end
	if radius then create("UICorner", {CornerRadius = UDim.new(0, radius), Parent = object}) end
	if stroke then
		create("UIStroke", {
			Color = stroke.Color or rgb(40, 40, 40), Thickness = stroke.Thickness or 1,
			Transparency = stroke.Transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = object,
		})
	end
	if parent then object.Parent = parent end
	return object
end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

-- Drag with a 4 px threshold (a tap is not a drag), smooth follow, clamped to the screen,
-- OnClick for a plain tap, OnDoubleClick for two taps. Returns a disconnect function.
local function makeDraggable(handle, target, opts)
	opts = opts or {}
	local MARGIN, THRESH, SMOOTH, DOUBLE = opts.Margin or 56, 4, 30, 0.3
	local home = target.Position
	local conns, stepConn, homeTween = {}, nil, nil
	local drag = {input = nil, moved = false}
	local startMouse, startPos, startAbs = Vector2.new(), target.Position, Vector2.new()
	local goal, cur = Vector2.new(), Vector2.new()
	local lastTap = 0

	local function screen()
		local gui = target:FindFirstAncestorWhichIsA("ScreenGui")
		return gui and gui.AbsoluteSize or Vector2.new(1920, 1080)
	end
	local function clampAbs(abs)
		local s, size = screen(), target.AbsoluteSize
		return Vector2.new(math.clamp(abs.X, MARGIN - size.X, s.X - MARGIN), math.clamp(abs.Y, 0, s.Y - MARGIN))
	end
	local function apply(d)
		target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
	local function stopStep()
		if stepConn then stepConn:Disconnect() stepConn = nil end
	end
	local function startStep()
		if stepConn then return end
		stepConn = RunService.RenderStepped:Connect(function(dt)
			cur = cur:Lerp(goal, 1 - math.exp(-dt * SMOOTH))
			if (goal - cur).Magnitude < 0.25 then cur = goal end
			apply(cur)
			if cur == goal and not drag.input then stopStep() end
		end)
	end
	local function overButton(pos)
		for _, d in ipairs(handle:GetDescendants()) do
			if d:IsA("GuiButton") and d.Visible then
				local p, sz = d.AbsolutePosition, d.AbsoluteSize
				if pos.X >= p.X and pos.X <= p.X + sz.X and pos.Y >= p.Y and pos.Y <= p.Y + sz.Y then return true end
			end
		end
		return false
	end

	table.insert(conns, handle.InputBegan:Connect(function(input)
		if not isClick(input) or drag.input then return end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		if overButton(pos) then return end
		if homeTween then homeTween:Cancel() homeTween = nil end
		drag.input, drag.moved = input, false
		startMouse, startPos, startAbs = pos, target.Position, target.AbsolutePosition
		cur, goal = Vector2.new(), Vector2.new()
	end))
	table.insert(conns, UIS.InputChanged:Connect(function(input)
		if not drag.input then return end
		if drag.input.UserInputType == Enum.UserInputType.Touch then
			if input ~= drag.input then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - startMouse
		if not drag.moved then
			if delta.Magnitude < THRESH then return end
			drag.moved = true
		end
		goal = clampAbs(startAbs + delta) - startAbs
		startStep()
	end))
	table.insert(conns, UIS.InputEnded:Connect(function(input)
		local d = drag.input
		if not d then return end
		local same
		if d.UserInputType == Enum.UserInputType.Touch then
			same = input == d
		else
			same = input.UserInputType == d.UserInputType
		end
		if not same then return end
		local wasDrag = drag.moved
		drag.input, drag.moved = nil, false
		if wasDrag then return end
		local now = os.clock()
		if now - lastTap < DOUBLE then
			lastTap = 0
			if opts.OnDoubleClick then opts.OnDoubleClick() end
			if opts.Home ~= false then
				stopStep()
				homeTween = TweenService:Create(target, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = home})
				homeTween:Play()
			end
		else
			lastTap = now
			if opts.OnClick then opts.OnClick() end
		end
	end))
	table.insert(conns, target:GetPropertyChangedSignal("Position"):Connect(function()
		if not drag.input then home = target.Position end
	end))

	local function cleanup()
		stopStep()
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)
	end
	handle.Destroying:Connect(cleanup)
	return cleanup
end

-- square checkerboard (alpha preview)
local function checker(parent, x, y, w, h, square, light, dark)
	local base = create("Frame", {
		Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = light or rgb(206, 206, 206), BorderSizePixel = 0, Parent = parent,
	})
	for row = 0, h / square - 1 do
		for col = 0, w / square - 1 do
			if (row + col) % 2 == 1 then
				create("Frame", {
					Size = UDim2.fromOffset(square, square), Position = UDim2.fromOffset(col * square, row * square),
					BackgroundColor3 = dark or rgb(132, 132, 132), BorderSizePixel = 0, Parent = base,
				})
			end
		end
	end
	return base
end

local function resolveParent(option)
	if typeof(option) == "Instance" then return option end
	if option == "PlayerGui" then return LocalPlayer:WaitForChild("PlayerGui") end
	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then
		local probe = Instance.new("ScreenGui")
		local placed = pcall(function() probe.Parent = core end)
		local good = placed and probe.Parent == core
		probe:Destroy()
		if good then return core end
	end
	if gethui then
		local ok2, hidden = pcall(gethui)
		if ok2 and typeof(hidden) == "Instance" then return hidden end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------------
-- classes
----------------------------------------------------------------------
local Window, Tab, Page, Section, Element, Link, Watermark, Item = {}, {}, {}, {}, {}, {}, {}, {}
Window.__index, Tab.__index, Page.__index, Section.__index = Window, Tab, Page, Section
Element.__index, Link.__index, Watermark.__index, Item.__index = Element, Link, Watermark, Item

local M = {W = 480, H = 338, Header = 36, Bottom = 35}
M.Body = M.H - M.Header - M.Bottom
local TAB_W = 102

----------------------------------------------------------------------
-- theme binding, accent tracking, animation
----------------------------------------------------------------------
-- Binds instance properties to theme tokens: W:_bind(frame, {BackgroundColor3 = "Card"})
function Window:_bind(object, map)
	self._bound[object] = self._bound[object] or {}
	for prop, token in pairs(map) do
		self._bound[object][prop] = token
		local value = self.Theme[token]
		if value then object[prop] = value end
	end
	return object
end

-- fn(theme, accent, alpha) runs now and on every theme or accent change
function Window:_track(fn)
	table.insert(self._refreshers, fn)
	pcall(fn, self.Theme, self.Accent, self.AccentAlpha)
	return fn
end

function Window:_untrack(fn)
	for index, f in ipairs(self._refreshers) do
		if f == fn then table.remove(self._refreshers, index) return end
	end
end

function Window:_restyle()
	for object, map in pairs(self._bound) do
		for prop, token in pairs(map) do
			local value = self.Theme[token]
			if value then pcall(function() object[prop] = value end) end
		end
	end
	for _, fn in ipairs(self._refreshers) do
		pcall(fn, self.Theme, self.Accent, self.AccentAlpha)
	end
end

function Window:_tween(object, props, time)
	if not self.Animations or not time or time <= 0 then
		for key, value in pairs(props) do object[key] = value end
		return nil
	end
	local tween = TweenService:Create(object, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

function Window:_connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(self._conns, connection)
	return connection
end

-- A themed label. Color is a token name ("Text", "TextSub", ...) or a Color3.
function Window:_label(parent, text, o)
	o = o or {}
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = o.Size or UDim2.new(1, 0, 1, 0),
		Position = o.Position or UDim2.new(),
		Text = text or "",
		TextSize = o.TextSize or 11,
		Weight = o.Weight or "Medium",
		TextXAlignment = o.Align or Enum.TextXAlignment.Left,
		TextYAlignment = o.AlignY or Enum.TextYAlignment.Center,
		TextWrapped = o.Wrap == true,
		AutomaticSize = o.AutoX and Enum.AutomaticSize.X or (o.AutoY and Enum.AutomaticSize.Y or Enum.AutomaticSize.None),
		Parent = parent,
	})
	if typeof(o.Color) == "Color3" then
		label.TextColor3 = o.Color
	else
		self:_bind(label, {TextColor3 = o.Color or "TextSub"})
	end
	return label
end

function Window:_icon(parent, names, size, position, token)
	local image = create("ImageLabel", {
		Size = UDim2.fromOffset(size, size), Position = position or UDim2.new(0, 0, 0.5, -size / 2),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Stretch, Parent = parent,
	})
	applyIcon(image, names)
	if typeof(token) == "Color3" then
		image.ImageColor3 = token
	elseif token == "Accent" then
		self:_track(function(_, accent, alpha) image.ImageColor3 = accent image.ImageTransparency = 1 - (alpha or 1) end)
	elseif token then
		self:_bind(image, {ImageColor3 = token})
	end
	return image
end

-- the Z logo, tinted by the accent
function Window:_zLogo(parent, size)
	local box = create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent})
	local function bar(s, p, rotation)
		return create("Frame", {Size = s, Position = p, Rotation = rotation or 0, BorderSizePixel = 0, Parent = box})
	end
	local parts = {
		bar(UDim2.new(0.84, 0, 0.19, 0), UDim2.new(0.08, 0, 0.08, 0)),
		bar(UDim2.new(1.04, 0, 0.19, 0), UDim2.new(-0.02, 0, 0.405, 0), -39),
		bar(UDim2.new(0.84, 0, 0.19, 0), UDim2.new(0.08, 0, 0.73, 0)),
	}
	self:_track(function(_, accent)
		for _, p in ipairs(parts) do p.BackgroundColor3 = accent end
	end)
	return box
end

----------------------------------------------------------------------
-- popups: one at a time, always inside the menu body, closed by an outside click
----------------------------------------------------------------------
function Window:_closePopup()
	for _, c in ipairs(self._popupConns) do c:Disconnect() end
	table.clear(self._popupConns)
	if self._popup then self._popup:Destroy() self._popup = nil end
	self._popupOwner = nil
	self._popupLayer.Visible = false
end

function Window:_openPopup(anchor, width, height, build)
	self:_closePopup()
	local scale = self.Scale.Scale
	local rel = (anchor.AbsolutePosition - self._main.AbsolutePosition) / scale
	local anchorH = anchor.AbsoluteSize.Y / scale
	local top, bottomLimit = M.Header + 4, M.H - M.Bottom - 4
	local y = rel.Y + anchorH + 4
	if y + height > bottomLimit then y = rel.Y - height - 4 end
	y = math.clamp(y, top, math.max(top, bottomLimit - height))
	local x = math.clamp(rel.X, 6, M.W - width - 6)

	self._popupLayer.Visible = true
	local frame = self:_bind(create("Frame", {
		Size = UDim2.fromOffset(width, height), Position = UDim2.fromOffset(x, y),
		ClipsDescendants = true, BorderSizePixel = 0, ZIndex = 35, Active = true, Corner = 5,
		Stroke = {Thickness = 1}, Parent = self._popupLayer,
	}), {BackgroundColor3 = "Popup"})
	self._popup = frame
	build(frame)
end

----------------------------------------------------------------------
-- navigation: tabs, sub-tabs, settings
----------------------------------------------------------------------
function Window:_renderNav()
	for _, tab in ipairs(self._tabs) do
		local active = tab == self._activeTab
		self:_tween(tab._tile, {BackgroundTransparency = active and 0 or 1, Size = active and UDim2.fromOffset(94, 27) or UDim2.fromOffset(80, 23)}, 0.2)
		self:_tween(tab._label, {TextColor3 = active and self.Theme.Text or self.Theme.Nav}, 0.2)
		if tab._icon then tab._icon.ImageColor3 = active and self.Accent or self.Theme.Nav end
	end
	local settingsActive = self._current ~= nil and self._current.IsSettings
	self:_tween(self._gear, {BackgroundTransparency = settingsActive and 0 or 1}, 0.2)

	for _, ch in ipairs(self._subHolder:GetChildren()) do
		if ch:IsA("GuiObject") then ch:Destroy() end
	end
	local tab = self._activeTab
	if not tab or #tab.Pages < 2 then return end
	for index, page in ipairs(tab.Pages) do
		local active = page == self._current
		local button = create("TextButton", {
			Size = active and UDim2.new(0, 0, 0, 26) or UDim2.fromOffset(26, 26),
			AutomaticSize = active and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
			BackgroundTransparency = active and 0 or 1, Text = "", AutoButtonColor = false,
			LayoutOrder = index, Corner = 5, Parent = self._subHolder,
		})
		self:_bind(button, {BackgroundColor3 = "Tile"})
		if active then
			create("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 8), Parent = button})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = button,
			})
			self:_icon(button, page.Icon or {"circle"}, 12, nil, "Accent").LayoutOrder = 1
			self:_label(button, page.Name, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = "Text"}).LayoutOrder = 2
		else
			self:_icon(button, page.Icon or {"circle"}, 12, UDim2.new(0.5, -6, 0.5, -6), "Nav")
		end
		button.MouseButton1Click:Connect(function() self:Navigate(page) end)
	end
end

-- Page switch: the body fades out, the new page slides up while the fader dissolves in.
function Window:_showPage(page, animate)
	self._switchToken = self._switchToken + 1
	local token = self._switchToken
	for _, t in ipairs(self._tweens) do t:Cancel() end
	table.clear(self._tweens)

	local function swap()
		for _, p in ipairs(self._pages) do
			if p ~= page then p.Scroll.Visible = false end
		end
		page.Scroll.CanvasPosition = Vector2.new(0, 0)
		page.Scroll.Visible = true
		if animate and self.Animations then
			page.Scroll.Position = UDim2.fromOffset(0, M.Header + 12)
			self._fader.BackgroundTransparency = 0
			table.insert(self._tweens, self:_tween(page.Scroll, {Position = UDim2.fromOffset(0, M.Header)}, 0.34))
			table.insert(self._tweens, self:_tween(self._fader, {BackgroundTransparency = 1}, 0.28))
		else
			page.Scroll.Position = UDim2.fromOffset(0, M.Header)
			self._fader.BackgroundTransparency = 1
		end
		self:_updateBar()
	end

	if not animate or not self.Animations then
		swap()
		return
	end
	local out = self:_tween(self._fader, {BackgroundTransparency = 0}, 0.09)
	if out then
		out.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and token == self._switchToken then swap() end
		end)
	else
		swap()
	end
end

-- Navigate(page) shows a page (a Tab's page, or the settings page).
function Window:Navigate(page)
	if not page or page == self._current then return end
	self._touched = true
	local animate = self._current ~= nil
	self._current = page
	self._activeTab = page.Tab
	if page.Tab then page.Tab._active = page end
	self:_renderNav()
	self:_showPage(page, animate)
end

function Window:Settings()
	return self._settings
end

----------------------------------------------------------------------
-- shared scrollbar (drawn by the library, follows the current page)
----------------------------------------------------------------------
local TRACK_TOP, TRACK_BOTTOM = 9, 10
local function trackLength() return M.Body - TRACK_TOP - TRACK_BOTTOM end

function Window:_updateBar()
	local page = self._current
	local scroll = page and page.Scroll
	local scale = math.max(self.Scale.Scale, 0.01)
	local canvas = (scroll and scroll.Visible) and (scroll.AbsoluteCanvasSize.Y / scale) or 0
	local maxScroll = canvas - M.Body
	self._bar.Visible = scroll ~= nil and scroll.Visible and maxScroll > 1
	if not self._bar.Visible then return end
	local width = self.BarW
	local length = trackLength()
	self._bar.Size = UDim2.fromOffset(width + 8, length)
	self._bar.Position = UDim2.fromOffset(M.W - 8 - width - 4, M.Header + TRACK_TOP)
	self._barTrack.Size = UDim2.new(0, width, 1, 0)
	self._barTrack.Position = UDim2.fromOffset(4, 0)
	local thumbLength = math.clamp(length * M.Body / canvas, 20, length)
	local fraction = math.clamp(scroll.CanvasPosition.Y / maxScroll, 0, 1)
	self._barThumb.Size = UDim2.new(1, 0, 0, thumbLength)
	self._barThumb.Position = UDim2.fromOffset(0, fraction * (length - thumbLength))
end

function Window:_scrollFromMouse(mouseY)
	local page = self._current
	if not page then return end
	local scale = math.max(self.Scale.Scale, 0.01)
	local canvas = page.Scroll.AbsoluteCanvasSize.Y / scale
	local maxScroll = canvas - M.Body
	if maxScroll <= 1 then return end
	local thumbLength = self._barThumb.AbsoluteSize.Y / scale
	local travel = trackLength() - thumbLength
	if travel <= 0 then return end
	local top = (mouseY - self._bar.AbsolutePosition.Y) / scale - self._grab
	page.Scroll.CanvasPosition = Vector2.new(0, math.clamp(top / travel, 0, 1) * maxScroll)
	self:_updateBar()
end

----------------------------------------------------------------------
-- flags, config, toggling
----------------------------------------------------------------------
function Window:Get(flag)
	local element = self._elements[flag]
	if element then return element.Value end
	return self.Flags[flag]
end

function Window:Set(flag, value)
	local element = self._elements[flag]
	if element then element:Set(value) return true end
	return false
end

function Window:GetConfig()
	local config = {}
	for flag, element in pairs(self._elements) do
		if element._encode then config[flag] = element:_encode() end
	end
	return config
end

-- silent = true: applies the values without firing callbacks
function Window:SetConfig(config, silent)
	for flag, raw in pairs(config or {}) do
		local element = self._elements[flag]
		if element and element._decode then
			local results = {pcall(element._decode, raw)}
			if results[1] and results[2] ~= nil then
				if silent then element:SetSilently(results[2], results[3]) else element:Set(results[2], results[3]) end
			end
		end
	end
end

function Window:Save(name)
	if not writefile then return false end
	if makefolder and isfolder and not isfolder(Zenin.ConfigFolder) then pcall(makefolder, Zenin.ConfigFolder) end
	return (pcall(writefile, Zenin.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(self:GetConfig())))
end

function Window:Load(name)
	if not (readfile and isfile) then return false end
	local path = Zenin.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, config = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if ok and type(config) == "table" then self:SetConfig(config) return true end
	return false
end

function Window:ListConfigs()
	local names = {}
	if listfiles and isfolder and isfolder(Zenin.ConfigFolder) then
		for _, path in ipairs(listfiles(Zenin.ConfigFolder)) do
			local name = string.match(path, "([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	end
	return names
end

function Window:SetVisible(state)
	self._holder.Visible = state == true
	if not state then self:_closePopup() end
	for _, fn in ipairs(self._toggleListeners) do pcall(fn, state == true) end
end

function Window:Show() self:SetVisible(true) end
function Window:Hide() self:SetVisible(false) end
function Window:IsVisible() return self._holder.Visible end
function Window:Toggle() self:SetVisible(not self._holder.Visible) end

-- fn(visible) on every show / hide (menu key, watermark, Show/Hide)
function Window:OnToggle(fn)
	table.insert(self._toggleListeners, fn)
	return function()
		for index, f in ipairs(self._toggleListeners) do
			if f == fn then table.remove(self._toggleListeners, index) break end
		end
	end
end

function Window:SetToggleKey(keyCode)
	self.ToggleKey = keyCode
	return self
end

----------------------------------------------------------------------
-- appearance
----------------------------------------------------------------------
function Window:SetTheme(name)
	local theme = Themes[name]
	if not theme then return false end
	self.ThemeName = name
	self.Theme = theme
	self:_closePopup()
	self:_restyle()
	return true
end

function Window:SetAccent(color, alpha)
	self.Accent = color
	if alpha then self.AccentAlpha = math.clamp(alpha, 0, 1) end
	self:_restyle()
	return self
end

function Window:GetAccent()
	return self.Accent, self.AccentAlpha
end

function Window:SetScale(scale, animate)
	self.Scale.Scale = scale
	self:_updateBar()
	return self
end

function Window:SetScrollbarSize(size)
	self.BarW = math.clamp(math.floor(size + 0.5), 1, 14)
	self:_updateBar()
	return self
end

function Window:SetAnimations(state)
	self.Animations = state == true
	return self
end

function Window:SetMouseWheel(state)
	self.MouseWheel = state == true
	for _, page in ipairs(self._pages) do page.Scroll.ScrollingEnabled = self.MouseWheel end
	return self
end

-- A small button in the header, to the left of the settings gear.
function Window:HeaderButton(o)
	o = o or {}
	local button = create("TextButton", {
		Size = UDim2.fromOffset(26, 27), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		LayoutOrder = #self._headerButtons + 1, Corner = 5, Parent = self._headerRight,
	})
	self:_bind(button, {BackgroundColor3 = "Tile"})
	self:_icon(button, o.Icon or {"circle"}, 12, UDim2.new(0.5, -6, 0.5, -6), "Nav")
	button.MouseButton1Click:Connect(function() if o.Callback then o.Callback(self) end end)
	table.insert(self._headerButtons, button)
	self:_layoutHeader()
	return {Button = button, Destroy = function() button:Destroy() self:_layoutHeader() end}
end

function Window:_layoutHeader()
	local count = #self._headerButtons + 1 -- + gear
	self._headerRight.Size = UDim2.fromOffset(count * 31 - 5, 27)
	self._subHolder.Position = UDim2.new(0, M.W - 8 - count * 31 - 6, 0.5, 0)
end

----------------------------------------------------------------------
-- notifications
----------------------------------------------------------------------
function Window:Notify(o)
	o = o or {}
	local note = {}
	local frame = self:_bind(create("Frame", {
		Size = UDim2.fromOffset(252, 50), Position = UDim2.new(1, 20, 0, 14),
		BorderSizePixel = 0, ZIndex = 5, Corner = 7, Stroke = {Thickness = 1}, Parent = self._notifyGui,
	}), {BackgroundColor3 = "Card"})
	local bar = create("Frame", {Size = UDim2.fromOffset(3, 26), Position = UDim2.fromOffset(8, 12), BorderSizePixel = 0, Corner = 2, Parent = frame})
	self:_track(function(_, accent) bar.BackgroundColor3 = o.Color or accent end)
	self:_label(frame, o.Title or "Zenin", {Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -28, 0, 14), Color = "Text", Weight = "SemiBold"})
	self:_label(frame, o.Text or "", {Position = UDim2.fromOffset(20, 24), Size = UDim2.new(1, -28, 0, 16), Color = "TextSub"})
	note.Frame = frame
	table.insert(self._notes, note)
	local function reflow()
		for index, n in ipairs(self._notes) do
			self:_tween(n.Frame, {Position = UDim2.new(1, -262, 0, 14 + (index - 1) * 58)}, 0.25)
		end
	end
	reflow()
	local function dismiss()
		for index, n in ipairs(self._notes) do
			if n == note then table.remove(self._notes, index) break end
		end
		local out = self:_tween(frame, {Position = UDim2.new(1, 20, 0, frame.Position.Y.Offset)}, 0.2)
		if out then out.Completed:Connect(function() frame:Destroy() end) else frame:Destroy() end
		reflow()
	end
	task.delay(o.Duration or 3, dismiss)
	return {Dismiss = dismiss}
end

----------------------------------------------------------------------
-- window shell: header, bottom navigation, layers
----------------------------------------------------------------------
function Window:_buildShell()
	self._holder = create("Frame", {
		Name = "Holder", Size = UDim2.fromOffset(M.W, M.H), Position = UDim2.new(0.5, -M.W / 2, 0.5, -M.H / 2),
		BackgroundTransparency = 1, Parent = self._gui,
	})
	self.Scale = create("UIScale", {Scale = self._initialScale or 1, Parent = self._holder})
	self._main = create("Frame", {Name = "Main", Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, Active = true, Corner = 8, Parent = self._holder})
	self:_bind(self._main, {BackgroundColor3 = "Window"})

	-- header: rounded top, flat bottom, accent wash on the left under the logo
	local header = create("Frame", {Name = "Header", Size = UDim2.new(1, 0, 0, M.Header), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true, ZIndex = 8, Corner = 8, Parent = self._main})
	local headerFill = create("Frame", {Size = UDim2.new(1, 0, 0, M.Header / 2), Position = UDim2.new(0, 0, 0, M.Header / 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = header})
	local gradients = {create("UIGradient", {Parent = header}), create("UIGradient", {Parent = headerFill})}
	self:_track(function(theme, accent, alpha)
		local seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Bar:Lerp(accent, 0.07 * (alpha or 1))),
			ColorSequenceKeypoint.new(0.16, theme.Bar),
			ColorSequenceKeypoint.new(1, theme.Bar),
		})
		for _, g in ipairs(gradients) do g.Color = seq end
	end)
	self:_bind(self._bindHeaderMask or create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, Parent = header}), {BackgroundColor3 = "BarLine"})
	self._header = header
	makeDraggable(header, self._holder, {Home = true})

	local titleX = 10
	if self._logo then
		local logo = self:_zLogo(header, 10)
		logo.Position = UDim2.fromOffset(10, 13)
		titleX = 26
	end
	self:_label(header, self.Title, {Position = UDim2.fromOffset(titleX, 0), Size = UDim2.new(0, 220, 1, 0), Color = "Text", Weight = "SemiBold"})

	-- right side: custom header buttons, then the settings gear (always last)
	self._headerRight = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(26, 27), BackgroundTransparency = 1, Parent = header})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = self._headerRight})
	self._gear = create("TextButton", {Size = UDim2.fromOffset(26, 27), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 999, Corner = 5, Parent = self._headerRight})
	self:_bind(self._gear, {BackgroundColor3 = "Tile"})
	self:_icon(self._gear, {"settings", "cog"}, 12, UDim2.new(0.5, -6, 0.5, -6), "Nav")
	self._gear.MouseButton1Click:Connect(function() self:Navigate(self._settings) end)

	-- sub-tabs, right aligned left of the buttons
	self._subHolder = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0, M.W - 42, 0.5, 0), Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = header})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = self._subHolder})

	-- bottom bar with the main tabs
	local bottom = create("Frame", {Name = "Bottom", Size = UDim2.new(1, 0, 0, M.Bottom), Position = UDim2.new(0, 0, 1, -M.Bottom), BorderSizePixel = 0, ZIndex = 10, Corner = 8, Parent = self._main})
	self:_bind(bottom, {BackgroundColor3 = "Bar"})
	self:_bind(create("Frame", {Size = UDim2.new(1, 0, 0, M.Bottom / 2), BorderSizePixel = 0, Parent = bottom}), {BackgroundColor3 = "Bar"})
	self:_bind(create("Frame", {Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = bottom}), {BackgroundColor3 = "BarLine"})
	self._navHolder = create("Frame", {Size = UDim2.new(0, 408, 1, 0), Position = UDim2.new(0.5, -204, 0, 0), BackgroundTransparency = 1, Parent = bottom})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._navHolder})

	-- soft fade above the bottom bar
	local fade = create("Frame", {Size = UDim2.new(1, 0, 0, 41), Position = UDim2.fromOffset(0, M.Header + M.Body - 41), BorderSizePixel = 0, ZIndex = 6, Parent = self._main})
	self:_bind(fade, {BackgroundColor3 = "Window"})
	create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.85, 0.08), NumberSequenceKeypoint.new(1, 0),
	}), Parent = fade})

	-- fader covers the body during page changes
	self._fader = create("Frame", {Size = UDim2.new(1, 0, 0, M.Body), Position = UDim2.fromOffset(0, M.Header), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4, Parent = self._main})
	self:_bind(self._fader, {BackgroundColor3 = "Window"})

	-- popup layer (ZIndex 30) with an outside-click catcher
	self._popupLayer = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 30, Parent = self._main})
	local outside = create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 30, Parent = self._popupLayer})
	outside.MouseButton1Click:Connect(function() self:_closePopup() end)

	-- the scrollbar (ZIndex 7-8, above pages and fade)
	self._bar = create("Frame", {BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 7, Parent = self._main})
	self._barTrack = create("Frame", {BorderSizePixel = 0, ZIndex = 7, Parent = self._bar})
	self:_bind(self._barTrack, {BackgroundColor3 = "ScrollTrack"})
	self._barThumb = create("Frame", {BorderSizePixel = 0, ZIndex = 8, Parent = self._barTrack})
	self:_bind(self._barThumb, {BackgroundColor3 = "ScrollThumb"})
	self:_connect(self._bar.InputBegan, function(input)
		if not isClick(input) then return end
		local scale = math.max(self.Scale.Scale, 0.01)
		local ty, th = self._barThumb.AbsolutePosition.Y, self._barThumb.AbsoluteSize.Y
		if input.Position.Y >= ty and input.Position.Y <= ty + th then
			self._dragging = true
			self._grab = (input.Position.Y - ty) / scale
			self:_scrollFromMouse(input.Position.Y)
		else
			local page = self._current
			local maxScroll = page and (page.Scroll.AbsoluteCanvasSize.Y / scale - M.Body) or 0
			if maxScroll > 1 then
				local dir = input.Position.Y < ty and -1 or 1
				local target = math.clamp(page.Scroll.CanvasPosition.Y + dir * M.Body * 0.9, 0, maxScroll)
				self:_tween(page.Scroll, {CanvasPosition = Vector2.new(0, target)}, 0.18)
			end
		end
	end)
	self:_connect(UIS.InputChanged, function(input)
		if self._dragging and isMove(input) then self:_scrollFromMouse(input.Position.Y) end
	end)
	self:_connect(UIS.InputEnded, function(input)
		if self._dragging and isClick(input) then self._dragging = false end
	end)
end

----------------------------------------------------------------------
-- tabs and pages
----------------------------------------------------------------------
function Window:Tab(o)
	o = o or {}
	local index = #self._tabs + 1
	local button = create("TextButton", {Size = UDim2.new(0, TAB_W, 1, 0), BackgroundTransparency = 1, Text = "", LayoutOrder = index, Parent = self._navHolder})
	local tile = self:_bind(create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(80, 23), BackgroundTransparency = 1, BorderSizePixel = 0, Corner = 5, Parent = button}), {BackgroundColor3 = "Tile"})
	local content = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = button})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = content})
	local tab = setmetatable({Window = self, Name = o.Name or ("Tab " .. index), Icon = o.Icon, Pages = {}, _tile = tile, _button = button}, Tab)
	tab._icon = self:_icon(content, o.Icon or {"circle"}, 12, nil, nil)
	tab._icon.LayoutOrder = 1
	tab._label = self:_label(content, tab.Name, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = "Nav"})
	tab._label.LayoutOrder = 2
	button.MouseButton1Click:Connect(function()
		self:Navigate(tab._active or tab.Pages[1])
	end)
	table.insert(self._tabs, tab)
	return tab
end

function Tab:Page(o)
	o = o or {}
	local W = self.Window
	local page = W:_newPage(self, o.Name or ("Page " .. (#self.Pages + 1)), o.Icon)
	table.insert(self.Pages, page)
	-- the first page of the first tab opens by itself, until the user picks something
	if W._current == nil or (W._current.IsSettings and not W._touched) then
		W:Navigate(page)
		W._touched = false
	end
	return page
end

-- Shortcut: a tab with one page, straight to a section.
function Tab:Section(o)
	if #self.Pages == 0 then self:Page({Name = self.Name, Icon = self.Icon}) end
	return self.Pages[1]:Section(o)
end

function Window:_newPage(tab, name, icon)
	local page = setmetatable({Window = self, Tab = tab, Name = name, Icon = icon, Sections = {}, _order = 0}, Page)
	page.Scroll = create("ScrollingFrame", {
		Size = UDim2.fromOffset(M.W, M.Body), Position = UDim2.fromOffset(0, M.Header), BackgroundTransparency = 1, BorderSizePixel = 0,
		ZIndex = 2, ScrollBarThickness = 0, ScrollBarImageTransparency = 1, TopImage = "", MidImage = "", BottomImage = "",
		VerticalScrollBarInset = Enum.ScrollBarInset.None, ScrollingEnabled = self.MouseWheel, ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false, Parent = self._main,
	})
	page.Container = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page.Scroll})
	create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), Parent = page.Container})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 9), VerticalAlignment = Enum.VerticalAlignment.Top, Parent = page.Container})
	page.Columns = {}
	for index, side in ipairs({"Left", "Right"}) do
		local column = create("Frame", {Name = side, Size = UDim2.new(0.5, -4.5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = index, Parent = page.Container})
		create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 9), Parent = column})
		page.Columns[side] = column
	end
	table.insert(self._pages, page)
	self:_connect(page.Scroll:GetPropertyChangedSignal("CanvasPosition"), function() if self._current == page then self:_updateBar() end end)
	self:_connect(page.Scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"), function() if self._current == page then self:_updateBar() end end)
	return page
end

-- Pages can also be reached by name: Win:Page("Combat/Aimbot")
function Window:Page(path)
	for _, tab in ipairs(self._tabs) do
		for _, page in ipairs(tab.Pages) do
			if tab.Name .. "/" .. page.Name == path or page.Name == path then return page end
		end
	end
	if path == "Settings" then return self._settings end
	return nil
end

----------------------------------------------------------------------
-- sections: cards that stack by themselves (no manual heights)
----------------------------------------------------------------------
function Page:Section(o)
	o = o or {}
	local W = self.Window
	local column = self.Columns[o.Side == "Right" and "Right" or "Left"]
	self._order = self._order + 1
	local card = W:_bind(create("Frame", {
		Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
		LayoutOrder = self._order, Corner = 6, Parent = column,
	}), {BackgroundColor3 = "Card"})
	create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9), Parent = card})
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
	if o.Name then
		W:_label(card, o.Name, {Size = UDim2.new(1, 0, 0, 14), Color = "Text", Weight = "SemiBold", LayoutOrder = 0})
	end
	local content = create("Frame", {Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
	create("UIPadding", {PaddingTop = UDim.new(0, 7), Parent = content})
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = content})
	local section = setmetatable({Window = W, Page = self, Name = o.Name, Frame = card, _content = content, _order = 0, _elements = {}}, Section)
	table.insert(self.Sections, section)
	return section
end

function Section:_row(height)
	self._order = self._order + 1
	return create("Frame", {Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = self._order, Parent = self._content})
end

function Section:Remove()
	for _, element in ipairs(self._elements) do element:Destroy() end
	self.Frame:Destroy()
end

----------------------------------------------------------------------
-- element base: one class for every control, with a uniform API
--   :Set(value, extra)   fires the callback      :SetSilently(value)   does not
--   :Get()  :SetEnabled(b)  :SetVisible(b)  :OnChanged(fn)  :Destroy()
----------------------------------------------------------------------
local function indexOf(list, value)
	for index, item in ipairs(list) do
		if item == value then return index end
	end
	return nil
end

local function newElement(section, kind, o, root)
	local el = setmetatable({
		Window = section.Window, Section = section, Kind = kind, Name = o.Name, Flag = o.Flag, Root = root,
		Value = nil, Alpha = nil, _enabled = true, _visible = true, _listeners = {},
		_callback = o.Callback, _ready = false,
	}, Element)
	if el.Flag then
		assert(section.Window._elements[el.Flag] == nil, "Zenin: duplicate flag '" .. tostring(el.Flag) .. "'")
		section.Window._elements[el.Flag] = el
	end
	table.insert(section._elements, el)
	return el
end

function Element:_update(fire, value, extra)
	if self._apply then self._apply(value, extra) end
	if self.Flag then self.Window.Flags[self.Flag] = self.Value end
	if self._paint then self._paint(self._ready) end
	if fire then self:_fire(self.Value, self.Alpha) end
	return self
end

function Element:_finish(value, extra)
	self:_update(false, value, extra)
	self._ready = true
	self._refresh = self.Window:_track(function()
		if self._paint then self._paint(false) end
	end)
	return self
end

function Element:_fire(a, b)
	if self._callback then
		local ok, err = pcall(self._callback, a, b)
		if not ok then warn("[Zenin] " .. tostring(self.Name) .. ": " .. tostring(err)) end
	end
	for _, fn in ipairs(self._listeners) do
		pcall(fn, a, b)
	end
end

function Element:Set(value, extra) return self:_update(true, value, extra) end
function Element:SetSilently(value, extra) return self:_update(false, value, extra) end
function Element:Get() return self.Value end

function Element:SetName(text)
	self.Name = text
	if self._nameLabel then self._nameLabel.Text = text end
	return self
end

function Element:SetEnabled(state)
	self._enabled = state == true
	if self._paint then self._paint(self._ready) end
	return self
end

function Element:SetVisible(state)
	self._visible = state == true
	self.Root.Visible = self._visible
	return self
end

function Element:OnChanged(fn)
	table.insert(self._listeners, fn)
	return function()
		local index = indexOf(self._listeners, fn)
		if index then table.remove(self._listeners, index) end
	end
end

function Element:Destroy()
	if self._refresh then self.Window:_untrack(self._refresh) end
	if self.Flag and self.Window._elements[self.Flag] == self then
		self.Window._elements[self.Flag] = nil
		self.Window.Flags[self.Flag] = nil
	end
	local index = indexOf(self.Section._elements, self)
	if index then table.remove(self.Section._elements, index) end
	self.Root:Destroy()
end

----------------------------------------------------------------------
-- controls
----------------------------------------------------------------------
function Section:_nextOrder()
	self._order = self._order + 1
	return self._order
end

-- Toggle: Set(true / false)
function Section:Toggle(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(21)
	local label = W:_label(row, o.Name or "Toggle", {Size = UDim2.new(0.75, 0, 1, 0)})
	local switch = create("TextButton", {Size = UDim2.fromOffset(26, 14), Position = UDim2.new(1, -26, 0.5, -7), Text = "", AutoButtonColor = false, Corner = 7, Parent = row})
	local dot = create("Frame", {Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Corner = 4, Parent = switch})
	local el = newElement(self, "Toggle", o, row)
	el._nameLabel = label
	el._apply = function(value) el.Value = value == true end
	el._paint = function(animate)
		local t = animate and 0.14 or 0
		local on, enabled = el.Value == true, el._enabled
		if on then
			W:_tween(switch, {BackgroundColor3 = W.Accent, BackgroundTransparency = 1 - W.AccentAlpha * (enabled and 1 or 0.45)}, t)
			W:_tween(dot, {Position = UDim2.new(1, -11, 0.5, -4), BackgroundColor3 = Color3.new(1, 1, 1)}, t)
		else
			W:_tween(switch, {BackgroundColor3 = enabled and W.Theme.ToggleOff or W.Theme.ToggleOffDisabled, BackgroundTransparency = 0}, t)
			W:_tween(dot, {Position = UDim2.new(0, 3, 0.5, -4), BackgroundColor3 = enabled and W.Theme.ToggleDot or W.Theme.ToggleDotDisabled}, t)
		end
		label.TextColor3 = (not enabled) and W.Theme.TextDim or (on and W.Theme.Text or W.Theme.TextSub)
	end
	el._encode = function() return el.Value end
	el._decode = function(raw) return raw == true end
	switch.MouseButton1Click:Connect(function()
		if el._enabled then el:Set(not el.Value) end
	end)
	return el:_finish(o.Default == true)
end

-- Slider: Min, Max, Step, Decimals, Suffix, Default
function Section:Slider(o)
	o = o or {}
	local W = self.Window
	local minV, maxV = o.Min or 0, o.Max or 100
	local step = o.Step or 1
	local decimals = o.Decimals or (step < 1 and 2 or 0)
	local suffix = o.Suffix or ""
	local R = 5.5
	local row = self:_row(28)
	local label = W:_label(row, o.Name or "Slider", {Size = UDim2.new(0.65, 0, 0, 15), Color = "TextSub"})
	local valueLabel = W:_label(row, "", {Position = UDim2.new(0.65, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 15), Align = Enum.TextXAlignment.Right, Color = "TextSub"})
	local hit = create("Frame", {Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 12.5), BackgroundTransparency = 1, Active = true, Parent = row})
	local track = create("Frame", {Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BorderSizePixel = 0, Corner = 2, Parent = hit})
	W:_bind(track, {BackgroundColor3 = "Track"})
	local fill = create("Frame", {BorderSizePixel = 0, Corner = 2, Parent = track})
	local knob = create("Frame", {Size = UDim2.fromOffset(7, 7), BorderSizePixel = 0, ZIndex = 3, Corner = 4, Parent = track})
	W:_bind(knob, {BackgroundColor3 = "Knob"})
	local ring = create("UIStroke", {Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = knob})

	local el = newElement(self, "Slider", o, row)
	el._nameLabel = label
	local function layout(p)
		fill.Size = UDim2.new(p, R * (1 - 2 * p), 1, 0)
		knob.Position = UDim2.new(p, R * (1 - 2 * p) - 3.5, 0.5, -3.5)
	end
	el._apply = function(value)
		local v = math.floor((tonumber(value) or minV) / step + 0.5) * step
		v = math.clamp(v, minV, maxV)
		el.Value = v
		layout((v - minV) / (maxV - minV))
		valueLabel.Text = string.format("%." .. decimals .. "f", v) .. suffix
	end
	el._paint = function()
		local enabled = el._enabled
		label.TextColor3 = enabled and W.Theme.TextSub or W.Theme.TextDim
		valueLabel.TextColor3 = enabled and W.Theme.TextSub or W.Theme.TextDim
		fill.BackgroundColor3 = W.Accent
		fill.BackgroundTransparency = 1 - W.AccentAlpha * (enabled and 1 or 0.45)
		ring.Color = enabled and W.Theme.KnobRing or W.Theme.KnobRingOff
	end
	el._encode = function() return el.Value end
	el._decode = function(raw) return tonumber(raw) end

	local dragging = false
	local function valueAt(x)
		local sc = W.Scale.Scale
		local left = track.AbsolutePosition.X + R * sc
		local width = track.AbsoluteSize.X - 2 * R * sc
		local p = width > 0 and math.clamp((x - left) / width, 0, 1) or 0
		return minV + (maxV - minV) * p
	end
	hit.InputBegan:Connect(function(input)
		if el._enabled and isClick(input) then
			dragging = true
			el:Set(valueAt(input.Position.X))
		end
	end)
	W:_connect(UIS.InputChanged, function(input)
		if dragging and isMove(input) then el:Set(valueAt(input.Position.X)) end
	end)
	W:_connect(UIS.InputEnded, function(input)
		if isClick(input) then dragging = false end
	end)
	return el:_finish(o.Default or minV)
end

-- Dropdown: Options, Default, Multi = true for several choices, Icon
function Section:Dropdown(o)
	o = o or {}
	local W = self.Window
	local multi = o.Multi == true
	local options = o.Options or {}
	local row = self:_row(25)
	local labelX = o.Icon and 14 or 0
	local label = W:_label(row, o.Name or "Dropdown", {Position = UDim2.fromOffset(labelX, 0), Size = UDim2.new(0.5, -labelX, 1, 0)})
	if o.Icon then W:_icon(row, o.Icon, 12, UDim2.new(0, -1.5, 0.5, -6), "TextSub") end
	local button = create("TextButton", {Size = UDim2.new(0.5, 0, 0, 25), Position = UDim2.new(0.5, 0, 0, 0), Text = "", AutoButtonColor = false, Corner = 5, Parent = row})
	W:_bind(button, {BackgroundColor3 = "Field"})
	local outline = create("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button})
	local valueLabel = W:_label(button, "", {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -24, 1, 0), Color = "Text"})
	local chevron = W:_icon(button, {"chevron-down"}, 12, UDim2.new(1, -17, 0.5, -6), "TextSub")

	local el = newElement(self, "Dropdown", o, row)
	el._nameLabel = label
	el.Options = options
	local function isSelected(option)
		if multi then return indexOf(el.Value or {}, option) ~= nil end
		return el.Value == option
	end
	local function displayText()
		if not multi then return tostring(el.Value or "") end
		local list = el.Value or {}
		if #list == 0 then return "None" end
		if #list == 1 then return list[1] end
		return list[1] .. " +" .. (#list - 1)
	end
	el._apply = function(value)
		if multi then
			local wanted, list = {}, {}
			if type(value) == "table" then
				for _, v in ipairs(value) do wanted[v] = true end
			end
			for _, option in ipairs(options) do
				if wanted[option] then table.insert(list, option) end
			end
			el.Value = list
		else
			local chosen = value
			if chosen == nil or indexOf(options, chosen) == nil then chosen = el.Value or options[1] end
			el.Value = chosen
		end
	end
	el._paint = function()
		local enabled = el._enabled
		valueLabel.Text = displayText()
		valueLabel.TextColor3 = enabled and W.Theme.Text or W.Theme.Disabled
		label.TextColor3 = enabled and W.Theme.TextSub or W.Theme.TextDim
		outline.Color = enabled and W.Theme.FieldBorder or W.Theme.DisabledBorder
		chevron.ImageColor3 = enabled and W.Theme.TextSub or W.Theme.TextDim
	end
	el._encode = function() return el.Value end
	el._decode = function(raw) return raw end

	button.MouseButton1Click:Connect(function()
		if not el._enabled then return end
		if W._popupOwner == el then W:_closePopup() return end
		W:_closePopup()
		W._popupOwner = el
		local height = math.min(#options * 21 + 8, 176)
		W:_openPopup(button, button.AbsoluteSize.X / math.max(W.Scale.Scale, 0.01), height, function(frame)
			local list = create("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
				CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
			})
			create("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = list})
			create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})
			local rows = {}
			local function refreshRows()
				for option, r in pairs(rows) do
					local on = isSelected(option)
					r.Check.Visible = on
					r.Text.TextColor3 = on and W.Accent or W.Theme.Text
				end
			end
			for index, option in ipairs(options) do
				local item = create("TextButton", {Size = UDim2.new(1, 0, 0, 21), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = index, Parent = list})
				local text = W:_label(item, option, {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -24, 1, 0), Color = "Text"})
				local check = W:_icon(item, {"check"}, 12, UDim2.new(1, -18, 0.5, -6), "Accent")
				rows[option] = {Text = text, Check = check}
				item.MouseButton1Click:Connect(function()
					if multi then
						local copy = {}
						for _, v in ipairs(el.Value or {}) do table.insert(copy, v) end
						local at = indexOf(copy, option)
						if at then table.remove(copy, at) else table.insert(copy, option) end
						el:Set(copy)
						refreshRows()
					else
						el:Set(option)
						W:_closePopup()
					end
				end)
			end
			refreshRows()
		end)
	end)
	return el:_finish(o.Default)
end

-- ColorPicker: Default (Color3), Alpha (0..1), popup with SV / hue / alpha / hex
function Section:ColorPicker(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(25)
	W:_icon(row, {"palette"}, 12, UDim2.new(0, -1.5, 0.5, -6), "TextSub")
	local label = W:_label(row, o.Name or "Color", {Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.7, -14, 1, 0)})
	local swatch = create("TextButton", {Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -18, 0.5, -9), Text = "", AutoButtonColor = false, Corner = 9, Parent = row})

	local el = newElement(self, "ColorPicker", o, row)
	el._nameLabel = label
	el._apply = function(color, alpha)
		if typeof(color) == "Color3" then el.Value = color end
		if el.Value == nil then el.Value = W.Accent end
		if alpha ~= nil then el.Alpha = math.clamp(alpha, 0, 1) end
		if el.Alpha == nil then el.Alpha = 1 end
	end
	el._paint = function()
		swatch.BackgroundColor3 = el.Value
		swatch.BackgroundTransparency = 1 - (el.Alpha or 1) * (el._enabled and 1 or 0.45)
		label.TextColor3 = el._enabled and W.Theme.TextSub or W.Theme.TextDim
	end
	el._encode = function()
		return {el.Value.R, el.Value.G, el.Value.B, el.Alpha}
	end
	el._decode = function(raw)
		if type(raw) ~= "table" then return nil end
		return Color3.new(raw[1], raw[2], raw[3]), raw[4]
	end

	swatch.MouseButton1Click:Connect(function()
		if not el._enabled then return end
		if W._popupOwner == el then W:_closePopup() return end
		W:_closePopup()
		W._popupOwner = el
		W:_openPopup(swatch, 208, 184, function(frame)
			local SV, BW, BH, HX, AX = 144, 16, 144, 160, 184
			local h, s, v = el.Value:ToHSV()
			local a = 1 - (el.Alpha or 1)

			local svBox = create("Frame", {Size = UDim2.fromOffset(SV, SV), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = frame})
			local white = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = svBox})
			create("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = white})
			local black = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3, Parent = svBox})
			create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}), Parent = black})
			local cursor = create("Frame", {Size = UDim2.fromOffset(9, 9), BorderSizePixel = 0, ZIndex = 5, Corner = 5, Parent = svBox})
			create("UIStroke", {Color = Color3.fromRGB(245, 245, 245), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = cursor})
			local svHit = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = svBox})

			local hueBar = create("Frame", {Size = UDim2.fromOffset(BW, BH), Position = UDim2.fromOffset(HX, 8), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = frame})
			create("UIGradient", {Rotation = 90, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}), Parent = hueBar})
			local hueHit = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = hueBar})
			local hueMark = create("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 10, Parent = hueBar})

			local alphaBar = checker(frame, AX, 8, BW, BH, 8)
			local alphaTint = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 5, Parent = alphaBar})
			create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}), Parent = alphaTint})
			local alphaHit = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = alphaBar})
			local alphaMark = create("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 10, Parent = alphaBar})

			local swatchBg = checker(frame, 8, 162, 24, 12, 6)
			local swatchFill = create("Frame", {Size = UDim2.new(1, 0, 1, 0), BorderSizePixel = 0, ZIndex = 5, Parent = swatchBg})
			local hexLabel = W:_label(frame, "", {Position = UDim2.fromOffset(40, 158), Size = UDim2.fromOffset(90, 20), TextSize = 10, Color = "Text"})
			local alphaLabel = W:_label(frame, "", {Position = UDim2.fromOffset(208 - 78, 158), Size = UDim2.fromOffset(70, 20), TextSize = 10, Align = Enum.TextXAlignment.Right, Color = "TextSub"})

			local function refresh()
				local color = Color3.fromHSV(h, s, v)
				local alpha = 1 - a
				svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				cursor.Position = UDim2.new(s, -4.5, 1 - v, -4.5)
				cursor.BackgroundColor3 = color
				alphaTint.BackgroundColor3 = color
				swatchFill.BackgroundColor3 = color
				swatchFill.BackgroundTransparency = 1 - alpha
				hueMark.Position = UDim2.new(0, 0, 0, h * BH - 1)
				alphaMark.Position = UDim2.new(0, 0, 0, a * BH - 1)
				hexLabel.Text = string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
				alphaLabel.Text = math.floor(alpha * 100 + 0.5) .. "%"
			end

			local mode
			local function process(input)
				if mode == "SV" then
					s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
				elseif mode == "H" then
					h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
				elseif mode == "A" then
					a = math.clamp((input.Position.Y - alphaBar.AbsolutePosition.Y) / alphaBar.AbsoluteSize.Y, 0, 1)
				else
					return
				end
				refresh()
				el:Set(Color3.fromHSV(h, s, v), 1 - a)
			end
			local function begin(which)
				return function(input)
					if isClick(input) then
						mode = which
						process(input)
					end
				end
			end
			svHit.InputBegan:Connect(begin("SV"))
			hueHit.InputBegan:Connect(begin("H"))
			alphaHit.InputBegan:Connect(begin("A"))
			table.insert(W._popupConns, UIS.InputChanged:Connect(function(input)
				if mode and isMove(input) then process(input) end
			end))
			table.insert(W._popupConns, UIS.InputEnded:Connect(function(input)
				if isClick(input) then mode = nil end
			end))
			refresh()
		end)
	end)
	local startAlpha = type(o.Alpha) == "number" and o.Alpha or 1 -- Alpha = true is read as fully opaque
	return el:_finish(o.Default or W.Accent, startAlpha)
end

-- Keybind: Default (KeyCode), Mode = "Press" | "Toggle" | "Hold"
--   Callback(state)  on every press / release (Press always sends true)
--   OnBind(key)      when the key is assigned (nil when cleared)
function Section:Keybind(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(25)
	local label = W:_label(row, o.Name or "Keybind", {Size = UDim2.new(0.5, 0, 1, 0)})
	local button = create("TextButton", {Size = UDim2.new(0.5, 0, 0, 25), Position = UDim2.new(0.5, 0, 0, 0), Text = "", AutoButtonColor = false, Corner = 5, Parent = row})
	W:_bind(button, {BackgroundColor3 = "Field"})
	local outline = create("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button})
	local keyLabel = W:_label(button, "", {Size = UDim2.new(1, 0, 1, 0), Align = Enum.TextXAlignment.Center, Color = "Text"})

	local listening = false
	local el = newElement(self, "Keybind", o, row)
	el._nameLabel = label
	el.Mode = o.Mode or "Press"
	el.State = false
	el._callback = o.OnBind
	el._press = o.Callback
	el._apply = function(value)
		if value == false or value == nil then el.Value = nil else el.Value = value end
	end
	el._paint = function()
		if not listening then keyLabel.Text = el.Value and el.Value.Name or "None" end
		label.TextColor3 = el._enabled and W.Theme.TextSub or W.Theme.TextDim
		keyLabel.TextColor3 = el._enabled and W.Theme.Text or W.Theme.Disabled
		outline.Color = el._enabled and W.Theme.FieldBorder or W.Theme.DisabledBorder
	end
	el._encode = function() return el.Value and el.Value.Name or "" end
	el._decode = function(raw)
		if raw == nil or raw == "" then return false end
		return Enum.KeyCode[raw]
	end

	button.MouseButton1Click:Connect(function()
		if not el._enabled or listening then return end
		listening = true
		keyLabel.Text = "..."
		local conn
		conn = UIS.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				el:Set(false)
			else
				el:Set(input.KeyCode)
			end
		end)
	end)

	W:_connect(UIS.InputBegan, function(input, processed)
		if processed or not el._enabled or el.Value == nil or input.KeyCode ~= el.Value then return end
		if el.Mode == "Toggle" then
			el.State = not el.State
			if el._press then pcall(el._press, el.State) end
		elseif el.Mode == "Hold" then
			el.State = true
			if el._press then pcall(el._press, true) end
		elseif el._press then
			pcall(el._press, true)
		end
	end)
	W:_connect(UIS.InputEnded, function(input)
		if el.Mode == "Hold" and el.State and el.Value ~= nil and input.KeyCode == el.Value then
			el.State = false
			if el._press then pcall(el._press, false) end
		end
	end)
	return el:_finish(o.Default)
end

-- Button: Callback, Style = "Default" | "Danger" | "Accent"
function Section:Button(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(25)
	local button = create("TextButton", {Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, Corner = 5, Parent = row})
	W:_bind(button, {BackgroundColor3 = "Field"})
	local outline = create("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button})
	local text = W:_label(button, o.Name or "Button", {Size = UDim2.new(1, 0, 1, 0), Align = Enum.TextXAlignment.Center, Color = "Text"})

	local el = newElement(self, "Button", o, row)
	el._nameLabel = text
	el._apply = function() end
	el._paint = function()
		local enabled = el._enabled
		if not enabled then
			text.TextColor3 = W.Theme.TextDim
		elseif o.Style == "Danger" then
			text.TextColor3 = W.Theme.Danger
		elseif o.Style == "Accent" then
			text.TextColor3 = W.Accent
		else
			text.TextColor3 = W.Theme.Text
		end
		outline.Color = enabled and W.Theme.FieldBorder or W.Theme.DisabledBorder
	end
	button.MouseButton1Click:Connect(function() el:Click() end)
	function el:Click()
		if self._enabled then self:_fire() end
		return self
	end
	function el:SetText(value)
		text.Text = value
		return self
	end
	return el:_finish()
end

-- TextBox: Default, Placeholder, Numeric = true to accept numbers only
function Section:TextBox(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(25)
	local label = W:_label(row, o.Name or "Text", {Size = UDim2.new(0.5, 0, 1, 0)})
	local box = create("TextBox", {
		Size = UDim2.new(0.5, 0, 0, 25), Position = UDim2.new(0.5, 0, 0, 0), Text = "",
		PlaceholderText = o.Placeholder or "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 11, Corner = 5, Parent = row,
	})
	W:_bind(box, {BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "TextDim"})
	create("UIPadding", {PaddingLeft = UDim.new(0, 7), Parent = box})

	local el = newElement(self, "TextBox", o, row)
	el._nameLabel = label
	el._apply = function(value)
		local v = value == nil and "" or tostring(value)
		if o.Numeric and v ~= "" and not tonumber(v) then v = el.Value or "" end
		el.Value = v
		box.Text = v
	end
	el._paint = function()
		label.TextColor3 = el._enabled and W.Theme.TextSub or W.Theme.TextDim
		box.TextEditable = el._enabled
	end
	el._encode = function() return el.Value end
	el._decode = function(raw) return tostring(raw) end
	box.FocusLost:Connect(function()
		local text = box.Text
		if o.Numeric and text ~= "" and not tonumber(text) then
			box.Text = el.Value or ""
			return
		end
		el:Set(text)
	end)
	return el:_finish(o.Default or "")
end

-- Label: static text, wraps and grows with its content
function Section:Label(o)
	o = o or {}
	local W = self.Window
	local row = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = self:_nextOrder(), Parent = self._content})
	local text = W:_label(row, o.Text or o.Name or "", {Size = UDim2.new(1, 0, 0, 0), AutoY = true, Wrap = true, TextSize = o.TextSize or 10, Color = o.Color or "TextSub"})
	local el = newElement(self, "Label", o, row)
	el._nameLabel = text
	el._paint = function() end
	function el:SetText(value)
		text.Text = value
		return self
	end
	return el:_finish()
end

function Section:Separator()
	local row = self:_row(7)
	local line = create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 3), BorderSizePixel = 0, Parent = row})
	self.Window:_bind(line, {BackgroundColor3 = "Divider"})
	return newElement(self, "Separator", {}, row):_finish()
end

----------------------------------------------------------------------
-- links: Telegram-style cards with a button; any action you like
----------------------------------------------------------------------
-- Link({Name, Desc, Icon, Url, Button = "Open", Action = fn(link), CopyUrl = false})
-- Without Action a click copies the Url. With Action, the action runs (and the Url is
-- copied too when CopyUrl = true).
function Section:Link(o)
	o = o or {}
	local W = self.Window
	local row = self:_row(40)
	local card = create("TextButton", {Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, Corner = 5, Parent = row})
	W:_bind(card, {BackgroundColor3 = "Field"})
	local outline = create("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card})
	W:_bind(outline, {Color = "FieldBorder"})
	local tile = create("Frame", {Size = UDim2.fromOffset(25, 25), Position = UDim2.fromOffset(8, 7.5), BorderSizePixel = 0, Corner = 5, Parent = card})
	W:_track(function(theme, accent) tile.BackgroundColor3 = theme.Card:Lerp(accent, 0.22) end)
	W:_icon(tile, o.Icon or {"link"}, 12, UDim2.new(0.5, -6, 0.5, -6), "Accent")
	local title = W:_label(card, o.Name or "Link", {Position = UDim2.fromOffset(42, 6), Size = UDim2.new(1, -120, 0, 14), Color = "Text", Weight = "SemiBold"})
	local desc = W:_label(card, o.Desc or o.Url or "", {Position = UDim2.fromOffset(42, 21), Size = UDim2.new(1, -120, 0, 12), Color = "TextSub", TextSize = 10})
	local badge = create("Frame", {Size = UDim2.fromOffset(59, 25), Position = UDim2.new(1, -67, 0.5, -12.5), BorderSizePixel = 0, Corner = 5, Parent = card})
	W:_bind(badge, {BackgroundColor3 = "Tile"})
	local badgeOutline = create("UIStroke", {Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = badge})
	W:_bind(badgeOutline, {Color = "FieldBorder"})
	local badgeText = W:_label(badge, o.Button or "Open", {Size = UDim2.new(1, 0, 1, 0), Align = Enum.TextXAlignment.Center, Color = "TextSub"})

	local link = setmetatable({
		Window = W, Section = self, Name = o.Name, Desc = o.Desc, Url = o.Url, Action = o.Action,
		CopyUrl = o.CopyUrl == true, Root = row, _title = title, _desc = desc, _badgeText = badgeText, _buttonText = o.Button or "Open",
	}, Link)
	card.MouseButton1Click:Connect(function() link:Click() end)
	table.insert(self._elements, link)
	return link
end

function Link:Click()
	local W = self.Window
	local handled = false
	if self.Action then
		handled = true
		local ok, err = pcall(self.Action, self)
		if not ok then warn("[Zenin] link action failed: " .. tostring(err)) end
	end
	if self.Url and (not handled or self.CopyUrl) then
		if setclipboard then pcall(setclipboard, self.Url) end
		self._badgeText.Text = "Copied"
		task.delay(1.2, function() if self.Root.Parent then self._badgeText.Text = self._buttonText end end)
		W:Notify({Title = "Link copied", Text = self.Url, Duration = 2.5})
	end
	return self
end

function Link:SetName(text) self.Name = text self._title.Text = text return self end
function Link:SetDesc(text) self.Desc = text self._desc.Text = text return self end
function Link:SetUrl(url) self.Url = url self._desc.Text = self.Desc or url return self end
function Link:SetAction(fn) self.Action = fn return self end
function Link:SetButtonText(text) self._buttonText = text self._badgeText.Text = text return self end
function Link:SetVisible(state) self.Root.Visible = state == true return self end
function Link:Destroy()
	local index = indexOf(self.Section._elements, self)
	if index then table.remove(self.Section._elements, index) end
	self.Root:Destroy()
end

----------------------------------------------------------------------
-- watermark: a small pill that also opens and closes the menu on click
----------------------------------------------------------------------
function Watermark:_fade(object, prop, base)
	table.insert(self._fades, {object, prop, base})
	object[prop] = 1 - (1 - base) * self.Opacity
end

function Watermark:_next()
	self._order = self._order + 1
	return self._order
end

function Watermark:_spacer(width)
	create("Frame", {Size = UDim2.fromOffset(width, 1), BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self._frame})
end

function Watermark:_divider()
	local line = create("Frame", {Size = UDim2.fromOffset(1, 14), BorderSizePixel = 0, LayoutOrder = self:_next(), Parent = self._frame})
	self.Window:_bind(line, {BackgroundColor3 = "WmDivider"})
	self:_fade(line, "BackgroundTransparency", 0)
	return line
end

function Watermark:_detailText()
	local mode = self.Mode
	if mode == "Time" then return os.date("%H:%M:%S") end
	if mode == "FPS" then return string.format("%d fps", math.floor(self._fps + 0.5)) end
	if mode == "Ping" then
		local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return ok and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
	end
	if mode == "Version" then return "v" .. Zenin.Version end
	return self._product
end

-- Add({Id, Icon, Text, Color = "WmIcon" | "Accent" | Color3, TextColor, Update = fn, Interval, Divider})
function Watermark:Add(o)
	o = o or {}
	local W = self.Window
	local item = setmetatable({Watermark = self, Id = o.Id, Interval = o.Interval or 0.5, Update = o.Update, Visible = true, _last = 0, Text = tostring(o.Text or "")}, Item)
	if o.Divider then
		item.Root = self:_divider()
		table.insert(self._items, item)
		return item
	end
	local group = create("Frame", {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self._frame})
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = group})
	local icon = W:_icon(group, o.Icon or {"circle"}, 12, nil, o.Color or "WmIcon")
	icon.LayoutOrder = 1
	icon.Visible = self._icons
	local label = W:_label(group, o.Text or "", {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = o.TextColor or "Text"})
	label.LayoutOrder = 2
	self:_fade(icon, "ImageTransparency", 0)
	self:_fade(label, "TextTransparency", 0)
	item.Root, item._icon, item._label = group, icon, label
	table.insert(self._items, item)
	return item
end

function Watermark:Get(id)
	for _, item in ipairs(self._items) do
		if item.Id == id then return item end
	end
	return nil
end

function Watermark:Remove(id)
	local item = self:Get(id)
	if item then item:Remove() end
end

function Watermark:SetText(id, text)
	local item = self:Get(id)
	if item then item:Set(text) end
end

function Watermark:SetVisible(state) self._frame.Visible = state == true return self end
function Watermark:SetOpacity(alpha)
	self.Opacity = math.clamp(alpha, 0, 1)
	for _, f in ipairs(self._fades) do f[1][f[2]] = 1 - (1 - f[3]) * self.Opacity end
	return self
end
function Watermark:SetRadius(radius)
	self.Radius = radius
	self._corner.CornerRadius = UDim.new(0, radius)
	return self
end
function Watermark:SetIcons(state)
	self._icons = state == true
	for _, item in ipairs(self._items) do
		if item._icon then item._icon.Visible = self._icons end
	end
	return self
end
function Watermark:SetDetail(mode)
	self.Mode = mode
	return self
end
function Watermark:SetProduct(text)
	self._product = text
	return self
end
function Watermark:SetPosition(x, y)
	self._frame.Position = UDim2.fromOffset(x, y)
	return self
end
function Watermark:SetClickToggle(state)
	self._clickToggle = state == true
	return self
end
function Watermark:Items() return self._items end

function Item:Set(text)
	self.Text = tostring(text)
	if self._label then self._label.Text = self.Text end
	return self
end
function Item:SetIcon(names)
	if self._icon then applyIcon(self._icon, names) end
	return self
end
function Item:SetColor(color)
	if self._icon then self._icon.ImageColor3 = color end
	return self
end
function Item:SetVisible(state)
	self.Visible = state == true
	if self.Root then self.Root.Visible = self.Visible end
	return self
end
function Item:Remove()
	if self.Root then self.Root:Destroy() end
	for index, item in ipairs(self.Watermark._items) do
		if item == self then table.remove(self.Watermark._items, index) break end
	end
end

----------------------------------------------------------------------
-- watermark construction and live updates
----------------------------------------------------------------------
function Window:_buildWatermark(cfg)
	local wm = setmetatable({
		Window = self, _items = {}, _fades = {}, _order = 0, _icons = cfg.Icons ~= false,
		_clickToggle = cfg.ClickToggle ~= false, Mode = cfg.Detail or "Product Type", Radius = cfg.Radius or 8,
		Opacity = math.clamp(cfg.Opacity or 1, 0, 1), _fps = 60, _product = cfg.Product == nil and "internal" or cfg.Product,
	}, Watermark)
	self.Watermark = wm

	local p = cfg.Position
	local position = UDim2.fromOffset(8, 8)
	if typeof(p) == "Vector2" then
		position = UDim2.fromOffset(p.X, p.Y)
	elseif type(p) == "table" then
		position = UDim2.fromOffset(p[1] or 8, p[2] or 8)
	end

	local frame = create("Frame", {
		Name = "Watermark", Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, Position = position,
		BorderSizePixel = 0, Active = true, Parent = self._wmGui,
	})
	wm._frame = frame
	self:_bind(frame, {BackgroundColor3 = "WmBg"})
	frame.BackgroundTransparency = 0.1
	wm._corner = create("UICorner", {CornerRadius = UDim.new(0, wm.Radius), Parent = frame})
	local outline = create("UIStroke", {Thickness = 1, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = frame})
	self:_bind(outline, {Color = "WmStroke"})
	wm:_fade(frame, "BackgroundTransparency", 0.1)
	wm:_fade(outline, "Transparency", 0.15)
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame})
	create("UIPadding", {PaddingLeft = UDim.new(0, 11.5), PaddingRight = UDim.new(0, 15.5), Parent = frame})

	-- a plain click toggles the menu; dragging moves the pill
	makeDraggable(frame, frame, {Home = false, OnClick = function()
		if wm._clickToggle then self:Toggle() end
	end})

	if self._logo then
		local logo = self:_zLogo(frame, 10)
		logo.LayoutOrder = wm:_next()
		for _, child in ipairs(logo:GetChildren()) do wm:_fade(child, "BackgroundTransparency", 0) end
		wm:_spacer(10.5)
		wm:_divider()
		wm:_spacer(3.7)
	end
	local name = cfg.Name
	if name == nil then name = "zenin" end
	if name then
		wm:Add({Id = "name", Icon = {"tag"}, Color = "Accent", Text = name})
		wm:_spacer(13)
	end
	local site = cfg.Site
	if site == nil then site = "zenin.cc" end
	if site then
		wm:Add({Id = "site", Icon = {"globe"}, Color = rgb(104, 122, 232), Text = site})
		wm:_spacer(8.5)
		wm:_divider()
		wm:_spacer(3.5)
	end
	wm:Add({Id = "detail", Icon = {"monitor"}, Text = wm:_detailText(), Interval = 0.25, Update = function()
		return wm:_detailText()
	end})

	self:_connect(RunService.RenderStepped, function(dt)
		if dt > 0 then wm._fps = wm._fps + (1 / dt - wm._fps) * 0.1 end
	end)
	frame.Visible = cfg.Enabled ~= false
	return wm
end

----------------------------------------------------------------------
-- default settings page (built with the same public API you use)
----------------------------------------------------------------------
local function themeNames()
	local names = {"Dark"}
	local rest = {}
	for name in pairs(Themes) do
		if name ~= "Dark" then table.insert(rest, name) end
	end
	table.sort(rest)
	for _, name in ipairs(rest) do table.insert(names, name) end
	return names
end

function Window:_buildSettings(opts)
	local page = self:_newPage(nil, "Settings", {"settings", "cog"})
	page.IsSettings = true
	self._settings = page
	local defaults = opts.DefaultSettings ~= false

	if defaults then
		local appearance = page:Section({Name = "Appearance", Side = "Left"})
		appearance:Dropdown({Name = "Theme", Options = themeNames(), Default = self.ThemeName, Flag = "zenin.theme",
			Callback = function(name) self:SetTheme(name) end})
		appearance:ColorPicker({Name = "Accent Color", Default = self.Accent, Alpha = self.AccentAlpha, Flag = "zenin.accent",
			Callback = function(color, alpha) self:SetAccent(color, alpha) end})

		local interface = page:Section({Name = "Interface", Side = "Left"})
		interface:Slider({Name = "UI Scale", Min = 60, Max = 150, Step = 5, Default = math.floor((self.Scale.Scale or 1) * 100 + 0.5),
			Suffix = "%", Flag = "zenin.scale", Callback = function(v) self:SetScale(v / 100) end})
		interface:Slider({Name = "Scrollbar Size", Min = 0, Max = 14, Step = 1, Default = self.BarW, Suffix = "px",
			Flag = "zenin.scrollbar", Callback = function(v) self:SetScrollbarSize(v) end})
		interface:Keybind({Name = "Menu Key", Default = self.ToggleKey, Mode = "Press", Flag = "zenin.menukey",
			OnBind = function(key) self:SetToggleKey(key or nil) end})
		interface:Toggle({Name = "Animations", Default = self.Animations, Flag = "zenin.animations",
			Callback = function(v) self:SetAnimations(v) end})

		local wm = page:Section({Name = "Watermark", Side = "Right"})
		wm:Toggle({Name = "Show Watermark", Default = self.Watermark._frame.Visible, Flag = "zenin.wm.show",
			Callback = function(v) self.Watermark:SetVisible(v) end})
		wm:Slider({Name = "Opacity", Min = 0, Max = 100, Step = 1, Default = math.floor(self.Watermark.Opacity * 100 + 0.5),
			Suffix = "%", Flag = "zenin.wm.opacity", Callback = function(v) self.Watermark:SetOpacity(v / 100) end})
		wm:Slider({Name = "Corner Radius", Min = 0, Max = 14, Step = 1, Default = self.Watermark.Radius, Suffix = "px",
			Flag = "zenin.wm.radius", Callback = function(v) self.Watermark:SetRadius(v) end})
		wm:Toggle({Name = "Show Icons", Default = self.Watermark._icons, Flag = "zenin.wm.icons",
			Callback = function(v) self.Watermark:SetIcons(v) end})
		wm:Dropdown({Name = "Details", Options = {"Time", "FPS", "Ping", "Version", "Product Type"}, Default = self.Watermark.Mode,
			Flag = "zenin.wm.detail", Callback = function(v) self.Watermark:SetDetail(v) end})

		local behaviour = page:Section({Name = "Behaviour", Side = "Right"})
		behaviour:Toggle({Name = "Watermark Toggles Menu", Default = self.Watermark._clickToggle, Flag = "zenin.wm.click",
			Callback = function(v) self.Watermark:SetClickToggle(v) end})
		behaviour:Toggle({Name = "Mouse Wheel Scroll", Default = self.MouseWheel, Flag = "zenin.mousewheel",
			Callback = function(v) self:SetMouseWheel(v) end})
	end
	self._info = page:Section({Name = "Information", Side = "Right"})
	return page
end

-- Link cards go to the Information section of the settings page.
function Window:AddLink(o)
	return self._info:Link(o)
end

function Window:Destroy()
	if not self._alive then return end
	self._alive = false
	self:_closePopup()
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	table.clear(self._conns)
	for _, c in ipairs(self._popupConns) do pcall(function() c:Disconnect() end) end
	for index, w in ipairs(Zenin.Windows) do
		if w == self then table.remove(Zenin.Windows, index) break end
	end
	if self._gui then self._gui:Destroy() end
	if self._wmGui then self._wmGui:Destroy() end
	if self._notifyGui then self._notifyGui:Destroy() end
end

----------------------------------------------------------------------
-- constructor
----------------------------------------------------------------------
-- Zenin.new({
--   Title = "Zenin Internal", Theme = "Dark", Accent = Color3, AccentAlpha = 1, Scale = 1,
--   ToggleKey = Enum.KeyCode.RightShift, Parent = "CoreGui" | "PlayerGui" | Instance,
--   DisplayOrder = Zenin.Priority.Window, Logo = true, Animations = true, MouseWheel = false,
--   ScrollbarSize = 6, DefaultSettings = true,
--   Watermark = {Name = "zenin", Site = "zenin.cc", Product = "internal", Detail = "Product Type",
--                Radius = 8, Opacity = 1, Icons = true, ClickToggle = true, Position = {8, 8}, Enabled = true},
-- })
function Zenin.new(opts)
	opts = opts or {}
	if not IconSet and not IconsTried then Zenin.LoadIcons() end

	local W = setmetatable({}, Window)
	W.Title = opts.Title or "Zenin"
	W.ThemeName = Themes[opts.Theme or "Dark"] and (opts.Theme or "Dark") or "Dark"
	W.Theme = Themes[W.ThemeName]
	W.Accent = opts.Accent or rgb(255, 89, 89)
	W.AccentAlpha = opts.AccentAlpha or 1
	W.Animations = opts.Animations ~= false
	W.MouseWheel = opts.MouseWheel == true
	W.BarW = opts.ScrollbarSize or 6
	W.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	W.Scale = opts.Scale or 1
	W._initialScale = opts.Scale or 1
	W._logo = opts.Logo ~= false
	W.Flags = {}
	W._elements = {}
	W._bound = setmetatable({}, {__mode = "k"})
	W._refreshers = {}
	W._conns = {}
	W._popupConns = {}
	W._tabs = {}
	W._pages = {}
	W._tweens = {}
	W._notes = {}
	W._headerButtons = {}
	W._toggleListeners = {}
	W._switchToken = 0
	W._alive = true
	W._touched = false

	local root = resolveParent(opts.Parent or "CoreGui")
	W._root = root
	for _, name in ipairs({"ZeninUI", "ZeninWatermark", "ZeninNotify"}) do
		local old = root:FindFirstChild(name)
		if old then old:Destroy() end
	end
	W._gui = create("ScreenGui", {Name = "ZeninUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = opts.DisplayOrder or Zenin.Priority.Window, Parent = root})
	W._wmGui = create("ScreenGui", {Name = "ZeninWatermark", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = Zenin.Priority.Watermark, Parent = root})
	W._notifyGui = create("ScreenGui", {Name = "ZeninNotify", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = Zenin.Priority.Notify, Parent = root})

	W:_buildShell()
	W:_buildWatermark(opts.Watermark or {})
	W:_buildSettings(opts)
	W:_layoutHeader()

	-- the menu key
	W:_connect(UIS.InputBegan, function(input, processed)
		if processed or not W._alive then return end
		if W.ToggleKey and input.KeyCode == W.ToggleKey then W:Toggle() end
	end)

	-- live watermark items and the scrollbar
	task.spawn(function()
		while W._alive do
			local now = os.clock()
			for _, item in ipairs(W.Watermark._items) do
				if item.Update and item.Visible and now - item._last >= item.Interval then
					item._last = now
					local ok, text = pcall(item.Update)
					if ok and text ~= nil then item:Set(text) end
				end
			end
			task.wait(0.1)
		end
	end)

	W:Navigate(W._settings)
	W._touched = false
	W:SetVisible(opts.Visible ~= false)
	table.insert(Zenin.Windows, W)
	return W
end

Zenin.Library = Zenin
return Zenin
