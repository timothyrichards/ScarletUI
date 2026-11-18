-- Reminders: an icon on screen for a buff that is missing while the bags hold
-- the item that gives it. Each is styled like the fishing bar's lure:
-- right-click uses the item, left-click opens a list of the usable items in the
-- bags to pick the one shown. Hidden in combat and while dead. The icon is a
-- secure button (using an item is a protected action), so it only shows, hides,
-- or changes item out of combat.
--
-- Food buff, every client: a food that leaves the character Well Fed, while
-- that buff is missing. While a food is being eaten the icon counts down the
-- seconds to Well Fed instead.
-- On Forever cooked food and brewed drinks also grant Well Fed XP Boost, 5% more
-- experience from kills for 15 minutes. That bonus (spell 1243969) is a hidden
-- aura addons cannot see, so the buff is read from the visible Well Fed auras
-- these foods apply: one spell per stat bonus, each triggered by the food's
-- Nutritious Food or Drink use spell.
--
-- Weapon enhancements, Era, TBC, and Forever: sharpening stones, weightstones,
-- oils, and poisons, for a main- or off-hand weapon with no temporary enchant.
--
-- Camp items, Forever only: a second page of the bar, one icon per profession
-- for the campfire kits and camp items in the bags. A switch at the front of
-- the bar flips between the pages.
local WELL_FED = {
    1248406, 1248420, 1248421, 1248422, 1248688, 1249519, 1249520,
    1249521, 1249523, 1249907, 1249926, 1249927, 1294007, 1319310,
}
-- The Classic Well Fed, on every client: its name finds the buff and the foods.
local WELL_FED_NAME = 19705
local ICON_SIZE, ICON_GAP = 36, 4
local LIST_CLOSE_DELAY = 1 -- seconds the mouse may be off the open item list
-- Seconds of eating before Well Fed: each food's use spell (Nutritious Food or
-- Drink) is a hidden aura that triggers it once, after this long.
local EAT_TIME = 10
local IsSecret = issecretvalue or function() return false end
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount
local GetItemSpell = C_Item and C_Item.GetItemSpell or GetItemSpell
local GetSpellDescription = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return GetSpellInfo and (GetSpellInfo(spellID))
end

local function SpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellID) end
    return GetSpellTexture and GetSpellTexture(spellID)
end

-- Forever's foods, item ID = required level, keyed below by that level. Their
-- use spell is not known to mention Well Fed, so they are listed; every other
-- food is found by its use spell's text (see FoodLevel).
-- ponytail: both lists are hand-kept from forever.wowhead.com (every item whose
-- effect text has "experience gained from kills", November 2026); a Forever
-- food or Well Fed spell added later is only noticed if its text or name says
-- Well Fed.
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

-- Item ID = kind of weapon enhancement. Fishing lures are left to Fishing.lua.
-- ponytail: hand-kept from memory of the Classic and TBC items, not checked
-- against a database; an item a client adds later is not noticed. Add its ID
-- here, or match the "Use:" tooltip text if they keep appearing.
local ENHANCEMENTS = {}
for kind, items in pairs({
    -- Rough to Consecrated, then Fel and Adamantite.
    sharp = { 2862, 2863, 2871, 7964, 12404, 18262, 23122, 23528, 23529 },
    blunt = { 3239, 3240, 3241, 7965, 12643, 28420, 28421 },
    -- Shadow and Frost Oil, the wizard and mana oils.
    oil = { 3824, 3829, 20744, 20745, 20746, 20747, 20748, 20749, 20750, 22521, 22522, 23123 },
    -- Deadly, Crippling, Mind-numbing, Instant, Wound, and Anesthetic.
    poison = {
        2892, 2893, 3775, 3776, 5237, 6947, 6949, 6950, 6951, 8926, 8927, 8928, 8984, 8985,
        9186, 10918, 10920, 10921, 10922, 20844, 21835, 21927, 22053, 22054, 22055,
    },
}) do
    for _, itemID in ipairs(items) do ENHANCEMENTS[itemID] = kind end
