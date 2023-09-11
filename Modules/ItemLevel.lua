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

function ScarletUI:SetupItemLevels()
    if not self.db.global.itemLevel then
        return
    end

    self.Frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self.Frame:RegisterEvent("INSPECT_READY")
    self.Frame:HookScript('OnEvent', function(_, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_INVENTORY_CHANGED" then
            self:CharacterFrameItemLevel()
        elseif event == "INSPECT_READY" then
            if not self.inspectOpened then
                self:InspectFrameItemLevel()
            else
                self.inspectOpened = false
            end
        end
    end)
    CharacterFrame:HookScript('OnShow', function()
        self:CharacterFrameItemLevel()
    end)
end

function ScarletUI:CharacterFrameItemLevel()
    for _, slotName in ipairs(slots) do
        local slotID = GetInventorySlotInfo(slotName .. "Slot")
        if (slotID ~= nil) then
            local itemLink = GetInventoryItemLink("player", slotID)
            local itemButton = _G["Character" .. slotName .. "Slot"]
            ItemLevelText(itemLink, itemButton)
        end
    end
end

function ScarletUI:InspectFrameItemLevel()
    for _, slotName in ipairs(slots) do
        if self.lightWeightMode and slotName == "Ranged" then
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
    local frame = "ContainerFrame"
    --if IsAddOnLoaded("Bagnon") then
    --    print('bagnon loaded')
    --    frame = "BagnonInventoryFrame"
    --end
    --for bag = 1, NUM_BAG_SLOTS do
    --    for slot = 1, GetContainerNumSlots(bag) do
    --        local itemLink = GetContainerItemLink(bag, slot)
    --        local itemButton = _G[frame .. bag .. "Item" .. slot]
    --        print(frame .. bag .. "Item" .. slot)
    --        ItemLevelText(itemLink, itemButton)
    --    end
    --end
end