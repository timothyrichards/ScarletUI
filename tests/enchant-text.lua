-- Run from the addon root: lua tests/enchant-text.lua
-- Enchant text beside the character and inspect window slots.
local SLOT_NAMES = { "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
    "Finger0", "Finger1", "Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged" }
-- Globals this test replaces, put back at the end for the tests that run after it.
local TOUCHED = { "C_Item", "ENCHANTED_TOOLTIP_LINE", "GetInventorySlotInfo", "GetInventoryItemLink",
    "C_TooltipInfo", "C_Timer", "IsPlayerSpell", "InspectFrame", "CreateFrame",
    "ScarletUIEnchantScanTooltipTextLeft1", "ScarletUIEnchantScanTooltipTextLeft2" }
for _, name in ipairs(SLOT_NAMES) do
    TOUCHED[#TOUCHED + 1] = "Character" .. name .. "Slot"
    TOUCHED[#TOUCHED + 1] = "Inspect" .. name .. "Slot"
end
local saved = {}
for _, name in ipairs(TOUCHED) do
    saved[name] = _G[name]
end

local version = { "FOREVER", 16001 }
ScarletUI = { db = { global = { enchantText = true } } }
ScarletUI.GetWoWVersion = function() return version[1], version[2] end

-- Items by ID: equip location, class, subclass.
local ITEMS = {
    [1] = { "INVTYPE_HEAD", 4, 4 },
    [2] = { "INVTYPE_NECK", 4, 0 },
    [3] = { "INVTYPE_FINGER", 4, 0 },
    [4] = { "INVTYPE_WEAPON", 2, 7 },      -- sword
    [5] = { "INVTYPE_SHIELD", 4, 6 },
    [6] = { "INVTYPE_HOLDABLE", 4, 0 },
    [7] = { "INVTYPE_RANGEDRIGHT", 2, 3 }, -- gun
    [8] = { "INVTYPE_RANGEDRIGHT", 2, 19 }, -- wand
    [9] = { "INVTYPE_2HWEAPON", 2, 20 },   -- fishing pole
    [10] = { "INVTYPE_CLOAK", 4, 1 },
    [11] = { "INVTYPE_TRINKET", 4, 0 },
}
C_Item = {
    GetItemInfoInstant = function(link)
        local id = tonumber(link:match("item:(%d+)"))
        local item = ITEMS[id]
        return id, nil, nil, item[1], nil, item[2], item[3]
    end,
}
ENCHANTED_TOOLTIP_LINE = "Enchanted: %s"
dofile("Modules/EnchantText.lua")
local E = ScarletUI.EnchantText

-- Links
assert(E.EnchantID("|cff1eff00|Hitem:4:1900:0:0:0:0:0:0:60|h[Sword]|h|r") == 1900)
assert(E.EnchantID("|Hitem:4::::::::60:::::|h[Sword]|h") == nil)
assert(E.EnchantID("item:4:0:0:0") == nil)
assert(E.EnchantID(nil) == nil)
assert(E.Unenchanted("|Hitem:4:1900:0:0|h[Sword]|h") == "|Hitem:4::0:0|h[Sword]|h")
print("PASS: enchant ID read from the item link")

-- Shortening
assert(E.Shorten("+60 Strength") == "+60 Strength")
assert(E.Shorten("+50 Critical Strike") == "+50 Critical Strike")
assert(E.Shorten("+190 Attack Power") == "+190 Attack Power")
assert(E.Shorten("|cnGREEN_FONT_COLOR:+15 All Stats|r |A:Professions-ChatIcon-Quality-Tier3:20:20|a") == "+15 All Stats")
assert(E.Shorten("|cff00ff00+7 Stamina|r") == "+7 Stamina")
assert(E.Shorten("+12 Critical Strike Rating") == "+12 Critical Strike")
assert(E.Shorten("+30 Spell Damage and Healing") == "+30 Spell Dmg & Heal")
assert(E.Shorten("Mana Regen 4 per 5 sec.") == "Mana Regen 4 per...")
assert(E.Shorten("+4 Mana every 5 sec.") == "+4 Mana every 5 sec.")
assert(E.Shorten("+8 Healing and +4 Mana every 5 sec.") == "+8 Heal & +4 MP5")
local cut = E.Shorten("Lifestealing Weapon of Unusual Length")
assert(cut == "Lifestealing Weap..." and #cut == 20, cut)
print("PASS: enchant text stripped of markup and shortened to fit")

-- Finding the enchant line
local GREEN, WHITE = { r = 0.1, g = 1, b = 0.1 }, { r = 1, g = 1, b = 1 }
local function L(text, color) return { text = text, color = color } end
assert(E.FindLine({ L("Sword", WHITE), L("Enchanted: +60 Strength", GREEN) }) == "+60 Strength")
local classic = { L("Sword", WHITE), L("Equip: +5 Agility", GREEN), L("Crusader", GREEN), L("Durability 90 / 90", WHITE) }
local base = { L("Sword", WHITE), L("Equip: +5 Agility", GREEN), L("Durability 90 / 90", WHITE) }
assert(E.FindLine(classic) == nil, "no Enchanted: line on Classic")
assert(E.FindLine(classic, base) == "Crusader")
assert(E.FindLine({ L("Sword", WHITE), L("Socket", WHITE) }, { L("Sword", WHITE) }) == nil, "only green lines count")
assert(E.FindLine({ L("Sword"), L("+3 Agility") }, { L("Sword") }) == "+3 Agility", "uncolored lines are a fallback")
print("PASS: enchant line found by the Enchanted: prefix or against the unenchanted tooltip")

-- Which slots can be enchanted
local R = E.RULES
local function Can(client, slot, id, enchanter)
    local item = ITEMS[id]
    return E.CanEnchant(R[client], slot, item[2], item[3], item[1], enchanter)
end
assert(Can("FOREVER", "Head", 1) and Can("VANILLA", "Back", 10))
assert(not Can("FOREVER", "Neck", 2) and not Can("FOREVER", "Trinket0", 11))
assert(not Can("VANILLA", "Finger0", 3, true), "no ring enchants in Vanilla")
assert(Can("TBC", "Finger1", 3, true) and not Can("TBC", "Finger1", 3, false), "TBC rings are enchanter-only")
assert(Can("MOP", "Finger0", 3, true) and not Can("MOP", "Finger0", 3))
assert(Can("RETAIL", "Finger0", 3) and not Can("RETAIL", "Back", 10) and Can("RETAIL", "Head", 1))
assert(not Can("MOP", "Head", 1), "Mists has no head enchants")
assert(Can("VANILLA", "SecondaryHand", 5) and not Can("RETAIL", "SecondaryHand", 5), "shields")
assert(Can("RETAIL", "SecondaryHand", 4))
assert(not Can("TBC", "SecondaryHand", 6) and Can("CATA", "SecondaryHand", 6), "off-hand frills")
assert(Can("TBC", "Ranged", 7) and not Can("TBC", "Ranged", 8), "scopes on guns, not wands")
assert(not Can("FOREVER", "MainHand", 9), "fishing poles")
assert(not E.CanEnchant(nil, "Head", 4, 4, "INVTYPE_HEAD"), "unknown clients flag nothing")
print("PASS: enchantable slots per expansion, rings for enchanters, shields, frills, scopes")

-- The character window
local function FontString()
    local f = { shown = false }
    function f:SetFont() end
    function f:GetFont() return "Fonts\\FRIZQT__.TTF", 10 end
    function f:SetWordWrap() end
    function f:ClearAllPoints() self.point = nil end
    function f:SetPoint(point, _, relative) self.point = point .. ">" .. relative end
    function f:SetJustifyH() end
    function f:SetText(text) self.text = text end
    function f:SetTextColor(r, g, b) self.color = { r, g, b } end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    return f
end
local function Button()
    return { CreateFontString = function() return FontString() end, IsShown = function() return true end }
end
local slotIDs = {}
for index, name in ipairs(SLOT_NAMES) do
    slotIDs[name .. "Slot"] = index
    _G["Character" .. name .. "Slot"] = Button()
    _G["Inspect" .. name .. "Slot"] = Button()
end
GetInventorySlotInfo = function(name) return assert(slotIDs[name], name) end
local equipped = {}
GetInventoryItemLink = function(unit, slotID) return equipped[unit] and equipped[unit][slotID] end
local function Equip(unit, items)
    equipped[unit] = {}
    for slot, link in pairs(items) do
        equipped[unit][slotIDs[slot .. "Slot"]] = link
    end
end
local TIPS = {
    [1900] = "Crusader",
    [2504] = "+30 Spell Damage and Healing",
}
local tooltipCalls, loaded = 0, true
C_TooltipInfo = {
    GetHyperlink = function(link)
        tooltipCalls = tooltipCalls + 1
        if not loaded then return { lines = {} } end
        local lines = { { leftText = "Item", leftColor = WHITE } }
        local text = TIPS[E.EnchantID(link)]
        if text then lines[2] = { leftText = text, leftColor = GREEN } end
        return { lines = lines }
    end,
}
local timers = {}
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local function Label(prefix, slot) return _G[prefix .. slot .. "Slot"].scarletEnchant end

Equip("player", {
    Head = "item:1:2504:0", Neck = "item:2::0", Back = "item:10::0", Finger0 = "item:3::0",
    Trinket0 = "item:11::0", MainHand = "item:4:1900:0", SecondaryHand = "item:5::0", Ranged = "item:8::0",
})
ScarletUI:UpdateEnchantTexts("Character", "player")
local head = Label("Character", "Head")
assert(head.text == "+30 Spell Dmg & Heal" and head.shown and head.point == "LEFT>RIGHT", head.text)
assert(head.color[2] > 0.9 and head.color[1] < 0.3, "enchants are green")
assert(Label("Character", "MainHand").text == "Crusader" and Label("Character", "MainHand").point == "RIGHT>LEFT")
local back = Label("Character", "Back")
assert(back.text == "No enchant" and back.color[1] == 1 and back.color[2] < 0.3, "missing enchants are red")
local shield = Label("Character", "SecondaryHand")
assert(shield.text == "No enchant" and shield.point == "BOTTOM>TOP", "the middle weapon's text goes above it")
assert(Label("Character", "Neck") == nil and Label("Character", "Trinket0") == nil and Label("Character", "Finger0") == nil)
assert(Label("Character", "Ranged") == nil, "wands take no scope")
assert(Label("Character", "Hands") == nil, "empty slots stay blank")
print("PASS: character window enchants, No enchant on enchantable slots only, placed toward the model")

-- Enchant texts are cached by enchant ID; reads of an uncached item retry.
local calls = tooltipCalls
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(tooltipCalls == calls, "known enchants are not read again")
loaded = false
Equip("player", { Head = "item:1:2505:0" })
TIPS[2505] = "+8 Stamina"
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(not head.shown and #timers == 1, "an unloaded tooltip shows nothing and retries")
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(#timers == 1, "one retry at a time")
loaded = true
table.remove(timers)()
assert(head.shown and head.text == "+8 Stamina")
assert(not Label("Character", "Back").shown and not Label("Character", "MainHand").shown, "unequipped slots clear")
print("PASS: enchant cache, retry for uncached items, cleared slots")

-- Events while an item loads never give up on its enchant; the timed retries stop after three.
loaded = false
TIPS[2506] = "+10 Agility"
Equip("player", { Head = "item:1:2506:0" })
for _ = 1, 6 do
    ScarletUI:UpdateEnchantTexts("Character", "player") -- equip, inventory and inspect events
end
for _ = 1, 3 do
    assert(#timers == 1, "retries while the item is unread")
    table.remove(timers)()
end
assert(#timers == 0 and not head.shown, "timed retries stop after three")
loaded = true
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(head.shown and head.text == "+10 Agility", "a late-loading enchant is read on the next event")
print("PASS: unread enchants are never cached as missing; timed retries are capped")

-- The toggle hides everything.
ScarletUI.db.global.enchantText = false
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(not head.shown)
ScarletUI.db.global.enchantText = true
print("PASS: enchant toggle")

-- TBC: rings for an enchanter, never on inspect; the inspect window gets the same labels.
version = { "TBC", 20505 }
IsPlayerSpell = function(spellID) return spellID == 28029 end
Equip("player", { Finger0 = "item:3::0", Ranged = "item:7::0" })
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(Label("Character", "Finger0").text == "No enchant" and Label("Character", "Ranged").text == "No enchant")
InspectFrame = { unit = "target" }
Equip("target", { Finger0 = "item:3::0", Back = "item:10:1900:0" })
ScarletUI:UpdateEnchantTexts("Inspect", "target")
assert(Label("Inspect", "Finger0") == nil, "inspect can't tell whether the player enchants")
assert(Label("Inspect", "Back").text == "Crusader")
IsPlayerSpell = function() return false end
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(not Label("Character", "Finger0").shown, "rings need Enchanting in TBC")
print("PASS: TBC rings for enchanters, scopes, inspect window")

-- Mists and Retail have no ranged slot: the off hand's text goes to its right.
version = { "MOP", 50504 }
CharacterRangedSlot = nil
Equip("player", { MainHand = "item:4::0", SecondaryHand = "item:6::0" })
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(Label("Character", "SecondaryHand").point == "LEFT>RIGHT" and Label("Character", "MainHand").point == "RIGHT>LEFT")
print("PASS: two-weapon layout")

-- Classic tooltips: the enchant is the green line the unenchanted item lacks.
C_TooltipInfo = nil
ENCHANTED_TOOLTIP_LINE = nil
local tipLines, tipLink = {}, nil
CreateFrame = function()
    local tip = {}
    function tip:SetOwner() end
    function tip:ClearLines() end
    function tip:Hide() end
    function tip:SetHyperlink(link) tipLink = link end
    function tip:NumLines()
        tipLines = { { "Sword", WHITE } }
        if E.EnchantID(tipLink) then tipLines[2] = { "Fiery Weapon", GREEN } end
        for i, line in ipairs(tipLines) do
            _G["ScarletUIEnchantScanTooltipTextLeft" .. i] = {
                GetText = function() return line[1] end,
                GetTextColor = function() return line[2].r, line[2].g, line[2].b end,
            }
        end
        return #tipLines
    end
    return tip
end
version = { "VANILLA", 11507 }
CharacterRangedSlot = Button()
Equip("player", { MainHand = "item:4:803:0" })
ScarletUI:UpdateEnchantTexts("Character", "player")
assert(Label("Character", "MainHand").text == "Fiery Weapon")
print("PASS: hidden tooltip scan on clients without C_TooltipInfo")

CharacterRangedSlot = nil
for _, name in ipairs(TOUCHED) do
    _G[name] = saved[name]
end
