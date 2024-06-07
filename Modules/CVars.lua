local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

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
    local requireReload = false
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
                requireReload = true;
            end
        end
    end

    if (requireReload) then
        self:ShowReloadDialog()
    end
end

function ScarletUI:RestoreCVarsDefaults()
    local CVarModule = self.db.global.CVarModule
    if CVarModule.enabled or self:InCombat() then
        return
    end

    local requireReload = false
    for k, _ in pairs(CVarModule.CVars) do
        local defaultValue = GetCVarDefault(k)
        SetCVar(k, defaultValue)

        if self:ArrayHasValue(self.reloadCVars, k) then
            requireReload = true;
        end
    end

    if (requireReload) then
        self:ShowReloadDialog()
    end
end
