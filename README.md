# ZeninLib

UI Library для Roblox: тёмное окно 480×338 с шапкой, нижними вкладками, под-вкладками в шапке, своей полосой прокрутки, ватермарком и анимациями.

**Элементы:** `Toggle`, `Slider`, `Dropdown`, `MultiDropdown`, `ColorPicker` (1–4 цвета), `Button` (обычная и карточка). У элементов может быть шестерёнка с панелью настроек.
**Настройки (шестерёнка)** есть всегда: Theme, Accent Color, UI Scale, Scrollbar Size и ватермарк (Opacity, Show Icons, Details — можно выбрать несколько: Time, FPS, Ping, Product Type). Туда можно добавлять свои секции.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()
```

Полный пример меню: [`Example.lua`](Example.lua).

Все методы можно вызывать и через `:`, и через `.` (`Toggle:Set(true)` == `Toggle.Set(true)`).

## Окно

```lua
local Window = Library:CreateWindow({
    Title = "My Hub",
    Logo = "M",                     -- см. «Логотип»
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",                 -- Dark | Light | своя
    Accent = Color3.fromRGB(255, 89, 89),
    AccentAlpha = 1,
    Scale = 1,                      -- масштаб окна
    ScrollbarSize = 6,              -- 3..24; блоки сужаются под полосу только там, где она нужна
    MouseWheel = false,             -- true = листать колесом (по умолчанию только полосой)
    ConfigFolder = nil,             -- nil = корень workspace экзекутора, "MyHub" = подпапка
    Configs = true,                 -- кнопка конфигов слева от шестерёнки (по желанию)
    Parent = nil,                   -- по умолчанию gethui() или PlayerGui
    Watermark = {                   -- или false, чтобы скрыть
        Title = "myhub", TitleIcon = "tag",
        Site = "myhub.cc", SiteIcon = "globe",   -- без Site пункт скрыт
        Detail = "roblox", DetailIcon = "monitor",
        Modes = {"Product Type"},   -- любые из: Time, FPS, Ping, Product Type
        ToggleOnClick = true,       -- клик по ватермарку открывает/закрывает меню
    },
})
```

### Логотип

Логотип задаётся при создании окна и показывается в шапке и в ватермарке:

| Значение `Logo` | Результат |
|---|---|
| не задан | первая буква `Title` |
| `"M"` или `"AB"` (1–2 символа) | текст цветом акцента |
| `"zap"` | Lucide-иконка цветом акцента |
| `"rbxassetid://123"` / `123` | картинка как есть |
| `{Text = "M", Color = ..., TextSize = 16}` | текст |
| `{Icon = "zap", Color = ...}` | иконка |
| `{Image = "rbxassetid://123", Tint = true, Corner = 3}` | картинка (`Tint` красит акцентом) |

`Window:SetLogo(value)` меняет логотип на лету.

### Методы окна

| Метод | Описание |
|---|---|
| `AddTab({Name, Icon, Default})` | нижняя вкладка |
| `Settings:AddSection(o)` / `AddSettingsSection(o)` | своя секция на странице настроек |
| `SelectSettings()` | открыть настройки |
| `SetTitle(text)`, `SetLogo(value)` | заголовок и логотип |
| `SetTheme(name)`, `GetTheme()`, `GetThemes()` | тема |
| `SetAccent(color, alpha)`, `GetAccent()` | акцент |
| `SetScale(n, animate)`, `GetScale()` | размер меню |
| `SetScrollbarSize(px)`, `SetMouseWheel(bool)` | прокрутка |
| `ClosePopups()` | закрыть все открытые попапы и панели |
| `Show()`, `Hide()`, `Toggle()`, `SetVisible(b)`, `IsVisible()` | видимость |
| `SetToggleKey(KeyCode)`, `GetToggleKey()`, `SetPosition(UDim2)`, `Center()` | клавиша, позиция, вернуть в центр |
| `AddHeaderButton({Icon, Callback})` | иконка-кнопка в шапке слева от шестерёнки (`:SetIcon`, `:SetCallback`, `:Destroy`) |
| `Notify({Title, Content, Icon, Duration})` | уведомление справа снизу |
| `EnableConfigs({Folder})` | включить страницу конфигов (то же, что `Configs = true`); возвращает страницу, в неё можно добавить свои секции |
| `SelectConfigs()`, `RefreshConfigs()`, `GetActiveConfig()` | страница конфигов |
| `SaveConfig(name)`, `LoadConfig(name)`, `DeleteConfig(name)`, `ListConfigs()` | файлы `<name>.cfg` в workspace экзекутора (или `<ConfigFolder>/<name>.cfg`) (все элементы с `Flag` + акцент + настройки) |
| `GetStats()` | число подписок, соединений, элементов, страниц и инстансов (для контроля памяти) |
| `GetConfig()`, `ApplyConfig(table)` | конфиг таблицей |
| `OnUnload(fn)`, `Destroy()` / `Unload()` | выгрузка (отключает все соединения) |

## Конфиги

`Configs = true` добавляет в шапку кнопку слева от шестерёнки. На её странице:
- **Actions**: поле «Name (optional)», **Create New** (без имени будет `config_N`, повтор имени получает суффикс `-1`), **Refresh List**;
- **Config List**: `Active: ...` и список `.cfg` с кнопками загрузить / перезаписать / удалить.

## Память

- На окно приходится одна пара глобальных подключений ввода. Перетаскивание окна и ватермарка, слайдеры, скроллбары и пикер цвета работают через общий диспетчер, поэтому новые элементы не добавляют соединений.
- Плавная прокрутка подключается к `RenderStepped` только пока контент едет.
- Подписки на тему и акцент удаляются вместе с элементом или секцией (`Destroy`).
- `Window:Destroy()` отключает всё, удаляет GUI, очищает флаги и внутренние таблицы.

## Вкладки, под-вкладки, секции

```lua
local Combat = Window:AddTab({Name = "Combat", Icon = "crosshair"})
local Aimbot = Combat:AddSubTab({Name = "Aimbot", Icon = "crosshair"}) -- кнопки в шапке
local Target = Aimbot:AddSection({Name = "Target", Side = "Left"})       -- карточка

