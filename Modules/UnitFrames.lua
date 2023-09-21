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

function ScarletUI:SetupUnitFrames()
    local unitFramesModule = self.db.global.unitFramesModule
    if not unitFramesModule.enabled then
        return
    end

    self:SetupPlayerFrame(unitFramesModule)
    self:SetupTargetFrame(unitFramesModule)
    self:SetupFocusFrame(unitFramesModule)

    if not self.unitFramesEventRegistered then
        self.unitFramesEventRegistered = true
        self.Frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
        self.Frame:RegisterEvent("GROUP_JOINED")
        self.Frame:RegisterEvent("GROUP_FORMED")
        self.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.Frame:HookScript("OnEvent", function(_, event, ...)
            if event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then
                ScarletUI:SetupRaidProfiles()
            elseif event == "GROUP_JOINED" or event == "GROUP_FORMED" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
                ScarletUI:UpdateActiveRaidProfile()
            end
        end)
    end
end

function ScarletUI:SetupPlayerFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    if not playerFrame.move then
        return
    end

    PlayerFrame:SetMovable(true)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint(
            self.frameAnchors[playerFrame.frameAnchor],
            UIParent,
            self.frameAnchors[playerFrame.screenAnchor],
            playerFrame.x,
            playerFrame.y
    )
end

function ScarletUI:SetupTargetFrame(unitFramesModule)
    local playerFrame = unitFramesModule.playerFrame
    local targetFrame = unitFramesModule.targetFrame
    if not targetFrame.move then
        return
    end

    TargetFrame:SetMovable(true)
    TargetFrame:SetUserPlaced(true)
    TargetFrame:ClearAllPoints()
    if not targetFrame.mirrorPlayerFrame then
        TargetFrame:SetPoint(
                self.frameAnchors[targetFrame.frameAnchor],
                UIParent,
                self.frameAnchors[targetFrame.screenAnchor],
                targetFrame.x,
                targetFrame.y
        )
    else
        TargetFrame:SetPoint(
                self:OppositeFrameAnchor(playerFrame.frameAnchor),
                UIParent,
                self:OppositeFrameAnchor(playerFrame.screenAnchor),
                unitFramesModule.playerFrame.x * -1,
                unitFramesModule.playerFrame.y
        )
    end
end

function ScarletUI:SetupFocusFrame(unitFramesModule)
    local focusFrame = unitFramesModule.focusFrame
    if not focusFrame.move then
        return
    end

    if FocusFrame then
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint(
                self.frameAnchors[focusFrame.frameAnchor],
                UIParent,
                self.frameAnchors[focusFrame.screenAnchor],
                focusFrame.x,
                focusFrame.y
        )
    end
end

function ScarletUI:SetupRaidProfiles()
    local raidFramesModule = self.db.global.raidFramesModule
    if not raidFramesModule.enabled or self.inCombat then
        return
    end

    local profiles = { 'Party', 'Raid' }
    for _, profile in ipairs(profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)

            -- Set profile settings
            SetRaidProfileOption(profile, "autoActivatePvE", '1')
            SetRaidProfileOption(profile, "autoActivatePvP", '1')

            if profile == 'Party' then
                SetRaidProfileSavedPosition(profile, false, 'TOP', 450, 'BOTTOM', 295, 'LEFT', 535)
                SetRaidProfileOption(profile, "displayPets", '1')
            elseif profile == 'Raid' then
                SetRaidProfileSavedPosition(profile, false, 'TOP', 375, 'BOTTOM', 90, 'LEFT', 165)
                SetRaidProfileOption(profile, "keepGroupsTogether", '1')
                SetRaidProfileOption(profile, "horizontalGroups", '1')
            end

            -- Check and apply Raid Profile settings
            for k, v in pairs(self.raidProfile) do
                local currentValue = tostring(GetRaidProfileOption(profile, k))
                local targetValue = tostring(v)
                if currentValue ~= targetValue then
                    SetRaidProfileOption(profile, k, v)
                end
            end

            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end
    end

    -- Update active raid profile
    ScarletUI:UpdateActiveRaidProfile()
end

function ScarletUI:UpdateActiveRaidProfile()
    if self.inCombat then
        return
    end

    local activeRaidProfile = GetActiveRaidProfile()
    if IsInRaid() then
        CompactUnitFrameProfiles_ActivateRaidProfile('Raid')
    elseif not IsInRaid() then
        CompactUnitFrameProfiles_ActivateRaidProfile('Party')
    elseif activeRaidProfile ~= 'Party' and activeRaidProfile ~= 'Raid' then
        CompactUnitFrameProfiles_ActivateRaidProfile('Party')
    end
end