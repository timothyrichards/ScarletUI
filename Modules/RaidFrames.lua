local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:SetupRaidProfiles()
    local cufLoaded = IsAddOnLoaded("Blizzard_CompactRaidFrames");
    local raidFramesModule = self.db.global.raidFramesModule
    local party = raidFramesModule.partyFrames;
    local raid = raidFramesModule.raidFrames;
    if not cufLoaded or not raidFramesModule.enabled or self.lightWeightMode or self.retail or self.inCombat then
        return
    end

    self.movingRaidFrames = false
    if not self.raidProfileEventRegistered then
        self.raidProfileEventRegistered = true;
        local frame = CreateFrame("Frame", "SUI_ItemLevelFrame", SUI_Frame)
        frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
        frame:SetScript("OnEvent", function (_, event, ...)
            if event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" then
                ScarletUI:SetupRaidProfiles()
            end
        end)

        hooksecurefunc("SetRaidProfileSavedPosition", function()
            local profile = GetActiveRaidProfile()
            local _, _, top, _, bottom, _, left = GetRaidProfileSavedPosition(profile)

            if not ScarletUI.movingRaidFrames then
                if profile == "Party" and party.move then
                    party.y = top
                    party.height = bottom
                    party.x = left
                elseif profile == "Raid" and raid.move then
                    raid.y = top
                    raid.height = bottom
                    raid.x = left
                end

                AceConfigRegistry:NotifyChange("ScarletUI")
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

    self.movingRaidFrames = true
    local raidFramesModule = self.db.global.raidFramesModule
    local party = raidFramesModule.partyFrames;
    local raid = raidFramesModule.raidFrames;

    CompactRaidFrameManagerContainerResizeFrame:ClearAllPoints()
    local activeRaidProfile = GetActiveRaidProfile()
    if activeRaidProfile == "Party" then
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "TOP", UIParent, "TOP", 0, party.y * -1)
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "BOTTOM", UIParent, "BOTTOM", 0, party.height)
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "LEFT", UIParent, "LEFT", party.x, 0)
    elseif activeRaidProfile == "Raid" then
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "TOP", UIParent, "TOP", 0, raid.y * -1)
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "BOTTOM", UIParent, "BOTTOM", 0, raid.height)
        self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "LEFT", UIParent, "LEFT", raid.x, 0)
    end

    -- Update positions
    SetRaidProfileSavedPosition("Party", false, 'TOP', party.y, 'BOTTOM', party.height, 'LEFT', party.x)
    SetRaidProfileSavedPosition("Raid", false, 'TOP', raid.y, 'BOTTOM', raid.height, 'LEFT', raid.x)

    -- Prompt a reload
    StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    self.movingRaidFrames = false
end
