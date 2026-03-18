local GetContainerNumSlots = C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemLink = C_Container.GetContainerItemLink or GetContainerItemLink
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo

local slots = {
    "Head",
    "Neck",
    "Shoulder",
    "Back",
    "Chest",
    "Wrist",
    "Hands",
    "Waist",
    "Legs",
    "Feet",
    "Finger0",
    "Finger1",
    "Trinket0",
    "Trinket1",
    "MainHand",
    "SecondaryHand",
    "Ranged"
}

local function CreateTextElement(parent, text, color, xOffset, yOffset)
    local fontString = parent:CreateFontString(nil, "OVERLAY")
    fontString:SetFontObject("GameFontNormal")
    fontString:SetText(text)
    fontString:SetTextColor(color.r, color.g, color.b)
    fontString:SetPoint("CENTER", parent, "CENTER", xOffset, yOffset)
    fontString:SetShadowColor(0, 0, 0, 1)
    fontString:SetShadowOffset(1, -1)
    fontString:SetFont(fontString:GetFont(), 12, "OUTLINE")
    return fontString
end

local function UpdateTextElement(fontString, text, color)
    fontString:SetText(text)
    fontString:SetTextColor(color.r, color.g, color.b)
end

local function ItemLevelText(itemLink, itemLocation, itemButton, hide)
    if not hide and itemLink then
        local _, _, itemQuality, itemLevel, _, itemType = GetItemInfo(itemLink)

        if itemLocation then
            itemLevel = C_Item.GetCurrentItemLevel(itemLocation)
        elseif GetDetailedItemLevelInfo then
            itemLevel = GetDetailedItemLevelInfo(itemLink)
        end

        if itemType == 'Armor' or itemType == 'Weapon' then
            if itemQuality and itemLevel then
                if itemButton then
                    local color
                    if ScarletUI.db.global.itemLevelColorOverride then
                        color = ScarletUI.db.global.itemLevelColor
                    else
                        color = ITEM_QUALITY_COLORS[itemQuality]
                    end

                    if itemButton.itemLevel then
                        itemButton.itemLevel:Show()
                        UpdateTextElement(itemButton.itemLevel, itemLevel, color)
                    else
                        itemButton.itemLevel = CreateTextElement(itemButton, itemLevel, color, 0, 0)
                    end
                end
            end
        elseif itemButton and itemButton.itemLevel then
            itemButton.itemLevel:Hide()
        end
    elseif itemButton and itemButton.itemLevel then
        itemButton.itemLevel:Hide()
    end
end

local function calculateUnitItemLevel(unit)
    local totalItemLevel = 0
    local itemCount = 0
    local isHunter = (select(2, UnitClass(unit)) == "HUNTER")
    local mainHandItemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("MainHandSlot"))
    local secondaryHandItemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("SecondaryHandSlot"))
    local mainHandItemLevel = mainHandItemLink and GetDetailedItemLevelInfo(mainHandItemLink) or 0
    local secondaryHandItemLevel = secondaryHandItemLink and GetDetailedItemLevelInfo(secondaryHandItemLink) or 0
    local dualWieldItemLevel = math.max(mainHandItemLevel, secondaryHandItemLevel)
    local versionText, interfaceVersion = ScarletUI:GetWoWVersion()

    for _, slotName in ipairs(slots) do
        local skipSlot = false

        -- Skip MainHand and SecondaryHand slots if the player is a hunter and has a ranged weapon equipped
        if isHunter and interfaceVersion < 50000 then
            local rangedItemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("RangedSlot"))

            if rangedItemLink and (slotName == "MainHand" or slotName == "SecondaryHand") then
                skipSlot = true
            end
        else
            if slotName == "Ranged" then
                skipSlot = true
            end

            if slotName == "SecondaryHand" then
                if mainHandItemLink then
                    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(mainHandItemLink)
                    -- INVTYPE_2HWEAPON includes 2H melee weapons
                    -- INVTYPE_RANGED and INVTYPE_RANGEDRIGHT are for bows/guns/crossbows (used by hunters in MoP)
                    if itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" then
                        skipSlot = true
                    end
                end
            end
        end

        if not skipSlot then
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            local itemLink = GetInventoryItemLink(unit, slotID)
            if itemLink then
                local itemLevel = GetDetailedItemLevelInfo(itemLink)
                if slotName == "MainHand" or slotName == "SecondaryHand" then
                    -- Player is dual wielding, use the higher item level item for the calculation
                    totalItemLevel = totalItemLevel + dualWieldItemLevel
                else
                    totalItemLevel = totalItemLevel + itemLevel
                end
            end
            itemCount = itemCount + 1
        end
    end

    return totalItemLevel / itemCount
