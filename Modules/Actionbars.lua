function ScarletUI:CreateActionBar(barName, settingsKey, settings)
    local frameData = self:GetFrameData(settingsKey)
    local buttonSize = frameData.buttonSize or 36
    local buttonCount = frameData.buttonCount or 12
    local buttonName = frameData.buttonName or barName .. "Button"

    -- Create or retrieve the action bar frame
    local container = _G[barName .. "Container"] or CreateFrame("Frame", barName .. "Container", UIParent)
    container.settingsKey = settingsKey

    if settings.move then
        -- Calculate the width and height based on the number of buttons per row
        local spacing = 6
        local buttonsPerRow = settings.buttonsPerRow
        local width = buttonsPerRow * buttonSize + (buttonsPerRow - 1) * spacing
        local rows = math.ceil(buttonCount / buttonsPerRow)
        local height = rows * buttonSize + (rows - 1) * spacing

        -- Set dimensions and position of the action bar
        _G[barName]:SetParent(container)
        container:ClearAllPoints()
        container:SetSize(width + 2, height + 2)
        container:SetPoint(
                self.frameAnchors[settings.frameAnchor],
                UIParent,
                self.frameAnchors[settings.screenAnchor],
                settings.x,
                settings.y
        )
        container:SetScale(settings.scale)

        for i = 1, buttonCount do
            local button = _G[buttonName .. i]

            if button then
                if i == 1 then
                    self:SetPoint(button, "TOPLEFT", container, "TOPLEFT", 2, 0)
                elseif buttonsPerRow == 1 then
                    self:SetPoint(button, "TOP", _G[buttonName .. (i - 1)], "BOTTOM", 0, -spacing)
                elseif i % buttonsPerRow == 1 then
                    self:SetPoint(button, "TOP", _G[buttonName .. (i - buttonsPerRow)], "BOTTOM", 0, -spacing)
                else
                    self:SetPoint(button, "LEFT", _G[buttonName .. (i - 1)], "RIGHT", spacing, 0)
                end
            end
        end
    end

    self:CreateMover(container, settings)

    if settings.hide then
        container:Hide()
        _G[barName]:UnregisterAllEvents()
    end
end

