-- Run from the addon root: lua tests/bank-cache.lua
-- Cached bank: snapshots per client bank layout, debounced updates, and counts.
local function noop() end
local handlers, timers, now = {}, {}, 1000
ScarletUI = {
    defaults = { global = {}, char = {} },
    RegisterEventHandler = function(_, event, fn)
        handlers[event] = handlers[event] or {}
        table.insert(handlers[event], fn)
    end,
}
local function Fire(event, ...)
    for _, fn in ipairs(handlers[event] or {}) do fn(event, ...) end
end
local function RunTimers()
    local queued = timers
    timers = {}
    for _, fn in ipairs(queued) do fn() end
end
C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
time = function() return now end
UnitClass = function() return "Paladin", "PALADIN" end
issecretvalue = nil

-- bags[bagID] = { size, { [slot] = { itemID, count } } }
local bags
local function Link(itemID) return "|cffffffff|Hitem:" .. itemID .. "::::::::60:::::|h[Item " .. itemID .. "]|h|r" end
local function ModernContainer()
    C_Container = {
        GetContainerNumSlots = function(bag) return bags[bag] and bags[bag][1] or 0 end,
        GetContainerItemInfo = function(bag, slot)
            local item = bags[bag] and bags[bag][2][slot]
            return item and { hyperlink = Link(item[1]), stackCount = item[2], iconFileID = 100 + item[1], itemID = item[1] }
        end,
    }
end

dofile("Modules/BankCache.lua")
local BankCache = ScarletUI.BankCache
ScarletUI.db = {
    global = { bankCacheModule = { enabled = true, tooltip = true } },
    keys = { char = "Scarlet - Realm", realm = "Realm" },
}

