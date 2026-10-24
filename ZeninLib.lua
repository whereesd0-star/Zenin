--[[
	Zenin UI Library v3.0.0

	Элементы: Toggle, Slider, Dropdown, MultiDropdown, Button.
	Настройки (шестерёнка) встроены всегда: тема, акцент, размер меню, скроллбар, ватермарк.
	Полная документация: README.md

	local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()
	local Window = Library:CreateWindow({Title = "My Hub", Logo = "M"})
]]

local Library = {
	Version = "3.0.0",
	Flags = {},
	Options = {},
	Themes = {},
	ThemeOrder = {},
	IconsUrl = "https://raw.githubusercontent.com/whereesd0-star/Icons/refs/heads/main/Icons.lua%20(3).txt",
	IconsCache = "zenin_lucide_icons.lua",
	ConfigFolder = nil, -- nil = корень workspace экзекутора; строка = подпапка в workspace
	GuiName = "ZeninUI",
	ActiveWindow = nil,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

-- Методы работают и через ":" и через "." (obj:Set(v) == obj.Set(v)).
local function Method(obj, name, fn)
	obj[name] = function(first, ...)
		if first == obj then
			return fn(...)
		end
		return fn(first, ...)
	end
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, res = pcall(fn, ...)
	if not ok then
		warn("[Zenin] callback error: " .. tostring(res))
		return nil
	end
	return res
end

local function Opts(o)
	if type(o) == "string" then return {Name = o} end
	return o or {}
end

local function CopyList(t)
	local out = {}
	for i, v in ipairs(t or {}) do out[i] = v end
	return out
end

local function IndexOf(t, v)
	for i, x in ipairs(t) do
		if x == v then return i end
	end
	return nil
end

-- ============================================================================
-- ТЕМЫ
-- ============================================================================
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

Library.Themes.Dark = {
	WindowBg = rgb(14, 14, 14), BarBg = rgb(18, 18, 18), BarLine = rgb(22, 22, 22),
	CardBg = rgb(18, 18, 18), BoxBg = rgb(22, 22, 22), BoxBorder = rgb(26, 26, 26),
	TileBg = rgb(22, 22, 22), TileHover = rgb(30, 30, 30),
	DropdownBg = rgb(22, 22, 22), DropdownBorder = rgb(42, 42, 42), DropdownBorderOff = rgb(28, 28, 28),
	PopupBg = rgb(14, 14, 14), PopupHover = rgb(22, 22, 22),
	SliderTrack = rgb(22, 22, 22), KnobFill = rgb(14, 14, 14), KnobStroke = rgb(246, 246, 249), KnobStrokeOff = rgb(150, 150, 156),
	ToggleOffBg = rgb(22, 22, 22), ToggleOffDot = rgb(44, 44, 44),
	ToggleOffBgOff = rgb(19, 19, 19), ToggleOffDotOff = rgb(32, 32, 32), ToggleOnDot = rgb(255, 255, 255),
	Text = rgb(255, 255, 255), TextGray = rgb(160, 160, 168), TextDim = rgb(88, 88, 96),
	ValueOff = rgb(110, 110, 110), NavGray = rgb(180, 180, 188), Divider = rgb(34, 34, 38),
	ScrollTrack = rgb(18, 18, 18), ScrollThumb = rgb(22, 22, 22), ScrollHover = rgb(30, 30, 30), ScrollDrag = rgb(40, 40, 40),
	WmBg = rgb(14, 14, 14), WmStroke = rgb(38, 38, 43), WmDivider = rgb(42, 42, 47), WmText = rgb(255, 255, 255),
	WmDetailIcon = rgb(205, 205, 210), WmSiteIcon = rgb(104, 122, 232),
}
Library.ThemeOrder[1] = "Dark"

local ThemeHooks = {}

-- Новая тема = Dark + переопределённые цвета. Сразу появляется в Settings -> Theme.
local function AddTheme(name, tokens)
	local t = {}
	for k, v in pairs(Library.Themes.Dark) do t[k] = v end
	for k, v in pairs(tokens or {}) do t[k] = v end
	if not Library.Themes[name] then
		table.insert(Library.ThemeOrder, name)
	end
	Library.Themes[name] = t
	for _, fn in ipairs(ThemeHooks) do SafeCall(fn, name) end
	return t
end
Method(Library, "AddTheme", AddTheme)

AddTheme("Light", {
	WindowBg = rgb(240, 240, 242), BarBg = rgb(255, 255, 255), BarLine = rgb(228, 228, 232),
	CardBg = rgb(231, 231, 233), BoxBg = rgb(224, 224, 226), BoxBorder = rgb(210, 210, 214),
	TileBg = rgb(240, 240, 242), TileHover = rgb(222, 222, 226),
	DropdownBg = rgb(217, 217, 219), DropdownBorder = rgb(191, 191, 193), DropdownBorderOff = rgb(212, 212, 216),
	PopupBg = rgb(240, 240, 242), PopupHover = rgb(226, 226, 230),
	SliderTrack = rgb(217, 217, 219), KnobFill = rgb(255, 255, 255), KnobStroke = rgb(20, 20, 24), KnobStrokeOff = rgb(160, 160, 168),
	ToggleOffBg = rgb(217, 217, 219), ToggleOffDot = rgb(174, 174, 176),
	ToggleOffBgOff = rgb(226, 226, 228), ToggleOffDotOff = rgb(200, 200, 204), ToggleOnDot = rgb(21, 19, 24),
	Text = rgb(20, 20, 24), TextGray = rgb(70, 70, 78), TextDim = rgb(150, 150, 158),
	ValueOff = rgb(150, 150, 158), NavGray = rgb(110, 110, 118), Divider = rgb(221, 220, 225),
	ScrollTrack = rgb(228, 228, 230), ScrollThumb = rgb(214, 214, 216), ScrollHover = rgb(200, 200, 204), ScrollDrag = rgb(186, 186, 190),
	WmBg = rgb(242, 242, 242), WmStroke = rgb(197, 198, 202), WmDivider = rgb(214, 214, 218), WmText = rgb(20, 20, 24),
	WmDetailIcon = rgb(90, 90, 100),
})

-- ============================================================================
-- ИКОНКИ (Lucide) + картинки
-- ============================================================================
local Icons, IconsTried

local function LoadIcons()
	if IconsTried then return Icons end
	IconsTried = true
	local function Parse(src)
		if type(src) ~= "string" or #src < 200 or not loadstring then return nil end
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
			if isfile(Library.IconsCache) then return readfile(Library.IconsCache) end
			return nil
		end)
		if ok then cached = data end
	end
	Icons = Parse(cached)
	if not Icons then
		local src = Download(Library.IconsUrl)
		Icons = Parse(src)
		if Icons and writefile then pcall(writefile, Library.IconsCache, src) end
	end
	return Icons
end

local function IsImage(s)
	if type(s) == "number" then return true end
	if type(s) ~= "string" then return false end
	return s:find("^rbxasset") ~= nil or s:find("^rbxthumb") ~= nil or s:find("^https?://") ~= nil or tonumber(s) ~= nil
end

local function ResolveIcon(name)
	local set = LoadIcons()
	if not set then return nil end
	for _, sheet in ipairs({"48px", "256px"}) do
		local s = set[sheet]
		local e = s and s[name]
		if e then return e end
	end
	return nil
end

-- spec: имя Lucide-иконки, список имён (первое найденное), rbxassetid://... или число (asset id)
local function ApplyIcon(img, spec)
	if spec == nil or spec == false then
		img.Image = ""
		return false
	end
	local list = type(spec) == "table" and spec or {spec}
	for _, s in ipairs(list) do
		if IsImage(s) then
			img.Image = tonumber(s) and ("rbxassetid://" .. tostring(s)) or s
			img.ImageRectSize = Vector2.new(0, 0)
			img.ImageRectOffset = Vector2.new(0, 0)
			return true
		end
		local e = type(s) == "string" and ResolveIcon(s)
		if e then
			img.Image = "rbxassetid://" .. tostring(e[1])
			img.ImageRectSize = Vector2.new(e[2][1], e[2][2])
			img.ImageRectOffset = Vector2.new(e[3][1], e[3][2])
			return true
		end
	end
	img.Image = ""
	return false
end

Method(Library, "GetIcon", function(name)
	local e = ResolveIcon(name)
	if not e then return nil end
	return {
		Image = "rbxassetid://" .. tostring(e[1]),
		ImageRectSize = Vector2.new(e[2][1], e[2][2]),
		ImageRectOffset = Vector2.new(e[3][1], e[3][2]),
	}
end)

-- ============================================================================
-- УТИЛИТЫ
-- ============================================================================
local WIN_W, WIN_H = 480, 338
local HEADER_H, BOTTOM_H = 36, 35
local BODY_H = WIN_H - HEADER_H - BOTTOM_H
local TRK_TOP, TRK_BOT = 9, 10
local TRK_LEN = BODY_H - TRK_TOP - TRK_BOT
local BAR_RIGHT = WIN_W - 8
local TEXT = 11
local TI_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SCALE_OPTIONS = {"1.0x", "1.5x", "2.0x", "2.5x"}
local SCALE_MAP = {["1.0x"] = 0.8, ["1.5x"] = 0.9, ["2.0x"] = 0.95, ["2.5x"] = 1}
local DETAIL_MODES = {"Time", "FPS", "Ping", "Version", "Product Type"}
local WHITE = Color3.new(1, 1, 1)

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

-- Скругления как в оригинале: окно 6, карточки 4, поля/кнопки/попапы 3, плитки вкладок 2.
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
		Text = tostring(text),
		TextColor3 = o.Color or Library.Themes.Dark.TextGray,
		TextSize = o.TextSize or TEXT,
		Weight = o.Weight or "Medium",
		TextXAlignment = o.Align or Enum.TextXAlignment.Left,
		TextTruncate = o.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		AutomaticSize = o.AutoX and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
		Parent = parent,
	})
end

local function CreateIcon(parent, spec, size, pos, color)
	local img = Create("ImageLabel", {
		Size = UDim2.fromOffset(size, size),
		Position = pos or UDim2.new(0, 0, 0.5, -size / 2),
		BackgroundTransparency = 1,
		ImageColor3 = color or WHITE,
		ScaleType = Enum.ScaleType.Stretch,
		Parent = parent,
	})
	ApplyIcon(img, spec)
	return img
end

