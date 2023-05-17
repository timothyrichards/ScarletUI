-- Can remove when addons are fixed from P3 WotLK PTR
GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

ScarletUI.frameAnchors = {
    'BOTTOM',
    'BOTTOMLEFT',
    'BOTTOMRIGHT',
    'CENTER',
    'LEFT',
    'RIGHT',
    'TOP',
    'TOPLEFT',
    'TOPRIGHT',
}

ScarletUI.CVars = {
    -- UI CVars
    useUiScale =  '1',
    UIScale =  '0.75',
    XpBarText = '1',
    lootUnderMouse = '1',
    autoLootDefault = '1',
    floatingCombatTextCombatHealing = '1',
    showTargetOfTarget = '1',
    doNotFlashLowHealthWarning = '0',

    -- Chat CVars
    chatStyle = 'classic',
    whisperMode = 'inline',
    colorChatNamesByClass = '1',
    chatClassColorOverride = '0',
    speechToText = '0',
    textToSpeech = '0',
    chatMouseScroll = '1',

    -- Floating Combat Text
    enableFloatingCombatText = '1',
    floatingCombatTextLowManaHealth = '1',
    floatingCombatTextDodgeParryMiss = '1',
    floatingCombatTextCombatState = '1',
    floatingCombatTextFriendlyHealers = '1',
    floatingCombatTextEnergyGains = '1',

    -- Raid Frame CVars
    useCompactPartyFrames = '1',

    -- Misc CVars
    nameplateShowEnemies = '1',
    countdownForCooldowns = '0',
    Sound_EnableErrorSpeech = '0',
}

ScarletUI.raidProfile = {
    useClassColors = true,
    displayBorder = false,
    displayPowerBar = true,
    displayOnlyDispellableDebuffs = true,
    displayMainTankAndAssist = false,
    healthText = 'perc',
    frameHeight = 46,
    frameWidth = 90,
}

ScarletUI.reloadExceptionCVars = {
    'autoLootDefault',
    'nameplateShowEnemies',
    'useCompactPartyFrames',
    'countdownForCooldowns'
}

function ScarletUI:SetupCVars()
    -- Check and apply CVars
    local CVarsChanged = false
    for k, v in pairs(self.CVars) do
        local currentValue = tostring(GetCVar(k))
        local targetValue = tostring(v)
        if currentValue ~= targetValue then
            SetCVar(k, v)

            if not self:ArrayHasValue(self.reloadExceptionCVars, k) then
                CVarsChanged = true;
                print('(CVar) - ' .. k .. ': ' .. currentValue .. '('..type(GetCVar(k))..')' .. ' : ' .. targetValue .. '('..type(v)..')')
            end
        end
    end

    -- Show popup to reload if any CVars are updated
    if (CVarsChanged) then
        StaticPopup_Show('SCARLET_UI_CVAR_DIALOG')
    end
end

function ScarletUI:SpellBookPageScrolling()
    -- Allow spell book page scrolling
    local frame = SpellBookFrame
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if not InCombatLockdown() then
            if delta > 0 then
                SpellBookPrevPageButton:Click()
            else
                SpellBookNextPageButton:Click()
            end
        end
    end)
end

function ScarletUI:SwapActionbar(sourceBar, destinationBar)
    for i = 1, 12 do
        local sourceButton = _G[sourceBar.."Button"..i].action
        local destinationButton = _G[destinationBar.."Button"..i].action

        PickupAction(sourceButton)
        if GetCursorInfo() ~= nil then
            PlaceAction(destinationButton)
            PlaceAction(sourceButton)
        else
            PickupAction(destinationButton)
            PlaceAction(sourceButton)
            PlaceAction(destinationButton)
        end
    end
end

function ScarletUI:SettingDisabled(moduleEnabled)
    if ScarletUI.inCombat then
        return true
    else
        return not moduleEnabled
    end
end

function ScarletUI:DumpTable(table, indent)
    indent = indent or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. " = {")
            self:DumpTable(value, indent .. "    ")
            print(indent .. "}")
        else
            print(indent .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

function ScarletUI:ArrayHasValue(array, value)
    for _, v in ipairs(array) do
        if tostring(v) == tostring(value) then
            return true
        end
    end

    return false
end