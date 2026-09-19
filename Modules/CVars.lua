local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

ScarletUI.reloadCVars = {
    'XpBarText',
}

ScarletUI.knownCVars = {
    'advancedCombatLogging',
    'autoLootDefault',
    'chatClassColorOverride',
    'chatMouseScroll',
    'chatStyle',
    'colorChatNamesByClass',
    'countdownForCooldowns',
    'doNotFlashLowHealthWarning',
    'enableFloatingCombatText',
    'enableMouseoverCast',
    'floatingCombatTextCombatHealing',
    'floatingCombatTextCombatState',
    'floatingCombatTextDodgeParryMiss',
    'floatingCombatTextEnergyGains',
    'floatingCombatTextFriendlyHealers',
    'floatingCombatTextLowManaHealth',
    'lootUnderMouse',
    'mapFade',
    'nameplateMotion',
    'nameplateShowAll',
    'nameplateOverlapH',
    'nameplateOverlapV',
    'nameplateMinScale',
    'nameplateMaxScale',
    'nameplateMinAlpha',
    'nameplateMaxAlpha',
    'nameplateSelfScale',
    'nameplateSelfAlpha',
    'nameplateOtherAtBase',
    'nameplateShowEnemies',
    'nameplateShowFriends',
    'nameplateMaxDistance',
    'nameplateMotionSpeed',
    'nameplateGlobalScale',
    'nameplateLargerScale',
    'nameplateSelfTopInset',
    'nameplateShowEnemyPets',
    'nameplateSelectedScale',
    'nameplateNotSelectedAlpha',
    'pvpFramesDisplayClassColor',
    'pvpFramesDisplayPowerBars',
    'raidFramesDisplayClassColor',
    'raidFramesDisplayPowerBars',
    'showDynamicBuffSize',
    'showTargetCastbar',
    'showTargetOfTarget',
    'Sound_EnableErrorSpeech',
    'speechToText',
    'textToSpeech',
    'UnitNameOwn',
    'UIScale',
    'useCompactPartyFrames',
    'useUiScale',
    'whisperMode',
    'XpBarText',
}

function ScarletUI:SetupCVars()
    local CVarModule = self.db.global.CVarModule
    if not CVarModule.enabled or self:InCombat() then
        return
    end

    -- Auto-override known CVars that have non-default values
    for _, name in ipairs(self.knownCVars) do
        if CVarModule.overrides[name] == nil and not CVarModule.hiddenCVars[name] and GetCVar(name) ~= nil then
            local currentVal = tostring(GetCVar(name))
            local defaultVal = tostring(GetCVarDefault(name))
            if currentVal ~= defaultVal then
                CVarModule.overrides[name] = currentVal
            end
        end
    end

    local requireReload = false
    for k, v in pairs(CVarModule.overrides) do
        if GetCVar(k) ~= nil then
            local currentValue = tostring(GetCVar(k))
            local targetValue = tostring(v)
            if currentValue ~= targetValue then
                if k == 'countdownForCooldowns' and (C_AddOns.IsAddOnLoaded or IsAddOnLoaded)('OmniCC') then
                    SetCVar(k, '0')
                else
                    SetCVar(k, v)
                end

                if self:ArrayHasValue(self.reloadCVars, k) then
                    requireReload = true
                end
            end
        end
    end

    if requireReload then
        self:ShowReloadDialog()
    end
end

function ScarletUI:RestoreCVarsDefaults()
    local CVarModule = self.db.global.CVarModule
    if self:InCombat() then
        return
    end

    wipe(CVarModule.overrides)
end

function ScarletUI:ClearCVarOverride(cvarName)
    local CVarModule = self.db.global.CVarModule
    if CVarModule.overrides[cvarName] == nil then
        return
    end

    CVarModule.overrides[cvarName] = nil
end