local function IsClickOrTouch(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function Tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function TextWidth(text, size)
	local ok, v = pcall(function()
		return TextService:GetTextSize(tostring(text), size, Enum.Font.GothamMedium, Vector2.new(1000, 100)).X
	end)
	return ok and v or #tostring(text) * size * 0.55
end

local function Decimals(step)
	local s = tostring(step)
	if s:find("e") then return 4 end
	local d = s:find("%.")
	return d and (#s - d) or 0
end

local function FormatNumber(v, decimals)
	if decimals > 0 then
		return string.format("%." .. decimals .. "f", v)
	end
	return tostring(math.floor(v + 0.5))
end

local function ToHex(c)
	return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function FromHex(hex)
	hex = tostring(hex):gsub("#", "")
	if #hex ~= 6 then return nil end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

-- Перетаскивание через общий диспетчер окна: порог 4px (клик не двигает), без задержки,
-- без ограничений по краям экрана. opts.OnClick вызывается на клик без перетаскивания.
local function MakeDraggable(W, handle, target, opts)
	opts = opts or {}
	local THRESH = 4

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

	W.Connect(handle.InputBegan, function(input)
		if not IsClickOrTouch(input) then return end
		local origin = Vector2.new(input.Position.X, input.Position.Y)
		if OverButton(origin) then return end
		local startPos, started = target.Position, false
		W.BeginDrag(input, function(inp)
			local delta = Vector2.new(inp.Position.X, inp.Position.Y) - origin
			if not started then
				if delta.Magnitude < THRESH then return end
				started = true
			end
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end, function(_, cancelled)
			if not started and not cancelled and opts.OnClick then opts.OnClick() end
		end)
	end)
end

-- Шахматка под альфой (w и h кратны sq)
local CHECK_LIGHT, CHECK_DARK = rgb(206, 206, 206), rgb(132, 132, 132)
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
-- ЛОГОТИП: своя буква/текст, Lucide-иконка или картинка
-- ============================================================================
local function NormalizeLogo(spec, title)
	if spec == nil or spec == false then
		local first = tostring(title or "Z"):match("[%w]") or "Z"
		return {Text = first:upper()}
	end
	if type(spec) == "number" then return {Image = spec} end
	if type(spec) == "string" then
		if IsImage(spec) then return {Image = spec} end
		if #spec <= 2 then return {Text = spec} end
		return {Icon = spec}
	end
	return spec
end

local function CreateLogo(W, parent, spec, size, textSize)
	local box = Create("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent})
	local fades = {}
	local target, prop
	if spec.Text then
		box.Size = UDim2.fromOffset(0, size)
		box.AutomaticSize = Enum.AutomaticSize.X
		local lbl = Label(box, spec.Text, {
			Size = UDim2.new(0, 0, 1, 0),
			AutoX = true,
			TextSize = spec.TextSize or textSize,
			Weight = "Bold",
			Align = Enum.TextXAlignment.Center,
		})
		target, prop = lbl, "TextColor3"
		table.insert(fades, {lbl, "TextTransparency", 0})
	else
		local img = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ImageColor3 = WHITE,
			ScaleType = spec.Image and Enum.ScaleType.Fit or Enum.ScaleType.Stretch,
			Parent = box,
		})
		ApplyIcon(img, spec.Image or spec.Icon)
		if spec.Corner then Corner(img, spec.Corner) end
		if not spec.Image or spec.Tint then
			target, prop = img, "ImageColor3"
		end
		table.insert(fades, {img, "ImageTransparency", 0})
	end
	if spec.Color and target then
		target[prop] = spec.Color
	elseif target then
		W.Bind(function(_, accent) target[prop] = accent end, target)
	end
	return box, fades
end

-- ============================================================================
-- БАЗА ЭЛЕМЕНТА
-- ============================================================================
local function NewElement(W, S, kind, o, height)
	S.Order = S.Order + 1
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = S.Order,
		Parent = S.Content,
	})
	local el = {
		Type = kind,
		Flag = o.Flag,
		Enabled = o.Enabled ~= false and o.Disabled ~= true,
		Visible = o.Visible ~= false,
		Row = row,
	}
	row.Visible = el.Visible
	local listeners = {}
	el._apply = function() end

	-- зависимые элементы (DependsOn) обновляются и при тихом Set
	el._deps = {}
	function el._sync(value)
		if el.Flag then Library.Flags[el.Flag] = value end
		for _, fn in ipairs(el._deps) do SafeCall(fn, value) end
	end
	function el._fire(value, extra)
		el._sync(value)
		SafeCall(o.Callback, value, extra)
		for _, fn in ipairs(listeners) do SafeCall(fn, value, extra) end
	end

	Method(el, "OnChanged", function(fn)
		table.insert(listeners, fn)
		return el
	end)
	Method(el, "SetCallback", function(fn) o.Callback = fn end)
	Method(el, "SetEnabled", function(b)
		el.Enabled = b ~= false
		if not el.Enabled and W.PopupOwner == el then W.ClosePopup() end
		el._apply(false)
	end)
	Method(el, "IsEnabled", function() return el.Enabled end)
	Method(el, "SetVisible", function(b)
		el.Visible = b ~= false
		row.Visible = el.Visible
		if not el.Visible and W.PopupOwner == el then W.ClosePopup() end
	end)
	Method(el, "IsVisible", function() return el.Visible end)
	-- Элемент активен только когда other (обычно Toggle) включён; invert = наоборот.
	Method(el, "DependsOn", function(other, invert)
		local function Upd(v)
			if type(v) == "table" then
				v = next(v) ~= nil
			else
				v = v and true or false
			end
			if invert then v = not v end
			el.SetEnabled(v)
		end
		table.insert(other._deps, Upd)
		el._depOn = el._depOn or {}
		table.insert(el._depOn, {other, Upd})
		Upd(other.Get())
		return el
	end)
	Method(el, "Destroy", function()
		if W.PopupOwner == el then W.ClosePopup() end
		if el.Flag then
			Library.Flags[el.Flag] = nil
			Library.Options[el.Flag] = nil
		end
		local i = IndexOf(W.Elements, el)
		if i then table.remove(W.Elements, i) end
		for _, link in ipairs(el._depOn or {}) do
			local j = IndexOf(link[1]._deps, link[2])
			if j then table.remove(link[1]._deps, j) end
		end
		el._depOn = nil
		table.clear(el._deps)
		row:Destroy()
		W.Prune()
	end)

	if el.Flag then Library.Options[el.Flag] = el end
	table.insert(W.Elements, el)
	return el, row
end

local function Finish(el, o)
	if el.Flag then Library.Flags[el.Flag] = el.Get() end
	if o.DependsOn then el.DependsOn(o.DependsOn, o.InvertDependency) end
	el._apply(false)
	return el
end

-- ============================================================================
-- ПОПАП СПИСКА (Dropdown / MultiDropdown)
-- ============================================================================
local function OpenList(W, owner, btn, options, isSelected, onPick, multi)
	if W.ActivePopup then
		W.ClosePopup()
		return
	end
	local T = W.Theme
	W.PopupLayer.Visible = true
	local sc = W.Scale.Scale
	local rel = (btn.AbsolutePosition - W.Main.AbsolutePosition) / sc
	local w = btn.AbsoluteSize.X / sc
	local itemH = 21
	local maxVisible = owner.MaxVisible or 8
	local count = math.max(#options, 1)
	local listH = math.min(count, maxVisible) * itemH
	local totalH = listH + 8
	local py = math.clamp(rel.Y + 12.5 - totalH / 2, 6, math.max(6, WIN_H - 6 - totalH))

	local popup = Create("Frame", {
		Size = UDim2.fromOffset(w, 0),
		Position = UDim2.fromOffset(rel.X, py),
		BackgroundColor3 = T.PopupBg,
		ClipsDescendants = true,
		Active = true,
		ZIndex = 35,
		Parent = W.PopupLayer,
	})
	Corner(popup, 3)
	Stroke(popup, T.DropdownBorder, 1)
	local scrolls = #options > maxVisible
	local list = Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, listH),
		Position = UDim2.fromOffset(0, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = scrolls and 2 or 0,
		ScrollBarImageColor3 = T.DropdownBorder,
		ScrollingEnabled = scrolls,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(0, #options * itemH),
		Parent = popup,
	})
	Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})

	local items = {}
	local function Paint(it)
		local sel = isSelected(it.opt)
		it.btn.TextColor3 = sel and W.Accent or T.Text
		ApplyFont(it.btn, sel and "SemiBold" or "Medium")
		if it.check then
			it.check.Visible = sel
			it.check.ImageColor3 = W.Accent
		end
	end

	if #options == 0 then
		Label(list, "No options", {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -7, 0, itemH), Color = T.TextDim})
	end
	for i, opt in ipairs(options) do
		local ob = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, itemH),
			BackgroundColor3 = T.PopupHover,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = tostring(opt),
			TextSize = TEXT,
			Weight = "Medium",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = list,
		})
		Create("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, multi and 22 or 7), Parent = ob})
		local it = {opt = opt, btn = ob}
		if multi then
			it.check = CreateIcon(ob, {"check"}, 12, UDim2.new(1, 5, 0.5, -6), W.Accent)
		end
		table.insert(items, it)
		Paint(it)
		ob.MouseEnter:Connect(function() ob.BackgroundTransparency = 0 end)
		ob.MouseLeave:Connect(function() ob.BackgroundTransparency = 1 end)
		ob.MouseButton1Click:Connect(function()
			onPick(opt)
			if multi then
				for _, x in ipairs(items) do Paint(x) end
			else
				W.ClosePopup()
			end
		end)
	end

	W.ActivePopup = popup
	W.PopupOwner = owner
	Tween(popup, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(w, totalH)})
end

-- ============================================================================
-- ЭЛЕМЕНТЫ
-- ============================================================================
local function AddToggle(W, S, o)
	o = Opts(o)
	local el, row = NewElement(W, S, "Toggle", o, 21)
	local state = o.Default == true or o.Value == true
	el.Value = state

	local lbl = Label(row, o.Name or o.Title or "Toggle", {Size = UDim2.new(1, -34, 1, 0), Truncate = true})
	local click = Create("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row})
	local sw = Create("TextButton", {
		Size = UDim2.fromOffset(26, 14),
		Position = UDim2.new(1, -26, 0.5, -7),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = row,
	})
	Corner(sw, 7)
	local dot = Create("Frame", {Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, ZIndex = 2, Parent = sw})
	Corner(dot, 4)

	function el._apply(animate)
		local T, enabled = W.Theme, el.Enabled
		local bg, bgT, dotC, dotPos
		if state then
			bg, bgT = W.Accent, 1 - W.AccentAlpha * (enabled and 1 or 0.45)
			dotC, dotPos = T.ToggleOnDot, UDim2.new(1, -11, 0.5, -4)
		else
			bg = enabled and T.ToggleOffBg or T.ToggleOffBgOff
			bgT = 0
			dotC = enabled and T.ToggleOffDot or T.ToggleOffDotOff
			dotPos = UDim2.new(0, 3, 0.5, -4)
		end
		lbl.TextColor3 = (not enabled) and T.TextDim or (state and T.Text or T.TextGray)
		ApplyFont(lbl, state and "SemiBold" or "Medium")
		if animate then
			local ti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
			Tween(dot, ti, {Position = dotPos, BackgroundColor3 = dotC})
			Tween(sw, ti, {BackgroundColor3 = bg, BackgroundTransparency = bgT})
		else
			dot.Position, dot.BackgroundColor3 = dotPos, dotC
			sw.BackgroundColor3, sw.BackgroundTransparency = bg, bgT
		end
	end
	W.Bind(function() el._apply(false) end, row)

	Method(el, "Set", function(v, silent)
		v = v and true or false
		local changed = v ~= state
		state = v
		el.Value = v
		el._apply(true)
		if changed and not silent then
			el._fire(v)
		else
			el._sync(v)
		end
	end)
	Method(el, "Get", function() return state end)
	Method(el, "Toggle", function() el.Set(not state) end)
	Method(el, "SetName", function(t) lbl.Text = tostring(t) end)

	local function OnClick()
		if el.Enabled then el.Set(not state) end
	end
	click.MouseButton1Click:Connect(OnClick)
	sw.MouseButton1Click:Connect(OnClick)
	return Finish(el, o)
end

local function AddSlider(W, S, o)
	o = Opts(o)
	local EXTRA = 2
	local el, row = NewElement(W, S, "Slider", o, 28 + EXTRA)
	local minV, maxV = o.Min or 0, o.Max or 100
	if maxV <= minV then maxV = minV + 1 end
	local step = o.Step or o.Increment or 1
	local decimals = o.Decimals or Decimals(step)

	local function Fmt(v)
		if type(o.Format) == "function" then return tostring(o.Format(v)) end
		return FormatNumber(v, decimals) .. (o.Suffix or "")
	end
	local function Round(v)
		v = tonumber(v) or minV
		if step > 0 then v = math.floor((v - minV) / step + 0.5) * step + minV end
		v = math.clamp(v, minV, maxV)
		return tonumber(FormatNumber(v, decimals)) or v
	end
	local value = Round(o.Default or o.Value or minV)
	el.Value = value

	local lbl = Label(row, o.Name or o.Title or "Slider", {Position = UDim2.fromOffset(0, EXTRA), Size = UDim2.new(0.65, 0, 0, 15), Truncate = true})
	local valLbl = Label(row, Fmt(value), {
		Position = UDim2.new(0.65, 0, 0, EXTRA),
		Size = UDim2.new(0.35, 0, 0, 15),
		Align = Enum.TextXAlignment.Right,
	})
	local hit = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, EXTRA + 12.5),
		BackgroundTransparency = 1,
		Active = true,
		Parent = row,
	})
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 0.5, -2),
		BorderSizePixel = 0,
		Parent = hit,
	})
	Corner(track, 2)
	local R = 5.5
	local fill = Create("Frame", {BorderSizePixel = 0, Parent = track})
	Corner(fill, 2)
	local knob = Create("Frame", {Size = UDim2.fromOffset(7, 7), BorderSizePixel = 0, ZIndex = 3, Parent = track})
	Corner(knob, 4)
	local ks = Stroke(knob, WHITE, 2)

	local SLIDE = TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local function Layout(animate)
		local p = (value - minV) / (maxV - minV)
		local fs = UDim2.new(p, R * (1 - 2 * p), 1, 0)
		local kp = UDim2.new(p, R * (1 - 2 * p) - 3.5, 0.5, -3.5)
		if animate then
			Tween(fill, SLIDE, {Size = fs})
			Tween(knob, SLIDE, {Position = kp})
		else
			fill.Size, knob.Position = fs, kp
		end
		valLbl.Text = Fmt(value)
	end
	Layout(false)

	function el._apply()
		local T, enabled = W.Theme, el.Enabled
		lbl.TextColor3 = enabled and T.TextGray or T.TextDim
		valLbl.TextColor3 = enabled and T.TextGray or T.TextDim
		track.BackgroundColor3 = T.SliderTrack
		fill.BackgroundColor3 = W.Accent
		fill.BackgroundTransparency = 1 - W.AccentAlpha * (enabled and 1 or 0.45)
		knob.BackgroundColor3 = T.KnobFill
		ks.Color = enabled and T.KnobStroke or T.KnobStrokeOff
	end
	W.Bind(function() el._apply() end, row)

	local function SetValue(v, silent)
		v = Round(v)
		local changed = v ~= value
		value = v
		el.Value = v
		Layout(true)
		if changed and not silent then
			el._fire(v)
		else
			el._sync(v)
		end
	end

	Method(el, "Set", SetValue)
	Method(el, "Get", function() return value end)
	Method(el, "SetName", function(t) lbl.Text = tostring(t) end)
	Method(el, "SetRange", function(mn, mx)
		minV, maxV = mn or minV, mx or maxV
		if maxV <= minV then maxV = minV + 1 end
		SetValue(value)
	end)
	Method(el, "SetMin", function(mn) el.SetRange(mn, maxV) end)
	Method(el, "SetMax", function(mx) el.SetRange(minV, mx) end)
	Method(el, "SetSuffix", function(s) o.Suffix = s Layout() end)
	Method(el, "SetFormat", function(fn) o.Format = fn Layout() end)

	local function Update(input)
		local sc = W.Scale.Scale
		local left = track.AbsolutePosition.X + R * sc
		local width = track.AbsoluteSize.X - 2 * R * sc
		if width <= 0 then return end
		local p = math.clamp((input.Position.X - left) / width, 0, 1)
		SetValue(minV + (maxV - minV) * p)
	end
	hit.InputBegan:Connect(function(input)
		if el.Enabled and IsClickOrTouch(input) and W.BeginDrag(input, Update) then
			Update(input)
		end
	end)
	return Finish(el, o)
