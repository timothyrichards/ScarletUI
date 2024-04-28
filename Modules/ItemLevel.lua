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
    if not self.db.global.itemLevelInspect then
        return
    end

    for _, slotName in ipairs(slots) do
        if self.retail and slotName == "Ranged" then
            -- nothing
        else
            local slotID = GetInventorySlotInfo(slotName .. "Slot")
            local itemLink = GetInventoryItemLink("target", slotID)
            local itemButton = _G["Inspect" .. slotName .. "Slot"]
            ItemLevelText(itemLink, itemButton)
        end
    end
end

function ScarletUI:BagItemLevel()
    if not self.db.global.itemLevelBag then
        return
    end

    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        if C_Container.GetContainerNumSlots then
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                local adjustedSlot = C_Container.GetContainerNumSlots(bag) - slot + 1
                local itemButton = _G["ContainerFrame" .. (bag + 1) .. "Item" .. adjustedSlot]
                ItemLevelText(itemLink, itemButton)
            end
        elseif GetContainerNumSlots then
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
        self.frame:SetScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
                ScarletUI:CharacterFrameItemLevel()
            elseif event == "INSPECT_READY" then
                if not ScarletUI.inspectOpened then
                    ScarletUI:InspectFrameItemLevel()
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
