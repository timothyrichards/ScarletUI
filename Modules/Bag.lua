-- Keyring was removed in Patch 4.2 (Cataclysm); hide it for Mists of Pandaria and above
local KEYRING_CONTAINER = KEYRING_CONTAINER
if KEYRING_CONTAINER then
    local _, _, _, interfaceVersion = GetBuildInfo()
    if tonumber(interfaceVersion) >= 50000 then
        KEYRING_CONTAINER = nil
    end
end

local GetContainerNumSlots = C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo or GetContainerItemInfo
local GetContainerItemLink = C_Container.GetContainerItemLink or GetContainerItemLink
local PickupContainerItem = C_Container.PickupContainerItem or PickupContainerItem
local UseContainerItem = C_Container.UseContainerItem or UseContainerItem
local GetContainerItemCooldown = C_Container.GetContainerItemCooldown or GetContainerItemCooldown
local ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID or ContainerIDToInventoryID
local SplitContainerItem = C_Container.SplitContainerItem or SplitContainerItem
local GetContainerNumFreeSlots = C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
local SortBags = C_Container.SortBags or _G.SortBags

-- Bag type border colors for specialty containers (bagType bitmask -> RGB)
local bagTypeColors = {
    [1]    = { 0.8, 0.6, 0.3 },  -- Quiver (amber)
    [2]    = { 0.8, 0.6, 0.3 },  -- Ammo Pouch (amber, same as quiver)
    [4]    = { 0.7, 0.3, 0.9 },  -- Soul Bag (purple)
    [8]    = { 0.6, 0.4, 0.2 },  -- Leatherworking Bag (brown)
    [16]   = { 0.9, 0.9, 0.6 },  -- Inscription Bag (parchment)
    [32]   = { 0.2, 0.8, 0.2 },  -- Herb Bag (green)
    [64]   = { 0.4, 0.5, 1.0 },  -- Enchanting Bag (blue)
    [128]  = { 0.9, 0.5, 0.1 },  -- Engineering Bag (orange)
    [256]  = { 0.9, 0.8, 0.3 },  -- Keyring (gold)
    [512]  = { 0.1, 0.9, 0.9 },  -- Gem Bag (cyan)
    [1024] = { 0.7, 0.7, 0.7 },  -- Mining Bag (silver)
}

local bagSlots = {}
local orderedSlots = {}
local lastPickedUpButton
local hiddenBags = {}
local searchText = ""
local headerHeight = 28
local lastBagCounts = {}
local bagEquipInProgress = false
local origPutItemInBag = PutItemInBag
local bagStateHandled = false
local bagStateResetFrame
local bagBindingFrame
local bagBindingButton

local bankSlots = {}
local orderedBankSlots = {}
local hiddenBankBags = {}
local bankSearchText = ""
local bankBagButtons = {}
local lastBankBagCounts = {}

-- Button pools for reuse across rebuilds
local bagButtonPool = {}
local bankButtonPool = {}

-- Sort frame singletons (avoid creating new frames per sort)
local bagSortFrame
local bankSortFrame
local sortMoveDelay = 0.05

local function ResizeSlotButton(button, size)
    button:SetSize(size, size)
    -- Template default is 37px button with 64px border texture
    local borderSize = size * (64 / 37)
    local icon = button.icon or button.Icon
    if icon then
        icon:SetSize(size, size)
    end
    local nt = button:GetNormalTexture()
    if nt then
        nt:SetSize(borderSize, borderSize)
    end
    local pt = button:GetPushedTexture()
    if pt then
        pt:SetSize(borderSize, borderSize)
    end
    local ht = button:GetHighlightTexture()
    if ht then
        ht:SetSize(size, size)
    end
    if button.IconBorder then
        button.IconBorder:SetSize(size, size)
    end
    if button.IconOverlay then
        button.IconOverlay:SetSize(size, size)
    end
end

local function IsPlayerBag(bagID)
    return bagID
        and ((bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS)
            or (KEYRING_CONTAINER and bagID == KEYRING_CONTAINER))
end

local function MarkBagStateHandled()
    bagStateHandled = true

    if bagStateResetFrame then
        bagStateResetFrame:SetScript("OnUpdate", function(frame)
            bagStateHandled = false
            frame:SetScript("OnUpdate", nil)
        end)
    end
end

local function ShowBagFrame()
    if ScarletUI_BagFrame then
        local wasShown = ScarletUI_BagFrame:IsShown()
        ScarletUI_BagFrame:Show()
        if not wasShown then
            MarkBagStateHandled()
        end
    end
end

local function HideBagFrame()
    if ScarletUI_BagFrame then
        local wasShown = ScarletUI_BagFrame:IsShown()
        ScarletUI_BagFrame:Hide()
        if wasShown then
            MarkBagStateHandled()
        end
    end
end

local function ToggleBagFrameIfUnhandled()
    if bagStateHandled then
        return
    end

    if ScarletUI_BagFrame then
        ScarletUI_BagFrame:SetShown(not ScarletUI_BagFrame:IsShown())
        -- Classic clients can nest bag toggle functions (for example,
        -- ToggleBackpack calling ToggleBag). Keep the guard set until the next
        -- frame so every hook in the same call chain cannot toggle us again.
        MarkBagStateHandled()
    end
end

local function ToggleBagFrame()
    if ScarletUI_BagFrame then
        ScarletUI_BagFrame:SetShown(not ScarletUI_BagFrame:IsShown())
    end
end

local function ApplyBagKeybindOverrides()
    if not SetOverrideBindingClick or not ClearOverrideBindings or not GetBindingKey or (InCombatLockdown and InCombatLockdown()) then
        return
    end

    if not bagBindingButton then
        bagBindingButton = CreateFrame("Button", "ScarletUI_BagKeybindButton", UIParent)
        bagBindingButton:SetScript("OnClick", ToggleBagFrame)
    end

    ClearOverrideBindings(bagBindingButton)

    local commands = { "OPENALLBAGS", "TOGGLEBACKPACK", "TOGGLEBAG1", "TOGGLEBAG2", "TOGGLEBAG3", "TOGGLEBAG4", "TOGGLEKEYRING" }
    for _, command in ipairs(commands) do
        local keys = { GetBindingKey(command) }
        for _, key in ipairs(keys) do
            SetOverrideBindingClick(bagBindingButton, false, key, "ScarletUI_BagKeybindButton")
        end
    end
end

local function HideTooltipIfOwned(frame)
    if GameTooltip.IsOwned and not GameTooltip:IsOwned(frame) then
        return
    end

    GameTooltip:Hide()
end

local function UpdateBagCursor(frame)
    if ShowContainerSellCursor and IsPlayerBag(frame.bag) and MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 then
        ShowContainerSellCursor(frame.bag, frame.slot)
    end
end

local function ResetBagCursor()
    if ResetCursor and (not CursorHasItem or not CursorHasItem()) then
        ResetCursor()
    end
end

local function RefreshHoveredTooltip(frame, elapsed)
    frame.scarletTooltipElapsed = (frame.scarletTooltipElapsed or 0) + elapsed
    if frame.scarletTooltipElapsed < 0.25 then
        return
    end
    frame.scarletTooltipElapsed = 0

    if frame:IsMouseOver() and frame.UpdateTooltip then
        frame:UpdateTooltip()
        UpdateBagCursor(frame)
    else
        frame:SetScript("OnUpdate", nil)
    end
end

local function updateCurrencyDisplay()
    local currencyFooter = ScarletUI.bagFrame.currencyFooter;

    -- Iterate over each currency
    local trackedIndex = 1
    for i = 1, GetCurrencyListSize() do
        if trackedIndex <= 3 then
            local _, isHeader, _, _, isWatched, count, icon = GetCurrencyListInfo(i)
            if not isHeader and isWatched then
                -- Get the existing FontString or create a new one
                local fs = currencyFooter.currencies[trackedIndex]
                fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                fs:SetText(count)

                -- Get the existing Texture or create a new one
                local iconTexture = fs.iconTexture
                iconTexture:SetTexture(icon)
                iconTexture:SetSize(16, 16)

                -- Position the FontString and the Texture
                if trackedIndex == 1 then
                    fs:SetPoint("LEFT", currencyFooter, "LEFT", 0, 0)
                    iconTexture:SetPoint("LEFT", fs, "RIGHT", 5, 0)
                else
                    fs:SetPoint("LEFT", currencyFooter.currencies[trackedIndex - 1], "RIGHT", 30, 0)
                    iconTexture:SetPoint("LEFT", fs, "RIGHT", 5, 0)
                end

                -- Show the FontString and the Texture
                fs:Show()
                iconTexture:Show()

                trackedIndex = trackedIndex + 1
            end
        end
    end

    -- Hide unused currency displays
    for i = trackedIndex, 3 do
        if currencyFooter.currencies[i] then
            currencyFooter.currencies[i]:Hide()
            if currencyFooter.currencies[i].iconTexture then
                currencyFooter.currencies[i].iconTexture:Hide()
            end
        end
    end
end