end

local function AddDropdown(W, S, o, multi)
	o = Opts(o)
	local el, row = NewElement(W, S, multi and "MultiDropdown" or "Dropdown", o, 25)
	local options = CopyList(o.Options or o.Values or o.List)
	local value
	local selected = {}
	el.MaxVisible = o.MaxVisible or 8

	if multi then
		local def = o.Default or o.Value or {}
		if type(def) ~= "table" then def = {def} end
		for k, v in pairs(def) do
			if type(k) == "number" then
				selected[v] = true
			elseif v then
				selected[k] = true
			end
		end
	else
		value = o.Default or o.Value
		if value == nil and not o.AllowNone then value = options[1] end
	end

	local leftPad, icon = 0, nil
	if o.Icon then
		icon = CreateIcon(row, o.Icon, 12, UDim2.new(0, -1.5, 0.5, -6))
		leftPad = 14
	end
	local lbl = Label(row, o.Name or o.Title or "Dropdown", {Position = UDim2.fromOffset(leftPad, 0), Size = UDim2.new(0.5, -leftPad - 4, 1, 0), Truncate = true})
	local btn = Create("TextButton", {
		Size = UDim2.new(0.5, 0, 0, 25),
		Position = UDim2.new(0.5, 0, 0, 0),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(btn, 3)
	local bs = Stroke(btn, WHITE, 1)
	local valLbl = Label(btn, "", {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -24, 1, 0), Truncate = true})
	local chev = CreateIcon(btn, {"chevron-down"}, 12, UDim2.new(1, -17, 0.5, -6))

	local function List()
		local out = {}
		for _, opt in ipairs(options) do
			if selected[opt] then table.insert(out, opt) end
		end
		return out
	end
	local function Current()
		if multi then return List() end
		return value
	end
	local function Sync()
		el.Value = Current()
		if multi then
			local names = {}
			for i, v in ipairs(el.Value) do names[i] = tostring(v) end
			valLbl.Text = #names > 0 and table.concat(names, ", ") or (o.Placeholder or "None")
		else
			valLbl.Text = value ~= nil and tostring(value) or (o.Placeholder or "None")
		end
	end
	local function SelectedMap()
		local m = {}
		for _, v in ipairs(List()) do m[v] = true end
		return m
	end
	local function Fire()
		if multi then
			el._fire(el.Value, SelectedMap())
		else
			el._fire(value)
		end
	end
	Sync()

	function el._apply()
		local T, enabled = W.Theme, el.Enabled
		lbl.TextColor3 = enabled and T.TextGray or T.TextDim
		btn.BackgroundColor3 = T.DropdownBg
		valLbl.TextColor3 = enabled and T.Text or T.ValueOff
		bs.Color = enabled and T.DropdownBorder or T.DropdownBorderOff
		chev.ImageColor3 = enabled and T.TextGray or T.TextDim
		if icon then icon.ImageColor3 = enabled and T.TextGray or T.TextDim end
	end
	W.Bind(function() el._apply() end, row)

	local function IsSelected(opt)
		if multi then return selected[opt] == true end
		return opt == value
	end

	btn.MouseButton1Click:Connect(function()
		if not el.Enabled then return end
		OpenList(W, el, btn, options, IsSelected, function(opt)
			if multi then
				selected[opt] = (not selected[opt]) or nil
				Sync()
				Fire()
			elseif opt ~= value then
				value = opt
				Sync()
				Fire()
			end
		end, multi)
	end)

	local function Key()
		if multi then
			local names = {}
			for i, v in ipairs(List()) do names[i] = tostring(v) end
			return table.concat(names, "\0")
		end
		return tostring(value)
	end

	Method(el, "Set", function(v, silent)
		local before = Key()
		if multi then
			selected = {}
			if type(v) ~= "table" then v = {v} end
			for k, x in pairs(v) do
				if type(k) == "number" then
					selected[x] = true
				elseif x then
					selected[k] = true
				end
			end
		else
			if v == nil and not o.AllowNone then return end
			if v ~= nil and not IndexOf(options, v) then return end
			value = v
		end
		if W.PopupOwner == el then W.ClosePopup() end
		Sync()
		if Key() ~= before and not silent then
			Fire()
		else
			el._sync(el.Value)
		end
	end)
	Method(el, "Get", function()
		if multi then return List() end
		return value
	end)
	Method(el, "SetName", function(t) lbl.Text = tostring(t) end)
	Method(el, "GetOptions", function() return CopyList(options) end)
	Method(el, "SetOptions", function(list, silent)
		local before = Key()
		options = CopyList(list)
		if W.PopupOwner == el then W.ClosePopup() end
		if multi then
			for k in pairs(selected) do
				if not IndexOf(options, k) then selected[k] = nil end
			end
		elseif value ~= nil and not IndexOf(options, value) then
			value = (not o.AllowNone) and options[1] or nil
		elseif value == nil and not o.AllowNone then
			value = options[1]
		end
		Sync()
		if Key() ~= before and not silent then
			Fire()
		else
			el._sync(el.Value)
		end
	end)
	el.Refresh = el.SetOptions
	Method(el, "AddOption", function(opt)
		if IndexOf(options, opt) then return end
		local list = CopyList(options)
		table.insert(list, opt)
		el.SetOptions(list)
	end)
	Method(el, "RemoveOption", function(opt)
		local i = IndexOf(options, opt)
		if not i then return end
		local list = CopyList(options)
		table.remove(list, i)
		el.SetOptions(list)
	end)
	if multi then
		Method(el, "IsSelected", function(opt) return selected[opt] == true end)
		Method(el, "Select", function(opt)
			if not IndexOf(options, opt) or selected[opt] then return end
			selected[opt] = true
			Sync()
			Fire()
		end)
		Method(el, "Deselect", function(opt)
			if not selected[opt] then return end
			selected[opt] = nil
			Sync()
			Fire()
		end)
		Method(el, "ToggleOption", function(opt)
			if selected[opt] then el.Deselect(opt) else el.Select(opt) end
		end)
		Method(el, "Clear", function() el.Set({}) end)
		Method(el, "SelectAll", function() el.Set(CopyList(options)) end)
	end
	return Finish(el, o)
end

-- Кнопка-карточка (как бывшая Telegram): иконка + заголовок (+описание) + кнопка действия справа.
local function AddButton(W, S, o)
	o = Opts(o)
	local cb = o.Callback
	local el, row = NewElement(W, S, "Button", {Enabled = o.Enabled, Disabled = o.Disabled, Visible = o.Visible}, 40)
	local title = o.Name or o.Title or "Button"
	local desc = o.Description or o.Desc
	local buttonText = o.ButtonText or o.Text or "Open"
	local iconSpec = o.Icon

	local box = Create("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = row})
	Corner(box, 3)
	local boxStroke = Stroke(box, WHITE, 1)
	local tile = Create("Frame", {Size = UDim2.fromOffset(25, 25), Position = UDim2.fromOffset(8, 7.5), BorderSizePixel = 0, Parent = box})
	Corner(tile, 2)
	local icon = CreateIcon(tile, iconSpec, 12, UDim2.new(0.5, -6, 0.5, -6))
	local titleLbl = Label(box, title, {Truncate = true})
	local descLbl = Label(box, desc or "", {TextSize = 10, Truncate = true})
	local action = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(59, 25),
		BorderSizePixel = 0,
		Text = buttonText,
		TextSize = TEXT,
		Weight = "Medium",
		AutoButtonColor = false,
		Parent = box,
	})
	Corner(action, 3)
	local actionStroke = Stroke(action, WHITE, 1)
	local hovering = false

	local function Layout()
		local hasIcon = iconSpec ~= nil
		local hasDesc = desc ~= nil and desc ~= ""
		tile.Visible = hasIcon
		local bw = math.clamp(math.floor(TextWidth(action.Text, TEXT) + 24), 59, 120)
		action.Size = UDim2.fromOffset(bw, 25)
		local x = hasIcon and 42 or 10
		local w = -(x + bw + 16)
		titleLbl.Position = UDim2.fromOffset(x, hasDesc and 6 or 0)
		titleLbl.Size = UDim2.new(1, w, 0, hasDesc and 15 or 40)
		descLbl.Visible = hasDesc
		descLbl.Position = UDim2.fromOffset(x, 20)
		descLbl.Size = UDim2.new(1, w, 0, 13)
	end
	Layout()

	function el._apply()
		local T, enabled = W.Theme, el.Enabled
		local a = W.AccentAlpha * (enabled and 1 or 0.45)
		box.BackgroundColor3 = T.DropdownBg
		boxStroke.Color = enabled and T.DropdownBorder or T.DropdownBorderOff
		tile.BackgroundColor3 = T.CardBg:Lerp(o.IconColor or W.Accent, 0.22 * a)
		icon.ImageColor3 = o.IconColor or W.Accent
		icon.ImageTransparency = 1 - a
		titleLbl.TextColor3 = enabled and T.TextGray or T.TextDim
		descLbl.TextColor3 = T.TextDim
		action.BackgroundColor3 = (hovering and enabled) and T.TileHover or T.TileBg
		action.TextColor3 = not enabled and T.TextDim or (hovering and T.Text or T.TextGray)
		actionStroke.Color = enabled and T.DropdownBorder or T.DropdownBorderOff
	end
	W.Bind(function() el._apply() end, row)

	action.MouseEnter:Connect(function() hovering = true el._apply() end)
	action.MouseLeave:Connect(function() hovering = false el._apply() end)

	local flashToken = 0
	Method(el, "Flash", function(text, duration)
		flashToken = flashToken + 1
		local token = flashToken
		action.Text = tostring(text)
		Layout()
		task.delay(duration or 1.2, function()
			if token == flashToken then
				action.Text = buttonText
				Layout()
			end
		end)
	end)
	Method(el, "Get", function() return nil end)
	Method(el, "SetName", function(t) title = tostring(t) titleLbl.Text = title end)
	el.SetTitle = el.SetName
	Method(el, "SetDescription", function(t) desc = t descLbl.Text = tostring(t or "") Layout() end)
	Method(el, "SetButtonText", function(t)
		buttonText = tostring(t)
		flashToken = flashToken + 1
		action.Text = buttonText
		Layout()
	end)
	Method(el, "SetIcon", function(spec)
		iconSpec = spec
		ApplyIcon(icon, spec)
		Layout()
	end)
	Method(el, "SetIconColor", function(c) o.IconColor = c el._apply() end)

	Method(el, "SetCallback", function(fn) cb = fn end)
	-- Callback может вернуть строку: она на 1.2 сек покажется на кнопке (например "Copied").
	Method(el, "Fire", function()
		if not el.Enabled then return end
		local res = SafeCall(cb)
		el._fire(nil)
		if type(res) == "string" then el.Flash(res) end
	end)

	action.MouseButton1Click:Connect(function()
		el.Fire()
	end)
	if o.DependsOn then el.DependsOn(o.DependsOn, o.InvertDependency) end
	el._apply()
	return el
end

