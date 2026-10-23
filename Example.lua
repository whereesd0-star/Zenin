-- Пример: эталонное меню Zenin Internal, собранное на ZeninLib.
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()

local Window = Library:CreateWindow({
	Title = "Zenin Internal",
	Logo = "Z", -- буква/текст; или "zap" (Lucide-иконка); или "rbxassetid://123" (картинка)
	ToggleKey = Enum.KeyCode.RightShift,
	Configs = true, -- кнопка конфигов слева от шестерёнки
	Accent = Color3.fromRGB(255, 89, 89),
	Watermark = {
		Title = "zenin",
		Site = "zenin.cc",
		Detail = "internal",
		Version = "v2.4",
	},
})

-- ===== Combat =====
local Combat = Window:AddTab({Name = "Combat", Icon = {"crosshair", "target"}})

local Aimbot = Combat:AddSubTab({Name = "Aimbot", Icon = {"crosshair", "target"}})
do
	local main = Aimbot:AddSection({Side = "Left"})
	local aim = main:AddToggle({Name = "Aimbot", Flag = "Aimbot"})
	main:AddToggle({Name = "Silent", Flag = "Silent", DependsOn = aim})

	local target = Aimbot:AddSection({Name = "Target", Side = "Left"})
	target:AddDropdown({Name = "Bones Group", Options = {"Head", "Neck", "Chest", "Body"}, Default = "Head", Flag = "Bones"})
	target:AddSlider({Name = "Multipoints Scale", Min = 10, Max = 100, Default = 70, Suffix = "%", Flag = "Multipoints"})
	target:AddToggle({Name = "Visible Check", Default = true, Flag = "VisibleCheck"})
	target:AddToggle({Name = "Auto Wall", Flag = "AutoWall"})
	target:AddSlider({Name = "Min. Damage", Min = 0, Max = 100, Default = 0, Flag = "MinDamage"})

	local weapons = Aimbot:AddSection({Side = "Right"})
	local perWeapon = weapons:AddToggle({Name = "Per Weapon", Flag = "PerWeapon"})
	weapons:AddDropdown({
		Name = "Weapon Group",
		Options = {"Pistols", "Rifles", "Snipers", "SMGs", "Heavy"},
		Flag = "WeaponGroup",
		DependsOn = perWeapon,
	})

	local other = Aimbot:AddSection({Name = "Other", Side = "Right"})
	other:AddToggle({Name = "Back Camera", Flag = "BackCamera"})
	other:AddToggle({Name = "Shot Buffer", Flag = "ShotBuffer"})
	local interp = other:AddToggle({Name = "Interpolation", Flag = "Interpolation"})
	other:AddSlider({Name = "Buffer", Min = 0, Max = 20, Default = 0, Suffix = " ticks", Flag = "Buffer", DependsOn = interp})
	other:AddMultiDropdown({Name = "Hitboxes", Options = {"Head", "Chest", "Arms", "Legs"}, Default = {"Head"}, Flag = "Hitboxes"})
end

Combat:AddSubTab({Name = "Trigger", Icon = "zap"})

local AntiAim = Combat:AddSubTab({Name = "Anti-Aim", Icon = "refresh-cw"})
do
	local aa = AntiAim:AddSection({Side = "Left"})
	local enabled = aa:AddToggle({Name = "Anti-Aim", Flag = "AntiAim"})
	aa:AddDropdown({Name = "Yaw Mode", Options = {"Jitter", "Spin", "Static"}, Flag = "YawMode", DependsOn = enabled})
	aa:AddToggle({Name = "Random Pitch", Flag = "RandomPitch", DependsOn = enabled})
	aa:AddSlider({Name = "Pitch", Min = -90, Max = 90, Default = 0, Step = 0.1, Suffix = " deg", Flag = "Pitch", DependsOn = enabled})
	aa:AddSlider({Name = "Jitter Range", Min = 0, Max = 180, Default = 120, Step = 0.1, Suffix = " deg", Flag = "JitterRange", DependsOn = enabled})
end

Window:AddTab({Name = "Visuals", Icon = {"image", "eye"}})
Window:AddTab({Name = "Misc", Icon = {"sliders-horizontal", "sliders"}})
Window:AddTab({Name = "Skins", Icon = "shirt"})

-- ===== Своя кнопка в настройках (бывшая Telegram) =====
local info = Window.Settings:AddSection({Name = "Information", Side = "Right"})
info:AddButton({
	Name = "Telegram",
	Icon = "send",
	ButtonText = "Open",
	Callback = function()
		if setclipboard then setclipboard("https://t.me/your_channel") end
		return "Copied" -- строка на 1.2 сек появится на кнопке
	end,
})

Window:Notify({Title = "Zenin", Content = "Loaded. Right Shift - open/close menu.", Duration = 4})
