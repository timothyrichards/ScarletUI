local GetItemInfo = C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant or GetItemInfoInstant

-- Enum.ItemClass values (Profession is Retail only) and Enum.ItemWeaponSubclass.Fishingpole
local CONSUMABLE, WEAPON, REAGENT, TRADESKILL, QUEST, PROFESSION, FISHING_POLE = 0, 2, 5, 7, 12, 19, 20

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

local function IsIgnored(bag, slot, itemID, classID, subclassID, isCraftingReagent)
    -- Reagents: spell reagents (Reagent class), Trade Goods, and crafting reagents of other classes such as gems.
    if classID == CONSUMABLE or classID == QUEST or classID == PROFESSION or classID == TRADESKILL
        or classID == REAGENT or isCraftingReagent or tools[itemID] or (classID == WEAPON and subclassID == FISHING_POLE) then
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

-- The item ID in an item link, an item ID, or the name of an item the client
-- has cached (everything in the bags is); nil if none matches.
function ScarletUI:ParseItemID(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text == "" then return end
    local id = tonumber(text:match("item:(%d+)") or text)
    return id or GetItemInfoInstant(text)
end

-- Exclusions are item IDs in db.global.cheapestItemExclusions, never highlighted.
-- Every change refreshes the highlight and the settings list and says so in chat.
local function ExclusionsChanged(self, id, message)
    self:UpdateCheapestItem()
    LibStub("AceConfigRegistry-3.0"):NotifyChange("ScarletUI")
    self:Print((select(2, GetItemInfo(id)) or ("Item " .. id)) .. message)
end

-- `undo` tells the player how to take it back; the settings input's items may not be in the bags.
function ScarletUI:ExcludeCheapestItem(text, undo)
    local id = self:ParseItemID(text)
    if id then
        self.db.global.cheapestItemExclusions[id] = true
        ExclusionsChanged(self, id, " will not be highlighted as your cheapest item. "
            .. (undo or "Remove it under Excluded Items in /sui to undo."))
    end
    return id
end

function ScarletUI:IncludeCheapestItem(id)
    self.db.global.cheapestItemExclusions[id] = nil
    ExclusionsChanged(self, id, " can be highlighted as your cheapest item again.")
end

-- Excludes the item in a bag slot, or brings it back if it already is; true if now excluded.
function ScarletUI:ToggleCheapestItem(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then return end
    if self.db.global.cheapestItemExclusions[info.itemID] then
        self:IncludeCheapestItem(info.itemID)
        return false
    end
    return self:ExcludeCheapestItem(info.itemID, "Ctrl+Alt+Click it again to undo.") ~= nil
end

-- Ctrl+Alt+left-click on a bag item toggles its exclusion. Blizzard binds Shift (link, split),
-- Ctrl (dress up), and Alt (self-cast) alone, and right-click uses or sells, so this chord does
-- nothing else; a modified click also never picks the item up. A post-hook (HookScript), so the
-- button's own click runs untainted first.
local function OnItemClick(button, mouseButton)
    if mouseButton == "LeftButton" and IsControlKeyDown() and IsAltKeyDown() and not IsShiftKeyDown()
        and ScarletUI.db.global.highlightCheapestItem then
        -- Bag.lua slots, Mainline buttons, Classic buttons (parent frame ID is the bag)
        local bag = button.bag or (button.GetBagID and button:GetBagID()) or button:GetParent():GetID()
        ScarletUI:ToggleCheapestItem(bag, button:GetID())
    end
end

local hooked = setmetatable({}, { __mode = "k" })
local function HookItemClick(button)
    if not hooked[button] then
        hooked[button] = true
        button:HookScript("OnClick", OnItemClick)
    end
end

-- A muted hint on the highlighted item's tooltip, whose owner is its bag button.
local HINT = "Cheapest item. Ctrl+Alt+Click: never highlight this item"
local function AddHint(tooltip)
    local owner = tooltip == GameTooltip and tooltip:GetOwner()
    if owner and owner.cheapestGlow and owner.cheapestGlow:IsShown() then
        tooltip:AddLine(HINT, 0.5, 0.5, 0.5)
        return true
    end
end

local function HookTooltip()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddHint)
    else
        GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
            if AddHint(tooltip) then tooltip:Show() end -- resize
        end)
    end
end

-- Bag and slot of the stack with the lowest vendor value (sell price x count).
-- Unsellable items, consumables, spell and crafting reagents, quest items, profession tools, equipment set items,
-- and the player's exclusions are ignored.
-- ponytail: uncached items are skipped until the next bag update; listen to GET_ITEM_INFO_RECEIVED if that shows up.
function ScarletUI:FindCheapestBagItem()
    local cheapestBag, cheapestSlot, cheapestValue
    local setItems = GetEquipmentSetItems()
    local excluded = self.db.global.cheapestItemExclusions
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not setItems[info.itemID] and not excluded[info.itemID] then
                local sellPrice, classID, subclassID, _, _, _, isCraftingReagent = select(11, GetItemInfo(info.itemID))
                if sellPrice and sellPrice > 0
                    and not IsIgnored(bag, slot, info.itemID, classID, subclassID, isCraftingReagent) then
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
    HookItemClick(button)
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
local tooltipHooked
function ScarletUI:UpdateCheapestItem()
    if not tooltipHooked then
        tooltipHooked = true
        HookTooltip()
    end
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
