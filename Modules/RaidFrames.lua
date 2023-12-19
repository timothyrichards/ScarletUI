local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:SetupRaidProfiles()
    local cufLoaded = IsAddOnLoaded("Blizzard_CompactRaidFrames");
    local raidFramesModule = self.db.global.raidFramesModule
    if not cufLoaded or not raidFramesModule.enabled or self.lightWeightMode or self.retail or self.inCombat then
        return
    end

    self.movingRaidFrames = false
    if not self.raidProfileEventRegistered then
        self.raidProfileEventRegistered = true;
        local frame = CreateFrame("Frame", "SUI_RaidFrame", SUI_Frame)
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
                local options = raidFramesModule.profiles[profile]
                if options ~= nil and options.move then
                    options.y = top
                    options.height = bottom
                    options.x = left
                end

                AceConfigRegistry:NotifyChange("ScarletUI")
            end
        end)

        return
    end

    for profile, options in pairs(raidFramesModule.profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end

        -- Update settings if the profile does exist
        if RaidProfileExists(profile) then
            -- Check and apply Raid Profile settings
            for k, v in pairs(options) do
                if not (k == "move" or k == "x" or k == "y" or k == "height") then
                    local currentValue = tostring(GetRaidProfileOption(profile, k))
                    local targetValue = tostring(v)
                    if currentValue ~= targetValue then
                        SetRaidProfileOption(profile, k, v)
                    end
                end
            end

            -- Update position
            SetRaidProfileSavedPosition(profile, false, 'TOP', options.y, 'BOTTOM', options.height, 'LEFT', options.x)
        end
    end
end

function ScarletUI:UpdateProfilePositions()
    if self.inCombat then
        return
    end

    self.movingRaidFrames = true
    local raidFramesModule = self.db.global.raidFramesModule
    for profile, options in pairs(raidFramesModule.profiles) do
        CompactRaidFrameManagerContainerResizeFrame:ClearAllPoints()
        local activeRaidProfile = GetActiveRaidProfile()
        if activeRaidProfile == profile then
            self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "TOP", UIParent, "TOP", 0, options.y * -1)
            self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "BOTTOM", UIParent, "BOTTOM", 0, options.height)
            self:SetPoint(CompactRaidFrameManagerContainerResizeFrame, "LEFT", UIParent, "LEFT", options.x, 0)
        end

        -- Update positions
        SetRaidProfileSavedPosition(profile, false, 'TOP', options.y, 'BOTTOM', options.height, 'LEFT', options.x)
    end

    -- Prompt a reload
    StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
    self.movingRaidFrames = false
end
