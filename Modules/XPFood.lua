-- XP food reminder, Forever only: cooked food and brewed drinks there also grant
-- Well Fed XP Boost, 5% more experience from kills for 15 minutes. While that
-- buff is missing and the bags hold a food the character can eat, that food's
-- icon shows on screen, styled like the fishing bar's lure: right-click eats
-- it, left-click opens a list of the usable XP foods in the bags to pick the
-- one shown. While a food is being eaten the icon counts down the seconds to
-- Well Fed instead. Hidden in combat, while dead, and at max level. The icon is a secure button
-- (eating is a protected action), so it only shows, hides, or changes food out
-- of combat.
-- The XP bonus itself (spell 1243969) is a hidden aura addons cannot see, so the
-- buff is read from the visible Well Fed auras these foods apply: one spell per
-- stat bonus, each triggered by the food's Nutritious Food or Drink use spell.
local WELL_FED = {
    1248406, 1248420, 1248421, 1248422, 1248688, 1249519, 1249520,
    1249521, 1249523, 1249907, 1249926, 1249927, 1294007, 1319310,
}
local ICON_SIZE, ICON_GAP = 36, 4
local LIST_CLOSE_DELAY = 1 -- seconds the mouse may be off the open food list
-- Seconds of eating before Well Fed: each food's use spell (Nutritious Food or
-- Drink) is a hidden aura that triggers it once, after this long.
local EAT_TIME = 10
local IsSecret = issecretvalue or function() return false end
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local GetItemSpell = C_Item and C_Item.GetItemSpell or GetItemSpell

-- Item ID = required level, keyed below by that level.
-- ponytail: both lists are hand-kept from forever.wowhead.com (every item whose
-- effect text has "experience gained from kills", November 2026); a food or
-- Well Fed spell added later is not noticed. Match the item tooltip text and
-- the aura name instead if they keep appearing.
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
    for _, spellID in ipairs(WELL_FED) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if IsSecret(aura) or aura ~= nil then return true end
    end
    return false
end

-- The use spell's own aura is hidden, but it also applies the ordinary Food
-- (433) or Drink (430) aura, which ends when the player stands up. Every rank
-- shares the name.
local function HasEatingAura()
    local byName = C_UnitAuras.GetAuraDataBySpellName
    for _, spellID in ipairs({ 433, 430 }) do
        local name = byName and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
        if name and byName("player", name) ~= nil then return true end
    end
    return false
end

