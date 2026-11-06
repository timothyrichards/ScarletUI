local GetItemInfo = C_Item.GetItemInfo or GetItemInfo

-- Bag and slot of the stack with the lowest vendor value (sell price x count).
-- Items that cannot be sold are ignored.
-- ponytail: uncached items are skipped until the next bag update; listen to GET_ITEM_INFO_RECEIVED if that shows up.
function ScarletUI:FindCheapestBagItem()
    local cheapestBag, cheapestSlot, cheapestValue
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            local sellPrice = info and select(11, GetItemInfo(info.itemID))
            if sellPrice and sellPrice > 0 then
                local value = sellPrice * info.stackCount
                if not cheapestValue or value < cheapestValue then
                    cheapestBag, cheapestSlot, cheapestValue = bag, slot, value
                end
            end
        end
    end
    return cheapestBag, cheapestSlot
end

local function SetGlow(button, show)
    if show and not button.cheapestGlow then
        button.cheapestGlow = button:CreateTexture(nil, "OVERLAY", nil, 2)
        button.cheapestGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        button.cheapestGlow:SetBlendMode("ADD")
        button.cheapestGlow:SetVertexColor(1, 0.2, 0.2)
        button.cheapestGlow:SetPoint("CENTER")
    end
    if button.cheapestGlow then
        if show then
            -- The border art fills the middle of its texture; custom bag slots can be resized.
            button.cheapestGlow:SetSize(button:GetWidth() * 1.8, button:GetHeight() * 1.8)
        end
        button.cheapestGlow:SetShown(show)
    end
end

-- Runs from BagItemLevel, which already fires on every bag change and bag open.
function ScarletUI:UpdateCheapestItem()
    local bag, slot
    if self.db.global.highlightCheapestItem then
        bag, slot = self:FindCheapestBagItem()
    end

    -- Blizzard bags: the combined backpack and individual bag frames
    for i = 0, NUM_CONTAINER_FRAMES or 0 do
        local frame = i == 0 and ContainerFrameCombinedBags or _G["ContainerFrame" .. i]
        if frame and frame.EnumerateValidItems then
            for _, button in frame:EnumerateValidItems() do
                SetGlow(button, button:GetBagID() == bag and button:GetID() == slot)
            end
        elseif frame then
            -- Classic frames reuse named buttons whose IDs are their slots.
            local frameBag = frame:GetID()
            for j = 1, MAX_CONTAINER_ITEMS or 36 do
                local button = _G[frame:GetName() .. "Item" .. j]
                if button then
                    SetGlow(button, frameBag == bag and button:GetID() == slot)
                end
            end
        end
    end

    -- Custom bag frame from Bag.lua (Era, TBC, and Mists)
    for index, button in pairs(self.bagSlots or {}) do
        SetGlow(button, bag ~= nil and index == bag * 100 + slot)
    end
end
