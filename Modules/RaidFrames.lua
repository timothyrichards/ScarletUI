local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:SetupRaidProfiles()
    local raidFramesModule = self.db.global.raidFramesModule
    if not raidFramesModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    self.movingRaidFrames = false
    self.updatingSettings = false
    if not self.raidProfileEventRegistered then
        local functionExecuted = false
        self.frame:SetScript("OnUpdate", function (_, ...)
            if HasLoadedCUFProfiles() and not functionExecuted then
                ScarletUI:UpdateProfileOptions()

                hooksecurefunc("SetRaidProfileSavedPosition", function()
                    if not ScarletUI.movingRaidFrames then
                        local profile = GetActiveRaidProfile()
                        local _, _, top, _, bottom, _, left = GetRaidProfileSavedPosition(profile)
                        local options = raidFramesModule.profiles[profile]
                        if options ~= nil and options.move then
                            options.y = top
                            options.height = bottom
                            options.x = left
                        end

                        AceConfigRegistry:NotifyChange("ScarletUI")
                    end
                end)

                hooksecurefunc("CompactUnitFrameProfiles_ApplyCurrentSettings", function()
                    if not ScarletUI.updatingSettings then
                        local profile = GetActiveRaidProfile()
                        if raidFramesModule.profiles[profile] then
                            for k, v in pairs(raidFramesModule.profiles[profile]) do
                                if not (k == "move" or k == "x" or k == "y" or k == "height") then
                                    local currentValue = tostring(v)
                                    local targetValue = tostring(GetRaidProfileOption(profile, k))
                                    if currentValue ~= targetValue then
                                        raidFramesModule.profiles[profile][k] = GetRaidProfileOption(profile, k)
                                    end
                                end
                            end
                        end
                    end
                end)

                functionExecuted = true
                self.frame:SetScript("OnUpdate", nil)
            end
        end)

        self.raidProfileEventRegistered = true;
    end
end

function ScarletUI:UpdateProfileOptions()
    local raidFramesModule = self.db.global.raidFramesModule
    for profile, options in pairs(raidFramesModule.profiles) do
        -- Create a new raid profile if it doesn't exist
        if not RaidProfileExists(profile) then
            CreateNewRaidProfile(profile)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end

        -- Update settings if the profile does exist
        self.updatingSettings = true
        if RaidProfileExists(profile) then
            -- Check and apply Raid Profile settings
            for k, v in pairs(options) do
                if not (k == "move" or k == "x" or k == "y" or k == "height") then
                    local currentValue = tostring(GetRaidProfileOption(profile, k))
                    local targetValue = tostring(v)
                    if currentValue ~= targetValue then
                        SetRaidProfileOption(profile, k, v)
                        StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                    end
                end
            end

            -- Update position
            self:UpdateProfilePositions()
        end
        self.updatingSettings = false
    end
end

function ScarletUI:UpdateProfilePositions()
    if self:InCombat() then
        return
    end

    self.movingRaidFrames = true
    local raidFramesModule = self.db.global.raidFramesModule
    for profile, options in pairs(raidFramesModule.profiles) do
        local _, _, top, _, bottom, _, left = GetRaidProfileSavedPosition(profile)
        if top ~= options.y or bottom ~= options.height or left ~= options.x then
            SetRaidProfileSavedPosition(profile, false, 'TOP', options.y, 'BOTTOM', options.height, 'LEFT', options.x)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
        end
    end
    self.movingRaidFrames = false
end