local function UpdateCurrencyFooter()
    local currencyFooter = ScarletUI.bagFrame.currencyFooter;
    local gold = math.floor(GetMoney() / (COPPER_PER_SILVER * SILVER_PER_GOLD))
    local silver = math.floor((GetMoney() - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
    local bronze = math.floor(GetMoney() % COPPER_PER_SILVER)

    currencyFooter.goldText:SetText(gold)
    currencyFooter.silverText:SetText(silver)
    currencyFooter.bronzeText:SetText(bronze)
end

local function ApplySearchFilter()
    local lowerSearch = string.lower(searchText)
    for _, button in ipairs(orderedSlots) do
        if button:IsShown() then
            if searchText ~= "" then
                local itemLink = GetContainerItemLink(button.bag, button.slot)
                if itemLink then
                    local itemName = GetItemInfo(itemLink)
                    if itemName and string.find(string.lower(itemName), lowerSearch, 1, true) then
                        button:SetAlpha(1)
                    else
                        button:SetAlpha(0.3)
                    end
                else
                    button:SetAlpha(1)
                end
            else
                button:SetAlpha(1)
            end
        end
    end
end

local function RebuildSlotLayout()
    local bagModule = ScarletUI.db.global.bagModule
    local borderPadding = 10
    local startX = borderPadding
    local startY = -borderPadding - headerHeight - 5
    local distance = bagModule.slotSize + bagModule.slotSpacing

    local visibleIndex = 0
    for _, button in ipairs(orderedSlots) do
        if hiddenBags[button.bag] then
            button:Hide()
        else
            visibleIndex = visibleIndex + 1
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", ScarletUI.bagFrame, "TOPLEFT", startX + ((visibleIndex - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((visibleIndex - 1) / bagModule.slotsPerRow) * -distance)
            button:Show()
        end
    end

    local numRows = math.ceil(math.max(visibleIndex, 1) / bagModule.slotsPerRow)
    local bagFrameWidth = (bagModule.slotSize + bagModule.slotSpacing) * bagModule.slotsPerRow - bagModule.slotSpacing + borderPadding * 2
    local slotGridHeight = (bagModule.slotSize + bagModule.slotSpacing) * numRows - bagModule.slotSpacing
    local currencyFooterHeight = 20
    local bagFrameHeight = slotGridHeight + borderPadding * 2 + currencyFooterHeight + 10 + headerHeight + 5
    ScarletUI.bagFrame:SetSize(bagFrameWidth, bagFrameHeight)

    ApplySearchFilter()
end

local function UpdateBagSlots(bag)
    for slot = 1, GetContainerNumSlots(bag) do
        local index = bag * 100 + slot
        local button = bagSlots[index]
        if not button then break end
        local containerInfo = GetContainerItemInfo(bag, slot)
        if containerInfo and containerInfo.iconFileID then
            SetItemButtonTexture(button, containerInfo.iconFileID)
            SetItemButtonCount(button, containerInfo.stackCount)

            local itemQuality = containerInfo.quality

            -- Use template's quality border
            if SetItemButtonQuality then
                SetItemButtonQuality(button, itemQuality, containerInfo.hyperlink)
            end

            -- Gray out junk items and show coin icon
            if itemQuality and itemQuality == 0 then
                SetItemButtonDesaturated(button, true)
                button.junkCoin:Show()
            else
                SetItemButtonDesaturated(button, false)
                button.junkCoin:Hide()
            end

            -- Update the cooldown
            local start, duration = GetContainerItemCooldown(bag, slot)
            if start > 0 and duration > 0 then
                button.Cooldown:SetCooldown(start, duration)
                button.Cooldown:Show()
            else
                button.Cooldown:Hide()
            end
        else
            SetItemButtonTexture(button, nil)
            SetItemButtonCount(button, 0)
            SetItemButtonDesaturated(button, false)
            if SetItemButtonQuality then
                SetItemButtonQuality(button, nil)
            end
            button.Cooldown:Hide()
            button.junkCoin:Hide()
        end
    end
end

local function UpdateBag()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        UpdateBagSlots(bag)
    end
    if KEYRING_CONTAINER then
        UpdateBagSlots(KEYRING_CONTAINER)
    end

    ScarletUI:BagItemLevel()
    UpdateCurrencyFooter()
    ApplySearchFilter()
end

-- Returns the bag type for a container (0 = normal, non-zero = specialty like quiver/ammo/soul)
local function GetBagType(bag)
    if bag == BACKPACK_CONTAINER then return 0 end
    if KEYRING_CONTAINER and bag == KEYRING_CONTAINER then return 256 end
    local _, bagType = GetContainerNumFreeSlots(bag)
    return bagType or 0
end

local function GetSortSlotKey(slot)
    return slot.bag .. ":" .. slot.slot
end

local function GetSortItemSignature(item)
    if not item then return nil end

    if item.itemID and item.itemID ~= 0 then
        return "id:" .. tostring(item.itemID) .. ":" .. tostring(item.stackCount or 1)
    end

    return "name:"
        .. tostring(item.name or "") .. ":"
        .. tostring(item.quality or 0) .. ":"
        .. tostring(item.itemType or "") .. ":"
        .. tostring(item.subType or "") .. ":"
        .. tostring(item.stackCount or 1)
end

local function IsSortSlotLocked(slot)
    if not slot then return false end

    local info, _, locked = GetContainerItemInfo(slot.bag, slot.slot)
    if type(info) == "table" then
        return info.isLocked
    end

    return locked
end

local function IsSortMoveLocked(move)
    return move and (IsSortSlotLocked(move.source) or IsSortSlotLocked(move.target))
end

local function BuildFinalSortMoves(allSlots, items)
    local slotByKey = {}
    local slotToItem = {}
    local targetSignatureBySlotKey = {}
    local moves = {}

    for _, slot in ipairs(allSlots) do
        slotByKey[GetSortSlotKey(slot)] = slot
    end

    for _, item in ipairs(items) do
        item.key = item.key or GetSortSlotKey(item)
        slotToItem[item.key] = item
    end

    for index, desiredItem in ipairs(items) do
        local targetSlot = allSlots[index]
        if targetSlot then
            targetSignatureBySlotKey[GetSortSlotKey(targetSlot)] = GetSortItemSignature(desiredItem)
        end
    end

    local function FindSourceItem(signature, targetKey)
        local fallbackKey, fallbackItem

        for sourceKey, item in pairs(slotToItem) do
            if sourceKey ~= targetKey and GetSortItemSignature(item) == signature then
                if targetSignatureBySlotKey[sourceKey] ~= signature then
                    return sourceKey, item
                end

                if not fallbackKey then
                    fallbackKey = sourceKey
                    fallbackItem = item
                end
            end
        end

        return fallbackKey, fallbackItem
    end

    for index, desiredItem in ipairs(items) do
        local targetSlot = allSlots[index]
        if targetSlot then
            local targetKey = GetSortSlotKey(targetSlot)
            local desiredSignature = GetSortItemSignature(desiredItem)
            local currentItem = slotToItem[targetKey]

            if GetSortItemSignature(currentItem) ~= desiredSignature then
                local sourceKey, sourceItem = FindSourceItem(desiredSignature, targetKey)
                local sourceSlot = sourceKey and slotByKey[sourceKey]

                if sourceSlot and sourceItem then
                    table.insert(moves, {
                        source = { bag = sourceSlot.bag, slot = sourceSlot.slot },
                        target = { bag = targetSlot.bag, slot = targetSlot.slot },
                    })

                    slotToItem[sourceKey] = currentItem
                    slotToItem[targetKey] = sourceItem
                end
            end
        end
    end

    return moves
end

local function CustomSortBags()
    -- Group bags by their bag type so we never move items across bag types
    local bagGroups = {}
    local groupOrder = {}
    local allBags = {}
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        table.insert(allBags, bag)
    end
    if KEYRING_CONTAINER and GetContainerNumSlots(KEYRING_CONTAINER) > 0 then
        table.insert(allBags, KEYRING_CONTAINER)
    end
    for _, bag in ipairs(allBags) do
        if GetContainerNumSlots(bag) > 0 then
            local bagType = GetBagType(bag)
            if not bagGroups[bagType] then
                bagGroups[bagType] = {}
                table.insert(groupOrder, bagType)
            end
            table.insert(bagGroups[bagType], bag)
        end
    end
    table.sort(groupOrder)

    local function FindMergeInBags(bags)
        local partials = {}
        for _, bag in ipairs(bags) do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, _, _, _, _, _, maxStack = GetItemInfo(link)
                    local info = GetContainerItemInfo(bag, slot)
                    local itemID = info and info.itemID or 0
                    local count = info and info.stackCount or 1
                    maxStack = maxStack or 1
                    if maxStack > 1 and count < maxStack then
                        if not partials[itemID] then partials[itemID] = {} end
                        table.insert(partials[itemID], { bag = bag, slot = slot, count = count })
                    end
                end
            end
        end

        for _, slots in pairs(partials) do
            if #slots >= 2 then
                table.sort(slots, function(a, b) return a.count > b.count end)
                local dst = slots[1]
                local src = slots[#slots]
                local move = {
                    source = { bag = src.bag, slot = src.slot },
                    target = { bag = dst.bag, slot = dst.slot },
                }
                PickupContainerItem(src.bag, src.slot)
                PickupContainerItem(dst.bag, dst.slot)
                if CursorHasItem() then ClearCursor() end
                return true, move
            end
        end
        return false
    end

    local function ScanAndSortBags(bags)
        local allSlots = {}
        local items = {}

        for _, bag in ipairs(bags) do
            for slot = 1, GetContainerNumSlots(bag) do
                table.insert(allSlots, { bag = bag, slot = slot })
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local name, _, quality, _, _, itemType, subType = GetItemInfo(link)
                    if name then
                        local containerInfo = GetContainerItemInfo(bag, slot)
                        local stackCount = containerInfo and containerInfo.stackCount or 1
                        local itemID = containerInfo and containerInfo.itemID or 0
                        table.insert(items, {
                            bag = bag, slot = slot,
                            key = bag .. ":" .. slot,
                            name = name, quality = quality or 0,
                            itemType = itemType or "", subType = subType or "",
                            stackCount = stackCount, itemID = itemID,
                        })
                    end
                end
            end
        end

        table.sort(items, function(a, b)
            if a.quality ~= b.quality then return a.quality > b.quality end
            if a.itemType ~= b.itemType then return a.itemType < b.itemType end
            if a.subType ~= b.subType then return a.subType < b.subType end
            if a.name ~= b.name then return a.name < b.name end
            if a.stackCount ~= b.stackCount then return a.stackCount > b.stackCount end
            if a.itemID ~= b.itemID then return a.itemID < b.itemID end
            if a.bag ~= b.bag then return a.bag < b.bag end
            return a.slot < b.slot
        end)

        return allSlots, items
    end

    bagSortFrame = bagSortFrame or CreateFrame("Frame")
    local sortFrame = bagSortFrame
    sortFrame:SetScript("OnUpdate", nil)
    local ticker = 0
    local passes = 0
    local phase = "merge"
    local groupIndex = 1
    local sortMoves
    local moveIndex = 1
    local pendingMove

    sortFrame:SetScript("OnUpdate", function(self, dt)
        ticker = ticker + dt

        if CursorHasItem() then
            ClearCursor()
            return
        end

        if IsSortMoveLocked(pendingMove) then
            return
        end
        pendingMove = nil

        if ticker < sortMoveDelay then return end
        ticker = 0

        passes = passes + 1
        if passes > 200 then
            self:SetScript("OnUpdate", nil)
            UpdateBag()
            return
        end

        if groupIndex > #groupOrder then
            self:SetScript("OnUpdate", nil)
            UpdateBag()
            return
        end

        local currentBags = bagGroups[groupOrder[groupIndex]]

        -- Phase 1: merge partial stacks within this bag type group
        if phase == "merge" then
            local merged, mergeMove = FindMergeInBags(currentBags)
            if merged then
                pendingMove = mergeMove
            else
                phase = "sort"
                sortMoves = nil
                moveIndex = 1
            end
            return
        end

        -- Phase 2: execute a fixed positional plan within this bag type group.
        if not sortMoves then
            local allSlots, items = ScanAndSortBags(currentBags)
            sortMoves = BuildFinalSortMoves(allSlots, items)
            moveIndex = 1
        end

        local move = sortMoves[moveIndex]
        if move then
            PickupContainerItem(move.source.bag, move.source.slot)
            PickupContainerItem(move.target.bag, move.target.slot)
            if CursorHasItem() then ClearCursor() end
            pendingMove = move
            moveIndex = moveIndex + 1
        else
            local allSlots, items = ScanAndSortBags(currentBags)
            local validationMoves = BuildFinalSortMoves(allSlots, items)
            if #validationMoves > 0 then
                sortMoves = validationMoves
                moveIndex = 1
            else
                groupIndex = groupIndex + 1
                phase = "merge"
                sortMoves = nil
                moveIndex = 1
                pendingMove = nil
            end
        end
    end)
end

if not SortBags then
    SortBags = CustomSortBags
end

local function ApplyBankSearchFilter()
    local lowerSearch = string.lower(bankSearchText)
    for _, button in ipairs(orderedBankSlots) do
        if button:IsShown() then
            if bankSearchText ~= "" then
                local itemLink = GetContainerItemLink(button.bag, button.slot)
                if itemLink then
                    local itemName = GetItemInfo(itemLink)
                    if itemName and string.find(string.lower(itemName), lowerSearch, 1, true) then
                        button:SetAlpha(1)
                    else
                        button:SetAlpha(0.3)
                    end
                else
                    button:SetAlpha(1)
                end
            else
                button:SetAlpha(1)
            end
        end
    end
end

local function RebuildBankSlotLayout()
    local bagModule = ScarletUI.db.global.bagModule
    local borderPadding = 10
    local startX = borderPadding
    local startY = -borderPadding - headerHeight - 5
    local distance = bagModule.slotSize + bagModule.slotSpacing

    local visibleIndex = 0
    for _, button in ipairs(orderedBankSlots) do
        if hiddenBankBags[button.bag] then
            button:Hide()
        else
            visibleIndex = visibleIndex + 1
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", ScarletUI.bankFrame, "TOPLEFT", startX + ((visibleIndex - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((visibleIndex - 1) / bagModule.slotsPerRow) * -distance)
            button:Show()
        end
    end

    local numRows = math.ceil(math.max(visibleIndex, 1) / bagModule.slotsPerRow)
    local bankFrameWidth = (bagModule.slotSize + bagModule.slotSpacing) * bagModule.slotsPerRow - bagModule.slotSpacing + borderPadding * 2
    local slotGridHeight = (bagModule.slotSize + bagModule.slotSpacing) * numRows - bagModule.slotSpacing
    local bagSlotRowHeight = (ScarletUI.bankFrame and ScarletUI.bankFrame.bagSlotRow) and 33 or 0
    local bankFrameHeight = slotGridHeight + borderPadding * 2 + headerHeight + 5 + bagSlotRowHeight
    ScarletUI.bankFrame:SetSize(bankFrameWidth, bankFrameHeight)

    ApplyBankSearchFilter()
end

local function UpdateBank()
    -- Update main bank container (BANK_CONTAINER = -1)
    for slot = 1, GetContainerNumSlots(BANK_CONTAINER) do
        local index = BANK_CONTAINER * 100 + slot
        local button = bankSlots[index]
        if button then
            local containerInfo = GetContainerItemInfo(BANK_CONTAINER, slot)
            if containerInfo and containerInfo.iconFileID then
                SetItemButtonTexture(button, containerInfo.iconFileID)
                SetItemButtonCount(button, containerInfo.stackCount)

                local itemQuality = containerInfo.quality
                if SetItemButtonQuality then
                    SetItemButtonQuality(button, itemQuality, containerInfo.hyperlink)
                end

                if itemQuality and itemQuality == 0 then
                    SetItemButtonDesaturated(button, true)
                    button.junkCoin:Show()
                else
                    SetItemButtonDesaturated(button, false)
                    button.junkCoin:Hide()
                end

                local start, duration = GetContainerItemCooldown(BANK_CONTAINER, slot)
                if start > 0 and duration > 0 then
                    button.Cooldown:SetCooldown(start, duration)
                    button.Cooldown:Show()
                else
                    button.Cooldown:Hide()
                end
            else
                SetItemButtonTexture(button, nil)
                SetItemButtonCount(button, 0)
                SetItemButtonDesaturated(button, false)
                if SetItemButtonQuality then
                    SetItemButtonQuality(button, nil)
                end
                button.Cooldown:Hide()
                button.junkCoin:Hide()
            end
        end
    end

    -- Update bank bag containers
    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local index = bag * 100 + slot
            local button = bankSlots[index]
            if button then
                local containerInfo = GetContainerItemInfo(bag, slot)
                if containerInfo and containerInfo.iconFileID then
                    SetItemButtonTexture(button, containerInfo.iconFileID)
                    SetItemButtonCount(button, containerInfo.stackCount)

                    local itemQuality = containerInfo.quality
                    if SetItemButtonQuality then
                        SetItemButtonQuality(button, itemQuality, containerInfo.hyperlink)
                    end

                    if itemQuality and itemQuality == 0 then
                        SetItemButtonDesaturated(button, true)
                        button.junkCoin:Show()
                    else
                        SetItemButtonDesaturated(button, false)
                        button.junkCoin:Hide()
                    end

                    local start, duration = GetContainerItemCooldown(bag, slot)
                    if start > 0 and duration > 0 then
                        button.Cooldown:SetCooldown(start, duration)
                        button.Cooldown:Show()
                    else
                        button.Cooldown:Hide()
                    end
                else
                    SetItemButtonTexture(button, nil)
                    SetItemButtonCount(button, 0)
                    SetItemButtonDesaturated(button, false)
                    if SetItemButtonQuality then
                        SetItemButtonQuality(button, nil)
                    end
                    button.Cooldown:Hide()
                    button.junkCoin:Hide()
                end
            end
        end
    end

    ScarletUI:BagItemLevel()
    ApplyBankSearchFilter()
end

local function UpdateBankBagSlots()
    if not GetNumBankSlots then return end

    local numPurchased = GetNumBankSlots()
    for i = 1, NUM_BANKBAGSLOTS do
        local button = bankBagButtons[i]
        if button then
            local invSlotID = BankButtonIDToInvSlotID(i, 1)
            local textureName = GetInventoryItemTexture("player", invSlotID)

            if i <= numPurchased then
                -- Purchased slot
                if textureName then
                    -- Has a bag equipped
                    button.icon:SetTexture(textureName)
                else
                    -- Empty purchased slot
                    button.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                end
                button.icon:SetVertexColor(1, 1, 1)
            else
                -- Unpurchased slot
                button.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                button.icon:SetVertexColor(1, 0.1, 0.1)
            end
        end
    end
end

local function CustomSortBank()
    -- Group bank containers by bag type
    local bagGroups = {}
    local groupOrder = {}

    -- Main bank container is always normal type
    local mainBankType = 0
    if GetContainerNumSlots(BANK_CONTAINER) > 0 then
        bagGroups[mainBankType] = { BANK_CONTAINER }
        table.insert(groupOrder, mainBankType)
    end

    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        if GetContainerNumSlots(bag) > 0 then
            local bagType = GetBagType(bag)
            if not bagGroups[bagType] then
                bagGroups[bagType] = {}
                if bagType ~= mainBankType then
                    table.insert(groupOrder, bagType)
                end
            end
            table.insert(bagGroups[bagType], bag)
        end
    end
    table.sort(groupOrder)

    local function FindBankMergeInBags(bags)
        local partials = {}
        for _, bag in ipairs(bags) do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, _, _, _, _, _, maxStack = GetItemInfo(link)
                    local info = GetContainerItemInfo(bag, slot)
                    local itemID = info and info.itemID or 0
                    local count = info and info.stackCount or 1
                    maxStack = maxStack or 1
                    if maxStack > 1 and count < maxStack then
                        if not partials[itemID] then partials[itemID] = {} end
                        table.insert(partials[itemID], { bag = bag, slot = slot, count = count })
                    end
                end
            end
        end

        for _, slots in pairs(partials) do
            if #slots >= 2 then
                table.sort(slots, function(a, b) return a.count > b.count end)
                local dst = slots[1]
                local src = slots[#slots]
                local move = {
                    source = { bag = src.bag, slot = src.slot },
                    target = { bag = dst.bag, slot = dst.slot },
                }
                PickupContainerItem(src.bag, src.slot)
                PickupContainerItem(dst.bag, dst.slot)
                if CursorHasItem() then ClearCursor() end
                return true, move
            end
        end
        return false
    end

    local function ScanAndSortBankBags(bags)
        local allSlots = {}
        local items = {}

        for _, bag in ipairs(bags) do
            for slot = 1, GetContainerNumSlots(bag) do
                table.insert(allSlots, { bag = bag, slot = slot })
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local name, _, quality, _, _, itemType, subType = GetItemInfo(link)
                    if name then
                        local containerInfo = GetContainerItemInfo(bag, slot)
                        local stackCount = containerInfo and containerInfo.stackCount or 1
                        local itemID = containerInfo and containerInfo.itemID or 0
                        table.insert(items, {
                            bag = bag, slot = slot,
                            key = bag .. ":" .. slot,
                            name = name, quality = quality or 0,
                            itemType = itemType or "", subType = subType or "",
                            stackCount = stackCount, itemID = itemID,
                        })
                    end
                end
            end
        end

        table.sort(items, function(a, b)
            if a.quality ~= b.quality then return a.quality > b.quality end
            if a.itemType ~= b.itemType then return a.itemType < b.itemType end
            if a.subType ~= b.subType then return a.subType < b.subType end
            if a.name ~= b.name then return a.name < b.name end
            if a.stackCount ~= b.stackCount then return a.stackCount > b.stackCount end
            if a.itemID ~= b.itemID then return a.itemID < b.itemID end
            if a.bag ~= b.bag then return a.bag < b.bag end
            return a.slot < b.slot
        end)

        return allSlots, items
    end

    bankSortFrame = bankSortFrame or CreateFrame("Frame")
    local sortFrame = bankSortFrame
    sortFrame:SetScript("OnUpdate", nil)
    local ticker = 0
    local passes = 0
    local phase = "merge"
    local groupIndex = 1
    local sortMoves
    local moveIndex = 1
    local pendingMove

    sortFrame:SetScript("OnUpdate", function(self, dt)
        ticker = ticker + dt

        if CursorHasItem() then
            ClearCursor()
            return
        end

        if IsSortMoveLocked(pendingMove) then
            return
        end
        pendingMove = nil

        if ticker < sortMoveDelay then return end
        ticker = 0

        passes = passes + 1
        if passes > 200 then
            self:SetScript("OnUpdate", nil)
            UpdateBank()
            return
        end

        if groupIndex > #groupOrder then
            self:SetScript("OnUpdate", nil)
            UpdateBank()
            return
        end

        local currentBags = bagGroups[groupOrder[groupIndex]]

        if phase == "merge" then
            local merged, mergeMove = FindBankMergeInBags(currentBags)
            if merged then
                pendingMove = mergeMove
            else
                phase = "sort"
                sortMoves = nil
                moveIndex = 1
            end
            return
        end

        if not sortMoves then
            local allSlots, items = ScanAndSortBankBags(currentBags)
            sortMoves = BuildFinalSortMoves(allSlots, items)
            moveIndex = 1
        end

        local move = sortMoves[moveIndex]
        if move then
            PickupContainerItem(move.source.bag, move.source.slot)
            PickupContainerItem(move.target.bag, move.target.slot)
            if CursorHasItem() then ClearCursor() end
            pendingMove = move
            moveIndex = moveIndex + 1
        else
            local allSlots, items = ScanAndSortBankBags(currentBags)
            local validationMoves = BuildFinalSortMoves(allSlots, items)
            if #validationMoves > 0 then
                sortMoves = validationMoves
                moveIndex = 1
            else
                groupIndex = groupIndex + 1
                phase = "merge"
                sortMoves = nil
                moveIndex = 1
                pendingMove = nil
            end
        end
    end)
end

function ScarletUI:SetupBags()
    local bagModule = self.db.global.bagModule
    if not bagModule.enabled or self.lightWeightMode then
        return
    end

    local borderPadding = 10
    local currencyFooterHeight = 20

    -- Only create the frame once; subsequent calls just rebuild contents
    if not self.bagFrame then
        -- Calculate initial size
        local totalSlots = 0
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            totalSlots = totalSlots + GetContainerNumSlots(bag)
        end
        local numRows = math.ceil(totalSlots / bagModule.slotsPerRow)
        local bagFrameWidth = (bagModule.slotSize + bagModule.slotSpacing) * bagModule.slotsPerRow - bagModule.slotSpacing + borderPadding * 2
        local slotGridHeight = (bagModule.slotSize + bagModule.slotSpacing) * numRows - bagModule.slotSpacing
        local bagFrameHeight = slotGridHeight + borderPadding * 2 + currencyFooterHeight + 10 + headerHeight + 5

        -- Create the bag frame
        self.bagFrame = CreateFrame("Frame", "ScarletUI_BagFrame", UIParent, "BackdropTemplate")
        self.bagFrame:Hide()
        self.bagFrame:SetSize(bagFrameWidth, bagFrameHeight)
        self.bagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -1, 40)
        self.bagFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.bagFrame:SetBackdropColor(0, 0, 0, bagModule.bagAlpha)
        self.bagFrame:SetFrameStrata("HIGH")

        self.bagFrame:EnableMouse(true)
        self.bagFrame:SetMovable(true)
        self.bagFrame:RegisterForDrag("LeftButton")
        self.bagFrame:SetScript("OnDragStart", function(f)
            if not ScarletUI.db.global.bagModule.bagLocked then f:StartMoving() end
        end)
        self.bagFrame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

        tinsert(UISpecialFrames, "ScarletUI_BagFrame")

        self.bagFrame:SetScript("OnShow", function()
            PlaySound(117)
        end)

        self.bagFrame:SetScript("OnHide", function()
            PlaySound(617)
        end)
        bagStateResetFrame = bagStateResetFrame or CreateFrame("Frame")
        bagBindingFrame = bagBindingFrame or CreateFrame("Frame")
        bagBindingFrame:RegisterEvent("UPDATE_BINDINGS")
        bagBindingFrame:SetScript("OnEvent", ApplyBagKeybindOverrides)
        ApplyBagKeybindOverrides()

        -- Create header bar with bag toggles, search, and sort button
        local headerFrame = CreateFrame("Frame", nil, self.bagFrame)
        headerFrame:SetSize(bagFrameWidth - borderPadding * 2, headerHeight)
        headerFrame:SetPoint("TOPLEFT", self.bagFrame, "TOPLEFT", borderPadding, -borderPadding)
        self.bagFrame.headerFrame = headerFrame

        -- Create bag icon toggle buttons (one per bag slot, always present)
        local bagToggleButtons = {}
        local prevToggle = nil
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local toggle = CreateFrame("Button", nil, headerFrame)
            toggle:SetSize(20, 20)
            if prevToggle then
                toggle:SetPoint("LEFT", prevToggle, "RIGHT", 4, 0)
            else
                toggle:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
            end

            toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
            toggle.icon:SetAllPoints()
            toggle.bag = bag
            toggle:SetScript("OnClick", function(self)
                if hiddenBags[self.bag] then
                    hiddenBags[self.bag] = nil
                    self.icon:SetDesaturated(false)
                else
                    hiddenBags[self.bag] = true
                    self.icon:SetDesaturated(true)
                end
                RebuildSlotLayout()
            end)

            bagToggleButtons[bag] = toggle
            prevToggle = toggle
        end
        -- Keyring toggle button (only exists in Classic versions)
        if KEYRING_CONTAINER then
            -- Initialize hidden state from saved setting (default hidden)
            if bagModule.hideKeyring then
                hiddenBags[KEYRING_CONTAINER] = true
            end

            local toggle = CreateFrame("Button", nil, headerFrame)
            toggle:SetSize(20, 20)
            if prevToggle then
                toggle:SetPoint("LEFT", prevToggle, "RIGHT", 4, 0)
            else
                toggle:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
            end
            toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
            toggle.icon:SetAllPoints()
            toggle.icon:SetTexture("Interface\\ContainerFrame\\KeyRing-Bag-Icon")
            toggle.icon:SetDesaturated(bagModule.hideKeyring)
            toggle.bag = KEYRING_CONTAINER
            toggle:SetScript("OnClick", function(self)
                if hiddenBags[self.bag] then
                    hiddenBags[self.bag] = nil
                    self.icon:SetDesaturated(false)
                    ScarletUI.db.global.bagModule.hideKeyring = false
                else
                    hiddenBags[self.bag] = true
                    self.icon:SetDesaturated(true)
                    ScarletUI.db.global.bagModule.hideKeyring = true
                end
                RebuildSlotLayout()
            end)
            bagToggleButtons[KEYRING_CONTAINER] = toggle
            prevToggle = toggle
        end

        self.bagFrame.bagToggleButtons = bagToggleButtons

        -- Create sort button (left of search bar, after bag toggles)
        local sortButton = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
        sortButton:SetSize(40, 22)
        if prevToggle then
            sortButton:SetPoint("LEFT", prevToggle, "RIGHT", 10, 0)
        else
            sortButton:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        end
        sortButton:SetText("Sort")
        sortButton:SetScript("OnClick", function()
            CustomSortBags()
        end)

        -- Create search bar (right of sort button, fills remaining space)
        local searchBox = CreateFrame("EditBox", nil, headerFrame, "InputBoxTemplate")
        searchBox:SetSize(100, 20)
        searchBox:SetAutoFocus(false)
        searchBox:SetPoint("LEFT", sortButton, "RIGHT", 10, 0)
        searchBox:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)

        local clearButton = CreateFrame("Button", nil, searchBox)
        clearButton:SetSize(14, 14)
        clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
        clearButton:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        clearButton:GetNormalTexture():SetVertexColor(1, 0.2, 0.2)
        clearButton:Hide()
        clearButton:SetScript("OnClick", function()
            searchBox:SetText("")
            searchBox:ClearFocus()
        end)

        searchBox:SetScript("OnTextChanged", function(self)
            searchText = self:GetText()
            ApplySearchFilter()
            clearButton:SetShown(searchText ~= "")
        end)
        searchBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        searchBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
            ScarletUI_BagFrame:Hide()
        end)

        -- Create per-bag wrapper frames (persistent, reused across rebuilds)
        local bagWrappers = {}
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local wrapper = CreateFrame("Frame", nil, self.bagFrame)
            wrapper:SetID(bag)
            wrapper:SetAllPoints(self.bagFrame)
            wrapper:Show()
            bagWrappers[bag] = wrapper
        end
        if KEYRING_CONTAINER then
            local wrapper = CreateFrame("Frame", nil, self.bagFrame)
            wrapper:SetID(KEYRING_CONTAINER)
            wrapper:SetAllPoints(self.bagFrame)
            wrapper:Show()
            bagWrappers[KEYRING_CONTAINER] = wrapper
        end
        self.bagFrame.bagWrappers = bagWrappers

        -- Create currency footer
        self.bagFrame.currencyFooter = CreateFrame("Frame", nil, self.bagFrame, "BackdropTemplate")
        self.bagFrame.currencyFooter:SetSize(bagFrameWidth - borderPadding * 2, currencyFooterHeight)
        self.bagFrame.currencyFooter:SetPoint("BOTTOM", self.bagFrame, "BOTTOM", 0, borderPadding)
        self.bagFrame.currencyFooter:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        self.bagFrame.currencyFooter:RegisterEvent("BAG_UPDATE_COOLDOWN")

        self.bagFrame.currencyFooter.currencies = {}
        for i = 1, 3 do
            local fs = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
            fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            local iconTexture = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
            iconTexture:SetSize(16, 16)
            fs.iconTexture = iconTexture
            self.bagFrame.currencyFooter.currencies[i] = fs
        end

        local cooldownFunction = function()
            local cooldownBags = { BACKPACK_CONTAINER }
            for bag = 1, NUM_BAG_SLOTS do
                table.insert(cooldownBags, bag)
            end
            if KEYRING_CONTAINER then
                table.insert(cooldownBags, KEYRING_CONTAINER)
            end
            for _, bag in ipairs(cooldownBags) do
                for slot = 1, GetContainerNumSlots(bag) do
                    local index = bag * 100 + slot
                    local button = bagSlots[index]
                    if button then
                        local start, duration = GetContainerItemCooldown(bag, slot)
                        if start > 0 and duration > 0 then
                            button.Cooldown:SetCooldown(start, duration)
                            button.Cooldown:Show()
                        else
                            button.Cooldown:Hide()
                        end
                    end
                end
            end
        end

        updateCurrencyDisplay()
        hooksecurefunc("SetCurrencyBackpack", updateCurrencyDisplay)
        self.bagFrame.currencyFooter:RegisterEvent("PLAYER_MONEY")
        self.bagFrame.currencyFooter:SetScript("OnEvent", function(_, event)
            if event == "CURRENCY_DISPLAY_UPDATE" then
                updateCurrencyDisplay()
            elseif event == "BAG_UPDATE_COOLDOWN" then
                cooldownFunction()
            elseif event == "PLAYER_MONEY" then
                UpdateCurrencyFooter()
            end
        end)

        cooldownFunction()

        self.bagFrame.currencyFooter.bronzeText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
        self.bagFrame.currencyFooter.bronzeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        self.bagFrame.currencyFooter.bronzeText:SetPoint("RIGHT", self.bagFrame.currencyFooter, "RIGHT", -16, 0)

        self.bagFrame.currencyFooter.bronzeIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
        self.bagFrame.currencyFooter.bronzeIcon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon")
        self.bagFrame.currencyFooter.bronzeIcon:SetSize(16, 16)
        self.bagFrame.currencyFooter.bronzeIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.bronzeText, "RIGHT", 1, 0)

        self.bagFrame.currencyFooter.silverText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
        self.bagFrame.currencyFooter.silverText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        self.bagFrame.currencyFooter.silverText:SetPoint("RIGHT", self.bagFrame.currencyFooter.bronzeText, "LEFT", -20, 0)

        self.bagFrame.currencyFooter.silverIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
        self.bagFrame.currencyFooter.silverIcon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon")
        self.bagFrame.currencyFooter.silverIcon:SetSize(16, 16)
        self.bagFrame.currencyFooter.silverIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.silverText, "RIGHT", 1, 0)

        self.bagFrame.currencyFooter.goldText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
        self.bagFrame.currencyFooter.goldText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        self.bagFrame.currencyFooter.goldText:SetPoint("RIGHT", self.bagFrame.currencyFooter.silverText, "LEFT", -20, 0)

        self.bagFrame.currencyFooter.goldIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
        self.bagFrame.currencyFooter.goldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        self.bagFrame.currencyFooter.goldIcon:SetSize(16, 16)
        self.bagFrame.currencyFooter.goldIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.goldText, "RIGHT", 1, 0)

        -- Override PutItemInBag to detect bag equips (must be pre-hook; no hooksecurefunc alternative)
        PutItemInBag = function(slot)
            if CursorHasItem() then
                bagEquipInProgress = true
            end
            origPutItemInBag(slot)
        end

        -- Suppress default container frames so only the custom bag UI shows
        for i = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame" .. i]
            if frame then
                frame:HookScript("OnShow", function(f) f:Hide() end)
            end
        end

        -- Hook bag functions to drive the custom frame (preserves secure status of originals)
        hooksecurefunc("OpenAllBags", ShowBagFrame)
        hooksecurefunc("CloseAllBags", HideBagFrame)
        hooksecurefunc("ToggleAllBags", ToggleBagFrameIfUnhandled)
        hooksecurefunc("OpenBackpack", ShowBagFrame)
        hooksecurefunc("CloseBackpack", HideBagFrame)
        hooksecurefunc("ToggleBackpack", ToggleBagFrameIfUnhandled)
        hooksecurefunc("OpenBag", function(bagID)
            if IsPlayerBag(bagID) then
                ShowBagFrame()
            end
        end)
        hooksecurefunc("CloseBag", function(bagID)
            if IsPlayerBag(bagID) then
                HideBagFrame()
            end
        end)
        hooksecurefunc("ToggleBag", function(bagID)
            if bagEquipInProgress then
                bagEquipInProgress = false
                return
            end
            if IsPlayerBag(bagID) then
                ToggleBagFrameIfUnhandled()
            end
        end)
        if ToggleKeyRing then
            hooksecurefunc("ToggleKeyRing", ToggleBagFrameIfUnhandled)
        end
    end

    -- === Rebuild bag contents (runs on init and on bag swap) ===

    -- Return old slot buttons to pool
    for _, button in ipairs(orderedSlots) do
        button:Hide()
        button:EnableMouse(false)
        table.insert(bagButtonPool, button)
    end
    wipe(bagSlots)
    wipe(orderedSlots)

    -- Track per-bag slot counts for detecting bag swaps
    wipe(lastBagCounts)
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        lastBagCounts[bag] = GetContainerNumSlots(bag)
    end
    if KEYRING_CONTAINER then
        lastBagCounts[KEYRING_CONTAINER] = GetContainerNumSlots(KEYRING_CONTAINER)
    end

    -- Update header toggle button icons and visibility
    local bagToggleButtons = self.bagFrame.bagToggleButtons
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local toggle = bagToggleButtons[bag]
        if toggle then
            local numSlots = GetContainerNumSlots(bag)
            if numSlots > 0 then
                if bag == BACKPACK_CONTAINER then
                    toggle.icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
                else
                    toggle.icon:SetTexture(GetInventoryItemTexture("player", ContainerIDToInventoryID(bag)))
                end
                toggle:Show()
            else
                toggle:Hide()
            end
        end
    end
    if KEYRING_CONTAINER then
        local toggle = bagToggleButtons[KEYRING_CONTAINER]
        if toggle then
            if GetContainerNumSlots(KEYRING_CONTAINER) > 0 then
                toggle:Show()
            else
                toggle:Hide()
            end
        end
    end

    -- Create slot buttons
    local startX = borderPadding
    local startY = -borderPadding - headerHeight - 5
    local bagWrappers = self.bagFrame.bagWrappers

    -- Helper to get or create a bag slot button
    local function GetOrCreateBagButton(bag, slot, parentWrapper)
        local button = table.remove(bagButtonPool)
        if button then
            -- Reuse pooled button
            button:SetParent(parentWrapper)
            button.bag = bag
            button.slot = slot
            button:SetID(slot)
            ResizeSlotButton(button, bagModule.slotSize)
            button:EnableMouse(true)

            -- Reset border color for normal bags
            local nt = button:GetNormalTexture()
            if nt then nt:SetVertexColor(1, 1, 1) end

            -- Clear item visuals
            SetItemButtonTexture(button, nil)
            SetItemButtonCount(button, 0)
            SetItemButtonDesaturated(button, false)
            if SetItemButtonQuality then
                SetItemButtonQuality(button, nil)
            end
            button.Cooldown:Hide()
            button.junkCoin:Hide()
        else
            -- Create new button
            button = CreateFrame("ItemButton", "ScarletUI_Bag" .. bag .. "Slot" .. slot, parentWrapper, "ContainerFrameItemButtonTemplate")
            button.bag = bag
            button.slot = slot
            button:SetID(slot)
            ResizeSlotButton(button, bagModule.slotSize)

            if not button.Cooldown then
                button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
                button.Cooldown:SetAllPoints()
                button.Cooldown:Hide()
            end

            button.junkCoin = button:CreateTexture(nil, "OVERLAY")
            button.junkCoin:SetSize(14, 14)
            button.junkCoin:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            button.junkCoin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
            button.junkCoin:Hide()
        end

        button:Show()

        if button.NewItemTexture then button.NewItemTexture:Hide() end
        if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide() end
        if button.flash then button.flash:Hide() end
        if button.flashAnim then button.flashAnim:Stop() end
        if button.newitemglowAnim then button.newitemglowAnim:Stop() end
        button:SetScript("OnUpdate", nil)

        -- Guard HookScript to prevent stacking
        if not button.scarletPostClickHooked then
            button:HookScript("PostClick", function()
                UpdateBag()
            end)
            button.scarletPostClickHooked = true
        end

        return button
    end

    totalSlots = 0
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            totalSlots = totalSlots + 1

            local button = GetOrCreateBagButton(bag, slot, bagWrappers[bag])

            -- Color-code specialty bag borders
            local bagType = GetBagType(bag)
            if bagType ~= 0 and bagTypeColors[bagType] then
                local r, g, b = unpack(bagTypeColors[bagType])
                local nt = button:GetNormalTexture()
                if nt then nt:SetVertexColor(r, g, b) end
            end

            local distance = bagModule.slotSize + bagModule.slotSpacing
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.bagFrame, "TOPLEFT", startX + ((totalSlots - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((totalSlots - 1) / bagModule.slotsPerRow) * -distance)

            bagSlots[bag * 100 + slot] = button
            orderedSlots[#orderedSlots + 1] = button

            local function SetBagTooltip(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
                GameTooltip:SetBagItem(btn.bag, btn.slot)
                GameTooltip:Show()
            end

            button.UpdateTooltip = SetBagTooltip
            button:SetScript("OnEnter", function(self)
                self.scarletTooltipElapsed = 0
                if ContainerFrameItemButton_OnEnter then
                    ContainerFrameItemButton_OnEnter(self)
                else
                    self:UpdateTooltip()
                end
                UpdateBagCursor(self)
                self:SetScript("OnUpdate", RefreshHoveredTooltip)
            end)

            button:SetScript("OnLeave", function(self)
                self:SetScript("OnUpdate", nil)
                ResetBagCursor()
                HideTooltipIfOwned(self)
            end)
        end
    end

    -- Create keyring slots
    if KEYRING_CONTAINER then
        local keyBag = KEYRING_CONTAINER
        for slot = 1, GetContainerNumSlots(keyBag) do
            totalSlots = totalSlots + 1

            local button = GetOrCreateBagButton(keyBag, slot, bagWrappers[keyBag])

            -- Color-code keyring borders
            local color = bagTypeColors[256]
            if color then
                local nt = button:GetNormalTexture()
                if nt then nt:SetVertexColor(unpack(color)) end
            end

            local distance = bagModule.slotSize + bagModule.slotSpacing
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.bagFrame, "TOPLEFT", startX + ((totalSlots - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((totalSlots - 1) / bagModule.slotsPerRow) * -distance)

            bagSlots[keyBag * 100 + slot] = button
            orderedSlots[#orderedSlots + 1] = button

            local function SetKeyTooltip(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
                local link = GetContainerItemLink(btn.bag, btn.slot)
                if link then
                    GameTooltip:SetHyperlink(link)
                end
                GameTooltip:Show()
            end

            button.UpdateTooltip = SetKeyTooltip

            button:SetScript("OnEnter", function(self)
                self.scarletTooltipElapsed = 0
                if ContainerFrameItemButton_OnEnter then
                    ContainerFrameItemButton_OnEnter(self)
                else
                    self:UpdateTooltip()
                end
                UpdateBagCursor(self)
                self:SetScript("OnUpdate", RefreshHoveredTooltip)
            end)

            button:SetScript("OnLeave", function(self)
                self:SetScript("OnUpdate", nil)
                ResetBagCursor()
                HideTooltipIfOwned(self)
            end)
        end
    end

    -- Store the bagSlots table in the addon object
    self.bagSlots = bagSlots

    -- Resize the frame to fit current contents
    RebuildSlotLayout()

    -- Register bag events (only hook once)
    if not self.bagEventHooked then
        local function CheckBagSlotCountChanged()
            for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
                if GetContainerNumSlots(bag) ~= (lastBagCounts[bag] or 0) then
                    return true
                end
            end
            if KEYRING_CONTAINER then
                if GetContainerNumSlots(KEYRING_CONTAINER) ~= (lastBagCounts[KEYRING_CONTAINER] or 0) then
                    return true
                end
            end
            return false
        end

        self:RegisterEventHandler("BAG_UPDATE", function()
            bagEquipInProgress = false
            if CheckBagSlotCountChanged() then
                ScarletUI:SetupBags()
            else
                UpdateBag()
            end
        end)

        -- BAG_UPDATE_DELAYED fires after all pending bag updates are resolved,
        -- guaranteeing GetContainerNumSlots returns the new counts (e.g. after
        -- equipping/unequipping a bag where BAG_UPDATE may fire too early).
        self:RegisterEventHandler("BAG_UPDATE_DELAYED", function()
            if CheckBagSlotCountChanged() then
                ScarletUI:SetupBags()
            end
        end)

        self.bagEventHooked = true
    end

    -- Update the bag contents
    UpdateBag()
end

function ScarletUI:SetupBank()
    local bagModule = self.db.global.bagModule
    if not bagModule.enabled or self.lightWeightMode then
        return
    end

    -- Suppress the default bank frame so only the SUI bank shows
    if BankFrame and not self.bankFrameSuppressed then
        BankFrame:UnregisterAllEvents()
        BankFrame:SetScript("OnHide", nil)
        BankFrame:HookScript("OnShow", function(f) f:Hide() end)
        BankFrame:Hide()
        BankFrame:EnableMouse(false)
        self.bankFrameSuppressed = true
    end

    local borderPadding = 10

    -- Only create the frame once; subsequent calls just rebuild contents
    if not self.bankFrame then
        -- Calculate initial size
        local totalSlots = GetContainerNumSlots(BANK_CONTAINER)
        for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
            totalSlots = totalSlots + GetContainerNumSlots(bag)
        end

        local numRows = math.ceil(math.max(totalSlots, 1) / bagModule.slotsPerRow)
        local bankFrameWidth = (bagModule.slotSize + bagModule.slotSpacing) * bagModule.slotsPerRow - bagModule.slotSpacing + borderPadding * 2
        local slotGridHeight = (bagModule.slotSize + bagModule.slotSpacing) * numRows - bagModule.slotSpacing
        local bankBagSlotRowHeight = GetNumBankSlots and 33 or 0
        local bankFrameHeight = slotGridHeight + borderPadding * 2 + headerHeight + 5 + bankBagSlotRowHeight

        -- Create bank frame
        self.bankFrame = CreateFrame("Frame", "ScarletUI_BankFrame", UIParent, "BackdropTemplate")
        self.bankFrame:Hide()
        self.bankFrame:SetSize(bankFrameWidth, bankFrameHeight)
        self.bankFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 1, 40)
        self.bankFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        self.bankFrame:SetBackdropColor(0, 0, 0, bagModule.bankAlpha)
        self.bankFrame:SetFrameStrata("HIGH")
        self.bankFrame:EnableMouse(true)
        self.bankFrame:SetMovable(true)
        self.bankFrame:RegisterForDrag("LeftButton")
        self.bankFrame:SetScript("OnDragStart", function(f)
            if not ScarletUI.db.global.bagModule.bankLocked then f:StartMoving() end
        end)
        self.bankFrame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

        tinsert(UISpecialFrames, "ScarletUI_BankFrame")

        self.bankFrame:SetScript("OnShow", function()
            PlaySound(117)
        end)

        self.bankFrame:SetScript("OnHide", function()
            PlaySound(617)
            CloseBankFrame()
        end)

        -- Create header bar
        local headerFrame = CreateFrame("Frame", nil, self.bankFrame)
        headerFrame:SetSize(bankFrameWidth - borderPadding * 2, headerHeight)
        headerFrame:SetPoint("TOPLEFT", self.bankFrame, "TOPLEFT", borderPadding, -borderPadding)
        self.bankFrame.headerFrame = headerFrame

        -- Bank container toggle buttons
        local bankToggleButtons = {}
        local prevToggle = nil

        -- Main bank toggle
        local mainToggle = CreateFrame("Button", nil, headerFrame)
        mainToggle:SetSize(20, 20)
        mainToggle:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        mainToggle.icon = mainToggle:CreateTexture(nil, "ARTWORK")
        mainToggle.icon:SetAllPoints()
        mainToggle.icon:SetTexture("Interface\\Icons\\INV_Box_02")
        mainToggle.bag = BANK_CONTAINER
        mainToggle:SetScript("OnClick", function(self)
            if hiddenBankBags[self.bag] then
                hiddenBankBags[self.bag] = nil
                self.icon:SetDesaturated(false)
            else
                hiddenBankBags[self.bag] = true
                self.icon:SetDesaturated(true)
            end
            RebuildBankSlotLayout()
        end)
        bankToggleButtons[BANK_CONTAINER] = mainToggle
        self.bankFrame.mainToggle = mainToggle
        prevToggle = mainToggle

        -- Bank bag toggles
        for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
            local numSlots = GetContainerNumSlots(bag)
            if numSlots > 0 then
                local toggle = CreateFrame("Button", nil, headerFrame)
                toggle:SetSize(20, 20)
                toggle:SetPoint("LEFT", prevToggle, "RIGHT", 4, 0)

                local icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
                toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
                toggle.icon:SetAllPoints()
                toggle.icon:SetTexture(icon)

                toggle.bag = bag
                toggle:SetScript("OnClick", function(self)
                    if hiddenBankBags[self.bag] then
                        hiddenBankBags[self.bag] = nil
                        self.icon:SetDesaturated(false)
                    else
                        hiddenBankBags[self.bag] = true
                        self.icon:SetDesaturated(true)
                    end
                    RebuildBankSlotLayout()
                end)

                bankToggleButtons[bag] = toggle
                prevToggle = toggle
            end
        end

        self.bankFrame.bankToggleButtons = bankToggleButtons

        -- Sort button (left of search bar, after bank toggles)
        local sortButton = CreateFrame("Button", "ScarletUI_BankSortButton", headerFrame, "UIPanelButtonTemplate")
        sortButton:SetSize(40, 22)
        if prevToggle then
            sortButton:SetPoint("LEFT", prevToggle, "RIGHT", 10, 0)
        else
            sortButton:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
        end
        sortButton:SetText("Sort")
        sortButton:SetScript("OnClick", function()
            CustomSortBank()
        end)
        self.bankFrame.sortButton = sortButton

        -- Search bar (right of sort button, fills remaining space)
        local searchBox = CreateFrame("EditBox", "ScarletUI_BankSearchBox", headerFrame, "InputBoxTemplate")
        searchBox:SetSize(100, 20)
        searchBox:SetAutoFocus(false)
        searchBox:SetPoint("LEFT", sortButton, "RIGHT", 10, 0)
        searchBox:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)

        local clearButton = CreateFrame("Button", nil, searchBox)
        clearButton:SetSize(14, 14)
        clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
        clearButton:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        clearButton:GetNormalTexture():SetVertexColor(1, 0.2, 0.2)
        clearButton:Hide()
        clearButton:SetScript("OnClick", function()
            searchBox:SetText("")
            searchBox:ClearFocus()
        end)

        searchBox:SetScript("OnTextChanged", function(self)
            bankSearchText = self:GetText()
            ApplyBankSearchFilter()
            clearButton:SetShown(bankSearchText ~= "")
        end)
        searchBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        searchBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
            ScarletUI_BankFrame:Hide()
        end)
        self.bankFrame.searchBox = searchBox

        -- Create bank bag slot row (non-retail only)
        if GetNumBankSlots then
            local bagSlotRow = CreateFrame("Frame", nil, self.bankFrame)
            bagSlotRow:SetSize(NUM_BANKBAGSLOTS * 32, 28)
            bagSlotRow:SetPoint("BOTTOMLEFT", self.bankFrame, "BOTTOMLEFT", borderPadding, borderPadding)
            self.bankFrame.bagSlotRow = bagSlotRow

            for i = 1, NUM_BANKBAGSLOTS do
                local btn = CreateFrame("Button", "ScarletUI_BankBagSlot" .. i, bagSlotRow)
                btn:SetSize(28, 28)
                btn:SetPoint("LEFT", bagSlotRow, "LEFT", (i - 1) * 32, 0)
                btn.bagIndex = i

                btn.icon = btn:CreateTexture(nil, "ARTWORK")
                btn.icon:SetAllPoints()
                btn.icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")

                local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                highlight:SetAllPoints()
                highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                highlight:SetBlendMode("ADD")

                btn:SetScript("OnClick", function()
                    local numPurchased = GetNumBankSlots()
                    local invSlotID = BankButtonIDToInvSlotID(i, 1)

                    if i > numPurchased then
                        if i == numPurchased + 1 then
                            local cost = GetBankSlotCost(numPurchased + 1)
                            StaticPopup_Show("SCARLET_PURCHASE_BANK_SLOT", GetCoinTextureString(cost))
                        end
                    else
                        if CursorHasItem() then
                            PutItemInBag(invSlotID)
                        else
                            PickupBagFromSlot(invSlotID)
                        end
                    end
                end)

                btn:SetScript("OnDragStart", function()
                    local numPurchased = GetNumBankSlots()
                    if i <= numPurchased then
                        local invSlotID = BankButtonIDToInvSlotID(i, 1)
                        PickupBagFromSlot(invSlotID)
                    end
                end)
                btn:RegisterForDrag("LeftButton")

                btn:SetScript("OnReceiveDrag", function()
                    local numPurchased = GetNumBankSlots()
                    if i <= numPurchased then
                        local invSlotID = BankButtonIDToInvSlotID(i, 1)
                        PutItemInBag(invSlotID)
                    end
                end)

                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local numPurchased = GetNumBankSlots()
                    local invSlotID = BankButtonIDToInvSlotID(i, 1)

                    if i <= numPurchased then
                        local textureName = GetInventoryItemTexture("player", invSlotID)
                        if textureName then
                            GameTooltip:SetInventoryItem("player", invSlotID)
                        else
                            GameTooltip:SetText("Empty Bank Bag Slot")
                        end
                    elseif i == numPurchased + 1 then
                        local cost = GetBankSlotCost(numPurchased + 1)
                        GameTooltip:SetText("Purchase Bank Bag Slot")
                        GameTooltip:AddLine("Cost: " .. GetCoinTextureString(cost), 1, 1, 1)
                    else
                        GameTooltip:SetText("Bank Bag Slot (Locked)")
                    end
                    GameTooltip:Show()
                end)

                btn:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                bankBagButtons[i] = btn
            end
        end

        -- Per-bag wrapper frames for ContainerFrameItemButtonTemplate
        local bankWrappers = {}

        -- Main bank wrapper
        local mainWrapper = CreateFrame("Frame", "ScarletUI_BankWrapper_Main", self.bankFrame)
        mainWrapper:SetID(BANK_CONTAINER)
        mainWrapper:SetAllPoints(self.bankFrame)
        mainWrapper:Show()
        bankWrappers[BANK_CONTAINER] = mainWrapper

        -- Bank bag wrappers
        for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
            local wrapper = CreateFrame("Frame", "ScarletUI_BankWrapper" .. bag, self.bankFrame)
            wrapper:SetID(bag)
            wrapper:SetAllPoints(self.bankFrame)
            wrapper:Show()
            bankWrappers[bag] = wrapper
        end
        self.bankFrame.bankWrappers = bankWrappers

        -- Event frame for bank events
        self.bankEventFrame = CreateFrame("Frame")
        self.bankEventFrame:RegisterEvent("BANKFRAME_OPENED")
        self.bankEventFrame:RegisterEvent("BANKFRAME_CLOSED")
        self.bankEventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
        self.bankEventFrame:RegisterEvent("BAG_UPDATE")
        self.bankEventFrame:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
        self.bankEventFrame:SetScript("OnEvent", function(_, event)
            if event == "BANKFRAME_OPENED" then
                ScarletUI:SetupBank()
                ScarletUI_BankFrame:Show()
                OpenAllBags()
                UpdateBank()
                UpdateBankBagSlots()
                RebuildBankSlotLayout()
            elseif event == "BANKFRAME_CLOSED" then
                ScarletUI_BankFrame:Hide()
                CloseAllBags()
            elseif event == "PLAYERBANKSLOTS_CHANGED" then
                if ScarletUI_BankFrame:IsShown() then
                    UpdateBank()
                end
            elseif event == "BAG_UPDATE" then
                if ScarletUI_BankFrame:IsShown() then
                    local changed = false
                    if GetContainerNumSlots(BANK_CONTAINER) ~= (lastBankBagCounts[BANK_CONTAINER] or 0) then
                        changed = true
                    end
                    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
                        if GetContainerNumSlots(bag) ~= (lastBankBagCounts[bag] or 0) then
                            changed = true
                            break
                        end
                    end
                    if changed then
                        ScarletUI:SetupBank()
                        UpdateBank()
                        UpdateBankBagSlots()
                        RebuildBankSlotLayout()
                    else
                        UpdateBank()
                    end
                end
            elseif event == "PLAYERBANKBAGSLOTS_CHANGED" then
                if ScarletUI_BankFrame:IsShown() then
                    ScarletUI:SetupBank()
                    UpdateBank()
                    UpdateBankBagSlots()
                    RebuildBankSlotLayout()
                end
            end
        end)
    end

    -- === Rebuild bank contents (runs on init and on bank open/bag swap) ===

    local bankWrappers = self.bankFrame.bankWrappers
    local headerFrame = self.bankFrame.headerFrame
    local bankToggleButtons = self.bankFrame.bankToggleButtons
    local mainToggle = self.bankFrame.mainToggle
    local sortButton = self.bankFrame.sortButton
    local searchBox = self.bankFrame.searchBox
    local startX = borderPadding
    local startY = -borderPadding - headerHeight - 5

    -- Return old slot buttons to pool
    for _, button in ipairs(orderedBankSlots) do
        button:Hide()
        button:EnableMouse(false)
        table.insert(bankButtonPool, button)
    end
    wipe(bankSlots)
    wipe(orderedBankSlots)

    -- Helper to get or create a bank slot button
    local function CreateBankSlotButton(bag, slot, slotIndex)
        local button = table.remove(bankButtonPool)
        if button then
            -- Reuse pooled button
            button:SetParent(bankWrappers[bag])
            button.bag = bag
            button.slot = slot
            button:SetID(slot)
            ResizeSlotButton(button, bagModule.slotSize)
            button:EnableMouse(true)

            -- Reset border color
            local nt = button:GetNormalTexture()
            if nt then nt:SetVertexColor(1, 1, 1) end

            -- Clear item visuals
            SetItemButtonTexture(button, nil)
            SetItemButtonCount(button, 0)
            SetItemButtonDesaturated(button, false)
            if SetItemButtonQuality then
                SetItemButtonQuality(button, nil)
            end
            button.Cooldown:Hide()
            button.junkCoin:Hide()
        else
            -- Create new button
            button = CreateFrame("ItemButton", "ScarletUI_Bank" .. bag .. "Slot" .. slot, bankWrappers[bag], "ContainerFrameItemButtonTemplate")
            button.bag = bag
            button.slot = slot
            button:SetID(slot)
            ResizeSlotButton(button, bagModule.slotSize)

            if not button.Cooldown then
                button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
                button.Cooldown:SetAllPoints()
                button.Cooldown:Hide()
            end

            button.junkCoin = button:CreateTexture(nil, "OVERLAY")
            button.junkCoin:SetSize(14, 14)
            button.junkCoin:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
            button.junkCoin:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
            button.junkCoin:Hide()
        end

        button:Show()

        if button.NewItemTexture then button.NewItemTexture:Hide() end
        if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide() end
        if button.flash then button.flash:Hide() end
        if button.flashAnim then button.flashAnim:Stop() end
        if button.newitemglowAnim then button.newitemglowAnim:Stop() end
        button:SetScript("OnUpdate", nil)

        -- Color-code specialty bag borders
        local bagType = GetBagType(bag)
        if bagType ~= 0 and bagTypeColors[bagType] then
            local r, g, b = unpack(bagTypeColors[bagType])
            local nt = button:GetNormalTexture()
            if nt then nt:SetVertexColor(r, g, b) end
        end

        local distance = bagModule.slotSize + bagModule.slotSpacing
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.bankFrame, "TOPLEFT", startX + ((slotIndex - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((slotIndex - 1) / bagModule.slotsPerRow) * -distance)

        bankSlots[bag * 100 + slot] = button
        orderedBankSlots[#orderedBankSlots + 1] = button

        -- Guard HookScript to prevent stacking
        if not button.scarletPostClickHooked then
            button:HookScript("PostClick", function()
                UpdateBank()
            end)
            button.scarletPostClickHooked = true
        end

        -- Tooltip handler shared by OnEnter and UpdateTooltip (periodic refresh)
        local function SetBankTooltip(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            if bag == BANK_CONTAINER then
                GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(slot))
            else
                GameTooltip:SetBagItem(bag, slot)
            end
            GameTooltip:Show()
        end

        button.UpdateTooltip = SetBankTooltip

        button:SetScript("OnEnter", function(self)
            self.scarletTooltipElapsed = 0
            self:UpdateTooltip()
            self:SetScript("OnUpdate", RefreshHoveredTooltip)
        end)

        button:SetScript("OnLeave", function(self)
            self:SetScript("OnUpdate", nil)
            HideTooltipIfOwned(self)
        end)

        return button
    end

    local slotIndex = 0

    -- Main bank slots
    for slot = 1, GetContainerNumSlots(BANK_CONTAINER) do
        slotIndex = slotIndex + 1
        CreateBankSlotButton(BANK_CONTAINER, slot, slotIndex)
    end

    -- Bank bag slots
    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            slotIndex = slotIndex + 1
            CreateBankSlotButton(bag, slot, slotIndex)
        end
    end

    -- Rebuild bank bag toggle buttons (bags may have been added/removed)
    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        local numSlots = GetContainerNumSlots(bag)
        if bankToggleButtons[bag] then
            if numSlots > 0 then
                local icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
                bankToggleButtons[bag].icon:SetTexture(icon)
                bankToggleButtons[bag]:Show()
            else
                bankToggleButtons[bag]:Hide()
            end
        elseif numSlots > 0 then
            local toggle = CreateFrame("Button", nil, headerFrame)
            toggle:SetSize(20, 20)

            local lastToggle = mainToggle
            for b = NUM_BAG_SLOTS + 1, bag - 1 do
                if bankToggleButtons[b] and bankToggleButtons[b]:IsShown() then
                    lastToggle = bankToggleButtons[b]
                end
            end
            toggle:SetPoint("LEFT", lastToggle, "RIGHT", 4, 0)

            local icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
            toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
            toggle.icon:SetAllPoints()
            toggle.icon:SetTexture(icon)

            toggle.bag = bag
            toggle:SetScript("OnClick", function(self)
                if hiddenBankBags[self.bag] then
                    hiddenBankBags[self.bag] = nil
                    self.icon:SetDesaturated(false)
                else
                    hiddenBankBags[self.bag] = true
                    self.icon:SetDesaturated(true)
                end
                RebuildBankSlotLayout()
            end)

            bankToggleButtons[bag] = toggle
        end
    end

    -- Re-anchor search bar to the last visible toggle
    local lastVisibleToggle = mainToggle
    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        if bankToggleButtons[bag] and bankToggleButtons[bag]:IsShown() then
            lastVisibleToggle = bankToggleButtons[bag]
        end
    end
    sortButton:ClearAllPoints()
    sortButton:SetPoint("LEFT", lastVisibleToggle, "RIGHT", 10, 0)
    searchBox:ClearAllPoints()
    searchBox:SetPoint("LEFT", sortButton, "RIGHT", 10, 0)
    searchBox:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)

    self.bankSlots = bankSlots

    -- Track per-bag slot counts for detecting bag swaps
    wipe(lastBankBagCounts)
    lastBankBagCounts[BANK_CONTAINER] = GetContainerNumSlots(BANK_CONTAINER)
    for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
        lastBankBagCounts[bag] = GetContainerNumSlots(bag)
    end
end
