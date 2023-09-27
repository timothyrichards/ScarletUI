function ScarletUI:SetupRaidProfiles()
    print("SetupRaidProfiles()")
    local raidFramesModule = self.db.global.raidFramesModule
    if not raidFramesModule.enabled or self.inCombat then
        return
    end

    local profiles = { 'Party', 'Raid' }
    for _, profile in ipairs(profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end

        -- Set profile settings
        SetRaidProfileOption(profile, "autoActivatePvE", '1')
        SetRaidProfileOption(profile, "autoActivatePvP", '1')

        if profile == 'Party' then
            SetRaidProfileOption(profile, "displayPets", '1')
            SetRaidProfileOption(profile, "autoActivate2Players", '1')
            SetRaidProfileOption(profile, "autoActivate3Players", '1')
            SetRaidProfileOption(profile, "autoActivate5Players", '1')
        elseif profile == 'Raid' then
            SetRaidProfileOption(profile, "keepGroupsTogether", '1')
            SetRaidProfileOption(profile, "horizontalGroups", '1')
            SetRaidProfileOption(profile, "autoActivate10Players", '1')
            SetRaidProfileOption(profile, "autoActivate15Players", '1')
            SetRaidProfileOption(profile, "autoActivate20Players", '1')
            SetRaidProfileOption(profile, "autoActivate40Players", '1')
        end

        -- Update positions
        self:UpdateProfilePositions()

        -- Check and apply Raid Profile settings
        for k, v in pairs(self.raidProfile) do
            local currentValue = tostring(GetRaidProfileOption(profile, k))
            local targetValue = tostring(v)
            if currentValue ~= targetValue then
                SetRaidProfileOption(profile, k, v)
            end
        end
    end
end

function ScarletUI:UpdateProfilePositions()
    print("UpdateProfilePositions()")
    if self.inCombat then
        return
    end

    local raidFramesModule = self.db.global.raidFramesModule
    local party = raidFramesModule.partyFrames;
    local raid = raidFramesModule.raidFrames;
    SetRaidProfileSavedPosition("Party", false, 'TOP', party.y, 'BOTTOM', party.height, 'LEFT', party.x)
    SetRaidProfileSavedPosition("Raid", false, 'TOP', raid.y, 'BOTTOM', raid.height, 'LEFT', raid.x)
end