-- Era, TBC, and Mists: the bank container and the bank bags after the bag slots.
ModernContainer()
Enum = { BagIndex = { Bank = -1 } }
NUM_BAG_SLOTS, NUM_BANKBAGSLOTS = 4, 7
bags = {
    [-1] = { 24, { [1] = { 2589, 20 }, [3] = { 2592, 5 } } },
    [5] = { 16, { [2] = { 2589, 7 } } },
    [11] = { 6, { [6] = { 4306, 1 } } },
    [12] = { 10, { [1] = { 9999, 1 } } }, -- past the bank bags: not read
}
local list = BankCache.Containers()
assert(#list == 8 and list[1] == -1 and list[2] == 5 and list[8] == 11)
local read = BankCache.Read()
assert(read.size == 24 + 16 + 6 and #read.items == 4)
assert(read.counts[2589] == 27 and read.counts[2592] == 5 and read.counts[4306] == 1 and read.counts[9999] == nil)
assert(read.items[1].link == Link(2589) and read.items[1].count == 20 and read.items[1].icon == 2689)
-- A reagent bank is read where the client has one and it is bought.
IsReagentBankUnlocked = function() return true end
Enum.BagIndex.Reagentbank = -3
bags[-3] = { 98, { [4] = { 2589, 3 } } }
assert(BankCache.Read().counts[2589] == 30)
IsReagentBankUnlocked, bags[-3] = nil, nil

-- The old global container API (no C_Container), item ID read from the link.
C_Container = nil
GetContainerNumSlots = function(bag) return bags[bag] and bags[bag][1] or 0 end
GetContainerItemInfo = function(bag, slot)
    local item = bags[bag] and bags[bag][2][slot]
    if item then return 100 + item[1], item[2], false, 1, false, false, Link(item[1]) end
end
read = BankCache.Read()
assert(read.counts[2589] == 27 and read.counts[4306] == 1 and #read.items == 4)
GetContainerNumSlots, GetContainerItemInfo = nil, nil

-- Retail and Forever: the purchased character bank tabs (Forever's bank bags).
ModernContainer()
local viewable = true
Enum = { BankType = { Character = 0, Account = 2 }, BagIndex = {} }
C_Bank = {
    CanViewBank = function(bankType) return bankType == 0 and viewable end,
    FetchPurchasedBankTabIDs = function(bankType) return bankType == 0 and { 6, 7 } or { 15 } end,
}
bags = {
    [6] = { 98, { [1] = { 2589, 200 }, [98] = { 2592, 1 } } },
    [7] = { 98, { [10] = { 2589, 50 } } },
    [15] = { 98, { [1] = { 4306, 9 } } }, -- the Warband/account bank: not saved
    [-1] = { 24, { [1] = { 9999, 1 } } },
}
read = BankCache.Read()
assert(read.size == 196 and read.counts[2589] == 250 and read.counts[2592] == 1 and read.counts[4306] == nil)
assert(read.counts[9999] == nil)
-- A banker that only shows the Warband bank leaves the character bank unread.
viewable = false
assert(BankCache.Containers() == nil and BankCache.Read() == nil)
viewable = true
-- No slots yet (tabs still loading) reads as nothing rather than an empty bank.
C_Bank.FetchPurchasedBankTabIDs = function() return {} end
assert(BankCache.Read() == nil)
C_Bank.FetchPurchasedBankTabIDs = function(bankType) return bankType == 0 and { 6, 7 } or { 15 } end

-- Events: saved only while the bank is open, once per burst of updates.
GameTooltip = { HookScript = noop }
local postCalls = {}
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
Enum.TooltipDataType = { Item = 0 }
ScarletUI:SetupBankCache()
ScarletUI:SetupBankCache() -- setup reruns after a reset; hooks stay single
assert(#handlers.BANKFRAME_OPENED == 1 and #handlers.BANK_TABS_CHANGED == 1 and postCalls[0])
Fire("BAG_UPDATE", 0)
assert(#timers == 0) -- bank closed: nothing to read
Fire("BANKFRAME_OPENED")
Fire("BAG_UPDATE", 6)
Fire("BAG_UPDATE", 0)
Fire("PLAYERBANKSLOTS_CHANGED", 3)
assert(#timers == 1)
RunTimers()
local saved = ScarletUI.db.global.bankCache["Scarlet - Realm"]
assert(saved.time == 1000 and saved.realm == "Realm" and saved.class == "PALADIN" and saved.counts[2589] == 250)
-- A withdrawal while open replaces the snapshot.
now = 2000
bags[7][2][10] = nil
Fire("BAG_UPDATE", 7)
RunTimers()
saved = ScarletUI.db.global.bankCache["Scarlet - Realm"]
assert(saved.time == 2000 and saved.counts[2589] == 200)
-- A change just before closing is saved at the close, while still readable.
now = 2500
bags[6][2][1] = { 2589, 150 }
Fire("BAG_UPDATE", 6)
Fire("BANKFRAME_CLOSED")
saved = ScarletUI.db.global.bankCache["Scarlet - Realm"]
assert(saved.time == 2500 and saved.counts[2589] == 150)
-- The queued timer then finds the bank closed and saves nothing more.
bags[6][2][1] = nil
RunTimers()
assert(ScarletUI.db.global.bankCache["Scarlet - Realm"].counts[2589] == 150)
-- Closing with nothing queued reads nothing.
Fire("BANKFRAME_CLOSED")
assert(ScarletUI.db.global.bankCache["Scarlet - Realm"].counts[2589] == 150)
-- Switched off, it stops saving.
ScarletUI.db.global.bankCacheModule.enabled = false
Fire("BANKFRAME_OPENED")
RunTimers()
assert(ScarletUI.db.global.bankCache["Scarlet - Realm"].counts[2589] == 150)
ScarletUI.db.global.bankCacheModule.enabled = true
Fire("BANKFRAME_CLOSED")

-- Counts and characters: same realm only, the current character first.
local cache = {
    ["Scarlet - Realm"] = { realm = "Realm", counts = { [2589] = 5 } },
    ["Alt - Realm"] = { realm = "Realm", counts = { [2589] = 12, [2592] = 1 } },
    ["Bank - Realm"] = { realm = "Realm", counts = { [2592] = 3 } },
    ["Far - Other"] = { realm = "Other", counts = { [2589] = 99 } },
}
local counts = BankCache.Counts(cache, "Realm", 2589, "Scarlet - Realm")
assert(#counts == 2 and counts[1].key == "Scarlet - Realm" and counts[1].count == 5)
assert(counts[2].label == "Alt" and counts[2].count == 12)
counts = BankCache.Counts(cache, "Realm", 2592, "Scarlet - Realm")
assert(#counts == 2 and counts[1].label == "Alt" and counts[2].label == "Bank")
assert(#BankCache.Counts(cache, "Realm", 1, "Scarlet - Realm") == 0 and #BankCache.Counts(nil, "Realm", 1) == 0)
local characters = BankCache.Characters(cache, "Realm", "Scarlet - Realm")
assert(#characters == 3 and characters[1].label == "Scarlet" and characters[2].label == "Alt")
-- Forever's keys are first name and surname, with the ruleset as realm.
assert(BankCache.Label("Scarlet Bubbles", "PvE") == "Scarlet Bubbles")
assert(BankCache.Label("Scarlet - Azjol-Nerub", "Azjol-Nerub") == "Scarlet")

-- Tooltips: "Bank: N" for this character, then the others on the realm.
ScarletUI.db.global.bankCache = cache
local lines
local tooltip = { AddLine = function(_, text) lines[#lines + 1] = text end, IsForbidden = function() return false end }
local function Hover(itemID)
    lines = {}
    postCalls[0](tooltip, { id = itemID })
    return lines
end
Hover(2589)
assert(#lines == 2 and lines[1] == "Bank: 5" and lines[2] == "Bank (Alt): 12")
assert(#Hover(4306) == 0)
ScarletUI.db.global.bankCacheModule.tooltip = false
assert(#Hover(2589) == 0)
ScarletUI.db.global.bankCacheModule.tooltip = true
tooltip.IsForbidden = function() return true end
assert(#Hover(2589) == 0)

-- Older clients without TooltipDataProcessor hook OnTooltipSetItem.
local scripts = {}
local function OldTooltip(name)
    return { HookScript = function(_, script, fn) scripts[name] = script == "OnTooltipSetItem" and fn end,
        AddLine = function(_, text) lines[#lines + 1] = text end, Show = noop,
        GetItem = function() return "Item", Link(2592) end }
end
GameTooltip, ItemRefTooltip = OldTooltip("game"), OldTooltip("ref")
TooltipDataProcessor = nil
ScarletUI.bankCacheHooked = nil
ScarletUI:SetupBankCache()
lines = {}
scripts.game(GameTooltip)
assert(#lines == 2 and lines[1] == "Bank (Alt): 1" and lines[2] == "Bank (Bank): 3" and scripts.ref)

-- Search: names come from C_Item.GetItemInfo, else the global one, else the
-- [Name] in the link; matching ignores case and surrounding spaces.
local names = { [2589] = "Linen Cloth", [2592] = "Wool Cloth" }
local function idOf(link) return tonumber(tostring(link):match("item:(%-?%d+)")) end
C_Item = { GetItemInfo = function(link) return names[idOf(link)] end }
assert(BankCache.ItemName("item:2589") == "Linen Cloth")
assert(BankCache.Matches("item:2589", "linen") and BankCache.Matches("item:2589", "  LINEN CL "))
assert(BankCache.Matches("item:2592", "cloth") and not BankCache.Matches("item:2592", "linen"))
assert(BankCache.Matches("item:2589", "") and BankCache.Matches("item:2589", "   "))
assert(BankCache.Matches("item:2589", "n.n") == false) -- plain text, not a pattern
assert(BankCache.Matches("item:2589", "(") == false)
-- Not loaded: no match, and flagged so the viewer asks again on GET_ITEM_INFO_RECEIVED.
local match, unknown = BankCache.Matches("item:4306", "silk")
assert(match == false and unknown == true)
assert(select(2, BankCache.Matches("item:4306", "")) == nil) -- empty query needs no name
names[4306] = "Silk Cloth"
assert(BankCache.Matches("item:4306", "silk") == true and select(2, BankCache.Matches("item:4306", "silk")) == nil)
-- The link's own [Name] covers items the client has not loaded.
assert(BankCache.Matches(Link(9999), "item 9999") and not select(2, BankCache.Matches(Link(9999), "x")))
-- Clients without C_Item use the global GetItemInfo.
C_Item = nil
GetItemInfo = function(link) return names[idOf(link)] end
assert(BankCache.Matches("item:2589", "LINEN") and not BankCache.Matches("item:2589", "wool"))
GetItemInfo = nil

-- Viewer slots dressed as bag slots: quality border from Common up, junk
-- greyed with a coin, the item level per the bags' setting.
local quality = { [1] = 0, [2] = 1, [3] = 4 }
C_Item = { GetItemInfo = function(link) return "Item", link, quality[idOf(link)] end }
ITEM_QUALITY_COLORS = { [0] = { r = .6, g = .6, b = .6 }, [1] = { r = 1, g = 1, b = 1 }, [4] = { r = .6, g = .2, b = 1 } }
local levelCalls = {}
ScarletUI.ItemLevelText = function(link, location, button, hide) levelCalls[#levelCalls + 1] = { link, location, hide } end
ScarletUI.db.global.itemLevelBag = true
local function Part() return { SetShown = function(self, v) self.shown = v end, SetVertexColor = function(self, r) self.r = r end,
    SetDesaturated = function(self, v) self.grey = v end } end
local slot = { IconBorder = Part(), junkCoin = Part(), texture = Part() }
assert(BankCache.Decorate(slot, "item:3") == false)
assert(slot.IconBorder.shown and slot.IconBorder.r == .6 and not slot.texture.grey and not slot.junkCoin.shown)
assert(levelCalls[1][1] == "item:3" and levelCalls[1][2] == nil and levelCalls[1][3] == false)
BankCache.Decorate(slot, "item:1") -- junk
assert(not slot.IconBorder.shown and slot.texture.grey and slot.junkCoin.shown)
BankCache.Decorate(slot, "item:2") -- common: white border
assert(slot.IconBorder.shown and slot.IconBorder.r == 1 and not slot.texture.grey)
ScarletUI.db.global.itemLevelBag = false
assert(BankCache.Decorate(slot, "item:9") == true) -- not loaded: plain until GET_ITEM_INFO_RECEIVED
assert(not slot.IconBorder.shown and not slot.junkCoin.shown and levelCalls[4][3] == true)
C_Item, ITEM_QUALITY_COLORS = nil, nil

C_Bank, C_Container, TooltipDataProcessor, GameTooltip, ItemRefTooltip = nil, nil, nil, nil, nil
print("PASS: cached bank snapshots on Classic, Retail, and Forever bank layouts, debounced updates, counts, tooltips, name search, and bag-style slots")
