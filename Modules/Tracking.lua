-- Shares the minimap tracking menu checkboxes across characters. Entries are
-- keyed by name; a character only receives entries it has (e.g. Find Herbs).
local GetNumTypes = C_Minimap and C_Minimap.GetNumTrackingTypes or GetNumTrackingTypes

local function GetTracking(index)
    if C_Minimap and C_Minimap.GetTrackingInfo then
        local info = C_Minimap.GetTrackingInfo(index)
        if info then return info.name, info.active end
    elseif GetTrackingInfo then
        local name, _, active = GetTrackingInfo(index)
        return name, active
    end
end

local function SetTracking(index, active)
    -- MinimapUtil also routes quest filters that Blizzard backs with settings.
    if MinimapUtil and MinimapUtil.SetTrackingFilterByFilterIndex then
        MinimapUtil.SetTrackingFilterByFilterIndex(index, active)
    elseif C_Minimap and C_Minimap.SetTracking then
        C_Minimap.SetTracking(index, active)
    else
        _G.SetTracking(index, active)
    end
end

-- Find Minerals and Find Herbs, kept on when enabled in settings. Classic rules
-- drop tracking on death, so they are turned back on at login and resurrection.
local ALWAYS_ON = { 2580, 2383 }

local function GetSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    return GetSpellInfo and (GetSpellInfo(spellID))
end

function ScarletUI:ApplyAlwaysOnTracking()
    if not GetNumTypes or UnitIsDeadOrGhost("player") then return end
    local alwaysOn = self.db.global.trackingModule.alwaysOn
    for _, spellID in ipairs(ALWAYS_ON) do
        local spellName = alwaysOn[spellID] and GetSpellName(spellID)
        for index = 1, spellName and GetNumTypes() or 0 do
            local name, active = GetTracking(index)
            if name == spellName then
                if not active then SetTracking(index, true) end
                break
            end
        end
    end
end

function ScarletUI:SetupTracking()
    if not self.alwaysOnTrackingRegistered then
        self.alwaysOnTrackingRegistered = true
        -- PLAYER_ALIVE: resurrected before releasing; PLAYER_UNGHOST: as a ghost.
        for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
            self:RegisterEventHandler(event, function() ScarletUI:ApplyAlwaysOnTracking() end)
        end
    end

    local module = self.db.global.trackingModule
    if not module.enabled or not GetNumTypes or self.trackingApplied then
        return
    end

    -- Spell-based entries can be missing this early; retry when the world loads.
    local count = GetNumTypes()
    if count == 0 then
        if not self.trackingWaiting then
            self.trackingWaiting = true
            self:RegisterEventHandler("PLAYER_ENTERING_WORLD", function()
                ScarletUI:SetupTracking()
            end)
        end
        return
    end

    local saved = module.states or {}
    for index = 1, count do
        local name, active = GetTracking(index)
        if name and saved[name] ~= nil and saved[name] ~= (active and true or false) then
            SetTracking(index, saved[name])
        end
    end
    self.trackingApplied = true
    -- The shared states may have just turned an always-on entry off.
    self:ApplyAlwaysOnTracking()

    if not self.trackingShutdownRegistered then
        self.trackingShutdownRegistered = true
        -- AceDB strips default-only tables on PLAYER_LOGOUT; this fires first.
        -- One callback per target and event, so each module uses its own target.
        self.db.RegisterCallback("ScarletUI-Tracking", "OnDatabaseShutdown", function()
            local current = ScarletUI.db.global.trackingModule
            if not current.enabled or not ScarletUI.trackingApplied then return end
            -- Merge so entries this character lacks keep their shared state.
            current.states = current.states or {}
            for index = 1, GetNumTypes() do
                local name, active = GetTracking(index)
                if name then current.states[name] = active and true or false end
            end
        end)
    end
end