-- The XP foods in the bags the character can eat, highest required level
-- first, and the one to show: the picked food while the bags hold it,
-- otherwise the first.
local function FindFoods(picked)
    local level, seen, foods = UnitLevel("player"), {}, {}
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            local required = itemID and FOODS[itemID]
            if required and required <= level and not seen[itemID] then
                seen[itemID] = true
                foods[#foods + 1] = itemID
            end
        end
    end
    table.sort(foods, function(a, b)
        if FOODS[a] ~= FOODS[b] then return FOODS[a] > FOODS[b] end
        return a < b
    end)
    return foods, picked and seen[picked] and picked or foods[1]
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

    -- A food's icon and stack count, with its item tooltip and hints below it.
    local function FoodButton(parent, hint, note, name, template)
        local food = self:CreateIconButton(parent, ICON_SIZE, name, template)
        food.count = food:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        food.count:SetPoint("BOTTOMRIGHT", -2, 2)
        food:SetScript("OnEnter", function()
            GameTooltip:SetOwner(food, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. food.itemID)
            GameTooltip:AddLine(hint, 0, 1, 0, true)
            if note then GameTooltip:AddLine(note, 0.6, 0.6, 0.6, true) end
            GameTooltip:Show()
        end)
        return food
    end

    local function ShowFood(food, itemID)
        food.itemID = itemID
        food.texture:SetTexture((select(5, GetItemInfoInstant(itemID))))
        food.count:SetText(GetItemCount(itemID))
    end

    -- Right-click runs the secure macro that eats the food shown.
    local icon = FoodButton(UIParent, "Right-click to eat. Left-click to choose a food.",
        "Drag to move. Ctrl-click to reset its position.", "ScarletUIXPFood", "SecureActionButtonTemplate")
    self.xpFoodFrame = icon
    icon:RegisterForClicks("AnyUp")
    icon:SetAttribute("useOnKeyDown", false)
    icon:SetAttribute("type2", "macro")
    local combat = InCombatLockdown()
    local label = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -4)
    label:SetText("XP Food")

    -- While an XP food is being eaten, an empty slot counting down to Well Fed
    -- covers the food. Not a secure frame, so it may show and hide at any time.
    local timer = CreateFrame("Frame", nil, icon)
    timer:SetAllPoints(icon)
    timer:Hide()
    local slot = timer:CreateTexture(nil, "BACKGROUND")
    slot:SetAllPoints()
    slot:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    timer.text = timer:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    timer.text:SetPoint("CENTER")
    -- When Well Fed is due, and whether the Food or Drink aura has been seen
    -- since: only an aura that was there and went means the meal was cut short.
    local wellFedAt, sawEating
    local function StopEating()
        wellFedAt, sawEating = nil, nil
        timer:Hide()
    end
    timer:SetScript("OnUpdate", function()
        local left = wellFedAt - GetTime()
        if left <= 0 then return StopEating() end
        timer.text:SetText(math.ceil(left))
    end)

    -- Left-click opens the usable foods in the bags, stacked upward from the icon.
    local list = CreateFrame("Frame", nil, icon)
    list:SetAllPoints(icon)
    list:Hide()
    local listButtons, away = {}, 0
    -- The open list closes once the mouse has been off the foods for a moment.
    list:SetScript("OnUpdate", function(_, elapsed)
        local over = icon:IsMouseOver()
        for _, food in ipairs(listButtons) do
            over = over or food:IsShown() and food:IsMouseOver()
        end
        away = over and 0 or away + elapsed
        if away >= LIST_CLOSE_DELAY then list:Hide() end
    end)

    icon:SetMovable(true)
    icon:SetClampedToScreen(true)
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function() icon:StartMoving() end)
    icon:SetScript("OnDragStop", function()
        icon:StopMovingOrSizing()
        local point, _, relativePoint, x, y = icon:GetPoint()
        self.db.global.xpFoodModule.position = { point, relativePoint, x, y }
    end)
    -- OnClick belongs to the secure template, so our clicks are read after it.
    icon:SetScript("PostClick", function(_, button)
        if button ~= "LeftButton" then return end
        if IsControlKeyDown() then
            self.db.global.xpFoodModule.position = nil
            self:PlaceXPFood()
            return
        end
        away = 0
        list:SetShown(not list:IsShown())
    end)

    function self:PlaceXPFood()
        if InCombatLockdown() then return end -- a secure button cannot move in combat
        local position = self.db.global.xpFoodModule.position
        icon:ClearAllPoints()
        if position then
            icon:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            icon:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        end
    end
    self:PlaceXPFood()

    local foods = {} -- the usable foods as last drawn
    function self:UpdateXPFood()
        -- Hidden on entering combat; nothing on a secure button may change until it ends.
        if combat or InCombatLockdown() then return end
        local module = self.db.global.xpFoodModule
        -- The dead and ghosts cannot eat.
        local wanted = module.enabled and not UnitIsDeadOrGhost("player")
            and not (IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel())
        local shown
        foods = {}
        if wanted and not HasBuff() then foods, shown = FindFoods(module.food) end
        icon:SetShown(shown ~= nil)
        if not shown then
            list:Hide()
            StopEating()
            return
        end
        ShowFood(icon, shown)
        icon:SetAttribute("macrotext2", "/use item:" .. shown)
        for index, itemID in ipairs(foods) do
            local food = listButtons[index]
            if not food then
                food = FoodButton(list, "Click to pick this. Click it again to show the best food.")
                listButtons[index] = food
                food:SetPoint("BOTTOM", icon, "TOP", 0, ICON_GAP + (index - 1) * (ICON_SIZE + ICON_GAP))
                food.applied = food:CreateTexture(nil, "OVERLAY")
                food.applied:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                food.applied:SetBlendMode("ADD")
                food.applied:SetAllPoints()
                food:SetScript("OnClick", function()
                    -- Clicking the picked food again goes back to the best one.
                    local settings = self.db.global.xpFoodModule
                    settings.food = settings.food ~= food.itemID and food.itemID or nil
                    list:Hide()
                    self:UpdateXPFood()
                end)
            end
            ShowFood(food, itemID)
            food:Show()
            -- The highlight marks the food the icon shows and eats.
            food.applied:SetShown(itemID == shown)
        end
        for index = #foods + 1, #listButtons do listButtons[index]:Hide() end
    end

    -- Hidden frames still receive events.
    icon:SetScript("OnEvent", function(_, event, _, _, spellID)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Fires before the combat lockdown, so the button can still hide.
            list:Hide()
            icon:Hide()
            StopEating()
            combat = true
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            combat = false
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Eating a listed food (the player's own casts are not secret)
            -- starts the countdown. Nobody eats in combat.
            if combat or InCombatLockdown() then return end
            for _, itemID in ipairs(foods) do
                if select(2, GetItemSpell(itemID)) == spellID then
                    wellFedAt, sawEating = GetTime() + EAT_TIME, nil
                    timer:Show()
                    break
                end
            end
            return
        elseif event == "UNIT_AURA" and wellFedAt then
            if HasEatingAura() then
                sawEating = true
            elseif sawEating then
                StopEating()
            end
        end
        self:UpdateXPFood()
    end)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
        icon:RegisterEvent(event)
    end
    icon:RegisterUnitEvent("UNIT_AURA", "player")
    icon:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    self:UpdateXPFood()
end
