-- Can remove when addons are fixed from P3 WotLK PTR
GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

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
    countdownForCooldowns = '1',
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
    for k, v in pairs(self.CVars) do
        if GetCVar(k) ~= v then
            SetCVar(k, v)
            CVarsChanged = true;
            print(GetCVar(k) .. '('..type(GetCVar(k))..')' .. ' : ' .. '('..type(v)..')' .. v)
        end
    end

    -- Show popup to reload if any CVars are updated
    if (CVarsChanged) then
        StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    end
end

function ScarletUI:SetupRaidProfiles()
    local profiles = { 'Party', 'Raid' }
    for _, profile in ipairs(profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)
        end

        -- Set profile settings
        if profile == 'Party' then
            SetRaidProfileSavedPosition(profile, false, 'TOP', 450, 'BOTTOM', 295, 'LEFT', 635)
        elseif profile == 'Raid' then
            SetRaidProfileSavedPosition(profile, false, 'TOP', 375, 'BOTTOM', 90, 'LEFT', 165)
            SetRaidProfileOption(profile, "keepGroupsTogether", '1')
            SetRaidProfileOption(profile, "horizontalGroups", '1')
        end

        -- Check and apply Raid Profile settings
        local settingsChanged = false
        for k, v in pairs(self.raidProfile) do
            if GetRaidProfileOption(profile, k) ~= v then
                SetRaidProfileOption(profile, k, v)
                settingsChanged = true;
                --print(GetRaidProfileOption(profile, k) .. '('..type(GetRaidProfileOption('Primary', k))..')' .. ' : ' .. '('..type(v)..')' .. v)
            end
        end
    end

    -- Show popup to reload if any Raid Profile settings are updated
    if (settingsChanged) then
        StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    end
end

function ScarletUI:UpdateMainBar()
    if not InCombatLockdown() and (MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown()) then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 15)
    end
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
