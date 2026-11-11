-- Fishing mode: while a fishing pole is in the main hand, one key (Space by
-- default) casts Fishing, and for the length of the cast the same key is
-- Interact With Target, which hooks the bobber. With no lure on the pole, the
-- key applies a lure from the bags first. The key keeps its normal action in
-- combat and while moving, since neither allows fishing.
-- A small panel marks the mode while the pole is equipped: the addon's name over
-- the Fishing icon, the lure the key applies, which opens a list of the lures in
-- the bags, and the Fishing skill with its cap.
-- Everything protected goes through a secure button and override bindings,
-- which can only change out of combat; the bar itself only stores a choice.
local BUTTON = "ScarletUIFishingButton"
local WEAPON, FISHING_POLE, MAIN_HAND = 2, 20, 16
local FISHING = 7620 -- every rank shares this spell's name
local FISHING_SKILL = 356 -- skill line ID
local FISHING_ICON = "Interface\\Icons\\Trade_Fishing"
local ICON_SIZE, ICON_GAP = 32, 4
local PADDING, TITLE_HEIGHT, TEXT_GAP = 16, 22, 8 -- panel edge, title row, icons to skill text
local LIST_CLOSE_DELAY = 1 -- seconds the mouse may be off the open lure list
local NONE = 0 -- picked in place of an item ID: apply no lure
local IsSecret = issecretvalue or function() return false end
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
local GetItemCount = C_Item and C_Item.GetItemCount or GetItemCount

-- Item ID = fishing skill bonus.
-- ponytail: hand-kept list; a lure missing here is never applied. Read the
-- bonus from the item tooltip if new lures keep appearing.
local LURES = {
    [6529] = 25,   -- Shiny Bauble
    [6530] = 50,   -- Nightcrawlers
    [6811] = 50,   -- Aquadynamic Fish Lens
    [6532] = 75,   -- Bright Baubles
    [7307] = 75,   -- Flesh Eating Worm
    [6533] = 100,  -- Aquadynamic Fish Attractor
    [34861] = 100, -- Sharpened Fish Hook
    [46006] = 100, -- Glow Worm
    [62673] = 100, -- Feathered Lure
    [67404] = 15,  -- Glass Fishing Bobber
    [68049] = 150, -- Heat-Treated Spinning Lure
}

-- The bobber is only interactable through soft targeting, widened for the cast.
local INTERACT_CVARS = { SoftTargetInteract = "3", SoftTargetInteractArc = "2", SoftTargetInteractRange = "30" }

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return GetSpellInfo and (GetSpellInfo(spellID))
end

local function PoleEquipped()
    local itemID = GetInventoryItemID("player", MAIN_HAND)
    if not itemID then return false end
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)
    return classID == WEAPON and subclassID == FISHING_POLE
end

-- The Fishing skill's rank and cap, or nil while it is unknown.
local function FishingSkill()
    local info = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID and C_SkillInfo.GetSkillLineInfoByID(FISHING_SKILL)
    if info then return info.rank, info.maxRank end
    if GetProfessions then -- Mists has no skill list
        local _, _, _, fishing = GetProfessions()
        if not fishing then return end
        local _, _, rank, maxRank = GetProfessionInfo(fishing)
        return rank, maxRank
    end
    -- ponytail: Era and TBC only list skills by row, and a collapsed header
    -- hides its rows, so the skill reads as unknown while Secondary Skills is
    -- collapsed. Expand and re-collapse headers here if that comes up.
    for index = 1, GetNumSkillLines and GetNumSkillLines() or 0 do
        local name, _, _, rank, _, _, maxRank = GetSkillLineInfo(index)
        if name == SpellName(FISHING) then return rank, maxRank end
    end
end