function ScarletUI:mainMenuBar(module)
    local mainMenuBarSettings = module.mainMenuBar;

    if mainMenuBarSettings.move then
        if module.showMainBarBackground then
            MainMenuBarTexture0:Show()
            MainMenuBarTexture0:ClearAllPoints()
            MainMenuBarTexture0:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 0, 0)

            MainMenuBarTexture1:Show()
            MainMenuBarTexture1:ClearAllPoints()
            MainMenuBarTexture1:SetPoint("BOTTOMLEFT", MainMenuBarTexture0, "BOTTOMRIGHT", 0, 0)
        else
            MainMenuBarTexture0:Hide()
            MainMenuBarTexture1:Hide()
        end

        MainMenuBarTexture2:Hide()
        MainMenuBarTexture3:Hide()

        if MainMenuBarTextureExtender then
            MainMenuBarTextureExtender:Hide()
        end

        MainMenuBar:SetWidth(512)
        ActionButton1:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 8, 4)

        for i = 1, 12 do
            local button = _G["ActionButton"..i]
            button:SetAttribute("showgrid", 1)
            ActionButton_Update(button)
        end

        if module.showPagingNumbers then
            ActionBarUpButton:Show()
            ActionBarDownButton:Show()
            MainMenuBarPageNumber:Show()
            MainMenuBarPageNumber:ClearAllPoints()
            MainMenuBarPageNumber:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", 22, -3)
        else
            ActionBarUpButton:Hide()
            ActionBarDownButton:Hide()
            MainMenuBarPageNumber:Hide()
        end

        if module.showGryphons then
            MainMenuBarLeftEndCap:Show()
            MainMenuBarLeftEndCap:ClearAllPoints()
            MainMenuBarLeftEndCap:SetPoint("BOTTOMRIGHT", MainMenuBarArtFrame, "BOTTOMLEFT", 30, 0)

            MainMenuBarRightEndCap:Show()
            MainMenuBarRightEndCap:ClearAllPoints()
            MainMenuBarRightEndCap:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMRIGHT", -30, 0)
        else
            MainMenuBarLeftEndCap:Hide()
            MainMenuBarRightEndCap:Hide()
        end
    end

    self:CreateMover(MainMenuBar, mainMenuBarSettings)

    if mainMenuBarSettings.hide then
        MainMenuBar:UnregisterAllEvents()
        MainMenuBar:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:vehicleLeaveButton(module)
    local vehicleLeaveButtonSettings = module.vehicleLeaveButton;

    if vehicleLeaveButtonSettings.move then
        local setup = function()
            MainMenuBarVehicleLeaveButton:SetParent(UIParent)
            MainMenuBarVehicleLeaveButton:ClearAllPoints()
            MainMenuBarVehicleLeaveButton:SetPoint(
                    self.frameAnchors[vehicleLeaveButtonSettings.frameAnchor],
                    UIParent,
                    self.frameAnchors[vehicleLeaveButtonSettings.screenAnchor],
                    vehicleLeaveButtonSettings.x,
                    vehicleLeaveButtonSettings.y
            )
            MainMenuBarVehicleLeaveButton:SetScale(vehicleLeaveButtonSettings.scale)
            MainMenuBarVehicleLeaveButton.settingsKey = "vehicleLeaveButton"
            self:CreateMover(MainMenuBarVehicleLeaveButton, vehicleLeaveButtonSettings)
        end

        setup()
        MainMenuBarVehicleLeaveButton:HookScript("OnShow", function()
            setup()
        end)
    end

    if vehicleLeaveButtonSettings.hide then
        MainMenuBarVehicleLeaveButton:UnregisterAllEvents()
        MainMenuBarVehicleLeaveButton:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:microBar(module)
    local microBarSettings = module.microBar;
    if self:InCombat() then
        return
    end

    self.movingMicroButtons = true;

    -- Create or retrieve the MicroBar frame
    local MicroBar = _G["MicroBar"] or CreateFrame("Frame", "MicroBar", UIParent)

    if microBarSettings.move then
        local microButtons = {
            "CharacterMicroButton",
            "SpellbookMicroButton",
            "TalentMicroButton",
            "AchievementMicroButton",
            "QuestLogMicroButton",
            "SocialsMicroButton",
            "GuildMicroButton",
            "PVPMicroButton",
            "LFGMicroButton",
            "CollectionsMicroButton",
            "EJMicroButton",
            "StoreMicroButton",
            "MainMenuMicroButton",
            "WorldMapMicroButton",
            "HelpMicroButton",
            -- "MainMenuBarPerformanceBarFrame",
        }
        local buttonCount = 0
        for _, buttonName in ipairs(microButtons) do
            if _G[buttonName] then
                buttonCount = buttonCount + 1
            end
        end

        local buttonSpacing = 1
        local buttonWidth, buttonHeight = CharacterMicroButton:GetWidth(), 42
        local totalWidth = buttonWidth * (buttonCount - buttonSpacing)

        -- Set dimensions and position of MicroBar
        MicroBar:ClearAllPoints()
        MicroBar:SetSize(totalWidth, buttonHeight)
        MicroBar:SetPoint(
                self.frameAnchors[microBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[microBarSettings.screenAnchor],
                microBarSettings.x,
                microBarSettings.y
        )
        MicroBar:SetScale(microBarSettings.scale)

        local previousButton = MicroBar
        for _, buttonName in ipairs(microButtons) do
            local button = _G[buttonName]

            if button and button:IsShown() then
                button:SetParent(MicroBar)
                if buttonName == "CharacterMicroButton" then
                    self:SetPoint(button, "BOTTOMLEFT", MicroBar, "BOTTOMLEFT", 0, 0)
                elseif buttonName == "MainMenuBarPerformanceBarFrame" then
                    self:SetPoint(button, "LEFT", previousButton, "RIGHT", 0, -9)
                else
                    self:SetPoint(button, "LEFT", previousButton, "RIGHT", -3, 0)
                end

                if not button.setPointEventRegistered then
                    hooksecurefunc(button, "SetPoint", function()
                        if self.movingMicroButtons then
                            return
                        end

                        self:microBar(module)
                    end)
                    button.setPointEventRegistered = true
                end

                previousButton = button;
            end
        end
    end

    self:CreateMover(MicroBar, microBarSettings)
    self.movingMicroButtons = false;

    if microBarSettings.hide then
        MicroBar:Hide()
    end
end

function ScarletUI:bagBar(module)
    local bagBarSettings = module.bagBar;

    -- Create or retrieve the BagBar frame
    local BagBar = _G["BagBar"] or CreateFrame("Frame", "BagBar", UIParent)

    if bagBarSettings.move then
        local buttonSpacing = 5  -- Spacing between buttons, you can adjust this as needed
        local buttonWidth, buttonHeight = MainMenuBarBackpackButton:GetWidth(), MainMenuBarBackpackButton:GetHeight()
        local totalButtons = 5  -- Backpack + 4 Bag Slots + KeyRing
        local totalWidth = buttonWidth * totalButtons + buttonSpacing * (totalButtons - 1)

        -- Set dimensions and position of BagBar
        BagBar:ClearAllPoints()
        BagBar:SetSize(totalWidth, buttonHeight)
        BagBar:SetPoint(
                self.frameAnchors[bagBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[bagBarSettings.screenAnchor],
                bagBarSettings.x,
                bagBarSettings.y
        )
        BagBar:SetScale(bagBarSettings.scale)

        -- Move the Backpack button to the new BagBar frame
        MainMenuBarBackpackButton:ClearAllPoints()
        MainMenuBarBackpackButton:SetMovable(true)
        MainMenuBarBackpackButton:SetUserPlaced(true)
        MainMenuBarBackpackButton:SetPoint("RIGHT", BagBar, "RIGHT", 0, 0)
        MainMenuBarBackpackButton:SetParent(BagBar)
        MainMenuBarBackpackButtonNormalTexture:Hide()

        -- Position the other bag buttons relative to the Backpack button
        CharacterBag0Slot:ClearAllPoints()
        CharacterBag0Slot:SetMovable(true)
        CharacterBag0Slot:SetUserPlaced(true)
        CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -buttonSpacing, 0)

        for i = 0, 3 do
            local bag = _G["CharacterBag"..i.."Slot"]
            bag:SetParent(BagBar)

            local texture = _G["CharacterBag"..i.."SlotNormalTexture"]
            texture:Hide()
        end
    end

    if module.microBag then
        for i = 0, 3 do
            local frame = _G["CharacterBag"..i.."Slot"]
            frame:Hide()
        end

        if KeyRingButton then
            KeyRingButton:ClearAllPoints()
            KeyRingButton:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -5, 0)
        end
    else
        for i = 0, 3 do
            local frame = _G["CharacterBag"..i.."Slot"]
            frame:Show()
        end
    end

    self:CreateMover(BagBar, bagBarSettings)

    if bagBarSettings.hide then
        BagBar:Hide()
    end
