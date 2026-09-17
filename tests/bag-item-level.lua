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
NUM_CONTAINER_FRAMES, BANK_CONTAINER = 1, -1
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
        CreateFontString = function()
            return {
                shown = true,
                SetFontObject = noop, SetTextColor = noop, SetPoint = noop,
                SetShadowColor = noop, SetShadowOffset = noop, SetFont = noop,
                GetFont = function() return "Font", 12 end,
                SetText = function(self, value) self.text = value end,
                Show = function(self) self.shown = true end,
                Hide = function(self) self.shown = false end,
            }
        end,
    }
end

for _, modern in ipairs({ false, true }) do
    local first, second, bank = button(0, 1), button(0, 2), button(-1, 1)
    contents[0][1] = 101
    ContainerFrame1 = {
        GetID = function() return 0 end, IsShown = function() return true end, HookScript = noop,
    }
    -- Legacy Blizzard bag buttons are numbered in reverse slot order.
    ContainerFrame1Item1, ContainerFrame1Item2 = second, first
    ContainerFrameCombinedBags = { EnumerateValidItems = function() return ipairs({ first, second }) end }
    BankFrameItem1 = bank
    BankFrame = { IsShown = function() return true end, GetChildren = function() return bank end }
    ScarletUI = { retail = modern, db = { global = { itemLevelBag = true } }, events = {} }
    ScarletUI.RegisterEventHandler = function(self, event, callback) self.events[event] = callback end
    dofile("Modules/ItemLevel.lua")
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
