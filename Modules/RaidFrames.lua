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
                        local dynamic, topPoint, topOffset, bottomPoint, bottomOffset, leftPoint, leftOffset = GetRaidProfileSavedPosition(profile)
                        local options = raidFramesModule.profiles[profile]
                        if options ~= nil and options.move then
                            options.savedPosition = {
                                dynamic = dynamic,
                                topPoint = topPoint,
                                topOffset = topOffset,
                                bottomPoint = bottomPoint,
                                bottomOffset = bottomOffset,
                                leftPoint = leftPoint,
                                leftOffset = leftOffset
                            }
                        end

                        AceConfigRegistry:NotifyChange("ScarletUI")
                    end
                end)

                hooksecurefunc("CompactUnitFrameProfiles_ApplyCurrentSettings", function()
                    if not ScarletUI.updatingSettings then
                        local profile = GetActiveRaidProfile()
                        if raidFramesModule.profiles[profile] then
                            for k, v in pairs(raidFramesModule.profiles[profile]) do
                                if k ~= "move" and k ~= "createProfile" and k ~= "savedPosition" then
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

                hooksecurefunc("SetCVar", function(k, v)
                    if k == "useCompactPartyFrames" then
                        local CVars = ScarletUI.db.global.CVarModule.CVars
                        local currentValue = tostring(CVars.useCompactPartyFrames)
                        local targetValue = tostring(v)
                        if currentValue ~= targetValue then
                            CVars.useCompactPartyFrames = v
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

function ScarletUI:DeleteRaidProfile(profile)
    DeleteRaidProfile(profile)
end

function ScarletUI:UpdateProfileOptions()
    local raidFramesModule = self.db.global.raidFramesModule

    for profile, options in pairs(raidFramesModule.profiles) do
        if raidFramesModule.profiles[profile].createProfile then
            -- Create a new raid profile if it doesn't exist
            if not RaidProfileExists(profile) then
                CreateNewRaidProfile(profile)
                self:ShowRaidFrameDialog()
                self:InitializeRaidProfileSettings(profile, options)
            end

            -- Update settings if the profile does exist
            self.updatingSettings = true
            if RaidProfileExists(profile) then
                -- Check and apply Raid Profile settings
                self:InitializeRaidProfileSettings(profile, options)

                -- Update position
                self:UpdateProfilePositions()
            end
            self.updatingSettings = false
        end
    end

    -- Check and apply Raid Style party frames setting
    local CVars = self.db.global.CVarModule.CVars
    local currentValue = tostring(GetCVar("useCompactPartyFrames"))
    local targetValue = tostring(CVars.useCompactPartyFrames)
    if currentValue ~= targetValue then
        SetCVar("useCompactPartyFrames", CVars.useCompactPartyFrames)
    end
end

function ScarletUI:InitializeRaidProfileSettings(profile, options)
    local raidFramesModule = self.db.global.raidFramesModule

    for k, v in pairs(options) do
        -- Remove obsolete x, y, and height values from the profile settings
        if k == "x" and k == "y" and k == "height" then
            raidFramesModule.profiles[profile][k] = nil
        end

        -- Don't remove k ~= "x" and k ~= "y" and k ~= "height", these are old settings that cause errors when they're still in the profile settings
        if k ~= "move" and k ~= "createProfile" and k ~= "savedPosition" and k ~= "x" and k ~= "y" and k ~= "height" then
            local currentValue = tostring(GetRaidProfileOption(profile, k))
            local targetValue = tostring(v)

            if currentValue ~= targetValue then
                SetRaidProfileOption(profile, k, v)
                self:ShowRaidFrameDialog()
            end
        end
    end
end

function ScarletUI:UpdateProfilePositions()
    if self:InCombat() then
        return
    end

    self.movingRaidFrames = true
    local raidFramesModule = self.db.global.raidFramesModule
    for profile, profileOptions in pairs(raidFramesModule.profiles) do
        local options = profileOptions.savedPosition

        if profileOptions.createProfile and profileOptions.move then
            local dynamic, topPoint, topOffset, bottomPoint, bottomOffset, leftPoint, leftOffset = GetRaidProfileSavedPosition(profile)
            if dynamic ~= options.dynamic or topPoint ~= options.topPoint or topOffset ~= options.topOffset or bottomPoint ~= options.bottomPoint or bottomOffset ~= options.bottomOffset or leftPoint ~= options.leftPoint or leftOffset ~= options.leftOffset then
                SetRaidProfileSavedPosition(profile, options.dynamic, options.topPoint, options.topOffset, options.bottomPoint, options.bottomOffset, options.leftPoint, options.leftOffset)
                self:ShowRaidFrameDialog()
            end
        end
    end
    self.movingRaidFrames = false
end
