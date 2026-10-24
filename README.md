# ZeninLib

UI Library для Roblox.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()
```

Полный пример: [`Example.lua`](Example.lua).

## Окно

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

| Опция | Что делает |
|---|---|
| `Title` | название в шапке |
| `Logo` | буква (`"M"`), иконка (`"zap"`) или картинка (`"rbxassetid://123"`) |
| `ToggleKey` | клавиша открытия меню |
| `Theme` | `"Dark"` или `"Light"` |
| `Accent` | основной цвет |
| `Configs` | кнопка конфигов рядом с настройками |
| `ConfigFolder` | папка для конфигов (по умолчанию workspace) |
| `ScrollbarSize` | толщина полосы прокрутки, 3–24 |
| `Watermark` | настройки ватермарка, `false` чтобы скрыть |

Клик по ватермарку открывает и закрывает меню.

Настройки (шестерёнка в шапке) есть всегда: тема, цвет, размер меню, полоса прокрутки, ватермарк.

## Вкладки и секции

```lua
local Combat = Window:AddTab({Name = "Combat", Icon = "crosshair"})
local Aimbot = Combat:AddSubTab({Name = "Aimbot", Icon = "crosshair"})
local Section = Aimbot:AddSection({Name = "Target", Side = "Left"})
```

Если у вкладки нет под-вкладок, секции добавляются прямо в неё: `Tab:AddSection(...)`.

Свою секцию в настройках: `Window.Settings:AddSection({Name = "Info"})`.

## Элементы

У всех элементов есть `Name`, `Flag`, `Default`, `Callback`.
Значение по флагу: `Library.Flags["MyFlag"]`.

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

- В ColorPicker можно передать до 4 цветов.
- Если `Callback` кнопки вернёт текст, он ненадолго появится на кнопке.
- `DependsOn = toggle`: элемент работает только когда тоггл включён.

Методы элементов: `Set(value)`, `Get()`, `SetEnabled(bool)`, `SetVisible(bool)`, `OnChanged(fn)`, `Destroy()`.
У дропдаунов ещё есть `SetOptions(list)`.

### Шестерёнка у элемента

```lua
local font = Section:AddDropdown({Name = "Font", Options = {"Small", "Big"}})
local settings = font:AddSettings({Title = "Font Settings"})
settings:AddSlider({Name = "Size", Min = 6, Max = 20, Default = 10})
```

Работает у Toggle, Slider, Dropdown, MultiDropdown и ColorPicker.

## Окно — методы

| Метод | Что делает |
|---|---|
| `Show()`, `Hide()`, `Toggle()` | показать / скрыть меню |
| `SetTheme(name)`, `SetAccent(color)` | тема и цвет |
| `SetScale(n)`, `Center()` | размер и позиция |
| `SetLogo(value)`, `SetTitle(text)` | логотип и название |
| `Notify({Title, Content, Duration})` | уведомление |
| `SaveConfig(name)`, `LoadConfig(name)`, `ListConfigs()`, `DeleteConfig(name)` | конфиги |
| `Destroy()` | выгрузить меню |

## Ватермарк

```lua
Window.Watermark:SetTitle("myhub")
Window.Watermark:SetSite("myhub.cc")
Window.Watermark:SetDetail("roblox")
Window.Watermark:SetModes({"Time", "FPS", "Ping"})
Window.Watermark:SetVisible(false)
```

Режимы: `Time`, `FPS`, `Ping`, `Product Type`. Можно включать несколько сразу.

## Своя тема

```lua
Library:AddTheme("Ocean", {WindowBg = Color3.fromRGB(10, 16, 22)})
Window:SetTheme("Ocean")
```