end

function ScarletUI:CharacterFrameItemLevel()
    local hide = not self.db.global.itemLevelCharacter
    local versionText, interfaceVersion = ScarletUI:GetWoWVersion()

    for _, slotName in ipairs(slots) do
        if interfaceVersion >= 50000 and slotName == "Ranged" then
            -- nothing
        else
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            local itemLocation

            if slotID ~= nil then
                local itemLink = GetInventoryItemLink("player", slotID)
                local itemButton = _G["Character" .. slotName .. "Slot"]

                if ItemLocation.CreateFromEquipmentSlot then
                    itemLocation = ItemLocation:CreateFromEquipmentSlot(slotID)
                end

                ItemLevelText(itemLink, itemLocation, itemButton, hide)
            end
        end
    end
end

function ScarletUI:InspectFrameItemLevel()
    local hide = not self.db.global.itemLevelInspect
    if not InspectFrame then
        return
    end

    local unit = InspectFrame.unit
    if not unit then
        return
    end


    local averageItemLevel = calculateUnitItemLevel(unit)

    if not self.inspectFrameItemLevelText then
        self.inspectFrameItemLevelText = InspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

        local versionText, interfaceVersion = self:GetWoWVersion()
        if self.retail then
            self.inspectFrameItemLevelText:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 10, 15)
        elseif interfaceVersion >= 50000 then
            self.inspectFrameItemLevelText:SetPoint("TOP", InspectFrame, "TOP", 0, -40)
        else
            self.inspectFrameItemLevelText:SetPoint("TOP", InspectFrame, "TOP", 0, -60)
        end
    end

    self.inspectFrameItemLevelText:SetText("Item Level: " .. math.floor(averageItemLevel))

    local versionText, interfaceVersion = ScarletUI:GetWoWVersion()
    for _, slotName in ipairs(slots) do
        if interfaceVersion >= 50000 and slotName == "Ranged" then
            -- nothing
        else
            local slotID = GetInventorySlotInfo(slotName .. "Slot")

            if slotID ~= nil then
                local itemLink = GetInventoryItemLink(unit, slotID)
                local itemButton = _G["Inspect" .. slotName .. "Slot"]

                ItemLevelText(itemLink, nil, itemButton, hide)
            end
        end
    end
end

function ScarletUI:LoopBagButtons(containerFrame)
    local hide = not self.db.global.itemLevelBag

    if containerFrame then
        for _, button in containerFrame:EnumerateValidItems() do
            if button then
                local itemLink
                local itemLocation = ItemLocation:CreateFromBagAndSlot(button:GetBagID(), button:GetID())

                if itemLocation:IsValid() then
                    itemLink = C_Item.GetItemLink(itemLocation)
                else
                    itemLocation = nil
                end

                ItemLevelText(itemLink, itemLocation, button, hide)
            end
        end
    end
end

-- Hide all item level labels in the bank frame tree.
-- Used to clear stale labels before pooled buttons are regenerated.
function ScarletUI:ClearBankItemLevels()
    if not BankFrame then return end
    local function clear(frame, depth)
        if not frame or depth > 4 then return end
        if frame.itemLevel then
            frame.itemLevel:Hide()
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            clear(child, depth + 1)
        end
    end
    clear(BankFrame, 0)
end

-- Schedule a bank item level update for next frame, with debouncing.
-- Multiple calls per frame (e.g. rapid BAG_UPDATE) collapse into one scan.
function ScarletUI:ScheduleBankUpdate()
    if self.bankUpdatePending then return end
    self.bankUpdatePending = true
    C_Timer.After(0, function()
        self.bankUpdatePending = false
        self:UpdateBankItemLevels()
    end)
