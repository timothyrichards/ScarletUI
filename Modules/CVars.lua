ScarletUI.booleanOptions = {
    "true",
    "false"
}

ScarletUI.reloadCVars = {
    'XpBarText',
}

function ScarletUI:SetupCVars()
    local CVarModule = self.db.global.CVarModule
    if not CVarModule.enabled or self:InCombat() then
        return
    end

    -- Check and apply CVars
    local CVarsChanged = false
    for k, v in pairs(CVarModule.CVars) do
        local currentValue = tostring(GetCVar(k))
        local targetValue = tostring(v)
        if currentValue ~= targetValue then
            if k == 'countdownForCooldowns' and IsAddOnLoaded('OmniCC') then
                SetCVar(k, '0')
            else
                SetCVar(k, v)
            end

            if self:ArrayHasValue(self.reloadCVars, k) then
                CVarsChanged = true;
            end
        end
    end

    -- Show popup to reload if any CVars are updated
    if (CVarsChanged) then
        StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    end
end
