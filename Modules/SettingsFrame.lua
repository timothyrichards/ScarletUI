-- Prototype settings window (/sui new). It draws the same options table
-- AceConfig does (ScarletUI:Options()), so pages need no second definition,
-- but with Blizzard's own frame templates, which carry each client's skin.

local ICON = "Interface\\Icons\\INV_Misc_Gear_01"
local WIDTH = 580 -- scrolling content width
local UNIT = 170  -- one AceConfig width unit, so existing `width` hints carry over

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

-- Flattens a group into the rows to draw: { header = name } for each child
-- group that has visible settings, { option, disabled } for each setting.
-- `text` (lowercase) keeps only settings whose name or description contain it.
function ScarletUI:CollectSettings(group, text, items, disabled)
    items = items or {}
    disabled = disabled or Value(group, "disabled") or false
    for _, option in ipairs(Sorted(group.args)) do
        if not Value(option, "hidden") then
            if option.type == "group" then
                local header = #items + 1
                items[header] = { header = Value(option, "name") }
                self:CollectSettings(option, text, items, disabled)
                if #items == header then items[header] = nil end
            elseif not text or Matches(option, text) then
                items[#items + 1] = { option = option, disabled = disabled or Value(option, "disabled") or false }
            end
        end
    end
    return items
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

-- `control` shows the name and description of the widget it belongs to.
local function Tooltip(control, widget)
    control:SetScript("OnEnter", function(self)
        local name, desc = widget.name, widget.desc
        if (not name or name == "") and not desc then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if name and name ~= "" then
            GameTooltip:SetText(name, 1, 0.82, 0)
            if desc then GameTooltip:AddLine(desc, 1, 1, 1, true) end
        else
            GameTooltip:SetText(desc, 1, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Label(widget)
    local label = widget:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 2, -2)
    label:SetPoint("RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    return label
end

-- Each constructor returns a frame with Apply(option, name, disabled) and a
-- `height` the layout reads after Apply.
local Widgets = {}

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
        self.height = 34 + (item.desc and desc:GetStringHeight() + 4 or 0)
    end
    return w
end

-- The bronze bar Blizzard draws for list categories; plain gold text over a
-- rule on clients without that art.
function Widgets.header(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 36
    local left, right, middle = w:CreateTexture(nil, "BACKGROUND"), w:CreateTexture(nil, "BACKGROUND"), w:CreateTexture(nil, "BACKGROUND")
    if Atlas(left, "Professions-recipe-header-left", true) and Atlas(right, "Professions-recipe-header-right", true)
        and Atlas(middle, "Professions-recipe-header-middle") then
        left:SetPoint("BOTTOMLEFT", 0, 2)
        right:SetPoint("BOTTOMRIGHT", -6, 2)
        middle:SetPoint("TOPLEFT", left, "TOPRIGHT")
        middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
    else
        left:Hide()
        right:Hide()
        middle:SetColorTexture(0.6, 0.48, 0.28, 0.6)
        middle:SetPoint("BOTTOMLEFT", 0, 2)
        middle:SetPoint("BOTTOMRIGHT", -6, 2)
        middle:SetHeight(1)
    end
    local label = w:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", 10, 10)
    function w:Apply(item) label:SetText(item.header) end
    return w
end

function Widgets.description(parent)
    local w = CreateFrame("Frame", nil, parent)
    local text = w:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 2, -3)
    text:SetJustifyH("LEFT")
    Tooltip(w, w)
    function w:Apply(option, name)
        text:SetFontObject(option.fontSize == "medium" and "GameFontHighlight" or "GameFontHighlightSmall")
        text:SetWidth(self:GetWidth() - 10)
        text:SetText(name)
        -- An empty description is AceConfig's line break.
        self.height = name == "" and 0 or text:GetStringHeight() + 6
    end
    return w
end

function Widgets.toggle(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 28
    local check = CreateFrame("CheckButton", nil, w, "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("LEFT")
    local label = w:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetPoint("RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    check:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        Set(w.option, checked)
    end)
    Tooltip(check, w)
    function w:Apply(option, name, disabled)
        check:SetChecked(option.get() and true or false)
        check:SetEnabled(not disabled)
        label:SetFontObject(disabled and "GameFontDisable" or "GameFontHighlight")
        label:SetText(name)
        -- The label is part of the click target.
        check:SetHitRectInsets(0, -math.min(label:GetStringWidth() + 4, self:GetWidth() - 34), 0, 0)
    end
    return w
end

function Widgets.execute(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 28
    local button = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    button:SetHeight(22)
    button:SetPoint("LEFT")
    button:SetPoint("RIGHT", -8, 0)
    button:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        w.option.func()
        ScarletUI:RefreshSettings()
    end)
    Tooltip(button, w)
    function w:Apply(_, name, disabled)
        button:SetText(name)
        button:SetEnabled(not disabled)
    end
    return w
end

function Widgets.input(parent)
    local w = CreateFrame("Frame", nil, parent)
    local label = Label(w)
    local edit = CreateFrame("EditBox", nil, w, "InputBoxTemplate")
    edit:SetAutoFocus(false)
    edit:SetHeight(20)
    edit:SetPoint("BOTTOMLEFT", 7, 3)
    edit:SetPoint("BOTTOMRIGHT", -10, 3)
    edit:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        self:ClearFocus()
        Set(w.option, text)
    end)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        ScarletUI:RefreshSettings()
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    Tooltip(edit, w)
    function w:Apply(option, name, disabled)
        label:SetText(name)
        self.height = name == "" and 28 or 44
        if not edit:HasFocus() then
            edit:SetText(tostring(option.get() or ""))
            edit:SetCursorPosition(0)
        end
        edit:SetEnabled(not disabled)
        edit:SetTextColor(disabled and 0.5 or 1, disabled and 0.5 or 1, disabled and 0.5 or 1)
    end
    return w
end

function Widgets.range(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 46
    local label = Label(w)
    local slider = CreateFrame("Frame", nil, w, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("BOTTOMLEFT", 0, 2)
    slider:SetPoint("BOTTOMRIGHT", -46, 2) -- room for the value at its right
    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return tostring(math.floor(value * 100 + 0.5) / 100)
        end,
    }
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not w.applying and value ~= w.option.get() then Set(w.option, value) end
    end, w)
    Tooltip(slider.Slider, w)
    function w:Apply(option, name, disabled)
        label:SetText(name)
        local value, min, max, step = option.get(), option.min, option.max, option.step or 1
        -- Left alone while unchanged, so a refresh never interrupts a drag.
        if self.min ~= min or self.max ~= max or self.step ~= step or slider.Slider:GetValue() ~= value then
            self.applying = true
            slider:Init(value, min, max, (max - min) / step, formatters)
            self.applying = false
            self.min, self.max, self.step = min, max, step
        end
        slider:SetEnabled(not disabled)
    end
    return w
end

function Widgets.select(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 46
    local label = Label(w)
    local dropdown = CreateFrame("DropdownButton", nil, w, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", 0, 2)
    dropdown:SetPoint("BOTTOMRIGHT", -10, 2)
    Tooltip(dropdown, w)
    function w:Apply(option, name, disabled)
        label:SetText(name)
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
        dropdown:SetEnabled(not disabled)
    end
    return w
end

function Widgets.color(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 28
    local swatch = CreateFrame("Button", nil, w)
    swatch:SetSize(20, 20)
    swatch:SetPoint("LEFT", 3, 0)
    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetColorTexture(1, 1, 1)
    border:SetPoint("CENTER")
    border:SetSize(16, 16)
    local color = swatch:CreateTexture(nil, "ARTWORK")
    color:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    color:SetAllPoints()
    local label = w:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
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
    Tooltip(swatch, w)
    function w:Apply(option, name, disabled)
        color:SetVertexColor(option.get())
        label:SetText(name)
        label:SetFontObject(disabled and "GameFontDisable" or "GameFontHighlight")
        swatch:SetEnabled(not disabled)
        swatch:SetAlpha(disabled and 0.4 or 1)
    end
    return w
end

function Widgets.keybinding(parent)
    local w = CreateFrame("Frame", nil, parent)
    w.height = 46
    local label = Label(w)
    local button = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    button:SetHeight(22)
    button:SetPoint("BOTTOMLEFT", 0, 2)
    button:SetPoint("BOTTOMRIGHT", -8, 2)
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
    function w:Apply(option, name, disabled)
        label:SetText(name)
        button:SetEnabled(not disabled)
        if disabled then Listen(false) end
        if not self.listening then
            local key = option.get()
            button:SetText(key and key ~= "" and (GetBindingText and GetBindingText(key) or key) or NOT_BOUND or "Not Bound")
        end
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

local function Layout(items)
    for kind, pool in pairs(pools) do
        used[kind] = 0
        for _, widget in ipairs(pool) do widget:Hide() end
    end

    local x, y, rowHeight, row = 0, 0, 0, {}
    local function EndRow()
        for _, widget in ipairs(row) do
            widget:ClearAllPoints()
            widget:SetPoint("TOPLEFT", content, "TOPLEFT", widget.x, -(y + (rowHeight - widget.height) / 2))
        end
        if rowHeight > 0 then y = y + rowHeight + 4 end
        x, rowHeight, row = 0, 0, {}
    end

    for _, item in ipairs(items) do
        local option = item.option
        local kind = item.title and "title" or item.header and "header" or option.type
        if Widgets[kind] then
            local width = WIDTH
            if option and type(option.width) == "number" then
                width = math.min(WIDTH, option.width * UNIT)
            elseif option and option.width ~= "full" and kind ~= "description" then
                width = UNIT
            end
            if x > 0 and x + width > WIDTH then EndRow() end

            local widget = Acquire(kind)
            widget:SetWidth(width)
            if option then
                widget.option, widget.name, widget.desc = option, Value(option, "name") or "", Value(option, "desc")
                widget:Apply(option, widget.name, item.disabled)
            else
                widget:Apply(item)
            end
            widget:SetHeight(math.max(widget.height, 1))
            widget.x = x
            row[#row + 1] = widget
            x = x + width
            rowHeight = math.max(rowHeight, widget.height)
        end
    end
    EndRow()
    content:SetHeight(math.max(y, 1))
end

local navButtons = {}
local function NavButton(i)
    if navButtons[i] then return navButtons[i] end
    local button = CreateFrame("Button", nil, nav)
    button:SetHeight(24)
    button:SetPoint("TOPLEFT", 4, -5 - (i - 1) * 24)
    button:SetPoint("TOPRIGHT", -4, -5 - (i - 1) * 24)
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
    button.label:SetPoint("LEFT", 10, 0)
    button:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        selected = self.key
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
    local pages = {}
    for _, page in ipairs(Sorted(ScarletUI:Options().args)) do
        if not Value(page, "hidden") then pages[#pages + 1] = page end
    end

    local current = pages[1]
    for _, page in ipairs(pages) do
        if page.key == selected then current = page end
    end
    selected = current.key

    for i, page in ipairs(pages) do
        local button = NavButton(i)
        local active = not query and page == current
        button.key = page.key
        button.label:SetText(Value(page, "name"))
        button.label:SetFontObject(active and "GameFontHighlight" or "GameFontNormal")
        button.selected:SetShown(active)
        button:Show()
    end
    for i = #pages + 1, #navButtons do navButtons[i]:Hide() end

    local items = {}
    -- A search covers every page; otherwise only the selected one is drawn.
    for _, page in ipairs(query and pages or { current }) do
        local title = #items + 1
        items[title] = { title = Value(page, "name"), desc = Value(page, "desc") }
        ScarletUI:CollectSettings(page, query, items)
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

function ScarletUI:ToggleSettingsFrame()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end
