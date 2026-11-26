-- Small visibility tweaks for Blizzard frames. Showing and hiding textures and
-- unprotected frames is stored by the client, so it does not taint.

function ScarletUI:SetupMicroMenuArt()
    local menu = MicroMenu
    if not (menu and menu.BackgroundArt and menu.BorderArt) then return end
    local shown = not self.db.global.hideMicroMenuArt
    menu.BackgroundArt:SetShown(shown)
    menu.BorderArt:SetShown(shown)
end

-- Temporary fix for Forever: GamepadBagBar only hides its bag buttons when
-- Gamepad UI is on, so they appear on the combined backpack when it is off.
-- Blizzard never shows or hides the bar itself, so it is safe to own.
local function UpdateGamepadBagBar()
    GamepadBagBar:SetShown(InputUtil.IsGamepadUIEnabled())
end

-- The Cooldown Manager hides an inactive tracked buff but keeps its slot, which
-- leaves gaps between the buff icons and bars. After each Blizzard layout this
-- records where every slot sits, then moves the shown items into the slots at
-- one end. Items are plain pooled frames, so moving them is allowed in combat.
-- State stays in these locals: fields written onto Blizzard's frames taint them.
local viewerSlots, hookedItems = {}, setmetatable({}, { __mode = "k" })

local function PackBuffs(viewer)
    local slots = viewerSlots[viewer]
    local first, last = slots[1], slots[#slots]
    if not first then return end
    local mode = ScarletUI.db.global.collapseInactiveBuffs
    local shown = {}
    for item in viewer.itemFramePool:EnumerateActive() do
        if item:IsShown() and slots[item.layoutIndex] then shown[#shown + 1] = item end
    end
    table.sort(shown, function(a, b) return a.layoutIndex < b.layoutIndex end)
    -- Slot 1 is leftmost or topmost unless Edit Mode reverses the icon direction.
    local firstIsStart = first[4] < last[4] or (first[4] == last[4] and first[5] >= last[5])
    local shift = (mode == "START") == firstIsStart and 0 or #slots - #shown
    for i, item in ipairs(shown) do
        local slot = slots[mode == "OFF" and item.layoutIndex or i + shift]
        if slot then
            item:ClearAllPoints()
            item:SetPoint(unpack(slot, 1, 5))
        end
    end
end

-- Blizzard has just anchored every item, hidden ones included, to its own slot.
local function OnBuffLayout(viewer)
    local slots = {}
    for item in viewer.itemFramePool:EnumerateActive() do
        if item.layoutIndex and item:GetPoint(1) then
            slots[item.layoutIndex] = { item:GetPoint(1) }
        end
        if not hookedItems[item] then
            hookedItems[item] = true
            -- Buffs starting and ending show and hide items without a new layout.
            item:HookScript("OnShow", function() PackBuffs(viewer) end)
            item:HookScript("OnHide", function() PackBuffs(viewer) end)
        end
    end
    viewerSlots[viewer] = slots
    PackBuffs(viewer)
end

function ScarletUI:IsBuffCollapseSupported()
    local viewer = BuffIconCooldownViewer
    return viewer and viewer.itemFramePool and viewer.Layout and true or false
end

function ScarletUI:SetupBuffCollapse()
    if not self:IsBuffCollapseSupported() then return end
    for _, name in ipairs({ "BuffIconCooldownViewer", "BuffBarCooldownViewer" }) do
        local viewer = _G[name]
        if viewer and viewerSlots[viewer] then
            PackBuffs(viewer)
        elseif viewer and viewer.itemFramePool and self.db.global.collapseInactiveBuffs ~= "OFF" then
            -- Hooked on first use, so the viewers stay untouched while this is off.
            hooksecurefunc(viewer, "Layout", OnBuffLayout)
            OnBuffLayout(viewer)
        end
    end
end

-- Right-click on a bag's portrait opens the cached bank. The portrait is a
-- DropdownButton, which registers only for left-button mouse events, so a hook
-- on it never sees a right-click. A child overlay takes the right-click and
-- passes left-clicks and mouse motion through, so Blizzard's bag menu and
-- tooltip still work and none of their code runs from ours.
local function AddPortraitOverlay(portrait)
    local overlay = CreateFrame("Button", nil, portrait)
    overlay:SetAllPoints(portrait)
    overlay:RegisterForClicks("RightButtonUp")
    overlay:SetPassThroughButtons("LeftButton")
    overlay:SetPropagateMouseMotion(true)
    overlay:SetScript("OnClick", function(_, mouse)
        if ScarletUI.debugContainer and ScarletUI.debugContainer:IsShown() then
            ScarletUI:Print("Bag portrait click: " .. tostring(mouse))
        end
        if mouse == "RightButton" then ScarletUI:ToggleBankFromUI() end
    end)
    portrait:HookScript("OnEnter", function()
        GameTooltip:AddLine("Right-click: open bank")
        GameTooltip:Show()
    end)
end

function ScarletUI:SetupBagPortraitHooks()
    if self.bagPortraitsHooked then return end
    -- The pass-through setters are protected; wait for combat to end.
    if InCombatLockdown() then
        if not self.bagPortraitsWaiting then
            self.bagPortraitsWaiting = true
            self:RegisterEventHandler("PLAYER_REGEN_ENABLED", function() self:SetupBagPortraitHooks() end)
        end
        return
    end
    self.bagPortraitsHooked = true
    local frames = { ContainerFrameCombinedBags }
    for i = 1, 13 do frames[#frames + 1] = _G["ContainerFrame" .. i] end
    for _, frame in pairs(frames) do
        local portrait = frame.PortraitButton
        if portrait and portrait.SetPassThroughButtons then AddPortraitOverlay(portrait) end
    end
end

-- Auto Shot clipping window (Forever, hunters): the last 0.5s of each ranged swing
-- is Auto Shot's windup, and moving then cancels the shot. Forever's Auto Shot
-- (spell 75) data matches Classic Era's, where that windup is server-side.
-- A band over the end of Blizzard's ranged swing timer (our own texture on its
-- StatusBar, which dims with it out of range) marks that window.
local AUTO_SHOT_WINDUP = 0.5
local IsSecret = issecretvalue or function() return false end

-- The share of a ranged swing of `swing` seconds that the windup takes, with
-- `haste` percent ranged haste shortening the windup.
-- ponytail: haste scaling of the windup is assumed from Classic, unchecked in game.
function ScarletUI.AutoShotClip(swing, haste)
    if not swing or swing <= 0 then return 0 end
    return math.min(1, AUTO_SHOT_WINDUP / (1 + (haste or 0) / 100) / swing)
end

function ScarletUI:SetupAutoShotClip()
    local bar = SwingTimerRangedFrame and SwingTimerRangedFrame.StatusBar
    if self.autoShotClipBand or not bar or select(2, UnitClass("player")) ~= "HUNTER" then return end
    local band = bar:CreateTexture(nil, "OVERLAY", nil, -1) -- under the pip and labels
    self.autoShotClipBand = band
    band:SetColorTexture(1, 0.1, 0.1, 0.35)
    band:SetPoint("TOPRIGHT")
    band:SetPoint("BOTTOMRIGHT")
    local swing -- the ranged swing the bar is timing, or the next one
    local function Update()
        local haste, quiver = GetRangedHaste()
        if IsSecret(swing) or IsSecret(haste) or IsSecret(quiver) then return end
        local share = ScarletUI.AutoShotClip(swing, (haste or 0) + (quiver or 0))
        band:SetWidth(math.max(1, bar:GetWidth() * share))
        band:SetShown(ScarletUI.db.global.autoShotClip and share > 0)
    end
    self.UpdateAutoShotClip = Update
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SWING")
    frame:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
    frame:RegisterUnitEvent("UNIT_RANGEDDAMAGE", "player")
    frame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    frame:SetScript("OnEvent", function(_, event, duration, swingType)
        if event == "PLAYER_SWING" then
            if IsSecret(swingType) or swingType ~= 2 then return end -- ranged
            swing = duration
        else
            swing = select(3, UnitAttackSpeed("player"))
        end
        Update()
    end)
    bar:HookScript("OnSizeChanged", Update)
    swing = select(3, UnitAttackSpeed("player"))
    Update()
end

-- Hunter dead zone (Forever): the target is out of melee range but inside Auto
-- Shot's 8 yd minimum. Auto Shot (spell 75, 8-35 yd) reads out of range there
-- and past 35 yd alike; the trade interact distance (index 2: 11 yd on Classic,
-- 8 on Retail) tells the two apart. Melee range is the main-hand swing check,
-- or Raptor Strike's range without a melee weapon. The ranged swing timer gets
-- a red tint and a label, on our own frame so the bar's out-of-range dimming
-- (on its StatusBar) doesn't fade it. Polled only while the target is hostile.
local DEAD_ZONE_POLL = 0.1
local AUTO_SHOT, RAPTOR_STRIKE, TRADE_DISTANCE = 75, 2973, 2
-- Retail blocked CheckInteractDistance in combat (10.2.0), then allowed enemy
-- units again (2023-12-11 hotfix). Should Forever still block it, the first
-- ADDON_ACTION_BLOCKED for it stops in-combat calls, so polling can't spam them.
local distanceBlocked = false

local function Known(value)
    if IsSecret(value) then return nil end
    return value
end

local function HostileTarget()
    return Known(UnitCanAttack("player", "target")) and not Known(UnitIsDeadOrGhost("target"))
end

function ScarletUI.TargetInDeadZone()
    if not HostileTarget() then return false end
    local melee = C_SwingTimer and C_SwingTimer.IsTargetWithinSwingRange
        and Known(C_SwingTimer.IsTargetWithinSwingRange(0)) -- main hand
    if melee == nil then
        local name = C_Spell.GetSpellName(RAPTOR_STRIKE) -- the rank the player knows
        melee = name and Known(C_Spell.IsSpellInRange(name, "target"))
    end
    local shot = Known(C_Spell.IsSpellInRange(AUTO_SHOT, "target"))
    -- Unknown readings (nil, secret) never count as out of range.
    if melee ~= false or shot ~= false then return false end
    if distanceBlocked and InCombatLockdown() then return false end
    return Known(CheckInteractDistance("target", TRADE_DISTANCE)) == true
end

function ScarletUI:SetupHunterDeadZone()
    local timer = SwingTimerRangedFrame
    local bar = timer and timer.StatusBar
    if self.hunterDeadZoneOverlay or not bar or select(2, UnitClass("player")) ~= "HUNTER" then return end
    local overlay = CreateFrame("Frame", nil, timer)
    self.hunterDeadZoneOverlay = overlay
    overlay:SetAllPoints(bar)
    overlay:SetFrameLevel(bar:GetFrameLevel() + 5)
    overlay:Hide()
    local tint = overlay:CreateTexture(nil, "ARTWORK")
    tint:SetAllPoints()
    tint:SetColorTexture(1, 0.1, 0.1, 0.55)
    local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText("Dead zone")

    local poll, waited = CreateFrame("Frame"), 0
    local function Check() overlay:SetShown(ScarletUI.TargetInDeadZone()) end
    local function OnUpdate(_, elapsed)
        waited = waited + elapsed
        if waited < DEAD_ZONE_POLL then return end
        waited = 0
        Check()
    end
    local function Update()
        local on = ScarletUI.db.global.hunterDeadZone and HostileTarget()
        poll:SetScript("OnUpdate", on and OnUpdate or nil)
        if on then Check() else overlay:Hide() end
    end
    self.UpdateHunterDeadZone = Update
    poll:RegisterEvent("PLAYER_TARGET_CHANGED")
    poll:RegisterUnitEvent("UNIT_FACTION", "target")
    poll:RegisterEvent("ADDON_ACTION_BLOCKED")
    poll:SetScript("OnEvent", function(_, event, addon, func)
        if event ~= "ADDON_ACTION_BLOCKED" then return Update() end
        if addon == "ScarletUI" and type(func) == "string" and func:find("CheckInteractDistance", 1, true) then
            distanceBlocked = true
        end
    end)
    Update()
end

function ScarletUI:SetupFrameTweaks()
    self:SetupMicroMenuArt()
    self:SetupBuffCollapse()
    self:SetupBagPortraitHooks()
    if not self.gamepadBagBarHooked and GamepadBagBar and InputUtil and ContainerFrameCombinedBags then
        self.gamepadBagBarHooked = true
        UpdateGamepadBagBar()
        -- No event fires when Gamepad UI is toggled, so check whenever the bags open.
        ContainerFrameCombinedBags:HookScript("OnShow", UpdateGamepadBagBar)
    end
    -- Last, so a failure in the newest tweak can't block the others.
    self:SetupAutoShotClip()
    self:SetupHunterDeadZone()
end
