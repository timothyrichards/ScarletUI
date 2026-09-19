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
    'damageMeterEnabled',
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
    'raidFramesDisplayDebuffs',
    'raidFramesDisplayOnlyDispellableDebuffs',
    'raidFramesHealthText',
    'raidOptionDisplayPets',
    'raidOptionDisplayMainTankAndAssist',
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

-- Capture once, before the first override or when a custom CVar is added.
function ScarletUI:SnapshotCVar(name)
    local originals = self.db.char.cvarOriginalValues
    local getInfo = C_CVar and C_CVar.GetCVarInfo or GetCVarInfo
    if getInfo then
        local _, _, _, perCharacter = getInfo(name)
        if perCharacter == false then
            originals = self.db.global.CVarModule.originalValues
        end
    end
    local value = GetCVar(name)
    if value ~= nil and originals[name] == nil then
        originals[name] = tostring(value)
    end
end

local function WriteCVar(self, name, value)
    local current = GetCVar(name)
    if current == nil then return false end
    if tostring(current) == tostring(value) then return true end

    local ok, result = pcall(SetCVar, name, value)
    if not ok or result == false then
        self:Print("Could not set CVar: " .. name)
        return false
    end
    if self:ArrayHasValue(self.reloadCVars, name) then
        self:ShowReloadDialog()
    end
    return true
end

function ScarletUI:RestoreCVars()
    if self:InCombat() then return end
    local module = self.db.global.CVarModule
    for _, originals in ipairs({ module.originalValues, self.db.char.cvarOriginalValues }) do
        for name, value in pairs(originals) do
            if not module.enabled or not module.overrides[name] or module.hiddenCVars[name] then
                if WriteCVar(self, name, value) then
                    originals[name] = nil
                end
            end
        end
    end
end

function ScarletUI:SetupCVars()
    if self:InCombat() then return end
    local module = self.db.global.CVarModule
    -- Also restores this character after the module was disabled on another one.
    self:RestoreCVars()
    if not module.enabled then return end

    -- Import existing non-default values, but respect explicitly cleared overrides.
    for _, name in ipairs(self.knownCVars) do
        local current = GetCVar(name)
        if module.overrides[name] == nil and not module.hiddenCVars[name] and current ~= nil then
            if tostring(current) ~= tostring(GetCVarDefault(name)) then
                module.overrides[name] = tostring(current)
            end
        end
    end

    for name, value in pairs(module.overrides) do
        if value ~= false and not module.hiddenCVars[name] and GetCVar(name) ~= nil then
            self:SnapshotCVar(name)
            if name == 'countdownForCooldowns' and IsAddOnLoaded('OmniCC') then
                value = '0'
            end
            WriteCVar(self, name, value)
        end
    end
end

function ScarletUI:ClearCVarOverride(name)
    if self:InCombat() then return end
    -- false survives AceDB default merging and prevents automatic re-import.
    self.db.global.CVarModule.overrides[name] = false
    self:RestoreCVars()
end

function ScarletUI:SetCVarDefault(name)
    if self:InCombat() or not self.db.global.CVarModule.enabled then return end
    local value = GetCVarDefault(name)
    if value == nil or GetCVar(name) == nil then return end
    self:SnapshotCVar(name)
    self.db.global.CVarModule.overrides[name] = tostring(value)
    self:SetupCVars()
end
