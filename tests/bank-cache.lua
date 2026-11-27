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
UnitFactionGroup = function() return "Horde" end
issecretvalue = nil
-- The logged-in character, read by the character snapshot.
local player = { level = 42, money = 123456, zone = "Orgrimmar", xp = 300, xpMax = 1000, rested = 450, resting = true }
UnitLevel = function() return player.level end
UnitXP = function() return player.xp end
UnitXPMax = function() return player.xpMax end
GetXPExhaustion = function() return player.rested end
IsResting = function() return player.resting end
GetMoney = function() return player.money end
GetRealZoneText = function() return player.zone end

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
dofile("Modules/CraftProfit.lua") -- its money format
dofile("Modules/XPPerHour.lua") -- its max-level check
local BankCache = ScarletUI.BankCache
ScarletUI.db = {
    global = { bankCacheModule = { enabled = true, tooltip = true } },
    keys = { char = "Scarlet - Realm", realm = "Realm" },
}
-- AceDB's logout order: OnDatabaseShutdown, then default-only tables stripped
-- (bankCacheModule once viewerChoice is cleared), then addons' PLAYER_LOGOUT.
local shutdown = {}
ScarletUI.db.RegisterCallback = function(target, event, fn) shutdown[target .. event] = fn end
local function Logout()
    for _, fn in pairs(shutdown) do fn() end
    local settings = ScarletUI.db.global.bankCacheModule
    ScarletUI.db.global.bankCacheModule = nil
    Fire("PLAYER_LOGOUT")
    ScarletUI.db.global.bankCacheModule = settings -- reloaded with defaults
end

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
-- Equipment sets: an exact bank location marks that slot only; an unreadable
-- location falls back to the item ID; no C_EquipmentSet means no set data.
assert(read.items[1].sets == nil)
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 1, 2 } end,
    GetEquipmentSetInfo = function(id) return id == 1 and "Tank" or "Ret" end,
    GetItemIDs = function(id) return id == 1 and { [1] = 2589, [2] = 4306 } or { [1] = 2589, [2] = 2592, [3] = 9 } end,
    -- Tank: 2589 at bank slot 1, 4306 elsewhere (equipped, location 1 = missing). Ret: 2589 in bag 5 slot 2.
    GetItemLocations = function(id)
        return id == 1 and { [1] = 1000 + 1, [2] = 1 } or { [1] = 1000 + 52, [2] = 5, [3] = 0 }
    end,
}
EquipmentManager_UnpackLocation = function(loc)
    if loc == 1001 then return false, true, false, false, 1, -1 end
    if loc == 1052 then return false, false, true, false, 2, 5 end
    return true, false, false, false, 1, nil -- equipped
end
read = BankCache.Read()
assert(table.concat(read.items[1].sets, ",") == "Tank") -- bag -1 slot 1
assert(read.items[3].sets and table.concat(read.items[3].sets, ",") == "Ret") -- bag 5 slot 2 (2589)
assert(read.items[2].sets == nil and read.items[4].sets == nil) -- 2592 slot 3, 4306: not in a bank location
-- Without the unpack helper every banked copy of a set's item ID is marked.
EquipmentManager_UnpackLocation = nil
read = BankCache.Read()
assert(table.concat(read.items[1].sets, ",") == "Ret,Tank" and table.concat(read.items[3].sets, ",") == "Ret,Tank")
assert(table.concat(read.items[2].sets, ",") == "Ret" and table.concat(read.items[4].sets, ",") == "Tank")
C_EquipmentSet = nil
assert(BankCache.Read().items[1].sets == nil)

-- Search: a set name or "set:name" matches that set's items; "set:" any set item.
local tank = { "Ret", "Tank" }
assert(BankCache.Matches("item:2589", "tank", tank) and BankCache.Matches("item:2589", "set:ret", tank))
assert(BankCache.Matches("item:2589", "set: TA", tank) and BankCache.Matches("item:2589", "set:", tank))
assert(not BankCache.Matches("item:2589", "set:tank", { "Ret" }) and not BankCache.Matches("item:2589", "set:", nil))
assert(not BankCache.Matches("item:2589", "set:linen", tank)) -- set: ignores item names
assert(BankCache.Matches("item:9999", "ret", tank) and not select(2, BankCache.Matches("item:9999", "ret", tank)))

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

