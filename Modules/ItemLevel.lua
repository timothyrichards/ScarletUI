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

local function ItemLevelText(itemLink, itemButton)
    if itemLink then
        local _, _, itemQuality, itemLevel, _, itemType, _, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemLink)
        if itemType == 'Armor' or itemType == 'Weapon' then
            if itemQuality and itemLevel then
                if itemButton then
                    if itemButton.itemLevel then
                        itemButton.itemLevel:Show()
                        UpdateTextElement(itemButton.itemLevel, itemLevel, ITEM_QUALITY_COLORS[itemQuality])
                    else
                        itemButton.itemLevel = CreateTextElement(itemButton, itemLevel, ITEM_QUALITY_COLORS[itemQuality], 0, 0)
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
    local mainHandItemLevel = mainHandItemLink and select(4, GetItemInfo(mainHandItemLink)) or 0
    local secondaryHandItemLevel = secondaryHandItemLink and select(4, GetItemInfo(secondaryHandItemLink)) or 0
    local dualWieldItemLevel = math.max(mainHandItemLevel, secondaryHandItemLevel)

    for _, slotName in ipairs(slots) do
        local skipSlot = false

        -- Skip MainHand and SecondaryHand slots if the player is a hunter and has a ranged weapon equipped
        local rangedItemLink = GetInventoryItemLink(unit, GetInventorySlotInfo("RangedSlot"))
        if isHunter and rangedItemLink then
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
                    if itemEquipLoc == "INVTYPE_2HWEAPON" then
                        skipSlot = true
                    end
                end
            end
        end

        if not skipSlot then
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            local itemLink = GetInventoryItemLink(unit, slotID)
            if itemLink then
                local _, _, _, itemLevel = GetItemInfo(itemLink)
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
    if not self.db.global.itemLevelCharacter then
        return
    end

    for _, slotName in ipairs(slots) do
        if self.retail and slotName == "Ranged" then
            -- nothing
        else
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            if (slotID ~= nil) then
                local itemLink = GetInventoryItemLink("player", slotID)
                local itemButton = _G["Character" .. slotName .. "Slot"]
                ItemLevelText(itemLink, itemButton)
            end
        end
    end
end

function ScarletUI:InspectFrameItemLevel()
    if not self.db.global.itemLevelInspect or not InspectFrame then
        return
    end

    local unit = InspectFrame.unit
    if not unit then
        return
    end

    local averageItemLevel = calculateUnitItemLevel(unit)

    if not self.inspectFrameItemLevelText then
        self.inspectFrameItemLevelText = InspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.inspectFrameItemLevelText:SetPoint("TOP", InspectFrame, "TOP", 0, -60)
    end

    self.inspectFrameItemLevelText:SetText("Item Level: " .. math.floor(averageItemLevel))

    for _, slotName in ipairs(slots) do
        if self.retail and slotName == "Ranged" then
            -- nothing
        else
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            local itemLink = GetInventoryItemLink(unit, slotID)
            local itemButton = _G["Inspect" .. slotName .. "Slot"]
            ItemLevelText(itemLink, itemButton)
        end
    end
end

function ScarletUI:BagItemLevel()
    if not self.db.global.itemLevelBag then
        return
    end

    if ScarletUI_BagFrame then
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local index = bag * GetContainerNumSlots(bag) + slot
                local itemLink = GetContainerItemLink(bag, slot)
                local itemButton = self.bagSlots[index]
                ItemLevelText(itemLink, itemButton)
            end
        end
    else
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                local adjustedSlot = GetContainerNumSlots(bag) - slot + 1
                local itemButton = _G["ContainerFrame" .. (bag + 1) .. "Item" .. adjustedSlot]
                ItemLevelText(itemLink, itemButton)
            end
        end
    end
end

function ScarletUI:SetupItemLevels()
    if not self.itemLevelEventRegistered then
        self.itemLevelEventRegistered = true;
        self.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
        self.frame:RegisterEvent("INSPECT_READY")
        self.frame:RegisterEvent("BAG_UPDATE")
        self.frame:HookScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
                ScarletUI:CharacterFrameItemLevel()
            elseif event == "INSPECT_READY" then
                if not ScarletUI.inspectOpened then
                    C_Timer.After(0.1, function() ScarletUI:InspectFrameItemLevel() end)
                else
                    ScarletUI.inspectOpened = false
                end
            elseif event == "BAG_UPDATE" then
                ScarletUI:BagItemLevel()
            end
        end)

        CharacterFrame:HookScript("OnShow", function()
            ScarletUI:CharacterFrameItemLevel()
        end)
    end

    self:BagItemLevel()
end