end

function ScarletUI:multiCastBar(module)
    local multiCastBarSettings = module.multiCastBar;
    if not MultiCastActionBarFrame then
        return
    end

    MultiCastActionBarFrame.settingsKey = "multiCastBar"

    if multiCastBarSettings.move then
        -- stupid hack to fix the position of the MultiCastActionBarFrame
        C_Timer.NewTimer(1, function()
            if ScarletUI:InCombat() then
                return
            end

            MultiCastActionBarFrame:SetParent(UIParent)
            MultiCastActionBarFrame:ClearAllPoints()
            MultiCastActionBarFrame:SetPoint(
                    self.frameAnchors[multiCastBarSettings.frameAnchor],
                    UIParent,
                    self.frameAnchors[multiCastBarSettings.screenAnchor],
                    multiCastBarSettings.x,
                    multiCastBarSettings.y
            )
            MultiCastActionBarFrame:SetScale(multiCastBarSettings.scale)
        end)
    end

    self:CreateMover(MultiCastActionBarFrame, multiCastBarSettings)

    if multiCastBarSettings.hide then
        MultiCastActionBarFrame:UnregisterAllEvents()
        MultiCastActionBarFrame:SetParent(self.hideFrameContainer)
    end
end

-- TODO: improve this functionality, maybe add to options
function ScarletUI:possessBarFrame(module)
    if not PossessBarFrame or not module.multiBarRight.move then
        return
    end

    PossessBarFrame:ClearAllPoints()
    self:SetPoint(
            PossessBarFrame,
            "BOTTOMRIGHT",
            MultiBarBottomRight,
            "TOPRIGHT",
            -100,
            0
    )

    PossessBarFrame:HookScript("OnShow", function()
        PossessBarFrame:ClearAllPoints()
        self:SetPoint(
                PossessBarFrame,
                "BOTTOMRIGHT",
                MultiBarBottomRight,
                "TOPRIGHT",
                -100,
                0
        )
    end)
end

