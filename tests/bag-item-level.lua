-- Run from the addon root: lua tests/bag-item-level.lua
local function noop() end
local contents = { [0] = { 101, 202 }, [-1] = { 303 } }
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 2 or 1 end,
    GetContainerItemLink = function(bag, slot) return contents[bag][slot] end,
}
C_Item = {
    GetItemInfo = function(link) return "Item", nil, 1, link, nil, "Armor" end,
    GetItemLink = function(location) return contents[location.bag][location.slot] end,
    GetCurrentItemLevel = function(location) return contents[location.bag][location.slot] end,
}
ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot)
    return { bag = bag, slot = slot, IsValid = function() return contents[bag][slot] ~= nil end }
end }
ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 } }
NUM_CONTAINER_FRAMES, BANK_CONTAINER, BACKPACK_CONTAINER, NUM_BAG_SLOTS = 1, -1, 0, 0
C_Timer = { After = function(_, callback) callback() end }
CharacterFrame = { HookScript = noop }
EventRegistry = { RegisterCallback = noop }
hooksecurefunc = noop

local function button(bag, slot)
    return {
        GetBagID = function() return bag end,
        GetID = function() return slot end,
        GetItemLocation = function() return ItemLocation:CreateFromBagAndSlot(bag, slot) end,
        GetChildren = function() end,
        IsShown = function() return true end,
        GetWidth = function() return 37 end,
        GetHeight = function() return 37 end,
        CreateFontString = function()
            return {
                shown = true,
                SetFontObject = noop, SetTextColor = noop, SetPoint = noop, SetAtlas = noop, SetHeight = noop,
                SetShadowColor = noop, SetShadowOffset = noop, SetFont = noop,
                SetTexture = noop, SetBlendMode = noop, SetVertexColor = noop, SetSize = noop,
                GetFont = function() return "Font", 12 end,
                SetText = function(self, value) self.text = value end,
                Show = function(self) self.shown = true end,
                Hide = function(self) self.shown = false end,
                SetShown = function(self, shown) self.shown = shown end,
            }
        end,
        CreateTexture = function(self) return self:CreateFontString() end,
    }
end

for _, modern in ipairs({ false, true }) do
    local first, second, bank = button(0, 1), button(0, 2), button(-1, 1)
    contents[0][1] = 101
    ContainerFrame1 = {
        GetID = function() return 0 end, IsShown = function() return true end, HookScript = noop,
        GetName = function() return "ContainerFrame1" end,
    }
    -- Legacy Blizzard bag buttons are numbered in reverse slot order.
    ContainerFrame1Item1, ContainerFrame1Item2 = second, first
    ContainerFrameCombinedBags = { EnumerateValidItems = function() return ipairs({ first, second }) end }
    BankFrameItem1 = bank
    BankFrame = { IsShown = function() return true end, GetChildren = function() return bank end }
    ScarletUI = { retail = modern, db = { global = { itemLevelBag = true } }, events = {} }
    ScarletUI.RegisterEventHandler = function(self, event, callback) self.events[event] = callback end
    dofile("Modules/ItemLevel.lua")
    dofile("Modules/CheapestItem.lua")
    ScarletUI:SetupItemLevels()
    assert(first.itemLevel.text == 101 and second.itemLevel.text == 202)
    assert(bank.itemLevel.text == 303, "Native bank item level missing")
    contents[0][1] = 404
    ScarletUI.events.BAG_UPDATE()
    assert(first.itemLevel.text == 404, "Bag event did not refresh item level")
    ScarletUI.events.BANKFRAME_OPENED()
    ScarletUI.events.PLAYERBANKSLOTS_CHANGED()
    assert(bank.itemLevel.text == 303)
    contents[0][1] = nil
    ScarletUI.events.BAG_UPDATE()
    assert(not first.itemLevel.shown, "Empty slot kept a stale item level")
    ScarletUI.db.global.itemLevelBag = false
    ScarletUI:BagItemLevel()
    assert(not second.itemLevel.shown and not bank.itemLevel.shown, "Item-level toggle failed")
    ScarletUI.db.global.itemLevelBag = true
    ScarletUI:BagItemLevel()
    assert(second.itemLevel.shown and bank.itemLevel.shown)
end
print("PASS: native Classic and modern bag/bank item levels, events, empty slots, and toggle")

-- The cheapest stack by sell price x count is outlined; unsellable items, consumables,
-- spell and crafting reagents, quest items, tools, and equipment set items are ignored.
-- Items are { sell price, class, subclass, is crafting reagent }.
local items = { [1] = { 3, 15 }, [2] = { 10, 15 }, [3] = { 0, 15 }, [4] = { 1, 0 }, [5] = { 1, 12 },
    [6] = { 1, 15 }, [7] = { 1, 2, 20 }, [8] = { 1, 19 }, [9] = { 1, 4 }, [10] = { 1, 7 },
    [11] = { 1, 3, nil, true }, [12] = { 1, 5 }, [2901] = { 1, 15 } }
local stacks = { { itemID = 1, stackCount = 5 }, { itemID = 2, stackCount = 1 } }
C_Container.GetContainerItemInfo = function(bag, slot) return stacks[slot] end
C_Container.GetContainerItemQuestInfo = function(bag, slot)
    return { isQuestItem = false, questID = stacks[slot].itemID == 6 and 1234 or nil }
end
C_Item.GetItemInfo = function(id)
    local item = items[id]
    return "Item", nil, 1, 1, nil, "Junk", nil, nil, nil, nil, item[1], item[2], item[3], nil, nil, nil, item[4]
