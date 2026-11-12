-- Stat display: a small panel listing the character's combat stats for one
-- role (melee, ranged, or caster), kept current while it shows. Off by default.
-- The panel is drawn like the fishing bar: Blizzard's dialog border, an item
-- slot icon as the handle, gold labels and white values as on the character
-- sheet. Clicking the icon switches role (saved per character; the class picks
-- the first one), dragging it moves the panel, Ctrl-click resets the position.
-- The same line of stats is published as a LibDataBroker feed, "ScarletUI
-- Stats", for Titan Panel, ChocolateBar, and other broker displays.
-- Every client but Retail, whose stats (mastery, versatility) are not these.
local PADDING, ICON_SIZE, GAP, ROW_HEIGHT = 12, 28, 8, 16
local INTERVAL = 0.5 -- seconds between refreshes
local IsSecret = issecretvalue or function() return false end

-- Set when a stat meets a secret value: in combat some clients (Forever) hand
-- addons stats they may not read or do arithmetic on.
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
        { "Crit Chance", "Crit", function() return Percent(Sum((GetCritChance()))) end },
        { "Hit Chance", "Hit", function() return Percent(Hit(CR_HIT_MELEE, GetHitModifier)) end },
        { "Attack Speed", "Speed", function()
            local main, off = UnitAttackSpeed("player")
            main, off = Sum(main), Sum(off) -- no off hand: nil
            return main and (off and ("%.2f / %.2f"):format(main, off) or ("%.2f"):format(main))
        end },
    } },
    RANGED = { name = "Ranged", icon = "Interface\\Icons\\Ability_Marksmanship", stats = {
        { "Attack Power", "AP", function() return Whole(Sum(UnitRangedAttackPower("player"))) end },
        { "Crit Chance", "Crit", function() return Percent(Sum((GetRangedCritChance()))) end },
        { "Hit Chance", "Hit", function() return Percent(Hit(CR_HIT_RANGED, GetHitModifier)) end },
        { "Attack Speed", "Speed", function()
            local speed = Sum((UnitRangedDamage("player")))
            return speed and speed > 0 and ("%.2f"):format(speed) -- 0 with no ranged weapon
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
-- The role a class starts on; the rest start on melee.
local CLASS_SET = { HUNTER = "RANGED", MAGE = "CASTER", PRIEST = "CASTER", WARLOCK = "CASTER" }

function ScarletUI:SetupStatDisplay()
    if self.statDisplayFrame then
        -- Setup reruns after a settings reset.
        self:PlaceStatDisplay()
        self:UpdateStatDisplay()
        return
    end
    if self:GetWoWVersion() == "RETAIL" then return end

    -- Plain frames with no secure children, so the panel can change in combat.
    local panel = CreateFrame("Frame", "ScarletUIStatDisplay", UIParent)
    self.statDisplayFrame = panel
    CreateFrame("Frame", nil, panel, "DialogBorderDarkTemplate")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    function self:PlaceStatDisplay()
        local position = self.db.global.statDisplay.position
        panel:ClearAllPoints()
        if position then
            panel:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            panel:SetPoint("CENTER", UIParent, "CENTER", 320, 0)
        end
    end
    self:PlaceStatDisplay()

    -- The role's icon is the handle; its name sits beside it in the title font's gold.
    local handle = self:CreateIconButton(panel, ICON_SIZE)
    handle:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING, -PADDING)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", handle, "RIGHT", GAP, 0)

    local rows, last, current, feed = {}, {}, nil, nil
    local function Cycle()
        for index, key in ipairs(ORDER) do
            if key == current then
                self.db.char.statDisplay.set = ORDER[index % #ORDER + 1]
                break
            end
        end
        self:UpdateStatDisplay()
    end

    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() panel:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local point, _, relativePoint, x, y = panel:GetPoint()
        self.db.global.statDisplay.position = { point, relativePoint, x, y }
    end)
    handle:SetScript("OnClick", function()
        if IsControlKeyDown() then
            self.db.global.statDisplay.position = nil
            self:PlaceStatDisplay()
        else
            Cycle()
        end
    end)
    handle:SetScript("OnEnter", function()
        GameTooltip:SetOwner(handle, "ANCHOR_TOP")
        GameTooltip:AddLine(SETS[current].name .. " Stats")
        GameTooltip:AddLine("Click to switch between melee, ranged, and caster stats.", 1, 1, 1, true)
        GameTooltip:AddLine("Drag to move. Ctrl-click to reset its position.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    function self:UpdateStatDisplay()
        local enabled = self.db.global.statDisplay.enabled
        panel:SetShown(enabled)
        if not enabled then
            if feed then feed.text = "" end
            return
        end
        current = self.db.char.statDisplay.set
        if not SETS[current] then current = CLASS_SET[select(2, UnitClass("player"))] or "MELEE" end
        local set = SETS[current]
        -- Made on first use, so broker displays only list the feed once it is on.
        feed = feed or LibStub("LibDataBroker-1.1"):NewDataObject("ScarletUI Stats", {
            type = "data source", label = "Stats", text = "", OnClick = Cycle,
        })
        feed.icon = set.icon
        handle.texture:SetTexture(set.icon)
        title:SetText(set.name)

        local shown, labels, values, parts = 0, 0, 0, {}
        for index, stat in ipairs(set.stats) do
            local row = rows[index]
            if not row then
                row = {
                    label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
                    value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
                }
                rows[index] = row
            end
            -- Clients differ in which stat functions exist: one that is missing
            -- errors here and its row is left out. A stat that was readable
            -- and now is not (secret in combat) keeps the last text it had,
            -- so the panel holds its pre-combat values through a fight.
            unreadable = false
            local ok, text = pcall(stat[3])
            text = ok and text or nil
            if text or (ok and not unreadable) then
                last[stat] = text
            else
                text = last[stat]
            end
            row.label:SetShown(text ~= nil)
            row.value:SetShown(text ~= nil)
            if text then
                local y = -(PADDING + ICON_SIZE + GAP + shown * ROW_HEIGHT)
                row.label:SetText(stat[1])
                row.label:SetPoint("TOPLEFT", panel, "TOPLEFT", PADDING, y)
                row.value:SetText(text)
                row.value:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PADDING, y)
                shown = shown + 1
                labels = math.max(labels, row.label:GetStringWidth())
                values = math.max(values, row.value:GetStringWidth())
                parts[#parts + 1] = stat[2] .. " " .. text
            end
        end
        for index = #set.stats + 1, #rows do
            rows[index].label:Hide()
            rows[index].value:Hide()
        end
        -- The panel wraps the header and the two columns.
        panel:SetSize(PADDING * 2 + math.max(ICON_SIZE + GAP + title:GetStringWidth(), labels + GAP * 2 + values),
            PADDING * 2 + ICON_SIZE + GAP + shown * ROW_HEIGHT)
        feed.text = table.concat(parts, "  ")
    end

    -- ponytail: polls twice a second while shown instead of following each
    -- client's stat events (they differ, and miss some talent and aura
    -- changes). Register the events if the handful of calls ever shows up.
    local elapsed = 0
    panel:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < INTERVAL then return end
        elapsed = 0
        self:UpdateStatDisplay()
    end)
    self:UpdateStatDisplay()
end