-- Встроенный пикер акцента (только для Settings).
local function AccentPicker(W, S, labelText)
	local el, row = NewElement(W, S, "AccentPicker", {}, 25)
	local icon = CreateIcon(row, {"palette"}, 12, UDim2.new(0, -1.5, 0.5, -6))
	local lbl = Label(row, labelText, {Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.7, -14, 1, 0)})
	local circle = Create("TextButton", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -18, 0.5, -9),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	Corner(circle, 9)
	W.Bind(function(T, accent)
		icon.ImageColor3 = T.TextGray
		lbl.TextColor3 = T.TextGray
		circle.BackgroundColor3 = accent
	end, row)
	Method(el, "Get", function() return W.Accent, W.AccentAlpha end)
	Method(el, "Set", function(c, a) W.SetAccent(c, a) end)

	circle.MouseButton1Click:Connect(function()
		if W.ActivePopup then W.ClosePopup() return end
		local T = W.Theme
		W.PopupLayer.Visible = true
		local h, s, v = W.Accent:ToHSV()
		local a = 1 - W.AccentAlpha

		local MW, MH = 208, 184
		local SV, BW, BH = 144, 16, 144
		local HX, AX = 160, 184
		local sc = W.Scale.Scale
		local rel = (circle.AbsolutePosition - W.Main.AbsolutePosition) / sc
		local mx = math.clamp(rel.X + 18 + 13, 6, WIN_W - MW - 6)
		local my = math.clamp(rel.Y + 9 - MH / 2, HEADER_H + 6, WIN_H - BOTTOM_H - 6 - MH)

		local modal = Create("Frame", {
			Size = UDim2.fromOffset(MW, MH),
			Position = UDim2.fromOffset(mx, my),
			BackgroundColor3 = T.PopupBg,
			BorderSizePixel = 0,
			Active = true,
			ZIndex = 35,
			Parent = W.PopupLayer,
		})
		Corner(modal, 4)
		Stroke(modal, T.BoxBorder, 1)

		local svBox = Create("Frame", {
			Size = UDim2.fromOffset(SV, SV),
			Position = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel = 0,
			Parent = modal,
		})
		local wL = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2, Parent = svBox})
		Create("UIGradient", {
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Parent = wL,
		})
		local bL = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 3, Parent = svBox})
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
			Parent = bL,
		})
		local cursor = Create("Frame", {Size = UDim2.fromOffset(9, 9), BorderSizePixel = 0, ZIndex = 5, Parent = svBox})
		Corner(cursor, 5)
		Stroke(cursor, rgb(245, 245, 245), 1.5)
		local svHit = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = svBox})

		local hueBar = Create("Frame", {
			Size = UDim2.fromOffset(BW, BH),
			Position = UDim2.fromOffset(HX, 8),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Parent = modal,
		})
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rgb(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, rgb(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, rgb(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, rgb(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, rgb(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, rgb(255, 0, 255)),
				ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
			}),
			Parent = hueBar,
		})
		local hueHit = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = hueBar})

		local alphaBar = Checker(modal, AX, 8, BW, BH, 8)
		local alphaTint = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = W.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = alphaBar})
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
			Parent = alphaTint,
		})
		local alphaHit = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Active = true, ZIndex = 9, Parent = alphaBar})

		-- Маркер: ромб, обрезанный рамкой 3x6 до треугольника.
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
				BackgroundColor3 = WHITE,
				BorderSizePixel = 0,
				ZIndex = 10,
				Parent = clip,
			})
			return clip
		end
		local hueL, hueR = Marker(HX, true), Marker(HX + BW - 3, false)
		local alL, alR = Marker(AX, true), Marker(AX + BW - 3, false)

		local swatchBg = Checker(modal, 8, 162, 24, 12, 6)
		local swatch = Create("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 5, Parent = swatchBg})
		local hexLbl = Label(modal, "", {Position = UDim2.fromOffset(40, 158), Size = UDim2.fromOffset(90, 20), TextSize = 10, Color = T.TextGray})
		local alphaLbl = Label(modal, "", {Position = UDim2.fromOffset(MW - 78, 158), Size = UDim2.fromOffset(70, 20), TextSize = 10, Align = Enum.TextXAlignment.Right, Color = T.TextGray})

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
			hexLbl.Text = "#" .. ToHex(col)
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
			W.SetAccent(Color3.fromHSV(h, s, v), 1 - a)
		end
		local function Begin(m)
			return function(i)
				if IsClickOrTouch(i) and W.BeginDrag(i, Process, function() mode = nil end, "popup") then
					mode = m
					Process(i)
				end
			end
		end
		svHit.InputBegan:Connect(Begin("SV"))
		hueHit.InputBegan:Connect(Begin("H"))
		alphaHit.InputBegan:Connect(Begin("A"))
		W.ActivePopup = modal
		W.PopupOwner = el
	end)
	return el
end

-- ============================================================================
-- СЕКЦИИ И СТРАНИЦЫ
-- ============================================================================
local ELEMENT_KINDS = {"Toggle", "Slider", "Dropdown", "MultiDropdown", "Button"}

local function NewSection(W, page, o)
	o = Opts(o)
	local side = o.Side
	if type(side) == "string" then side = side:lower() end
	local col
	if side == "right" or side == 2 then
		col = page.Right
	elseif side == "left" or side == 1 then
		col = page.Left
	else
		col = (page.Right.count < page.Left.count) and page.Right or page.Left
	end
	col.count = col.count + 1

	local titleText = o.Name or o.Title
	local top = titleText and 30 or 7
	local bottom = titleText and 9 or 7
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, top + bottom),
		BorderSizePixel = 0,
		LayoutOrder = col.count,
		Parent = col.frame,
	})
	W.Paint(card, "BackgroundColor3", "CardBg")
	Corner(card, 4)
	local titleLbl
	if titleText then
		titleLbl = Label(card, titleText, {
			Position = UDim2.fromOffset(9, 8),
			Size = UDim2.new(1, -18, 0, 14),
			Weight = "SemiBold",
			Truncate = true,
		})
		W.Paint(titleLbl, "TextColor3", "Text")
	end
	local content = Create("Frame", {
		Size = UDim2.new(1, -18, 0, 0),
		Position = UDim2.fromOffset(9, top),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local layout = Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content})
	local function Resize()
		local sc = W.Scale.Scale
		if sc <= 0 then return end
		local h = layout.AbsoluteContentSize.Y / sc
		content.Size = UDim2.new(1, -18, 0, h)
		card.Size = UDim2.new(1, 0, 0, top + h + bottom)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)

	local S = {Order = 0, Content = content, Card = card}
	Method(S, "AddToggle", function(x) return AddToggle(W, S, x) end)
	Method(S, "AddSlider", function(x) return AddSlider(W, S, x) end)
	Method(S, "AddDropdown", function(x) return AddDropdown(W, S, x, false) end)
	Method(S, "AddMultiDropdown", function(x) return AddDropdown(W, S, x, true) end)
	Method(S, "AddButton", function(x) return AddButton(W, S, x) end)
	for _, k in ipairs(ELEMENT_KINDS) do
		S[k] = S["Add" .. k]
		S["Create" .. k] = S["Add" .. k]
	end
	-- служебный ряд произвольной высоты (встроенные страницы)
	function S._raw(h)
		S.Order = S.Order + 1
		return Create("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = S.Order, Parent = content})
	end
	Method(S, "SetTitle", function(t) if titleLbl then titleLbl.Text = tostring(t) end end)
	S.SetName = S.SetTitle
	Method(S, "SetVisible", function(b) card.Visible = b ~= false end)
	Method(S, "Destroy", function()
		for i = #W.Elements, 1, -1 do
			local el = W.Elements[i]
			if el.Row:IsDescendantOf(card) then el.Destroy() end
		end
		card:Destroy()
		W.Prune()
	end)
	return S
end

local function NewPage(W, full)
	local scroll = Create("ScrollingFrame", {
		Size = UDim2.fromOffset(WIN_W, BODY_H),
		Position = UDim2.fromOffset(0, HEADER_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 1,
		TopImage = "",
		MidImage = "",
		BottomImage = "",
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ScrollingEnabled = W.WheelScroll,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = W.Main,
	})
	local hit = Create("Frame", {BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 7, Parent = W.Main})
	local track = Create("Frame", {BorderSizePixel = 0, ZIndex = 7, Parent = hit})
	local thumb = Create("Frame", {BorderSizePixel = 0, ZIndex = 8, Parent = track})
	W.Paint(track, "BackgroundColor3", "ScrollTrack")

	local page = {scroll = scroll, canvas = 0}
	local dragging, hovering, grabOff = false, false, 0
	local goal, step = 0, nil

	local function ThumbColor(instant)
		local T = W.Theme
		local c = dragging and T.ScrollDrag or (hovering and T.ScrollHover or T.ScrollThumb)
		if instant then
			thumb.BackgroundColor3 = c
		else
			Tween(thumb, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = c})
		end
	end
	W.Bind(function() ThumbColor(true) end, thumb)

	local function MaxScroll()
		return math.max(0, page.canvas - BODY_H)
	end

	function page.Update()
		local maxS = page.canvas - BODY_H
		local show = scroll.Visible and maxS > 1
		hit.Visible = show
		if not show then return end
		local bw = W.BarW + 1
		hit.Size = UDim2.fromOffset(bw + 8, TRK_LEN)
		hit.Position = UDim2.fromOffset(BAR_RIGHT - bw - 4, HEADER_H + TRK_TOP)
		track.Size = UDim2.new(0, bw, 1, 0)
		track.Position = UDim2.fromOffset(4, 0)
		local th = math.clamp(TRK_LEN * BODY_H / page.canvas, 20, TRK_LEN)
		local frac = math.clamp(scroll.CanvasPosition.Y / maxS, 0, 1)
		thumb.Size = UDim2.new(1, 0, 0, th)
		thumb.Position = UDim2.fromOffset(0, frac * (TRK_LEN - th))
	end

	function page.StopScroll()
		if step then
			step:Disconnect()
			step = nil
		end
	end
	-- Плавная прокрутка: экспоненциальное сглаживание к цели.
	-- RenderStepped подключён только пока контент едет, затем отключается.
	function page.ScrollTo(y, instant)
		goal = math.clamp(tonumber(y) or 0, 0, MaxScroll())
		if instant then
			page.StopScroll()
			scroll.CanvasPosition = Vector2.new(0, goal)
			return
		end
		if step then return end
		step = RunService.RenderStepped:Connect(function(dt)
			local cur = scroll.CanvasPosition.Y
			local nxt = cur + (goal - cur) * (1 - math.exp(-dt * 18))
			if math.abs(goal - nxt) < 0.5 then nxt = goal end
			scroll.CanvasPosition = Vector2.new(0, nxt)
			if nxt == goal then page.StopScroll() end
		end)
	end

	function page.SetCanvas(h)
		page.canvas = h
		scroll.CanvasSize = UDim2.fromOffset(0, h)
		goal = math.clamp(goal, 0, MaxScroll())
		page.Update()
	end
	function page.Show(b)
		scroll.Visible = b
		if not b then page.StopScroll() end
		page.Update()
	end

	local function SetFromMouse(mouseY)
		local maxS = MaxScroll()
		if maxS <= 1 then return end
		local sc = W.Scale.Scale
		local th = thumb.AbsoluteSize.Y / sc
		local travel = TRK_LEN - th
		if travel <= 0 then return end
		local top = (mouseY - hit.AbsolutePosition.Y) / sc - grabOff
		page.ScrollTo(math.clamp(top / travel, 0, 1) * maxS)
	end

	hit.InputBegan:Connect(function(input)
		if not IsClickOrTouch(input) then return end
		local sc = W.Scale.Scale
		local ty, th = thumb.AbsolutePosition.Y, thumb.AbsoluteSize.Y
		if input.Position.Y >= ty and input.Position.Y <= ty + th then
			local began = W.BeginDrag(input, function(i) SetFromMouse(i.Position.Y) end, function()
				dragging = false
				ThumbColor()
			end)
			if began then
				dragging = true
				grabOff = (input.Position.Y - ty) / sc
				ThumbColor()
			end
		elseif MaxScroll() > 1 and not W.Drag then
			-- клик по дорожке: страница в сторону клика
			local dir = (input.Position.Y < ty) and -1 or 1
			local from = step and goal or scroll.CanvasPosition.Y
			page.ScrollTo(from + dir * BODY_H * 0.9)
		end
	end)
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(page.Update)
	hit.MouseEnter:Connect(function() hovering = true ThumbColor() end)
	hit.MouseLeave:Connect(function() hovering = false ThumbColor() end)

	function page.Recalc()
		local sc = W.Scale.Scale
		if sc <= 0 or not (page.Left and page.Right) then return end
		local h = math.max(page.Left.layout.AbsoluteContentSize.Y, page.Right.layout.AbsoluteContentSize.Y) / sc
		page.SetCanvas(h > 0 and (h + 18) or 0)
	end
	local function Column()
		local frame = Create("Frame", {Position = UDim2.fromOffset(9, 9), BackgroundTransparency = 1, Parent = scroll})
		local layout = Create("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame})
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.Recalc() end)
		return {frame = frame, layout = layout, count = 0}
	end
	page.Left = Column()
	page.Right = full and page.Left or Column()
	-- Блоки сужаются под толщину полосы: правый край контента = 9px левее полосы.
	-- При стандартной толщине (6) это ровно 456, как в оригинале.
	function page.LayoutColumns()
		local right = math.min(456, BAR_RIGHT - (W.BarW + 1) - 9)
		local total = right - 9
		if full then
			page.Left.frame.Size = UDim2.fromOffset(total, 0)
		else
			local w = math.floor((total - 9) / 2)
			page.Left.frame.Size = UDim2.fromOffset(w, 0)
			page.Right.frame.Size = UDim2.fromOffset(w, 0)
			page.Right.frame.Position = UDim2.fromOffset(right - w, 9)
		end
	end
	page.LayoutColumns()

	table.insert(W.Pages, page)
	return page
end

local function AttachSections(W, api, page)
	Method(api, "AddSection", function(o) return NewSection(W, page, o) end)
	api.Section = api.AddSection
	api.CreateSection = api.AddSection
	Method(api, "ScrollTo", function(y, instant) page.ScrollTo(y, instant) end)
	return api
end

-- ============================================================================
-- ВАТЕРМАРК
-- ============================================================================
local function BuildWatermark(W, cfg)
	if cfg == false then cfg = {Enabled = false} end
	cfg = cfg or {}
	local WM = {
		Fade = {},
		LogoFade = {},
		IconGroups = {},
		Mode = cfg.Mode or "Product Type",
		Detail = cfg.Detail or cfg.Text or "internal",
		Version = cfg.Version or ("v" .. Library.Version),
		Provider = cfg.Provider,
		ToggleOnClick = cfg.ToggleOnClick ~= false,
		Opacity = 1,
		ShowIcons = true,
	}
	W.WM = WM

	local frame = Create("Frame", {
		Name = "Watermark",
		Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = cfg.Position or UDim2.fromOffset(8, 8),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Active = true,
		Visible = cfg.Enabled ~= false,
		Parent = W.Gui,
	})
	WM.Frame = frame
	W.Paint(frame, "BackgroundColor3", "WmBg")
	table.insert(WM.Fade, {frame, "BackgroundTransparency", 0.1})
	Corner(frame, 13)
	local stroke = Stroke(frame, WHITE, 1, 0.15)
	W.Paint(stroke, "Color", "WmStroke")
	table.insert(WM.Fade, {stroke, "Transparency", 0.15})
	MakeDraggable(W, frame, frame, {
		OnClick = function()
			if WM.ToggleOnClick and W.Window then W.Window.Toggle() end
		end,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})
	Create("UIPadding", {PaddingLeft = UDim.new(0, 11.5), PaddingRight = UDim.new(0, 15.5), Parent = frame})

	local order = 0
	local function nx() order = order + 1 return order end
	local function Spacer(w)
		return Create("Frame", {Size = UDim2.fromOffset(w, 1), BackgroundTransparency = 1, LayoutOrder = nx(), Parent = frame})
	end
	local function Divider()
		local d = Create("Frame", {Size = UDim2.fromOffset(1, 14), BorderSizePixel = 0, LayoutOrder = nx(), Parent = frame})
		W.Paint(d, "BackgroundColor3", "WmDivider")
		table.insert(WM.Fade, {d, "BackgroundTransparency", 0})
	end
	local function Item(iconSpec, colorKey, text)
		local grp = Create("Frame", {Size = UDim2.fromOffset(16, 12), BackgroundTransparency = 1, LayoutOrder = nx(), Parent = frame})
		local ic = CreateIcon(grp, iconSpec, 12, UDim2.fromOffset(0, 0))
		W.Bind(function(T, accent)
			ic.ImageColor3 = colorKey == "Accent" and accent or T[colorKey]
		end, ic)
		table.insert(WM.Fade, {ic, "ImageTransparency", 0})
		table.insert(WM.IconGroups, grp)
		local lbl = Label(frame, text, {AutoX = true, Size = UDim2.new(0, 0, 1, 0)})
		lbl.LayoutOrder = nx()
		W.Paint(lbl, "TextColor3", "WmText")
		table.insert(WM.Fade, {lbl, "TextTransparency", 0})
		return {grp = grp, icon = ic, label = lbl}
	end

	WM.LogoOrder = nx()
	function WM.BuildLogo()
		if WM.LogoFrame then WM.LogoFrame:Destroy() end
		local box, fades = CreateLogo(W, frame, W.LogoSpec, 10, 12)
		box.LayoutOrder = WM.LogoOrder
		WM.LogoFrame, WM.LogoFade = box, fades
		WM.ApplyOpacity()
	end

	Spacer(10.5)
	Divider()
	Spacer(3.7)
	WM.TitleItem = Item(cfg.TitleIcon or "tag", "Accent", cfg.Title or W.Title)
	WM.SiteSpacer = Spacer(13)
	WM.SiteItem = Item(cfg.SiteIcon or "globe", "WmSiteIcon", cfg.Site or "")
	Spacer(8.5)
	Divider()
	Spacer(3.5)
	WM.DetailItem = Item(cfg.DetailIcon or "monitor", "WmDetailIcon", WM.Detail)

	function WM.ApplyOpacity()
		local a = WM.Opacity
		for _, list in ipairs({WM.Fade, WM.LogoFade}) do
			for _, e in ipairs(list) do
				e[1][e[2]] = 1 - (1 - e[3]) * a
			end
		end
	end
	function WM.SetSite(text)
		local has = text ~= nil and text ~= ""
		WM.SiteItem.label.Text = has and tostring(text) or ""
		WM.SiteItem.label.Visible = has
		WM.SiteItem.grp.Visible = has and WM.ShowIcons
		WM.SiteSpacer.Visible = has
		WM.HasSite = has
	end
	function WM.SetIconsVisible(b)
		WM.ShowIcons = b
		for _, g in ipairs(WM.IconGroups) do g.Visible = b end
		if not WM.HasSite then WM.SiteItem.grp.Visible = false end
	end
	WM.BuildLogo()
	WM.SetSite(cfg.Site)

	local fps = 60
	W.Connect(RunService.RenderStepped, function(dt)
		if dt > 0 then fps = fps + (1 / dt - fps) * 0.1 end
	end)
	function WM.Text()
		if WM.Provider then
			local res = SafeCall(WM.Provider, WM.Mode)
			if res ~= nil then return tostring(res) end
		end
		local mode = WM.Mode
		if mode == "Time" then
			return os.date("%H:%M:%S")
		elseif mode == "FPS" then
			return string.format("%d fps", math.floor(fps + 0.5))
		elseif mode == "Ping" then
			local ok, ping = pcall(function()
				return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			return ok and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
		elseif mode == "Version" then
			return tostring(WM.Version)
		end
		return tostring(WM.Detail)
	end
	task.spawn(function()
		while W.Alive do
			local txt = WM.Text()
			if WM.DetailItem.label.Text ~= txt then WM.DetailItem.label.Text = txt end
			task.wait(0.25)
		end
	end)

	local api = {}
	Method(api, "SetVisible", function(b) frame.Visible = b ~= false end)
	Method(api, "IsVisible", function() return frame.Visible end)
	Method(api, "Toggle", function() frame.Visible = not frame.Visible end)
	Method(api, "SetTitle", function(t) WM.TitleItem.label.Text = tostring(t) end)
	Method(api, "SetSite", function(t) WM.SetSite(t) end)
	Method(api, "SetDetail", function(t) WM.Detail = t WM.DetailItem.label.Text = WM.Text() end)
	Method(api, "SetVersion", function(t) WM.Version = t end)
	Method(api, "SetProvider", function(fn) WM.Provider = fn end)
	Method(api, "SetMode", function(m)
		if W.WmDetails then W.WmDetails.Set(m) else WM.Mode = m end
	end)
	Method(api, "GetMode", function() return WM.Mode end)
	Method(api, "SetOpacity", function(a)
		a = math.clamp(tonumber(a) or 1, 0, 1)
		if W.WmOpacity then W.WmOpacity.Set(math.floor(a * 100 + 0.5)) else WM.Opacity = a WM.ApplyOpacity() end
	end)
	Method(api, "SetIconsVisible", function(b)
		if W.WmIcons then W.WmIcons.Set(b) else WM.SetIconsVisible(b ~= false) end
	end)
	Method(api, "SetIcons", function(t)
		t = t or {}
		if t.Title then ApplyIcon(WM.TitleItem.icon, t.Title) end
		if t.Site then ApplyIcon(WM.SiteItem.icon, t.Site) end
		if t.Detail then ApplyIcon(WM.DetailItem.icon, t.Detail) end
	end)
	Method(api, "SetPosition", function(p) frame.Position = p end)
	Method(api, "SetToggleOnClick", function(b) WM.ToggleOnClick = b ~= false end)
	return api
end

-- ============================================================================
-- УВЕДОМЛЕНИЯ
-- ============================================================================
local function Notify(W, o)
	if not W.Alive then return nil end
	if type(o) == "string" then o = {Content = o} end
	o = o or {}
	local T = W.Theme
	W.NotifyOrder = W.NotifyOrder + 1
	local holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = W.NotifyOrder,
		Parent = W.NotifyHolder,
	})
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(260, 0),
		BackgroundColor3 = T.CardBg,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Corner(card, 4)
	Stroke(card, T.DropdownBorder, 1)
	Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 12),
		Parent = card,
	})
	Create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card})
	local top = Create("Frame", {Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
	local x = 0
	if o.Icon ~= false then
		CreateIcon(top, o.Icon or "bell", 12, UDim2.new(0, 0, 0.5, -6), W.Accent)
		x = 18
	end
	Label(top, o.Title or W.Title, {Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -x, 1, 0), Color = T.Text, Weight = "SemiBold", Truncate = true})
	if o.Content or o.Text then
		local c = Label(card, o.Content or o.Text, {Size = UDim2.new(1, 0, 0, 0), Color = T.TextGray})
		c.AutomaticSize = Enum.AutomaticSize.Y
		c.TextWrapped = true
		c.LayoutOrder = 2
	end
	-- полоса таймера живёт в нижнем отступе карточки (хост нулевой высоты в конце списка)
	local barHost = Create("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 3, Parent = card})
	local bar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.fromOffset(0, 4),
		BackgroundColor3 = W.Accent,
		BackgroundTransparency = 1 - W.AccentAlpha,
		BorderSizePixel = 0,
		Parent = barHost,
	})
	Corner(bar, 1)

	local duration = o.Duration or o.Time or 4
	Tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
	Tween(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
	local closed = false
	local function Close()
		if closed then return end
		closed = true
		local t = Tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.fromOffset(260, 0)})
		t.Completed:Connect(function() holder:Destroy() end)
	end
	task.delay(duration, Close)
	SafeCall(o.Callback)
	return {Close = Close}
