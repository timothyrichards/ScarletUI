-- Enchant text beside the equipment slots of the character and inspect windows:
-- the enchant in green, or "No enchant" in red on a slot that could hold one.
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local EnchantText = {}
ScarletUI.EnchantText = EnchantText

EnchantText.MAX_LENGTH = 20
EnchantText.NO_ENCHANT = "No enchant"

local GREEN = GREEN_FONT_COLOR or { r = 0.1, g = 1, b = 0.1 }
local RED = RED_FONT_COLOR or { r = 1, g = 0.1, b = 0.1 }

-- Which side of the slot faces the model. The weapon row is placed in UpdateEnchantTexts.
local SLOTS = {
    Head = "RIGHT", Neck = "RIGHT", Shoulder = "RIGHT", Back = "RIGHT", Chest = "RIGHT", Wrist = "RIGHT",
    Hands = "LEFT", Waist = "LEFT", Legs = "LEFT", Feet = "LEFT",
    Finger0 = "LEFT", Finger1 = "LEFT", Trinket0 = "LEFT", Trinket1 = "LEFT",
    MainHand = "LEFT", SecondaryHand = "RIGHT", Ranged = "RIGHT",
}

-- Slots each expansion can enchant (by Enchanting or by arcanums, inscriptions,
-- armor kits, spellthread and scopes). Hand-kept: neck, trinkets, shirt, tabard and
-- belt never count. `rings` is true where anyone can enchant them, "enchanter" where
-- only an enchanter can (only checked for the player, since inspect can't see professions).
local CLASSIC_ARMOR = { Head = true, Shoulder = true, Back = true, Chest = true, Wrist = true, Hands = true, Legs = true, Feet = true }
local VANILLA = { armor = CLASSIC_ARMOR, rings = false, shield = true, holdable = false, scope = true }
local BURNING_CRUSADE = { armor = CLASSIC_ARMOR, rings = "enchanter", shield = true, holdable = false, scope = true }
EnchantText.RULES = {
    VANILLA = VANILLA,
    FOREVER = VANILLA,
    TBC = BURNING_CRUSADE,
    WOTLK = BURNING_CRUSADE,
    CATA = { armor = CLASSIC_ARMOR, rings = "enchanter", shield = true, holdable = true, scope = true },
    -- Mists dropped head enchants and the ranged slot.
    MOP = {
        armor = { Shoulder = true, Back = true, Chest = true, Wrist = true, Hands = true, Legs = true, Feet = true },
        rings = "enchanter", shield = true, holdable = true, scope = false,
    },
    -- Midnight: helm, shoulders, chest, legs, boots, rings and weapons.
    RETAIL = {
        armor = { Head = true, Shoulder = true, Chest = true, Legs = true, Feet = true },
        rings = true, shield = false, holdable = false, scope = false,
    },
}

local WEAPON, FISHING_POLE = 2, 20
local SCOPED = { [2] = true, [3] = true, [18] = true } -- bows, guns, crossbows

function EnchantText.CanEnchant(rules, slot, classID, subClassID, equipLoc, hasEnchanting)
    if not rules then
        return false
    elseif rules.armor[slot] then
        return true
    elseif slot == "Finger0" or slot == "Finger1" then
        return rules.rings == true or (rules.rings == "enchanter" and hasEnchanting == true)
    elseif slot == "MainHand" then
        return classID == WEAPON and subClassID ~= FISHING_POLE
    elseif slot == "SecondaryHand" then
        if classID == WEAPON then
            return true
        elseif equipLoc == "INVTYPE_SHIELD" then
            return rules.shield
        elseif equipLoc == "INVTYPE_HOLDABLE" then
            return rules.holdable
        end
    elseif slot == "Ranged" then
        return rules.scope and classID == WEAPON and SCOPED[subClassID] == true
    end
    return false
end

-- The permanent enchant ID, the second field of the item string, or nil.
function EnchantText.EnchantID(link)
    local id = link and tonumber(link:match("item:%-?%d+:(%-?%d+)"))
    return id and id > 0 and id or nil
end

-- The same link with its enchant removed.
function EnchantText.Unenchanted(link)
    return (link:gsub("(item:%-?%d+:)%-?%d*", "%1", 1))
end

local function IsGreen(color)
    return color.g > 0.9 and color.r < 0.3 and color.b < 0.3
end

-- The enchant's line in an item's tooltip lines ({ text, color }). Retail-style
-- tooltips say "Enchanted: +60 Strength"; Classic ones show a bare green line, found
-- as the green line the unenchanted item's tooltip (baseLines) lacks.
function EnchantText.FindLine(lines, baseLines)
    local prefix, suffix
    if type(ENCHANTED_TOOLTIP_LINE) == "string" then
        prefix, suffix = ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s(.*)$")
    end
    if prefix then
        for _, line in ipairs(lines) do
            local text = line.text
            if #text > #prefix + #suffix and text:sub(1, #prefix) == prefix
                and (suffix == "" or text:sub(-#suffix) == suffix) then
                return text:sub(#prefix + 1, #text - #suffix)
            end
        end
    end
    if not baseLines then
        return nil
    end

    local seen = {}
    for _, line in ipairs(baseLines) do
        seen[line.text] = (seen[line.text] or 0) + 1
    end
    local uncolored
    for _, line in ipairs(lines) do
        if (seen[line.text] or 0) > 0 then
            seen[line.text] = seen[line.text] - 1
        elseif not line.color then
            uncolored = uncolored or line.text
        elseif IsGreen(line.color) then
            return line.text
        end
    end
    return uncolored
end

local CHARACTER = "[%z\1-\127\194-\244][\128-\191]*"

local function Length(text)
    local count = 0
    for _ in text:gmatch(CHARACTER) do
        count = count + 1
    end
    return count
end

local function Truncate(text, count)
    local characters = {}
    for character in text:gmatch(CHARACTER) do
        if #characters == count then
            break
        end
        characters[#characters + 1] = character
    end
    return table.concat(characters)
end

-- Tried in order until the text fits.
local ABBREVIATIONS = {
    { " Rating", "" },
    { "Critical Strike", "Crit" },
    { "Attack Power", "AP" },
    { "Spell Power", "SP" },
    { " and ", " & " },
    { "Damage", "Dmg" },
    { "Healing", "Heal" },
    { "Intellect", "Int" },
    { "Strength", "Str" },
    { "Agility", "Agi" },
    { "Stamina", "Stam" },
    { "Spirit", "Spi" },
    { "Defense", "Def" },
    { "Resistance", "Res" },
    { "Mana [epv]%a+ 5 [Ss]ec%a*%.?", "MP5" },
}

-- Strips markup (quality atlases, textures, colors) and shortens the text to fit
-- beside a slot: abbreviations first, then a cut with "...".
function EnchantText.Shorten(text, maxLength)
    maxLength = maxLength or EnchantText.MAX_LENGTH
    text = text:gsub("|A.-|a", ""):gsub("|T.-|t", ""):gsub("|cn.-:", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:match("^%s*(.-)%s*$")
    for _, abbreviation in ipairs(ABBREVIATIONS) do
        if Length(text) <= maxLength then
            return text
        end
        text = text:gsub(abbreviation[1], abbreviation[2])
    end
    if Length(text) <= maxLength then
        return text
    end
    return Truncate(text, maxLength - 3):match("^(.-)%s*$") .. "..."
end

local function Readable(text)
    return type(text) == "string" and not (issecretvalue and issecretvalue(text)) and text ~= ""
end

local scanTooltip
local function TooltipLines(link)
    local lines = {}
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local data = C_TooltipInfo.GetHyperlink(link)
        for _, line in ipairs(data and data.lines or {}) do
            if Readable(line.leftText) then
                local color = line.leftColor
                lines[#lines + 1] = { text = line.leftText, color = color and { r = color.r, g = color.g, b = color.b } }
            end
        end
        return lines
    end

    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", "ScarletUIEnchantScanTooltip", nil, "GameTooltipTemplate")
    end
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(link)
    for i = 1, scanTooltip:NumLines() do
        local fontString = _G["ScarletUIEnchantScanTooltipTextLeft" .. i]
        local text = fontString and fontString:GetText()
        if Readable(text) then
            local r, g, b = fontString:GetTextColor()
            lines[#lines + 1] = { text = text, color = { r = r, g = g, b = b } }
        end
    end
    scanTooltip:Hide()
    return lines
end

-- Enchant text by enchant ID. Only found texts are kept: an enchant that can't be
-- read yet (item data still loading) is read again on the next update.
local texts = {}
EnchantText.cache = texts
-- Timed retries after an update leaves an enchant unread. Events start the count over.
local MAX_RETRIES = 3

local function ReadEnchant(link, enchantID)
    if texts[enchantID] then
        return texts[enchantID]
    end
    local lines = TooltipLines(link)
    if #lines > 0 then
        local text = EnchantText.FindLine(lines) or EnchantText.FindLine(lines, TooltipLines(EnchantText.Unenchanted(link)))
        if text then
            texts[enchantID] = EnchantText.Shorten(text)
            return texts[enchantID]
        end
    end
    return nil
end

local ENCHANTING = 333
local ENCHANTING_RANKS = { 7411, 7412, 7413, 13920, 28029, 51313, 74258 }

local function PlayerHasEnchanting()
    if GetProfessions and GetProfessionInfo then
        local first, second = GetProfessions()
        for _, index in ipairs({ first or false, second or false }) do
            if index and select(7, GetProfessionInfo(index)) == ENCHANTING then
                return true
            end
        end
    end
    if IsPlayerSpell then
        for _, spellID in ipairs(ENCHANTING_RANKS) do
            if IsPlayerSpell(spellID) then
                return true
            end
        end
    end
    return false
end

local function Label(button)
    local label = button.scarletEnchant
    if not label then
        label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetFont(label:GetFont(), 10, "OUTLINE")
        if label.SetWordWrap then
            label:SetWordWrap(false)
        end
        button.scarletEnchant = label
    end
    return label
end

local function Place(label, button, side)
    if label.side == side then
        return
    end
    label.side = side
    label:ClearAllPoints()
    if side == "RIGHT" then
        label:SetPoint("LEFT", button, "RIGHT", 5, 0)
        label:SetJustifyH("LEFT")
    elseif side == "LEFT" then
        label:SetPoint("RIGHT", button, "LEFT", -5, 0)
        label:SetJustifyH("RIGHT")
    else
        label:SetPoint("BOTTOM", button, "TOP", 0, 4)
        label:SetJustifyH("CENTER")
    end
end

-- prefix is the slot buttons' name prefix: "Character" or "Inspect". retries counts
-- the timed rereads so far; event-driven calls leave it nil.
function ScarletUI:UpdateEnchantTexts(prefix, unit, retries)
    local versionText, interfaceVersion = self:GetWoWVersion()
    local rules = EnchantText.RULES[versionText]
    local enabled = self.db.global.enchantText and unit
    local hasEnchanting = enabled and unit == "player" and rules and rules.rings == "enchanter" and PlayerHasEnchanting()
    local rangedButton = interfaceVersion < 50000 and _G[prefix .. "RangedSlot"]
    local threeWeapons = rangedButton and rangedButton:IsShown()
    local unread = false

    for slot, side in pairs(SLOTS) do
        local button = _G[prefix .. slot .. "Slot"]
        if button and (slot ~= "Ranged" or rangedButton) then
            local text, color
            if enabled then
                local link = GetInventoryItemLink(unit, GetInventorySlotInfo(slot .. "Slot"))
                local enchantID = EnchantText.EnchantID(link)
                if enchantID then
                    text, color = ReadEnchant(link, enchantID), GREEN
                    unread = unread or not text
                elseif link then
                    local _, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(link)
                    if EnchantText.CanEnchant(rules, slot, classID, subClassID, equipLoc, hasEnchanting) then
                        text, color = EnchantText.NO_ENCHANT, RED
                    end
                end
            end

            if text then
                local label = Label(button)
                if slot == "SecondaryHand" and threeWeapons then
                    side = "TOP"
                end
                Place(label, button, side)
                label:SetText(text)
                label:SetTextColor(color.r, color.g, color.b)
                label:Show()
            elseif button.scarletEnchant then
                button.scarletEnchant:Hide()
            end
        end
    end

    -- Uncached items have no tooltip yet; read them again in a moment.
    retries = retries or 0
    self.enchantRetry = self.enchantRetry or {}
    if unread and retries < MAX_RETRIES and not self.enchantRetry[prefix] then
        self.enchantRetry[prefix] = true
        C_Timer.After(1, function()
            self.enchantRetry[prefix] = nil
            self:UpdateEnchantTexts(prefix, prefix == "Inspect" and InspectFrame and InspectFrame.unit or unit, retries + 1)
        end)
    end
end