local Visuals = Window:AddTab({Name = "Visuals", Icon = "eye"})
local Esp = Visuals:AddSection({Name = "ESP"})   -- вкладка без под-вкладок
```

- `Tab`: `AddSubTab(o)`, `AddSection(o)`, `Select()`, `SetName(text)`, `SetIcon(icon)`.
- `SubTab`: `AddSection(o)`, `Select()`.
- `Section`: `Name` можно не указывать (карточка без заголовка). `Side = "Left"/"Right"`; если не задан, секция попадает в колонку, где их меньше. Методы `SetTitle`, `SetVisible`, `Destroy`.
- Если у вкладки есть под-вкладки, страница показывает активную под-вкладку.

Иконки — Lucide-имена (можно списком запасных: `{"crosshair", "target"}`) или `rbxassetid://`.

## Элементы

Общие опции: `Name`, `Flag`, `Callback`, `Default`, `Disabled = true`, `Visible = false`, `DependsOn = toggle`, `InvertDependency = true`.

Общие методы: `Set(value, silent)`, `Get()`, `SetName(text)`, `SetEnabled(bool)`, `IsEnabled()`, `SetVisible(bool)`, `IsVisible()`, `OnChanged(fn)`, `SetCallback(fn)`, `DependsOn(element, invert)`, `Destroy()`.

Значения с `Flag` доступны в `Library.Flags[flag]`, элементы — в `Library.Options[flag]`.

### Toggle
```lua
local t = Section:AddToggle({Name = "Aimbot", Default = false, Flag = "Aimbot", Callback = function(v) end})
t:Toggle()
```

### Slider
```lua
Section:AddSlider({
    Name = "Pitch", Min = -90, Max = 90, Default = 0,
    Step = 0.1,            -- знаки после запятой берутся из шага
    Suffix = " deg",       -- или Format = function(v) return v .. "!" end
    Flag = "Pitch", Callback = function(v) end,
})
-- SetRange(min, max), SetMin, SetMax, SetSuffix, SetFormat
```

### Dropdown
```lua
local dd = Section:AddDropdown({
    Name = "Bones Group", Icon = "user",   -- Icon необязателен
    Options = {"Head", "Neck", "Chest"}, Default = "Head",
    AllowNone = false, MaxVisible = 8, Placeholder = "None",
    Flag = "Bones", Callback = function(v) end,
})
-- SetOptions(list) / Refresh(list), AddOption(v), RemoveOption(v), GetOptions()
```

### MultiDropdown
```lua
local md = Section:AddMultiDropdown({
    Name = "Hitboxes", Options = {"Head", "Chest", "Legs"}, Default = {"Head"},
    Flag = "Hitboxes",
    Callback = function(list, map) end, -- {"Head","Legs"}, {Head=true, Legs=true}
})
-- Select(v), Deselect(v), ToggleOption(v), IsSelected(v), SelectAll(), Clear(), + методы Dropdown
```
Список не закрывается при выборе; выбранные пункты подсвечены акцентом и отмечены галочкой.

