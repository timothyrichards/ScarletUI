-- Cached bank and character viewer: the client only shows bank contents while
-- the bank is open, so each character's bank is saved when seen
-- (db.global.bankCache, keyed by AceDB's character key) and shown later in a
-- viewer (/sui bank) and as bank counts on item tooltips. Bags, money, level,
-- rested XP, and zone are saved at login, logout, and on change
-- (db.global.characterCache) and shown in the same viewer. Retail and Forever
-- keep the bank in purchased tabs
-- (C_Bank.FetchPurchasedBankTabIDs; Forever's are bank bags); Era, TBC, and
-- Mists in the bank container and bank bags. The Warband/account bank is not
-- saved. Only add-on data is written; tooltips get post-hooked lines.
local BankCache = {}
ScarletUI.BankCache = BankCache

local function IsSecret(value) return issecretvalue ~= nil and issecretvalue(value) end
local COLUMNS, SIZE, GAP, DIM_ALPHA = 10, 37, 4, 0.25 -- the bags' slots per row, size and spacing
local PORTRAIT = "Interface\\Icons\\INV_Box_02" -- a chest
local TOOLTIP_COLOR = { r = 0.5, g = 0.75, b = 1 }

local function NumSlots(bag)
    local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    return GetNumSlots and GetNumSlots(bag) or 0
end

local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%-?%d+)")) or nil
end

-- link, count, icon, item ID of a filled slot.
local function SlotItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.hyperlink, info.stackCount, info.iconFileID, info.itemID end
    elseif GetContainerItemInfo then
        local icon, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bag, slot)
        if icon or link then return link, count, icon, itemID end
    end
end

