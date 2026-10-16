

















































































local _orig_print = print or function() end
local _orig_warn  = warn  or function() end
-- ═══════════════════════════════════════════════════════════
-- PASTEBIN AUTO-SCAN  (auto-detect by username/uid)
-- ═══════════════════════════════════════════════════════════
local _PB_URL = "https://pastebin.com/raw/GauasFJv"

local function _fetchPastebinRaw()
    local tries = {
        function() return game:HttpGet(_PB_URL, true) end,
        function() return game:HttpGet(_PB_URL) end,
        function() return game:HttpGetAsync(_PB_URL) end,
    }
    if typeof(request) == "function" then
        table.insert(tries, function()
            local r = request({Url=_PB_URL, Method="GET"})
            if r and r.Body then return r.Body end
        end)
    end
    for _, fn in ipairs(tries) do
        local ok, res = pcall(fn)
        if ok and type(res) == "string" and #res > 5 then return res end
    end
    return nil
end

local function _parseEntries(text)
    if not text or #text < 5 then return {} end
    local entries = {}
    local function ensure(n)
        n = tonumber(n)
        if not n then return nil end
        entries[n] = entries[n] or {}
        return entries[n]
    end
    for n, v in string.gmatch(text, "key(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n); if e then e.key = v end
    end
    for n, v in string.gmatch(text, "expires(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n); if e then e.expires = v end
    end
    for n, v in string.gmatch(text, "whitelist(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n); if e then e.whitelist = v end
    end
    for n, v in string.gmatch(text, "username(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n); if e then e.username = v end
    end
    -- playeruidN
    for n, v in string.gmatch(text, "playeruid(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n); if e then e.playeruid = v end
    end
    -- uidN  (alias, если playeruid нет)
    for n, v in string.gmatch(text, "uid(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n)
        if e and (not e.playeruid or e.playeruid == "") then e.playeruid = v end
    end
    -- useridN  (alias)
    for n, v in string.gmatch(text, "userid(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n)
        if e and (not e.playeruid or e.playeruid == "") then e.playeruid = v end
    end
    -- robloxidN  (alias)
    for n, v in string.gmatch(text, "robloxid(%d+)%s*:%s*%(%s*\"([^\"]*)\"%s*%)") do
        local e = ensure(n)
        if e and (not e.playeruid or e.playeruid == "") then e.playeruid = v end
    end
    return entries
end

-- Приоритет: 1) username  2) playeruid  3) наличие ника в whitelist-поле
local function scanPastebinForPlayer(userId, playerName)
    local raw = _fetchPastebinRaw()
    if not raw then return nil, "pastebin unreachable" end
    local entries = _parseEntries(raw)
    if not next(entries) then return nil, "pastebin format bad" end

    local uidStr    = tostring(userId or "")
    local nameLower = tostring(playerName or ""):lower()

    -- 1) по username
    if nameLower ~= "" then
        for _, e in pairs(entries) do
            if e.username and tostring(e.username):lower() == nameLower then
                return e, "username"
            end
        end
    end

    -- 2) по playeruid
    if uidStr ~= "" and uidStr ~= "0" then
        for _, e in pairs(entries) do
            if e.playeruid and tostring(e.playeruid) == uidStr then
                return e, "uid"
            end
        end
    end

    -- 3) по whitelist-полю: если ник входит в "a,b,c"
    if nameLower ~= "" then
        for _, e in pairs(entries) do
            if e.whitelist and e.whitelist ~= "" then
                for name in string.gmatch(e.whitelist, "([^,]+)") do
                    name = name:gsub("^%s+", ""):gsub("%s+$", ""):lower()
                    if name == nameLower then
                        return e, "whitelist"
                    end
                end
            end
        end
    end

    return nil, "not found"
end

-- Проверяет, входит ли игрок в whitelist-field (comma-separated)
local function _isNameInWhitelist(whitelistField, playerName)
    if not whitelistField or whitelistField == "" then return false end
    local target = tostring(playerName or ""):lower()
    for name in string.gmatch(whitelistField, "([^,]+)") do
        name = name:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if name == target then return true end
    end
    return false
end

local function runCheat(KEYDATA)

local UIB = {}
local Library, Section, makePopupFrame, getPopupGui, reg, ConfigSystem
local targetESPHolder, Window

local function _runPart(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        _orig_warn("[hysteria] " .. tostring(name) .. " ERROR: " .. tostring(err))
    end
    return ok
end

local function _part1_UIB()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local FONT_REGULAR = Enum.Font.Arial
local FONT_BOLD = Enum.Font.ArialBold
local FONT_FACE_ALIAS = {FontFace = "Font"}

local PALETTE = {
    Window=Color3.fromRGB(12,12,16), WindowGlass=Color3.fromRGB(18,18,24),
    Panel=Color3.fromRGB(16,16,22), PanelGlass=Color3.fromRGB(20,20,28),
    Element=Color3.fromRGB(36,36,48), ElementHi=Color3.fromRGB(48,48,62),
    ElementGlass=Color3.fromRGB(40,40,54),
    Text=Color3.fromRGB(245,245,250), TextDim=Color3.fromRGB(160,160,175),
    Shadow=Color3.fromRGB(0,0,0), Warn=Color3.fromRGB(255,90,90),
    Ok=Color3.fromRGB(120,240,160),
}
local DEFAULT_ACCENT = Color3.fromRGB(180,180,190)
-- Menu toggle key — можно менять в settings. Хранится в Library.Settings.MenuKey
-- (само объявление Library идёт НИЖЕ, после THEMES)

-- ═══════════════════════════════════════════════════════════
-- THEMES
-- ═══════════════════════════════════════════════════════════
local THEMES = {
    dark = {
        Window=Color3.fromRGB(12,12,16), WindowGlass=Color3.fromRGB(18,18,24),
        Panel=Color3.fromRGB(16,16,22), PanelGlass=Color3.fromRGB(20,20,28),
        Element=Color3.fromRGB(36,36,48), ElementHi=Color3.fromRGB(48,48,62),
        ElementGlass=Color3.fromRGB(40,40,54),
        Text=Color3.fromRGB(245,245,250), TextDim=Color3.fromRGB(160,160,175),
        Shadow=Color3.fromRGB(0,0,0),
        Warn=Color3.fromRGB(255,90,90), Ok=Color3.fromRGB(120,240,160),
    },
light = {
    -- тёплый приглушённый беж, без резких переходов
    Window=Color3.fromRGB(232,228,222), WindowGlass=Color3.fromRGB(240,236,230),
    Panel=Color3.fromRGB(224,220,214), PanelGlass=Color3.fromRGB(234,230,224),
    Element=Color3.fromRGB(210,206,200), ElementHi=Color3.fromRGB(198,194,188),
    ElementGlass=Color3.fromRGB(206,202,196),
    Text=Color3.fromRGB(58,54,58), TextDim=Color3.fromRGB(122,116,120),
    Shadow=Color3.fromRGB(178,174,168),
    Warn=Color3.fromRGB(196,72,72), Ok=Color3.fromRGB(58,164,100),
},
    pastel = {
        -- мягкая пастель — приглушённая лавандово-пудровая
        Window=Color3.fromRGB(228,218,226), WindowGlass=Color3.fromRGB(236,226,234),
        Panel=Color3.fromRGB(218,208,216), PanelGlass=Color3.fromRGB(230,220,228),
        Element=Color3.fromRGB(206,194,204), ElementHi=Color3.fromRGB(194,182,192),
        ElementGlass=Color3.fromRGB(212,200,210),
        Text=Color3.fromRGB(74,52,74), TextDim=Color3.fromRGB(128,104,128),
        Shadow=Color3.fromRGB(176,152,174),
        Warn=Color3.fromRGB(198,80,108), Ok=Color3.fromRGB(110,172,132),
    },
    glass = {
        Window=Color3.fromRGB(72,92,132), WindowGlass=Color3.fromRGB(120,150,200),
        Panel=Color3.fromRGB(64,84,120), PanelGlass=Color3.fromRGB(110,140,190),
        Element=Color3.fromRGB(90,115,160), ElementHi=Color3.fromRGB(110,140,190),
        ElementGlass=Color3.fromRGB(100,125,170),
        Text=Color3.fromRGB(255,255,255), TextDim=Color3.fromRGB(200,210,230),
        Shadow=Color3.fromRGB(30,40,70),
        Warn=Color3.fromRGB(255,110,110), Ok=Color3.fromRGB(130,240,170),
    },
}

Library = {}; Library.__index = Library
Library.Version = "3.0"
Library.Themes = THEMES
Library.Settings = {
    AccentColor=DEFAULT_ACCENT, TweenTime=0.15, MenuScale=1.0,
    Theme="dark",
    CustomThemes = {},
    AvatarURL="rbxassetid://1590754819",
    MenuImageURL="rbxassetid://12150333118",
    ProfilePreset="classic",
    MenuStyle="classic",
    MenuFont="arial",
    -- ❗ name protect: подмена ников whitelisted-игроков в ESP и chat leaker
    NameProtectEnabled=false,
    NameProtectText="Protected",
    AmbientEnabled=false,
    AmbientUseAccent=true,
    AmbientIntensity=0.6,
    AmbientShape="circle",
    AmbientSpread=1.0,
    AmbientLayers=4,
    AmbientGroups = {
        avatar = {
            enabled = false, useAccent = true, color = nil,
            intensity = 1.0, shape = "circle",
            spread = 1.0, layers = 4,
            spreadBase = 0.15, baseT = 0.88,
        },
        menu = {
            enabled = false, useAccent = true, color = nil,
            intensity = 1.0, shape = "circle",
            spread = 1.0, layers = 4,
            spreadBase = 0.08, baseT = 0.9,
        },
    },
}
Library.Settings.MenuKey = Enum.KeyCode.Insert

-- защита от старых конфигов где MenuFont отсутствует
Library.Settings.MenuFont = Library.Settings.MenuFont or "arial"

-- ❗ инициализация глобалов name protect (UI-тумблер их обновляет)
_G.__PRIMO_NAMEPROTECT_ENABLED = Library.Settings.NameProtectEnabled == true
_G.__PRIMO_NAMEPROTECT_TEXT    = Library.Settings.NameProtectText or "Protected"

-- forward-declare before SetAccentColor uses it
local _notifHolder = nil

local accentBindings = {}
local function registerAccent(fn)
    table.insert(accentBindings, fn)
    -- ❗ раньше было fn() без pcall → любой баг в callback валил весь UI
    -- и утаскивал ошибку в CoreGui-обвязку Roblox. Теперь изолирован.
    local ok, err = pcall(fn)
    if not ok then
        _orig_warn("[hysteria] accent callback ERROR: " .. tostring(err))
    end
end
local function refreshAccent() for _, fn in ipairs(accentBindings) do pcall(fn) end end
local function clearAccentBindings() accentBindings = {} end
Library._clearAccentBindings = clearAccentBindings
function Library:SetAccentColor(c)
    if typeof(c) == "Color3" then
        Library.Settings.AccentColor = c
        refreshAccent()
        pcall(function()
            local holder = _notifHolder
            if holder and holder.Parent then
                for _, ch in ipairs(holder:GetChildren()) do
                    if ch:IsA("Frame") then
                        local b = ch:FindFirstChild("bar")
                        local s = ch:FindFirstChildOfClass("UIStroke")
                        if b then b.BackgroundColor3 = c end
                        if s then s.Color = c end
                    end
                end
            end
        end)
    end
end
function Library:GetAccentColor() return Library.Settings.AccentColor end

-- ── theme registry ──
-- ВАЖНО: объявлено ДО Library:SetTheme, иначе closure захватывает nil-глобалы
local _themeRegistry = setmetatable({}, {__mode = "k"})
local _paletteHex = {}

local function _colorKey(c)
    return string.format("%d_%d_%d",
        math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end
local function _rebuildPaletteHex()
    local nh = {}
    for k, v in pairs(PALETTE) do
        if typeof(v) == "Color3" then
            local ck = _colorKey(v)
            if not nh[ck] then nh[ck] = {} end
            table.insert(nh[ck], k)
        end
    end
    _paletteHex = nh
end
_rebuildPaletteHex()

function Library:SetTheme(name)
    local t = THEMES[name]
    if not t then return end
    Library.Settings.Theme = name
    for k, v in pairs(t) do
        if typeof(v) == "Color3" then PALETTE[k] = v end
    end
    _rebuildPaletteHex()
    for inst, entries in pairs(_themeRegistry) do
        if inst and inst.Parent then
            for _, e in ipairs(entries) do
                pcall(function() inst[e.prop] = PALETTE[e.key] end)
            end
        end
    end
    if refreshAccent then refreshAccent() end
end
function Library:GetTheme() return Library.Settings.Theme or "dark" end

-- ── palette editing ──
function Library:SetPaletteColor(key, color)
    if type(key) ~= "string" then return end
    if typeof(color) ~= "Color3" then return end
    if PALETTE[key] == nil then return end
    PALETTE[key] = color
    _rebuildPaletteHex()
    for inst, entries in pairs(_themeRegistry) do
        if inst and inst.Parent then
            for _, e in ipairs(entries) do
                if e.key == key then
                    pcall(function() inst[e.prop] = color end)
                end
            end
        end
    end
    if refreshAccent then refreshAccent() end
end

function Library:GetPaletteColor(key)
    return PALETTE[key]
end

-- ═══════════════════════════════════════════════════════════
-- CUSTOM THEMES  —  каждый файл = отдельная тема-конфиг
--   primo_configs/themes/<name>.json
-- ═══════════════════════════════════════════════════════════
local _THEMES_DIR = "hysteria_configs_blyat/themes"
local _HS = game:GetService("HttpService")
local HAS_THEME_FS = (typeof(writefile) == "function")
    and (typeof(readfile) == "function")
    and (typeof(isfile) == "function")
    and (typeof(listfiles) == "function")
    and (typeof(makefolder) == "function")
    and (typeof(isfolder) == "function")
    and (typeof(delfile) == "function")

local function _ensureThemesDir()
    if not HAS_THEME_FS then return end
    local ok, isF = pcall(isfolder, "hysteria_configs_blyat")
    if not ok or not isF then pcall(makefolder, "hysteria_configs_blyat") end
    local ok2, isT = pcall(isfolder, _THEMES_DIR)
    if not ok2 or not isT then pcall(makefolder, _THEMES_DIR) end
end
_ensureThemesDir()

local function _themePath(name) return _THEMES_DIR .. "/" .. name .. ".json" end

local function _sanitizeThemeName(name)
    if not name or name == "" then return nil end
    local n = tostring(name):gsub("[^%w_%-%. ]", "_"):sub(1, 48)
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then return nil end
    return n
end

local function _serializePalette()
    local out = {}
    for k, v in pairs(PALETTE) do
        if typeof(v) == "Color3" then
            out[k] = { v.R, v.G, v.B }
        end
    end
    return {
        __meta = { version = 1, type = "hysteria_theme", savedAt = os.time() },
        palette = out,
        accent  = Library.Settings.AccentColor,
    }
end

local function _applyPaletteFromJson(dec)
    if type(dec) ~= "table" then return false end
    local pal = dec.palette
    if type(pal) ~= "table" then return false end
    for k, rgb in pairs(pal) do
        if PALETTE[k] ~= nil and type(rgb) == "table" and #rgb >= 3 then
            PALETTE[k] = Color3.new(rgb[1], rgb[2], rgb[3])
        end
    end
    _rebuildPaletteHex()
    for inst, entries in pairs(_themeRegistry) do
        if inst and inst.Parent then
            for _, e in ipairs(entries) do
                pcall(function() inst[e.prop] = PALETTE[e.key] end)
            end
        end
    end
    if type(dec.accent) == "table" and #dec.accent >= 3 then
        Library.Settings.AccentColor = Color3.new(dec.accent[1], dec.accent[2], dec.accent[3])
    end
    if refreshAccent then refreshAccent() end
    return true
end

-- SAVE — пишет новый файл-конфиг темы
function Library:SaveCustomTheme(name)
    local clean = _sanitizeThemeName(name)
    if not clean then return false, "bad name" end
    if not HAS_THEME_FS then
        return false, "executor has no fs"
    end
    -- запрещаем имена, которые могут конфликтовать с config-system
    local low = clean:lower()
    if low == "whitelist" or low == "trashtalk" or low == "themes" then
        return false, "reserved name"
    end
    _ensureThemesDir()
    local payload = _serializePalette()
    local ok, json = pcall(function() return _HS:JSONEncode(payload) end)
    if not ok then return false, "encode failed" end
    local path = _themePath(clean)
    -- бэкап старого файла
    if isfile(path) then
        pcall(function()
            local old = readfile(path)
            if old and writefile then
                writefile(path .. ".bak", old)
            end
        end)
    end
    local okW = pcall(writefile, path, json)
    if not okW then return false, "write failed" end
    return true, clean
end

-- LOAD — читает файл и применяет палитру
function Library:LoadCustomTheme(name)
    local clean = _sanitizeThemeName(name)
    if not clean then return false, "bad name" end
    if not HAS_THEME_FS then return false, "executor has no fs" end
    local path = _themePath(clean)
    local okE, exists = pcall(isfile, path)
    if not okE or not exists then return false, "not found" end
    local okR, raw = pcall(readfile, path)
    if not okR or not raw then return false, "read failed" end
    local okD, dec = pcall(function() return _HS:JSONDecode(raw) end)
    if not okD or type(dec) ~= "table" then
        -- fallback на .bak
        local bakPath = path .. ".bak"
        local okB, hasBak = pcall(isfile, bakPath)
        if okB and hasBak then
            local okR2, rawB = pcall(readfile, bakPath)
            if okR2 and rawB then
                local okD2, decB = pcall(function() return _HS:JSONDecode(rawB) end)
                if okD2 then dec = decB end
            end
        end
    end
    if type(dec) ~= "table" then return false, "corrupt file" end
    return _applyPaletteFromJson(dec)
end

-- DELETE — удаляет файл (и .bak)
function Library:DeleteCustomTheme(name)
    local clean = _sanitizeThemeName(name)
    if not clean then return false end
    if not HAS_THEME_FS then return true end
    pcall(function()
        local path = _themePath(clean)
        if isfile(path) then delfile(path) end
        if isfile(path .. ".bak") then delfile(path .. ".bak") end
    end)
    return true
end

-- LIST — читает имена тем с диска
function Library:ListCustomThemes()
    local out = {}
    if not HAS_THEME_FS then return out end
    _ensureThemesDir()
    local ok, files = pcall(listfiles, _THEMES_DIR)
    if not ok or not files then return out end
    for _, f in ipairs(files) do
        local base = f:match("([^/\\]+)%.json$")
        if base and not base:match("%.bak$") and not base:match("%.tmp$") then
            out[#out+1] = base
        end
    end
    table.sort(out)
    return out
end

-- экспорт наружу чтобы ConfigSystem мог тоже подхватывать
Library.HAS_THEME_FS = HAS_THEME_FS
Library.THEMES_DIR   = _THEMES_DIR

function Library:SetProfileImage(url)
    if type(url) ~= "string" or url == "" then return end
    -- мягкая нормализация: голый ID → rbxassetid://ID
    local url2 = url:gsub("^%s+", ""):gsub("%s+$", "")
    if url2:match("^%d+$") then
        url2 = "rbxassetid://" .. url2
    end
    Library.Settings.AvatarURL = url2
    local box = Library._avatarBox
    if box and box.Parent then
        pcall(function() box.Image = url2 end)
    end
end
function Library:SetMenuImage(url)
    if type(url) ~= "string" or url == "" then return end
    local url2 = url:gsub("^%s+", ""):gsub("%s+$", "")
    if url2:match("^%d+$") then url2 = "rbxassetid://" .. url2 end
    Library.Settings.MenuImageURL = url2
    local img = Library._menuImage
    if img and img.Parent then
        pcall(function() img.Image = url2 end)
    end
end
-- Ambient: круглое гало ЗА элементом. Слои масштабируются относительно
-- размера фрейма (scale-based), поэтому и для 50px аватара, и для 200px
-- big-picture выглядят одинаково аккуратно.
Library._ambientGlows = Library._ambientGlows or {}

local function addAmbientGlow(frame, color, opts)
    opts = opts or {}
    local groupName = opts.group
    local grp = nil
    if groupName and Library.Settings.AmbientGroups then
        grp = Library.Settings.AmbientGroups[groupName]
    end

    local origLayers = grp and grp.layers or opts.layers or 5
    local origSpread = grp and grp.spreadBase or opts.spread or 0.08
    local spreadMult = grp and grp.spread or (tonumber(Library.Settings.AmbientSpread) or 1)
    local layers     = math.max(1, math.floor(origLayers))
    local baseT      = grp and grp.baseT or opts.baseT or 0.9
    local shape      = grp and grp.shape or opts.shape or Library.Settings.AmbientShape or "circle"
    local glowColor  = (grp and not grp.useAccent and grp.color) or color or Library.Settings.AccentColor
    local intensity  = grp and grp.intensity or 1
    local totalSpread = origSpread * spreadMult * 4   -- нормализация: 4 = "стандартный" размер

    local parent = frame.Parent
    if not parent then return nil end

    local glowRoot = Instance.new("Frame")
    glowRoot.Name                   = "__primo_glow_root"
    glowRoot.BackgroundTransparency = 1
    glowRoot.BorderSizePixel        = 0
    glowRoot.Active                 = false
    glowRoot.ClipsDescendants       = false
    glowRoot.Size                   = frame.Size
    glowRoot.Position               = frame.Position
    glowRoot.AnchorPoint            = frame.AnchorPoint
    glowRoot.ZIndex                 = math.max((frame.ZIndex or 1) - 1, 0)
    glowRoot.Parent                 = parent

    local _sync
    _sync = function()
        if not glowRoot.Parent then return end
        glowRoot.Size        = frame.Size
        glowRoot.Position    = frame.Position
        glowRoot.AnchorPoint = frame.AnchorPoint
        glowRoot.Visible     = frame.Visible
        glowRoot.ZIndex      = math.max((frame.ZIndex or 1) - 1, 0)
    end
    _sync()

    local _conns = {}
    for _, prop in ipairs({"Position","Size","AnchorPoint","Visible","ZIndex"}) do
        table.insert(_conns, frame:GetPropertyChangedSignal(prop):Connect(_sync))
    end
    table.insert(_conns, frame.AncestryChanged:Connect(_sync))

    local glowList, extraList = {}, {}

    local function _applyShape(holder, uc, baseRot)
        holder.Rotation = baseRot or 0
        if shape == "circle" then
            uc.CornerRadius = UDim.new(1, 0)
        elseif shape == "square" then
            uc.CornerRadius = UDim.new(0, 0)
        elseif shape == "rounded" then
            uc.CornerRadius = UDim.new(0, 10)
        elseif shape == "diamond" then
            uc.CornerRadius = UDim.new(0, 5)
            holder.Rotation = (baseRot or 0) + 45
        elseif shape == "hexagon" then
            uc.CornerRadius = UDim.new(0, 22)
        elseif shape == "pill" then
            uc.CornerRadius = UDim.new(1, 0)
            holder.Size = UDim2.new(holder.Size.X.Scale, 0, holder.Size.Y.Scale, 0)
        elseif shape == "star" then
            uc.CornerRadius = UDim.new(0, 4)
            holder.Rotation = (baseRot or 0) + 45
        elseif shape == "frame" then
            uc.CornerRadius = UDim.new(0, 10)
            holder.BackgroundTransparency =
                math.min(holder.BackgroundTransparency + 0.12, 0.97)
        else
            local pc = frame:FindFirstChildOfClass("UICorner")
            local cr = pc and pc.CornerRadius.Offset or 10
            uc.CornerRadius = UDim.new(0, cr)
        end
    end

    -- smoothstep для мягкой кривой
    local function smoothstep(t) return t*t*(3 - 2*t) end

    -- i = 1: внутренний (маленький, чуть виднее)
    -- i = layers: внешний (большой, почти прозрачный)
    for i = 1, layers do
        local u = (i - 1) / math.max(layers - 1, 1)   -- 0..1
        local su = smoothstep(u)                       -- мягкая кривая
        local s = totalSpread * su
        -- inner 0.92 → outer 0.985, но с учётом intensity
        local tr = baseT + (0.985 - baseT) * su
        tr = math.clamp(1 - (1 - tr) * intensity, 0, 0.985)

        local holder = Instance.new("Frame")
        holder.Name                   = "__primo_ambient_" .. i
        holder.BackgroundColor3       = glowColor
        holder.BackgroundTransparency = tr
        holder.BorderSizePixel        = 0
        holder.Active                 = false
        holder.ZIndex                 = layers - i + 1
        holder.Size                   = UDim2.new(1 + s * 2, 0, 1 + s * 2, 0)
        holder.Position               = UDim2.new(-s, 0, -s, 0)
        holder.Parent                 = glowRoot

        local uc = Instance.new("UICorner")
        _applyShape(holder, uc, 0)
        uc.Parent = holder

        table.insert(glowList, holder)

        if shape == "star" then
            local star2 = Instance.new("Frame")
            star2.Name                   = "__primo_ambient_star_" .. i
            star2.BackgroundColor3       = glowColor
            star2.BackgroundTransparency = holder.BackgroundTransparency
            star2.BorderSizePixel        = 0
            star2.Active                 = false
            star2.ZIndex                 = layers - i + 1
            star2.Size                   = holder.Size
            star2.Position               = holder.Position
            star2.Rotation               = 0
            star2.Parent                 = glowRoot
            local uc2 = Instance.new("UICorner")
            uc2.CornerRadius = UDim.new(0, 4)
            uc2.Parent = star2
            table.insert(extraList, star2)
        end
    end

    local api = {
        frames = glowList, extras = extraList, root = glowRoot,
        _frame = frame,
        _color = color,
        _group = groupName,
        _baseOpts = { layers = origLayers, spread = origSpread,
                      baseT = baseT, shape = shape },
    }

    function api:SetColor(c)
        c = c or glowColor or Library.Settings.AccentColor
        for _, g in ipairs(glowList) do
            if g and g.Parent then pcall(function() g.BackgroundColor3 = c end) end
        end
        for _, g in ipairs(extraList) do
            if g and g.Parent then pcall(function() g.BackgroundColor3 = c end) end
        end
    end

    function api:SetEnabled(v)
        for _, g in ipairs(glowList) do
            if g and g.Parent then pcall(function() g.Visible = v and true or false end) end
        end
        for _, g in ipairs(extraList) do
            if g and g.Parent then pcall(function() g.Visible = v and true or false end) end
        end
    end

    function api:Destroy()
        for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
        pcall(function() glowRoot:Destroy() end)
    end

    registerAccent(function() api:SetColor(glowColor or Library.Settings.AccentColor) end)
    api:SetEnabled((grp and grp.enabled) or Library.Settings.AmbientEnabled == true)

    table.insert(Library._ambientGlows, api)
    return api
end
-- глобалы — toggle'ят ВСЕ амбиенты
Library.SetAmbientEnabled = function(v)
    Library.Settings.AmbientEnabled = v and true or false
    for _, api in ipairs(Library._ambientGlows) do
        local grp = api._group and Library.Settings.AmbientGroups
                    and Library.Settings.AmbientGroups[api._group]
        local show = v
        if grp and grp.enabled == false then show = false end
        pcall(function() api:SetEnabled(show) end)
    end
end
Library.SetAmbientColor = function(c)
    Library.Settings.AmbientColor = c
    for _, api in ipairs(Library._ambientGlows) do
        pcall(function() api:SetColor(c or Library.Settings.AccentColor) end)
    end
end
Library.SetAmbientIntensity = function(m)
    Library.Settings.AmbientIntensity = m
    for _, api in ipairs(Library._ambientGlows) do
        pcall(function() api:SetIntensity(m) end)
    end
end
Library.RebuildAmbientGlows = function()
    local snapshots = {}
    for _, api in ipairs(Library._ambientGlows) do
        if api and api._frame and api._frame.Parent then
            snapshots[#snapshots+1] = {
                frame = api._frame,
                color = api._color,
                group = api._group,
            }
        end
    end
    for _, api in ipairs(Library._ambientGlows) do
        pcall(function() if api.Destroy then api:Destroy() end end)
    end
    Library._ambientGlows = {}
    for _, snap in ipairs(snapshots) do
        if snap.frame and snap.frame.Parent then
            local newApi = addAmbientGlow(snap.frame, snap.color, { group = snap.group })
            if snap.frame == Library._menuImage then Library._menuImageGlow = newApi end
            if snap.frame == Library._avatarBox then Library._avatarGlow     = newApi end
        end
    end
end
_G.__PRIMO_AMBIENT            = Library.SetAmbientEnabled
_G.__PRIMO_AMBIENT_COLOR      = Library.SetAmbientColor
_G.__PRIMO_AMBIENT_INTENSITY  = Library.SetAmbientIntensity

local function create(class, props, parent)
    local inst = Instance.new(class)
    local entries = nil
    for k, v in pairs(props) do
        if k == "FontFace" and typeof(v) == "EnumItem" then
            inst.Font = v
        else
            local ok = pcall(function() inst[k] = v end)
            if not ok and FONT_FACE_ALIAS[k] then
                pcall(function() inst[FONT_FACE_ALIAS[k]] = v end)
            end
            if typeof(v) == "Color3"
                and (k == "BackgroundColor3" or k == "TextColor3"
                     or k == "Color" or k == "ImageColor3"
                     or k == "PlaceholderColor3") then
                local pkeys = _paletteHex[_colorKey(v)]
                if pkeys then
                    entries = entries or {}
                    for _, pkey in ipairs(pkeys) do
                        entries[#entries+1] = {prop = k, key = pkey}
                    end
                end
            end
        end
    end
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if parent then inst.Parent = parent end
    if entries then _themeRegistry[inst] = entries end
    return inst
end
local function corner(parent, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent; return c
end
local function tween(inst, props, time)
    if not inst or type(props) ~= "table" then return end
    local safe, ok = {}, false
    for k, v in pairs(props) do
        local tv = typeof(v)
        if tv == "ColorSequence" or tv == "NumberSequence"
            or tv == "ColorSequenceKeypoint" or tv == "NumberSequenceKeypoint" then
            pcall(function() inst[k] = v end)
        else
            safe[k] = v
            ok = true
        end
    end
    if not ok then return end
    TweenService:Create(inst, TweenInfo.new(time or Library.Settings.TweenTime,
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out), safe):Play()
end
local function hexOf(color)
    if typeof(color) ~= "Color3" then color = Color3.new(1,1,1) end
    return string.format("#%02x%02x%02x",
        math.floor(color.R*255+0.5), math.floor(color.G*255+0.5), math.floor(color.B*255+0.5))
end
local function addGlass(parent, t, color)
    local g = create("Frame", {Name="glass", BackgroundColor3=color or PALETTE.PanelGlass,
        BackgroundTransparency=t or 0.3, Size=UDim2.new(1,0,1,0), ZIndex=-1}, parent)
    corner(g, 8)
    local grad = Instance.new("UIGradient")
    -- ❗ адаптация под тему: на светлых темах используем тёмный градиент,
    -- на тёмных — светлый. Иначе на white/pastel всё превращается в мутное пятно
    local themeName = Library.Settings.Theme or "dark"
    local isLight = (themeName == "light" or themeName == "pastel")
    if isLight then
        grad.Color = ColorSequence.new(Color3.fromRGB(80,80,90), Color3.fromRGB(180,180,190))
    else
        grad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200))
    end
    grad.Rotation = 45
    grad.Transparency = NumberSequence.new(isLight and 0.75 or 0.5,
                                           isLight and 0.9  or 0.8)
    grad.Parent = g
    return g
end

local HUE_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
})

local MB_ALIASES = {
    ["mb1"]="MouseButton1",["m1"]="MouseButton1",["mouse1"]="MouseButton1",
    ["mousebutton1"]="MouseButton1",["lmb"]="MouseButton1",
    ["mb2"]="MouseButton2",["m2"]="MouseButton2",["mouse2"]="MouseButton2",
    ["mousebutton2"]="MouseButton2",["rmb"]="MouseButton2",
    ["mb3"]="MouseButton3",["m3"]="MouseButton3",["mouse3"]="MouseButton3",
    ["mousebutton3"]="MouseButton3",["mmb"]="MouseButton3",
}
local function parseBind(str)
    if not str or str == "" then return nil end
    local clean = str:gsub("%s+","")
    local low = clean:lower()
    if MB_ALIASES[low] then return Enum.UserInputType[MB_ALIASES[low]] end
    local target = clean:upper()
    if target == "ESC" then target = "ESCAPE" end
    if target == "CTRL" then target = "LEFTCONTROL" end
    if target == "SHIFT" then target = "LEFTSHIFT" end
    if target == "ALT" then target = "LEFTALT" end
    if target == "ENTER" then target = "RETURN" end
    for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
        if kc.Name:upper() == target then return kc end
    end
    return nil
end
local function bindName(bind)
    if not bind then return "unbound" end
    if typeof(bind) == "EnumItem" then return bind.Name end
    return tostring(bind)
end

UIB.create       = create
UIB.corner       = corner
UIB.tween        = tween
UIB.addGlass     = addGlass
UIB.hexOf        = hexOf
UIB.PALETTE      = PALETTE
UIB.FONT_REGULAR = FONT_REGULAR
UIB.FONT_BOLD    = FONT_BOLD
UIB.HUE_GRADIENT = HUE_GRADIENT
UIB.parseBind    = parseBind
UIB.bindName     = bindName
-- expose services for PART 4
UIB.UserInputService = UserInputService
UIB.TweenService     = TweenService
UIB.RunService       = RunService
UIB.Players          = Players
UIB.Stats            = Stats
UIB.PlayerGui        = PlayerGui
UIB.LocalPlayer      = LocalPlayer
UIB.registerAccent = registerAccent
UIB.refreshAccent  = refreshAccent

getPopupGui = function()
    local existing = PlayerGui:FindFirstChild("primo_popups")
    if not existing then
        existing = create("ScreenGui", {Name="primo_popups", ResetOnSpawn=false,
            ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
            DisplayOrder=950}, PlayerGui)
    end
    return existing
end

-- ═══════════════════════════════════════════════════════════
-- NOTIFICATIONS  (toasts, right-top corner)
-- ═══════════════════════════════════════════════════════════
-- (_notifHolder already forward-declared above)

local function _ensureNotifHolder()
    if _notifHolder and _notifHolder.Parent then return _notifHolder end
    local gui = getPopupGui and getPopupGui()
    if not gui then return nil end
    _notifHolder = create("Frame", {Name="primo_notifications",
        BackgroundTransparency=1, Size=UDim2.new(0,320,1,-20),
        Position=UDim2.new(1,-332,0,10), ZIndex=999}, gui)
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0,6)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Top
    lay.Parent = _notifHolder
    return _notifHolder
end

function Library:Notify(title, message, opts)
    opts = opts or {}
    local holder = _ensureNotifHolder()
    if not holder then return end
    local kind = opts.Kind or "info"
    local lifeTime = opts.Duration or 3.5
    local iconColor = Library.Settings.AccentColor
    if kind == "success" then iconColor = PALETTE.Ok
    elseif kind == "error" then iconColor = PALETTE.Warn end

    -- cap: не больше 5 одновременно
    local kids = {}
    for _, c in ipairs(holder:GetChildren()) do
        if c:IsA("Frame") then kids[#kids+1] = c end
    end
    if #kids >= 5 then
        local oldest = kids[1]
        for i=2,#kids do
            if kids[i].LayoutOrder < oldest.LayoutOrder then oldest = kids[i] end
        end
        if oldest then oldest:Destroy() end
    end

    local toast = create("Frame", {Name="toast",
        BackgroundColor3=PALETTE.Panel, BackgroundTransparency=0.05,
        Size=UDim2.new(1,0,0,54), LayoutOrder=math.floor(os.clock()*1000)}, holder)
    corner(toast, 8)
    local stroke = Instance.new("UIStroke")
    stroke.Color = iconColor; stroke.Thickness = 1.5
    stroke.Transparency = 0.4; stroke.Parent = toast
    local bar = create("Frame", {Name="bar",
        BackgroundColor3=iconColor, BackgroundTransparency=0.15,
        Size=UDim2.new(0,3,1,-12), Position=UDim2.new(0,0,0,6)}, toast)
    corner(bar, 2)
    create("TextLabel", {Name="title", BackgroundTransparency=1,
        Text=tostring(title or "notification"), TextSize=13,
        TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-22,0,18), Position=UDim2.new(0,12,0,6)}, toast)
    create("TextLabel", {Name="msg", BackgroundTransparency=1,
        Text=tostring(message or ""), TextSize=12,
        TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-22,0,16), Position=UDim2.new(0,12,0,28)}, toast)

    toast.Position = UDim2.new(1,60,0,0)
    task.spawn(function()
        tween(toast, {Position=UDim2.new(0,0,0,0)}, 0.22)
        task.wait(lifeTime)
        tween(toast, {Position=UDim2.new(1,60,0,0), BackgroundTransparency=1}, 0.22)
        task.wait(0.3)
        pcall(function() toast:Destroy() end)
    end)
end

function Library:NotifyError(t, m)   self:Notify(t, m, {Kind="error"})   end
function Library:NotifySuccess(t, m) self:Notify(t, m, {Kind="success"}) end

local function buildColorPicker(parent, opts)
    local gui = getPopupGui()
    local row = create("Frame", {Name="colorpicker", BackgroundTransparency=1,
        Size=UDim2.new(1,-24,0,28)}, parent)
    local labelBtn = create("TextButton", {Name="labelBtn", AutoButtonColor=false,
        Text="", BackgroundTransparency=1, Size=UDim2.new(1,-46,1,0)}, row)
    create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "color", TextSize=14, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,0,1,0)}, labelBtn)
    local initialColor = opts.InitialColor or Library.Settings.AccentColor
    if typeof(initialColor) ~= "Color3" then initialColor = Library.Settings.AccentColor end
    local swatch = create("TextButton", {Name="swatch", AutoButtonColor=false,
        Text="", BackgroundColor3=initialColor, Size=UDim2.new(0,36,0,22),
        Position=UDim2.new(1,-36,0.5,-11)}, row)
    corner(swatch, 6)
    -- ❗ рамка на swatch: на белых картинках без неё не видно границ
    local swStroke = Instance.new("UIStroke")
    swStroke.Color = Color3.fromRGB(0,0,0)
    swStroke.Thickness = 1
    swStroke.Transparency = 0.55
    swStroke.Parent = swatch

    local PW, PH = 240, 260
    -- ❗ уникальное имя, иначе при 2+ picker'ах outside-click и FindFirstChild ломаются
    local _cp_id = tostring(math.random(1, 1e9))
    local popup = create("Frame", {Name="colorpicker_popup_".._cp_id,
        BackgroundColor3=PALETTE.Panel,
        Size=UDim2.new(0,PW,0,PH), Position=UDim2.new(0,100,0,100), Visible=false,
        ZIndex=10}, gui)
    corner(popup, 10); addGlass(popup, 0.2, PALETTE.PanelGlass)
    create("TextLabel", {Name="title", BackgroundTransparency=1, Text="- color picker -",
        TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.new(1,0,0,24)}, popup)
    local svHolder = create("Frame", {BackgroundColor3=Color3.fromRGB(255,0,0),
        Size=UDim2.new(0,200,0,150), Position=UDim2.new(0.5,-100,0,32),
        ClipsDescendants=true}, popup)
    corner(svHolder, 8)
    local whiteOverlay = create("Frame", {BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(1,0,1,0)}, svHolder)
    do
        local wg = Instance.new("UIGradient")
        wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),
            NumberSequenceKeypoint.new(1,1)}); wg.Parent = whiteOverlay
    end
    local blackOverlay = create("Frame", {BackgroundColor3=Color3.new(0,0,0),
        Size=UDim2.new(1,0,1,0)}, svHolder)
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(1,0)}); bg.Parent = blackOverlay
    local svCursor = create("Frame", {BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(0,14,0,14), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(1,0,0,0)}, svHolder)
    corner(svCursor, 7)
    local hueStrip = create("Frame", {BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(0,200,0,16), Position=UDim2.new(0.5,-100,0,192),
        ClipsDescendants=true}, popup)
    corner(hueStrip, 8)
    local hg = Instance.new("UIGradient"); hg.Color = HUE_GRADIENT; hg.Parent = hueStrip
    local hueCursor = create("Frame", {BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(0,6,1,4), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0,0,0.5,0)}, hueStrip)
    corner(hueCursor, 3)
    local preview = create("Frame", {BackgroundColor3=initialColor,
        Size=UDim2.new(0,40,0,26), Position=UDim2.new(0,20,0,222)}, popup)
    corner(preview, 6)
    local hexLabel = create("TextLabel", {BackgroundTransparency=1, Text="#ffffff",
        TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-112,0,26), Position=UDim2.new(0,68,0,222)}, popup)

    local resetBtn = create("TextButton", {Name="reset", AutoButtonColor=false,
        Text="reset", TextSize=12, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,-56,0,224)}, popup)
    corner(resetBtn, 6)
    resetBtn.MouseEnter:Connect(function()
        tween(resetBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
    end)
    resetBtn.MouseLeave:Connect(function()
        tween(resetBtn, {TextColor3=PALETTE.TextDim, BackgroundTransparency=0.4})
    end)
    resetBtn.MouseButton1Click:Connect(function()
        local d = Library.Settings.AccentColor
        syncFromColor(d); applyVisual(true)
    end)

    local hue, sat, val = 0, 0, 1
    local function getInitial()
        if opts.GetInitialColor then
            local ok, c = pcall(opts.GetInitialColor)
            if ok and typeof(c) == "Color3" then return c end
        end
        if typeof(opts.InitialColor) == "Color3" then return opts.InitialColor end
        return Library.Settings.AccentColor
    end
    local function syncFromColor(c)
        if typeof(c) ~= "Color3" then c = Library.Settings.AccentColor end
        if typeof(c) ~= "Color3" then c = Color3.fromRGB(255,200,160) end
        local ok, h, s, v = pcall(function() return Color3.toHSV(c) end)
        if ok then hue, sat, val = h, s, v else hue, sat, val = 0, 0, 1 end
    end
    local function applyVisual(fire)
        local c = Color3.fromHSV(hue or 0, sat or 0, val or 1)
        svHolder.BackgroundColor3 = Color3.fromHSV(hue or 0, 1, 1)
        svCursor.Position = UDim2.new(sat or 0, 0, 1-(val or 1), 0)
        hueCursor.Position = UDim2.new(hue or 0, 0, 0.5, 0)
        preview.BackgroundColor3 = c
        hexLabel.Text = hexOf(c)
        swatch.BackgroundColor3 = c
        if fire and opts.Callback then opts.Callback(c) end
    end
    syncFromColor(getInitial()); applyVisual(false)

    local svDragging, hueDragging = false, false
    local function updateSV(mx, my)
        local pos, size = svHolder.AbsolutePosition, svHolder.AbsoluteSize
        sat = math.clamp((mx-pos.X)/math.max(size.X,1), 0, 1)
        val = 1 - math.clamp((my-pos.Y)/math.max(size.Y,1), 0, 1)
        applyVisual(true)
    end
    local function updateHue(mx)
        local pos, size = hueStrip.AbsolutePosition, hueStrip.AbsoluteSize
        hue = math.clamp((mx-pos.X)/math.max(size.X,1), 0, 1)
        applyVisual(true)
    end
    svHolder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true; updateSV(input.Position.X, input.Position.Y)
        end
    end)
    hueStrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true; updateHue(input.Position.X)
        end
    end)
    local changedConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then updateSV(input.Position.X, input.Position.Y)
            elseif hueDragging then updateHue(input.Position.X) end
        end
    end)
    local endedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            svDragging, hueDragging = false, false
        end
    end)
    local openedAt = 0
    local function openPopup()
        local iPos = swatch.AbsolutePosition
        local iSize = swatch.AbsoluteSize
        local vp = gui.AbsoluteSize
        local x = math.clamp(iPos.X-PW+iSize.X, 4, math.max(4, vp.X-PW-4))
        local y = math.clamp(iPos.Y+iSize.Y+4, 4, math.max(4, vp.Y-PH-4))
        popup.Position = UDim2.new(0, x, 0, y)
        syncFromColor(getInitial()); applyVisual(false)
        popup.Visible = true; openedAt = os.clock()
        tween(popup, {BackgroundTransparency=0}, 0.2)
    end
    local function closePopup()
        tween(popup, {BackgroundTransparency=1}, 0.15)
        task.delay(0.15, function() popup.Visible = false end)
    end
    swatch.MouseButton1Click:Connect(function()
        if popup.Visible then closePopup() else openPopup() end
    end)
    labelBtn.MouseButton1Click:Connect(function()
        if popup.Visible then closePopup() else openPopup() end
    end)
    local closeHandle = UserInputService.InputBegan:Connect(function(input)
        if not popup.Visible then return end
        if os.clock() - openedAt < 0.25 then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = input.Position
        local function inside(g)
            local a, s = g.AbsolutePosition, g.AbsoluteSize
            return p.X>=a.X and p.X<=a.X+s.X and p.Y>=a.Y and p.Y<=a.Y+s.Y
        end
        if not inside(popup) and not inside(swatch) and not inside(labelBtn) then
            closePopup()
        end
    end)
    local api = {Frame=row, Popup=popup}
    function api:Get() return Color3.fromHSV(hue, sat, val) end
    function api:Set(c, silent)
        if typeof(c) == "Color3" then syncFromColor(c); applyVisual(not silent) end
    end
    function api:Destroy()
        pcall(function() closeHandle:Disconnect() end)
        pcall(function() changedConn:Disconnect() end)
        pcall(function() endedConn:Disconnect() end)
        popup:Destroy()
    end
    return api
end

local function buildButton(parent, opts)
    local btn = create("TextButton", {Name=opts.Name or "button", AutoButtonColor=false,
        Text=opts.Text or "button", TextSize=opts.TextSize or 14,
        TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        BackgroundColor3=PALETTE.Element, Size=opts.Size or UDim2.new(1,-24,0,28),
        TextXAlignment=Enum.TextXAlignment.Center}, parent)
    corner(btn, 7); addGlass(btn, 0.4, PALETTE.ElementGlass)
    local function apply()
        local hovered = btn:GetAttribute("hovered")
        local pressed = btn:GetAttribute("pressed")
        local c = PALETTE.Text
        if hovered then c = Library.Settings.AccentColor end
        if pressed then c = Library.Settings.AccentColor:Lerp(Color3.new(1,1,1), 0.3) end
        tween(btn, {TextColor3=c})
        local t = 0.4
        if hovered then t = 0.3 end
        if pressed then t = 0.2 end
        tween(btn, {BackgroundTransparency=t})
    end
    btn.MouseEnter:Connect(function() btn:SetAttribute("hovered", true); apply() end)
    btn.MouseLeave:Connect(function() btn:SetAttribute("hovered", false); apply() end)
    btn.MouseButton1Down:Connect(function() btn:SetAttribute("pressed", true); apply() end)
    btn.MouseButton1Up:Connect(function() btn:SetAttribute("pressed", false); apply() end)
    registerAccent(apply)
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(opts.Callback) end
    end)
    return {Frame=btn, Instance=btn}
end

local function buildToggle(parent, opts)
    local row = create("TextButton", {Name=opts.Name or "toggle", AutoButtonColor=false,
        Text="", BackgroundTransparency=1, Size=opts.Size or UDim2.new(1,-24,0,28)}, parent)
    local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "toggle", TextSize=14, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-50,1,0)}, row)
    local switch = create("Frame", {Name="switch", BackgroundColor3=PALETTE.ElementHi,
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-38,0.5,-10)}, row)
    corner(switch, 10); addGlass(switch, 0.3, PALETTE.ElementGlass)
    local knob = create("Frame", {Name="knob", BackgroundColor3=PALETTE.Text,
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,2,0.5,-8),
        Active=false}, switch)
    corner(knob, 8)
    local state = opts.Default == true
    local function apply()
        local sc = PALETTE.ElementHi
        if state then sc = Library.Settings.AccentColor end
        tween(switch, {BackgroundColor3 = sc})
        local knobOffset = 2
        if state then knobOffset = 22 end
        tween(knob, {Position = UDim2.new(0, knobOffset, 0.5, -8)})
        local hovered = row:GetAttribute("hovered")
        local textColor = PALETTE.Text
        if hovered then textColor = Library.Settings.AccentColor end
        tween(label, {TextColor3 = textColor})
    end
    row.MouseEnter:Connect(function() row:SetAttribute("hovered", true); apply() end)
    row.MouseLeave:Connect(function() row:SetAttribute("hovered", false); apply() end)
    registerAccent(apply); apply()
    local api = {Frame=row}
    function api:Get() return state end
    function api:Set(v, silent)
        state = v and true or false; apply()
        if not silent and opts.Callback then opts.Callback(state) end
    end
    row.MouseButton1Click:Connect(function()
        state = not state; apply()
        if opts.Callback then opts.Callback(state) end
    end)
    return api
end

local function buildTextBox(parent, opts)
    local box = create("TextBox", {Name=opts.Name or "input", Text=opts.Text or "",
        PlaceholderText=opts.Placeholder or "", PlaceholderColor3=PALETTE.TextDim,
        TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
        Size=UDim2.new(1,-24,0,opts.Height or 28),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd}, parent)
    corner(box, 7); addGlass(box, 0.4, PALETTE.ElementGlass)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,12); pad.PaddingRight = UDim.new(0,12); pad.Parent = box
    box.Focused:Connect(function()
        local c = Library.Settings.AccentColor:Lerp(PALETTE.Element, 0.8)
        tween(box, {BackgroundColor3 = c})
    end)
    box.FocusLost:Connect(function(enter)
        tween(box, {BackgroundColor3 = PALETTE.Element})
        if opts.Callback then opts.Callback(box.Text, enter) end
    end)
    local api = {Frame=box, Instance=box}
    function api:Get() return box.Text end
    function api:Set(v, silent)
        box.Text = tostring(v or "")
        if not silent and opts.Callback then opts.Callback(box.Text, false) end
    end
    return api
end

local function buildNumberInput(parent, opts)
    local row = create("Frame", {Name=opts.Name or "numberinput",
        BackgroundTransparency=1, Size=UDim2.new(1,-24,0,28)}, parent)
    create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "number", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-110,1,0)}, row)
    local box = create("TextBox", {Name="input", Text=tostring(opts.Default or 0),
        PlaceholderText=opts.Placeholder or "0", PlaceholderColor3=PALETTE.TextDim,
        TextSize=13, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
        Size=UDim2.new(0,100,1,0), Position=UDim2.new(1,-100,0,0),
        TextXAlignment=Enum.TextXAlignment.Center}, row)
    corner(box, 7); addGlass(box, 0.4, PALETTE.ElementGlass)
    box.Focused:Connect(function()
        local c = Library.Settings.AccentColor:Lerp(PALETTE.Element, 0.8)
        tween(box, {BackgroundColor3 = c})
    end)
    box.FocusLost:Connect(function(enter)
        tween(box, {BackgroundColor3 = PALETTE.Element})
        local num = tonumber(box.Text) or opts.Default or 0
        if opts.Min then num = math.max(num, opts.Min) end
        if opts.Max then num = math.min(num, opts.Max) end
        box.Text = tostring(num)
        if opts.Callback then opts.Callback(num, enter) end
    end)
    local api = {Frame=row, Instance=box}
    function api:Get() return tonumber(box.Text) or opts.Default or 0 end
    function api:Set(v, silent)
        local num = tonumber(v) or opts.Default or 0
        box.Text = tostring(num)
        if not silent and opts.Callback then opts.Callback(num, false) end
    end
    return api
end

local function buildBindInput(parent, opts)
    local row = create("Frame", {Name=opts.Name or "bindinput",
        BackgroundTransparency=1, Size=UDim2.new(1,-24,0,50)}, parent)
    create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "bind", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,0,0,0)}, row)
    local currentLabel = create("TextLabel", {Name="current", BackgroundTransparency=1,
        Text=bindName(opts.Default), TextSize=12, TextColor3=PALETTE.TextDim,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,80,0,18), Position=UDim2.new(1,-80,0,0)}, row)
    local box = create("TextBox", {Name="input", Text="",
        PlaceholderText="type key (e, mb2, leftshift, space)",
        PlaceholderColor3=PALETTE.TextDim, TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, BackgroundColor3=PALETTE.Element, ClearTextOnFocus=true,
        Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,20),
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, row)
    corner(box, 7); addGlass(box, 0.4, PALETTE.ElementGlass)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10); pad.Parent = box
    local current = opts.Default
    local function setCurrent(bind, fire)
        current = bind; currentLabel.Text = bindName(bind); box.Text = ""
        if fire and opts.Callback then opts.Callback(bind) end
    end
    setCurrent(opts.Default, false)
    if opts.Default and opts.Callback then
        task.defer(function() pcall(opts.Callback, opts.Default) end)
    end
    box.Focused:Connect(function()
        _G.__PRIMO_BIND_LISTENING = true
    end)
    -- правый клик в поле = clear bind
    box.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            setCurrent(nil, true)
            task.defer(function()
                if box:IsFocused() then
                    -- снимаем фокус, чтобы юзер случайно не забиндил RMB
                    UserInputService:GetFocusedTextBox()
                end
            end)
        end
    end)
    box.FocusLost:Connect(function(enter)
        _G.__PRIMO_BIND_LISTENING = false
        task.delay(0.1, function()
            -- если фокус уже ушёл из-под носа, флаг всё равно снимаем
            if not UserInputService:GetFocusedTextBox() then
                _G.__PRIMO_BIND_LISTENING = false
            end
        end)
        local txt = box.Text
        if txt and txt ~= "" then
            local parsed = parseBind(txt)
            if parsed then setCurrent(parsed, true)
            else
                box.Text = ""
                local prev = currentLabel.TextColor3
                currentLabel.TextColor3 = PALETTE.Warn
                task.delay(0.5, function() currentLabel.TextColor3 = prev end)
            end
        end
    end)
    pcall(function()
        box.Destroying:Connect(function()
            _G.__PRIMO_BIND_LISTENING = false
        end)
    end)
    box.AncestryChanged:Connect(function(_, parent)
        if not parent then
            _G.__PRIMO_BIND_LISTENING = false
        end
    end)

    local api = {Frame=row}
    function api:Get() return current end
    function api:Set(v, silent)
        if v == nil then return end
        local parsed = v
        if type(v) == "string" then parsed = parseBind(v) end
        if parsed then setCurrent(parsed, not silent) end
    end
    -- Система конфигов сохраняет BindInput через Get() (в основном value-поле),
    -- поэтому отдельный GetBind не нужен. Но SetBind должен существовать —
    -- чтобы старые конфиги с суффиксом |BIND корректно загружались.
    function api:SetBind(v, silent)
        if v == nil then
            setCurrent(nil, not silent)
            return
        end
        local parsed = v
        if type(v) == "string" then parsed = parseBind(v) end
        if parsed then setCurrent(parsed, not silent) end
    end
    return api
end

local function buildConfirmButton(parent, opts)
    local b = buildButton(parent, {Text=opts.Text or "confirm", Callback=nil})
    local btn = b.Instance
    local originalText = opts.Text or "confirm"
    local confirming = false
    local remaining = 3
    local confirmTask = nil
    local warningTemplate = opts.Warning or "are you sure? (?)"
    local function stopConfirm()
        confirming = false
        if confirmTask then
            pcall(function() task.cancel(confirmTask) end)
            confirmTask = nil
        end
        btn.Text = originalText
        btn.TextColor3 = PALETTE.Text
    end
    local function enterConfirm()
        confirming = true; remaining = 3
        btn.TextColor3 = PALETTE.Warn
        local function render() btn.Text = warningTemplate:gsub("%?", tostring(remaining)) end
        render()
        confirmTask = task.spawn(function()
            for _ = 1, 3 do
                task.wait(1)
                remaining = remaining - 1
                if remaining < 1 then break end
                render()
            end
            -- тред завершился сам — не отменяем себя
            if confirming then
                confirming = false
                btn.Text = originalText
                btn.TextColor3 = PALETTE.Text
            end
            confirmTask = nil
        end)
    end
    btn.MouseButton1Click:Connect(function()
        if confirming then
            stopConfirm()
            if opts.Callback then task.spawn(opts.Callback) end
        else enterConfirm() end
    end)
    local api = {Frame=b.Frame, Instance=btn}
    function api:Get() return confirming end
    function api:Set() end
    function api:IsPersistable() return false end
    return api
end

local function buildCheckGearRow(parent, opts)
    local holder = create("Frame", {Name=opts.Name or "checkGearRow",
        BackgroundTransparency=1, Size=UDim2.new(1,-24,0,28)}, parent)

    local clickArea = create("TextButton", {Name="clickArea", AutoButtonColor=false,
        Text="", BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        ZIndex=1}, holder)

    local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "option", TextSize=14, TextColor3=PALETTE.Text,
        Font=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-120,1,0), ZIndex=1}, clickArea)

    local switch = create("Frame", {Name="switch", BackgroundColor3=PALETTE.ElementHi,
        Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-74,0.5,-10),
        ZIndex=1}, clickArea)
    corner(switch, 10); addGlass(switch, 0.3, PALETTE.ElementGlass)
    local knob = create("Frame", {Name="knob", BackgroundColor3=PALETTE.Text,
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,2,0.5,-8),
        ZIndex=1}, switch)
    corner(knob, 8)

    local gear = create("TextButton", {Name="gear", AutoButtonColor=false, Text="",
        BackgroundColor3=PALETTE.Element, Size=UDim2.new(0,28,1,0),
        Position=UDim2.new(1,-28,0,0), ZIndex=2}, holder)
    corner(gear, 7); addGlass(gear, 0.4, PALETTE.ElementGlass)
    local gearIcon = create("ImageLabel", {Name="icon", BackgroundTransparency=1,
        Image="rbxassetid://7059346373", ImageColor3=PALETTE.Text,
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0.5,-8,0.5,-8)}, gear)

    local state = opts.Default == true
    local function applyToggle()
        local sc = PALETTE.ElementHi
        if state then sc = Library.Settings.AccentColor end
        tween(switch, {BackgroundColor3 = sc})
        local knobOffset = 2
        if state then knobOffset = 22 end
        tween(knob, {Position = UDim2.new(0, knobOffset, 0.5, -8)})
        local hovered = clickArea:GetAttribute("hovered")
        local textColor = PALETTE.Text
        if hovered then textColor = Library.Settings.AccentColor end
        tween(label, {TextColor3 = textColor})
    end

    local function applyGear()
        local hovered = gear:GetAttribute("hovered")
        local imgCol = PALETTE.Text
        if hovered then imgCol = Library.Settings.AccentColor end
        tween(gearIcon, {ImageColor3 = imgCol})
        local bgc = 0.4
        if hovered then bgc = 0.3 end
        tween(gear, {BackgroundTransparency = bgc})
    end

    clickArea.MouseEnter:Connect(function() clickArea:SetAttribute("hovered", true); applyToggle() end)
    clickArea.MouseLeave:Connect(function() clickArea:SetAttribute("hovered", false); applyToggle() end)
    gear.MouseEnter:Connect(function() gear:SetAttribute("hovered", true); applyGear() end)
    gear.MouseLeave:Connect(function() gear:SetAttribute("hovered", false); applyGear() end)

    registerAccent(applyToggle); registerAccent(applyGear)
    applyToggle(); applyGear()

    local api = {Frame=holder, Toggle=switch, Gear=gear, Label=label}
    function api:Get() return state end
    function api:Set(v, silent)
        state = v and true or false; applyToggle()
        if not silent and opts.Callback then opts.Callback(state) end
    end

    clickArea.MouseButton1Click:Connect(function() api:Set(not state) end)
    gear.MouseButton1Click:Connect(function()
        if opts.GearCallback then
            local ok, err = pcall(opts.GearCallback)
            if not ok then warn("[primo] gear callback: "..tostring(err)) end
        end
    end)

    if opts.Callback then task.defer(function() pcall(opts.Callback, state) end) end

    return api
end

local function buildToggleBindRow(parent, opts)
    local hasHint = type(opts.Hint) == "string" and opts.Hint ~= ""
    local rowH = hasHint and 44 or 28

    local holder = create("Frame", {Name=opts.Name or "toggleBindRow",
        BackgroundTransparency=1, Size=UDim2.new(1,-24,0,rowH)}, parent)

    -- bind button справа — фиксированная ширина
    local bindBtn = create("TextButton", {Name="bind", AutoButtonColor=false,
        Text=bindName(opts.DefaultBind), TextSize=12, TextColor3=PALETTE.TextDim,
        FontFace=FONT_BOLD, BackgroundColor3=PALETTE.Element,
        Size=UDim2.new(0,64,0,28), Position=UDim2.new(1,-64,0,0),
        TextXAlignment=Enum.TextXAlignment.Center}, holder)
    corner(bindBtn, 7); addGlass(bindBtn, 0.4, PALETTE.ElementGlass)

    -- clickArea — всё что левее bindBtn, кликается → toggles
    local clickArea = create("TextButton", {Name="clickArea", AutoButtonColor=false,
        Text="", BackgroundTransparency=1, Size=UDim2.new(1,-68,0,28)}, holder)

    -- switch справа внутри clickArea
    local switch = create("Frame", {Name="switch", BackgroundColor3=PALETTE.ElementHi,
        Size=UDim2.new(0,34,0,18), Position=UDim2.new(1,-34,0.5,-9),
        Active=false}, clickArea)
    corner(switch, 9); addGlass(switch, 0.3, PALETTE.ElementGlass)
    local knob = create("Frame", {Name="knob", BackgroundColor3=PALETTE.Text,
        Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,2,0.5,-7),
        Active=false}, switch)
    corner(knob, 7)

    -- label слева
    local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "option", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-40,1,0)}, clickArea)

    if hasHint then
        create("TextLabel", {Name="hint", BackgroundTransparency=1,
            Text=opts.Hint, TextSize=11, TextColor3=PALETTE.TextDim,
            FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,
            Size=UDim2.new(1,-68,0,14), Position=UDim2.new(0,0,0,29)}, holder)
    end

    local state = opts.Default == true
    local listening = false
    local listenConn
    local function applyToggle()
        local sc = PALETTE.ElementHi
        if state then sc = Library.Settings.AccentColor end
        tween(switch, {BackgroundColor3 = sc})
        local off = state and 18 or 2
        tween(knob, {Position = UDim2.new(0, off, 0.5, -7)})
        local hovered = clickArea:GetAttribute("hovered")
        local textColor = PALETTE.Text
        if hovered then textColor = Library.Settings.AccentColor end
        tween(label, {TextColor3 = textColor})
    end
    applyToggle()

    local currentBind = opts.DefaultBind
    local function applyBindVisual()
        if listening then
            bindBtn.Text = "..."; bindBtn.TextColor3 = Library.Settings.AccentColor
        else
            bindBtn.Text = bindName(currentBind); bindBtn.TextColor3 = PALETTE.TextDim
        end
    end
    applyBindVisual()

    local function stopListening()
        listening = false
        _G.__PRIMO_BIND_LISTENING = false
        applyBindVisual()
        if listenConn then
            pcall(function() listenConn:Disconnect() end)
            listenConn = nil
        end
    end

    clickArea.MouseEnter:Connect(function()
        clickArea:SetAttribute("hovered", true); applyToggle()
    end)
    clickArea.MouseLeave:Connect(function()
        clickArea:SetAttribute("hovered", false); applyToggle()
    end)
    clickArea.MouseButton1Click:Connect(function()
        state = not state; applyToggle()
        if opts.Callback then
            local ok, err = pcall(opts.Callback, state)
            if not ok then warn("[hysteria] toggle '"..tostring(opts.Text).."' error: "..tostring(err)) end
        end
    end)

    bindBtn.MouseButton2Click:Connect(function()
        if listening then stopListening() return end
        currentBind = nil
        applyBindVisual()
        if opts.BindCallback then opts.BindCallback(nil) end
    end)
    bindBtn.MouseEnter:Connect(function()
        if not listening and currentBind then bindBtn.Text = "rclick clear" end
    end)
    bindBtn.MouseLeave:Connect(function() applyBindVisual() end)
    bindBtn.MouseButton1Click:Connect(function()
        if listening then stopListening() return end
        listening = true
        _G.__PRIMO_BIND_LISTENING = true
        applyBindVisual()
        listenConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    currentBind = input.KeyCode
                    if opts.BindCallback then opts.BindCallback(currentBind) end
                end
                stopListening()
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                currentBind = input.UserInputType
                if opts.BindCallback then opts.BindCallback(currentBind) end
                stopListening()
            end
        end)
    end)

    pcall(function()
        holder.Destroying:Connect(function()
            if listening then
                listening = false
                _G.__PRIMO_BIND_LISTENING = false
                if listenConn then
                    pcall(function() listenConn:Disconnect() end)
                    listenConn = nil
                end
            end
        end)
    end)
    holder.AncestryChanged:Connect(function(_, parent)
        if not parent and listening then
            listening = false
            _G.__PRIMO_BIND_LISTENING = false
            if listenConn then
                pcall(function() listenConn:Disconnect() end)
                listenConn = nil
            end
        end
    end)

    if opts.DefaultBind and opts.BindCallback then
        task.defer(function() pcall(opts.BindCallback, opts.DefaultBind) end)
    end

    local api = {Frame=holder, Toggle=switch, BindBtn=bindBtn}
    function api:Get() return state end
    function api:GetBind() return currentBind end
    function api:Set(v, silent)
        state = v and true or false; applyToggle()
        if not silent and opts.Callback then opts.Callback(state) end
    end
    function api:SetBind(v, silent)
        if v == nil then currentBind = nil
        else
            if type(v) == "string" then currentBind = parseBind(v) else currentBind = v end
        end
        applyBindVisual()
        if not silent and opts.BindCallback then opts.BindCallback(currentBind) end
    end
    return api
end

local function buildSlider(parent, opts)
    local row = create("Frame", {Name=opts.Name or "slider", BackgroundTransparency=1,
        Size=UDim2.new(1,-24,0,38)}, parent)
    create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "slider", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-60,0,18)}, row)
    local valueLabel = create("TextLabel", {Name="value", BackgroundTransparency=1,
        Text=tostring(opts.Default or opts.Min or 0), TextSize=13,
        TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,60,0,18), Position=UDim2.new(1,-60,0,0)}, row)
    local track = create("Frame", {Name="track", BackgroundColor3=PALETTE.Element,
        Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,0,26)}, row)
    corner(track, 4); addGlass(track, 0.5, PALETTE.ElementGlass)
    local fill = create("Frame", {Name="fill", BackgroundColor3=Library.Settings.AccentColor,
        Size=UDim2.new(0,0,1,0)}, track)
    corner(fill, 4)
    local knob = create("Frame", {Name="knob", BackgroundColor3=PALETTE.Text,
        Size=UDim2.new(0,14,0,14), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0,0,0.5,0)}, track)
    corner(knob, 7)
    local min = opts.Min or 0
    local max = opts.Max or 100
    if max == min then max = min + 1 end
    local value = opts.Default or min
    local function apply()
        local alpha = (value - min)/(max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(value*100+0.5)/100)
    end
    registerAccent(function() tween(fill, {BackgroundColor3 = Library.Settings.AccentColor}) end)
    apply()
    local dragging = false
    local function updateFromX(x)
        local absX = track.AbsolutePosition.X
        local absW = math.max(track.AbsoluteSize.X, 1)
        value = min + (max - min)*math.clamp((x-absX)/absW, 0, 1)
        apply()
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(input.Position.X)
        end
    end)
    local chConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
            -- ❗ live update: callback срабатывает прямо во время drag
            -- (используется chat logger'ом чтобы ширина менялась на лету)
            if opts.Live and opts.Callback then
                pcall(opts.Callback, value)
            end
        end
    end)
    local enConn = UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if opts.Callback then opts.Callback(value) end
        end
    end)
    local api = {Frame=row}
    function api:Get() return value end
    function api:Set(v, silent)
        value = math.clamp(v, min, max); apply()
        if not silent and opts.Callback then opts.Callback(value) end
    end
    function api:Destroy()
        pcall(function() chConn:Disconnect() end)
        pcall(function() enConn:Disconnect() end)
    end
    return api
end

local function buildMultiSelectButton(parent, opts)
    local row = create("Frame", {Name=opts.Name or "multiselect",
        BackgroundTransparency=1, Size=UDim2.new(1,-24,0,28)}, parent)
    local btn = create("TextButton", {Name="main", AutoButtonColor=false,
        Text="", BackgroundColor3=PALETTE.Element, Size=UDim2.new(1,0,1,0)}, row)
    corner(btn, 7); addGlass(btn, 0.4, PALETTE.ElementGlass)
    local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=opts.Text or "select", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0)}, btn)
    local arrow = create("TextLabel", {Name="arrow", BackgroundTransparency=1,
        Text="v", TextSize=13, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-26,0,0)}, btn)
    local selected = {}
    if opts.Default then
        for _, v in ipairs(opts.Default) do selected[v] = true end
    end
    local gui = getPopupGui()
    local PW = 240
    local PH = math.min(360, 40 + 24 * math.max(#opts.Values, 4))
    local popup = create("Frame", {Name="multiselect_popup",
        BackgroundColor3=PALETTE.Panel, Size=UDim2.new(0,PW,0,PH),
        Position=UDim2.new(0,100,0,100), Visible=false, ZIndex=12}, gui)
    corner(popup, 10); addGlass(popup, 0.2, PALETTE.PanelGlass)
    create("TextLabel", {Name="title", BackgroundTransparency=1,
        Text=opts.PopupTitle or "- select -", TextSize=13,
        TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,24)}, popup)
    local scroll = create("ScrollingFrame", {Name="scroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-12,1,-32),
        Position=UDim2.new(0,6,0,28), BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, popup)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,2); layout.Parent = scroll
    local itemButtons = {}
    local function refreshLabel()
        local parts = {}
        for _, v in ipairs(opts.Values) do
            if selected[v] then parts[#parts+1] = v end
        end
        local full = opts.Text .. " : "
        if #parts == 0 then full = full .. "none"
        else full = full .. table.concat(parts, ", ") end
        if #full > 36 then full = full:sub(1, 33) .. "..." end
        label.Text = full
    end
    for i, v in ipairs(opts.Values) do
        local it = create("TextButton", {Name="item_"..i, AutoButtonColor=false,
            Text="", BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(1,0,0,22), LayoutOrder=i}, scroll)
        corner(it, 6)
        local chk = create("Frame", {Name="chk", BackgroundColor3=PALETTE.ElementHi,
            Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,6,0.5,-7)}, it)
        corner(chk, 3)
        local chkFill = create("Frame", {Name="fill",
            BackgroundColor3=Library.Settings.AccentColor,
            Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0),
            AnchorPoint=Vector2.new(0.5,0.5)}, chk)
        corner(chkFill, 2)
        local txt = create("TextLabel", {Name="txt", BackgroundTransparency=1,
            Text=v, TextSize=13, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,26,0,0)}, it)
        local function refreshItem()
            local on = selected[v]
            local fillSize = UDim2.new(0,0,0,0)
            if on then fillSize = UDim2.new(1,-4,1,-4) end
            tween(chkFill, {Size = fillSize}, 0.1)
            local txtColor = PALETTE.Text
            if on then txtColor = Library.Settings.AccentColor end
            tween(txt, {TextColor3 = txtColor}, 0.1)
            local bgTr = 0.4
            if on then bgTr = 0.1 end
            tween(it, {BackgroundTransparency = bgTr}, 0.1)
        end
        refreshItem()
        it.MouseButton1Click:Connect(function()
            selected[v] = not selected[v]
            refreshItem(); refreshLabel()
            if opts.Callback then
                local list = {}
                for _, val in ipairs(opts.Values) do
                    if selected[val] then list[#list+1] = val end
                end
                opts.Callback(list, v, selected[v])
            end
        end)
        itemButtons[#itemButtons+1] = it
    end
    refreshLabel()
    local openedAt = 0
    local function openPopup()
        local iPos, iSize = btn.AbsolutePosition, btn.AbsoluteSize
        local vp = gui.AbsoluteSize
        local x = math.clamp(iPos.X, 4, math.max(4, vp.X-PW-4))
        local y = math.clamp(iPos.Y+iSize.Y+2, 4, math.max(4, vp.Y-PH-4))
        popup.Position = UDim2.new(0, x, 0, y)
        popup.Visible = true; popup.BackgroundTransparency = 1
        openedAt = os.clock()
        tween(popup, {BackgroundTransparency=0}, 0.15)
    end
    local function closePopup()
        tween(popup, {BackgroundTransparency=1}, 0.12)
        task.delay(0.12, function() popup.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function()
        if popup.Visible then closePopup() else openPopup() end
    end)
    local outsideConn = UserInputService.InputBegan:Connect(function(input)
        if not popup.Visible then return end
        if os.clock() - openedAt < 0.25 then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = input.Position
        local function inside(g)
            local a, s = g.AbsolutePosition, g.AbsoluteSize
            return p.X>=a.X and p.X<=a.X+s.X and p.Y>=a.Y and p.Y<=a.Y+s.Y
        end
        if not inside(popup) and not inside(btn) then closePopup() end
    end)
    local function applyBtn()
        local h = btn:GetAttribute("hovered")
        local col = PALETTE.Text
        if h then col = Library.Settings.AccentColor end
        tween(label, {TextColor3 = col})
        local col2 = PALETTE.TextDim
        if h then col2 = Library.Settings.AccentColor end
        tween(arrow, {TextColor3 = col2})
    end
    btn.MouseEnter:Connect(function() btn:SetAttribute("hovered", true); applyBtn() end)
    btn.MouseLeave:Connect(function() btn:SetAttribute("hovered", false); applyBtn() end)
    registerAccent(applyBtn)
    local api = {Frame=row}
    function api:Get()
        local list = {}
        for _, val in ipairs(opts.Values) do
            if selected[val] then list[#list+1] = val end
        end
        return list
    end
    function api:Set(list, silent)
        selected = {}
        if type(list) == "table" then
            for _, v in ipairs(list) do selected[v] = true end
        end
        for i, v in ipairs(opts.Values) do
            local it = itemButtons[i]
            if it then
                local chk = it:FindFirstChild("chk")
                local chkFill = chk and chk:FindFirstChild("fill")
                local txt = it:FindFirstChild("txt")
                local on = selected[v]
                if chkFill then
                    local fillSize = UDim2.new(0,0,0,0)
                    if on then fillSize = UDim2.new(1,-4,1,-4) end
                    tween(chkFill, {Size = fillSize}, 0.1)
                end
                if txt then
                    local txtColor = PALETTE.Text
                    if on then txtColor = Library.Settings.AccentColor end
                    tween(txt, {TextColor3 = txtColor}, 0.1)
                end
                local bgTr = 0.4
                if on then bgTr = 0.1 end
                tween(it, {BackgroundTransparency = bgTr}, 0.1)
            end
        end
        refreshLabel()
        if not silent and opts.Callback then opts.Callback(self:Get()) end
    end
    function api:Destroy()
        pcall(function() outsideConn:Disconnect() end)
        popup:Destroy()
    end
    return api
end

Section = {}
Section.__index = Section
function Section:_place(gui, height)
    gui.Position = UDim2.new(0,12,0,self.Y)
    gui.Size = UDim2.new(1,-24,0,height)
    self.Y = self.Y + height + 8
    return gui
end
function Section:Toggle(o) local t = buildToggle(self.Frame, o); self:_place(t.Frame, 28); return t end
function Section:Button(o) local b = buildButton(self.Frame, o); self:_place(b.Frame, o.Height or 28); return b end
function Section:CheckGearRow(o) local r = buildCheckGearRow(self.Frame, o); self:_place(r.Frame, 28); return r end
function Section:ToggleBindRow(o)
    local r = buildToggleBindRow(self.Frame, o)
    local h = (type(o.Hint) == "string" and o.Hint ~= "") and 44 or 28
    self:_place(r.Frame, h)
    return r
end
function Section:ConfirmButton(o) local b = buildConfirmButton(self.Frame, o); self:_place(b.Frame, 28); return b end
function Section:MultiSelect(o) local b = buildMultiSelectButton(self.Frame, o); self:_place(b.Frame, 28); return b end
function Section:Cycle(o)
    local values = o.Values or {}
    local prefix = o.Prefix or ""
    local idx = o.Index or 1
    if #values == 0 then values = {""} end
    if idx < 1 or idx > #values then idx = 1 end
    local b = buildButton(self.Frame, {Text = prefix .. tostring(values[idx] or "")})
    self:_place(b.Frame, 28)
    local api = {Frame=b.Frame, Instance=b.Instance}
    function api:Get() return values[idx] end
    function api:Set(v, silent)
        local found = false
        for i, val in ipairs(values) do
            if val == v then
                idx = i
                found = true
                break
            end
        end
        if not found then return end
        b.Instance.Text = prefix .. tostring(values[idx])
        if not silent and o.Callback then o.Callback(values[idx]) end
    end
    function api:Refresh(newValues, newIndex)
        values = newValues or values
        if #values == 0 then values = {""} end
        idx = newIndex or 1
        if idx > #values or idx < 1 then idx = 1 end
        b.Instance.Text = prefix .. tostring(values[idx])
    end
    b.Instance.MouseButton1Click:Connect(function()
        idx = (idx % #values) + 1
        b.Instance.Text = prefix .. tostring(values[idx])
        if o.Callback then o.Callback(values[idx]) end
    end)
    return api
end
function Section:TextBox(o) local b = buildTextBox(self.Frame, o); self:_place(b.Frame, o.Height or 28); return b end
function Section:NumberInput(o) local b = buildNumberInput(self.Frame, o); self:_place(b.Frame, 28); return b end
function Section:BindInput(o) local b = buildBindInput(self.Frame, o); self:_place(b.Frame, 50); return b end
function Section:Slider(o) local s = buildSlider(self.Frame, o); self:_place(s.Frame, 38); return s end
function Section:ColorPicker(o) local c = buildColorPicker(self.Frame, o or {}); self:_place(c.Frame, 28); return c end
function Section:Label(text, height)
    local l = create("TextLabel", {Name="label", BackgroundTransparency=1, Text=text,
        TextSize=13, TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true}, self.Frame)
    self:_place(l, height or 20); return l
end
function Section:Divider()
    local d = create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
        BackgroundTransparency=0.7, Size=UDim2.new(1,-24,0,1)}, self.Frame)
    self:_place(d, 1)
    return d
end
function Section:Swatches(o)
    local colors = o.Colors or {}
    local cols = o.Columns or 5
    local size = o.Size or 28
    local gap = o.Gap or 8
    local rows = math.max(1, math.ceil(#colors/cols))
    local height = rows*size + (rows-1)*gap
    local holder = create("Frame", {Name="swatches", BackgroundTransparency=1}, self.Frame)
    for i, color in ipairs(colors) do
        local c = (i-1)%cols
        local r = math.floor((i-1)/cols)
        local sw = create("TextButton", {Name="swatch", AutoButtonColor=false, Text="",
            BackgroundColor3=color, Size=UDim2.new(0,size,0,size),
            Position=UDim2.new(0,c*(size+gap),0,r*(size+gap))}, holder)
        corner(sw, 8)
        local scale = Instance.new("UIScale"); scale.Parent = sw
        local glow = Instance.new("UIStroke")
        glow.Color = Color3.new(1,1,1); glow.Thickness = 2; glow.Transparency = 1
        glow.Parent = sw
        sw.MouseEnter:Connect(function()
            tween(scale, {Scale=1.15}, 0.15); tween(glow, {Transparency=0.3}, 0.15)
        end)
        sw.MouseLeave:Connect(function()
            tween(scale, {Scale=1.0}, 0.15); tween(glow, {Transparency=1}, 0.15)
        end)
        sw.MouseButton1Click:Connect(function()
            if o.Callback then o.Callback(color) end
        end)
    end
    self:_place(holder, height); return holder
end

local function buildSection(parent, opts)
    local frame = create("Frame", {Name=opts.Name or "section",
        BackgroundColor3=PALETTE.Panel, Size=opts.Size or UDim2.new(0,204,0,204),
        Position=opts.Position or UDim2.new(0,0,0,0),
        ZIndex=opts.ZIndex or 1}, parent)
    corner(frame, 10); addGlass(frame, 0.2, PALETTE.PanelGlass)
    local divider = create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
        BackgroundTransparency=0.8, Size=UDim2.new(1,-24,0,1),
        Position=UDim2.new(0,12,0,28)}, frame)
    local dg = Instance.new("UIGradient")
    dg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,1)})
    dg.Parent = divider
    create("TextLabel", {Name="header", BackgroundTransparency=1,
        Text=opts.Title or "- section -", TextSize=14, TextColor3=PALETTE.Text,
        FontFace=FONT_BOLD, Size=UDim2.new(1,0,0,28)}, frame)
    return setmetatable({Frame=frame, Y=36}, Section)
end

makePopupFrame = function(name, titleText, PW, PH)
    local gui = getPopupGui()
    local popup = create("Frame", {Name=name, BackgroundColor3=PALETTE.Panel,
        BackgroundTransparency=1, Size=UDim2.new(0,PW,0,PH),
        Position=UDim2.new(0,100,0,100), Visible=false, ZIndex=5}, gui)
    corner(popup, 10); addGlass(popup, 0.2, PALETTE.PanelGlass)
    local titleBar = create("Frame", {Name="titlebar", BackgroundTransparency=1,
        Active=true, Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,0), ZIndex=6}, popup)
    create("TextLabel", {Name="title", BackgroundTransparency=1, Text=titleText,
        TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.new(1,0,0,26)}, titleBar)
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = input.Position; startPos = popup.Position
    end)
    local dragConns = {}
    table.insert(dragConns, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        popup.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
            startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end))
    table.insert(dragConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))
    popup.Destroying:Connect(function()
        for _, c in ipairs(dragConns) do
            pcall(function() c:Disconnect() end)
        end
        dragConns = {}
    end)
    return popup, gui
end

local ANIMATION_STYLES = {"flow", "sweep", "wave", "pulse"}

local function resolveSeq(A, B)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, A),
        ColorSequenceKeypoint.new(0.5, B),
        ColorSequenceKeypoint.new(1, A),
    })
end
local function resolvePulseSeq(A, B, k)
    local mid = A:Lerp(B, k)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, A),
        ColorSequenceKeypoint.new(0.5, mid),
        ColorSequenceKeypoint.new(1, A),
    })
end

local FONT_CHOICES = {
    {name="arial", enum=Enum.Font.Arial},
    {name="arial bold", enum=Enum.Font.ArialBold},
    {name="gotham", enum=Enum.Font.Gotham},
    {name="gotham bold", enum=Enum.Font.GothamBold},
    {name="gotham black", enum=Enum.Font.GothamBlack},
    {name="source sans", enum=Enum.Font.SourceSans},
    {name="code", enum=Enum.Font.Code},
    {name="cartoon", enum=Enum.Font.Cartoon},
    {name="fantasy", enum=Enum.Font.Fantasy},
    {name="indie flower", enum=Enum.Font.IndieFlower},
    {name="patrick hand", enum=Enum.Font.PatrickHand},
    {name="sci-fi", enum=Enum.Font.SciFi},
    {name="special elite", enum=Enum.Font.SpecialElite},
    {name="arcade", enum=Enum.Font.Arcade},
    {name="highway", enum=Enum.Font.Highway},
    {name="jura", enum=Enum.Font.Jura},
    {name="luckiest guy", enum=Enum.Font.LuckiestGuy},
    {name="michroma", enum=Enum.Font.Michroma},
    {name="nunito", enum=Enum.Font.Nunito},
    {name="roboto", enum=Enum.Font.Roboto},
    {name="roboto condensed", enum=Enum.Font.RobotoCondensed},
    {name="roboto mono", enum=Enum.Font.RobotoMono},
    {name="ubuntu", enum=Enum.Font.Ubuntu},
}
local FONT_NAMES = {}
for _, f in ipairs(FONT_CHOICES) do table.insert(FONT_NAMES, f.name) end
local function getFontByName(n)
    for _, f in ipairs(FONT_CHOICES) do
        if f.name == n then return Font.fromEnum(f.enum) end
    end
    return Font.fromEnum(Enum.Font.Arial)
end

local function buildStylePicker(parent, opts)
    local gui = getPopupGui()
    local row = create("Frame", {Name="stylepicker", BackgroundTransparency=1,
        Size=UDim2.new(1,-24,0,28)}, parent)
    local btn = create("TextButton", {Name="main", AutoButtonColor=false, Text="",
        BackgroundColor3=PALETTE.Element, Size=UDim2.new(1,0,1,0)}, row)
    corner(btn, 7); addGlass(btn, 0.4, PALETTE.ElementGlass)
    local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
        Text=(opts.Text or "style") .. " : " .. tostring(opts.Default or "flow"),
        TextSize=13, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0)}, btn)
    create("TextLabel", {Name="arrow", BackgroundTransparency=1, Text="v",
        TextSize=13, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-26,0,0)}, btn)

    local values = opts.Values or ANIMATION_STYLES
    local current = opts.Default or values[1]

    local PW = 240
    local PH = 40 + 26 * math.max(#values, 4)
    local _sp_id = tostring(math.random(1, 1e9))
    local popup = create("Frame", {Name="stylepicker_popup_".._sp_id,
        BackgroundColor3=PALETTE.Panel, Size=UDim2.new(0,PW,0,PH),
        Position=UDim2.new(0,100,0,100), Visible=false, ZIndex=21}, gui)
    corner(popup, 10); addGlass(popup, 0.2, PALETTE.PanelGlass)
    create("TextLabel", {Name="title", BackgroundTransparency=1, Text="- animation style -",
        TextSize=13, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,24)}, popup)
    local scroll = create("ScrollingFrame", {Name="scroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-12,1,-32),
        Position=UDim2.new(0,6,0,28), BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, popup)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,2); layout.Parent = scroll

    local items = {}
    local function refreshItems()
        for _, it in pairs(items) do
            local on = (it.value == current)
            tween(it.txt, {TextColor3 = on and Library.Settings.AccentColor or PALETTE.Text}, 0.1)
            tween(it.frame, {BackgroundTransparency = on and 0.1 or 0.4}, 0.1)
        end
    end
    for i, v in ipairs(values) do
        local it = create("TextButton", {Name="item_"..i, AutoButtonColor=false,
            Text="", BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(1,0,0,22), LayoutOrder=i}, scroll)
        corner(it, 6)
        local txt = create("TextLabel", {Name="txt", BackgroundTransparency=1,
            Text=tostring(v), TextSize=13, TextColor3=PALETTE.Text,
            FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0)}, it)
        items[#items+1] = {frame=it, txt=txt, value=v}
        it.MouseButton1Click:Connect(function()
            current = v
            label.Text = (opts.Text or "style") .. " : " .. tostring(v)
            refreshItems()
            if opts.Callback then opts.Callback(v) end
            tween(popup, {BackgroundTransparency=1}, 0.12)
            task.delay(0.12, function() popup.Visible = false end)
        end)
    end
    refreshItems()

    local openedAt = 0
    local function closePopup()
        tween(popup, {BackgroundTransparency=1}, 0.12)
        task.delay(0.12, function() popup.Visible = false end)
    end
    btn.MouseButton1Click:Connect(function()
        if popup.Visible then closePopup() return end
        local iPos, iSize = btn.AbsolutePosition, btn.AbsoluteSize
        local vp = gui.AbsoluteSize
        local x = math.clamp(iPos.X-PW+iSize.X, 4, math.max(4, vp.X-PW-4))
        local y = math.clamp(iPos.Y, 4, math.max(4, vp.Y-PH-4))
        popup.Position = UDim2.new(0, x, 0, y)
        popup.Visible = true; popup.BackgroundTransparency = 1
        openedAt = os.clock()
        tween(popup, {BackgroundTransparency=0}, 0.15)
    end)
    local outsideConn = UserInputService.InputBegan:Connect(function(input)
        if not popup.Visible then return end
        if os.clock() - openedAt < 0.25 then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = input.Position
        local function inside(g)
            local a, s = g.AbsolutePosition, g.AbsoluteSize
            return p.X>=a.X and p.X<=a.X+s.X and p.Y>=a.Y and p.Y<=a.Y+s.Y
        end
        if not inside(popup) and not inside(btn) then closePopup() end
    end)
    btn.MouseEnter:Connect(function() tween(label, {TextColor3=Library.Settings.AccentColor}) end)
    btn.MouseLeave:Connect(function() tween(label, {TextColor3=PALETTE.Text}) end)
    local api = {Frame=row}
    function api:Get() return current end
    function api:Set(v, silent)
        if v == nil then return end
        current = v
        label.Text = (opts.Text or "style") .. " : " .. tostring(v)
        refreshItems()
        if not silent and opts.Callback then opts.Callback(v) end
    end
    function api:Destroy() outsideConn:Disconnect(); popup:Destroy() end
    return api
end

function Section:StylePicker(o)
    local c = buildStylePicker(self.Frame, o)
    self:_place(c.Frame, 28)
    return c
end

local function makeSettingsHandlers(popup, PW, PH, anchorRef, openedAtRef, gui)
    local api = {}

    -- ═══════════════════════════════════════════════════════════
    -- ❗ DIM BACKGROUND + POP-IN ANIMATION
    -- чёрный полупрозрачный фон перекрывает меню и HUD,
    -- ловит клики мимо попапа → нельзя случайно нажать кнопку под ним
    -- ═══════════════════════════════════════════════════════════
    -- ═══════════════════════════════════════════════════════════
    -- ❗ DIMMER — только над областью МЕНЮ, а не весь экран.
    -- Раньше он был full-screen и перехватывал клики по HUD
    -- (watermark, keybinds, targetesp, picture, session) — из-за
    -- этого попап закрывался когда юзер тащил HUD-элемент.
    -- ═══════════════════════════════════════════════════════════
    local dimName = "__dim_" .. popup.Name
    local dimmer = gui:FindFirstChild(dimName)
    if not dimmer then
        dimmer = create("TextButton", {Name=dimName,
            BackgroundColor3=Color3.new(0,0,0),
            BackgroundTransparency=1,
            Text="", AutoButtonColor=false,
            Size=UDim2.new(0,0,0,0),   -- синкается с меню через syncDim
            Position=UDim2.new(0,0,0,0),
            Visible=false,
            ZIndex=4,
            BorderSizePixel=0}, gui)
    end
    dimmer.ClipsDescendants = false

    local _dimConns = {}
    local function syncDim()
        local mf = Library._menuFrame
        if not mf or not mf.Parent then
            -- fallback: если меню нет (должно быть редко) → на весь экран
            dimmer.Position = UDim2.new(0,0,0,0)
            dimmer.Size     = UDim2.new(1,0,1,0)
            return
        end
        local ap = mf.AbsolutePosition
        local as = mf.AbsoluteSize
        local pad = 10
        dimmer.Position = UDim2.new(0, ap.X - pad, 0, ap.Y - pad)
        dimmer.Size     = UDim2.new(0, as.X + pad*2, 0, as.Y + pad*2)
    end
    syncDim()
    do
        local mf = Library._menuFrame
        if mf then
            table.insert(_dimConns, mf:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncDim))
            table.insert(_dimConns, mf:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncDim))
            table.insert(_dimConns, mf.AncestryChanged:Connect(syncDim))
        end
    end

    -- UIScale для pop-in анимации
    local popScale = popup:FindFirstChildOfClass("UIScale")
    if not popScale then
        popScale = Instance.new("UIScale")
        popScale.Parent = popup
    end
    popScale.Scale = 1

    local _animating = false
    local function _hasChildPopup()
        -- не даём dimmer'у закрыть settings, если открыт colorpicker/stylepicker
        for _, ch in ipairs(gui:GetChildren()) do
            if ch:IsA("GuiObject") and ch.Visible and ch ~= popup then
                local n = ch.Name
                if n:find("colorpicker_popup", 1, true)
                   or n:find("stylepicker_popup", 1, true)
                   or n:find("multiselect_popup", 1, true) then
                    return true
                end
            end
        end
        return false
    end

    local function openAnimated(finalPos)
        if _animating then return end
        _animating = true
        popup.Position = finalPos
        popup.Visible = true
        dimmer.Visible = true
        popup.BackgroundTransparency = 1
        dimmer.BackgroundTransparency = 1
        popScale.Scale = 0.85
        openedAtRef.value = os.clock()
        tween(popup, {BackgroundTransparency=0}, 0.22)
        tween(dimmer, {BackgroundTransparency=0.55}, 0.22)
        TweenService:Create(popScale,
            TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}):Play()
        task.delay(0.32, function() _animating = false end)
    end
    local function closeAnimated()
        if _animating then return end
        if not popup.Visible then return end
        _animating = true
        tween(popup, {BackgroundTransparency=1}, 0.16)
        tween(dimmer, {BackgroundTransparency=1}, 0.16)
        TweenService:Create(popScale,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.9}):Play()
        task.delay(0.18, function()
            popup.Visible = false
            dimmer.Visible = false
            popScale.Scale = 1
            _animating = false
        end)
    end
    api._openAnimated  = openAnimated
    api._closeAnimated = closeAnimated

    -- клик по dimmer → закрыть (если нет дочернего попапа сверху)
    dimmer.MouseButton1Click:Connect(function()
        if _hasChildPopup() then return end
        closeAnimated()
    end)

    -- ❗ при закрытии/уничтожении отписываем syncDim-коннекты
    local _origDestroy = api.Destroy
    api.Destroy = function(self)
        for _, c in ipairs(_dimConns) do pcall(function() c:Disconnect() end) end
        _dimConns = {}
        if _origDestroy then pcall(_origDestroy, self) end
    end

    -- ❗ крестик закрытия в правом верхнем углу любого settings-попапа
    do
        local closeBtn = create("TextButton", {Name="__close", AutoButtonColor=false,
            Text="×", TextSize=20, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.5,
            Size=UDim2.new(0,22,0,20), Position=UDim2.new(1,-26,0,3),
            ZIndex=60}, popup)
        corner(closeBtn, 5)
        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, {TextColor3=PALETTE.Warn, BackgroundTransparency=0.15})
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, {TextColor3=PALETTE.TextDim, BackgroundTransparency=0.5})
        end)
        closeBtn.MouseButton1Click:Connect(function()
            closeAnimated()
        end)
    end

    function api:Open(anchor)
        anchorRef.instance = anchor
        local vp = gui.AbsoluteSize
        local x, y
        if anchor then
            local gPos, gSize = anchor.AbsolutePosition, anchor.AbsoluteSize
            x = gPos.X + gSize.X - PW
            y = gPos.Y + gSize.Y + 6
        else
            x = (vp.X - PW) / 2
            y = (vp.Y - PH) / 2
        end
        -- ❗ не даём попапу перекрывать сам меню-фрейм:
        -- сдвигаем направо или налево, если есть место
        local mf = Library._menuFrame
        if mf and mf.Parent and anchor then
            local mPos, mSize = mf.AbsolutePosition, mf.AbsoluteSize
            local overlapsH = (x + PW > mPos.X) and (x < mPos.X + mSize.X)
            local overlapsV = (y + PH > mPos.Y) and (y < mPos.Y + mSize.Y)
            if overlapsH and overlapsV then
                if mPos.X + mSize.X + PW + 12 <= vp.X then
                    x = mPos.X + mSize.X + 12
                elseif mPos.X - PW - 12 >= 4 then
                    x = mPos.X - PW - 12
                end
            end
        end
        x = math.clamp(x, 4, math.max(4, vp.X - PW - 4))
        y = math.clamp(y, 4, math.max(4, vp.Y - PH - 4))
        openAnimated(UDim2.new(0, x, 0, y))
    end
    function api:Close()
        closeAnimated()
    end
    function api:Toggle(anchor) if popup.Visible then self:Close() else self:Open(anchor) end end
    function api:IsOpen() return popup.Visible end
    local outsideConn = UserInputService.InputBegan:Connect(function(input)
        if not popup.Visible then return end
        if os.clock() - openedAtRef.value < 0.3 then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p = input.Position
        local function inside(g)
            if not g or not g.Parent then return false end
            local a, s = g.AbsolutePosition, g.AbsoluteSize
            return p.X>=a.X and p.X<=a.X+s.X and p.Y>=a.Y and p.Y<=a.Y+s.Y
        end
        if inside(popup) then return end
        if anchorRef.instance and inside(anchorRef.instance) then return end
        for _, ch in ipairs(gui:GetChildren()) do
            if ch:IsA("GuiObject") and ch.Visible then
                local n = ch.Name
                if n:find("colorpicker_popup", 1, true)
                   or n:find("stylepicker_popup", 1, true)
                   or n:find("multiselect_popup", 1, true) then
                    if inside(ch) then return end
                end
            end
        end
        -- ❗ не закрываем попап если клик попал по HUD-элементу
        -- (watermark / keybinds / targetesp / picture / session / chat)
        -- — иначе нельзя тащить HUD с открытыми настройками
        do
            local reg = _G.__PRIMO_HUD_FRAMES
            if reg then
                for _, fr in ipairs(reg) do
                    if fr and fr.Parent and inside(fr) then return end
                end
            end
        end
        closeAnimated()
    end)
    function api:Destroy()
        outsideConn:Disconnect()
        popup:Destroy()
    end
    return api
end

local function buildWatermarkSettingsPopup(wmApi)
    local PW, PH = 720, 680
    local popup, gui = makePopupFrame("watermark_settings", "- watermark settings -", PW, PH)
    local colW, colGap, startX, startY = 170, 5, 5, 30
    local colH = PH - startY - 10
    -- ❗ делаем колонки скроллируемыми — иначе контент вроде logo/layout/bg
    -- обрезается за нижней границей попапа (жалоба "немного закрывает")
    local function makeCol(idx)
        return create("ScrollingFrame", {Name="col"..idx, BackgroundTransparency=1,
            Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
            Size=UDim2.new(0,colW,0,colH),
            BorderSizePixel=0,
            ScrollBarThickness=3,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            ScrollBarImageTransparency=0.5,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
            ClipsDescendants=true}, popup)
    end
    local s1 = setmetatable({Frame=makeCol(1), Y=0}, Section)
    local s2 = setmetatable({Frame=makeCol(2), Y=0}, Section)
    local s3 = setmetatable({Frame=makeCol(3), Y=0}, Section)
    local s4 = setmetatable({Frame=makeCol(4), Y=0}, Section)
    local cfg = wmApi:GetConfig()

    s1:Label("visibility:")
    reg(s1, "Toggle", "wm.ShowName", {Text="name", Default=cfg.ShowName, Callback=function(v) wmApi:SetShowName(v) end})
    reg(s1, "Toggle", "wm.ShowFPS", {Text="fps", Default=cfg.ShowFPS, Callback=function(v) wmApi:SetShowFPS(v) end})
    reg(s1, "Toggle", "wm.ShowPing", {Text="ping", Default=cfg.ShowPing, Callback=function(v) wmApi:SetShowPing(v) end})
    reg(s1, "Toggle", "wm.ShowTime", {Text="time", Default=cfg.ShowTime, Callback=function(v) wmApi:SetShowTime(v) end})
    reg(s1, "Toggle", "wm.ShowPlayers", {Text="players", Default=cfg.ShowPlayers, Callback=function(v) wmApi:SetShowPlayers(v) end})
    reg(s1, "Toggle", "wm.ShowUptime", {Text="uptime", Default=cfg.ShowUptime, Callback=function(v) wmApi:SetShowUptime(v) end})
    reg(s1, "Toggle", "wm.ShowHealth", {Text="health", Default=cfg.ShowHealth, Callback=function(v) wmApi:SetShowHealth(v) end})
    reg(s1, "Toggle", "wm.ShowTarget", {Text="target", Default=cfg.ShowTarget, Callback=function(v) wmApi:SetShowTarget(v) end})
    reg(s1, "Toggle", "wm.ShowExpires", {Text="expires", Default=cfg.ShowExpires, Callback=function(v) wmApi:SetShowExpires(v) end})
    reg(s1, "Toggle", "wm.ShowUID", {Text="uid", Default=cfg.ShowUID, Callback=function(v) wmApi:SetShowUID(v) end})
    s1:Divider()
    reg(s1, "Toggle", "wm.ShowSeparators", {Text="separators", Default=cfg.ShowSeparators, Callback=function(v) wmApi:SetShowSeparators(v) end})

    s2:Label("gradient:")
    reg(s2, "Toggle", "wm.Gradient", {Text="enabled", Default=cfg.Gradient, Callback=function(v) wmApi:SetGradient(v) end})
    s2:Divider()
    s2:Label("colors:")
    reg(s2, "ColorPicker", "wm.ColorA", {Text="color a",
        GetInitialColor=function() return wmApi:GetConfig().ColorA end,
        Callback=function(c) wmApi:SetColorA(c) end})
    reg(s2, "ColorPicker", "wm.ColorB", {Text="color b",
        GetInitialColor=function() return wmApi:GetConfig().ColorB end,
        Callback=function(c) wmApi:SetColorB(c) end})
    s2:Divider()
    s2:Label("animation style:")
    reg(s2, "StylePicker", "wm.Style", {Text="style", Default=cfg.Style,
        Callback=function(v) wmApi:SetStyle(v) end})
    reg(s2, "Slider", "wm.Speed", {Text="speed", Min=0, Max=3, Default=cfg.Speed,
        Callback=function(v) wmApi:SetSpeed(v) end})

    s3:Label("gradient on (per element):")
    reg(s3, "Toggle", "wm.GradProductName", {Text="product name", Default=cfg.GradProductName, Callback=function(v) wmApi:SetGradProductName(v) end})
    reg(s3, "Toggle", "wm.GradPlayerName",  {Text="player name",  Default=cfg.GradPlayerName,  Callback=function(v) wmApi:SetGradPlayerName(v) end})
    reg(s3, "Toggle", "wm.GradFPS",         {Text="fps",          Default=cfg.GradFPS,         Callback=function(v) wmApi:SetGradFPS(v) end})
    reg(s3, "Toggle", "wm.GradPing",        {Text="ping",         Default=cfg.GradPing,        Callback=function(v) wmApi:SetGradPing(v) end})
    reg(s3, "Toggle", "wm.GradTime",        {Text="time",         Default=cfg.GradTime,        Callback=function(v) wmApi:SetGradTime(v) end})
    reg(s3, "Toggle", "wm.GradPlayers",     {Text="players",      Default=cfg.GradPlayers,     Callback=function(v) wmApi:SetGradPlayers(v) end})
    reg(s3, "Toggle", "wm.GradUptime",      {Text="uptime",       Default=cfg.GradUptime,      Callback=function(v) wmApi:SetGradUptime(v) end})
    reg(s3, "Toggle", "wm.GradHealth",      {Text="health",       Default=cfg.GradHealth,      Callback=function(v) wmApi:SetGradHealth(v) end})
    reg(s3, "Toggle", "wm.GradTarget",      {Text="target",       Default=cfg.GradTarget,      Callback=function(v) wmApi:SetGradTarget(v) end})

    s4:Label("cheat name preset:")
    reg(s4, "Cycle", "wm.CheatNamePreset", {
        Prefix="name: ",
        Values={"classic","true","kawaii","legacy","kaomoji"},
        Index=1,
        Callback=function(v) wmApi:SetCheatNamePreset(v) end})
    s4:Label("classic=hysteria | true=ХЫСТЭРЫЯ ЧЫТ", 14)
    s4:Label("kawaii=hysteria >w< | kaomoji=(●'◡'●)", 14)
    s4:Divider()
    s4:Label("name:")
    reg(s4, "Toggle", "wm.CustomName", {Text="custom name", Default=cfg.CustomName,
        Callback=function(v) wmApi:SetCustomName(v) end})
    reg(s4, "TextBox", "wm.CustomNameText", {Placeholder="enter name...", Text=cfg.CustomNameText,
        Callback=function(t) wmApi:SetCustomNameText(t) end})
    local initialFontIdx = 1
    for i, n in ipairs(FONT_NAMES) do if n == cfg.Font then initialFontIdx = i break end end
    s4:Label("font:")
    reg(s4, "Cycle", "wm.Font", {Prefix="", Values=FONT_NAMES, Index=initialFontIdx,
        Callback=function(v) wmApi:SetFont(v) end})
    s4:Divider()
    s4:Label("logo:")
    reg(s4, "Toggle", "wm.LogoAccent", {Text="use accent color",
        Default=wmApi:GetConfig().LogoAccent, Callback=function(v) wmApi:SetLogoAccent(v) end})
    reg(s4, "ColorPicker", "wm.LogoColor", {Text="logo color",
        GetInitialColor=function() return wmApi:GetConfig().LogoColor end,
        Callback=function(c) wmApi:SetLogoColor(c) end})
    reg(s4, "Slider", "wm.LogoTransparency", {Text="logo transparency",
        Min=0, Max=1, Default=wmApi:GetConfig().LogoTransparency,
        Callback=function(v) wmApi:SetLogoTransparency(v) end})

    -- ══ LOGO IMAGE BROWSER ══
    local WM_LOGOS = {
        { name = "default (hysteria)",   url = "rbxassetid://304489727" },
        { name = "aspirine transparent", url = "rbxassetid://98491322897003" },
        { name = "hysteria banner",      url = "rbxassetid://12150333118" },
        { name = "aspirine",             url = "rbxassetid://125404550221755" },
        { name = "furry femboy",         url = "rbxassetid://106158288148110" },
        { name = "player avatar",        url = "rbxthumb://type=AvatarHeadShot&id="
                                            .. tostring(game:GetService("Players").LocalPlayer.UserId)
                                            .. "&w=150&h=150" },
    }
    local function openWMLogoBrowser()
        local PW2, PH2 = 460, 480
        local popup2, _ = makePopupFrame("wm_logo_browser", "- logo browser -", PW2, PH2)
        local scroll2 = create("ScrollingFrame", {
            Name="list", BackgroundTransparency=1,
            Size=UDim2.new(1,-24,1,-40), Position=UDim2.new(0,12,0,32),
            BorderSizePixel=0, ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, popup2)
        local lay2 = Instance.new("UIListLayout")
        lay2.SortOrder = Enum.SortOrder.LayoutOrder
        lay2.Padding = UDim.new(0,4); lay2.Parent = scroll2
        local pad2 = Instance.new("UIPadding")
        pad2.PaddingTop = UDim.new(0,4); pad2.PaddingBottom = UDim.new(0,4)
        pad2.PaddingLeft = UDim.new(0,4); pad2.PaddingRight = UDim.new(0,4)
        pad2.Parent = scroll2
        for i, item in ipairs(WM_LOGOS) do
            local row = create("Frame", {Name="wm_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.35,
                Size=UDim2.new(1,0,0,44), LayoutOrder=i}, scroll2)
            corner(row, 6)
            local thumb = create("ImageLabel", {Name="thumb",
                BackgroundColor3=PALETTE.Element, Image=item.url,
                ImageColor3=Color3.new(1,1,1),
                Size=UDim2.new(0,36,0,36), Position=UDim2.new(0,4,0.5,-18)}, row)
            corner(thumb, 5)
            create("TextLabel", {Name="nm", BackgroundTransparency=1,
                Text=item.name, TextSize=12, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,48,0,0)}, row)
            local applyBtn = create("TextButton", {Name="apply",
                AutoButtonColor=false, Text="apply", TextSize=11,
                TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,60,1,-12), Position=UDim2.new(1,-66,0,6)}, row)
            corner(applyBtn, 5)
            applyBtn.MouseEnter:Connect(function()
                tween(applyBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
            end)
            applyBtn.MouseLeave:Connect(function()
                tween(applyBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
            end)
            applyBtn.MouseButton1Click:Connect(function()
                if wmApi.SetLogoImage then pcall(function() wmApi:SetLogoImage(item.url) end) end
                popup2:Destroy()
            end)
        end
        local customBox = create("TextBox", {Name="custom",
            Text="", PlaceholderText="id or rbxassetid://",
            PlaceholderColor3=PALETTE.TextDim, TextSize=12,
            TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
            BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-100,0,26), Position=UDim2.new(0,12,1,-34)}, popup2)
        corner(customBox, 5); addGlass(customBox, 0.4, PALETTE.ElementGlass)
        local cpad = Instance.new("UIPadding")
        cpad.PaddingLeft = UDim.new(0,8); cpad.PaddingRight = UDim.new(0,8); cpad.Parent = customBox
        local applyCustom = create("TextButton", {Name="applyC",
            AutoButtonColor=false, Text="apply", TextSize=11,
            TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(0,72,0,26), Position=UDim2.new(1,-84,1,-34)}, popup2)
        corner(applyCustom, 5)
        local function applyC()
            local t = customBox.Text or ""
            if t == "" then return end
            if t:match("^%d+$") then t = "rbxassetid://" .. t end
            if wmApi.SetLogoImage then pcall(function() wmApi:SetLogoImage(t) end) end
            popup2:Destroy()
        end
        applyCustom.MouseButton1Click:Connect(applyC)
        customBox.FocusLost:Connect(function(enter) if enter then applyC() end end)
        popup2.Position = UDim2.new(0.5, -PW2/2, 0.5, -PH2/2)
        popup2.Visible = true
        popup2.BackgroundTransparency = 0
    end
    s4:Button({Text="browse logo image", Callback=openWMLogoBrowser})
    s4:Label("aspirine transparent = pinned", 14)

    s4:Divider()
    s4:Label("layout:")
    reg(s4, "Slider", "wm.TextSize", {Text="text size",
        Min=8, Max=28, Default=(cfg.TextSize or 14),
        Callback=function(v) wmApi:SetTextSize(v) end})
    reg(s4, "Slider", "wm.LogoSize", {Text="logo size",
        Min=10, Max=48, Default=(cfg.LogoSize or 22),
        Callback=function(v) wmApi:SetLogoSize(v) end})
    reg(s4, "Slider", "wm.Gap", {Text="gap between items",
        Min=0, Max=24, Default=(cfg.Gap or 6),
        Callback=function(v) wmApi:SetGap(v) end})
    reg(s4, "Slider", "wm.PaddingLeft", {Text="padding left",
        Min=0, Max=40, Default=(cfg.PaddingLeft or 8),
        Callback=function(v) wmApi:SetPaddingLeft(v) end})
    reg(s4, "Slider", "wm.PaddingRight", {Text="padding right",
        Min=0, Max=40, Default=(cfg.PaddingRight or 10),
        Callback=function(v) wmApi:SetPaddingRight(v) end})

    s4:Divider()
    s4:Label("transform:")
    reg(s4, "Slider", "wm.scale", {Text="scale",
        Min=0.5, Max=3, Default=1,
        Callback=function(v)
            if wmApi and wmApi.SetScale then wmApi:SetScale(v) end
        end})
    reg(s4, "Toggle", "wm.LockDrag", {Text="lock position", Default=false,
        Callback=function(v) wmApi:GetConfig().LockDrag = v end})
    s4:Divider()
    s4:Label("background:")
    reg(s4, "ColorPicker", "wm.BgColor", {Text="bg color",
        GetInitialColor=function() return wmApi:GetConfig().BgColor end,
        Callback=function(c) wmApi:SetBgColor(c) end})
    reg(s4, "Slider", "wm.BgTransparency", {Text="bg transparency", Min=0, Max=1,
        Default=wmApi:GetConfig().BgTransparency,
        Callback=function(v) wmApi:SetBgTransparency(v) end})
    reg(s4, "Slider", "wm.CornerRadius", {Text="corner radius", Min=0, Max=20,
        Default=wmApi:GetConfig().CornerRadius,
        Callback=function(v) wmApi:SetCornerRadius(v) end})
    s4:Divider()
    s4:Label("stroke:")
    reg(s4, "ColorPicker", "wm.StrokeColor", {Text="stroke color",
        GetInitialColor=function() return wmApi:GetConfig().StrokeColor end,
        Callback=function(c) wmApi:SetStrokeColor(c) end})
    reg(s4, "Slider", "wm.StrokeThickness", {Text="thickness", Min=0, Max=5,
        Default=wmApi:GetConfig().StrokeThickness,
        Callback=function(v) wmApi:SetStrokeThickness(v) end})
    reg(s4, "Slider", "wm.StrokeTransparency", {Text="transparency", Min=0, Max=1,
        Default=wmApi:GetConfig().StrokeTransparency,
        Callback=function(v) wmApi:SetStrokeTransparency(v) end})

    -- ❗ авто-подгонка высоты попапа под самую длинную колонку
    task.defer(function()
        if not popup or not popup.Parent then return end
        local cols = {s1.Frame, s2.Frame, s3.Frame, s4.Frame}
        local maxH = 0
        for _, c in ipairs(cols) do
            if c and c.Parent then
                local h = c.AbsoluteCanvasSize.Y
                if h > maxH then maxH = h end
            end
        end
        if maxH > 0 then
            local vp = gui.AbsoluteSize
            local targetH = math.min(maxH + startY + 20, vp.Y - 40)
            popup.Size = UDim2.new(0, PW, 0, targetH)
            for _, c in ipairs(cols) do
                if c and c.Parent then
                    c.Size = UDim2.new(0, colW, 0, targetH - startY - 10)
                end
            end
        end
    end)

    local openedAtRef = {value=0}
    local anchorRef = {instance=nil}
    return makeSettingsHandlers(popup, PW, PH, anchorRef, openedAtRef, gui)
end

local function buildWatermark()
    if PlayerGui:FindFirstChild("watermark") then PlayerGui.watermark:Destroy() end
    local ScreenGui = create("ScreenGui", {Name="watermark",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
        IgnoreGuiInset=true, DisplayOrder=850}, PlayerGui)
    local Frame = create("Frame", {Name="Main", BackgroundColor3=PALETTE.Panel,
        BackgroundTransparency=0, Active=true,
        Position=UDim2.new(0.61156,0,0.02713,0),
        AutomaticSize=Enum.AutomaticSize.X, Size=UDim2.new(0,0,0,30)}, ScreenGui)
    local wmCorner = corner(Frame, 5)
    local wmStroke = Instance.new("UIStroke")
    wmStroke.Color = Color3.fromRGB(255,255,255); wmStroke.Thickness = 0
    wmStroke.Transparency = 1; wmStroke.Parent = Frame
    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Horizontal
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Padding = UDim.new(0, 6); Layout.Parent = Frame
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0,8); Padding.PaddingRight = UDim.new(0,10)
    Padding.Parent = Frame

    local function makeLabel(name, text, order, bold)
        local label = Instance.new("TextLabel")
        label.Name = name; label.BackgroundTransparency = 1; label.BorderSizePixel = 0
        label.Font = bold and Enum.Font.ArialBold or Enum.Font.Arial
        label.TextColor3 = Color3.fromRGB(255,255,255); label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = text; label.LayoutOrder = order
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Size = UDim2.new(0,0,0,20); label.Parent = Frame
        return label
    end

    local ProductLogo = Instance.new("ImageLabel")
    ProductLogo.Name = "logo"; ProductLogo.BackgroundTransparency = 1
    ProductLogo.BorderSizePixel = 0; ProductLogo.Image = "rbxassetid://304489727"
    ProductLogo.Size = UDim2.new(0,22,0,22); ProductLogo.LayoutOrder = 1
    ProductLogo.ImageColor3 = Library.Settings.AccentColor
    ProductLogo.ImageTransparency = 0
    ProductLogo.Parent = Frame
    local ProductName = makeLabel("productname", "hysteria", 2, true)
    local function makeSep(order)
        local sep = makeLabel("sep", "|", order, false)
        sep.TextColor3 = Color3.fromRGB(120,120,120); return sep
    end
    local Sep1 = makeSep(3)
    local PlayerName = makeLabel("playername",
        tostring(KEYDATA.Username or LocalPlayer.Name), 4, false)
    local Sep2 = makeSep(5)
    local FpsCounter = makeLabel("fpscounter", "60fps", 6, false)
    local Sep3 = makeSep(7)
    local PingCounter = makeLabel("pingcounter", "0ms", 8, false)
    local Sep4 = makeSep(9)
    local TimeCounter = makeLabel("timecounter", "00:00:00", 10, false)
    local Sep5 = makeSep(11)
    local PlayersCounter = makeLabel("playerscounter", "1/"..Players.MaxPlayers, 12, false)
    local Sep6 = makeSep(13)
    local UptimeCounter = makeLabel("uptimecounter", "00:00:00", 14, false)
    local Sep7 = makeSep(15)
    local HealthCounter = makeLabel("healthcounter", "100hp", 16, false)
    local Sep8 = makeSep(17)
    local TargetCounter = makeLabel("targetcounter", "target: -", 18, false)
    local Sep9 = makeSep(19)
    local ExpiresCounter = makeLabel("expirescounter", "expires: "..tostring(KEYDATA.Expires), 20, false)
    local Sep10 = makeSep(21)
    local UidCounter = makeLabel("uidcounter", "UID: "..tostring(KEYDATA.UID), 22, false)

    local separators = {Sep1, Sep2, Sep3, Sep4, Sep5, Sep6, Sep7, Sep8, Sep9, Sep10}
    local dataLabels = {ProductName, PlayerName, FpsCounter, PingCounter, TimeCounter,
        PlayersCounter, UptimeCounter, HealthCounter, TargetCounter,
        ExpiresCounter, UidCounter}
    local fontTargets = {Sep1, PlayerName, Sep2, FpsCounter, Sep3, PingCounter, Sep4,
        TimeCounter, Sep5, PlayersCounter, Sep6, UptimeCounter, Sep7, HealthCounter,
        Sep8, TargetCounter, Sep9, ExpiresCounter, Sep10, UidCounter}

    local flagByLabelName = {
        productname = "GradProductName", playername = "GradPlayerName",
        fpscounter = "GradFPS", pingcounter = "GradPing",
        timecounter = "GradTime", playerscounter = "GradPlayers",
        uptimecounter = "GradUptime", healthcounter = "GradHealth",
        targetcounter = "GradTarget",
    }
    local gradientTargets = {}
    for _, lbl in ipairs(dataLabels) do
        local g = Instance.new("UIGradient")
        g.Name = "WmGrad"; g.Enabled = false; g.Parent = lbl
        table.insert(gradientTargets, g)
    end

    local config = {Enabled=true, ShowName=true, ShowFPS=true, ShowPing=true, ShowTime=true,
        ShowPlayers=true, ShowUptime=false, ShowHealth=false, ShowTarget=false,
        ShowExpires=true, ShowUID=true,
        ShowSeparators=true, Gradient=false,
        GradProductName=true, GradPlayerName=true, GradFPS=true, GradPing=true,
        GradTime=true, GradPlayers=true, GradUptime=true, GradHealth=true, GradTarget=true,
        ColorA=Library.Settings.AccentColor, ColorB=Color3.new(1,1,1),
        Speed=1, Style="flow",
        CustomName=false, CustomNameText=KEYDATA.Username or "primo user", Font="arial",
        BgColor=Color3.fromRGB(20,20,20), BgTransparency=0, CornerRadius=5,
        LogoAccent=true, LogoColor=Library.Settings.AccentColor, LogoTransparency=0,
        LogoImage="rbxassetid://304489727",
        StrokeColor=Color3.fromRGB(255,255,255), StrokeThickness=0, StrokeTransparency=1,
        CheatNamePreset="classic",
        -- ❗ новые поля (больше кастомизации)
        TextSize=14, LogoSize=22, Gap=6,
        PaddingLeft=8, PaddingRight=10}

    local CHEAT_NAME_MAP = {
        classic = "hysteria",
        ["true"] = "ХЫСТЭРЫЯ ЧЫТ",
        kawaii  = "hysteria >w<",
        legacy  = "primo",
        kaomoji = "hysteria (●'◡'●)",
    }
    local function applyCheatName()
        ProductName.Text = CHEAT_NAME_MAP[config.CheatNamePreset or "classic"] or "hysteria"
    end
    applyCheatName()

    local function applyVisibility()
        Frame.Visible = config.Enabled
        Sep1.Visible = config.ShowName and config.ShowSeparators;     PlayerName.Visible = config.ShowName
        Sep2.Visible = config.ShowFPS and config.ShowSeparators;      FpsCounter.Visible = config.ShowFPS
        Sep3.Visible = config.ShowPing and config.ShowSeparators;     PingCounter.Visible = config.ShowPing
        Sep4.Visible = config.ShowTime and config.ShowSeparators;     TimeCounter.Visible = config.ShowTime
        Sep5.Visible = config.ShowPlayers and config.ShowSeparators;  PlayersCounter.Visible = config.ShowPlayers
        Sep6.Visible = config.ShowUptime and config.ShowSeparators;   UptimeCounter.Visible = config.ShowUptime
        Sep7.Visible = config.ShowHealth and config.ShowSeparators;   HealthCounter.Visible = config.ShowHealth
        Sep8.Visible = config.ShowTarget and config.ShowSeparators;   TargetCounter.Visible = config.ShowTarget
        Sep9.Visible = config.ShowExpires and config.ShowSeparators;  ExpiresCounter.Visible = config.ShowExpires
        Sep10.Visible = config.ShowUID and config.ShowSeparators;     UidCounter.Visible = config.ShowUID
    end
local function applyFont()
    local f = getFontByName(config.Font)
    for _, lbl in ipairs(fontTargets) do lbl.FontFace = f end
end
    local function applyGradient()
        for i, g in ipairs(gradientTargets) do
            local flag = flagByLabelName[dataLabels[i].Name]
            local on = config.Gradient and flag and config[flag]
            g.Enabled = on and true or false
            if on then
                g.Offset = Vector2.new(0, 0)
                g.Rotation = (config.Style == "sweep") and 45 or 0
                g.Color = resolveSeq(config.ColorA, config.ColorB)
            end
        end
    end

    -- ❗ новые appliers
    local function applyTextSize()
        local sz = config.TextSize or 14
        for _, obj in ipairs(Frame:GetChildren()) do
            if obj:IsA("TextLabel") then
                pcall(function() obj.TextSize = sz end)
            end
        end
    end
    local function applyLogoSize()
        local sz = config.LogoSize or 22
        ProductLogo.Size = UDim2.new(0, sz, 0, sz)
    end
    local function applyLayout()
        pcall(function() Layout.Padding = UDim.new(0, config.Gap or 6) end)
        pcall(function() Padding.PaddingLeft  = UDim.new(0, config.PaddingLeft or 8) end)
        pcall(function() Padding.PaddingRight = UDim.new(0, config.PaddingRight or 10) end)
    end
    applyVisibility(); applyFont(); applyGradient()
    applyTextSize(); applyLogoSize(); applyLayout()
    local frameCount = 0
    local lastTime = tick()
    local fpsConn = RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = tick()
        if now - lastTime >= 1 then
            pcall(function()
                if FpsCounter and FpsCounter.Parent then
                    FpsCounter.Text = tostring(frameCount) .. "fps"
                end
            end)
            frameCount = 0; lastTime = now
        end
    end)
    local pingThread = task.spawn(function()
        while true do
            task.wait(1)
            if not PingCounter or not PingCounter.Parent then break end
            pcall(function()
                local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                if ping and PingCounter and PingCounter.Parent then
                    PingCounter.Text = tostring(ping) .. "ms"
                end
            end)
        end
    end)
    local sessionStart = tick()
     local timeThread = task.spawn(function()
        while true do
            task.wait(1)
            if not TimeCounter or not TimeCounter.Parent then break end
            pcall(function()
                if not TimeCounter or not TimeCounter.Parent then return end
                local t = os.date("*t")
                TimeCounter.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
                PlayersCounter.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
                local elapsed = math.floor(tick() - sessionStart)
                UptimeCounter.Text = string.format("%02d:%02d:%02d",
                    math.floor(elapsed/3600), math.floor(elapsed%3600/60), elapsed%60)
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then HealthCounter.Text = math.floor(hum.Health) .. "hp"
                else HealthCounter.Text = "-" end
            end)
        end
    end)
    local function applyName()
        if config.CustomName and config.CustomNameText ~= "" then
            PlayerName.Text = config.CustomNameText
        else
            PlayerName.Text = KEYDATA.Username or LocalPlayer.Name
        end
    end
    applyName()
    -- nameConn больше не нужен: applyName не зависит от персонажа.
    -- оставляем переменную, чтобы api:Destroy не упал на nil:Disconnect()
    local nameConn = { Disconnect = function() end }
    local phase = 0
    local animConn = RunService.Heartbeat:Connect(function(dt)
        if not config.Gradient then return end
        local enabledGrads = {}
        for _, g in ipairs(gradientTargets) do
            if g.Enabled then table.insert(enabledGrads, g) end
        end
        if #enabledGrads == 0 then return end
        local style = config.Style; local speed = config.Speed
        if style == "sweep" then
            phase = (phase + dt*speed*60) % 360
            for _, g in ipairs(enabledGrads) do g.Rotation = phase end
        elseif style == "pulse" then
            phase = (phase + dt*speed*0.4) % 1
            local k = (math.sin(phase*math.pi*2)+1)*0.5
            local seq = resolvePulseSeq(config.ColorA, config.ColorB, k)
            for _, g in ipairs(enabledGrads) do g.Color = seq end
        elseif style == "wave" then
            phase = (phase + dt*speed*0.15) % 1
            local o = math.sin(phase*math.pi*2)*0.5
            for _, g in ipairs(enabledGrads) do
                g.Rotation = 0
                g.Offset = Vector2.new(0, o)
            end
        else -- flow
            phase = (phase + dt*speed*0.15) % 1
            local o = math.sin(phase*math.pi*2)*0.5
            for _, g in ipairs(enabledGrads) do g.Offset = Vector2.new(o, 0) end
        end
    end)
    registerAccent(function() if config.Gradient then applyGradient() end end)

    local dragging, dragStart, startPos = false, nil, nil
    Frame.InputBegan:Connect(function(input)
        if config.LockDrag then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Frame.Position
        end
    end)
    local teDragChanged = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
            Frame.Position = newPos
            _G.__HYSTERIA_WM_POS = newPos
        end
    end)
    local teDragEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local api = {}
        function api:SetCheatNamePreset(p)
        config.CheatNamePreset = p or "classic"
        applyCheatName()
    end
    function api:GetCheatNamePreset() return config.CheatNamePreset or "classic" end
    function api:GetConfig() return config end
    function api:GetPosition() return Frame.Position end
    function api:SetPosition(pos)
        if typeof(pos) == "UDim2" then
            Frame.Position = pos
            _G.__HYSTERIA_WM_POS = pos
        end
    end
    function api:SetEnabled(v)          config.Enabled = v and true or false;        applyVisibility() end
    function api:SetShowName(v)         config.ShowName = v and true or false;       applyVisibility() end
    function api:SetShowFPS(v)          config.ShowFPS = v and true or false;        applyVisibility() end
    function api:SetShowPing(v)         config.ShowPing = v and true or false;       applyVisibility() end
    function api:SetShowTime(v)         config.ShowTime = v and true or false;       applyVisibility() end
    function api:SetShowPlayers(v)      config.ShowPlayers = v and true or false;    applyVisibility() end
    function api:SetShowUptime(v)       config.ShowUptime = v and true or false;     applyVisibility() end
    function api:SetShowHealth(v)       config.ShowHealth = v and true or false;     applyVisibility() end
    function api:SetShowTarget(v)       config.ShowTarget = v and true or false;     applyVisibility() end
    function api:SetShowExpires(v)      config.ShowExpires = v and true or false;    applyVisibility() end
    function api:SetShowUID(v)          config.ShowUID = v and true or false;        applyVisibility() end
    function api:SetShowSeparators(v)   config.ShowSeparators = v and true or false; applyVisibility() end
    function api:SetGradient(v)         config.Gradient = v and true or false;       applyGradient()   end
    function api:SetGradProductName(v)  config.GradProductName = v and true or false; applyGradient() end
    function api:SetGradPlayerName(v)   config.GradPlayerName = v and true or false;  applyGradient() end
    function api:SetGradFPS(v)          config.GradFPS = v and true or false;         applyGradient() end
    function api:SetGradPing(v)         config.GradPing = v and true or false;        applyGradient() end
    function api:SetGradTime(v)         config.GradTime = v and true or false;        applyGradient() end
    function api:SetGradPlayers(v)      config.GradPlayers = v and true or false;     applyGradient() end
    function api:SetGradUptime(v)       config.GradUptime = v and true or false;      applyGradient() end
    function api:SetGradHealth(v)       config.GradHealth = v and true or false;      applyGradient() end
    function api:SetGradTarget(v)       config.GradTarget = v and true or false;      applyGradient() end
    function api:SetColorA(c)           config.ColorA = c; applyGradient() end
    function api:SetColorB(c)           config.ColorB = c; applyGradient() end
    function api:SetSpeed(v)            config.Speed = v end
    function api:SetStyle(v)            config.Style = v; applyGradient() end
    function api:SetCustomName(v)       config.CustomName = v and true or false; applyName() end
    function api:SetCustomNameText(t)   config.CustomNameText = t or ""; applyName() end
    function api:SetFont(n)             config.Font = n; applyFont() end
    function api:SetTargetText(t)       TargetCounter.Text = "target: " .. tostring(t or "-") end
    function api:SetUsername(n)
        KEYDATA.Username = tostring(n or KEYDATA.Username)
        PlayerName.Text = KEYDATA.Username
        config.CustomNameText = KEYDATA.Username
    end
    function api:SetExpires(n)
        KEYDATA.Expires = tostring(n or KEYDATA.Expires)
        ExpiresCounter.Text = "expires: " .. KEYDATA.Expires
    end
    function api:SetUID(n)
        KEYDATA.UID = tostring(n or KEYDATA.UID)
        UidCounter.Text = "UID: " .. KEYDATA.UID
    end
    function api:SetBgColor(c) config.BgColor = c; Frame.BackgroundColor3 = c end
    function api:SetLogoAccent(v)
        config.LogoAccent = v and true or false
        if config.LogoAccent then
            ProductLogo.ImageColor3 = Library.Settings.AccentColor
        else
            ProductLogo.ImageColor3 = config.LogoColor
        end
    end
    function api:SetLogoColor(c)
        config.LogoColor = c
        if not config.LogoAccent then ProductLogo.ImageColor3 = c end
    end
    function api:SetLogoTransparency(t)
        config.LogoTransparency = math.clamp(t,0,1)
        ProductLogo.ImageTransparency = config.LogoTransparency
    end
        function api:SetLogoImage(url)
        if type(url) ~= "string" or url == "" then return end
        if url:match("^%d+$") then url = "rbxassetid://" .. url end
        config.LogoImage = url
        if ProductLogo and ProductLogo.Parent then
            pcall(function() ProductLogo.Image = url end)
        end
    end
    function api:SetBgTransparency(t)
        config.BgTransparency = math.clamp(t,0,1)
        Frame.BackgroundTransparency = config.BgTransparency
    end
    function api:SetCornerRadius(r)
        config.CornerRadius = math.max(0, r)
        wmCorner.CornerRadius = UDim.new(0, config.CornerRadius)
    end
    function api:SetStrokeColor(c) config.StrokeColor = c; wmStroke.Color = c end
    function api:SetStrokeThickness(n)
        config.StrokeThickness = math.max(0, n); wmStroke.Thickness = config.StrokeThickness
    end
    function api:SetStrokeTransparency(t)
        config.StrokeTransparency = math.clamp(t,0,1); wmStroke.Transparency = config.StrokeTransparency
    end
    function api:IsVisible() return Frame.Visible end
    function api:GetFrame() return Frame end
    function api:SetScale(s)
        s = math.clamp(tonumber(s) or 1, 0.5, 3.0)
        local us = Frame:FindFirstChildOfClass("UIScale")
        if not us then
            us = Instance.new("UIScale"); us.Parent = Frame
        end
        us.Scale = s
        Library.Settings.HUDScale = Library.Settings.HUDScale or {}
        Library.Settings.HUDScale.watermark = s
    end
    function api:GetScale()
        local us = Frame:FindFirstChildOfClass("UIScale")
        return us and us.Scale or 1
    end
    local settingsPopup = buildWatermarkSettingsPopup(api)
    if _G.__HYSTERIA_WM_POS then
        Frame.Position = _G.__HYSTERIA_WM_POS
    end
    function api:Destroy()
        pcall(function() fpsConn:Disconnect() end)
        pcall(function() animConn:Disconnect() end)
        pcall(function() nameConn:Disconnect() end)
        pcall(function() teDragChanged:Disconnect() end)
        pcall(function() teDragEnded:Disconnect() end)
        pcall(function() task.cancel(pingThread) end)
        pcall(function() task.cancel(timeThread) end)
        pcall(function() settingsPopup:Destroy() end)
        pcall(function() ScreenGui:Destroy() end)
    end
    function api:ToggleSettings(a) settingsPopup:Toggle(a) end
    function api:CloseSettings() settingsPopup:Close() end
    function api:IsSettingsOpen() return settingsPopup:IsOpen() end
    return api
end

local function buildKeybindsSettingsPopup(kbApi)
    local PW, PH = 720, 680
    local popup, gui = makePopupFrame("keybinds_settings", "- keybinds settings -", PW, PH)
    local colW, colGap, startX, startY = 170, 5, 5, 30
    local colH = PH - startY - 10
    local function makeCol(idx)
        return create("Frame", {Name="col"..idx, BackgroundTransparency=1,
            Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
            Size=UDim2.new(0,colW,0,colH)}, popup)
    end
    local s1 = setmetatable({Frame=makeCol(1), Y=0}, Section)
    local s2 = setmetatable({Frame=makeCol(2), Y=0}, Section)
    local s3 = setmetatable({Frame=makeCol(3), Y=0}, Section)
    local s4 = setmetatable({Frame=makeCol(4), Y=0}, Section)
    local cfg = kbApi:GetConfig()

    s1:Label("gradient:")
    reg(s1, "Toggle", "kb.Gradient", {Text="enabled", Default=cfg.Gradient, Callback=function(v) kbApi:SetGradient(v) end})
    reg(s1, "Toggle", "kb.Blink", {Text="blink", Default=cfg.Blink, Callback=function(v) kbApi:SetBlink(v) end})
    s1:Label("gradient on:")
    reg(s1, "Toggle", "kb.GradientTitle", {Text="title", Default=cfg.GradientTitle, Callback=function(v) kbApi:SetGradientTitle(v) end})
    reg(s1, "Toggle", "kb.GradientLabel", {Text="labels", Default=cfg.GradientLabel, Callback=function(v) kbApi:SetGradientLabel(v) end})
    reg(s1, "Toggle", "kb.GradientKey", {Text="keybinds", Default=cfg.GradientKey, Callback=function(v) kbApi:SetGradientKey(v) end})

    s2:Label("colors:")
    reg(s2, "ColorPicker", "kb.ColorA", {Text="color a",
        GetInitialColor=function() return kbApi:GetConfig().ColorA end,
        Callback=function(c) kbApi:SetColorA(c) end})
    reg(s2, "ColorPicker", "kb.ColorB", {Text="color b",
        GetInitialColor=function() return kbApi:GetConfig().ColorB end,
        Callback=function(c) kbApi:SetColorB(c) end})
    s2:Divider()
    s2:Label("animation style:")
    reg(s2, "StylePicker", "kb.Style", {Text="style", Default=cfg.Style, Callback=function(v) kbApi:SetStyle(v) end})
    reg(s2, "Slider", "kb.Speed", {Text="speed", Min=0, Max=3, Default=cfg.Speed, Callback=function(v) kbApi:SetSpeed(v) end})

    local initialFontIdx = 1
    for i, n in ipairs(FONT_NAMES) do if n == cfg.Font then initialFontIdx = i break end end
    s3:Label("font:")
    reg(s3, "Cycle", "kb.Font", {Prefix="", Values=FONT_NAMES, Index=initialFontIdx,
        Callback=function(v) kbApi:SetFont(v) end})

    s3:Divider()
    s3:Label("transform:")
    reg(s3, "Slider", "kb.scale", {Text="scale",
        Min=0.5, Max=3, Default=1,
        Callback=function(v)
            if kbApi and kbApi.SetScale then kbApi:SetScale(v) end
        end})
    reg(s3, "Toggle", "kb.LockDrag", {Text="lock position", Default=false,
        Callback=function(v) kbApi:GetConfig().LockDrag = v end})

    s4:Label("background:")
    reg(s4, "ColorPicker", "kb.BgColor", {Text="bg color",
        GetInitialColor=function() return kbApi:GetConfig().BgColor end,
        Callback=function(c) kbApi:SetBgColor(c) end})
    reg(s4, "Slider", "kb.BgTransparency", {Text="bg transparency", Min=0, Max=1,
        Default=kbApi:GetConfig().BgTransparency,
        Callback=function(v) kbApi:SetBgTransparency(v) end})
    reg(s4, "Slider", "kb.GlassTransparency", {Text="glass transparency", Min=0, Max=1,
        Default=kbApi:GetConfig().GlassTransparency,
        Callback=function(v) kbApi:SetGlassTransparency(v) end})
    reg(s4, "Slider", "kb.CornerRadius", {Text="corner radius", Min=0, Max=20,
        Default=kbApi:GetConfig().CornerRadius,
        Callback=function(v) kbApi:SetCornerRadius(v) end})
    s4:Divider()
    s4:Label("stroke:")
    reg(s4, "ColorPicker", "kb.StrokeColor", {Text="stroke color",
        GetInitialColor=function() return kbApi:GetConfig().StrokeColor end,
        Callback=function(c) kbApi:SetStrokeColor(c) end})
    reg(s4, "Slider", "kb.StrokeThickness", {Text="thickness", Min=0, Max=5,
        Default=kbApi:GetConfig().StrokeThickness,
        Callback=function(v) kbApi:SetStrokeThickness(v) end})
    reg(s4, "Slider", "kb.StrokeTransparency", {Text="transparency", Min=0, Max=1,
        Default=kbApi:GetConfig().StrokeTransparency,
        Callback=function(v) kbApi:SetStrokeTransparency(v) end})

    local openedAtRef = {value=0}
    local anchorRef = {instance=nil}
    return makeSettingsHandlers(popup, PW, PH, anchorRef, openedAtRef, gui)
end

local function buildKeybindsList()
    if PlayerGui:FindFirstChild("keybinds") then PlayerGui.keybinds:Destroy() end
    local ScreenGui = create("ScreenGui", {Name="keybinds",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
        IgnoreGuiInset=true, DisplayOrder=850}, PlayerGui)
    local Frame = create("Frame", {Name="Main", BackgroundColor3=PALETTE.Panel,
        BackgroundTransparency=0, Active=true,
        Position=UDim2.new(0.61156,0,0.02713,40), Size=UDim2.new(0,220,0,30),
        AutomaticSize=Enum.AutomaticSize.Y}, ScreenGui)
    local kbCorner = corner(Frame, 8)
    local kbGlass = addGlass(Frame, 0.15, PALETTE.PanelGlass)
    local kbStroke = Instance.new("UIStroke")
    kbStroke.Color = Color3.fromRGB(255,255,255); kbStroke.Thickness = 0
    kbStroke.Transparency = 1; kbStroke.Parent = Frame
    local header = create("Frame", {Name="header", BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,28)}, Frame)
    local icon = create("ImageLabel", {Name="kbindicator", BackgroundTransparency=1,
        Image="rbxassetid://80904592327311", ImageColor3=Library.Settings.AccentColor,
        Size=UDim2.new(0,14,0,14), Position=UDim2.new(0.5,-7,0.5,-7)}, header)
    registerAccent(function() tween(icon, {ImageColor3=Library.Settings.AccentColor}) end)
    local title = create("TextLabel", {Name="title", BackgroundTransparency=1,
        Text="- keybinds -", TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,1,0)}, header)
    local divider = create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
        BackgroundTransparency=0.8, Size=UDim2.new(1,-16,0,1),
        Position=UDim2.new(0,8,0,27)}, Frame)
    local listHolder = create("Frame", {Name="list", BackgroundTransparency=1,
        Position=UDim2.new(0,0,0,29), Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y}, Frame)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,3); layout.Parent = listHolder
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0,4); padding.PaddingBottom = UDim.new(0,6)
    padding.PaddingLeft = UDim.new(0,8); padding.PaddingRight = UDim.new(0,8)
    padding.Parent = listHolder

    local binds = {}
    local listeningBind = nil
    local api = {Enabled=true, Collapsed=false}
    local config = {Enabled=true, Collapsed=false, LockDrag=false, Gradient=false, Blink=true,
        GradientTitle=true, GradientLabel=true, GradientKey=true,
        ColorA=Library.Settings.AccentColor, ColorB=Color3.new(1,1,1),
        Speed=1, Style="flow", Font="arial",
        BgColor=PALETTE.Panel, BgTransparency=0, GlassTransparency=0.15,
        CornerRadius=8, StrokeColor=Color3.fromRGB(255,255,255),
        StrokeThickness=0, StrokeTransparency=1}

    local function styleGradient(g)
        g.Offset = Vector2.new(0, 0)
        g.Rotation = (config.Style == "sweep") and 45 or 0
        g.Color = resolveSeq(config.ColorA, config.ColorB)
    end
    local function ensureGradient(lbl, enabled)
        local g = lbl:FindFirstChildOfClass("UIGradient")
        if not g then g = Instance.new("UIGradient"); g.Parent = lbl end
        g.Enabled = enabled
        if enabled then styleGradient(g) end
    end
    local function applyFont()
        local f = getFontByName(config.Font)
        title.FontFace = f
        for _, b in ipairs(binds) do
            if b.Label then b.Label.FontFace = f end
            if b.KeyLabel then b.KeyLabel.FontFace = f end
        end
    end
    local function applyGradient()
        ensureGradient(title, config.Gradient and config.GradientTitle)
        for _, b in ipairs(binds) do
            if b.Label then ensureGradient(b.Label, config.Gradient and config.GradientLabel) end
            if b.KeyLabel then ensureGradient(b.KeyLabel, config.Gradient and config.GradientKey) end
        end
    end
    local function animTargets()
        local list = {}
        if config.GradientTitle then table.insert(list, {label=title}) end
        if config.GradientLabel then
            for _, b in ipairs(binds) do if b.Label then table.insert(list, {label=b.Label}) end end
        end
        if config.GradientKey then
            for _, b in ipairs(binds) do if b.KeyLabel then table.insert(list, {label=b.KeyLabel}) end end
        end
        return list
    end
    local function refreshOrders() for i, b in ipairs(binds) do b.Frame.LayoutOrder = i end end
    local function refreshKeyVisuals()
        for _, b in ipairs(binds) do
            if b.applyKeyVisual then
                local txt = (listeningBind == b) and "press..."
                    or (b.Key and b.Key.Name or "none")
                if b.KeyLabel and b.KeyLabel.Text ~= txt then
                    b.applyKeyVisual()
                end
            end
        end
    end

    local function createBind(spec)
        local row = create("Frame", {Name="bind", BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,18)}, listHolder)
        local label = create("TextLabel", {Name="label", BackgroundTransparency=1,
            Text=spec.Name or "bind", TextSize=13, TextColor3=PALETTE.Text,
            FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-60,1,0)}, row)
        local keyBtn = create("TextButton", {Name="key", AutoButtonColor=false,
            Text=spec.Key and spec.Key.Name or "none", TextSize=13,
            TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
            BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right,
            Size=UDim2.new(0,56,1,0), Position=UDim2.new(1,-56,0,0)}, row)
        local bind = {Name=spec.Name or "bind", Key=spec.Key, Callback=spec.Callback,
            Frame=row, Label=label, KeyLabel=keyBtn, Connection=nil}
        local function applyKeyVisual()
            if listeningBind == bind then
                keyBtn.Text = "press..."
                keyBtn.TextColor3 = Library.Settings.AccentColor
            else
                keyBtn.Text = bind.Key and bind.Key.Name or "none"
                keyBtn.TextColor3 = PALETTE.TextDim
            end
        end
        bind.applyKeyVisual = applyKeyVisual
        function bind:SetKey(key) self.Key = key; applyKeyVisual() end
        function bind:SetName(name) self.Name = name; self.Label.Text = name end
        function bind:Remove()
            for i, b in ipairs(binds) do if b == self then table.remove(binds, i); break end end
            if self.Connection then self.Connection:Disconnect() end
            if self.Frame then self.Frame:Destroy() end
            refreshOrders(); applyFont(); applyGradient()
        end
        keyBtn.MouseButton1Click:Connect(function()
            listeningBind = (listeningBind == bind) and nil or bind
            refreshKeyVisuals()
        end)
        bind.Connection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if listeningBind then return end
            if not bind.Key then return end
            if typeof(bind.Key) ~= "EnumItem" then return end
            local matches = false
            if bind.Key.EnumType == Enum.KeyCode then matches = (input.KeyCode == bind.Key)
            elseif bind.Key.EnumType == Enum.UserInputType then matches = (input.UserInputType == bind.Key) end
            if matches then if bind.Callback then task.spawn(bind.Callback) end end
        end)
        table.insert(binds, bind)
        refreshOrders(); applyKeyVisual(); applyFont(); applyGradient()
        return bind
    end
    function api:AddBind(spec) return createBind(spec or {}) end
    function api:_findByName(n) for _, b in ipairs(binds) do if b.Name == n then return b end end end
    function api:RemoveBind(bind) if bind then bind:Remove() end end
    function api:ClearBinds()
        for _, b in ipairs(binds) do
            if b.Connection then b.Connection:Disconnect() end
            if b.Frame then b.Frame:Destroy() end
        end
        binds = {}
    end
    function api:GetBinds() return binds end
    function api:SetEnabled(v) api.Enabled = v and true or false; ScreenGui.Enabled = api.Enabled end
    function api:Toggle() api:SetEnabled(not api.Enabled) end
    function api:IsEnabled() return api.Enabled end
    function api:SetCollapsed(v)
        api.Collapsed = v and true or false
        config.Collapsed = api.Collapsed
        listHolder.Visible = not api.Collapsed
        divider.Visible = not api.Collapsed
    end
    local kbListenConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if UserInputService:GetFocusedTextBox() then return end
        if not listeningBind then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local target = listeningBind
        listeningBind = nil
        if input.KeyCode ~= Enum.KeyCode.Escape then target:SetKey(input.KeyCode) end
        refreshKeyVisuals()
    end)
    registerAccent(function() refreshKeyVisuals(); applyGradient() end)

    local blinkPhase, gradientPhase = 0, 0
    local _wasBlinkOn = false
    local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not api.Enabled then return end
        -- early out: ничего не крутится
        if not config.Blink and not config.Gradient then return end
        if config.Blink then
            _wasBlinkOn = true
            blinkPhase = (blinkPhase + dt*config.Speed*0.6) % 1
            local t = (math.sin(blinkPhase*math.pi*2)+1)*0.5
            local base = Library.Settings.AccentColor
            local pulsed = base:Lerp(base:Lerp(Color3.new(1,1,1), 0.7), t)
            for _, b in ipairs(binds) do
                if b.Label then b.Label.TextColor3 = pulsed end
                if listeningBind == b then b.KeyLabel.TextColor3 = Library.Settings.AccentColor end
            end
        elseif _wasBlinkOn then
            -- одноразовый сброс цветов после отключения blink
            _wasBlinkOn = false
            for _, b in ipairs(binds) do
                if b.Label then b.Label.TextColor3 = PALETTE.Text end
                if listeningBind == b then b.KeyLabel.TextColor3 = Library.Settings.AccentColor end
            end
        end
        if config.Gradient then
            local speed = config.Speed
            if config.Style == "sweep" then
                gradientPhase = (gradientPhase + dt*speed*60) % 360
                for _, e in ipairs(animTargets()) do
                    local g = e.label:FindFirstChildOfClass("UIGradient")
                    if g then g.Rotation = gradientPhase end
                end
            elseif config.Style == "pulse" then
                gradientPhase = (gradientPhase + dt*speed*0.4) % 1
                local k = (math.sin(gradientPhase*math.pi*2)+1)*0.5
                local seq = resolvePulseSeq(config.ColorA, config.ColorB, k)
                for _, e in ipairs(animTargets()) do
                    local g = e.label:FindFirstChildOfClass("UIGradient")
                    if g then g.Color = seq end
                end
            elseif config.Style == "wave" then
                gradientPhase = (gradientPhase + dt*speed*0.15) % 1
                local o = math.sin(gradientPhase*math.pi*2)*0.5
                for _, e in ipairs(animTargets()) do
                    local g = e.label:FindFirstChildOfClass("UIGradient")
                    if g then g.Rotation = 0; g.Offset = Vector2.new(0, o) end
                end
            else -- flow
                gradientPhase = (gradientPhase + dt*speed*0.15) % 1
                local o = math.sin(gradientPhase*math.pi*2)*0.5
                for _, e in ipairs(animTargets()) do
                    local g = e.label:FindFirstChildOfClass("UIGradient")
                    if g then g.Offset = Vector2.new(o, 0) end
                end
            end
        end
    end)
    applyFont(); applyGradient()

    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(input)
        if config.LockDrag then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = input.Position; startPos = Frame.Position
    end)
    local kbDragChanged = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
            startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end)
    local kbDragEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    function api:GetConfig() return config end
    function api:GetPosition() return Frame.Position end
    function api:SetPosition(pos)
        if typeof(pos) == "UDim2" then
            Frame.Position = pos
            _G.__HYSTERIA_KB_POS = pos
        end
    end
    function api:SetGradient(v)        config.Gradient = v and true or false;        applyGradient() end
    function api:SetBlink(v)           config.Blink = v and true or false end
    function api:SetGradientTitle(v)   config.GradientTitle = v and true or false;   applyGradient() end
    function api:SetGradientLabel(v)   config.GradientLabel = v and true or false;   applyGradient() end
    function api:SetGradientKey(v)     config.GradientKey = v and true or false;     applyGradient() end
    function api:SetColorA(c)          config.ColorA = c; applyGradient() end
    function api:SetColorB(c)          config.ColorB = c; applyGradient() end
    function api:SetSpeed(v)           config.Speed = v end
    function api:SetStyle(v)           config.Style = v; applyGradient() end
    function api:SetFont(n)            config.Font = n; applyFont() end
    function api:SetBgColor(c)         config.BgColor = c; Frame.BackgroundColor3 = c end
    function api:SetBgTransparency(t)
        config.BgTransparency = math.clamp(t,0,1)
        Frame.BackgroundTransparency = config.BgTransparency
    end
    function api:SetGlassTransparency(t)
        config.GlassTransparency = math.clamp(t,0,1); kbGlass.BackgroundTransparency = config.GlassTransparency
    end
    function api:SetCornerRadius(r)
        config.CornerRadius = math.max(0,r); kbCorner.CornerRadius = UDim.new(0, config.CornerRadius)
    end
    function api:SetStrokeColor(c) config.StrokeColor = c; kbStroke.Color = c end
    function api:SetStrokeThickness(n)
        config.StrokeThickness = math.max(0,n); kbStroke.Thickness = config.StrokeThickness
    end
    function api:SetStrokeTransparency(t)
        config.StrokeTransparency = math.clamp(t,0,1); kbStroke.Transparency = config.StrokeTransparency
    end
    function api:GetFrame() return Frame end
    function api:SetScale(s)
        s = math.clamp(tonumber(s) or 1, 0.5, 3.0)
        local us = Frame:FindFirstChildOfClass("UIScale")
        if not us then
            us = Instance.new("UIScale"); us.Parent = Frame
        end
        us.Scale = s
        Library.Settings.HUDScale = Library.Settings.HUDScale or {}
        Library.Settings.HUDScale.keybinds = s
    end
    function api:GetScale()
        local us = Frame:FindFirstChildOfClass("UIScale")
        return us and us.Scale or 1
    end
    local settingsPopup = buildKeybindsSettingsPopup(api)
    if _G.__HYSTERIA_KB_POS then
        Frame.Position = _G.__HYSTERIA_KB_POS
    end
    function api:Destroy()
        pcall(function() heartbeatConn:Disconnect() end)
        pcall(function() kbDragChanged:Disconnect() end)
        pcall(function() kbDragEnded:Disconnect() end)
        pcall(function() kbListenConn:Disconnect() end)
        listeningBind = nil
        _G.__PRIMO_BIND_LISTENING = false
        pcall(function() settingsPopup:Destroy() end)
        pcall(function() ScreenGui:Destroy() end)
    end
    function api:ToggleSettings(a) settingsPopup:Toggle(a) end
    function api:CloseSettings() settingsPopup:Close() end
    function api:IsSettingsOpen() return settingsPopup:IsOpen() end
    api._openSettings = function(anchor)
        if anchor then settingsPopup:Toggle(anchor) else settingsPopup:Open() end
    end
    return api
end

local function buildTargetESPSettingsPopup(teApi)
    local PW, PH = 720, 680
    local popup, gui = makePopupFrame("targetesp_settings", "- target esp settings -", PW, PH)
    local colW, colGap, startX, startY = 170, 5, 5, 30
    local colH = PH - startY - 10
    local function makeCol(idx)
        return create("Frame", {Name="col"..idx, BackgroundTransparency=1,
            Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
            Size=UDim2.new(0,colW,0,colH)}, popup)
    end
    local s1 = setmetatable({Frame=makeCol(1), Y=0}, Section)
    local s2 = setmetatable({Frame=makeCol(2), Y=0}, Section)
    local s3 = setmetatable({Frame=makeCol(3), Y=0}, Section)
    local s4 = setmetatable({Frame=makeCol(4), Y=0}, Section)
    local cfg = teApi:GetConfig()

    s1:Label("effects:")
    reg(s1, "Toggle", "te.Gradient", {Text="gradient", Default=cfg.Gradient, Callback=function(v) teApi:SetGradient(v) end})
    reg(s1, "Toggle", "te.Blink", {Text="blink", Default=cfg.Blink, Callback=function(v) teApi:SetBlink(v) end})
    s1:Label("target:")
    reg(s1, "Toggle", "te.ShowDistance", {Text="show distance", Default=cfg.ShowDistance, Callback=function(v) teApi:SetShowDistance(v) end})
    reg(s1, "Toggle", "te.AutoTarget", {Text="auto nearest", Default=cfg.AutoTarget, Callback=function(v) teApi:SetAutoTarget(v) end})
    reg(s1, "Toggle", "te.ShowOnlyWhenEnemies", {Text="show only when enemies", Default=cfg.ShowOnlyWhenEnemies,
        Callback=function(v) teApi:SetShowOnlyWhenEnemies(v) end})

    s2:Label("colors:")
    reg(s2, "ColorPicker", "te.AccentColor", {Text="accent color",
        GetInitialColor=function() return teApi:GetConfig().AccentColor end,
        Callback=function(c) teApi:SetAccentColor(c) end})
    reg(s2, "ColorPicker", "te.ColorA", {Text="color a",
        GetInitialColor=function() return teApi:GetConfig().ColorA end,
        Callback=function(c) teApi:SetColorA(c) end})
    reg(s2, "ColorPicker", "te.ColorB", {Text="color b",
        GetInitialColor=function() return teApi:GetConfig().ColorB end,
        Callback=function(c) teApi:SetColorB(c) end})
    s2:Divider()
    s2:Label("animation style:")
    reg(s2, "StylePicker", "te.Style", {Text="style", Default=cfg.Style, Callback=function(v) teApi:SetStyle(v) end})
    reg(s2, "Slider", "te.Speed", {Text="speed", Min=0, Max=3, Default=cfg.Speed, Callback=function(v) teApi:SetSpeed(v) end})

    s3:Label("gradient on (per element):")
    reg(s3, "Toggle", "te.GradName", {Text="name", Default=cfg.GradName, Callback=function(v) teApi:SetGradName(v) end})
    reg(s3, "Toggle", "te.GradDisplay", {Text="@username", Default=cfg.GradDisplay, Callback=function(v) teApi:SetGradDisplay(v) end})
    reg(s3, "Toggle", "te.GradHealth", {Text="health", Default=cfg.GradHealth, Callback=function(v) teApi:SetGradHealth(v) end})
    s3:Divider()
    s3:Label("spoofer:")
    reg(s3, "Toggle", "te.Spoofer", {Text="spoofer", Default=cfg.Spoofer, Callback=function(v) teApi:SetSpoofer(v) end})
    reg(s3, "TextBox", "te.SpooferText", {Placeholder="custom name...", Text=cfg.SpooferText,
        Callback=function(t) teApi:SetSpooferText(t) end})

    -- ❗ DECAL BROWSER для spoofer-аватарки
    local SPOOF_AVATARS = {
        { name = "default (aspirine)", url = "rbxassetid://125404550221755" },
        { name = "aspirine transparent", url = "rbxassetid://98491322897003" },
        { name = "hysteria logo",       url = "rbxassetid://304489727" },
        { name = "player avatar",       url = "rbxthumb://type=AvatarHeadShot&id="
                                          .. tostring(LocalPlayer.UserId) .. "&w=150&h=150" },
        { name = "mellstroy 1",  url = "rbxassetid://129477975431198" },
        { name = "mellstroy 2",  url = "rbxassetid://17431397425" },
        { name = "mellstroy 3",  url = "rbxassetid://83756648376461" },
        { name = "mellstroy 11", url = "rbxassetid://135535710084064" },
        { name = "mellstroy 12", url = "rbxassetid://91665367380741" },
        { name = "floppa 1",     url = "rbxassetid://7184835629" },
        { name = "floppa 2",     url = "rbxassetid://7436293165" },
        { name = "floppa 3",     url = "rbxassetid://6782393070" },
        { name = "el gato 1",    url = "rbxassetid://10185836151" },
        { name = "el gato 2",    url = "rbxassetid://10153623424" },
        { name = "boykisser 1",  url = "rbxassetid://110482195453919" },
        { name = "boykisser 2",  url = "rbxassetid://17529062315" },
        { name = "dima twin 1",  url = "rbxassetid://110165141362804" },
        { name = "dima twin 2",  url = "rbxassetid://84335861136344" },
        { name = "mimi typh 1",  url = "rbxassetid://138729523360924" },
        { name = "mimi typh 4",  url = "rbxassetid://132986177369877" },
        { name = "furry 1",      url = "rbxassetid://9000135198" },
        { name = "furry 2",      url = "rbxassetid://7284437208" },
        { name = "furry 5",      url = "rbxassetid://7235621717" },
        { name = "femboy robin", url = "rbxassetid://105159771431173" },
        { name = "ralsei 1",     url = "rbxassetid://7652140680" },
        { name = "ralsei 2",     url = "rbxassetid://5365488179" },
        { name = "anime 1",      url = "rbxassetid://4934665327" },
        { name = "anime 3",      url = "rbxassetid://7201239769" },
        { name = "cat 1",        url = "rbxassetid://9896044884" },
        { name = "cat 2",        url = "rbxassetid://13447686141" },
        { name = "cat 3",        url = "rbxassetid://133025255930097" },
        { name = "standoff 2",   url = "rbxassetid://13863684860" },
        { name = "standoff ctrax", url = "rbxassetid://14587254725" },
        { name = "LIL UZI VERT", url = "rbxassetid://12950728616" },
        { name = "idkr 1",       url = "rbxassetid://97131184818802" },
        { name = "idkr 2",       url = "rbxassetid://105960904062678" },
    }
    local function openSpooferBrowser()
        local PW3, PH3 = 560, 620
        local popup3, _ = makePopupFrame("spoofer_browser", "- spoofer avatar browser -", PW3, PH3)
        local scroll3 = create("ScrollingFrame", {
            Name="list", BackgroundTransparency=1,
            Size=UDim2.new(1,-24,1,-90), Position=UDim2.new(0,12,0,32),
            BorderSizePixel=0, ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, popup3)
        local lay3 = Instance.new("UIListLayout")
        lay3.SortOrder=Enum.SortOrder.LayoutOrder
        lay3.Padding=UDim.new(0,4); lay3.Parent=scroll3
        local pad3 = Instance.new("UIPadding")
        pad3.PaddingTop=UDim.new(0,4); pad3.PaddingBottom=UDim.new(0,4)
        pad3.PaddingLeft=UDim.new(0,4); pad3.PaddingRight=UDim.new(0,4)
        pad3.Parent=scroll3

        local function applyURL(url)
            if teApi.SetAvatarImage then
                pcall(function() teApi:SetAvatarImage(url) end)
            else
                pcall(function() teApi:SetSpooferText(url) end)
            end
            popup3:Destroy()
        end

        for i, item in ipairs(SPOOF_AVATARS) do
            local row = create("Frame", {Name="sp_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.35,
                Size=UDim2.new(1,0,0,56), LayoutOrder=i}, scroll3)
            corner(row, 6)
            local thumb = create("ImageLabel", {Name="thumb",
                BackgroundColor3=PALETTE.Element, Image=item.url,
                ImageColor3=Color3.new(1,1,1),
                Size=UDim2.new(0,48,0,48), Position=UDim2.new(0,4,0.5,-24)}, row)
            corner(thumb, 6)
            create("TextLabel", {Name="nm", BackgroundTransparency=1,
                Text=item.name, TextSize=12, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-120,1,0), Position=UDim2.new(0,60,0,0)}, row)
            local applyBtn = create("TextButton", {Name="apply",
                AutoButtonColor=false, Text="apply", TextSize=11,
                TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,68,1,-14), Position=UDim2.new(1,-74,0,7)}, row)
            corner(applyBtn, 5)
            applyBtn.MouseEnter:Connect(function()
                tween(applyBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
            end)
            applyBtn.MouseLeave:Connect(function()
                tween(applyBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
            end)
            applyBtn.MouseButton1Click:Connect(function() applyURL(item.url) end)
        end

        local customBox = create("TextBox", {Name="custom",
            Text="", PlaceholderText="id или rbxassetid://",
            PlaceholderColor3=PALETTE.TextDim, TextSize=12,
            TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
            BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-100,0,26), Position=UDim2.new(0,12,1,-34)}, popup3)
        corner(customBox, 5); addGlass(customBox, 0.4, PALETTE.ElementGlass)
        local cpad = Instance.new("UIPadding")
        cpad.PaddingLeft=UDim.new(0,8); cpad.PaddingRight=UDim.new(0,8); cpad.Parent=customBox
        local applyC = create("TextButton", {Name="applyC",
            AutoButtonColor=false, Text="apply", TextSize=11,
            TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(0,72,0,26), Position=UDim2.new(1,-84,1,-34)}, popup3)
        corner(applyC, 5)
        local function doApplyC()
            local t = customBox.Text or ""
            if t == "" then return end
            if t:match("^%d+$") then t = "rbxassetid://" .. t end
            applyURL(t)
        end
        applyC.MouseButton1Click:Connect(doApplyC)
        customBox.FocusLost:Connect(function(enter) if enter then doApplyC() end end)

        popup3.Position = UDim2.new(0.5, -PW3/2, 0.5, -PH3/2)
        popup3.Visible = true
        popup3.BackgroundTransparency = 0
    end

    s3:Button({Text="browse spoofer avatar", Callback=openSpooferBrowser})

    reg(s3, "Toggle", "te.HideAvatar", {Text="hide avatar", Default=cfg.HideAvatar,
        Callback=function(v) teApi:SetHideAvatar(v) end})
    local initialFontIdx = 1
    for i, n in ipairs(FONT_NAMES) do if n == cfg.Font then initialFontIdx = i break end end
    s3:Label("font:")
    reg(s3, "Cycle", "te.Font", {Prefix="", Values=FONT_NAMES, Index=initialFontIdx,
        Callback=function(v) teApi:SetFont(v) end})

    s3:Divider()
    s3:Label("transform:")
    reg(s3, "Slider", "te.scale", {Text="scale",
        Min=0.5, Max=3, Default=1,
        Callback=function(v)
            if teApi and teApi.SetScale then teApi:SetScale(v) end
        end})
    reg(s3, "Toggle", "te.LockDrag", {Text="lock position", Default=false,
        Callback=function(v) teApi:GetConfig().LockDrag = v end})

    s4:Label("background:")
    reg(s4, "ColorPicker", "te.BgColor", {Text="bg color",
        GetInitialColor=function() return teApi:GetConfig().BgColor end,
        Callback=function(c) teApi:SetBgColor(c) end})
    reg(s4, "Slider", "te.BgTransparency", {Text="bg transparency", Min=0, Max=1,
        Default=teApi:GetConfig().BgTransparency,
        Callback=function(v) teApi:SetBgTransparency(v) end})
    reg(s4, "Slider", "te.CornerRadius", {Text="corner radius", Min=0, Max=20,
        Default=teApi:GetConfig().CornerRadius,
        Callback=function(v) teApi:SetCornerRadius(v) end})
    s4:Divider()
    s4:Label("stroke:")
    reg(s4, "ColorPicker", "te.StrokeColor", {Text="stroke color",
        GetInitialColor=function() return teApi:GetConfig().StrokeColor end,
        Callback=function(c) teApi:SetStrokeColor(c) end})
    reg(s4, "Slider", "te.StrokeThickness", {Text="thickness", Min=0, Max=5,
        Default=teApi:GetConfig().StrokeThickness,
        Callback=function(v) teApi:SetStrokeThickness(v) end})
    reg(s4, "Slider", "te.StrokeTransparency", {Text="transparency", Min=0, Max=1,
        Default=teApi:GetConfig().StrokeTransparency,
        Callback=function(v) teApi:SetStrokeTransparency(v) end})

    local openedAtRef = {value=0}
    local anchorRef = {instance=nil}
    return makeSettingsHandlers(popup, PW, PH, anchorRef, openedAtRef, gui)
end

local function buildTargetList()
    if PlayerGui:FindFirstChild("TargetESP") then PlayerGui.TargetESP:Destroy() end
    local DEFAULT_AVATAR = "rbxassetid://135535710084064"
    local ScreenGui = create("ScreenGui", {Name="TargetESP",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
        IgnoreGuiInset=true, DisplayOrder=850}, PlayerGui)
    local Frame = create("Frame", {Name="Main", BackgroundColor3=PALETTE.Panel,
        BackgroundTransparency=0, Size=UDim2.new(0,260,0,78),
        Position=UDim2.new(0.56035,0,0.44636,0), Active=true, Visible=true}, ScreenGui)
    local teCorner = corner(Frame, 10)
    local teStroke = Instance.new("UIStroke")
    teStroke.Color = Color3.fromRGB(255,255,255); teStroke.Thickness = 0
    teStroke.Transparency = 1; teStroke.Parent = Frame
    local accentStroke = Instance.new("UIStroke")
    accentStroke.Color = Library.Settings.AccentColor; accentStroke.Thickness = 1
    accentStroke.Transparency = 0.4; accentStroke.Parent = Frame
    local accentBar = create("Frame", {Name="accentBar", BackgroundColor3=Library.Settings.AccentColor,
        BackgroundTransparency=0.3, Size=UDim2.new(0,3,1,-20),
        Position=UDim2.new(0,0,0,10)}, Frame)
    corner(accentBar, 2)
    local avatar = create("ImageLabel", {Name="avatar", BackgroundColor3=PALETTE.Element,
        Image=DEFAULT_AVATAR, Size=UDim2.new(0,56,0,56),
        Position=UDim2.new(0,12,0,11)}, Frame)
    avatar.ImageColor3 = Color3.new(1,1,1)
    avatar.ImageTransparency = 0
    corner(avatar, 8)
    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Library.Settings.AccentColor
    avatarStroke.Thickness = 1.5; avatarStroke.Transparency = 0.35
    avatarStroke.Parent = avatar
    local playerInfo = create("TextLabel", {Name="playerinfo", BackgroundTransparency=1,
        Text="target preview", TextSize=14, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-82,0,18), Position=UDim2.new(0,78,0,12)}, Frame)
    local displayInfo = create("TextLabel", {Name="displayinfo", BackgroundTransparency=1,
        Text="@-", TextSize=12, FontFace=FONT_REGULAR, TextColor3=PALETTE.TextDim,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd,
        Size=UDim2.new(1,-82,0,14), Position=UDim2.new(0,78,0,30)}, Frame)
    local healthLabel = create("TextLabel", {Name="hpLabel", BackgroundTransparency=1,
        Text="hp 0 / 100", TextSize=11, FontFace=FONT_BOLD, TextColor3=PALETTE.TextDim,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-86,0,12), Position=UDim2.new(0,78,0,46)}, Frame)
    local healthTrack = create("Frame", {Name="healthTrack", BackgroundColor3=PALETTE.Element,
        BackgroundTransparency=0, Size=UDim2.new(1,-86,0,8),
        Position=UDim2.new(0,78,0,60)}, Frame)
    corner(healthTrack, 4)
    local healthFill = create("Frame", {Name="fill", BackgroundColor3=Library.Settings.AccentColor,
        Size=UDim2.new(0,0,1,0)}, healthTrack)
    corner(healthFill, 4)

    local textTargets = {playerInfo, displayInfo, healthLabel}
    local flagByLabel = {playerinfo="GradName", displayinfo="GradDisplay", hpLabel="GradHealth"}
    local textGradients = {}
    for _, lbl in ipairs(textTargets) do
        local g = Instance.new("UIGradient")
        g.Name = "TeGrad"; g.Enabled = false; g.Parent = lbl
        table.insert(textGradients, g)
    end

    local config = {Enabled=true, Gradient=false, Blink=false,
        GradName=true, GradDisplay=true, GradHealth=true,
        AccentColor=Library.Settings.AccentColor,
        ColorA=Library.Settings.AccentColor, ColorB=Color3.new(1,1,1),
        Speed=1, Style="flow", Font="arial",
        Spoofer=false, SpooferText="primo user", HideAvatar=false, Target=nil,
        AvatarTintAccent=false, AvatarTintColor=Library.Settings.AccentColor,
        AvatarTransparency=0,
        ShowDistance=true, AutoTarget=false, ShowOnlyWhenEnemies=false,
        BgColor=PALETTE.Panel, BgTransparency=0, CornerRadius=10,
        StrokeColor=Color3.fromRGB(255,255,255),
        StrokeThickness=0, StrokeTransparency=1,
        LockDrag=false}

    local function applyVisibility()
        local show = config.Enabled
        if config.ShowOnlyWhenEnemies and not config.Target then
            show = false
        end
        Frame.Visible = show
    end
    local function getDistance()
        local target = config.Target
        if not target or not target.Parent then return nil end
        local myChar = LocalPlayer.Character; local tChar = target.Character
        if not myChar or not tChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        if not myRoot or not tRoot then return nil end
        return math.floor((myRoot.Position - tRoot.Position).Magnitude)
    end
    local function applyName()
        local target = config.Target
        if config.Spoofer then
            playerInfo.Text = config.SpooferText
            displayInfo.Text = config.SpooferText
            displayInfo.Visible = false
        else
            displayInfo.Visible = true
            if target and target.Parent then
                local dist = config.ShowDistance and getDistance()
                local suffix = dist and ("  [" .. dist .. "m]") or ""
                playerInfo.Text = target.DisplayName .. suffix
                displayInfo.Text = "@" .. target.Name
            else
                playerInfo.Text = "target preview"; displayInfo.Text = "@-"
            end
        end
    end
    local function applyAvatar()
        if config.HideAvatar then avatar.Image = DEFAULT_AVATAR
        elseif config.AvatarImage then avatar.Image = config.AvatarImage
        else
            local target = config.Target
            if target and target.Parent then
                avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. target.UserId .. "&w=150&h=150"
            else avatar.Image = DEFAULT_AVATAR end
        end
    end
    local function applyHealth()
        local target = config.Target
        local hp, maxHp = 0, 100
        if target and target.Parent and target.Character then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then hp = math.floor(humanoid.Health); maxHp = math.floor(humanoid.MaxHealth) end
        end
        healthLabel.Text = "hp " .. hp .. " / " .. maxHp
        local a = 0; if maxHp > 0 then a = hp/maxHp end
        tween(healthFill, {Size = UDim2.new(a, 0, 1, 0)}, 0.2)
    end
    local function applyFont()
        playerInfo.FontFace = getFontByName(config.Font)
        displayInfo.FontFace = getFontByName(config.Font)
        healthLabel.FontFace = getFontByName(config.Font)
    end
    local function applyGradient()
        for i, g in ipairs(textGradients) do
            local flag = flagByLabel[textTargets[i].Name]
            local on = config.Gradient and config[flag]
            g.Enabled = on and true or false
            if on then
                g.Offset = Vector2.new(0, 0)
                g.Rotation = (config.Style == "sweep") and 45 or 0
                g.Color = resolveSeq(config.ColorA, config.ColorB)
            end
        end
    end
    local function applyTeAccent()
        tween(accentStroke, {Color=config.AccentColor})
        tween(accentBar, {BackgroundColor3=config.AccentColor})
        tween(avatarStroke, {Color=config.AccentColor})
        tween(healthFill, {BackgroundColor3=config.AccentColor})
    end
    applyVisibility(); applyFont(); applyGradient(); applyTeAccent()

    local gradientPhase = 0
    local animConn = RunService.Heartbeat:Connect(function(dt)
        if not config.Enabled then return end
        if not config.Gradient then return end
        local enabledGrads = {}
        for _, g in ipairs(textGradients) do
            if g.Enabled then table.insert(enabledGrads, g) end
        end
        if #enabledGrads == 0 then return end
        local style = config.Style; local speed = config.Speed
        if style == "sweep" then
            gradientPhase = (gradientPhase + dt*speed*60) % 360
            for _, g in ipairs(enabledGrads) do g.Rotation = gradientPhase end
        elseif style == "pulse" then
            gradientPhase = (gradientPhase + dt*speed*0.4) % 1
            local k = (math.sin(gradientPhase*math.pi*2)+1)*0.5
            local seq = resolvePulseSeq(config.ColorA, config.ColorB, k)
            for _, g in ipairs(enabledGrads) do g.Color = seq end
        else
            gradientPhase = (gradientPhase + dt*speed*0.15) % 1
            local o = math.sin(gradientPhase*math.pi*2)*0.5
            for _, g in ipairs(enabledGrads) do g.Offset = Vector2.new(o, 0) end
        end
    end)
    local function autoTargetNearest()
        if not config.AutoTarget then return end
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local Ab = I.Aimbot
        local wl = I.isWhitelisted
        local nd = I.isTeamNoDraw
        local localTeam = LocalPlayer.Team

        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local skip = false
                if Ab and Ab.teamCheck and p.Team ~= nil and p.Team == localTeam then
                    skip = true
                end
                if not skip and Ab and Ab.skipFriends and wl and wl(p) then
                    skip = true
                end
                if not skip and nd and nd(p) then
                    skip = true
                end
                if not skip then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        local d = (myRoot.Position - root.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closest = p
                        end
                    end
                end
            end
        end
        if closest and closest ~= config.Target then
            config.Target = closest
            applyName()
            applyAvatar()
            applyHealth()
            applyVisibility()
        end
    end
    local running = true
    local updateThread = task.spawn(function()
        while running do
            task.wait(0.25)
            if not running then break end
            if Frame.Visible then
                if config.Enabled then pcall(autoTargetNearest) end
                if config.Enabled and config.Target then
                    pcall(applyHealth)
                    if not config.Spoofer then pcall(applyName) end
                    pcall(applyAvatar)
                end
            end
        end
    end)
    local removeConn = Players.PlayerRemoving:Connect(function(p)
        if p == config.Target then
            config.Target = nil
            applyName(); applyAvatar(); applyHealth(); applyVisibility()
        end
    end)

    local dragging, dragStart, startPos = false, nil, nil
    Frame.InputBegan:Connect(function(input)
        if config.LockDrag then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Frame.Position
        end
    end)
    local teDragChanged = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
            Frame.Position = newPos
            _G.__HYSTERIA_TL_POS = newPos
        end
    end)
    local teDragEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local api = {}
    function api:GetConfig() return config end
    function api:GetPosition() return Frame.Position end
    function api:SetPosition(pos)
        if typeof(pos) == "UDim2" then
            Frame.Position = pos
            _G.__HYSTERIA_TL_POS = pos
        end
    end
    function api:SetAccentColor(c) config.AccentColor = c; applyTeAccent() end
    function api:SetEnabled(v) config.Enabled = v and true or false; applyVisibility() end
    function api:SetGradient(v) config.Gradient = v and true or false; applyGradient() end
    function api:SetBlink(v) config.Blink = v and true or false end
    function api:SetGradName(v) config.GradName = v and true or false; applyGradient() end
    function api:SetGradDisplay(v) config.GradDisplay = v and true or false; applyGradient() end
    function api:SetGradHealth(v) config.GradHealth = v and true or false; applyGradient() end
    function api:SetColorA(c) config.ColorA = c; applyGradient() end
    function api:SetColorB(c) config.ColorB = c; applyGradient() end
    function api:SetSpeed(v) config.Speed = v end
    function api:SetStyle(v) config.Style = v; applyGradient() end
    function api:SetFont(n) config.Font = n; applyFont() end
    function api:SetSpoofer(v) config.Spoofer = v and true or false; applyName() end
    function api:SetSpooferText(t) config.SpooferText = t or ""; applyName() end
    function api:SetHideAvatar(v) config.HideAvatar = v and true or false; applyAvatar() end
    function api:SetAvatarImage(url)
        if type(url) ~= "string" or url == "" then return end
        config.AvatarImage = url
        config.HideAvatar = false
        local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["te.HideAvatar"]
        if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
        applyAvatar()
    end
        function api:SetAvatarTintAccent(v)
        config.AvatarTintAccent = v and true or false
        avatar.ImageColor3 = config.AvatarTintAccent and Library.Settings.AccentColor or config.AvatarTintColor
    end
    function api:SetAvatarTintColor(c)
        config.AvatarTintColor = c
        if not config.AvatarTintAccent then avatar.ImageColor3 = c end
    end
    function api:SetAvatarTransparency(t)
        config.AvatarTransparency = math.clamp(t,0,1)
        avatar.ImageTransparency = config.AvatarTransparency
    end
    function api:SetShowDistance(v) config.ShowDistance = v and true or false; applyName() end
    function api:SetAutoTarget(v) config.AutoTarget = v and true or false end
    function api:SetShowOnlyWhenEnemies(v)
        config.ShowOnlyWhenEnemies = v and true or false
        applyVisibility()
    end
    function api:SetBgColor(c) config.BgColor = c; Frame.BackgroundColor3 = c end

    -- ❗ новые сеттеры (для новых слайдеров)
    function api:SetTextSize(v)
        config.TextSize = math.clamp(tonumber(v) or 14, 8, 28)
        applyTextSize()
    end
    function api:SetLogoSize(v)
        config.LogoSize = math.clamp(tonumber(v) or 22, 10, 48)
        applyLogoSize()
    end
    function api:SetGap(v)
        config.Gap = math.clamp(tonumber(v) or 6, 0, 24)
        applyLayout()
    end
    function api:SetPaddingLeft(v)
        config.PaddingLeft = math.clamp(tonumber(v) or 8, 0, 40)
        applyLayout()
    end
    function api:SetPaddingRight(v)
        config.PaddingRight = math.clamp(tonumber(v) or 10, 0, 40)
        applyLayout()
    end
    function api:SetBgTransparency(t)
        config.BgTransparency = math.clamp(t,0,1)
        Frame.BackgroundTransparency = config.BgTransparency
    end
    function api:SetCornerRadius(r)
        config.CornerRadius = math.max(0,r); teCorner.CornerRadius = UDim.new(0, config.CornerRadius)
    end
    function api:SetStrokeColor(c) config.StrokeColor = c; teStroke.Color = c end
    function api:SetStrokeThickness(n)
        config.StrokeThickness = math.max(0,n); teStroke.Thickness = config.StrokeThickness
    end
    function api:SetStrokeTransparency(t)
        config.StrokeTransparency = math.clamp(t,0,1); teStroke.Transparency = config.StrokeTransparency
    end
    function api:SetTarget(player)
        config.Target = player
        applyName(); applyAvatar(); applyHealth(); applyVisibility()
    end
    function api:ClearTarget()
        config.Target = nil
        applyName(); applyAvatar(); applyHealth(); applyVisibility()
    end
    function api:GetTarget() return config.Target end
    function api:GetFrame() return Frame end
    function api:SetScale(s)
        s = math.clamp(tonumber(s) or 1, 0.5, 3.0)
        local us = Frame:FindFirstChildOfClass("UIScale")
        if not us then
            us = Instance.new("UIScale"); us.Parent = Frame
        end
        us.Scale = s
        Library.Settings.HUDScale = Library.Settings.HUDScale or {}
        Library.Settings.HUDScale.targetesp = s
    end
    function api:GetScale()
        local us = Frame:FindFirstChildOfClass("UIScale")
        return us and us.Scale or 1
    end
    local settingsPopup = buildTargetESPSettingsPopup(api)
    if _G.__HYSTERIA_TL_POS then
        Frame.Position = _G.__HYSTERIA_TL_POS
    end
    function api:Destroy()
        running = false
        pcall(function() removeConn:Disconnect() end)
        pcall(function() animConn:Disconnect() end)
        pcall(function() teDragChanged:Disconnect() end)
        pcall(function() teDragEnded:Disconnect() end)
        pcall(function() settingsPopup:Destroy() end)
        pcall(function() ScreenGui:Destroy() end)
    end
    function api:ToggleSettings(a) settingsPopup:Toggle(a) end
    function api:CloseSettings() settingsPopup:Close() end
    function api:IsSettingsOpen() return settingsPopup:IsOpen() end
    api._openSettings = function(anchor)
        if anchor then settingsPopup:Toggle(anchor) else settingsPopup:Open() end
    end
    return api
end

-- ═══════════════════════════════════════════════════════════
-- PICTURE HUD  —  оверлей-картинка на экране
-- ═══════════════════════════════════════════════════════════
local function buildPictureHUD()
    if PlayerGui:FindFirstChild("primo_picture") then
        PlayerGui.primo_picture:Destroy()
    end
    local ScreenGui = create("ScreenGui", {Name="primo_picture",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
        IgnoreGuiInset=true, DisplayOrder=840}, PlayerGui)

    local W_DEF, H_DEF = 260, 195

    local Frame = create("Frame", {Name="Main",
        BackgroundColor3=PALETTE.Panel, BackgroundTransparency=1,
        Size=UDim2.new(0, W_DEF, 0, H_DEF),
        Position=_G.__HYSTERIA_PIC_POS or UDim2.new(0.02, 0, 0.4, 0),
        Active=true, Visible=true}, ScreenGui)
    local picCorner = corner(Frame, 8)

    local picStroke = Instance.new("UIStroke")
    picStroke.Color = Library.Settings.AccentColor
    picStroke.Thickness = 0
    picStroke.Transparency = 1
    picStroke.Parent = Frame

    local image = create("ImageLabel", {Name="pic",
        BackgroundTransparency=1,
        Image="rbxassetid://12150333118",
        ImageColor3=Color3.new(1,1,1),
        ImageTransparency=0,
        ScaleType=Enum.ScaleType.Fit,
        Size=UDim2.new(1,0,1,0),
        Position=UDim2.new(0,0,0,0),
        ZIndex=2}, Frame)
    corner(image, 8)

    registerAccent(function()
        if picStroke and picStroke.Parent then
            tween(picStroke, {Color=Library.Settings.AccentColor})
        end
        local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.accentTint"]
        if c and c:Get() and image and image.Parent then
            image.ImageColor3 = Library.Settings.AccentColor
        end
    end)

    -- ── состояние ──
    local cfg = {
        Enabled            = true,
        Url                = "rbxassetid://12150333118",
        ImageTransparency  = 0,
        Width              = W_DEF,
        Height             = H_DEF,
        CornerRadius       = 8,
        StrokeColor        = Library.Settings.AccentColor,
        StrokeThickness    = 0,
        StrokeTransparency = 1,
        BgColor            = PALETTE.Panel,
        BgTransparency     = 1,
        ScaleType          = "Fit",
        LockDrag           = false,
        AccentTint         = false,
        ImageColor         = Color3.new(1,1,1),
        Rotation           = 0,
    }

    local SCALE_TYPE_MAP = {
        Fit     = Enum.ScaleType.Fit,
        Crop    = Enum.ScaleType.Crop,
        Stretch = Enum.ScaleType.Stretch,
        Tile    = Enum.ScaleType.Tile,
    }

    local function applyAll()
        if not Frame or not Frame.Parent then return end
        Frame.Size                   = UDim2.new(0, cfg.Width, 0, cfg.Height)
        Frame.BackgroundColor3       = cfg.BgColor
        Frame.BackgroundTransparency = cfg.BgTransparency
        Frame.Visible                = cfg.Enabled
        picCorner.CornerRadius       = UDim.new(0, cfg.CornerRadius)
        picStroke.Color              = cfg.StrokeColor
        picStroke.Thickness          = cfg.StrokeThickness
        picStroke.Transparency       = cfg.StrokeTransparency
        image.Image                  = cfg.Url
        image.ImageTransparency      = cfg.ImageTransparency
        image.ScaleType              = SCALE_TYPE_MAP[cfg.ScaleType] or Enum.ScaleType.Fit
        image.ImageColor3            = cfg.AccentTint
            and Library.Settings.AccentColor
            or  (cfg.ImageColor or Color3.new(1,1,1))
        image.Rotation               = cfg.Rotation or 0
    end
    applyAll()

    -- ══ POPUP настроек ══
    local PW, PH = 720, 680
    local popup, gui = makePopupFrame("picture_settings", "- picture settings -", PW, PH)
    local colW, colGap, startX, startY = 170, 5, 5, 30
    local colH = PH - startY - 10
    local function makeCol(idx)
        return create("Frame", {Name="col"..idx, BackgroundTransparency=1,
            Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
            Size=UDim2.new(0,colW,0,colH)}, popup)
    end
    local s1 = setmetatable({Frame=makeCol(1), Y=0}, Section)
    local s2 = setmetatable({Frame=makeCol(2), Y=0}, Section)
    local s3 = setmetatable({Frame=makeCol(3), Y=0}, Section)
    local s4 = setmetatable({Frame=makeCol(4), Y=0}, Section)

    -- ── браузер картинок ──
    local PIC_PRESETS = {
        { name = "hysteria banner",      url = "rbxassetid://12150333118" },
        { name = "hysteria logo",        url = "rbxassetid://304489727" },
        { name = "aspirine transparent", url = "rbxassetid://98491322897003" },
        { name = "aspirine",             url = "rbxassetid://125404550221755" },
        { name = "furry femboy",         url = "rbxassetid://106158288148110" },
        { name = "dima twin 1",          url = "rbxassetid://110165141362804" },
        { name = "dima twin 2",          url = "rbxassetid://84335861136344" },
        { name = "mimi typh 1",          url = "rbxassetid://138729523360924" },
        { name = "floppa 1",             url = "rbxassetid://7184835629" },
        { name = "el gato 1",            url = "rbxassetid://10185836151" },
        { name = "boykisser 1",          url = "rbxassetid://110482195453919" },
        { name = "mellstroy 11",         url = "rbxassetid://135535710084064" },
        { name = "rainbow cat",          url = "rbxassetid://70509481945808" },
        { name = "player avatar",        url = "rbxthumb://type=AvatarHeadShot&id="
                                            .. tostring(LocalPlayer.UserId) .. "&w=150&h=150" },
    }

    -- forward decl
    local api = {}
    local setUrl

    local function openPictureBrowser()
        local PW2, PH2 = 520, 560
        local popup2, _ = makePopupFrame("picture_browser", "- picture browser -", PW2, PH2)
        local scroll2 = create("ScrollingFrame", {
            Name="list", BackgroundTransparency=1,
            Size=UDim2.new(1,-24,1,-90), Position=UDim2.new(0,12,0,32),
            BorderSizePixel=0, ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, popup2)
        local lay = Instance.new("UIListLayout")
        lay.SortOrder=Enum.SortOrder.LayoutOrder
        lay.Padding=UDim.new(0,4); lay.Parent=scroll2
        local pad = Instance.new("UIPadding")
        pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,4)
        pad.PaddingLeft=UDim.new(0,4); pad.PaddingRight=UDim.new(0,4)
        pad.Parent=scroll2

        for i, item in ipairs(PIC_PRESETS) do
            local row = create("Frame", {Name="p_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.35,
                Size=UDim2.new(1,0,0,56), LayoutOrder=i}, scroll2)
            corner(row, 6)
            local thumb = create("ImageLabel", {Name="thumb",
                BackgroundColor3=PALETTE.Element, Image=item.url,
                ImageColor3=Color3.new(1,1,1),
                Size=UDim2.new(0,48,0,48), Position=UDim2.new(0,4,0.5,-24)}, row)
            corner(thumb, 6)
            create("TextLabel", {Name="nm", BackgroundTransparency=1,
                Text=item.name, TextSize=12, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-120,1,0), Position=UDim2.new(0,60,0,0)}, row)
            local applyBtn = create("TextButton", {Name="apply",
                AutoButtonColor=false, Text="apply", TextSize=11,
                TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,68,1,-14), Position=UDim2.new(1,-74,0,7)}, row)
            corner(applyBtn, 5)
            applyBtn.MouseEnter:Connect(function()
                tween(applyBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
            end)
            applyBtn.MouseLeave:Connect(function()
                tween(applyBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
            end)
            applyBtn.MouseButton1Click:Connect(function()
                setUrl(item.url)
                popup2:Destroy()
            end)
        end

        local customBox = create("TextBox", {Name="custom",
            Text="", PlaceholderText="id или rbxassetid://",
            PlaceholderColor3=PALETTE.TextDim, TextSize=12,
            TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
            BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,-100,0,26), Position=UDim2.new(0,12,1,-34)}, popup2)
        corner(customBox, 5); addGlass(customBox, 0.4, PALETTE.ElementGlass)
        local cpad = Instance.new("UIPadding")
        cpad.PaddingLeft=UDim.new(0,8); cpad.PaddingRight=UDim.new(0,8); cpad.Parent=customBox
        local applyC = create("TextButton", {Name="applyC",
            AutoButtonColor=false, Text="apply", TextSize=11,
            TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(0,72,0,26), Position=UDim2.new(1,-84,1,-34)}, popup2)
        corner(applyC, 5)
        local function doApplyC()
            local t = customBox.Text or ""
            if t == "" then return end
            setUrl(t); popup2:Destroy()
        end
        applyC.MouseButton1Click:Connect(doApplyC)
        customBox.FocusLost:Connect(function(enter) if enter then doApplyC() end end)

        popup2.Position = UDim2.new(0.5, -PW2/2, 0.5, -PH2/2)
        popup2.Visible = true
        popup2.BackgroundTransparency = 0
    end

    -- ── настройки ──
    s1:Label("visibility:")
    reg(s1, "Toggle", "picture.enabled", {Text="enabled", Default=true,
        Callback=function(v) cfg.Enabled = v; applyAll() end})
    reg(s1, "Toggle", "picture.lockDrag", {Text="lock position", Default=false,
        Callback=function(v) cfg.LockDrag = v end})
    s1:Divider()
    s1:Label("image scaling:")
    reg(s1, "Cycle", "picture.scaleType", {Prefix="mode: ",
        Values={"Fit","Crop","Stretch","Tile"}, Index=1,
        Callback=function(v) cfg.ScaleType = v; applyAll() end})
    s1:Divider()
    s1:Label("transform:")
    reg(s1, "Slider", "picture.scale", {Text="scale",
        Min=0.2, Max=5, Default=1,
        Callback=function(v)
            if api and api.SetScale then api:SetScale(v) end
        end})
    reg(s1, "Slider", "picture.rotation", {Text="rotation (°)",
        Min=-180, Max=180, Default=0,
        Callback=function(v) cfg.Rotation = v; applyAll() end})
    reg(s1, "Button", "picture.resetRotation", {Text="reset rotation",
        Callback=function()
            cfg.Rotation = 0
            applyAll()
            local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.rotation"]
            if c and c.Set then pcall(function() c:Set(0, true) end) end
        end})
    s1:Divider()
    s1:Label("actions:")
    s1:Button({Text="browse image...", Callback=openPictureBrowser})
    s1:Button({Text="reset size", Callback=function()
        cfg.Width  = W_DEF
        cfg.Height = H_DEF
        applyAll()
        local cw = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.width"]
        if cw and cw.Set then cw:Set(W_DEF, true) end
        local ch = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.height"]
        if ch and ch.Set then ch:Set(H_DEF, true) end
    end})
    s1:Button({Text="reset position", Callback=function()
        Frame.Position = UDim2.new(0.02, 0, 0.4, 0)
        _G.__HYSTERIA_PIC_POS = Frame.Position
    end})

    s2:Label("image:")
    reg(s2, "Slider", "picture.transparency", {Text="image transparency",
        Min=0, Max=1, Default=0,
        Callback=function(v) cfg.ImageTransparency = v; applyAll() end})
    reg(s2, "Toggle", "picture.accentTint", {Text="use accent color", Default=false,
        Callback=function(v) cfg.AccentTint = v; applyAll() end})
    -- ❗ ручной цвет картинки (если accentTint выключен — используется этот)
    reg(s2, "ColorPicker", "picture.imageColor", {Text="image color",
        GetInitialColor=function() return cfg.ImageColor or Color3.new(1,1,1) end,
        Callback=function(c)
            cfg.ImageColor = c
            cfg.AccentTint = false
            local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.accentTint"]
            if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
            applyAll()
        end})
    reg(s2, "Slider", "picture.width", {Text="width (px)", Min=40, Max=1200, Default=W_DEF,
        Callback=function(v) cfg.Width = math.floor(v); applyAll() end})
    reg(s2, "Slider", "picture.height", {Text="height (px)", Min=40, Max=1200, Default=H_DEF,
        Callback=function(v) cfg.Height = math.floor(v); applyAll() end})
    reg(s2, "Slider", "picture.cornerRadius", {Text="corner radius",
        Min=0, Max=60, Default=8,
        Callback=function(v) cfg.CornerRadius = v; applyAll() end})

    s3:Label("stroke:")
    reg(s3, "ColorPicker", "picture.strokeColor", {Text="stroke color",
        GetInitialColor=function() return cfg.StrokeColor end,
        Callback=function(c) cfg.StrokeColor = c; applyAll() end})
    reg(s3, "Slider", "picture.strokeThickness", {Text="thickness",
        Min=0, Max=8, Default=0,
        Callback=function(v) cfg.StrokeThickness = v; applyAll() end})
    reg(s3, "Slider", "picture.strokeTransparency", {Text="transparency",
        Min=0, Max=1, Default=1,
        Callback=function(v) cfg.StrokeTransparency = v; applyAll() end})
    s3:Divider()
    s3:Label("background:")
    reg(s3, "ColorPicker", "picture.bgColor", {Text="bg color",
        GetInitialColor=function() return cfg.BgColor end,
        Callback=function(c) cfg.BgColor = c; applyAll() end})
    reg(s3, "Slider", "picture.bgTransparency", {Text="bg transparency",
        Min=0, Max=1, Default=1,
        Callback=function(v) cfg.BgTransparency = v; applyAll() end})

    s4:Label("hints:")
    s4:Label("— drag image on screen to move", 18)
    s4:Label("— right-click image to open this menu", 18)
    s4:Label("— toggle 'lock position' to disable drag", 18)
    s4:Divider()
    s4:Button({Text="close settings", Callback=function() popup.Visible=false end})

    -- ── setUrl ──
    setUrl = function(url)
        if type(url) ~= "string" or url == "" then return end
        if url:match("^%d+$") then url = "rbxassetid://" .. url end
        cfg.Url = url
        applyAll()
        local cu = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["picture.url"]
        if cu and cu.Set then pcall(function() cu:Set(url, true) end) end
    end

    -- ── drag ──
    local dragging, dragStart, startPos = false, nil, nil
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if api and api._settingsPopup then
                pcall(function() api._settingsPopup:Toggle(Frame) end)
            end
            return
        end
        -- ❗ lock: не начинаем drag если заблокировано
        if cfg.LockDrag then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)
    local dragChanged = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        -- ❗ lock: прерываем drag на середине если включили lock
        if cfg.LockDrag then dragging = false; return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                startPos.Y.Scale, startPos.Y.Offset+d.Y)
            Frame.Position = newPos
            _G.__HYSTERIA_PIC_POS = newPos
        end
    end)
    local dragEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ── API ──
    api._settingsPopup = makeSettingsHandlers(popup, PW, PH,
        {instance=nil}, {value=0}, gui)

    function api:SetEnabled(v) cfg.Enabled = v; applyAll() end
    function api:SetUrl(url) setUrl(url) end
    function api:GetUrl() return cfg.Url end
    function api:GetConfig() return cfg end
    function api:GetPosition() return Frame.Position end
    function api:SetPosition(pos)
        if typeof(pos) == "UDim2" then
            Frame.Position = pos
            _G.__HYSTERIA_PIC_POS = pos
        end
    end
    function api:GetFrame() return Frame end
    function api:SetScale(s)
        s = math.clamp(tonumber(s) or 1, 0.2, 5.0)
        local us = Frame:FindFirstChildOfClass("UIScale")
        if not us then
            us = Instance.new("UIScale"); us.Parent = Frame
        end
        us.Scale = s
        Library.Settings.HUDScale = Library.Settings.HUDScale or {}
        Library.Settings.HUDScale.picture = s
    end
    function api:GetScale()
        local us = Frame:FindFirstChildOfClass("UIScale")
        return us and us.Scale or 1
    end
    function api:ToggleSettings(a) api._settingsPopup:Toggle(a or Frame) end
    function api:CloseSettings() api._settingsPopup:Close() end
    function api:IsSettingsOpen() return api._settingsPopup:IsOpen() end
    function api:Destroy()
        pcall(function() dragChanged:Disconnect() end)
        pcall(function() dragEnded:Disconnect() end)
        pcall(function() api._settingsPopup:Destroy() end)
        pcall(function() ScreenGui:Destroy() end)
    end

    -- persistable URL control
    local CONTROLS = _G.__PRIMO_CONTROLS
    if CONTROLS and not CONTROLS["picture.url"] then
        CONTROLS["picture.url"] = {
            Get = function(self) return cfg.Url end,
            Set = function(self, v, silent) setUrl(v) end,
        }
    end

    if _G.__HYSTERIA_PIC_POS then
        Frame.Position = _G.__HYSTERIA_PIC_POS
    end
    return api
end

function Library:CreateWindow(opts)
    opts = opts or {}
    -- сбрасываем старые accent-колбэки, чтобы не копились между запусками
    if Library._clearAccentBindings then
        pcall(Library._clearAccentBindings)
    end
    -- отключаем старый меню-коннект
    if _G.__PRIMO_MenuConn then
        pcall(function() _G.__PRIMO_MenuConn:Disconnect() end)
        _G.__PRIMO_MenuConn = nil
    end
    local existing = PlayerGui:FindFirstChild("primo")
    if existing then existing:Destroy() end
    local existingPopups = PlayerGui:FindFirstChild("primo_popups")
    if existingPopups then existingPopups:Destroy() end
    local screen = create("ScreenGui", {Name="primo", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true,
        DisplayOrder=900}, PlayerGui)

    -- реестр глобальных коннектов этого окна — рвём их при unload
    _G.__PRIMO_CW_CONNS = _G.__PRIMO_CW_CONNS or {}
    local function cwTrack(conn)
        if conn then table.insert(_G.__PRIMO_CW_CONNS, conn) end
        return conn
    end

    create("Frame", {Name="menu_background",
        BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.5,
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0), Active=false, ZIndex=0}, screen)

    local MAIN_W, MAIN_H = 1320, 740
    local main = create("Frame", {Name="frame", BackgroundColor3=PALETTE.Window,
        Size=UDim2.new(0,MAIN_W,0,MAIN_H),
        Position=UDim2.new(0.5,-MAIN_W/2,0.5,-MAIN_H/2), Active=false, ZIndex=1}, screen)
    corner(main, 12)
    -- ❗ ref на меню: dimmer настроек будет затемнять ТОЛЬКО область меню,
    -- а не весь экран — иначе HUD-элементы нельзя тащить когда попап открыт
    Library._menuFrame = main
    local shadow = create("Frame", {Name="shadow", BackgroundColor3=PALETTE.Shadow,
        BackgroundTransparency=0.5, Size=UDim2.new(1,8,1,8),
        Position=UDim2.new(0,-4,0,-4), ZIndex=-2}, main)
    corner(shadow, 14)
    local _bgGlass = addGlass(main, 0.1, PALETTE.WindowGlass)
    -- animated background gradient
    local _bgGrad = Instance.new("UIGradient")
    _bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, PALETTE.Window),
        ColorSequenceKeypoint.new(0.5, PALETTE.WindowGlass),
        ColorSequenceKeypoint.new(1.0, PALETTE.Window),
    })
    _bgGrad.Rotation = 45
    _bgGrad.Parent = _bgGlass
    local menuVisible = true
    _G.__PRIMO_MENU_OPEN = true
    task.spawn(function()
        local rot = 0
        while _bgGrad and _bgGrad.Parent do
            if menuVisible then
                rot = (rot + 1.2) % 360
                _bgGrad.Rotation = rot
                task.wait(0.066)
            else
                task.wait(0.5)
            end
        end
    end)

    local dragBar = create("Frame", {Name="dragbar", BackgroundTransparency=1,
        Active=true, Size=UDim2.new(1,-40,0,26), Position=UDim2.new(0,0,0,0), ZIndex=50}, main)
    local dragging, dragStart, startPos = false, nil, nil
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = input.Position; startPos = main.Position
    end)
    cwTrack(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        local vp = screen.AbsoluteSize
        local absX = vp.X * startPos.X.Scale + startPos.X.Offset + delta.X
        local absY = vp.Y * startPos.Y.Scale + startPos.Y.Offset + delta.Y
        absX = math.clamp(absX, -MAIN_W + 80, math.max(-MAIN_W + 80, vp.X - 80))
        absY = math.clamp(absY, 0, math.max(0, vp.Y - 40))
        local offX = absX - vp.X * startPos.X.Scale
        local offY = absY - vp.Y * startPos.Y.Scale
        main.Position = UDim2.new(startPos.X.Scale, offX, startPos.Y.Scale, offY)
    end))
    cwTrack(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))

    local watermarkImg = create("ImageLabel", {Name="watermark", BackgroundTransparency=1,
        Image=Library.Settings.MenuImageURL or "rbxassetid://12150333118",
        ImageColor3=Library.Settings.AccentColor:Lerp(Color3.new(1,1,1), 0.5),
        Size=UDim2.new(0,190,0,188), Position=UDim2.new(0,15,0,21), ZIndex=2}, main)
    corner(watermarkImg, 10)
    Library._menuImage = watermarkImg
    registerAccent(function()
        tween(watermarkImg, {ImageColor3 = Library.Settings.AccentColor:Lerp(Color3.new(1,1,1), 0.5)})
    end)

    -- ✨ ambient glow — big picture (group "menu")
    Library._menuImageGlow = addAmbientGlow(watermarkImg, nil, { group = "menu" })
    do
        local checker = create("Frame", {Name="checker",
            BackgroundColor3=PALETTE.Text, BackgroundTransparency=0.88,
            Size=UDim2.new(0,1,1,-20), Position=UDim2.new(0,220,0,10),
            ZIndex=2}, main)
        corner(checker, 1)
        local cg = Instance.new("UIGradient")
        cg.Rotation = 90
        cg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1,   1),
        })
        cg.Parent = checker
    end
    local tabTitle = create("TextLabel", {Name="tabtitle", BackgroundTransparency=1,
        Text="", TextSize=15, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,-238,0,26), Position=UDim2.new(0,226,0,0), ZIndex=2}, main)
    local navHolder = create("Frame", {Name="nav", BackgroundTransparency=1,
        Position=UDim2.new(0,0,0,230), Size=UDim2.new(0,220,0,420), ZIndex=2}, main)
    local content = create("Frame", {Name="content", BackgroundTransparency=1,
        Position=UDim2.new(0,226,0,30), Size=UDim2.new(1,-238,1,-122),
        ZIndex=2, ClipsDescendants=true}, main)
    create("TextLabel", {Name="productname", BackgroundTransparency=1,
        Text="", Visible=false, TextSize=1,
        TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,300,0,19), Position=UDim2.new(0,10,0,MAIN_H-25), ZIndex=2}, main)
    local avatarBox = create("ImageLabel", {Name="avatar", BackgroundColor3=PALETTE.Text,
        Image=Library.Settings.AvatarURL or "rbxassetid://1615907559",
        Size=UDim2.new(0,51,0,47),
        Position=UDim2.new(0,11,0,MAIN_H-83), ZIndex=2}, main)
    Library._avatarBox = avatarBox
    corner(avatarBox, 10)
    avatarBox.BackgroundTransparency = Library.Settings.AvatarBgTransparency or 0

    -- ✨ ambient glow — аватар (group "avatar")
    Library._avatarGlow = addAmbientGlow(avatarBox, nil, { group = "avatar" })

    local avatarGlow = Instance.new("UIStroke")
    avatarGlow.Color = Library.Settings.AccentColor; avatarGlow.Thickness = 2
    avatarGlow.Transparency = Library.Settings.AvatarBorderTransparency or 0.3
    avatarGlow.Parent = avatarBox
    Library._avatarStroke = avatarGlow
    registerAccent(function() tween(avatarGlow, {Color=Library.Settings.AccentColor}) end)
    local profileNameLabel = create("TextLabel", {Name="playername", BackgroundTransparency=1,
        Text=tostring(KEYDATA.Username or ""),
        TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,200,0,18), Position=UDim2.new(1,8,0,2), ZIndex=2}, avatarBox)
    local profileExpiresLabel = create("TextLabel", {Name="expires", BackgroundTransparency=1,
        Text="expires: "..tostring(KEYDATA.Expires or "never"),
        TextSize=13, TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,200,0,18), Position=UDim2.new(1,8,0,22), ZIndex=2}, avatarBox)
    local profileUidLabel = create("TextLabel", {Name="uid", BackgroundTransparency=1,
        Text="UID: "..tostring(KEYDATA.UID or "0"),
        TextSize=13, TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
        TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,200,0,18), Position=UDim2.new(1,8,0,40), ZIndex=2}, avatarBox)

    -- ── profile gradient (nickname / uid / expires) ──
    local profileGradName    = Instance.new("UIGradient")
    profileGradName.Name = "ProfileGrad"; profileGradName.Enabled = false
    profileGradName.Parent = profileNameLabel

    local profileGradUid     = Instance.new("UIGradient")
    profileGradUid.Name = "ProfileGrad"; profileGradUid.Enabled = false
    profileGradUid.Parent = profileUidLabel

    local profileGradExpires = Instance.new("UIGradient")
    profileGradExpires.Name = "ProfileGrad"; profileGradExpires.Enabled = false
    profileGradExpires.Parent = profileExpiresLabel

    local HS_X, HS_Y, HS_W, HS_H = 230, MAIN_H - 65, MAIN_W - 240, 20
    local hscrollHolder = create("Frame", {Name="hscroll_holder",
        BackgroundColor3=PALETTE.Panel, BackgroundTransparency=0.15,
        Size=UDim2.new(0,HS_W,0,HS_H), Position=UDim2.new(0,HS_X,0,HS_Y),
        ZIndex=30, Visible=false}, main)
    corner(hscrollHolder, 6)
    local hsTrack = create("Frame", {Name="track", BackgroundColor3=PALETTE.Element,
        Size=UDim2.new(1,-12,0,8), Position=UDim2.new(0,6,0.5,-4)}, hscrollHolder)
    corner(hsTrack, 4)
    local hsFill = create("Frame", {Name="fill", BackgroundColor3=Library.Settings.AccentColor,
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,0,0,0)}, hsTrack)
    corner(hsFill, 4)
    registerAccent(function() tween(hsFill, {BackgroundColor3=Library.Settings.AccentColor}, 0.2) end)
    local currentHorizontalTab = nil
    local draggingHS = false
    local function getHSContainer()
        if currentHorizontalTab and currentHorizontalTab.Container then
            return currentHorizontalTab.Container
        end
    end
    local function refreshHS()
        local container = getHSContainer()
        if not container then return end
        local canvasX = math.max(container.AbsoluteCanvasSize.X, 1)
        local viewX = math.max(container.AbsoluteSize.X, 1)
        local maxScroll = math.max(0, canvasX - viewX)
        local visibleRatio = math.clamp(viewX/canvasX, 0.05, 1)
        local rel = 0
        if maxScroll > 0 then rel = math.clamp(container.CanvasPosition.X/maxScroll, 0, 1) end
        hsFill.Size = UDim2.new(visibleRatio, 0, 1, 0)
        hsFill.Position = UDim2.new(rel*(1-visibleRatio), 0, 0, 0)
    end
    local function updateFromX(x)
        local container = getHSContainer()
        if not container then return end
        local canvasX = math.max(container.AbsoluteCanvasSize.X, 1)
        local viewX = math.max(container.AbsoluteSize.X, 1)
        local maxScroll = math.max(0, canvasX - viewX)
        if maxScroll <= 0 then return end
        local trackX = hsTrack.AbsolutePosition.X
        local trackW = math.max(hsTrack.AbsoluteSize.X, 1)
        local rel = math.clamp((x-trackX)/trackW, 0, 1)
        container.CanvasPosition = Vector2.new(rel*maxScroll, container.CanvasPosition.Y)
    end
    hsTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingHS = true; updateFromX(input.Position.X)
        end
    end)
    cwTrack(UserInputService.InputChanged:Connect(function(input)
        if draggingHS and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end))
    cwTrack(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then draggingHS = false end
    end))

    local window = {}
    window.Frame = main
    window.ScreenGui = screen
    window.Tabs = {}
    window.ActiveTab = nil
    function window:SetScale(scale)
        scale = math.clamp(scale, 0.5, 2.0)
        local s = main:FindFirstChildOfClass("UIScale")
        if not s then
            s = Instance.new("UIScale")
            s.Parent = main
        end
        s.Scale = scale
    end
    function window:SetOpacity(v)
        v = math.clamp(tonumber(v) or 1, 0.3, 1.0)
        Library.Settings.MenuOpacity = v
        local t = 1 - v
        main.BackgroundTransparency = t
        local glass = main:FindFirstChild("glass")
        if glass and glass:IsA("Frame") then
            glass.BackgroundTransparency = math.clamp(t + 0.1, 0, 1)
        end
        local shadow = main:FindFirstChild("shadow")
        if shadow then shadow.BackgroundTransparency = math.clamp(0.5 + t * 0.4, 0, 1) end
    end
    function window:SelectTab(tab)
        if not tab then return end
        for _, t in ipairs(self.Tabs) do
            t.Container.Visible = (t == tab)
            t.Button:SetAttribute("active", t == tab)
            t.Refresh()
        end
        self.ActiveTab = tab
        tabTitle.Text = tab.Title
        if tab.Horizontal then
            currentHorizontalTab = tab
            hscrollHolder.Visible = true
            task.defer(refreshHS); task.delay(0.1, refreshHS)
        else
            currentHorizontalTab = nil
            hscrollHolder.Visible = false
        end
    end
    function window:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tab = {Name=tabOpts.Name or "tab",
            Title=tabOpts.Title or ("- " .. (tabOpts.Name or "tab") .. " tab -"),
            Horizontal=tabOpts.Horizontal or false}
        local index = #self.Tabs
        local btn = create("TextButton", {Name=tab.Name, AutoButtonColor=false,
            Text=tab.Name, TextSize=15, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundTransparency=1, Size=UDim2.new(0,212,0,36),
            Position=UDim2.new(0,4,0,index*40),
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=3}, navHolder)
        btn:SetAttribute("active", false)
        btn:SetAttribute("hovered", false)
        local indicator = create("Frame", {Name="indicator",
            BackgroundColor3=Library.Settings.AccentColor, BackgroundTransparency=1,
            Size=UDim2.new(0,4,0,36), Position=UDim2.new(0,0,0,0)}, btn)
        corner(indicator, 2)
        registerAccent(function() tween(indicator, {BackgroundColor3=Library.Settings.AccentColor}) end)
        local function refresh()
            local active = btn:GetAttribute("active")
            local hovered = btn:GetAttribute("hovered")
            local color
            if active then
                color = Library.Settings.AccentColor
                tween(indicator, {BackgroundTransparency=0.3})
            elseif hovered then
                color = Library.Settings.AccentColor:Lerp(PALETTE.Text, 0.5)
                tween(indicator, {BackgroundTransparency=0.7})
            else
                color = PALETTE.Text
                tween(indicator, {BackgroundTransparency=1})
            end
            tween(btn, {TextColor3=color})
        end
        btn.MouseEnter:Connect(function() btn:SetAttribute("hovered", true); refresh() end)
        btn.MouseLeave:Connect(function() btn:SetAttribute("hovered", false); refresh() end)
        btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
        registerAccent(refresh); refresh()
        local scrollMode = Enum.ScrollingDirection.Y
        if tabOpts.Horizontal then scrollMode = Enum.ScrollingDirection.XY end
        local canvasSize = UDim2.new(0,0,0,0)
        if tabOpts.Horizontal then
            canvasSize = UDim2.new(0, tabOpts.CanvasWidth or 1000, 0, 0)
        end
        local scrollBarThickness = 3
        if tabOpts.Horizontal then scrollBarThickness = 0 end
        local container = create("ScrollingFrame", {Name=tab.Name .. "_container",
            BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Visible=false,
            BorderSizePixel=0, ScrollBarThickness=scrollBarThickness,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            ScrollBarImageTransparency=0.5, ScrollingDirection=scrollMode,
            CanvasSize=canvasSize,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable, ZIndex=2}, content)
        registerAccent(function()
            tween(container, {ScrollBarImageColor3=Library.Settings.AccentColor}, 0.2)
        end)
        tab.Button = btn
        tab.Container = container
        tab.Refresh = refresh
        function tab:CreateSection(secOpts) return buildSection(container, secOpts or {}) end
        if tabOpts.Horizontal then
            container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                if currentHorizontalTab == tab then refreshHS() end
            end)
            container:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
                if currentHorizontalTab == tab then refreshHS() end
            end)
            container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if currentHorizontalTab == tab then refreshHS() end
            end)
        end
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then
            self:SelectTab(tab)
        end
        -- если активная вкладка горизонтальная — сразу показываем полоску
        if self.ActiveTab and self.ActiveTab.Horizontal then
            hscrollHolder.Visible = true
            task.defer(refreshHS)
            task.delay(0.1, refreshHS)
        end
        return tab
    end
    local menuVisible = true

    -- ═══════════════════════════════════════════════════════════
    -- MENU CURSOR (без вмешательства в камеру)
    -- при открытом меню:
    --   • курсор свободен и кликабелен
    --   • шифтлок отключён (камера не крутится от мыши)
    -- камера остаётся там, где её поставила игра
    -- ═══════════════════════════════════════════════════════════
    local _menuMouse = {
        active         = false,
        savedBehavior  = nil,
        savedIcon      = nil,
        savedCameraMode    = nil,
        savedDevEnableLock = nil,
        _menuLP        = Players.LocalPlayer,
    }

    local function _applyMenuCamState()
        local lp = _menuMouse._menuLP
        if menuVisible then
            if _menuMouse.active then return end
            _menuMouse.active = true

            _menuMouse.savedBehavior = UserInputService.MouseBehavior
            _menuMouse.savedIcon     = UserInputService.MouseIconEnabled
            if _menuMouse.savedIcon == false then _menuMouse.savedIcon = true end

            if lp then
                pcall(function() _menuMouse.savedCameraMode    = lp.CameraMode end)
                pcall(function() _menuMouse.savedDevEnableLock = lp.DevEnableMouseLock end)
                -- вырубаем шифтлок, чтобы камера не крутилась от движения мыши
                pcall(function() lp.CameraMode        = Enum.CameraMode.Classic end)
                pcall(function() lp.DevEnableMouseLock = false end)
            end

            pcall(function() UserInputService.MouseBehavior    = Enum.MouseBehavior.Default end)
            pcall(function() UserInputService.MouseIconEnabled = true end)
        else
            if not _menuMouse.active then return end
            _menuMouse.active = false

            if _menuMouse.savedBehavior ~= nil then
                pcall(function() UserInputService.MouseBehavior = _menuMouse.savedBehavior end)
                _menuMouse.savedBehavior = nil
            end
            if _menuMouse.savedIcon ~= nil then
                pcall(function() UserInputService.MouseIconEnabled = _menuMouse.savedIcon end)
                _menuMouse.savedIcon = nil
            end
            if lp then
                if _menuMouse.savedCameraMode ~= nil then
                    pcall(function() lp.CameraMode = _menuMouse.savedCameraMode end)
                    _menuMouse.savedCameraMode = nil
                end
                if _menuMouse.savedDevEnableLock ~= nil then
                    pcall(function() lp.DevEnableMouseLock = _menuMouse.savedDevEnableLock end)
                    _menuMouse.savedDevEnableLock = nil
                end
            end
        end
    end
    _G.__PRIMO_MENU_MOUSE_UPDATE = _applyMenuCamState



    local _menuInputConns = {}


    local function setMenuVisible(v)
        local wasVisible = menuVisible
        menuVisible = v and true or false
        _G.__PRIMO_MENU_OPEN = menuVisible
        screen.Enabled = menuVisible
        local popupScreen = PlayerGui:FindFirstChild("primo_popups")
        if popupScreen then popupScreen.Enabled = menuVisible end
        -- HUD НЕ трогаем — ими управляют свои свитчи в settings -> hud/screens

        -- pop-in animation when opening
        if menuVisible and not wasVisible and main then
            local existing = main:FindFirstChildOfClass("UIScale")
            local target = 1
            if existing then target = existing.Scale end
            if not existing then
                existing = Instance.new("UIScale"); existing.Parent = main
            end
            existing.Scale = target * 0.92
            main.BackgroundTransparency = 0.25
            task.spawn(function()
                TweenService:Create(existing,
                    TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {Scale = target}):Play()
                TweenService:Create(main, TweenInfo.new(0.22),
                    {BackgroundTransparency = 0}):Play()
            end)
        end

        -- камера/курсор при открытом меню
        _applyMenuCamState()
    end

    -- при первом запуске меню открыто → сразу готовим камеру/курсор
    task.defer(_applyMenuCamState)
    _G.__PRIMO_MenuConn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if UserInputService:GetFocusedTextBox() then return end
        local currentKey = Library.Settings.MenuKey
        if typeof(currentKey) == "EnumItem" then
            local match = false
            if currentKey.EnumType == Enum.KeyCode then
                match = (input.KeyCode == currentKey)
            elseif currentKey.EnumType == Enum.UserInputType then
                match = (input.UserInputType == currentKey)
            end
            if match and not _G.__PRIMO_BIND_LISTENING then
                setMenuVisible(not menuVisible)
                return
            end
        end
        if input.KeyCode == Enum.KeyCode.Escape and menuVisible then
            if _G.__PRIMO_BIND_LISTENING then return end
            setMenuVisible(false)
        end
    end)
window.SetMenuVisible = setMenuVisible
window.IsMenuVisible = function() return menuVisible end
window._menuInputConns = _menuInputConns   -- FIX: выставляем наружу для cleanup

    -- ── close button (×) top-right ──
    do
        local closeMenuBtn = create("TextButton", {Name="menuClose", AutoButtonColor=false,
            Text="×", TextSize=22, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.55,
            Size=UDim2.new(0,28,0,22), Position=UDim2.new(1,-34,0,2), ZIndex=60}, main)
        corner(closeMenuBtn, 6)
        closeMenuBtn.MouseEnter:Connect(function()
            tween(closeMenuBtn, {TextColor3=PALETTE.Warn, BackgroundTransparency=0.15})
        end)
        closeMenuBtn.MouseLeave:Connect(function()
            tween(closeMenuBtn, {TextColor3=PALETTE.TextDim, BackgroundTransparency=0.55})
        end)
        closeMenuBtn.MouseButton1Click:Connect(function()
            setMenuVisible(false)
        end)
    end

    -- ── menu footer: fps + clock + version ──
    do
        local footer = create("TextLabel", {Name="menufooter",
            BackgroundTransparency=1, Text="", TextSize=11,
            TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
            TextXAlignment=Enum.TextXAlignment.Right,
            Size=UDim2.new(0,320,0,14),
            Position=UDim2.new(1,-332,0,MAIN_H-18), ZIndex=5}, main)

        local frames, lastFpsCalc, fps = 0, tick(), 60
        local _footerConn = RunService.RenderStepped:Connect(function()
            if not menuVisible then return end
            frames = frames + 1
            local now = tick()
            if now - lastFpsCalc >= 0.5 then
                fps = math.floor(frames / (now - lastFpsCalc) + 0.5)
                frames = 0
                lastFpsCalc = now
                local t = os.date("*t")
                footer.Text = string.format("fps %d  ·  %02d:%02d:%02d  ·  hysteria v%s",
                    fps, t.hour, t.min, t.sec, Library.Version or "?")
            end
        end)
        main.Destroying:Connect(function()
            pcall(function() _footerConn:Disconnect() end)
        end)
    end

    window._profileLabels = {
        name        = profileNameLabel,
        uid         = profileUidLabel,
        expires     = profileExpiresLabel,
        gradName    = profileGradName,
        gradUid     = profileGradUid,
        gradExpires = profileGradExpires,
    }

    -- ═══════════════════════════════════════════════════════════
    -- PROFILE PRESETS  (classic / experimental)
    -- ═══════════════════════════════════════════════════════════
    -- classic      : то что было всегда — маленький квадрат слева,
    --                3 строки текста, тонкая рамка.
    -- experimental : «премиум» — увеличенный аватар, круглый
    --                угол больше, жирная акцентная рамка, плюс
    --                подложка-пилюля за текстом (в цвет палитры),
    --                чуть больше воздуха между строками.
    -- Применяется в любой момент (и из UI, и из конфига).
    window.SetProfilePreset = function(presetName)
        presetName = tostring(presetName or "classic")
        Library.Settings.ProfilePreset = presetName

        local avCorner = avatarBox:FindFirstChildOfClass("UICorner")
        -- фон-пилюля за текстом живёт под именем avatarBox с именем "labelBg"
        local labelBg = avatarBox:FindFirstChild("labelBg")

        if presetName == "experimental" then
            -- ── аватар ──
            avatarBox.Size     = UDim2.new(0, 60, 0, 54)
            avatarBox.Position = UDim2.new(0, 12, 0, MAIN_H - 88)
            avatarBox.ZIndex   = 2

            if avCorner then avCorner.CornerRadius = UDim.new(0, 16) end
            if avatarGlow then
                avatarGlow.Thickness    = 2.5
                avatarGlow.Transparency = 0.15
            end

            -- ── пилюля-фон под текстом ──
            if not labelBg then
                labelBg = create("Frame", {Name="labelBg",
                    BackgroundColor3=PALETTE.PanelGlass,
                    BackgroundTransparency=0.15,
                    BorderSizePixel=0,
                    Size=UDim2.new(0, 218, 0, 54),
                    Position=UDim2.new(1, 6, 0, 0),
                    ZIndex=1}, avatarBox)
                corner(labelBg, 14)
            end
            labelBg.Visible = true
            labelBg.Size    = UDim2.new(0, 218, 0, 54)
            labelBg.Position= UDim2.new(1, 6, 0, 0)
            labelBg.BackgroundColor3 = PALETTE.PanelGlass

            -- ── лейблы ──
            profileNameLabel.TextSize = 15
            profileNameLabel.Position = UDim2.new(1, 16, 0, 3)
            profileNameLabel.Size     = UDim2.new(0, 200, 0, 20)
            profileNameLabel.ZIndex   = 3

            profileExpiresLabel.TextSize = 12
            profileExpiresLabel.Position = UDim2.new(1, 16, 0, 24)
            profileExpiresLabel.Size     = UDim2.new(0, 200, 0, 16)
            profileExpiresLabel.ZIndex   = 3

            profileUidLabel.TextSize = 12
            profileUidLabel.Position = UDim2.new(1, 16, 0, 41)
            profileUidLabel.Size     = UDim2.new(0, 200, 0, 16)
            profileUidLabel.ZIndex   = 3
        else
            -- ── аватар (classic) ──
            avatarBox.Size     = UDim2.new(0, 51, 0, 47)
            avatarBox.Position = UDim2.new(0, 11, 0, MAIN_H - 83)

            if avCorner then avCorner.CornerRadius = UDim.new(0, 10) end
            if avatarGlow then
                avatarGlow.Thickness    = 2
                avatarGlow.Transparency = 0.3
            end

            -- ── пилюля выключена ──
            if labelBg then labelBg.Visible = false end

            -- ── лейблы (classic) ──
            profileNameLabel.TextSize = 14
            profileNameLabel.Position = UDim2.new(1, 8, 0, 2)
            profileNameLabel.Size     = UDim2.new(0, 200, 0, 18)

            profileExpiresLabel.TextSize = 13
            profileExpiresLabel.Position = UDim2.new(1, 8, 0, 22)
            profileExpiresLabel.Size     = UDim2.new(0, 200, 0, 18)

            profileUidLabel.TextSize = 13
            profileUidLabel.Position = UDim2.new(1, 8, 0, 40)
            profileUidLabel.Size     = UDim2.new(0, 200, 0, 18)
        end
    end

    -- ═══════════════════════════════════════════════════════════
    -- MENU STYLE  (classic / experimental)
    -- ═══════════════════════════════════════════════════════════
    -- classic      : всё как было — углы 6-12, стекло лёгкое, тени умеренные
    -- experimental : углы +5 (до 20), мягкие тени, усиленное стекло,
    --                тонкая акцентная обводка на главном окне.
    -- Работает на живом окне — переключается без перезагрузки.
    window.SetMenuStyle = function(styleName)
        styleName = tostring(styleName or "classic")
        Library.Settings.MenuStyle = styleName
        local isExp = (styleName == "experimental")

        -- 1) corner-радиусы всех элементов внутри main
        for _, obj in ipairs(main:GetDescendants()) do
            if obj:IsA("GuiObject") then
                local uc = obj:FindFirstChildOfClass("UICorner")
                if uc then
                    if not obj:GetAttribute("__primoOrigCorner") then
                        obj:SetAttribute("__primoOrigCorner", uc.CornerRadius.Offset)
                    end
                    local orig = obj:GetAttribute("__primoOrigCorner") or uc.CornerRadius.Offset
                    if orig >= 4 then
                        uc.CornerRadius = UDim.new(0, isExp and math.min(orig + 5, 20) or orig)
                    end
                end
            end
        end

        -- 2) главное окно
        local mc = main:FindFirstChildOfClass("UICorner")
        if mc then
            if not main:GetAttribute("__primoOrigMainCorner") then
                main:SetAttribute("__primoOrigMainCorner", mc.CornerRadius.Offset)
            end
            local orig = main:GetAttribute("__primoOrigMainCorner") or 12
            mc.CornerRadius = UDim.new(0, isExp and 18 or orig)
        end

        -- 3) тень
        local sh = main:FindFirstChild("shadow")
        if sh then
            local sc = sh:FindFirstChildOfClass("UICorner")
            if sc then
                if not sh:GetAttribute("__primoOrigShadowCorner") then
                    sh:SetAttribute("__primoOrigShadowCorner", sc.CornerRadius.Offset)
                end
                local o = sh:GetAttribute("__primoOrigShadowCorner") or 14
                sc.CornerRadius = UDim.new(0, isExp and 24 or o)
            end
            if not sh:GetAttribute("__primoOrigShadowTr") then
                sh:SetAttribute("__primoOrigShadowTr", sh.BackgroundTransparency)
            end
            local oTr = sh:GetAttribute("__primoOrigShadowTr") or 0.5
            sh.BackgroundTransparency = isExp and math.max(oTr - 0.15, 0.15) or oTr
        end

        -- 4) стекло
        local glass = main:FindFirstChild("glass")
        if glass and glass:IsA("Frame") then
            if not glass:GetAttribute("__primoOrigGlassTr") then
                glass:SetAttribute("__primoOrigGlassTr", glass.BackgroundTransparency)
            end
            local oG = glass:GetAttribute("__primoOrigGlassTr") or 0.1
            glass.BackgroundTransparency = isExp and math.max(oG - 0.05, 0.04) or oG
        end

        -- 5) акцентная обводка главного окна
        local glowStroke = main:FindFirstChild("__primoMenuGlow")
        if isExp then
            if not glowStroke then
                glowStroke = Instance.new("UIStroke")
                glowStroke.Name = "__primoMenuGlow"
                glowStroke.Color = Library.Settings.AccentColor
                glowStroke.Thickness = 1.5
                glowStroke.Transparency = 0.45
                glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                glowStroke.Parent = main
                registerAccent(function()
                    if glowStroke and glowStroke.Parent then
                        tween(glowStroke, {Color = Library.Settings.AccentColor})
                    end
                end)
            else
                glowStroke.Visible = true
            end
        elseif glowStroke then
            glowStroke.Visible = false
        end
    end

    window.Watermark = buildWatermark()
    window.Keybinds = buildKeybindsList()
    window.TargetList = buildTargetList()
    window.TargetESP = window.TargetList
    window.Picture = buildPictureHUD()

    -- ❗ реестр HUD-фреймов: клики по ним не закрывают settings-попап
    _G.__PRIMO_HUD_FRAMES = _G.__PRIMO_HUD_FRAMES or {}
    local function _regHud(api)
        if api and api.GetFrame then
            local ok, f = pcall(function() return api:GetFrame() end)
            if ok and f then
                table.insert(_G.__PRIMO_HUD_FRAMES, f)
            end
        end
    end
    _regHud(window.Watermark)
    _regHud(window.Keybinds)
    _regHud(window.TargetList)
    _regHud(window.Picture)

    return window
end

-- late UIB exports (helpers defined above in this do-block)
UIB.resolveSeq       = resolveSeq
UIB.resolvePulseSeq  = resolvePulseSeq
UIB.getFontByName    = getFontByName
UIB.FONT_NAMES       = FONT_NAMES
UIB.registerAccent   = registerAccent
UIB.refreshAccent    = refreshAccent
UIB.UserInputService = UserInputService
UIB.TweenService     = TweenService
UIB.RunService       = RunService
UIB.Players          = Players
UIB.PlayerGui        = PlayerGui
UIB.LocalPlayer      = LocalPlayer
end
_runPart("PART1/UIB", _part1_UIB)

local function _part2_Config()
local CONTROLS = {}
_G.__PRIMO_CONTROLS = CONTROLS
local HttpService = game:GetService("HttpService")

local HAS_FILE_API =
    (typeof(writefile) == "function") and (typeof(readfile) == "function")
    and (typeof(isfile) == "function") and (typeof(listfiles) == "function")
    and (typeof(makefolder) == "function") and (typeof(isfolder) == "function")
    and (typeof(delfile) == "function")

reg = function(sect, method, path, opts)
    local ok, ctrl = pcall(function() return sect[method](sect, opts) end)
    if not ok or not ctrl then return nil end
    if ctrl.IsPersistable and not ctrl:IsPersistable() then return ctrl end
    CONTROLS[path] = ctrl
    -- ❗ запоминаем default каждого контрола — нужно для reset config settings
    if opts then
        _G.__PRIMO_DEFAULTS = _G.__PRIMO_DEFAULTS or {}
        if opts.Default ~= nil then
            _G.__PRIMO_DEFAULTS[path] = opts.Default
        elseif method == "Cycle" and opts.Values and opts.Index then
            _G.__PRIMO_DEFAULTS[path] = opts.Values[opts.Index]
        end
    end
    return ctrl
end

local function ser(v)
    local t = type(v)
    if t == "number" or t == "string" or t == "boolean" then return v end
    if typeof(v) == "Color3" then return {__t="c3", R=v.R, G=v.G, B=v.B} end
    if typeof(v) == "EnumItem" then
        return {__t="enum", et=tostring(v.EnumType), n=v.Name}
    end
    if t == "table" then
        local arr, dict = {}, {}
        local hasArr, hasDict = false, false
        -- array part
        for i, x in ipairs(v) do
            arr[i] = ser(x); hasArr = true
        end
        -- dict part (все ключи, включая строковые и "дырки" в массиве)
        for k, x in pairs(v) do
            local isArrayKey = (type(k) == "number" and k >= 1 and k % 1 == 0 and k <= #arr)
            if not isArrayKey then
                local sk = tostring(k)
                dict[sk] = ser(x)
                hasDict = true
            end
        end
        local o = {__t="tbl"}
        if hasArr  then o.arr  = arr  end
        if hasDict then o.dict = dict end
        return o
    end
    return nil
end
local function deser(v)
    if type(v) ~= "table" then return v end
    if v.__t == "c3" then return Color3.new(v.R, v.G, v.B) end
    if v.__t == "enum" then
        if type(v.et) ~= "string" or type(v.n) ~= "string" then return nil end
        local etName = v.et:gsub("^Enum%.", "")
        local et = Enum[etName]
        if et then
            local ok, item = pcall(function() return et[v.n] end)
            if ok then return item end
        end
        return nil
    end
    if v.__t == "tbl" then
        local o = {}
        -- новый формат
        if type(v.arr) == "table" then
            for i, x in ipairs(v.arr) do o[i] = deser(x) end
        end
        if type(v.dict) == "table" then
            for k, x in pairs(v.dict) do
                -- восстановить числовой ключ если был числом
                local nk = tonumber(k)
                if nk and tostring(nk) == k then o[nk] = deser(x) else o[k] = deser(x) end
            end
        end
        -- legacy-формат {__t="tbl", v={...}} — обратная совместимость
        if type(v.v) == "table" then
            for i, x in ipairs(v.v) do o[i] = deser(x) end
        end
        return o
    end
    return v
end

local function ensureFolder()
    if not HAS_FILE_API then return end
    local ok, isF = pcall(isfolder, "hysteria_configs_blyat")
    if not ok or not isF then pcall(makefolder, "hysteria_configs_blyat") end
end
local function cfgPath(n) return "hysteria_configs_blyat/" .. n .. ".json" end
local function bakPath(n) return "hysteria_configs_blyat/" .. n .. ".json.bak" end

-- Атомарная запись: пишем в .tmp, бэкапим старый, потом заменяем.
-- Так при краше не остаётся половинчатый JSON.
local function safeWriteConfig(path, bak, data)
    if not HAS_FILE_API then return false end
    -- backup существующего
    if isfile(path) then
        pcall(function()
            local old = readfile(path)
            if old then
                if isfile(bak) then pcall(delfile, bak) end
                writefile(bak, old)
            end
        end)
    end
    -- пишем напрямую (tmp-цепочка ненадёжна на некоторых экзекуторах)
    local ok = pcall(writefile, path, data)
    if not ok then return false end
    -- верификация: файл реально появился и непустой
    local exists = pcall(isfile, path) and isfile(path)
    if not exists then return false end
    local check = readfile(path)
    if not check or #check == 0 then return false end
    return true
end

ConfigSystem = {}
ConfigSystem.Configs = {}
ConfigSystem.Current = nil
ConfigSystem.Folder = "hysteria_configs_blyat"

-- ── резервные имена, которые НЕ являются конфигами ──
local _RESERVED_CONFIG_NAMES = {
    whitelist = true,
    trashtalk = true,
    themes    = true,
}

local function _extractConfigName(fullPath)
    if type(fullPath) ~= "string" or fullPath == "" then return nil end
    local norm = fullPath:gsub("\\", "/")
    -- берём только последний сегмент пути (имя файла)
    local fname = norm:match("([^/]+)$") or norm
    -- имя файла должно быть <name>.json (НЕ .json.bak)
    local name = fname:match("^([^/]+)%.json$")
    if not name then return nil end
    if _RESERVED_CONFIG_NAMES[name:lower()] then return nil end
    return name
end

local BIND_SUFFIX = "|BIND"
function ConfigSystem:Collect()
    local out = {}
    for path, ctrl in pairs(CONTROLS) do
        if ctrl and type(ctrl.Get) == "function" then
            local ok, v = pcall(function() return ctrl:Get() end)
            if ok then
                local sv = ser(v)
                if sv ~= nil then out[path] = sv end
            end
            -- also persist the keybind for ToggleBindRow controls
            if type(ctrl.GetBind) == "function" then
                local okb, bv = pcall(function() return ctrl:GetBind() end)
                if okb then
                    local sbv = ser(bv)
                    if sbv ~= nil then out[path .. BIND_SUFFIX] = sbv end
                end
            end
        end
    end
    return out
end
function ConfigSystem:Apply(cfg)
    if not cfg then return 0 end
    local count = 0
    local sLen = #BIND_SUFFIX
    for path, v in pairs(cfg) do
        local bindPath = nil
        if path:sub(-sLen) == BIND_SUFFIX then
            bindPath = path:sub(1, -sLen - 1)
        end
        if bindPath then
            local ctrl = CONTROLS[bindPath]
            if ctrl and type(ctrl.SetBind) == "function" then
                local dv = deser(v)
                pcall(function() ctrl:SetBind(dv, false) end)
                count = count + 1
            end
        else
            local ctrl = CONTROLS[path]
            if ctrl and type(ctrl.Set) == "function" then
                local dv = deser(v)
                if dv ~= nil then
                    pcall(function() ctrl:Set(dv, false) end)
                    count = count + 1
                end
            end
        end
    end
    -- post-load: применяем зависимые настройки (тема/аватар) ещё раз,
    -- чтобы не зависеть от неопределённого порядка pairs()
    if _G.__PRIMO_POSTLOAD then pcall(_G.__PRIMO_POSTLOAD) end
    return count
end
function ConfigSystem:Save(name)
    if not name or name == "" then return false, "no name" end
    local clean = name:gsub("[^%w_%-%. ]", "_")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then return false, "invalid name" end
    name = clean
    local cfg = self:Collect()
    local okEnc, json = pcall(function() return HttpService:JSONEncode(cfg) end)
    if not okEnc or type(json) ~= "string" then
        warn("[hysteria] config save: encode failed")
        return false, "encode failed"
    end
    local okDec, dec = pcall(function() return HttpService:JSONDecode(json) end)
    if not okDec or type(dec) ~= "table" then
        warn("[hysteria] config save: decode validate failed")
        return false, "serialization failed"
    end
    self.Configs[name] = cfg
    self.Current = name
    if HAS_FILE_API then
        ensureFolder()
        local ok = safeWriteConfig(cfgPath(name), bakPath(name), json)
        if not ok then
            warn("[hysteria] config save: writefile failed for "..cfgPath(name))
            return false, "write failed"
        end
    else
        warn("[hysteria] config save: NO FILE API - config only in memory")
    end
    return true, name
end
function ConfigSystem:Load(name)
    if not name or name == "" then return false, "no name" end
    name = name:gsub("[^%w_%-%. ]", "_"):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false, "invalid name" end
    local cfg = self.Configs[name]
    if not cfg and HAS_FILE_API then
        local okf, exists = pcall(isfile, cfgPath(name))
        if okf and exists then
            local ok, data = pcall(readfile, cfgPath(name))
            if ok and data then
                local ok2, dec = pcall(function() return HttpService:JSONDecode(data) end)
                if ok2 and type(dec) == "table" then
                    cfg = dec
                    self.Configs[name] = cfg
                end
            end
        end
        -- fallback: если основной файл битый — пробуем бэкап
        if not cfg then
            local okb, exists = pcall(isfile, bakPath(name))
            if okb and exists then
                local ok, bdata = pcall(readfile, bakPath(name))
                if ok and bdata then
                    local ok2, dec = pcall(function() return HttpService:JSONDecode(bdata) end)
                    if ok2 and type(dec) == "table" then
                        cfg = dec
                        self.Configs[name] = cfg
                        -- восстанавливаем основной файл из бэкапа
                        pcall(function() writefile(cfgPath(name), bdata) end)
                    end
                end
            end
        end
    end
    if not cfg then return false, "not found" end
    self:Apply(cfg)
    self.Current = name
    return true, name
end
function ConfigSystem:Override()
    if not self.Current then return false, "no current" end
    return self:Save(self.Current)
end
function ConfigSystem:Refresh()
    if not HAS_FILE_API then return true end
    if type(self.Configs) ~= "table" then self.Configs = {} end
    ensureFolder()
    local ok, files = pcall(listfiles, self.Folder)
    if not ok or not files then return false end
    -- merge: не стираем in-memory конфиги, которых нет на диске
    for _, f in ipairs(files) do
        local base = _extractConfigName(f)
        if base then
            local ok2, data = pcall(readfile, f)
            if ok2 and data then
                local ok3, dec = pcall(function() return HttpService:JSONDecode(data) end)
                if ok3 and type(dec) == "table" then
                    self.Configs[base] = dec
                end
            end
        end
    end
    return true
end
function ConfigSystem:Delete(name)
    if not name or name == "" then return false end
    self.Configs[name] = nil
    if self.Current == name then self.Current = nil end
    if HAS_FILE_API then
        pcall(function()
            if isfile(cfgPath(name)) then delfile(cfgPath(name)) end
            if isfile(bakPath(name)) then delfile(bakPath(name)) end
        end)
    end
    return true
end
function ConfigSystem:DeleteAll(confirmed)
    if confirmed ~= true then return false, "not confirmed" end
    for _, name in ipairs(self:List()) do
        self.Configs[name] = nil
    end
    if HAS_FILE_API then
        local ok, files = pcall(listfiles, self.Folder)
        if ok and files then
            for _, f in ipairs(files) do
                -- удаляем ТОЛЬКО top-level <name>.json и <name>.json.bak
                -- в primo_configs/; темы, whitelist, trashtalk — НЕ трогаем
                local base = _extractConfigName(f)
                if base then
                    pcall(delfile, f)
                    -- и .bak рядом
                    local bak = f .. ".bak"
                    if isfile(bak) then pcall(delfile, bak) end
                end
            end
        end
    end
    self.Configs = {}
    self.Current = nil
    return true
end
function ConfigSystem:List()
    local names, seen = {}, {}
    -- 1) in-memory: тоже фильтруем служебные
    for n in pairs(self.Configs) do
        if not _RESERVED_CONFIG_NAMES[n:lower()] then
            if not seen[n] then seen[n] = true; table.insert(names, n) end
        end
    end
    -- 2) с диска: только верхнеуровневые <name>.json в primo_configs/
    if HAS_FILE_API then
        local ok, files = pcall(listfiles, self.Folder)
        if ok and files then
            for _, f in ipairs(files) do
                local base = _extractConfigName(f)
                if base and not seen[base] then
                    seen[base] = true
                    table.insert(names, base)
                end
            end
        end
    end
    table.sort(names)
    return names
end

-- ❗ глобальная функция: сбрасывает все настройки к Default-значениям,
-- которые были переданы при reg(). Не трогает сохранённые конфиги.
_G.__PRIMO_RESET_DEFAULTS = function()
    local D = _G.__PRIMO_DEFAULTS or {}
    local count = 0
    for path, ctrl in pairs(CONTROLS) do
        if ctrl and type(ctrl.Set) == "function" and D[path] ~= nil then
            local ok = pcall(function() ctrl:Set(D[path], false) end)
            if ok then count = count + 1 end
        end
    end
    return count
end
end
_runPart("PART2/Config", _part2_Config)

local function _part3_Internal()
local PREFIX = "primo_internal_"
local FOV_REF_H = 1080
local HS_POOL = 16
local KS_POOL = 8
local HM_POOL = 24
local GLOW_LAYERS = 6

-- forward declares для do-блоков SilentAim/AutoShoot
local keyHeld, _fireOnce, getAimPart, resolverPredict, aimVisible, isKnocked

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundServiceS = game:GetService("SoundService")
local LightingS = game:GetService("Lighting")
local VirtualUserS = game:GetService("VirtualUser")
local WorkspaceS = game:GetService("Workspace")

local LocalPlayerS = LocalPlayer
local CameraS = WorkspaceS.CurrentCamera
_G.__PRIMO_CamChangedConn = WorkspaceS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    CameraS = WorkspaceS.CurrentCamera or CameraS
end)

local LIGHTING_ORIGINALS = {
    Brightness=LightingS.Brightness, Ambient=LightingS.Ambient,
    OutdoorAmbient=LightingS.OutdoorAmbient, ClockTime=LightingS.ClockTime,
    ExposureCompensation=LightingS.ExposureCompensation,
    GlobalShadows=LightingS.GlobalShadows,
    FogColor=LightingS.FogColor, FogStart=LightingS.FogStart, FogEnd=LightingS.FogEnd,
    EnvironmentDiffuseScale=LightingS.EnvironmentDiffuseScale,
    EnvironmentSpecularScale=LightingS.EnvironmentSpecularScale,
}
local ORIGINAL_ATMOSPHERE = nil
do
    local a = LightingS:FindFirstChildOfClass("Atmosphere")
    if a then
        ORIGINAL_ATMOSPHERE = {
            Color=a.Color, Decay=a.Decay, Density=a.Density,
            Glare=a.Glare, Haze=a.Haze, Offset=a.Offset,
        }
    end
end
local ORIGINAL_SKY = LightingS:FindFirstChildOfClass("Sky")

-- aliases for panic-reset — БЕЗ local, чтобы не жрать регистры
LightingBrightnessOrig  = LIGHTING_ORIGINALS.Brightness
LightingAmbientOrig     = LIGHTING_ORIGINALS.Ambient
LightingOutdoorOrig     = LIGHTING_ORIGINALS.OutdoorAmbient
LightingClockOrig       = LIGHTING_ORIGINALS.ClockTime
LightingExposureOrig    = LIGHTING_ORIGINALS.ExposureCompensation
LightingShadowsOrig     = LIGHTING_ORIGINALS.GlobalShadows
LightingEnvDiffOrig     = LIGHTING_ORIGINALS.EnvironmentDiffuseScale
LightingEnvSpecOrig     = LIGHTING_ORIGINALS.EnvironmentSpecularScale
LightingFogColorOrig    = LIGHTING_ORIGINALS.FogColor
LightingFogStartOrig    = LIGHTING_ORIGINALS.FogStart
LightingFogEndOrig      = LIGHTING_ORIGINALS.FogEnd

local DrawOK, DrawNew = false, nil
do
    local ok = pcall(function()
        if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then error() end
        if type(Drawing.new) ~= "function" then error() end
        local t = Drawing.new("Square")
        if t == nil then error() end
        if not pcall(function() t.Visible = false end) then error() end
        pcall(function() t:Remove() end)
        DrawNew = Drawing.new
        DrawOK = true
    end)
end

local function isDraw(o)
    if o == nil then return false end
    local t = type(o)
    -- userdata из Drawing.new() всегда валиден, pcall не нужен
    if t == "userdata" then return true end
    if t ~= "table" then return false end
    return pcall(function() local _ = o.Visible end)
end
local function newDraw(cls, props)
    if not DrawOK or not DrawNew then return nil end
    local ok, obj = pcall(DrawNew, cls)
    if not ok or obj == nil then return nil end
    local t = type(obj)
    if t ~= "userdata" and t ~= "table" then return nil end
    if props then
        for k, v in pairs(props) do
            if not pcall(function() obj[k] = v end) then
                local alt
                if k == "Center" then alt = "Centered"
                elseif k == "Outline" then alt = "HasOutline" end
                if alt then pcall(function() obj[alt] = v end) end
            end
        end
    end
    return obj
end
local function dRem(o)
    if o == nil then return end
    local t = type(o)
    if t ~= "userdata" and t ~= "table" then return end
    pcall(function() o:Remove() end)
end

-- ==== WHITELIST / FRIENDS ====
local Whitelist = {
    Names = {},   -- lowercase username -> true
    UIDs = {},    -- tostring(userid) -> true
    Teams = {},   -- lowercase team name -> true (friends)
    NoDrawTeams = {}, -- lowercase team name -> true (skip ESP/aimbot)
    Enabled = true,
}

-- ⚠️ ВАЖНО: объявлено ДО функций, которые это используют
local _wlCache, _noDrawCache = {}, {}
local function _invalidateWLCaches()
    _wlCache = {}
    _noDrawCache = {}
end
local WL_FILE = "hysteria_configs_blyat/whitelist.json"
local WL_HAS_FILE = (typeof(writefile) == "function") and (typeof(readfile) == "function")
    and (typeof(isfile) == "function") and (typeof(makefolder) == "function")
    and (typeof(isfolder) == "function")

-- ⚠️ ФИКС: saveWhitelist был потерян при рефакторинге.
-- без него падают все add/remove функции и кэш никогда не сбрасывается
local function saveWhitelist()
    _invalidateWLCaches()
    if not WL_HAS_FILE then return end
    local okF, isF = pcall(isfolder, "hysteria_configs_blyat")
    if not okF or not isF then pcall(makefolder, "hysteria_configs_blyat") end
    local data = {names = {}, uids = {}, teams = {}, nodraw = {}}
    for k in pairs(Whitelist.Names) do table.insert(data.names, k) end
    for k in pairs(Whitelist.UIDs) do table.insert(data.uids, k) end
    for k in pairs(Whitelist.Teams) do table.insert(data.teams, k) end
    for k in pairs(Whitelist.NoDrawTeams) do table.insert(data.nodraw, k) end
    pcall(writefile, WL_FILE, game:GetService("HttpService"):JSONEncode(data))
end

local function loadWhitelist()
    if not WL_HAS_FILE then return end
    local ok, exists = pcall(isfile, WL_FILE)
    if not ok or not exists then return end
    local ok2, data = pcall(readfile, WL_FILE)
    if not ok2 or not data then return end
    local ok3, dec = pcall(function()
        return game:GetService("HttpService"):JSONDecode(data)
    end)
    if not ok3 or type(dec) ~= "table" then return end
    Whitelist.Names = {}
    Whitelist.UIDs = {}
    Whitelist.Teams = {}
    Whitelist.NoDrawTeams = {}
    for _, n in ipairs(dec.names or {}) do Whitelist.Names[tostring(n):lower()] = true end
    for _, u in ipairs(dec.uids or {}) do Whitelist.UIDs[tostring(u)] = true end
    for _, t in ipairs(dec.teams or {}) do Whitelist.Teams[tostring(t):lower()] = true end
    for _, t in ipairs(dec.nodraw or {}) do Whitelist.NoDrawTeams[tostring(t):lower()] = true end
end
local function isWhitelisted(p)
    if not Whitelist.Enabled then return false end
    if not p then return false end
    local cached = _wlCache[p]
    if cached ~= nil then return cached end
    local name = tostring(p.Name or ""):lower()
    local res = Whitelist.Names[name]
        or Whitelist.UIDs[tostring(p.UserId or "")]
        or (p.Team and Whitelist.Teams[tostring(p.Team.Name):lower()])
    res = res == true
    _wlCache[p] = res
    return res
end
local function addWhitelist(name)
    if not name or name == "" then return false end
    Whitelist.Names[tostring(name):lower()] = true
    saveWhitelist()
    return true
end
local function addWhitelistUID(uid)
    if not uid then return false end
    Whitelist.UIDs[tostring(uid)] = true
    saveWhitelist()
    return true
end
local function removeWhitelist(name)
    if not name or name == "" then return false end
    Whitelist.Names[tostring(name):lower()] = nil
    saveWhitelist()
    return true
end
local function removeWhitelistUID(uid)
    if not uid then return false end
    Whitelist.UIDs[tostring(uid)] = nil
    saveWhitelist()
    return true
end
local function addTeamWhitelist(name)
    if not name or name == "" then return false end
    Whitelist.Teams[tostring(name):lower()] = true
    saveWhitelist()
    return true
end
local function removeTeamWhitelist(name)
    if not name or name == "" then return false end
    Whitelist.Teams[tostring(name):lower()] = nil
    saveWhitelist()
    return true
end
local function listTeamWhitelist()
    local out = {}
    for t in pairs(Whitelist.Teams) do table.insert(out, t) end
    table.sort(out)
    return out
end
local function clearWhitelist()
    Whitelist.Names = {}
    Whitelist.UIDs = {}
    Whitelist.Teams = {}
    saveWhitelist()
end
local function listWhitelist()
    local out = {}
    for n in pairs(Whitelist.Names) do table.insert(out, n) end
    for u in pairs(Whitelist.UIDs) do table.insert(out, "uid:"..u) end
    table.sort(out)
    return out
end
local function isTeamNoDraw(p)
    if not p then return false end
    local cached = _noDrawCache[p]
    if cached ~= nil then return cached end
    local team = p.Team
    local res = team and Whitelist.NoDrawTeams[tostring(team.Name):lower()] == true or false
    _noDrawCache[p] = res
    return res
end
local function addNoDrawTeam(name)
    if not name or name == "" then return false end
    Whitelist.NoDrawTeams[tostring(name):lower()] = true
    saveWhitelist()
    return true
end
local function removeNoDrawTeam(name)
    if not name or name == "" then return false end
    Whitelist.NoDrawTeams[tostring(name):lower()] = nil
    saveWhitelist()
    return true
end
local function listNoDrawTeam()
    local out = {}
    for t in pairs(Whitelist.NoDrawTeams) do table.insert(out, t) end
    table.sort(out)
    return out
end
loadWhitelist()

local ESP = {
    enabled=true, box=true, boxFill=false, cornerBox=false, outline=false,
    glow=false, glowLayers=GLOW_LAYERS, glowThick=14,
    name=true, nameFormat="DisplayNameUsername", customName="custom text",
    health=false, healthSide="Right",
    tracer=false, tracerOrigin="Bottom",
    distance=false, headDot=false,
    teamCheck=false, useTeamColor=true,
    boxColor=Color3.fromRGB(255,255,255), outlineColor=Color3.fromRGB(0,0,0),
    glowColor=Color3.fromRGB(255,100,100), tracerColor=Color3.fromRGB(255,255,255),
    nameColor=Color3.fromRGB(255,255,255), headDotColor=Color3.fromRGB(255,255,255),
    boxTransp=0.3, boxThick=1.5, outlineThick=1, outlineTransp=0.5, glowTransp=0.4,
    nameSize=15, nameOffset=4, nameScale=false,
    distSize=13, maxDistance=1000, cornerLength=0.25,
    headDotSize=5, headDotScale=false, headDotTransp=0,
    headDotFilled=true, headDotThickness=1, font=2,
    healthBarThickness=3, healthBarLength=1, healthBarOffset=4,
    healthColorMode="Gradient",
    healthCustomColor=Color3.fromRGB(0,255,0),
    healthGradStart=Color3.fromRGB(0,255,0),
    healthGradEnd=Color3.fromRGB(255,0,0),
    healthBarBgColor=Color3.new(0,0,0), healthBarBgTransp=0.4,
    healthText=false, healthTextColor=Color3.fromRGB(255,255,255),
    healthTextSize=12, healthTextOffsetY=20,
    skeleton=false, skeletonColor=Color3.fromRGB(255,255,255),
    skeletonThick=1, skeletonTransp=0.2,
    healthBasedColor=false, distanceFade=false,
    weaponName=false, weaponColor=Color3.fromRGB(255,200,120),
    nameShowHP=false, nameShowDistance=false, nameShowWeapon=false,
    -- ── visual v2 ──
    box3D=false, box3DThick=1, box3DTransp=0.4,
    distanceFadeNear=30, distanceFadeFar=500,
    targetPulse=false,
    -- ── visual v3 ──
    boxGradient2D=false,
    boxGradientColorA=Color3.fromRGB(255,200,160),
    boxGradientColorB=Color3.fromRGB(140,200,255),
    boxGradientTransp=0.65,
    headSphere=false, headSphereColor=Color3.fromRGB(255,255,255),
    headSphereThick=1.5, headSphereTransp=0.15, headSphereScale=1.15,
    skeletonR6Fallback=true,
}

local Aimbot = {
    enabled=false, key=Enum.UserInputType.MouseButton2, toggleMode=false,
    targetParts={Head=true}, multiPoints={},
    teamCheck=false, aliveCheck=true, wallCheck=false, forcefieldCheck=true,
    fov=150, maxDist=700, targetPlayers=true, targetNPCs=false,
    priority="Closest", skipKnocked=false,
    smoothness=0.45, sensitivity=1.2, stickiness=0.5,
    -- ── CURVE ──
    smoothCurve = "ease-out",   -- linear / ease-in / ease-out / ease-in-out / bezier
    bezierP1    = {0.25, 0.10}, -- координаты (x,y) первой контрольной точки
    bezierP2    = {0.25, 1.00}, -- второй контрольной точки
    thirdPerson=false, thirdPersonSens=1, blatant=false,
    prediction=20, projSpeed=150, projGravity=0, gravityCorrection=0,
    method="Camera",
    triggerBot=false, triggerKey=Enum.UserInputType.MouseButton1,
    triggerToggleMode=false, triggerDelay=0.05, triggerWallCheck=false,
    triggerMultipoint=true, triggerOnlySettled=true, triggerNoShake=true,
    triggerRange=100, triggerRadius=8, triggerNPCs=false,
    autoShoot=false, autoShootDelay=0.1, autoShootSettled=true,
    rapidFire=false, rapidFireMult=2, rapidFireGap=0.02,
    onlyADS=false, hitChance=100,
    -- ── BODYPART LOCKS ──
    bindHead   = nil,   -- зажать = целиться в Head
    bindTorso  = nil,   -- зажать = целиться в Torso/UpperTorso
    bindHRP    = nil,   -- зажать = целиться в HumanoidRootPart
    bindClosest= nil,   -- зажать = целиться в ближайший part
    lockPriority = { "bindHead","bindTorso","bindHRP","bindClosest" },

    showFOV=false,
    fovColor=Color3.fromRGB(255,255,255), fovLockedColor=Color3.fromRGB(255,60,60),
    fovTransp=0.5, fovSides=64, fovThickness=1,
    fovFilled=false, fovRainbow=false, fovRainbowSpeed=1,
    skipFriends=true,  
    _fov=nil, _fovCache=nil,
    _lastShoot=0, _lastTrigger=0,
    _currentTarget=nil, _stickyTarget=nil, _stickyTimer=0,
    _hitChancePass=true, _lastHitPart=nil, _toggle=false,

    -- ── FOV SWITCHER ──
    switchOnLeave    = false,   -- авто-переключение при выходе цели из FOV
    switchDelay      = 0.35,    -- сек. удержания после выхода из FOV
    switchMaxTargets = 2,       -- максимум целей в ротации
    _switchQueue     = {},      -- {[player]=tick}, кто недавно был целью
    _switchState     = {},      -- {current=player, leftAt=tick}
}

-- ═══════════════════════════════════════════════════════════
-- SILENT AIM (изолировано в do-блоке → экономит регистры)
-- ═══════════════════════════════════════════════════════════
local SilentAimAPI = {}
do
    local SilentAim = {
        enabled = false, key = nil, toggleMode = false,
        hitChance = 100, maxDist = 700, fov = 200,
        showFOV = false,
        fovColor = Color3.fromRGB(200, 180, 255),
        fovLockedColor = Color3.fromRGB(255, 80, 80),
        fovTransp = 0.5,
        fovThickness = 1,
        fovSides = 64,
        fovRainbow = false,
        fovRainbowSpeed = 1,
        _fovDraw = nil,
        _fovCache = nil,
        wallCheck = false, teamCheck = false, skipFriends = true,
        forcefieldCheck = true, aliveCheck = true, skipKnocked = false,
        targetParts = {Head = true}, resolverOn = true,
        prediction = 20, projSpeed = 150, projGravity = 0,
        _mouse = nil, _origIndex = nil, _hookInstalled = false,
        _target = nil, _lastTarget = nil, _toggle = false,
        _hitPass = true, _lastHookErr = nil,
    }
    SilentAimAPI.SA = SilentAim

    local _getrawmetatable = rawget(_G, "getrawmetatable") or rawget(_G, "getrawmetatable")
                          or (typeof(getmetatable) == "function" and getmetatable or nil)
    local _setreadonly     = rawget(_G, "setreadonly") or function() end
    local _newcclosure     = rawget(_G, "newcclosure") or function(f) return f end
    local _hookmetamethod  = rawget(_G, "hookmetamethod")
    local _hookfunction    = rawget(_G, "hookfunction")

    local function isActive()
        if not SilentAim.enabled then return false end
        if SilentAim.toggleMode then return SilentAim._toggle end
        if not SilentAim.key then return true end
        return keyHeld(SilentAim.key)
    end

    local function shouldTarget(p)
        if p == LocalPlayerS then return false end
        if not p.Character then return false end
        if SilentAim.teamCheck and p.Team ~= nil and p.Team == LocalPlayerS.Team then return false end
        if SilentAim.skipFriends and isWhitelisted(p) then return false end
        if isTeamNoDraw(p) then return false end
        if SilentAim.forcefieldCheck
            and p.Character:FindFirstChildOfClass("ForceField") then return false end
        if SilentAim.aliveCheck then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return false end
        end
        if SilentAim.skipKnocked and isKnocked(p.Character) then return false end
        return true
    end

    local function findTarget()
        local char = LocalPlayerS.Character
        if not char then return nil end
        local myHrp = char:FindFirstChild("HumanoidRootPart")
        if not myHrp then return nil end
        local vp = CameraS.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        local fovPx = SilentAim.fov * (vp.Y / FOV_REF_H)
        local best, bd = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if shouldTarget(p) then
                local tChar = p.Character
                local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                if tHrp then
                    local part = getAimPart(tChar)
                    if part then
                        local d3 = (part.Position - myHrp.Position).Magnitude
                        if d3 <= SilentAim.maxDist then
                            local aimPos
                            if SilentAim.resolverOn then
                                aimPos = resolverPredict(part, tChar,
                                    SilentAim.projSpeed, SilentAim.projGravity,
                                    SilentAim.prediction)
                            else
                                aimPos = part.Position
                            end
                            local sp, on = CameraS:WorldToViewportPoint(aimPos)
                            if on and sp.Z > 0 then
                                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if d <= fovPx and d < bd then
                                    if not SilentAim.wallCheck
                                        or aimVisible(tChar, part) then
                                        bd = d
                                        best = { player = p, char = tChar,
                                                 part = part, pos = aimPos }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function installHook()
        if SilentAim._hookInstalled then return true end
        local ok, mouse = pcall(function() return LocalPlayerS:GetMouse() end)
        if not ok or not mouse then
            SilentAim._lastHookErr = "GetMouse failed"
            return false, SilentAim._lastHookErr
        end
        SilentAim._mouse = mouse

        -- интерсептор, который будет вызываться для Mouse.Hit / .Target / .UnitRay
        local function interceptor(self, k)
            if self == mouse and SilentAim.enabled and SilentAim._target then
                local tg = SilentAim._target
                if k == "Hit" then return CFrame.new(tg.pos)
                elseif k == "Target" then return tg.part
                elseif k == "UnitRay" then
                    local origin = CameraS.CFrame.Position
                    local dir = tg.pos - origin
                    if dir.Magnitude < 0.01 then dir = CameraS.CFrame.LookVector end
                    return Ray.new(origin, dir.Unit * 5000)
                elseif k == "TargetSurface" then return Enum.NormalId.Front
                elseif k == "Origin" then return CameraS.CFrame
                end
            end
            -- fallback: делегируем оригиналу
            if SilentAim._origIndex then
                return SilentAim._origIndex(self, k)
            end
        end

        -- СПОСОБ 1: hookmetamethod (Synapse, KRNL, Script-Ware, Xeno)
        if type(_hookmetamethod) == "function" then
            local okh, err = pcall(function()
                local orig = _hookmetamethod(game, "__index", _newcclosure(function(self, k)
                    if self == mouse then return interceptor(self, k) end
                    return orig(self, k)
                end))
                SilentAim._origIndex = orig
            end)
            if okh then
                SilentAim._hookInstalled = true
                SilentAim._lastHookErr = nil
                return true
            end
        end

        -- СПОСОБ 2: getrawmetatable + setreadonly (старые Synapse)
        if type(_getrawmetatable) == "function" then
            local ok2, mt = pcall(_getrawmetatable, game)
            if ok2 and mt and mt.__index then
                SilentAim._origIndex = mt.__index
                local origIndex = mt.__index
                pcall(_setreadonly, mt, false)
                mt.__index = _newcclosure(function(self, k)
                    if self == mouse then return interceptor(self, k) end
                    return origIndex(self, k)
                end)
                pcall(_setreadonly, mt, true)
                SilentAim._hookInstalled = true
                SilentAim._lastHookErr = nil
                return true
            end
        end

        -- СПОСОБ 3: hookfunction напрямую (некоторые форки)
        if type(_hookfunction) == "function" and type(_getrawmetatable) == "function" then
            local ok3, mt = pcall(_getrawmetatable, game)
            if ok3 and mt and type(mt.__index) == "function" then
                SilentAim._origIndex = mt.__index
                local newFn = _newcclosure(function(self, k)
                    if self == mouse then return interceptor(self, k) end
                    return SilentAim._origIndex(self, k)
                end)
                local okh = pcall(function() _hookfunction(mt.__index, newFn) end)
                if okh then
                    SilentAim._hookInstalled = true
                    SilentAim._lastHookErr = nil
                    return true
                end
            end
        end

        SilentAim._lastHookErr = "executor has no hookmetamethod / getrawmetatable / hookfunction"
        return false, SilentAim._lastHookErr
    end

    local function uninstallHook()
        if not SilentAim._hookInstalled then return end
        local ok, mt = pcall(_getrawmetatable, game)
        if ok and mt and SilentAim._origIndex then
            pcall(_setreadonly, mt, false)
            pcall(function() mt.__index = SilentAim._origIndex end)
            pcall(_setreadonly, mt, true)
        end
        SilentAim._hookInstalled = false
        SilentAim._target = nil
    end

    local function tick()
        if not SilentAim.enabled then SilentAim._target = nil; return end
        if not isActive() then SilentAim._target = nil; return end
        local t = findTarget()
        if t then
            if SilentAim._lastTarget ~= t.player then
                SilentAim._hitPass = (SilentAim.hitChance >= 100)
                    or (math.random(1, 100) <= SilentAim.hitChance)
                SilentAim._lastTarget = t.player
            end
            SilentAim._target = SilentAim._hitPass and t or nil
        else
            SilentAim._target = nil
            SilentAim._lastTarget = nil
        end
    end

    SilentAimAPI.isActive      = isActive
    SilentAimAPI.shouldTarget  = shouldTarget
    SilentAimAPI.findTarget    = findTarget
    SilentAimAPI.installHook   = installHook
    SilentAimAPI.uninstallHook = uninstallHook
    SilentAimAPI.tick          = tick
end

-- ═══════════════════════════════════════════════════════════
-- AUTOSTOP  (не даёт мазать: останавливает движение при лоcке)
-- ═══════════════════════════════════════════════════════════
local Autostop = {
    enabled          = false,
    stopMove         = true,   -- WalkSpeed = 0
    stopJump         = false,  -- JumpPower = 0
    onlyWhenLocked   = true,   -- только когда цель найдена
    releaseDelay     = 0.05,   -- задержка перед восстановлением (сек)
    _active          = false,
    _savedWS         = nil,
    _savedJP         = nil,
    _releaseAt       = nil,
}

local function autostopApply()
    if Autostop._active then return end
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    Autostop._savedWS = hum.WalkSpeed
    Autostop._savedJP = hum.JumpPower
    if Autostop.stopMove then
        hum.WalkSpeed = 0
    end
    if Autostop.stopJump then hum.JumpPower = 0 end
    Autostop._active = true
    Autostop._releaseAt = nil
end

local function autostopRelease()
    if not Autostop._active then return end
    local char = LocalPlayerS.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Autostop.stopMove and Autostop._savedWS then
            hum.WalkSpeed = Autostop._savedWS
        end
        if Autostop.stopJump and Autostop._savedJP then
            hum.JumpPower = Autostop._savedJP
        end
    end
    Autostop._active = false
    Autostop._savedWS = nil
    Autostop._savedJP = nil
    Autostop._releaseAt = nil
end

local Chams = {
    enabled=false,
    skipWhitelist=true,
    useWhitelistColor=true,
    whitelistColor=Color3.fromRGB(0,255,120),
    useTargetColor=true,
    targetColor=Color3.fromRGB(255,100,100),

    teamCheck=false, useTeamColor=false,
    fillColor=Color3.fromRGB(255,0,0),
    outlineColor=Color3.fromRGB(0,0,0),
    outlineEnabled=false,
    fillTransp=0.5, outlineTransp=0,
    depth="AlwaysOnTop",
    depthMode="Both",
    rainbow=false, rainbowSpeed=1,
    maxDistance=1500,
}
local SelfChams = {
    enabled=false,
    fillColor=Color3.fromRGB(255,0,0),
    outlineColor=Color3.fromRGB(0,0,0),
    outlineEnabled=false,
    fillTransp=0.5, outlineTransp=0,
    depthMode="Both",
    rainbow=false, rainbowSpeed=1,
}

local Hitmarker = {
    enabled=false, mode="Cross",
    crossSize=8, crossThickness=2, crossDuration=0.35,
    crossColor=Color3.fromRGB(255,255,255),
    crossSpin=0, crossSpinKill=360,
    crossRainbow=false, crossRainbowSpeed=1, crossTransp=0,
    crossOutline=true, crossOutlineColor=Color3.fromRGB(0,0,0),
    crossFadeIn=0.05, crossScaleIn=true,
    numberOutline=true, numberOutlineColor=Color3.fromRGB(0,0,0),
    numberDuration=0.8, numberSize=22,
    numberColor=Color3.fromRGB(255,255,255),
    numberPrefix="-", numberSuffix="", numberRiseSpeed=80,
    numberRainbow=false, numberRainbowSpeed=1,
    killEnabled=true, killColor=Color3.fromRGB(255,60,60),
    killSizeBoost=1.6, killDurationBoost=1.8,
    killTextEnabled=true, killText="kill", killTextSize=20,
    killTextColor=Color3.fromRGB(255,60,60),
    headshotEnabled=true, headshotColor=Color3.fromRGB(255,200,0),
    headshotSizeBoost=1.3,
    comboEnabled=true, comboColor=Color3.fromRGB(255,255,0),
    comboDuration=1.2, comboSize=28,
    comboMinCount=2, comboOffsetY=30,
    comboRainbow=false, comboRainbowSpeed=2,
    pool={}, poolIndex=1, poolSize=HM_POOL,
    comboCount=0, comboLastHit=0, comboStartTime=0,
}

local Hitsound = {
    enabled=false, preset="COD Hitmarker", customId="",
    volume=1, onTrigger=true, onManual=true,
    mode="single",   -- "single" | "every"
    pool={}, poolIndex=1,
    _lastManualShot=0, _lastTriggerShot=0,
    cache={}, hitCount=0,
}
local KillSound = {
    enabled=false, preset="Gamesense Bell", customId="",
    volume=1, pool={}, poolIndex=1, cache={},
}

-- ==== TRASHTALK ====
local TrashTalk = {
    enabled = false,
    interval = 1.0,
    hidePrefix = false,
    prefix = "hysteria | ",
    stripEmoji = false,    -- выкл по умолчанию: Roblox нормально жуёт 4-байтные эмодзи.
                           -- Включай если в твоей игре фильтр чата режет сообщения с эмодзи
    phrases = {},          -- each: { text, enabled }
    _pendingSend = nil,    -- tick() at which to send
    _lastSent = 0,         -- ❗ время последней отправки
    _lastText = "",        -- ❗ текст последней отправки (для анти-дубликата)
    _minInterval = 3.0,    -- ❗ ЖЁСТКИЙ минимум 3 сек между сообщениями
}
local TT_FILE = "hysteria_configs_blyat/trashtalk.json"
local TT_HAS_FILE = (typeof(writefile) == "function") and (typeof(readfile) == "function")
    and (typeof(isfile) == "function") and (typeof(makefolder) == "function")
    and (typeof(isfolder) == "function")

local function ttDefaults()
    local p = TrashTalk.prefix
    local function T(t) return { p .. t, true } end
    return {
        T("погавкай мне еще, щенок"),
        T("каждый бездарь тут БУДЕТ выть 🤧"),
        T("ur so eZzZzZzZz... 💤"),
        T("я был player, но теперь я тренер а ты мой ученик 🥺👆"),
        T("translate please ->  Злись И Плачь Бургер)0)0 🥺👆"),
        T("get good dog 🥺"),
        T("im not sorry for killing u lmao get good 👆_( >w< )_👆"),
        T("suck + liedown 👿"),
        T("🤡 Иду На Забив, 1 😈"),
        T("прости за то что убил 😅"),
        T("ты не в духе или просто не попадаешь? 🤧"),
        T("ПлАКи ПлАКи, нормалдаки??? 😹😹😹"),
        T("owned by primo user (god) 👑"),
        T("на мне люксовая шкура леопарда на тебе реплика одежды баленси 🤡"),
        T("я сломал себе две руки и играю ногами, и даже так тебя попустил)))"),
        T("recently i got تم حظر اللعبة because أنت كلب سهل التعامل معه"),
        T("ощущаю себя королем в этом притоне tryhard пешек"),
        T("ежа голой жопой не напугаешь друг (ты мне не равня) 😪"),
        T("мне сказали «lock», но я не понял, о чём это они 😇"),
        T("скотина умираешь от моего силуэта даже когда я на тя не смотрю"),
        T("im sorry i have paws not hands 🐾🐾🐾"),
        T("все надежды преодолеть меня. но ты не смог"),
        T("скажи мне, стоит ли мне ждать отпор? не считая то что ты будешь в конвульсиях биться? xD"),
        T("sorry, im using translator rn and actually i don’t speak \"🍔\""),
    }
end
TrashTalk.phrases = ttDefaults()

local function saveTrashTalk()
    if not TT_HAS_FILE then return end
    local okF, isF = pcall(isfolder, "hysteria_configs_blyat")
    if not okF or not isF then pcall(makefolder, "hysteria_configs_blyat") end
    local data = { enabled=TrashTalk.enabled, interval=TrashTalk.interval,
        hidePrefix=TrashTalk.hidePrefix, stripEmoji=TrashTalk.stripEmoji,
        phrases=TrashTalk.phrases }
    pcall(writefile, TT_FILE, game:GetService("HttpService"):JSONEncode(data))
end
local function loadTrashTalk()
    if not TT_HAS_FILE then return end
    local ok, exists = pcall(isfile, TT_FILE)
    if not ok or not exists then return end
    local ok2, raw = pcall(readfile, TT_FILE)
    if not ok2 or not raw then return end
    local ok3, dec = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not ok3 or type(dec) ~= "table" then return end
    if type(dec.enabled) == "boolean" then TrashTalk.enabled = dec.enabled end
    if type(dec.interval) == "number" then TrashTalk.interval = dec.interval end
    if type(dec.hidePrefix) == "boolean" then TrashTalk.hidePrefix = dec.hidePrefix end
    if type(dec.stripEmoji) == "boolean" then TrashTalk.stripEmoji = dec.stripEmoji end
    if type(dec.phrases) == "table" and #dec.phrases > 0 then
        local list = {}
        for i, p in ipairs(dec.phrases) do
            if type(p) == "table" and type(p[1]) == "string" then
                -- миграция старого префикса primo | → hysteria |
                local text = p[1]
                if text:sub(1, 8) == "primo | " then
                    text = "hysteria | " .. text:sub(9)
                end
                list[i] = { text, p[2] ~= false }
            end
        end
        if #list > 0 then TrashTalk.phrases = list end
    end
end
loadTrashTalk()

-- ═══════════════════════════════════════════════════════════
-- TRASHTALK SETS  —  отдельные файлы-коллекции фраз
--   hysteria_configs_blyat/trashtalk_sets/<name>.json
-- ═══════════════════════════════════════════════════════════
local _TT_SETS_DIR = "hysteria_configs_blyat/trashtalk_sets"
local HAS_TT_SETS_FS = (typeof(writefile) == "function")
    and (typeof(readfile) == "function")
    and (typeof(isfile) == "function")
    and (typeof(listfiles) == "function")
    and (typeof(makefolder) == "function")
    and (typeof(isfolder) == "function")
    and (typeof(delfile) == "function")

local function _ensureTTSetsDir()
    if not HAS_TT_SETS_FS then return end
    local ok, isF = pcall(isfolder, "hysteria_configs_blyat")
    if not ok or not isF then pcall(makefolder, "hysteria_configs_blyat") end
    local ok2, isT = pcall(isfolder, _TT_SETS_DIR)
    if not ok2 or not isT then pcall(makefolder, _TT_SETS_DIR) end
end
_ensureTTSetsDir()

local function _ttSetPath(name)
    return _TT_SETS_DIR .. "/" .. name .. ".json"
end

local function _sanitizeTTName(name)
    if not name or name == "" then return nil end
    local n = tostring(name):gsub("[^%w_%-%. ]", "_"):sub(1, 48)
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then return nil end
    return n
end

local function saveTrashTalkSet(name, phrases)
    local clean = _sanitizeTTName(name)
    if not clean then return false, "bad name" end
    if not HAS_TT_SETS_FS then return false, "no fs" end
    _ensureTTSetsDir()
    -- sanitize phrases: only {string, bool}
    local safe = {}
    for i, p in ipairs(phrases or {}) do
        if type(p) == "table" and type(p[1]) == "string" then
            safe[i] = { p[1], p[2] ~= false }
        end
    end
    local data = {
        __meta = { version = 1, type = "hysteria_trashtalk_set", savedAt = os.time() },
        phrases = safe,
    }
    local ok, json = pcall(function()
        return game:GetService("HttpService"):JSONEncode(data)
    end)
    if not ok then return false, "encode failed" end
    local path = _ttSetPath(clean)
    if isfile(path) then
        pcall(function()
            local old = readfile(path)
            if old then writefile(path .. ".bak", old) end
        end)
    end
    local okW = pcall(writefile, path, json)
    if not okW then return false, "write failed" end
    return true, clean
end

local function loadTrashTalkSet(name)
    local clean = _sanitizeTTName(name)
    if not clean then return false, "bad name" end
    if not HAS_TT_SETS_FS then return false, "no fs" end
    local path = _ttSetPath(clean)
    local okE, exists = pcall(isfile, path)
    if not okE or not exists then return false, "not found" end
    local okR, raw = pcall(readfile, path)
    if not okR or not raw then return false, "read failed" end
    local okD, dec = pcall(function()
        return game:GetService("HttpService"):JSONDecode(raw)
    end)
    if not okD or type(dec) ~= "table" then return false, "corrupt" end
    local phrases = dec.phrases
    if type(phrases) ~= "table" then return false, "no phrases" end
    local out = {}
    for i, p in ipairs(phrases) do
        if type(p) == "table" and type(p[1]) == "string" then
            out[i] = { p[1], p[2] ~= false }
        end
    end
    if #out == 0 then return false, "empty set" end
    return true, out
end

local function listTrashTalkSets()
    local out = {}
    if not HAS_TT_SETS_FS then return out end
    _ensureTTSetsDir()
    local ok, files = pcall(listfiles, _TT_SETS_DIR)
    if not ok or not files then return out end
    for _, f in ipairs(files) do
        local base = f:match("([^/\\]+)%.json$")
        if base and not base:match("%.bak$") and not base:match("%.tmp$") then
            out[#out+1] = base
        end
    end
    table.sort(out)
    return out
end

local function deleteTrashTalkSet(name)
    local clean = _sanitizeTTName(name)
    if not clean then return false end
    if not HAS_TT_SETS_FS then return true end
    pcall(function()
        local path = _ttSetPath(clean)
        if isfile(path) then delfile(path) end
        if isfile(path .. ".bak") then delfile(path .. ".bak") end
    end)
    return true
end

-- remove emoji (сохраняя кириллицу!)
-- ❗ ГЛАВНЫЙ ФИКС: раньше паттерны вида "[\194\160-\194\191]" были
-- символьным классом одиночных байт (0xA0–0xC2), а не 2-байтовой
-- последовательностью. Из-за этого вырезались trailing-байты кириллицы
-- → в чат уходило "hysteria |?" вместо фразы.
-- Теперь используем ЯВНЫЕ многобайтовые последовательности через \xxx.
local function _stripEmoji(s)
    if type(s) ~= "string" then return s end
    -- 4-byte UTF-8 (U+10000..U+10FFFF) — почти вся эмодзи-раскладка
    s = s:gsub("\240[\128-\191][\128-\191][\128-\191]", "")
    s = s:gsub("\241[\128-\191][\128-\191][\128-\191]", "")
    s = s:gsub("\242[\128-\191][\128-\191][\128-\191]", "")
    s = s:gsub("\243[\128-\191][\128-\191][\128-\191]", "")
    s = s:gsub("\244[\128-\191][\128-\191][\128-\191]", "")
    -- 3-byte misc symbols (U+2600–U+26FF): ☀ ☁ ♥ ★ ⚡ и т.п.
    s = s:gsub("\226[\152-\158][\128-\191]", "")
    -- 3-byte dingbats (U+2700–U+27BF): ✂ ✈ ✉ ✅ ❌ и т.п.
    s = s:gsub("\226[\156-\157][\128-\191]", "")
    -- 3-byte em spaces + zero-width (U+2000–U+200F) → просто в пробел
    s = s:gsub("\226\128[\128-\143]", " ")
    -- NBSP (U+00A0) → пробел
    s = s:gsub("\194\160", " ")
    -- soft hyphen (U+00AD) → удаляем
    s = s:gsub("\194\173", "")
    -- схлопываем пробелы, триммим
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

-- remove control chars that break chat filter
local function _sanitizeChat(s)
    if type(s) ~= "string" then return s end
    s = s:gsub("[\n\r\t]", " ")
    s = s:gsub("  +", " ")
    s = s:gsub("%s+$", ""):gsub("^%s+", "")
    return s
end

local function sendChatMessage(msg)
    if not msg or msg == "" then return false end
    -- ❗ FIX: раньше тут ВСЕГДА вызывался _stripEmoji, из-за чего настройка
    -- "strip emoji" в UI вообще ничего не решала. Убираем принудительный вызов —
    -- решение об эмодзи принимается РАНЬШЕ, в fireTrashTalk().
    msg = _sanitizeChat(msg)
    if msg == "" then return false end
    if #msg > 190 then msg = msg:sub(1, 190) end

    -- 1) TextChatService (современные игры) — сначала, потому что
    --    legacy-инстанс может существовать как артефакт и "пожрать" сообщение
    local TCS = game:GetService("TextChatService")
    if TCS and TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        local chans = TCS:FindFirstChild("TextChannels")
        local general = chans and (chans:FindFirstChild("RBXGeneral")
            or chans:FindFirstChild("RBGGeneral")
            or chans:FindFirstChildWhichIsA("TextChannel"))
        if general then
            local ok = pcall(function() general:SendAsync(msg) end)
            if ok then return true end
        end
    end

    -- 2) legacy chat
    local RS = game:GetService("ReplicatedStorage")
    local ce = RS:FindFirstChild("DefaultChatSystemChatEvents")
    local say = ce and ce:FindFirstChild("SayMessageRequest")
    if say then
        local ok = pcall(function() say:FireServer(msg, "All") end)
        if ok then return true end
    end

    -- 3) chat bar fallback (capture + release)
    pcall(function()
        local cfg = TCS and TCS:FindFirstChild("ChatInputBarConfiguration")
        if cfg then
            local bar = cfg:FindFirstChild("TextBox")
            if bar and bar:IsA("TextBox") then
                bar:CaptureFocus()
                task.wait(0.02)
                bar.Text = msg
                bar:ReleaseFocus(true)
            end
        end
    end)

    return false
end

local function fireTrashTalk()
    -- собираем пул из ВСЕХ включённых фраз, без фильтрации содержимого
    local pool = {}
    for _, p in ipairs(TrashTalk.phrases) do
        if type(p) == "table" and p[2] ~= false
            and type(p[1]) == "string" and p[1] ~= "" then
            pool[#pool+1] = p[1]
        end
    end
    if #pool == 0 then return end

    local msg = pool[math.random(1, #pool)]

    -- ❗ избегаем повтора той же фразы подряд
    if #pool > 1 and msg == TrashTalk._lastText then
        for _ = 1, 5 do
            msg = pool[math.random(1, #pool)]
            if msg ~= TrashTalk._lastText then break end
        end
    end

    if TrashTalk.hidePrefix then
        local pre = TrashTalk.prefix
        if msg:sub(1, #pre) == pre then msg = msg:sub(#pre + 1) end
    end

    -- эмодзи режем ТОЛЬКО если юзер сам включил
    if TrashTalk.stripEmoji then msg = _stripEmoji(msg) end

    -- ❗ единственная защита: не отправлять заведомо пустую строку,
    --    иначе Roblox не примет и в чате висит "hysteria | " без текста
    if msg == nil or msg:gsub("%s","") == "" then return end

    TrashTalk._lastText = msg
    TrashTalk._lastSent = tick()
    sendChatMessage(msg)
end
local PRESETS = {
    ["None"]=nil,
    ["COD Hitmarker"]="rbxassetid://77082587278347",
    ["Gamesense Bell"]="rbxassetid://140247876667835",
    ["NeverLose Bell"]="rbxassetid://139452805868562",
    ["MLG"]="rbxassetid://109817519733426",
    ["TF2 Hitsound"]="rbxassetid://124010691633262",
    ["Mellstroy KpAcHbIu"]="rbxassetid://105330340607642",
    ["Mellstroy Bites"]="rbxassetid://93212904055668",
    ["Mellstroy Privet Artur"]="rbxassetid://127480875607982",
    ["Meow 1"]="rbxassetid://134699420140804",
    ["Meow 2"]="rbxassetid://134881862056957",
    ["Meow 3"]="rbxassetid://137858393997267",
    ["CashCashCash"]="rbxassetid://18894298256",
    ["Undertale Hit"]="rbxassetid://140721035016341",
    ["osu hitsound"]="rbxassetid://123941247147792",
    ["pizza tower"]="rbxassetid://121311089745141",
    ["tf2 bubble"]="rbxassetid://104824514322839",
    ["quake shit"]="rbxassetid://4868633804",
    ["fatality"]="rbxassetid://115982072912004",
    ["minecraft xp"]="rbxassetid://134763632925481",
    ["primordial"]="rbxassetid://97511223764004",
    ["csgo headshot"]="rbxassetid://18537680989",
    ["lbp"]="rbxassetid://104373364424359",
    ["nya"]="rbxassetid://102774986031312",
    ["nya 2"]="rbxassetid://137965684634919",
    ["nya 3"]="rbxassetid://129772045629820",
}

local World = {
    fullbright=false,
    brightness=LightingS.Brightness, ambient=LightingS.Ambient,
    outdoorAmbient=LightingS.OutdoorAmbient, clockTime=LightingS.ClockTime,
    exposure=LightingS.ExposureCompensation, globalShadows=LightingS.GlobalShadows,
    envDiffuse=LightingS.EnvironmentDiffuseScale, envSpecular=LightingS.EnvironmentSpecularScale,
    fogEnabled=false, fogColor=LightingS.FogColor,
    fogStart=LightingS.FogStart, fogEnd=LightingS.FogEnd,
    atmoEnabled=false,
    atmoColor=Color3.fromRGB(199,199,199), atmoDecay=Color3.fromRGB(106,112,125),
    atmoDensity=0.3, atmoHaze=0, atmoGlare=0, atmoOffset=0,
    skyOverride=false, skyStarCount=3000, skyMoonSize=11, skySunSize=21, skyCelestial=true,
    skyColorEnabled=false, skyColor=Color3.fromRGB(100,150,255), skyColorDensity=0.5,
    fogUseAtmoColor=false,
    sunRaysEnabled=false, sunRaysIntensity=0.1, sunRaysSpread=1,
    bloomEnabled=false, bloomIntensity=0.5, bloomSize=24, bloomThreshold=1.5,
    ccEnabled=false, ccBrightness=0, ccContrast=0, ccSaturation=0,
    ccTintColor=Color3.new(1,1,1),
    blurEnabled=false, blurSize=4,
    dofEnabled=false, dofFar=0, dofFocus=0, dofInRadius=0, dofNear=0,
}

local WORLD_STATE = {
    atmoInstance=nil, atmoCreatedByUs=false,
    skyInstance=nil, skyCreatedByUs=false,
    SunRaysEffect=nil, BloomEffect=nil, ColorCorrectionEffect=nil,
    BlurEffect=nil, DepthOfFieldEffect=nil,
    fogApplied=false, fogAtmoSaved=nil, fogAtmoRef=nil,
    skyColorHidden=false, skyColorSavedTextures=nil,
}

local Misc = {
    noclip=false,
    noclipEnabled=false, noclipKey=nil,
    loopSpeedEnabled=false, loopSpeedValue=16, loopSpeedKey=nil,
    spinEnabled=false, spinValue=360, spinKey=nil,
    lowPerf=false,
    hideNametags=false,
    -- ── fly ──
    flyEnabled=false, flyKey=nil,
    flySpeed=60,
    _flyBV=nil, _flyBG=nil, _flyConn=nil,
    -- ── override jumppower ──
    loopJumpPowerEnabled=false, loopJumpPowerValue=50, loopJumpPowerKey=nil,
    _savedJumpPower=nil, _savedUseJumpPower=nil,
}
-- ═══════════════════════════════════════════════════════════
-- AURA (orbit) — CFrame + Physics mode, стабильно и без дёрганья
-- ═══════════════════════════════════════════════════════════
local Aura = {
    enabled       = false,
    key           = nil,
    radius        = 8,          -- studs from target
    speed         = 180,        -- deg/sec
    height        = 2,          -- studs above target's HRP
    teamCheck     = false,
    skipFriends   = true,
    autoTarget    = true,
    target        = nil,
    smoothSwitch  = 0.25,       -- сек. задержки перед сменой цели
    physicsMode   = true,       -- Humanoid:ChangeState(Physics) — убивает гравитацию/инерцию
    visualizer    = false,      -- рисовать окружность орбиты
    visualColor   = Color3.fromRGB(255, 90, 90),
    onlyWhenAlive = true,
    _conn         = nil,
    _phase        = 0,
    _saved        = nil,        -- {platformStand, walkSpeed, jumpPower, autoRotate, state}
    _visualize    = nil,
    _lastTarget   = nil,
    _switchTimer  = 0,
}

-- ==== SESSION ==== (single declaration)
local Session = {
    kills = 0,
    deaths = 0,
    shots = 0,      -- shots fired (mouse click + triggerbot + auto)
    hits = 0,       -- shots that dealt damage
    startTime = tick(),
    enabled = true,
}
local _sessionDeathConn = nil
local function hookSessionDeaths()
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if _sessionDeathConn then
        pcall(function() _sessionDeathConn:Disconnect() end)
    end
    _sessionDeathConn = hum.Died:Connect(function()
        Session.deaths = Session.deaths + 1
        if _G.__PRIMO_SESSION_REFRESH then
            pcall(_G.__PRIMO_SESSION_REFRESH)
        end
    end)
end
LocalPlayerS.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(hookSessionDeaths)
end)
task.defer(hookSessionDeaths)
local Bypasses = {
    forceResetEnabled=false, forceResetKey=nil,
    hitboxEnabled=false, hitboxSize=20,
    hitboxTransparency=0.7, hitboxColor=Color3.fromRGB(0,0,255),
    hitboxMaterial="Neon", hitboxCanCollide=true,
    hitboxApplyToHead=true,
    hitboxThrottle=0.1,
    skipFriends=true,
}

local playerData = {}
local localChamsCache = {}
local localChamsValsCache = {}
local activePlayers = {}
local charAddedPlayers = {}
local selfChamsCache = nil
local lastMouseShot = 0
local _ttKilled = {}
local HITBOX_TAG = PREFIX .. "HitboxExt"

-- cached humanoid lookup (perf: avoid FindFirstChildOfClass every frame)
local _humCache = {}
local function getHumCached(p)
    local h = _humCache[p]
    if h and h.Parent then return h end
    local c = p.Character
    h = c and c:FindFirstChildOfClass("Humanoid") or nil
    _humCache[p] = h
    return h
end

local function getTeamColor(p)
    if p and p.Team and p.Team.TeamColor then return p.Team.TeamColor.Color end
    return Color3.fromRGB(255,255,255)
end
local function getESPName(p)
    -- ❗ name protect: подменяем ник для whitelisted игроков
    if _G.__PRIMO_NAMEPROTECT_ENABLED == true and isWhitelisted(p) then
        return _G.__PRIMO_NAMEPROTECT_TEXT or "Protected"
    end
    local dn, un = p.DisplayName, p.Name
    local hasDN = dn and dn ~= "" and dn ~= un
    local f = ESP.nameFormat
    if f == "Username" then return un end
    if f == "DisplayName" then
        if hasDN then return dn end
        return un
    end
    if f == "DisplayNameUsernameStar" then
        if hasDN then return dn.." (@"..un..")" end
        return "@"..un
    end
    if f == "Custom" then return ESP.customName or un end
    if hasDN then return dn.." (@"..un..")" end
    return "@"..un
end
local function healthColor(pct)
    if ESP.healthColorMode == "Custom" then return ESP.healthCustomColor end
    if ESP.healthColorMode == "Static" then return Color3.fromRGB(0,255,0) end
    if ESP.healthColorMode == "Rainbow" then return Color3.fromHSV((tick()%2)/2,1,1) end
    if ESP.healthColorMode == "GradientCustom" then
        return ESP.healthGradStart:Lerp(ESP.healthGradEnd, 1-pct)
    end
    if pct > 0.5 then return Color3.fromRGB(255*((1-pct)*2),255,0) end
    return Color3.fromRGB(255,255*(pct*2),0)
end

local function hideAll(d)
    if not d then return end
    if d._hidden then return end        -- уже спрятан → ничего не делаем
    d._hidden = true
    local keys = {"box","outline","label","health","healthBg","healthText","tracer","dist","headDot","weaponLabel"}
    -- ❗ скелет: 14 линий (R15), а не 6
    if d.skel then
        for i=1, 14 do
            local o = d.skel[i]
            if o ~= nil and isDraw(o) then
                pcall(function() o.Visible = false end)
            end
        end
    end
    for _, k in ipairs(keys) do
        local o = d[k]
        if o ~= nil then
            local t = type(o)
            if t == "userdata" or t == "table" then pcall(function() o.Visible = false end) end
        end
    end
    if d.glowLayers then
        for i=1, #d.glowLayers do
            local o = d.glowLayers[i]
            if o ~= nil then
                local t = type(o)
                if t == "userdata" or t == "table" then pcall(function() o.Visible = false end) end
            end
        end
    end
    if d.box3D then
        for i=1, 12 do
            local o = d.box3D[i]
            if o ~= nil then
                local t = type(o)
                if t == "userdata" or t == "table" then pcall(function() o.Visible = false end) end
            end
        end
    end
    -- ❗ ГЛАВНЫЙ ФИКС: corner box висел на экране,
    --    потому что его тут не было вообще
    if d.corners then
        for i=1, 8 do
            local o = d.corners[i]
            if o ~= nil and isDraw(o) then
                pcall(function() o.Visible = false end)
            end
        end
    end
    if d.gradTop then pcall(function() d.gradTop.Visible = false end) end
    if d.gradBot then pcall(function() d.gradBot.Visible = false end) end
    if d.headSphere then pcall(function() d.headSphere.Visible = false end) end
    d.cache = nil
end

local function destroyDrawings(p)
    local d = playerData[p]
    if not d or d == false then return end
    local keys = {"box","outline","label","health","healthBg","healthText","tracer","dist","headDot"}
    for _, k in ipairs(keys) do
        if d[k] ~= nil then dRem(d[k]); d[k] = nil end
    end
    if d.glowLayers then
        for i=1, #d.glowLayers do
            if d.glowLayers[i] ~= nil then dRem(d.glowLayers[i]); d.glowLayers[i] = nil end
        end
        d.glowLayers = nil
    end
    if d.box3D then
        for i=1, 12 do
            if d.box3D[i] ~= nil then dRem(d.box3D[i]); d.box3D[i] = nil end
        end
        d.box3D = nil
    end
    if d.gradTop then dRem(d.gradTop); d.gradTop = nil end
    if d.gradBot then dRem(d.gradBot); d.gradBot = nil end
    if d.headSphere then dRem(d.headSphere); d.headSphere = nil end
    if d.corners then
        for i=1, 8 do
            if d.corners[i] ~= nil then dRem(d.corners[i]); d.corners[i] = nil end
        end
        d.corners = nil
    end
    if d.skel then
        for i=1, 6 do
            if d.skel[i] then dRem(d.skel[i]) end
        end
        d.skel = nil
    end
    if d.weaponLabel then dRem(d.weaponLabel); d.weaponLabel = nil end
    if d.teamConn then pcall(function() d.teamConn:Disconnect() end); d.teamConn = nil end
end

local function createPlayerData(p)
    if p == LocalPlayerS then return end
    if playerData[p] ~= nil then return end
    if not p.Parent or not DrawOK then return end
    local tc = getTeamColor(p)
    local track = {}
    local function sc(cls, props)
        local o = newDraw(cls, props)
        if isDraw(o) then track[#track+1] = o end
        return o
    end
    local box = sc("Square", {Visible=false, Color=tc, Thickness=ESP.boxThick,
        Filled=ESP.boxFill, Transparency=ESP.boxTransp, ZIndex=4})
    if not isDraw(box) then
        for _, o in ipairs(track) do dRem(o) end
        return
    end
    local outline = sc("Square", {Visible=false, Color=ESP.outlineColor,
        Thickness=ESP.outlineThick, Filled=false, Transparency=ESP.outlineTransp, ZIndex=3})
    local glowLayers = {}
    for i=1, GLOW_LAYERS do
        local t = i/GLOW_LAYERS
        local thick = ESP.glowThick*t
        local transp = math.min(ESP.glowTransp + (1-ESP.glowTransp)*t*0.85, 0.98)
        glowLayers[i] = sc("Square", {Visible=false, Color=ESP.glowColor,
            Thickness=thick*0.6, Filled=false, Transparency=transp, ZIndex=2-i*0.001})
    end
    -- ✨ 3D wireframe box (12 edges)
    local box3D = {}
    for i=1, 12 do
        box3D[i] = sc("Line", {Visible=false, Color=tc,
            Thickness=ESP.box3DThick, Transparency=ESP.box3DTransp, ZIndex=4})
    end
    local label = sc("Text", {Visible=false, Text=p.Name, Color=tc, Size=ESP.nameSize,
        Center=true, Outline=true, OutlineColor=Color3.new(0,0,0), Font=ESP.font, ZIndex=6})
    local healthBg = sc("Square", {Visible=false, Color=ESP.healthBarBgColor,
        Filled=true, Transparency=ESP.healthBarBgTransp, ZIndex=5})
    local health = sc("Square", {Visible=false, Color=Color3.fromRGB(0,255,0),
        Filled=true, ZIndex=5})
    local healthText = sc("Text", {Visible=false, Text="", Color=ESP.healthTextColor,
        Size=ESP.healthTextSize, Center=true, Outline=true,
        OutlineColor=Color3.new(0,0,0), Font=ESP.font, ZIndex=6})
    local tracer = sc("Line", {Visible=false, Color=ESP.tracerColor, Thickness=1, ZIndex=1})
    local dist = sc("Text", {Visible=false, Text="", Color=Color3.new(1,1,1),
        Size=ESP.distSize, Center=true, Outline=true,
        OutlineColor=Color3.new(0,0,0), Font=ESP.font, ZIndex=5})
    local headDot = sc("Circle", {Visible=false, Color=ESP.headDotColor,
        Filled=ESP.headDotFilled, NumSides=24, Thickness=ESP.headDotThickness,
        Radius=ESP.headDotSize, Transparency=ESP.headDotTransp, ZIndex=5})
    local corners = {}
    for i=1, 8 do
        corners[i] = sc("Line", {Visible=false, Color=tc, Thickness=ESP.boxThick, ZIndex=4})
    end
    -- full R15 skeleton (14 bones)
    local skel = {}
    for i=1, 14 do
        skel[i] = sc("Line", {Visible=false, Color=ESP.skeletonColor,
            Thickness=ESP.skeletonThick, Transparency=ESP.skeletonTransp, ZIndex=5})
    end
    -- gradient 2D box overlays (top + bottom halves)
    local gradTop = sc("Square", {Visible=false, Filled=true,
        Color=ESP.boxGradientColorA, Transparency=ESP.boxGradientTransp, ZIndex=3})
    local gradBot = sc("Square", {Visible=false, Filled=true,
        Color=ESP.boxGradientColorB, Transparency=ESP.boxGradientTransp, ZIndex=3})
    -- 3D head sphere
    local headSphere = sc("Circle", {Visible=false, Filled=false, NumSides=48,
        Color=ESP.headSphereColor, Thickness=ESP.headSphereThick,
        Transparency=ESP.headSphereTransp, Radius=10, ZIndex=6})
    local weaponLabel = sc("Text", {Visible=false, Text="", Color=ESP.weaponColor,
        Size=12, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0),
        Font=ESP.font, ZIndex=6})
    local conn = p:GetPropertyChangedSignal("Team"):Connect(function()
        -- сброс кэшей для этого игрока при смене команды
        _wlCache[p] = nil
        _noDrawCache[p] = nil
        local c = getTeamColor(p)
        local d = playerData[p]
        if not d or d == false then return end
        if isDraw(d.box) then pcall(function() d.box.Color = c end) end
        if isDraw(d.label) then pcall(function() d.label.Color = c end) end
        if d.corners then
            for i=1, 8 do
                if isDraw(d.corners[i]) then pcall(function() d.corners[i].Color = c end) end
            end
        end
        if d.cache then d.cache = {} end
    end)
    playerData[p] = {
        box=box, outline=outline, glowLayers=glowLayers, label=label,
        health=health, healthBg=healthBg, healthText=healthText,
        tracer=tracer, dist=dist, headDot=headDot, corners=corners,
        skel=skel, weaponLabel=weaponLabel, box3D=box3D,
        gradTop=gradTop, gradBot=gradBot, headSphere=headSphere,
        teamConn=conn, cache={},
    }
end

local function getScreenBox(char)
    if not char then return nil end
    -- extended hitbox must not expand the visual box
    local hasExt = char:FindFirstChild(HITBOX_TAG) ~= nil
    local cf, sz
    local ok = false
    -- HITBOX_TAG больше не создаётся → GetBoundingBox всегда false-путь, но
    -- он всё равно дорогой. Используем cheap bounding box из head/hrp.
    if not hasExt then
        local _hrp = char:FindFirstChild("HumanoidRootPart")
        if _hrp then
            cf = _hrp.CFrame
            sz = Vector3.new(2, 5, 1)   -- приблизительный бокс R15
            ok = true
        end
    end
    if not ok or not cf then
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return nil end
        local topScreen = CameraS:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
        local botScreen = CameraS:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
        -- ❗ только Z-проверка, без onScreen
        if topScreen.Z <= 0 or botScreen.Z <= 0 then return nil end
        local h = math.abs(botScreen.Y - topScreen.Y)
        local w = h * 0.55
        local cx = (topScreen.X + botScreen.X) * 0.5
        return cx-w*0.5, cx+w*0.5, math.min(topScreen.Y, botScreen.Y), math.max(topScreen.Y, botScreen.Y)
    end
    local corners = {
        cf*CFrame.new(-sz.X/2,  sz.Y/2, -sz.Z/2),
        cf*CFrame.new( sz.X/2,  sz.Y/2, -sz.Z/2),
        cf*CFrame.new(-sz.X/2,  sz.Y/2,  sz.Z/2),
        cf*CFrame.new( sz.X/2,  sz.Y/2,  sz.Z/2),
        cf*CFrame.new(-sz.X/2, -sz.Y/2, -sz.Z/2),
        cf*CFrame.new( sz.X/2, -sz.Y/2, -sz.Z/2),
        cf*CFrame.new(-sz.X/2, -sz.Y/2,  sz.Z/2),
        cf*CFrame.new( sz.X/2, -sz.Y/2,  sz.Z/2),
    }
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    local any = false
    for _, c in ipairs(corners) do
        -- ❗ проверяем ТОЛЬКО Z > 0 (перед камерой).
        -- onScreen=false значит точка за краем вьюпорта, но её X/Y
        -- всё равно валидны — иначе ESP пропадает у краёв экрана
        local sp = CameraS:WorldToViewportPoint(c.Position)
        if sp.Z > 0 then
            any = true
            if sp.X < minX then minX = sp.X end
            if sp.X > maxX then maxX = sp.X end
            if sp.Y < minY then minY = sp.Y end
            if sp.Y > maxY then maxY = sp.Y end
        end
    end
    if not any then return nil end
    local padX = (maxX-minX)*0.06
    local padY = (maxY-minY)*0.03
    return minX-padX, maxX+padX, minY-padY, maxY+padY
end

local function updateESP(p)
    local d = playerData[p]
    if not d or d == false then return end
    if not isDraw(d.box) then return end
    if not ESP.enabled then hideAll(d) return end
    if ESP.teamCheck and p.Team ~= nil and p.Team == LocalPlayerS.Team then hideAll(d) return end
    if isTeamNoDraw(p) then hideAll(d) return end
    local char = p.Character
    if not char or not char.Parent then hideAll(d) return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not root then hideAll(d) return end
    if hum and hum.Health <= 0 then hideAll(d) return end
    local cam = CameraS.CFrame.Position
    local rp = root.Position
    local dx, dy, dz = cam.X-rp.X, cam.Y-rp.Y, cam.Z-rp.Z
    local dist = math.sqrt(dx*dx+dy*dy+dz*dz)
    if dist > ESP.maxDistance then hideAll(d) return end
    -- cheap early out: только по Z (перед камерой).
    -- rootOn игнорим, иначе ESP пропадает когда HRP уходит за край экрана
    local rootScreen = CameraS:WorldToViewportPoint(rp)
    if rootScreen.Z <= 0 then hideAll(d) return end
    local x1, x2, tY, bY = getScreenBox(char)
    if not x1 or not x2 then hideAll(d) return end
    local w = x2 - x1
    local h = bY - tY
    if h <= 1 or w <= 1 then hideAll(d) return end
    local cx = (x1 + x2) * 0.5
    local color = ESP.boxColor
    if ESP.useTeamColor then color = getTeamColor(p) end
    if d._hidden then
        d._hidden = false
        d.cache = nil
    end
    local c = d.cache or {}
    d.cache = c

    -- ── distance fade ──
    local fadeAlpha = 1
    if ESP.distanceFade then
        local n = ESP.distanceFadeNear or 30
        local f = ESP.distanceFadeFar or 500
        fadeAlpha = math.clamp(1 - (dist - n) / math.max(f - n, 1), 0.1, 1)
    end
    -- ── target pulse ──
    if ESP.targetPulse then
        local isTgt = (_G.PRIMO_TARGETS and _G.PRIMO_TARGETS[p] == true)
            or (_G.PRIMO_TARGET == p)
        if isTgt then
            local puls = (math.sin(tick() * 5) + 1) * 0.5
            fadeAlpha = fadeAlpha * (0.55 + puls * 0.45)
        end
    end
    local function fT(t) return 1 - (1 - t) * fadeAlpha end

    -- ✨ 3D WIREFRAME BOX ──
    if ESP.box3D and d.box3D then
        local cf3 = root.CFrame
        local sx, sy, sz_ = 1.0, 2.5, 0.5   -- 2x5x1 halved
        local pts3 = {
            (cf3 * CFrame.new(-sx,  sy, -sz_)).Position,
            (cf3 * CFrame.new( sx,  sy, -sz_)).Position,
            (cf3 * CFrame.new( sx,  sy,  sz_)).Position,
            (cf3 * CFrame.new(-sx,  sy,  sz_)).Position,
            (cf3 * CFrame.new(-sx, -sy, -sz_)).Position,
            (cf3 * CFrame.new( sx, -sy, -sz_)).Position,
            (cf3 * CFrame.new( sx, -sy,  sz_)).Position,
            (cf3 * CFrame.new(-sx, -sy,  sz_)).Position,
        }
        local scr = {}
        for i=1, 8 do
            local sp = CameraS:WorldToViewportPoint(pts3[i])
            if sp.Z > 0 then scr[i] = Vector2.new(sp.X, sp.Y) end
        end
        local edges = {
            {1,2},{2,3},{3,4},{4,1},
            {5,6},{6,7},{7,8},{8,5},
            {1,5},{2,6},{3,7},{4,8},
        }
        local tr3d = fT(ESP.box3DTransp)
        for i=1, 12 do
            local ln = d.box3D[i]
            if isDraw(ln) then
                local a, b = scr[edges[i][1]], scr[edges[i][2]]
                if a and b then
                    pcall(function()
                        ln.From = a; ln.To = b
                        ln.Color = color
                        ln.Thickness = ESP.box3DThick
                        ln.Transparency = tr3d
                        ln.Visible = true
                    end)
                else
                    pcall(function() ln.Visible = false end)
                end
            end
        end
    elseif d.box3D then
        for i=1, 12 do
            if isDraw(d.box3D[i]) then
                pcall(function() d.box3D[i].Visible = false end)
            end
        end
    end

    -- ✨ GRADIENT 2D BOX ──
    if ESP.boxGradient2D and isDraw(d.gradTop) and isDraw(d.gradBot) then
        local gt = fT(ESP.boxGradientTransp)
        local midY = tY + h * 0.5
        pcall(function()
            d.gradTop.Position = Vector2.new(x1, tY)
            d.gradTop.Size     = Vector2.new(w, h * 0.5)
            d.gradTop.Color    = ESP.boxGradientColorA
            d.gradTop.Transparency = gt
            d.gradTop.Visible  = true
        end)
        pcall(function()
            d.gradBot.Position = Vector2.new(x1, midY)
            d.gradBot.Size     = Vector2.new(w, h * 0.5)
            d.gradBot.Color    = ESP.boxGradientColorB
            d.gradBot.Transparency = gt
            d.gradBot.Visible  = true
        end)
    else
        if isDraw(d.gradTop) then pcall(function() d.gradTop.Visible = false end) end
        if isDraw(d.gradBot) then pcall(function() d.gradBot.Visible = false end) end
    end

    -- ✨ 3D HEAD SPHERE ──
    if ESP.headSphere and isDraw(d.headSphere) and head then
        local hp = head.Position
        local sp  = CameraS:WorldToViewportPoint(hp)
        local spR = CameraS:WorldToViewportPoint(hp + Vector3.new(0.7, 0, 0))
        if sp.Z > 0 and spR.Z > 0 then
            local px = (Vector2.new(sp.X, sp.Y) - Vector2.new(spR.X, spR.Y)).Magnitude
            px = px * ESP.headSphereScale
            pcall(function()
                d.headSphere.Position = Vector2.new(sp.X, sp.Y)
                d.headSphere.Radius = px
                d.headSphere.Color = ESP.headSphereColor
                d.headSphere.Thickness = ESP.headSphereThick
                d.headSphere.Transparency = fT(ESP.headSphereTransp)
                d.headSphere.Visible = true
            end)
        else
            if isDraw(d.headSphere) then pcall(function() d.headSphere.Visible = false end) end
        end
    else
        if isDraw(d.headSphere) then pcall(function() d.headSphere.Visible = false end) end
    end

    if ESP.box and not ESP.cornerBox and isDraw(d.box) then
        local sz, ps = Vector2.new(w,h), Vector2.new(x1,tY)
        if c.boxSize ~= sz then d.box.Size = sz; c.boxSize = sz end
        if c.boxPos ~= ps then d.box.Position = ps; c.boxPos = ps end
        if c.boxCol ~= color then d.box.Color = color; c.boxCol = color end
        if c.boxTh ~= ESP.boxThick then d.box.Thickness = ESP.boxThick; c.boxTh = ESP.boxThick end
        local _tr = fT(ESP.boxTransp)
        if c.boxTr ~= _tr then d.box.Transparency = _tr; c.boxTr = _tr end
        if c.boxFl ~= ESP.boxFill then d.box.Filled = ESP.boxFill; c.boxFl = ESP.boxFill end
        if c.boxVis ~= true then d.box.Visible = true; c.boxVis = true end
    else
        if isDraw(d.box) and c.boxVis ~= false then d.box.Visible = false; c.boxVis = false end
    end
    if ESP.glow and not ESP.cornerBox and d.glowLayers then
        local total = ESP.glowThick
        local layerCount = math.min(#d.glowLayers, ESP.glowLayers or GLOW_LAYERS)
        for i=1, #d.glowLayers do
            local g = d.glowLayers[i]
            if i <= layerCount and isDraw(g) then
                local t = i/layerCount
                local thick = total*t
                local sz = Vector2.new(w+thick, h+thick)
                local ps = Vector2.new(x1-thick*0.5, tY-thick*0.5)
                local transp = math.min(ESP.glowTransp + (1-ESP.glowTransp)*t*0.85, 0.98)
                transp = fT(transp)
                if c["gSz"..i] ~= sz then g.Size = sz; c["gSz"..i] = sz end
                if c["gPs"..i] ~= ps then g.Position = ps; c["gPs"..i] = ps end
                if c["gCol"..i] ~= ESP.glowColor then g.Color = ESP.glowColor; c["gCol"..i] = ESP.glowColor end
                local tThick = math.max(thick*0.55, 1)
                if c["gTh"..i] ~= tThick then g.Thickness = tThick; c["gTh"..i] = tThick end
                if c["gTr"..i] ~= transp then g.Transparency = transp; c["gTr"..i] = transp end
                if c["gVis"..i] ~= true then g.Visible = true; c["gVis"..i] = true end
            else
                if isDraw(g) and c["gVis"..i] ~= false then g.Visible = false; c["gVis"..i] = false end
            end
        end
    else
        if d.glowLayers then
            for i=1, #d.glowLayers do
                local g = d.glowLayers[i]
                if isDraw(g) and c["gVis"..i] ~= false then g.Visible = false; c["gVis"..i] = false end
            end
        end
    end
    if ESP.outline and ESP.box and not ESP.cornerBox and isDraw(d.outline) then
        local sz = Vector2.new(w+2, h+2)
        local ps = Vector2.new(x1-1, tY-1)
        if c.olSz ~= sz then d.outline.Size = sz; c.olSz = sz end
        if c.olPs ~= ps then d.outline.Position = ps; c.olPs = ps end
        if c.olCol ~= ESP.outlineColor then d.outline.Color = ESP.outlineColor; c.olCol = ESP.outlineColor end
        if c.olTh ~= ESP.outlineThick then d.outline.Thickness = ESP.outlineThick; c.olTh = ESP.outlineThick end
        local _olTr = fT(ESP.outlineTransp)
        if c.olTr ~= _olTr then d.outline.Transparency = _olTr; c.olTr = _olTr end
        if c.olVis ~= true then d.outline.Visible = true; c.olVis = true end
    else
        if isDraw(d.outline) and c.olVis ~= false then d.outline.Visible = false; c.olVis = false end
    end
    if ESP.cornerBox and ESP.box then
        local hx, hy = w*ESP.cornerLength, h*ESP.cornerLength
        local segs = {
            {Vector2.new(x1,tY), Vector2.new(x1+hx,tY)},
            {Vector2.new(x1,tY), Vector2.new(x1,tY+hy)},
            {Vector2.new(x2,tY), Vector2.new(x2-hx,tY)},
            {Vector2.new(x2,tY), Vector2.new(x2,tY+hy)},
            {Vector2.new(x1,bY), Vector2.new(x1+hx,bY)},
            {Vector2.new(x1,bY), Vector2.new(x1,bY-hy)},
            {Vector2.new(x2,bY), Vector2.new(x2-hx,bY)},
            {Vector2.new(x2,bY), Vector2.new(x2,bY-hy)},
        }
        for i=1, 8 do
            local cc = d.corners and d.corners[i]
            if isDraw(cc) then
                if c["cF"..i] ~= segs[i][1] then cc.From = segs[i][1]; c["cF"..i] = segs[i][1] end
                if c["cT"..i] ~= segs[i][2] then cc.To = segs[i][2]; c["cT"..i] = segs[i][2] end
                if c.cCol ~= color then cc.Color = color end
                if c.cTh ~= ESP.boxThick then cc.Thickness = ESP.boxThick end
                if c.cTr ~= ESP.boxTransp then cc.Transparency = ESP.boxTransp end
                if c.cVis ~= true then cc.Visible = true end
            end
        end
        c.cCol = color; c.cTh = ESP.boxThick; c.cTr = ESP.boxTransp; c.cVis = true
    else
        if c.cVis ~= false and d.corners then
            for i=1, 8 do
                if isDraw(d.corners[i]) then d.corners[i].Visible = false end
            end
            c.cVis = false
        end
    end
    if ESP.name and isDraw(d.label) then
        local ns = ESP.nameSize
        if ESP.nameScale then ns = math.clamp(math.floor(h*0.20), 8, ESP.nameSize) end
        local txt = getESPName(p)
        if ESP.nameShowHP and hum then
            txt = txt .. "  [" .. math.floor(hum.Health) .. "]"
        end
        if ESP.nameShowDistance then
            txt = txt .. "  " .. math.floor(dist) .. "m"
        end
        if ESP.nameShowWeapon then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then txt = txt .. "  • " .. tool.Name end
        end
        local pos = Vector2.new(cx, tY - ESP.nameOffset)
        local nc = ESP.nameColor
        if ESP.useTeamColor then nc = color end
        if c.nmTxt ~= txt then d.label.Text = txt; c.nmTxt = txt end
        if c.nmPs ~= pos then d.label.Position = pos; c.nmPs = pos end
        if c.nmCol ~= nc then d.label.Color = nc; c.nmCol = nc end
        if c.nmSz ~= ns then d.label.Size = ns; c.nmSz = ns end
        if c.nmF ~= ESP.font then d.label.Font = ESP.font; c.nmF = ESP.font end
        if c.nmVis ~= true then d.label.Visible = true; c.nmVis = true end
    else
        if isDraw(d.label) and c.nmVis ~= false then d.label.Visible = false; c.nmVis = false end
    end
    if ESP.health and hum and isDraw(d.health) and isDraw(d.healthBg) then
        local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
        local hc = healthColor(pct)
        local th = ESP.healthBarThickness
        local ls = ESP.healthBarLength
        local off = ESP.healthBarOffset
        if ESP.healthSide == "Right" then
            local bh = h*ls
            local by = tY + (h-bh)*0.5
            local bxx = x2 + off
            local bgsz, bgps = Vector2.new(th,bh), Vector2.new(bxx,by)
            local hsz, hps = Vector2.new(th,bh*pct), Vector2.new(bxx,by+bh*(1-pct))
            if c.hbBgSz ~= bgsz then d.healthBg.Size = bgsz; c.hbBgSz = bgsz end
            if c.hbBgPs ~= bgps then d.healthBg.Position = bgps; c.hbBgPs = bgps end
            if c.hbBgCol ~= ESP.healthBarBgColor then d.healthBg.Color = ESP.healthBarBgColor; c.hbBgCol = ESP.healthBarBgColor end
            if c.hbBgTr ~= ESP.healthBarBgTransp then d.healthBg.Transparency = ESP.healthBarBgTransp; c.hbBgTr = ESP.healthBarBgTransp end
            if c.hbBgVis ~= true then d.healthBg.Visible = true; c.hbBgVis = true end
            if c.hSz ~= hsz then d.health.Size = hsz; c.hSz = hsz end
            if c.hPs ~= hps then d.health.Position = hps; c.hPs = hps end
            if c.hCol ~= hc then d.health.Color = hc; c.hCol = hc end
            if c.hVis ~= true then d.health.Visible = true; c.hVis = true end
        else
            local bw = w*ls
            local bx = x1 + (w-bw)*0.5
            local by = bY + off
            local bgsz, bgps = Vector2.new(bw,th), Vector2.new(bx,by)
            local hsz, hps = Vector2.new(bw*pct,th), Vector2.new(bx,by)
            if c.hbBgSz ~= bgsz then d.healthBg.Size = bgsz; c.hbBgSz = bgsz end
            if c.hbBgPs ~= bgps then d.healthBg.Position = bgps; c.hbBgPs = bgps end
            if c.hbBgCol ~= ESP.healthBarBgColor then d.healthBg.Color = ESP.healthBarBgColor; c.hbBgCol = ESP.healthBarBgColor end
            if c.hbBgTr ~= ESP.healthBarBgTransp then d.healthBg.Transparency = ESP.healthBarBgTransp; c.hbBgTr = ESP.healthBarBgTransp end
            if c.hbBgVis ~= true then d.healthBg.Visible = true; c.hbBgVis = true end
            if c.hSz ~= hsz then d.health.Size = hsz; c.hSz = hsz end
            if c.hPs ~= hps then d.health.Position = hps; c.hPs = hps end
            if c.hCol ~= hc then d.health.Color = hc; c.hCol = hc end
            if c.hVis ~= true then d.health.Visible = true; c.hVis = true end
        end
    else
        if isDraw(d.healthBg) and c.hbBgVis ~= false then d.healthBg.Visible = false; c.hbBgVis = false end
        if isDraw(d.health) and c.hVis ~= false then d.health.Visible = false; c.hVis = false end
    end
    if ESP.healthText and hum and isDraw(d.healthText) then
        local txt = string.format("%d", math.floor(hum.Health))
        local baseY = tY - ESP.nameOffset
        if ESP.name then baseY = baseY - (ESP.nameSize+4) end
        local tp = Vector2.new(cx, baseY - ESP.healthTextOffsetY + 20)
        if c.hTxt ~= txt then d.healthText.Text = txt; c.hTxt = txt end
        if c.hTxtPs ~= tp then d.healthText.Position = tp; c.hTxtPs = tp end
        if c.hTxtSz ~= ESP.healthTextSize then d.healthText.Size = ESP.healthTextSize; c.hTxtSz = ESP.healthTextSize end
        if c.hTxtCol ~= ESP.healthTextColor then d.healthText.Color = ESP.healthTextColor; c.hTxtCol = ESP.healthTextColor end
        if c.hTxtF ~= ESP.font then d.healthText.Font = ESP.font; c.hTxtF = ESP.font end
        if c.hTxtVis ~= true then d.healthText.Visible = true; c.hTxtVis = true end
    else
        if isDraw(d.healthText) and c.hTxtVis ~= false then d.healthText.Visible = false; c.hTxtVis = false end
    end
    if ESP.tracer and isDraw(d.tracer) then
        local vp = CameraS.ViewportSize
        local src
        if ESP.tracerOrigin == "Center" then src = Vector2.new(vp.X*0.5, vp.Y*0.5)
        elseif ESP.tracerOrigin == "Top" then src = Vector2.new(vp.X*0.5, 0)
        else src = Vector2.new(vp.X*0.5, vp.Y) end
        local tgt = Vector2.new(cx, bY)
        if c.tFrom ~= src then d.tracer.From = src; c.tFrom = src end
        if c.tTo ~= tgt then d.tracer.To = tgt; c.tTo = tgt end
        if c.tCol ~= ESP.tracerColor then d.tracer.Color = ESP.tracerColor; c.tCol = ESP.tracerColor end
        if c.tVis ~= true then d.tracer.Visible = true; c.tVis = true end
    else
        if isDraw(d.tracer) and c.tVis ~= false then d.tracer.Visible = false; c.tVis = false end
    end
    if ESP.distance and isDraw(d.dist) then
        local txt = string.format("[%d]", math.floor(dist))
        local pos = Vector2.new(cx, bY+2)
        if c.dTxt ~= txt then d.dist.Text = txt; c.dTxt = txt end
        if c.dPs ~= pos then d.dist.Position = pos; c.dPs = pos end
        if c.dSz ~= ESP.distSize then d.dist.Size = ESP.distSize; c.dSz = ESP.distSize end
        if c.dVis ~= true then d.dist.Visible = true; c.dVis = true end
    else
        if isDraw(d.dist) and c.dVis ~= false then d.dist.Visible = false; c.dVis = false end
    end
    -- ── skeleton (full R15 / R6 fallback v2) ──
    if ESP.skeleton and d.skel then
        local function gp(...)
            for _, n in ipairs({...}) do
                local p = char:FindFirstChild(n)
                if p then return p end
            end
        end
        local jHead = gp("Head")
        local jUT   = gp("UpperTorso", "Torso")
        local jLT   = gp("LowerTorso", "Torso")
        local jLUA  = gp("LeftUpperArm", "Left Arm")
        local jLLA  = gp("LeftLowerArm")
        local jLH   = gp("LeftHand")
        local jRUA  = gp("RightUpperArm", "Right Arm")
        local jRLA  = gp("RightLowerArm")
        local jRH   = gp("RightHand")
        local jLUL  = gp("LeftUpperLeg", "Left Leg")
        local jLLL  = gp("LeftLowerLeg")
        local jLF   = gp("LeftFoot")
        local jRUL  = gp("RightUpperLeg", "Right Leg")
        local jRLL  = gp("RightLowerLeg")
        local jRF   = gp("RightFoot")

        local function spAt(pos)
            local v = CameraS:WorldToViewportPoint(pos)
            if v.Z > 0 then return Vector2.new(v.X, v.Y) end
        end
        local function sp(p)
            if not p then return nil end
            return spAt(p.Position)
        end
        -- R6 helper: get top / mid / bottom of a limb by CFrame.UpVector
        local function partTop(p)
            if not p then return nil end
            return spAt(p.Position + p.CFrame.UpVector * (p.Size.Y * 0.5))
        end
        local function partMid(p)
            if not p then return nil end
            return spAt(p.Position)
        end
        local function partBot(p)
            if not p then return nil end
            return spAt(p.Position - p.CFrame.UpVector * (p.Size.Y * 0.5))
        end
        -- choose R15 vs R6 automatically
        local isR6 = (jLLA == nil)
        local P = {}

        if isR6 then
            -- ────── R6 ──────
            local jT = jUT  -- Torso
            P.head  = sp(jHead)
            P.neck  = partTop(jT)
            P.spine = partBot(jT)
            P.lsh   = partTop(jLUA); P.lel = partMid(jLUA); P.lhd = partBot(jLUA)
            P.rsh   = partTop(jRUA); P.rel = partMid(jRUA); P.rhd = partBot(jRUA)
            P.lhip  = partTop(jLUL); P.lkn = partMid(jLUL); P.lft = partBot(jLUL)
            P.rhip  = partTop(jRUL); P.rkn = partMid(jRUL); P.rft = partBot(jRUL)
        else
            -- ────── R15 ──────
            P.head  = sp(jHead)
            P.neck  = sp(jUT)
            P.spine = sp(jLT)
            P.lsh   = sp(jLUA); P.lel = sp(jLLA) or sp(jLH); P.lhd = sp(jLH)  or sp(jLLA)
            P.rsh   = sp(jRUA); P.rel = sp(jRLA) or sp(jRH); P.rhd = sp(jRH)  or sp(jRLA)
            P.lhip  = sp(jLUL); P.lkn = sp(jLLL) or sp(jLF); P.lft = sp(jLF)  or sp(jLLL)
            P.rhip  = sp(jRUL); P.rkn = sp(jRLL) or sp(jRF); P.rft = sp(jRF)  or sp(jRLL)
        end

        local segs = {
            {P.head,  P.neck},   --  1 neck
            {P.neck,  P.spine},  --  2 spine
            {P.neck,  P.lsh},    --  3 left clavicle
            {P.lsh,   P.lel},    --  4 left upper arm
            {P.lel,   P.lhd},    --  5 left forearm
            {P.neck,  P.rsh},    --  6 right clavicle
            {P.rsh,   P.rel},    --  7 right upper arm
            {P.rel,   P.rhd},    --  8 right forearm
            {P.spine, P.lhip},   --  9 left pelvis
            {P.lhip,  P.lkn},    -- 10 left thigh
            {P.lkn,   P.lft},    -- 11 left calf
            {P.spine, P.rhip},   -- 12 right pelvis
            {P.rhip,  P.rkn},    -- 13 right thigh
            {P.rkn,   P.rft},    -- 14 right calf
        }
        local skelCol = ESP.skeletonColor
        if ESP.useTeamColor then skelCol = color end
        local skelTr = fT(ESP.skeletonTransp)
        for i = 1, 14 do
            local ln = d.skel[i]
            if isDraw(ln) and segs[i][1] and segs[i][2] then
                pcall(function()
                    ln.From = segs[i][1]
                    ln.To   = segs[i][2]
                    ln.Color = skelCol
                    ln.Thickness = ESP.skeletonThick
                    ln.Transparency = skelTr
                    ln.Visible = true
                end)
            elseif isDraw(ln) then
                pcall(function() ln.Visible = false end)
            end
        end
    elseif d.skel then
        for i = 1, 14 do
            if isDraw(d.skel[i]) then
                pcall(function() d.skel[i].Visible = false end)
            end
        end
    end

    -- ── health-based color override ──
    if ESP.healthBasedColor and hum then
        local pct = math.clamp(hum.Health/math.max(hum.MaxHealth,1), 0, 1)
        local hc = Color3.fromRGB(255*(1-pct), 255*pct, 0)
        if isDraw(d.box) then pcall(function() d.box.Color = hc end) end
        if isDraw(d.label) then pcall(function() d.label.Color = hc end) end
    end

    -- ── weapon name ──
    if ESP.weaponName and isDraw(d.weaponLabel) then
        local tool = char:FindFirstChildOfClass("Tool")
        local wname = tool and tool.Name or ""
        if wname ~= "" then
            pcall(function()
                d.weaponLabel.Text = wname
                d.weaponLabel.Position = Vector2.new(cx, bY + 18)
                d.weaponLabel.Color = ESP.weaponColor
                d.weaponLabel.Size = 12
                d.weaponLabel.Visible = true
            end)
        else
            pcall(function() d.weaponLabel.Visible = false end)
        end
    elseif isDraw(d.weaponLabel) then
        pcall(function() d.weaponLabel.Visible = false end)
    end

    if ESP.headDot and isDraw(d.headDot) then
        local hs = CameraS:WorldToViewportPoint(head.Position)
        if hs.Z > 0 then
            local r = ESP.headDotSize
            if ESP.headDotScale then r = math.clamp(math.floor(h*0.06), 3, ESP.headDotSize) end
            local p2 = Vector2.new(hs.X, hs.Y)
            if c.hdPs ~= p2 then d.headDot.Position = p2; c.hdPs = p2 end
            if c.hdR ~= r then d.headDot.Radius = r; c.hdR = r end
            if c.hdCol ~= ESP.headDotColor then d.headDot.Color = ESP.headDotColor; c.hdCol = ESP.headDotColor end
            if c.hdTr ~= ESP.headDotTransp then d.headDot.Transparency = ESP.headDotTransp; c.hdTr = ESP.headDotTransp end
            if c.hdFilled ~= ESP.headDotFilled then d.headDot.Filled = ESP.headDotFilled; c.hdFilled = ESP.headDotFilled end
            if c.hdTh ~= ESP.headDotThickness then d.headDot.Thickness = ESP.headDotThickness; c.hdTh = ESP.headDotThickness end
            if c.hdVis ~= true then d.headDot.Visible = true; c.hdVis = true end
        else
            if c.hdVis ~= false then d.headDot.Visible = false; c.hdVis = false end
        end
    else
        if isDraw(d.headDot) and c.hdVis ~= false then d.headDot.Visible = false; c.hdVis = false end
    end
end

-- local chams
local function clearLocalChams(p)
    local list = localChamsCache[p]
    if list then
        for _, h in ipairs(list) do pcall(function() h:Destroy() end) end
    end
    localChamsCache[p] = nil
    localChamsValsCache[p] = nil
end
local function buildLocalChams(p)
    clearLocalChams(p)
    local char = p.Character
    if not char or not char.Parent then return end
    local list = {}
    local fillCol = Chams.fillColor
    if Chams.rainbow then
        fillCol = Color3.fromHSV((tick()*Chams.rainbowSpeed*0.2)%1, 1, 1)
    end
    local outlineTr = Chams.outlineEnabled and Chams.outlineTransp or 1
    local mode = Chams.depthMode or "Both"

    if mode == "Both" then
        local occ = Instance.new("Highlight")
        occ.Name = PREFIX.."LocalChamOcc"; occ.Adornee = char
        occ.DepthMode = Enum.HighlightDepthMode.Occluded
        occ.FillColor = fillCol; occ.FillTransparency = Chams.fillTransp
        occ.OutlineColor = Chams.outlineColor
        occ.OutlineTransparency = outlineTr
        occ.Parent = WorkspaceS
        list[1] = occ

        local onTop = Instance.new("Highlight")
        onTop.Name = PREFIX.."LocalChamTop"; onTop.Adornee = char
        onTop.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        onTop.FillColor = fillCol; onTop.FillTransparency = Chams.fillTransp
        onTop.OutlineColor = Chams.outlineColor
        onTop.OutlineTransparency = outlineTr
        onTop.Parent = WorkspaceS
        list[2] = onTop
    elseif mode == "Occluded" then
        local occ = Instance.new("Highlight")
        occ.Name = PREFIX.."LocalChamOcc"; occ.Adornee = char
        occ.DepthMode = Enum.HighlightDepthMode.Occluded
        occ.FillColor = fillCol; occ.FillTransparency = Chams.fillTransp
        occ.OutlineColor = Chams.outlineColor
        occ.OutlineTransparency = outlineTr
        occ.Parent = WorkspaceS
        list[1] = occ
    elseif mode == "AlwaysOnTop" then
        local onTop = Instance.new("Highlight")
        onTop.Name = PREFIX.."LocalChamTop"; onTop.Adornee = char
        onTop.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        onTop.FillColor = fillCol; onTop.FillTransparency = Chams.fillTransp
        onTop.OutlineColor = Chams.outlineColor
        onTop.OutlineTransparency = outlineTr
        onTop.Parent = WorkspaceS
        list[1] = onTop
    end
    localChamsCache[p] = list
end
local function updateLocalChams(p)
    if not Chams.enabled then
        if localChamsCache[p] then clearLocalChams(p) end
        return
    end
    if Chams.teamCheck and p.Team ~= nil and p.Team == LocalPlayerS.Team then
        if localChamsCache[p] then clearLocalChams(p) end
        return
    end
    if isTeamNoDraw(p) then
        if localChamsCache[p] then clearLocalChams(p) end
        return
    end
    -- ─── distance optimization ───
    local maxD = Chams.maxDistance or 0
    if maxD > 0 then
        local myChar = LocalPlayerS.Character
        local tChar  = p.Character
        if not myChar or not tChar then
            if localChamsCache[p] then clearLocalChams(p) end
            return
        end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local tRoot  = tChar:FindFirstChild("HumanoidRootPart")
        if not myRoot or not tRoot then
            if localChamsCache[p] then clearLocalChams(p) end
            return
        end
        local dx = myRoot.Position.X - tRoot.Position.X
        local dy = myRoot.Position.Y - tRoot.Position.Y
        local dz = myRoot.Position.Z - tRoot.Position.Z
        if (dx*dx + dy*dy + dz*dz) > (maxD*maxD) then
            if localChamsCache[p] then clearLocalChams(p) end
            return
        end
    end
    -- ─── end distance optimization ───
    local wl = isWhitelisted(p)
    if wl and Chams.skipWhitelist and not Chams.useWhitelistColor then
        if localChamsCache[p] then clearLocalChams(p) end
        return
    end
    local char = p.Character
    if not char then clearLocalChams(p); return end
    local list = localChamsCache[p]
    if not list or #list == 0 or (list[1] and list[1].Adornee ~= char) then
        buildLocalChams(p); return
    end
    local wantBoth = (Chams.depthMode == "Both")
    local hasBoth = (#list == 2)
    if wantBoth ~= hasBoth and Chams.depthMode ~= nil then
        buildLocalChams(p); return
    end

    local fillCol = Chams.fillColor
    local isTarget = (_G.PRIMO_TARGETS and _G.PRIMO_TARGETS[p] == true)
        or (_G.PRIMO_TARGET == p)
    if isTarget and Chams.useTargetColor then
        fillCol = Chams.targetColor
    elseif Chams.useWhitelistColor and isWhitelisted(p) then
        fillCol = Chams.whitelistColor
    elseif Chams.rainbow then
        fillCol = Color3.fromHSV((tick()*Chams.rainbowSpeed*0.2)%1, 1, 1)
    end

    local outlineTr = Chams.outlineEnabled and Chams.outlineTransp or 1
    local cache = localChamsValsCache[p]
    if not cache then cache = {}; localChamsValsCache[p] = cache end
    for _, h in ipairs(list) do
        if h and h.Parent then
            if cache.fillCol ~= fillCol then h.FillColor = fillCol end
            if cache.fillTr ~= Chams.fillTransp then h.FillTransparency = Chams.fillTransp end
            if cache.outCol ~= Chams.outlineColor then h.OutlineColor = Chams.outlineColor end
            if cache.outTr ~= outlineTr then h.OutlineTransparency = outlineTr end
        end
    end
    cache.fillCol = fillCol
    cache.fillTr = Chams.fillTransp
    cache.outCol = Chams.outlineColor
    cache.outTr = outlineTr
end

local function clearSelfChams()
    if selfChamsCache then
        for _, h in ipairs(selfChamsCache) do pcall(function() h:Destroy() end) end
    end
    selfChamsCache = nil
end

local function buildSelfChams()
    clearSelfChams()
    local char = LocalPlayerS.Character
    if not char or not char.Parent then return end
    local list = {}
    local fillCol = SelfChams.fillColor
    if SelfChams.rainbow then
        fillCol = Color3.fromHSV((tick()*SelfChams.rainbowSpeed*0.2)%1, 1, 1)
    end
    local outlineTr = SelfChams.outlineEnabled and SelfChams.outlineTransp or 1
    local mode = SelfChams.depthMode or "Both"

    if mode == "Both" then
        local occ = Instance.new("Highlight")
        occ.Name = PREFIX.."SelfChamOcc"; occ.Adornee = char
        occ.DepthMode = Enum.HighlightDepthMode.Occluded
        occ.FillColor = fillCol; occ.FillTransparency = SelfChams.fillTransp
        occ.OutlineColor = SelfChams.outlineColor
        occ.OutlineTransparency = outlineTr
        occ.Parent = WorkspaceS
        list[1] = occ

        local onTop = Instance.new("Highlight")
        onTop.Name = PREFIX.."SelfChamTop"; onTop.Adornee = char
        onTop.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        onTop.FillColor = fillCol; onTop.FillTransparency = SelfChams.fillTransp
        onTop.OutlineColor = SelfChams.outlineColor
        onTop.OutlineTransparency = outlineTr
        onTop.Parent = WorkspaceS
        list[2] = onTop
    elseif mode == "Occluded" then
        local occ = Instance.new("Highlight")
        occ.Name = PREFIX.."SelfChamOcc"; occ.Adornee = char
        occ.DepthMode = Enum.HighlightDepthMode.Occluded
        occ.FillColor = fillCol; occ.FillTransparency = SelfChams.fillTransp
        occ.OutlineColor = SelfChams.outlineColor
        occ.OutlineTransparency = outlineTr
        occ.Parent = WorkspaceS
        list[1] = occ
    elseif mode == "AlwaysOnTop" then
        local onTop = Instance.new("Highlight")
        onTop.Name = PREFIX.."SelfChamTop"; onTop.Adornee = char
        onTop.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        onTop.FillColor = fillCol; onTop.FillTransparency = SelfChams.fillTransp
        onTop.OutlineColor = SelfChams.outlineColor
        onTop.OutlineTransparency = outlineTr
        onTop.Parent = WorkspaceS
        list[1] = onTop
    end
    selfChamsCache = list
end

local function updateSelfChams()
    if not SelfChams.enabled then
        if selfChamsCache then clearSelfChams() end
        return
    end
    local char = LocalPlayerS.Character
    if not char or not char.Parent then
        if selfChamsCache then clearSelfChams() end
        return
    end
    if not selfChamsCache or #selfChamsCache == 0
        or (selfChamsCache[1] and selfChamsCache[1].Adornee ~= char) then
        buildSelfChams(); return
    end
    local wantBoth = (SelfChams.depthMode == "Both")
    local hasBoth = (#selfChamsCache == 2)
    if wantBoth ~= hasBoth then
        buildSelfChams(); return
    end
    local fillCol = SelfChams.fillColor
    if SelfChams.rainbow then
        fillCol = Color3.fromHSV((tick()*SelfChams.rainbowSpeed*0.2)%1, 1, 1)
    end
    local outlineTr = SelfChams.outlineEnabled and SelfChams.outlineTransp or 1
    local cache = _G.__PRIMO_SELFCHAMS_CACHE
    if not cache then cache = {}; _G.__PRIMO_SELFCHAMS_CACHE = cache end
    for _, h in ipairs(selfChamsCache) do
        if h and h.Parent then
            if cache.fillCol ~= fillCol then h.FillColor = fillCol end
            if cache.fillTr ~= SelfChams.fillTransp then h.FillTransparency = SelfChams.fillTransp end
            if cache.outCol ~= SelfChams.outlineColor then h.OutlineColor = SelfChams.outlineColor end
            if cache.outTr ~= outlineTr then h.OutlineTransparency = outlineTr end
        end
    end
    cache.fillCol = fillCol
    cache.fillTr = SelfChams.fillTransp
    cache.outCol = SelfChams.outlineColor
    cache.outTr = outlineTr
end

-- check if target player is near crosshair (for kill attribution)
local function isPlayerNearCrosshair(p, thresholdPx)
    if not p then return false end
    local cam = CameraS
    if not cam then return false end
    local tChar = p.Character
    if not tChar then return false end
    local root = tChar:FindFirstChild("HumanoidRootPart")
        or tChar:FindFirstChild("Head")
    if not root then return false end
    local sp, on = cam:WorldToViewportPoint(root.Position)
    if not on or sp.Z <= 0 then return false end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X*0.5, vp.Y*0.5)
    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
    return d < (thresholdPx or 180)
end

-- strict: raycast from crosshair must hit target (or its extended hitbox)
local _xhairRP = RaycastParams.new()
_xhairRP.FilterType = Enum.RaycastFilterType.Exclude
_xhairRP.IgnoreWater = true

local function isCrosshairOnPlayer(p)
    if not p then return false end
    local cam = CameraS
    if not cam then return false end
    local tChar = p.Character
    if not tChar then return false end
    local myChar = LocalPlayerS.Character
    if not myChar then return false end
    _xhairRP.FilterDescendantsInstances = {myChar}
    local ok, res = pcall(function()
        return WorkspaceS:Raycast(cam.CFrame.Position,
            cam.CFrame.LookVector * 5000, _xhairRP)
    end)
    if not ok or not res or not res.Instance then return false end
    local model = res.Instance:FindFirstAncestorOfClass("Model")
    return model == tChar
end

-- ─── resolve part by name (was accidentally removed) ───
local function resolvePart(char, name)
    if not char then return nil end
    local pt = char:FindFirstChild(name)
    if pt and pt:IsA("BasePart") then return pt end
    return nil
end

-- хэш конфига targetParts / multiPoints (быстрый, без аллокаций)
local function _aimTargetsHash()
    local h = 5381
    for n, on in pairs(Aimbot.targetParts or {}) do
        if on then
            for i = 1, #n do h = ((h * 33) + n:byte(i)) % 2147483647 end
        end
    end
    for n, on in pairs(Aimbot.multiPoints or {}) do
        if on then
            for i = 1, #n do h = ((h * 33) + n:byte(i) + 7) % 2147483647 end
        end
    end
    return h
end
local _partsCache = {}   -- [char] = { hash, parts }

local function getAllParts(char)
    if not char then return {} end
    local hash = _aimTargetsHash()
    local hasClosest = Aimbot.targetParts and Aimbot.targetParts["Closest"]

    local staticParts
    local cached = _partsCache[char]
    if cached and cached.hash == hash then
        local ok = true
        for i = 1, #cached.parts do
            local pt = cached.parts[i]
            if not pt or not pt.Parent then ok = false break end
        end
        if ok then staticParts = cached.parts end
    end

    if not staticParts then
        staticParts = {}
        local list = {}
        for n, on in pairs(Aimbot.multiPoints or {}) do
            if on then list[#list+1] = n end
        end
        for _, n in ipairs(list) do
            local p = resolvePart(char, n)
            if p then staticParts[#staticParts+1] = p end
        end
        local singles = {}
        for n, on in pairs(Aimbot.targetParts or {}) do
            if on and n ~= "Closest" then singles[#singles+1] = n end
        end
        for _, n in ipairs(singles) do
            local p = resolvePart(char, n)
            if p then staticParts[#staticParts+1] = p end
        end
        _partsCache[char] = { hash = hash, parts = staticParts }
    end

    local parts
    if hasClosest then
        parts = {}
        for i = 1, #staticParts do parts[i] = staticParts[i] end
        local cam = CameraS.CFrame.Position
        local best, bd = nil, math.huge
        for _, name in ipairs({"Head","UpperTorso","LowerTorso","Torso","HumanoidRootPart"}) do
            local p = resolvePart(char, name)
            if p then
                local dd = (p.Position - cam).Magnitude
                if dd < bd then best = p; bd = dd end
            end
        end
        if best then parts[#parts+1] = best end
    else
        parts = staticParts
    end

    if #parts == 0 then
        local h = resolvePart(char, "Head")
        if h then return { h } end
    end
    if #parts == 0 then
        local ext = char:FindFirstChild(HITBOX_TAG)
        if ext and ext:IsA("BasePart") then return { ext } end
    end
    return parts
end
local function _aimLockPartName()
    -- возвращает имя part-а, в который нужно целиться по биндам, или nil
    for _, field in ipairs(Aimbot.lockPriority or {}) do
        local bind = Aimbot[field]
        if bind and keyHeld(bind) then
            if field == "bindHead"    then return "Head" end
            if field == "bindTorso"   then return "UpperTorso" end
            if field == "bindHRP"     then return "HumanoidRootPart" end
            if field == "bindClosest" then return "__closest" end
        end
    end
    return nil
end

function getAimPart(char)
    -- bodypart-lock перебивает всё
    local forced = _aimLockPartName()
    if forced == "__closest" then
        local parts = getAllParts(char)
        if #parts == 0 then return nil end
        local vp = CameraS.ViewportSize
        local sc = Vector2.new(vp.X*0.5, vp.Y*0.5)
        local best, bd = nil, math.huge
        for _, pt in ipairs(parts) do
            local sp, on = CameraS:WorldToViewportPoint(pt.Position)
            if on and sp.Z > 0 then
                local dd = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
                if dd < bd then best = pt; bd = dd end
            end
        end
        return best
    elseif forced then
        local p = char:FindFirstChild(forced)
        if p and p:IsA("BasePart") then return p end
        if forced == "UpperTorso" then
            p = char:FindFirstChild("Torso")
            if p then return p end
        end
    end
    -- обычная логика
    local parts = getAllParts(char)
    if #parts == 0 then return nil end
    if #parts == 1 then return parts[1] end
    local vp = CameraS.ViewportSize
    local sc = Vector2.new(vp.X*0.5, vp.Y*0.5)
    local best, bd = nil, math.huge
    for _, pt in ipairs(parts) do
        local sp, on = CameraS:WorldToViewportPoint(pt.Position)
        if on and sp.Z > 0 then
            local dd = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
            if dd < bd then best = pt; bd = dd end
        end
    end
    if best then return best end
    return parts[1]
end
-- переиспользуемый RaycastParams для проверки видимости
local _aimVisRP = RaycastParams.new()
_aimVisRP.FilterType = Enum.RaycastFilterType.Exclude
_aimVisRP.IgnoreWater = true

function aimVisible(tChar, tPart)
    if not tPart or not tChar then return false end
    local char = LocalPlayerS.Character
    if not char then return false end
    _aimVisRP.FilterDescendantsInstances = {char, tChar}
    local origin = CameraS.CFrame.Position
    local dir = tPart.Position - origin
    local dist = dir.Magnitude
    if dist < 0.1 then return true end
    local res = WorkspaceS:Raycast(origin, (dir / dist) * (dist - 0.25), _aimVisRP)
    return res == nil
end

-- ── проверка стены по позиции (для autoshoot: target.pos) ──
local function aimVisiblePos(tChar, pos)
    if not tChar or not pos then return false end
    local char = LocalPlayerS.Character
    if not char then return false end
    _aimVisRP.FilterDescendantsInstances = {char, tChar}
    local origin = CameraS.CFrame.Position
    local dir = pos - origin
    local dist = dir.Magnitude
    if dist < 0.1 then return true end
    local res = WorkspaceS:Raycast(origin, (dir / dist) * (dist - 0.25), _aimVisRP)
    return res == nil
end
function isKnocked(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return true end
    if hum:GetState() == Enum.HumanoidStateType.Dead then return true end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp:GetAttribute("Knocked") or hrp:GetAttribute("Downed")) then return true end
    return false
end
local function aimShouldTarget(p)
    if p == LocalPlayerS then return false end
    if Aimbot.skipFriends and isWhitelisted(p) then return false end  
    if not p.Character then return false end
    if Aimbot.teamCheck and p.Team ~= nil and p.Team == LocalPlayerS.Team then return false end
    if isTeamNoDraw(p) then return false end
    -- forcefield check: skip players with active spawn protection
    if Aimbot.forcefieldCheck and p.Character:FindFirstChildOfClass("ForceField") then
        return false
    end
    if Aimbot.aliveCheck then
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
    end
    if Aimbot.skipKnocked and isKnocked(p.Character) then return false end
    return true
end
local function isNPC(m)
    if not m:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(m) then return false end
    return m:FindFirstChildOfClass("Humanoid") ~= nil
end
local _npcCache = {}
local _npcCacheTime = 0
local function collectNPCs()
    if not Aimbot.targetNPCs and not Aimbot.triggerNPCs then
        return _npcCache
    end
    local now = tick()
    if now - _npcCacheTime < 3 then return _npcCache end
    _npcCacheTime = now
    local list = {}
    for _, obj in ipairs(WorkspaceS:GetDescendants()) do
        if isNPC(obj) then list[#list+1] = obj end
    end
    _npcCache = list
    return list
end
-- ═══════════════════════════════════════════════════════════
-- RESOLVER — итеративное решение времени полёта пули
-- ═══════════════════════════════════════════════════════════
function resolverPredict(tPart, tChar, projSpeed, projGravity, predPct)
    if not tPart or not tChar then return tPart and tPart.Position or Vector3.zero end
    local origin = CameraS.CFrame.Position
    local targetPos = tPart.Position

    -- velocity цели
    local vel = Vector3.zero
    local hrp = tChar:FindFirstChild("HumanoidRootPart")
    if hrp then
        vel = hrp.AssemblyLinearVelocity
    end

    -- авто-компенсация 20% если юзер выкрутил 0
    local pct = predPct or Aimbot.prediction
    if pct <= 0 then pct = 20 end
    pct = pct / 100

    if projSpeed <= 0 then
        -- хитроболь: без скорости пули используем просто линейную экстраполяцию 0.1с
        return targetPos + vel * 0.1 * pct
    end

    -- итеративный solver (4 шага достаточно для 99% случаев)
    local guess = targetPos
    for _ = 1, 4 do
        local dist = (guess - origin).Magnitude
        local t = dist / projSpeed
        guess = targetPos + vel * (t * pct)
    end

    -- гравитационная компенсация
    if projGravity and projGravity > 0 then
        local finalDist = (guess - origin).Magnitude
        local t = finalDist / projSpeed
        local gcorr = 1 - (Aimbot.gravityCorrection or 0) / 100
        guess = guess + Vector3.new(0, 0.5 * projGravity * t * t * gcorr, 0)
    end

    return guess
end

local function getPred(tPart, tChar, dist)
    return resolverPredict(tPart, tChar,
        Aimbot.projSpeed or 150,
        Aimbot.projGravity or 0,
        Aimbot.prediction or 20)
end
-- собирает ВСЕХ кандидатов, отсортированных по приоритету
local function findTargetCandidates()
    local char = LocalPlayerS.Character
    if not char then return {} end
    local myH = char:FindFirstChild("HumanoidRootPart")
    if not myH then return {} end
    local vp = CameraS.ViewportSize
    local sc = Vector2.new(vp.X*0.5, vp.Y*0.5)
    local fovPx = Aimbot.fov * (vp.Y/FOV_REF_H)
    local out = {}

    local function eval(tChar, pObj)
        if not tChar then return end
        local part = getAimPart(tChar)
        if not part then return end
        local d3 = (part.Position - myH.Position).Magnitude
        if d3 > Aimbot.maxDist then return end
        local tPos = getPred(part, tChar, d3)
        local sp, on = CameraS:WorldToViewportPoint(tPos)
        if not on or sp.Z <= 0 then return end
        local sd = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
        if sd > fovPx then return end
        if Aimbot.wallCheck and not aimVisible(tChar, part) then return end
        local score = sd
        if Aimbot.priority == "Closest" then score = d3
        elseif Aimbot.priority == "LowestHealth" then
            local hum = tChar:FindFirstChildOfClass("Humanoid")
            if hum then score = hum.Health else score = 0 end
        elseif Aimbot.priority == "HighestHealth" then
            local hum = tChar:FindFirstChildOfClass("Humanoid")
            if hum then score = 100000 - hum.Health else score = 0 end
        end
        if _G.PRIMO_TARGETS and pObj and _G.PRIMO_TARGETS[pObj] then
            score = score - 5000000
        end
        out[#out+1] = {
            player = pObj, char = tChar, part = part,
            pos = tPos, screenDist = sd, dist3D = d3, score = score,
        }
    end

    if Aimbot.targetPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if aimShouldTarget(p) then eval(p.Character, p) end
        end
    end
    if Aimbot.targetNPCs then
        for _, obj in ipairs(collectNPCs()) do
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then eval(obj, nil) end
        end
    end
    table.sort(out, function(a, b) return a.score < b.score end)
    return out
end

local function findTarget()
    local candidates = findTargetCandidates()
    if #candidates == 0 then return nil end

    local now = tick()

    -- ── FOV SWITCHER logic ──
    if Aimbot.switchOnLeave then
        local cur = Aimbot._switchState.current
        local curValid = false
        if cur and cur.Parent then
            for _, c in ipairs(candidates) do
                if c.player == cur then curValid = true break end
            end
        end
        if not curValid then
            -- текущая цель вышла из FOV или умерла
            if Aimbot._switchState.leftAt == nil then
                Aimbot._switchState.leftAt = now
            end
            -- удерживаем «призрака» не дольше switchDelay, потом переключаемся
            if now - Aimbot._switchState.leftAt < Aimbot.switchDelay then
                -- ищем любую валидную позицию прежней цели, чтобы не дёргаться
                local ghost = Aimbot._currentTarget
                if ghost and ghost.player == cur and ghost.char and ghost.char.Parent then
                    return ghost
                end
            end
        else
            Aimbot._switchState.leftAt = nil
        end
    end

    -- sticky target (как и раньше)
    local sticky = Aimbot._stickyTarget
    if sticky and sticky.char and sticky.char.Parent
        and sticky.player and sticky.player.Parent
        and Aimbot._stickyTimer and Aimbot._stickyTimer > 0 then
        for _, c in ipairs(candidates) do
            if c.player == sticky.player then return c end
        end
    end

    local pick = candidates[1]

    -- запоминаем смену
    if Aimbot.switchOnLeave then
        if not Aimbot._switchState.current
            or Aimbot._switchState.current ~= pick.player then
            Aimbot._switchState.current = pick.player
            Aimbot._switchState.leftAt = nil
        end
    end

    return pick
end
-- Кривая для сглаживания. t = 0..1 → возвращает модифицированный t (0..1)
local function _applyCurve(t)
    local c = Aimbot.smoothCurve
    if c == "linear" then
        return t
    elseif c == "ease-in" then
        return t*t
    elseif c == "ease-out" then
        return 1 - (1-t)*(1-t)
    elseif c == "ease-in-out" then
        if t < 0.5 then return 2*t*t end
        return 1 - ((-2*t + 2)^2) / 2
    elseif c == "bezier" then
        -- кубическая bezier через (0,0) → P1 → P2 → (1,1)
        -- параметр t НЕ совпадает с координатой X на кривой,
        -- поэтому делаем 4 итерации Newton-Бисекции для восстановления X
        local x1 = Aimbot.bezierP1[1]; local y1 = Aimbot.bezierP1[2]
        local x2 = Aimbot.bezierP2[1]; local y2 = Aimbot.bezierP2[2]
        local function bez(a, b, u)
            local mu = 1 - u
            return 3*mu*mu*u*a + 3*mu*u*u*b + u*u*u
        end
        local lo, hi = 0, 1
        local u = t
        for _ = 1, 12 do
            local xU = bez(x1, x2, u)
            if math.abs(xU - t) < 1e-4 then break end
            if xU < t then lo = u else hi = u end
            u = (lo + hi) * 0.5
        end
        return bez(y1, y2, u)
    end
    return t
end

-- утилита: включён ли шифтлок / first-person (т.е. камеру крутит игра, а не мы)
local function _isShiftLockActive()
    local char = LocalPlayerS.Character
    if not char then return false end
    local mb
    local ok = pcall(function() mb = UserInputService.MouseBehavior end)
    if ok and mb then
        if mb == Enum.MouseBehavior.LockCenter then return true end
        local lockCur = Enum.MouseBehavior.LockCurrentPosition
        if lockCur and mb == lockCur then return true end
    end
    -- fallback: если Roblox сам спрятал иконку — считаем что шифтлок/1st person
    if UserInputService.MouseIconEnabled == false then return true end
    return false
end

local function aimLock(t)
    if not t then return end
    if _G.__PRIMO_MENU_OPEN then return end
    local pos = t.pos
    local cam = CameraS
    if not cam then return end
    if Aimbot.blatant or Aimbot.method == "Position" or Aimbot.method == "CameraSnap" then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
        return
    end
    do
        local char = LocalPlayerS.Character
        local isThirdPerson = false
        local mb
        local ok = pcall(function() mb = UserInputService.MouseBehavior end)
        if ok and mb and mb == Enum.MouseBehavior.LockCenter then
            isThirdPerson = true
        end
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                local dist = (cam.CFrame.Position - head.Position).Magnitude
                if dist > 3 then isThirdPerson = true end
            end
        end
    if isThirdPerson then
        local cf = cam.CFrame
        local dir = pos - cf.Position
        if dir.Magnitude < 0.01 then return end
                local localDir = cf:VectorToObjectSpace(dir.Unit)
                local yaw   = -math.deg(math.atan2(localDir.X, -localDir.Z))
                local pitch =  math.deg(math.asin(math.clamp(localDir.Y, -1, 1)))
                local gameSens = UserInputService.MouseDeltaSensitivity
                if type(gameSens) ~= "number" or gameSens <= 0 then gameSens = 1 end
                local sm = Aimbot.smoothness * Aimbot.sensitivity
                sm = math.clamp(sm, 0.02, 1.0)
                if Aimbot.blatant then sm = 1.0 else sm = _applyCurve(sm) end
                local dx = math.clamp((yaw / gameSens) * sm, -60, 60)
                local dy = math.clamp((pitch / gameSens) * sm, -60, 60)
                local moved = false
                if type(mousemoverel) == "function" then
                    moved = pcall(mousemoverel, dx, dy)
                end
                if not moved and type(mousemover) == "function" then
                    local cur = UserInputService:GetMouseLocation()
                    moved = pcall(mousemover, cur.X + dx, cur.Y + dy)
                end
                if not moved and type(mousemoveabs) == "function" then
                    local vp = cam.ViewportSize
                    pcall(mousemoveabs, vp.X*0.5 + dx, vp.Y*0.5 + dy)
                    moved = true
                end
                if not moved then
                    pcall(function()
                        local VIM = game:GetService("VirtualInputManager")
                        local cur = UserInputService:GetMouseLocation()
                        VIM:SendMouseMoveEvent(cur.X + dx, cur.Y + dy, game)
                    end)
                end
            return
        end
    end

    -- ── BLATANT / CameraSnap — жёстко ставим камеру ──
    if Aimbot.blatant or Aimbot.method == "Position" or Aimbot.method == "CameraSnap" then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, pos)
        return
    end

    -- ── SHIFT-LOCK / FIRST-PERSON — двигаем САМ КУРСОР, а не камеру ──
    -- Иначе Roblox-контроллер камеры перезатрёт CFrame на следующем кадре.
    if _isShiftLockActive() then
        local cf = cam.CFrame
        local origin = cf.Position
        local dir = pos - origin
        if dir.Magnitude < 0.01 then return end
        -- мировое направление → локальные углы относительно текущей камеры
        local localDir = cf:VectorToObjectSpace(dir.Unit)
        -- yaw: влево/вправо (в градусах). знак минус — потому что Roblox
        -- поворачивает камеру в противоположную сторону от мыши по X
        local yaw   = -math.deg(math.atan2(localDir.X, -localDir.Z))
        local pitch =  math.deg(math.asin(math.clamp(localDir.Y, -1, 1)))

        -- чувствительность игры (у Roblox по умолчанию ~1)
        local gameSens = UserInputService.MouseDeltaSensitivity
        if type(gameSens) ~= "number" or gameSens <= 0 then gameSens = 1 end

        -- множитель aimbot'а + сглаживание
        local sm = Aimbot.smoothness * Aimbot.sensitivity
        sm = math.clamp(sm, 0.02, 1.0)
        if not Aimbot.blatant then
            sm = _applyCurve(sm)
        end

        -- перевод углов в "пиксели мыши"
        local dx = (yaw   / gameSens) * sm
        local dy = (pitch / gameSens) * sm

        -- защита от огромных прыжков (когда только что взяли цель)
        dx = math.clamp(dx, -45, 45)
        dy = math.clamp(dy, -45, 45)

        -- двигаем мышь — шифтлок сам повернёт камеру
        if type(mousemoverel) == "function" then
            pcall(mousemoverel, dx, dy)
        elseif type(mousemover) == "function" then
            -- fallback: некоторые экзекуторы называют по-другому
            local cur = UserInputService:GetMouseLocation()
            pcall(mousemover, cur.X + dx, cur.Y + dy)
        else
            -- последний fallback — олдскул, работает не везде
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendMouseMoveEvent(
                    UserInputService:GetMouseLocation().X + dx,
                    UserInputService:GetMouseLocation().Y + dy,
                    game)
            end)
        end
        return
    end

    -- ── ОБЫЧНЫЙ РЕЖИМ (first-person, камеру не трогает игра) ──
    local cur = cam.CFrame
    local want = CFrame.lookAt(cur.Position, pos)
    local raw = Aimbot.smoothness * Aimbot.sensitivity
    local sm = math.clamp(raw, 0.02, 1.0)
    if Aimbot.blatant then
        sm = 1.0
    else
        sm = _applyCurve(sm)
    end
    if Aimbot.thirdPerson then sm = sm * Aimbot.thirdPersonSens end
    cam.CFrame = cur:Lerp(want, sm)
end

-- Конфиг: двигать ли OS-курсор при выстреле.
-- true = двигать (лучше hitreg в некоторых играх, но прыгает под shiftlock)
-- false = не двигать (чисто, работает на 95% игр)
local FIRE_MOVE_CURSOR = false

function _fireOnce()
    local cam = WorkspaceS.CurrentCamera
    if not cam then return false end
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local cf = cam.CFrame

    local origMouse = nil
    if FIRE_MOVE_CURSOR then
        pcall(function() origMouse = UserInputService:GetMouseLocation() end)
        if type(mousemoveabs) == "function" then
            pcall(mousemoveabs, center.X, center.Y)
        end
    end

    -- способ 1: активировать tool (не двигает курсор)
    local char = LocalPlayerS.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool.Enabled then
            if pcall(function() tool:Activate() end) then
                if FIRE_MOVE_CURSOR and origMouse and type(mousemoveabs) == "function" then
                    task.defer(function() pcall(mousemoveabs, origMouse.X, origMouse.Y) end)
                end
                return true
            end
        end
    end

    -- способ 2: mouse1click (executor сам знает центр)
    if type(mouse1click) == "function" then
        if pcall(mouse1click) then
            if FIRE_MOVE_CURSOR and origMouse and type(mousemoveabs) == "function" then
                task.defer(function() pcall(mousemoveabs, origMouse.X, origMouse.Y) end)
            end
            return true
        end
    end

    -- способ 3: press/release
    if type(mouse1press) == "function" and type(mouse1release) == "function" then
        pcall(mouse1press)
        pcall(mouse1release)
        if FIRE_MOVE_CURSOR and origMouse and type(mousemoveabs) == "function" then
            task.defer(function() pcall(mousemoveabs, origMouse.X, origMouse.Y) end)
        end
        return true
    end

    -- способ 4: VirtualInputManager (не двигает реальный курсор)
    local ok2 = pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 1)
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
    end)
    if ok2 then
        if FIRE_MOVE_CURSOR and origMouse and type(mousemoveabs) == "function" then
            task.defer(function() pcall(mousemoveabs, origMouse.X, origMouse.Y) end)
        end
        return true
    end

    -- способ 5: VirtualUser
    local ok = pcall(function()
        VirtualUserS:Button1Down(center, cf)
        VirtualUserS:Button1Up(center, cf)
    end)
    if FIRE_MOVE_CURSOR and origMouse and type(mousemoveabs) == "function" then
        task.defer(function() pcall(mousemoveabs, origMouse.X, origMouse.Y) end)
    end
    return ok
end

-- 🎯 fireShot объявим позже (после playHit) — тут только форвард
-- (глобальная функция, чтобы была видна из aimFire/triggerFire ниже)

local function aimFire()
    local now = tick()
    if now - Aimbot._lastShoot < Aimbot.autoShootDelay then return end
    Aimbot._lastShoot = now
    lastMouseShot = now

    -- debug лог выключен
    local shots = 1
    if Aimbot.rapidFire and Aimbot.rapidFireMult > 1 then
        shots = math.max(1, math.floor(Aimbot.rapidFireMult))
    end
    Session.shots = (Session.shots or 0) + shots

    fireShot()

    if shots > 1 then
        task.spawn(function()
            for i = 2, shots do
                if Aimbot.rapidFireGap > 0 then task.wait(Aimbot.rapidFireGap) end
                fireShot()
            end
        end)
    end
end
local function triggerFire(originalCF)
    local now = tick()
    local d = Aimbot.triggerDelay
    if Aimbot.rapidFire and Aimbot.rapidFireMult > 1 then
        d = d/math.max(Aimbot.rapidFireMult, 1)
    end
    if now - Aimbot._lastTrigger < d then
        if originalCF and Aimbot.triggerNoShake then CameraS.CFrame = originalCF end
        return
    end
    Aimbot._lastTrigger = now
    Hitsound._lastTriggerShot = now
    local shots = 1
    if Aimbot.rapidFire and Aimbot.rapidFireMult > 1 then
        shots = math.max(1, math.floor(Aimbot.rapidFireMult))
    end
    Session.shots = (Session.shots or 0) + shots

    -- ВАЖНО: стреляем СИНХРОННО, пока CF ещё указывает на цель
    _fireOnce()

    -- отложенные rapidFire — уже можно после первого выстрела
    if shots > 1 then
        task.spawn(function()
            for i = 2, shots do
                if Aimbot.rapidFireGap > 0 then task.wait(Aimbot.rapidFireGap) end
                _fireOnce()
            end
        end)
    end

    -- сброс камеры ТОЛЬКО ПОСЛЕ первого выстрела
    if originalCF and Aimbot.triggerNoShake then CameraS.CFrame = originalCF end
end
local trigRayP = RaycastParams.new()
trigRayP.FilterType = Enum.RaycastFilterType.Exclude
trigRayP.IgnoreWater = true
local function trigRayScan()
    local char = LocalPlayerS.Character
    if not char then return nil end
    -- фильтруем себя + игнорим extended hitbox чтобы случайно не «поймать» стену за ним
    trigRayP.FilterDescendantsInstances = {char}
    local ok, res = pcall(WorkspaceS.Raycast, WorkspaceS,
        CameraS.CFrame.Position, CameraS.CFrame.LookVector * Aimbot.triggerRange, trigRayP)
    if not ok or not res or not res.Instance then return nil end
    local hp = res.Instance
    local hm = hp:FindFirstAncestorOfClass("Model")
    if not hm then return nil end
    local pl = Players:GetPlayerFromCharacter(hm)

    if pl and pl ~= LocalPlayerS then
        if not (Aimbot.teamCheck and pl.Team ~= nil and pl.Team == LocalPlayerS.Team) then
            if Aimbot.skipFriends and isWhitelisted(pl) then return nil end
            if isTeamNoDraw(pl) then return nil end
            if Aimbot.forcefieldCheck and hm:FindFirstChildOfClass("ForceField") then return nil end
            if Aimbot.skipKnocked and isKnocked(hm) then return nil end
            if Aimbot.aliveCheck then
                local hum = hm:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return {player=pl, char=hm, part=hp} end
            else return {player=pl, char=hm, part=hp} end
        end
    elseif Aimbot.triggerNPCs and isNPC(hm) then
        local hum = hm:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return {player=nil, char=hm, part=hp} end
    end
    return nil
end
local function trigScreenScan()
    local char = LocalPlayerS.Character
    if not char then return nil end
    local myH = char:FindFirstChild("HumanoidRootPart")
    if not myH then return nil end
    local vp = CameraS.ViewportSize
    local sc = Vector2.new(vp.X*0.5, vp.Y*0.5)
    local th = Aimbot.triggerRadius
    local best, bd = nil, math.huge
    local function check(tChar, pObj)
        if not tChar then return end
        local parts
        if Aimbot.triggerMultipoint then parts = getAllParts(tChar)
        else
            local tp = getAimPart(tChar)
            parts = {}
            if tp then parts[1] = tp end
        end
        for _, pt in ipairs(parts) do
            if pt and pt:IsA("BasePart") then
                local d3 = (pt.Position - myH.Position).Magnitude
                if d3 <= Aimbot.triggerRange then
                    local sp, on = CameraS:WorldToViewportPoint(pt.Position)
                    if on and sp.Z > 0 then
                        local dd = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
                        if dd <= th then
                            if not Aimbot.triggerWallCheck or aimVisible(tChar, pt) then
                                if dd < bd then
                                    bd = dd
                                    best = {player=pObj, char=tChar, part=pt}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if aimShouldTarget(p) then check(p.Character, p) end
    end
    if Aimbot.triggerNPCs then
        for _, obj in ipairs(collectNPCs()) do
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then check(obj, nil) end
        end
    end
    return best
end
local function triggerCheck()
    if Aimbot.triggerWallCheck then
        -- с wallcheck — только точный рейкаст, никаких screen fallback
        return trigRayScan()
    end
    local r = trigRayScan()
    if r then return r end
    return trigScreenScan()
end
local function isSettled(part)
    if not part then return false end
    local look = CameraS.CFrame.LookVector
    local want = part.Position - CameraS.CFrame.Position
    if want.Magnitude < 0.001 then return true end
    -- было 0.9925 (~7°), стало 0.985 (~10°) —
    -- Prison Life не всегда даёт точный settle
    return look:Dot(want.Unit) > 0.985
end
local function updateFOV(locked)
    if not DrawOK then return end
    if not Aimbot.showFOV then
        if isDraw(Aimbot._fov) then pcall(function() Aimbot._fov.Visible = false end) end
        Aimbot._fovCache = nil
        return
    end
    if not isDraw(Aimbot._fov) then
        Aimbot._fov = newDraw("Circle", {Visible=false, Filled=Aimbot.fovFilled,
            NumSides=Aimbot.fovSides, Thickness=Aimbot.fovThickness,
            Transparency=Aimbot.fovTransp, ZIndex=9999})
        Aimbot._fovCache = nil
    end
    local c = Aimbot._fov
    if not isDraw(c) then return end
    local cache = Aimbot._fovCache
    if not cache then cache = {}; Aimbot._fovCache = cache end
    local vp = CameraS.ViewportSize
    local r = Aimbot.fov * (vp.Y/FOV_REF_H)
    local col
    if Aimbot.fovRainbow then
        col = Color3.fromHSV((tick()*Aimbot.fovRainbowSpeed*0.1)%1, 1, 1)
    else
        col = Aimbot.fovColor
        if locked then col = Aimbot.fovLockedColor end
    end
    local ps = Vector2.new(vp.X*0.5, vp.Y*0.5)
    if cache.ps ~= ps then pcall(function() c.Position = ps end); cache.ps = ps end
    if cache.r ~= r then pcall(function() c.Radius = r end); cache.r = r end
    if cache.col ~= col then pcall(function() c.Color = col end); cache.col = col end
    if cache.v ~= true then pcall(function() c.Visible = true end); cache.v = true end
end
local aimbotToggle = false
local triggerToggle = false
local function aimActive()
    if not Aimbot.enabled then return false end
    if Aimbot.toggleMode then return Aimbot._toggle end
    return aimbotToggle
end
function keyHeld(tk)
    if typeof(tk) ~= "EnumItem" then return false end
    if tk.EnumType == Enum.UserInputType then
        return UserInputService:IsMouseButtonPressed(tk)
    elseif tk.EnumType == Enum.KeyCode then
        return UserInputService:IsKeyDown(tk)
    end
    return false
end
local function trigActive()
    if not Aimbot.triggerBot then return false end
    if Aimbot.triggerToggleMode then return triggerToggle end
    return keyHeld(Aimbot.triggerKey)
end
local function shouldFire()
    if Aimbot.onlyADS then
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return false end
    end
    return true
end

local function resolveSndId(preset, custom)
    if preset == "Custom" then
        if custom and custom ~= "" then
            if custom:sub(1,13) == "rbxassetid://" then return custom end
            return "rbxassetid://"..custom
        end
        return nil
    end
    return PRESETS[preset]
end
local function createSndPool()
    for _, s in ipairs(Hitsound.pool) do pcall(function() s:Destroy() end) end
    Hitsound.pool = {}; Hitsound.poolIndex = 1
    local id = resolveSndId(Hitsound.preset, Hitsound.customId)
    if not id then return end
    for i=1, HS_POOL do
        local s = Instance.new("Sound")
        s.Name = PREFIX.."Hit_"..i; s.SoundId = id
        s.Volume = Hitsound.volume; s.Parent = SoundServiceS
        Hitsound.pool[i] = s
    end
end
local function playHit()
    Hitsound.hitCount = Hitsound.hitCount + 1
    if #Hitsound.pool == 0 then createSndPool() end
    if #Hitsound.pool == 0 then return end

    if Hitsound.mode == "every" then
        -- 🎯 каждое нажатие = отдельный звук.
        -- Используем строгую ротацию по слотам — гарантированно разные
        -- инстансы, не полагаясь на IsPlaying (он обновляется с задержкой).
        Hitsound.poolIndex = Hitsound.poolIndex % #Hitsound.pool + 1
        local s = Hitsound.pool[Hitsound.poolIndex]
        if s and s.Parent then
            pcall(function()
                s.TimePosition = 0
                s.Volume = Hitsound.volume
                s.PlaybackSpeed = 1
                s:Play()
            end)
        end
        -- если пул маленький — долбим клоном, чтобы не резать подряд идущие
        if #Hitsound.pool < 6 then
            local tmpl = Hitsound.pool[1]
            if tmpl and tmpl.Parent and (tmpl.SoundId or "") ~= "" then
                local clone = tmpl:Clone()
                clone.Name = PREFIX.."HitTemp"
                clone.Parent = SoundServiceS
                clone.TimePosition = 0
                clone.Volume = Hitsound.volume
                clone:Play()
                task.delay(1.5, function() pcall(function() clone:Destroy() end) end)
            end
        end
    else
        -- single — стоп + рестарт
        Hitsound.poolIndex = Hitsound.poolIndex % #Hitsound.pool + 1
        local s = Hitsound.pool[Hitsound.poolIndex]
        if s and s.Parent then
            pcall(function()
                if s.IsPlaying then s:Stop() end
                s.TimePosition = 0
                s.Volume = Hitsound.volume
                s.PlaybackSpeed = 1
                s:Play()
            end)
        end
    end
end

-- 🎯 теперь playHit уже точно определён → можно замкнуть на него
function fireShot()
    local ok = _fireOnce()
    if ok and Hitsound.enabled and Hitsound.mode == "every" then
        pcall(playHit)
    end
    return ok
end

local function createKillPool()
    for _, s in ipairs(KillSound.pool) do pcall(function() s:Destroy() end) end
    KillSound.pool = {}; KillSound.poolIndex = 1
    local id = resolveSndId(KillSound.preset, KillSound.customId)
    if not id then return end
    for i=1, KS_POOL do
        local s = Instance.new("Sound")
        s.Name = PREFIX.."Kill_"..i; s.SoundId = id
        s.Volume = KillSound.volume; s.Parent = SoundServiceS
        KillSound.pool[i] = s
    end
end
local function playKill()
    if #KillSound.pool == 0 then createKillPool() end
    if #KillSound.pool == 0 then return end
    KillSound.poolIndex = KillSound.poolIndex % #KillSound.pool + 1
    local s = KillSound.pool[KillSound.poolIndex]
    if s and s.Parent then
        pcall(function()
            if s.IsPlaying then s:Stop() end
            s.TimePosition = 0; s.Volume = KillSound.volume; s:Play()
        end)
    end
end

-- hitmarker
local function buildHM()
    local h = {lines={}, text=nil, active=false, startTime=0,
        cx=0, cy=0, isKill=false, isHeadshot=false, amount=0}
    for i=1, 4 do
        h.lines[i] = newDraw("Line", {Visible=false, Thickness=Hitmarker.crossThickness, ZIndex=9999})
        if not isDraw(h.lines[i]) then return nil end
    end
    h.text = newDraw("Text", {Visible=false, Center=true, Outline=true,
        OutlineColor=Hitmarker.numberOutlineColor or Color3.new(0,0,0), Font=2, ZIndex=9999})
    if not isDraw(h.text) then return nil end
    return h
end
local function ensureHMPool()
    for i = 1, Hitmarker.poolSize do
        if not Hitmarker.pool[i] then
            local h = buildHM()
            if h then Hitmarker.pool[i] = h end
        end
    end
end
local function getFreeHMSlot()
    ensureHMPool()
    local n = #Hitmarker.pool
    if n == 0 then return nil end
    for _ = 1, n do
        Hitmarker.poolIndex = (Hitmarker.poolIndex % n) + 1
        local h = Hitmarker.pool[Hitmarker.poolIndex]
        if h and not h.active then return h end
    end
    Hitmarker.poolIndex = (Hitmarker.poolIndex % n) + 1
    return Hitmarker.pool[Hitmarker.poolIndex]
end
local function computeHMSegs(mode, cx, cy, size, rot)
    local segs = {}
    if mode == "Cross" or mode == "Both" then
        for i, a in ipairs({45,135,225,315}) do
            local ar = math.rad(a+rot)
            segs[i] = {
                Vector2.new(cx + math.cos(ar)*size*0.35, cy + math.sin(ar)*size*0.35),
                Vector2.new(cx + math.cos(ar)*size, cy + math.sin(ar)*size),
            }
        end
    elseif mode == "Dot" then
        for i=1, 4 do
            local a = math.rad(45 + (i-1)*90 + rot)
            local x = cx + math.cos(a)*size*0.5
            local y = cy + math.sin(a)*size*0.5
            segs[i] = {Vector2.new(x,y), Vector2.new(x+0.5,y)}
        end
    elseif mode == "Square" then
        local r = math.rad(rot)
        local cs, sn = math.cos(r), math.sin(r)
        local half = size*0.8
        local corners = {{-half,-half},{half,-half},{half,half},{-half,half}}
        for i=1, 4 do
            local j = (i%4)+1
            local x1 = corners[i][1]*cs - corners[i][2]*sn
            local y1 = corners[i][1]*sn + corners[i][2]*cs
            local x2 = corners[j][1]*cs - corners[j][2]*sn
            local y2 = corners[j][1]*sn + corners[j][2]*cs
            segs[i] = {Vector2.new(cx+x1, cy+y1), Vector2.new(cx+x2, cy+y2)}
        end
    elseif mode == "Diamond" then
        local r = math.rad(rot)
        local cs, sn = math.cos(r), math.sin(r)
        local corners = {{0,-size},{size,0},{0,size},{-size,0}}
        for i=1, 4 do
            local j = (i%4)+1
            local x1 = corners[i][1]*cs - corners[i][2]*sn
            local y1 = corners[i][1]*sn + corners[i][2]*cs
            local x2 = corners[j][1]*cs - corners[j][2]*sn
            local y2 = corners[j][1]*sn + corners[j][2]*cs
            segs[i] = {Vector2.new(cx+x1, cy+y1), Vector2.new(cx+x2, cy+y2)}
        end
    elseif mode == "Circle" then
        for i=1, 4 do
            local a1 = math.rad((i-1)*90 + rot)
            local a2 = math.rad(i*90 + rot)
            segs[i] = {
                Vector2.new(cx + math.cos(a1)*size, cy + math.sin(a1)*size),
                Vector2.new(cx + math.cos(a2)*size, cy + math.sin(a2)*size),
            }
        end
    elseif mode == "Star" then
        for i=1, 4 do
            local a = math.rad((i-1)*90 + rot)
            segs[i] = {Vector2.new(cx,cy),
                Vector2.new(cx + math.cos(a)*size, cy + math.sin(a)*size)}
        end
    elseif mode == "Chevron" then
        for i=1, 4 do
            local baseA = (i-1)*90 + rot
            local tipR = size*0.35
            local outerR = size
            local tipx = cx + math.cos(math.rad(baseA))*tipR
            local tipy = cy + math.sin(math.rad(baseA))*tipR
            local a1 = math.rad(baseA-35)
            local a2 = math.rad(baseA+35)
            local x1 = cx + math.cos(a1)*outerR
            local y1 = cy + math.sin(a1)*outerR
            local x2 = cx + math.cos(a2)*outerR
            local y2 = cy + math.sin(a2)*outerR
            segs[i] = {Vector2.new((x1+x2)*0.5, (y1+y2)*0.5), Vector2.new(tipx, tipy)}
        end
    end
    return segs
end
local function spawnHM(amount, isKill, isHeadshot)
    if not Hitmarker.enabled or not DrawOK then return end
    if #Hitmarker.pool == 0 then ensureHMPool() end
    if #Hitmarker.pool == 0 then return end
    local now = tick()
    if Hitmarker.comboEnabled then
        if now - Hitmarker.comboLastHit < Hitmarker.comboDuration then
            Hitmarker.comboCount = Hitmarker.comboCount + 1
        else Hitmarker.comboCount = 1 end
        Hitmarker.comboLastHit = now
    end
    local h = getFreeHMSlot()
    if not h then return end
    h.active = true; h.startTime = now
    h.isKill = isKill or false
    h.isHeadshot = isHeadshot or false
    h.amount = amount or 0
    local vp = CameraS.ViewportSize
    h.cx = vp.X*0.5; h.cy = vp.Y*0.5
    local showText = false
    local txt = ""
    local txtSize = Hitmarker.numberSize
    local txtColor = Hitmarker.numberColor
    if h.isKill and Hitmarker.killTextEnabled then
        txt = Hitmarker.killText; txtSize = Hitmarker.killTextSize
        txtColor = Hitmarker.killTextColor; showText = true
    elseif Hitmarker.mode == "Number" or Hitmarker.mode == "Both" then
        txt = Hitmarker.numberPrefix .. tostring(math.floor(amount or 0)) .. Hitmarker.numberSuffix
        showText = true
    end
    if showText and isDraw(h.text) then
        pcall(function()
            h.text.Text = txt; h.text.Size = txtSize; h.text.Color = txtColor
            h.text.Transparency = 0
            h.text.Position = Vector2.new(h.cx, h.cy); h.text.Visible = true
        end)
    elseif isDraw(h.text) then
        pcall(function() h.text.Visible = false end)
    end
end
local function updateHM()
    if not DrawOK then return end
    if #Hitmarker.pool == 0 then return end
    -- fast path: нет активных слотов → выходим без tick()
    local anyActive = false
    for i = 1, #Hitmarker.pool do
        local h = Hitmarker.pool[i]
        if h and h.active then anyActive = true; break end
    end
    if not anyActive then return end
    local now = tick()
    for i = 1, #Hitmarker.pool do
        local h = Hitmarker.pool[i]
        if h and h.active then
            local age = now - h.startTime
            local baseDur = Hitmarker.crossDuration
            local numDur = Hitmarker.numberDuration
            local sizeMult = 1
            if h.isKill and Hitmarker.killEnabled then
                baseDur = baseDur * Hitmarker.killDurationBoost
                numDur = numDur * Hitmarker.killDurationBoost
                sizeMult = Hitmarker.killSizeBoost
            elseif h.isHeadshot and Hitmarker.headshotEnabled then
                sizeMult = Hitmarker.headshotSizeBoost
            end
            local isCrossy = (Hitmarker.mode ~= "Number")
            if isCrossy and age < baseDur then
                local alpha = 1 - (age/baseDur)
                local baseColor = Hitmarker.crossColor
                if h.isKill and Hitmarker.killEnabled then baseColor = Hitmarker.killColor
                elseif h.isHeadshot and Hitmarker.headshotEnabled then baseColor = Hitmarker.headshotColor end
                if Hitmarker.crossRainbow then
                    baseColor = Color3.fromHSV((now*Hitmarker.crossRainbowSpeed*0.15)%1, 1, 1)
                end
                local transp = Hitmarker.crossTransp + (1-alpha)*0.4
                local size = Hitmarker.crossSize * sizeMult
                local rot = Hitmarker.crossSpin * age
                if h.isKill then rot = Hitmarker.crossSpinKill * age end
                local segs = computeHMSegs(Hitmarker.mode, h.cx, h.cy, size, rot)
                for i=1, 4 do
                    local ln = h.lines[i]
                    if isDraw(ln) and segs[i] then
                        pcall(function()
                            ln.From = segs[i][1]; ln.To = segs[i][2]
                            ln.Color = baseColor
                            local thickMul = 1
                            if h.isKill then thickMul = 1.4 end
                            ln.Thickness = Hitmarker.crossThickness*thickMul
                            ln.Transparency = transp; ln.Visible = true
                        end)
                    elseif isDraw(ln) then pcall(function() ln.Visible = false end) end
                end
            else
                for i=1, 4 do
                    if isDraw(h.lines[i]) then pcall(function() h.lines[i].Visible = false end) end
                end
            end
            local showText = (Hitmarker.mode == "Number" or Hitmarker.mode == "Both")
                or (h.isKill and Hitmarker.killTextEnabled)
            if showText and age < numDur and isDraw(h.text) then
                local alpha = 1 - (age/numDur)
                local col = Hitmarker.numberColor
                if h.isKill then col = Hitmarker.killTextColor end
                if Hitmarker.numberRainbow and not h.isKill then
                    col = Color3.fromHSV((now*Hitmarker.numberRainbowSpeed*0.15)%1, 1, 1)
                end
                local yOff = -age * Hitmarker.numberRiseSpeed
                pcall(function()
                    h.text.Position = Vector2.new(h.cx, h.cy + yOff)
                    h.text.Color = col; h.text.Transparency = 1 - alpha; h.text.Visible = true
                end)
            else
                if isDraw(h.text) then pcall(function() h.text.Visible = false end) end
            end
            local maxDur = math.max(baseDur, numDur)
            if age >= maxDur then
                for i=1, 4 do
                    if isDraw(h.lines[i]) then pcall(function() h.lines[i].Visible = false end) end
                end
                if isDraw(h.text) then pcall(function() h.text.Visible = false end) end
                h.active = false
            end
        end
    end
end
local function destroyHitmarkers()
    for _, h in ipairs(Hitmarker.pool) do
        for i=1, 4 do dRem(h.lines[i]) end
        dRem(h.text)
    end
    Hitmarker.pool = {}
    Hitmarker.poolIndex = 1
end

-- world
local function ensureAtmosphere()
    local a = WORLD_STATE.atmoInstance
    if not a or not a.Parent then
        a = LightingS:FindFirstChildOfClass("Atmosphere")
        if a then
            WORLD_STATE.atmoInstance = a
            WORLD_STATE.atmoCreatedByUs = false
        else
            a = Instance.new("Atmosphere"); a.Parent = LightingS
            WORLD_STATE.atmoInstance = a
            WORLD_STATE.atmoCreatedByUs = true
        end
    end
    return a
end
local function applyAtmosphere()
    if World.atmoEnabled then
        local a = ensureAtmosphere()
        pcall(function()
            a.Color = World.atmoColor; a.Decay = World.atmoDecay
            a.Density = World.atmoDensity; a.Haze = World.atmoHaze
            a.Glare = World.atmoGlare; a.Offset = World.atmoOffset
        end)
    elseif not World.skyColorEnabled then
        -- sky color owns the atmosphere right now — don't touch it
        local a = WORLD_STATE.atmoInstance
        if a and a.Parent then
            if WORLD_STATE.atmoCreatedByUs then
                pcall(function() a:Destroy() end)
                WORLD_STATE.atmoInstance = nil
                WORLD_STATE.atmoCreatedByUs = false
            elseif ORIGINAL_ATMOSPHERE then
                pcall(function()
                    a.Color = ORIGINAL_ATMOSPHERE.Color
                    a.Decay = ORIGINAL_ATMOSPHERE.Decay
                    a.Density = ORIGINAL_ATMOSPHERE.Density
                    a.Haze = ORIGINAL_ATMOSPHERE.Haze
                    a.Glare = ORIGINAL_ATMOSPHERE.Glare
                    a.Offset = ORIGINAL_ATMOSPHERE.Offset
                end)
            end
        end
    end
end
local function ensureSky()
    local s = WORLD_STATE.skyInstance
    if not s or not s.Parent then
        s = LightingS:FindFirstChildOfClass("Sky")
        if s then
            WORLD_STATE.skyInstance = s
            WORLD_STATE.skyCreatedByUs = false
        else
            s = Instance.new("Sky"); s.Parent = LightingS
            WORLD_STATE.skyInstance = s
            WORLD_STATE.skyCreatedByUs = true
        end
    end
    return s
end
local function applySky()
    if World.skyOverride then
        local s = ensureSky()
        pcall(function()
            s.StarCount = World.skyStarCount; s.MoonAngularSize = World.skyMoonSize
            s.SunAngularSize = World.skySunSize; s.CelestialBodiesShown = World.skyCelestial
        end)
    else
        local s = WORLD_STATE.skyInstance
        if s and s.Parent then
            if WORLD_STATE.skyCreatedByUs then
                pcall(function() s:Destroy() end)
                WORLD_STATE.skyInstance = nil
                WORLD_STATE.skyCreatedByUs = false
            elseif ORIGINAL_SKY then
                pcall(function()
                    s.StarCount = ORIGINAL_SKY.StarCount
                    s.MoonAngularSize = ORIGINAL_SKY.MoonAngularSize
                    s.SunAngularSize = ORIGINAL_SKY.SunAngularSize
                    s.CelestialBodiesShown = ORIGINAL_SKY.CelestialBodiesShown
                end)
            end
        end
    end
end
-- props to snapshot for each effect class
local EFFECT_PROPS = {
    SunRaysEffect = {"Enabled","Intensity","Spread"},
    BloomEffect = {"Enabled","Intensity","Size","Threshold"},
    ColorCorrectionEffect = {"Enabled","Brightness","Contrast","Saturation","TintColor"},
    BlurEffect = {"Enabled","Size"},
    DepthOfFieldEffect = {"Enabled","FarIntensity","FocusDistance","InFocusRadius","NearIntensity"},
}
local function ensureEffect(cls)
    if WORLD_STATE[cls] and WORLD_STATE[cls].Parent then return WORLD_STATE[cls] end
    local existing = LightingS:FindFirstChildOfClass(cls)
    if existing then
        -- we take over an existing effect → snapshot everything
        WORLD_STATE[cls] = existing
        WORLD_STATE[cls.."_Owned"] = false
        local snap = {}
        for _, prop in ipairs(EFFECT_PROPS[cls] or {}) do
            local ok, v = pcall(function() return existing[prop] end)
            if ok then snap[prop] = v end
        end
        WORLD_STATE[cls.."_Snapshot"] = snap
    else
        local e = Instance.new(cls); e.Parent = LightingS
        WORLD_STATE[cls] = e
        WORLD_STATE[cls.."_Owned"] = true
        WORLD_STATE[cls.."_Snapshot"] = nil
    end
    return WORLD_STATE[cls]
end

-- helper: restore an effect to its pre-takeover state (or disable if we created it)
local function resetEffect(cls)
    local e = WORLD_STATE[cls]
    if not e or not e.Parent then return end
    if WORLD_STATE[cls.."_Owned"] then
        pcall(function() e.Enabled = false end)
    elseif WORLD_STATE[cls.."_Snapshot"] then
        for prop, val in pairs(WORLD_STATE[cls.."_Snapshot"]) do
            pcall(function() e[prop] = val end)
        end
    else
        pcall(function() e.Enabled = false end)
    end
end

local function applyPostEffects()
    if World.sunRaysEnabled then
        local s = ensureEffect("SunRaysEffect")
        pcall(function()
            s.Intensity = World.sunRaysIntensity; s.Spread = World.sunRaysSpread; s.Enabled = true
        end)
    else
        resetEffect("SunRaysEffect")
    end
    if World.bloomEnabled then
        local b = ensureEffect("BloomEffect")
        pcall(function()
            b.Intensity = World.bloomIntensity; b.Size = World.bloomSize
            b.Threshold = World.bloomThreshold; b.Enabled = true
        end)
    else
        resetEffect("BloomEffect")
    end
    if World.ccEnabled then
        local c = ensureEffect("ColorCorrectionEffect")
        pcall(function()
            c.Brightness = World.ccBrightness; c.Contrast = World.ccContrast
            c.Saturation = World.ccSaturation; c.TintColor = World.ccTintColor; c.Enabled = true
        end)
    else
        resetEffect("ColorCorrectionEffect")
    end
    if World.blurEnabled then
        local b = ensureEffect("BlurEffect")
        pcall(function() b.Size = World.blurSize; b.Enabled = true end)
    else
        resetEffect("BlurEffect")
    end
    if World.dofEnabled then
        local d = ensureEffect("DepthOfFieldEffect")
        pcall(function()
            d.FarIntensity = World.dofFar; d.FocusDistance = World.dofFocus
            d.InFocusRadius = World.dofInRadius; d.NearIntensity = World.dofNear; d.Enabled = true
        end)
    else
        resetEffect("DepthOfFieldEffect")
    end
end
-- sky color override: forces atmosphere color AND strips skybox textures
-- so the atmosphere tint actually reaches the zenith
local function restoreSkyColor()
    if not WORLD_STATE.skyColorHidden then return end
    local sky = LightingS:FindFirstChildOfClass("Sky")
    if sky and WORLD_STATE.skyColorSavedTextures then
        for k, v in pairs(WORLD_STATE.skyColorSavedTextures) do
            pcall(function() sky[k] = v end)
        end
    end
    WORLD_STATE.skyColorHidden = false
    WORLD_STATE.skyColorSavedTextures = nil
end

local function applySkyColor()
    if not World.skyColorEnabled then
        restoreSkyColor()
        return
    end
    -- resolve atmosphere FRESH every call — reference may be stale
    local a = LightingS:FindFirstChildOfClass("Atmosphere")
    if not a then
        a = Instance.new("Atmosphere")
        a.Parent = LightingS
        WORLD_STATE.atmoInstance = a
        WORLD_STATE.atmoCreatedByUs = true
    else
        WORLD_STATE.atmoInstance = a
    end
    pcall(function()
        a.Color = World.skyColor
        a.Decay = World.skyColor
        -- clamp so it's actually visible: 0.15 barely tints, 0.5+ definitely shows
        a.Density = math.clamp(World.skyColorDensity or 0.5, 0.15, 1)
        a.Haze = 0
        a.Glare = 0
        a.Offset = 0
    end)
    -- strip skybox textures so zenith picks up the atmosphere color
    local sky = LightingS:FindFirstChildOfClass("Sky")
    if sky then
        if not WORLD_STATE.skyColorHidden then
            WORLD_STATE.skyColorSavedTextures = {
                SkyboxBk = sky.SkyboxBk, SkyboxDn = sky.SkyboxDn,
                SkyboxFt = sky.SkyboxFt, SkyboxLf = sky.SkyboxLf,
                SkyboxRt = sky.SkyboxRt, SkyboxUp = sky.SkyboxUp,
                SunTextureId = sky.SunTextureId, MoonTextureId = sky.MoonTextureId,
                StarCount = sky.StarCount,
            }
            WORLD_STATE.skyColorHidden = true
        end
        pcall(function()
            sky.SkyboxBk = ""; sky.SkyboxDn = ""
            sky.SkyboxFt = ""; sky.SkyboxLf = ""
            sky.SkyboxRt = ""; sky.SkyboxUp = ""
            sky.SunTextureId = ""; sky.MoonTextureId = ""
            sky.StarCount = 0
        end)
    end
end

local function applyFog()
    if World.fogEnabled then
        if not WORLD_STATE.fogApplied then
            local a = WORLD_STATE.atmoInstance or LightingS:FindFirstChildOfClass("Atmosphere")
            if a then
                WORLD_STATE.fogAtmoRef = a
                WORLD_STATE.fogAtmoSaved = {
                    Density=a.Density, Haze=a.Haze, Glare=a.Glare,
                    Color=a.Color, Decay=a.Decay,
                }
            end
            WORLD_STATE.fogApplied = true
        end
        pcall(function()
            LightingS.FogColor = World.fogColor
            LightingS.FogStart = World.fogStart
            LightingS.FogEnd = World.fogEnd
            local a = WORLD_STATE.atmoInstance or LightingS:FindFirstChildOfClass("Atmosphere")
            if a and a.Parent then
                if World.atmoEnabled then
                    a.Color = World.fogColor
                    a.Decay = World.fogColor
                else
                    a.Density = 0; a.Haze = 0; a.Glare = 0
                end
            end
        end)
    else
        if WORLD_STATE.fogApplied then
            pcall(function()
                local a = WORLD_STATE.fogAtmoRef
                    or WORLD_STATE.atmoInstance
                    or LightingS:FindFirstChildOfClass("Atmosphere")
                if a and a.Parent and WORLD_STATE.fogAtmoSaved then
                    a.Density = WORLD_STATE.fogAtmoSaved.Density
                    a.Haze = WORLD_STATE.fogAtmoSaved.Haze
                    a.Glare = WORLD_STATE.fogAtmoSaved.Glare
                    if WORLD_STATE.fogAtmoSaved.Color then a.Color = WORLD_STATE.fogAtmoSaved.Color end
                    if WORLD_STATE.fogAtmoSaved.Decay then a.Decay = WORLD_STATE.fogAtmoSaved.Decay end
                end
                LightingS.FogColor = LIGHTING_ORIGINALS.FogColor
                LightingS.FogStart = LIGHTING_ORIGINALS.FogStart
                LightingS.FogEnd = LIGHTING_ORIGINALS.FogEnd
            end)
            WORLD_STATE.fogApplied = false
            WORLD_STATE.fogAtmoSaved = nil
            WORLD_STATE.fogAtmoRef = nil
        end
    end
end
local function applyWorld()
    if World.fullbright then
        pcall(function()
            LightingS.Ambient = Color3.fromRGB(255,255,255)
            LightingS.OutdoorAmbient = Color3.fromRGB(255,255,255)
            LightingS.Brightness = 2; LightingS.ClockTime = 14; LightingS.GlobalShadows = false
        end)
    else
        pcall(function()
            LightingS.Ambient = World.ambient
            LightingS.OutdoorAmbient = World.outdoorAmbient
            LightingS.Brightness = World.brightness
            LightingS.ClockTime = World.clockTime
            LightingS.ExposureCompensation = World.exposure
            LightingS.GlobalShadows = World.globalShadows
            LightingS.EnvironmentDiffuseScale = World.envDiffuse
            LightingS.EnvironmentSpecularScale = World.envSpecular
        end)
    end
    if World.fogEnabled then pcall(applyFog) end
end
local function restoreWorldOriginals()
    World.skyColorEnabled = false
    World.fogEnabled = false
    pcall(restoreSkyColor)
    -- 1) Lighting base props
    pcall(function()
        LightingS.Brightness = LIGHTING_ORIGINALS.Brightness
        LightingS.Ambient = LIGHTING_ORIGINALS.Ambient
        LightingS.OutdoorAmbient = LIGHTING_ORIGINALS.OutdoorAmbient
        LightingS.ClockTime = LIGHTING_ORIGINALS.ClockTime
        LightingS.ExposureCompensation = LIGHTING_ORIGINALS.ExposureCompensation
        LightingS.GlobalShadows = LIGHTING_ORIGINALS.GlobalShadows
        LightingS.FogColor = LIGHTING_ORIGINALS.FogColor
        LightingS.FogStart = LIGHTING_ORIGINALS.FogStart
        LightingS.FogEnd = LIGHTING_ORIGINALS.FogEnd
        LightingS.EnvironmentDiffuseScale = LIGHTING_ORIGINALS.EnvironmentDiffuseScale
        LightingS.EnvironmentSpecularScale = LIGHTING_ORIGINALS.EnvironmentSpecularScale
    end)
    -- 2) Atmosphere
    if WORLD_STATE.atmoInstance then
        local a = WORLD_STATE.atmoInstance
        if a.Parent then
            if WORLD_STATE.atmoCreatedByUs then
                pcall(function() a:Destroy() end)
            elseif ORIGINAL_ATMOSPHERE then
                pcall(function()
                    a.Color = ORIGINAL_ATMOSPHERE.Color
                    a.Decay = ORIGINAL_ATMOSPHERE.Decay
                    a.Density = ORIGINAL_ATMOSPHERE.Density
                    a.Haze = ORIGINAL_ATMOSPHERE.Haze
                    a.Glare = ORIGINAL_ATMOSPHERE.Glare
                    a.Offset = ORIGINAL_ATMOSPHERE.Offset
                end)
            end
        end
        WORLD_STATE.atmoInstance = nil
        WORLD_STATE.atmoCreatedByUs = false
    end
    -- 3) Sky
    if WORLD_STATE.skyInstance then
        local s = WORLD_STATE.skyInstance
        if s.Parent and WORLD_STATE.skyCreatedByUs then
            pcall(function() s:Destroy() end)
        elseif s.Parent and ORIGINAL_SKY then
            pcall(function()
                s.StarCount = ORIGINAL_SKY.StarCount
                s.MoonAngularSize = ORIGINAL_SKY.MoonAngularSize
                s.SunAngularSize = ORIGINAL_SKY.SunAngularSize
                s.CelestialBodiesShown = ORIGINAL_SKY.CelestialBodiesShown
            end)
        end
        WORLD_STATE.skyInstance = nil
        WORLD_STATE.skyCreatedByUs = false
    end
    -- 4) Post-processing effects
    for _, cls in ipairs({"SunRaysEffect","BloomEffect","ColorCorrectionEffect","BlurEffect","DepthOfFieldEffect"}) do
        local e = WORLD_STATE[cls]
        if e then
            if e.Parent then
                if WORLD_STATE[cls.."_Owned"] then
                    pcall(function() e:Destroy() end)
                elseif WORLD_STATE[cls.."_Snapshot"] then
                    for prop, val in pairs(WORLD_STATE[cls.."_Snapshot"]) do
                        pcall(function() e[prop] = val end)
                    end
                end
            end
            WORLD_STATE[cls] = nil
            WORLD_STATE[cls.."_Owned"] = nil
            WORLD_STATE[cls.."_Snapshot"] = nil
        end
    end
    -- 5) Fog state
    if WORLD_STATE.fogApplied and WORLD_STATE.fogAtmoRef and WORLD_STATE.fogAtmoSaved then
        local a = WORLD_STATE.fogAtmoRef
        if a and a.Parent then
            pcall(function()
                a.Density = WORLD_STATE.fogAtmoSaved.Density
                a.Haze = WORLD_STATE.fogAtmoSaved.Haze
                a.Glare = WORLD_STATE.fogAtmoSaved.Glare
            end)
        end
    end
    WORLD_STATE.fogApplied = false
    WORLD_STATE.fogAtmoSaved = nil
    WORLD_STATE.fogAtmoRef = nil
end
local function reapplyAllWorld()
    pcall(applyWorld); pcall(applyAtmosphere); pcall(applySky)
    pcall(applyPostEffects); pcall(applyFog)
    pcall(applySkyColor)   -- last so it wins over atmo/fog tint
    if not World.skyColorEnabled then pcall(restoreSkyColor) end
end

local SHADER_PRESETS = {
    ["Cinematic"]=function()
        World.fullbright=false; World.brightness=1.8; World.exposure=0.1
        World.clockTime=17; World.ambient=Color3.fromRGB(100,90,80)
        World.outdoorAmbient=Color3.fromRGB(140,120,100); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=0.9; World.bloomSize=32; World.bloomThreshold=1.0
        World.ccEnabled=true; World.ccBrightness=0; World.ccContrast=0.25; World.ccSaturation=-0.1
        World.ccTintColor=Color3.fromRGB(255,240,220); World.blurEnabled=false
        World.atmoEnabled=true; World.atmoDensity=0.3; World.atmoHaze=2; World.atmoGlare=0.3
        World.atmoColor=Color3.fromRGB(220,200,180); World.atmoDecay=Color3.fromRGB(150,130,110)
    end,
    ["Dark Night"]=function()
        World.fullbright=false; World.brightness=0.4; World.exposure=-0.3
        World.clockTime=0; World.ambient=Color3.fromRGB(20,20,30)
        World.outdoorAmbient=Color3.fromRGB(30,30,45); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=0.6; World.bloomSize=20; World.bloomThreshold=1.4
        World.ccEnabled=true; World.ccBrightness=-0.1; World.ccContrast=0.2; World.ccSaturation=-0.2
        World.ccTintColor=Color3.fromRGB(180,200,255)
        World.atmoEnabled=true; World.atmoDensity=0.35; World.atmoHaze=0.5; World.atmoGlare=0.1
        World.atmoColor=Color3.fromRGB(20,25,40); World.atmoDecay=Color3.fromRGB(10,15,25)
    end,
    ["Soft"]=function()
        World.fullbright=false; World.brightness=2.2; World.exposure=0.3
        World.clockTime=13; World.ambient=Color3.fromRGB(180,180,190)
        World.outdoorAmbient=Color3.fromRGB(200,200,210); World.globalShadows=false
        World.bloomEnabled=true; World.bloomIntensity=0.7; World.bloomSize=40; World.bloomThreshold=1.2
        World.ccEnabled=true; World.ccBrightness=0.05; World.ccContrast=-0.15; World.ccSaturation=0.15
        World.ccTintColor=Color3.fromRGB(255,245,235)
        World.atmoEnabled=true; World.atmoDensity=0.15; World.atmoHaze=1; World.atmoGlare=0.15
        World.atmoColor=Color3.fromRGB(230,225,220); World.atmoDecay=Color3.fromRGB(180,175,170)
    end,
    ["Horror"]=function()
        World.fullbright=false; World.brightness=0.25; World.exposure=-0.7
        World.clockTime=2; World.ambient=Color3.fromRGB(28,28,32)
        World.outdoorAmbient=Color3.fromRGB(45,45,52); World.globalShadows=true
        World.bloomEnabled=false
        World.ccEnabled=true; World.ccBrightness=-0.2; World.ccContrast=0.35; World.ccSaturation=-0.7
        World.ccTintColor=Color3.fromRGB(140,145,160); World.blurEnabled=false
        World.atmoEnabled=true; World.atmoDensity=0.45; World.atmoHaze=3; World.atmoGlare=0
        World.atmoColor=Color3.fromRGB(110,110,120); World.atmoDecay=Color3.fromRGB(70,70,80)
        World.fogEnabled=true; World.fogColor=Color3.fromRGB(90,90,100)
        World.fogStart=30; World.fogEnd=280
    end,
    ["Night Mode"]=function()
        World.fullbright=false; World.brightness=0.8; World.exposure=-0.1
        World.clockTime=0; World.ambient=Color3.fromRGB(40,45,70)
        World.outdoorAmbient=Color3.fromRGB(50,55,90); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=0.5; World.bloomSize=24; World.bloomThreshold=1.6
        World.ccEnabled=true; World.ccBrightness=-0.05; World.ccContrast=0.15; World.ccSaturation=-0.1
        World.ccTintColor=Color3.fromRGB(190,210,255); World.blurEnabled=false
        World.atmoEnabled=true; World.atmoDensity=0.15; World.atmoHaze=0.3; World.atmoGlare=0.15
        World.atmoColor=Color3.fromRGB(40,45,70); World.atmoDecay=Color3.fromRGB(20,25,45)
    end,
    ["Kelvin's preset"]=function()
        World.fullbright=false; World.brightness=1.5; World.exposure=0.4
        World.clockTime=0; World.ambient=Color3.fromRGB(30,20,50)
        World.outdoorAmbient=Color3.fromRGB(50,30,80); World.globalShadows=false
        World.bloomEnabled=true; World.bloomIntensity=2.5; World.bloomSize=48; World.bloomThreshold=0.5
        World.ccEnabled=true; World.ccBrightness=0.1; World.ccContrast=0.4; World.ccSaturation=0.8
        World.ccTintColor=Color3.fromRGB(200,150,255)
        World.atmoEnabled=true; World.atmoDensity=0.2; World.atmoHaze=0.5; World.atmoGlare=0.5
        World.atmoColor=Color3.fromRGB(150,80,200); World.atmoDecay=Color3.fromRGB(80,40,120)
    end,
    ["Sunset"]=function()
        World.fullbright=false; World.brightness=1.6; World.exposure=0.2
        World.clockTime=18.2; World.ambient=Color3.fromRGB(150,100,80)
        World.outdoorAmbient=Color3.fromRGB(200,130,90); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=1.3; World.bloomSize=36; World.bloomThreshold=0.9
        World.ccEnabled=true; World.ccBrightness=0.05; World.ccContrast=0.15; World.ccSaturation=0.35
        World.ccTintColor=Color3.fromRGB(255,180,120)
        World.sunRaysEnabled=true; World.sunRaysIntensity=0.25; World.sunRaysSpread=1.3
        World.atmoEnabled=true; World.atmoDensity=0.28; World.atmoHaze=1.8; World.atmoGlare=0.4
        World.atmoColor=Color3.fromRGB(255,180,140); World.atmoDecay=Color3.fromRGB(200,100,70)
    end,
    ["Frost"]=function()
        World.fullbright=false; World.brightness=2.0; World.exposure=0.3
        World.clockTime=8; World.ambient=Color3.fromRGB(150,170,200)
        World.outdoorAmbient=Color3.fromRGB(180,200,230); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=1.0; World.bloomSize=24; World.bloomThreshold=1.1
        World.ccEnabled=true; World.ccBrightness=0.05; World.ccContrast=0.2; World.ccSaturation=-0.15
        World.ccTintColor=Color3.fromRGB(200,225,255)
        World.atmoEnabled=true; World.atmoDensity=0.32; World.atmoHaze=2.5; World.atmoGlare=0.2
        World.atmoColor=Color3.fromRGB(200,220,240); World.atmoDecay=Color3.fromRGB(140,170,200)
    end,
    ["Vaporwave"]=function()
        World.fullbright=false; World.brightness=1.4; World.exposure=0.5
        World.clockTime=3; World.ambient=Color3.fromRGB(80,40,120)
        World.outdoorAmbient=Color3.fromRGB(120,60,180); World.globalShadows=false
        World.bloomEnabled=true; World.bloomIntensity=2.8; World.bloomSize=52; World.bloomThreshold=0.4
        World.ccEnabled=true; World.ccBrightness=0.05; World.ccContrast=0.35; World.ccSaturation=0.9
        World.ccTintColor=Color3.fromRGB(255,150,255)
        World.atmoEnabled=true; World.atmoDensity=0.3; World.atmoHaze=1.5; World.atmoGlare=0.6
        World.atmoColor=Color3.fromRGB(255,80,200); World.atmoDecay=Color3.fromRGB(100,50,180)
    end,
    ["Noir"]=function()
        World.fullbright=false; World.brightness=0.8; World.exposure=0.1
        World.clockTime=20; World.ambient=Color3.fromRGB(60,60,60)
        World.outdoorAmbient=Color3.fromRGB(90,90,90); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=0.5; World.bloomSize=20; World.bloomThreshold=1.3
        World.ccEnabled=true; World.ccBrightness=-0.05; World.ccContrast=0.5; World.ccSaturation=-1
        World.ccTintColor=Color3.fromRGB(255,255,255)
        World.atmoEnabled=true; World.atmoDensity=0.25; World.atmoHaze=2; World.atmoGlare=0.1
        World.atmoColor=Color3.fromRGB(80,80,80); World.atmoDecay=Color3.fromRGB(40,40,40)
    end,
    ["Kawaii"]=function()
        World.fullbright=false; World.brightness=2.3; World.exposure=0.4
        World.clockTime=12; World.ambient=Color3.fromRGB(255,200,220)
        World.outdoorAmbient=Color3.fromRGB(255,220,235); World.globalShadows=false
        World.bloomEnabled=true; World.bloomIntensity=1.5; World.bloomSize=44; World.bloomThreshold=0.8
        World.ccEnabled=true; World.ccBrightness=0.1; World.ccContrast=-0.1; World.ccSaturation=0.4
        World.ccTintColor=Color3.fromRGB(255,220,240)
        World.atmoEnabled=true; World.atmoDensity=0.2; World.atmoHaze=1.5; World.atmoGlare=0.3
        World.atmoColor=Color3.fromRGB(255,220,240); World.atmoDecay=Color3.fromRGB(255,180,220)
    end,
    ["Toxic"]=function()
        World.fullbright=false; World.brightness=1.4; World.exposure=0.2
        World.clockTime=1; World.ambient=Color3.fromRGB(20,50,20)
        World.outdoorAmbient=Color3.fromRGB(30,80,30); World.globalShadows=true
        World.bloomEnabled=true; World.bloomIntensity=1.8; World.bloomSize=40; World.bloomThreshold=0.6
        World.ccEnabled=true; World.ccBrightness=0.05; World.ccContrast=0.3; World.ccSaturation=0.7
        World.ccTintColor=Color3.fromRGB(150,255,150)
        World.atmoEnabled=true; World.atmoDensity=0.35; World.atmoHaze=2; World.atmoGlare=0.4
        World.atmoColor=Color3.fromRGB(80,200,80); World.atmoDecay=Color3.fromRGB(40,120,40)
    end,
}
local function applyShaderPreset(name)
    local fn = SHADER_PRESETS[name]
    if fn then
        World.sunRaysEnabled=false
        World.fogEnabled=false
        fn()
        reapplyAllWorld()
    end
end

-- misc
local _noclipCache = {}
local function applyNoclip(on)
    Misc.noclip = on
    local char = LocalPlayerS.Character
    if not char or not char.Parent then return end
    local cache = _noclipCache[char]
    if on then
        if not cache then cache = {}; _noclipCache[char] = cache end
        for _, pt in ipairs(char:GetDescendants()) do
            if pt:IsA("BasePart") then
                if cache[pt] == nil then cache[pt] = pt.CanCollide end
                pt.CanCollide = false
            end
        end
    else
        if cache then
            for pt, orig in pairs(cache) do
                if pt and pt.Parent then pt.CanCollide = orig end
            end
            _noclipCache[char] = nil
        end
    end
end
local function applyLoopSpeed()
    if not Misc.loopSpeedEnabled then return end
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    -- всегда сохраняем оригинал при первом вызове
    if Misc._savedWalkSpeed == nil then
        Misc._savedWalkSpeed = hum.WalkSpeed
    end
    if hum.WalkSpeed ~= Misc.loopSpeedValue then
        hum.WalkSpeed = Misc.loopSpeedValue
    end
end

local function disableLoopSpeed()
    Misc.loopSpeedEnabled = false
    local char = LocalPlayerS.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and Misc._savedWalkSpeed then
            hum.WalkSpeed = Misc._savedWalkSpeed
        end
    end
    Misc._savedWalkSpeed = nil
end

-- ── override jumppower ──
local function applyLoopJumpPower()
    if not Misc.loopJumpPowerEnabled then return end
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Misc._savedJumpPower == nil or Misc._savedUseJumpPower == nil then
        Misc._savedJumpPower = hum.JumpPower
        Misc._savedUseJumpPower = hum.UseJumpPower
    end
    if not hum.UseJumpPower then
        hum.UseJumpPower = true
    end
    if hum.JumpPower ~= Misc.loopJumpPowerValue then
        hum.JumpPower = Misc.loopJumpPowerValue
    end
end

local function disableLoopJumpPower()
    Misc.loopJumpPowerEnabled = false
    local char = LocalPlayerS.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and Misc._savedJumpPower then
            hum.JumpPower = Misc._savedJumpPower
        end
        if hum and Misc._savedUseJumpPower ~= nil then
            hum.UseJumpPower = Misc._savedUseJumpPower
        end
    end
    Misc._savedJumpPower = nil
    Misc._savedUseJumpPower = nil
end

-- ─── hide nametags (client-side only) ───
local function applyNametagsHide()
    local hide = Misc.hideNametags
    local function setHum(hum)
        if not hum then return end
        pcall(function()
            if hide then
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                hum.NameDisplayDistance   = 0
                hum.HealthDisplayDistance = 0
            else
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Player
            end
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c then
            setHum(c:FindFirstChildOfClass("Humanoid"))
        end
    end
    -- если выключили — прогоняем ещё раз для чужих уже-обработанных
    if not hide then
        -- nop: humanoid reference is enough
    end
end

local _lsPropConn = nil
local function installLoopSpeedHook()
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if _lsPropConn then pcall(function() _lsPropConn:Disconnect() end); _lsPropConn = nil end
    _lsPropConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Misc.loopSpeedEnabled and hum.WalkSpeed ~= Misc.loopSpeedValue then
            hum.WalkSpeed = Misc.loopSpeedValue
        end
    end)
end
local function applySpin(dt)
    if not Misc.spinEnabled then return end
    local char = LocalPlayerS.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt*Misc.spinValue*math.pi/180, 0)
end

-- ── FLY + AURA builder (isolated scope to save registers) ──
local FlyAura = (function()
    local FAC = { _flyBV=nil, _flyBG=nil, _flyConn=nil,
                  _auraConn=nil }

    local function stopFly()
        Misc.flyEnabled = false
        if FAC._flyBV then pcall(function() FAC._flyBV:Destroy() end); FAC._flyBV = nil end
        if FAC._flyBG then pcall(function() FAC._flyBG:Destroy() end); FAC._flyBG = nil end
        if FAC._flyConn then pcall(function() FAC._flyConn:Disconnect() end); FAC._flyConn = nil end
    end

    local function startFly()
        stopFly()
        Misc.flyEnabled = true
        local char = LocalPlayerS.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local bv = Instance.new("BodyVelocity")
        bv.Name = PREFIX.."FlyBV"
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        FAC._flyBV = bv

        local bg = Instance.new("BodyGyro")
        bg.Name = PREFIX.."FlyBG"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 1000; bg.D = 50
        bg.Parent = hrp
        FAC._flyBG = bg

        FAC._flyConn = RunService.Heartbeat:Connect(function()
            if not Misc.flyEnabled then return end
            if UserInputService:GetFocusedTextBox() then return end
            local c = LocalPlayerS.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then return end
            local cam = WorkspaceS.CurrentCamera
            if not cam then return end

            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end

            if move.Magnitude > 0 then
                move = move.Unit * (Misc.flySpeed or 60)
            end
            if FAC._flyBV and FAC._flyBV.Parent then FAC._flyBV.Velocity = move end
            if FAC._flyBG and FAC._flyBG.Parent then FAC._flyBG.CFrame = cam.CFrame end
        end)
    end

    -- ── helpers ──
    local function auraPickTarget()
        local char = LocalPlayerS.Character
        if not char then return nil end
        local myHrp = char:FindFirstChild("HumanoidRootPart")
        if not myHrp then return nil end
        local localTeam = LocalPlayerS.Team
        local closest, closestDist = nil, math.huge
        for i = 1, #activePlayers do
            local p = activePlayers[i]
            if p ~= LocalPlayerS and p.Character then
                local skip = false
                if Aura.teamCheck and p.Team ~= nil and p.Team == localTeam then skip = true end
                if not skip and Aura.skipFriends and isWhitelisted(p) then skip = true end
                if not skip and isTeamNoDraw(p) then skip = true end
                if not skip then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and hrp then
                        local d = (hrp.Position - myHrp.Position).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closest = p
                        end
                    end
                end
            end
        end
        return closest
    end

    -- ────────────────────────────────────────────────────────────
    -- AURA — CFrame + Physics state (никакой физики игры не мешает)
    -- ────────────────────────────────────────────────────────────
    local function auraStopVisualizer()
        local v = Aura._visualize
        if v and v.circle and isDraw(v.circle) then
            pcall(function() v.circle.Visible = false end)
        end
    end

    local function auraDestroyVisualizer()
        local v = Aura._visualize
        if v and v.circle then dRem(v.circle) end
        Aura._visualize = nil
    end

    local function auraEnsureVisualizer()
        if Aura._visualize then return end
        if not DrawOK or not newDraw then return end
        local circle = newDraw("Circle", {
            Visible   = false,
            Filled    = false,
            NumSides  = 64,
            Thickness = 2,
            Transparency = 0.35,
            ZIndex    = 1,
        })
        if not isDraw(circle) then return end
        Aura._visualize = { circle = circle }
    end

    local function auraUpdateVisualizer(tHrp)
        -- выключено → спрятать
        if not Aura.visualizer then
            auraStopVisualizer()
            return
        end
        auraEnsureVisualizer()
        local v = Aura._visualize
        if not v or not v.circle then return end

        -- центр орбиты — над HRP цели, на высоте Aura.height
        local centerPos = tHrp.Position + Vector3.new(0, Aura.height or 2, 0)
        local cScreen, cOn = CameraS:WorldToViewportPoint(centerPos)
        if not cOn or cScreen.Z <= 0 then
            pcall(function() v.circle.Visible = false end)
            return
        end

        -- Радиус в пикселях: проецируем 4 точки по X/Z и берём максимум.
        -- Это устойчиво к перспективе и ориентации камеры.
        local r = Aura.radius or 8
        local maxPx = 0
        local offsets = {
            Vector3.new( r, 0,  0),
            Vector3.new(-r, 0,  0),
            Vector3.new( 0, 0,  r),
            Vector3.new( 0, 0, -r),
        }
        for _, off in ipairs(offsets) do
            local eScreen, eOn = CameraS:WorldToViewportPoint(centerPos + off)
            if eOn and eScreen.Z > 0 then
                local px = (Vector2.new(eScreen.X, eScreen.Y)
                         - Vector2.new(cScreen.X, cScreen.Y)).Magnitude
                if px > maxPx then maxPx = px end
            end
        end
        if maxPx < 4 then
            pcall(function() v.circle.Visible = false end)
            return
        end

        pcall(function()
            v.circle.Position = Vector2.new(cScreen.X, cScreen.Y)
            v.circle.Radius   = maxPx
            v.circle.Color    = Aura.visualColor
            v.circle.Visible  = true
        end)
    end

    local function stopAura()
        Aura.enabled = false
        if FAC._auraConn then pcall(function() FAC._auraConn:Disconnect() end); FAC._auraConn = nil end
        auraDestroyVisualizer()

        local char = LocalPlayerS.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and Aura._saved then
                pcall(function()
                    hum.PlatformStand = Aura._saved.platformStand
                    hum.WalkSpeed     = Aura._saved.walkSpeed
                    hum.JumpPower     = Aura._saved.jumpPower
                    hum.AutoRotate    = Aura._saved.autoRotate
                end)
                -- вернуть состояние гуманоида в норму
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
        end
        Aura._saved = nil
        Aura._phase = 0
        Aura.target = nil
        Aura._lastTarget = nil
        Aura._switchTimer = 0
    end

    local function startAura()
        stopAura()
        Aura.enabled = true

        local char = LocalPlayerS.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        Aura._saved = {
            platformStand = hum.PlatformStand,
            walkSpeed     = hum.WalkSpeed,
            jumpPower     = hum.JumpPower,
            autoRotate    = hum.AutoRotate,
        }
        hum.PlatformStand = true
        hum.WalkSpeed     = 0
        hum.AutoRotate    = false
        pcall(function() hum.JumpPower = 0 end)
        if Aura.physicsMode then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        end

        Aura._phase = 0
        Aura._lastTarget = nil
        Aura._switchTimer = 0

        FAC._auraConn = RunService.Heartbeat:Connect(function(dt)
            if not Aura.enabled then return end
            local c = LocalPlayerS.Character
            if not c then return end
            local h = c:FindFirstChild("HumanoidRootPart")
            local hum2 = c:FindFirstChildOfClass("Humanoid")
            if not h then return end

            -- ── цель ──
            local t = Aura.target
            local tHrp, tHum
            if t and t.Parent and t.Character then
                tHrp = t.Character:FindFirstChild("HumanoidRootPart")
                tHum = t.Character:FindFirstChildOfClass("Humanoid")
            end
            local valid = tHrp ~= nil
            if valid and Aura.onlyWhenAlive and (not tHum or tHum.Health <= 0) then
                valid = false
            end

            if not valid then
                if Aura.autoTarget then
                    local newT = auraPickTarget()
                    if newT and newT ~= Aura._lastTarget then
                        Aura._switchTimer = tick() + (Aura.smoothSwitch or 0)
                        Aura._lastTarget = newT
                    end
                    if Aura._switchTimer <= tick() then
                        t = newT
                        Aura.target = t
                        tHrp = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") or nil
                    else
                        t = Aura._lastTarget
                        Aura.target = t
                        tHrp = t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") or nil
                    end
                else
                    Aura.target = nil
                    t = nil
                end
            end

            if not t or not tHrp then
                auraStopVisualizer()
                return
            end

            -- ── держим hum в правильном состоянии ──
            if hum2 and Aura.physicsMode then
                if hum2:GetState() ~= Enum.HumanoidStateType.Physics then
                    pcall(function() hum2:ChangeState(Enum.HumanoidStateType.Physics) end)
                end
            end

            -- ── орбита ──
            local step = dt or (1/60)
            Aura._phase = (Aura._phase + math.rad(Aura.speed or 180) * step) % (math.pi * 2)
            local tPos = tHrp.Position
            local radius = Aura.radius or 8
            local height = Aura.height or 2
            local x = tPos.X + math.cos(Aura._phase) * radius
            local z = tPos.Z + math.sin(Aura._phase) * radius
            local y = tPos.Y + height

            h.CFrame = CFrame.lookAt(
                Vector3.new(x, y, z),
                Vector3.new(tPos.X, y, tPos.Z))
            h.AssemblyLinearVelocity  = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero

            auraUpdateVisualizer(tHrp)
        end)
    end

    return {
        startFly = startFly, stopFly = stopFly,
        startAura = startAura, stopAura = stopAura,
        setFly = function(v) if v then startFly() else stopFly() end end,
        setAura = function(v) if v then startAura() else stopAura() end end,
    }
end)()

-- ═══════════════════════════════════════════════════════════
-- AUTOSHOOT v3 — self-contained, no external deps
-- ═══════════════════════════════════════════════════════════
local AutoShootAPI = {}
do
    local AutoShoot = {
        enabled         = false,
        delay           = 0.08,
        range           = 500,
        wallCheck       = true,
        teamCheck       = false,
        skipFriends     = true,
        forcefieldCheck = true,
        aliveCheck      = true,
        useScreenCheck  = false,
        crosshairRadius = 60,
        rapidFire       = false,
        rapidFireMult   = 2,
        rapidFireGap    = 0.02,
        _lastShot       = 0,
    }
    AutoShootAPI.SA = AutoShoot
    _G.__PRIMO_AUTOSHOOT = AutoShoot

    local _rp = RaycastParams.new()
    _rp.FilterType = Enum.RaycastFilterType.Exclude
    _rp.IgnoreWater = true

    -- ── стрельба ──
    local function fire()
        local char = LocalPlayerS.Character
        if not char then return false end

        -- способ 1: активировать tool
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool.Enabled then
            if pcall(function() tool:Activate() end) then return true end
        end

        -- способ 2: mouse1click (Xeno умеет)
        if type(mouse1click) == "function" then
            if pcall(mouse1click) then return true end
        end

        -- способ 3: mouse1press/release
        if type(mouse1press) == "function" and type(mouse1release) == "function" then
            pcall(mouse1press)
            pcall(mouse1release)
            return true
        end

        -- способ 4: VirtualInputManager
        local vp = CameraS.ViewportSize
        return pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendMouseButtonEvent(vp.X*0.5, vp.Y*0.5, 0, true,  game, 1)
            VIM:SendMouseButtonEvent(vp.X*0.5, vp.Y*0.5, 0, false, game, 1)
        end)
    end

    -- ── фильтр валидности игрока ──
    local function isTargetValid(pl, model)
        if not pl or pl == LocalPlayerS then return false end
        if AutoShoot.teamCheck and pl.Team and pl.Team == LocalPlayerS.Team then return false end
        if AutoShoot.skipFriends and isWhitelisted and isWhitelisted(pl) then return false end
        if AutoShoot.forcefieldCheck and model:FindFirstChildOfClass("ForceField") then return false end
        if AutoShoot.aliveCheck then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return false end
        end
        return true
    end

    -- ── raycast из камеры ──
    local function findTargetRay()
        local char = LocalPlayerS.Character
        if not char then return nil end
        _rp.FilterDescendantsInstances = {char}
        local ok, res = pcall(function()
            return WorkspaceS:Raycast(
                CameraS.CFrame.Position,
                CameraS.CFrame.LookVector * AutoShoot.range,
                _rp)
        end)
        if not ok or not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not isTargetValid(pl, model) then return nil end
        return pl
    end

    -- ── screen proximity (fallback) ──
    local function findTargetScreen()
        local vp = CameraS.ViewportSize
        local center = Vector2.new(vp.X*0.5, vp.Y*0.5)
        local best, bestD = nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayerS and pl.Character then
                local model = pl.Character
                local head = model:FindFirstChild("Head")
                if head and isTargetValid(pl, model) then
                    local sp, on = CameraS:WorldToViewportPoint(head.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < AutoShoot.crosshairRadius and d < bestD then
                            bestD = d
                            best = pl
                        end
                    end
                end
            end
        end
        return best
    end

    local function findTarget()
        if AutoShoot.useScreenCheck then
            local t = findTargetScreen()
            if t then return t end
        end
        return findTargetRay()
    end

    -- ── основной tick ──
    local function tick()
        if not AutoShoot.enabled then return end
        local now = tick()
        if now - AutoShoot._lastShot < AutoShoot.delay then return end

        -- 1) aimbot target first
        local target = nil
        if Aimbot and Aimbot._currentTarget and Aimbot._currentTarget.player then
            target = Aimbot._currentTarget.player
        end
        -- 2) raycast
        if not target then target = findTargetRay() end
        -- 3) screen proximity fallback
        if not target then target = findTargetScreen() end
        if not target then return end

        AutoShoot._lastShot = now
        Hitsound._lastTriggerShot = now
        lastMouseShot = now
        if Session then Session.shots = (Session.shots or 0) + 1 end

        fire()
        if AutoShoot.rapidFire and AutoShoot.rapidFireMult > 1 then
            local extra = math.max(1, math.floor(AutoShoot.rapidFireMult)) - 1
            task.spawn(function()
                for _ = 1, extra do
                    if AutoShoot.rapidFireGap > 0 then task.wait(AutoShoot.rapidFireGap) end
                    fire()
                end
            end)
        end
    end

    AutoShootAPI.tick = tick
    AutoShootAPI.findTarget = findTarget
    AutoShootAPI.SA = AutoShoot
end
-- ── HITBOX EXPANDER (HRP + Head size override) ──
-- прямая модификация HumanoidRootPart.Size / Head.Size с полным
-- сохранением и восстановлением оригиналов на каждого игрока
local _hitboxOriginals = {}   -- [player] = {char, hrp*, head*}

local resetHitboxOne
-- ── HITBOX EXPANDER (v2) — HRP + Head + все конечности R6/R15 ──
-- Ключевые фишки:
--   1. Сохраняем оригинальные размеры КАЖДОЙ части, а не только HRP/Head
--   2. Материал по умолчанию Neon, CanCollide корректно восстанавливается
--   3. Опционально Massless=false и CustomPhysicalProperties чтобы
--      игра не «выплюнула» расширенную часть обратно
--   4. Пропускает whitelist / team-check
--   5. Мгновенный fast-path когда всё уже правильно
local _hitboxPartNames = {
    "HumanoidRootPart", "Head",
    "UpperTorso", "LowerTorso", "Torso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot",
}

local function applyHitbox(p)
    if p == LocalPlayerS then return end
    if Bypasses.skipFriends and isWhitelisted(p) then
        if resetHitboxOne then resetHitboxOne(p) end
        return
    end
    local char = p.Character
    if not char or not char.Parent then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local sz = math.clamp(Bypasses.hitboxSize or 20, 1, 500)
    local vec = Vector3.new(sz, sz, sz)
    local mat = Enum.Material[Bypasses.hitboxMaterial] or Enum.Material.Neon

    -- ── сохранение оригиналов при первом применении / смене персонажа ──
    local saved = _hitboxOriginals[p]
    if not saved or saved.char ~= char then
        saved = { char = char, parts = {} }
        for _, name in ipairs(_hitboxPartNames) do
            local part = char:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                saved.parts[name] = {
                    Size        = part.Size,
                    Transparency= part.Transparency,
                    Color       = part.Color,
                    Material    = part.Material,
                    CanCollide  = part.CanCollide,
                    Massless    = part.Massless,
                    CustomPhys  = part.CustomPhysicalProperties,
                }
            end
        end
        _hitboxOriginals[p] = saved
    end

    -- ── fast-path: HRP уже правильный ──
    if hrp.Size == vec
       and hrp.Transparency == Bypasses.hitboxTransparency
       and hrp.Color == Bypasses.hitboxColor
       and hrp.Material == mat
       and hrp.CanCollide == Bypasses.hitboxCanCollide
       and hrp.Massless == false then
        if not Bypasses.hitboxApplyToHead then return end
        local head = char:FindFirstChild("Head")
        if head
           and head.Size == vec
           and head.Transparency == Bypasses.hitboxTransparency then
            return
        end
    end

    -- ── применяем ко всем частям ──
    for _, name in ipairs(_hitboxPartNames) do
        -- если выключен "apply to head" — пропускаем Head и всё что выше шеи
        if not Bypasses.hitboxApplyToHead
           and (name == "Head") then
            -- skip
        else
            local part = char:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                pcall(function()
                    part.Size         = vec
                    part.Transparency = Bypasses.hitboxTransparency
                    part.Color        = Bypasses.hitboxColor
                    part.Material     = mat
                    part.CanCollide   = Bypasses.hitboxCanCollide
                    -- не даём физике игры вытолкнуть нас
                    part.Massless     = false
                    part.CustomPhysicalProperties =
                        PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
                end)
            end
        end
    end
end

resetHitboxOne = function(p)
    local saved = _hitboxOriginals[p]
    if not saved then return end
    local char = saved.char
    if char and char.Parent and saved.parts then
        for name, orig in pairs(saved.parts) do
            local part = char:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                pcall(function()
                    part.Size         = orig.Size
                    part.Transparency = orig.Transparency
                    part.Color        = orig.Color
                    part.Material     = orig.Material
                    if orig.CanCollide ~= nil then part.CanCollide = orig.CanCollide end
                    if orig.Massless   ~= nil then part.Massless   = orig.Massless   end
                    if orig.CustomPhys then part.CustomPhysicalProperties = orig.CustomPhys end
                end)
            end
        end
    end
    _hitboxOriginals[p] = nil
end

local function resetAllHitboxes()
    for p in pairs(_hitboxOriginals) do
        pcall(resetHitboxOne, p)
    end
end

local function applyHitboxAll()
    if not Bypasses.hitboxEnabled then return end
    for i = 1, #activePlayers do
        pcall(applyHitbox, activePlayers[i])
    end
end

local PERF_STATE = {saved={}, active=false}

local function _perfBlockNewObjects(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
        or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
        if obj.Enabled then
            PERF_STATE.saved.particles[obj] = true
            obj.Enabled = false
        end
    end
end

local function enterLowPerf()
    if PERF_STATE.active then return end
    PERF_STATE.active = true
    Misc.lowPerf = true

    -- 1) освещение — мягкий режим
    pcall(function()
        PERF_STATE.saved.fogEnd       = LightingS.FogEnd
        PERF_STATE.saved.fogStart     = LightingS.FogStart
        PERF_STATE.saved.brightness   = LightingS.Brightness
        PERF_STATE.saved.globalShadows= LightingS.GlobalShadows
        LightingS.FogEnd       = 500
        LightingS.FogStart     = 100
        LightingS.Brightness   = 1
        LightingS.GlobalShadows= false
    end)

    -- 2) вырубаем частицы/трейлы/бимы БАТЧАМИ (иначе фриз 2-5 сек на большой карте)
    PERF_STATE.saved.particles = {}
    task.spawn(function()
        local batch, MAX = 0, 400
        for _, obj in ipairs(WorkspaceS:GetDescendants()) do
            if not PERF_STATE.active then return end
            pcall(_perfBlockNewObjects, obj)
            batch = batch + 1
            if batch >= MAX then
                batch = 0
                task.wait()   -- отдаём управление главному потоку
            end
        end
    end)
    PERF_STATE.saved.childConn = WorkspaceS.ChildAdded:Connect(function(child)
        if not PERF_STATE.active then return end
        task.spawn(function()
            pcall(function()
                _perfBlockNewObjects(child)
                for _, obj in ipairs(child:GetDescendants()) do
                    _perfBlockNewObjects(obj)
                end
            end)
        end)
    end)

    -- 3) post-FX — тяжёлое, вырубаем
    PERF_STATE.saved.sunRays = World.sunRaysEnabled
    PERF_STATE.saved.bloom   = World.bloomEnabled
    PERF_STATE.saved.cc      = World.ccEnabled
    PERF_STATE.saved.blur    = World.blurEnabled
    PERF_STATE.saved.dof     = World.dofEnabled
    World.sunRaysEnabled = false
    World.bloomEnabled   = false
    World.ccEnabled      = false
    World.blurEnabled    = false
    World.dofEnabled     = false
    pcall(applyPostEffects)

    -- 4) sky — тяжёлое, вырубаем
    PERF_STATE.saved.skyColor    = World.skyColorEnabled
    PERF_STATE.saved.skyOverride = World.skyOverride
    World.skyColorEnabled = false
    World.skyOverride     = false
    pcall(reapplyAllWorld)

    -- ❗️ ESP / чамсы / hitmarker / sounds — НЕ трогаем
end

local function exitLowPerf()
    if not PERF_STATE.active then return end
    PERF_STATE.active = false
    Misc.lowPerf = false

    pcall(function()
        if PERF_STATE.saved.fogEnd    then LightingS.FogEnd    = PERF_STATE.saved.fogEnd    end
        if PERF_STATE.saved.fogStart  then LightingS.FogStart  = PERF_STATE.saved.fogStart  end
        if PERF_STATE.saved.brightness then LightingS.Brightness = PERF_STATE.saved.brightness end
        if PERF_STATE.saved.globalShadows ~= nil then
            LightingS.GlobalShadows = PERF_STATE.saved.globalShadows
        end
    end)

    for obj in pairs(PERF_STATE.saved.particles or {}) do
        pcall(function() if obj and obj.Parent then obj.Enabled = true end end)
    end
    if PERF_STATE.saved.childConn then
        pcall(function() PERF_STATE.saved.childConn:Disconnect() end)
        PERF_STATE.saved.childConn = nil
    end

    if PERF_STATE.saved.sunRays ~= nil then World.sunRaysEnabled = PERF_STATE.saved.sunRays end
    if PERF_STATE.saved.bloom   ~= nil then World.bloomEnabled   = PERF_STATE.saved.bloom   end
    if PERF_STATE.saved.cc      ~= nil then World.ccEnabled      = PERF_STATE.saved.cc      end
    if PERF_STATE.saved.blur    ~= nil then World.blurEnabled    = PERF_STATE.saved.blur    end
    if PERF_STATE.saved.dof     ~= nil then World.dofEnabled     = PERF_STATE.saved.dof     end
    if PERF_STATE.saved.skyColor    ~= nil then World.skyColorEnabled = PERF_STATE.saved.skyColor    end
    if PERF_STATE.saved.skyOverride ~= nil then World.skyOverride     = PERF_STATE.saved.skyOverride end
    pcall(reapplyAllWorld)

    PERF_STATE.saved = {}
end

-- hooks
local function rebuildActive()
    activePlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayerS then activePlayers[#activePlayers+1] = p end
    end
end
rebuildActive()
local function hookPlayerRespawn(p)
    if p == LocalPlayerS then return end
    if charAddedPlayers[p] then pcall(function() charAddedPlayers[p]:Disconnect() end) end
    charAddedPlayers[p] = p.CharacterAdded:Connect(function(char)
        localChamsCache[p] = nil
        localChamsValsCache[p] = nil
        _humCache[p] = nil
        _partsCache[char] = nil
        _hitboxOriginals[p] = nil   -- старый HRP мёртв, оригиналы невалидны
        _ttKilled[p] = nil          -- ФИКС: сбрасываем флаг килла при респавне
        Hitsound.cache[p] = nil     -- чтобы детект урона работал с чистого листа
        if Bypasses.hitboxEnabled then
            task.spawn(function()
                task.wait(0.5)
                if p.Character == char and char.Parent then
                    pcall(applyHitbox, p)
                end
            end)
        end
        task.spawn(function()
            task.wait(0.3)
            pcall(applyNametagsHide)
        end)
    end)
end
local _refreshTargetListDebounce = nil
local function debouncedRefreshTargetList()
    if _refreshTargetListDebounce then
        pcall(function() task.cancel(_refreshTargetListDebounce) end)
    end
    _refreshTargetListDebounce = task.delay(0.5, function()
        _refreshTargetListDebounce = nil
        if _G.refreshTargetList then pcall(_G.refreshTargetList) end
    end)
end

_G.__PRIMO_PlayerAddedConn = Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayerS then
        activePlayers[#activePlayers+1] = p
        pcall(createPlayerData, p)
        hookPlayerRespawn(p)
        debouncedRefreshTargetList()
        task.spawn(function()
            task.wait(1)
            pcall(applyNametagsHide)
        end)
        -- give hitbox to new players if enabled
        if Bypasses.hitboxEnabled then
            task.spawn(function()
                task.wait(1)
                if p.Parent and p.Character and p.Character.Parent then
                    pcall(applyHitbox, p)
                end
            end)
        end
    end
end)
_G.__PRIMO_PlayerRemovingConn = Players.PlayerRemoving:Connect(function(p)
    _humCache[p] = nil
    _hitboxOriginals[p] = nil
    _wlCache[p] = nil
    _noDrawCache[p] = nil
    if p.Character then _partsCache[p.Character] = nil end
    if _G.PRIMO_TARGETS then _G.PRIMO_TARGETS[p] = nil end
    if _G.PRIMO_TARGET == p then _G.PRIMO_TARGET = nil end
    if _refreshTargetListDebounce then
        pcall(function() task.cancel(_refreshTargetListDebounce) end)
        _refreshTargetListDebounce = nil
    end
    _refreshTargetListDebounce = task.delay(0.5, function()
        _refreshTargetListDebounce = nil
        if _G.refreshTargetList then pcall(_G.refreshTargetList) end
    end)
    local nl = {}
    for _, x in ipairs(activePlayers) do
        if x ~= p then nl[#nl+1] = x end
    end
    activePlayers = nl
    destroyDrawings(p)
    playerData[p] = nil
    clearLocalChams(p)
    Hitsound.cache[p] = nil
    KillSound.cache[p] = nil
    _ttKilled[p] = nil
    if charAddedPlayers[p] then
        pcall(function() charAddedPlayers[p]:Disconnect() end)
        charAddedPlayers[p] = nil
    end
end)
for _, p in ipairs(activePlayers) do
    pcall(createPlayerData, p)
    hookPlayerRespawn(p)
end
_G.__PRIMO_CharAddedConn = LocalPlayerS.CharacterAdded:Connect(function(newChar)
    _noclipCache = {}
    Misc._savedWalkSpeed = nil
    Misc._savedJumpPower = nil
    Misc._savedUseJumpPower = nil
    -- Autostop держал ссылки на старую humanoid — сбрасываем
    Autostop._active = false
    Autostop._savedWS = nil
    Autostop._savedJP = nil
    Autostop._releaseAt = nil
    pcall(clearSelfChams)
    task.wait(0.5)
    pcall(function()
        if Misc.noclip then applyNoclip(true) end
    end)
    -- восстановить fly на новом персонаже
    task.spawn(function()
        if Misc.flyEnabled then
            task.wait(0.3)
            if Misc.flyEnabled and FlyAura and FlyAura.startFly then
                FlyAura.startFly()
            end
        end
    end)
    pcall(function()
        if Misc.loopSpeedEnabled then
            applyLoopSpeed()
            installLoopSpeedHook()
        end
    end)
    pcall(applyNametagsHide)
    pcall(reapplyAllWorld)
end)
_G.__PRIMO_WORLD_TASK = task.spawn(function()
    while true do
        task.wait(Misc.lowPerf and 8 or 2)
        if Misc.lowPerf then
            -- minimal: only light maintenance
            if World.fullbright then
                pcall(function()
                    LightingS.Ambient = Color3.fromRGB(255,255,255)
                    LightingS.OutdoorAmbient = Color3.fromRGB(255,255,255)
                    LightingS.Brightness = 2
                    LightingS.ClockTime = 14
                    LightingS.GlobalShadows = false
                end)
            end
        else
        -- only reapply the subsystems that are actually enabled
        -- (prevents fighting game's day/night cycle and FPS drops)
        if World.fullbright then
            pcall(function()
                LightingS.Ambient = Color3.fromRGB(255,255,255)
                LightingS.OutdoorAmbient = Color3.fromRGB(255,255,255)
                LightingS.Brightness = 2
                LightingS.ClockTime = 14
                LightingS.GlobalShadows = false
            end)
        end
        if World.atmoEnabled then pcall(applyAtmosphere) end
        if World.skyOverride then pcall(applySky) end
        if World.fogEnabled then pcall(applyFog) end
        if World.skyColorEnabled then pcall(applySkyColor) end
        if World.sunRaysEnabled or World.bloomEnabled or World.ccEnabled
            or World.blurEnabled or World.dofEnabled then
            pcall(applyPostEffects)
        end

        -- periodic hitbox refresh (медленный резерв, основной — в Heartbeat)
        if Bypasses.hitboxEnabled then
            for i = 1, #activePlayers do
                pcall(applyHitbox, activePlayers[i])
            end
        end

        -- nametags refresh (some games re-enable them)
        if Misc.hideNametags then
            pcall(applyNametagsHide)
        end
        end   -- closing `if not Misc.lowPerf`
    end
end)

-- render
local AIM_BIND = "Primo_AimStep"
pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
RunService:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Last.Value, function(dt)
    -- sticky timer decay
    if Aimbot._stickyTimer and Aimbot._stickyTimer > 0 then
        Aimbot._stickyTimer = Aimbot._stickyTimer - dt
        if Aimbot._stickyTimer <= 0 then Aimbot._stickyTarget = nil end
    end
    local target = nil
    if Aimbot.enabled then
        if not Aimbot.toggleMode then aimbotToggle = keyHeld(Aimbot.key) end
        if aimActive() then
            local newTarget = findTarget()
            if newTarget then
                local prev = Aimbot._currentTarget
                local isNew = (not prev)
                    or (prev.player ~= newTarget.player)
                    or (prev.part ~= newTarget.part)
                if isNew then
                    Aimbot._hitChancePass = (Aimbot.hitChance >= 100)
                        or (math.random(1,100) <= Aimbot.hitChance)
                end
                target = newTarget
                Aimbot._currentTarget = target
                if Aimbot.stickiness > 0 then
                    Aimbot._stickyTarget = target
                    Aimbot._stickyTimer = Aimbot.stickiness
                end
                -- ── aimLock + fire ТОЛЬКО если hitChance прошёл ──
                if Aimbot._hitChancePass then
                    aimLock(target)

                    if Aimbot.autoShoot and shouldFire() then
                        local settled = true
                        if Aimbot.autoShootSettled then
                            settled = isSettled(target.part)
                        end
                        if settled then
                            -- ПЕРЕ-lock перед выстрелом (игра могла перезаписать CF)
                            aimLock(target)

                            -- ── ФИКС: повторная проверка стены ПЕРЕД выстрелом ──
                            -- между findTarget и текущим кадром цель могла уйти за стену
                            local canFire = true
                            if Aimbot.wallCheck then
                                canFire = aimVisiblePos(target.char, target.pos)
                            end
                            if canFire then
                                aimFire()
                            end
                        end
                    end
                end
                -- ── AUTOSTOP: цель есть ──
                if Autostop.enabled then
                    if Aimbot._hitChancePass or not Autostop.onlyWhenLocked then
                        autostopApply()
                    end
                end
            else
                Aimbot._currentTarget = nil
                -- ── AUTOSTOP: цели нет, но юзер хочет стопать всегда ──
                if Autostop.enabled and not Autostop.onlyWhenLocked then
                    autostopApply()
                end
            end
            updateFOV(target ~= nil)
        else
            updateFOV(false)
            Aimbot._currentTarget = nil
            Aimbot._stickyTarget = nil
            Aimbot._stickyTimer = 0
        end
    else
        updateFOV(false)
        Aimbot._currentTarget = nil
    end
    -- ── AUTOSTOP: если не держим цель / выключено — план восстановления ──
    if Autostop.enabled then
        local shouldHold = Aimbot.enabled and aimActive() and target ~= nil
        if not shouldHold then
            if Autostop._active and not Autostop._releaseAt then
                Autostop._releaseAt = tick() + (Autostop.releaseDelay or 0)
            end
        else
            Autostop._releaseAt = nil
        end
    elseif Autostop._active then
        autostopRelease()
    end


    -- ── SILENT AIM: обновляем фейковый Mouse.Hit ──
    pcall(SilentAimAPI.tick)

    if targetESPHolder then
        local newTgt = (target and target.player) or nil
        if _G.__LAST_TARGET_PLAYER ~= newTgt then
            _G.__LAST_TARGET_PLAYER = newTgt
            if newTgt then
                targetESPHolder:SetTarget(newTgt)
            else
                targetESPHolder:ClearTarget()
            end
        end
    end
    -- ── HUD: watermark обновляем 5 раз/сек, а не 60 ──
    _G.__PRIMO_WM_ACCUM = (_G.__PRIMO_WM_ACCUM or 0) + dt
    if _G.__PRIMO_WM_ACCUM >= 0.2 then
        _G.__PRIMO_WM_ACCUM = 0
        if Window and Window.Watermark then
            local tn = "-"
            if target and target.player then tn = target.player.Name end
            pcall(function() Window.Watermark:SetTargetText(tn) end)
        end
    end
    if Aimbot.triggerBot and trigActive() then
        local tb = triggerCheck()
        if tb then
            local settled = true
            if Aimbot.triggerOnlySettled then settled = isSettled(tb.part) end
            if settled then
                local originalCF = CameraS.CFrame
                if Aimbot.triggerNoShake then
                    -- ставим CF ровно на цель, БЕЗ интерполяции
                    CameraS.CFrame = CFrame.lookAt(CameraS.CFrame.Position, tb.part.Position)
                end
                if shouldFire() then
                    -- triggerFire уже синхронно стреляет (фикс #2)
                    -- и восстанавливает CF только после выстрела
                    triggerFire(originalCF)
                    if Aimbot.autoShoot then aimFire() end
                end
                Aimbot._lastHitPart = tb.part.Name
            end
        end
    end
    do
        local hmRate = Misc.lowPerf and (1/30) or (1/60)
        _primo_hmAccum = (_primo_hmAccum or 0) + dt
        if _primo_hmAccum >= hmRate then
            _primo_hmAccum = 0
            pcall(updateHM)
        end
    end
end)
-- ═══════════════════════════════════════════════════════════
-- FORCE CAMERA OVERRIDE — последний рубеж
-- Игра с кастомным шифтлоком перезаписывает Camera.CFrame
-- на своём RenderStepped. Мы перезаписываем ПОСЛЕ неё.
-- ═══════════════════════════════════════════════════════════
_G.__PRIMO_FORCE_CAM_CONN = RunService.RenderStepped:Connect(function()
    local t = Aimbot and Aimbot._currentTarget
    if not t or not Aimbot.enabled then return end
    if not aimbotToggle and not Aimbot.toggleMode then return end
    if Aimbot.toggleMode and not Aimbot._toggle then return end
    if not t.pos or not CameraS then return end
    if not Aimbot._hitChancePass then return end
    pcall(function()
        CameraS.CFrame = CFrame.lookAt(CameraS.CFrame.Position, t.pos)
    end)
end)

_G.__PRIMO_SteppedConn = RunService.Stepped:Connect(function()
    if Misc.loopSpeedEnabled then
        pcall(applyLoopSpeed)
    end
end)

_G.__PRIMO_HeartbeatConn = RunService.Heartbeat:Connect(function(dt)
    if dt > 0.5 or dt <= 0 then dt = 1/60 end
    pcall(applySpin, dt)
    -- (applyLoopSpeed уже крутится в Stepped — не дублируем)
    -- NOCLIP: 5Hz вместо 60Hz — GetDescendants() дорогой вызов
    if Misc.noclip then
        _G.__PRIMO_NOCLIP_ACCUM = (_G.__PRIMO_NOCLIP_ACCUM or 0) + dt
        if _G.__PRIMO_NOCLIP_ACCUM >= 0.5 then
            _G.__PRIMO_NOCLIP_ACCUM = 0
            pcall(applyNoclip, true)
        end
    end
    -- ── HITBOX: throttle refresh (игра может ресетить размеры) ──
    if Bypasses.hitboxEnabled then
        _G.__PRIMO_HitboxAccum = (_G.__PRIMO_HitboxAccum or 0) + dt
        if _G.__PRIMO_HitboxAccum >= (Bypasses.hitboxThrottle or 0.1) then
            _G.__PRIMO_HitboxAccum = 0
            for i = 1, #activePlayers do
                pcall(applyHitbox, activePlayers[i])
            end
        end
    end
    -- ── AUTOSTOP: применяем восстановление по таймеру ──
    if Autostop._active and Autostop._releaseAt and tick() >= Autostop._releaseAt then
        autostopRelease()
    end

    -- ── AUTOSHOOT tick ──
    pcall(AutoShootAPI.tick)
    -- hitbox welded, no per-frame re-apply needed
    do
        local chamsRate = Misc.lowPerf and (1/5) or (1/15)
        _primo_chamsAccum = (_primo_chamsAccum or 0) + dt
        if _primo_chamsAccum >= chamsRate then
            _primo_chamsAccum = 0
            for i=1, #activePlayers do
                pcall(updateLocalChams, activePlayers[i])
            end
            pcall(updateSelfChams)
        end
    end
    if TrashTalk._pendingSend and tick() >= TrashTalk._pendingSend then
        local timeSince = tick() - (TrashTalk._lastSent or 0)
        local minI = TrashTalk._minInterval or 3.0
        if not TrashTalk.enabled then
            TrashTalk._pendingSend = nil
        elseif timeSince >= minI then
            TrashTalk._pendingSend = nil
            pcall(fireTrashTalk)
        else
            -- ❗ FIX: раньше сообщение терялось если minInterval не прошёл.
            -- Теперь переносим отправку на момент когда блокировка снимется
            TrashTalk._pendingSend = tick() + (minI - timeSince) + 0.01
        end
    end
     -- ── health tracking: throttle до 20Hz вместо каждого кадра ──
    _G.__PRIMO_HEALTH_ACCUM = (_G.__PRIMO_HEALTH_ACCUM or 0) + dt
    if _G.__PRIMO_HEALTH_ACCUM < 0.05 then
        -- пропускаем — экономим цикл по игрокам
    else
    _G.__PRIMO_HEALTH_ACCUM = 0
    do
        local now = tick()
        for i = 1, #activePlayers do
            local p = activePlayers[i]
            if p ~= LocalPlayerS and p.Character then
                local hum = getHumCached(p)
                if hum then
                    local prev = Hitsound.cache[p]
                    local cur = hum.Health
                    if prev and cur < prev - 0.01 then
                        local delta = prev - cur
                        local headHit = false
                        local tgt = Aimbot._currentTarget
                        if tgt and tgt.player == p and tgt.part
                            and tgt.part.Name == "Head" then headHit = true end
                        if not headHit and Aimbot._lastHitPart == "Head"
                            and (now - Hitsound._lastTriggerShot) < 0.6 then
                            headHit = true
                        end

local shotRecently = (now - lastMouseShot) < 0.7
    or (now - Hitsound._lastTriggerShot) < 0.7
local weResponsible = false
if shotRecently then
    if tgt and tgt.player == p then
        weResponsible = true
    elseif isPlayerNearCrosshair(p, 400) then
        weResponsible = true
    elseif isCrosshairOnPlayer(p) then
        weResponsible = true
    end
end
-- fallback: если мы реально стреляли и это не whitelist — считаем что попали
if not weResponsible and shotRecently
   and not (I and I.isWhitelisted and I.isWhitelisted(p)) then
    weResponsible = isPlayerNearCrosshair(p, 500)
end

                        if weResponsible then
                            Session.hits = (Session.hits or 0) + 1
                        end
if weResponsible then
    if Hitsound.enabled and Hitsound.mode ~= "every" then
        -- single mode: один звук за факт попадания
        playHit()
    end
    -- для "every" звук уже сыгран при выстреле в fireShot() / InputBegan
end
if Hitmarker.enabled and weResponsible then spawnHM(delta, false, headHit) end
                        if cur <= 0 and prev > 0 and not _ttKilled[p] then
                            if weResponsible then
                                _ttKilled[p] = true
                                if KillSound.enabled then playKill() end
                                if Hitmarker.enabled then spawnHM(delta, true, false) end
                                if TrashTalk.enabled and not TrashTalk._pendingSend then
                                    TrashTalk._pendingSend = now + (TrashTalk.interval or 1)
                                end
                                Session.kills = Session.kills + 1
                                if _G.__PRIMO_SESSION_REFRESH then
                                    pcall(_G.__PRIMO_SESSION_REFRESH)
                                end
                            end
                        end
                        if cur > 0 and _ttKilled[p] then
                            _ttKilled[p] = nil
                        end
                    end
                    Hitsound.cache[p] = cur
                end
            end
        end
    end
    end  -- end health throttle
end)
local lastE = tick()
local eA = 0
_G.__PRIMO_RenderConn = RunService.RenderStepped:Connect(function()
    if not DrawOK then return end
    local now = tick()
    local dt = now - lastE
    lastE = now
    eA = eA + dt
    local rate = Misc.lowPerf and (1/20) or (1/60)
    local doESP = eA >= rate
    if doESP then eA = 0 end
    for i=1, #activePlayers do
        local p = activePlayers[i]
        if playerData[p] == nil then pcall(createPlayerData, p) end
        local d = playerData[p]
        if d and d ~= false and isDraw(d.box) then
            if doESP then pcall(updateESP, p) end
        end
    end
end)

-- input
local function isKeyMatch(input, tk)
    if typeof(tk) ~= "EnumItem" then return false end
    if tk.EnumType == Enum.KeyCode then return input.KeyCode == tk
    elseif tk.EnumType == Enum.UserInputType then return input.UserInputType == tk end
    return false
end
_G.__PRIMO_InputBeganConn = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lastMouseShot = tick()
        Hitsound._lastManualShot = lastMouseShot
        if tick() - (Aimbot._lastTrigger or 0) > 0.05 then
            Session.shots = (Session.shots or 0) + 1
        end
        -- 🎯 every-режим: играем sound при каждом ручном клике
        if Hitsound.enabled and Hitsound.mode == "every"
           and not Aimbot.triggerBot and not Aimbot.autoShoot then
            pcall(playHit)
        end
    end
    if Aimbot.enabled and isKeyMatch(input, Aimbot.key) then
        if Aimbot.toggleMode then Aimbot._toggle = not Aimbot._toggle
        else aimbotToggle = true end
    end
    if Aimbot.triggerBot and Aimbot.triggerToggleMode
        and isKeyMatch(input, Aimbot.triggerKey) then
        triggerToggle = not triggerToggle
    end
    if Misc.loopSpeedKey and isKeyMatch(input, Misc.loopSpeedKey) then
        Misc.loopSpeedEnabled = not Misc.loopSpeedEnabled
        if Misc.loopSpeedEnabled then applyLoopSpeed() end
    end
    if Misc.spinKey and isKeyMatch(input, Misc.spinKey) then
        Misc.spinEnabled = not Misc.spinEnabled
    end
    if Bypasses.forceResetEnabled and Bypasses.forceResetKey
        and isKeyMatch(input, Bypasses.forceResetKey) then
        forceReset()
    end
end)
_G.__PRIMO_InputEndedConn = UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if Aimbot.enabled and isKeyMatch(input, Aimbot.key) and not Aimbot.toggleMode then
        aimbotToggle = false
    end
end)

-- ── force reset (kill self) ──
function forceReset()
    local char = LocalPlayerS.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
    end
    pcall(function() char:BreakJoints() end)
end

_G.PRIMO_INTERNAL = {
    CONTROLS = (function() return _G.__PRIMO_CONTROLS end)(),
    PRESETS = PRESETS,
    ttDefaults = ttDefaults,
    ESP=ESP, Aimbot=Aimbot, Autostop=Autostop, Chams=Chams, SelfChams=SelfChams,
    SilentAim            = SilentAimAPI.SA,
    silentAimInstallHook = SilentAimAPI.installHook,
    silentAimUninstallHook = SilentAimAPI.uninstallHook,
    silentAimTick        = SilentAimAPI.tick,
    AutoShoot            = AutoShootAPI.SA,
    autoshootTick        = AutoShootAPI.tick,
    Hitmarker=Hitmarker, Hitsound=Hitsound, KillSound=KillSound,
    World=World, Misc=Misc, Bypasses=Bypasses,
    WORLD_STATE=WORLD_STATE, PERF_STATE=PERF_STATE,
    Whitelist=Whitelist,
    isWhitelisted=isWhitelisted,
    TrashTalk=TrashTalk,
    Session=Session,
    saveTrashTalk=saveTrashTalk,
    loadTrashTalk=loadTrashTalk,
    sendChatMessage=sendChatMessage,
    fireTrashTalk=fireTrashTalk,
    saveTrashTalkSet=saveTrashTalkSet,
    loadTrashTalkSet=loadTrashTalkSet,
    listTrashTalkSets=listTrashTalkSets,
    deleteTrashTalkSet=deleteTrashTalkSet,
    addWhitelist=addWhitelist,
    addWhitelistUID=addWhitelistUID,
    removeWhitelist=removeWhitelist,
    removeWhitelistUID=removeWhitelistUID,
    clearWhitelist=clearWhitelist,
    listWhitelist=listWhitelist,
    addTeamWhitelist=addTeamWhitelist,
    removeTeamWhitelist=removeTeamWhitelist,
    listTeamWhitelist=listTeamWhitelist,
    saveWhitelist=saveWhitelist,
    isTeamNoDraw=isTeamNoDraw,
    addNoDrawTeam=addNoDrawTeam,
    removeNoDrawTeam=removeNoDrawTeam,
    listNoDrawTeam=listNoDrawTeam,
    clearTeamWhitelist=function()
        Whitelist.Teams = {}
        saveWhitelist()
    end,
    destroyHitmarkers=destroyHitmarkers,
    destroyDrawings=destroyDrawings,
    clearLocalChams=clearLocalChams,
    clearSelfChams=clearSelfChams,
    forceReset=forceReset,
    applyNoclip=applyNoclip,
    applyNametagsHide=applyNametagsHide,
    applyLoopSpeed=applyLoopSpeed,
    disableLoopSpeed=disableLoopSpeed,
    applyLoopJumpPower=applyLoopJumpPower,
    disableLoopJumpPower=disableLoopJumpPower,
    installLoopSpeedHook=installLoopSpeedHook,
    applySpin=applySpin,
    startFly=FlyAura.startFly,
    stopFly=FlyAura.stopFly,
    setFlyEnabled=FlyAura.setFly,
    startAura=FlyAura.startAura,
    stopAura=FlyAura.stopAura,
    setAuraEnabled=FlyAura.setAura,
    Aura=Aura,
    enterLowPerf=enterLowPerf,
    exitLowPerf=exitLowPerf,
    applyHitboxAll=applyHitboxAll,
    applyHitbox=applyHitbox,
    resetAllHitboxes=resetAllHitboxes,
    resetHitboxOne=resetHitboxOne,
    HITBOX_TAG=HITBOX_TAG,   -- legacy, больше не создаётся
    hitboxOriginals=_hitboxOriginals,
    restoreWorldOriginals=restoreWorldOriginals,
    reapplyAllWorld=reapplyAllWorld,
    LightingAmbientOrig=LightingAmbientOrig,
    LightingBrightnessOrig=LightingBrightnessOrig,
    LightingOutdoorOrig=LightingOutdoorOrig,
    LightingClockOrig=LightingClockOrig,
    LightingExposureOrig=LightingExposureOrig,
    LightingShadowsOrig=LightingShadowsOrig,
    LightingEnvDiffOrig=LightingEnvDiffOrig,
    LightingEnvSpecOrig=LightingEnvSpecOrig,
    LightingFogColorOrig=LightingFogColorOrig,
    LightingFogStartOrig=LightingFogStartOrig,
    LightingFogEndOrig=LightingFogEndOrig,
    applyWorld=applyWorld,
    applyAtmosphere=applyAtmosphere,
    applySky=applySky,
    applyPostEffects=applyPostEffects,
    applyFog=applyFog,
    applySkyColor=applySkyColor,
    restoreSkyColor=restoreSkyColor,
    applyShaderPreset=applyShaderPreset,
    setAimbotToggle=function(v) aimbotToggle = v; if Aimbot then Aimbot._toggle = v end end,
    setTriggerToggle=function(v) triggerToggle = v end,
    updateHM=updateHM,
    createSndPool=createSndPool,
    createKillPool=createKillPool,
    playHit=playHit,
    playKill=playKill,
    fireShot=fireShot,
    _fireOnce=_fireOnce,
}
end
_runPart("PART3/Internal", _part3_Internal)

--=================================================================
-- PART 4 : UI
--=================================================================
local function _part4_UI()
local I = _G.PRIMO_INTERNAL or {}

-- ensure target tables exist before any tab uses them
_G.PRIMO_TARGET  = _G.PRIMO_TARGET  or nil
_G.PRIMO_TARGETS = _G.PRIMO_TARGETS or {}

-- ── SAFETY: заглушки для модулей, если их экспорт не удался ──
I.SilentAim = I.SilentAim or {
    enabled=false, key=nil, toggleMode=false, fov=200, maxDist=700,
    hitChance=100, wallCheck=false, teamCheck=false, skipFriends=true,
    forcefieldCheck=true, aliveCheck=true, skipKnocked=false,
    resolverOn=true, projSpeed=150, projGravity=0,
    _hookInstalled=false, _lastHookErr="not exported",
}
I.AutoShoot = I.AutoShoot or {
    enabled=false, key=nil, toggleMode=false, delay=0.08, range=500,
    wallCheck=true, teamCheck=false, skipFriends=true, forcefieldCheck=true,
    aliveCheck=true, onlyADS=false, crosshairRadius=40, useScreenCheck=false,
    hitChance=100, rapidFire=false, rapidFireMult=2, rapidFireGap=0.02,
}
I.__PRIMO_AUTOSHOOT = I.__PRIMO_AUTOSHOOT or I.AutoShoot
I.Aura = I.Aura or {
    enabled=false, key=nil, radius=8, speed=180, height=2,
    teamCheck=false, skipFriends=true, autoTarget=true, target=nil,
    smoothSwitch=0.25, physicsMode=true, visualizer=false,
    visualColor=Color3.fromRGB(255,90,90), onlyWhenAlive=true,
}
I.silentAimInstallHook   = I.silentAimInstallHook   or function() return false, "not exported" end
I.silentAimUninstallHook = I.silentAimUninstallHook or function() end
I.silentAimTick          = I.silentAimTick          or function() end
I.autoshootTick          = I.autoshootTick          or function() end
I.startAura              = I.startAura              or function() end
I.stopAura               = I.stopAura               or function() end
-- trove for global connections that survive UI destroy
I._trove = I._trove or {}
I._track = function(conn) table.insert(I._trove, conn); return conn end
I._untrackAll = function()
    for _, c in ipairs(I._trove) do
        pcall(function() c:Disconnect() end)
    end
    I._trove = {}
end
local create       = UIB.create
local corner       = UIB.corner
local tween        = UIB.tween
local addGlass     = UIB.addGlass
local PALETTE      = UIB.PALETTE
local FONT_REGULAR = UIB.FONT_REGULAR
local FONT_BOLD    = UIB.FONT_BOLD

-- services & helpers
local UserInputService = UIB.UserInputService or game:GetService("UserInputService")
local TweenService     = UIB.TweenService     or game:GetService("TweenService")
local RunService       = UIB.RunService       or game:GetService("RunService")
local Players          = UIB.Players          or game:GetService("Players")
local Stats            = UIB.Stats            or game:GetService("Stats")
local PlayerGui        = UIB.PlayerGui        or Players.LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayer      = UIB.LocalPlayer      or Players.LocalPlayer

local registerAccent   = UIB.registerAccent
local refreshAccent    = UIB.refreshAccent
local resolveSeq       = UIB.resolveSeq
local resolvePulseSeq  = UIB.resolvePulseSeq
local getFontByName    = UIB.getFontByName
local FONT_NAMES       = UIB.FONT_NAMES
local bindName         = UIB.bindName
local parseBind        = UIB.parseBind

-- PART 3 locals, использующиеся в UI (sound browser, trashtalk defaults)
local PRESETS    = (I and I.PRESETS) or {}
local ttDefaults =  I and I.ttDefaults

-- safety fallbacks
if type(registerAccent) ~= "function" then
    registerAccent = function(fn) pcall(fn) end
end
if type(refreshAccent) ~= "function" then
    refreshAccent = function() end
end
if type(resolveSeq) ~= "function" then
    resolveSeq = function(A, B)
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, A),
            ColorSequenceKeypoint.new(0.5, B),
            ColorSequenceKeypoint.new(1, A),
        })
    end
end
if type(resolvePulseSeq) ~= "function" then resolvePulseSeq = resolveSeq end
if type(getFontByName) ~= "function" then
    getFontByName = function() return Font.fromEnum(Enum.Font.Arial) end
end
if type(FONT_NAMES) ~= "table" then FONT_NAMES = {"arial"} end
if type(bindName) ~= "function" then
    bindName = function(b)
        if b == nil then return "unbound" end
        if typeof(b) == "EnumItem" then return b.Name end
        return tostring(b)
    end
end
if type(parseBind) ~= "function" then
    parseBind = function() return nil end
end

local function syncKeybind(name, bind, cb)
    if not Window or not Window.Keybinds then return end
    local kb = Window.Keybinds
    local existing = nil
    if kb._findByName then existing = kb:_findByName(name) end
    -- bind == nil → полностью удаляем запись из киблистов
    if not bind then
        if existing and existing.Remove then existing:Remove() end
        return
    end
    if existing then
        existing:SetKey(bind)
        existing.Callback = cb
    else
        kb:AddBind({Name=name, Key=bind, Callback=cb})
    end
end
I.syncKeybind = syncKeybind
Window = Library:CreateWindow({
    Footer = "hysteria  ///  telegram: @hy5teria",
})
targetESPHolder = Window.TargetList

-- применить сохранённые пресеты сразу
if Window and Window.SetProfilePreset then
    pcall(function()
        Window:SetProfilePreset(Library.Settings.ProfilePreset or "classic")
    end)
end
if Window and Window.SetMenuStyle then
    pcall(function()
        Window:SetMenuStyle(Library.Settings.MenuStyle or "classic")
    end)
end
-- ── menu font applier ──
-- Активный Font-object меню — используем глобально, чтобы хук мог применять его
-- к новым элементам без повторных поисков
_G.__PRIMO_MENU_FONT_OBJ = _G.__PRIMO_MENU_FONT_OBJ or Font.fromEnum(Enum.Font.Arial)

local function _applyMenuFontToObject(obj, fontObj)
    if not fontObj then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        pcall(function() obj.FontFace = fontObj end)
    end
end

 -- Активный Font-object меню
_G.__PRIMO_MENU_FONT_OBJ = _G.__PRIMO_MENU_FONT_OBJ or Font.fromEnum(Enum.Font.Arial)

local function _applyMenuFontToObject(obj, fontObj)
    if not obj then return end
    local isText = obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
    if not isText then return end
    if fontObj then
        pcall(function() obj.FontFace = fontObj end)
    end
end

_G.__PRIMO_APPLY_MENU_FONT = function(fontName)
    if type(fontName) ~= "string" then
        fontName = Library.Settings.MenuFont or "arial"
    end
    fontName = fontName:gsub("^%s+", ""):gsub("%s+$", ""):lower()

    local fObj = nil
    for _, choice in ipairs(FONT_NAMES) do
        if choice:lower() == fontName then
            if UIB.getFontByName then
                fObj = UIB.getFontByName(choice)
            end
            break
        end
    end
    if not fObj then
        fObj = Font.fromEnum(Enum.Font.Arial)
    end
    _G.__PRIMO_MENU_FONT_OBJ = fObj

    local targets = {}
    if Window and Window.Frame then table.insert(targets, Window.Frame) end
    local pg = PlayerGui
    if pg then
        local primo = pg:FindFirstChild("primo")
        if primo then table.insert(targets, primo) end
        local popups = pg:FindFirstChild("primo_popups")
        if popups then table.insert(targets, popups) end
    end

    for _, root in ipairs(targets) do
        for _, obj in ipairs(root:GetDescendants()) do
            _applyMenuFontToObject(obj, fObj)
        end
    end
end

-- Хук на новые элементы
local function _installMenuFontHook()
    local pg = PlayerGui
    if not pg then return end
    local function hook(screen)
        if not screen then return end
        if screen:GetAttribute("__primoFontHooked") then return end
        screen:SetAttribute("__primoFontHooked", true)
        screen.DescendantAdded:Connect(function(obj)
            _applyMenuFontToObject(obj, _G.__PRIMO_MENU_FONT_OBJ)
            -- для контейнеров — обходим детей с задержкой
            if obj:IsA("GuiObject") then
                task.defer(function()
                    if obj and obj.Parent then
                        for _, child in ipairs(obj:GetDescendants()) do
                            _applyMenuFontToObject(child, _G.__PRIMO_MENU_FONT_OBJ)
                        end
                    end
                end)
            end
        end)
    end
    local primo = pg:FindFirstChild("primo")
    if primo then hook(primo) end
    local popups = pg:FindFirstChild("primo_popups")
    if popups then hook(popups) end
    task.spawn(function()
        for _ = 1, 60 do
            task.wait(0.5)
            local p = pg:FindFirstChild("primo")
            if p then hook(p) end
            local q = pg:FindFirstChild("primo_popups")
            if q then hook(q) end
        end
    end)
end
task.defer(_installMenuFontHook)

-- отложенное переприменение — 3 раза после старта
task.spawn(function()
    for _ = 1, 3 do
        task.wait(0.5)
        if _G.__PRIMO_APPLY_MENU_FONT then
            pcall(_G.__PRIMO_APPLY_MENU_FONT, Library.Settings.MenuFont)
        end
    end
end)
-- ── post-config-load hook: переприменяем зависимые настройки ──
-- (theme, avatar preset/custom) чтобы не зависеть от порядка pairs()
_G.__PRIMO_POSTLOAD = function()
    -- theme
    if Library and Library.SetTheme then
        local themeName = Library.Settings and Library.Settings.Theme or "dark"
        pcall(function() Library:SetTheme(themeName) end)
    end
    -- HUD scales
    local sc = Library.Settings and Library.Settings.HUDScale or {}
    if Window then
        if Window.Watermark and Window.Watermark.SetScale and sc.watermark then
            pcall(function() Window.Watermark:SetScale(sc.watermark) end)
        end
        if Window.Keybinds and Window.Keybinds.SetScale and sc.keybinds then
            pcall(function() Window.Keybinds:SetScale(sc.keybinds) end)
        end
        if Window.TargetList and Window.TargetList.SetScale and sc.targetesp then
            pcall(function() Window.TargetList:SetScale(sc.targetesp) end)
        end
        if Window.Picture and Window.Picture.SetScale and sc.picture then
            pcall(function() Window.Picture:SetScale(sc.picture) end)
        end
        if _G.__PRIMO_SESSION_SET_SCALE and sc.session then
            pcall(function() _G.__PRIMO_SESSION_SET_SCALE(sc.session) end)
        end
    end
    -- avatar — нормализуем через ту же функцию, что и ручной ввод
    if _G.__PRIMO_APPLY_AVATAR_PRESET then
        local pc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.avatarPreset"]
        if pc then
            pcall(_G.__PRIMO_APPLY_AVATAR_PRESET, pc:Get())
        end
    end
    -- переприменяем прозрачности аватарки (важно если Set-контрол
    -- отработал раньше, чем создан avatarBox)
    if Library and Library._avatarBox and Library._avatarBox.Parent then
        local bgt = Library.Settings.AvatarBgTransparency
        if bgt ~= nil then
            pcall(function() Library._avatarBox.BackgroundTransparency = bgt end)
        end
    end
    if Library and Library._avatarStroke and Library._avatarStroke.Parent then
        local bdt = Library.Settings.AvatarBorderTransparency
        if bdt ~= nil then
            pcall(function() Library._avatarStroke.Transparency = bdt end)
        end
    end
    -- menu scale (применяется к Window, может не успеть)
    if Window and Window.SetScale and Library then
        local s = Library.Settings and Library.Settings.MenuScale or 1.0
        pcall(function() Window:SetScale(s) end)
    end
    -- avatar size / corner
    if Library and Library._avatarBox and Library._avatarBox.Parent then
        local sz = Library.Settings.AvatarSize
        if sz then
            pcall(function()
                Library._avatarBox.Size = UDim2.new(0, sz, 0, math.floor(sz * 0.92))
            end)
        end
        local cr = Library.Settings.AvatarCorner
        if cr then
            local c = Library._avatarBox:FindFirstChildOfClass("UICorner")
            if c then c.CornerRadius = UDim.new(0, cr) end
        end
    end
    -- menu corner / shadow
    if Window and Window.Frame then
        local mcr = Library.Settings.MenuCornerRadius
        if mcr then
            local c = Window.Frame:FindFirstChildOfClass("UICorner")
            if c then c.CornerRadius = UDim.new(0, mcr) end
        end
        local mst = Library.Settings.MenuShadowTransp
        if mst then
            local sh = Window.Frame:FindFirstChild("shadow")
            if sh then sh.BackgroundTransparency = mst end
        end
    end
    -- menu font (двойное применение: сразу + через 0.15с чтобы попапы успели создаться)
    if _G.__PRIMO_APPLY_MENU_FONT then
        local desiredFont = Library.Settings.MenuFont or "arial"
        pcall(_G.__PRIMO_APPLY_MENU_FONT, desiredFont)
        task.delay(0.15, function()
            if _G.__PRIMO_APPLY_MENU_FONT then
                pcall(_G.__PRIMO_APPLY_MENU_FONT, Library.Settings.MenuFont or desiredFont)
            end
        end)
    end
    -- profile layout preset
    if Window and Window.SetProfilePreset then
        pcall(function()
            Window:SetProfilePreset(Library.Settings.ProfilePreset or "classic")
        end)
    end
    -- menu style preset
    if Window and Window.SetMenuStyle then
        pcall(function()
            Window:SetMenuStyle(Library.Settings.MenuStyle or "classic")
        end)
    end
end

-- ── register HUD positions as persistable controls ──
do
    local function posControl(api)
        if not api then return end
        local CONTROLS = _G.__PRIMO_CONTROLS
        if not CONTROLS then return end
        return {
            Get = function(self)
                local p = api:GetPosition()
                return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
            end,
            Set = function(self, v, silent)
                if type(v) ~= "table" or #v < 4 then return end
                local p = UDim2.new(v[1], v[2], v[3], v[4])
                api:SetPosition(p)
            end,
        }
    end
    local c = _G.__PRIMO_CONTROLS
    if c then
        if Window.Watermark and Window.Watermark.GetPosition then
            c["hud.position.watermark"] = posControl(Window.Watermark)
        end
        if Window.Keybinds and Window.Keybinds.GetPosition then
            c["hud.position.keybinds"] = posControl(Window.Keybinds)
        end
        if Window.TargetList and Window.TargetList.GetPosition then
            c["hud.position.targetlist"] = posControl(Window.TargetList)
        end
        if Window.Picture and Window.Picture.GetPosition then
            c["hud.position.picture"] = posControl(Window.Picture)
        end
        if Window.Picture and Window.Picture.GetPosition then
            c["hud.position.picture"] = posControl(Window.Picture)
        end

        -- session HUD создаётся в do-блоке session ниже,
        -- поэтому позиция резолвится лениво через _G
        c["hud.position.session"] = {
            Get = function(self)
                local sf = _G.__PRIMO_SESSION_FRAME
                if not sf then return { 0.56035, 0, 0.54636, 0 } end
                local p = sf.Position
                return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
            end,
            Set = function(self, v, silent)
                if type(v) ~= "table" or #v < 4 then return end
                local sf = _G.__PRIMO_SESSION_FRAME
                if sf then
                    sf.Position = UDim2.new(v[1], v[2], v[3], v[4])
                end
            end,
        }

        -- позиция самого меню
        c["hud.position.menu"] = {
            Get = function(self)
                if not Window or not Window.Frame then
                    return { 0.5, -660, 0.5, -370 }
                end
                local p = Window.Frame.Position
                return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
            end,
            Set = function(self, v, silent)
                if type(v) ~= "table" or #v < 4 then return end
                if Window and Window.Frame then
                    Window.Frame.Position = UDim2.new(v[1], v[2], v[3], v[4])
                end
            end,
        }
    end
end   -- ← ЭТОГО end НЕ ХВАТАЛО

--===============================================================
-- VISUALS TAB
--===============================================================
do
    local visualsTab = Window:CreateTab({
        Name = "visuals", Horizontal = true, CanvasWidth = 1620,
    })

    local espSect = visualsTab:CreateSection({
        Title = "- esp -", Position = UDim2.new(0,8,0,8),
        Size = UDim2.new(0,214,0,1420),
    })
    reg(espSect, "Toggle", "esp.enabled", {Text="enable esp", Default=true,
        Callback=function(v) I.ESP.enabled = v end})
    reg(espSect, "Toggle", "esp.box", {Text="box", Default=true,
        Callback=function(v) I.ESP.box = v end})
    reg(espSect, "Toggle", "esp.boxFill", {Text="box filled", Default=false,
        Callback=function(v) I.ESP.boxFill = v end})
    reg(espSect, "Toggle", "esp.cornerBox", {Text="corner box", Default=false,
        Callback=function(v) I.ESP.cornerBox = v end})
    reg(espSect, "Toggle", "esp.outline", {Text="box outline", Default=false,
        Callback=function(v) I.ESP.outline = v end})
    reg(espSect, "Toggle", "esp.glow", {Text="multi-layer glow", Default=false,
        Callback=function(v) I.ESP.glow = v end})
    reg(espSect, "Toggle", "esp.name", {Text="name", Default=true,
        Callback=function(v) I.ESP.name = v end})
    reg(espSect, "Cycle", "esp.nameFormat", {
        Prefix="name: ",
        Values={"DisplayNameUsername","DisplayNameUsernameStar","Username","DisplayName","Custom"},
        Index=1, Callback=function(v) I.ESP.nameFormat = v end})
    reg(espSect, "TextBox", "esp.customName", {Placeholder="custom name text",
        Text=I.ESP.customName,
        Callback=function(t) if t and t ~= "" then I.ESP.customName = t end end})
    reg(espSect, "Toggle", "esp.health", {Text="health bar", Default=false,
        Callback=function(v) I.ESP.health = v end})
    reg(espSect, "Cycle", "esp.healthSide", {Prefix="hp side: ",
        Values={"Right","Bottom"}, Index=1,
        Callback=function(v) I.ESP.healthSide = v end})
    reg(espSect, "Cycle", "esp.healthColorMode", {Prefix="hp color: ",
        Values={"Gradient","GradientCustom","Static","Custom","Rainbow"}, Index=1,
        Callback=function(v) I.ESP.healthColorMode = v end})
    reg(espSect, "Toggle", "esp.healthText", {Text="health TEXT", Default=false,
        Callback=function(v) I.ESP.healthText = v end})
    reg(espSect, "Toggle", "esp.tracer", {Text="tracer", Default=false,
        Callback=function(v) I.ESP.tracer = v end})
    reg(espSect, "Cycle", "esp.tracerOrigin", {Prefix="tracer origin: ",
        Values={"Bottom","Center","Top"}, Index=1,
        Callback=function(v) I.ESP.tracerOrigin = v end})
    reg(espSect, "Toggle", "esp.distance", {Text="distance", Default=false,
        Callback=function(v) I.ESP.distance = v end})
    reg(espSect, "Toggle", "esp.headDot", {Text="head dot", Default=false,
        Callback=function(v) I.ESP.headDot = v end})
    reg(espSect, "Toggle", "esp.headDotFilled", {Text="head dot filled", Default=true,
        Callback=function(v) I.ESP.headDotFilled = v end})
    reg(espSect, "Toggle", "esp.teamCheck", {Text="team check", Default=false,
        Callback=function(v) I.ESP.teamCheck = v end})
    reg(espSect, "Toggle", "esp.useTeamColor", {Text="use team color", Default=true,
        Callback=function(v) I.ESP.useTeamColor = v end})
    reg(espSect, "Toggle", "esp.nameScale", {Text="name scales w/ box", Default=false,
        Callback=function(v) I.ESP.nameScale = v end})
    reg(espSect, "Toggle", "esp.headDotScale", {Text="head dot scales w/ box", Default=false,
        Callback=function(v) I.ESP.headDotScale = v end})
    reg(espSect, "Slider", "esp.maxDistance", {Text="max distance",
        Min=50, Max=5000, Default=1000,
        Callback=function(v) I.ESP.maxDistance = v end})
    reg(espSect, "Slider", "esp.nameSize", {Text="name size",
        Min=8, Max=30, Default=15,
        Callback=function(v) I.ESP.nameSize = v end})
    reg(espSect, "Slider", "esp.nameOffset", {Text="name offset",
        Min=0, Max=40, Default=4,
        Callback=function(v) I.ESP.nameOffset = v end})
    reg(espSect, "Slider", "esp.distSize", {Text="distance size",
        Min=8, Max=24, Default=13,
        Callback=function(v) I.ESP.distSize = v end})
    reg(espSect, "Slider", "esp.headDotSize", {Text="head dot radius",
        Min=1, Max=30, Default=5,
        Callback=function(v) I.ESP.headDotSize = v end})
    reg(espSect, "Slider", "esp.headDotTransp", {Text="head dot transp",
        Min=0, Max=1, Default=0,
        Callback=function(v) I.ESP.headDotTransp = v end})
    reg(espSect, "Slider", "esp.headDotThickness", {Text="head dot thickness",
        Min=1, Max=10, Default=1,
        Callback=function(v) I.ESP.headDotThickness = v end})
    reg(espSect, "Toggle", "esp.skeleton", {Text="skeleton", Default=false,
        Callback=function(v) I.ESP.skeleton = v end})
    reg(espSect, "Slider", "esp.skeletonThick", {Text="skeleton thickness",
        Min=1, Max=5, Default=1,
        Callback=function(v) I.ESP.skeletonThick = v end})
    reg(espSect, "Slider", "esp.skeletonTransp", {Text="skeleton transparency",
        Min=0, Max=1, Default=0.2,
        Callback=function(v) I.ESP.skeletonTransp = v end})
    reg(espSect, "Toggle", "esp.healthBasedColor", {Text="health-based color", Default=false,
        Callback=function(v) I.ESP.healthBasedColor = v end})
    reg(espSect, "Toggle", "esp.weaponName", {Text="weapon name (label)", Default=false,
        Callback=function(v) I.ESP.weaponName = v end})

    espSect:Divider()
    espSect:Label("- 3D wireframe box -", 18)
    reg(espSect, "Toggle", "esp.box3D", {Text="enable 3D box", Default=false,
        Callback=function(v) I.ESP.box3D = v end})
    reg(espSect, "Slider", "esp.box3DThick", {Text="3D box thickness",
        Min=1, Max=4, Default=1,
        Callback=function(v) I.ESP.box3DThick = v end})
    reg(espSect, "Slider", "esp.box3DTransp", {Text="3D box transparency",
        Min=0, Max=1, Default=0.4,
        Callback=function(v) I.ESP.box3DTransp = v end})

    espSect:Divider()
    espSect:Label("- visual fx -", 18)
    reg(espSect, "Toggle", "esp.distanceFade", {Text="distance fade", Default=false,
        Callback=function(v) I.ESP.distanceFade = v end})
    reg(espSect, "Slider", "esp.distanceFadeNear", {Text="fade near (studs)",
        Min=5, Max=500, Default=30,
        Callback=function(v) I.ESP.distanceFadeNear = v end})
    reg(espSect, "Slider", "esp.distanceFadeFar", {Text="fade far (studs)",
        Min=50, Max=3000, Default=500,
        Callback=function(v) I.ESP.distanceFadeFar = v end})
    reg(espSect, "Toggle", "esp.targetPulse", {Text="pulse on target", Default=false,
        Callback=function(v) I.ESP.targetPulse = v end})

    espSect:Divider()
    espSect:Label("- gradient 2D box -", 18)
    reg(espSect, "Toggle", "esp.boxGradient2D", {Text="enable gradient box", Default=false,
        Callback=function(v) I.ESP.boxGradient2D = v end})
    reg(espSect, "ColorPicker", "esp.boxGradientColorA", {Text="top color",
        GetInitialColor=function() return I.ESP.boxGradientColorA end,
        Callback=function(c) I.ESP.boxGradientColorA = c end})
    reg(espSect, "ColorPicker", "esp.boxGradientColorB", {Text="bottom color",
        GetInitialColor=function() return I.ESP.boxGradientColorB end,
        Callback=function(c) I.ESP.boxGradientColorB = c end})
    reg(espSect, "Slider", "esp.boxGradientTransp", {Text="gradient transparency",
        Min=0, Max=1, Default=0.65,
        Callback=function(v) I.ESP.boxGradientTransp = v end})

    espSect:Divider()
    espSect:Label("- 3D head sphere -", 18)
    reg(espSect, "Toggle", "esp.headSphere", {Text="enable head sphere", Default=false,
        Callback=function(v) I.ESP.headSphere = v end})
    reg(espSect, "ColorPicker", "esp.headSphereColor", {Text="sphere color",
        GetInitialColor=function() return I.ESP.headSphereColor end,
        Callback=function(c) I.ESP.headSphereColor = c end})
    reg(espSect, "Slider", "esp.headSphereThick", {Text="thickness",
        Min=1, Max=6, Default=1.5,
        Callback=function(v) I.ESP.headSphereThick = v end})
    reg(espSect, "Slider", "esp.headSphereTransp", {Text="transparency",
        Min=0, Max=1, Default=0.15,
        Callback=function(v) I.ESP.headSphereTransp = v end})
    reg(espSect, "Slider", "esp.headSphereScale", {Text="scale",
        Min=0.7, Max=2.0, Default=1.15,
        Callback=function(v) I.ESP.headSphereScale = v end})

    espSect:Divider()
    espSect:Label("- inline info (in name) -", 18)
    reg(espSect, "Toggle", "esp.nameShowHP", {Text="hp in name", Default=false,
        Callback=function(v) I.ESP.nameShowHP = v end})
    reg(espSect, "Toggle", "esp.nameShowDistance", {Text="distance in name", Default=false,
        Callback=function(v) I.ESP.nameShowDistance = v end})
    reg(espSect, "Toggle", "esp.nameShowWeapon", {Text="weapon in name", Default=false,
        Callback=function(v) I.ESP.nameShowWeapon = v end})

    espSect:Divider()
    espSect:Label("- presets -", 18)

    local function syncESP(pairs_)
        for path, val in pairs(pairs_) do
            local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS[path]
            if c and c.Set then pcall(function() c:Set(val, true) end) end
        end
    end

    espSect:Button({Text="preset: legit", Callback=function()
        local E = I.ESP
        E.enabled=true; E.box=true; E.boxFill=false; E.cornerBox=false
        E.outline=true; E.glow=false
        E.name=true; E.nameShowHP=false; E.nameShowDistance=false; E.nameShowWeapon=false
        E.health=true; E.healthText=false
        E.tracer=false; E.distance=true; E.headDot=false
        E.skeleton=false; E.weaponName=false
        E.boxTransp=0.5; E.boxThick=1; E.outlineThick=1; E.outlineTransp=0.6
        syncESP({
            ["esp.enabled"]=true, ["esp.box"]=true, ["esp.boxFill"]=false,
            ["esp.cornerBox"]=false, ["esp.outline"]=true, ["esp.glow"]=false,
            ["esp.name"]=true, ["esp.nameShowHP"]=false,
            ["esp.nameShowDistance"]=false, ["esp.nameShowWeapon"]=false,
            ["esp.health"]=true, ["esp.healthText"]=false,
            ["esp.tracer"]=false, ["esp.distance"]=true, ["esp.headDot"]=false,
            ["esp.skeleton"]=false, ["esp.weaponName"]=false,
            ["esp.boxTransp"]=0.5, ["esp.boxThick"]=1,
        })
    end})

    espSect:Button({Text="preset: rage", Callback=function()
        local E = I.ESP
        E.enabled=true; E.box=true; E.boxFill=true; E.cornerBox=false
        E.outline=true; E.glow=true
        E.name=true; E.nameShowHP=true; E.nameShowDistance=true; E.nameShowWeapon=false
        E.health=true; E.healthText=true
        E.tracer=true; E.distance=true; E.headDot=true
        E.skeleton=true; E.weaponName=true
        E.boxTransp=0.2; E.boxThick=2; E.outlineThick=2; E.outlineTransp=0.3
        E.glowThick=18; E.glowTransp=0.3
        syncESP({
            ["esp.enabled"]=true, ["esp.box"]=true, ["esp.boxFill"]=true,
            ["esp.cornerBox"]=false, ["esp.outline"]=true, ["esp.glow"]=true,
            ["esp.name"]=true, ["esp.nameShowHP"]=true,
            ["esp.nameShowDistance"]=true, ["esp.nameShowWeapon"]=false,
            ["esp.health"]=true, ["esp.healthText"]=true,
            ["esp.tracer"]=true, ["esp.distance"]=true, ["esp.headDot"]=true,
            ["esp.skeleton"]=true, ["esp.weaponName"]=true,
            ["esp.boxTransp"]=0.2, ["esp.boxThick"]=2,
            ["esp.glowThick"]=18, ["esp.glowTransp"]=0.3,
        })
    end})

    espSect:Button({Text="preset: minimal", Callback=function()
        local E = I.ESP
        E.enabled=true; E.box=true; E.boxFill=false; E.cornerBox=false
        E.outline=false; E.glow=false
        E.name=false; E.nameShowHP=false; E.nameShowDistance=false; E.nameShowWeapon=false
        E.health=false; E.healthText=false
        E.tracer=false; E.distance=false; E.headDot=false
        E.skeleton=false; E.weaponName=false
        E.boxTransp=0.4; E.boxThick=1
        syncESP({
            ["esp.enabled"]=true, ["esp.box"]=true, ["esp.boxFill"]=false,
            ["esp.cornerBox"]=false, ["esp.outline"]=false, ["esp.glow"]=false,
            ["esp.name"]=false, ["esp.nameShowHP"]=false,
            ["esp.nameShowDistance"]=false, ["esp.nameShowWeapon"]=false,
            ["esp.health"]=false, ["esp.healthText"]=false,
            ["esp.tracer"]=false, ["esp.distance"]=false, ["esp.headDot"]=false,
            ["esp.skeleton"]=false, ["esp.weaponName"]=false,
            ["esp.boxTransp"]=0.4, ["esp.boxThick"]=1,
        })
    end})

    espSect:Button({Text="preset: streamer", Callback=function()
        local E = I.ESP
        E.enabled=true; E.box=true; E.boxFill=false; E.cornerBox=true
        E.outline=false; E.glow=false
        E.name=true; E.nameShowHP=false; E.nameShowDistance=true; E.nameShowWeapon=false
        E.health=true; E.healthText=false
        E.tracer=false; E.distance=false; E.headDot=false
        E.skeleton=false; E.weaponName=false
        E.cornerLength=0.18; E.boxThick=2; E.boxTransp=0.25
        syncESP({
            ["esp.enabled"]=true, ["esp.box"]=true, ["esp.boxFill"]=false,
            ["esp.cornerBox"]=true, ["esp.outline"]=false, ["esp.glow"]=false,
            ["esp.name"]=true, ["esp.nameShowHP"]=false,
            ["esp.nameShowDistance"]=true, ["esp.nameShowWeapon"]=false,
            ["esp.health"]=true, ["esp.healthText"]=false,
            ["esp.tracer"]=false, ["esp.distance"]=false, ["esp.headDot"]=false,
            ["esp.skeleton"]=false, ["esp.weaponName"]=false,
            ["esp.cornerLength"]=0.18, ["esp.boxThick"]=2, ["esp.boxTransp"]=0.25,
        })
    end})

    local appSect = visualsTab:CreateSection({
        Title = "- appearance -", Position = UDim2.new(0,234,0,8),
        Size = UDim2.new(0,214,0,1180),
    })
    reg(appSect, "ColorPicker", "esp.skeletonColor", {Text="skeleton color",
        GetInitialColor=function() return I.ESP.skeletonColor end,
        Callback=function(c) I.ESP.skeletonColor = c end})
    reg(appSect, "ColorPicker", "esp.weaponColor", {Text="weapon color",
        GetInitialColor=function() return I.ESP.weaponColor end,
        Callback=function(c) I.ESP.weaponColor = c end})
    reg(appSect, "Slider", "esp.boxTransp", {Text="box transparency",
        Min=0, Max=1, Default=0.3,
        Callback=function(v) I.ESP.boxTransp = v end})
    reg(appSect, "Slider", "esp.boxThick", {Text="box thickness",
        Min=1, Max=5, Default=1.5,
        Callback=function(v) I.ESP.boxThick = v end})
    reg(appSect, "Slider", "esp.cornerLength", {Text="corner length",
        Min=0.05, Max=0.5, Default=0.25,
        Callback=function(v) I.ESP.cornerLength = v end})
    reg(appSect, "Slider", "esp.outlineThick", {Text="outline thickness",
        Min=1, Max=8, Default=1,
        Callback=function(v) I.ESP.outlineThick = v end})
    reg(appSect, "Slider", "esp.outlineTransp", {Text="outline transparency",
        Min=0, Max=1, Default=0.5,
        Callback=function(v) I.ESP.outlineTransp = v end})
    reg(appSect, "Slider", "esp.glowThick", {Text="glow total thickness",
        Min=4, Max=30, Default=14,
        Callback=function(v) I.ESP.glowThick = v end})
    reg(appSect, "Slider", "esp.glowLayers", {Text="glow layers",
        Min=1, Max=6, Default=6,
        Callback=function(v) I.ESP.glowLayers = math.floor(v) end})
    reg(appSect, "Slider", "esp.glowTransp", {Text="glow base transp",
        Min=0, Max=1, Default=0.4,
        Callback=function(v) I.ESP.glowTransp = v end})
    reg(appSect, "Slider", "esp.healthBarThickness", {Text="hp thickness",
        Min=1, Max=12, Default=3,
        Callback=function(v) I.ESP.healthBarThickness = v end})
    reg(appSect, "Slider", "esp.healthBarLength", {Text="hp length scale",
        Min=0.1, Max=2, Default=1,
        Callback=function(v) I.ESP.healthBarLength = v end})
    reg(appSect, "Slider", "esp.healthBarOffset", {Text="hp offset",
        Min=0, Max=30, Default=4,
        Callback=function(v) I.ESP.healthBarOffset = v end})
    reg(appSect, "Slider", "esp.healthTextSize", {Text="hp text size",
        Min=6, Max=32, Default=12,
        Callback=function(v) I.ESP.healthTextSize = v end})
    reg(appSect, "Slider", "esp.healthTextOffsetY", {Text="hp text y offset",
        Min=0, Max=80, Default=20,
        Callback=function(v) I.ESP.healthTextOffsetY = v end})
    reg(appSect, "Cycle", "esp.font", {Prefix="font: ",
        Values={"UI","System","Plex","Monospace"}, Index=3,
        Callback=function(v)
            local map = {UI=0, System=1, Plex=2, Monospace=3}
            I.ESP.font = map[v] or 2
        end})
    reg(appSect, "ColorPicker", "esp.boxColor", {Text="box color",
        GetInitialColor=function() return I.ESP.boxColor end,
        Callback=function(c) I.ESP.boxColor = c end})
    reg(appSect, "ColorPicker", "esp.outlineColor", {Text="outline color",
        GetInitialColor=function() return I.ESP.outlineColor end,
        Callback=function(c) I.ESP.outlineColor = c end})
    reg(appSect, "ColorPicker", "esp.glowColor", {Text="glow color",
        GetInitialColor=function() return I.ESP.glowColor end,
        Callback=function(c) I.ESP.glowColor = c end})
    reg(appSect, "ColorPicker", "esp.tracerColor", {Text="tracer color",
        GetInitialColor=function() return I.ESP.tracerColor end,
        Callback=function(c) I.ESP.tracerColor = c end})
    reg(appSect, "ColorPicker", "esp.nameColor", {Text="name color",
        GetInitialColor=function() return I.ESP.nameColor end,
        Callback=function(c) I.ESP.nameColor = c end})
    reg(appSect, "ColorPicker", "esp.headDotColor", {Text="head dot color",
        GetInitialColor=function() return I.ESP.headDotColor end,
        Callback=function(c) I.ESP.headDotColor = c end})
    reg(appSect, "ColorPicker", "esp.healthGradStart", {Text="hp grad start",
        GetInitialColor=function() return I.ESP.healthGradStart end,
        Callback=function(c) I.ESP.healthGradStart = c end})
    reg(appSect, "ColorPicker", "esp.healthGradEnd", {Text="hp grad end",
        GetInitialColor=function() return I.ESP.healthGradEnd end,
        Callback=function(c) I.ESP.healthGradEnd = c end})
    reg(appSect, "ColorPicker", "esp.healthCustomColor", {Text="hp custom color",
        GetInitialColor=function() return I.ESP.healthCustomColor end,
        Callback=function(c) I.ESP.healthCustomColor = c end})
    reg(appSect, "ColorPicker", "esp.healthBarBgColor", {Text="hp bg color",
        GetInitialColor=function() return I.ESP.healthBarBgColor end,
        Callback=function(c) I.ESP.healthBarBgColor = c end})
    reg(appSect, "ColorPicker", "esp.healthTextColor", {Text="hp text color",
        GetInitialColor=function() return I.ESP.healthTextColor end,
        Callback=function(c) I.ESP.healthTextColor = c end})

     local chamsSect = visualsTab:CreateSection({
        Title = "- chams -", Position = UDim2.new(0,460,0,8),
        Size = UDim2.new(0,214,0,700),
    })
    reg(chamsSect, "Toggle", "chams.enabled", {Text="enable chams", Default=false,
        Callback=function(v)
            I.Chams.enabled = v
            if not v then
                if I.clearSelfChams then pcall(I.clearSelfChams) end
                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                    if I.clearLocalChams then pcall(I.clearLocalChams, p) end
                end
            end
        end})
    chamsSect:Divider()
    chamsSect:Label("- whitelist chams override -")
    reg(chamsSect, "Toggle", "chams.useWhitelistColor", {Text="enable override", Default=false,
        Callback=function(v) I.Chams.useWhitelistColor = v end})
    reg(chamsSect, "ColorPicker", "chams.whitelistColor", {Text="whitelist color",
        GetInitialColor=function() return I.Chams.whitelistColor end,
        Callback=function(c) I.Chams.whitelistColor = c end})
    reg(chamsSect, "Toggle", "chams.skipWhitelist", {Text="skip whitelist (no override)", Default=true,
        Callback=function(v) I.Chams.skipWhitelist = v end})
    chamsSect:Divider()
    reg(chamsSect, "Toggle", "chams.outlineEnabled", {Text="outline", Default=false,
        Callback=function(v) I.Chams.outlineEnabled = v end})
    reg(chamsSect, "Cycle", "chams.depthMode", {Prefix="mode: ",
        Values={"Both","Occluded","AlwaysOnTop"}, Index=1,
        Callback=function(v) I.Chams.depthMode = v end})
    reg(chamsSect, "Toggle", "chams.teamCheck", {Text="team check", Default=false,
        Callback=function(v) I.Chams.teamCheck = v end})
    chamsSect:Divider()
    reg(chamsSect, "Toggle", "chams.rainbow", {Text="rainbow fill", Default=false,
        Callback=function(v) I.Chams.rainbow = v end})
    reg(chamsSect, "Slider", "chams.rainbowSpeed", {Text="rainbow speed",
        Min=0.1, Max=5, Default=1,
        Callback=function(v) I.Chams.rainbowSpeed = v end})
    reg(chamsSect, "Slider", "chams.fillTransp", {Text="fill transparency",
        Min=0, Max=1, Default=0.5,
        Callback=function(v) I.Chams.fillTransp = v end})
    reg(chamsSect, "Slider", "chams.outlineTransp", {Text="outline transparency",
        Min=0, Max=1, Default=0,
        Callback=function(v) I.Chams.outlineTransp = v end})
    reg(chamsSect, "ColorPicker", "chams.fillColor", {Text="fill color",
        GetInitialColor=function() return I.Chams.fillColor end,
        Callback=function(c) I.Chams.fillColor = c end})
    reg(chamsSect, "ColorPicker", "chams.outlineColor", {Text="outline color",
        GetInitialColor=function() return I.Chams.outlineColor end,
        Callback=function(c) I.Chams.outlineColor = c end})
            chamsSect:Divider()
    chamsSect:Label("- optimization -", 18)
    reg(chamsSect, "Slider", "chams.maxDistance", {Text="max distance (0=inf)",
        Min=0, Max=5000, Default=1500,
        Callback=function(v) I.Chams.maxDistance = math.floor(v) end})

    local hmSect = visualsTab:CreateSection({
        Title = "- hitmarker -", Position = UDim2.new(0,460,0,716),
        Size = UDim2.new(0,214,0,700),
    })
    reg(hmSect, "Toggle", "hitmarker.enabled", {Text="enable hitmarker", Default=false,
        Callback=function(v) I.Hitmarker.enabled = v end})
    reg(hmSect, "Cycle", "hitmarker.mode", {Prefix="mode: ",
        Values={"Cross","Number","Both","Dot","Square","Diamond","Circle","Star","Chevron"},
        Index=1, Callback=function(v) I.Hitmarker.mode = v end})
    reg(hmSect, "Toggle", "hitmarker.killEnabled", {Text="kill marker", Default=true,
        Callback=function(v) I.Hitmarker.killEnabled = v end})
    reg(hmSect, "Toggle", "hitmarker.headshotEnabled", {Text="headshot marker", Default=true,
        Callback=function(v) I.Hitmarker.headshotEnabled = v end})
    reg(hmSect, "Slider", "hitmarker.crossSize", {Text="cross size",
        Min=2, Max=60, Default=8,
        Callback=function(v) I.Hitmarker.crossSize = v end})
    reg(hmSect, "Slider", "hitmarker.crossThickness", {Text="cross thickness",
        Min=1, Max=10, Default=2,
        Callback=function(v) I.Hitmarker.crossThickness = v end})
    reg(hmSect, "Slider", "hitmarker.crossDuration", {Text="cross duration",
        Min=0.05, Max=3, Default=0.35,
        Callback=function(v) I.Hitmarker.crossDuration = v end})
    reg(hmSect, "Slider", "hitmarker.numberSize", {Text="number size",
        Min=8, Max=60, Default=22,
        Callback=function(v) I.Hitmarker.numberSize = v end})
    reg(hmSect, "Slider", "hitmarker.numberDuration", {Text="number duration",
        Min=0.2, Max=5, Default=0.8,
        Callback=function(v) I.Hitmarker.numberDuration = v end})
    reg(hmSect, "Slider", "hitmarker.crossTransp", {Text="cross transparency",
        Min=0, Max=1, Default=0,
        Callback=function(v) I.Hitmarker.crossTransp = v end})
    reg(hmSect, "Toggle", "hitmarker.crossOutline", {Text="cross outline", Default=true,
        Callback=function(v) I.Hitmarker.crossOutline = v end})
    reg(hmSect, "ColorPicker", "hitmarker.crossColor", {Text="cross color",
        GetInitialColor=function() return I.Hitmarker.crossColor end,
        Callback=function(c) I.Hitmarker.crossColor = c end})
    reg(hmSect, "ColorPicker", "hitmarker.killColor", {Text="kill color",
        GetInitialColor=function() return I.Hitmarker.killColor end,
        Callback=function(c) I.Hitmarker.killColor = c end})
    reg(hmSect, "ColorPicker", "hitmarker.headshotColor", {Text="headshot color",
        GetInitialColor=function() return I.Hitmarker.headshotColor end,
        Callback=function(c) I.Hitmarker.headshotColor = c end})
    reg(hmSect, "ColorPicker", "hitmarker.numberColor", {Text="number color",
        GetInitialColor=function() return I.Hitmarker.numberColor end,
        Callback=function(c) I.Hitmarker.numberColor = c end})
    reg(hmSect, "Slider", "hitmarker.numberRiseSpeed", {Text="number rise speed",
        Min=0, Max=300, Default=80,
        Callback=function(v) I.Hitmarker.numberRiseSpeed = v end})

    local shaderSect = visualsTab:CreateSection({
        Title = "- shading -", Position = UDim2.new(0,686,0,8),
        Size = UDim2.new(0,214,0,110),
    })
    shaderSect:Label("open full shader list:")
    shaderSect:Button({Text="select shading ^", Callback=function()
        local PW, PH = 340, 520
        local popup, gui = makePopupFrame("shader_popup", "- select shading -", PW, PH)
        local scroll = create("ScrollingFrame", {
            Name="list", BackgroundTransparency=1,
            Size=UDim2.new(1,-24,1,-40), Position=UDim2.new(0,12,0,32),
            BorderSizePixel=0, ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, popup)
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.Parent = scroll

        local presets = {"Cinematic","Dark Night","Soft","Horror","Night Mode",
            "Kelvin's preset","Sunset","Frost","Vaporwave","Noir","Kawaii","Toxic"}
        for i, name in ipairs(presets) do
            local btn = create("TextButton", {
                Name="p_"..i, AutoButtonColor=false,
                Text=name, TextSize=14, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, BackgroundColor3=PALETTE.Element,
                Size=UDim2.new(1, 0, 0, 32), LayoutOrder=i,
            }, scroll)
            corner(btn, 7); addGlass(btn, 0.4, PALETTE.ElementGlass)
            btn.MouseEnter:Connect(function()
                tween(btn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.3})
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
            end)
        btn.MouseButton1Click:Connect(function()
                pcall(I.applyShaderPreset, name)
                -- sync sliders with new World values
                local function sync(path, val)
                    local c = _G.PRIMO_INTERNAL and _G.PRIMO_INTERNAL.CONTROLS and _G.PRIMO_INTERNAL.CONTROLS[path]
                    if c and c.Set then pcall(function() c:Set(val, true) end) end
                end
                local W = I.World
                sync("world.clockTime", W.clockTime)
                sync("world.brightness", W.brightness)
                sync("world.exposure", W.exposure)
                sync("world.globalShadows", W.globalShadows)
                sync("world.atmoEnabled", W.atmoEnabled)
                sync("world.atmoDensity", W.atmoDensity)
                sync("world.atmoHaze", W.atmoHaze)
                sync("world.atmoGlare", W.atmoGlare)
                sync("world.atmoOffset", W.atmoOffset)
                sync("world.fogEnabled", W.fogEnabled)
                sync("world.fogStart", W.fogStart)
                sync("world.fogEnd", W.fogEnd)
                sync("world.bloomEnabled", W.bloomEnabled)
                sync("world.bloomIntensity", W.bloomIntensity)
                sync("world.bloomSize", W.bloomSize)
                sync("world.ccEnabled", W.ccEnabled)
                sync("world.ccBrightness", W.ccBrightness)
                sync("world.ccContrast", W.ccContrast)
                sync("world.ccSaturation", W.ccSaturation)
                sync("world.blurEnabled", W.blurEnabled)
                sync("world.blurSize", W.blurSize)
                sync("world.sunRaysEnabled", W.sunRaysEnabled)
                sync("world.sunRaysIntensity", W.sunRaysIntensity)
                sync("world.ambient", W.ambient)
                sync("world.outdoorAmbient", W.outdoorAmbient)
                sync("world.atmoColor", W.atmoColor)
                sync("world.atmoDecay", W.atmoDecay)
                sync("world.fogColor", W.fogColor)
                sync("world.ccTintColor", W.ccTintColor)
                popup.Visible = false
            end)
        end
        local closeBtn = create("TextButton", {
            Name="close", AutoButtonColor=false, Text="x",
            TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, Size=UDim2.new(0,26,0,22),
            Position=UDim2.new(1,-32,0,4),
        }, popup)
        corner(closeBtn, 5)
        closeBtn.MouseButton1Click:Connect(function() popup.Visible = false end)
        popup.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
        popup.Visible = true
        popup.BackgroundTransparency = 0
    end})

    local selfChamsSect = visualsTab:CreateSection({
        Title = "- self chams -", Position = UDim2.new(0,460,0,1424),
        Size = UDim2.new(0,214,0,520),
    })
    reg(selfChamsSect, "Toggle", "selfChams.enabled", {Text="enable self chams", Default=false,
        Callback=function(v)
            I.SelfChams.enabled = v
            if not v and I.clearSelfChams then pcall(I.clearSelfChams) end
        end})
    reg(selfChamsSect, "Toggle", "selfChams.outlineEnabled", {Text="outline", Default=false,
        Callback=function(v) I.SelfChams.outlineEnabled = v end})
    reg(selfChamsSect, "Cycle", "selfChams.depthMode", {Prefix="mode: ",
        Values={"Both","Occluded","AlwaysOnTop"}, Index=1,
        Callback=function(v) I.SelfChams.depthMode = v end})
    selfChamsSect:Divider()
    reg(selfChamsSect, "Toggle", "selfChams.rainbow", {Text="rainbow fill", Default=false,
        Callback=function(v) I.SelfChams.rainbow = v end})
    reg(selfChamsSect, "Slider", "selfChams.rainbowSpeed", {Text="rainbow speed",
        Min=0.1, Max=5, Default=1,
        Callback=function(v) I.SelfChams.rainbowSpeed = v end})
    reg(selfChamsSect, "Slider", "selfChams.fillTransp", {Text="fill transparency",
        Min=0, Max=1, Default=0.5,
        Callback=function(v) I.SelfChams.fillTransp = v end})
    reg(selfChamsSect, "Slider", "selfChams.outlineTransp", {Text="outline transparency",
        Min=0, Max=1, Default=0,
        Callback=function(v) I.SelfChams.outlineTransp = v end})
    reg(selfChamsSect, "ColorPicker", "selfChams.fillColor", {Text="fill color",
        GetInitialColor=function() return I.SelfChams.fillColor end,
        Callback=function(c) I.SelfChams.fillColor = c end})
    reg(selfChamsSect, "ColorPicker", "selfChams.outlineColor", {Text="outline color",
        GetInitialColor=function() return I.SelfChams.outlineColor end,
        Callback=function(c) I.SelfChams.outlineColor = c end})

    local worldSect = visualsTab:CreateSection({
        Title = "- world -", Position = UDim2.new(0,686,0,126),
        Size = UDim2.new(0,214,0,640),
    })
    reg(worldSect, "Toggle", "world.fullbright", {Text="fullbright", Default=false,
        Callback=function(v) I.World.fullbright = v; I.reapplyAllWorld() end})
    worldSect:Label("time presets:")
    local clockSlider
    local function setClock(v)
        I.World.clockTime = v
        if clockSlider then clockSlider:Set(v, true) end
        I.reapplyAllWorld()
    end
    worldSect:Button({Text="dawn (6:00)", Callback=function() setClock(6) end})
    worldSect:Button({Text="noon (12:00)", Callback=function() setClock(12) end})
    worldSect:Button({Text="sunset (18:00)", Callback=function() setClock(18) end})
    worldSect:Button({Text="night (0:00)", Callback=function() setClock(0) end})
    clockSlider = reg(worldSect, "Slider", "world.clockTime", {Text="clock time", Min=0, Max=24, Default=I.World.clockTime,
        Callback=function(v) I.World.clockTime=v; I.reapplyAllWorld() end})
    reg(worldSect, "Slider", "world.brightness", {Text="brightness", Min=0, Max=5, Default=I.World.brightness,
        Callback=function(v) I.World.brightness=v; I.reapplyAllWorld() end})
    reg(worldSect, "Slider", "world.exposure", {Text="exposure", Min=-3, Max=3, Default=I.World.exposure,
        Callback=function(v) I.World.exposure=v; I.reapplyAllWorld() end})
    reg(worldSect, "Toggle", "world.globalShadows", {Text="global shadows", Default=I.World.globalShadows,
        Callback=function(v) I.World.globalShadows=v; I.reapplyAllWorld() end})
    reg(worldSect, "ColorPicker", "world.ambient", {Text="ambient",
        GetInitialColor=function() return I.World.ambient end,
        Callback=function(c) I.World.ambient=c; I.reapplyAllWorld() end})
    reg(worldSect, "ColorPicker", "world.outdoorAmbient", {Text="outdoor ambient",
        GetInitialColor=function() return I.World.outdoorAmbient end,
        Callback=function(c) I.World.outdoorAmbient=c; I.reapplyAllWorld() end})

    local atmoSect = visualsTab:CreateSection({
        Title = "- atmosphere & sky -", Position = UDim2.new(0,912,0,8),
        Size = UDim2.new(0,214,0,900),
    })
    reg(atmoSect, "Toggle", "world.atmoEnabled", {Text="custom atmosphere", Default=false,
        Callback=function(v) I.World.atmoEnabled=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.atmoDensity", {Text="density", Min=0, Max=1, Default=I.World.atmoDensity,
        Callback=function(v) I.World.atmoDensity=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.atmoHaze", {Text="haze", Min=0, Max=10, Default=I.World.atmoHaze,
        Callback=function(v) I.World.atmoHaze=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.atmoGlare", {Text="glare", Min=0, Max=10, Default=I.World.atmoGlare,
        Callback=function(v) I.World.atmoGlare=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.atmoOffset", {Text="offset", Min=-1, Max=1, Default=I.World.atmoOffset,
        Callback=function(v) I.World.atmoOffset=v; I.reapplyAllWorld() end})
    reg(atmoSect, "ColorPicker", "world.atmoColor", {Text="atmo color",
        GetInitialColor=function() return I.World.atmoColor end,
        Callback=function(c) I.World.atmoColor=c; I.reapplyAllWorld() end})
    reg(atmoSect, "ColorPicker", "world.atmoDecay", {Text="atmo decay color",
        GetInitialColor=function() return I.World.atmoDecay end,
        Callback=function(c) I.World.atmoDecay=c; I.reapplyAllWorld() end})
    atmoSect:Label("- sky override -")
    reg(atmoSect, "Toggle", "world.skyOverride", {Text="sky override", Default=false,
        Callback=function(v) I.World.skyOverride=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.skyStarCount", {Text="star count", Min=0, Max=10000, Default=I.World.skyStarCount,
        Callback=function(v) I.World.skyStarCount=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.skySunSize", {Text="sun size", Min=0, Max=60, Default=I.World.skySunSize,
        Callback=function(v) I.World.skySunSize=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.skyMoonSize", {Text="moon size", Min=0, Max=60, Default=I.World.skyMoonSize,
        Callback=function(v) I.World.skyMoonSize=v; I.reapplyAllWorld() end})
    reg(atmoSect, "Toggle", "world.skyCelestial", {Text="celestial bodies", Default=I.World.skyCelestial,
        Callback=function(v) I.World.skyCelestial=v; I.reapplyAllWorld() end})
    atmoSect:Divider()
    atmoSect:Label("- sky color override -")
    reg(atmoSect, "Toggle", "world.skyColorEnabled", {
        Text="enable sky color", Default=I.World.skyColorEnabled,
        Callback=function(v) I.World.skyColorEnabled=v; I.reapplyAllWorld() end})
    reg(atmoSect, "ColorPicker", "world.skyColor", {Text="sky color",
        GetInitialColor=function() return I.World.skyColor end,
        Callback=function(c) I.World.skyColor=c; I.reapplyAllWorld() end})
    reg(atmoSect, "Slider", "world.skyColorDensity", {
        Text="sky color density", Min=0.1, Max=1,
        Default=I.World.skyColorDensity,
        Callback=function(v) I.World.skyColorDensity=v; I.reapplyAllWorld() end})
    atmoSect:Label("density 0 = sky only, 1 = thick haze", 18)

    local fogSect = visualsTab:CreateSection({
        Title = "- fog -", Position = UDim2.new(0,912,0,916),
        Size = UDim2.new(0,214,0,380),
    })
    reg(fogSect, "Toggle", "world.fogEnabled", {Text="custom fog", Default=false,
        Callback=function(v) I.World.fogEnabled=v; I.reapplyAllWorld() end})
    reg(fogSect, "ColorPicker", "world.fogColor", {Text="fog color",
        GetInitialColor=function() return I.World.fogColor end,
        Callback=function(c) I.World.fogColor=c; I.reapplyAllWorld() end})
    reg(fogSect, "Slider", "world.fogStart", {Text="fog start", Min=0, Max=1000, Default=I.World.fogStart,
        Callback=function(v) I.World.fogStart=v; I.reapplyAllWorld() end})
    reg(fogSect, "Slider", "world.fogEnd", {Text="fog end", Min=10, Max=10000, Default=I.World.fogEnd,
        Callback=function(v) I.World.fogEnd=v; I.reapplyAllWorld() end})
    fogSect:Divider()
    fogSect:Label("hint: with atmosphere ON, fog", 18)
    fogSect:Label("automatically tints to fog color.", 18)
    fogSect:Label("turn atmosphere OFF for pure fog.", 18)

    local postSect = visualsTab:CreateSection({
        Title = "- post-processing -", Position = UDim2.new(0,1138,0,8),
        Size = UDim2.new(0,214,0,900),
    })
    reg(postSect, "Toggle", "world.sunRaysEnabled", {Text="sun rays", Default=false,
        Callback=function(v) I.World.sunRaysEnabled=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.sunRaysIntensity", {Text="intensity", Min=0, Max=1, Default=I.World.sunRaysIntensity,
        Callback=function(v) I.World.sunRaysIntensity=v; I.reapplyAllWorld() end})
    reg(postSect, "Toggle", "world.bloomEnabled", {Text="bloom", Default=false,
        Callback=function(v) I.World.bloomEnabled=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.bloomIntensity", {Text="bloom intensity", Min=0, Max=5, Default=I.World.bloomIntensity,
        Callback=function(v) I.World.bloomIntensity=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.bloomSize", {Text="bloom size", Min=0, Max=56, Default=I.World.bloomSize,
        Callback=function(v) I.World.bloomSize=v; I.reapplyAllWorld() end})
    reg(postSect, "Toggle", "world.ccEnabled", {Text="color correction", Default=false,
        Callback=function(v) I.World.ccEnabled=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.ccBrightness", {Text="brightness", Min=-1, Max=1, Default=I.World.ccBrightness,
        Callback=function(v) I.World.ccBrightness=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.ccContrast", {Text="contrast", Min=-1, Max=1, Default=I.World.ccContrast,
        Callback=function(v) I.World.ccContrast=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.ccSaturation", {Text="saturation", Min=-1, Max=1, Default=I.World.ccSaturation,
        Callback=function(v) I.World.ccSaturation=v; I.reapplyAllWorld() end})
    reg(postSect, "ColorPicker", "world.ccTintColor", {Text="tint color",
        GetInitialColor=function() return I.World.ccTintColor end,
        Callback=function(c) I.World.ccTintColor=c; I.reapplyAllWorld() end})
    reg(postSect, "Toggle", "world.blurEnabled", {Text="blur", Default=false,
        Callback=function(v) I.World.blurEnabled=v; I.reapplyAllWorld() end})
    reg(postSect, "Slider", "world.blurSize", {Text="blur size", Min=0, Max=56, Default=I.World.blurSize,
        Callback=function(v) I.World.blurSize=v; I.reapplyAllWorld() end})
    reg(postSect, "Toggle", "world.dofEnabled", {Text="depth of field", Default=false,
        Callback=function(v) I.World.dofEnabled=v; I.reapplyAllWorld() end})
        
end

--===============================================================
-- AIMBOT TAB
--===============================================================
do
    local aimTab = Window:CreateTab({Name="aimbot", Horizontal=true, CanvasWidth=1430})
    local mainSect = aimTab:CreateSection({Title="- main -",
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,214,0,1260)})
    reg(mainSect, "Toggle", "aimbot.enabled", {Text="enable aimbot", Default=false,
        Callback=function(v)
            I.Aimbot.enabled = v
            if not v then I.setAimbotToggle(false) end
        end})
    reg(mainSect, "BindInput", "aimbot.key", {Text="aim key", Default=I.Aimbot.key,
        Callback=function(bind)
            if bind then I.Aimbot.key = bind end
            I.setAimbotToggle(false)
            I.syncKeybind("aimbot", bind, function() end)
        end})
    reg(mainSect, "Toggle", "aimbot.toggleMode", {Text="toggle mode", Default=false,
        Callback=function(v)
            I.Aimbot.toggleMode = v
            if not v then
                I.setAimbotToggle(false)
                if I.Aimbot then I.Aimbot._toggle = false end
            end
        end})
    reg(mainSect, "Cycle", "aimbot.method", {Prefix="method: ",
        Values={"Camera","CameraSnap","Position"}, Index=1,
        Callback=function(v) I.Aimbot.method = v end})
    local R15_PARTS = {"Head","UpperTorso","LowerTorso","HumanoidRootPart",
        "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
        "LeftHand","RightHand","LeftUpperLeg","RightUpperLeg",
        "LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
    reg(mainSect, "MultiSelect", "aimbot.targetParts", {
        Text="target parts", PopupTitle="- select target parts -",
        Values=R15_PARTS, Default={"Head"},
        Callback=function(list)
            I.Aimbot.targetParts = {}
            for _, n in ipairs(list) do I.Aimbot.targetParts[n] = true end
        end})
    reg(mainSect, "Toggle", "aimbot.teamCheck", {Text="team check", Default=false,
        Callback=function(v) I.Aimbot.teamCheck = v end})
    reg(mainSect, "Toggle", "aimbot.skipFriends", {Text="skip whitelist (friends)", Default=true,
        Callback=function(v) I.Aimbot.skipFriends = v end})
    reg(mainSect, "Toggle", "aimbot.aliveCheck", {Text="alive check", Default=true,
        Callback=function(v) I.Aimbot.aliveCheck = v end})
    reg(mainSect, "Toggle", "aimbot.wallCheck", {Text="wall check", Default=false,
        Callback=function(v) I.Aimbot.wallCheck = v end})
    reg(mainSect, "Toggle", "aimbot.forcefieldCheck", {Text="forcefield check", Default=true,
        Callback=function(v) I.Aimbot.forcefieldCheck = v end})
    reg(mainSect, "Toggle", "aimbot.targetPlayers", {Text="target players", Default=true,
        Callback=function(v) I.Aimbot.targetPlayers = v end})
    reg(mainSect, "Toggle", "aimbot.targetNPCs", {Text="target npcs", Default=false,
        Callback=function(v) I.Aimbot.targetNPCs = v end})
    reg(mainSect, "Cycle", "aimbot.priority", {Prefix="priority: ",
        Values={"Closest","ScreenCenter","LowestHealth","HighestHealth"}, Index=1,
        Callback=function(v) I.Aimbot.priority = v end})
    reg(mainSect, "Slider", "aimbot.fov", {Text="fov radius (px)",
        Min=10, Max=800, Default=150,
        Callback=function(v) I.Aimbot.fov = v end})
    reg(mainSect, "Slider", "aimbot.maxDist", {Text="max distance",
        Min=10, Max=2000, Default=700,
        Callback=function(v) I.Aimbot.maxDist = v end})
    reg(mainSect, "Slider", "aimbot.smoothness", {Text="smoothness",
        Min=0.01, Max=1, Default=0.45,
        Callback=function(v) I.Aimbot.smoothness = v end})
    reg(mainSect, "Slider", "aimbot.sensitivity", {Text="sensitivity",
        Min=0.1, Max=5, Default=1.2,
        Callback=function(v) I.Aimbot.sensitivity = v end})
    reg(mainSect, "Slider", "aimbot.stickiness", {Text="stickiness",
        Min=0, Max=2, Default=0.5,
        Callback=function(v) I.Aimbot.stickiness = v end})
    reg(mainSect, "Toggle", "aimbot.blatant", {Text="blatant mode", Default=false,
        Callback=function(v) I.Aimbot.blatant = v end})
    reg(mainSect, "Slider", "aimbot.hitChance", {Text="hit chance %",
        Min=0, Max=100, Default=100,
        Callback=function(v) I.Aimbot.hitChance = v end})
    mainSect:Divider()
    mainSect:Label("- autostop -")
    reg(mainSect, "Toggle", "autostop.enabled", {Text="enable autostop", Default=false,
        Callback=function(v)
            I.Autostop.enabled = v
            if not v and I.Autostop._active then
                local char = game:GetService("Players").LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if I.Autostop._savedWS then hum.WalkSpeed = I.Autostop._savedWS end
                    if I.Autostop._savedJP then hum.JumpPower = I.Autostop._savedJP end
                end
                I.Autostop._active = false
                I.Autostop._savedWS = nil
                I.Autostop._savedJP = nil
                I.Autostop._releaseAt = nil
            end
        end})
    reg(mainSect, "Toggle", "autostop.stopMove", {Text="stop movement", Default=true,
        Callback=function(v) I.Autostop.stopMove = v end})
    reg(mainSect, "Toggle", "autostop.stopJump", {Text="stop jump", Default=false,
        Callback=function(v) I.Autostop.stopJump = v end})
    reg(mainSect, "Toggle", "autostop.onlyWhenLocked", {Text="only when locked", Default=true,
        Callback=function(v) I.Autostop.onlyWhenLocked = v end})
    reg(mainSect, "Slider", "autostop.releaseDelay", {Text="release delay (s)",
        Min=0, Max=0.5, Default=0.05,
        Callback=function(v) I.Autostop.releaseDelay = v end})
    mainSect:Button({Text="add target to whitelist", Callback=function()
        if targetESPHolder and targetESPHolder.GetTarget then
            local t = targetESPHolder:GetTarget()
            if t then I.addWhitelist(t.Name) end
        end
    end})

    local predSect = aimTab:CreateSection({Title="- prediction -",
        Position=UDim2.new(0,234,0,8), Size=UDim2.new(0,214,0,1680)})
    reg(predSect, "Slider", "aimbot.prediction", {Text="prediction %",
        Min=0, Max=100, Default=0,
        Callback=function(v) I.Aimbot.prediction = v end})
    reg(predSect, "Slider", "aimbot.projSpeed", {Text="projectile speed",
        Min=10, Max=1000, Default=100,
        Callback=function(v) I.Aimbot.projSpeed = v end})
    reg(predSect, "Slider", "aimbot.projGravity", {Text="projectile gravity",
        Min=0, Max=200, Default=0,
        Callback=function(v) I.Aimbot.projGravity = v end})
    predSect:Label("- fov visual -")
    reg(predSect, "Toggle", "aimbot.showFOV", {Text="show fov circle", Default=false,
        Callback=function(v) I.Aimbot.showFOV = v end})
    reg(predSect, "ColorPicker", "aimbot.fovColor", {Text="fov color",
        GetInitialColor=function() return I.Aimbot.fovColor end,
        Callback=function(c) I.Aimbot.fovColor = c end})
    reg(predSect, "ColorPicker", "aimbot.fovLockedColor", {Text="fov locked color",
        GetInitialColor=function() return I.Aimbot.fovLockedColor end,
        Callback=function(c) I.Aimbot.fovLockedColor = c end})

    -- ── AUTOSHOOT ──
    predSect:Divider()
    predSect:Label("- autoshoot -", 18)
    predSect:Label("fires without moving camera", 16)

    reg(predSect, "Toggle", "autoshoot.enabled", {
        Text="enable autoshoot", Default=false,
        Callback=function(v)
            I.__PRIMO_AUTOSHOOT.enabled = v
            if not v then I.__PRIMO_AUTOSHOOT._toggle = false end
        end})
    reg(predSect, "BindInput", "autoshoot.key", {
        Text="fire key (leave unbound)", Default=I.__PRIMO_AUTOSHOOT.key,
        Callback=function(bind)
            if bind then I.__PRIMO_AUTOSHOOT.key = bind end
            I.syncKeybind("autoshoot", bind, function() end)
        end})
    predSect:Label("leave key unbound to fire always", 16)
    reg(predSect, "Slider", "autoshoot.delay", {
        Text="delay (s)", Min=0.01, Max=0.5, Default=0.08,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.delay = v end})
    reg(predSect, "Slider", "autoshoot.range", {
        Text="range (studs)", Min=50, Max=2000, Default=500,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.range = v end})
    reg(predSect, "Toggle", "autoshoot.wallCheck", {
        Text="wall check", Default=true,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.wallCheck = v end})
    reg(predSect, "Toggle", "autoshoot.teamCheck", {
        Text="team check", Default=false,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.teamCheck = v end})
    reg(predSect, "Toggle", "autoshoot.skipFriends", {
        Text="skip whitelist", Default=true,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.skipFriends = v end})
    reg(predSect, "Toggle", "autoshoot.forcefieldCheck", {
        Text="forcefield check", Default=true,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.forcefieldCheck = v end})
    reg(predSect, "Toggle", "autoshoot.onlyADS", {
        Text="only ADS", Default=false,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.onlyADS = v end})
    reg(predSect, "Toggle", "autoshoot.useScreenCheck", {
        Text="screen check (vs strict ray)", Default=true,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.useScreenCheck = v end})
    reg(predSect, "Slider", "autoshoot.crosshairRadius", {
        Text="crosshair radius (px)", Min=5, Max=200, Default=40,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.crosshairRadius = v end})
    reg(predSect, "Slider", "autoshoot.hitChance", {
        Text="hit chance %", Min=0, Max=100, Default=100,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.hitChance = v end})
    reg(predSect, "Toggle", "autoshoot.rapidFire", {
        Text="rapid fire", Default=false,
        Callback=function(v) I.__PRIMO_AUTOSHOOT.rapidFire = v end})
    reg(predSect, "NumberInput", "autoshoot.rapidFireMult", {
        Text="rapid mult", Default=2, Min=1, Max=20, Placeholder="2",
        Callback=function(v) I.__PRIMO_AUTOSHOOT.rapidFireMult = v end})
    reg(predSect, "Toggle", "aimbot.autoShootSettled", {Text="wait until on target", Default=true,
        Callback=function(v) I.Aimbot.autoShootSettled = v end})
    reg(predSect, "Slider", "aimbot.autoShootDelay", {Text="auto shoot delay",
        Min=0.01, Max=1, Default=0.1,
        Callback=function(v) I.Aimbot.autoShootDelay = v end})

    local trigSect = aimTab:CreateSection({Title="- triggerbot -",
        Position=UDim2.new(0,460,0,8), Size=UDim2.new(0,214,0,1180)})
    reg(trigSect, "Toggle", "aimbot.triggerBot", {Text="enable triggerbot", Default=false,
        Callback=function(v)
            I.Aimbot.triggerBot = v
            if not v then I.setTriggerToggle(false) end
        end})
    reg(trigSect, "BindInput", "aimbot.triggerKey", {Text="trigger key",
        Default=I.Aimbot.triggerKey,
        Callback=function(bind)
            if bind then I.Aimbot.triggerKey = bind end
            I.setTriggerToggle(false)
            I.syncKeybind("triggerbot", bind, function() end)
        end})
    reg(trigSect, "Slider", "aimbot.triggerDelay", {Text="delay (s)",
        Min=0.01, Max=1, Default=0.05,
        Callback=function(v) I.Aimbot.triggerDelay = v end})
    reg(trigSect, "Slider", "aimbot.triggerRange", {Text="range (studs)",
        Min=10, Max=500, Default=100,
        Callback=function(v) I.Aimbot.triggerRange = v end})
    reg(trigSect, "Slider", "aimbot.triggerRadius", {Text="radius (px)",
        Min=1, Max=50, Default=8,
        Callback=function(v) I.Aimbot.triggerRadius = v end})
    trigSect:Divider()
    trigSect:Label("- trigger filters -")
    reg(trigSect, "Toggle", "aimbot.triggerWallCheck", {Text="wall check", Default=false,
        Callback=function(v) I.Aimbot.triggerWallCheck = v end})
    reg(trigSect, "Toggle", "aimbot.triggerOnlySettled", {Text="only when settled", Default=true,
        Callback=function(v) I.Aimbot.triggerOnlySettled = v end})
    reg(trigSect, "Toggle", "aimbot.triggerNoShake", {Text="no camera shake", Default=true,
        Callback=function(v) I.Aimbot.triggerNoShake = v end})
    reg(trigSect, "Toggle", "aimbot.triggerMultipoint", {Text="multipoint", Default=true,
        Callback=function(v) I.Aimbot.triggerMultipoint = v end})
    reg(trigSect, "Toggle", "aimbot.triggerNPCs", {Text="target NPCs", Default=false,
        Callback=function(v) I.Aimbot.triggerNPCs = v end})


    -- ─── SILENT AIM ───
    local saSect = aimTab:CreateSection({Title="- silent aim -",
        Position=UDim2.new(0,686,0,8), Size=UDim2.new(0,240,0,900)})
    saSect:Label("shoots without moving camera:", 18)

    reg(saSect, "Toggle", "silent.enabled", {Text="enable silent aim", Default=false,
        Callback=function(v)
            local SA = I.SilentAim
            SA.enabled = v
            if v then
                if not SA._hookInstalled then
                    local ok, err = I.silentAimInstallHook()
                    if not ok then
                        saSect:Label("hook failed: "..tostring(err), 18)
                        pcall(function() Library:NotifyError("silent aim", tostring(err)) end)
                    else
                        pcall(function() Library:NotifySuccess("silent aim", "hook installed") end)
                    end
                end
            else
                I.silentAimUninstallHook()
            end
        end})
    reg(saSect, "BindInput", "silent.key", {
        Text="silent fire key", Default=I.SilentAim.key,
        Callback=function(bind)
            if bind then I.SilentAim.key = bind end
            I.syncKeybind("silentaim", bind, function() end)
        end})
    reg(saSect, "Toggle", "silent.toggleMode", {Text="toggle mode", Default=false,
        Callback=function(v) I.SilentAim.toggleMode = v end})
    reg(saSect, "Slider", "silent.fov", {Text="silent fov (px)",
        Min=20, Max=1200, Default=200,
        Callback=function(v) I.SilentAim.fov = v end})
    reg(saSect, "Slider", "silent.maxDist", {Text="silent max dist",
        Min=50, Max=3000, Default=700,
        Callback=function(v) I.SilentAim.maxDist = v end})
    reg(saSect, "Slider", "silent.hitChance", {Text="hit chance %",
        Min=0, Max=100, Default=100,
        Callback=function(v) I.SilentAim.hitChance = v end})
    reg(saSect, "Toggle", "silent.wallCheck", {Text="wall check", Default=false,
        Callback=function(v) I.SilentAim.wallCheck = v end})
    reg(saSect, "Toggle", "silent.teamCheck", {Text="team check", Default=false,
        Callback=function(v) I.SilentAim.teamCheck = v end})
    reg(saSect, "Toggle", "silent.skipFriends", {Text="skip whitelist", Default=true,
        Callback=function(v) I.SilentAim.skipFriends = v end})
    reg(saSect, "Toggle", "silent.resolverOn", {Text="use resolver", Default=true,
        Callback=function(v) I.SilentAim.resolverOn = v end})
    reg(saSect, "Slider", "silent.projSpeed", {Text="proj speed",
        Min=10, Max=1000, Default=150,
        Callback=function(v) I.SilentAim.projSpeed = v end})
    reg(saSect, "Slider", "silent.projGravity", {Text="proj gravity",
        Min=0, Max=200, Default=0,
        Callback=function(v) I.SilentAim.projGravity = v end})
    saSect:Label("note: requires getrawmetatable (syn/krnl/etc)", 16)
    saSect:Button({Text="test hook status", Callback=function()
        local SA = I.SilentAim
        local txt = SA._hookInstalled and "installed" or ("not installed: "..tostring(SA._lastHookErr))
        pcall(function() Library:Notify("silent aim", txt) end)
    end})

    -- ─── FOV SWITCHER ───
    local swSect = aimTab:CreateSection({Title="- fov switcher -",
        Position=UDim2.new(0,934,0,8), Size=UDim2.new(0,240,0,420)})
    swSect:Label("auto-switch between targets", 18)
    reg(swSect, "Toggle", "aimbot.switchOnLeave", {
        Text="switch on fov leave", Default=false,
        Callback=function(v) I.Aimbot.switchOnLeave = v end})
    reg(swSect, "Slider", "aimbot.switchDelay", {
        Text="hold-off delay (s)", Min=0, Max=1.5, Default=0.35,
        Callback=function(v) I.Aimbot.switchDelay = v end})
    reg(swSect, "NumberInput", "aimbot.switchMaxTargets", {
        Text="max targets", Default=2, Min=1, Max=10, Placeholder="2",
        Callback=function(v) I.Aimbot.switchMaxTargets = v end})
    swSect:Label("prefers last target until it", 16)
    swSect:Label("leaves the fov entirely.", 16)

    -- ─── BODYPART LOCKS ───
    local blSect = aimTab:CreateSection({Title="- bodypart locks -",
        Position=UDim2.new(0,934,0,436), Size=UDim2.new(0,240,0,560)})
    blSect:Label("hold bind → force aim that part", 18)
    reg(blSect, "BindInput", "aimbot.bindHead", {
        Text="lock head", Default=I.Aimbot.bindHead,
        Callback=function(bind)
            I.Aimbot.bindHead = bind
            I.syncKeybind("lock head", bind, function() end)
        end})
    reg(blSect, "BindInput", "aimbot.bindTorso", {
        Text="lock torso", Default=I.Aimbot.bindTorso,
        Callback=function(bind)
            I.Aimbot.bindTorso = bind
            I.syncKeybind("lock torso", bind, function() end)
        end})
    reg(blSect, "BindInput", "aimbot.bindHRP", {
        Text="lock hrp", Default=I.Aimbot.bindHRP,
        Callback=function(bind)
            I.Aimbot.bindHRP = bind
            I.syncKeybind("lock hrp", bind, function() end)
        end})
    reg(blSect, "BindInput", "aimbot.bindClosest", {
        Text="lock closest", Default=I.Aimbot.bindClosest,
        Callback=function(bind)
            I.Aimbot.bindClosest = bind
            I.syncKeybind("lock closest", bind, function() end)
        end})
    blSect:Divider()
    blSect:Label("priority (top = higher):", 18)
    blSect:Label("bindHead > bindTorso >", 16)
    blSect:Label("bindHRP > bindClosest", 16)

    -- ─── CURVE ───
    local cuSect = aimTab:CreateSection({Title="- smooth curve -",
        Position=UDim2.new(0,1182,0,8), Size=UDim2.new(0,240,0,500)})
    cuSect:Label("shape of aim assist:", 18)
    reg(cuSect, "Cycle", "aimbot.smoothCurve", {
        Prefix="curve: ",
        Values={"linear","ease-in","ease-out","ease-in-out","bezier"},
        Index=3,
        Callback=function(v) I.Aimbot.smoothCurve = v end})
    cuSect:Label("bezier control points:", 18)
    reg(cuSect, "Slider", "aimbot.bezierP1x", {
        Text="P1.x", Min=0, Max=1, Default=0.25,
        Callback=function(v) I.Aimbot.bezierP1[1] = v end})
    reg(cuSect, "Slider", "aimbot.bezierP1y", {
        Text="P1.y", Min=0, Max=1, Default=0.10,
        Callback=function(v) I.Aimbot.bezierP1[2] = v end})
    reg(cuSect, "Slider", "aimbot.bezierP2x", {
        Text="P2.x", Min=0, Max=1, Default=0.25,
        Callback=function(v) I.Aimbot.bezierP2[1] = v end})
    reg(cuSect, "Slider", "aimbot.bezierP2y", {
        Text="P2.y", Min=0, Max=1, Default=1.00,
        Callback=function(v) I.Aimbot.bezierP2[2] = v end})
    cuSect:Label("ease-out ~ snappy start", 16)
    cuSect:Label("ease-in  ~ slow start", 16)
    cuSect:Label("bezier   ~ custom curve", 16)

    -- ─── RESOLVER ───
    local rsSect = aimTab:CreateSection({Title="- resolver -",
        Position=UDim2.new(0,1182,0,516), Size=UDim2.new(0,240,0,300)})
    rsSect:Label("iterative projectile prediction", 16)
    rsSect:Label("prediction/proj sliders — в «prediction» секции", 16)
    reg(rsSect, "Slider", "aimbot.gravityCorrection", {
        Text="gravity correction %", Min=0, Max=100, Default=0,
        Callback=function(v) I.Aimbot.gravityCorrection = v end})
end

--===============================================================
-- MISC TAB
--===============================================================
do
    local miscTab = Window:CreateTab({
        Name = "misc", Horizontal = true, CanvasWidth = 1320,
    })
    local miscMainSect = miscTab:CreateSection({Title="- main -",
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,250,0,900)})
    -- ── fly (выше noclip) ──
    reg(miscMainSect, "ToggleBindRow", "misc.fly", {
        Text="fly", Default=false, DefaultBind=I.Misc.flyKey,
        Callback=function(v)
            if v then
                I.startFly()
                I.installLoopSpeedHook()
            else
                I.stopFly()
            end
        end,
        BindCallback=function(bind)
            I.Misc.flyKey = bind
            I.syncKeybind("fly", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                if I.Misc.flyEnabled then
                    I.stopFly()
                else
                    I.startFly()
                end
            end)
        end})
    reg(miscMainSect, "Slider", "misc.flySpeed", {
        Text="fly speed", Min=10, Max=400, Default=I.Misc.flySpeed,
        Callback=function(v) I.Misc.flySpeed = v end})

    reg(miscMainSect, "ToggleBindRow", "misc.noclip", {
        Text="noclip", Default=false, DefaultBind=I.Misc.noclipKey,
        Callback=function(v)
            I.Misc.noclipEnabled = v
            I.applyNoclip(v)
        end,
        BindCallback=function(bind)
            I.Misc.noclipKey = bind
            I.syncKeybind("noclip", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                I.Misc.noclipEnabled = not I.Misc.noclipEnabled
                I.applyNoclip(I.Misc.noclipEnabled)
            end)
        end})
    reg(miscMainSect, "Toggle", "misc.hideNametags", {Text="hide nametags", Default=false,
        Callback=function(v)
            I.Misc.hideNametags = v
            I.applyNametagsHide()
        end})
    reg(miscMainSect, "ToggleBindRow", "misc.loopSpeed", {
        Text="override speed", Default=false, DefaultBind=I.Misc.loopSpeedKey,
        Callback=function(v)
            if v then
                I.Misc.loopSpeedEnabled = true
                I.applyLoopSpeed()
                I.installLoopSpeedHook()
            else
                I.disableLoopSpeed()
            end
        end,
        BindCallback=function(bind)
            I.Misc.loopSpeedKey = bind
            I.syncKeybind("loopspeed", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                if I.Misc.loopSpeedEnabled then
                    I.disableLoopSpeed()
                else
                    I.Misc.loopSpeedEnabled = true
                    I.applyLoopSpeed()
                    I.installLoopSpeedHook()
                end
            end)
        end})
    reg(miscMainSect, "NumberInput", "misc.loopSpeedValue", {
        Text="speed value", Default=I.Misc.loopSpeedValue,
        Placeholder="16", Min=1, Max=1000,
        Callback=function(v)
            I.Misc.loopSpeedValue = v
            if I.Misc.loopSpeedEnabled then I.applyLoopSpeed() end
        end})
    -- ── override jumppower (под speed) ──
    reg(miscMainSect, "ToggleBindRow", "misc.loopJumpPower", {
        Text="override jumppower", Default=false, DefaultBind=I.Misc.loopJumpPowerKey,
        Callback=function(v)
            if v then
                I.Misc.loopJumpPowerEnabled = true
                I.applyLoopJumpPower()
            else
                I.disableLoopJumpPower()
            end
        end,
        BindCallback=function(bind)
            I.Misc.loopJumpPowerKey = bind
            I.syncKeybind("jumppower", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                if I.Misc.loopJumpPowerEnabled then
                    I.disableLoopJumpPower()
                else
                    I.Misc.loopJumpPowerEnabled = true
                    I.applyLoopJumpPower()
                end
            end)
        end})
    reg(miscMainSect, "NumberInput", "misc.loopJumpPowerValue", {
        Text="jumppower value", Default=I.Misc.loopJumpPowerValue,
        Placeholder="50", Min=1, Max=1000,
        Callback=function(v)
            I.Misc.loopJumpPowerValue = v
            if I.Misc.loopJumpPowerEnabled then I.applyLoopJumpPower() end
        end})
    reg(miscMainSect, "ToggleBindRow", "misc.spin", {
        Text="spin", Default=false, DefaultBind=I.Misc.spinKey,
        Callback=function(v) I.Misc.spinEnabled = v end,
        BindCallback=function(bind)
            I.Misc.spinKey = bind
            I.syncKeybind("spin", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                I.Misc.spinEnabled = not I.Misc.spinEnabled
            end)
        end})
    reg(miscMainSect, "NumberInput", "misc.spinValue", {
        Text="spin (deg/s)", Default=I.Misc.spinValue, Placeholder="360",
        Min=0, Max=1440,
        Callback=function(v) I.Misc.spinValue = v end})
    reg(miscMainSect, "ConfirmButton", "misc.lowPerf", {
        Text="low performance mode",
        Warning="it may lower ur fps (?)",
        Callback=function()
            if I.PERF_STATE.active then I.exitLowPerf()
            else I.enterLowPerf() end
        end})

    local bypassSect = miscTab:CreateSection({Title="- bypass -",
        Position=UDim2.new(0,268,0,8), Size=UDim2.new(0,240,0,560)})
    reg(bypassSect, "ToggleBindRow", "bypasses.forceReset", {
        Text="force reset", Default=false, DefaultBind=nil,
        Callback=function(v) I.Bypasses.forceResetEnabled = v end,
        BindCallback=function(bind)
            I.Bypasses.forceResetKey = bind
            I.syncKeybind("force reset", bind, function()
                -- не срабатываем, если пользователь сейчас слушает бинд
                if _G.__PRIMO_BIND_LISTENING then return end
                I.forceReset()
            end)
        end})

    -- Force Reset NOW button - explicitly uses accent color for text
    do
        local b = bypassSect:Button({Text="force reset now",
            Callback=function() I.forceReset() end})
        if b and b.Instance then
            local btn = b.Instance
            local function applyAccent()
                local hovered = btn:GetAttribute("hovered")
                if hovered then
                    tween(btn, { TextColor3 = Library.Settings.AccentColor })
                else
                    tween(btn, { TextColor3 = Library.Settings.AccentColor:Lerp(Color3.new(1,1,1), 0.15) })
                end
            end
            btn.MouseEnter:Connect(applyAccent)
            btn.MouseLeave:Connect(applyAccent)
            registerAccent(applyAccent)
            applyAccent()
        end
    end
    bypassSect:Label("— hitbox expander —")
    reg(bypassSect, "Toggle", "bypasses.hitboxEnabled", {
        Text="hitbox expander", Default=false,
        Callback=function(v)
            I.Bypasses.hitboxEnabled = v
            if not v then
                I.resetAllHitboxes()
            else
                task.spawn(function()
                    I.applyHitboxAll()
                    task.wait(0.5)
                    I.applyHitboxAll()
                end)
            end
        end})
    bypassSect:Button({Text="refresh hitboxes now", Callback=function()
        if I.Bypasses.hitboxEnabled then
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                if p ~= game:GetService("Players").LocalPlayer
                   and p.Character and p.Character.Parent then
                    pcall(I.applyHitbox, p)
                end
            end
        end
    end})
    reg(bypassSect, "Toggle", "bypasses.skipFriends", {
        Text="no hitbox on friends", Default=true,
        Callback=function(v)
            I.Bypasses.skipFriends = v
            if I.Bypasses.hitboxEnabled then I.applyHitboxAll() end
        end})
    reg(bypassSect, "NumberInput", "bypasses.hitboxSize", {
        Text="hitbox size", Default=I.Bypasses.hitboxSize, Placeholder="20",
        Min=1, Max=100,
        Callback=function(v)
            I.Bypasses.hitboxSize = v
            if I.Bypasses.hitboxEnabled then I.applyHitboxAll() end
        end})
    reg(bypassSect, "Slider", "bypasses.hitboxTransparency", {
        Text="hitbox transparency", Min=0, Max=1, Default=I.Bypasses.hitboxTransparency,
        Callback=function(v)
            I.Bypasses.hitboxTransparency = v
            if I.Bypasses.hitboxEnabled then I.applyHitboxAll() end
        end})
    bypassSect:Label("0 = visible, 1 = invisible", 18)
    reg(bypassSect, "ColorPicker", "bypasses.hitboxColor", {
        Text="hitbox color",
        GetInitialColor=function() return I.Bypasses.hitboxColor end,
        Callback=function(c)
            I.Bypasses.hitboxColor = c
            if I.Bypasses.hitboxEnabled then I.applyHitboxAll() end
        end})
    reg(bypassSect, "Toggle", "bypasses.hitboxApplyToHead", {
        Text="apply to head", Default=I.Bypasses.hitboxApplyToHead,
        Callback=function(v)
            I.Bypasses.hitboxApplyToHead = v
            if I.Bypasses.hitboxEnabled then
                I.resetAllHitboxes()
                task.wait(0.05)
                I.applyHitboxAll()
            end
        end})
    reg(bypassSect, "Toggle", "bypasses.hitboxCanCollide", {
        Text="can collide", Default=I.Bypasses.hitboxCanCollide,
        Callback=function(v)
            I.Bypasses.hitboxCanCollide = v
            if I.Bypasses.hitboxEnabled then I.applyHitboxAll() end
        end})

    local sndSect = miscTab:CreateSection({Title="- sounds -",
        Position=UDim2.new(0,520,0,8), Size=UDim2.new(0,260,0,560)})
    reg(sndSect, "Toggle", "hitsound.enabled", {Text="enable hitsound", Default=false,
        Callback=function(v) I.Hitsound.enabled = v; if v then I.createSndPool() end end})
            reg(sndSect, "Cycle", "hitsound.mode", {
        Prefix="hitsound mode: ",
        Values={"single","every"},
        Index=1,
        Callback=function(v) I.Hitsound.mode = v end})
    reg(sndSect, "Cycle", "hitsound.preset", {Prefix="hitsound preset: ",
        Values={"None","COD Hitmarker","Gamesense Bell","NeverLose Bell","MLG","TF2 Hitsound",
            "Mellstroy KpAcHbIu","Mellstroy Bites","Mellstroy Privet Artur",
            "Meow 1","Meow 2","Meow 3",
            "nya","nya 2","nya 3",
            "CashCashCash","Undertale Hit",
            "osu hitsound","pizza tower","tf2 bubble","quake shit","fatality",
            "minecraft xp","primordial","csgo headshot","lbp",
            "Custom"},
        Index=2, Callback=function(v) I.Hitsound.preset = v; I.createSndPool() end})
    reg(sndSect, "TextBox", "hitsound.customId", {Placeholder="custom hitsound id", Text="",
        Callback=function(t)
            I.Hitsound.customId = t or ""
            if I.Hitsound.preset == "Custom" then I.createSndPool() end
        end})
    reg(sndSect, "Slider", "hitsound.volume", {Text="hitsound volume",
        Min=0, Max=3, Default=1,
        Callback=function(v)
            I.Hitsound.volume = v
            for _, s in ipairs(I.Hitsound.pool) do pcall(function() s.Volume = v end) end
        end})
    sndSect:Button({Text="test hitsound x5", Callback=function()
        I.createSndPool()
        for i=1, 5 do task.delay(i*0.15, I.playHit) end
    end})
    reg(sndSect, "Toggle", "killsound.enabled", {Text="enable kill sound", Default=false,
        Callback=function(v) I.KillSound.enabled = v; if v then I.createKillPool() end end})
    reg(sndSect, "Cycle", "killsound.preset", {Prefix="kill preset: ",
        Values={"None","COD Hitmarker","Gamesense Bell","NeverLose Bell","MLG","TF2 Hitsound",
            "Mellstroy KpAcHbIu","Mellstroy Bites","Mellstroy Privet Artur",
            "Meow 1","Meow 2","Meow 3",
            "nya","nya 2","nya 3",
            "CashCashCash","Undertale Hit",
            "osu hitsound","pizza tower","tf2 bubble","quake shit","fatality",
            "minecraft xp","primordial","csgo headshot","lbp",
            "Custom"},
        Index=3, Callback=function(v) I.KillSound.preset = v; I.createKillPool() end})
    reg(sndSect, "TextBox", "killsound.customId", {Placeholder="custom kill id", Text="",
        Callback=function(t)
            I.KillSound.customId = t or ""
            if I.KillSound.preset == "Custom" then I.createKillPool() end
        end})
    reg(sndSect, "Slider", "killsound.volume", {Text="kill volume",
        Min=0, Max=3, Default=1,
        Callback=function(v)
            I.KillSound.volume = v
            for _, s in ipairs(I.KillSound.pool) do pcall(function() s.Volume = v end) end
        end})

    -- ── sound browser ──
    local function testPreset(id, vol)
        if not id then return end
        local s = Instance.new("Sound")
        s.SoundId = id; s.Volume = vol or 1; s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(3, function() pcall(function() s:Destroy() end) end)
    end

    local function openSoundBrowser(mode)
        -- mode = "hit" or "kill"
        local PW, PH = 480, 620
        local popup, gui = makePopupFrame("sound_browser_"..mode,
            mode == "hit" and "- hitsounds -" or "- killsounds -", PW, PH)
        local scroll = create("ScrollingFrame", {
            Name="list", BackgroundTransparency=1,
            Size=UDim2.new(1,-24,1,-40), Position=UDim2.new(0,12,0,32),
            BorderSizePixel=0, ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            ScrollingDirection=Enum.ScrollingDirection.Y,
        }, popup)
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 4)
        lay.Parent = scroll

        local names = {}
        for k in pairs(PRESETS) do
            if k ~= "None" then names[#names+1] = k end
        end
        table.sort(names)

        local idx = 0
        for _, name in ipairs(names) do
            idx = idx + 1
            local row = create("Frame", {Name="s_"..idx,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,28), LayoutOrder=idx}, scroll)
            corner(row, 6)
            local sel = create("TextButton", {Name="sel", AutoButtonColor=false,
                Text=name, TextSize=13, TextColor3=PALETTE.Text,
                FontFace=FONT_REGULAR, BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-44,1,0), Position=UDim2.new(0,8,0,0)}, row)
            sel.MouseEnter:Connect(function()
                tween(sel, {TextColor3=Library.Settings.AccentColor})
            end)
            sel.MouseLeave:Connect(function()
                tween(sel, {TextColor3=PALETTE.Text})
            end)
            sel.MouseButton1Click:Connect(function()
                if mode == "hit" then
                    I.Hitsound.preset = name
                    local c = _G.__PRIMO_CONTROLS["hitsound.preset"]
                    if c and c.Set then pcall(function() c:Set(name, true) end) end
                    I.createSndPool()
                else
                    I.KillSound.preset = name
                    local c = _G.__PRIMO_CONTROLS["killsound.preset"]
                    if c and c.Set then pcall(function() c:Set(name, true) end) end
                    I.createKillPool()
                end
                popup.Visible = false
            end)

            local testBtn = create("TextButton", {Name="test", AutoButtonColor=false,
                Text="▶", TextSize=12, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(0,32,1,-6), Position=UDim2.new(1,-38,0,3)}, row)
            corner(testBtn, 5)
            testBtn.MouseEnter:Connect(function()
                tween(testBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.1})
            end)
            testBtn.MouseLeave:Connect(function()
                tween(testBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.3})
            end)
            testBtn.MouseButton1Click:Connect(function()
                local vol = (mode == "hit") and I.Hitsound.volume or I.KillSound.volume
                testPreset(PRESETS[name], vol)
            end)
        end
        popup.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
        popup.Visible = true
        popup.BackgroundTransparency = 0
    end

    sndSect:Button({Text="open hitsounds list", Callback=function()
        openSoundBrowser("hit")
    end})
    sndSect:Button({Text="open killsounds list", Callback=function()
        openSoundBrowser("kill")
    end})

    -- ── aura (orbit) ──
local auraSect = miscTab:CreateSection({Title="- aura -",
        Position=UDim2.new(0,792,0,8), Size=UDim2.new(0,240,0,640)})
    reg(auraSect, "ToggleBindRow", "aura.enabled", {
        Text="enable aura", Default=false, DefaultBind=I.Aura.key,
        Callback=function(v)
            if v then I.startAura() else I.stopAura() end
        end,
        BindCallback=function(bind)
            I.Aura.key = bind
            I.syncKeybind("aura", bind, function()
                if _G.__PRIMO_BIND_LISTENING then return end
                if I.Aura.enabled then I.stopAura() else I.startAura() end
            end)
        end})
    auraSect:Label("setts:", 16)
    reg(auraSect, "Slider", "aura.radius", {Text="radius (studs)", Min=2, Max=30, Default=I.Aura.radius,
        Callback=function(v) I.Aura.radius = v end})
    reg(auraSect, "Slider", "aura.speed", {Text="speed (deg/s)", Min=30, Max=1080, Default=I.Aura.speed,
        Callback=function(v) I.Aura.speed = v end})
    reg(auraSect, "Slider", "aura.height", {Text="height (studs)", Min=-2, Max=8, Default=I.Aura.height,
        Callback=function(v) I.Aura.height = v end})
    reg(auraSect, "Slider", "aura.smoothSwitch", {Text="target switch delay (s)",
        Min=0, Max=1, Default=I.Aura.smoothSwitch,
        Callback=function(v) I.Aura.smoothSwitch = v end})
    reg(auraSect, "Toggle", "aura.physicsMode", {Text="physics mode (no gravity)",
        Default=I.Aura.physicsMode,
        Callback=function(v) I.Aura.physicsMode = v end})
    reg(auraSect, "Toggle", "aura.onlyWhenAlive", {Text="only when target alive",
        Default=I.Aura.onlyWhenAlive,
        Callback=function(v) I.Aura.onlyWhenAlive = v end})
    reg(auraSect, "Toggle", "aura.visualizer", {Text="visualizer",
        Default=I.Aura.visualizer,
        Callback=function(v) I.Aura.visualizer = v end})
    reg(auraSect, "ColorPicker", "aura.visualColor", {Text="visual color",
        GetInitialColor=function() return I.Aura.visualColor end,
        Callback=function(c) I.Aura.visualColor = c end})
    reg(auraSect, "Toggle", "aura.autoTarget", {Text="auto nearest target", Default=I.Aura.autoTarget,
        Callback=function(v) I.Aura.autoTarget = v end})
    reg(auraSect, "Toggle", "aura.teamCheck", {Text="team check", Default=I.Aura.teamCheck,
        Callback=function(v) I.Aura.teamCheck = v end})
    reg(auraSect, "Toggle", "aura.skipFriends", {Text="skip whitelist", Default=I.Aura.skipFriends,
        Callback=function(v) I.Aura.skipFriends = v end})
    auraSect:Button({Text="set current aim target", Callback=function()
        if _G.__LAST_TARGET_PLAYER then I.Aura.target = _G.__LAST_TARGET_PLAYER end
        I.Aura.autoTarget = false
        local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["aura.autoTarget"]
        if c and c.Set then pcall(function() c:Set(false, true) end) end
    end})
    auraSect:Button({Text="clear target", Callback=function()
        I.Aura.target = nil
    end})

     -- ════════════ TELEPORT / SPECTATE (styled) ════════════
    do
        local TP = {
            active=false, spectateActive=false, toastGui=nil,
            spawnMode = "behind",
        }

        local PlayersSvc = game:GetService("Players")
        local LP = PlayersSvc.LocalPlayer

        -- ⬇️ forward declares — чтобы openCountdownDialog видел их ниже
        local doTeleport
        local openSelectPosPopup

        local SPAWN_MODES = {
            { name="from behind", key="behind" },
            { name="in front",    key="front"  },
            { name="on top",      key="top"    },
            { name="above",       key="above"  },
            { name="below",       key="below"  },
            { name="left side",   key="left"   },
            { name="right side",  key="right"  },
            { name="at position", key="on"     },
        }
        local SPAWN_MODE_NAMES = {}
        for _, m in ipairs(SPAWN_MODES) do table.insert(SPAWN_MODE_NAMES, m.name) end

        local function getSpawnOffset(tHRP)
            local mode = TP.spawnMode
            local look  = tHRP.CFrame.LookVector
            local right = tHRP.CFrame.RightVector
            local up    = Vector3.new(0, 1, 0)
            if mode == "behind" then return -look * 4 + up * 2 end
            if mode == "front"  then return  look * 4 + up * 2 end
            if mode == "top"    then return up * 5 end
            if mode == "above"  then return up * 8 end
            if mode == "below"  then return up * 0.5 end
            if mode == "left"   then return -right * 4 + up * 2 end
            if mode == "right"  then return  right * 4 + up * 2 end
            return up * 2
        end

        -- ─── STYLED toast ───
        local function ensureToastGui()
            if TP.toastGui and TP.toastGui.Parent then return TP.toastGui end
            local pg = LP:FindFirstChild("PlayerGui"); if not pg then return nil end
            TP.toastGui = Instance.new("ScreenGui")
            TP.toastGui.Name = "primo_tp_toast"
            TP.toastGui.ResetOnSpawn = false
            TP.toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            TP.toastGui.IgnoreGuiInset = true
            TP.toastGui.DisplayOrder = 960
            TP.toastGui.Parent = pg
            return TP.toastGui
        end

        local function hideToast()
            if TP.toastGui then
                local t = TP.toastGui:FindFirstChild("toastFrame")
                if t then t:Destroy() end
            end
        end

        local function showToast(text, showCancel, onCancel)
            local gui = ensureToastGui(); if not gui then return end
            hideToast()

            local holder = create("Frame", {
                Name="toastFrame",
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0.5,0,0.8,0),
                Size=UDim2.new(0,460,0,60),
                BackgroundColor3=PALETTE.Panel,
                BackgroundTransparency=0,
                BorderSizePixel=0, Active=true,
            }, gui)
            corner(holder, 10); addGlass(holder, 0.15, PALETTE.PanelGlass)

            local stroke = Instance.new("UIStroke")
            stroke.Color = Library.Settings.AccentColor
            stroke.Thickness = 1.5; stroke.Transparency = 0.35
            stroke.Parent = holder
            registerAccent(function() tween(stroke, {Color=Library.Settings.AccentColor}) end)

            local bar = create("Frame", {Name="bar",
                BackgroundColor3=Library.Settings.AccentColor,
                BackgroundTransparency=0.25,
                Size=UDim2.new(0,3,1,-16),
                Position=UDim2.new(0,0,0,8)}, holder)
            corner(bar, 2)
            registerAccent(function() tween(bar, {BackgroundColor3=Library.Settings.AccentColor}) end)

            local lbl = create("TextLabel", {
                BackgroundTransparency=1, Text=text,
                TextSize=15, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextYAlignment=Enum.TextYAlignment.Center,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1, showCancel and -120 or -28, 1, 0),
                Position=UDim2.new(0,18,0,0),
            }, holder)

            if showCancel then
                local cancelBtn = create("TextButton", {
                    AutoButtonColor=false, Text="cancel", TextSize=13,
                    FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                    BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.25,
                    Size=UDim2.new(0,84,1,-18),
                    Position=UDim2.new(1,-92,0,9),
                }, holder)
                corner(cancelBtn, 7); addGlass(cancelBtn, 0.35, PALETTE.ElementGlass)
                cancelBtn.MouseEnter:Connect(function()
                    tween(cancelBtn,{BackgroundTransparency=0.1,TextColor3=Color3.new(1,1,1)})
                end)
                cancelBtn.MouseLeave:Connect(function()
                    tween(cancelBtn,{BackgroundTransparency=0.25,TextColor3=PALETTE.Text})
                end)
                cancelBtn.MouseButton1Click:Connect(function()
                    holder:Destroy(); if onCancel then pcall(onCancel) end
                end)
            end

            local dragging, dragStart, startPos
            local dragConns = {}
            table.insert(dragConns, holder.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then
                    dragging=true; dragStart=input.Position; startPos=holder.Position
                end
            end))
            table.insert(dragConns, UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType==Enum.UserInputType.MouseMovement
                   or input.UserInputType==Enum.UserInputType.Touch then
                    local d=input.Position-dragStart
                    holder.Position=UDim2.new(
                        startPos.X.Scale,startPos.X.Offset+d.X,
                        startPos.Y.Scale,startPos.Y.Offset+d.Y)
                end
            end))
            table.insert(dragConns, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
            end))
            holder.Destroying:Connect(function()
                for _,c in ipairs(dragConns) do pcall(function() c:Disconnect() end) end
            end)

            holder.BackgroundTransparency=1; stroke.Transparency=1
            bar.BackgroundTransparency=1; lbl.TextTransparency=1
            task.spawn(function()
                local info=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
                TweenService:Create(holder,info,{BackgroundTransparency=0}):Play()
                TweenService:Create(stroke,info,{Transparency=0.35}):Play()
                TweenService:Create(bar,info,{BackgroundTransparency=0.25}):Play()
                TweenService:Create(lbl,info,{TextTransparency=0}):Play()
            end)
        end

        -- ─── STYLED player picker ───
        local function openPlayerPicker(title, onPick)
            local pg = LP:FindFirstChild("PlayerGui")
            local popups = pg and pg:FindFirstChild("primo_popups")
            if not popups then return end
            local old = popups:FindFirstChild("primo_picker")
            if old then old:Destroy() end

            local PW, PH = 380, 500
            local popup = create("Frame", {
                Name="primo_picker", BackgroundColor3=PALETTE.Panel,
                Size=UDim2.new(0,PW,0,PH),
                Position=UDim2.new(0.5,-PW/2,0.5,-PH/2),
            }, popups)
            corner(popup, 10); addGlass(popup, 0.15, PALETTE.PanelGlass)

            local stroke = Instance.new("UIStroke")
            stroke.Color=Library.Settings.AccentColor
            stroke.Thickness=1.5; stroke.Transparency=0.4
            stroke.Parent=popup
            registerAccent(function() tween(stroke,{Color=Library.Settings.AccentColor}) end)

            local accentBar = create("Frame", {Name="accentBar",
                BackgroundColor3=Library.Settings.AccentColor,
                BackgroundTransparency=0.25,
                Size=UDim2.new(0,3,1,-16), Position=UDim2.new(0,0,0,8)}, popup)
            corner(accentBar, 2)
            registerAccent(function() tween(accentBar,{BackgroundColor3=Library.Settings.AccentColor}) end)

            local titleBar = create("Frame", {Name="titlebar", BackgroundTransparency=1,
                Active=true, Size=UDim2.new(1,0,0,28)}, popup)
            local titleLbl = create("TextLabel", {
                BackgroundTransparency=1, Text=title,
                TextSize=13, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,25,0,0),
            }, titleBar)
            local hg = Instance.new("UIGradient")
            hg.Color = resolveSeq(Library.Settings.AccentColor, PALETTE.Text)
            hg.Parent = titleLbl
            local phase=0
            local gradConn = RunService.Heartbeat:Connect(function(dt)
                if not titleLbl.Parent then return end
                phase=(phase+dt*0.15)%1
                hg.Offset=Vector2.new(math.sin(phase*math.pi*2)*0.5,0)
            end)
            popup.Destroying:Connect(function() pcall(function() gradConn:Disconnect() end) end)
            registerAccent(function() hg.Color = resolveSeq(Library.Settings.AccentColor,PALETTE.Text) end)

            local closeBtn = create("TextButton", {
                AutoButtonColor=false, Text="×", TextSize=18, FontFace=FONT_BOLD,
                TextColor3=PALETTE.TextDim, BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.4,
                Size=UDim2.new(0,22,0,20), Position=UDim2.new(1,-26,0,4),
            }, popup)
            corner(closeBtn, 5)
            closeBtn.MouseEnter:Connect(function()
                tween(closeBtn,{TextColor3=PALETTE.Warn,BackgroundTransparency=0.15}) end)
            closeBtn.MouseLeave:Connect(function()
                tween(closeBtn,{TextColor3=PALETTE.TextDim,BackgroundTransparency=0.4}) end)
            closeBtn.MouseButton1Click:Connect(function() popup:Destroy() end)

            create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
                BackgroundTransparency=0.8,
                Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0,28)}, popup)

            local drag, ds, sp
            titleBar.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then
                    drag=true; ds=input.Position; sp=popup.Position
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if not drag then return end
                if input.UserInputType==Enum.UserInputType.MouseMovement
                   or input.UserInputType==Enum.UserInputType.Touch then
                    local d=input.Position-ds
                    popup.Position=UDim2.new(
                        sp.X.Scale,sp.X.Offset+d.X,
                        sp.Y.Scale,sp.Y.Offset+d.Y)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then drag=false end
            end)

            local scroll = create("ScrollingFrame", {
                Name="list",
                BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.4,
                Size=UDim2.new(1,-24,1,-110),
                Position=UDim2.new(0,12,0,36),
                BorderSizePixel=0, ScrollBarThickness=4,
                ScrollBarImageColor3=Library.Settings.AccentColor,
                ScrollBarImageTransparency=0.4,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            }, popup)
            corner(scroll, 8)
            registerAccent(function()
                tween(scroll,{ScrollBarImageColor3=Library.Settings.AccentColor}) end)
            local lay = Instance.new("UIListLayout")
            lay.SortOrder=Enum.SortOrder.LayoutOrder
            lay.Padding=UDim.new(0,4); lay.Parent=scroll
            local spad = Instance.new("UIPadding")
            spad.PaddingTop=UDim.new(0,6); spad.PaddingBottom=UDim.new(0,6)
            spad.PaddingLeft=UDim.new(0,6); spad.PaddingRight=UDim.new(0,6)
            spad.Parent=scroll

            local selected, rows, order = nil, {}, 0
            for _, p in ipairs(PlayersSvc:GetPlayers()) do
                if p ~= LP then
                    order = order + 1
                    local row = create("TextButton", {
                        Name="p_"..order, AutoButtonColor=false, Text="",
                        BackgroundColor3=PALETTE.ElementHi,
                        BackgroundTransparency=0.35,
                        Size=UDim2.new(1,0,0,32), LayoutOrder=order,
                    }, scroll)
                    corner(row, 6)
                    create("TextLabel", {
                        Name="lbl", BackgroundTransparency=1,
                        Text=p.DisplayName.."  (@"..p.Name..")",
                        TextSize=12, FontFace=FONT_REGULAR, TextColor3=PALETTE.Text,
                        TextXAlignment=Enum.TextXAlignment.Left,
                        TextTruncate=Enum.TextTruncate.AtEnd,
                        Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,10,0,0),
                    }, row)
                    row.MouseEnter:Connect(function()
                        if selected ~= p then tween(row,{BackgroundTransparency=0.15}) end
                    end)
                    row.MouseLeave:Connect(function()
                        if selected ~= p then tween(row,{BackgroundTransparency=0.35}) end
                    end)
                    row.MouseButton1Click:Connect(function()
                        selected = p
                        for pr, rr in pairs(rows) do
                            local l = rr.row:FindFirstChild("lbl")
                            if pr == p then
                                tween(rr.row,{BackgroundTransparency=0.08})
                                if l then tween(l,{TextColor3=Library.Settings.AccentColor}) end
                            else
                                tween(rr.row,{BackgroundTransparency=0.35})
                                if l then tween(l,{TextColor3=PALETTE.Text}) end
                            end
                        end
                    end)
                    rows[p] = {row=row}
                end
            end
            if order == 0 then
                create("TextLabel", {Name="empty", BackgroundTransparency=1,
                    Text="no other players", TextSize=12, TextColor3=PALETTE.TextDim,
                    FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(1,0,0,40), LayoutOrder=1}, scroll)
            end

            local applyBtn = create("TextButton", {
                AutoButtonColor=false, Text="apply", TextSize=14, FontFace=FONT_BOLD,
                TextColor3=PALETTE.Text, BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.3,
                Size=UDim2.new(1,-24,0,30), Position=UDim2.new(0,12,1,-40),
            }, popup)
            corner(applyBtn, 7); addGlass(applyBtn, 0.4, PALETTE.ElementGlass)
            applyBtn.MouseEnter:Connect(function()
                tween(applyBtn,{TextColor3=Library.Settings.AccentColor,BackgroundTransparency=0.15}) end)
            applyBtn.MouseLeave:Connect(function()
                tween(applyBtn,{TextColor3=PALETTE.Text,BackgroundTransparency=0.3}) end)
            applyBtn.MouseButton1Click:Connect(function()
                if not selected then return end
                local s = selected; popup:Destroy()
                if onPick then task.spawn(function() onPick(s) end) end
            end)

            local escConn
            escConn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode==Enum.KeyCode.Escape then
                    if popup and popup.Parent then popup:Destroy() end
                    if escConn then escConn:Disconnect() end
                end
            end)
            popup.Destroying:Connect(function()
                if escConn then pcall(function() escConn:Disconnect() end) end
            end)
        end

        -- ─── countdown + spawn-where dialog (styled) ───
        local function openCountdownDialog(target, spawnModeKey)
            local pg = LP:FindFirstChild("PlayerGui")
            local popups = pg and pg:FindFirstChild("primo_popups")
            if not popups then return end
            local old = popups:FindFirstChild("primo_tp_countdown")
            if old then old:Destroy() end

            local PW, PH = 320, 220
            local dlg = create("Frame", {
                Name="primo_tp_countdown",
                BackgroundColor3=PALETTE.Panel,
                Size=UDim2.new(0,PW,0,PH),
                Position=UDim2.new(0.5,-PW/2,0.5,-PH/2),
            }, popups)
            corner(dlg, 10); addGlass(dlg, 0.15, PALETTE.PanelGlass)

            local stroke = Instance.new("UIStroke")
            stroke.Color=Library.Settings.AccentColor
            stroke.Thickness=1.5; stroke.Transparency=0.4
            stroke.Parent=dlg
            registerAccent(function() tween(stroke,{Color=Library.Settings.AccentColor}) end)

            local accentBar = create("Frame", {Name="accentBar",
                BackgroundColor3=Library.Settings.AccentColor,
                BackgroundTransparency=0.25,
                Size=UDim2.new(0,3,1,-16), Position=UDim2.new(0,0,0,8)}, dlg)
            corner(accentBar, 2)
            registerAccent(function() tween(accentBar,{BackgroundColor3=Library.Settings.AccentColor}) end)

            local titleLbl = create("TextLabel", {
                BackgroundTransparency=1, Text="- teleport -",
                TextSize=13, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,28),
            }, dlg)
            local hg = Instance.new("UIGradient")
            hg.Color = resolveSeq(Library.Settings.AccentColor, PALETTE.Text)
            hg.Parent = titleLbl
            local phase=0
            local gradConn = RunService.Heartbeat:Connect(function(dt)
                if not titleLbl.Parent then return end
                phase=(phase+dt*0.15)%1
                hg.Offset=Vector2.new(math.sin(phase*math.pi*2)*0.5,0)
            end)
            dlg.Destroying:Connect(function() pcall(function() gradConn:Disconnect() end) end)
            registerAccent(function() hg.Color = resolveSeq(Library.Settings.AccentColor,PALETTE.Text) end)

            create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
                BackgroundTransparency=0.8,
                Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0,28)}, dlg)

            create("TextLabel", {Name="prompt", BackgroundTransparency=1,
                Text="countdown (seconds):", TextSize=12, FontFace=FONT_REGULAR,
                TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-24,0,16), Position=UDim2.new(0,12,0,36)}, dlg)

            local box = create("TextBox", {Name="input", Text="3",
                TextSize=14, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,12,0,56)}, dlg)
            corner(box, 6); addGlass(box, 0.4, PALETTE.ElementGlass)
            box.Focused:Connect(function()
                tween(box,{BackgroundColor3=Library.Settings.AccentColor:Lerp(PALETTE.Element,0.8)})
            end)
            box.FocusLost:Connect(function() tween(box,{BackgroundColor3=PALETTE.Element}) end)

            create("TextLabel", {Name="spawnLbl", BackgroundTransparency=1,
                Text="spawn where:", TextSize=12, FontFace=FONT_REGULAR,
                TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-24,0,16), Position=UDim2.new(0,12,0,92)}, dlg)

            local currentIdx = 1
            for i, m in ipairs(SPAWN_MODES) do
                if m.key == spawnModeKey then currentIdx = i break end
            end
            local spawnBtn = create("TextButton", {
                Name="spawnBtn", AutoButtonColor=false,
                Text=SPAWN_MODES[currentIdx].name .. "  ▾",
                TextSize=13, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.25,
                Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,12,0,112),
            }, dlg)
            corner(spawnBtn, 6); addGlass(spawnBtn, 0.4, PALETTE.ElementGlass)
            spawnBtn.MouseEnter:Connect(function()
                tween(spawnBtn,{TextColor3=Library.Settings.AccentColor,BackgroundTransparency=0.1}) end)
            spawnBtn.MouseLeave:Connect(function()
                tween(spawnBtn,{TextColor3=PALETTE.Text,BackgroundTransparency=0.25}) end)
            spawnBtn.MouseButton1Click:Connect(function()
                -- запоминаем "на лету" выбор через глобальный select pos popup
                local prevSpawnMode = TP.spawnMode
                openSelectPosPopup()
                -- наблюдаем за сменой и обновляем лейбл диалога
                task.spawn(function()
                    while dlg and dlg.Parent do
                        if TP.spawnMode ~= prevSpawnMode then
                            for i, m in ipairs(SPAWN_MODES) do
                                if m.key == TP.spawnMode then currentIdx = i break end
                            end
                            if spawnBtn and spawnBtn.Parent then
                                spawnBtn.Text = SPAWN_MODES[currentIdx].name .. "  ▾"
                            end
                            break
                        end
                        task.wait(0.1)
                    end
                end)
            end)

            local cancelBtn = create("TextButton", {
                AutoButtonColor=false, Text="cancel", TextSize=13, FontFace=FONT_BOLD,
                TextColor3=PALETTE.Text, BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.4,
                Size=UDim2.new(0,100,0,28), Position=UDim2.new(0,12,1,-40),
            }, dlg)
            corner(cancelBtn, 6); addGlass(cancelBtn, 0.4, PALETTE.ElementGlass)
            cancelBtn.MouseEnter:Connect(function()
                tween(cancelBtn,{TextColor3=Library.Settings.AccentColor,BackgroundTransparency=0.15}) end)
            cancelBtn.MouseLeave:Connect(function()
                tween(cancelBtn,{TextColor3=PALETTE.Text,BackgroundTransparency=0.4}) end)
            cancelBtn.MouseButton1Click:Connect(function() dlg:Destroy() end)

            local applyBtn = create("TextButton", {
                AutoButtonColor=false, Text="apply", TextSize=13, FontFace=FONT_BOLD,
                TextColor3=PALETTE.Text, BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.3,
                Size=UDim2.new(0,100,0,28), Position=UDim2.new(1,-112,1,-40),
            }, dlg)
            corner(applyBtn, 6); addGlass(applyBtn, 0.4, PALETTE.ElementGlass)
            applyBtn.MouseEnter:Connect(function()
                tween(applyBtn,{TextColor3=Library.Settings.AccentColor,BackgroundTransparency=0.15}) end)
            applyBtn.MouseLeave:Connect(function()
                tween(applyBtn,{TextColor3=PALETTE.Text,BackgroundTransparency=0.3}) end)
            applyBtn.MouseButton1Click:Connect(function()
                local n = tonumber(box.Text) or 3
                n = math.clamp(math.floor(n), 0, 60)
                local mode = SPAWN_MODES[currentIdx].key
                TP.spawnMode = mode
                -- sync главный Cycle-контрол в меню
                local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["teleport.spawnMode"]
                if cc and cc.Set then
                    pcall(function() cc:Set(SPAWN_MODES[currentIdx].name, true) end)
                end
                dlg:Destroy()
                if n == 0 then
                    task.spawn(function() _G.__PRIMO_HARD_TP(target) end)
                else
                    TP.active = true
                    doTeleport(target, n)
                end
            end)

            local escConn
            escConn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode==Enum.KeyCode.Escape then
                    if dlg and dlg.Parent then dlg:Destroy() end
                    if escConn then escConn:Disconnect() end
                end
            end)
            dlg.Destroying:Connect(function()
                if escConn then pcall(function() escConn:Disconnect() end) end
            end)
        end

        -- Форвард-объявление, чтобы callback'и ниже могли его вызвать
        _G.__PRIMO_HARD_TP = function(target)
            local myChar = LP.Character
            if not myChar then return false end
            local myHRP  = myChar:FindFirstChild("HumanoidRootPart")
            local myHum  = myChar:FindFirstChildOfClass("Humanoid")
            local tChar  = target and target.Character
            local tHRP   = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if not myHRP or not tHRP then return false end

            local targetCF
            if TP.spawnMode == "on" then
                targetCF = CFrame.lookAt(tHRP.Position,
                    tHRP.Position + tHRP.CFrame.LookVector)
            else
                local newPos = tHRP.Position + getSpawnOffset(tHRP)
                targetCF = CFrame.lookAt(newPos, tHRP.Position)
            end

            pcall(function() myHum:ChangeState(Enum.HumanoidStateType.Physics) end)
            pcall(function() myHRP.AssemblyLinearVelocity  = Vector3.zero end)
            pcall(function() myHRP.AssemblyAngularVelocity = Vector3.zero end)

            for i = 1, 5 do
                myHRP.CFrame = targetCF
                myHRP.AssemblyLinearVelocity  = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
                task.wait(0.03)
            end

            pcall(function() myHum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            return true
        end

        doTeleport = function(target, delaySeconds)
            local label = target.DisplayName.." (@"..target.Name..")"
            task.spawn(function()
                for i = delaySeconds, 1, -1 do
                    if not TP.active then hideToast(); return end
                    showToast("teleporting to "..label.." in "..i.."...", true, function()
                        TP.active=false; hideToast()
                    end)
                    task.wait(1)
                end
                if not TP.active then hideToast(); return end
                hideToast(); TP.active = false
                _G.__PRIMO_HARD_TP(target)
            end)
        end

        local function openTeleportPicker()
            openPlayerPicker("- teleport to -", function(target)
                openCountdownDialog(target, TP.spawnMode)
            end)
        end

        local function stopSpectate()
            TP.spectateActive = false
            hideToast()
            local cam = workspace.CurrentCamera
            if cam and LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then cam.CameraSubject = hum end
            end
        end

        local function startSpectate(target)
            TP.spectateActive = true
            local cam = workspace.CurrentCamera
            if not cam then return end
            task.spawn(function()
                while TP.spectateActive and target and target.Parent do
                    local tChar = target.Character
                    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                    if tHum and tHum.Health > 0 then cam.CameraSubject = tHum
                    else break end
                    task.wait(0.3)
                end
                if TP.spectateActive then stopSpectate() end
            end)
            showToast("spectating "..target.DisplayName.." (@"..target.Name..")", true, stopSpectate)
        end

        -- ── SELECT POS popup (все позиции в одном окне) ──
        openSelectPosPopup = function()
            local pg = LP:FindFirstChild("PlayerGui")
            local popups = pg and pg:FindFirstChild("primo_popups")
            if not popups then return end
            local old = popups:FindFirstChild("primo_selectpos")
            if old then old:Destroy() end

            local PW, PH = 360, 500
            local popup = create("Frame", {
                Name="primo_selectpos", BackgroundColor3=PALETTE.Panel,
                Size=UDim2.new(0,PW,0,PH),
                Position=UDim2.new(0.5,-PW/2,0.5,-PH/2),
            }, popups)
            corner(popup, 10); addGlass(popup, 0.15, PALETTE.PanelGlass)

            local stroke = Instance.new("UIStroke")
            stroke.Color=Library.Settings.AccentColor
            stroke.Thickness=1.5; stroke.Transparency=0.4
            stroke.Parent=popup
            registerAccent(function() tween(stroke,{Color=Library.Settings.AccentColor}) end)

            local accentBar = create("Frame", {Name="accentBar",
                BackgroundColor3=Library.Settings.AccentColor,
                BackgroundTransparency=0.25,
                Size=UDim2.new(0,3,1,-16), Position=UDim2.new(0,0,0,8)}, popup)
            corner(accentBar, 2)
            registerAccent(function() tween(accentBar,{BackgroundColor3=Library.Settings.AccentColor}) end)

            local titleBar = create("Frame", {Name="titlebar", BackgroundTransparency=1,
                Active=true, Size=UDim2.new(1,0,0,28)}, popup)
            local titleLbl = create("TextLabel", {
                BackgroundTransparency=1, Text="- select spawn position -",
                TextSize=13, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,25,0,0),
            }, titleBar)
            local hg = Instance.new("UIGradient")
            hg.Color = resolveSeq(Library.Settings.AccentColor, PALETTE.Text)
            hg.Parent = titleLbl
            local phase=0
            local gradConn = RunService.Heartbeat:Connect(function(dt)
                if not titleLbl.Parent then return end
                phase=(phase+dt*0.15)%1
                hg.Offset=Vector2.new(math.sin(phase*math.pi*2)*0.5,0)
            end)
            popup.Destroying:Connect(function() pcall(function() gradConn:Disconnect() end) end)
            registerAccent(function() hg.Color = resolveSeq(Library.Settings.AccentColor,PALETTE.Text) end)

            local closeBtn = create("TextButton", {
                AutoButtonColor=false, Text="×", TextSize=18, FontFace=FONT_BOLD,
                TextColor3=PALETTE.TextDim, BackgroundColor3=PALETTE.Element,
                BackgroundTransparency=0.4,
                Size=UDim2.new(0,22,0,20), Position=UDim2.new(1,-26,0,4),
            }, popup)
            corner(closeBtn, 5)
            closeBtn.MouseButton1Click:Connect(function() popup:Destroy() end)

            create("Frame", {Name="divider", BackgroundColor3=PALETTE.Text,
                BackgroundTransparency=0.8,
                Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0,28)}, popup)

            -- drag
            local drag, ds, sp
            titleBar.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then
                    drag=true; ds=input.Position; sp=popup.Position
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if not drag then return end
                if input.UserInputType==Enum.UserInputType.MouseMovement
                   or input.UserInputType==Enum.UserInputType.Touch then
                    local d=input.Position-ds
                    popup.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1
                   or input.UserInputType==Enum.UserInputType.Touch then drag=false end
            end)

            local scroll = create("ScrollingFrame", {
                Name="list",
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(1,-24,1,-24),
                Position=UDim2.new(0,12,0,36),
                BorderSizePixel=0, ScrollBarThickness=4,
                ScrollBarImageColor3=Library.Settings.AccentColor,
                ScrollBarImageTransparency=0.4,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
            }, popup)
            corner(scroll, 8)
            registerAccent(function()
                tween(scroll,{ScrollBarImageColor3=Library.Settings.AccentColor}) end)

            local lay = Instance.new("UIListLayout")
            lay.SortOrder=Enum.SortOrder.LayoutOrder
            lay.Padding=UDim.new(0,5); lay.Parent=scroll
            local spad = Instance.new("UIPadding")
            spad.PaddingTop=UDim.new(0,6); spad.PaddingBottom=UDim.new(0,6)
            spad.PaddingLeft=UDim.new(0,6); spad.PaddingRight=UDim.new(0,6)
            spad.Parent=scroll

            for i, m in ipairs(SPAWN_MODES) do
                local isCurrent = (m.key == TP.spawnMode)
                local btn = create("TextButton", {
                    Name="pos_"..i, AutoButtonColor=false, Text="",
                    BackgroundColor3=isCurrent and Library.Settings.AccentColor or PALETTE.ElementHi,
                    BackgroundTransparency=isCurrent and 0.75 or 0.3,
                    Size=UDim2.new(1,0,0,32), LayoutOrder=i,
                }, scroll)
                corner(btn, 6)
                local lbl = create("TextLabel", {
                    BackgroundTransparency=1, Text=m.name,
                    TextSize=13, FontFace=isCurrent and FONT_BOLD or FONT_REGULAR,
                    TextColor3=isCurrent and Library.Settings.AccentColor or PALETTE.Text,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,12,0,0),
                }, btn)
                if isCurrent then
                    create("TextLabel", {Name="mark", BackgroundTransparency=1,
                        Text="◉", TextSize=14, FontFace=FONT_BOLD,
                        TextColor3=Library.Settings.AccentColor,
                        TextXAlignment=Enum.TextXAlignment.Right,
                        Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-24,0,0)}, btn)
                end
                btn.MouseEnter:Connect(function()
                    if not isCurrent then
                        tween(btn,{BackgroundColor3=Library.Settings.AccentColor, BackgroundTransparency=0.6})
                        tween(lbl,{TextColor3=Library.Settings.AccentColor})
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if not isCurrent then
                        tween(btn,{BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3})
                        tween(lbl,{TextColor3=PALETTE.Text})
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    TP.spawnMode = m.key
                    local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["teleport.spawnMode"]
                    if cc and cc.Set then
                        pcall(function() cc:Set(m.name, true) end)
                    end
                    popup:Destroy()
                end)
            end

            -- Esc закрывает
            local escConn
            escConn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.KeyCode==Enum.KeyCode.Escape then
                    if popup and popup.Parent then popup:Destroy() end
                    if escConn then escConn:Disconnect() end
                end
            end)
            popup.Destroying:Connect(function()
                if escConn then pcall(function() escConn:Disconnect() end) end
            end)
        end

    local tpSect = miscTab:CreateSection({Title="- teleport / spectate -",
        Position=UDim2.new(0,1044,0,8), Size=UDim2.new(0,240,0,380)})
        tpSect:Label("teleport to a player:", 16)
        tpSect:Button({Text="teleport to...", Callback=openTeleportPicker})
        tpSect:Divider()
        tpSect:Label("- spawn where -", 16)

        local spawnModeIndex = 1
        for i, m in ipairs(SPAWN_MODES) do
            if m.key == TP.spawnMode then spawnModeIndex = i break end
        end
        local spawnCycle = reg(tpSect, "Cycle", "teleport.spawnMode", {
            Prefix = "spawn: ",
            Values = SPAWN_MODE_NAMES,
            Index = spawnModeIndex,
            Callback = function(v)
                for _, m in ipairs(SPAWN_MODES) do
                    if m.name == v then TP.spawnMode = m.key; break end
                end
            end,
        })

        tpSect:Button({Text="select pos", Callback=openSelectPosPopup})

        tpSect:Divider()
        tpSect:Label("spectate a player:", 16)
        tpSect:Button({Text="spectate...", Callback=function()
            openPlayerPicker("- spectate -", function(target) startSpectate(target) end)
        end})
        tpSect:Button({Text="stop spectate", Callback=stopSpectate})
    end
    -- ════════════ SCOREBOARD — УДАЛЁН ════════════
    _G.__PRIMO_SCOREBOARD_SET_ENABLED = nil
    _G.__PRIMO_SB_DESTROY = nil
    _G.__PRIMO_SB_TOGGLE_SETTINGS = nil
    _G.__PRIMO_SB_SETTINGS_DESTROY = nil
        -- ════════════ CHAT LEAKER (styled) ════════════
    do
        local CL = {gui=nil, frame=nil, list=nil, layout=nil, running=true, messages={}}

        local CLCfg = {
            -- поведение
            showTimestamp=true,
            maxMessages=200,
            fadeOld=false, fadeDuration=30,
            -- размеры
            -- ❗ 300 → 360: длинные фразы вроде "You must wait before sending"
            -- больше не плющит в 3 строки
            width=360, height=220,
            messageSize=11, messagePadding=4,
            -- внешка
            bgColor=PALETTE.Panel, bgTransparency=0,
            cornerRadius=10,
            strokeColor=Library.Settings.AccentColor,
            strokeThickness=1.2, strokeTransparency=0.4,
            msgBgColor=PALETTE.Element, msgBgTransparency=0.55,
            font="arial",
            -- цвета sender/time
            accentSender=true,
            timeColor=Color3.fromRGB(0x80,0x80,0x8f),
            textColor=Color3.fromRGB(0xe8,0xe8,0xf2),
        }
        CL.cfg = CLCfg

        local function ensureGui()
            if CL.gui and CL.gui.Parent then return CL.gui end
            local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
            if not pg then return nil end
            CL.gui = Instance.new("ScreenGui")
            CL.gui.Name = "primo_chatleaker"
            CL.gui.ResetOnSpawn = false
            CL.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            CL.gui.IgnoreGuiInset = true
            CL.gui.DisplayOrder = 850
            CL.gui.Parent = pg
            return CL.gui
        end

        local function hexOf(c)
            if typeof(c) ~= "Color3" then c = Color3.new(1,1,1) end
            return string.format("#%02x%02x%02x",
                math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
        end
        local function esc(s)
            return tostring(s):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
        end
        -- срезает любые rich-text теги (<font>, <b>, <br>, <color>, и т.д.)
        local function stripTags(s)
            if type(s) ~= "string" then return "" end
            return (s:gsub("<[^>]->", ""):gsub("&lt;", "<"):gsub("&gt;", ">")
                     :gsub("&amp;", "&"))
        end

        local function build()
            local gui = ensureGui(); if not gui then return end
            if CL.frame and CL.frame.Parent then return end

            local _bgc  = (CLCfg and CLCfg.bgColor)        or PALETTE.Panel
            local _bgt  = (CLCfg and CLCfg.bgTransparency) or 0
            local _cr   = (CLCfg and CLCfg.cornerRadius)   or 10
            local _stc  = (CLCfg and CLCfg.strokeColor)    or Library.Settings.AccentColor
            local _stt  = (CLCfg and CLCfg.strokeThickness) or 1.2
            local _sttr = (CLCfg and CLCfg.strokeTransparency) or 0.4

            CL.frame = create("Frame", {Name="Main",
                BackgroundColor3=_bgc, BackgroundTransparency=_bgt,
                Size=UDim2.new(0, (CLCfg and CLCfg.width) or 300,
                               0, (CLCfg and CLCfg.height) or 200),
                Position=_G.__HYSTERIA_CL_POS or UDim2.new(0.82, 0, 0.5, -100),
                Active=true, BorderSizePixel=0}, gui)
            corner(CL.frame, _cr)
            addGlass(CL.frame, 0.15, PALETTE.PanelGlass)
            -- ❗ в реестр HUD-фреймов
            _G.__PRIMO_HUD_FRAMES = _G.__PRIMO_HUD_FRAMES or {}
            table.insert(_G.__PRIMO_HUD_FRAMES, CL.frame)

            local stroke = Instance.new("UIStroke")
            stroke.Color = _stc
            stroke.Thickness = _stt
            stroke.Transparency = _sttr
            stroke.Parent = CL.frame
            registerAccent(function() tween(stroke, {Color = Library.Settings.AccentColor}) end)

            local bar = create("Frame", {Name="accentBar",
                BackgroundColor3=Library.Settings.AccentColor,
                BackgroundTransparency=0.25, Size=UDim2.new(0, 3, 1, -16),
                Position=UDim2.new(0, 0, 0, 8)}, CL.frame)
            corner(bar, 2)
            registerAccent(function() tween(bar, {BackgroundColor3 = Library.Settings.AccentColor}) end)

            local header = create("TextLabel", {Name="header",
                BackgroundTransparency=1, Text="- chat leaker -",
                TextSize=13, FontFace=FONT_BOLD, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1, -50, 0, 30), Position=UDim2.new(0, 6, 0, 0)}, CL.frame)

            local hg = Instance.new("UIGradient")
            hg.Color = resolveSeq(Library.Settings.AccentColor, PALETTE.Text)
            hg.Parent = header
            local phase = 0
            local gradConn = RunService.Heartbeat:Connect(function(dt)
                if not header.Parent then return end
                phase = (phase + dt * 0.15) % 1
                hg.Offset = Vector2.new(math.sin(phase * math.pi * 2) * 0.5, 0)
            end)
            CL.frame.Destroying:Connect(function() pcall(function() gradConn:Disconnect() end) end)
            registerAccent(function()
                hg.Color = resolveSeq(Library.Settings.AccentColor, PALETTE.Text)
            end)

            local clearBtn = create("TextButton", {Name="clear", AutoButtonColor=false,
                Text="clear", TextSize=11, FontFace=FONT_BOLD,
                TextColor3=PALETTE.TextDim, BackgroundTransparency=1,
                Size=UDim2.new(0, 40, 0, 22), Position=UDim2.new(1, -44, 0, 4)}, CL.frame)
            clearBtn.MouseEnter:Connect(function()
                tween(clearBtn, {TextColor3=Library.Settings.AccentColor}) end)
            clearBtn.MouseLeave:Connect(function()
                tween(clearBtn, {TextColor3=PALETTE.TextDim}) end)
            clearBtn.MouseButton1Click:Connect(function()
                CL.messages = {}
                if CL.list then
                    for _, ch in ipairs(CL.list:GetChildren()) do
                        if ch:IsA("Frame") then ch:Destroy() end
                    end
                end
            end)

            create("Frame", {Name="divider",
                BackgroundColor3=PALETTE.Text, BackgroundTransparency=0.8,
                Size=UDim2.new(1, -16, 0, 1),
                Position=UDim2.new(0, 8, 0, 30)}, CL.frame)

            CL.list = create("ScrollingFrame", {Name="list",
                BackgroundTransparency=1,
                Position=UDim2.new(0, 0, 0, 31),
                Size=UDim2.new(1, 0, 1, -31),
                BorderSizePixel=0, ScrollBarThickness=3,
                ScrollBarImageColor3=Library.Settings.AccentColor,
                ScrollBarImageTransparency=0.4,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, CL.frame)
            registerAccent(function()
                tween(CL.list, {ScrollBarImageColor3=Library.Settings.AccentColor})
            end)

            CL.layout = Instance.new("UIListLayout")
            CL.layout.SortOrder = Enum.SortOrder.LayoutOrder
            CL.layout.Padding = UDim.new(0, 3)
            CL.layout.Parent = CL.list

            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 4)
            pad.PaddingBottom = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 8)
            pad.Parent = CL.list

            -- draggable via header
            local drag, ds, sp
            header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    drag = true; ds = input.Position; sp = CL.frame.Position
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if not drag then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch then
                    local d = input.Position - ds
                    CL.frame.Position = UDim2.new(
                        sp.X.Scale, sp.X.Offset + d.X,
                        sp.Y.Scale, sp.Y.Offset + d.Y)
                    _G.__HYSTERIA_CL_POS = CL.frame.Position
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    drag = false
                end
            end)

            -- ═══════════════════════════════════════════════════
            -- ❗ RESIZE HANDLES (тяни за края — ширина/высота live)
            -- ═══════════════════════════════════════════════════
            do
                -- helper: тонкая полоска-ручка
                local function makeHandle(name, size, pos, cursorHint)
                    local h = create("Frame", {Name=name,
                        BackgroundColor3=Library.Settings.AccentColor,
                        BackgroundTransparency=1,
                        BorderSizePixel=0,
                        Size=size, Position=pos,
                        ZIndex=52, Active=true}, CL.frame)
                    -- при наведении подсвечиваем — так юзер видит что тут можно тянуть
                    h.MouseEnter:Connect(function()
                        tween(h, {BackgroundTransparency=0.75})
                    end)
                    h.MouseLeave:Connect(function()
                        tween(h, {BackgroundTransparency=1})
                    end)
                    return h
                end

                -- правая грань (ширина)
                local handleR = makeHandle("resizeR",
                    UDim2.new(0, 6, 1, -30),
                    UDim2.new(1, -6, 0, 30))
                -- нижняя грань (высота)
                local handleB = makeHandle("resizeB",
                    UDim2.new(1, -30, 0, 6),
                    UDim2.new(0, 30, 1, -6))
                -- правый нижний угол (ширина+высота)
                local handleBR = makeHandle("resizeBR",
                    UDim2.new(0, 14, 0, 14),
                    UDim2.new(1, -14, 1, -14))

                local resizeMode, startMouse, startW, startH

                local function beginResize(mode, input)
                    resizeMode = mode
                    startMouse = input.Position
                    startW = CLCfg.width or 360
                    startH = CLCfg.height or 220
                end

                local function doResize(input)
                    if not resizeMode then return end
                    local dx = input.Position.X - startMouse.X
                    local dy = input.Position.Y - startMouse.Y
                    local newW = startW
                    local newH = startH
                    if resizeMode == "width" or resizeMode == "both" then
                        newW = math.clamp(math.floor(startW + dx), 200, 1200)
                    end
                    if resizeMode == "height" or resizeMode == "both" then
                        newH = math.clamp(math.floor(startH + dy), 100, 900)
                    end
                    if newW == (CLCfg.width or 0) and newH == (CLCfg.height or 0) then
                        return
                    end
                    CLCfg.width  = newW
                    CLCfg.height = newH
                    CL.frame.Size = UDim2.new(0, newW, 0, newH)
                    -- синкаем слайдеры в настройках (silent, чтобы не дёргать callback)
                    local cw = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["cl.cfg.width"]
                    local ch = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["cl.cfg.height"]
                    if cw and cw.Set then pcall(function() cw:Set(newW, true) end) end
                    if ch and ch.Set then pcall(function() ch:Set(newH, true) end) end
                end

                local function endResize()
                    resizeMode = nil
                end

                local function hookHandle(h, mode)
                    h.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.Touch then
                            beginResize(mode, input)
                        end
                    end)
                end
                hookHandle(handleR,  "width")
                hookHandle(handleB,  "height")
                hookHandle(handleBR, "both")

                UserInputService.InputChanged:Connect(function(input)
                    if not resizeMode then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                        doResize(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        endResize()
                    end
                end)
            end

            -- ❗ правый клик по chat logger → открыть его настройки
            CL.frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    if _G.__PRIMO_CL_TOGGLE_SETTINGS then
                        pcall(function() _G.__PRIMO_CL_TOGGLE_SETTINGS(nil) end)
                    end
                end
            end)
        end

        local function addMessage(sender, text)
            if not CL.list or not CL.layout then return end

            -- 🧹 чистим возможные rich-text теги
            text   = stripTags(text)
            sender = stripTags(sender)

            local ts = os.date("%H:%M:%S")
            local accentHex = hexOf(Library.Settings.AccentColor)

            local row = create("Frame", {Name="msg",
                BackgroundColor3=(CLCfg and CLCfg.msgBgColor) or PALETTE.Element,
                BackgroundTransparency=(CLCfg and CLCfg.msgBgTransparency) or 0.55,
                Size=UDim2.new(1, 0, 0, 0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BorderSizePixel=0}, CL.list)
            corner(row, 5)

            local _showTs  = (CLCfg and CLCfg.showTimestamp) ~= false
            local _maxMsgs = (CLCfg and CLCfg.maxMessages)   or 200
            local _timeHex = (CLCfg and CLCfg.timeColor)
                and string.format("#%02x%02x%02x",
                    math.floor(CLCfg.timeColor.R*255+0.5),
                    math.floor(CLCfg.timeColor.G*255+0.5),
                    math.floor(CLCfg.timeColor.B*255+0.5))
                or "#80808f"
            local _textHex = (CLCfg and CLCfg.textColor)
                and string.format("#%02x%02x%02x",
                    math.floor(CLCfg.textColor.R*255+0.5),
                    math.floor(CLCfg.textColor.G*255+0.5),
                    math.floor(CLCfg.textColor.B*255+0.5))
                or "#e8e8f2"
            local _accHex = (CLCfg and CLCfg.accentSender ~= false)
                and accentHex or _textHex
            local richText
            if _showTs then
                richText = string.format(
                    "<font color='%s' size='10'>%s</font>  "
                 .. "<font color='%s'><b>%s</b></font>  "
                 .. "<font color='%s'>%s</font>",
                    _timeHex, ts, _accHex, esc(sender), _textHex, esc(text))
            else
                richText = string.format(
                    "<font color='%s'><b>%s</b></font>  "
                 .. "<font color='%s'>%s</font>",
                    _accHex, esc(sender), _textHex, esc(text))
            end
            create("TextLabel", {Name="txt",
                BackgroundTransparency=1,
                RichText=true,
                Text = richText,
                TextSize=(CLCfg and CLCfg.messageSize) or 11,
                FontFace=FONT_REGULAR, TextColor3=PALETTE.Text,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextYAlignment=Enum.TextYAlignment.Top,
                TextWrapped=true,
                Size=UDim2.new(1, -12, 0, 0),
                Position=UDim2.new(0, 6, 0, 4),
                AutomaticSize=Enum.AutomaticSize.Y}, row)

            table.insert(CL.messages, {sender=sender, text=text, ts=ts})
            if #CL.messages > _maxMsgs then
                table.remove(CL.messages, 1)
                local children = CL.list:GetChildren()
                local oldest = nil
                for _, ch in ipairs(children) do
                    if ch:IsA("Frame") then
                        if not oldest or ch.LayoutOrder < oldest.LayoutOrder then
                            oldest = ch
                        end
                    end
                end
                if oldest then oldest:Destroy() end
            end

            task.defer(function()
                if CL.list and CL.list.Parent then
                    CL.list.CanvasPosition = Vector2.new(0, CL.list.AbsoluteCanvasSize.Y)
                end
            end)
        end

        build()

        -- ── dedup guard: не даём одному и тому же сообщению попасть дважды ──
        local _lastMsgKey, _lastMsgTime = nil, 0
        local _origAddMessage = addMessage
        addMessage = function(sender, text)
            local key = tostring(sender) .. "\1" .. tostring(text)
            local now = tick()
            if _lastMsgKey == key and (now - _lastMsgTime) < 0.4 then
                return  -- дубликат в пределах 0.4 сек — игнор
            end
            _lastMsgKey  = key
            _lastMsgTime = now
            _origAddMessage(sender, text)
        end

        -- ── helper: форматирование сендера (name protect + age group) ──
        local function _formatSender(p)
            if not p then return nil end
            local dn = p.DisplayName or p.Name
            local un = p.Name
            -- name protect для whitelisted
            if _G.__PRIMO_NAMEPROTECT_ENABLED == true
               and I.isWhitelisted and I.isWhitelisted(p) then
                local txt = _G.__PRIMO_NAMEPROTECT_TEXT or "Protected"
                dn = txt; un = txt
            end
            -- age group: показывает свежесть аккаунта
            local ageText = ""
            local age = p.AccountAge
            if type(age) == "number" then
                if age < 1 then ageText = " [new]"
                elseif age < 30 then ageText = " ["..age.."d]"
                elseif age < 365 then ageText = " ["..math.floor(age/30).."mo]"
                else ageText = " ["..math.floor(age/365).."y]" end
            end
            return dn .. " (@" .. un .. ")" .. ageText
        end

        -- ── выбираем ОДИН источник, а не оба ──
        local usedTCS = false
        pcall(function()
            local TCS = game:GetService("TextChatService")
            if TCS and TCS.ChatVersion == Enum.ChatVersion.TextChatService then
                TCS.MessageReceived:Connect(function(msg)
                    pcall(function()
                        -- ❗ ФИКС: отсекаем системные сообщения
                        -- ("You must wait before sending another message." и т.п.)
                        -- у них TextSource == nil
                        if not msg.TextSource then return end
                        local txt = msg.Text or ""
                        if txt == "" then return end
                        local senderPlayer = Players:FindFirstChild(msg.TextSource.Name)
                        local sender
                        if senderPlayer then
                            sender = _formatSender(senderPlayer)
                        else
                            sender = msg.TextSource.Name or "?"
                        end
                        if sender and sender ~= "" then
                            addMessage(sender, txt)
                        end
                    end)
                end)
                usedTCS = true
            end
        end)

        -- legacy chat — только если TextChatService не активен
        if not usedTCS then
            local function hookLegacy(p)
                pcall(function()
                    p.Chatted:Connect(function(msg)
                        local txt = msg or ""
                        if txt == "" then return end
                        local sender = _formatSender(p) or p.Name
                        addMessage(sender, txt)
                    end)
                end)
            end
            for _, p in ipairs(Players:GetPlayers()) do hookLegacy(p) end
            Players.PlayerAdded:Connect(hookLegacy)
        end

        _G.__PRIMO_CHATLEAKER_SET_ENABLED = function(v)
            if not CL.gui then ensureGui() end
            if v then
                if CL.gui then CL.gui.Enabled = true end
                build()
            else
                if CL.gui then CL.gui.Enabled = false end
            end
        end

        _G.__PRIMO_CL_DESTROY = function()
            CL.running = false
            if CL.list then
                for _, ch in ipairs(CL.list:GetChildren()) do
                    if ch:IsA("Frame") then
                        pcall(function() ch:Destroy() end)
                    end
                end
            end
            CL.messages = {}
            if _G.__PRIMO_CL_SETTINGS_DESTROY then
                pcall(_G.__PRIMO_CL_SETTINGS_DESTROY)
                _G.__PRIMO_CL_SETTINGS_DESTROY = nil
            end
            if CL.gui then pcall(function() CL.gui:Destroy() end) end
            CL.gui    = nil
            CL.frame  = nil
            CL.list   = nil
            CL.layout = nil
        end

        -- ── Chat leaker settings (использует CLCfg из начала блока) ──

        local CL_PW, CL_PH = 720, 680
        local clPopup = makePopupFrame("chatleaker_settings", "- chat leaker settings -", CL_PW, CL_PH)

        -- ⬇️ локальные координаты колонок (иначе они nil в этом скоупе)
        local colW, colGap, startX, startY = 170, 5, 5, 30
        local colH = CL_PH - startY - 10

        local function makeCCol(idx)
            return create("Frame", {Name="col"..idx, BackgroundTransparency=1,
                Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
                Size=UDim2.new(0,colW,0,colH)}, clPopup)
        end
        local c1 = setmetatable({Frame=makeCCol(1), Y=0}, Section)
        local c2 = setmetatable({Frame=makeCCol(2), Y=0}, Section)
        local c3 = setmetatable({Frame=makeCCol(3), Y=0}, Section)
        local c4 = setmetatable({Frame=makeCCol(4), Y=0}, Section)

        -- col 1: options
        c1:Label("options:")
        reg(c1, "Toggle", "cl.cfg.showTimestamp", {Text="show timestamp", Default=true,
            Callback=function(v) CLCfg.showTimestamp = v end})
        reg(c1, "NumberInput", "cl.cfg.maxMessages", {Text="max messages",
            Default=200, Min=20, Max=1000, Placeholder="200",
            Callback=function(v) CLCfg.maxMessages = v end})
        c1:Divider()
        c1:Label("size:")
        reg(c1, "Slider", "cl.cfg.width", {Text="width",
            Min=200, Max=1200, Default=360,
            Live=true,
            Callback=function(v)
                CLCfg.width = v
                if CL.frame then
                    local h = CLCfg.height or 220
                    CL.frame.Size = UDim2.new(0, v, 0, h)
                end
            end})
        reg(c1, "Slider", "cl.cfg.height", {Text="height",
            Min=100, Max=900, Default=220,
            Live=true,
            Callback=function(v)
                CLCfg.height = v
                if CL.frame then
                    local w = CLCfg.width or 360
                    CL.frame.Size = UDim2.new(0, w, 0, v)
                end
            end})
        reg(c1, "Slider", "cl.cfg.messageSize", {Text="message font size",
            Min=8, Max=18, Default=11,
            Callback=function(v) CLCfg.messageSize = v end})
        c1:Divider()
        c1:Button({Text="clear now", Callback=function()
            CL.messages = {}
            if CL.list then
                for _, ch in ipairs(CL.list:GetChildren()) do
                    if ch:IsA("Frame") then pcall(function() ch:Destroy() end) end
                end
            end
        end})

        -- col 2: background + corner
        c2:Label("background:")
        reg(c2, "ColorPicker", "cl.cfg.bgColor", {Text="bg color",
            GetInitialColor=function() return CLCfg.bgColor end,
            Callback=function(c)
                CLCfg.bgColor=c
                if CL.frame then CL.frame.BackgroundColor3=c end
            end})
        reg(c2, "Slider", "cl.cfg.bgTransparency", {Text="bg transparency",
            Min=0, Max=1, Default=0,
            Callback=function(v)
                CLCfg.bgTransparency=v
                if CL.frame then CL.frame.BackgroundTransparency=v end
            end})
        reg(c2, "Slider", "cl.cfg.cornerRadius", {Text="corner radius",
            Min=0, Max=20, Default=10,
            Callback=function(v)
                CLCfg.cornerRadius=v
                if CL.frame then
                    local c = CL.frame:FindFirstChildOfClass("UICorner")
                    if c then c.CornerRadius = UDim.new(0,v) end
                end
            end})
        c2:Divider()
        c2:Label("messages bg:")
        reg(c2, "ColorPicker", "cl.cfg.msgBgColor", {Text="row bg",
            GetInitialColor=function() return CLCfg.msgBgColor end,
            Callback=function(c) CLCfg.msgBgColor = c end})
        reg(c2, "Slider", "cl.cfg.msgBgTransparency", {Text="row transparency",
            Min=0, Max=1, Default=0.55,
            Callback=function(v) CLCfg.msgBgTransparency = v end})
        c2:Divider()
        c2:Label("font:")
        reg(c2, "Cycle", "cl.cfg.font", {Prefix="", Values=FONT_NAMES, Index=1,
            Callback=function(v) CLCfg.font = v end})

        -- col 3: stroke + text colors
        c3:Label("stroke:")
        reg(c3, "ColorPicker", "cl.cfg.strokeColor", {Text="stroke color",
            GetInitialColor=function() return CLCfg.strokeColor end,
            Callback=function(c)
                CLCfg.strokeColor=c
                local st = CL.frame and CL.frame:FindFirstChildOfClass("UIStroke")
                if st then st.Color=c end
            end})
        reg(c3, "Slider", "cl.cfg.strokeThickness", {Text="thickness",
            Min=0, Max=5, Default=1.2,
            Callback=function(v)
                CLCfg.strokeThickness=v
                local st = CL.frame and CL.frame:FindFirstChildOfClass("UIStroke")
                if st then st.Thickness=v end
            end})
        reg(c3, "Slider", "cl.cfg.strokeTransparency", {Text="transparency",
            Min=0, Max=1, Default=0.4,
            Callback=function(v)
                CLCfg.strokeTransparency=v
                local st = CL.frame and CL.frame:FindFirstChildOfClass("UIStroke")
                if st then st.Transparency=v end
            end})
        c3:Divider()
        c3:Label("message colors:")
        reg(c3, "Toggle", "cl.cfg.accentSender", {Text="sender uses accent", Default=true,
            Callback=function(v) CLCfg.accentSender = v end})
        reg(c3, "ColorPicker", "cl.cfg.timeColor", {Text="timestamp color",
            GetInitialColor=function() return CLCfg.timeColor end,
            Callback=function(c) CLCfg.timeColor = c end})
        reg(c3, "ColorPicker", "cl.cfg.textColor", {Text="message text color",
            GetInitialColor=function() return CLCfg.textColor end,
            Callback=function(c) CLCfg.textColor = c end})

        -- col 4: actions
        c4:Label("actions:")
        c4:Button({Text="reset position", Callback=function()
            if CL.frame then CL.frame.Position = UDim2.new(0.82,0,0.5,-100) end
        end})
        c4:Button({Text="reset size", Callback=function()
            CLCfg.width = 300; CLCfg.height = 200
            if CL.frame then CL.frame.Size = UDim2.new(0,300,0,200) end
        end})
        c4:Divider()
        c4:Label("hint: ты можешь тащить окошко", 16)
        c4:Label("за заголовок.", 16)
        c4:Button({Text="close settings", Callback=function() clPopup.Visible=false end})

        _G.__PRIMO_CL_TOGGLE_SETTINGS = function(anchor)
            if clPopup.Visible then
                clPopup.Visible = false
            else
                if anchor then
                    local a = anchor.AbsolutePosition
                    local vp = PlayerGui:FindFirstChild("primo_popups")
                    if vp then
                        local sz = vp.AbsoluteSize
                        local x = math.clamp(a.X - CL_PW + anchor.AbsoluteSize.X, 4, math.max(4, sz.X - CL_PW - 4))
                        local y = math.clamp(a.Y + anchor.AbsoluteSize.Y + 4, 4, math.max(4, sz.Y - CL_PH - 4))
                        clPopup.Position = UDim2.new(0, x, 0, y)
                    end
                end
                clPopup.Visible = true
                clPopup.BackgroundTransparency = 0
            end
        end
        _G.__PRIMO_CL_SETTINGS_DESTROY = function()
            pcall(function() clPopup:Destroy() end)
        end
    end
    end   -- ⬅ ЭТОГО end НЕ ХВАТАЛО — закрывает `do` MISC-таба
--===============================================================
-- WHITELIST TAB  (new)
--===============================================================
do
    -- fallback: если что-то из PART 3 упало, UI не крашится
    if not I.Whitelist then
        I.Whitelist = { Names={}, UIDs={}, Teams={}, NoDrawTeams={}, Enabled=true }
    end
    if type(I.listWhitelist)      ~= "function" then I.listWhitelist      = function() return {} end end
    if type(I.addWhitelist)       ~= "function" then I.addWhitelist       = function() return false end end
    if type(I.addWhitelistUID)    ~= "function" then I.addWhitelistUID    = function() return false end end
    if type(I.removeWhitelist)    ~= "function" then I.removeWhitelist    = function() return false end end
    if type(I.removeWhitelistUID) ~= "function" then I.removeWhitelistUID = function() return false end end
    if type(I.clearWhitelist)     ~= "function" then I.clearWhitelist     = function() return true end end
    if type(I.isWhitelisted)      ~= "function" then I.isWhitelisted      = function() return false end end
    if type(I.isTeamNoDraw)       ~= "function" then I.isTeamNoDraw       = function() return false end end
    if type(I.addNoDrawTeam)      ~= "function" then I.addNoDrawTeam      = function() return false end end
    if type(I.removeNoDrawTeam)   ~= "function" then I.removeNoDrawTeam   = function() return false end end
    if not I.Whitelist.NoDrawTeams then I.Whitelist.NoDrawTeams = {} end

    local wlTab = Window:CreateTab({
        Name="whitelist", Horizontal = true, CanvasWidth = 850,
    })

    -- ─────────────────────────────────────────────
    -- LEFT COLUMN : players (names / uids)
    -- ─────────────────────────────────────────────
    local wlMain = wlTab:CreateSection({Title="- whitelist / friends -",
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,260,0,900)})

    -- ── name protect ──
    wlMain:Label("- name protect -", 18)
    reg(wlMain, "Toggle", "nameprotect.enabled", {
        Text="enable name protect", Default=false,
        Callback=function(v)
            _G.__PRIMO_NAMEPROTECT_ENABLED = v and true or false
            Library.Settings.NameProtectEnabled = v and true or false
        end})
    reg(wlMain, "TextBox", "nameprotect.text", {
        Placeholder="Protected", Text="Protected",
        Callback=function(t)
            local txt = (t and t ~= "") and t or "Protected"
            _G.__PRIMO_NAMEPROTECT_TEXT = txt
            Library.Settings.NameProtectText = txt
        end})
    wlMain:Label("replaces nicknames of whitelisted players", 16)
    wlMain:Label("in ESP and chat leaker", 16)
    wlMain:Divider()

    wlMain:Label("username (case-insensitive):", 20)
    local nameBox
    nameBox = wlMain:TextBox({Placeholder="player name", Text="",
        Callback=function(t) end})
    wlMain:Button({Text="add username", Callback=function()
        local v = nameBox:Get()
        if v and v ~= "" then
            I.addWhitelist(v)
            nameBox:Set("", true)
            _G.refreshWL()
        end
    end})
    wlMain:Button({Text="add all current players", Callback=function()
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                I.addWhitelist(p.Name)
            end
        end
        _G.refreshWL()
    end})
    wlMain:Button({Text="clear whole whitelist", Callback=function()
        I.clearWhitelist()
        _G.refreshWL()
        if _G.refreshTeamWL then _G.refreshTeamWL() end
    end})
    wlMain:Label("- whitelist entries -", 22)

    local holder = create("Frame", {Name="wlHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,500)}, wlMain.Frame)
    corner(holder, 8)
    holder.Position = UDim2.new(0, 12, 0, wlMain.Y)
    wlMain.Y = wlMain.Y + 500 + 8

    local scroll = create("ScrollingFrame", {Name="wlScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, holder)
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,4)
    layout.Parent = scroll
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
    pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)
    pad.Parent = scroll

    _G.refreshWL = function()
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= layout then ch:Destroy() end
        end
        local list = I.listWhitelist()
        if #list == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="whitelist is empty", TextSize=12, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,40), LayoutOrder=1}, scroll)
            return
        end
        for i, name in ipairs(list) do
            local row = create("Frame", {Name="wl_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,28), LayoutOrder=i}, scroll)
            corner(row, 6)
            create("TextLabel", {Name="txt", BackgroundTransparency=1,
                Text=name, TextSize=12, TextColor3=PALETTE.Text,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,8,0,0)}, row)
            local delBtn = create("TextButton", {Name="del", AutoButtonColor=false,
                Text="x", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.5,
                Size=UDim2.new(0,26,1,-6), Position=UDim2.new(1,-30,0,3)}, row)
            corner(delBtn, 5)
            delBtn.MouseButton1Click:Connect(function()
                if name:sub(1,4) == "uid:" then
                    I.removeWhitelistUID(name:sub(5))
                else
                    I.removeWhitelist(name)
                end
                _G.refreshWL()
            end)
        end
    end
    _G.refreshWL()

    -- ─────────────────────────────────────────────
    -- RIGHT COLUMN : team whitelist
    -- ─────────────────────────────────────────────
    -- (проверки уже сделаны выше; тут только Teams-специфичное)
    if not I.Whitelist.Teams then I.Whitelist.Teams = {} end
    if type(I.addTeamWhitelist)    ~= "function" then I.addTeamWhitelist    = function() return false end end
    if type(I.removeTeamWhitelist) ~= "function" then I.removeTeamWhitelist = function() return false end end
    if type(I.clearTeamWhitelist)  ~= "function" then I.clearTeamWhitelist  = function() return true end end

    local teamSect = wlTab:CreateSection({Title="- team whitelist -",
        Position=UDim2.new(0,280,0,8), Size=UDim2.new(0,260,0,740)})
    teamSect:Label("teams from current game:", 20)
    teamSect:Label("toggle = whitelist  |  ⊘ = dont draw", 18)
    teamSect:Button({Text="refresh teams list",
        Callback=function() _G.refreshTeamWL() end})
    teamSect:Button({Text="whitelist all teams", Callback=function()
        local Teams
        local ok = pcall(function() Teams = game:GetService("Teams") end)
        if ok and Teams then
            for _, t in ipairs(Teams:GetTeams()) do
                I.addTeamWhitelist(t.Name)
            end
        end
        _G.refreshTeamWL()
    end})
    teamSect:Button({Text="clear team whitelist", Callback=function()
        I.clearTeamWhitelist()
        _G.refreshTeamWL()
    end})

    local teamHolder = create("Frame", {Name="teamHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,540)}, teamSect.Frame)
    corner(teamHolder, 8)
    teamHolder.Position = UDim2.new(0, 12, 0, teamSect.Y)
    teamSect.Y = teamSect.Y + 540 + 8

    local teamScroll = create("ScrollingFrame", {Name="teamScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, teamHolder)
    local teamLayout = Instance.new("UIListLayout")
    teamLayout.SortOrder = Enum.SortOrder.LayoutOrder
    teamLayout.Padding = UDim.new(0,5)
    teamLayout.Parent = teamScroll
    local teamPad = Instance.new("UIPadding")
    teamPad.PaddingTop = UDim.new(0,6); teamPad.PaddingBottom = UDim.new(0,6)
    teamPad.PaddingLeft = UDim.new(0,6); teamPad.PaddingRight = UDim.new(0,6)
    teamPad.Parent = teamScroll

    _G.refreshTeamWL = function()
        for _, ch in ipairs(teamScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= teamLayout then ch:Destroy() end
        end
        local Teams
        local ok = pcall(function() Teams = game:GetService("Teams") end)
        if not ok or not Teams then
            _G.buildTeamEmptyPlaceholder(teamScroll, "teams service unavailable")
            return
        end
        local list = Teams:GetTeams()
        if #list == 0 then
            _G.buildTeamEmptyPlaceholder(teamScroll)
            return
        end
        for i, team in ipairs(list) do
            local row = create("Frame", {Name="team_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,36), LayoutOrder=i}, teamScroll)
            corner(row, 6)
            local teamColor = Color3.fromRGB(128,128,128)
            pcall(function()
                if team.TeamColor then teamColor = team.TeamColor.Color end
            end)
            local swatch = create("Frame", {Name="swatch",
                BackgroundColor3=teamColor,
                Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,8,0.5,-9)}, row)
            corner(swatch, 4)
            create("TextLabel", {Name="txt", BackgroundTransparency=1,
                Text=team.Name, TextSize=13, TextColor3=PALETTE.Text,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,34,0,0)}, row)

            local state = I.Whitelist.Teams[tostring(team.Name):lower()] == true
            local toggleBtn = create("TextButton", {Name="toggle", AutoButtonColor=false,
                Text="", BackgroundColor3=PALETTE.ElementHi,
                Size=UDim2.new(0,38,0,20), Position=UDim2.new(1,-84,0.5,-10)}, row)
            corner(toggleBtn, 10)
            local knob = create("Frame", {Name="knob", BackgroundColor3=PALETTE.Text,
                Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,2,0.5,-8)}, toggleBtn)
            corner(knob, 8)
            local function applyToggle()
                local c = PALETTE.ElementHi
                if state then c = Library.Settings.AccentColor end
                tween(toggleBtn, {BackgroundColor3=c})
                local off = state and 22 or 2
                tween(knob, {Position=UDim2.new(0,off,0.5,-8)})
            end
            applyToggle()
            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                applyToggle()
                if state then I.addTeamWhitelist(team.Name)
                else I.removeTeamWhitelist(team.Name) end
            end)

            -- second toggle: dont draw (skip ESP/aimbot)
            local noDrawState = I.Whitelist.NoDrawTeams[tostring(team.Name):lower()] == true
            local ndBtn = create("TextButton", {Name="nodraw", AutoButtonColor=false,
                Text="⊘", TextSize=14, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.ElementHi,
                Size=UDim2.new(0,32,0,20), Position=UDim2.new(1,-42,0.5,-10)}, row)
            corner(ndBtn, 10)
            local function applyNoDraw()
                local c = PALETTE.ElementHi
                local tc = PALETTE.TextDim
                if noDrawState then c = PALETTE.Warn; tc = Color3.fromRGB(255,255,255) end
                tween(ndBtn, {BackgroundColor3=c, TextColor3=tc})
            end
            applyNoDraw()
            ndBtn.MouseButton1Click:Connect(function()
                noDrawState = not noDrawState
                applyNoDraw()
                if noDrawState then I.addNoDrawTeam(team.Name)
                else I.removeNoDrawTeam(team.Name) end
            end)
        end
    end

    -- ─────────────────────────────────────────────
    -- EMPTY-STATE BUILDER (универсальный)
    -- ─────────────────────────────────────────────
    _G.buildTeamEmptyPlaceholder = function(parent, customLine)
        local holder = create("Frame", {Name="emptyWrap",
            BackgroundTransparency=1, Size=UDim2.new(1, -12, 0, 240),
            Position=UDim2.new(0, 6, 0, 40), LayoutOrder=1}, parent)

        local uiList = Instance.new("UIListLayout")
        uiList.SortOrder = Enum.SortOrder.LayoutOrder
        uiList.Padding = UDim.new(0, 6)
        uiList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiList.Parent = holder

        local function line(text, order, size, color, bold)
            local lbl = create("TextLabel", {
                Name="ln", BackgroundTransparency=1, Text=text,
                TextSize=size or 12,
                TextColor3=color or PALETTE.TextDim,
                FontFace=bold and FONT_BOLD or FONT_REGULAR,
                TextWrapped=true,
                TextXAlignment=Enum.TextXAlignment.Center,
                TextYAlignment=Enum.TextYAlignment.Top,
                Size=UDim2.new(1, 0, 0, 0),
                AutomaticSize=Enum.AutomaticSize.Y,
                LayoutOrder=order,
            }, holder)
            return lbl
        end

        if customLine then
            line(customLine, 1, 12, PALETTE.TextDim, false)
            return holder
        end

        local mainColor = PALETTE.Text:Lerp(PALETTE.TextDim, 0.45)

        line("We tried to find something, but there are chickens.", 1, 12, mainColor, false)
        line("This script is universal, so this one may not work if game has custom team system", 2, 11, mainColor, false)
        line("at least follow our telegram channel:", 3, 11, mainColor, false)

        local link = line("t.me/hy5teria", 4, 13, Library.Settings.AccentColor, true)
        link.TextStrokeTransparency = 1
        link.TextTransparency = 0.25
        if type(registerAccent) == "function" then
            pcall(registerAccent, function()
                tween(link, { TextColor3 = Library.Settings.AccentColor })
            end)
        end

        return holder
    end

    _G.refreshTeamWL()

    pcall(function()
        local Teams = game:GetService("Teams")
        _G.__PRIMO_TEAMS_ADDED_CONN = Teams.ChildAdded:Connect(function()
            task.wait(0.1); pcall(_G.refreshTeamWL)
        end)
        _G.__PRIMO_TEAMS_REMOVED_CONN = Teams.ChildRemoved:Connect(function()
            task.wait(0.1); pcall(_G.refreshTeamWL)
        end)
    end)

    -- ─────────────────────────────────────────────
    -- THIRD COLUMN : target list
    -- ─────────────────────────────────────────────
    local targetSect = wlTab:CreateSection({Title="- target list -",
        Position=UDim2.new(0,552,0,8), Size=UDim2.new(0,260,0,740)})
    targetSect:Label("click a player to set target", 18)
    targetSect:Label("target gets chams + aim priority", 18)
    targetSect:Button({Text="clear current target", Callback=function()
        _G.PRIMO_TARGET = nil
        if _G.refreshTargetList then _G.refreshTargetList() end
    end})

    local targetHolder = create("Frame", {Name="targetHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,540)}, targetSect.Frame)
    corner(targetHolder, 8)
    targetHolder.Position = UDim2.new(0, 12, 0, targetSect.Y)
    targetSect.Y = targetSect.Y + 540 + 8

    local targetScroll = create("ScrollingFrame", {Name="targetScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, targetHolder)
    local targetLayout = Instance.new("UIListLayout")
    targetLayout.SortOrder = Enum.SortOrder.LayoutOrder
    targetLayout.Padding = UDim.new(0,4)
    targetLayout.Parent = targetScroll
    local targetPad = Instance.new("UIPadding")
    targetPad.PaddingTop = UDim.new(0,6); targetPad.PaddingBottom = UDim.new(0,6)
    targetPad.PaddingLeft = UDim.new(0,6); targetPad.PaddingRight = UDim.new(0,6)
    targetPad.Parent = targetScroll

    _G.refreshTargetList = function()
        for _, ch in ipairs(targetScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= targetLayout then ch:Destroy() end
        end
        local Players2 = game:GetService("Players")
        local list = {}
        for _, pl in ipairs(Players2:GetPlayers()) do
            if pl ~= Players2.LocalPlayer then list[#list+1] = pl end
        end
        table.sort(list, function(a, b)
            return a.Name:lower() < b.Name:lower()
        end)
        if #list == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="no other players", TextSize=12, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,40), LayoutOrder=1}, targetScroll)
            return
        end
        -- multi-target: маркер если в таблице ИЛИ если это legacy-таргет
        for i, pl in ipairs(list) do
            local isTarget = _G.PRIMO_TARGETS[pl] == true

            local row = create("TextButton", {Name="tgt_"..pl.Name, AutoButtonColor=false,
                Text="", BackgroundColor3=PALETTE.ElementHi,
                BackgroundTransparency=isTarget and 0.1 or 0.35,
                Size=UDim2.new(1,0,0,28), LayoutOrder=i}, targetScroll)
            corner(row, 6)

            -- галочка слева (для визуального отличия multi от single)
            local mark = create("TextLabel", {Name="chk", BackgroundTransparency=1,
                Text=isTarget and "◉" or "○", TextSize=14,
                TextColor3=isTarget and Library.Settings.AccentColor or PALETTE.TextDim,
                FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(0,22,1,0), Position=UDim2.new(0,4,0,0)}, row)

            create("TextLabel", {Name="txt", BackgroundTransparency=1,
                Text=pl.Name, TextSize=12,
                TextColor3=isTarget and Library.Settings.AccentColor or PALETTE.Text,
                FontFace=isTarget and FONT_BOLD or FONT_REGULAR,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-46,1,0), Position=UDim2.new(0,30,0,0)}, row)

            row.MouseButton1Click:Connect(function()
                -- toggle в таблице
                if _G.PRIMO_TARGETS[pl] then
                    _G.PRIMO_TARGETS[pl] = nil
                else
                    _G.PRIMO_TARGETS[pl] = true
                end
                -- legacy single: берём первый живой из таблицы
                local first = nil
                for p in pairs(_G.PRIMO_TARGETS) do
                    if p and p.Parent then first = p; break end
                end
                _G.PRIMO_TARGET = first
                _G.refreshTargetList()
            end)
        end
    end
    _G.refreshTargetList()

    -- отдельная кнопка "clear all targets"
    targetSect:Button({Text="clear ALL targets", Callback=function()
        _G.PRIMO_TARGETS = {}
        _G.PRIMO_TARGET = nil
        _G.refreshTargetList()
    end})
end

-- глобальная инициализация таргета (если ещё не создан)
_G.PRIMO_TARGET = _G.PRIMO_TARGET or nil
_G.PRIMO_TARGETS = _G.PRIMO_TARGETS or {}

--===============================================================
-- TARGET ESP  —  встроенный в меню шаблон-драг  (fixed)
--===============================================================
pcall(function()
    if Window and Window.Frame and Window.TargetList then
        local menuFrame = Window.Frame
        local HUD = Window.TargetList
        local DEFAULT_X, DEFAULT_Y = 400, 220

        -- restore last offset
        local storedOffsetX, storedOffsetY = DEFAULT_X, DEFAULT_Y
        if _G.__HYSTERIA_TL_PREVIEW_OFFSET then
            storedOffsetX = _G.__HYSTERIA_TL_PREVIEW_OFFSET[1] or DEFAULT_X
            storedOffsetY = _G.__HYSTERIA_TL_PREVIEW_OFFSET[2] or DEFAULT_Y
        end

        local preview = create("Frame", {
            Name = "TargetESP_template",
            BackgroundColor3 = PALETTE.Panel,
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 260, 0, 78),
            Position = UDim2.new(0, storedOffsetX, 0, storedOffsetY),
            ZIndex = 100,
            Active = true,
            Visible = false,
        }, menuFrame)
        corner(preview, 10)

        local previewStroke = Instance.new("UIStroke")
        previewStroke.Color = Library.Settings.AccentColor
        previewStroke.Thickness = 2
        previewStroke.Transparency = 0.35
        previewStroke.Parent = preview
        registerAccent(function()
            tween(previewStroke, {Color = Library.Settings.AccentColor})
        end)

        local hint = create("TextLabel", {
            Name = "hint", BackgroundTransparency = 1,
            Text = "‹ drag to place TargetESP ›  (double-click = reset)",
            TextSize = 11, TextColor3 = PALETTE.TextDim,
            FontFace = FONT_BOLD,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 1, 4),
            ZIndex = 101,
        }, preview)

        -- mockup body
        local accentBar = create("Frame", {Name="accentBar",
            BackgroundColor3 = Library.Settings.AccentColor,
            BackgroundTransparency = 0.3,
            Size = UDim2.new(0, 3, 1, -20),
            Position = UDim2.new(0, 0, 0, 10)}, preview)
        corner(accentBar, 2)

        local pAvatar = create("ImageLabel", {Name="avatar",
            BackgroundColor3 = PALETTE.Element,
            Image = "rbxassetid://135535710084064",
            Size = UDim2.new(0, 56, 0, 56),
            Position = UDim2.new(0, 12, 0, 11)}, preview)
        corner(pAvatar, 8)
        local pStroke = Instance.new("UIStroke")
        pStroke.Color = Library.Settings.AccentColor
        pStroke.Thickness = 1.5
        pStroke.Transparency = 0.35
        pStroke.Parent = pAvatar

        create("TextLabel", {Name="playerinfo", BackgroundTransparency=1,
            Text="target preview", TextSize=14, FontFace=FONT_BOLD,
            TextColor3 = PALETTE.Text, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1,-82,0,18), Position = UDim2.new(0,78,0,12)}, preview)
        create("TextLabel", {Name="displayinfo", BackgroundTransparency=1,
            Text="@-", TextSize=12, FontFace=FONT_REGULAR,
            TextColor3 = PALETTE.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1,-82,0,14), Position = UDim2.new(0,78,0,30)}, preview)
        create("TextLabel", {Name="hpLabel", BackgroundTransparency=1,
            Text="hp 100 / 100", TextSize=11, FontFace=FONT_BOLD,
            TextColor3 = PALETTE.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1,-86,0,12), Position = UDim2.new(0,78,0,46)}, preview)
        local pHpTrack = create("Frame", {Name="healthTrack",
            BackgroundColor3 = PALETTE.Element,
            Size = UDim2.new(1,-86,0,8),
            Position = UDim2.new(0,78,0,60)}, preview)
        corner(pHpTrack, 4)
        local pHpFill = create("Frame", {Name="fill",
            BackgroundColor3 = Library.Settings.AccentColor,
            Size = UDim2.new(1,0,1,0)}, pHpTrack)
        corner(pHpFill, 4)
        registerAccent(function()
            tween(accentBar, {BackgroundColor3 = Library.Settings.AccentColor})
            tween(pStroke,   {Color = Library.Settings.AccentColor})
            tween(pHpFill,   {BackgroundColor3 = Library.Settings.AccentColor})
        end)

        -- ── coordinate helpers (UIScale-aware) ──
        local dragging, dragStart = false, nil

        local function getMenuScale()
            local us = menuFrame:FindFirstChildOfClass("UIScale")
            return us and us.Scale or 1
        end

        local function previewToScreen()
            local mp = menuFrame.AbsolutePosition
            local s  = getMenuScale()
            return mp.X + preview.Position.X.Offset * s,
                   mp.Y + preview.Position.Y.Offset * s
        end

        local function screenToPreview(sx, sy)
            local mp = menuFrame.AbsolutePosition
            local s  = getMenuScale()
            return (sx - mp.X) / s, (sy - mp.Y) / s
        end

        local function applyToHUD()
            local sx, sy = previewToScreen()
            local pos = UDim2.new(0, math.floor(sx), 0, math.floor(sy))
            HUD:SetPosition(pos)
            _G.__HYSTERIA_TL_POS = pos
        end

        local function syncFromHUD()
            local hudFrame = HUD.GetFrame and HUD:GetFrame()
            if not hudFrame then return end
            local hp = hudFrame.AbsolutePosition
            local px, py = screenToPreview(hp.X, hp.Y)
            preview.Position = UDim2.new(0, math.floor(px), 0, math.floor(py))
            storedOffsetX = math.floor(px)
            storedOffsetY = math.floor(py)
        end

        -- initial sync (после того как меню встало по позиции)
        task.defer(syncFromHUD)
        task.delay(0.1, syncFromHUD)

        -- menu moved → держим preview приклеенным к HUD
        menuFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if not dragging then syncFromHUD() end
        end)
        -- menu scaled → пересчёт
        menuFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            if not dragging then syncFromHUD() end
        end)

        -- ── drag handlers ──
        preview._dragConns = {}
        preview.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                tween(previewStroke, {Transparency = 0, Thickness = 2.5}, 0.12)
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                local anchor = HUD.GetFrame and HUD:GetFrame()
                if HUD.ToggleSettings then
                    pcall(function() HUD:ToggleSettings(anchor) end)
                end
            end
        end)

        local _lastHudUpdate = 0
        table.insert(preview._dragConns, UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local d = input.Position - dragStart
            dragStart = input.Position
            local s = getMenuScale()
            preview.Position = UDim2.new(0,
                preview.Position.X.Offset + d.X / s,
                0,
                preview.Position.Y.Offset + d.Y / s)
            storedOffsetX = preview.Position.X.Offset
            storedOffsetY = preview.Position.Y.Offset
            local now = tick()
            if now - _lastHudUpdate > 0.016 then
                _lastHudUpdate = now
                applyToHUD()
            end
        end))

        table.insert(preview._dragConns, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if not dragging then return end
            dragging = false
            applyToHUD()
            tween(previewStroke, {Transparency = 0.35, Thickness = 2}, 0.15)
            _G.__HYSTERIA_TL_PREVIEW_OFFSET = {storedOffsetX, storedOffsetY}
        end))

        preview.Destroying:Connect(function()
            for _, c in ipairs(preview._dragConns or {}) do
                pcall(function() c:Disconnect() end)
            end
            preview._dragConns = nil
        end)

        -- double click = reset to default
        local _lastClick = 0
        preview.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local now = tick()
            if now - _lastClick < 0.35 then
                preview.Position = UDim2.new(0, DEFAULT_X, 0, DEFAULT_Y)
                storedOffsetX, storedOffsetY = DEFAULT_X, DEFAULT_Y
                applyToHUD()
                _G.__HYSTERIA_TL_PREVIEW_OFFSET = {DEFAULT_X, DEFAULT_Y}
            end
            _lastClick = now
        end)

        -- persist offset периодически
        task.spawn(function()
            while preview.Parent do
                task.wait(3)
                _G.__HYSTERIA_TL_PREVIEW_OFFSET = {storedOffsetX, storedOffsetY}
            end
        end)
    end
end)
--===============================================================
-- SESSION HUD  (без вкладки — управление из settings → hud/screens)
--===============================================================
_G.__PRIMO_SESSION_REFRESH = nil
_G.__PRIMO_SESSION_FRAME = nil
_G.__PRIMO_SESSION_TOGGLE_SETTINGS = nil

pcall(function()
    -- ── 1. Config ──
    local SessionConfig = {
        enabled        = true,
        LockDrag       = false,
        showKills      = true,
        showDeaths     = true,
        showTime       = true,
        showKD         = true,
        showAccuracy   = true,
        accentTint     = true,
        bgColor        = PALETTE.Panel,
        bgTransparency = 0,
        cornerRadius   = 10,
        strokeColor        = Library.Settings.AccentColor,
        strokeThickness    = 1,
        strokeTransparency = 0.4,
        gradient   = false,
        colorA     = Library.Settings.AccentColor,
        colorB     = Color3.new(1,1,1),
        style      = "flow",
        speed      = 1,
        gradTitle  = true,
        gradKills  = true,
        gradDeaths = true,
        gradTime   = true,
        font      = "arial",
        textSize  = 12,
        titleText = "- session -",
    }

    -- ── 2. HUD window ──
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    if pg:FindFirstChild("primo_session") then
        pg.primo_session:Destroy()
    end
    local SessionGui = create("ScreenGui", {Name="primo_session",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, ResetOnSpawn=false,
        IgnoreGuiInset=true, DisplayOrder=850}, pg)

    local SF = create("Frame", {Name="Main", BackgroundColor3=SessionConfig.bgColor,
        BackgroundTransparency=SessionConfig.bgTransparency,
        Size=UDim2.new(0, 200, 0, 82),
        Position=_G.__HYSTERIA_SESS_POS or UDim2.new(0.56035, 0, 0.54636, 0)}, SessionGui)
    _G.__PRIMO_SESSION_FRAME = SF
    -- ❗ в реестр HUD-фреймов (outsideConn настроек пропускает клики по нему)
    _G.__PRIMO_HUD_FRAMES = _G.__PRIMO_HUD_FRAMES or {}
    table.insert(_G.__PRIMO_HUD_FRAMES, SF)
    local sCorner = corner(SF, SessionConfig.cornerRadius)

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = SessionConfig.strokeColor
    sStroke.Thickness = SessionConfig.strokeThickness
    sStroke.Transparency = SessionConfig.strokeTransparency
    sStroke.Parent = SF

    local sBar = create("Frame", {Name="accentBar",
        BackgroundColor3=Library.Settings.AccentColor,
        BackgroundTransparency=0.3, Size=UDim2.new(0,3,1,-16),
        Position=UDim2.new(0,0,0,8)}, SF)
    corner(sBar, 2)

    registerAccent(function()
        if SessionConfig.accentTint then
            tween(sStroke, {Color = Library.Settings.AccentColor})
            tween(sBar,   {BackgroundColor3 = Library.Settings.AccentColor})
        end
    end)

    -- ── title ──
    local sTitle = create("TextLabel", {Name="title", BackgroundTransparency=1,
        Text=SessionConfig.titleText, TextSize=12, FontFace=FONT_BOLD,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Center,
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,3)}, SF)



    -- ── LEFT column (kills / deaths / time) ──
    local sKills = create("TextLabel", {Name="kills", BackgroundTransparency=1,
        Text="kills: 0", TextSize=SessionConfig.textSize, FontFace=FONT_REGULAR,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,116,0,16), Position=UDim2.new(0,12,0,22)}, SF)
    local sDeaths = create("TextLabel", {Name="deaths", BackgroundTransparency=1,
        Text="deaths: 0", TextSize=SessionConfig.textSize, FontFace=FONT_REGULAR,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,116,0,16), Position=UDim2.new(0,12,0,40)}, SF)
    local sTime = create("TextLabel", {Name="time", BackgroundTransparency=1,
        Text="time: 00:00:00", TextSize=SessionConfig.textSize, FontFace=FONT_REGULAR,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,116,0,16), Position=UDim2.new(0,12,0,58)}, SF)

    -- ── RIGHT column: K/D (row 1, aligned with kills) ──
    local sKDLabel = create("TextLabel", {Name="kdLabel", BackgroundTransparency=1,
        Text="K/D", TextSize=11, FontFace=FONT_REGULAR,
        TextColor3=PALETTE.TextDim, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,30,0,16), Position=UDim2.new(0,120,0,22)}, SF)
    local sKDValue = create("TextLabel", {Name="kdValue", BackgroundTransparency=1,
        Text="0.00", TextSize=14, FontFace=FONT_BOLD,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,44,0,16), Position=UDim2.new(0,150,0,22)}, SF)

    -- ── RIGHT column: ACC (row 2, aligned with deaths) ──
    local sAccLabel = create("TextLabel", {Name="accLabel", BackgroundTransparency=1,
        Text="ACC", TextSize=11, FontFace=FONT_REGULAR,
        TextColor3=PALETTE.TextDim, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(0,30,0,16), Position=UDim2.new(0,120,0,40)}, SF)
    local sAccValue = create("TextLabel", {Name="accValue", BackgroundTransparency=1,
        Text="0.0%", TextSize=14, FontFace=FONT_BOLD,
        TextColor3=PALETTE.Text, TextXAlignment=Enum.TextXAlignment.Right,
        Size=UDim2.new(0,44,0,16), Position=UDim2.new(0,150,0,40)}, SF)

    -- ── gradient targets ──
    local gradTargets = {sTitle, sKills, sDeaths, sTime}
    local gradFlagFor = {
        [sTitle]  = "gradTitle",
        [sKills]  = "gradKills",
        [sDeaths] = "gradDeaths",
        [sTime]   = "gradTime",
    }
    local sessionGrads = {}
    for _, lbl in ipairs(gradTargets) do
        local g = Instance.new("UIGradient")
        g.Name = "SessionGrad"; g.Enabled = false; g.Parent = lbl
        table.insert(sessionGrads, g)
    end

    local function applySessionFont()
        local f = getFontByName(SessionConfig.font)
        for _, lbl in ipairs(gradTargets) do lbl.FontFace = f end
    end
    local function applySessionTextSize()
        sKills.TextSize  = SessionConfig.textSize
        sDeaths.TextSize = SessionConfig.textSize
        sTime.TextSize   = SessionConfig.textSize
    end
    local function applySessionGradients()
        for i, g in ipairs(sessionGrads) do
            local lbl = gradTargets[i]
            local flag = gradFlagFor[lbl]
            local on = SessionConfig.gradient and flag and SessionConfig[flag]
            g.Enabled = on and true or false
            if on then
                g.Offset = Vector2.new(0, 0)
                g.Rotation = (SessionConfig.style == "sweep") and 45 or 0
                g.Color = resolveSeq(SessionConfig.colorA, SessionConfig.colorB)
            end
        end
    end
    local function applySessionTitle()
        sTitle.Text = SessionConfig.titleText or "- session -"
    end
    applySessionFont(); applySessionTextSize(); applySessionGradients(); applySessionTitle()

    -- ── gradient animation ──
    local sessPhase = 0
    local sessAnimConn = RunService.Heartbeat:Connect(function(dt)
        if not SessionConfig.gradient then return end
        local enabled = {}
        for _, g in ipairs(sessionGrads) do
            if g.Enabled then table.insert(enabled, g) end
        end
        if #enabled == 0 then return end
        local speed = SessionConfig.speed
        if SessionConfig.style == "sweep" then
            sessPhase = (sessPhase + dt*speed*60) % 360
            for _, g in ipairs(enabled) do g.Rotation = sessPhase end
        elseif SessionConfig.style == "pulse" then
            sessPhase = (sessPhase + dt*speed*0.4) % 1
            local k = (math.sin(sessPhase*math.pi*2)+1)*0.5
            local seq = resolvePulseSeq(SessionConfig.colorA, SessionConfig.colorB, k)
            for _, g in ipairs(enabled) do g.Color = seq end
        else
            sessPhase = (sessPhase + dt*speed*0.15) % 1
            local o = math.sin(sessPhase*math.pi*2)*0.5
            for _, g in ipairs(enabled) do g.Offset = Vector2.new(o, 0) end
        end
    end)

    -- ── 3. Refresh loop ──
    local function fmtTime(s)
        s = math.floor(s or 0)
        return string.format("%02d:%02d:%02d",
            math.floor(s/3600), math.floor((s%3600)/60), s%60)
    end
    _G.__PRIMO_SESSION_REFRESH = function()
        local S = I.Session
        if not S then return end
        sKills.Visible  = SessionConfig.showKills
        sDeaths.Visible = SessionConfig.showDeaths
        sTime.Visible   = SessionConfig.showTime
        if SessionConfig.showKills  then sKills.Text  = "kills: "  .. tostring(S.kills or 0) end
        if SessionConfig.showDeaths then sDeaths.Text = "deaths: " .. tostring(S.deaths or 0) end
        if SessionConfig.showTime   then sTime.Text   = "time: "   .. fmtTime(tick() - (S.startTime or tick())) end

        local k = tonumber(S.kills) or 0
        local d = tonumber(S.deaths) or 0
        local kd = k / math.max(d, 1)
        sKDValue.Text = string.format("%.2f", kd)

        local sh = tonumber(S.shots) or 0
        local ht = tonumber(S.hits) or 0
        local acc = (ht / math.max(sh, 1)) * 100
        sAccValue.Text = string.format("%.1f%%", acc)
    end
    _G.__PRIMO_SESSION_TASK = task.spawn(function()
        while task.wait(1) do
            if not _G.__PRIMO_SESSION_REFRESH then break end
            if not _G.__PRIMO_SESSION_FRAME
               or not _G.__PRIMO_SESSION_FRAME.Parent then break end
            pcall(_G.__PRIMO_SESSION_REFRESH)
        end
        _G.__PRIMO_SESSION_TASK = nil
    end)
    pcall(_G.__PRIMO_SESSION_REFRESH)

    -- ── 4. Dragging ──
    local _sessDragChanged, _sessDragEnded
    do
        local dragging, dragStart, startPos = false, nil, nil
        SF.InputBegan:Connect(function(input)
            if SessionConfig.LockDrag then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = SF.Position
            end
        end)
        _sessDragChanged = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                    startPos.Y.Scale, startPos.Y.Offset+d.Y)
                SF.Position = newPos
                _G.__HYSTERIA_SESS_POS = newPos
            end
        end)
        _sessDragEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- ── 5. Settings popup (720×680, 4 columns) ──
    local PW, PH = 720, 680
    local sessPopup, _ = makePopupFrame("session_settings", "- session hud settings -", PW, PH)
    local colW, colGap, startX, startY = 170, 5, 5, 30
    local colH = PH - startY - 10
    local function makeCol(idx)
        return create("Frame", {Name="col"..idx, BackgroundTransparency=1,
            Position=UDim2.new(0,startX+(idx-1)*(colW+colGap),0,startY),
            Size=UDim2.new(0,colW,0,colH)}, sessPopup)
    end
    local s1 = setmetatable({Frame=makeCol(1), Y=0}, Section)
    local s2 = setmetatable({Frame=makeCol(2), Y=0}, Section)
    local s3 = setmetatable({Frame=makeCol(3), Y=0}, Section)
    local s4 = setmetatable({Frame=makeCol(4), Y=0}, Section)

    -- col 1: visibility + actions
    s1:Label("visibility:")
    reg(s1, "Toggle", "session.showKills",  {Text="kills",  Default=true,
        Callback=function(v) SessionConfig.showKills  = v end})
    reg(s1, "Toggle", "session.showDeaths", {Text="deaths", Default=true,
        Callback=function(v) SessionConfig.showDeaths = v end})
    reg(s1, "Toggle", "session.showTime",   {Text="time",   Default=true,
        Callback=function(v) SessionConfig.showTime   = v end})
    reg(s1, "Toggle", "session.showKD", {Text="K/D", Default=true,
        Callback=function(v)
            SessionConfig.showKD = v
            sKDLabel.Visible = v
            sKDValue.Visible = v
        end})
    reg(s1, "Toggle", "session.showAccuracy", {Text="accuracy", Default=true,
        Callback=function(v)
            SessionConfig.showAccuracy = v
            sAccLabel.Visible = v
            sAccValue.Visible = v
        end})
    s1:Divider()
    s1:Label("actions:")
    s1:Button({Text="reset stats", Callback=function()
        if I.Session then
            I.Session.kills = 0
            I.Session.deaths = 0
            I.Session.shots = 0
            I.Session.hits = 0
            I.Session.startTime = tick()
        end
        if _G.__PRIMO_SESSION_REFRESH then pcall(_G.__PRIMO_SESSION_REFRESH) end
    end})
    s1:Button({Text="reset position", Callback=function()
        SF.Position = UDim2.new(0.56035, 0, 0.54636, 0)
    end})

    -- col 2: colors
    s2:Label("accent:")
    reg(s2, "Toggle", "session.accentTint", {Text="accent tint (bar + stroke)",
        Default=true, Callback=function(v)
            SessionConfig.accentTint = v
            if not v then
                tween(sStroke, {Color = SessionConfig.strokeColor})
                tween(sBar,   {BackgroundColor3 = SessionConfig.strokeColor})
            else
                tween(sStroke, {Color = Library.Settings.AccentColor})
                tween(sBar,   {BackgroundColor3 = Library.Settings.AccentColor})
            end
        end})
    s2:Divider()
    s2:Label("background:")
    reg(s2, "ColorPicker", "session.bgColor", {Text="bg color",
        GetInitialColor=function() return SessionConfig.bgColor end,
        Callback=function(c)
            SessionConfig.bgColor = c
            SF.BackgroundColor3 = c
        end})
    reg(s2, "Slider", "session.bgTransparency", {Text="bg transparency",
        Min=0, Max=1, Default=SessionConfig.bgTransparency,
        Callback=function(v)
            SessionConfig.bgTransparency = v
            SF.BackgroundTransparency = v
        end})
    reg(s2, "Slider", "session.cornerRadius", {Text="corner radius",
        Min=0, Max=20, Default=SessionConfig.cornerRadius,
        Callback=function(v)
            SessionConfig.cornerRadius = v
            sCorner.CornerRadius = UDim.new(0, v)
        end})
    s2:Divider()
    s2:Label("stroke:")
    reg(s2, "ColorPicker", "session.strokeColor", {Text="stroke color",
        GetInitialColor=function() return SessionConfig.strokeColor end,
        Callback=function(c)
            SessionConfig.strokeColor = c
            if not SessionConfig.accentTint then sStroke.Color = c end
        end})
    reg(s2, "Slider", "session.strokeThickness", {Text="thickness",
        Min=0, Max=5, Default=SessionConfig.strokeThickness,
        Callback=function(v)
            SessionConfig.strokeThickness = v
            sStroke.Thickness = v
        end})
    reg(s2, "Slider", "session.strokeTransparency", {Text="transparency",
        Min=0, Max=1, Default=SessionConfig.strokeTransparency,
        Callback=function(v)
            SessionConfig.strokeTransparency = v
            sStroke.Transparency = v
        end})

    -- col 3: gradient
    s3:Label("gradient:")
    reg(s3, "Toggle", "session.gradient", {Text="enabled", Default=false,
        Callback=function(v) SessionConfig.gradient = v; applySessionGradients() end})
    reg(s3, "ColorPicker", "session.colorA", {Text="color a",
        GetInitialColor=function() return SessionConfig.colorA end,
        Callback=function(c) SessionConfig.colorA = c; applySessionGradients() end})
    reg(s3, "ColorPicker", "session.colorB", {Text="color b",
        GetInitialColor=function() return SessionConfig.colorB end,
        Callback=function(c) SessionConfig.colorB = c; applySessionGradients() end})
    s3:Divider()
    s3:Label("animation:")
    reg(s3, "StylePicker", "session.style", {Text="style", Default="flow",
        Callback=function(v) SessionConfig.style = v; applySessionGradients() end})
    reg(s3, "Slider", "session.speed", {Text="speed",
        Min=0, Max=3, Default=1,
        Callback=function(v) SessionConfig.speed = v end})
    s3:Divider()
    s3:Label("gradient on:")
    reg(s3, "Toggle", "session.gradTitle",  {Text="title",  Default=true,
        Callback=function(v) SessionConfig.gradTitle = v;  applySessionGradients() end})
    reg(s3, "Toggle", "session.gradKills",  {Text="kills",  Default=true,
        Callback=function(v) SessionConfig.gradKills = v;  applySessionGradients() end})
    reg(s3, "Toggle", "session.gradDeaths", {Text="deaths", Default=true,
        Callback=function(v) SessionConfig.gradDeaths = v; applySessionGradients() end})
    reg(s3, "Toggle", "session.gradTime",   {Text="time",   Default=true,
        Callback=function(v) SessionConfig.gradTime = v;   applySessionGradients() end})

    -- col 4: text
    s4:Label("text:")
    reg(s4, "TextBox", "session.titleText", {Placeholder="- session -",
        Text=SessionConfig.titleText,
        Callback=function(t)
            SessionConfig.titleText = t or "- session -"
            applySessionTitle()
        end})

    s4:Divider()
    s4:Label("transform:")
    reg(s4, "Slider", "session.scale", {Text="scale",
        Min=0.5, Max=3, Default=1,
        Callback=function(v)
            if _G.__PRIMO_SESSION_SET_SCALE then
                _G.__PRIMO_SESSION_SET_SCALE(v)
            end
        end})
    reg(s4, "Toggle", "session.LockDrag", {Text="lock position", Default=false,
        Callback=function(v) SessionConfig.LockDrag = v end})
    local initialFontIdx = 1
    for i, n in ipairs(FONT_NAMES) do if n == SessionConfig.font then initialFontIdx = i break end end
    reg(s4, "Cycle", "session.font", {Prefix="font: ", Values=FONT_NAMES, Index=initialFontIdx,
        Callback=function(v) SessionConfig.font = v; applySessionFont() end})
    reg(s4, "Slider", "session.textSize", {Text="text size",
        Min=8, Max=20, Default=SessionConfig.textSize,
        Callback=function(v) SessionConfig.textSize = v; applySessionTextSize() end})

    _G.__PRIMO_SESSION_TOGGLE_SETTINGS = function()
        if sessPopup.Visible then
            sessPopup.Visible = false
        else
            sessPopup.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
            sessPopup.Visible = true
            sessPopup.BackgroundTransparency = 0
        end
    end

    _G.__PRIMO_SESSION_SET_SCALE = function(s)
        s = math.clamp(tonumber(s) or 1, 0.5, 3.0)
        local us = SF:FindFirstChildOfClass("UIScale")
        if not us then
            us = Instance.new("UIScale"); us.Parent = SF
        end
        us.Scale = s
        Library.Settings.HUDScale = Library.Settings.HUDScale or {}
        Library.Settings.HUDScale.session = s
    end
    _G.__PRIMO_SESSION_GET_SCALE = function()
        local us = SF:FindFirstChildOfClass("UIScale")
        return us and us.Scale or 1
    end

    _G.__PRIMO_SESSION_DESTROY = function()
        pcall(function() sessAnimConn:Disconnect() end)
        if _sessDragChanged then pcall(function() _sessDragChanged:Disconnect() end) end
        if _sessDragEnded then pcall(function() _sessDragEnded:Disconnect() end) end
    end
end)
--===============================================================
-- TRASHTALK TAB
--===============================================================
do
    local ttTab = Window:CreateTab({
        Name="trashtalk", Horizontal = true, CanvasWidth = 850,
    })
    local TT = I.TrashTalk
    if not TT then
        -- безопасный fallback: не даём скрипту упасть, если экспорт по какой-то причине не сработал
        TT = {
            enabled = false, interval = 1.0, hidePrefix = false,
            prefix = "hysteria | ", phrases = {},
        }
        I.TrashTalk = TT
        if type(I.saveTrashTalk) ~= "function" then I.saveTrashTalk = function() end end
        if type(I.fireTrashTalk) ~= "function" then I.fireTrashTalk = function() end end
    end

    -- ── left : settings ─────────────────────────
    local setSect = ttTab:CreateSection({Title="- trashtalk -",
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,214,0,320)})
    setSect:Label("sends a random phrase on kill", 18)
    reg(setSect, "Toggle", "trashtalk.enabled", {Text="enable trashtalk",
        Default=TT.enabled, Callback=function(v)
            TT.enabled = v
            if not v then TT._pendingSend = nil end
            I.saveTrashTalk()
        end})
    reg(setSect, "Toggle", "trashtalk.hidePrefix", {Text="dont show cheat name",
        Default=TT.hidePrefix, Callback=function(v)
            TT.hidePrefix = v; I.saveTrashTalk()
        end})
    reg(setSect, "Toggle", "trashtalk.stripEmoji", {Text="strip emoji (по желанию)",
        Default=TT.stripEmoji, Callback=function(v)
            TT.stripEmoji = v; I.saveTrashTalk()
        end})
    reg(setSect, "NumberInput", "trashtalk.interval", {
        Text="interval (s)", Default=TT.interval, Placeholder="1.0",
        Min=0, Max=30,
        Callback=function(v) TT.interval = v; I.saveTrashTalk() end})
    setSect:Button({Text="test (send random now)", Callback=function()
        if I.fireTrashTalk then pcall(I.fireTrashTalk) end
    end})

    -- ── right : dictionary ──────────────────────
    local dictSect = ttTab:CreateSection({Title="- dictionary -",
        Position=UDim2.new(0,234,0,8), Size=UDim2.new(0,600,0,740)})
    dictSect:Label("add new phrase:", 16)

    -- add row (custom, side by side)
    local addRow = create("Frame", {Name="addRow", BackgroundTransparency=1,
        Size=UDim2.new(1,-24,0,30)}, dictSect.Frame)
    addRow.Position = UDim2.new(0, 12, 0, dictSect.Y)
    dictSect.Y = dictSect.Y + 36

    local addBox = create("TextBox", {Name="addBox", Text="",
        PlaceholderText="type a new taunt...",
        PlaceholderColor3=PALETTE.TextDim, TextSize=13, TextColor3=PALETTE.Text,
        FontFace=FONT_REGULAR, BackgroundColor3=PALETTE.Element,
        ClearTextOnFocus=false, TextXAlignment=Enum.TextXAlignment.Left,
        Size=UDim2.new(1,-40,1,0)}, addRow)
    corner(addBox, 7); addGlass(addBox, 0.4, PALETTE.ElementGlass)
    local addPad = Instance.new("UIPadding")
    addPad.PaddingLeft = UDim.new(0,10); addPad.PaddingRight = UDim.new(0,10)
    addPad.Parent = addBox

    local addBtn = create("TextButton", {Name="addBtn", AutoButtonColor=false,
        Text="+", TextSize=20, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
        BackgroundColor3=PALETTE.Element, Size=UDim2.new(0,34,1,0),
        Position=UDim2.new(1,-34,0,0)}, addRow)
    corner(addBtn, 7); addGlass(addBtn, 0.4, PALETTE.ElementGlass)
    addBtn.MouseEnter:Connect(function()
        tween(addBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.2})
    end)
    addBtn.MouseLeave:Connect(function()
        tween(addBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
    end)

    -- scroll
    local ttHolder = create("Frame", {Name="ttHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,600)}, dictSect.Frame)
    corner(ttHolder, 8)
    ttHolder.Position = UDim2.new(0, 12, 0, dictSect.Y)
    dictSect.Y = dictSect.Y + 600 + 8

    local ttScroll = create("ScrollingFrame", {Name="ttScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, ttHolder)
    local ttLayout = Instance.new("UIListLayout")
    ttLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ttLayout.Padding = UDim.new(0,5)
    ttLayout.Parent = ttScroll
    local ttPad = Instance.new("UIPadding")
    ttPad.PaddingTop = UDim.new(0,6); ttPad.PaddingBottom = UDim.new(0,6)
    ttPad.PaddingLeft = UDim.new(0,6); ttPad.PaddingRight = UDim.new(0,6)
    ttPad.Parent = ttScroll

    local function refreshTT()
        for _, ch in ipairs(ttScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= ttLayout then ch:Destroy() end
        end
        if #TT.phrases == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="dictionary is empty", TextSize=12, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,40), LayoutOrder=1}, ttScroll)
            return
        end
        for i, p in ipairs(TT.phrases) do
            local text, on = p[1], p[2] ~= false
            local row = create("Frame", {Name="tt_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,32), LayoutOrder=i}, ttScroll)
            corner(row, 6)

            -- eye toggle (left)
            local eye = create("TextButton", {Name="eye", AutoButtonColor=false,
                Text=on and "◉" or "○", TextSize=16,
                TextColor3=on and Library.Settings.AccentColor or PALETTE.TextDim,
                FontFace=FONT_BOLD, BackgroundTransparency=1,
                Size=UDim2.new(0,26,1,0), Position=UDim2.new(0,2,0,0)}, row)
            eye.MouseButton1Click:Connect(function()
                TT.phrases[i][2] = not (TT.phrases[i][2] ~= false)
                I.saveTrashTalk()
                refreshTT()
            end)

            -- text
            create("TextLabel", {Name="txt", BackgroundTransparency=1,
                Text=text, TextSize=12,
                TextColor3=on and PALETTE.Text or PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
                TextWrapped=false, TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,30,0,0)}, row)

            -- delete
            local del = create("TextButton", {Name="del", AutoButtonColor=false,
                Text="x", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.5,
                Size=UDim2.new(0,26,1,-6), Position=UDim2.new(1,-30,0,3)}, row)
            corner(del, 5)
            del.MouseButton1Click:Connect(function()
                table.remove(TT.phrases, i)
                I.saveTrashTalk()
                refreshTT()
            end)
        end
    end


    -- ❗ FIX: addPhrase не был объявлен → клик по "+" падал
    local function addPhrase()
        local t = addBox.Text
        if not t then return end
        t = t:gsub("^%s+", ""):gsub("%s+$", "")
        if t == "" then return end
        -- авто-добавление префикса, чтобы фраза соответствовала формату
        local pre = TT.prefix or ""
        if pre ~= "" and t:sub(1, #pre) ~= pre then
            t = pre .. t
        end
        table.insert(TT.phrases, { t, true })
        if I.saveTrashTalk then pcall(I.saveTrashTalk) end
        addBox.Text = ""
        refreshTT()
    end

    addBtn.MouseButton1Click:Connect(addPhrase)
    addBox.FocusLost:Connect(function(enter)
        if enter then addPhrase() end
    end)

    refreshTT()

    -- ── FIX: safely ensure set functions exist ──
    if type(I.saveTrashTalkSet)   ~= "function" then I.saveTrashTalkSet   = function() return false, "no fs" end end
    if type(I.loadTrashTalkSet)   ~= "function" then I.loadTrashTalkSet   = function() return false, "no fs" end end
    if type(I.listTrashTalkSets)  ~= "function" then I.listTrashTalkSets  = function() return {} end end
    if type(I.deleteTrashTalkSet) ~= "function" then I.deleteTrashTalkSet = function() return false end end

    -- ═══════════════════════════════════════════════════════════
    -- PHRASE SETS  —  отдельные конфиги с наборами фраз
    -- ═══════════════════════════════════════════════════════════
    local setsSect = ttTab:CreateSection({Title="- phrase sets -",
        Position=UDim2.new(0,8,0,336), Size=UDim2.new(0,214,0,600)})
    setsSect:Label("save / load phrase collections:", 16)

    local setNameBox = setsSect:TextBox({
        Placeholder = "set name...",
        Text = "",
    })
    local setsStatus = setsSect:Label("no set selected", 14)

    local setsHolder = create("Frame", {Name="setsHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,340)}, setsSect.Frame)
    corner(setsHolder, 8)
    setsHolder.Position = UDim2.new(0, 12, 0, setsSect.Y)
    setsSect.Y = setsSect.Y + 340 + 8

    local setsScroll = create("ScrollingFrame", {Name="setsScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, setsHolder)
    local setsLayout = Instance.new("UIListLayout")
    setsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    setsLayout.Padding = UDim.new(0,4)
    setsLayout.Parent = setsScroll
    local setsPad = Instance.new("UIPadding")
    setsPad.PaddingTop = UDim.new(0,4); setsPad.PaddingBottom = UDim.new(0,4)
    setsPad.PaddingLeft = UDim.new(0,4); setsPad.PaddingRight = UDim.new(0,4)
    setsPad.Parent = setsScroll

    local refreshSetsList
    refreshSetsList = function()
        for _, ch in ipairs(setsScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= setsLayout then ch:Destroy() end
        end
        local names = I.listTrashTalkSets and I.listTrashTalkSets() or {}
        if #names == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="no sets yet", TextSize=11, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,30), LayoutOrder=1}, setsScroll)
            return
        end
        for i, name in ipairs(names) do
            local row = create("Frame", {Name="set_"..i,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,28), LayoutOrder=i}, setsScroll)
            corner(row, 5)
            -- name (click = pick)
            local nameBtn = create("TextButton", {Name="nameBtn", AutoButtonColor=false,
                Text=name, TextSize=11, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-72,1,0), Position=UDim2.new(0,4,0,0)}, row)
            nameBtn.MouseButton1Click:Connect(function()
                setNameBox:Set(name, true)
                setsStatus.Text = "selected: "..name
            end)
            -- LOAD (replace current phrases)
            local loadBtn = create("TextButton", {Name="loadBtn", AutoButtonColor=false,
                Text="L", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,26,1,-6), Position=UDim2.new(1,-60,0,3)}, row)
            corner(loadBtn, 4)
            loadBtn.MouseEnter:Connect(function()
                tween(loadBtn, {BackgroundColor3=Library.Settings.AccentColor, BackgroundTransparency=0.3})
            end)
            loadBtn.MouseLeave:Connect(function()
                tween(loadBtn, {BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4})
            end)
            loadBtn.MouseButton1Click:Connect(function()
                local ok, phrases = I.loadTrashTalkSet(name)
                if ok and type(phrases) == "table" then
                    TT.phrases = phrases
                    I.saveTrashTalk()
                    refreshTT()
                    setsStatus.Text = "loaded: "..name
                    pcall(function() Library:NotifySuccess("trashtalk set loaded", name) end)
                else
                    setsStatus.Text = "load failed: "..tostring(phrases)
                    pcall(function() Library:NotifyError("trashtalk load failed", tostring(phrases)) end)
                end
            end)
            -- APPEND (add to current instead of replace)
            local appendBtn = create("TextButton", {Name="appendBtn", AutoButtonColor=false,
                Text="+", TextSize=12, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,22,1,-6), Position=UDim2.new(1,-34,0,3)}, row)
            corner(appendBtn, 4)
            appendBtn.MouseEnter:Connect(function()
                tween(appendBtn, {BackgroundColor3=Library.Settings.AccentColor, BackgroundTransparency=0.3})
            end)
            appendBtn.MouseLeave:Connect(function()
                tween(appendBtn, {BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4})
            end)
            appendBtn.MouseButton1Click:Connect(function()
                local ok, phrases = I.loadTrashTalkSet(name)
                if ok and type(phrases) == "table" then
                    for _, p in ipairs(phrases) do
                        table.insert(TT.phrases, p)
                    end
                    I.saveTrashTalk()
                    refreshTT()
                    setsStatus.Text = "appended: "..name
                else
                    setsStatus.Text = "append failed"
                end
            end)
            -- DELETE
            local delBtn = create("TextButton", {Name="delBtn", AutoButtonColor=false,
                Text="x", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.5,
                Size=UDim2.new(0,22,1,-6), Position=UDim2.new(1,-12,0,3)}, row)
            corner(delBtn, 4)
            delBtn.MouseButton1Click:Connect(function()
                I.deleteTrashTalkSet(name)
                setsStatus.Text = "deleted: "..name
                refreshSetsList()
            end)
        end
    end
    refreshSetsList()

    setsSect:ConfirmButton({
        Text = "save current as new set",
        Warning = "save set? (?)",
        Callback = function()
            local n = setNameBox:Get()
            if not n or n == "" then
                setsStatus.Text = "enter a name"
                return
            end
            local ok, res = I.saveTrashTalkSet(n, TT.phrases)
            if ok then
                setNameBox:Set("", true)
                refreshSetsList()
                setsStatus.Text = "saved: "..tostring(res)
                pcall(function() Library:NotifySuccess("trashtalk set saved", tostring(res)) end)
            else
                setsStatus.Text = "failed: "..tostring(res)
                pcall(function() Library:NotifyError("save failed", tostring(res)) end)
            end
        end
    })

    setsSect:Button({Text="refresh list", Callback=function()
        refreshSetsList()
        setsStatus.Text = "list refreshed"
    end})

    setsSect:ConfirmButton({Text="apply default phrases",
        Warning="wipe yours & load defaults? (?)",
        Callback=function()
            TT.phrases = ttDefaults and ttDefaults() or TT.phrases
            I.saveTrashTalk()
            refreshTT()
            setsStatus.Text = "defaults restored"
        end})

    -- register into config system (so the dictionary is saved per-config too)
    local CONTROLS = _G.__PRIMO_CONTROLS
    if CONTROLS then
        CONTROLS["trashtalk"] = {
            Get = function(self)
                return { TT.enabled and 1 or 0, TT.interval,
                    TT.hidePrefix and 1 or 0, TT.phrases }
            end,
            Set = function(self, v, silent)
                if type(v) ~= "table" then return end
                TT.enabled = v[1] == 1
                TT.interval = tonumber(v[2]) or 1.0
                TT.hidePrefix = v[3] == 1
                if type(v[4]) == "table" then
                    local list = {}
                    for i, p in ipairs(v[4]) do
                        if type(p) == "table" and type(p[1]) == "string" then
                            list[i] = { p[1], p[2] ~= false }
                        end
                    end
                    if #list > 0 then TT.phrases = list end
                end
                I.saveTrashTalk()
                refreshTT()
            end,
        }
    end
end

--===============================================================
-- SETTINGS TAB
--===============================================================
do
    local settingsTab = Window:CreateTab({
        Name="settings", Title="- settings -",
        Horizontal = true, CanvasWidth = 1250,
    })

    local accentSect = settingsTab:CreateSection({Title="- accent color -",
        Position=UDim2.new(0,8,0,8), Size=UDim2.new(0,214,0,570)})
    accentSect:Label("pick accent color:")
    local accentPicker = reg(accentSect, "ColorPicker", "ui.accentColor", {Text="accent color",
        GetInitialColor=function() return Library.Settings.AccentColor end,
        Callback=function(color)
            -- ручной выбор отключает градиент, иначе он перетрёт выбор
            local ag = Library.Settings.AccentGradient
            if ag and ag.enabled then
                ag.enabled = false
                local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["accent.gradientEnabled"]
                if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
            end
            Library:SetAccentColor(color)
        end})
    accentSect:Label("presets:")
    accentSect:Swatches({Columns=6, Gap=5, Size=22,
        Colors={
            -- тёплые
            Color3.fromRGB(255,200,160), Color3.fromRGB(255,180,190),
            Color3.fromRGB(255,220,150), Color3.fromRGB(255,160,120),
            Color3.fromRGB(255,100,100), Color3.fromRGB(255,60,140),
            -- холодные
            Color3.fromRGB(180,220,255), Color3.fromRGB(140,200,255),
            Color3.fromRGB(180,240,200), Color3.fromRGB(140,255,180),
            Color3.fromRGB(100,220,220), Color3.fromRGB(180,180,255),
            -- фиолет
            Color3.fromRGB(220,190,255), Color3.fromRGB(180,140,255),
            Color3.fromRGB(140,100,240), Color3.fromRGB(200,120,255),
            Color3.fromRGB(255,120,220), Color3.fromRGB(255,60,220),
            -- нейтралы
            Color3.fromRGB(230,230,235), Color3.fromRGB(200,200,210),
            Color3.fromRGB(170,170,180), Color3.fromRGB(140,140,150),
            Color3.fromRGB(100,100,110), Color3.fromRGB(60,60,70),
            -- пастель
            Color3.fromRGB(255,240,180), Color3.fromRGB(240,255,200),
            Color3.fromRGB(200,240,240), Color3.fromRGB(240,200,240),
            Color3.fromRGB(255,220,200), Color3.fromRGB(220,220,240),
        },
        Callback=function(color)
            local ag = Library.Settings.AccentGradient
            if ag and ag.enabled then
                ag.enabled = false
                local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["accent.gradientEnabled"]
                if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
            end
            Library:SetAccentColor(color)
            if accentPicker then accentPicker:Set(color, true) end
        end})
    accentSect:Button({Text="reset to default",
        Callback=function()
            Library:SetAccentColor(Color3.fromRGB(255,200,160))
            if accentPicker then accentPicker:Set(Color3.fromRGB(255,200,160), true) end
        end})

    -- ── accent gradient ──
    do
        local AG = Library.Settings.AccentGradient or {
            enabled = false,
            colorA  = Color3.fromRGB(255,200,160),
            colorB  = Color3.fromRGB(140,200,255),
            speed   = 1,
            style   = "flow",
        }
        Library.Settings.AccentGradient = AG

        local agPhase = 0
        local agAccum = 0
        local agTickRate = 1/25   -- 25 Hz — плавно + не грузит CPU
        if _G.__PRIMO_ACCENT_GRAD_CONN then
            pcall(function() _G.__PRIMO_ACCENT_GRAD_CONN:Disconnect() end)
        end
        _G.__PRIMO_ACCENT_GRAD_CONN = RunService.Heartbeat:Connect(function(dt)
            if not AG.enabled then return end
            agAccum = agAccum + dt
            if agAccum < agTickRate then return end
            local step = agAccum
            agAccum = 0
            local style = AG.style
            local speed = AG.speed
            local c
            if style == "sweep" then
                -- hue rotation
                agPhase = (agPhase + step * speed * 0.15) % 1
                c = Color3.fromHSV(agPhase, 0.75, 1)
            elseif style == "pulse" then
                agPhase = (agPhase + step * speed * 0.6) % 1
                local k = (math.sin(agPhase * math.pi * 2) + 1) * 0.5
                c = AG.colorA:Lerp(AG.colorB, k)
            elseif style == "wave" then
                agPhase = (agPhase + step * speed * 0.25) % 1
                local k = (math.sin(agPhase * math.pi * 2) + 1) * 0.5
                c = AG.colorA:Lerp(AG.colorB, k)
            else -- flow
                agPhase = (agPhase + step * speed * 0.35) % 1
                local k = (math.sin(agPhase * math.pi * 2) + 1) * 0.5
                c = AG.colorA:Lerp(AG.colorB, k)
            end
            Library.Settings.AccentColor = c
            refreshAccent()
        end)

        accentSect:Divider()
        accentSect:Label("gradient:")
        reg(accentSect, "Toggle", "accent.gradientEnabled", {
            Text="enable accent gradient", Default=AG.enabled,
            Callback=function(v) AG.enabled = v end})
        reg(accentSect, "ColorPicker", "accent.gradientColorA", {
            Text="color a", GetInitialColor=function() return AG.colorA end,
            Callback=function(c) AG.colorA = c end})
        reg(accentSect, "ColorPicker", "accent.gradientColorB", {
            Text="color b", GetInitialColor=function() return AG.colorB end,
            Callback=function(c) AG.colorB = c end})
        reg(accentSect, "StylePicker", "accent.gradientStyle", {
            Text="style", Default=AG.style,
            Callback=function(v) AG.style = v end})
        reg(accentSect, "Slider", "accent.gradientSpeed", {
            Text="speed", Min=0, Max=3, Default=AG.speed,
            Callback=function(v) AG.speed = v end})
    end

    local scaleSect = settingsTab:CreateSection({Title="- menu -",
        Position=UDim2.new(0,8,0,586), Size=UDim2.new(0,214,0,260)})
    reg(scaleSect, "Slider", "ui.menuScale", {Text="menu scale",
        Min=0.5, Max=2.0, Default=1.0,
        Callback=function(v)
            Library.Settings.MenuScale = v
            if Window and Window.SetScale then Window:SetScale(v) end
        end})
    reg(scaleSect, "Slider", "ui.menuOpacity", {Text="menu opacity",
        Min=0.3, Max=1.0, Default=1.0,
        Callback=function(v)
            if Window and Window.SetOpacity then Window:SetOpacity(v) end
        end})

    scaleSect:Divider()
    scaleSect:Label("auto-fit to resolution:", 18)

    -- ❗ кнопки-пресеты: скейл меню под типичные высоты экрана.
    -- Базовый дизайн меню — под 1080p, поэтому scale = height / 1080
    local RESOLUTION_PRESETS = {
        { label = "720p",  h = 720  },
        { label = "900p",  h = 900  },
        { label = "1080p", h = 1080 },
        { label = "1440p", h = 1440 },
        { label = "4K",    h = 2160 },
    }
    local function applyMenuScale(v)
        if Window and Window.SetScale then Window:SetScale(v) end
        Library.Settings.MenuScale = v
        local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.menuScale"]
        if c and c.Set then pcall(function() c:Set(v, true) end) end
    end
    for _, p in ipairs(RESOLUTION_PRESETS) do
        scaleSect:Button({Text = p.label, Callback = function()
            applyMenuScale(p.h / 1080)
        end})
    end
    scaleSect:Button({Text="auto (current screen)", Callback=function()
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        if not vp then return end
        applyMenuScale(vp.Y / 1080)
    end})
    scaleSect:Label("auto = current viewport height / 1080", 16)

    scaleSect:Divider()
    scaleSect:Label("menu toggle key:", 18)
    reg(scaleSect, "BindInput", "ui.menuKey", {
        Text="toggle key",
        Default=Library.Settings.MenuKey,
        Callback=function(bind)
            if bind then
                Library.Settings.MenuKey = bind
            end
        end,
    })
    scaleSect:Label("right click to reset to Insert", 16)

    -- ─── HUD / SCREEN SECTION — checkboxes now guaranteed to work ───
 local screenSect = settingsTab:CreateSection({Title="- hud / screens -",
    Position=UDim2.new(0,8,0,880), Size=UDim2.new(0,214,0,560)})

local rows = {}
rows.wm = reg(screenSect, "CheckGearRow", "hud.watermark", {Text="watermark", Default=true,
    Callback=function(v)
        if Window.Watermark then Window.Watermark:SetEnabled(v) end
    end,
    GearCallback=function()
        if Window.Watermark and rows.wm and rows.wm.Gear then
            Window.Watermark:ToggleSettings(rows.wm.Gear)
        end
    end})

rows.kb = reg(screenSect, "CheckGearRow", "hud.keybinds", {Text="keybinds list", Default=true,
    Callback=function(v)
        if Window.Keybinds then Window.Keybinds:SetEnabled(v) end
    end,
    GearCallback=function()
        if Window.Keybinds and rows.kb and rows.kb.Gear then
            Window.Keybinds:ToggleSettings(rows.kb.Gear)
        end
    end})

rows.te = reg(screenSect, "CheckGearRow", "hud.targetlist", {Text="target list", Default=true,
    Callback=function(v)
        if Window.TargetList then Window.TargetList:SetEnabled(v) end
    end,
    GearCallback=function()
        if Window.TargetList and rows.te and rows.te.Gear then
            Window.TargetList:ToggleSettings(rows.te.Gear)
        end
    end})
-- scoreboard удалён

rows.cl = reg(screenSect, "CheckGearRow", "hud.chatleaker", {Text="chat leaker", Default=true,
    Callback=function(v)
        if _G.__PRIMO_CHATLEAKER_SET_ENABLED then
            _G.__PRIMO_CHATLEAKER_SET_ENABLED(v)
        end
    end,
    GearCallback=function()
        if _G.__PRIMO_CL_TOGGLE_SETTINGS and rows.cl and rows.cl.Gear then
            pcall(_G.__PRIMO_CL_TOGGLE_SETTINGS, rows.cl.Gear)
        end
    end})
rows.sess = reg(screenSect, "CheckGearRow", "hud.session", {Text="session", Default=true,
    Callback=function(v)
        if _G.__PRIMO_SESSION_FRAME then _G.__PRIMO_SESSION_FRAME.Visible = v end
    end,
    GearCallback=function()
        if _G.__PRIMO_SESSION_TOGGLE_SETTINGS then
            pcall(_G.__PRIMO_SESSION_TOGGLE_SETTINGS)
        end
    end})

rows.pic = reg(screenSect, "CheckGearRow", "hud.picture", {Text="picture", Default=true,
    Callback=function(v)
        if Window.Picture then Window.Picture:SetEnabled(v) end
    end,
    GearCallback=function()
        if Window.Picture and rows.pic and rows.pic.Gear then
            Window.Picture:ToggleSettings(rows.pic.Gear)
        end
    end})

screenSect.Frame.Size = UDim2.new(0, 214, 0, 600)

screenSect:Label("HUD windows on right side.", 22)
screenSect:Label("toggle to hide/show each.", 22)
screenSect:Divider()
screenSect:Label("- scale -", 18)

reg(screenSect, "Slider", "hud.scale.watermark", {
    Text="watermark", Min=0.5, Max=3, Default=1,
    Callback=function(v)
        if Window.Watermark and Window.Watermark.SetScale then
            Window.Watermark:SetScale(v)
        end
    end})
reg(screenSect, "Slider", "hud.scale.keybinds", {
    Text="keybinds", Min=0.5, Max=3, Default=1,
    Callback=function(v)
        if Window.Keybinds and Window.Keybinds.SetScale then
            Window.Keybinds:SetScale(v)
        end
    end})
reg(screenSect, "Slider", "hud.scale.targetesp", {
    Text="target esp", Min=0.5, Max=3, Default=1,
    Callback=function(v)
        if Window.TargetList and Window.TargetList.SetScale then
            Window.TargetList:SetScale(v)
        end
    end})
reg(screenSect, "Slider", "hud.scale.session", {
    Text="session", Min=0.5, Max=3, Default=1,
    Callback=function(v)
        if _G.__PRIMO_SESSION_SET_SCALE then
            _G.__PRIMO_SESSION_SET_SCALE(v)
        end
    end})
reg(screenSect, "Slider", "hud.scale.picture", {
    Text="picture", Min=0.2, Max=5, Default=1,
    Callback=function(v)
        if Window.Picture and Window.Picture.SetScale then
            Window.Picture:SetScale(v)
        end
    end})

    -- ─── CONFIG SYSTEM SECTION ───
    local cfgSect = settingsTab:CreateSection({Title="- configs -",
        Position=UDim2.new(0,234,0,8), Size=UDim2.new(0,260,0,740)})
    local cfgName = ""
    local cfgStatusLabel
    local refreshConfigList

    local nameBox = cfgSect:TextBox({Placeholder="config name...", Text="",
        Callback=function(t) cfgName = t or "" end})

    cfgSect:ConfirmButton({Text="save current as new",
        Warning="save? (?)",
        Callback=function()
            if cfgName == "" then
                if cfgStatusLabel then cfgStatusLabel.Text = "enter a name" end
                return
            end
            local ok, reason = ConfigSystem:Save(cfgName)
            if ok then
                if cfgStatusLabel then cfgStatusLabel.Text = "saved: "..tostring(reason) end
                pcall(function() Library:NotifySuccess("config saved", tostring(reason)) end)
            else
                if cfgStatusLabel then cfgStatusLabel.Text = "save failed: "..tostring(reason) end
                pcall(function() Library:NotifyError("save failed", tostring(reason)) end)
            end
            if refreshConfigList then refreshConfigList() end
        end})
    cfgSect:ConfirmButton({Text="override current",
        Warning="override? (?)",
        Callback=function()
            local ok = ConfigSystem:Override()
            if cfgStatusLabel then
                cfgStatusLabel.Text = ok and ("overwrote: "..(ConfigSystem.Current or "?")) or "no current"
            end
        end})
    cfgSect:Button({Text="refresh list", Callback=function()
        ConfigSystem:Refresh()
        if refreshConfigList then refreshConfigList() end
        if cfgStatusLabel then cfgStatusLabel.Text = "list refreshed" end
    end})
    cfgSect:ConfirmButton({Text="save as current name",
        Warning="save? (?)",
        Callback=function()
            if cfgName ~= "" then
                ConfigSystem:Save(cfgName)
                if refreshConfigList then refreshConfigList() end
                if cfgStatusLabel then cfgStatusLabel.Text = "saved as: "..cfgName end
            end
        end})
    cfgSect:ConfirmButton({Text="reset settings to defaults",
        Warning="reset ALL settings? (?)",
        Callback=function()
            local count = 0
            if _G.__PRIMO_RESET_DEFAULTS then
                count = _G.__PRIMO_RESET_DEFAULTS() or 0
            end
            if cfgStatusLabel then
                cfgStatusLabel.Text = "reset "..count.." controls"
            end
            pcall(function() Library:NotifySuccess("settings reset", count.." controls") end)
        end})

    cfgSect:ConfirmButton({Text="reset config settings",
        Warning="reset all to defaults? (?)",
        Callback=function()
            local count = 0
            if _G.__PRIMO_RESET_DEFAULTS then
                count = _G.__PRIMO_RESET_DEFAULTS() or 0
            end
            if cfgStatusLabel then
                cfgStatusLabel.Text = "reset "..count.." controls"
            end
        end})

    cfgSect:ConfirmButton({Text="delete all configs",
        Warning="r u sure? wipe ALL? (?)",
        Callback=function()
            ConfigSystem:DeleteAll(true)
            if refreshConfigList then refreshConfigList() end
            if cfgStatusLabel then cfgStatusLabel.Text = "all configs deleted" end
        end})
    cfgStatusLabel = cfgSect:Label("no config selected")

    local listHolder = create("Frame", {Name="configListHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,380)}, cfgSect.Frame)
    corner(listHolder, 8)
    listHolder.Position = UDim2.new(0, 12, 0, cfgSect.Y)
    cfgSect.Y = cfgSect.Y + 380 + 8

    local cfgScroll = create("ScrollingFrame", {Name="cfgScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, listHolder)
    local cfgLayout = Instance.new("UIListLayout")
    cfgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cfgLayout.Padding = UDim.new(0,6)
    cfgLayout.Parent = cfgScroll
    local cfgPad = Instance.new("UIPadding")
    cfgPad.PaddingTop = UDim.new(0,6)
    cfgPad.PaddingBottom = UDim.new(0,6)
    cfgPad.PaddingLeft = UDim.new(0,6)
    cfgPad.PaddingRight = UDim.new(0,6)
    cfgPad.Parent = cfgScroll

    refreshConfigList = function()
        for _, ch in ipairs(cfgScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= cfgLayout then ch:Destroy() end
        end
        local names = ConfigSystem:List()
        if #names == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="no configs yet", TextSize=12, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,40), LayoutOrder=1}, cfgScroll)
            return
        end
        for i, name in ipairs(names) do
            local row = create("Frame", {Name="cfg_"..name,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,36), LayoutOrder=i}, cfgScroll)
            corner(row, 6)
            local nameBtn = create("TextButton", {Name="nameBtn", AutoButtonColor=false,
                Text=name, TextSize=12, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-120,1,0), Position=UDim2.new(0,8,0,0)}, row)
            nameBtn.MouseButton1Click:Connect(function()
                cfgName = name
                nameBox:Set(name, true)
                if cfgStatusLabel then cfgStatusLabel.Text = "selected: "..name end
            end)
            local loadBtn = create("TextButton", {Name="loadBtn", AutoButtonColor=false,
                Text="load", TextSize=10, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,36,1,-8), Position=UDim2.new(1,-112,0,4)}, row)
            corner(loadBtn, 5)
            local loadConfirming = false
            local loadTask = nil
            local loadRemain = 3
            loadBtn.MouseButton1Click:Connect(function()
                if loadConfirming then
                    -- второй клик — выполняем
                    loadConfirming = false
                    if loadTask then pcall(function() task.cancel(loadTask) end); loadTask = nil end
                    loadBtn.Text = "load"
                    loadBtn.TextColor3 = PALETTE.Text
                    local ok = ConfigSystem:Load(name)
                    if cfgStatusLabel then
                        cfgStatusLabel.Text = ok and ("loaded: "..name) or "load failed"
                    end
                    return
                end
                -- первый клик — enter confirm
                loadConfirming = true
                loadRemain = 3
                loadBtn.TextColor3 = PALETTE.Warn
                local function render() loadBtn.Text = "sure? "..loadRemain end
                render()
                loadTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        loadRemain = loadRemain - 1
                        if loadRemain < 1 then break end
                        render()
                    end
                    if loadConfirming then
                        loadConfirming = false
                        loadBtn.Text = "load"
                        loadBtn.TextColor3 = PALETTE.Text
                    end
                    loadTask = nil
                end)
            end)
            local saveBtn = create("TextButton", {Name="saveBtn", AutoButtonColor=false,
                Text="save", TextSize=10, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,36,1,-8), Position=UDim2.new(1,-72,0,4)}, row)
            corner(saveBtn, 5)
            local saveConfirming = false
            local saveTask = nil
            local saveRemain = 3
            saveBtn.MouseButton1Click:Connect(function()
                if saveConfirming then
                    saveConfirming = false
                    if saveTask then pcall(function() task.cancel(saveTask) end); saveTask = nil end
                    saveBtn.Text = "save"
                    saveBtn.TextColor3 = PALETTE.Text
                    ConfigSystem:Save(name)
                    if cfgStatusLabel then cfgStatusLabel.Text = "overwrote: "..name end
                    refreshConfigList()
                    return
                end
                saveConfirming = true
                saveRemain = 3
                saveBtn.TextColor3 = PALETTE.Warn
                local function render() saveBtn.Text = "sure? "..saveRemain end
                render()
                saveTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        saveRemain = saveRemain - 1
                        if saveRemain < 1 then break end
                        render()
                    end
                    if saveConfirming then
                        saveConfirming = false
                        saveBtn.Text = "save"
                        saveBtn.TextColor3 = PALETTE.Text
                    end
                    saveTask = nil
                end)
            end)
            local delBtn = create("TextButton", {Name="delBtn", AutoButtonColor=false,
                Text="x", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.5,
                Size=UDim2.new(0,28,1,-8), Position=UDim2.new(1,-32,0,4)}, row)
            corner(delBtn, 5)
            local delConfirming = false
            local delTask = nil
            local delRemain = 3
            delBtn.MouseButton1Click:Connect(function()
                if delConfirming then
                    delConfirming = false
                    if delTask then pcall(function() task.cancel(delTask) end); delTask = nil end
                    delBtn.Text = "x"
                    delBtn.TextColor3 = PALETTE.Text
                    ConfigSystem:Delete(name)
                    if cfgStatusLabel then cfgStatusLabel.Text = "deleted: "..name end
                    refreshConfigList()
                    return
                end
                delConfirming = true
                delRemain = 3
                delBtn.TextColor3 = Color3.new(1,1,1)
                local function render() delBtn.Text = delRemain end
                render()
                delTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        delRemain = delRemain - 1
                        if delRemain < 1 then break end
                        render()
                    end
                    if delConfirming then
                        delConfirming = false
                        delBtn.Text = "x"
                        delBtn.TextColor3 = PALETTE.Text
                    end
                    delTask = nil
                end)
            end)
        end
    end
    refreshConfigList()

    local panicSect = settingsTab:CreateSection({Title="- panic -",
        Position=UDim2.new(0,516,0,8), Size=UDim2.new(0,214,0,368)})
    panicSect:Label("emergency controls")
    panicSect:Button({Text="full unload", Callback=function()
        pcall(function()
            game:GetService("RunService"):UnbindFromRenderStep("Primo_AimStep")
        end)
        -- ❗ 1) закрываем меню ПЕРВЫМ → восстановит камеру/курсор корректно
        if Window and Window.SetMenuVisible then
            pcall(function() Window.SetMenuVisible(false) end)
        end
        -- ❗ 2) страховка: принудительный сброс курсора/шифтлока
        pcall(function()
            local UIS = game:GetService("UserInputService")
            UIS.MouseBehavior    = Enum.MouseBehavior.Default
            UIS.MouseIconEnabled = true
        end)
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            if lp and lp.DevEnableMouseLock ~= nil then
                lp.DevEnableMouseLock = true
            end
        end)
        if I.World then
            I.World.fullbright = false
            I.World.fogEnabled = false
            I.World.atmoEnabled = false
            I.World.skyOverride = false
            I.World.sunRaysEnabled = false
            I.World.bloomEnabled = false
            I.World.ccEnabled = false
            I.World.blurEnabled = false
            I.World.dofEnabled = false
        end
        pcall(function()
            local L = game:GetService("Lighting")
            for _, cls in ipairs({"SunRaysEffect","BloomEffect","ColorCorrectionEffect","BlurEffect","DepthOfFieldEffect"}) do
                local e = L:FindFirstChildOfClass(cls)
                if e then e.Enabled = false end
            end
        end)
        pcall(function()
            local L = game:GetService("Lighting")
            if I.WORLD_STATE and I.WORLD_STATE.fogAtmoRef and I.WORLD_STATE.fogAtmoSaved then
                local a = I.WORLD_STATE.fogAtmoRef
                if a and a.Parent then
                    a.Density = I.WORLD_STATE.fogAtmoSaved.Density
                    a.Haze = I.WORLD_STATE.fogAtmoSaved.Haze
                    a.Glare = I.WORLD_STATE.fogAtmoSaved.Glare
                end
            end
        end)
        pcall(I.restoreWorldOriginals)
        if I.restoreSkyColor then pcall(I.restoreSkyColor) end
        pcall(function()
            local L = game:GetService("Lighting")
            for _, name in ipairs({"SunRaysEffect","BloomEffect","ColorCorrectionEffect","BlurEffect","DepthOfFieldEffect"}) do
                local e = L:FindFirstChildOfClass(name)
                if e then e:Destroy() end
            end
        end)
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            pcall(I.destroyDrawings, p)
            pcall(I.clearLocalChams, p)
        end
        pcall(I.destroyHitmarkers)
        pcall(I.resetAllHitboxes)
        if I.silentAimUninstallHook then pcall(I.silentAimUninstallHook) end
        if I.stopFly then pcall(I.stopFly) end
        if I.stopAura then pcall(I.stopAura) end
        if I.disableLoopSpeed then pcall(I.disableLoopSpeed) end
        if I.disableLoopJumpPower then pcall(I.disableLoopJumpPower) end
        if I.Autostop and I.Autostop._active then
            local lp = game:GetService("Players").LocalPlayer
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if I.Autostop._savedWS then pcall(function() hum.WalkSpeed = I.Autostop._savedWS end) end
                if I.Autostop._savedJP then pcall(function() hum.JumpPower = I.Autostop._savedJP end) end
            end
            I.Autostop._active = false
            I.Autostop._savedWS = nil
            I.Autostop._savedJP = nil
            I.Autostop._releaseAt = nil
        end
        if _G.__PRIMO_FORCE_CAM_CONN then
            pcall(function() _G.__PRIMO_FORCE_CAM_CONN:Disconnect() end)
            _G.__PRIMO_FORCE_CAM_CONN = nil
        end
        if _G.__PRIMO_CURSOR_WATCHDOG then
            pcall(function() _G.__PRIMO_CURSOR_WATCHDOG:Disconnect() end)
            _G.__PRIMO_CURSOR_WATCHDOG = nil
        end
        if I._untrackAll then pcall(I._untrackAll) end
        if I.hitboxOriginals then
            for p in pairs(I.hitboxOriginals) do I.hitboxOriginals[p] = nil end
        end
        if I.PERF_STATE and I.PERF_STATE.active then pcall(I.exitLowPerf) end
        if I.Aimbot and I.Aimbot._fov then
            pcall(function() I.Aimbot._fov:Remove() end)
            I.Aimbot._fov = nil
        end
        for _, s in ipairs(I.Hitsound.pool or {}) do pcall(function() s:Destroy() end) end
        for _, s in ipairs(I.KillSound.pool or {}) do pcall(function() s:Destroy() end) end
        if Window then
            if Window.Watermark and Window.Watermark.Destroy then pcall(Window.Watermark.Destroy, Window.Watermark) end
            if Window.Keybinds and Window.Keybinds.Destroy then pcall(Window.Keybinds.Destroy, Window.Keybinds) end
            if Window.TargetList and Window.TargetList.Destroy then pcall(Window.TargetList.Destroy, Window.TargetList) end
        end
        local PlayerGuiRef = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGuiRef then
            for _, name in ipairs({
                "primo","primo_popups","watermark","keybinds","TargetESP","primo_session",
                "primo_chatleaker","primo_tp_toast","primo_picture",
            }) do
                local g = PlayerGuiRef:FindFirstChild(name)
                if g then g:Destroy() end
            end
        end
        -- останавливаем CL loop
        if _G.__PRIMO_CL_DESTROY then
            pcall(_G.__PRIMO_CL_DESTROY); _G.__PRIMO_CL_DESTROY = nil
        end
        _G.__PRIMO_CHATLEAKER_SET_ENABLED = nil
        _G.__HYSTERIA_CL_POS = nil
        _G.__HYSTERIA_WM_POS = nil
        _G.__HYSTERIA_KB_POS = nil
        _G.__HYSTERIA_TL_POS = nil
        _G.__HYSTERIA_SESS_POS = nil
        -- sweep только СВОИХ объектов (без CoreGui — он триггерит UIBlox warning
        -- и на многих экзекуторах запрещён)
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj and obj.Parent and type(obj.Name) == "string"
                    and obj.Name:sub(1, 15) == "primo_internal_" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
        pcall(function()
            local SS = game:GetService("SoundService")
            for _, obj in ipairs(SS:GetChildren()) do
                if type(obj.Name) == "string"
                    and obj.Name:sub(1, 15) == "primo_internal_" then
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
        -- sweep всех ScreenGui с префиксом primo_ / hysteria_
        local function _sweepGui(container)
            if not container then return end
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("ScreenGui") then
                    local n = obj.Name
                    if n == "primo" or n == "primo_popups"
                       or n == "primo_session"
                       or n == "primo_chatleaker" or n == "primo_tp_toast"
                       or n == "primo_picture"
                       or n == "watermark" or n == "keybinds" or n == "TargetESP" then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
        _sweepGui(PlayerGuiRef)
        if _G.__PRIMO_WORLD_TASK then
            pcall(function() task.cancel(_G.__PRIMO_WORLD_TASK) end)
            _G.__PRIMO_WORLD_TASK = nil
        end
        -- disconnect all global connections
        for _, name in ipairs({
            "__PRIMO_PlayerAddedConn", "__PRIMO_PlayerRemovingConn",
            "__PRIMO_CharAddedConn", "__PRIMO_CamChangedConn",
            "__PRIMO_SteppedConn", "__PRIMO_HeartbeatConn",
            "__PRIMO_RenderConn", "__PRIMO_InputBeganConn",
            "__PRIMO_InputEndedConn", "__PRIMO_MenuConn",
            "__PRIMO_PROFILE_GRAD_CONN", "__PRIMO_ACCENT_GRAD_CONN",
            "__PRIMO_TEAMS_ADDED_CONN", "__PRIMO_TEAMS_REMOVED_CONN",
            "__PRIMO_FORCE_CAM_CONN", "__PRIMO_CURSOR_WATCHDOG",
        }) do
            local c = _G[name]
            if c then
                pcall(function() c:Disconnect() end)
                _G[name] = nil
            end
        end
        -- UIS-коннекты, зарегистрированные через cwTrack в CreateWindow
        if _G.__PRIMO_CW_CONNS then
            for _, cc in ipairs(_G.__PRIMO_CW_CONNS) do
                pcall(function() cc:Disconnect() end)
            end
            _G.__PRIMO_CW_CONNS = nil
        end
        if Window and Window._menuInputConns then
            for _, cc in ipairs(Window._menuInputConns) do
                pcall(function() cc:Disconnect() end)
            end
            Window._menuInputConns = nil
        end
        _G.__PRIMO_BIND_LISTENING = false
        if PlayerGuiRef then
            local ps = PlayerGuiRef:FindFirstChild("primo_session")
            if ps then ps:Destroy() end
        end
        if Window and Window.SetMenuVisible then Window.SetMenuVisible(false) end
        if Library and Library._clearAccentBindings then
            pcall(Library._clearAccentBindings)
        end
        if _G.__PRIMO_CONTROLS then
            _G.__PRIMO_CONTROLS = nil
        end
        Window = nil
        targetESPHolder = nil
        _G.PRIMO_INTERNAL = nil
        _G.__PRIMO_SESSION_FRAME = nil
        _G.__PRIMO_SESSION_REFRESH = nil
        _G.__PRIMO_SESSION_TOGGLE_SETTINGS = nil
        if _G.__PRIMO_SESSION_TASK then
            pcall(function() task.cancel(_G.__PRIMO_SESSION_TASK) end)
            _G.__PRIMO_SESSION_TASK = nil
        end
        if _G.__PRIMO_SESSION_DESTROY then
            pcall(_G.__PRIMO_SESSION_DESTROY)
            _G.__PRIMO_SESSION_DESTROY = nil
        end
        _G.refreshWL = nil
        _G.refreshTeamWL = nil
        _G.refreshTargetList = nil
        _G.buildTeamEmptyPlaceholder = nil
        _G.PRIMO_TARGETS = nil
        _G.PRIMO_TARGET = nil
        _G.__HYSTERIA_WM_POS = nil
        _G.__HYSTERIA_KB_POS = nil
        _G.__HYSTERIA_TL_POS = nil
        _G.__HYSTERIA_TL_PREVIEW_OFFSET = nil
        _G.__HYSTERIA_SESS_POS = nil
        _G.__HYSTERIA_PIC_POS = nil
        _G.__PRIMO_SESSION_SET_SCALE = nil
        _G.__PRIMO_SESSION_GET_SCALE = nil
        _G.__PRIMO_WM_ACCUM = nil
        _G.__PRIMO_NOCLIP_ACCUM = nil
        _G.__PRIMO_HitboxAccum = nil
        _G.__PRIMO_HEALTH_ACCUM = nil
        _G.__PRIMO_AIMFIRE_LOGGED = nil
        _G.__LAST_TARGET_PLAYER = nil
        _G.__PRIMO_SELFCHAMS_CACHE = nil
        _G.__PRIMO_POSTLOAD = nil
        _G.__PRIMO_APPLY_PROFILE_GRAD = nil
        _G.__PRIMO_TEAMS_ADDED_CONN = nil
        _G.__PRIMO_TEAMS_REMOVED_CONN = nil
        _G.__PRIMO_CW_CONNS = nil
        _G.__PRIMO_ACCENT_GRAD_CONN = nil
        _G.__PRIMO_PROFILE_GRAD_CONN = nil
        _G.__PRIMO_OPEN_AVATAR_BROWSER = nil
        _G.__PRIMO_APPLY_AVATAR_PRESET = nil
        _G.__PRIMO_APPLY_MENU_FONT = nil
        _G.__PRIMO_MENU_MOUSE_UPDATE = nil
        _G.__PRIMO_MENU_OPEN = nil
        _G.__PRIMO_HARD_TP = nil
        _G.__PRIMO_AMBIENT = nil
        _G.__PRIMO_AMBIENT_COLOR = nil
        _G.__PRIMO_AMBIENT_INTENSITY = nil
        _G.__PRIMO_AUTOSHOOT = nil
        _G.__PRIMO_CONTROLS = nil
        if Library and Library._ambientGlows then
            for _, api in ipairs(Library._ambientGlows) do
                pcall(function() if api.Destroy then api:Destroy() end end)
            end
            Library._ambientGlows = {}
        end
    end})

    panicSect:Button({Text="reset world visuals", Callback=function()
        -- restore nametags
        if I.Misc then I.Misc.hideNametags = false end
        if I.applyNametagsHide then pcall(I.applyNametagsHide) end
        local W = I.World
        W.fullbright = false
        W.atmoEnabled = false
        W.skyOverride = false
        W.skyColorEnabled = false
        W.fogEnabled = false
        if I.restoreSkyColor then pcall(I.restoreSkyColor) end
        W.sunRaysEnabled = false
        W.bloomEnabled = false
        W.ccEnabled = false
        W.blurEnabled = false
        W.dofEnabled = false
        W.brightness      = I.LightingBrightnessOrig or W.brightness
        W.ambient         = I.LightingAmbientOrig   or W.ambient
        W.outdoorAmbient  = I.LightingOutdoorOrig   or W.outdoorAmbient
        W.clockTime       = I.LightingClockOrig     or W.clockTime
        W.exposure        = I.LightingExposureOrig  or W.exposure
        W.globalShadows   = I.LightingShadowsOrig   or W.globalShadows
        W.envDiffuse      = I.LightingEnvDiffOrig   or W.envDiffuse
        W.envSpecular     = I.LightingEnvSpecOrig   or W.envSpecular
        W.fogColor = I.LightingFogColorOrig or W.fogColor
        W.fogStart = I.LightingFogStartOrig or W.fogStart
        W.fogEnd   = I.LightingFogEndOrig   or W.fogEnd
        W.bloomIntensity = 0.5; W.bloomSize = 24; W.bloomThreshold = 1.5
        W.ccBrightness = 0; W.ccContrast = 0; W.ccSaturation = 0
        W.ccTintColor = Color3.new(1,1,1)
        W.blurSize = 4
        W.atmoColor = Color3.fromRGB(199,199,199); W.atmoDecay = Color3.fromRGB(106,112,125)
        W.atmoDensity = 0.3; W.atmoHaze = 0; W.atmoGlare = 0; W.atmoOffset = 0
        W.skyStarCount = 3000; W.skyMoonSize = 11; W.skySunSize = 21; W.skyCelestial = true
        W.sunRaysIntensity = 0.1; W.sunRaysSpread = 1
        W.dofFar = 0; W.dofFocus = 0; W.dofInRadius = 0; W.dofNear = 0
        pcall(I.restoreWorldOriginals)
        pcall(I.clearSelfChams)
    end})

    panicSect:Button({Text="reset hud resolutions", Callback=function()
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local function resetHUD(screenName, frameName, pos)
            local sc = pg:FindFirstChild(screenName)
            if not sc then return end
            local fr = sc:FindFirstChild(frameName)
            if fr then fr.Position = pos end
        end
        local wmP  = UDim2.new(0.61156, 0, 0.02713, 0)
        local kbP  = UDim2.new(0.61156, 0, 0.02713, 40)
        local tlP  = UDim2.new(0.56035, 0, 0.44636, 0)
        local seP  = UDim2.new(0.56035, 0, 0.54636, 0)
        resetHUD("watermark",     "Main", wmP)
        resetHUD("keybinds",      "Main", kbP)
        resetHUD("TargetESP",     "Main", tlP)
        resetHUD("primo_session", "Main", seP)
        _G.__HYSTERIA_WM_POS   = wmP
        _G.__HYSTERIA_KB_POS   = kbP
        _G.__HYSTERIA_TL_POS   = tlP
        _G.__HYSTERIA_SESS_POS = seP
    end})

    panicSect:Button({Text="reset menu scale", Callback=function()
        Library.Settings.MenuScale = 1.0
        if Window and Window.SetScale then Window:SetScale(1.0) end
        local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.menuScale"]
        if c and c.Set then pcall(function() c:Set(1.0, true) end) end
    end})

    panicSect:Divider()

    panicSect:Button({Text="rejoin (same server)", Callback=function()
        local TS = game:GetService("TeleportService")
        local LP = game:GetService("Players").LocalPlayer
        task.spawn(function()
            pcall(function()
                local opts = Instance.new("TeleportOptions")
                opts.ServerInstanceId = game.JobId
                TS:TeleportAsync(game.PlaceId, {LP}, opts)
            end)
        end)
    end})

    panicSect:Button({Text="server hop", Callback=function()
        local TS = game:GetService("TeleportService")
        local LP = game:GetService("Players").LocalPlayer
        task.spawn(function()
            local hopped = false
            pcall(function()
                local req = request or http_request or (syn and syn.request)
                if type(req) == "function" then
                    local r = req({
                        Url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100",
                        Method = "GET",
                    })
                    if r and r.Body then
                        local Http = game:GetService("HttpService")
                        local dec = Http:JSONDecode(r.Body)
                        if dec and dec.data then
                            for _, srv in ipairs(dec.data) do
                                if srv.id and srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 100) then
                                    local opts = Instance.new("TeleportOptions")
                                    opts.ServerInstanceId = srv.id
                                    TS:TeleportAsync(game.PlaceId, {LP}, opts)
                                    hopped = true
                                    break
                                end
                            end
                        end
                    end
                end
            end)
            if not hopped then
                pcall(function()
                    TS:Teleport(game.PlaceId, LP)
                end)
            end
        end)
    end})

    panicSect:Button({Text="sleep (disconnect)", Callback=function()
        local LP = game:GetService("Players").LocalPlayer
        pcall(function() LP:Kick("hysteria: gn bitch") end)
    end})

    local infoSect = settingsTab:CreateSection({Title="- cheat info -",
        Position=UDim2.new(0,516,0,384), Size=UDim2.new(0,214,0,250)})
    infoSect:Label("• developer: t.me/hy5teria", 20)
    infoSect:Label("• last update: 1 oct 2026", 20)
    infoSect:Label(" ", 3)
    infoSect:Label("• socials link guns.lol/8un", 20)
    infoSect:Label("• send bugs to @hy5teria in telegram ", 36)
    infoSect:Label(" ", 3)
    infoSect:Label("• vavava nya meow meoww meow nya :3", 20)

    -- ─── MENU APPEARANCE (theme + font + corner + shadow) ───
    local themeSect = settingsTab:CreateSection({Title="- menu appearance -",
        Position=UDim2.new(0,750,0,8), Size=UDim2.new(0,240,0,1700)})
    local _themeVals = {"dark","light","glass","pastel"}
    local _themeIdx = 1
    for i, n in ipairs(_themeVals) do
        if n == (Library.Settings.Theme or "dark") then _themeIdx = i break end
    end
    reg(themeSect, "Cycle", "ui.menuTheme", {
        Prefix="theme: ",
        Values=_themeVals,
        Index=_themeIdx,
        Callback=function(v)
            Library:SetTheme(v)
        end
    })
    themeSect:Divider()
    themeSect:Label("- menu layout style -", 18)
    local _styleVals = {"classic","experimental"}
    local _styleIdx = 1
    for i, n in ipairs(_styleVals) do
        if n == (Library.Settings.MenuStyle or "classic") then _styleIdx = i break end
    end
    reg(themeSect, "Cycle", "ui.menuStyle", {
        Prefix="style: ",
        Values=_styleVals,
        Index=_styleIdx,
        Callback=function(v)
            if Window and Window.SetMenuStyle then
                pcall(function() Window:SetMenuStyle(v) end)
            end
        end,
    })
    themeSect:Divider()
    themeSect:Label("- menu font -", 18)
    local _fontIdx = 1
    for i, n in ipairs(FONT_NAMES) do
        if n == (Library.Settings.MenuFont or "arial") then _fontIdx = i break end
    end
    local _fontCycle = reg(themeSect, "Cycle", "ui.menuFont", {
        Prefix = "font: ",
        Values = FONT_NAMES,
        Index = _fontIdx,
        Callback = function(v)
            Library.Settings.MenuFont = v
            if _G.__PRIMO_APPLY_MENU_FONT then
                pcall(_G.__PRIMO_APPLY_MENU_FONT, v)
            end
        end,
    })

    -- RAW-контрол: гарантирует что значение сохраняется даже если Cycle
    -- не находит совпадение по регистру/whitespace
    do
        local CONTROLS = _G.__PRIMO_CONTROLS
        if CONTROLS then
            CONTROLS["ui.menuFont.raw"] = {
                Get = function(self)
                    return Library.Settings.MenuFont or "arial"
                end,
                Set = function(self, v, silent)
                    if type(v) ~= "string" or v == "" then return end
                    -- нормализация: trim + lowercase
                    v = v:gsub("^%s+", ""):gsub("%s+$", ""):lower()
                    -- проверим что такой шрифт есть
                    local found = false
                    for _, n in ipairs(FONT_NAMES) do
                        if n:lower() == v then found = true; v = n; break end
                    end
                    if not found then return end
                    Library.Settings.MenuFont = v
                    -- синхронизируем Cycle визуально
                    if _fontCycle and _fontCycle.Set then
                        pcall(function() _fontCycle:Set(v, true) end)
                    end
                    if _G.__PRIMO_APPLY_MENU_FONT then
                        pcall(_G.__PRIMO_APPLY_MENU_FONT, v)
                    end
                end,
            }
        end
    end
    themeSect:Divider()
    themeSect:Label("- menu shape -", 18)
    reg(themeSect, "Slider", "ui.menuCornerRadius", {
        Text = "menu corner radius",
        Min = 0, Max = 30, Default = 12,
        Callback = function(v)
            Library.Settings.MenuCornerRadius = v
            if Window and Window.Frame then
                local c = Window.Frame:FindFirstChildOfClass("UICorner")
                if c then c.CornerRadius = UDim.new(0, v) end
            end
        end,
    })
     themeSect:Divider()
    themeSect:Divider()
    themeSect:Label("- ambient glow -", 18)
    reg(themeSect, "Toggle", "ui.ambientEnabled", {
        Text = "enable ambient glow",
        Default = (Library.Settings.AmbientEnabled == true),
        Callback = function(v)
            if Library.SetAmbientEnabled then Library.SetAmbientEnabled(v) end
        end,
    })
    reg(themeSect, "Toggle", "ui.ambientUseAccent", {
        Text = "use accent color",
        Default = (Library.Settings.AmbientUseAccent ~= false),
        Callback = function(v)
            Library.Settings.AmbientUseAccent = v
            if Library.SetAmbientColor then
                if v then
                    Library.SetAmbientColor(nil)
                else
                    Library.SetAmbientColor(Library.Settings.AmbientColor or Color3.fromRGB(255,200,160))
                end
            end
        end,
    })
    reg(themeSect, "ColorPicker", "ui.ambientColor", {
        Text = "custom color",
        GetInitialColor = function()
            return Library.Settings.AmbientColor or Library.Settings.AccentColor
        end,
        Callback = function(c)
            Library.Settings.AmbientColor = c
            Library.Settings.AmbientUseAccent = false
            local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.ambientUseAccent"]
            if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
            if Library.SetAmbientColor then Library.SetAmbientColor(c) end
        end,
    })
    reg(themeSect, "Slider", "ui.ambientIntensity", {
        Text = "intensity", Min = 0.3, Max = 3, Default = 1,
        Callback = function(v)
            if Library.SetAmbientIntensity then Library.SetAmbientIntensity(v) end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- INDIVIDUAL AMBIENT GROUPS (avatar / menu image)
    -- ═══════════════════════════════════════════════════════════
    local function buildAmbientGroupUI(groupName, label)
        local G = Library.Settings.AmbientGroups[groupName]

        themeSect:Divider()
        themeSect:Label("- " .. label .. " glow -", 18)

        reg(themeSect, "Toggle", "ui.ambGrp."..groupName..".enabled", {
            Text = "enabled", Default = G.enabled,
            Callback = function(v)
                G.enabled = v
                for _, api in ipairs(Library._ambientGlows) do
                    if api._group == groupName then
                        pcall(function() api:SetEnabled(v) end)
                    end
                end
            end,
        })
        reg(themeSect, "Toggle", "ui.ambGrp."..groupName..".useAccent", {
            Text = "use accent color", Default = G.useAccent,
            Callback = function(v)
                G.useAccent = v
                if v then
                    for _, api in ipairs(Library._ambientGlows) do
                        if api._group == groupName then
                            pcall(function() api:SetColor(Library.Settings.AccentColor) end)
                        end
                    end
                else
                    Library.RebuildAmbientGlows()
                end
            end,
        })
        reg(themeSect, "ColorPicker", "ui.ambGrp."..groupName..".color", {
            Text = "custom color",
            GetInitialColor = function() return G.color or Library.Settings.AccentColor end,
            Callback = function(c)
                G.color = c
                G.useAccent = false
                local cc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.ambGrp."..groupName..".useAccent"]
                if cc and cc.Set then pcall(function() cc:Set(false, true) end) end
                for _, api in ipairs(Library._ambientGlows) do
                    if api._group == groupName then
                        pcall(function() api:SetColor(c) end)
                    end
                end
            end,
        })
        reg(themeSect, "Slider", "ui.ambGrp."..groupName..".intensity", {
            Text = "intensity", Min = 0.2, Max = 3, Default = G.intensity,
            Callback = function(v) G.intensity = v; Library.RebuildAmbientGlows() end,
        })
        reg(themeSect, "Slider", "ui.ambGrp."..groupName..".spread", {
            Text = "size", Min = 0.3, Max = 3, Default = G.spread,
            Callback = function(v) G.spread = v; Library.RebuildAmbientGlows() end,
        })
        reg(themeSect, "Slider", "ui.ambGrp."..groupName..".layers", {
            Text = "smoothness (layers)", Min = 2, Max = 10, Default = G.layers,
            Callback = function(v)
                G.layers = math.floor(v)
                Library.RebuildAmbientGlows()
            end,
        })
        reg(themeSect, "Cycle", "ui.ambGrp."..groupName..".shape", {
            Prefix = "shape: ",
            Values = {"circle","square","rounded","diamond","hexagon","star","pill","frame"},
            Index = 1,
            Callback = function(v) G.shape = v; Library.RebuildAmbientGlows() end,
        })
    end

    buildAmbientGroupUI("avatar", "avatar")
    buildAmbientGroupUI("menu", "menu image")

    themeSect:Divider()
    themeSect:Button({Text="reset ALL ambient", Callback=function()
        for name, G in pairs(Library.Settings.AmbientGroups) do
            G.enabled = false
            G.useAccent = true
            G.color = nil
            G.intensity = 1
            G.spread = 1
            G.layers = 4
            G.shape = "circle"
            local cc = _G.__PRIMO_CONTROLS
            if cc then
                local e = cc["ui.ambGrp."..name..".enabled"]; if e and e.Set then pcall(function() e:Set(false,true) end) end
                local u = cc["ui.ambGrp."..name..".useAccent"]; if u and u.Set then pcall(function() u:Set(true,true) end) end
                local i = cc["ui.ambGrp."..name..".intensity"]; if i and i.Set then pcall(function() i:Set(1,true) end) end
                local s = cc["ui.ambGrp."..name..".spread"]; if s and s.Set then pcall(function() s:Set(1,true) end) end
                local l = cc["ui.ambGrp."..name..".layers"]; if l and l.Set then pcall(function() l:Set(4,true) end) end
                local sh = cc["ui.ambGrp."..name..".shape"]; if sh and sh.Set then pcall(function() sh:Set("circle",true) end) end
            end
        end
        Library.RebuildAmbientGlows()
    end})
    -- ═══════════════════════════════════════════════════════════
    -- CUSTOM THEMES  —  файлы-конфиги + скроллируемый лист как у configs
    --   primo_configs/themes/<name>.json
    -- ═══════════════════════════════════════════════════════════
    -- custom themes переехала под configs (X=234) — раньше висела в самом низу column 4
    local customThemeSect = settingsTab:CreateSection({Title="- custom themes -",
        Position=UDim2.new(0,234,0,760), Size=UDim2.new(0,260,0,740)})

    -- ── 12 палитровых ключей ──
    local PAL_KEYS = {
        {key="Window",       label="window bg"},
        {key="WindowGlass",  label="window glass"},
        {key="Panel",        label="panel bg"},
        {key="PanelGlass",   label="panel glass"},
        {key="Element",      label="element bg"},
        {key="ElementHi",    label="element highlight"},
        {key="ElementGlass", label="element glass"},
        {key="Text",         label="text"},
        {key="TextDim",      label="text dim"},
        {key="Shadow",       label="shadow"},
        {key="Warn",         label="warning"},
        {key="Ok",           label="ok"},
    }

    customThemeSect:Label("edit palette colors:", 18)

    local _pickers = {}

    -- ❗ все 12 color picker'ов живут в отдельном попапе "palette editor",
    -- чтобы не есть 400+ пикселей высоты в основной секции custom themes
    local paletteEditorPopup, _palGui = makePopupFrame(
        "palette_editor_popup", "- palette editor -", 340, 560)
    paletteEditorPopup.Visible = false
    paletteEditorPopup.ZIndex = 30

    -- крестик
    do
        local x = create("TextButton", {Name="__close", AutoButtonColor=false,
            Text="×", TextSize=20, TextColor3=PALETTE.TextDim, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.5,
            Size=UDim2.new(0,22,0,20), Position=UDim2.new(1,-26,0,3),
            ZIndex=61}, paletteEditorPopup)
        corner(x, 5)
        x.MouseEnter:Connect(function()
            tween(x, {TextColor3=PALETTE.Warn, BackgroundTransparency=0.15})
        end)
        x.MouseLeave:Connect(function()
            tween(x, {TextColor3=PALETTE.TextDim, BackgroundTransparency=0.5})
        end)
        x.MouseButton1Click:Connect(function() paletteEditorPopup.Visible = false end)
    end

    local palScroll = create("ScrollingFrame", {Name="palList",
        BackgroundTransparency=1,
        Size=UDim2.new(1,-24,1,-40),
        Position=UDim2.new(0,12,0,32),
        BorderSizePixel=0, ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
        ScrollingDirection=Enum.ScrollingDirection.Y}, paletteEditorPopup)
    local palSection = setmetatable({Frame=palScroll, Y=0}, Section)

    for _, entry in ipairs(PAL_KEYS) do
        local key = entry.key
        local ctrl = reg(palSection, "ColorPicker", "ui.pal."..key, {
            Text = entry.label,
            GetInitialColor = function()
                return PALETTE[key] or Library.Settings.AccentColor
            end,
            Callback = function(c)
                Library:SetPaletteColor(key, c)
            end,
        })
        if ctrl then _pickers[key] = ctrl end
    end

    customThemeSect:Button({Text="open color editor",
        Callback=function()
            -- sync pickers с текущей палитрой (могла поменяться через Load theme)
            for _, entry in ipairs(PAL_KEYS) do
                local p = _pickers[entry.key]
                if p and p.Set then
                    local c = PALETTE[entry.key]
                    if typeof(c) == "Color3" then
                        pcall(function() p:Set(c, true) end)
                    end
                end
            end
            paletteEditorPopup.Position = UDim2.new(0.5, -170, 0.5, -280)
            paletteEditorPopup.Visible = true
            paletteEditorPopup.BackgroundTransparency = 0
        end})
    customThemeSect:Label("12 палитровых цветов в отдельном окне", 16)

    local function syncPickers()
        for _, entry in ipairs(PAL_KEYS) do
            local p = _pickers[entry.key]
            if p and p.Set then
                local c = PALETTE[entry.key]
                if typeof(c) == "Color3" then
                    pcall(function() p:Set(c, true) end)
                end
            end
        end
    end

    customThemeSect:Divider()
    customThemeSect:Label("save / load / delete themes:", 18)

    local ctNameBox = customThemeSect:TextBox({
        Placeholder = "theme name...",
        Text = "",
    })
    local ctStatus = customThemeSect:Label("no theme selected", 16)

    -- ── список файлов-тем (как у configs) ──
    local ctListHolder = create("Frame", {Name="themeListHolder",
        BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
        Size=UDim2.new(1,-24,0,340)}, customThemeSect.Frame)
    corner(ctListHolder, 8)
    ctListHolder.Position = UDim2.new(0, 12, 0, customThemeSect.Y)
    customThemeSect.Y = customThemeSect.Y + 340 + 8

    local ctScroll = create("ScrollingFrame", {Name="ctScroll",
        BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
        Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
        ScrollBarImageColor3=Library.Settings.AccentColor,
        ScrollBarImageTransparency=0.4,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        BorderSizePixel=0,
        ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, ctListHolder)
    local ctLayout = Instance.new("UIListLayout")
    ctLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ctLayout.Padding = UDim.new(0,6)
    ctLayout.Parent = ctScroll
    local ctPad = Instance.new("UIPadding")
    ctPad.PaddingTop = UDim.new(0,6);   ctPad.PaddingBottom = UDim.new(0,6)
    ctPad.PaddingLeft = UDim.new(0,6);  ctPad.PaddingRight = UDim.new(0,6)
    ctPad.Parent = ctScroll

    local refreshCtList
    refreshCtList = function()
        for _, ch in ipairs(ctScroll:GetChildren()) do
            if ch:IsA("GuiObject") and ch ~= ctLayout then ch:Destroy() end
        end
        local names = Library:ListCustomThemes()
        if #names == 0 then
            create("TextLabel", {Name="empty", BackgroundTransparency=1,
                Text="no themes yet", TextSize=12, TextColor3=PALETTE.TextDim,
                FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                Size=UDim2.new(1,0,0,40), LayoutOrder=1}, ctScroll)
            return
        end

        for i, name in ipairs(names) do
            local row = create("Frame", {Name="ct_"..name,
                BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,32), LayoutOrder=i}, ctScroll)
            corner(row, 6)

            -- имя (клик = выбрать)
            local nameBtn = create("TextButton", {Name="nameBtn", AutoButtonColor=false,
                Text=name, TextSize=11, TextColor3=PALETTE.Text,
                FontFace=FONT_BOLD, BackgroundTransparency=1,
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,6,0,0)}, row)
            nameBtn.MouseButton1Click:Connect(function()
                ctNameBox:Set(name, true)
                if ctStatus then ctStatus.Text = "selected: "..name end
            end)

            -- LOAD (с 3-сек подтверждением)
            local loadBtn = create("TextButton", {Name="loadBtn", AutoButtonColor=false,
                Text="load", TextSize=10, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,36,1,-8), Position=UDim2.new(1,-102,0,4)}, row)
            corner(loadBtn, 5)
            local loadConfirming, loadTask, loadRemain = false, nil, 3
            loadBtn.MouseButton1Click:Connect(function()
                if loadConfirming then
                    loadConfirming = false
                    if loadTask then pcall(function() task.cancel(loadTask) end); loadTask = nil end
                    loadBtn.Text = "load"; loadBtn.TextColor3 = PALETTE.Text
                    local ok = Library:LoadCustomTheme(name)
                    if ok then
                        syncPickers()
                        if ctStatus then ctStatus.Text = "loaded: "..name end
                    else
                        if ctStatus then ctStatus.Text = "load failed" end
                    end
                    return
                end
                loadConfirming = true; loadRemain = 3
                loadBtn.TextColor3 = PALETTE.Warn
                local function render() loadBtn.Text = "sure? "..loadRemain end
                render()
                loadTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        loadRemain = loadRemain - 1
                        if loadRemain < 1 then break end
                        render()
                    end
                    if loadConfirming then
                        loadConfirming = false
                        loadBtn.Text = "load"; loadBtn.TextColor3 = PALETTE.Text
                    end
                    loadTask = nil
                end)
            end)

            -- SAVE / OVERWRITE
            local saveBtn = create("TextButton", {Name="saveBtn", AutoButtonColor=false,
                Text="save", TextSize=10, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,36,1,-8), Position=UDim2.new(1,-62,0,4)}, row)
            corner(saveBtn, 5)
            local saveConfirming, saveTask, saveRemain = false, nil, 3
            saveBtn.MouseButton1Click:Connect(function()
                if saveConfirming then
                    saveConfirming = false
                    if saveTask then pcall(function() task.cancel(saveTask) end); saveTask = nil end
                    saveBtn.Text = "save"; saveBtn.TextColor3 = PALETTE.Text
                    local ok = Library:SaveCustomTheme(name)
                    if ok then
                        if ctStatus then ctStatus.Text = "overwrote: "..name end
                    else
                        if ctStatus then ctStatus.Text = "save failed" end
                    end
                    return
                end
                saveConfirming = true; saveRemain = 3
                saveBtn.TextColor3 = PALETTE.Warn
                local function render() saveBtn.Text = "sure? "..saveRemain end
                render()
                saveTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        saveRemain = saveRemain - 1
                        if saveRemain < 1 then break end
                        render()
                    end
                    if saveConfirming then
                        saveConfirming = false
                        saveBtn.Text = "save"; saveBtn.TextColor3 = PALETTE.Text
                    end
                    saveTask = nil
                end)
            end)

            -- DELETE
            local delBtn = create("TextButton", {Name="delBtn", AutoButtonColor=false,
                Text="x", TextSize=11, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Warn, BackgroundTransparency=0.5,
                Size=UDim2.new(0,26,1,-8), Position=UDim2.new(1,-28,0,4)}, row)
            corner(delBtn, 5)
            local delConfirming, delTask, delRemain = false, nil, 3
            delBtn.MouseButton1Click:Connect(function()
                if delConfirming then
                    delConfirming = false
                    if delTask then pcall(function() task.cancel(delTask) end); delTask = nil end
                    delBtn.Text = "x"; delBtn.TextColor3 = PALETTE.Text
                    Library:DeleteCustomTheme(name)
                    if ctStatus then ctStatus.Text = "deleted: "..name end
                    refreshCtList()
                    return
                end
                delConfirming = true; delRemain = 3
                delBtn.TextColor3 = Color3.new(1,1,1)
                local function render() delBtn.Text = delRemain end
                render()
                delTask = task.spawn(function()
                    for _ = 1, 3 do
                        task.wait(1)
                        delRemain = delRemain - 1
                        if delRemain < 1 then break end
                        render()
                    end
                    if delConfirming then
                        delConfirming = false
                        delBtn.Text = "x"; delBtn.TextColor3 = PALETTE.Text
                    end
                    delTask = nil
                end)
            end)
        end
    end
    refreshCtList()

    -- ── кнопки управления ──
    customThemeSect:ConfirmButton({
        Text = "save current palette as new",
        Warning = "save theme? (?)",
        Callback = function()
            local n = ctNameBox:Get()
            if not n or n == "" then
                if ctStatus then ctStatus.Text = "enter a name" end
                return
            end
            local ok, res = Library:SaveCustomTheme(n)
            if ok then
                ctNameBox:Set("", true)
                refreshCtList()
                if ctStatus then ctStatus.Text = "saved: "..tostring(res) end
                pcall(function() Library:NotifySuccess("theme saved", tostring(res)) end)
            else
                if ctStatus then ctStatus.Text = "failed: "..tostring(res) end
                pcall(function() Library:NotifyError("theme save failed", tostring(res)) end)
            end
        end
    })

    customThemeSect:Button({Text="refresh list", Callback=function()
        refreshCtList()
        if ctStatus then ctStatus.Text = "list refreshed" end
    end})

    customThemeSect:Button({Text="reset palette to base theme", Callback=function()
        local t = Library:GetTheme()
        if t and Library.SetTheme then Library:SetTheme(t) end
        syncPickers()
        if ctStatus then ctStatus.Text = "reset to "..tostring(t) end
    end})

    -- ═══════════════════════════════════════════════════════════
    -- + USER PREFERENCES  (avatar browser + per-field gradient)
    -- ═══════════════════════════════════════════════════════════
    do
    local UPSect = settingsTab:CreateSection({Title="+ user preferences",
        Position=UDim2.new(0,1000,0,8), Size=UDim2.new(0,240,0,1200)})

        -- ── avatar presets (папки + пин) ──
        -- icon у pinned-элементов: rbxassetid://7355274001
        local PIN_ICON = "rbxassetid://82008729089381"

        local AVATAR_GROUPS = {
            {
                name = "pinned",
                isPinned = true,
                items = {
                    { name = "default",           url = "rbxassetid://1615907559" },
                    { name = "player avatar",     url = "rbxthumb://type=AvatarHeadShot&id="
                                                       .. tostring(LocalPlayer.UserId) .. "&w=150&h=150" },
                    { name = "hysteria logo",     url = "rbxassetid://304489727" },
                    { name = "hysteria banner",   url = "rbxassetid://12150333118" },
                    { name = "furry femboy",      url = "rbxassetid://106158288148110" },
                    { name = "aspirine",          url = "rbxassetid://125404550221755" },
                    { name = "aspirine transparent", url = "rbxassetid://98491322897003" },
                },
            },
            {
                name = "dima twin",
                items = {
                    { name = "dima twin 1", url = "rbxassetid://110165141362804" },
                    { name = "dima twin 2", url = "rbxassetid://84335861136344" },
                    { name = "dima twin 3", url = "rbxassetid://85204562327105" },
                },
            },
            {
                name = "mimi typh",
                items = {
                    { name = "mimi typh 1", url = "rbxassetid://138729523360924" },
                    { name = "mimi typh 2", url = "rbxassetid://84759293823704" },
                    { name = "mimi typh 3", url = "rbxassetid://111363611359675" },
                    { name = "mimi typh 4", url = "rbxassetid://132986177369877" },
                    { name = "mimi typh 5", url = "rbxassetid://17729606031" },
                    { name = "mimi typh 6", url = "rbxassetid://119614254076477" },
                },
            },
            {
                name = "floppa",
                items = {
                    { name = "floppa 1",  url = "rbxassetid://7184835629" },
                    { name = "floppa 2",  url = "rbxassetid://7436293165" },
                    { name = "floppa 3",  url = "rbxassetid://6782393070" },
                    { name = "floppa 4",  url = "rbxassetid://9985082572" },
                    { name = "floppa 5",  url = "rbxassetid://6568460777" },
                    { name = "floppa 6",  url = "rbxassetid://7506753605" },
                    { name = "floppa 7",  url = "rbxassetid://9913176030" },
                    { name = "floppa 8",  url = "rbxassetid://9764700770" },
                    { name = "floppa 9",  url = "rbxassetid://6837646267" },
                    { name = "floppa 10", url = "rbxassetid://9966657816" },
                    { name = "floppa 11", url = "rbxassetid://9567394854" },
                    { name = "floppa 12", url = "rbxassetid://9755401875" },
                    { name = "floppa 13", url = "rbxassetid://11928176251" },
                    { name = "floppa 14", url = "rbxassetid://6303853182" },
                    { name = "floppa 15", url = "rbxassetid://9512628767" },
                },
            },
            {
                name = "el gato",
                items = {
                    { name = "el gato 1", url = "rbxassetid://10185836151" },
                    { name = "el gato 2", url = "rbxassetid://10153623424" },
                    { name = "el gato 3", url = "rbxassetid://9684906276" },
                    { name = "el gato 4", url = "rbxassetid://9722323269" },
                    { name = "el gato 5", url = "rbxassetid://10332407461" },
                },
            },
            {
                name = "cat",
                items = {
                    { name = "cat 1", url = "rbxassetid://9896044884" },
                    { name = "cat 2", url = "rbxassetid://13447686141" },
                    { name = "cat 3", url = "rbxassetid://133025255930097" },
                    { name = "cat 4", url = "rbxassetid://18928254034" },
                    { name = "cat 5", url = "rbxassetid://70509481945808" },
                },
            },
            {
                name = "boykisser",
                items = {
                    { name = "boykisser 1", url = "rbxassetid://110482195453919" },
                    { name = "boykisser 2", url = "rbxassetid://17529062315" },
                    { name = "boykisser 3", url = "rbxassetid://13463406477" },
                    { name = "boykisser 4", url = "rbxassetid://13061157395" },
                },
            },
            {
                name = "furry",
                items = {
                    { name = "furry 1",              url = "rbxassetid://9000135198" },
                    { name = "furry 2 (primo legacy)", url = "rbxassetid://7284437208" },
                    { name = "furry 3",              url = "rbxassetid://12316920007" },
                    { name = "furry 4",              url = "rbxassetid://9778081397" },
                    { name = "furry 5",              url = "rbxassetid://7235621717" },
                    { name = "furry 6",              url = "rbxassetid://9778137259" },
                    { name = "furry 7",              url = "rbxassetid://6449528328" },
                    { name = "furry 8",              url = "rbxassetid://9778089294" },
                    { name = "furry 9",              url = "rbxassetid://11118392179" },
                    { name = "furry 10",             url = "rbxassetid://7149187631" },
                },
            },
            {
                name = "femboy",
                items = {
                    { name = "femboy robin", url = "rbxassetid://105159771431173" },
                    { name = "femboy",       url = "rbxassetid://86474436752477" },
                },
            },
            {
                name = "ralsei",
                items = {
                    { name = "ralsei 1",            url = "rbxassetid://7652140680" },
                    { name = "ralsei??? is a jew",  url = "rbxassetid://7634441785" },
                    { name = "ralsei 2",            url = "rbxassetid://5365488179" },
                },
            },
            {
                name = "mellstroy",
                items = {
                    { name = "mellstroy 1",  url = "rbxassetid://129477975431198" },
                    { name = "mellstroy 2",  url = "rbxassetid://17431397425" },
                    { name = "mellstroy 3",  url = "rbxassetid://83756648376461" },
                    { name = "mellstroy 4",  url = "rbxassetid://92655920546930" },
                    { name = "mellstroy 5",  url = "rbxassetid://81063963166291" },
                    { name = "mellstroy 6",  url = "rbxassetid://18647840825" },
                    { name = "mellstroy 7",  url = "rbxassetid://87437772470500" },
                    { name = "mellstroy 8",  url = "rbxassetid://121259246208566" },
                    { name = "mellstroy 9",  url = "rbxassetid://18647834108" },
                    { name = "mellstroy 10", url = "rbxassetid://107387827855307" },
                    { name = "mellstroy 11", url = "rbxassetid://135535710084064" },
                    { name = "mellstroy 12", url = "rbxassetid://91665367380741" },
                },
            },
            {
                name = "standoff",
                items = {
                    { name = "standoff 2",     url = "rbxassetid://13863684860" },
                    { name = "standoff 3!!!",  url = "rbxassetid://82088559084510" },
                    { name = "standoff ctrax", url = "rbxassetid://14587254725" },
                    { name = "standoff 👍",    url = "rbxassetid://135861408196281" },
                },
            },
            {
                name = "anime",
                items = {
                    { name = "anime 1", url = "rbxassetid://4934665327" },
                    { name = "anime 2", url = "rbxassetid://10725335435" },
                    { name = "anime 3", url = "rbxassetid://7201239769" },
                    { name = "anime 4", url = "rbxassetid://8927607184" },
                    { name = "anime 5", url = "rbxassetid://10279250834" },
                },
            },
            {
                name = "spoofer decals",
                items = {
                    { name = "spoofer 1",  url = "rbxassetid://97131184818802" },
                    { name = "spoofer 2",  url = "rbxassetid://105960904062678" },
                    { name = "spoofer 3",  url = "rbxassetid://12950728616" },
                    { name = "spoofer 4",  url = "rbxassetid://75757517085816" },
                    { name = "spoofer 5",  url = "rbxassetid://120881264486798" },
                    { name = "spoofer 6",  url = "rbxassetid://77930634262074" },
                    { name = "spoofer 7",  url = "rbxassetid://114654563749286" },
                    { name = "spoofer 8",  url = "rbxassetid://91204824940819" },
                    { name = "spoofer 9",  url = "rbxassetid://132023758547398" },
                    { name = "spoofer 10", url = "rbxassetid://135921725470699" },
                },
            },
            {
                name = "misc",
                items = {
                    { name = "idkr 1",        url = "rbxassetid://97131184818802" },
                    { name = "idkr 2",        url = "rbxassetid://105960904062678" },
                    { name = "LIL UZI VERT",  url = "rbxassetid://12950728616" },
                    { name = "stind",         url = "rbxassetid://75757517085816" },
                },
            },
        }

        -- нормализует что угодно в валидный Image-URL Roblox
        local function normalizeAvatarURL(raw)
            if type(raw) ~= "string" then return nil end
            local url = raw:gsub("^%s+", ""):gsub("%s+$", "")
            if url == "" then return nil end
            if url:sub(1, 13) == "rbxassetid://" or url:sub(1, 11) == "rbxthumb://" then
                return url
            end
            if url:match("^%d+$") then return "rbxassetid://" .. url end
            local id = url:match("roblox%.com/library/(%d+)")
                    or url:match("roblox%.com/catalog/(%d+)")
                    or url:match("rbxassetid://(%d+)")
            if id then return "rbxassetid://" .. id end
            return url
        end

        -- скрытый persistable-контрол: хранит URL профиля для конфига
        local CONTROLS = _G.__PRIMO_CONTROLS
        if CONTROLS and not CONTROLS["ui.avatarCustom"] then
            local currentURL = Library.Settings.AvatarURL or ""
            CONTROLS["ui.avatarCustom"] = {
                Get = function(self) return currentURL end,
                Set = function(self, v, silent)
                    if type(v) ~= "string" then return end
                    currentURL = v
                    local norm = normalizeAvatarURL(v)
                    if norm then
                        pcall(function() Library:SetProfileImage(norm) end)
                    end
                end,
            }
        end

        local function commitAvatarURL(url)
            if not url then return end
            local norm = normalizeAvatarURL(url)
            if not norm then return end
            if CONTROLS and CONTROLS["ui.avatarCustom"] then
                pcall(function() CONTROLS["ui.avatarCustom"]:Set(norm, true) end)
            end
            pcall(function() Library:SetProfileImage(norm) end)
        end

        -- ── маленькое превью + кнопка открыть браузер ──
        UPSect:Label("- profile image -", 18)

        local previewBox = create("ImageLabel", {
            Name = "avatarPreview", BackgroundColor3 = PALETTE.Element,
            Image = Library.Settings.AvatarURL or "rbxassetid://1615907559",
            Size = UDim2.new(0, 48, 0, 48),
            Position = UDim2.new(0, 12, 0, UPSect.Y),
            ImageColor3 = Color3.new(1,1,1),
        }, UPSect.Frame)
        corner(previewBox, 8)
        local previewStroke = Instance.new("UIStroke")
        previewStroke.Color = Library.Settings.AccentColor
        previewStroke.Thickness = 1.5
        previewStroke.Transparency = 0.35
        previewStroke.Parent = previewBox
        registerAccent(function() tween(previewStroke, {Color = Library.Settings.AccentColor}) end)
        UPSect.Y = UPSect.Y + 56

        -- ── avatar browser popup ──
        local function openAvatarBrowser()
            local PW, PH = 600, 560
            local popup, _ = makePopupFrame("avatar_browser", "- avatar browser -", PW, PH)

            -- close button
            local closeBtn = create("TextButton", {Name="close", AutoButtonColor=false,
                Text="×", TextSize=20, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,24,0,20), Position=UDim2.new(1,-30,0,3),
                ZIndex=7}, popup)
            corner(closeBtn, 5)
            closeBtn.MouseEnter:Connect(function()
                tween(closeBtn, {TextColor3=PALETTE.Warn, BackgroundTransparency=0.15})
            end)
            closeBtn.MouseLeave:Connect(function()
                tween(closeBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
            end)
            closeBtn.MouseButton1Click:Connect(function() popup:Destroy() end)

            -- search
            local searchBox = create("TextBox", {Name="search",
                Text="", PlaceholderText="search preset...",
                PlaceholderColor3=PALETTE.TextDim, TextSize=13,
                TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
                BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
                TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,12,0,32)}, popup)
            corner(searchBox, 7); addGlass(searchBox, 0.4, PALETTE.ElementGlass)
            local searchPad = Instance.new("UIPadding")
            searchPad.PaddingLeft = UDim.new(0,10); searchPad.PaddingRight = UDim.new(0,10)
            searchPad.Parent = searchBox

            -- scroll списка
            local listHolder = create("Frame", {Name="listHolder",
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(1,-24,1,-160),
                Position=UDim2.new(0,12,0,68)}, popup)
            corner(listHolder, 8)
            local scroll = create("ScrollingFrame", {Name="list",
                BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
                Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
                ScrollBarImageColor3=Library.Settings.AccentColor,
                ScrollBarImageTransparency=0.4,
                ScrollingDirection=Enum.ScrollingDirection.Y,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                BorderSizePixel=0,
                ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, listHolder)
            local lay = Instance.new("UIListLayout")
            lay.SortOrder = Enum.SortOrder.LayoutOrder
            lay.Padding = UDim.new(0,4)
            lay.Parent = scroll
            local listPad = Instance.new("UIPadding")
            listPad.PaddingTop = UDim.new(0,4); listPad.PaddingBottom = UDim.new(0,4)
            listPad.PaddingLeft = UDim.new(0,4); listPad.PaddingRight = UDim.new(0,4)
            listPad.Parent = scroll

            -- какие папки раскрыты
            local expandedGroups = {}
            local refreshList     -- forward declaration (иначе click → nil)

            local function makeItemRow(preset, order, isPinned, indentPx)
                local row = create("Frame", {Name="p_"..order,
                    BackgroundColor3=PALETTE.ElementHi,
                    BackgroundTransparency=0.35,
                    Size=UDim2.new(1, 0, 0, 52),
                    LayoutOrder=order}, scroll)
                corner(row, 6)

                local thumb = create("ImageLabel", {Name="thumb",
                    BackgroundColor3=PALETTE.Element,
                    Image = preset.url,
                    ImageColor3 = Color3.new(1,1,1),
                    Size = UDim2.new(0,44,0,44),
                    Position = UDim2.new(0, 4 + indentPx, 0.5, -22)}, row)
                corner(thumb, 6)

                -- name-строка: имя, потом pin-иконка справа
                local nameHolder = create("Frame", {Name="nameRow",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -140 - indentPx, 0, 16),
                    Position = UDim2.new(0, 56 + indentPx, 0, 8)}, row)
                local nameLayout = Instance.new("UIListLayout")
                nameLayout.FillDirection = Enum.FillDirection.Horizontal
                nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
                nameLayout.Padding = UDim.new(0, 4)
                nameLayout.Parent = nameHolder

                create("TextLabel", {Name="nm",
                    BackgroundTransparency = 1,
                    Text = preset.name, TextSize = 13,
                    TextColor3 = PALETTE.Text, FontFace = FONT_BOLD,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    LayoutOrder = 1}, nameHolder)

                if isPinned then
                    create("ImageLabel", {Name = "pin",
                        BackgroundTransparency = 1,
                        Image = PIN_ICON,
                        ImageColor3 = Library.Settings.AccentColor,
                        Size = UDim2.new(0, 14, 0, 14),
                        LayoutOrder = 2}, nameHolder)
                end

                create("TextLabel", {Name="url", BackgroundTransparency=1,
                    Text=preset.url, TextSize=10, TextColor3=PALETTE.TextDim,
                    FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                    Size=UDim2.new(1, -140, 0, 12),
                    Position=UDim2.new(0, 56 + indentPx, 0, 28)}, row)

                local applyBtn = create("TextButton", {Name="apply",
                    AutoButtonColor=false, Text="apply", TextSize=12,
                    TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                    BackgroundColor3=PALETTE.Element,
                    BackgroundTransparency=0.4,
                    Size=UDim2.new(0,72,1,-14),
                    Position=UDim2.new(1,-80,0,7)}, row)
                corner(applyBtn, 6); addGlass(applyBtn, 0.4, PALETTE.ElementGlass)
                applyBtn.MouseEnter:Connect(function()
                    tween(applyBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.2})
                end)
                applyBtn.MouseLeave:Connect(function()
                    tween(applyBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
                end)
                applyBtn.MouseButton1Click:Connect(function()
                    commitAvatarURL(preset.url)
                    previewBox.Image = preset.url
                end)
            end

            local function makeFolderHeader(group, order)
                local count = #group.items
                local expanded = expandedGroups[group.name] == true
                local arrow = expanded and "▾" or "▸"
                local header = create("TextButton", {Name="folder_"..order,
                    AutoButtonColor=false,
                    Text = arrow .. "  " .. group.name .. "   (" .. count .. ")",
                    TextSize=14, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                    BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.25,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Size=UDim2.new(1, 0, 0, 34),
                    LayoutOrder=order}, scroll)
                corner(header, 6)
                local pad = Instance.new("UIPadding")
                pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
                pad.Parent = header
                header.MouseEnter:Connect(function()
                    tween(header, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.1})
                end)
                header.MouseLeave:Connect(function()
                    tween(header, {TextColor3=PALETTE.Text, BackgroundTransparency=0.25})
                end)
                header.MouseButton1Click:Connect(function()
                    expandedGroups[group.name] = not expandedGroups[group.name]
                    refreshList()
                end)
            end

            refreshList = function()
                for _, ch in ipairs(scroll:GetChildren()) do
                    if ch:IsA("GuiObject") and ch ~= lay then ch:Destroy() end
                end

                local query = (searchBox.Text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
                local searching = (query ~= "")
                local order = 0
                local totalShown = 0

                for _, group in ipairs(AVATAR_GROUPS) do
                    local isPinned = group.isPinned == true
                    local matching = {}
                    for _, preset in ipairs(group.items) do
                        local match = (query == "")
                            or preset.name:lower():find(query, 1, true)
                            or preset.url:lower():find(query, 1, true)
                        if match then table.insert(matching, preset) end
                    end

                    if isPinned then
                        -- pinned: всегда видны, без папки
                        for _, preset in ipairs(matching) do
                            order = order + 1
                            makeItemRow(preset, order, true, 0)
                            totalShown = totalShown + 1
                        end
                    else
                        -- обычная папка: показываем header всегда, items — при раскрытии или поиске
                        order = order + 1
                        makeFolderHeader(group, order)
                        totalShown = totalShown + 1

                        if searching or expandedGroups[group.name] then
                            for _, preset in ipairs(matching) do
                                order = order + 1
                                makeItemRow(preset, order, false, 14)
                                totalShown = totalShown + 1
                            end
                        end
                    end
                end

                if searching and totalShown == 0 then
                    create("TextLabel", {Name="empty", BackgroundTransparency=1,
                        Text="nothing found", TextSize=12,
                        TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
                        TextXAlignment=Enum.TextXAlignment.Center,
                        Size=UDim2.new(1,0,0,40), LayoutOrder=1}, scroll)
                end
            end
            refreshList()
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                if refreshList then refreshList() end
            end)

            -- custom row
            local customHolder = create("Frame", {Name="customHolder",
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(1,-24,0,68),
                Position=UDim2.new(0,12,1,-80)}, popup)
            corner(customHolder, 8)
            create("TextLabel", {Name="lbl", BackgroundTransparency=1,
                Text="custom (id, rbxassetid://, или roblox.com/library/...)",
                TextSize=11, TextColor3=PALETTE.TextDim, FontFace=FONT_REGULAR,
                TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-20,0,14),
                Position=UDim2.new(0,10,0,4)}, customHolder)

            local customBox = create("TextBox", {Name="input", Text="",
                PlaceholderText="12345 или rbxassetid://12345",
                PlaceholderColor3=PALETTE.TextDim, TextSize=13,
                TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
                BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
                TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-100,0,26),
                Position=UDim2.new(0,10,0,26)}, customHolder)
            corner(customBox, 6); addGlass(customBox, 0.4, PALETTE.ElementGlass)
            local cbPad = Instance.new("UIPadding")
            cbPad.PaddingLeft = UDim.new(0,10); cbPad.PaddingRight = UDim.new(0,10)
            cbPad.Parent = customBox

            local applyCustom = create("TextButton", {Name="applyCustom",
                AutoButtonColor=false, Text="apply", TextSize=12,
                TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.3,
                Size=UDim2.new(0,72,0,26),
                Position=UDim2.new(1,-84,0,26)}, customHolder)
            corner(applyCustom, 6); addGlass(applyCustom, 0.4, PALETTE.ElementGlass)
            applyCustom.MouseEnter:Connect(function()
                tween(applyCustom, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
            end)
            applyCustom.MouseLeave:Connect(function()
                tween(applyCustom, {TextColor3=PALETTE.Text, BackgroundTransparency=0.3})
            end)
            local function applyCustomNow()
                local norm = normalizeAvatarURL(customBox.Text)
                if not norm then return end
                commitAvatarURL(norm)
                previewBox.Image = norm
            end
            applyCustom.MouseButton1Click:Connect(applyCustomNow)
            customBox.FocusLost:Connect(function(enter)
                if enter then applyCustomNow() end
            end)

            popup.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
            popup.Visible = true
            popup.BackgroundTransparency = 0
        end
        _G.__PRIMO_OPEN_AVATAR_BROWSER = openAvatarBrowser

        UPSect:Button({Text="open avatar browser", Callback=function()
            openAvatarBrowser()
        end})
        UPSect:Label("presets + custom id + search", 20)

        -- ══ MENU IMAGE BROWSER (большая картинка меню) ══
        local MENU_IMAGE_PRESETS = {
            { name = "hysteria banner",      url = "rbxassetid://12150333118" },
            { name = "hysteria logo",        url = "rbxassetid://304489727" },
            { name = "aspirine",             url = "rbxassetid://125404550221755" },
            { name = "aspirine transparent", url = "rbxassetid://98491322897003" },
            { name = "furry femboy",         url = "rbxassetid://106158288148110" },
            { name = "dima twin 1",          url = "rbxassetid://110165141362804" },
            { name = "dima twin 2",          url = "rbxassetid://84335861136344" },
            { name = "mimi typh 1",          url = "rbxassetid://138729523360924" },
            { name = "floppa 1",             url = "rbxassetid://7184835629" },
            { name = "el gato 1",            url = "rbxassetid://10185836151" },
            { name = "boykisser 1",          url = "rbxassetid://110482195453919" },
            { name = "mellstroy 11",         url = "rbxassetid://135535710084064" },
        }
        local function openMenuImageBrowser()
            local PW2, PH2 = 500, 520
            local popup2, _ = makePopupFrame("menu_image_browser", "- menu image browser -", PW2, PH2)
            local scroll2 = create("ScrollingFrame", {
                Name="list", BackgroundTransparency=1,
                Size=UDim2.new(1,-24,1,-90), Position=UDim2.new(0,12,0,32),
                BorderSizePixel=0, ScrollBarThickness=4,
                ScrollBarImageColor3=Library.Settings.AccentColor,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,
                ScrollingDirection=Enum.ScrollingDirection.Y,
            }, popup2)
            local lay2 = Instance.new("UIListLayout")
            lay2.SortOrder = Enum.SortOrder.LayoutOrder
            lay2.Padding = UDim.new(0,4); lay2.Parent = scroll2
            local pad2 = Instance.new("UIPadding")
            pad2.PaddingTop = UDim.new(0,4); pad2.PaddingBottom = UDim.new(0,4)
            pad2.PaddingLeft = UDim.new(0,4); pad2.PaddingRight = UDim.new(0,4)
            pad2.Parent = scroll2

            local function commit(url)
                if not url or url == "" then return end
                if url:match("^%d+$") then url = "rbxassetid://" .. url end
                pcall(function() Library:SetMenuImage(url) end)
                local c = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS["ui.menuImage"]
                if c and c.Set then pcall(function() c:Set(url, true) end) end
            end

            for i, item in ipairs(MENU_IMAGE_PRESETS) do
                local row = create("Frame", {Name="mi_"..i,
                    BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.35,
                    Size=UDim2.new(1,0,0,56), LayoutOrder=i}, scroll2)
                corner(row, 6)
                local thumb = create("ImageLabel", {Name="thumb",
                    BackgroundColor3=PALETTE.Element, Image=item.url,
                    ImageColor3=Color3.new(1,1,1),
                    Size=UDim2.new(0,48,0,48), Position=UDim2.new(0,4,0.5,-24)}, row)
                corner(thumb, 6)
                create("TextLabel", {Name="nm", BackgroundTransparency=1,
                    Text=item.name, TextSize=12, TextColor3=PALETTE.Text,
                    FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                    Size=UDim2.new(1,-120,1,0), Position=UDim2.new(0,60,0,0)}, row)
                local applyBtn = create("TextButton", {Name="apply",
                    AutoButtonColor=false, Text="apply", TextSize=11,
                    TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                    BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                    Size=UDim2.new(0,68,1,-14), Position=UDim2.new(1,-74,0,7)}, row)
                corner(applyBtn, 5)
                applyBtn.MouseEnter:Connect(function()
                    tween(applyBtn, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.15})
                end)
                applyBtn.MouseLeave:Connect(function()
                    tween(applyBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
                end)
                applyBtn.MouseButton1Click:Connect(function()
                    commit(item.url)
                    popup2:Destroy()
                end)
            end

            local customBox = create("TextBox", {Name="custom",
                Text="", PlaceholderText="id или rbxassetid://",
                PlaceholderColor3=PALETTE.TextDim, TextSize=12,
                TextColor3=PALETTE.Text, FontFace=FONT_REGULAR,
                BackgroundColor3=PALETTE.Element, ClearTextOnFocus=false,
                TextXAlignment=Enum.TextXAlignment.Left,
                Size=UDim2.new(1,-100,0,26), Position=UDim2.new(0,12,1,-34)}, popup2)
            corner(customBox, 5); addGlass(customBox, 0.4, PALETTE.ElementGlass)
            local cpad = Instance.new("UIPadding")
            cpad.PaddingLeft = UDim.new(0,8); cpad.PaddingRight = UDim.new(0,8); cpad.Parent = customBox
            local applyCustom = create("TextButton", {Name="applyC",
                AutoButtonColor=false, Text="apply", TextSize=11,
                TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
                BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                Size=UDim2.new(0,72,0,26), Position=UDim2.new(1,-84,1,-34)}, popup2)
            corner(applyCustom, 5)
            local function applyC()
                local t = customBox.Text or ""
                if t == "" then return end
                commit(t); popup2:Destroy()
            end
            applyCustom.MouseButton1Click:Connect(applyC)
            customBox.FocusLost:Connect(function(enter) if enter then applyC() end end)

            popup2.Position = UDim2.new(0.5, -PW2/2, 0.5, -PH2/2)
            popup2.Visible = true
            popup2.BackgroundTransparency = 0
        end
        _G.__PRIMO_OPEN_MENU_IMAGE_BROWSER = openMenuImageBrowser

        UPSect:Button({Text="browse menu image (big pic)", Callback=openMenuImageBrowser})
        UPSect:Label("меняет большую картинку в сайдбаре", 18)

        -- persist-контрол для menu image
        do
            local CONTROLS2 = _G.__PRIMO_CONTROLS
            if CONTROLS2 and not CONTROLS2["ui.menuImage"] then
                CONTROLS2["ui.menuImage"] = {
                    Get = function(self) return Library.Settings.MenuImageURL or "" end,
                    Set = function(self, v, silent)
                        if type(v) ~= "string" or v == "" then return end
                        pcall(function() Library:SetMenuImage(v) end)
                    end,
                }
            end
        end
        -- ── PROFILE PRESET selector ──
        UPSect:Divider()
        UPSect:Label("- profile layout preset -", 18)
        local _ppVals = {"classic", "experimental"}
        local _ppIdx = 1
        for i, n in ipairs(_ppVals) do
            if n == (Library.Settings.ProfilePreset or "classic") then _ppIdx = i break end
        end
        reg(UPSect, "Cycle", "ui.profilePreset", {
            Prefix = "preset: ",
            Values = _ppVals,
            Index = _ppIdx,
            Callback = function(v)
                if Window and Window.SetProfilePreset then
                    pcall(function() Window:SetProfilePreset(v) end)
                end
            end,
        })
        UPSect:Label("classic = old, experimental = premium", 18)
        UPSect:Divider()
        UPSect:Label("- avatar appearance -", 18)
        reg(UPSect, "Slider", "ui.avatarBgTransp", {
            Text = "background transparency",
            Min = 0, Max = 1, Default = 0,
            Callback = function(v)
                Library.Settings.AvatarBgTransparency = v
                if Library._avatarBox and Library._avatarBox.Parent then
                    Library._avatarBox.BackgroundTransparency = v
                end
            end,
        })
        reg(UPSect, "Slider", "ui.avatarBorderTransp", {
            Text = "border transparency",
            Min = 0, Max = 1, Default = 0.3,
            Callback = function(v)
                Library.Settings.AvatarBorderTransparency = v
                if Library._avatarStroke and Library._avatarStroke.Parent then
                    Library._avatarStroke.Transparency = v
                end
            end,
        })
        reg(UPSect, "Slider", "ui.avatarSize", {
            Text = "image size (px)",
            Min = 24, Max = 120, Default = 51,
            Callback = function(v)
                Library.Settings.AvatarSize = v
                if Library._avatarBox and Library._avatarBox.Parent then
                    -- сохраняем пропорцию (51x47 → ratio ~0.92)
                    Library._avatarBox.Size = UDim2.new(0, v, 0, math.floor(v * 0.92))
                end
            end,
        })
        reg(UPSect, "Slider", "ui.avatarCorner", {
            Text = "image corner radius",
            Min = 0, Max = 30, Default = 10,
            Callback = function(v)
                Library.Settings.AvatarCorner = v
                if Library._avatarBox and Library._avatarBox.Parent then
                    local c = Library._avatarBox:FindFirstChildOfClass("UICorner")
                    if c then c.CornerRadius = UDim.new(0, v) end
                end
            end,
        })

        -- ── gradient presets for profile fields ──
        -- "custom" → использует colorA/colorB
        -- "rainbow"/"pride" → особая анимация (HSV rotation), colorA/B игнорируются
        -- остальные → ставят colorA/B и работают как обычный lerp
        local GRADIENT_PRESETS = {
            { name = "custom",     colorA = nil,                    colorB = nil },
            { name = "rainbow",    colorA = Color3.fromRGB(255,0,0),   colorB = Color3.fromRGB(0,255,255) },
            { name = "pastel",     colorA = Color3.fromRGB(255,200,230), colorB = Color3.fromRGB(200,220,255) },
            { name = "sunset",     colorA = Color3.fromRGB(255,150,80),  colorB = Color3.fromRGB(255,80,150) },
            { name = "ocean",      colorA = Color3.fromRGB(20,80,180),   colorB = Color3.fromRGB(80,220,240) },
            { name = "fire",       colorA = Color3.fromRGB(220,40,20),   colorB = Color3.fromRGB(255,210,60) },
            { name = "ice",        colorA = Color3.fromRGB(220,240,255), colorB = Color3.fromRGB(120,180,255) },
            { name = "monochrome", colorA = Color3.fromRGB(60,60,70),    colorB = Color3.fromRGB(240,240,245) },
            { name = "vaporwave",  colorA = Color3.fromRGB(255,100,220), colorB = Color3.fromRGB(100,240,255) },
            { name = "toxic",      colorA = Color3.fromRGB(60,220,80),   colorB = Color3.fromRGB(240,240,60) },
            { name = "gold",       colorA = Color3.fromRGB(180,120,30),  colorB = Color3.fromRGB(255,220,120) },
            { name = "pride",      colorA = Color3.fromRGB(255,0,0),     colorB = Color3.fromRGB(140,0,255) },
        }
        local GRADIENT_PRESET_NAMES = {}
        for _, p in ipairs(GRADIENT_PRESETS) do
            table.insert(GRADIENT_PRESET_NAMES, p.name)
        end
        local function _findGradPreset(n)
            for _, p in ipairs(GRADIENT_PRESETS) do
                if p.name == n then return p end
            end
        end

        -- ── per-field gradient state ──
        local PG = Library.Settings.ProfileGradient or {}
        local DEFAULT_FIELD = {
            enabled = false,
            colorA  = Color3.fromRGB(180,180,190),
            colorB  = Color3.new(1,1,1),
            speed   = 1,
            style   = "flow",
        }
        local function cloneDefault(over)
            local t = {}
            for k, v in pairs(DEFAULT_FIELD) do t[k] = v end
            if over then for k, v in pairs(over) do t[k] = v end end
            return t
        end
        PG.name    = PG.name    or cloneDefault({enabled = PG.gradName    == true})
        PG.uid     = PG.uid     or cloneDefault({enabled = PG.gradUid     == true})
        PG.expires = PG.expires or cloneDefault({enabled = PG.gradExpires == true})
        if PG.colorA or PG.colorB or PG.style or PG.speed then
            for _, f in ipairs({PG.name, PG.uid, PG.expires}) do
                if not f._migrated then
                    if PG.colorA then f.colorA = PG.colorA end
                    if PG.colorB then f.colorB = PG.colorB end
                    if PG.style  then f.style  = PG.style  end
                    if PG.speed  then f.speed  = PG.speed  end
                    f._migrated = true
                end
            end
        end
        Library.Settings.ProfileGradient = PG

        local function getRefs()
            if not Window then return nil end
            return Window._profileLabels
        end

        local function applyField(field, grad)
            if not grad then return end
            local on = field.enabled == true
            grad.Enabled = on
            if on then
                grad.Offset = Vector2.new(0, 0)
                grad.Rotation = (field.style == "sweep") and 45 or 0
                grad.Color = resolveSeq(field.colorA, field.colorB)
            end
        end

        local function applyProfileGradients()
            local refs = getRefs()
            if not refs then return end
            applyField(PG.name,    refs.gradName)
            applyField(PG.uid,     refs.gradUid)
            applyField(PG.expires, refs.gradExpires)
        end
        _G.__PRIMO_APPLY_PROFILE_GRAD = applyProfileGradients

        if _G.__PRIMO_PROFILE_GRAD_CONN then
            pcall(function() _G.__PRIMO_PROFILE_GRAD_CONN:Disconnect() end)
        end
        local pgPhases = { name = 0, uid = 0, expires = 0 }
        _G.__PRIMO_PROFILE_GRAD_CONN = RunService.Heartbeat:Connect(function(dt)
            local refs = getRefs()
            if not refs then return end
            local mapping = {
                { field = PG.name,    grad = refs.gradName,    key = "name"    },
                { field = PG.uid,     grad = refs.gradUid,     key = "uid"     },
                { field = PG.expires, grad = refs.gradExpires, key = "expires" },
            }
            for _, e in ipairs(mapping) do
                local f = e.field
                local g = e.grad
                if f.enabled and g and g.Enabled then
                    local speed = f.speed or 1
                    local preset = f.preset or "custom"

                    if preset == "rainbow" or preset == "pride" then
                        -- особая HSV-анимация
                        local rate = (preset == "pride") and 0.25 or 0.15
                        pgPhases[e.key] = (pgPhases[e.key] + dt * speed * rate) % 1
                        local hue = pgPhases[e.key]
                        local colA, colB
                        if preset == "pride" then
                            -- 6-полосный флаг радуги, крутится по кругу
                            local h1 = hue
                            local h2 = (hue + 0.33) % 1
                            local h3 = (hue + 0.66) % 1
                            local c1 = Color3.fromHSV(h1, 0.85, 1)
                            local c2 = Color3.fromHSV(h2, 0.85, 1)
                            local c3 = Color3.fromHSV(h3, 0.85, 1)
                            g.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0,    c1),
                                ColorSequenceKeypoint.new(0.33, c2),
                                ColorSequenceKeypoint.new(0.66, c3),
                                ColorSequenceKeypoint.new(1,    c1),
                            })
                            if f.style == "sweep" then
                                g.Offset = Vector2.new(0, 0)
                            else
                                g.Offset = Vector2.new(0, 0)
                            end
                        else
                            -- обычная радуга — две соседние точки спектра
                            colA = Color3.fromHSV(hue, 0.75, 1)
                            colB = Color3.fromHSV((hue + 0.25) % 1, 0.75, 1)
                            g.Color = resolveSeq(colA, colB)
                            if f.style == "sweep" then
                                g.Rotation = (hue * 360) % 360
                            else
                                g.Offset = Vector2.new(0, 0)
                            end
                        end
                    else
                        -- обычный режим colorA→colorB
                        if f.style == "sweep" then
                            pgPhases[e.key] = (pgPhases[e.key] + dt*speed*60) % 360
                            g.Rotation = pgPhases[e.key]
                        elseif f.style == "pulse" then
                            pgPhases[e.key] = (pgPhases[e.key] + dt*speed*0.4) % 1
                            local k = (math.sin(pgPhases[e.key]*math.pi*2)+1)*0.5
                            g.Color = resolvePulseSeq(f.colorA, f.colorB, k)
                        else
                            pgPhases[e.key] = (pgPhases[e.key] + dt*speed*0.15) % 1
                            local o = math.sin(pgPhases[e.key]*math.pi*2)*0.5
                            g.Offset = Vector2.new(o, 0)
                        end
                    end
                end
            end
        end)

        local function buildFieldUI(labelText, field, path)
            field.preset = field.preset or "custom"
            -- ❗ нормализация: если конфиг пришёл с другим регистром — приводим к нашему
            do
                local lc = tostring(field.preset):lower()
                for _, n in ipairs(GRADIENT_PRESET_NAMES) do
                    if n:lower() == lc then field.preset = n; break end
                end
            end
            UPSect:Divider()
            UPSect:Label("- " .. labelText .. " gradient -", 18)

            -- preset selector
            local presetIndex = 1
            for i, n in ipairs(GRADIENT_PRESET_NAMES) do
                if n == field.preset then presetIndex = i break end
            end
            reg(UPSect, "Cycle", path .. ".preset", {
                Prefix = "preset: ",
                Values = GRADIENT_PRESET_NAMES,
                Index = presetIndex,
                Callback = function(v)
                    field.preset = v
                    local p = _findGradPreset(v)
                    if p and p.colorA and p.colorB then
                        field.colorA = p.colorA
                        field.colorB = p.colorB
                        -- sync color pickers so UI показывает актуальный цвет
                        local ca = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS[path .. ".colorA"]
                        local cb = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS[path .. ".colorB"]
                        if ca and ca.Set then pcall(function() ca:Set(p.colorA, true) end) end
                        if cb and cb.Set then pcall(function() cb:Set(p.colorB, true) end) end
                    end
                    applyProfileGradients()
                end,
            })

            reg(UPSect, "Toggle", path .. ".enabled", {
                Text="enable", Default=field.enabled,
                Callback=function(v) field.enabled = v; applyProfileGradients() end})
            reg(UPSect, "ColorPicker", path .. ".colorA", {
                Text="color a",
                GetInitialColor=function() return field.colorA end,
                Callback=function(c)
                    field.colorA = c
                    field.preset = "custom"
                    local pc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS[path .. ".preset"]
                    if pc and pc.Set then pcall(function() pc:Set("custom", true) end) end
                    applyProfileGradients()
                end})
            reg(UPSect, "ColorPicker", path .. ".colorB", {
                Text="color b",
                GetInitialColor=function() return field.colorB end,
                Callback=function(c)
                    field.colorB = c
                    field.preset = "custom"
                    local pc = _G.__PRIMO_CONTROLS and _G.__PRIMO_CONTROLS[path .. ".preset"]
                    if pc and pc.Set then pcall(function() pc:Set("custom", true) end) end
                    applyProfileGradients()
                end})
            reg(UPSect, "StylePicker", path .. ".style", {
                Text="style", Default=field.style,
                Callback=function(v) field.style = v; applyProfileGradients() end})
            reg(UPSect, "Slider", path .. ".speed", {
                Text="speed", Min=0, Max=3, Default=field.speed,
                Callback=function(v) field.speed = v end})
        end

        buildFieldUI("nickname", PG.name,    "profile.name")
        buildFieldUI("uid",      PG.uid,     "profile.uid")
        buildFieldUI("expires",  PG.expires, "profile.expires")

        task.defer(applyProfileGradients)
    end   -- ← ЭТОТ end ЗАКРЫВАЕТ do user preferences

    -- ─── OTHER / BIND MANAGER ───
    local otherSect = settingsTab:CreateSection({Title="- other -",
        Position=UDim2.new(0,516,0,640), Size=UDim2.new(0,214,0,140)})
    otherSect:Label("view & manage all binds", 18)
    otherSect:Button({Text="open bind manager", Callback=function()
        -- 1) закрыть старую копию если она уже открыта
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local popups = pg and pg:FindFirstChild("primo_popups")
        if popups then
            local existing = popups:FindFirstChild("bind_manager")
            if existing then existing:Destroy() end
        end

        local PW, PH = 520, 620
        local popup, _ = makePopupFrame("bind_manager",
            "- bind manager -", PW, PH)

        -- 2) close-кнопка (×) в правом верхнем углу
        local closeBtn = create("TextButton", {Name="close", AutoButtonColor=false,
            Text="×", TextSize=20, TextColor3=PALETTE.Text, FontFace=FONT_BOLD,
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(0,24,0,20), Position=UDim2.new(1,-30,0,3),
            ZIndex=7}, popup)
        corner(closeBtn, 5)
        closeBtn.MouseEnter:Connect(function()
            tween(closeBtn, {TextColor3=PALETTE.Warn, BackgroundTransparency=0.15})
        end)
        closeBtn.MouseLeave:Connect(function()
            tween(closeBtn, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
        end)
        closeBtn.MouseButton1Click:Connect(function()
            popup:Destroy()
        end)

        -- 3) Esc закрывает
        local escConn
        escConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                if popup and popup.Parent then popup:Destroy() end
                if escConn then escConn:Disconnect() end
            end
        end)
        popup.Destroying:Connect(function()
            if escConn then escConn:Disconnect() end
        end)

        local listHolder = create("Frame", {Name="listHolder",
            BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
            Size=UDim2.new(1,-24,1,-40), Position=UDim2.new(0,12,0,32)}, popup)
        corner(listHolder, 8)
        local scroll = create("ScrollingFrame", {Name="bindScroll",
            BackgroundTransparency=1, Size=UDim2.new(1,-8,1,-8),
            Position=UDim2.new(0,4,0,4), ScrollBarThickness=4,
            ScrollBarImageColor3=Library.Settings.AccentColor,
            ScrollBarImageTransparency=0.4,
            ScrollingDirection=Enum.ScrollingDirection.Y,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            BorderSizePixel=0,
            ElasticBehavior=Enum.ElasticBehavior.WhenScrollable}, listHolder)
        local lay = Instance.new("UIListLayout")
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 4)
        lay.Parent = scroll
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6)
        pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)
        pad.Parent = scroll

        local function refreshBinds()
            for _, ch in ipairs(scroll:GetChildren()) do
                if ch:IsA("GuiObject") and ch ~= lay then ch:Destroy() end
            end
            local allBinds = {}
            for path, ctrl in pairs(_G.__PRIMO_CONTROLS or {}) do
                if type(ctrl.GetBind) == "function" then
                    local ok, b = pcall(function() return ctrl:GetBind() end)
                    if ok and b then
                        allBinds[#allBinds+1] = {
                            path = path,
                            bind = b,
                            name = path:gsub("^.*%.", ""),
                        }
                    end
                end
            end
            table.sort(allBinds, function(a, b) return a.name < b.name end)
            if #allBinds == 0 then
                create("TextLabel", {Name="empty", BackgroundTransparency=1,
                    Text="no binds set", TextSize=12, TextColor3=PALETTE.TextDim,
                    FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Center,
                    Size=UDim2.new(1,0,0,40), LayoutOrder=1}, scroll)
                return
            end
            for i, item in ipairs(allBinds) do
                local row = create("Frame", {Name="b_"..i,
                    BackgroundColor3=PALETTE.ElementHi, BackgroundTransparency=0.3,
                    Size=UDim2.new(1,0,0,30), LayoutOrder=i}, scroll)
                corner(row, 6)
                create("TextLabel", {Name="nm", BackgroundTransparency=1,
                    Text=item.name, TextSize=12, TextColor3=PALETTE.Text,
                    FontFace=FONT_BOLD, TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                    Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,8,0,0)}, row)
                local kb = create("TextButton", {Name="kb", AutoButtonColor=false,
                    Text=bindName(item.bind), TextSize=11,
                    TextColor3=Library.Settings.AccentColor, FontFace=FONT_BOLD,
                    BackgroundColor3=PALETTE.Element, BackgroundTransparency=0.4,
                    Size=UDim2.new(0,80,1,-6), Position=UDim2.new(1,-84,0,3)}, row)
                corner(kb, 5)
                kb.MouseButton1Click:Connect(function()
                    local ctrl = _G.__PRIMO_CONTROLS[item.path]
                    if ctrl and type(ctrl.SetBind) == "function" then
                        pcall(function() ctrl:SetBind(nil, true) end)
                    end
                    refreshBinds()
                end)
            end
        end
        refreshBinds()
        -- кнопка "clear all"
        local clearAll = create("TextButton", {Name="clearAll", AutoButtonColor=false,
            Text="clear all binds", TextSize=12, TextColor3=PALETTE.Text,
            FontFace=FONT_BOLD, BackgroundColor3=PALETTE.Element,
            Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,12,0,PH-38)}, popup)
        corner(clearAll, 7); addGlass(clearAll, 0.4, PALETTE.ElementGlass)
        clearAll.MouseEnter:Connect(function()
            tween(clearAll, {TextColor3=Library.Settings.AccentColor, BackgroundTransparency=0.3})
        end)
        clearAll.MouseLeave:Connect(function()
            tween(clearAll, {TextColor3=PALETTE.Text, BackgroundTransparency=0.4})
        end)
        clearAll.MouseButton1Click:Connect(function()
            for _, ctrl in pairs(_G.__PRIMO_CONTROLS or {}) do
                if type(ctrl.SetBind) == "function" then
                    pcall(function() ctrl:SetBind(nil, true) end)
                end
            end
            refreshBinds()
        end)
        popup.Position = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
        popup.Visible = true
        popup.BackgroundTransparency = 0
    end})

end

if Window and Window.Watermark then
    pcall(function() Window.Watermark:SetUsername(KEYDATA.Username) end)
    pcall(function() Window.Watermark:SetExpires(KEYDATA.Expires) end)
    -- ❗ FIX: было SetUI → падало "attempt to call missing method 'SetUI' of table"
    pcall(function() Window.Watermark:SetUID(KEYDATA.UID) end)
end

end  -- end PART 4 function
_runPart("PART4/UI", _part4_UI)

end -- END runCheat

-- ═════════════════════════════════════════════════════════
-- KEY_DATA  —  объявление (т.к. лоадер удалён, а runCheat
--              всё ещё читает KEYDATA.Username / .Expires / .UID)
-- ═════════════════════════════════════════════════════════
local KEY_DATA = {
    Username  = "user",
    Expires   = "never",
    UID       = "0",
    Key       = nil,
    Validated = true,
}

-- (опционально) автоподтягивание из pastebin autoscan — фоном,
-- иначе HttpGet блокирует загрузку меню на 0.5–3 сек
do
    local _lp = game:GetService("Players").LocalPlayer
    task.spawn(function()
        local ok, _entry = pcall(scanPastebinForPlayer, _lp.UserId, _lp.Name)
        if ok and _entry then
            KEY_DATA.Username = _entry.username   or _lp.Name
            KEY_DATA.Expires  = _entry.expires    or "never"
            KEY_DATA.UID      = _entry.playeruid  or tostring(_lp.UserId)
            KEY_DATA.Key      = _entry.key
            if Window and Window.Watermark then
                pcall(function()
                    Window.Watermark:SetUsername(KEY_DATA.Username)
                    Window.Watermark:SetExpires(KEY_DATA.Expires)
                    Window.Watermark:SetUID(KEY_DATA.UID)
                end)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────
-- DIRECT BOOT  (payload для loadstring — без лоадера)
-- ─────────────────────────────────────────────────────────
pcall(runCheat, KEY_DATA)

return _G.PRIMO_INTERNAL
