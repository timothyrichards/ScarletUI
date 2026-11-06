local GetItemInfo = C_Item.GetItemInfo or GetItemInfo

-- Enum.ItemClass values (Profession is Retail only) and Enum.ItemWeaponSubclass.Fishingpole
local CONSUMABLE, WEAPON, QUEST, PROFESSION, FISHING_POLE = 0, 2, 12, 19, 20

-- Classic profession tools kept in bags; nothing in the item API marks them as tools.
-- ponytail: hand-kept list; add IDs here when a tool still gets highlighted.
local tools = {
    [2901] = true,  -- Mining Pick
    [7005] = true,  -- Skinning Knife
    [5956] = true,  -- Blacksmith Hammer
    [6219] = true,  -- Arclight Spanner
    [10498] = true, -- Gyromatic Micro-Adjustor
    [9149] = true,  -- Philosopher's Stone
    [4471] = true,  -- Flint and Tinder
    [5060] = true,  -- Thieves' Tools
    [6218] = true,  -- Runed Copper Rod
    [6339] = true,  -- Runed Silver Rod
    [11130] = true, -- Runed Golden Rod
    [11145] = true, -- Runed Truesilver Rod
    [16207] = true, -- Runed Arcanite Rod
    [22461] = true, -- Runed Fel Iron Rod
    [22462] = true, -- Runed Adamantite Rod
    [22463] = true, -- Runed Eternium Rod
    [44452] = true, -- Runed Titanium Rod
    [52723] = true, -- Runed Elementium Rod
    [12709] = true, -- Finkle's Skinner
    [19901] = true, -- Zulian Slicer
    [20815] = true, -- Jeweler's Kit
    [20824] = true, -- Simple Grinder
    [23821] = true, -- Zapthrottle Mote Extractor
    [39505] = true, -- Virtuoso Inking Set
    [40772] = true, -- Gnomish Army Knife
    [40892] = true, -- Hammer Pick
    [40893] = true, -- Bladed Pickaxe
}

local function IsIgnored(bag, slot, itemID, classID, subclassID)
    if classID == CONSUMABLE or classID == QUEST or classID == PROFESSION or tools[itemID]
        or (classID == WEAPON and subclassID == FISHING_POLE) then
        return true
    end
    -- Catches quest starters filed under other item classes.
    local quest = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
    return quest and (quest.isQuestItem or quest.questID)
end

-- Item IDs saved in any Equipment Manager set. Era and TBC have no Equipment Manager.
-- ponytail: matches by item ID, so spare copies of a set item are skipped too;
-- C_EquipmentSet.GetItemLocations gives exact bag slots if that matters.
local function GetEquipmentSetItems()
    local items = {}
    if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs then
        for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
            for _, itemID in pairs(C_EquipmentSet.GetItemIDs(setID) or {}) do
                items[itemID] = true
            end
        end
    end
    return items
end

-- Bag and slot of the stack with the lowest vendor value (sell price x count).
-- Unsellable items, consumables, quest items, profession tools, and equipment set items are ignored.
-- ponytail: uncached items are skipped until the next bag update; listen to GET_ITEM_INFO_RECEIVED if that shows up.
function ScarletUI:FindCheapestBagItem()
    local cheapestBag, cheapestSlot, cheapestValue
    local setItems = GetEquipmentSetItems()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not setItems[info.itemID] then
                local sellPrice, classID, subclassID = select(11, GetItemInfo(info.itemID))
                if sellPrice and sellPrice > 0 and not IsIgnored(bag, slot, info.itemID, classID, subclassID) then
                    local value = sellPrice * info.stackCount
                    if not cheapestValue or value < cheapestValue then
                        cheapestBag, cheapestSlot, cheapestValue = bag, slot, value
                    end
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
            -- Frames not opened yet enumerate empty entries up to their bag size.
            for _, button in frame:EnumerateValidItems() do
                if button then
                    SetGlow(button, button:GetBagID() == bag and button:GetID() == slot)
                end
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