-- Events: the bank saved only while open, once per burst of updates; the
-- character snapshot has its own timer, queued at setup and on bag updates.
GameTooltip = { HookScript = noop }
local postCalls = {}
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
Enum.TooltipDataType = { Item = 0 }
ScarletUI:SetupBankCache()
ScarletUI:SetupBankCache() -- setup reruns after a reset; hooks stay single
assert(#handlers.BANKFRAME_OPENED == 1 and #handlers.BANK_TABS_CHANGED == 1 and postCalls[0])
assert(shutdown["ScarletUI-BankCacheOnDatabaseShutdown"] and #handlers.PLAYER_MONEY == 1 and #timers == 1) -- the login snapshot
RunTimers()
Fire("BAG_UPDATE", 0)
assert(#timers == 1) -- bank closed: the character only
RunTimers()
Fire("BANKFRAME_OPENED")
Fire("BAG_UPDATE", 6)
Fire("BAG_UPDATE", 0)
Fire("PLAYERBANKSLOTS_CHANGED", 3)
assert(#timers == 2) -- one bank, one character
RunTimers()
local saved = ScarletUI.db.global.bankCache["Scarlet - Realm"]
assert(saved.time == 1000 and saved.realm == "Realm" and saved.class == "PALADIN" and saved.faction == "Horde" and saved.counts[2589] == 250)
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

-- Carried bags: the backpack and bag slots. Era, TBC, and Mists put the first
-- bank bag after them, so it is not read; Retail's reagent bag is, unless it
-- is a bank tab. The keyring (-1) never is.
local savedBank, savedEnum = C_Bank, Enum
C_Bank, Enum = nil, { BagIndex = { Bank = -1, ReagentBag = 5 } }
local bagList = BankCache.BagContainers()
assert(#bagList == 5 and bagList[1] == 0 and bagList[5] == 4)
C_Bank, Enum = savedBank, savedEnum
assert(#BankCache.BagContainers() == 5) -- tabs, but no reagent bag
Enum.BagIndex.ReagentBag = 5
bagList = BankCache.BagContainers()
assert(#bagList == 6 and bagList[6] == 5)
C_Bank.FetchPurchasedBankTabIDs = function() return { 5, 6 } end
assert(#BankCache.BagContainers() == 5)
C_Bank.FetchPurchasedBankTabIDs = function(bankType) return bankType == 0 and { 6, 7 } or { 15 } end
Enum.BagIndex.ReagentBag = nil
-- A set item in a bag location is marked on that bag slot.
bags[0] = { 16, { [2] = { 2589, 4 }, [3] = { 4306, 1 } } }
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 1 } end,
    GetEquipmentSetInfo = function() return "Ret" end,
    GetItemIDs = function() return { [1] = 2589 } end,
    GetItemLocations = function() return { [1] = 2000 } end,
}
EquipmentManager_UnpackLocation = function() return false, false, true, false, 2, 0 end
read = BankCache.ReadContainers(BankCache.BagContainers())
assert(read.size == 16 and #read.items == 2 and read.counts[2589] == 4 and read.counts[4306] == 1)
assert(read.items[1].sets[1] == "Ret" and read.items[2].sets == nil)
C_EquipmentSet, EquipmentManager_UnpackLocation = nil, nil

-- Rested XP: 5% of the level per 8 hours resting, a quarter outside, capped at
-- 150% without lowering a saved value above it; none online or at max level.
local H8 = 8 * 3600
local function Rested(entry, at, online)
    entry.xpMax = entry.xpMax or 1000
    return BankCache.Rested(entry, at, online)
end
local function Near(a, b) return math.abs(a - b) < 1e-9 end
local pct, gain = Rested({ rested = 100, resting = true, time = 0 }, H8)
assert(Near(pct, 15) and Near(gain, 5))
pct, gain = Rested({ rested = 100, resting = false, time = 0 }, H8)
assert(Near(pct, 11.25) and Near(gain, 1.25))
pct, gain = Rested({ rested = 1400, resting = true, time = 0 }, 10 * H8)
assert(Near(pct, 150) and Near(gain, 10))
pct, gain = Rested({ rested = 1600, resting = true, time = 0 }, H8) -- above the cap: kept
assert(Near(pct, 160) and Near(gain, 0))
pct, gain = Rested({ rested = 100, resting = true, time = 0 }, H8, true)
assert(Near(pct, 10) and Near(gain, 0))
pct, gain = Rested({ resting = true, time = H8 }, 0) -- clock skew: no negative time
assert(Near(pct, 0) and Near(gain, 0))
assert(Rested({ rested = 100, time = 0, maxLevel = true }, H8) == nil)
assert(BankCache.Rested({ rested = 100, time = 0, xpMax = 0 }, H8) == nil and BankCache.Rested({ time = 0 }, H8) == nil)

-- Money: gold and silver, or silver and copper; nil counts as nothing.
assert(BankCache.Money(123456) == "12|cffffd700g|r 34|cffc7c7cfs|r")
assert(BankCache.Money(5000) == "50|cffc7c7cfs|r 0|cffeda55fc|r")
assert(BankCache.Money(0) == "0|cffeda55fc|r" and BankCache.Money(nil) == "0|cffeda55fc|r")
local moneyList = { { realm = "A", info = { money = 5 } }, { realm = "B", info = { money = 7 } }, { realm = "A", info = {} }, { realm = "A" } }
assert(BankCache.AccountMoney(moneyList) == 12 and BankCache.AccountMoney(moneyList, "A") == 5 and BankCache.AccountMoney({}) == 0)

-- Characters from both caches: bank-only and summary-only ones; every realm
-- with allRealms, this one first, else this realm only.
local bankOnly = { ["Old - Realm"] = { realm = "Realm" }, ["Far - Other"] = { realm = "Other" } }
local summaries = { ["Scarlet - Realm"] = { realm = "Realm", level = 42 }, ["Far - Other"] = { realm = "Other", level = 10 },
    ["Zed - Azure"] = { realm = "Azure" } }
local merged = BankCache.Characters(bankOnly, "Realm", "Scarlet - Realm", summaries, true)
assert(#merged == 4 and merged[1].key == "Scarlet - Realm" and merged[1].info.level == 42 and merged[1].entry == nil)
assert(merged[2].label == "Old" and merged[2].entry and merged[2].info == nil)
assert(merged[3].key == "Zed - Azure" and merged[3].label == "Zed" and merged[3].realm == "Azure") -- other realms by name
assert(merged[4].label == "Far" and merged[4].entry and merged[4].info.level == 10)
merged = BankCache.Characters(bankOnly, "Realm", "Scarlet - Realm", summaries)
assert(#merged == 2 and merged[1].key == "Scarlet - Realm" and merged[2].key == "Old - Realm")

-- Character snapshots: at login (after a load screen), on money, bag, XP,
-- rest, level, and zone changes, debounced, whether or not the bank is open.
now = 3000
local bankBefore = ScarletUI.db.global.bankCache["Scarlet - Realm"]
Fire("PLAYER_ENTERING_WORLD")
assert(#timers == 1)
RunTimers()
local me = ScarletUI.db.global.characterCache["Scarlet - Realm"]
assert(me.time == 3000 and me.realm == "Realm" and me.level == 42 and me.money == 123456 and me.zone == "Orgrimmar")
assert(me.class == "PALADIN" and me.className == "Paladin" and me.faction == "Horde" and me.xpMax == 1000)
assert(me.rested == 450 and me.resting == true and me.maxLevel == false)
assert(me.bags.counts[2589] == 4 and #me.bags.items == 2 and me.bags.size == 16)
for _, event in ipairs({ "PLAYER_MONEY", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
    assert(#handlers[event] == 1, event)
end
-- Money and bag changes with the bank closed: the bags and gold, not the bank.
now, player.money = 3100, 99
bags[0][2][3] = nil
Fire("PLAYER_MONEY")
Fire("BAG_UPDATE", 0)
assert(#timers == 1)
RunTimers()
me = ScarletUI.db.global.characterCache["Scarlet - Realm"]
assert(me.money == 99 and me.bags.counts[4306] == nil and me.time == 3100)
assert(ScarletUI.db.global.bankCache["Scarlet - Realm"] == bankBefore)
-- Logout saves the time at once (no timer runs then) and reads nothing else:
-- Forever reads 0 gold, XP, and rest while logging out, which zeroed every
-- alt's gold in the character viewer.
now = 3200
player.money, player.xp, player.xpMax, player.rested, player.resting = 0, 0, 0, nil, false
Logout()
me = ScarletUI.db.global.characterCache["Scarlet - Realm"]
assert(#timers == 0 and me.time == 3200 and me.money == 99 and me.xpMax == 1000 and me.rested == 450 and me.resting == true)
player.money, player.xp, player.xpMax, player.rested, player.resting = 99, 300, 1000, 450, true
-- 0 gold before the client knows the money keeps the saved gold; after
-- PLAYER_MONEY this session, 0 is real.
player.money = 0
assert(BankCache.ReadCharacter({ money = 5 }).money == 5 and BankCache.ReadCharacter({}).money == 0)
assert(BankCache.ReadCharacter({ money = 5 }, true).money == 0)
player.money = 99
-- Secret values (Forever) and a zone not loaded yet keep the saved ones; bags
-- that read as nothing keep the saved bags.
local SECRET = {}
issecretvalue = function(value) return value == SECRET end
player.xp, player.money, player.zone = SECRET, SECRET, ""
local savedBag0 = bags[0]
bags[0] = nil
ScarletUI:SnapshotCharacter()
me = ScarletUI.db.global.characterCache["Scarlet - Realm"]
assert(me.xp == 300 and me.money == 99 and me.zone == "Orgrimmar" and me.bags.counts[2589] == 4)
issecretvalue, bags[0] = nil, savedBag0
player.xp, player.money, player.zone, player.resting = 300, 123456, "Orgrimmar", true
-- Max level: no rested XP to show.
GetMaxPlayerLevel = function() return 42 end
ScarletUI:SnapshotCharacter()
assert(ScarletUI.db.global.characterCache["Scarlet - Realm"].maxLevel == true)
GetMaxPlayerLevel = nil
-- Switched off, nothing is saved.
ScarletUI.db.global.bankCacheModule.enabled = false
now, player.money = 3300, 1
Fire("PLAYER_MONEY")
RunTimers()
Logout()
assert(ScarletUI.db.global.characterCache["Scarlet - Realm"].money == 123456)
ScarletUI.db.global.bankCacheModule.enabled = true
ScarletUI.db.global.characterCache = nil

-- Item lines and characters: the current character first; bags then bank;
-- other realms named.
local cache = {
    ["Scarlet - Realm"] = { realm = "Realm", time = now, counts = { [2589] = 5 } },
    ["Alt - Realm"] = { realm = "Realm", time = now, counts = { [2589] = 12, [2592] = 1 } },
    ["Bank - Realm"] = { realm = "Realm", time = now, counts = { [2592] = 3 } },
    ["Far - Other"] = { realm = "Other", time = now, counts = { [2589] = 99 } },
}
local summaries = { ["Alt - Realm"] = { realm = "Realm", bags = { counts = { [2589] = 2 } } },
    ["Bags - Realm"] = { realm = "Realm" } } -- no bags read yet
local all = BankCache.Characters(cache, "Realm", "Scarlet - Realm", summaries, true)
local itemLines = BankCache.ItemLines(all, 2589, "Realm", now + 7200)
assert(#itemLines == 4 and itemLines[1] == "Bank: Scarlet x5 (2h ago)" and itemLines[2] == "Bags: Alt x2"
    and itemLines[3] == "Bank: Alt x12 (2h ago)" and itemLines[4] == "Bank: Far (Other) x99 (2h ago)")
assert(#BankCache.ItemLines(all, 1, "Realm", now) == 0 and #BankCache.ItemLines({}, 2589, "Realm", now) == 0)
local characters = BankCache.Characters(cache, "Realm", "Scarlet - Realm")
assert(#characters == 3 and characters[1].label == "Scarlet" and characters[2].label == "Alt")
-- Forever's keys are first name and surname, with the ruleset as realm.
assert(BankCache.Label("Scarlet Bubbles", "PvE") == "Scarlet Bubbles")
assert(BankCache.Label("Scarlet - Azjol-Nerub", "Azjol-Nerub") == "Scarlet")

-- Age: compact, rounded down; minutes, then hours, then days.
assert(BankCache.Age(nil, 5000) == "" and BankCache.Age(5000, 5000) == "just now" and BankCache.Age(5100, 5000) == "just now")
assert(BankCache.Age(4941, 5000) == "just now" and BankCache.Age(4940, 5000) == "1m ago" and BankCache.Age(5000 - 3599, 5000) == "59m ago")
assert(BankCache.Age(5000 - 3600, 5000) == "1h ago" and BankCache.Age(5000 - 3 * 3600 - 59, 5000) == "3h ago")
assert(BankCache.Age(5000 - 86399, 5000) == "23h ago" and BankCache.Age(5000 - 2 * 86400, 5000) == "2d ago")

-- Tooltips: every saved character's lines, as the viewer's All mode shows them.
ScarletUI.db.global.bankCache = cache
local lines
local tooltip = { AddLine = function(_, text) lines[#lines + 1] = text end, IsForbidden = function() return false end }
local function Hover(itemID)
    lines = {}
    postCalls[0](tooltip, { id = itemID })
    return lines
end
Hover(2589)
assert(#lines == 1 and lines[1] == "Total: 116")
assert(BankCache.Total(all, 2589) == 118) -- plus Alt's 2 in bags
assert(BankCache.Total(all, 1) == 0)
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
RunTimers() -- its login snapshot
ScarletUI.db.global.characterCache = nil
lines = {}
scripts.game(GameTooltip)
assert(#lines == 1 and lines[1] == "Total: 4" and scripts.ref)

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

-- Filter: only matching items stay; sections and headings with none go.
names = { [1] = "Linen Cloth", [2] = "Wool Cloth", [3] = "Iron Bar" }
C_Item = { GetItemInfo = function(link) return names[idOf(link)] end }
local function It(id) return { link = "item:" .. id } end
local groups = {
    { header = "Realm", items = {}, rank = 1 },
    { header = "Alt", items = {}, rank = 2 },
    { header = "Bags", items = { It(1), It(3) } },
    { header = "Bank", items = { It(3) } },
    { header = "Bob", items = {}, rank = 2 },
    { header = "Bags", items = { It(2), It(1) }, note = "x" },
    { header = "Realm2", items = {}, rank = 1 },
    { header = "Cy", items = {}, rank = 2 },
    { header = "Bags", items = { It(3) } },
}
assert(BankCache.Filter(groups, "  ") == groups) -- blank: untouched
local out = BankCache.Filter(groups, "cloth")
local heads = {}
for _, g in ipairs(out) do heads[#heads + 1] = g.header .. ":" .. #g.items end
assert(table.concat(heads, ",") == "Realm:0,Alt:0,Bags:1,Bob:0,Bags:2", table.concat(heads, ","))
assert(out[3].items[1].link == "item:1" and out[5].note == nil)
assert(#BankCache.Filter(groups, "zzz") == 0)
out = BankCache.Filter(groups, "iron")
heads = {}
for _, g in ipairs(out) do heads[#heads + 1] = g.header end
assert(table.concat(heads, ",") == "Realm,Alt,Bags,Bank,Realm2,Cy,Bags", table.concat(heads, ","))
local _, pendingNames = BankCache.Filter({ { header = "Bags", items = { It(77) } } }, "x")
assert(pendingNames == true) -- unloaded name: asks again later
C_Item = nil

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

-- Viewer placement: beside the open backpack; a drag holds until the backpack
-- opens again. Frames are mocks; any other field is a stub that can be called
-- or indexed (viewer.CloseButton:SetScript) and returns a new frame.
local Frame, Stub, menu
local frames, texts = {}, {}
Stub = setmetatable({}, { __call = function() return Frame() end, __index = function() return Stub end })
function Frame()
    local f = { shown = false, scripts = {}, hooks = {} }
    local function Run(self, name)
        if self.scripts[name] then self.scripts[name](self) end
        for _, fn in ipairs(self.hooks[name] or {}) do fn(self) end
    end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:HookScript(name, fn) self.hooks[name] = self.hooks[name] or {}; table.insert(self.hooks[name], fn) end
    function f:Show() if not self.shown then self.shown = true; Run(self, "OnShow") end end
    function f:Hide() if self.shown then self.shown = false; Run(self, "OnHide") end end
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:IsShown() return self.shown end
    function f:SetPoint(point, relative, ...) self.point, self.relative, self.args = point, relative, { relative, ... } end
    function f:ClearAllPoints() self.point, self.relative, self.args = nil, nil, nil end
    function f:SetText(text) self.text = text end
    function f:GetText() return self.text or "" end
    function f:SetAlpha(alpha) self.alpha = alpha end
    function f:SetupMenu(fn) menu = fn end
    function f:CreateFontString() local fs = Frame(); texts[#texts + 1] = fs; return fs end
    return setmetatable(f, { __index = function() return Stub end })
end
local named = {}
CreateFrame = function(_, name) local f = Frame(); if name then named[name] = f end; frames[#frames + 1] = f; return f end
UISpecialFrames, SOUNDKIT, PlaySound, date, tinsert = {}, {}, noop, function() return "" end, table.insert
ContainerFrame1, ScarletUI_BagFrame = nil, nil -- left by other suites in a shared runtime
local bag = Frame()
ContainerFrameCombinedBags = bag
bag:Show()
ScarletUI:ToggleBankViewer(true)
local view = named.ScarletUIBank
assert(view.shown and view.point == "BOTTOMRIGHT" and view.relative == bag)
-- Dragged away: it stays put while closed and reopened.
view:SetPoint("CENTER")
view.scripts.OnDragStop(view)
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(view.point == "CENTER")
-- Reopening the backpack puts it back beside it, once hooked only.
bag:Hide()
bag:Show()
assert(view.point == "BOTTOMRIGHT" and view.relative == bag and #bag.hooks.OnShow == 1)
-- With no backpack open it keeps its place.
bag:Hide()
RunTimers() -- the viewer closes with the backpack; reopen it with the bags closed
ScarletUI:ToggleBankViewer(true)
assert(view.shown)
view:SetPoint("CENTER")
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(view.point == "CENTER")
RunTimers()
assert(view.shown) -- opening it with the bags closed does not close it

-- Closing the backpack closes the viewer; a swap to another bag frame does not.
local single = Frame()
ContainerFrame1 = single
bag:Show()
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true) -- hooks ContainerFrame1 too
assert(#single.hooks.OnHide == 1 and #bag.hooks.OnHide == 1)
bag:Hide()
single:Show() -- the swap: one hides as the other opens
RunTimers()
assert(view.shown)
single:Hide()
assert(view.shown) -- not before the check runs
RunTimers()
assert(not view.shown)
-- Reopened from the minimap with the bags closed, it stays until a bag closes.
ScarletUI:ToggleBankViewer(true)
RunTimers()
assert(view.shown)
bag:Show()
bag:Hide()
RunTimers()
assert(not view.shown)
ContainerFrameCombinedBags, ContainerFrame1 = nil, nil

-- Characters: every realm in the menu, under realm titles with their gold;
-- each character's bags and bank; "All characters" groups every one under a
-- name header; the choice remembered.
local function Radios()
    local radios, titles = {}, {}
    menu(nil, {
        CreateRadio = function(_, label, isSelected, onSelect)
            if label:find("^Realm  ") or label:find("^Other  ") then -- a realm option, kept apart from the characters
                titles[#titles + 1] = { text = label, after = #radios, selected = isSelected, pick = onSelect }
            else
                radios[#radios + 1] = { label = label, selected = isSelected, pick = onSelect }
            end
        end,
    })
    return radios, titles
end
-- Shown grid headers, top to bottom, and any text set anywhere.
local function Headers()
    local list = {}
    for _, fs in ipairs(texts) do if fs.shown and fs.text and fs.args then list[#list + 1] = fs end end
    table.sort(list, function(a, b) return a.args[2] > b.args[2] end)
    for i, fs in ipairs(list) do list[i] = fs.text end
    return list
end
local function HasText(text)
    for _, fs in ipairs(texts) do if fs.text == text then return true end end
end
local quality2 = {}
C_Item = { GetItemInfo = function(link) return names[idOf(link)], link, quality2[idOf(link)] end }
ScarletUI.CreateIconButton = function(_, _, _, name)
    local button = Frame()
    button.texture, button.IconBorder, button.junkCoin = Frame(), Frame(), Frame()
    button.CreateTexture = function() return Frame() end
    button.CreateFontString = function() return Frame() end
    named[name] = button
    return button
end
RAID_CLASS_COLORS = { PALADIN = { r = 1, g = 0.5, b = 0 } }
now = 1000 + 3 * 3600
local item = function(id, count) return { link = Link(id), count = count, icon = id } end
local function Bags(...)
    local list, counts = {}, {}
    for _, it in ipairs({ ... }) do list[#list + 1] = it; counts[idOf(it.link)] = (counts[idOf(it.link)] or 0) + it.count end
    return { items = list, counts = counts, size = 16 }
end
ScarletUI.db.global.bankCache = {
    ["Scarlet - Realm"] = { realm = "Realm", faction = "Horde", time = now - 10, counts = { [2589] = 5 }, items = { item(2589, 5) } },
    ["Alt - Realm"] = { realm = "Realm", faction = "Alliance", time = 1000, counts = { [2589] = 12, [2592] = 1 }, items = { item(2592, 1), item(2589, 12) } },
    ["Empty - Realm"] = { realm = "Realm", time = 1000, counts = {}, items = {} }, -- saved before the summary existed
    ["Far - Other"] = { realm = "Other", time = 1000, counts = { [2589] = 99 }, items = { item(2589, 99) } },
}
ScarletUI.db.global.characterCache = {
    ["Scarlet - Realm"] = { realm = "Realm", class = "PALADIN", className = "Paladin", faction = "Horde", level = 42, money = 123456,
        zone = "Orgrimmar", xpMax = 1000, rested = 450, resting = true, time = now, bags = Bags(item(4306, 3)) },
    ["Alt - Realm"] = { realm = "Realm", class = "MAGE", className = "Mage", faction = "Alliance", level = 20, money = 5000,
        zone = "Stormwind City", xpMax = 1000, rested = 100, resting = true, time = now - 8 * 3600, bags = Bags(item(2589, 2)) },
    ["Bags - Realm"] = { realm = "Realm", faction = "Horde", level = 60, money = 10000, maxLevel = true, time = 1000 }, -- no bags read yet
    ["Far - Other"] = { realm = "Other", faction = "Horde", level = 10, money = 1000000, xpMax = 500, time = 1000, bags = Bags() },
}
names[2589], names[2592] = "Linen Cloth", "Wool Cloth"
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
local radios, titles = Radios()
-- This realm first, the current character first, then by name; then the other realm.
local H, A = "|TInterface\\FriendsFrame\\PlusManz-Horde:14|t ", "|TInterface\\FriendsFrame\\PlusManz-Alliance:14|t "
local function Lv(level) return "  |cff888888" .. level .. "|r" end
assert(#radios == 6 and radios[1].label == "All characters")
assert(radios[2].label == H .. "Scarlet" .. Lv(42) and radios[3].label == A .. "Alt" .. Lv(20) and radios[4].label == H .. "Bags" .. Lv(60))
assert(radios[5].label == "Empty" and radios[6].label == H .. "Far" .. Lv(10)) -- an old save: no faction, no level
assert(BankCache.Named("Bob", "Neutral") == "Bob" and BankCache.Named("Bob") == "Bob")
-- Realm options with each realm's gold, only because there are two realms.
assert(#titles == 2 and titles[1].after == 1 and titles[2].after == 5)
assert(titles[1].text == "Realm  " .. BankCache.Money(123456 + 5000 + 10000) and titles[2].text == "Other  " .. BankCache.Money(1000000))
-- The account total counts every realm.
assert(HasText("Account: " .. BankCache.Money(123456 + 5000 + 10000 + 1000000)))
-- Default: the current character, online, with its bags then its bank.
assert(radios[2].selected() and not radios[1].selected())
local DOT = "  \194\183  "
assert(HasText("Level 42 |cffff7f00Paladin|r" .. DOT .. "Orgrimmar" .. DOT .. "Online"))
assert(HasText("Gold " .. BankCache.Money(123456) .. DOT .. "Rested 45%")) -- online: no projection
local list = Headers()
assert(#list == 2 and list[1] == "Bags" and list[2] == "Bank  |cff888888Updated just now|r")
assert(named.ScarletUIBankSlot1.link == Link(4306) and named.ScarletUIBankSlot2.link == Link(2589) and not named.ScarletUIBankSlot3)
assert(named.ScarletUIBankSlot1.args[2] == -24 and named.ScarletUIBankSlot2.args[2] == -91) -- the Bank header sits between
-- A logged-out character: last seen, and rested XP gained since at the inn rate.
radios[3].pick()
assert(ScarletUI.db.global.bankCacheModule.viewerChoice == "Alt - Realm")
assert(HasText("Level 20 Mage" .. DOT .. "Stormwind City" .. DOT .. "Last seen 8h ago")) -- no class colour known: plain
assert(HasText("Gold " .. BankCache.Money(5000) .. DOT .. "Rested 15% (+5% since logout, resting)"))
assert(named.ScarletUIBankSlot1.link == Link(2589) and named.ScarletUIBankSlot2.link == Link(2592) and named.ScarletUIBankSlot3.shown)
ScarletUI.db.global.characterCache["Alt - Realm"].resting = false
radios[3].pick()
assert(HasText("Gold " .. BankCache.Money(5000) .. DOT .. "Rested 11% (+1% since logout, outside)"))
-- In single mode the item tooltip is the hook's one total line.
local tip = { lines = {} }
function tip:SetOwner() self.lines = {} end
function tip:SetHyperlink(link) postCalls[0](self, { id = idOf(link) }) end
function tip:AddLine(text) self.lines[#self.lines + 1] = text end
function tip:Show() end
GameTooltip = tip
named.ScarletUIBankSlot2.scripts.OnEnter(named.ScarletUIBankSlot2)
assert(#tip.lines == 1 and tip.lines[1] == "Bank: Alt x1 (3h ago)") -- breakdown, no hook Total
-- Max level, no bags saved: no rested part, and a note under Bags; a bank
-- never saved says how to save it.
radios[4].pick()
assert(HasText("Gold " .. BankCache.Money(10000)) and HasText("Level 60 " .. DOT .. "Last seen 3h ago"))
list = Headers()
assert(#list == 4 and list[1] == "Bags" and list[2]:find("Bags not saved yet", 1, true) and list[3] == "Bank"
    and list[4]:find("No bank saved yet", 1, true) and not named.ScarletUIBankSlot1.shown)
-- A save from before the summary: no info lines, the bank still shows.
radios[5].pick()
list = Headers()
assert(list[2]:find("Bags not saved yet", 1, true) and list[4]:find("This bank was empty", 1, true))
assert(not HasText("Level nil"))
-- All characters: realm headers with gold, a name header per character with
-- level, gold, and last seen, then its non-empty Bags and Bank.
radios[1].pick()
assert(ScarletUI.db.global.bankCacheModule.viewerChoice == "ALL" and Radios()[1].selected())
list = Headers()
assert(#list == 12, #list)
assert(list[1] == "Realm  " .. BankCache.Money(138456))
assert(list[2] == H .. "Scarlet  |cff888888Level 42|r  " .. BankCache.Money(123456) .. "  |cff888888Online|r")
assert(list[3] == "Bags" and list[4]:find("^Bank") and list[5]:find(A .. "Alt", 1, true) and list[5]:find("Last seen 8h ago", 1, true))
assert(list[6] == "Bags" and list[7] == "Bank  |cff888888Updated 3h ago|r")
assert(list[8]:find("Bags", 1, true) and list[8]:find("Level 60", 1, true) and list[9] == "Empty") -- nothing saved to show
assert(list[10] == "Other  " .. BankCache.Money(1000000) and list[11]:find("Far", 1, true) and list[12] == "Bank  |cff888888Updated 3h ago|r")
-- Slots: Scarlet's bag, Scarlet's bank, Alt's bag, Alt's bank (2), Far's bank.
local S = function(i) return named["ScarletUIBankSlot" .. i] end
assert(S(1).link == Link(4306) and S(2).link == Link(2589) and S(3).link == Link(2589) and S(4).link == Link(2592))
assert(S(5).link == Link(2589) and S(6).link == Link(2589) and S(6).shown and not S(7))
assert(S(4).args[1] == 4 and S(5).args[1] == 45 and S(1).args[2] == -64 and S(2).args[2] == -131)
-- The search hides non-matches and packs the rest; empty sections and headings go.
local search
for _, f in ipairs(frames) do if f.hooks.OnTextChanged then search = f end end
local function Search(text)
    search:SetText(text)
    for _, fn in ipairs(search.hooks.OnTextChanged) do fn(search) end
end
local function Shown()
    local n = 0
    for i = 1, 20 do if S(i) and S(i).shown then n = n + 1 end end
    return n
end
Search("linen")
assert(Shown() == 4 and S(1).link == Link(2589) and S(2).link == Link(2589) and S(3).link == Link(2589) and S(4).link == Link(2589))
list = Headers()
assert(#list == 9 and not HasText("No matches"))
for _, h in ipairs(list) do assert(not h:find("Level 60", 1, true)) end -- the character with nothing saved is gone
Search("zzz")
assert(Shown() == 0 and #Headers() == 0 and HasText("No matches"))
Search("")
-- A realm option: only that realm's characters, with its gold, searchable.
radios, titles = Radios()
titles[2].pick()
assert(ScarletUI.db.global.bankCacheModule.viewerChoice == "realm:Other")
radios, titles = Radios()
assert(titles[2].selected() and not titles[1].selected() and not radios[1].selected() and not radios[2].selected())
list = Headers()
assert(#list == 3 and list[1] == "Other  " .. BankCache.Money(1000000) and list[2]:find("Far", 1, true) and list[3]:find("^Bank"))
assert(S(1).link == Link(2589) and S(1).shown and not S(2).shown)
Search("wool")
assert(not S(1).shown and #Headers() == 0 and HasText("No matches"))
Search("linen")
assert(S(1).shown and S(1).alpha == 1 and #Headers() == 3 and not HasText("No matches"))
Search("")
titles[1].pick()
assert(Radios() and select(2, Radios())[1].selected())
list = Headers()
assert(#list == 9 and list[1] == "Realm  " .. BankCache.Money(138456) and not list[10])
assert(S(1).link == Link(4306) and S(4).link == Link(2592) and S(5).link == Link(2589) and not S(6).shown)
S(2).scripts.OnEnter(S(2))
assert(#tip.lines == 4 and tip.lines[3] == "Bank: Alt x12 (3h ago)" and tip.lines[4] == "Bank: Far (Other) x99 (3h ago)") -- every saved character, as the hook Total counts
radios[1].pick()
-- Tooltips: the viewer's own bag and bank lines per character, every realm
-- (others named), and with the hook off too.
ScarletUI.db.global.bankCacheModule.tooltip = false
S(2).scripts.OnEnter(S(2))
assert(#tip.lines == 4 and tip.lines[1] == "Bank: Scarlet x5 (just now)" and tip.lines[2] == "Bags: Alt x2"
    and tip.lines[3] == "Bank: Alt x12 (3h ago)" and tip.lines[4] == "Bank: Far (Other) x99 (3h ago)")
ScarletUI.db.global.bankCacheModule.tooltip = true
S(1).scripts.OnEnter(S(1))
assert(#tip.lines == 1 and tip.lines[1] == "Bags: Scarlet x3")
-- Sets: the corner marker shows on set items only, the tooltip names the sets,
-- and a set search hides everything else across every group.
ScarletUI.db.global.bankCache["Alt - Realm"].items[2].sets = { "Ret", "Tank" }
radios[1].pick() -- refresh
S(5).scripts.OnEnter(S(5))
assert(tip.lines[#tip.lines] == "Set: Ret, Tank" and S(5).setMark.shown)
S(4).scripts.OnEnter(S(4))
assert(tip.lines[#tip.lines] ~= "Set: Ret, Tank" and not S(4).setMark.shown)
Search("set:ret")
assert(Shown() == 1 and S(1).link == Link(2589) and S(1).setMark.shown and #Headers() == 3) -- realm, Alt, Bank: only Alt's set item
Search("tank")
assert(Shown() == 1 and S(1).link == Link(2589))
Search("")
-- A realm that is gone falls back to the current character.
ScarletUI.db.global.bankCacheModule.viewerChoice = "realm:Nowhere"
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(Radios()[2].selected())
radios[1].pick()
-- Closing and reopening goes back to the current character, not the last pick.
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(Radios()[2].selected() and not Radios()[1].selected() and ScarletUI.db.global.bankCacheModule.viewerChoice == nil)
radios[3].pick() -- picking while open still works
assert(Radios()[3].selected())
radios[1].pick()
-- A snapshot while it is shown refreshes it.
radios[2].pick()
bags[0] = { 16, { [1] = { 2592, 7 } } }
ScarletUI:SnapshotCharacter()
assert(S(1).link == Link(2592))
-- A character that is gone falls back to the current one.
ScarletUI.db.global.bankCacheModule.viewerChoice = "Gone - Realm"
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(Radios()[2].selected())
-- One realm: no realm titles or headers.
ScarletUI.db.global.bankCache["Far - Other"], ScarletUI.db.global.characterCache["Far - Other"] = nil, nil
Radios()[1].pick()
radios, titles = Radios()
assert(#titles == 0 and #radios == 5 and Headers()[1]:find("Scarlet", 1, true))
-- Nothing saved: an empty menu and a line saying so.
ScarletUI.db.global.bankCache, ScarletUI.db.global.characterCache = nil, nil
Radios()[1].pick()
radios = Radios()
assert(#radios == 1 and HasText("Nothing saved yet.") and #Headers() == 0)
ScarletUI:ToggleBankViewer(false)
-- Still anchored by its bottom to the bag's bottom.
local bottomBag = Frame()
ContainerFrameCombinedBags = bottomBag
bottomBag:Show()
ScarletUI:ToggleBankViewer(true)
assert(view.point == "BOTTOMRIGHT" and view.relative == bottomBag and view.args[2] == "BOTTOMLEFT")
ScarletUI:ToggleBankViewer(false)
C_Item, GameTooltip, RAID_CLASS_COLORS = nil, nil, nil
ContainerFrameCombinedBags, CreateFrame, UISpecialFrames, SOUNDKIT, PlaySound, date, tinsert = nil, nil, nil, nil, nil, nil, nil
UnitLevel, UnitXP, UnitXPMax, GetXPExhaustion, IsResting, GetMoney, GetRealZoneText = nil, nil, nil, nil, nil, nil, nil

C_Bank, C_Container, TooltipDataProcessor, GameTooltip, ItemRefTooltip = nil, nil, nil, nil, nil
print("PASS: cached bank snapshots on Classic, Retail, and Forever bank layouts, debounced updates, counts, tooltips, name search, bag-style slots, viewer placement beside the backpack, and the character viewer: bags, gold, rested XP, every realm")
