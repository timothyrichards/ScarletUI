-- The settings window (/sui). The settings themselves still come from
-- ScarletUI:Options(), so each is defined once, but the window has its own
-- navigation and layout: pages grouped by NAV, a card per option group, and
-- one setting per row with its control at the right. It is built from
-- Blizzard's frame templates, which carry each client's skin.

local ICON = "Interface\\Icons\\INV_Misc_Gear_01"
local WIDTH = 580      -- scrolling content width
local TEXT_WIDTH = 330 -- a row's name and description; the control takes the rest

-- Left-hand navigation. An entry lists the option groups (paths into
-- ScarletUI:Options().args) shown on that page; with several, each becomes a
-- card. `name` and `desc` default to the first group's. Top-level pages
-- missing from here are appended, so a new page is never lost. `master` marks
-- a page whose groups have no switch of their own; it gets one made of its
-- settings (see SetSettingsPageEnabled).
local NAV = {
    { header = "Features" },
    { "generalSettings.interface", master = true, desc = "Small interface tweaks and reminders." },
    { "generalSettings.itemLevel", master = true, desc = "Show item levels on equipment and in bags." },
    { "bagModuleSettings", master = true },
    { "chatModuleSettings" },
    { "actionBarTogglesSettings" },
    { "generalSettings.tracking", master = true, desc = "Share minimap tracking across characters and keep gathering tracking on." },
    { "fishingSettings" },
    { "auctionSettings", master = true },
    { "nameplatesModuleSettings" },
    { "CVarModuleSettings" },
    { header = "Setup" },
    { "editModeSettings" },
    { "generalSettings.shortcuts", "generalSettings.reset", name = "Shortcuts & Reset",
        desc = "Ways to open Scarlet UI, and restoring its defaults." },
}

local frame, nav, scroll, content, search
local selected, query
local Render

local function Value(option, key)
    local value = option[key]
    if type(value) == "function" then return value() end
    return value
end

