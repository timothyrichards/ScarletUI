-- Stat display: the character's combat stats for up to three roles (melee,
-- ranged, caster), kept current while shown. Off by default. Each role is
-- switched on per character (the class picks the first one) and drawn like the
-- fishing bar: Blizzard's dialog border, an item slot icon as the handle, gold
-- labels and white values as on the character sheet. The layout is either one
-- panel holding the roles or a panel per role; dragging a role's icon moves
-- its panel, Ctrl-click resets the position. A role's stats stack vertically
-- (rows) or horizontally (one line, label above value).
-- The same stats are published as a LibDataBroker feed, "ScarletUI Stats", for
-- Titan Panel, ChocolateBar, and other broker displays.
-- Every client but Retail, whose stats (mastery, versatility) are not these.
local PADDING, ICON_SIZE, GAP, ROW_HEIGHT = 12, 28, 8, 16
local SPLIT_STEP = 130 -- default vertical spacing of the separate panels
local INTERVAL = 0.5 -- seconds between refreshes
local IsSecret = issecretvalue or function() return false end

-- In combat some clients (Forever) hand addons secret values: they can be
-- formatted and shown, but not compared or added. `unreadable` is set when a
-- stat needed arithmetic on one.
local unreadable

-- The total of the numbers given, or nil when one is missing or secret.
local function Sum(...)
    local total = 0
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if IsSecret(value) then
            unreadable = true
            return nil
        end
        if type(value) ~= "number" then return nil end
        total = total + value
    end
    return total
end

-- One number as text. A secret one formats into a secret string, which a font
-- string can still show, so these stats stay live in combat.
local function One(format, value)
    return type(value) == "number" and format:format(value) or nil
end

local function Whole(value) return value and ("%.0f"):format(value) end
local function Percent(value) return value and ("%.2f%%"):format(value) end

-- Hit from rating (TBC and later) plus the talent and gear modifier, as
-- Blizzard's character sheet adds them. Era's spell modifier is nil at zero.
local function Hit(rating, modifier)
    return Sum(GetCombatRatingBonus and rating and GetCombatRatingBonus(rating) or 0, modifier and modifier() or 0)
end

-- The highest value across the six magic schools (Holy through Arcane).
local function BestSchool(get)
    local best
    for school = 2, 7 do
        local value = Sum((get(school)))
        if value and (not best or value > best) then best = value end
    end
    return best
end

-- Each stat: its label on the panel, its label in the broker feed, and a
-- function returning the text to show, or nil to leave the row out.
local ORDER = { "MELEE", "RANGED", "CASTER" }
local SETS = {
    MELEE = { name = "Melee", icon = "Interface\\Icons\\Ability_MeleeDamage", stats = {
        { "Attack Power", "AP", function() return Whole(Sum(UnitAttackPower("player"))) end },
        { "Crit Chance", "Crit", function() return One("%.2f%%", (GetCritChance())) end },
        { "Hit Chance", "Hit", function() return Percent(Hit(CR_HIT_MELEE, GetHitModifier)) end },
        { "Attack Speed", "Speed", function()
            local main, off = UnitAttackSpeed("player")
            return off and ("%.2f / %.2f"):format(main, off) or One("%.2f", main) -- no off hand: nil
        end },
    } },
    RANGED = { name = "Ranged", icon = "Interface\\Icons\\Ability_Marksmanship", stats = {
        { "Attack Power", "AP", function() return Whole(Sum(UnitRangedAttackPower("player"))) end },
        { "Crit Chance", "Crit", function() return One("%.2f%%", (GetRangedCritChance())) end },
        { "Hit Chance", "Hit", function() return Percent(Hit(CR_HIT_RANGED, GetHitModifier)) end },
        { "Attack Speed", "Speed", function()
            local speed = UnitRangedDamage("player")
            if not IsSecret(speed) and (type(speed) ~= "number" or speed <= 0) then return nil end -- 0: no ranged weapon
            return One("%.2f", speed)
        end },
    } },
    CASTER = { name = "Caster", icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", stats = {
        { "Spell Power", "SP", function() return Whole(BestSchool(GetSpellBonusDamage)) end },
        -- Left out where healing is just spell power (Mists).
        { "Healing", "Heal", function()
            local healing = Sum((GetSpellBonusHealing()))
            return healing ~= BestSchool(GetSpellBonusDamage) and Whole(healing)
        end },
        { "Crit Chance", "Crit", function() return Percent(BestSchool(GetSpellCritChance)) end },
        { "Hit Chance", "Hit", function() return Percent(Hit(CR_HIT_SPELL, GetSpellHitModifier)) end },
        -- GetManaRegen is per second: out of casting, then while casting.
        { "MP5 (Casting)", "MP5", function()
            local _, casting = GetManaRegen()
            casting = Sum(casting)
            return casting and Whole(casting * 5)
        end },
    } },
}
-- The role a class starts with; the rest start with melee.
local CLASS_SET = { HUNTER = "RANGED", MAGE = "CASTER", PRIEST = "CASTER", WARLOCK = "CASTER" }

