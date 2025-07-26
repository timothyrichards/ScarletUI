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
    local mainHandItemLevel = mainHandItemLink and GetDetailedItemLevelInfo(mainHandItemLink) or 0
    local secondaryHandItemLevel = secondaryHandItemLink and GetDetailedItemLevelInfo(secondaryHandItemLink) or 0
    local dualWieldItemLevel = math.max(mainHandItemLevel, secondaryHandItemLevel)
    local versionText, interfaceVersion = ScarletUI:GetWoWVersion()

    for _, slotName in ipairs(slots) do
        local skipSlot = false

        -- Skip MainHand and SecondaryHand slots if the player is a hunter and has a ranged weapon equipped
        if isHunter and not interfaceVersion >= 50000 then
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

function ScarletUI:BagItemLevel()
    local hide = not self.db.global.itemLevelBag

    if self.retail then
        for container = -1, NUM_CONTAINER_FRAMES do
            local containerFrame = _G["ContainerFrame" .. (container + 1)]

            if container == BANK_CONTAINER then
                containerFrame = _G["BankFrame"]
            end

            self:LoopBagButtons(containerFrame)
        end

        self:LoopBagButtons(_G["ContainerFrameCombinedBags"])
        -- TODO: Figure out how to get the AccountBankPanel to work
        --self:LoopBagButtons(_G["AccountBankPanel"])
    else
        for container = -1, NUM_CONTAINER_FRAMES do
            local numberOfSlots = GetContainerNumSlots(container)

            for slot = 1, numberOfSlots do
                local itemLink = GetContainerItemLink(container, slot)
                local itemButton

                if ScarletUI_BagFrame then
                    local index = container * numberOfSlots + slot
                    itemButton = self.bagSlots[index]
                else
                    local adjustedSlot = numberOfSlots - slot + 1

                    if container == BANK_CONTAINER then
                        itemButton = _G["BankFrameItem" .. slot]
                    else
                        itemButton = _G["ContainerFrame" .. (container + 1) .. "Item" .. adjustedSlot]
                    end
                end

                if itemButton then
                    ItemLevelText(itemLink, nil, itemButton, hide)
                end
            end
        end
    end
end

function ScarletUI:SetupItemLevels()
    if not self.itemLevelEventRegistered then
        self.itemLevelEventRegistered = true;
        self.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self.frame:RegisterEvent("BANKFRAME_OPENED")
        self.frame:RegisterEvent("BANKFRAME_CLOSED")
        self.frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
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
            elseif event == "BAG_UPDATE"or event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then
                ScarletUI:BagItemLevel()
            end
        end)

        CharacterFrame:HookScript("OnShow", function()
            ScarletUI:CharacterFrameItemLevel()
        end)


        EventRegistry:RegisterCallback("ContainerFrame.OpenBag", function()
            ScarletUI:BagItemLevel()
        end);

        self:BagItemLevel()
    end
end