-- By `order`, negatives last (as AceConfig), then by name.
local function Sorted(args)
    local list = {}
    for key, option in pairs(args) do
        if type(option) == "table" then
            option.key = key
            list[#list + 1] = option
        end
    end
    table.sort(list, function(a, b)
        local ao, bo = a.order or 100, b.order or 100
        if ao ~= bo then
            if (ao < 0) ~= (bo < 0) then return bo < 0 end
            return ao < bo
        end
        return tostring(Value(a, "name")) < tostring(Value(b, "name"))
    end)
    return list
end

local function Matches(option, text)
    if option.type == "description" then return false end
    local haystack = tostring(Value(option, "name") or "") .. " " .. tostring(Value(option, "desc") or "")
    return haystack:lower():find(text, 1, true) ~= nil
end

-- Flattens a group into the rows to draw. { card = title } opens a card ("" for
-- an untitled one) and is only added ahead of a visible setting; { option,
-- disabled } is a setting. The group's own settings form the card named `card`
-- and each child group its own. `text` (lowercase) keeps only settings whose
-- name or description contain it.
function ScarletUI:CollectSettings(group, text, items, disabled, card)
    items = items or {}
    disabled = disabled or Value(group, "disabled") or false
    card = card or ""
    local args, open = group.args, false

    -- The CVar list is label/input/Default/Remove options per CVar, numbered;
    -- each set is drawn as one row. Its filter field is left out: the
    -- window's own search covers these rows.
    if args.label1 then
        local n = 1
        while args["label" .. n] do
            local label = args["label" .. n]
            if not Value(label, "hidden") and (not text or Value(label, "name"):lower():find(text, 1, true)) then
                if not open then
                    items[#items + 1] = { card = "Overrides" }
                    open = true
                end
                items[#items + 1] = {
                    cvar = { label = label, input = args["input" .. n], clear = args["clear" .. n], remove = args["remove" .. n] },
                    disabled = disabled,
                }
            end
            n = n + 1
        end
        return items
    end

    for _, option in ipairs(Sorted(args)) do
        if not Value(option, "hidden") then
            if option.type == "group" then
                local name = Value(option, "name")
                self:CollectSettings(option, text, items, disabled, card ~= "" and (card .. " - " .. name) or name)
                open = false
            elseif not text or Matches(option, text) then
                if not open then
                    items[#items + 1] = { card = card }
                    open = true
                end
                items[#items + 1] = { option = option, disabled = disabled or Value(option, "disabled") or false }
            end
        end
    end
    return items
end

-- A page's rows: one card per group when it shows several.
local function PageItems(page, text, disabled, items)
    items = items or {}
    for _, group in ipairs(page.groups) do
        ScarletUI:CollectSettings(group, text, items, disabled, #page.groups > 1 and Value(group, "name") or "")
    end
    return items
end

function ScarletUI:IsSettingsPageEnabled(id)
    local masters = self.db.global.settingsMasters
    return not (masters and masters[id])
end

-- The switch of a `master` page. Off turns off every toggle on the page (and
-- every select that has an OFF value) through its own setter, remembering
-- what was on in db.global.settingsMasters[page.id]; on puts those back.
-- ponytail: the modules know nothing of this, so a setting turned on elsewhere
-- (/sui ace) while a page is off stays on. Give modules a real per-category
-- flag if that ever matters.
function ScarletUI:SetSettingsPageEnabled(page, on)
    local masters = self.db.global.settingsMasters or {}
    self.db.global.settingsMasters = masters

    local options, card = {}, ""
    for _, item in ipairs(PageItems(page)) do
        local option = item.option
        if item.card then
            card = item.card
        elseif option and (option.type == "toggle" or option.type == "select" and Value(option, "values").OFF) then
            options[card .. "/" .. option.key] = option
        end
    end

    if on then
        for id, value in pairs(masters[page.id] or {}) do
            if options[id] then options[id].set(nil, value) end
        end
        masters[page.id] = nil
    else
        local restore = {}
        for id, option in pairs(options) do
            local value = option.get()
            local off = option.type == "select" and "OFF" or false
            if value and value ~= off then
                restore[id] = value
                option.set(nil, off)
            end
        end
        masters[page.id] = restore
    end
    self:RefreshSettings()
end

local pending
function ScarletUI:RefreshSettings()
    if pending or not (frame and frame:IsShown()) then return end
    pending = true
    -- Next frame: a widget is never rebuilt inside its own click handler.
    C_Timer.After(0, function()
        pending = false
        if frame:IsShown() then Render() end
    end)
end

local function Set(option, ...)
    if option.set then option.set(nil, ...) end
    ScarletUI:RefreshSettings()
end

local function Atlas(texture, name, useAtlasSize)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
        texture:SetAtlas(name, useAtlasSize)
        return true
    end
end

-- `control` shows the full description held by `tip` (a row, or any table
-- with name and desc). Rows clear `desc` when all of it is already on screen.
local function Tooltip(control, tip)
    control:SetScript("OnEnter", function(self)
        if not tip.desc or tip.desc == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tip.name, 1, 0.82, 0)
        GameTooltip:AddLine(tip.desc, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Hover(row)
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.05)
end

-- Each constructor returns a frame with Apply(item) and a `height` the layout
-- reads after Apply.
local Widgets = {}

-- The shared row: name and the first sentence of the description at the left
-- (the tooltip has the rest), the control at the right.
local function Row(parent)
    local w = CreateFrame("Button", nil, parent)
    Hover(w)
    w.label = w:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    w.label:SetPoint("TOPLEFT", 12, -9)
    w.label:SetWidth(TEXT_WIDTH)
    w.label:SetJustifyH("LEFT")
    w.label:SetWordWrap(false)
    w.sub = w:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    w.sub:SetPoint("TOPLEFT", w.label, "BOTTOMLEFT", 0, -3)
    w.sub:SetWidth(TEXT_WIDTH)
    w.sub:SetJustifyH("LEFT")
    w.sub:SetTextColor(0.65, 0.65, 0.65)
    Tooltip(w, w)
    function w:Base(item)
        local option = item.option
        local name, desc = Value(option, "name") or "", Value(option, "desc")
        if name == "" then name, desc = desc or "", nil end
        local short = desc and (desc:match("^(.-[%.!])%s+[%u%(]") or desc)
        self.option, self.disabled = option, item.disabled
        self.name, self.desc = name, desc ~= short and desc or nil
        -- A page's on/off switch stands out from its settings.
        self.label:SetFontObject(item.disabled and "GameFontDisable" or item.master and "GameFontNormal" or "GameFontHighlight")
        self.label:SetText(name)
        self.sub:SetText(short or "")
        self.sub:SetAlpha(item.disabled and 0.5 or 1)
        self.height = short and self.sub:GetStringHeight() + 34 or 30
    end
    return w
end

function Widgets.title(parent)
    local w = CreateFrame("Frame", nil, parent)
    local name = w:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    name:SetPoint("TOPLEFT", 2, -6)
    local desc = w:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", -8, 0)
    desc:SetJustifyH("LEFT")
    function w:Apply(item)
        name:SetText(item.title)
        desc:SetText(item.desc or "")
        self.height = 38 + (item.desc and desc:GetStringHeight() + 4 or 0)
    end
    return w
end

-- A card's title: the bronze bar Blizzard draws for list categories, or plain
-- gold text over a rule on clients without that art.
function Widgets.card(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 32
    local left, right, middle = w:CreateTexture(nil, "BACKGROUND"), w:CreateTexture(nil, "BACKGROUND"), w:CreateTexture(nil, "BACKGROUND")
    if Atlas(left, "Professions-recipe-header-left", true) and Atlas(right, "Professions-recipe-header-right", true)
        and Atlas(middle, "Professions-recipe-header-middle") then
        left:SetPoint("BOTTOMLEFT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", 0, 0)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
        middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    else
        left:Hide()
        right:Hide()
        middle:SetColorTexture(0.6, 0.48, 0.28, 0.6)
        middle:SetPoint("BOTTOMLEFT", 0, 0)
        middle:SetPoint("BOTTOMRIGHT", 0, 0)
        middle:SetHeight(1)
    end
    local label = w:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", 12, 9)
    function w:Apply(item) label:SetText(item.card) end
    return w
end

function Widgets.description(parent)
    local w = CreateFrame("Frame", nil, parent)
    local text = w:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 12, -7)
    text:SetWidth(WIDTH - 24)
    text:SetJustifyH("LEFT")
    function w:Apply(item)
        local name = strtrim(Value(item.option, "name") or "")
        text:SetFontObject(item.option.fontSize == "medium" and "GameFontHighlight" or "GameFontHighlightSmall")
        text:SetText(name)
        -- An empty description is only AceConfig's line break.
        self.height = name == "" and 0 or text:GetStringHeight() + 14
    end
    return w
end

function Widgets.toggle(parent)
    local w = Row(parent)
    local check = CreateFrame("CheckButton", nil, w, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("RIGHT", -10, 0)
    check:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        Set(w.option, checked)
    end)
    -- The whole row is the click target.
    w:SetScript("OnClick", function() if not w.disabled then check:Click() end end)
    Tooltip(check, w)
    function w:Apply(item)
        self:Base(item)
        check:SetChecked(item.option.get() and true or false)
        check:SetEnabled(not item.disabled)
    end
    return w
end

function Widgets.execute(parent)
    local w = Row(parent)
    local button = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    button:SetSize(170, 22)
    button:SetPoint("RIGHT", -10, 0)
    button:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        w.option.func()
        ScarletUI:RefreshSettings()
    end)
    Tooltip(button, w)
    function w:Apply(item)
        self:Base(item)
        button:SetText(self.name)
        button:SetEnabled(not item.disabled)
    end
    return w
end

local function EditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetAutoFocus(false)
    edit:SetSize(width, 20)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        ScarletUI:RefreshSettings()
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    function edit:Update(value, disabled)
        if not self:HasFocus() then
            self:SetText(tostring(value or ""))
            self:SetCursorPosition(0)
        end
        self:SetEnabled(not disabled)
        local shade = disabled and 0.5 or 1
        self:SetTextColor(shade, shade, shade)
    end
    return edit
end

function Widgets.input(parent)
    local w = Row(parent)
    local edit = EditBox(w, 190)
    edit:SetPoint("RIGHT", -14, 0)
    edit:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        self:ClearFocus()
        Set(w.option, text)
    end)
    Tooltip(edit, w)
    function w:Apply(item)
        self:Base(item)
        edit:Update(item.option.get(), item.disabled)
    end
    return w
end

function Widgets.range(parent)
    local w = Row(parent)
    local slider = CreateFrame("Frame", nil, w, "MinimalSliderWithSteppersTemplate")
    slider:SetWidth(160)
    slider:SetPoint("RIGHT", -50, 0) -- room for the value at its right
    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return tostring(math.floor(value * 100 + 0.5) / 100)
        end,
    }
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not w.applying and value ~= w.option.get() then Set(w.option, value) end
    end, w)
    Tooltip(slider.Slider, w)
    function w:Apply(item)
        self:Base(item)
        local option = item.option
        local value, min, max, step = option.get(), option.min, option.max, option.step or 1
        -- Left alone while unchanged, so a refresh never interrupts a drag.
        if self.min ~= min or self.max ~= max or self.step ~= step or slider.Slider:GetValue() ~= value then
            self.applying = true
            slider:Init(value, min, max, (max - min) / step, formatters)
            self.applying = false
            self.min, self.max, self.step = min, max, step
        end
        slider:SetEnabled(not item.disabled)
    end
    return w
end

function Widgets.select(parent)
    local w = Row(parent)
    local dropdown = CreateFrame("DropdownButton", nil, w, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(200)
    dropdown:SetPoint("RIGHT", -10, 0)
    Tooltip(dropdown, w)
    function w:Apply(item)
        self:Base(item)
        local option = item.option
        local values = Value(option, "values")
        local keys = option.sorting
        if not keys then
            keys = {}
            for key in pairs(values) do keys[#keys + 1] = key end
            table.sort(keys, function(a, b) return tostring(values[a]) < tostring(values[b]) end)
        end
        dropdown:SetupMenu(function(_, root)
            for _, key in ipairs(keys) do
                root:CreateRadio(values[key],
                    function() return option.get() == key end,
                    function() Set(option, key) end)
            end
        end)
        dropdown:SetEnabled(not item.disabled)
    end
    return w
end

function Widgets.color(parent)
    local w = Row(parent)
    local swatch = CreateFrame("Button", nil, w)
    swatch:SetSize(20, 20)
    swatch:SetPoint("RIGHT", -13, 0)
    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetColorTexture(1, 1, 1)
    border:SetPoint("CENTER")
    border:SetSize(16, 16)
    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    color:SetAllPoints()
    swatch:SetScript("OnClick", function()
        local option = w.option
        local r, g, b, a = option.get()
        local function Apply()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            Set(option, nr, ng, nb, option.hasAlpha and ColorPickerFrame:GetColorAlpha() or nil)
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a or 1, hasOpacity = option.hasAlpha,
            swatchFunc = Apply, opacityFunc = Apply,
            cancelFunc = function() Set(option, r, g, b, a) end,
        })
    end)
    w:SetScript("OnClick", function() if not w.disabled then swatch:Click() end end)
    Tooltip(swatch, w)
    function w:Apply(item)
        self:Base(item)
        color:SetVertexColor(item.option.get())
        swatch:SetEnabled(not item.disabled)
        swatch:SetAlpha(item.disabled and 0.4 or 1)
    end
    return w
end

function Widgets.keybinding(parent)
    local w = Row(parent)
    local button = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    button:SetSize(170, 22)
    button:SetPoint("RIGHT", -10, 0)
    local function Listen(listening)
        w.listening = listening
        button:EnableKeyboard(listening)
        if listening then button:SetText("Press a key...") end
    end
    button:SetScript("OnClick", function()
        Listen(not w.listening)
        if not w.listening then ScarletUI:RefreshSettings() end
    end)
    button:SetScript("OnKeyDown", function(_, key)
        -- A modifier on its own waits for the key it modifies.
        if key == "UNKNOWN" or key:find("SHIFT") or key:find("CTRL") or key:find("ALT") or key:find("META") then return end
        Listen(false)
        if key == "ESCAPE" then
            ScarletUI:RefreshSettings()
            return
        end
        if IsShiftKeyDown() then key = "SHIFT-" .. key end
        if IsControlKeyDown() then key = "CTRL-" .. key end
        if IsAltKeyDown() then key = "ALT-" .. key end
        Set(w.option, key)
    end)
    button:SetScript("OnHide", function() Listen(false) end)
    Tooltip(button, w)
    function w:Apply(item)
        self:Base(item)
        button:SetEnabled(not item.disabled)
        if item.disabled then Listen(false) end
        if not self.listening then
            local key = item.option.get()
            button:SetText(key and key ~= "" and (GetBindingText and GetBindingText(key) or key) or NOT_BOUND or "Not Bound")
        end
    end
    return w
end

-- One CVar: its name, override value, and the Default and Remove buttons.
function Widgets.cvar(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 28
    w:EnableMouse(true)
    Hover(w)
    local label = w:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 12, 0)
    label:SetWidth(270)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    local remove = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    remove:SetSize(70, 20)
    remove:SetPoint("RIGHT", -10, 0)
    local default = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    default:SetSize(70, 20)
    default:SetPoint("RIGHT", remove, "LEFT", -4, 0)
    local edit = EditBox(w, 110)
    edit:SetPoint("RIGHT", default, "LEFT", -10, 0)
    edit:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        self:ClearFocus()
        Set(w.cvar.input, text)
    end)
    default:SetScript("OnClick", function()
        w.cvar.clear.func()
        ScarletUI:RefreshSettings()
    end)
    remove:SetScript("OnClick", function()
        w.cvar.remove.func()
        ScarletUI:RefreshSettings()
    end)
    local tips = { [w] = {}, [edit] = {}, [default] = {}, [remove] = {} }
    for control, tip in pairs(tips) do Tooltip(control, tip) end
    function w:Apply(item)
        local cvar, off = item.cvar, item.disabled
        self.cvar = cvar
        local options = { [w] = cvar.label, [edit] = cvar.input, [default] = cvar.clear, [remove] = cvar.remove }
        for control, tip in pairs(tips) do
            tip.name, tip.desc = Value(cvar.label, "name"), Value(options[control], "desc")
        end
        label:SetText(tips[w].name)
        label:SetAlpha(off and 0.5 or 1)
        edit:Update(cvar.input.get(), off or Value(cvar.input, "disabled"))
        default:SetText(Value(cvar.clear, "name"))
        default:SetEnabled(not (off or Value(cvar.clear, "disabled")))
        remove:SetText(Value(cvar.remove, "name"))
        remove:SetEnabled(not off)
    end
    return w