end

-- ============================================================================
-- ОКНО
-- ============================================================================
local function BuildShell(W)
	local Holder = Create("Frame", {
		Name = "Window",
		Size = UDim2.fromOffset(WIN_W, WIN_H),
		AnchorPoint = Vector2.new(0.5, 0.5), -- UIScale масштабирует вокруг AnchorPoint -> от центра
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = W.Gui,
	})
	W.Holder = Holder
	W.Scale = Create("UIScale", {Scale = 1, Parent = Holder})

	local Main = Create("Frame", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Active = true, Parent = Holder})
	W.Paint(Main, "BackgroundColor3", "WindowBg")
	Corner(Main, 6)
	W.Main = Main

	-- Header: скруглён сверху, снизу квадратная заливка; градиент подкрашен акцентом слева.
	local Header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 8,
		Parent = Main,
	})
	Corner(Header, 6)
	local HeaderFill = Create("Frame", {
		Size = UDim2.new(1, 0, 0, HEADER_H / 2),
		Position = UDim2.new(0, 0, 0, HEADER_H / 2),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = Header,
	})
	local grads = {Create("UIGradient", {Parent = Header}), Create("UIGradient", {Parent = HeaderFill})}
	W.Bind(function(T, accent, alpha)
		local tint = T.BarBg:Lerp(accent, 0.07 * (alpha or 1))
		local seq = ColorSequence.new({
			ColorSequenceKeypoint.new(0, tint),
			ColorSequenceKeypoint.new(0.16, T.BarBg),
			ColorSequenceKeypoint.new(1, T.BarBg),
		})
		for _, g in ipairs(grads) do g.Color = seq end
	end, Header)
	local hl = Create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BorderSizePixel = 0, Parent = Header})
	W.Paint(hl, "BackgroundColor3", "BarLine")
	MakeDraggable(W, Header, Holder)
	W.Header = Header

	local brand = Create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(9, 0),
		BackgroundTransparency = 1,
		Parent = Header,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = brand,
	})
	W.Brand = brand
	W.TitleLabel = Label(brand, W.Title, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Weight = "SemiBold"})
	W.TitleLabel.LayoutOrder = 2
	W.Paint(W.TitleLabel, "TextColor3", "Text")
	function W.BuildHeaderLogo()
		if W.HeaderLogo then W.HeaderLogo:Destroy() end
		W.HeaderLogo = CreateLogo(W, brand, W.LogoSpec, 12, 15)
		W.HeaderLogo.LayoutOrder = 1
	end
	W.BuildHeaderLogo()

	W.HeaderDivider = Create("Frame", {Size = UDim2.fromOffset(1, 15), BorderSizePixel = 0, Parent = Header})
	W.Paint(W.HeaderDivider, "BackgroundColor3", "Divider")

	local SetBtn = Create("TextButton", {
		Size = UDim2.fromOffset(26, 27),
		Position = UDim2.fromOffset(444.5, 4.5),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = Header,
	})
	W.Paint(SetBtn, "BackgroundColor3", "TileBg")
	Corner(SetBtn, 2)
	W.SetBtn = SetBtn
	W.GearIcon = CreateIcon(SetBtn, {"settings", "cog"}, 12, UDim2.new(0.5, -6, 0.5, -6))
	W.NavIcon(W.GearIcon)

	-- ширина 0 + AnchorPoint справа: кнопки раскладываются вручную влево от правого края
	W.SubHolder = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(0, 26),
		BackgroundTransparency = 1,
		Parent = Header,
	})
	W.SubIndicator = Create("Frame", {
		Size = UDim2.fromOffset(26, 26),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = W.SubHolder,
	})
	Corner(W.SubIndicator, 2)
	W.Paint(W.SubIndicator, "BackgroundColor3", "TileBg")

	-- Bottom bar
	local BottomBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, BOTTOM_H),
		Position = UDim2.new(0, 0, 1, -BOTTOM_H),
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = Main,
	})
	W.Paint(BottomBar, "BackgroundColor3", "BarBg")
	Corner(BottomBar, 6)
	local bf = Create("Frame", {Size = UDim2.new(1, 0, 0, BOTTOM_H / 2), BorderSizePixel = 0, Parent = BottomBar})
	W.Paint(bf, "BackgroundColor3", "BarBg")
	local bl = Create("Frame", {Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = BottomBar})
	W.Paint(bl, "BackgroundColor3", "BarLine")

	local BottomFade = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 41),
		Position = UDim2.fromOffset(0, HEADER_H + BODY_H - 41),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = Main,
	})
	W.Paint(BottomFade, "BackgroundColor3", "WindowBg")
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

	W.Fader = Create("Frame", {
		Size = UDim2.new(1, 0, 0, BODY_H),
		Position = UDim2.fromOffset(0, HEADER_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = Main,
	})
	W.Paint(W.Fader, "BackgroundColor3", "WindowBg")

	W.PopupLayer = Create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 30, Parent = Main})
	local ClickOutside = Create("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 30, Parent = W.PopupLayer})
	ClickOutside.MouseButton1Click:Connect(function() W.ClosePopup() end)

	W.NavHolder = Create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = BottomBar,
	})
	Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = W.NavHolder})

	W.NotifyHolder = Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0, 240, 1, -24),
		BackgroundTransparency = 1,
		Parent = W.Gui,
	})
	Create("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = W.NotifyHolder,
	})
