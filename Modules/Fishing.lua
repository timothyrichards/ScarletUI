-- Fishing mode: while a fishing pole is in the main hand, one key (Space by
-- default) casts Fishing, and for the length of the cast the same key is
-- Interact With Target, which hooks the bobber. With no lure on the pole, the
-- key applies the best lure in the bags first. The key keeps its normal action
-- in combat and while moving, since neither allows fishing.
-- Everything protected goes through a secure button and override bindings,
-- which can only change out of combat.
local BUTTON = "ScarletUIFishingButton"
local WEAPON, FISHING_POLE, MAIN_HAND = 2, 20, 16
local FISHING = 7620 -- every rank shares this spell's name
local IsSecret = issecretvalue or function() return false end
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

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

local function BestLure()
    local best, bestBag, bestSlot = 0, nil, nil
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local bonus = LURES[C_Container.GetContainerItemID(bag, slot)]
            if bonus and bonus > best then
                best, bestBag, bestSlot = bonus, bag, slot
            end
        end
    end
    return bestBag, bestSlot
end

function ScarletUI:SetupFishing()
    if self.fishingFrame then
        -- Setup reruns after a settings reset.
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
            -- The enchant shows up a moment after the lure cast succeeds.
            local wanted = self.db.global.fishingModule.autoLure and not GetWeaponEnchantInfo()
                and GetTime() - lastCast > 1
            local bag, slot = nil, nil
            if wanted then bag, slot = BestLure() end
            -- ponytail: a lure that cannot be used (skill too low) would block
            -- fishing, so a press after a failed lure casts instead. That wastes
            -- every other press; compare skill requirements if it comes up.
            if bag and not lureTried then
                lureTried = true
                macro = "/use " .. bag .. " " .. slot .. "\n/use " .. MAIN_HAND
            else
                lureTried = false
            end
        end
        button:SetAttribute("macrotext", macro)
    end)

    local function RestoreCVars()
        for name, value in pairs(savedCVars) do
            SetCVar(name, value)
            savedCVars[name] = nil
        end
    end

    function self:UpdateFishing()
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
        "PLAYER_REGEN_ENABLED", "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING", "PLAYER_LOGOUT" }) do
        frame:RegisterEvent(event)
    end
    for _, event in ipairs({ "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED" }) do
        frame:RegisterUnitEvent(event, "player")
    end
    self:UpdateFishing()
end