function ScarletUI:extraActionBar(module)
    local extraActionBarSettings = module.extraActionBar;

    if extraActionBarSettings.move then
        local setup = function()
            if self:InCombat() then
                return
            end

            if extraActionBarSettings.showBackground then
                ExtraActionButton1.style:Show()
            else
                ExtraActionButton1.style:Hide()
            end

            ExtraActionBarFrame:SetParent(UIParent)
            ExtraActionBarFrame:ClearAllPoints()
            ExtraActionBarFrame:SetPoint(
                    self.frameAnchors[extraActionBarSettings.frameAnchor],
                    UIParent,
                    self.frameAnchors[extraActionBarSettings.screenAnchor],
                    extraActionBarSettings.x,
                    extraActionBarSettings.y
            )
            ExtraActionBarFrame:SetScale(extraActionBarSettings.scale)
            ExtraActionBarFrame.settingsKey = "extraActionBar"
            self:CreateMover(ExtraActionBarFrame, extraActionBarSettings)
        end

        setup()
        ExtraActionBarFrame:HookScript("OnShow", function()
            setup()
        end)
    end

    if extraActionBarSettings.hide then
        ExtraActionBarFrame:UnregisterAllEvents()
        ExtraActionBarFrame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:experienceBar(module)
    local experienceBarSettings = module.experienceBar;

    if experienceBarSettings.move then
        self.movingExperienceBar = true

        MainMenuExpBar:SetParent(UIParent)
        MainMenuExpBar:ClearAllPoints()
        MainMenuExpBar:SetPoint(
                self.frameAnchors[experienceBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[experienceBarSettings.screenAnchor],
                experienceBarSettings.x,
                experienceBarSettings.y
        )
        MainMenuExpBar:SetScale(experienceBarSettings.scale)

        if not self.experienceBarEventRegistered then
            hooksecurefunc(MainMenuExpBar, "SetPoint", function()
                if self.movingExperienceBar then
                    return
                end

                self:experienceBar(module)
            end)
            self.experienceBarEventRegistered = true
        end

        self.movingExperienceBar = false
    end

    if experienceBarSettings.hide then
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:SetParent(self.hideFrameContainer)
    end

    if experienceBarSettings.short then
        MainMenuExpBar:SetSize(510, 10)

        MainMenuXPBarTexture0:SetWidth("255")
        MainMenuXPBarTexture0:ClearAllPoints()
        MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT", 0, 0)
        MainMenuXPBarTexture1:Hide()
        MainMenuXPBarTexture2:Hide()
        MainMenuXPBarTexture3:SetWidth("255")
        MainMenuXPBarTexture3:ClearAllPoints()
        MainMenuXPBarTexture3:SetPoint("LEFT", MainMenuXPBarTexture0, "RIGHT", 0, 0)
    else
        MainMenuExpBar:SetHeight(10)
        MainMenuXPBarTexture0:ClearAllPoints()
        MainMenuXPBarTexture0:SetPoint("TOPLEFT", MainMenuExpBar, "TOPLEFT", 0, 0)
        MainMenuXPBarTexture1:Show()
        MainMenuXPBarTexture1:ClearAllPoints()
        MainMenuXPBarTexture1:SetPoint("LEFT", MainMenuXPBarTexture0, "RIGHT", 0, 0)
        MainMenuXPBarTexture2:Show()
        MainMenuXPBarTexture2:ClearAllPoints()
        MainMenuXPBarTexture2:SetPoint("LEFT", MainMenuXPBarTexture1, "RIGHT", 0, 0)
        MainMenuXPBarTexture3:ClearAllPoints()
        MainMenuXPBarTexture3:SetPoint("LEFT", MainMenuXPBarTexture2, "RIGHT", 0, 0)
    end

    MainMenuBarMaxLevelBar:Hide()
    hooksecurefunc(MainMenuBarMaxLevelBar, "Show", function()
        MainMenuBarMaxLevelBar:UnregisterAllEvents()
        MainMenuBarMaxLevelBar:SetParent(ScarletUI.hideFrameContainer)
    end)

    MainMenuExpBar.settingsKey = "experienceBar"
    self:CreateMover(MainMenuExpBar, experienceBarSettings)
end

function ScarletUI:reputationBar(module)
    local reputationBarSettings = module.reputationBar;

    if reputationBarSettings.move then
        self.movingReputationBar = true

        ReputationWatchBar:SetParent(UIParent)
        ReputationWatchBar:ClearAllPoints()
        ReputationWatchBar:SetPoint(
                self.frameAnchors[reputationBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[reputationBarSettings.screenAnchor],
                reputationBarSettings.x,
                reputationBarSettings.y
        )
        ReputationWatchBar:SetScale(reputationBarSettings.scale)

        if not self.reputationBarEventRegistered then
            hooksecurefunc(ReputationWatchBar, "SetPoint", function()
                if self.movingReputationBar then
                    return
                end

                self:reputationBar(module)
            end)
            self.reputationBarEventRegistered = true
        end

        self.movingReputationBar = false
    end

    if reputationBarSettings.short then
        ReputationWatchBar:SetWidth(510)
        ReputationWatchBar.StatusBar:SetWidth(510)

        -- Leveling rep bar
        ReputationWatchBar.StatusBar.WatchBarTexture1.Show = function()
            ReputationWatchBar.StatusBar.WatchBarTexture1:Hide()
        end
        ReputationWatchBar.StatusBar.WatchBarTexture2.Show = function()
            ReputationWatchBar.StatusBar.WatchBarTexture2:Hide()
        end
        ReputationWatchBar.StatusBar.WatchBarTexture2:Hide()
        ReputationWatchBar.StatusBar.WatchBarTexture3:ClearAllPoints()
        ReputationWatchBar.StatusBar.WatchBarTexture3:SetPoint("LEFT", ReputationWatchBar.StatusBar.WatchBarTexture0, "RIGHT", 0, 0)

        -- Max level rep bar
        ReputationWatchBar.StatusBar.XPBarTexture1.Show = function()
            ReputationWatchBar.StatusBar.XPBarTexture1:Hide()
        end
        ReputationWatchBar.StatusBar.XPBarTexture2.Show = function()
            ReputationWatchBar.StatusBar.XPBarTexture2:Hide()
        end
        ReputationWatchBar.StatusBar.XPBarTexture2:Hide()
        ReputationWatchBar.StatusBar.XPBarTexture3:ClearAllPoints()
        ReputationWatchBar.StatusBar.XPBarTexture3:SetPoint("LEFT", ReputationWatchBar.StatusBar.XPBarTexture0, "RIGHT", 0, 0)
    end

    ReputationWatchBar.settingsKey = "reputationBar"
    self:CreateMover(ReputationWatchBar, reputationBarSettings)

    if reputationBarSettings.hide then
        ReputationWatchBar:UnregisterAllEvents()
        ReputationWatchBar:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:SetupActionBars()
    local actionbarsModule = self.db.global.actionbarsModule;
    if not actionbarsModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    local mainMenuBarSettings = actionbarsModule.mainMenuBar;
    if mainMenuBarSettings.move then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint(
                self.frameAnchors[mainMenuBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[mainMenuBarSettings.screenAnchor],
                mainMenuBarSettings.x,
                mainMenuBarSettings.y
        )
        MainMenuBar:SetScale(mainMenuBarSettings.scale)
    end

    self:mainMenuBar(actionbarsModule)
    self:vehicleLeaveButton(actionbarsModule)
    self:microBar(actionbarsModule)
    self:bagBar(actionbarsModule)
    self:multiCastBar(actionbarsModule)
    self:possessBarFrame(actionbarsModule)
    self:extraActionBar(actionbarsModule)
    self:experienceBar(actionbarsModule)
    self:reputationBar(actionbarsModule)

    local bars = {
        "multiBarBottomLeft",
        "multiBarBottomRight",
        "multiBarLeft",
        "multiBarRight",
        "stanceBar",
        "petBar",
    }

    for _, settingsKey in ipairs(bars) do
        local data = self:GetFrameData(settingsKey)

        if data ~= nil then
            local frameName = data.frame:GetName()
            local settings = self:GetValueFromPath(self.db.global, data.databasePath)

            self:CreateActionBar(frameName, settingsKey, settings)

            if settingsKey == "stanceBar" and settings.move then
                StanceBarLeft:SetScript("OnShow", function()
                    StanceBarLeft:Hide()
                    StanceBarLeft:SetParent(self.hideFrameContainer)
                end)

                StanceBarRight:SetScript("OnShow", function()
                    StanceBarRight:Hide()
                    StanceBarRight:SetParent(self.hideFrameContainer)
                end)
            end
        else
            self:Print("Frame data is nil for settings key: " .. self.selectedMover.settingsKey)
        end
    end

    if not self.actionbarEventRegistered then
        self.actionbarEventRegistered = true;
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:RegisterEvent("UNIT_EXITED_VEHICLE")
        self.frame:RegisterEvent("UPDATE_POSSESS_BAR")
        self.frame:RegisterEvent("CINEMATIC_STOP")
        self.frame:HookScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                self:microBar(actionbarsModule)
                self:possessBarFrame(actionbarsModule)
            end

            if event == "PLAYER_ENTERING_WORLD" then
                self:microBar(actionbarsModule)
            end

            if event == "UNIT_EXITED_VEHICLE" then
                self:microBar(actionbarsModule)
            end

            if event == "UPDATE_POSSESS_BAR" then
                self:possessBarFrame(actionbarsModule)
            end

            if event == "CINEMATIC_STOP" then
                self:multiCastBar(actionbarsModule)
            end
        end)
        self.frame:SetScript("OnShow", function(...)
            self:microBar(actionbarsModule)
        end)
    end
end