end
-- Enum.ItemWeaponSubclass values a stone can go on; oils and poisons go on
-- anything but a fishing pole (20).
-- ponytail: fist weapons (13) are counted as blunt from memory; move the 13 if
-- the game refuses a weightstone on them.
local STONE_FITS = {
    sharp = { [0] = true, [1] = true, [6] = true, [7] = true, [8] = true, [15] = true }, -- axes, polearms, swords, daggers
    blunt = { [4] = true, [5] = true, [10] = true, [13] = true },                        -- maces, staves, fist weapons
}
local FISHING_POLE = 20
local HANDS = { { slot = 16, name = "main hand" }, { slot = 17, name = "off hand" } }

-- Forever's camp items by profession, lowest tier first; Cooking's are the
-- campfire kits. The label is the icon's, so it is kept short.
-- ponytail: hand-kept from wowsod.pro and wow-professions.com (November 2026),
-- which give item IDs only for the kits, each profession's skill 20 item, the
-- Alchemy Laboratory, and the Tanning Rack. The other skill 140 and 300 items
-- are missing until their IDs are known; add them here.
local CAMP_KIT = 279981
local CAMP = {
    { label = "Cooking", items = { CAMP_KIT, 279961, 279974 } }, -- Basic, Journeyman, Expert Campfire Kit
    { label = "First Aid", items = { 279968 } },                 -- First Aid Kit
    { label = "Fishing", items = { 279967 } },                   -- Fish Bowl
    { label = "Alchemy", items = { 279956, 279990 } },           -- Mana Well, Alchemy Laboratory
    { label = "Smithing", items = { 279944 } },                  -- Sharpening Wheel
    { label = "Enchanting", items = { 279976 } },                -- Enchanted Lute
    { label = "Engineer", items = { 279950 } },                  -- Reagent Bot
    { label = "Leather", items = { 279978, 279941 } },           -- Camp Tent, Tanning Rack
    { label = "Tailoring", items = { 279973, 279972 } },         -- Alliance or Horde Faction Banner
    { label = "Herbalism", items = { 279962 } },                 -- Incense Candle
    { label = "Mining", items = { 279960 } },                    -- Lodestone
    { label = "Skinning", items = { 279979 } },                  -- Camp Chair
}

-- Only asked out of combat, where the player's own auras are readable; a
-- secret answer counts as buffed so the reminder stays quiet. Forever's Well
-- Fed spells are asked for by ID, any other by the name they all share.
local function HasBuff()
    for _, spellID in ipairs(WELL_FED) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if IsSecret(aura) or aura ~= nil then return true end
    end
    local name, byName = SpellName(WELL_FED_NAME), C_UnitAuras.GetAuraDataBySpellName
    local aura = name and byName and byName("player", name)
    return IsSecret(aura) or aura ~= nil
end

-- The level a buff food needs, or nothing for any other item. A food not in
-- FOODS is a consumable whose use spell's text names Well Fed.
-- ponytail: a plain lowercase match on the buff's name, which fits English
-- ("you will become well fed"); a language that words the text differently
-- finds no foods. Read the Well Fed spell the food triggers if that matters.
local textFoods = {} -- item ID = true or false, once the spell text has loaded
local function FoodLevel(itemID)
    if FOODS[itemID] then return FOODS[itemID] end
    if textFoods[itemID] == nil then
        local _, spellID = GetItemSpell(itemID)
        local name = SpellName(WELL_FED_NAME)
        if not spellID or select(6, GetItemInfoInstant(itemID)) ~= 0 then
            textFoods[itemID] = false
        elseif name and GetSpellDescription then
            local text = GetSpellDescription(spellID)
            -- Empty until the client has loaded the spell; asked again next time.
            if text and text ~= "" then textFoods[itemID] = text:lower():find(name:lower(), 1, true) ~= nil end
        end
    end
    return textFoods[itemID] and (select(5, GetItemInfo(itemID)) or 0)
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