-- Lures in the bags as itemID = { bag, slot } of one stack, and the one the key
-- applies: NONE if that was picked, the picked lure while the bags hold it,
-- otherwise the biggest bonus.
local function FindLures(picked)
    local found, best = {}, nil
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if LURES[itemID] and not found[itemID] then
                found[itemID] = { bag, slot }
                if not best or LURES[itemID] > LURES[best] then best = itemID end
            end
        end
    end
    return found, (picked == NONE or found[picked]) and picked or best
end

function ScarletUI:SetupFishing()
    if self.fishingFrame then
        -- Setup reruns after a settings reset.
        self:PlaceFishingBar()
        self:UpdateFishing()
        return
    end
    -- Retail fishing needs no pole in the main hand.
    if self:GetWoWVersion() == "RETAIL" then return end

    local frame = CreateFrame("Frame")
    self.fishingFrame = frame
    local combat, moving, fishing = InCombatLockdown(), IsPlayerMoving(), false
    local lastCast, lureTried = 0, false
    local savedCVars = {}

    local button = CreateFrame("Button", BUTTON, nil, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("type", "macro")
    -- Runs before the secure click; attributes can change here out of combat.
    button:SetScript("PreClick", function()
        if combat then return end
        local macro
        if UnitCastingInfo("player") then
            lureTried = false -- a lure is being applied; this press does nothing
        else
            macro = "/cast " .. SpellName(FISHING)
            local module = self.db.global.fishingModule
            -- The enchant shows up a moment after the lure cast succeeds.
            local wanted = module.autoLure and not GetWeaponEnchantInfo() and GetTime() - lastCast > 1
            local found, itemID = FindLures(module.lure)
            local lure = wanted and found[itemID]
            -- ponytail: a lure that cannot be used (skill too low) would block
            -- fishing, so a press after a failed lure casts instead. That wastes
            -- every other press; compare skill requirements if it comes up.
            if lure and not lureTried then
                lureTried = true
                macro = "/use " .. lure[1] .. " " .. lure[2] .. "\n/use " .. MAIN_HAND
            else
                lureTried = false
            end
        end
        button:SetAttribute("macrotext", macro)
    end)

    -- Blizzard's own art throughout, so the panel matches each client's dialogs
    -- and item slots: the border template fills its parent and draws below it.
    local bar = CreateFrame("Frame", "ScarletUIFishingBar", UIParent)
    CreateFrame("Frame", nil, bar, "DialogBorderDarkTemplate")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    function self:PlaceFishingBar()
        local position = self.db.global.fishingModule.position
        bar:ClearAllPoints()
        if position then
            bar:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        else
            bar:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
        end
    end
    self:PlaceFishingBar()

    local function IconButton(parent)
        return self:CreateIconButton(parent, ICON_SIZE)
    end

    -- A lure's icon and stack count, with its item tooltip and a hint below it.
    local function LureButton(parent, hint)
        local lure = IconButton(parent)
        lure.count = lure:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        lure.count:SetPoint("BOTTOMRIGHT", -2, 2)
        lure:SetScript("OnEnter", function()
            GameTooltip:SetOwner(lure, "ANCHOR_RIGHT")
            if lure.itemID == NONE then
                GameTooltip:AddLine("No Lure")
                GameTooltip:AddLine("The fishing key only casts Fishing.", 1, 1, 1, true)
            else
                GameTooltip:SetHyperlink("item:" .. lure.itemID)
            end
            GameTooltip:AddLine(hint, 0, 1, 0, true)
            GameTooltip:Show()
        end)
        return lure
    end

    -- NONE shows as an empty bag slot.
    local function ShowLure(lure, itemID)
        lure.itemID = itemID
        if itemID == NONE then
            lure.texture:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
            lure.count:SetText("")
        else
            lure.texture:SetTexture((select(5, GetItemInfoInstant(itemID))))
            lure.count:SetText(GetItemCount(itemID))
        end
        lure:Show()
    end

    -- The Fishing icon marks the mode and is the handle for dragging the bar.
    local handle = IconButton(bar)
    handle:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", PADDING, PADDING)
    handle.texture:SetTexture(FISHING_ICON)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() bar:StartMoving() end)
    handle:SetScript("OnDragStop", function()
        bar:StopMovingOrSizing()
        local point, _, relativePoint, x, y = bar:GetPoint()
        self.db.global.fishingModule.position = { point, relativePoint, x, y }
    end)
    handle:SetScript("OnEnter", function()
        local key = self.db.global.fishingModule.key
        GameTooltip:SetOwner(handle, "ANCHOR_TOP")
        GameTooltip:AddLine("Scarlet UI - Fishing Mode")
        GameTooltip:AddLine((GetBindingText and GetBindingText(key) or key)
            .. " casts Fishing, then hooks the bobber.", 1, 1, 1, true)
        GameTooltip:AddLine("Drag to move.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)

    -- Next to it, the lure the key applies. Clicking it opens a list of the
    -- lures in the bags and a no-lure entry, stacked upward from the panel's top.
    local current = LureButton(bar, "Click to choose a lure.")
    current:SetPoint("LEFT", handle, "RIGHT", ICON_GAP, 0)
    local list = CreateFrame("Frame", nil, bar)
    list:SetAllPoints(current)
    list:Hide()
    local listButtons, away = {}, 0
    current:SetScript("OnClick", function()
        away = 0
        list:SetShown(not list:IsShown())
    end)
    -- The open list closes once the mouse has been off the lures for a moment.
    list:SetScript("OnUpdate", function(_, elapsed)
        local over = current:IsMouseOver()
        for _, lure in ipairs(listButtons) do
            over = over or lure:IsShown() and lure:IsMouseOver()
        end
        away = over and 0 or away + elapsed
        if away >= LIST_CLOSE_DELAY then list:Hide() end
    end)

    -- Whose panel this is, above the icons; the Fishing skill and its cap beside them.
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", bar, "TOPLEFT", PADDING, -PADDING)
    title:SetText("Scarlet UI") -- the font's gold, as on Blizzard's own titles
    -- The cap is its own string so the rank's right edge can anchor the drop.
    local skill = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    local cap = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    cap:SetPoint("LEFT", skill, "RIGHT")

    -- A skill-up drifts up from the rank and fades, like a RuneScape XP drop.
    -- ponytail: one drop, restarted by the next skill-up; pool them if several
    -- ever need to be on screen at once.
    local drop = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    drop:SetTextColor(1, 1, 1)
    drop:SetPoint("BOTTOMRIGHT", skill, "TOPRIGHT", 0, 2)
    drop:Hide()
    local rise = drop:CreateAnimationGroup()
    local move = rise:CreateAnimation("Translation")
    move:SetOffset(0, 60)
    move:SetDuration(1.8)
    local fade = rise:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0)
    fade:SetStartDelay(1.2)
    fade:SetDuration(0.6)
    rise:SetScript("OnFinished", function() drop:Hide() end)
    local lastRank

    local function RefreshBar()
        local module = self.db.global.fishingModule
        local found, applied = FindLures(module.lure)
        local shown = module.enabled and PoleEquipped()
        local hasLure = shown and module.autoLure and applied
        bar:SetShown(shown)
        local rank, maxRank = FishingSkill()
        if rank and lastRank and rank > lastRank then
            drop:SetText("+" .. rank - lastRank)
            drop:Show()
            rise:Stop()
            rise:Play()
        end
        lastRank = rank or lastRank
        local known = rank and maxRank and maxRank > 0
        skill:SetText(known and SpellName(FISHING) .. " " .. rank or "")
        cap:SetText(known and "/" .. maxRank or "")
        current:SetShown(hasLure)
        -- The panel wraps the title, the icons, and the skill text.
        local icons = hasLure and ICON_SIZE * 2 + ICON_GAP or ICON_SIZE
        local text = skill:GetStringWidth() + cap:GetStringWidth()
        skill:SetPoint("LEFT", handle, "LEFT", icons + TEXT_GAP, 0)
        bar:SetSize(PADDING * 2 + math.max(title:GetStringWidth(), icons + (text > 0 and TEXT_GAP + text or 0)),
            PADDING * 2 + TITLE_HEIGHT + ICON_SIZE)
        if not hasLure then
            list:Hide()
            return
        end
        ShowLure(current, applied)
        local lures = {}
        for itemID in pairs(found) do lures[#lures + 1] = itemID end
        table.sort(lures, function(a, b)
            if LURES[a] ~= LURES[b] then return LURES[a] > LURES[b] end
            return a < b
        end)
        lures[#lures + 1] = NONE -- top of the list
        for index, itemID in ipairs(lures) do
            local lure = listButtons[index]
            if not lure then
                lure = LureButton(list, "Click to pick this. Click it again to use the best lure.")
                listButtons[index] = lure
                lure:SetPoint("BOTTOM", current, "TOP", 0,
                    TITLE_HEIGHT + PADDING + ICON_GAP + (index - 1) * (ICON_SIZE + ICON_GAP))
                lure.applied = lure:CreateTexture(nil, "OVERLAY")
                lure.applied:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                lure.applied:SetBlendMode("ADD")
                lure.applied:SetAllPoints()
                lure:SetScript("OnClick", function()
                    -- Clicking the picked lure again goes back to the best one.
                    local settings = self.db.global.fishingModule
                    settings.lure = settings.lure ~= lure.itemID and lure.itemID or nil
                    list:Hide()
                    RefreshBar()
                end)
            end
            ShowLure(lure, itemID)
            -- The highlight marks the lure the key applies.
            lure.applied:SetShown(itemID == applied)
        end
        for index = #lures + 1, #listButtons do listButtons[index]:Hide() end
    end

    local function RestoreCVars()
        for name, value in pairs(savedCVars) do
            SetCVar(name, value)
            savedCVars[name] = nil
        end
    end

    function self:UpdateFishing()
        RefreshBar() -- not protected, so it also follows changes made in combat
        if combat then return end
        ClearOverrideBindings(frame)
        local module = self.db.global.fishingModule
        local key = module.enabled and module.key ~= "" and module.key
        local active = key and not moving and PoleEquipped()
        if active and fishing then
            for name, value in pairs(INTERACT_CVARS) do
                local current = GetCVar(name)
                if current ~= nil then -- skip a CVar this client lacks
                    savedCVars[name] = savedCVars[name] or current
                    SetCVar(name, value)
                end
            end
            SetOverrideBinding(frame, true, key, "INTERACTTARGET")
            return
        end
        RestoreCVars()
        if active then
            SetOverrideBindingClick(frame, true, key, BUTTON)
        end
    end

    frame:SetScript("OnEvent", function(_, event, _, _, spellID)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Fires before the combat lockdown, so the key can still be released.
            ClearOverrideBindings(frame)
            combat = true
            return
        elseif event == "PLAYER_LOGOUT" then
            RestoreCVars()
            return
        elseif event == "BAG_UPDATE_DELAYED" or event == "SKILL_LINES_CHANGED" then
            RefreshBar()
            return
        elseif event == "UNIT_SPELLCAST_START" then
            lureTried = false
            return
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            lastCast = GetTime()
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            combat = false
        elseif event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then
            moving = event == "PLAYER_STARTED_MOVING"
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            fishing = not IsSecret(spellID) and SpellName(spellID) == SpellName(FISHING)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            fishing = false
        end
        self:UpdateFishing()
    end)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED", "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING", "PLAYER_LOGOUT",
        "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED" }) do
        frame:RegisterEvent(event)
    end
    for _, event in ipairs({ "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED" }) do
        frame:RegisterUnitEvent(event, "player")
    end
    self:UpdateFishing()
end