-- Roles are switched per character; one never switched follows the class.
function ScarletUI:IsStatRoleShown(key)
    local shown = self.db.char.statDisplay.roles[key]
    if shown == nil then shown = (CLASS_SET[select(2, UnitClass("player"))] or "MELEE") == key end
    return shown
end

function ScarletUI:SetupStatDisplay()
    if self.statDisplayFrame then
        -- Setup reruns after a settings reset.
        self:PlaceStatDisplay()
        return
    end
    if self:GetWoWVersion() == "RETAIL" then return end

    -- Plain frames with no secure children, so everything can change in combat.
    -- `panel` is the one-panel layout's frame; in the other layout each role's
    -- section stands alone with its own border.
    local panel = CreateFrame("Frame", "ScarletUIStatDisplay", UIParent)
    self.statDisplayFrame = panel
    CreateFrame("Frame", nil, panel, "DialogBorderDarkTemplate")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)

    local sections, last, widths, feed = {}, {}, {}, nil
    local function Combined() return self.db.global.statDisplay.layout ~= "SPLIT" end

    for _, key in ipairs(ORDER) do
        local set = SETS[key]
        local section = CreateFrame("Frame", "ScarletUIStatDisplay" .. set.name, UIParent)
        sections[key] = section
        section.border = CreateFrame("Frame", nil, section, "DialogBorderDarkTemplate")
        section.rows = {}
        section:SetMovable(true)
        section:SetClampedToScreen(true)

        -- The role's icon is the handle; its name sits beside it in the title font's gold.
        local handle = self:CreateIconButton(section, ICON_SIZE)
        handle:SetPoint("TOPLEFT", section, "TOPLEFT", PADDING, -PADDING)
        handle.texture:SetTexture(set.icon)
        section.title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        section.title:SetPoint("LEFT", handle, "RIGHT", GAP, 0)
        section.title:SetText(set.name)

        -- What a drag moves, and where its position is kept: the shared panel or this role's own.
        local function Moved()
            local settings = self.db.global.statDisplay
            if Combined() then return panel, settings, "position" end
            return section, settings.positions, key
        end
        handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart", function() Moved():StartMoving() end)
        handle:SetScript("OnDragStop", function()
            local frame, store, field = Moved()
            frame:StopMovingOrSizing()
            local point, _, relativePoint, x, y = frame:GetPoint()
            store[field] = { point, relativePoint, x, y }
        end)
        handle:SetScript("OnClick", function()
            if not IsControlKeyDown() then return end
            local _, store, field = Moved()
            store[field] = nil
            self:PlaceStatDisplay()
        end)
        handle:SetScript("OnEnter", function()
            GameTooltip:SetOwner(handle, "ANCHOR_TOP")
            GameTooltip:AddLine(set.name .. " Stats")
            GameTooltip:AddLine("Drag to move. Ctrl-click to reset its position.", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end)
    end

    local function Place(frame, position, y)
        frame:ClearAllPoints()
        if position then
            frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 320, y)
        end
    end

    -- Applies the layout and saved positions, then refreshes. Not part of the
    -- refresh itself, which would pull a panel back mid-drag.
    function self:PlaceStatDisplay()
        local settings = self.db.global.statDisplay
        local combined = Combined()
        Place(panel, settings.position, 0)
        for index, key in ipairs(ORDER) do
            local section = sections[key]
            section:SetParent(combined and panel or UIParent)
            section.border:SetShown(not combined)
            if not combined then Place(section, settings.positions[key], (2 - index) * SPLIT_STEP) end
        end
        self:UpdateStatDisplay()
    end

    -- Fills a role's stats and sizes its section; returns the size and the feed
    -- text. Stacked vertically, each stat is a row, label left and value right.
    -- Horizontally, the stats run along one line after the role's name, label
    -- above value; `titleWidth` is the widest name, so every role's line
    -- starts at the same place.
    local function Fill(section, set, horizontal, titleWidth)
        local shown, labels, values, parts = 0, 0, 0, {}
        local x = PADDING + ICON_SIZE + GAP + titleWidth + GAP * 2 -- the next stat on a horizontal line
        for index, stat in ipairs(set.stats) do
            local row = section.rows[index]
            if not row then
                row = {
                    label = section:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
                    value = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
                }
                section.rows[index] = row
            end
            -- Clients differ in which stat functions exist: one that is missing
            -- errors here and its row is left out. `plain` is the text that may
            -- be measured and published: the stat's own, or for a stat that is
            -- secret or unreadable (in combat), the last readable one.
            unreadable = false
            local ok, text = pcall(stat[3])
            text = ok and text or nil
            local secret, plain = IsSecret(text), text
            if secret then
                plain = last[stat]
            elseif text or (ok and not unreadable) then
                last[stat] = text
            else
                text, plain = last[stat], last[stat]
            end
            local visible = secret or text ~= nil
            row.label:SetShown(visible)
            row.value:SetShown(visible)
            if visible then
                row.label:SetText(stat[1])
                -- A secret text is shown live; if the client refuses it, the last readable one stands in.
                if not (secret and pcall(row.value.SetText, row.value, text)) then
                    row.value:SetText(plain or "")
                end
                if not secret then
                    local width = row.value:GetStringWidth()
                    if not IsSecret(width) then widths[stat] = width end
                end
                local labelWidth, valueWidth = row.label:GetStringWidth(), widths[stat] or 0
                -- The two layouts anchor by different points, so the old ones go first.
                row.label:ClearAllPoints()
                row.value:ClearAllPoints()
                if horizontal then
                    row.label:SetPoint("TOPLEFT", section, "TOPLEFT", x, -PADDING)
                    row.value:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", x, PADDING)
                    x = x + math.max(labelWidth, valueWidth) + GAP * 2
                else
                    local y = -(PADDING + ICON_SIZE + GAP + shown * ROW_HEIGHT)
                    row.label:SetPoint("TOPLEFT", section, "TOPLEFT", PADDING, y)
                    row.value:SetPoint("TOPRIGHT", section, "TOPRIGHT", -PADDING, y)
                end
                shown = shown + 1
                labels, values = math.max(labels, labelWidth), math.max(values, valueWidth)
                if plain then parts[#parts + 1] = stat[2] .. " " .. plain end
            end
        end
        for index = #set.stats + 1, #section.rows do
            section.rows[index].label:Hide()
            section.rows[index].value:Hide()
        end
        -- The section wraps its header and its stats: a line as tall as the icon, or two columns below it.
        local width, height = x - GAP * 2 + PADDING, PADDING * 2 + ICON_SIZE
        if not horizontal then
            width = PADDING * 2 + math.max(ICON_SIZE + GAP + section.title:GetStringWidth(), labels + GAP * 2 + values)
            height = height + GAP + shown * ROW_HEIGHT
        end
        section:SetSize(width, height)
        return width, height, table.concat(parts, "  ")
    end

    -- ponytail: polls twice a second while on instead of following each
    -- client's stat events (they differ, and miss some talent and aura
    -- changes). Register the events if the handful of calls ever shows up.
    local ticker, elapsed = CreateFrame("Frame"), 0
    ticker:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < INTERVAL then return end
        elapsed = 0
        self:UpdateStatDisplay()
    end)

    function self:UpdateStatDisplay()
        local settings = self.db.global.statDisplay
        local combined, horizontal = Combined(), settings.orientation == "HORIZONTAL"
        local titleWidth = 0
        for _, section in pairs(sections) do
            titleWidth = math.max(titleWidth, section.title:GetStringWidth())
        end
        -- One panel: roles run across it when their stats stack vertically, and
        -- down it when each is a horizontal line. `along` is that direction.
        local along, across, texts, icon = 0, 0, {}, nil
        for _, key in ipairs(ORDER) do
            local section = sections[key]
            local shown = settings.enabled and self:IsStatRoleShown(key)
            section:SetShown(shown)
            if shown then
                local width, height, text = Fill(section, SETS[key], horizontal, titleWidth)
                if combined then
                    section:ClearAllPoints()
                    section:SetPoint("TOPLEFT", panel, "TOPLEFT", horizontal and 0 or along, horizontal and -along or 0)
                end
                if horizontal then width, height = height, width end
                along, across = along + width, math.max(across, height)
                texts[#texts + 1] = text
                icon = icon or SETS[key].icon
            end
        end
        panel:SetShown(combined and along > 0)
        panel:SetSize(horizontal and across or along, horizontal and along or across)
        ticker:SetShown(settings.enabled)
        -- Made on first use, so broker displays only list the feed once it is on.
        if settings.enabled and not feed then
            feed = LibStub("LibDataBroker-1.1"):NewDataObject("ScarletUI Stats", {
                type = "data source", label = "Stats", text = "",
            })
        end
        if feed then
            feed.text = table.concat(texts, "  |  ")
            feed.icon = icon or feed.icon
        end
    end

    self:PlaceStatDisplay()
end