end

-- Frames cannot be destroyed, so each render reuses the last one's widgets.
local pools, used = {}, {}
local function Acquire(kind)
    local pool = pools[kind] or {}
    pools[kind] = pool
    local n = (used[kind] or 0) + 1
    used[kind] = n
    pool[n] = pool[n] or Widgets[kind](content)
    pool[n]:Show()
    return pool[n]
end

local backgrounds = {}

local function Layout(items)
    for kind, pool in pairs(pools) do
        used[kind] = 0
        for _, widget in ipairs(pool) do widget:Hide() end
    end
    for _, background in ipairs(backgrounds) do background:Hide() end

    -- A darker panel behind each card's rows sets it apart from the next.
    local y, cardTop, cards = 0, nil, 0
    local function CloseCard()
        if not cardTop then return end
        cards = cards + 1
        local background = backgrounds[cards] or content:CreateTexture(nil, "BACKGROUND")
        backgrounds[cards] = background
        background:SetColorTexture(0, 0, 0, 0.3)
        background:ClearAllPoints()
        background:SetPoint("TOPLEFT", 0, -cardTop)
        background:SetSize(WIDTH, y - cardTop + 4)
        background:Show()
        y, cardTop = y + 14, nil
    end

    for _, item in ipairs(items) do
        local kind = item.title and "title" or item.card and "card" or item.cvar and "cvar" or item.option.type
        if item.title or item.card then CloseCard() end
        if item.card == "" then
            cardTop, y = y, y + 4
        elseif Widgets[kind] then
            local widget = Acquire(kind)
            widget:SetWidth(WIDTH)
            widget:Apply(item)
            if widget.height > 0 then
                widget:SetHeight(widget.height)
                widget:ClearAllPoints()
                widget:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
                y = y + widget.height
            else
                widget:Hide()
            end
            if item.card then cardTop = y end
        end
    end
    CloseCard()
    content:SetHeight(math.max(y, 1))