end

function ScarletUI:UpdateBankItemLevels()
    local hide = not self.db.global.itemLevelBag
    if not (BankFrame and BankFrame:IsShown()) then return end

    -- Classic: character bank uses known global button names (BankFrameItem1..N)
    -- Retail: BankSlotsFrame may not exist; the scan below handles all panels
    local bankSlotsFrame = _G["BankSlotsFrame"]
    if bankSlotsFrame and bankSlotsFrame:IsShown() then
        local numSlots = GetContainerNumSlots(BANK_CONTAINER)
        for slot = 1, numSlots do
            local button = _G["BankFrameItem" .. slot]
            if button then
                local itemLocation = ItemLocation:CreateFromBagAndSlot(BANK_CONTAINER, slot)
                local itemLink
                if itemLocation:IsValid() then
                    itemLink = C_Item.GetItemLink(itemLocation)
                else
                    itemLocation = nil
                end
                ItemLevelText(itemLink, itemLocation, button, hide)
            end
        end
    end

    -- Retail: bank panels use pooled buttons with GetItemLocation (BankPanelItemButtonMixin).
    -- Duck-type to find them — works across expansions regardless of frame naming.
    local function scanForItemButtons(frame, depth)
        if not frame or not frame:IsShown() or depth > 3 then return end
        if frame.GetItemLocation then
            local itemLocation = frame:GetItemLocation()
            local itemLink
            if itemLocation and itemLocation:IsValid() then
                itemLink = C_Item.GetItemLink(itemLocation)
            else
                itemLocation = nil
            end
            ItemLevelText(itemLink, itemLocation, frame, hide)
        end
        for _, child in ipairs({ frame:GetChildren() }) do
            scanForItemButtons(child, depth + 1)
        end
    end

    for _, panel in ipairs({ BankFrame:GetChildren() }) do
        if panel ~= bankSlotsFrame and panel:IsShown() then
            scanForItemButtons(panel, 1)
        end
    end
end

function ScarletUI:BagItemLevel()
    local hide = not self.db.global.itemLevelBag

    if self.retail then
        self:LoopBagButtons(_G["ContainerFrameCombinedBags"])

        self:UpdateBankItemLevels()
    else
        -- Update custom bag frame if it exists
        if ScarletUI_BagFrame then
            for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
                local numberOfSlots = GetContainerNumSlots(container)
                for slot = 1, numberOfSlots do
                    local itemLink = GetContainerItemLink(container, slot)
                    local index = container * 100 + slot
                    local itemButton = self.bagSlots and self.bagSlots[index]
                    if itemButton then
                        ItemLevelText(itemLink, nil, itemButton, hide)
                    end
                end
            end
        end

        -- Update custom bank frame if it exists
        if self.bankSlots and ScarletUI_BankFrame and ScarletUI_BankFrame:IsShown() then
            -- Main bank container
            for slot = 1, GetContainerNumSlots(BANK_CONTAINER) do
                local itemLink = GetContainerItemLink(BANK_CONTAINER, slot)
                local index = BANK_CONTAINER * 100 + slot
                local itemButton = self.bankSlots[index]
                if itemButton then
                    ItemLevelText(itemLink, nil, itemButton, hide)
                end
            end

            -- Bank bag containers
            for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemLink = GetContainerItemLink(bag, slot)
                    local index = bag * 100 + slot
                    local itemButton = self.bankSlots[index]
                    if itemButton then
                        ItemLevelText(itemLink, nil, itemButton, hide)
                    end
                end
            end
        end

        -- Update default bag frames
        for frameIndex = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame" .. frameIndex]
            if frame and frame:IsShown() then
                local container = frame:GetID()
                local numberOfSlots = GetContainerNumSlots(container)

                for slot = 1, numberOfSlots do
                    local itemLink = GetContainerItemLink(container, slot)
                    local adjustedSlot = numberOfSlots - slot + 1
                    local itemButton = _G["ContainerFrame" .. frameIndex .. "Item" .. adjustedSlot]

                    if itemButton then
                        ItemLevelText(itemLink, nil, itemButton, hide)
                    end
                end
            end
        end

        -- Update bank frame if it's open
        if BankFrame and BankFrame:IsShown() then
            local container = BANK_CONTAINER
            local numberOfSlots = GetContainerNumSlots(container)

            for slot = 1, numberOfSlots do
                local itemLink = GetContainerItemLink(container, slot)
                local itemButton = _G["BankFrameItem" .. slot]

                if itemButton then
                    ItemLevelText(itemLink, nil, itemButton, hide)
                end
            end
        end
    end