end
local pricey, cheap, custom = button(0, 1), button(0, 2), button(0, 2)
-- Unopened Blizzard frames enumerate empty entries up to their bag size.
local enumerated = { pricey, nil, cheap }
ContainerFrameCombinedBags = { EnumerateValidItems = function()
    return function(_, i) if i < 3 then return i + 1, enumerated[i + 1] end end, nil, 0
end }
ContainerFrame1Item1, ContainerFrame1Item2 = cheap, pricey
ScarletUI = { db = { global = { highlightCheapestItem = true } }, bagSlots = { [2] = custom } }
dofile("Modules/CheapestItem.lua")
-- No C_EquipmentSet yet: Era and TBC have no Equipment Manager.
ScarletUI:UpdateCheapestItem()
assert(cheap.cheapestGlow.shown and custom.cheapestGlow.shown, "Cheapest stack not highlighted")
assert(not pricey.cheapestGlow, "Stack worth more in total was highlighted")
-- Set item lists are keyed by equipment slot and can have holes.
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 0 } end,
    GetItemIDs = function(setID) assert(setID == 0); return { [1] = 50, [16] = 9 } end,
}
for id, kind in pairs({ [3] = "Unsellable item", [4] = "Consumable", [5] = "Quest item", [6] = "Quest starter",
    [7] = "Fishing pole", [8] = "Retail profession tool", [9] = "Equipment set item", [10] = "Trade good",
    [11] = "Crafting reagent", [12] = "Spell reagent", [2901] = "Mining Pick" }) do
    stacks[2] = { itemID = id, stackCount = 1 }
    ScarletUI:UpdateCheapestItem()
    assert(pricey.cheapestGlow.shown and not cheap.cheapestGlow.shown, kind .. " was highlighted")
end
ScarletUI.db.global.highlightCheapestItem = false
ScarletUI:UpdateCheapestItem()
assert(not pricey.cheapestGlow.shown and not custom.cheapestGlow.shown, "Highlight toggle failed")
C_EquipmentSet = nil
print("PASS: cheapest bag item highlight, stack value, ignored item kinds, equipment sets, and toggle")

-- Inspect must work when only the namespaced item-level API exists.
local itemLink = "|cnIQ2:|Hitem:6214::::::::12:1487:::::::::|h[Heavy Copper Maul]|h|r"
UnitClass = function() return "Warrior", "WARRIOR" end
GetInventorySlotInfo = function(name) return name end
GetInventoryItemLink = function(_, slot) if slot == "MainHandSlot" then return itemLink end end
for _, api in ipairs({ "namespaced", "legacy", "baseOnly", "uncached", "baseFallback" }) do
    local baseLevel = api ~= "uncached" and 24 or nil
    C_Item.GetItemInfo = function()
        return "Heavy Copper Maul", itemLink, 1, baseLevel, nil, "Weapon", nil, nil, "INVTYPE_2HWEAPON"
    end
    C_Item.GetDetailedItemLevelInfo = nil
    GetDetailedItemLevelInfo = nil
    if api == "namespaced" then
        C_Item.GetDetailedItemLevelInfo = function(link) assert(link == itemLink); return 40 end
    elseif api == "legacy" then
        GetDetailedItemLevelInfo = function(link) assert(link == itemLink); return 40 end
    elseif api == "uncached" or api == "baseFallback" then
        C_Item.GetDetailedItemLevelInfo = function() return nil end
    end
    InspectFrame = button()
    InspectFrame.unit = "party3"
    InspectMainHandSlot = button()
    ScarletUI = { db = { global = { itemLevelInspect = true } }, retail = true }
    ScarletUI.GetWoWVersion = function() return "FOREVER", 16001 end
    dofile("Modules/ItemLevel.lua")
    ScarletUI:InspectFrameItemLevel()
    local expected = (api == "namespaced" or api == "legacy") and 40 or baseLevel
    assert(ScarletUI.inspectFrameItemLevelText.text == "Item Level: " .. math.floor((expected or 0) * 2 / 16), api)
    if expected then
        assert(InspectMainHandSlot.itemLevel.text == expected, api)
    else
        assert(InspectMainHandSlot.itemLevel == nil, "Uncached item must not create a bogus overlay")
    end
end
print("PASS: inspect item levels with namespaced, legacy, and base APIs, uncached items, and two-handed weapons")

-- The native inspect average wins when it exists; 0 (data not loaded) falls back to the formula.
for native, expected in pairs({ [41.5] = 41, [0] = 3 }) do
    C_PaperDollInfo = { GetInspectItemLevel = function(unit) assert(unit == "party3"); return native end }
    dofile("Modules/ItemLevel.lua")
    ScarletUI:InspectFrameItemLevel()
    assert(ScarletUI.inspectFrameItemLevelText.text == "Item Level: " .. expected, native)
end
C_PaperDollInfo = nil
dofile("Modules/ItemLevel.lua")
print("PASS: native inspect item level with formula fallback")

-- Forever shows the average under the level text without touching Blizzard's stat list.
local levelInfo = button()
CharacterLevelText = { GetParent = function() return levelInfo end }
GetAverageItemLevel = function() return 9, 3.6875, 7 end
ScarletUI.db.global.itemLevelCharacter = true
ScarletUI:CharacterFrameItemLevel()
local average, background = ScarletUI.characterFrameItemLevelText, ScarletUI.characterFrameItemLevelBackground
assert(average.text == "Item Level: 3" and average.shown and background.shown, "Forever average item level missing")
ScarletUI.db.global.itemLevelCharacter = false
ScarletUI:CharacterFrameItemLevel()
assert(not average.shown and not background.shown, "Character window toggle did not hide the average")
print("PASS: Forever character window average item level and toggle")
