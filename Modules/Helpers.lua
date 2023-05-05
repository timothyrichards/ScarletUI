ScarletUI.CVars = {
    -- UI CVars
    useUiScale =  1,
    UIScale =  0.75,
    XpBarText = 1,
    lootUnderMouse = 1,
    autoLootDefault = 1,
    floatingCombatTextCombatHealing = 1,
    showTargetOfTarget = 1,
    doNotFlashLowHealthWarning = 0,

    -- Chat CVars
    chatStyle = 'classic',
    whisperMode = 'inline',
    colorChatNamesByClass = 1,
    chatClassColorOverride = 0,
    speechToText = 0,
    textToSpeech = 0,
    chatMouseScroll = 1,

    -- Floating Combat Text
    enableFloatingCombatText = 1,
    floatingCombatTextLowManaHealth = 1,
    floatingCombatTextDodgeParryMiss = 1,
    floatingCombatTextCombatState = 1,
    floatingCombatTextFriendlyHealers = 1,
    floatingCombatTextEnergyGains = 1,

    -- Raid Frame CVars
    useCompactPartyFrames = 1,

    -- Misc CVars
    nameplateShowEnemies = 1,
    Sound_EnableErrorSpeech = 0,
}

ScarletUI.raidProfile = {
    useClassColors = true,
    displayBorder = false,
    displayPowerBar = true,
    displayOnlyDispellableDebuffs = true,
    healthText = 'perc',
    frameHeight = 46,
    frameWidth = 90,
}

function ScarletUI:SetupCVars()
    -- Dialog to reload and apply CVars
    StaticPopupDialogs['SCARLET_UI_RELOAD_DIALOG'] = {
        text = '<Scarlet UI>\n\nCVars have been updated, not all changes will be applied until your UI is reloaded.',
        button1 = 'Reload',
        button2 = 'Close',
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3,
    }

    -- Check and apply CVars
    local CVarsChanged = false
    for key, value in pairs(ScarletUI.CVars) do
        if tostring(GetCVar(key)) ~= tostring(value) then
            SetCVar(key, value)
            CVarsChanged = true;
        end
    end

    -- Check and apply Raid Profile settings
    for key, value in pairs(ScarletUI.raidProfile) do
        if tostring(GetRaidProfileOption('Primary', key)) ~= tostring(value) then
            SetRaidProfileOption('Primary', key, value)
            CVarsChanged = true;
        end
    end

    -- Show popup to reload if any CVars are updated
    if (CVarsChanged) then
        StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    end
end

function ScarletUI:GetContainerNumSlots(BagID)
    if GetContainerNumSlots then
        return GetContainerNumSlots(BagID)
    else
        return C_Container.GetContainerNumSlots(BagID)
    end
end

function ScarletUI:GetContainerItemLink(BagID, BagSlot)
    if GetContainerItemLink then
        return GetContainerItemLink(BagID, BagSlot)
    else
        return C_Container.GetContainerItemLink(BagID, BagSlot)
    end
end

function ScarletUI:GetContainerItemInfo(BagID, BagSlot)
    if GetContainerItemInfo then
        return GetContainerItemInfo(BagID, BagSlot)
    else
        return C_Container.GetContainerItemInfo(BagID, BagSlot)
    end
end

function ScarletUI:GetItemInfo(ItemLink)
    if GetItemInfo then
        return GetItemInfo(ItemLink)
    else
        return C_Container.GetItemInfo(ItemLink)
    end
end

function ScarletUI:UseContainerItem(BagID, BagSlot)
    if UseContainerItem then
        return UseContainerItem(BagID, BagSlot)
    else
        return C_Container.UseContainerItem(BagID, BagSlot)
    end
end
