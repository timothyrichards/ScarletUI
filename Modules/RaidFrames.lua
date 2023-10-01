function ScarletUI:SetupRaidProfiles()
    local cufLoaded = IsAddOnLoaded("Blizzard_CompactRaidFrames");
    local raidFramesModule = self.db.global.raidFramesModule
    if not cufLoaded or not raidFramesModule.enabled or self.inCombat then
        return
    end

    if not self.raidProfileEventRegistered then
        self.raidProfileEventRegistered = true;
        local frame = CreateFrame("Frame", "SUI_ItemLevelFrame", SUI_Frame)
        frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
        frame:SetScript("OnEvent", function (_, event, ...)
            if event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then
                ScarletUI:SetupRaidProfiles()
            end
        end)
        return
    end

    local profiles = { 'Party', 'Raid' }
    for _, profile in ipairs(profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end

        -- Update settings if the profile does exist
        if RaidProfileExists(profile) then
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
            local party = raidFramesModule.partyFrames;
            local raid = raidFramesModule.raidFrames;
            SetRaidProfileSavedPosition("Party", false, 'TOP', party.y, 'BOTTOM', party.height, 'LEFT', party.x)
            SetRaidProfileSavedPosition("Raid", false, 'TOP', raid.y, 'BOTTOM', raid.height, 'LEFT', raid.x)

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
end

function ScarletUI:UpdateProfilePositions()
    if self.inCombat then
        return
    end

    self:SetupRaidProfiles()
    StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
end