end

local function BuildNavigation(W)
	function W.LayoutHeader()
		local x = 444.5
		if W.CfgBtn then
			x = x - 30.5
			W.CfgBtn.Position = UDim2.fromOffset(x, 4.5)
		end
		for _, b in ipairs(W.HeaderButtons) do
			x = x - 30.5
			b.Position = UDim2.fromOffset(x, 6)
		end
		local divX = x - 5
		W.HeaderDivider.Position = UDim2.fromOffset(divX, 10.5)
		W.SubHolder.Position = UDim2.new(0, divX - 14, 0.5, 0)
	end
	W.LayoutHeader()

	function W.RelayoutNav()
		local n = #W.Tabs
		if n == 0 then return end
		local bw = math.min(102, math.floor((WIN_W - 16) / n))
		W.NavHolder.Size = UDim2.new(0, bw * n, 1, 0)
		W.NavHolder.Position = UDim2.new(0.5, -bw * n / 2, 0, 0)
		for _, t in ipairs(W.Tabs) do
			t.Button.Size = UDim2.new(0, bw, 1, 0)
			t.TileOn = UDim2.fromOffset(bw - 8, 27)
			t.TileOff = UDim2.fromOffset(bw - 22, 23)
		end
	end

	function W.PageFor()
		local m = W.Nav.main
		if m == "settings" then return W.SettingsPage end
		if m == "configs" then return W.ConfigPage end
		if #m.Subs > 0 and m.CurSub then return m.CurSub.Page end
		return m.Page
	end

	local ActiveTweens = {}
	local SwitchToken = 0
	function W.ShowPage(page, animate)
		SwitchToken = SwitchToken + 1
		local token = SwitchToken
		for _, t in ipairs(ActiveTweens) do t:Cancel() end
		table.clear(ActiveTweens)

		local function Swap()
			for _, p in ipairs(W.Pages) do
				if p ~= page then p.Show(false) end
			end
			page.ScrollTo(0, true)
			page.Show(true)
			if animate then
				page.scroll.Position = UDim2.fromOffset(0, HEADER_H + 12)
				W.Fader.BackgroundTransparency = 0
				table.insert(ActiveTweens, Tween(page.scroll, TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, HEADER_H)}))
				table.insert(ActiveTweens, Tween(W.Fader, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}))
			else
				page.scroll.Position = UDim2.fromOffset(0, HEADER_H)
				W.Fader.BackgroundTransparency = 1
			end
		end

		if not animate then
			Swap()
			return
		end
		local out = TweenService:Create(W.Fader, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 0})
		table.insert(ActiveTweens, out)
		out.Completed:Connect(function(state)
			if state ~= Enum.PlaybackState.Completed or token ~= SwitchToken then return end
			Swap()
		end)
		out:Play()
	end

	function W.RefreshAccentIcons()
		for _, ic in ipairs(W.AccentIcons) do
			ic.ImageColor3 = W.Accent
			ic.ImageTransparency = 1 - W.AccentAlpha
		end
	end

	-- Под-вкладки живут, пока открыта та же вкладка. Плашка активной вкладки общая:
	-- при переключении она переезжает и накрывает новую вкладку, та раскрывается, старая сворачивается.
	local Sub = {tab = nil, count = 0, items = {}}
	local SUB_TI = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local SUB_GAP = 5

	local function SubWidth(it)
		local w = it.label.TextBounds.X
		if w <= 0 then w = TextWidth(it.sub.Name, TEXT) end
		return math.floor(it.textX + w + 8 + 0.5)
	end

	local function LayoutSubs(animate)
		local tab, T = Sub.tab, W.Theme
		local right, activeX, activeW = 0, nil, nil
		for i = #Sub.items, 1, -1 do
			local it = Sub.items[i]
			local active = tab ~= nil and it.sub == tab.CurSub
			local w = active and SubWidth(it) or 26
			local x = -(right + w)
			right = right + w + SUB_GAP
			if active then activeX, activeW = x, w end
			local props = {Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 26)}
			local iconProps = it.icon and {
				ImageColor3 = active and W.Accent or T.NavGray,
				ImageTransparency = active and (1 - W.AccentAlpha) or 0,
			}
			if animate then
				Tween(it.btn, SUB_TI, props)
				Tween(it.label, SUB_TI, {TextTransparency = active and 0 or 1})
				if it.letter then Tween(it.letter, SUB_TI, {TextTransparency = active and 1 or 0}) end
				if iconProps then Tween(it.icon, SUB_TI, iconProps) end
			else
				it.btn.Position, it.btn.Size = props.Position, props.Size
				it.label.TextTransparency = active and 0 or 1
				if it.letter then it.letter.TextTransparency = active and 1 or 0 end
				if iconProps then it.icon.ImageColor3, it.icon.ImageTransparency = iconProps.ImageColor3, iconProps.ImageTransparency end
			end
			it.label.TextColor3 = T.Text
			if it.letter then it.letter.TextColor3 = T.NavGray end
		end
		local ind = W.SubIndicator
		if not activeX then
			ind.BackgroundTransparency = 1
			return
		end
		local props = {Position = UDim2.fromOffset(activeX, 0), Size = UDim2.fromOffset(activeW, 26), BackgroundTransparency = 0}
		if animate and ind.BackgroundTransparency < 1 then
			Tween(ind, SUB_TI, props)
		else
			ind.Position, ind.Size, ind.BackgroundTransparency = props.Position, props.Size, 0
		end
	end

	local function ClearSubs()
		for _, it in ipairs(Sub.items) do it.btn:Destroy() end
		table.clear(Sub.items)
		Sub.tab, Sub.count = nil, 0
		W.SubIndicator.BackgroundTransparency = 1
		W.Prune()
	end

	function W.BuildSubTabs(instant)
		local tab = W.Nav.main
		if type(tab) ~= "table" or #tab.Subs == 0 then
			if Sub.tab then ClearSubs() end
			return
		end
		local fresh = Sub.tab ~= tab or Sub.count ~= #tab.Subs
		if fresh then
			ClearSubs()
			Sub.tab, Sub.count = tab, #tab.Subs
			for i, sub in ipairs(tab.Subs) do
				local b = Create("TextButton", {
					Size = UDim2.fromOffset(26, 26),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 2,
					LayoutOrder = i,
					Parent = W.SubHolder,
				})
				local it = {sub = sub, btn = b, textX = 7}
				if sub.Icon then
					it.icon = CreateIcon(b, sub.Icon, 12, UDim2.fromOffset(7, 7), W.Theme.NavGray)
					it.textX = 25
				else
					-- без иконки свёрнутая вкладка показывает первую букву
					it.letter = Label(b, tostring(sub.Name):sub(1, 1), {Size = UDim2.fromOffset(26, 26), Align = Enum.TextXAlignment.Center, Weight = "SemiBold"})
				end
				it.label = Label(b, sub.Name, {Position = UDim2.fromOffset(it.textX, 0), AutoX = true, Size = UDim2.new(0, 0, 1, 0)})
				it.label:GetPropertyChangedSignal("TextBounds"):Connect(function()
					if Sub.tab == tab and tab.CurSub == sub then LayoutSubs(false) end
				end)
				b.MouseButton1Click:Connect(function()
					if tab.CurSub == sub then return end
					tab.CurSub = sub
					W.Navigated = true
					W.RefreshNav()
				end)
				table.insert(Sub.items, it)
			end
		end
		LayoutSubs((not instant) and not fresh)
	end

	W.Bind(function() LayoutSubs(false) end)

	function W.RefreshNav(instant)
		if not W.Alive then return end
		W.ClosePopup()
		table.clear(W.AccentIcons)
		local T = W.Theme

		local page = W.PageFor()
		if page ~= W.CurrentPage then
			W.ShowPage(page, W.CurrentPage ~= nil and not instant)
			W.CurrentPage = page
		end

		for _, t in ipairs(W.Tabs) do
			local active = W.Nav.main == t
			local tileProps = {BackgroundTransparency = active and 0 or 1, Size = active and t.TileOn or t.TileOff}
			local lblProps = {TextColor3 = active and T.Text or T.NavGray}
			if instant then
				t.Tile.BackgroundTransparency, t.Tile.Size = tileProps.BackgroundTransparency, tileProps.Size
				t.Label.TextColor3 = lblProps.TextColor3
			else
				Tween(t.Tile, TI_FAST, tileProps)
				Tween(t.Label, TI_FAST, lblProps)
			end
			t.Icon.ImageColor3 = T.NavGray
			t.Icon.ImageTransparency = 0
			if active then table.insert(W.AccentIcons, t.Icon) end
		end

		local gearActive = W.Nav.main == "settings"
		if instant then
			W.SetBtn.BackgroundTransparency = gearActive and 0 or 1
		else
			Tween(W.SetBtn, TI_FAST, {BackgroundTransparency = gearActive and 0 or 1})
		end
		W.GearIcon.ImageColor3 = T.NavGray
		W.GearIcon.ImageTransparency = 0
		if gearActive then table.insert(W.AccentIcons, W.GearIcon) end

		if W.CfgBtn then
			local cfgActive = W.Nav.main == "configs"
			if instant then
				W.CfgBtn.BackgroundTransparency = cfgActive and 0 or 1
			else
				Tween(W.CfgBtn, TI_FAST, {BackgroundTransparency = cfgActive and 0 or 1})
			end
			W.CfgIcon.ImageColor3 = T.NavGray
			W.CfgIcon.ImageTransparency = 0
			if cfgActive then table.insert(W.AccentIcons, W.CfgIcon) end
		end

		W.BuildSubTabs(instant)
		W.RefreshAccentIcons()
	end

	-- Перекраска навигации при смене темы/акцента без закрытия попапов.
	W.Bind(function(T)
		for _, t in ipairs(W.Tabs) do
			t.Label.TextColor3 = (W.Nav.main == t) and T.Text or T.NavGray
		end
		W.RefreshAccentIcons()
	end)

	W.SetBtn.MouseButton1Click:Connect(function()
		W.Nav.main = "settings"
		W.Navigated = true
		W.RefreshNav()
	end)
end

