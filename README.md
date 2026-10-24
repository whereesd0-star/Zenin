# ZeninLib

UI Library for Roblox.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()
```

Full example: [`Example.lua`](Example.lua).

## Window

```lua
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
```

| Option | What it does |
|---|---|
| `Title` | name in the header |
| `Logo` | a letter (`"M"`), an icon (`"zap"`) or an image (`"rbxassetid://123"`) |
| `ToggleKey` | key that opens the menu |
| `Theme` | `"Dark"` or `"Light"` |
| `Accent` | main color |
| `Configs` | configs button next to settings |
| `ConfigFolder` | folder for configs (workspace by default) |
| `ScrollbarSize` | scrollbar thickness, 3–24 |
| `Watermark` | watermark settings, `false` to hide it |

Clicking the watermark opens and closes the menu.

Settings (the gear in the header) are always there: theme, color, menu size, scrollbar, watermark.

## Tabs and sections

```lua
local Combat = Window:AddTab({Name = "Combat", Icon = "crosshair"})
local Aimbot = Combat:AddSubTab({Name = "Aimbot", Icon = "crosshair"})
local Section = Aimbot:AddSection({Name = "Target", Side = "Left"})
```

If a tab has no sub-tabs, add sections straight to it: `Tab:AddSection(...)`.

Your own section in settings: `Window.Settings:AddSection({Name = "Info"})`.

## Elements

Every element has `Name`, `Flag`, `Default`, `Callback`.
Get a value by flag: `Library.Flags["MyFlag"]`.

```lua
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
```

- ColorPicker takes up to 4 colors.
- If a button's `Callback` returns text, it shows on the button for a moment.
- `DependsOn = toggle`: the element only works while the toggle is on.

Element methods: `Set(value)`, `Get()`, `SetEnabled(bool)`, `SetVisible(bool)`, `OnChanged(fn)`, `Destroy()`.
Dropdowns also have `SetOptions(list)`.

### Element gear

```lua
local font = Section:AddDropdown({Name = "Font", Options = {"Small", "Big"}})
local settings = font:AddSettings({Title = "Font Settings"})
settings:AddSlider({Name = "Size", Min = 6, Max = 20, Default = 10})
```

Works on Toggle, Slider, Dropdown, MultiDropdown and ColorPicker.

## Window methods

| Method | What it does |
|---|---|
| `Show()`, `Hide()`, `Toggle()` | show / hide the menu |
| `SetTheme(name)`, `SetAccent(color)` | theme and color |
| `SetScale(n)`, `Center()` | size and position |
| `SetLogo(value)`, `SetTitle(text)` | logo and name |
| `Notify({Title, Content, Duration})` | notification |
| `SaveConfig(name)`, `LoadConfig(name)`, `ListConfigs()`, `DeleteConfig(name)` | configs |
| `Destroy()` | unload the menu |

## Watermark

```lua
Window.Watermark:SetTitle("myhub")
Window.Watermark:SetSite("myhub.cc")
Window.Watermark:SetDetail("roblox")
Window.Watermark:SetModes({"Time", "FPS", "Ping"})
Window.Watermark:SetVisible(false)
```

Modes: `Time`, `FPS`, `Ping`, `Product Type`. You can turn on several at once.

## Custom theme

```lua
Library:AddTheme("Ocean", {WindowBg = Color3.fromRGB(10, 16, 22)})
Window:SetTheme("Ocean")
```


## Rochess

`Rochess.lua` uses ZeninLib for its engine, automation, appearance, and profile controls.
It requires the Roblox game's `ReplicatedStorage.Chess` and `ChessClient` modules;
it is not a standalone chess engine. The UI library is fetched from this repository.
HTTP access and `loadstring` must be available in the runtime. Profile persistence
and clipboard support are optional; unavailable file APIs leave profiles in memory.

- **End**: toggle autoplay; **Home**: toggle arrows.
- **PageUp / +**: toggle the window; **PageDown**: switch analysis source.
- **Insert**: copy the position and moves when clipboard access is available.
- Existing profiles remain in `rocheese_profiles_v2.json`.

Analysis results are tied to the session and complete move history, so stale searches
cannot overwrite the current position. Move dispatch validates legality and uses
one handler per attempt to avoid duplicate submissions.

### Regression checks

```sh
npm ci
npm test
```

The tests execute extracted script logic in a mocked Lua runtime, covering stale
analysis, failed engines, move validation, and concurrent move attempts. The script is also syntax-checked with the Lua parser. These checks do not
replace live verification of the Roblox UI, game modules, or executor APIs.
