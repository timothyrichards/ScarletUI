-- XP food reminder, Forever only: cooked food and brewed drinks there also grant
-- Well Fed XP Boost, 5% more experience from kills for 15 minutes. While that
-- buff is missing and the bags hold a food the character can eat, that food's
-- icon shows on screen. Hidden in combat and at max level. The icon is a plain
-- frame: it reminds, it does not eat for you.
local XP_BUFF = 1243969 -- Well Fed XP Boost; every food below applies it
local ICON_SIZE = 36
local IsSecret = issecretvalue or function() return false end
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

-- Item ID = required level, keyed below by that level.
-- ponytail: hand-kept list from forever.wowhead.com (every item whose effect
-- text has "experience gained from kills", November 2026); a food added later
-- is not noticed. Match the item tooltip text instead if they keep appearing.
local FOODS = {}
for level, items in pairs({
    [1] = {
        787, 2680, 2681, 2682, 2888, 3663, 5472, 5474, 5477, 6290, 6888, 6890,
        12224, 249865, 249871, 250079, 287973, 287974,
    },
    [5] = {
        724, 733, 1082, 2683, 2684, 2687, 3220, 3662, 3726, 4592, 5095, 5476,
        5479, 6316, 12213, 249866, 249872, 250077, 250080, 263509, 263512, 268912, 268913,
    },
    [10] = {
        21072,
    },
    [15] = {
        1017, 2685, 3664, 3665, 3666, 3727, 3729, 4593, 5480, 12209, 12210, 12214,
        249867, 249873,
    },
    [25] = {
        3728, 4457, 4594, 6038, 8364, 10841, 12215, 12216, 13851, 20074, 249868, 249874,
        250073, 250074, 250078, 274971, 274976,
    },
    [30] = {
        21217,
    },
    [35] = {
        6887, 12212, 12218, 13927, 13928, 13929, 13930, 13931, 13932, 17222, 18045, 18254,
        249869, 249875, 250065, 250076, 286152,
    },
    [45] = {
        8957, 13933, 13934, 13935, 20452, 249870, 249876, 250066, 250067, 250068, 250069, 250070,
        250071, 250072, 250075,
    },
    [55] = {
        267341,
    },
}) do
    for _, itemID in ipairs(items) do FOODS[itemID] = level end
end

-- Only asked out of combat, where the player's own auras are readable; a
-- secret answer counts as buffed so the reminder stays quiet.
local function HasBuff()
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(XP_BUFF)
    return IsSecret(aura) or aura ~= nil
end

-- The XP food in the bags with the highest required level the character meets.
local function FindFood()
    local level, best = UnitLevel("player"), nil
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            local required = itemID and FOODS[itemID]
            if required and required <= level and (not best or required > FOODS[best]) then
                best = itemID
            end
        end
    end
    return best
end

function ScarletUI:SetupXPFood()
    if self.xpFoodFrame then
        -- Setup reruns after a settings reset.
        self:PlaceXPFood()
        self:UpdateXPFood()
        return
    end
    if self:GetWoWVersion() ~= "FOREVER" or not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then
        return
    end

    local icon = self:CreateIconButton(UIParent, ICON_SIZE, "ScarletUIXPFood")
    self.xpFoodFrame = icon
    local combat = InCombatLockdown()
    local label = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -4)
    label:SetText("XP Food")

    icon:SetMovable(true)
    icon:SetClampedToScreen(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function() icon:StartMoving() end)
    icon:SetScript("OnDragStop", function()
        icon:StopMovingOrSizing()
        local point, _, relativePoint, x, y = icon:GetPoint()
        self.db.global.xpFoodModule.position = { point, relativePoint, x, y }
    end)
    icon:SetScript("OnEnter", function()
        GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. icon.itemID)
        GameTooltip:AddLine("Eat this for 5% more experience from kills.", 0, 1, 0, true)
        GameTooltip:AddLine("Drag to move.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    function self:PlaceXPFood()
        local position = self.db.global.xpFoodModule.position
        icon:ClearAllPoints()
        if position then
            icon:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            icon:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
    end
    self:PlaceXPFood()

    function self:UpdateXPFood()
        local wanted = self.db.global.xpFoodModule.enabled and not combat
            and not (IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel())
        local itemID = wanted and not HasBuff() and FindFood()
        icon:SetShown(itemID and true or false)
        if itemID then
            icon.itemID = itemID
            icon.texture:SetTexture((select(5, GetItemInfoInstant(itemID))))
        end
    end

    -- Hidden frames still receive events.
    icon:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            combat = event == "PLAYER_REGEN_DISABLED"
        end
        self:UpdateXPFood()
    end)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
        icon:RegisterEvent(event)
    end
    icon:RegisterUnitEvent("UNIT_AURA", "player")
    self:UpdateXPFood()
end