### ColorPicker
```lua
local c = Section:AddColorPicker({Name = "Color", Default = Color3.new(1, 1, 1), Alpha = 1, Flag = "Color",
    Callback = function(color, alpha) end})

-- до 4 цветов в одной строке (например, градиент); значение — таблица
local g = Section:AddColorPicker({
    Name = "Gradient",
    Default = {Color3.fromRGB(255, 89, 89), Color3.fromRGB(89, 120, 255)},
    Alpha = {1, 0.5},
    Flag = "Gradient",
    Callback = function(colors, alphas) end,
})
-- Set(color | {colors}, alpha | {alphas}, silent), SetColor(i, color, alpha), GetColor(i), GetAlpha(i), GetCount()
```
В конфиге цвета хранятся hex-строками.

### Настройки элемента (шестерёнка)
У `Toggle`, `Slider`, `Dropdown`, `MultiDropdown` и `ColorPicker` есть `AddSettings`. Рядом с элементом появляется кнопка-шестерёнка; по нажатию открывается панель (например «Font Settings»), в которую добавляются любые элементы.
```lua
local font = Section:AddDropdown({Name = "Font", Options = {"Small", "Default"}})
local fs = font:AddSettings({Title = "Font Settings"})
fs:AddSlider({Name = "Size", Min = 6, Max = 20, Default = 10, Suffix = "px", Flag = "FontSize"})
fs:AddToggle({Name = "Outline", Flag = "FontOutline"})
fs:AddDropdown({Name = "Style", Options = {"Regular", "Bold"}})
-- fs:Open(), fs:Close(), fs:Toggle(), fs:IsOpen(), fs:SetTitle(text)
```
Дропдаун или пикер цвета внутри панели открываются поверх неё, панель при этом не закрывается. Клик мимо закрывает панель.

### Button
Обычная кнопка во всю ширину:
```lua
Section:AddButton({Name = "Reset to Defaults", Callback = function()
    return "Done"   -- строка на 1.2 сек появится на кнопке
end})
-- Fire(), Flash(text, seconds), SetText(text), SetCallback(fn)
```

### CardButton
Карточка, как бывшая кнопка Telegram: иконка, заголовок, необязательное описание и кнопка действия справа. `AddButton` с `Icon`, `Description` или `ButtonText` тоже создаёт карточку.
```lua
local b = Section:AddCardButton({
    Name = "Telegram", Description = "наш канал",
    Icon = "send", IconColor = nil,   -- по умолчанию цвет акцента
    ButtonText = "Open",
    Callback = function()
        setclipboard("https://t.me/...")
        return "Copied"               -- строка на 1.2 сек появится на кнопке
    end,
})
-- Fire(), Flash(text, seconds), SetButtonText, SetTitle, SetDescription, SetIcon, SetIconColor
```

## Ватермарк

`Window.Watermark`: `SetVisible`, `Toggle`, `SetTitle`, `SetSite` (пустая строка скрывает пункт), `SetDetail` (текст для режима Product Type), `SetModes({...})`, `GetModes()`, `SetOpacity(0..1)`, `SetIconsVisible`, `SetIcons({Title, Site, Detail})`, `SetPosition`, `SetToggleOnClick(bool)`, `SetProvider(function(mode) return "text" end)` для своего текста.

Клик по ватермарку открывает и закрывает меню (это основная кнопка). Перетаскивание ватермарка клик не засчитывает.

Окно и ватермарк перетаскиваются без ограничений по краям экрана; меню масштабируется от центра.

## Темы

```lua
Library:AddTheme("Ocean", {WindowBg = Color3.fromRGB(10, 16, 22), CardBg = Color3.fromRGB(14, 22, 30)})
Window:SetTheme("Ocean")
```
Новая тема берёт все цвета Dark и переопределяет переданные. Она сразу появляется в Settings → Theme. Ключи цветов перечислены в `Library.Themes.Dark`.

## Прочее

- `Library.IconsUrl` / `Library.IconsCache`: источник и кэш Lucide-иконок. Менять их нужно до `CreateWindow`.
- `Library:GetIcon(name)` возвращает `{Image, ImageRectSize, ImageRectOffset}`.
- `Library:Notify(o)` и `Library:Unload()` работают с активным окном. Новый `CreateWindow` выгружает предыдущее окно.