local function AddTab(W, o)
	o = Opts(o)
	local tab = {Name = o.Name or o.Title or ("Tab " .. (#W.Tabs + 1)), Subs = {}}
	tab.Page = NewPage(W)

	local btn = Create("TextButton", {
		Size = UDim2.new(0, 102, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		LayoutOrder = #W.Tabs + 1,
		Parent = W.NavHolder,
	})
	local tile = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(80, 23),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = btn,
	})
	W.Paint(tile, "BackgroundColor3", "TileBg")
	Corner(tile, 2)
	local content = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
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
	local ic = Create("ImageLabel", {Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, LayoutOrder = 1, Parent = content})
	ic.Visible = ApplyIcon(ic, o.Icon)
	local lbl = Label(content, tab.Name, {AutoX = true, Size = UDim2.new(0, 0, 1, 0), Color = W.Theme.NavGray})
	lbl.LayoutOrder = 2
	tab.Button, tab.Tile, tab.Icon, tab.Label = btn, tile, ic, lbl
	W.NavIcon(ic)

	table.insert(W.Tabs, tab)
	W.RelayoutNav()

	btn.MouseButton1Click:Connect(function()
		W.Nav.main = tab
		W.Navigated = true
		W.RefreshNav()
	end)

	local api = {Name = tab.Name}
	AttachSections(W, api, tab.Page)
	Method(api, "Select", function()
		W.Nav.main = tab
		W.Navigated = true
		W.RefreshNav()
	end)
	Method(api, "SetName", function(t)
		tab.Name = tostring(t)
		lbl.Text = tab.Name
	end)
	Method(api, "SetIcon", function(spec) ic.Visible = ApplyIcon(ic, spec) end)
	Method(api, "AddSubTab", function(so)
		so = Opts(so)
		local sub = {Name = so.Name or so.Title or ("Page " .. (#tab.Subs + 1)), Icon = so.Icon}
		sub.Page = NewPage(W)
		table.insert(tab.Subs, sub)
		if not tab.CurSub or so.Default then tab.CurSub = sub end
		if W.Nav.main == tab then W.RefreshNav(true) end
		local sapi = {Name = sub.Name}
		AttachSections(W, sapi, sub.Page)
		Method(sapi, "Select", function()
			W.Nav.main = tab
			tab.CurSub = sub
			W.Navigated = true
			W.RefreshNav()
		end)
		return sapi
	end)
	api.SubTab = api.AddSubTab
	api.AddPage = api.AddSubTab
	api.CreateSubTab = api.AddSubTab

	if o.Default or (not W.Navigated and #W.Tabs == 1) then
		W.Nav.main = tab
	end
	W.RefreshNav(true)
	return api
end

local function BuildSettings(W, o)
	local page = NewPage(W)
	W.SettingsPage = page
	local api = AttachSections(W, {}, page)
	W.SettingsApi = api

	local appearance = NewSection(W, page, {Name = "Appearance", Side = "Left"})
	W.ThemeDropdown = appearance.AddDropdown({
		Name = "Theme", Icon = "moon",
		Options = CopyList(Library.ThemeOrder), Default = W.ThemeName,
		Flag = "__ZeninTheme",
		Callback = function(v) W.SetTheme(v) end,
	})
	AccentPicker(W, appearance, "Accent Color")

	local interface = NewSection(W, page, {Name = "Interface", Side = "Left"})
	W.ScaleDropdown = interface.AddDropdown({
		Name = "UI Scale", Icon = {"expand", "maximize-2"},
		Options = SCALE_OPTIONS, Default = "2.5x",
		Flag = "__ZeninScale",
		Callback = function(v) W.SetScale(SCALE_MAP[v] or 1, true) end,
	})
	W.ScrollSlider = interface.AddSlider({
		Name = "Scrollbar Size", Min = 1, Max = 25, Default = W.BarW, Suffix = "px",
		Flag = "__ZeninScrollbar",
		Callback = function(v) W.SetBarWidth(v) end,
	})

	local wm = NewSection(W, page, {Name = "Watermark", Side = "Right"})
	W.WmOpacity = wm.AddSlider({
		Name = "Opacity", Min = 0, Max = 100, Default = 100, Suffix = "%",
		Flag = "__ZeninWmOpacity",
		Callback = function(v)
			W.WM.Opacity = v / 100
			W.WM.ApplyOpacity()
		end,
	})
	W.WmIcons = wm.AddToggle({
		Name = "Show Icons", Default = true,
		Flag = "__ZeninWmIcons",
		Callback = function(v) W.WM.SetIconsVisible(v) end,
	})
	W.WmDetails = wm.AddDropdown({
		Name = "Details", Options = DETAIL_MODES, Default = W.WM.Mode,
		Flag = "__ZeninWmDetails",
		Callback = function(v) W.WM.Mode = v end,
	})
	return api
end

-- Страница конфигов (кнопка слева от шестерёнки): Actions + Config List.
local function BuildConfigs(W, Window)
	local page = NewPage(W, true)
	W.ConfigPage = page
	local api = AttachSections(W, {}, page)
	local state = {active = nil}

	local btn = Create("TextButton", {
		Size = UDim2.fromOffset(26, 27),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = W.Header,
	})
	W.Paint(btn, "BackgroundColor3", "TileBg")
	Corner(btn, 2)
	W.CfgBtn = btn
	W.CfgIcon = CreateIcon(btn, {"file-text", "file"}, 12, UDim2.new(0.5, -6, 0.5, -6))
	W.NavIcon(W.CfgIcon)
	btn.MouseButton1Click:Connect(function() Window.SelectConfigs() end)
	W.LayoutHeader()

	local function Note(text)
		Window.Notify({Title = "Configs", Content = text, Icon = {"file-text", "file"}, Duration = 2.5})
	end

	-- ---------- Actions ----------
	local actions = NewSection(W, page, {Name = "Actions"})
	local box = Create("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Name (optional)",
		ClearTextOnFocus = false,
		TextSize = TEXT,
		Weight = "Medium",
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = actions._raw(25),
	})
	Corner(box, 3)
	local boxStroke = Stroke(box, WHITE, 1)
	Create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = box})
	W.Bind(function(T)
		box.BackgroundColor3 = T.DropdownBg
		boxStroke.Color = T.DropdownBorder
		box.TextColor3 = T.Text
		box.PlaceholderColor3 = T.TextDim
	end, box)

	local function WideButton(sec, text, icon, fn)
		local b = Create("TextButton", {Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = sec._raw(27)})
		Corner(b, 3)
		local st = Stroke(b, WHITE, 1)
		local content = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 0, 0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = b,
		})
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
			Parent = content,
		})
		local ic = Create("ImageLabel", {Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, LayoutOrder = 1, Parent = content})
		ApplyIcon(ic, icon)
		local lb = Label(content, text, {AutoX = true, Size = UDim2.new(0, 0, 1, 0)})
		lb.LayoutOrder = 2
		local hover = false
		local function Paint()
			local T = W.Theme
			b.BackgroundColor3 = hover and T.TileHover or T.DropdownBg
			st.Color = T.DropdownBorder
			lb.TextColor3 = hover and T.Text or T.TextGray
			ic.ImageColor3 = lb.TextColor3
		end
		W.Bind(Paint, b)
		b.MouseEnter:Connect(function() hover = true Paint() end)
		b.MouseLeave:Connect(function() hover = false Paint() end)
		b.MouseButton1Click:Connect(fn)
		return b
	end

	-- ---------- Config List ----------
	local list = NewSection(W, page, {Name = "Config List"})
	local activeLbl = Label(list._raw(16), "Active: None")
	W.Paint(activeLbl, "TextColor3", "TextGray")
	local holder = list._raw(0)
	Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder})

	local Refresh
	local function IconButton(parent, x, icon, onClick)
		local b = Create("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, x, 0.5, -12),
			BackgroundTransparency = 1,
			Text = "",
			Parent = parent,
		})
		local ic = CreateIcon(b, icon, 12, UDim2.new(0.5, -6, 0.5, -6))
		local st = {hover = false}
		function st.Paint()
			local T = W.Theme
			ic.ImageColor3 = st.hover and T.Text or T.NavGray
		end
		W.Bind(st.Paint, b)
		b.MouseEnter:Connect(function() st.hover = true st.Paint() end)
		b.MouseLeave:Connect(function() st.hover = false st.Paint() end)
		b.MouseButton1Click:Connect(function() onClick(st) end)
		return st
	end

	local function Item(i, name)
		local row = Create("Frame", {Size = UDim2.new(1, 0, 0, 45), BorderSizePixel = 0, LayoutOrder = i, Parent = holder})
		Corner(row, 3)
		W.Paint(row, "BackgroundColor3", "DropdownBg")
		local title = Label(row, name .. ".cfg", {Position = UDim2.fromOffset(14, 7), Size = UDim2.new(1, -110, 0, 16), Weight = "SemiBold", Truncate = true})
		local idx = Label(row, tostring(i), {Position = UDim2.fromOffset(14, 24), Size = UDim2.new(1, -110, 0, 14), TextSize = 10})
		W.Bind(function(T, accent)
			title.TextColor3 = (state.active == name) and accent or T.Text
			idx.TextColor3 = T.TextDim
		end, row)

		IconButton(row, -92, {"download", "import"}, function()
			local ok, err = Window.LoadConfig(name)
			if ok then
				state.active = name
				Refresh()
				Note("Loaded " .. name .. ".cfg")
			else
				Note("Load failed: " .. tostring(err))
			end
		end)
		IconButton(row, -64, {"save"}, function()
			local ok, err = Window.SaveConfig(name)
			Note(ok and ("Saved " .. name .. ".cfg") or ("Save failed: " .. tostring(err)))
		end)
		IconButton(row, -36, {"trash-2", "trash"}, function()
			if not Window.DeleteConfig(name) then
				Note("Delete failed: " .. name .. ".cfg")
				return
			end
			if state.active == name then state.active = nil end
			Refresh()
			Note("Deleted " .. name .. ".cfg")
		end)
	end

	function Refresh()
		for _, ch in ipairs(holder:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		W.Prune()
		local names = Window.ListConfigs()
		if #names == 0 then
			local empty = Label(holder, "No configs yet", {Size = UDim2.new(1, 0, 0, 20)})
			W.Paint(empty, "TextColor3", "TextDim")
			holder.Size = UDim2.new(1, 0, 0, 20)
		else
			for i, name in ipairs(names) do Item(i, name) end
			holder.Size = UDim2.new(1, 0, 0, #names * 45 + (#names - 1) * 5)
		end
		activeLbl.Text = "Active: " .. (state.active and (state.active .. ".cfg") or "None")
	end

	local function Unique(name)
		local taken = {}
		for _, n in ipairs(Window.ListConfigs()) do taken[n] = true end
		if not taken[name] then return name end
		local k = 1
		while taken[name .. "-" .. k] do k = k + 1 end
		return name .. "-" .. k
	end

	WideButton(actions, "Create New", {"file-plus", "file"}, function()
		local name = tostring(box.Text):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.cfg$", ""):gsub("[^%w%-_ ]", "_")
		if name == "" then name = "config_" .. (#Window.ListConfigs() + 1) end
		name = Unique(name)
		local ok, err = Window.SaveConfig(name)
		if ok then
			state.active = name
			box.Text = ""
			Refresh()
			Note("Created " .. name .. ".cfg")
		else
			Note("Create failed: " .. tostring(err))
		end
	end)
	WideButton(actions, "Refresh List", {"refresh-cw"}, function() Refresh() end)

	Refresh()
	W.ConfigState = state
	W.RefreshConfigs = Refresh
	return api
end

local function CreateWindow(o)
	o = Opts(o)
	if o.Name and not o.Title then o.Title = o.Name end
	if Library.ActiveWindow then pcall(Library.ActiveWindow.Destroy) end

	local themeName = Library.Themes[o.Theme or ""] and o.Theme or "Dark"
	local W = {
		Alive = true,
		Title = o.Title or "Zenin",
		ThemeName = themeName,
		Theme = Library.Themes[themeName],
		Accent = o.Accent or rgb(255, 89, 89),
		AccentAlpha = o.AccentAlpha or 1,
		Listeners = {}, Conns = {}, PopupConns = {},
		Pages = {}, Tabs = {}, Elements = {}, HeaderButtons = {}, AccentIcons = {}, UnloadCallbacks = {},
		BarW = math.clamp(math.floor(tonumber(o.ScrollbarSize) or 6), 1, 25),
		WheelScroll = o.MouseWheel == true,
		ToggleKey = o.ToggleKey or o.Keybind or Enum.KeyCode.RightShift,
		Nav = {main = "settings"},
		NotifyOrder = 0,
		ConfigFolder = o.ConfigFolder or Library.ConfigFolder,
	}
	W.LogoSpec = NormalizeLogo(o.Logo or o.Icon, W.Title)
	LoadIcons()

	-- Подписки на тему/акцент. owner = инстанс: когда он уничтожен (Parent == nil),
	-- подписка выкидывается при ближайшем Prune (удаление элементов/секций, смена темы).
	function W.Bind(fn, owner)
		table.insert(W.Listeners, {fn = fn, owner = owner})
		fn(W.Theme, W.Accent, W.AccentAlpha)
	end
	function W.Prune()
		local alive = {}
		for _, e in ipairs(W.Listeners) do
			if not e.owner or e.owner.Parent then table.insert(alive, e) end
		end
		W.Listeners = alive
	end
	function W.Refresh()
		W.Prune()
		for _, e in ipairs(W.Listeners) do
			local ok, err = pcall(e.fn, W.Theme, W.Accent, W.AccentAlpha)
			if not ok then warn("[Zenin] theme listener error: " .. tostring(err)) end
		end
	end
	function W.Paint(obj, prop, key)
		W.Bind(function(T) obj[prop] = T[key] end, obj)
	end
	-- Серые иконки навигации (кроме активных, которые красятся акцентом).
	function W.NavIcon(ic)
		W.Bind(function(T)
			if not IndexOf(W.AccentIcons, ic) then ic.ImageColor3 = T.NavGray end
		end, ic)
	end
	function W.Connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(W.Conns, c)
		return c
	end
	-- Единственная пара глобальных подключений ввода на окно: перетаскивание окна/ватермарка,
	-- слайдеры, скроллбары и пикер цвета регистрируют здесь активный drag, а не свои соединения.
	W.Drag = nil
	-- Если InputEnded потерялся (отпустили за окном игры, alt-tab), прежний drag зависает.
	-- Новое нажатие тем же способом значит, что старое уже закончилось.
	local function Stale(d, input)
		if d.input == input then return false end
		if d.input.UserInputType == Enum.UserInputType.Touch then
			return d.input.UserInputState == Enum.UserInputState.End
		end
		return input.UserInputType == d.input.UserInputType
	end
	function W.BeginDrag(input, move, finish, tag)
		if W.Drag and Stale(W.Drag, input) then W.CancelDrag() end
		if W.Drag then return false end
		W.Drag = {input = input, move = move, finish = finish, tag = tag}
		return true
	end
	function W.CancelDrag(tag)
		local d = W.Drag
		if d and (tag == nil or d.tag == tag) then
			W.Drag = nil
			if d.finish then SafeCall(d.finish, nil, true) end
		end
	end
	local function SameInput(d, input, ended)
		if d.input.UserInputType == Enum.UserInputType.Touch then return input == d.input end
		if ended then return input.UserInputType == d.input.UserInputType end
		return input.UserInputType == Enum.UserInputType.MouseMovement
	end
	W.Connect(UserInputService.InputChanged, function(input)
		local d = W.Drag
		if d and d.move and SameInput(d, input, false) then SafeCall(d.move, input) end
	end)
	W.Connect(UserInputService.InputEnded, function(input)
		local d = W.Drag
		if not d or not SameInput(d, input, true) then return end
		W.Drag = nil
		if d.finish then SafeCall(d.finish, input, false) end
	end)

	function W.ClosePopup()
		W.CancelDrag("popup")
		for _, c in ipairs(W.PopupConns) do c:Disconnect() end
		table.clear(W.PopupConns)
		if W.ActivePopup then
			W.ActivePopup:Destroy()
			W.ActivePopup = nil
		end
		W.PopupOwner = nil
		if W.PopupLayer then W.PopupLayer.Visible = false end
	end
	function W.SetAccent(c, alpha)
		if typeof(c) == "Color3" then W.Accent = c end
		if alpha then W.AccentAlpha = math.clamp(alpha, 0, 1) end
		W.Refresh()
	end
	function W.SetTheme(name)
		local t = Library.Themes[name]
		if not t then return false end
		W.Theme, W.ThemeName = t, name
		W.Refresh()
		if W.ThemeDropdown and W.ThemeDropdown.Get() ~= name then W.ThemeDropdown.Set(name, true) end
		return true
	end
	function W.SetScale(s, animate)
		s = math.clamp(tonumber(s) or 1, 0.3, 3)
		if animate then
			Tween(W.Scale, TweenInfo.new(0.18), {Scale = s})
		else
			W.Scale.Scale = s
		end
	end
	function W.SetBarWidth(v)
		W.BarW = math.clamp(math.floor((tonumber(v) or 6) + 0.5), 1, 25)
		for _, p in ipairs(W.Pages) do
			p.LayoutColumns()
			p.Update()
		end
	end

	-- ScreenGui
	local parent = o.Parent
	if not parent then
		local ok, hui = pcall(function() return gethui and gethui() end)
		parent = (ok and hui) or LocalPlayer:WaitForChild("PlayerGui")
	end
	local guiName = o.GuiName or Library.GuiName
	local old = parent:FindFirstChild(guiName)
	if old then old:Destroy() end
	W.Gui = Create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = o.DisplayOrder or 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	W.WatermarkApi = BuildWatermark(W, o.Watermark)
	BuildShell(W)
	BuildNavigation(W)
	local settingsApi = BuildSettings(W, o)
	if o.Scale then W.SetScale(o.Scale) end
	W.RefreshNav(true)

	W.Connect(UserInputService.InputBegan, function(input, gp)
		if not gp and W.ToggleKey and input.KeyCode == W.ToggleKey then
			W.Window.Toggle()
		end
	end)

	-- ======================== публичный API окна ========================
	local Window = {Library = Library, Settings = settingsApi}
	W.Window = Window
	Window.Watermark = W.WatermarkApi

	Method(Window, "AddTab", function(x) return AddTab(W, x) end)
	Window.Tab = Window.AddTab
	Window.CreateTab = Window.AddTab
	Method(Window, "AddSettingsSection", function(x) return settingsApi.AddSection(x) end)
	Method(Window, "SelectSettings", function()
		W.Nav.main = "settings"
		W.Navigated = true
		W.RefreshNav()
	end)

	Method(Window, "SetTitle", function(t)
		W.Title = tostring(t)
		W.TitleLabel.Text = W.Title
	end)
	Method(Window, "SetLogo", function(spec)
		W.LogoSpec = NormalizeLogo(spec, W.Title)
		W.BuildHeaderLogo()
		W.WM.BuildLogo()
	end)

	Method(Window, "SetTheme", function(name) return W.SetTheme(name) end)
	Method(Window, "GetTheme", function() return W.ThemeName end)
	Method(Window, "GetThemes", function() return CopyList(Library.ThemeOrder) end)
	Method(Window, "SetAccent", function(c, a) W.SetAccent(c, a) end)
	Method(Window, "GetAccent", function() return W.Accent, W.AccentAlpha end)
	Method(Window, "SetScale", function(s, animate) W.SetScale(s, animate) end)
	Method(Window, "GetScale", function() return W.Scale.Scale end)
	Method(Window, "SetScrollbarSize", function(px) W.ScrollSlider.Set(px) end)
	Method(Window, "SetMouseWheel", function(b)
		W.WheelScroll = b == true
		for _, p in ipairs(W.Pages) do p.scroll.ScrollingEnabled = W.WheelScroll end
	end)

	Method(Window, "SetVisible", function(b)
		W.Holder.Visible = b ~= false
		if not W.Holder.Visible then W.ClosePopup() end
	end)
	Method(Window, "Show", function() Window.SetVisible(true) end)
	Method(Window, "Hide", function() Window.SetVisible(false) end)
	Method(Window, "Toggle", function() Window.SetVisible(not W.Holder.Visible) end)
	Method(Window, "IsVisible", function() return W.Holder.Visible end)
	Method(Window, "SetToggleKey", function(k) W.ToggleKey = k end)
	Method(Window, "GetToggleKey", function() return W.ToggleKey end)
	Method(Window, "SetPosition", function(p) W.Holder.Position = p end)
	Method(Window, "Center", function()
		Tween(W.Holder, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)})
	end)

	Method(Window, "AddHeaderButton", function(bo)
		bo = Opts(bo)
		local b = Create("TextButton", {
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			Text = "",
			Parent = W.Header,
		})
		local ic = CreateIcon(b, bo.Icon or "circle", 12, UDim2.new(0.5, -6, 0.5, -6))
		W.Paint(ic, "ImageColor3", "NavGray")
		b.MouseEnter:Connect(function() ic.ImageColor3 = W.Theme.Text end)
		b.MouseLeave:Connect(function() ic.ImageColor3 = W.Theme.NavGray end)
		b.MouseButton1Click:Connect(function() SafeCall(bo.Callback) end)
		table.insert(W.HeaderButtons, b)
		W.LayoutHeader()
		local hb = {}
		Method(hb, "SetIcon", function(spec) ApplyIcon(ic, spec) end)
		Method(hb, "SetCallback", function(fn) bo.Callback = fn end)
		Method(hb, "Destroy", function()
			local i = IndexOf(W.HeaderButtons, b)
			if i then table.remove(W.HeaderButtons, i) end
			b:Destroy()
			W.LayoutHeader()
		end)
		return hb
	end)

	Method(Window, "Notify", function(x) return Notify(W, x) end)

	-- Конфиги
	Method(Window, "GetConfig", function()
		local data = {Flags = {}, Accent = ToHex(W.Accent), AccentAlpha = W.AccentAlpha}
		for _, el in ipairs(W.Elements) do
			if el.Flag and el.Get then data.Flags[el.Flag] = el.Get() end
		end
		return data
	end)
	Method(Window, "ApplyConfig", function(data)
		if type(data) ~= "table" then return false end
		local c = data.Accent and FromHex(data.Accent)
		if c then W.SetAccent(c, data.AccentAlpha) end
		for flag, v in pairs(data.Flags or {}) do
			local el = Library.Options[flag]
			if el and el.Set then pcall(el.Set, v) end
		end
		return true
	end)
	local function Folder()
		local f = W.ConfigFolder
		if f == nil or f == "" then return nil end
		if isfolder and makefolder then
			local ok, exists = pcall(isfolder, f)
			if not (ok and exists) then pcall(makefolder, f) end
		end
		return f
	end
	local function Path(name)
		local f = Folder()
		local file = tostring(name or "default") .. ".cfg"
		return f and (f .. "/" .. file) or file
	end
	Method(Window, "SaveConfig", function(name)
		if not writefile then return false, "writefile unsupported" end
		local ok, err = pcall(function()
			writefile(Path(name), HttpService:JSONEncode(Window.GetConfig()))
		end)
		return ok, err
	end)
	Method(Window, "LoadConfig", function(name)
		if not (readfile and isfile) then return false, "readfile unsupported" end
		local path = Path(name)
		local okf, exists = pcall(isfile, path)
		if not (okf and exists) then return false, "not found" end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
		if not ok then return false, data end
		return Window.ApplyConfig(data)
	end)
	Method(Window, "DeleteConfig", function(name)
		local path = Path(name)
		if not (delfile and isfile) then return false end
		local okf, exists = pcall(isfile, path)
		if not (okf and exists) then return false end
		return (pcall(delfile, path))
	end)
	Method(Window, "ListConfigs", function()
		local out = {}
		if not listfiles then return out end
		local files
		local f = Folder()
		-- корень workspace экзекуторы принимают по-разному
		for _, dir in ipairs(f and {f} or {"", ".", "./"}) do
			local ok, res = pcall(listfiles, dir)
			if ok and type(res) == "table" then
				files = res
				break
			end
		end
		if not files then return out end
		local seen = {}
		for _, file in ipairs(files) do
			local n = tostring(file):match("([^/\\]+)%.cfg$")
			if n and not seen[n] then
				seen[n] = true
				table.insert(out, n)
			end
		end
		table.sort(out)
		return out
	end)

	Method(Window, "EnableConfigs", function(co)
		if W.ConfigPage then return W.ConfigApi end
		co = co or {}
		if co.Folder then W.ConfigFolder = co.Folder end
		W.ConfigApi = BuildConfigs(W, Window)
		W.RefreshNav(true)
		return W.ConfigApi
	end)
	Method(Window, "SelectConfigs", function()
		if not W.ConfigPage then return end
		W.Nav.main = "configs"
		W.Navigated = true
		W.RefreshNav()
		W.RefreshConfigs()
	end)
	Method(Window, "RefreshConfigs", function() if W.RefreshConfigs then W.RefreshConfigs() end end)
	Method(Window, "GetActiveConfig", function() return W.ConfigState and W.ConfigState.active end)
	Method(Window, "GetStats", function()
		return {
			Listeners = #W.Listeners,
			Connections = #W.Conns,
			Elements = #W.Elements,
			Pages = #W.Pages,
			Instances = W.Alive and #W.Gui:GetDescendants() or 0,
		}
	end)

	Method(Window, "OnUnload", function(fn) table.insert(W.UnloadCallbacks, fn) end)
	Method(Window, "Destroy", function()
		if not W.Alive then return end
		W.Alive = false
		W.ClosePopup()
		W.CancelDrag()
		for _, p in ipairs(W.Pages) do p.StopScroll() end
		for _, c in ipairs(W.Conns) do pcall(function() c:Disconnect() end) end
		table.clear(W.Conns)
		local hi = IndexOf(ThemeHooks, W.ThemeHook)
		if hi then table.remove(ThemeHooks, hi) end
		for _, el in ipairs(W.Elements) do
			if el.Flag then
				Library.Flags[el.Flag] = nil
				Library.Options[el.Flag] = nil
			end
		end
		for _, fn in ipairs(W.UnloadCallbacks) do SafeCall(fn) end
		W.Gui:Destroy()
		-- отпускаем все ссылки на инстансы и замыкания, чтобы GC собрал окно целиком
		W.Listeners = {}
		for _, t in ipairs({W.Elements, W.Pages, W.Tabs, W.HeaderButtons, W.AccentIcons, W.UnloadCallbacks, W.PopupConns}) do
			table.clear(t)
		end
		W.ActivePopup, W.PopupOwner, W.CurrentPage, W.ConfigPage = nil, nil, nil, nil
		if Library.ActiveWindow == Window then Library.ActiveWindow = nil end
	end)
	Window.Unload = Window.Destroy

	W.ThemeHook = function()
		if W.Alive and W.ThemeDropdown then W.ThemeDropdown.SetOptions(CopyList(Library.ThemeOrder), true) end
	end
	table.insert(ThemeHooks, W.ThemeHook)
	if o.Configs then Window.EnableConfigs(type(o.Configs) == "table" and o.Configs or nil) end

	Library.ActiveWindow = Window
	return Window
end

Method(Library, "CreateWindow", CreateWindow)
Library.Window = Library.CreateWindow
Library.new = Library.CreateWindow
Method(Library, "Notify", function(o)
	if Library.ActiveWindow then return Library.ActiveWindow.Notify(o) end
	return nil
end)
Method(Library, "Unload", function()
	if Library.ActiveWindow then Library.ActiveWindow.Destroy() end
end)

return Library