end

function ScarletUI:SetupItemLevels()
    if not self.itemLevelEventRegistered then
        self.itemLevelEventRegistered = true

        self:RegisterEventHandler("PLAYER_EQUIPMENT_CHANGED", function()
            ScarletUI:CharacterFrameItemLevel()
        end)

        self:RegisterEventHandler("UNIT_INVENTORY_CHANGED", function()
            ScarletUI:CharacterFrameItemLevel()
        end)

        self:RegisterEventHandler("INSPECT_READY", function()
            if not ScarletUI.inspectOpened then
                C_Timer.After(0.1, function() ScarletUI:InspectFrameItemLevel() end)
            else
                ScarletUI.inspectOpened = false
            end
        end)

        self:RegisterEventHandler("BAG_UPDATE", function()
            C_Timer.After(0, function()
                ScarletUI:BagItemLevel()
            end)
        end)

        self:RegisterEventHandler("BANKFRAME_OPENED", function()
            C_Timer.After(0.05, function()
                ScarletUI:BagItemLevel()
            end)

            if ScarletUI.retail and not ScarletUI.bankHooked then
                ScarletUI.bankHooked = true

                -- Hook main bank tab buttons (Bank / Warband Bank switching)
                for i = 1, 5 do
                    local tab = _G["BankFrameTab" .. i]
                    if tab then
                        tab:HookScript("OnClick", function()
                            ScarletUI:ClearBankItemLevels()
                            ScarletUI:ScheduleBankUpdate()
                        end)
                    end
                end

                -- Hook all bank panels for sub-tab switches and item refreshes.
                -- Duck-type BankFrame children to find panels with BankPanelMixin methods.
                for _, panel in ipairs({ BankFrame:GetChildren() }) do
                    if panel.SelectTab then
                        hooksecurefunc(panel, "SelectTab", function()
                            ScarletUI:ClearBankItemLevels()
                            ScarletUI:ScheduleBankUpdate()
                        end)
                    end

                    if panel.GenerateItemSlotsForSelectedTab then
                        hooksecurefunc(panel, "GenerateItemSlotsForSelectedTab", function()
                            ScarletUI:UpdateBankItemLevels()
                        end)
                    end

                    if panel.RefreshAllItemsForSelectedTab then
                        hooksecurefunc(panel, "RefreshAllItemsForSelectedTab", function()
                            ScarletUI:UpdateBankItemLevels()
                        end)
                    end
                end
            end
        end)

        self:RegisterEventHandler("PLAYERBANKSLOTS_CHANGED", function()
            ScarletUI:BagItemLevel()
        end)

        CharacterFrame:HookScript("OnShow", function()
            ScarletUI:CharacterFrameItemLevel()
        end)

        if self.retail then
            EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function()
                ScarletUI:BagItemLevel()
            end);
        else
            -- Hook into each container frame's OnShow event for non-retail
            for frameIndex = 1, NUM_CONTAINER_FRAMES do
                local frame = _G["ContainerFrame" .. frameIndex]
                if frame then
                    frame:HookScript("OnShow", function()
                        -- Use a small delay to ensure the frame is fully initialized
                        C_Timer.After(0.01, function()
                            ScarletUI:BagItemLevel()
                        end)
                    end)
                end
            end

            -- Also hook the toggle functions to catch bag opens
            hooksecurefunc("ToggleBag", function()
                C_Timer.After(0.01, function()
                    ScarletUI:BagItemLevel()
                end)
            end)

            hooksecurefunc("OpenBag", function()
                C_Timer.After(0.01, function()
                    ScarletUI:BagItemLevel()
                end)
            end)
        end

        self:BagItemLevel()
    end
end
