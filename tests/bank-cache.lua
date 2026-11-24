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

-- Age: compact, rounded down; minutes, then hours, then days.
assert(BankCache.Age(nil, 5000) == "" and BankCache.Age(5000, 5000) == "just now" and BankCache.Age(5100, 5000) == "just now")
assert(BankCache.Age(4941, 5000) == "just now" and BankCache.Age(4940, 5000) == "1m ago" and BankCache.Age(5000 - 3599, 5000) == "59m ago")
assert(BankCache.Age(5000 - 3600, 5000) == "1h ago" and BankCache.Age(5000 - 3 * 3600 - 59, 5000) == "3h ago")
assert(BankCache.Age(5000 - 86399, 5000) == "23h ago" and BankCache.Age(5000 - 2 * 86400, 5000) == "2d ago")

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

-- All characters: the first menu entry, grouped under name headers with ages,
-- the choice remembered, one tooltip line per character.
local function Radios()
    local radios = {}
    menu(nil, { CreateRadio = function(_, label, isSelected, onSelect)
        radios[#radios + 1] = { label = label, selected = isSelected, pick = onSelect }
    end })
    return radios
end
local function HeaderTexts()
    local list = {}
    for _, fs in ipairs(texts) do if fs.shown and fs.text and fs.text:find("Updated") and fs.args then list[#list + 1] = fs.text end end
    return list
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
now = 1000 + 3 * 3600
local item = function(id, count) return { link = Link(id), count = count, icon = id } end
ScarletUI.db.global.bankCache = {
    ["Scarlet - Realm"] = { realm = "Realm", faction = "Horde", time = 1000 + 3 * 3600 - 10, counts = { [2589] = 5 }, items = { item(2589, 5) } },
    ["Alt - Realm"] = { realm = "Realm", faction = "Alliance", time = 1000, counts = { [2589] = 12, [2592] = 1 }, items = { item(2592, 1), item(2589, 12) } },
    ["Empty - Realm"] = { realm = "Realm", time = 1000, counts = {}, items = {} },
    ["Far - Other"] = { realm = "Other", counts = { [2589] = 99 }, items = { item(2589, 99) } },
}
names[2589], names[2592] = "Linen Cloth", "Wool Cloth"
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
local radios = Radios()
-- Default: the current character, no header, "Updated" beside the menu.
assert(#radios == 4 and radios[1].label == "All characters")
-- The faction icon leads the name; no faction recorded yet (older saves) means no icon.
local H, A = "|TInterface\\FriendsFrame\\PlusManz-Horde:14|t ", "|TInterface\\FriendsFrame\\PlusManz-Alliance:14|t "
assert(radios[2].label == H .. "Scarlet" and radios[3].label == A .. "Alt" and radios[4].label == "Empty")
assert(BankCache.Named("Bob", "Neutral") == "Bob" and BankCache.Named("Bob") == "Bob")
assert(radios[2].selected() and not radios[1].selected() and #HeaderTexts() == 0)
assert(named.ScarletUIBankSlot1.link == Link(2589) and not named.ScarletUIBankSlot2)
-- Picking All saves the choice and groups the slots, a header each.
radios[1].pick()
assert(ScarletUI.db.global.bankCacheModule.viewerChoice == "ALL" and Radios()[1].selected())
local headers = HeaderTexts()
assert(#headers == 2 and headers[1]:find(H .. "Scarlet", 1, true) and headers[2]:find(A .. "Alt", 1, true)
    and headers[1]:find("Scarlet", 1, true) and headers[1]:find("Updated just now", 1, true))
assert(headers[2]:find("Alt", 1, true) and headers[2]:find("Updated 3h ago", 1, true))
assert(named.ScarletUIBankSlot3.link == Link(2589) and named.ScarletUIBankSlot3.shown and not named.ScarletUIBankSlot4)
assert(named.ScarletUIBankSlot1.args[2] == -24 and named.ScarletUIBankSlot2.args[2] == -91) -- Alt's header sits between
assert(named.ScarletUIBankSlot2.args[1] == 4 and named.ScarletUIBankSlot3.args[1] == 45)
-- The search dims across every group.
local search
for _, f in ipairs(frames) do if f.hooks.OnTextChanged then search = f end end
search:SetText("wool")
for _, fn in ipairs(search.hooks.OnTextChanged) do fn(search) end
assert(named.ScarletUIBankSlot1.alpha == 0.25 and named.ScarletUIBankSlot2.alpha == 1 and named.ScarletUIBankSlot3.alpha == 0.25)
search:SetText("")
-- Tooltips: the viewer's own line per character, not the hook's, and with the hook off too.
local tip = { lines = {} }
function tip:SetOwner() self.lines = {} end
function tip:SetHyperlink(link) postCalls[0](self, { id = idOf(link) }) end
function tip:AddLine(text) self.lines[#self.lines + 1] = text end
function tip:Show() end
GameTooltip = tip
ScarletUI.db.global.bankCacheModule.tooltip = false
named.ScarletUIBankSlot3.scripts.OnEnter(named.ScarletUIBankSlot3)
assert(#tip.lines == 2 and tip.lines[1] == "Bank: Scarlet x5 (just now)" and tip.lines[2] == "Bank: Alt x12 (3h ago)")
ScarletUI.db.global.bankCacheModule.tooltip = true
named.ScarletUIBankSlot2.scripts.OnEnter(named.ScarletUIBankSlot2)
assert(#tip.lines == 1 and tip.lines[1] == "Bank: Alt x1 (3h ago)")
-- Sets: the corner marker shows on set items only, the tooltip names the sets,
-- and a set search dims everything else across every group.
ScarletUI.db.global.bankCache["Alt - Realm"].items[2].sets = { "Ret", "Tank" }
radios[1].pick() -- refresh
assert(named.ScarletUIBankSlot2.setMark ~= nil)
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
named.ScarletUIBankSlot3.scripts.OnEnter(named.ScarletUIBankSlot3)
assert(tip.lines[#tip.lines] == "Set: Ret, Tank" and named.ScarletUIBankSlot3.setMark.shown)
named.ScarletUIBankSlot2.scripts.OnEnter(named.ScarletUIBankSlot2)
assert(tip.lines[#tip.lines] ~= "Set: Ret, Tank" and not named.ScarletUIBankSlot2.setMark.shown)
search:SetText("set:ret")
for _, fn in ipairs(search.hooks.OnTextChanged) do fn(search) end
assert(named.ScarletUIBankSlot1.alpha == 0.25 and named.ScarletUIBankSlot2.alpha == 0.25 and named.ScarletUIBankSlot3.alpha == 1)
search:SetText("tank")
for _, fn in ipairs(search.hooks.OnTextChanged) do fn(search) end
assert(named.ScarletUIBankSlot3.alpha == 1 and named.ScarletUIBankSlot1.alpha == 0.25)
search:SetText("")
for _, fn in ipairs(search.hooks.OnTextChanged) do fn(search) end
-- The choice is remembered across closing and reopening.
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(Radios()[1].selected() and HeaderTexts()[1])
-- One character: its own grid, with its age beside the menu; the tooltip is the hook's again.
Radios()[3].pick()
assert(ScarletUI.db.global.bankCacheModule.viewerChoice == "Alt - Realm" and #HeaderTexts() == 0)
local seen
for _, fs in ipairs(texts) do if fs.text == "Updated 3h ago" then seen = true end end
assert(seen and named.ScarletUIBankSlot1.link == Link(2592) and not named.ScarletUIBankSlot3.shown)
named.ScarletUIBankSlot1.scripts.OnEnter(named.ScarletUIBankSlot1)
assert(#tip.lines == 1 and tip.lines[1] == "Bank (Alt): 1")
-- A character that is gone falls back to the current one.
ScarletUI.db.global.bankCacheModule.viewerChoice = "Gone - Realm"
ScarletUI:ToggleBankViewer(false)
ScarletUI:ToggleBankViewer(true)
assert(Radios()[2].selected())
ScarletUI:ToggleBankViewer(false)
C_Item, GameTooltip = nil, nil
ContainerFrameCombinedBags, CreateFrame, UISpecialFrames, SOUNDKIT, PlaySound, date, tinsert = nil, nil, nil, nil, nil, nil, nil

C_Bank, C_Container, TooltipDataProcessor, GameTooltip, ItemRefTooltip = nil, nil, nil, nil, nil
print("PASS: cached bank snapshots on Classic, Retail, and Forever bank layouts, debounced updates, counts, tooltips, name search, bag-style slots, and viewer placement beside the backpack")
