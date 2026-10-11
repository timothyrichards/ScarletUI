-- Shares the Settings > Action Bars toggles (bars 2-8) across characters.
-- They are per-character game settings, not CVars. Bars in module.ignored
-- keep each character's own state.
local function GetToggles()
    local toggles = {}
    for i = 1, select("#", GetActionBarToggles()) do
        toggles[i] = select(i, GetActionBarToggles()) and true or false
    end
    return toggles
end

function ScarletUI:SetupActionBarToggles()
    local module = self.db.global.actionBarToggles
    if not module.enabled or not GetActionBarToggles or self.actionBarTogglesApplied then
        return
    end

    if module.bars and self:InCombat() then
        -- Showing bars is protected; apply once combat ends.
        if not self.actionBarTogglesWaiting then
            self.actionBarTogglesWaiting = true
            self:RegisterEventHandler("PLAYER_REGEN_ENABLED", function()
                ScarletUI:SetupActionBarToggles()
            end)
        end
        return
    end

    if module.bars then
        local current = GetToggles()
        local toggles = {}
        for i = 1, #current do
            toggles[i] = module.bars[i]
            if toggles[i] == nil or module.ignored[i] then toggles[i] = current[i] end
        end
        SetActionBarToggles(unpack(toggles))
        if MultiActionBar_Update then MultiActionBar_Update() end
    end
    self.actionBarTogglesApplied = true

    if not self.actionBarTogglesLogoutRegistered then
        self.actionBarTogglesLogoutRegistered = true
        -- Only save after this character received the shared toggles, so a
        -- skipped apply cannot overwrite them with this character's old state.
        -- AceDB strips default-only tables on PLAYER_LOGOUT; this fires first.
        self.db.RegisterCallback("ScarletUI-ActionBars", "OnDatabaseShutdown", function()
            local current = ScarletUI.db.global.actionBarToggles
            if current.enabled and ScarletUI.actionBarTogglesApplied then
                -- Merge so ignored bars keep their last shared state.
                current.bars = current.bars or {}
                for i, shown in ipairs(GetToggles()) do
                    if not current.ignored[i] then current.bars[i] = shown end
                end
            end
        end)
    end
end