-- The bag IDs holding the character's bank, or nil when it cannot be viewed.
function BankCache.Containers()
    if C_Bank and C_Bank.FetchPurchasedBankTabIDs and Enum and Enum.BankType then
        local character = Enum.BankType.Character
        -- Retail opens the bank frame for Warband-only bankers too.
        if C_Bank.CanViewBank and not C_Bank.CanViewBank(character) then return end
        local list = {}
        for _, bag in ipairs(C_Bank.FetchPurchasedBankTabIDs(character) or {}) do list[#list + 1] = bag end
        return list
    end
    local bagIndex = Enum and Enum.BagIndex or {}
    local list = { bagIndex.Bank or BANK_CONTAINER or -1 }
    local first = (NUM_BAG_SLOTS or 4) + 1
    for bag = first, first + (NUM_BANKBAGSLOTS or 0) - 1 do list[#list + 1] = bag end
    -- No current client has one; kept for clients with a reagent bank.
    if IsReagentBankUnlocked and IsReagentBankUnlocked() then
        list[#list + 1] = bagIndex.Reagentbank or REAGENTBANK_CONTAINER or -3
    end
    return list
end

-- Equipment Manager sets of banked items: { exact = { ["bag:slot"] = names },
-- byID = { [itemID] = names } }, or nil on clients without sets. A set slot
-- whose location is a bank/bag slot marks exactly that slot; one whose
-- location cannot be read marks every banked copy of its item ID instead.
local function SetNames(list, name)
    for _, have in ipairs(list) do if have == name then return end end
    list[#list + 1] = name
end
local function EquipmentSets()
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs) then return end
    local exact, byID = {}, {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        local ids = C_EquipmentSet.GetItemIDs and C_EquipmentSet.GetItemIDs(setID) or {}
        local locations = C_EquipmentSet.GetItemLocations and C_EquipmentSet.GetItemLocations(setID)
        local UnpackLocation = EquipmentManager_UnpackLocation
        if name then
            for slot, itemID in pairs(ids) do
                local location = locations and locations[slot]
                if itemID and itemID ~= 0 then
                    if location and UnpackLocation then
                        if location > 1 then -- 0, 1: empty, missing, or ignored slot
                            local _, bank, bags, _, bagSlot, bag = UnpackLocation(location)
                            if (bank or bags) and bag then
                                local key = bag .. ":" .. bagSlot
                                exact[key] = exact[key] or {}
                                SetNames(exact[key], name)
                            end -- else equipped, or a bank slot without a bag: not matched
                        end
                    else
                        byID[itemID] = byID[itemID] or {}
                        SetNames(byID[itemID], name)
                    end
                end
            end
        end
    end
    return { exact = exact, byID = byID }
end

-- What `containers` hold: items in slot order and the total per item ID.
-- Nil while they have no slots, which means not loaded or cannot be seen.
function BankCache.ReadContainers(containers)
    local items, counts, size = {}, {}, 0
    local sets = EquipmentSets()
    for _, bag in ipairs(containers) do
        local slots = NumSlots(bag)
        size = size + slots
        for slot = 1, slots do
            local link, count, icon, itemID = SlotItem(bag, slot)
            itemID = itemID or ItemID(link)
            if itemID and not IsSecret(itemID) then
                count = count or 1
                local item = { link = link or ("item:" .. itemID), count = count, icon = icon }
                local names = sets and (sets.exact[bag .. ":" .. slot] or sets.byID[itemID])
                if names then
                    item.sets = { unpack(names) }
                    table.sort(item.sets)
                end
                items[#items + 1] = item
                counts[itemID] = (counts[itemID] or 0) + count
            end
        end
    end
    if size == 0 then return end
    return { items = items, counts = counts, size = size }
end

-- What the open bank holds, or nil when it cannot be read.
function BankCache.Read()
    local containers = BankCache.Containers()
    return containers and BankCache.ReadContainers(containers)
end

-- The carried bags: the backpack and bag slots, plus Retail's reagent bag.
-- On Era, TBC, and Mists bag NUM_BAG_SLOTS + 1 is the first bank bag, so the
-- reagent bag is only taken on bank-tab clients, and never when it is a tab.
-- The keyring (-1 on Forever) is not read.
function BankCache.BagContainers()
    local list = {}
    for bag = 0, NUM_BAG_SLOTS or 4 do list[#list + 1] = bag end
    local reagent = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
    if reagent and C_Bank and C_Bank.FetchPurchasedBankTabIDs and Enum.BankType then
        for _, tab in ipairs(C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character) or {}) do
            if tab == reagent then return list end
        end
        list[#list + 1] = reagent
    end
    return list
end

-- The logged-in character's summary; maxLevel means it cannot gain XP. A value the client keeps secret (Forever)
-- or has not loaded (an empty zone name) keeps the `previous` saved one.
function BankCache.ReadCharacter(previous)
    previous = previous or {}
    local className, class = UnitClass("player")
    local read = {
        class = class, className = className, faction = UnitFactionGroup("player"),
        level = UnitLevel("player"), money = GetMoney(), zone = GetRealZoneText(),
        xp = UnitXP("player"), xpMax = UnitXPMax("player"), rested = GetXPExhaustion(), resting = IsResting(),
        maxLevel = ScarletUI.XPDisabled(), -- XPPerHour.lua's check
    }
    for field, value in pairs(read) do
        if IsSecret(value) or value == "" then read[field] = previous[field] end
    end
    -- Tested only now: a secret value cannot be.
    read.rested, read.resting, read.maxLevel = read.rested or 0, read.resting and true or false, read.maxLevel and true or false
    return read
end

-- Rested XP as a percent of the saved level, projected from the last save to
-- `now` unless `online`: 5% of the level per 8 hours resting, a quarter of that
-- outside, up to 150%. Returns percent, percent gained since the save; nil at
-- max level or without a level size.
-- ponytail: Forever's rate is assumed to match Classic's; unchecked in game.
local RESTED_PER_SECOND, RESTED_CAP = 0.05 / (8 * 3600), 1.5
function BankCache.Rested(entry, now, online)
    local max = entry.xpMax
    if entry.maxLevel or not max or max <= 0 then return end
    local rested, projected = entry.rested or 0, entry.rested or 0
    if not online and entry.time then
        local rate = RESTED_PER_SECOND * (entry.resting and 1 or 0.25)
        projected = math.max(rested, math.min(RESTED_CAP * max, rested + math.max(0, now - entry.time) * rate * max))
    end
    return projected / max * 100, (projected - rested) / max * 100
end

-- Copper as coloured gold, silver, and copper (Craft Profit's format).
function BankCache.Money(copper)
    return ScarletUI.CraftProfit.Money(copper or 0)
end

-- The money of the listed characters, on `realm` only when given.
function BankCache.AccountMoney(list, realm)
    local total = 0
    for _, c in ipairs(list) do
        if c.info and c.info.money and (not realm or c.realm == realm) then total = total + c.info.money end
    end
    return total
end

-- The name shown for a saved character: its key without " - Realm". Forever's
-- keys are first name and surname, which already tell same-named ones apart.
function BankCache.Label(key, realm)
    local suffix = " - " .. tostring(realm)
    return key:sub(-#suffix) == suffix and key:sub(1, -#suffix - 1) or key
end

-- A character's name with its faction icon before it; banks saved before the
-- faction was recorded have none until they are seen again.
local FACTION_ICONS = { Horde = "PlusManz-Horde", Alliance = "PlusManz-Alliance" }
function BankCache.Named(label, faction)
    local icon = FACTION_ICONS[faction]
    return icon and ("|TInterface\\FriendsFrame\\" .. icon .. ":14|t " .. label) or label
end

-- Saved characters on `realm` (AceDB's realm key), `current` first, then by
-- name: { key, label, realm, entry = saved bank, info = saved summary }.
-- `characterCache` adds characters with only a summary; `allRealms` lists
-- every realm, `realm` first and the others by name.
function BankCache.Characters(cache, realm, current, characterCache, allRealms)
    local list, seen = {}, {}
    for _, source in ipairs({ cache or {}, characterCache or {} }) do
        for key, saved in pairs(source) do
            if not seen[key] then
                seen[key] = true
                local entry, info = cache and cache[key], characterCache and characterCache[key]
                local where = saved.realm
                if where == realm or (allRealms and where) then
                    list[#list + 1] = { key = key, label = BankCache.Label(key, where), realm = where, entry = entry, info = info }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.realm ~= b.realm then
            if (a.realm == realm) ~= (b.realm == realm) then return a.realm == realm end
            return tostring(a.realm) < tostring(b.realm)
        end
        if (a.key == current) ~= (b.key == current) then return a.key == current end
        return a.label < b.label
    end)
    return list
end

-- { key, label, count, time } per character on `realm` whose bank holds itemID.
function BankCache.Counts(cache, realm, itemID, current)
    local list = {}
    for _, character in ipairs(BankCache.Characters(cache, realm, current)) do
        local count = character.entry.counts and character.entry.counts[itemID]
        if count and count > 0 then
            list[#list + 1] = { key = character.key, label = character.label, count = count, time = character.entry.time }
        end
    end
    return list
end

-- How old a snapshot is, compactly: "just now", "5m ago", "3h ago", "2d ago".
-- Minutes under an hour, hours under a day, then days, each rounded down.
function BankCache.Age(saved, now)
    if not saved then return "" end
    local seconds = math.max(0, now - saved)
    if seconds < 60 then return "just now" end
    if seconds < 3600 then return math.floor(seconds / 60) .. "m ago" end
    if seconds < 86400 then return math.floor(seconds / 3600) .. "h ago" end
    return math.floor(seconds / 86400) .. "d ago"
end

-- Item name from a saved link or "item:ID": the client's item data, else the
-- [Name] saved inside the link, else nil while the client has not loaded it.
function BankCache.ItemName(link)
    local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local name = GetItemInfo and GetItemInfo(link)
    return name or link:match("%[(.-)%]")
end

-- Whether the item's name or one of its set names (`sets`, saved with the
-- item) contains `query`, ignoring case and surrounding spaces; "set:Ret"
-- looks at set names only, and bare "set:" takes any set item. An empty query
-- matches everything. Unknown names do not match.
-- Second result: the name is not loaded yet, so asking again later may differ.
-- ponytail: lower() folds ASCII only; accented capitals need a UTF-8 aware fold.
function BankCache.Matches(link, query, sets)
    query = query:match("^%s*(.-)%s*$"):lower()
    if query == "" then return true end
    local setQuery = query:match("^set:%s*(.-)$")
    for _, set in ipairs(sets or {}) do
        if set:lower():find(setQuery or query, 1, true) then return true end
    end
    if setQuery then return false end
    local name = BankCache.ItemName(link)
    if not name then return false, true end
    return name:lower():find(query, 1, true) ~= nil
end

-- A viewer slot dressed as a bag slot: the item level on gear (the bags'
-- setting), a quality-coloured border from Common up, and junk greyed with a
-- coin. Returns true while the item's data has not loaded.
function BankCache.Decorate(button, link)
    local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local quality = select(3, GetItemInfo(link))
    local color = quality and quality >= 1 and (BAG_ITEM_QUALITY_COLORS or ITEM_QUALITY_COLORS)[quality]
    if color then button.IconBorder:SetVertexColor(color.r, color.g, color.b) end
    button.IconBorder:SetShown(color and true or false)
    button.texture:SetDesaturated(quality == 0)
    button.junkCoin:SetShown(quality == 0)
    ScarletUI.ItemLevelText(link, nil, button, not ScarletUI.db.global.itemLevelBag)
    return quality == nil
end

local bankOpen, pending, pendingCharacter, viewer, viewerTip
local ALL = "ALL" -- the viewer's "All characters" choice

function ScarletUI:SnapshotBank()
    local settings = self.db.global.bankCacheModule
    if not (bankOpen and settings.enabled) then return end
    local snapshot = BankCache.Read()
    if not snapshot then return end
    snapshot.realm = self.db.keys.realm
    snapshot.class = select(2, UnitClass("player"))
    snapshot.faction = UnitFactionGroup("player")
    snapshot.time = time()
    self.db.global.bankCache = self.db.global.bankCache or {}
    self.db.global.bankCache[self.db.keys.char] = snapshot
    if viewer and viewer:IsShown() then viewer:Refresh() end
end

-- Bag and bank updates come in bursts; one snapshot after each.
function ScarletUI:ScheduleBankSnapshot()
    if pending then return end
    pending = true
    C_Timer.After(0.2, function()
        pending = false
        self:SnapshotBank()
    end)
end

-- The logged-in character's summary, bags, and last-seen time, in
-- db.global.characterCache. Bags that read as nothing keep the saved ones.
function ScarletUI:SnapshotCharacter()
    if not self.db.global.bankCacheModule.enabled then return end
    local global, key = self.db.global, self.db.keys.char
    global.characterCache = global.characterCache or {}
    local previous = global.characterCache[key] or {}
    local entry = BankCache.ReadCharacter(previous)
    entry.realm, entry.time = self.db.keys.realm, time()
    entry.bags = BankCache.ReadContainers(BankCache.BagContainers()) or previous.bags
    global.characterCache[key] = entry
    if viewer and viewer:IsShown() then viewer:Refresh() end
end

function ScarletUI:ScheduleCharacterSnapshot()
    if pendingCharacter then return end
    pendingCharacter = true
    C_Timer.After(0.2, function()
        pendingCharacter = false
        self:SnapshotCharacter()
    end)
end

local function AddBankCounts(tooltip, itemID)
    local self = ScarletUI
    local settings = self.db.global.bankCacheModule
    if viewerTip or not (settings.enabled and settings.tooltip) or not itemID or IsSecret(itemID)
        or (tooltip.IsForbidden and tooltip:IsForbidden()) then
        return
    end
    local current = self.db.keys.char
    local counts = BankCache.Counts(self.db.global.bankCache, self.db.keys.realm, itemID, current)
    for _, character in ipairs(counts) do
        local label = character.key == current and "Bank" or "Bank (" .. character.label .. ")"
        tooltip:AddLine(label .. ": " .. character.count, TOOLTIP_COLOR.r, TOOLTIP_COLOR.g, TOOLTIP_COLOR.b)
    end
    return #counts > 0
end

local function HookTooltips()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            AddBankCounts(tooltip, data and data.id)
        end)
        return
    end
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        tooltip:HookScript("OnTooltipSetItem", function(self)
            local _, link = self:GetItem()
            if AddBankCounts(self, ItemID(link)) then self:Show() end -- resize; no Show after hooks here
        end)
    end
end

function ScarletUI:SetupBankCache()
    if self.bankCacheHooked then return end
    self.bankCacheHooked = true
    local function Update(event)
        if event == "BANKFRAME_OPENED" then
            bankOpen = true
        elseif event == "BANKFRAME_CLOSED" then
            -- The bank is still readable now; save a change made just before
            -- closing. The queued timer then finds the bank closed.
            if pending then self:SnapshotBank() end
            bankOpen = false
        end
        if bankOpen then self:ScheduleBankSnapshot() end
    end
    for _, event in ipairs({ "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BAG_UPDATE", "PLAYERBANKSLOTS_CHANGED" }) do
        self:RegisterEventHandler(event, Update)
    end
    if C_Bank and C_Bank.FetchPurchasedBankTabIDs then
        self:RegisterEventHandler("BANK_TABS_CHANGED", Update)
    end
    HookTooltips()
    local function Character() self:ScheduleCharacterSnapshot() end
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE", "PLAYER_MONEY", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION",
        "PLAYER_UPDATE_RESTING", "PLAYER_LEVEL_UP", "ZONE_CHANGED_NEW_AREA" }) do
        self:RegisterEventHandler(event, Character)
    end
    -- No timer runs at logout; this save sets the time and resting state the
    -- rested projection counts from.
    self:RegisterEventHandler("PLAYER_LOGOUT", function() self:SnapshotCharacter() end)
    Character()
end

-- Viewer: the saved bags and bank of any character, as item icons. The
-- search box dims items whose name does not match; the grid keeps its places.
-- The open backpack the viewer sits beside: Bag.lua's frame, Blizzard's
-- combined bags, or the separate backpack.
local function OpenBag()
    for _, bag in ipairs({ ScarletUI_BagFrame or false, ContainerFrameCombinedBags or false, ContainerFrame1 or false }) do
        if bag and bag:IsShown() then return bag end
    end
end

-- In the bags' frame and slots (PortraitFrameTemplate, the bag slot art). It
-- opens beside the backpack and closes with it; a drag moves it until the
-- backpack opens again.
local function BuildViewer()
    viewer = CreateFrame("Frame", "ScarletUIBank", UIParent, "PortraitFrameTemplate")
    viewer:SetSize(COLUMNS * (SIZE + GAP) + 44, 500)
    viewer:SetPoint("CENTER")
    viewer:SetFrameStrata("HIGH")
    viewer:SetToplevel(true)
    viewer:SetClampedToScreen(true)
    viewer:SetMovable(true)
    viewer:EnableMouse(true)
    viewer:RegisterForDrag("LeftButton")
    local moved
    viewer:SetScript("OnDragStart", viewer.StartMoving)
    viewer:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        moved = true
    end)
    local function Anchor()
        local bag = OpenBag()
        if not bag then return end
        viewer:ClearAllPoints()
        viewer:SetPoint("BOTTOMRIGHT", bag, "BOTTOMLEFT", -14, 0)
    end
    local hooked = {}
    local function HookBags() -- Bag.lua builds its frame late, so this reruns on each opening
        for _, bag in ipairs({ ScarletUI_BagFrame or false, ContainerFrameCombinedBags or false, ContainerFrame1 or false }) do
            if bag and not hooked[bag] then
                hooked[bag] = true
                bag:HookScript("OnShow", function()
                    moved = false
                    if viewer:IsShown() then Anchor() end
                end)
                -- Closing the backpack closes the viewer. The check waits a tick:
                -- a rebuild or swap of the bag frames hides one just as another opens.
                bag:HookScript("OnHide", function()
                    C_Timer.After(0, function()
                        if viewer:IsShown() and not OpenBag() then viewer:Hide() end
                    end)
                end)
            end
        end
    end
    viewer:Hide()
    tinsert(UISpecialFrames, "ScarletUIBank")
    -- The template's X calls HideUIPanel, which refuses addon code in combat.
    if viewer.CloseButton then viewer.CloseButton:SetScript("OnClick", function() viewer:Hide() end) end
    if viewer.SetTitle then viewer:SetTitle("Scarlet UI Characters") else viewer.TitleText:SetText("Scarlet UI Characters") end
    if viewer.SetPortraitToAsset then viewer:SetPortraitToAsset(PORTRAIT) else SetPortraitToTexture(viewer.portrait, PORTRAIT) end

    local selected, query, shown, waiting = nil, "", {}, false
    local allMode -- the grid shows every character, so slots name their owner on hover
    local listed = {} -- the characters in the dropdown
    -- Dress each slot and dim non-matches; items without loaded data wait for
    -- GET_ITEM_INFO_RECEIVED.
    local buttons = {}
    local function ApplyFilter()
        waiting = false
        for i, item in ipairs(shown) do
            if not buttons[i] then break end -- Refresh failed partway
            local match, unknown = BankCache.Matches(item.link, query, item.sets)
            waiting = BankCache.Decorate(buttons[i], item.link) or waiting or unknown
            buttons[i]:SetAlpha(match and 1 or DIM_ALPHA)
            buttons[i].setMark:SetShown(item.sets ~= nil)
        end
    end

    -- SearchBoxTemplate has the clear button and placeholder; older clients lack it.
    local ok, search = pcall(CreateFrame, "EditBox", nil, viewer, "SearchBoxTemplate")
    if not ok then search = CreateFrame("EditBox", nil, viewer, "InputBoxTemplate") end
    search:SetAutoFocus(false)
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", 72, -33) -- right of the portrait
    search:SetPoint("TOPRIGHT", -14, -33)
    search:HookScript("OnTextChanged", function(self)
        query = self:GetText()
        ApplyFilter()
    end)
    -- Escape clears the search first, then closes the frame.
    search:SetScript("OnEscapePressed", function(self)
        local hadText = self:GetText() ~= ""
        self:SetText("")
        self:ClearFocus()
        if not hadText then viewer:Hide() end
    end)
    local dropdown = CreateFrame("DropdownButton", nil, viewer, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", 66, -60)
    dropdown:SetWidth(180)
    dropdown:SetDefaultText("No characters saved")
    local account = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    account:SetPoint("RIGHT", viewer, "TOPRIGHT", -16, -73) -- the dropdown's row
    -- The chosen character: level, class, zone, last seen; then money and rested XP.
    local info = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", 18, -96)
    local info2 = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info2:SetPoint("TOPLEFT", 18, -113)
    local empty = viewer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", 0, -20)

    -- ScrollFrameTemplate has the thin modern bar; older clients lack it.
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, viewer, "ScrollFrameTemplate")
    if not ok then scroll = CreateFrame("ScrollFrame", nil, viewer, "UIPanelScrollFrameTemplate") end
    scroll:SetPoint("TOPLEFT", 14, -134)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(COLUMNS * (SIZE + GAP), 1)
    scroll:SetScrollChild(content)

    local function Button(i)
        local button = buttons[i]
        if button then return button end
        -- A plain slot in the bags' art: ItemButtonTemplate is missing on
        -- Forever, and ContainerFrameItemButtonTemplate is secure. Decorate
        -- colours the quality border and adds the junk coin and item level.
        button = ScarletUI:CreateIconButton(content, SIZE, "ScarletUIBankSlot" .. i)
        button.IconBorder = button:CreateTexture(nil, "OVERLAY")
        button.IconBorder:SetAllPoints()
        button.IconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
        button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        button.Count:SetPoint("BOTTOMRIGHT", -5, 2)
        button.junkCoin = button:CreateTexture(nil, "OVERLAY")
        button.junkCoin:SetSize(14, 14)
        button.junkCoin:SetPoint("TOPLEFT", 1, -1)
        button.junkCoin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        -- Blizzard's bags mark set items with a small Equipment Manager icon.
        button.setMark = button:CreateTexture(nil, "OVERLAY")
        button.setMark:SetSize(14, 14)
        button.setMark:SetPoint("BOTTOMLEFT", 2, 2)
        if button.setMark.SetAtlas then button.setMark:SetAtlas("bags-icon-equipmentmanager") end
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- All mode: one line per character holding the item, instead of
            -- the tooltip hook's, so it shows even with that setting off.
            viewerTip = allMode
            GameTooltip:SetHyperlink(self.link)
            viewerTip = nil
            if allMode then
                local itemID, realm = ItemID(self.link), ScarletUI.db.keys.realm
                for _, c in ipairs(listed) do
                    local label = c.realm == realm and c.label or (c.label .. " (" .. tostring(c.realm) .. ")")
                    local bags = c.info and c.info.bags and c.info.bags.counts[itemID]
                    local bank = c.entry and c.entry.counts and c.entry.counts[itemID]
                    if bags then
                        GameTooltip:AddLine(("Bags: %s x%d"):format(label, bags), TOOLTIP_COLOR.r, TOOLTIP_COLOR.g, TOOLTIP_COLOR.b)
                    end
                    if bank then
                        GameTooltip:AddLine(("Bank: %s x%d (%s)"):format(label, bank, BankCache.Age(c.entry.time, time())),
                            TOOLTIP_COLOR.r, TOOLTIP_COLOR.g, TOOLTIP_COLOR.b)
                    end
                end
            end
            if self.sets then
                GameTooltip:AddLine("Set: " .. table.concat(self.sets, ", "), TOOLTIP_COLOR.r, TOOLTIP_COLOR.g, TOOLTIP_COLOR.b)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Shift-click links the item in chat, as from the bags.
        button:SetScript("OnClick", function(self)
            if HandleModifiedItemClick then HandleModifiedItemClick(self.link) end
        end)
        buttons[i] = button
        return button
    end

    local headers = {}
    local function Header(i)
        headers[i] = headers[i] or content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        return headers[i]
    end

    local DOT = "  \194\183  " -- a middle dot between parts
    local function Grey(text) return "|cff888888" .. text .. "|r" end
    local function Seen(c, now)
        if c.key == ScarletUI.db.keys.char then return "Online" end
        return "Last seen " .. BankCache.Age(c.info.time, now)
    end
    -- "Rested 45% (+12% since logout, resting)"; nil at max level or unknown.
    local function Rested(c, now)
        local percent, gained = BankCache.Rested(c.info, now, c.key == ScarletUI.db.keys.char)
        if not percent then return end
        local text = ("Rested %d%%"):format(math.floor(percent + 0.5))
        if gained >= 0.5 then
            text = text .. (" (+%d%% since logout, %s)"):format(math.floor(gained + 0.5), c.info.resting and "resting" or "outside")
        end
        return text
    end
    -- A character's Bags and Bank groups. `notes` keeps empty ones, with a line
    -- saying why; without it only groups with items are added.
    local function AddGroups(groups, c, now, notes)
        local bags, bank = c.info and c.info.bags, c.entry
        local bagItems, bankItems = bags and bags.items or {}, bank and bank.items or {}
        if notes or #bagItems > 0 then
            groups[#groups + 1] = { header = "Bags", items = bagItems,
                note = not bags and "Bags not saved yet. Log in on this character." or #bagItems == 0 and "The bags were empty." or nil }
        end
        if notes or #bankItems > 0 then
            groups[#groups + 1] = { header = "Bank" .. (bank and bank.time and ("  " .. Grey("Updated " .. BankCache.Age(bank.time, now))) or ""),
                items = bankItems,
                note = not bank and "No bank saved yet. Open your bank to save it." or #bankItems == 0 and "This bank was empty." or nil }
        end
    end

    -- The choice is saved: "All characters" or a character key; a character
    -- that is gone falls back to the first (the current one). Every realm is
    -- listed, this one first, under realm titles when there are several.
    function viewer:Refresh()
        local db = ScarletUI.db
        local settings = db.global.bankCacheModule
        local characters = BankCache.Characters(db.global.bankCache, db.keys.realm, db.keys.char, db.global.characterCache, true)
        local realms = 0
        for i, c in ipairs(characters) do
            if i == 1 or c.realm ~= characters[i - 1].realm then realms = realms + 1 end
        end
        -- A realm choice ("realm:Name", offered only with several realms) shows
        -- that realm's characters as All mode does; a realm that is gone falls back.
        local realmChoice = realms > 1 and type(settings.viewerChoice) == "string" and settings.viewerChoice:match("^realm:(.*)$")
        local visible = characters
        if realmChoice then
            visible = {}
            for _, c in ipairs(characters) do
                if tostring(c.realm) == realmChoice then visible[#visible + 1] = c end
            end
            if #visible == 0 then realmChoice, visible = nil, characters end
        end
        listed = visible
        local character
        for _, c in ipairs(characters) do
            if c.key == settings.viewerChoice then character = c end
        end
        character = character or characters[1]
        selected = #characters > 0 and (settings.viewerChoice == ALL and ALL or realmChoice and "realm:" .. realmChoice or character.key) or nil
        allMode = settings.viewerChoice == ALL or realmChoice and true or false
        local function Pick(key)
            return function() return key == selected end, function()
                settings.viewerChoice = key
                viewer:Refresh()
            end
        end
        local function Name(c) return BankCache.Named(c.label, c.info and c.info.faction or c.entry and c.entry.faction) end
        local function RealmTitle(realm)
            return tostring(realm) .. "  " .. BankCache.Money(BankCache.AccountMoney(characters, realm))
        end
        -- Calls `realmTitle(realm)` before each realm's characters when there are several.
        local function EachCharacter(fn, realmTitle, list)
            list = list or visible
            for i, c in ipairs(list) do
                if realms > 1 and (i == 1 or c.realm ~= list[i - 1].realm) then realmTitle(c.realm) end
                fn(c)
            end
        end
        dropdown:SetupMenu(function(_, root)
            root:CreateRadio("All characters", Pick(ALL))
            EachCharacter(function(c)
                local level = c.info and c.info.level and ("  " .. Grey(c.info.level)) or ""
                root:CreateRadio(Name(c) .. level, Pick(c.key))
            end, function(realm) root:CreateRadio(RealmTitle(realm), Pick("realm:" .. tostring(realm))) end, characters)
        end)
        account:SetText(#characters > 0 and ("Account: " .. BankCache.Money(BankCache.AccountMoney(characters))) or "")
        -- Groups of slots under headers. All mode heads each character's with
        -- its name, level, money and last seen, and each realm's with its money.
        local groups, now = {}, time()
        if allMode then
            EachCharacter(function(c)
                local text = Name(c)
                if c.info then
                    text = text .. "  " .. Grey("Level " .. tostring(c.info.level)) .. "  " .. BankCache.Money(c.info.money)
                        .. "  " .. Grey(Seen(c, now))
                end
                groups[#groups + 1] = { header = text, items = {} }
                AddGroups(groups, c, now, false)
            end, function(realm) groups[#groups + 1] = { header = RealmTitle(realm), items = {} } end)
        elseif character then
            AddGroups(groups, character, now, true)
        end
        local summary = not allMode and character and character.info
        if summary then
            local class = summary.className or summary.class or ""
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[summary.class]
            if color then class = ("|cff%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, class) end
            local parts = { ("Level %s %s"):format(tostring(summary.level), class) }
            if summary.zone then parts[#parts + 1] = summary.zone end
            parts[#parts + 1] = Seen(character, now)
            info:SetText(table.concat(parts, DOT))
            local rested = Rested(character, now)
            info2:SetText("Gold " .. BankCache.Money(summary.money) .. (rested and (DOT .. rested) or ""))
        else
            info:SetText("")
            info2:SetText("")
        end
        empty:SetText(#characters == 0 and "Nothing saved yet." or "")
        local n, y, h = 0, 4, 0
        shown = {}
        local function Line(text)
            h = h + 1
            local header = Header(h)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 4, -y)
            header:SetText(text)
            header:Show()
            y = y + 20
        end
        for _, group in ipairs(groups) do
            Line(group.header)
            if group.note then Line(Grey(group.note)) end
            for k, item in ipairs(group.items) do
                n = n + 1
                local button = Button(n)
                button.link, button.sets = item.link, item.sets or false
                button.texture:SetTexture(item.icon or 134400) -- question mark
                button.Count:SetText((item.count or 1) > 1 and item.count or "")
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", ((k - 1) % COLUMNS) * (SIZE + GAP) + 4, -(y + math.floor((k - 1) / COLUMNS) * (SIZE + GAP)))
                button:Show()
                shown[n] = item
            end
            y = y + math.ceil(#group.items / COLUMNS) * (SIZE + GAP) + (#group.items > 0 and 6 or 0)
        end
        for i = n + 1, #buttons do buttons[i]:Hide() end
        for i = h + 1, #headers do headers[i]:Hide() end
        content:SetHeight(y + 4)
        ApplyFilter()
    end
    viewer:SetScript("OnShow", function(self)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        HookBags()
        if not moved then Anchor() end
        self:Refresh()
    end)
    -- Closing by any route (X, Escape unfocused) starts the next opening unfiltered.
    viewer:SetScript("OnHide", function() search:SetText("") end)
    viewer:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    local queued
    viewer:SetScript("OnEvent", function(self)
        if not (waiting and self:IsShown()) or queued then return end
        queued = true
        C_Timer.After(0.1, function() -- item data arrives in bursts
            queued = false
            ApplyFilter()
        end)
    end)
end

-- `show` forces it open or closed; nil toggles.
function ScarletUI:ToggleBankViewer(show)
    if not viewer then BuildViewer() end
    if show == nil then show = not viewer:IsShown() end
    viewer:SetShown(show)
    if show then viewer:Raise() end
end
