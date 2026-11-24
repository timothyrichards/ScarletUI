-- Cached bank: the client only shows bank contents while the bank is open, so
-- each character's bank is saved when seen (db.global.bankCache, keyed by
-- AceDB's character key) and shown later in a viewer (/sui bank) and as bank
-- counts on item tooltips. Retail and Forever keep the bank in purchased tabs
-- (C_Bank.FetchPurchasedBankTabIDs; Forever's are bank bags); Era, TBC, and
-- Mists in the bank container and bank bags. The Warband/account bank is not
-- saved. Only add-on data is written; tooltips get post-hooked lines.
local BankCache = {}
ScarletUI.BankCache = BankCache

local IsSecret = issecretvalue or function() return false end
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

-- What the open bank holds: items in bank order and the total per item ID.
-- Nil while it has no slots, which means it has not loaded or cannot be seen.
function BankCache.Read()
    local containers = BankCache.Containers()
    if not containers then return end
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

-- Saved characters on `realm` (AceDB's realm key), `current` first, then by name.
function BankCache.Characters(cache, realm, current)
    local list = {}
    for key, entry in pairs(cache or {}) do
        if entry.realm == realm then
            list[#list + 1] = { key = key, label = BankCache.Label(key, realm), entry = entry }
        end
    end
    table.sort(list, function(a, b)
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

local bankOpen, pending, viewer, viewerTip
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
end

-- Viewer: the saved bank of a character on this realm, as item icons. The
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
    viewer:SetSize(COLUMNS * (SIZE + GAP) + 44, 450)
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
    if viewer.SetTitle then viewer:SetTitle("Scarlet UI Bank") else viewer.TitleText:SetText("Scarlet UI Bank") end
    if viewer.SetPortraitToAsset then viewer:SetPortraitToAsset(PORTRAIT) else SetPortraitToTexture(viewer.portrait, PORTRAIT) end

    local selected, query, shown, waiting = nil, "", {}, false
    local allMode -- the grid shows every character, so slots name their owner on hover
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
    dropdown:SetDefaultText("No banks saved")
    local lastSeen = viewer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lastSeen:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)
    local empty = viewer:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", 0, -20)

    -- ScrollFrameTemplate has the thin modern bar; older clients lack it.
    local ok, scroll = pcall(CreateFrame, "ScrollFrame", nil, viewer, "ScrollFrameTemplate")
    if not ok then scroll = CreateFrame("ScrollFrame", nil, viewer, "UIPanelScrollFrameTemplate") end
    scroll:SetPoint("TOPLEFT", 14, -96)
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
                local db = ScarletUI.db
                for _, c in ipairs(BankCache.Counts(db.global.bankCache, db.keys.realm, ItemID(self.link), db.keys.char)) do
                    GameTooltip:AddLine(("Bank: %s x%d (%s)"):format(c.label, c.count, BankCache.Age(c.time, time())),
                        TOOLTIP_COLOR.r, TOOLTIP_COLOR.g, TOOLTIP_COLOR.b)
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

    -- The choice is saved: "All characters" or a character key; a character
    -- that is gone falls back to the first (the current one).
    function viewer:Refresh()
        local db = ScarletUI.db
        local settings = db.global.bankCacheModule
        local characters = BankCache.Characters(db.global.bankCache, db.keys.realm, db.keys.char)
        local character
        for _, c in ipairs(characters) do
            if c.key == settings.viewerChoice then character = c end
        end
        character = character or characters[1]
        selected = #characters > 0 and (settings.viewerChoice == ALL and ALL or character.key) or nil
        allMode = selected == ALL
        local function Pick(key)
            return function() return key == selected end, function()
                settings.viewerChoice = key
                viewer:Refresh()
            end
        end
        dropdown:SetupMenu(function(_, root)
            root:CreateRadio("All characters", Pick(ALL))
            for _, c in ipairs(characters) do root:CreateRadio(BankCache.Named(c.label, c.entry.faction), Pick(c.key)) end
        end)
        -- Groups of slots; All mode puts a header with the age on each character's.
        local groups, now = {}, time()
        if allMode then
            for _, c in ipairs(characters) do
                if c.entry.items and #c.entry.items > 0 then
                    groups[#groups + 1] = { header = BankCache.Named(c.label, c.entry.faction) .. "  |cff888888Updated " .. BankCache.Age(c.entry.time, now) .. "|r", items = c.entry.items }
                end
            end
        elseif character then
            groups[1] = { items = character.entry.items or {} }
        end
        local entry = character and character.entry
        lastSeen:SetText(entry and not allMode and ("Updated " .. BankCache.Age(entry.time, now)) or "")
        empty:SetText(not entry and "No bank saved yet. Open your bank to save it."
            or #groups == 0 and (allMode and "Every saved bank is empty." or "This bank was empty.") or "")
        local n, y, h = 0, 4, 0
        shown = {}
        for _, group in ipairs(groups) do
            if group.header then
                h = h + 1
                local header = Header(h)
                header:ClearAllPoints()
                header:SetPoint("TOPLEFT", 4, -y)
                header:SetText(group.header)
                header:Show()
                y = y + 20
            end
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
            y = y + math.ceil(#group.items / COLUMNS) * (SIZE + GAP) + (group.header and 6 or 0)
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
