# ZeninLib v3

UI Library для Roblox, повторяющая эталонное меню Zenin Internal: тёмное окно 480×338 с шапкой, нижними вкладками, под-вкладками в шапке, своей полосой прокрутки, ватермарком и анимациями.

**Элементы:** `Toggle`, `Slider`, `Dropdown`, `MultiDropdown`, `Button`.
**Настройки (шестерёнка)** есть всегда: Theme, Accent Color, UI Scale, Scrollbar Size и ватермарк (Opacity, Show Icons, Details). Туда можно добавлять свои секции.

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whereesd0-star/Zenin/main/ZeninLib.lua"))()
```

Полный пример, который собирает эталонное меню: [`Example.lua`](Example.lua).

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
    ScrollbarSize = 6,              -- 1..25; блоки с элементами сужаются под толстую полосу
    MouseWheel = false,             -- true = листать колесом (в эталоне только полосой)
    ConfigFolder = nil,             -- nil = корень workspace экзекутора, "MyHub" = подпапка
    Configs = true,                 -- кнопка конфигов слева от шестерёнки (по желанию)
    Parent = nil,                   -- по умолчанию gethui() или PlayerGui
    Watermark = {                   -- или false, чтобы скрыть
        Title = "myhub", TitleIcon = "tag",
        Site = "myhub.cc", SiteIcon = "globe",   -- без Site пункт скрыт
        Detail = "internal", DetailIcon = "monitor",
        Version = "v1.0",
        Mode = "Product Type",      -- Time | FPS | Ping | Version | Product Type
        ToggleOnClick = true,       -- клик по ватермарку открывает/закрывает меню
    },
})
```

### Логотип

Буква Z из эталона в библиотеке не зашита. Логотип показывается в шапке и в ватермарке:

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
- `Section`: `Name` можно не указывать (карточка без заголовка, как в эталоне). `Side = "Left"/"Right"`; если не задан, секция попадает в колонку, где их меньше. Методы `SetTitle`, `SetVisible`, `Destroy`.
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

### Button
Карточка, как бывшая кнопка Telegram: иконка, заголовок, необязательное описание и кнопка действия справа.
```lua
local b = Section:AddButton({
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

`Window.Watermark`: `SetVisible`, `Toggle`, `SetTitle`, `SetSite` (пустая строка скрывает пункт), `SetDetail` (текст для режима Product Type), `SetVersion`, `SetMode`, `GetMode`, `SetOpacity(0..1)`, `SetIconsVisible`, `SetIcons({Title, Site, Detail})`, `SetPosition`, `SetToggleOnClick(bool)`, `SetProvider(function(mode) return "text" end)` для своего текста.

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
