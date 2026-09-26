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

function ScarletUI:SetupTracking()
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