-- The bag items `Rank` gives a number for, highest first, and the one to show:
-- the picked item while the bags hold it, otherwise the first.
local function FindItems(Rank, picked)
    local ranks, items = {}, {}
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and ranks[itemID] == nil then
                ranks[itemID] = Rank(itemID) or false
                if ranks[itemID] then items[#items + 1] = itemID end
            end
        end
    end
    table.sort(items, function(a, b)
        if ranks[a] ~= ranks[b] then return ranks[a] > ranks[b] end
        return a < b
    end)
    return items, picked and ranks[picked] and picked or items[1]
end

-- The reminders share one bar: the shown icons sit side by side in setup order,
-- and dragging any of them moves the bar (position in
-- `db.global.remindersPosition`). It holds secure buttons, so it only moves or
-- lays out out of combat.
local BAR_GAP = 12 -- room for the labels under neighboring icons
local bar, barIcons
-- The page switch, set up with the camp items (Forever only).
local toggle

-- The page the bar shows: "buffs" or "camp" (saved as nil or "camp").
local function CampOn() return toggle and ScarletUI.db.global.campReminderModule.enabled end
local function Page() return CampOn() and ScarletUI.db.global.remindersPage or "buffs" end

local function PlaceBar()
    if InCombatLockdown() then return end
    local position = ScarletUI.db.global.remindersPosition
    bar:ClearAllPoints()
    if position then
        bar:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else
        bar:SetPoint("LEFT", UIParent, "CENTER", -ICON_SIZE / 2, 150)
    end
end

local function LayOutBar()
    if InCombatLockdown() then return end
    local page, x, any = Page(), 0, false
    for _, icon in ipairs(barIcons) do any = any or icon.active end
    -- The switch leads the bar while either page has an icon to show.
    if toggle then
        toggle:SetShown(CampOn() and any)
        if toggle:IsShown() then
            toggle:ClearAllPoints()
            toggle:SetPoint("LEFT", bar, "LEFT", 0, 0)
            toggle.Draw()
            x = ICON_SIZE + BAR_GAP
        end
    end
    for _, icon in ipairs(barIcons) do
        icon:SetShown(icon.active and icon.page == page)
        if icon:IsShown() then
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", bar, "LEFT", x, 0)
            x = x + ICON_SIZE + BAR_GAP
        end
    end
    bar:SetWidth(math.max(ICON_SIZE, x - BAR_GAP))
end

local function CreateBar()
    bar, barIcons = CreateFrame("Frame", "ScarletUIReminders", UIParent), {}
    bar:SetSize(ICON_SIZE, ICON_SIZE)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    -- Each icon had its own position before they shared the bar; the food
    -- icon's, the one there was for longest, becomes the bar's.
    local global = ScarletUI.db.global
    if global.xpFoodModule.position then
        global.remindersPosition, global.xpFoodModule.position = global.xpFoodModule.position, nil
    end
end

-- Dragging any icon on the bar moves it; Ctrl-click puts it back.
local function MakeHandle(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() bar:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        bar:StopMovingOrSizing()
        local point, _, relativePoint, x, y = bar:GetPoint()
        ScarletUI.db.global.remindersPosition = { point, relativePoint, x, y }
    end)
end

local function ResetBar()
    ScarletUI.db.global.remindersPosition = nil
    PlaceBar()
end

-- A plain button: it only changes which secure icons LayOutBar shows, which
-- waits for the end of combat. It shows the page a click switches to.
local function CreateToggle()
    toggle = ScarletUI:CreateIconButton(UIParent, ICON_SIZE, "ScarletUIRemindersPage")
    toggle:Hide()
    local label = toggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", toggle, "BOTTOM", 0, -4)
    function toggle.Draw()
        if Page() == "camp" then
            label:SetText("Buffs")
            toggle.texture:SetTexture(SpellTexture(WELL_FED_NAME))
        else
            label:SetText("Camp")
            toggle.texture:SetTexture((select(5, GetItemInfoInstant(CAMP_KIT))))
        end
    end
    MakeHandle(toggle)
    toggle:RegisterForClicks("LeftButtonUp")
    toggle:SetScript("OnClick", function()
        if IsControlKeyDown() then return ResetBar() end
        ScarletUI.db.global.remindersPage = Page() == "buffs" and "camp" or nil
        LayOutBar()
    end)
    toggle:SetScript("OnEnter", function()
        GameTooltip:SetOwner(toggle, "ANCHOR_RIGHT")
        GameTooltip:SetText(Page() == "camp" and "Show buff reminders" or "Show camp items")
        GameTooltip:AddLine("Drag to move the reminders. Ctrl-click to reset their position.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
end

-- One reminder icon on the bar. `spec` has the frame `name`, the `label` under it,
-- the tooltip lines `hint` and `pickHint`,
-- `Settings()` returning its saved table (enabled), `Find(settings)`
-- returning the usable items, the one to show, the macro that uses it, and
-- optionally a hint for it, and `Pick(settings, itemID)` for a click in the
-- list. Optional: `page` ("camp" for the camp page, "buffs" otherwise), `events`, `unitEvents`,
-- `OnEvent(event, ...)` returning true when no update should follow, and `OnHide()`.
-- The icon gets `Place()`, `Update()`, and `items`, the list as last drawn.
local function CreateReminder(spec)
    -- An item's icon and stack count, with its item tooltip and hints below it.
    local function ItemButton(parent, hint, note, name, template)
        local button = ScarletUI:CreateIconButton(parent, ICON_SIZE, name, template)
        button.hint = hint
        button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        button.count:SetPoint("BOTTOMRIGHT", -2, 2)
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. button.itemID)
            GameTooltip:AddLine(button.hint, 0, 1, 0, true)
            if note then GameTooltip:AddLine(note, 0.6, 0.6, 0.6, true) end
            GameTooltip:Show()
        end)
        return button
    end

    local function ShowItem(button, itemID)
        button.itemID = itemID
        button.texture:SetTexture((select(5, GetItemInfoInstant(itemID))))
        button.count:SetText(GetItemCount(itemID))
    end

    -- Right-click runs the secure macro that uses the item shown.
    if not bar then CreateBar() end
    local icon = ItemButton(UIParent, spec.hint, "Drag to move the reminders. Ctrl-click to reset their position.",
        spec.name, "SecureActionButtonTemplate")
    barIcons[#barIcons + 1] = icon
    icon.items = {}
    icon:RegisterForClicks("AnyUp")
    icon:SetAttribute("useOnKeyDown", false)
    icon:SetAttribute("type2", "macro")
    local combat = InCombatLockdown()
    local label = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -4)
    label:SetText(spec.label)

    -- Left-click opens the usable items in the bags, stacked upward from the icon.
    local list = CreateFrame("Frame", nil, icon)
    list:SetAllPoints(icon)
    list:Hide()
    local listButtons, away = {}, 0
    -- The open list closes once the mouse has been off the items for a moment.
    list:SetScript("OnUpdate", function(_, elapsed)
        local over = icon:IsMouseOver()
        for _, button in ipairs(listButtons) do
            over = over or button:IsShown() and button:IsMouseOver()
        end
        away = over and 0 or away + elapsed
        if away >= LIST_CLOSE_DELAY then list:Hide() end
    end)

    icon.Place = PlaceBar
    icon.page = spec.page or "buffs"
    icon.active = false
    MakeHandle(icon)
    -- OnClick belongs to the secure template, so our clicks are read after it.
    icon:SetScript("PostClick", function(_, button)
        if button ~= "LeftButton" then return end
        if IsControlKeyDown() then return ResetBar() end
        away = 0
        list:SetShown(not list:IsShown())
    end)

    function icon.Update()
        -- Hidden on entering combat; nothing on a secure button may change until it ends.
        if combat or InCombatLockdown() then return end
        local settings = spec.Settings()
        local items, shown, macro, hint
        -- The dead and ghosts cannot use items.
        if settings.enabled and not UnitIsDeadOrGhost("player") then
            items, shown, macro, hint = spec.Find(settings)
        end
        icon.items = items or {}
        -- Whether it has something to show; LayOutBar shows it on its page.
        icon.active = shown ~= nil
        LayOutBar()
        if not shown then
            list:Hide()
            if spec.OnHide then spec.OnHide() end
            return
        end
        ShowItem(icon, shown)
        icon.hint = hint or spec.hint
        icon:SetAttribute("macrotext2", macro)
        for index, itemID in ipairs(icon.items) do
            local button = listButtons[index]
            if not button then
                button = ItemButton(list, spec.pickHint)
                listButtons[index] = button
                button:SetPoint("BOTTOM", icon, "TOP", 0, ICON_GAP + (index - 1) * (ICON_SIZE + ICON_GAP))
                button.applied = button:CreateTexture(nil, "OVERLAY")
                button.applied:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                button.applied:SetBlendMode("ADD")
                button.applied:SetAllPoints()
                button:SetScript("OnClick", function()
                    spec.Pick(spec.Settings(), button.itemID)
                    list:Hide()
                    icon.Update()
                end)
            end
            ShowItem(button, itemID)
            button:Show()
            -- The highlight marks the item the icon shows and uses.
            button.applied:SetShown(itemID == shown)
        end
        for index = #icon.items + 1, #listButtons do listButtons[index]:Hide() end
    end

    -- Hidden frames still receive events.
    icon:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Fires before the combat lockdown, so the button can still hide.
            list:Hide()
            icon:Hide()
            -- Not shown again by another icon's layout until its own update after combat.
            icon.active = false
            if toggle then toggle:Hide() end
            if spec.OnHide then spec.OnHide() end
            combat = true
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            combat = false
        elseif spec.OnEvent and spec.OnEvent(event, ...) then
            return
        end
        icon.Update()
    end)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED", "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED", "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
        icon:RegisterEvent(event)
    end
    for _, event in ipairs(spec.events or {}) do icon:RegisterEvent(event) end
    for _, event in ipairs(spec.unitEvents or {}) do icon:RegisterUnitEvent(event, "player") end
    return icon
