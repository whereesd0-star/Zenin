ZeninLib

A UI library for Roblox.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()

Full example: ""Example.lua"" (Example.lua).

Window

local Window = Library:CreateWindow({
    Title = "My Hub",
    Logo = "M",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    Accent = Color3.fromRGB(255, 89, 89),
    Configs = true,
    Watermark = {
        Title = "myhub",
        Site = "myhub.cc",
        Detail = "roblox",
        Modes = {"Product Type"},
    },
})

Option| Description
"Title"| Title displayed in the header
"Logo"| A letter (""M""), an icon (""zap""), or an image (""rbxassetid://123"")
"ToggleKey"| Key used to open or close the menu
"Theme"| ""Dark"" or ""Light""
"Accent"| Primary accent color
"Configs"| Adds a config button next to the settings button
"ConfigFolder"| Folder used to store configs (defaults to "workspace")
"ScrollbarSize"| Scrollbar thickness, from 3 to 24
"Watermark"| Watermark settings; set to "false" to hide it

Clicking the watermark opens or closes the menu.

Settings (the gear icon in the header) are always available and include the theme, accent color, menu scale, scrollbar, and watermark.

Tabs and Sections

local Combat = Window:AddTab({Name = "Combat", Icon = "crosshair"})
local Aimbot = Combat:AddSubTab({Name = "Aimbot", Icon = "crosshair"})
local Section = Aimbot:AddSection({Name = "Target", Side = "Left"})

If a tab has no subtabs, sections can be added directly to it using "Tab:AddSection(...)".

To add a custom section to the settings menu, use "Window.Settings:AddSection({Name = "Info"})".

Elements

All elements support "Name", "Flag", "Default", and "Callback".

Access an element's value by its flag using "Library.Flags["MyFlag"]".

Section:AddToggle({Name = "Aimbot", Default = false, Flag = "Aimbot", Callback = function(v) end})

Section:AddSlider({Name = "FOV", Min = 0, Max = 100, Default = 50, Step = 1, Suffix = "%", Flag = "FOV"})

Section:AddDropdown({Name = "Bone", Options = {"Head", "Body"}, Default = "Head", Flag = "Bone"})

Section:AddMultiDropdown({Name = "Hitboxes", Options = {"Head", "Chest", "Legs"}, Default = {"Head"}, Flag = "Hitboxes"})

Section:AddColorPicker({Name = "Color", Default = Color3.new(1, 1, 1), Flag = "Color"})
Section:AddColorPicker({Name = "Gradient", Default = {Color3.new(1, 0, 0), Color3.new(0, 0, 1)}, Flag = "Gradient"})

Section:AddButton({Name = "Reset", Callback = function() end})

Section:AddCardButton({Name = "Telegram", Icon = "send", ButtonText = "Open", Callback = function()
    setclipboard("https://t.me/...")
    return "Copied"
end})

- "ColorPicker" supports up to 4 colors.
- If a button's "Callback" returns a string, it will briefly appear on the button.
- "DependsOn = toggle": the element only works while the specified toggle is enabled.

Element methods: "Set(value)", "Get()", "SetEnabled(bool)", "SetVisible(bool)", "OnChanged(fn)", "Destroy()".

Dropdowns also support "SetOptions(list)".

Element Settings (Gear Icon)

local font = Section:AddDropdown({Name = "Font", Options = {"Small", "Big"}})
local settings = font:AddSettings({Title = "Font Settings"})
settings:AddSlider({Name = "Size", Min = 6, Max = 20, Default = 10})

This feature is available for Toggle, Slider, Dropdown, MultiDropdown, and ColorPicker elements.

Window Methods

Method| Description
"Show()", "Hide()", "Toggle()"| Show, hide, or toggle the menu
"SetTheme(name)", "SetAccent(color)"| Set the theme and accent color
"SetScale(n)", "Center()"| Set the menu scale and center its position
"SetLogo(value)", "SetTitle(text)"| Set the logo and title
"Notify({Title, Content, Duration})"| Display a notification
"SaveConfig(name)", "LoadConfig(name)", "ListConfigs()", "DeleteConfig(name)"| Manage configs
"Destroy()"| Unload the menu

Watermark

Window.Watermark:SetTitle("myhub")
Window.Watermark:SetSite("myhub.cc")
Window.Watermark:SetDetail("roblox")
Window.Watermark:SetModes({"Time", "FPS", "Ping"})
Window.Watermark:SetVisible(false)

Available modes: "Time", "FPS", "Ping", and "Product Type". Multiple modes can be enabled simultaneously.

Custom Themes

Library:AddTheme("Ocean", {WindowBg = Color3.fromRGB(10, 16, 22)})
Window:SetTheme("Ocean")