end

local function Resolve(options, path)
    local node = options
    for key in path:gmatch("[^.]+") do
        node = node and node.args and node.args[key]
    end
    return type(node) == "table" and node or nil
end

-- NAV against the live options: section headers and the pages that have at
-- least one group this client and character can see.
local function Entries()
    local options = ScarletUI:Options()
    local entries, listed, header = {}, {}, nil
    local function Add(spec)
        local page = { id = spec[1], master = spec.master, groups = {} }
        for _, path in ipairs(spec) do
            listed[path:match("^[^.]+")] = true
            local group = Resolve(options, path)
            if group and not Value(group, "hidden") then page.groups[#page.groups + 1] = group end
        end
        local first = page.groups[1]
        if not first then return end
        page.name = spec.name or Value(first, "name")
        page.desc = spec.desc or Value(first, "desc")
        if header then
            entries[#entries + 1] = { header = header }
            header = nil
        end
        entries[#entries + 1] = page
    end
    for _, spec in ipairs(NAV) do
        if spec.header then header = spec.header else Add(spec) end
    end
    for _, page in ipairs(Sorted(options.args)) do
        if not listed[page.key] then Add({ page.key }) end
    end
    return entries
end

local navButtons, navHeaders = {}, {}
local function NavButton(i)
    if navButtons[i] then return navButtons[i] end
    local button = CreateFrame("Button", nil, nav)
    button:SetHeight(24)
    button.selected = button:CreateTexture(nil, "BACKGROUND")
    button.selected:SetAllPoints()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    -- The recipe list's row art; quest log highlight where that is missing.
    if not Atlas(button.selected, "Professions_Recipe_Active") then
        button.selected:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        button.selected:SetBlendMode("ADD")
    end
    if not Atlas(highlight, "Professions_Recipe_Hover") then
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.5)
    end
    button.label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    button.label:SetPoint("LEFT", 12, 0)
    -- Lit while the page's feature is switched on.
    button.status = button:CreateTexture(nil, "ARTWORK")
    button.status:SetSize(12, 12)
    button.status:SetPoint("RIGHT", -8, 0)
    button:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        selected = self.id
        scroll:SetVerticalScroll(0)
        if search:GetText() ~= "" then
            search:SetText("") -- its OnTextChanged renders
        else
            Render()
        end
    end)
    navButtons[i] = button
    return button
end

function Render()
    local entries = Entries()
    local pages, current = {}, nil
    for _, entry in ipairs(entries) do
        if not entry.header then
            pages[#pages + 1] = entry
            if entry.id == selected or not current then current = entry end
        end
    end
    selected = current.id

    local y, buttons, headers = 6, 0, 0
    for _, entry in ipairs(entries) do
        if entry.header then
            headers = headers + 1
            local header = navHeaders[headers] or nav:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            navHeaders[headers] = header
            y = y + (headers > 1 and 10 or 2)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 12, -y)
            header:SetText(entry.header:upper())
            header:Show()
            y = y + 16
        else
            buttons = buttons + 1
            local button = NavButton(buttons)
            local active = not query and entry == current
            button.id = entry.id
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", 4, -y)
            button:SetPoint("TOPRIGHT", -4, -y)
            button.label:SetText(entry.name)
            button.label:SetFontObject(active and "GameFontHighlight" or "GameFontNormal")
            button.selected:SetShown(active)
            local switch, lit = entry.groups[1].args.enabled, nil
            if entry.master then
                lit = ScarletUI:IsSettingsPageEnabled(entry.id)
            elseif switch then
                lit = switch.get() and true or false
            end
            button.status:SetShown(lit ~= nil)
            if lit ~= nil then
                button.status:SetTexture(lit and "Interface\\COMMON\\Indicator-Green" or "Interface\\COMMON\\Indicator-Gray")
            end
            button:Show()
            y = y + 24
        end
    end
    for i = buttons + 1, #navButtons do navButtons[i]:Hide() end
    for i = headers + 1, #navHeaders do navHeaders[i]:Hide() end

    local items = {}
    -- A search covers every page; otherwise only the selected one is drawn.
    for _, page in ipairs(query and pages or { current }) do
        local title = #items + 1
        items[title] = { title = page.name, desc = page.desc }
        local off = page.master and not ScarletUI:IsSettingsPageEnabled(page.id)
        if page.master and not query then
            items[#items + 1] = { card = "" }
            items[#items + 1] = {
                master = true,
                -- A page whose group is disabled (Auction Prices without Auctionator) has no switch to flip.
                disabled = ScarletUI:InCombat() or Value(page.groups[1], "disabled") or false,
                option = {
                    type = "toggle",
                    name = "Enable " .. page.name,
                    desc = "Turn this off to switch off everything on this page. Turning it back on restores the settings you had.",
                    get = function() return not off end,
                    set = function(_, value) ScarletUI:SetSettingsPageEnabled(page, value) end,
                },
            }
        end
        local first = #items + 1
        PageItems(page, query, off, items)
        -- Other pages have their own switch among their settings.
        local switch = not page.master and page.groups[1].args.enabled
        for i = first, #items do
            if switch and items[i].option == switch then items[i].master = true end
        end
        if query and #items == title then items[title] = nil end
    end
    if #items == 0 then
        items[1] = { option = { type = "description", fontSize = "medium", name = "No settings match \"" .. query .. "\"." } }
    end
    Layout(items)
end

local function Build()
    frame = CreateFrame("Frame", "ScarletUISettings", UIParent, "PortraitFrameTemplate")
    frame:SetSize(820, 540)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "ScarletUISettings") -- Escape closes it

    if frame.SetTitle then frame:SetTitle("Scarlet UI") else frame.TitleText:SetText("Scarlet UI") end
    if frame.SetPortraitToAsset then frame:SetPortraitToAsset(ICON) else SetPortraitToTexture(frame.portrait, ICON) end

    search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    search:SetSize(200, 20)
    search:SetPoint("TOPLEFT", 72, -33)
    search:HookScript("OnTextChanged", function(self)
        local text = self:GetText():lower()
        query = text ~= "" and text or nil
        scroll:SetVerticalScroll(0)
        Render()
    end)

    nav = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    nav:SetPoint("TOPLEFT", 8, -62)
    nav:SetPoint("BOTTOMLEFT", 8, 8)
    nav:SetWidth(180)

    local pane = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    pane:SetPoint("TOPLEFT", nav, "TOPRIGHT", 4, 0)
    pane:SetPoint("BOTTOMRIGHT", -8, 8)

    -- ScrollFrameTemplate has the thin modern bar; older clients lack it.
    local ok
    ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, pane, "ScrollFrameTemplate")
    if not ok then scroll = CreateFrame("ScrollFrame", nil, pane, "UIPanelScrollFrameTemplate") end
    scroll:SetPoint("TOPLEFT", 12, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH, 1)
    scroll:SetScrollChild(content)

    frame:SetScript("OnShow", function()
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        Render()
    end)
    frame:SetScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
    -- Combat changes which settings are disabled.
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function() ScarletUI:RefreshSettings() end)
    -- Modules already announce changes to AceConfig; listen to the same call.
    LibStub("AceConfigRegistry-3.0").RegisterCallback(frame, "ConfigTableChange", function(_, app)
        if app == "ScarletUI" then ScarletUI:RefreshSettings() end
    end)
end

-- `show` forces it open or closed; nil toggles.
function ScarletUI:ToggleSettingsFrame(show)
    if not frame then Build() end
    if show == nil then show = not frame:IsShown() end
    frame:SetShown(show)
end