end

function ScarletUI:SetupXPFood()
    if self.xpFoodFrame then
        -- Setup reruns after a settings reset.
        self:PlaceXPFood()
        self:UpdateXPFood()
        return
    end
    if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return end

    -- When Well Fed is due, and whether the Food or Drink aura has been seen
    -- since: only an aura that was there and went means the meal was cut short.
    local icon, timer, wellFedAt, sawEating
    local function StopEating()
        wellFedAt, sawEating = nil, nil
        timer:Hide()
    end

    icon = CreateReminder({
        name = "ScarletUIXPFood",
        label = "Food",
        hint = "Right-click to eat. Left-click to choose a food.",
        pickHint = "Click to pick this. Click it again to show the best food.",
        Settings = function() return self.db.global.xpFoodModule end,
        -- The buff foods the character can eat, highest required level first.
        Find = function(settings)
            if HasBuff() then return end
            local level = UnitLevel("player")
            local foods, shown = FindItems(function(itemID)
                local required = FoodLevel(itemID)
                return required and required <= level and required
            end, settings.food)
            return foods, shown, shown and "/use item:" .. shown
        end,
        -- Clicking the picked food again goes back to the best one.
        Pick = function(settings, itemID)
            settings.food = settings.food ~= itemID and itemID or nil
        end,
        events = { "PLAYER_LEVEL_UP" },
        unitEvents = { "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED" },
        OnEvent = function(event, _, _, spellID)
            if event == "UNIT_SPELLCAST_SUCCEEDED" then
                -- Eating a listed food (the player's own casts are not secret)
                -- starts the countdown. The icon is hidden in combat, where nobody eats.
                for _, itemID in ipairs(icon:IsShown() and icon.items or {}) do
                    if select(2, GetItemSpell(itemID)) == spellID then
                        wellFedAt, sawEating = GetTime() + EAT_TIME, nil
                        timer:Show()
                        break
                    end
                end
                return true
            elseif event == "UNIT_AURA" and wellFedAt then
                if HasEatingAura() then
                    sawEating = true
                elseif sawEating then
                    StopEating()
                end
            end
        end,
        OnHide = StopEating,
    })
    self.xpFoodFrame = icon

    -- While a food is being eaten, the Well Fed icon counting down to the
    -- buff covers the food. Not a secure frame, so it may show and hide at any time.
    timer = CreateFrame("Frame", nil, icon)
    timer:SetAllPoints(icon)
    timer:Hide()
    local buff = timer:CreateTexture(nil, "BACKGROUND")
    buff:SetAllPoints()
    buff:SetTexture(SpellTexture(WELL_FED[1]) or SpellTexture(WELL_FED_NAME)) -- every Well Fed shares the icon
    timer.text = timer:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    timer.text:SetPoint("CENTER")
    timer:SetScript("OnUpdate", function()
        local left = wellFedAt - GetTime()
        if left <= 0 then return StopEating() end
        timer.text:SetText(math.ceil(left))
    end)

    function self:PlaceXPFood() icon.Place() end
    function self:UpdateXPFood() icon.Update() end
    icon.Place()
    icon.Update()
end

function ScarletUI:SetupWeaponReminder()
    if self.weaponReminderFrame then
        -- Setup reruns after a settings reset.
        self:PlaceWeaponReminder()
        self:UpdateWeaponReminder()
        return
    end
    -- Mists and Retail have other items, or none.
    local version = self:GetWoWVersion()
    if version ~= "FOREVER" and version ~= "VANILLA" and version ~= "TBC" then return end

    -- The hand the icon is for, and the timer for the next enchant to run out:
    -- nothing is known to fire when one does.
    local icon, slot, expiry
    icon = CreateReminder({
        name = "ScarletUIWeaponReminder",
        label = "Weapon",
        pickHint = "Click to pick this. Click it again to show the best one.",
        Settings = function() return self.db.global.weaponReminderModule end,
        -- The first hand holding a weapon with no temporary enchant that an
        -- enhancement in the bags fits, highest required level first.
        Find = function(settings)
            local enchants = { GetWeaponEnchantInfo() }
            if expiry then expiry:Cancel() end
            expiry = nil
            -- Unreadable counts as enchanted, so the reminder stays quiet.
            if IsSecret(enchants[1]) or IsSecret(enchants[5]) then return end
            -- Main hand first; an off hand's fields follow the main hand's four.
            local soonest
            for index, hand in ipairs(HANDS) do
                local enchanted, left = enchants[index * 4 - 3], enchants[index * 4 - 2]
                if enchanted and left and (not soonest or left < soonest) then soonest = left end
                hand.enchanted = enchanted
            end
            if soonest then expiry = C_Timer.NewTimer(soonest / 1000 + 1, icon.Update) end

            local level, _, class = UnitLevel("player"), UnitClass("player")
            for _, hand in ipairs(HANDS) do
                local weapon = not hand.enchanted and GetInventoryItemID("player", hand.slot)
                if weapon then
                    local _, _, _, _, _, classID, subclass = GetItemInfoInstant(weapon)
                    -- A weapon (class 2), not a shield or held item.
                    local items, shown = {}, nil
                    if classID == 2 and subclass ~= FISHING_POLE then
                        items, shown = FindItems(function(itemID)
                            local kind = ENHANCEMENTS[itemID]
                            if not kind or kind == "poison" and class ~= "ROGUE" then return end
                            if STONE_FITS[kind] and not STONE_FITS[kind][subclass] then return end
                            local required = select(5, GetItemInfo(itemID)) or 0
                            return required <= level and required
                        end, settings.items[hand.slot])
                    end
                    if shown then
                        slot = hand.slot
                        return items, shown, "/use item:" .. shown .. "\n/use " .. slot,
                            "Right-click to apply to your " .. hand.name .. ". Left-click to choose another."
                    end
                end
            end
        end,
        -- Picked per hand. Clicking the picked item again goes back to the best one.
        Pick = function(settings, itemID)
            settings.items[slot] = settings.items[slot] ~= itemID and itemID or nil
        end,
        events = { "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP" },
        unitEvents = { "UNIT_INVENTORY_CHANGED" },
    })
    self.weaponReminderFrame = icon

    function self:PlaceWeaponReminder() icon.Place() end
    function self:UpdateWeaponReminder() icon.Update() end
    icon.Place()
    icon.Update()
end

-- One icon per profession on the camp page, for its camp items in the bags.
function ScarletUI:SetupCampReminders()
    if self.campReminderFrames then
        -- Setup reruns after a settings reset.
        self:UpdateCampReminders()
        return
    end
    if self:GetWoWVersion() ~= "FOREVER" then return end

    CreateToggle()
    local icons = {}
    for _, profession in ipairs(CAMP) do
        local tier = {}
        for index, itemID in ipairs(profession.items) do tier[itemID] = index end
        icons[#icons + 1] = CreateReminder({
            name = "ScarletUICamp" .. profession.label:gsub("%W", ""),
            label = profession.label,
            page = "camp",
            hint = "Right-click to use it. Left-click to choose another.",
            pickHint = "Click to pick this. Click it again to show the best one.",
            Settings = function() return self.db.global.campReminderModule end,
            -- The highest tier in the bags first.
            Find = function(settings)
                local items, shown = FindItems(function(itemID) return tier[itemID] end, settings.items[profession.label])
                return items, shown, shown and "/use item:" .. shown
            end,
            -- Picked per profession. Clicking the picked item again goes back to the best one.
            Pick = function(settings, itemID)
                settings.items[profession.label] = settings.items[profession.label] ~= itemID and itemID or nil
            end,
        })
    end
    self.campReminderFrames = icons

    function self:UpdateCampReminders()
        for _, icon in ipairs(icons) do icon.Update() end
    end
    self:UpdateCampReminders()
end
