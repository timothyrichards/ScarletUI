function ScarletUI:CreateContainer(frame, settings, width, height)
    local containerName = frame:GetName() .. "Container"
    local container = _G[containerName] or CreateFrame("FRAME", containerName, UIParent)
    container.originalFrameName = frame:GetName()
    container.settingsKey = frame.settingsKey

    if width == nil then
        width = frame:GetWidth()
    end

    if height == nil then
        height = frame:GetHeight()
    end

    frame:ClearAllPoints()
    frame:SetMovable(true)
    frame:SetUserPlaced(true)
    frame:SetParent(container)
    frame:SetAllPoints(container)

    container:SetFrameStrata(frame:GetFrameStrata())
    container:SetFrameLevel(frame:GetFrameLevel())
    container:ClearAllPoints()
    container:SetSize(width, height)
    container:SetPoint(
            self.frameAnchors[settings.frameAnchor],
            UIParent,
            self.frameAnchors[settings.screenAnchor],
            settings.x,
            settings.y
    )

    return container
end

function ScarletUI:CreateContainerAndMover(frame, settings, width, height)
    if not frame then
        return
    end

    local container = self:CreateContainer(frame, settings, width, height)

    frame:ClearAllPoints()
    frame:UnregisterAllEvents()
    frame:SetPoint("LEFT", container, "LEFT")

    self:CreateMover(container, settings)

    if settings.hide then
        container:Hide()
        frame:UnregisterAllEvents()
        frame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:mainMenuBar(module)
    MainMenuBarPerformanceBarFrame:Hide()

    MainMenuBarTexture0:ClearAllPoints()
    MainMenuBarTexture0:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 0, 0)
    MainMenuBarTexture1:ClearAllPoints()
    MainMenuBarTexture1:SetPoint("BOTTOMLEFT", MainMenuBarTexture0, "BOTTOMRIGHT", 0, 0)
    MainMenuBarTexture2:Hide()
    MainMenuBarTexture3:Hide()

    if MainMenuBarTextureExtender then
        MainMenuBarTextureExtender:Hide()
    end

    MainMenuBar:SetWidth(512)
    ActionButton1:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 8, 4)

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

    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        button:SetAttribute("showgrid", 1)
        ActionButton_Update(button)
    end

    if not module.showGryphons then
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    else
        MainMenuBarLeftEndCap:Show()
        MainMenuBarLeftEndCap:ClearAllPoints()
        MainMenuBarLeftEndCap:SetPoint("BOTTOMRIGHT", MainMenuBarArtFrame, "BOTTOMLEFT", 30, 0)

        MainMenuBarRightEndCap:Show()
        MainMenuBarRightEndCap:ClearAllPoints()
        MainMenuBarRightEndCap:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMRIGHT", -30, 0)
    end

    local mainMenuBarSettings = module.mainMenuBar;
    self:CreateMover(MainMenuBar, mainMenuBarSettings)

    if mainMenuBarSettings.hide then
        MainMenuBar:UnregisterAllEvents()
        MainMenuBar:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:vehicleLeaveButton(module)
    local vehicleLeaveButtonSettings = module.vehicleLeaveButton;
    local setup = function()
        MainMenuBarVehicleLeaveButton:ClearAllPoints()
        MainMenuBarVehicleLeaveButton:SetPoint(
                self.frameAnchors[vehicleLeaveButtonSettings.frameAnchor],
                UIParent,
                self.frameAnchors[vehicleLeaveButtonSettings.screenAnchor],
                vehicleLeaveButtonSettings.x,
                vehicleLeaveButtonSettings.y
        )
        MainMenuBarVehicleLeaveButton.settingsKey = "vehicleLeaveButton"
        self:CreateMover(MainMenuBarVehicleLeaveButton, vehicleLeaveButtonSettings)
    end

    setup()
    MainMenuBarVehicleLeaveButton:HookScript("OnShow", function()
        setup()
    end)

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

    local microButtons = {
        "CharacterMicroButton",
        "SpellbookMicroButton",
        "TalentMicroButton",
        "AchievementMicroButton",
        "QuestLogMicroButton",
        "SocialsMicroButton",
        "GuildMicroButton",
        "CollectionsMicroButton",
        "PVPMicroButton",
        "LFGMicroButton",
        "EJMicroButton",
        "MainMenuMicroButton",
        "HelpMicroButton",
    }
    local buttonCount = 0
    for _, buttonName in ipairs(microButtons) do
        if _G[buttonName] then
            buttonCount = buttonCount + 1
        end
    end

    -- Create or retrieve the MicroBar frame
    local MicroBar = _G["MicroBar"] or CreateFrame("Frame", "MicroBar", UIParent)
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

    local previousButton
    for _, buttonName in ipairs(microButtons) do
        local button = _G[buttonName]

        if button then
            button:ClearAllPoints()
            button:SetMovable(true)
            button:SetUserPlaced(true)
            button:SetParent(MicroBar)
            if buttonName == "CharacterMicroButton" then
                self:SetPoint(button, "BOTTOMLEFT", MicroBar, "BOTTOMLEFT", 0, 0)
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

    if module.microBag then
        for i = 0, 3 do
            local frame = _G["CharacterBag"..i.."Slot"]
            frame:Hide()
        end

        if KeyRingButton then
            KeyRingButton:ClearAllPoints()
            KeyRingButton:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -5, 0)
        end
    end

    self:CreateMover(BagBar, bagBarSettings)

    if bagBarSettings.hide then
        BagBar:Hide()
    end
end

function ScarletUI:multiBarLeft(module)
    local multiBarLeftSettings = module.multiBarLeft;

    -- Create or retrieve the MultiBarLeft frame
    local container = _G["MultiBarLeftContainer"] or CreateFrame("Frame", "MultiBarLeftContainer", UIParent)
    container.settingsKey = "multiBarLeft"

    -- Set dimensions and position of MultiBarLeft
    container:ClearAllPoints()
    container:SetSize(40, 502)
    container:SetPoint(
            self.frameAnchors[multiBarLeftSettings.frameAnchor],
            UIParent,
            self.frameAnchors[multiBarLeftSettings.screenAnchor],
            multiBarLeftSettings.x,
            multiBarLeftSettings.y
    )

    local previousButton
    for i = 1, 12 do
        local button = _G["MultiBarLeftButton"..i]

        if button then
            if i == 1 then
                self:SetPoint(button, "TOPRIGHT", container, "TOPRIGHT", -2, -3)
            else
                self:SetPoint(button, "TOP", previousButton, "BOTTOM", 0, -6)
            end

            previousButton = button
        end
    end

    self:CreateMover(container, multiBarLeftSettings)

    if multiBarLeftSettings.hide then
        container:Hide()
        MultiBarLeft:UnregisterAllEvents()
        MultiBarLeft:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:petActionBar(module)
    local petBarSettings = module.petBar;

    -- Create or retrieve the PetBar frame
    local PetBar = _G["PetBar"] or CreateFrame("Frame", "PetBar", UIParent)

    -- Set dimensions and position of MicroBar
    PetBar:ClearAllPoints()
    PetBar:SetSize(500, 38)
    PetBar:SetPoint(
            self.frameAnchors[petBarSettings.frameAnchor],
            UIParent,
            self.frameAnchors[petBarSettings.screenAnchor],
            petBarSettings.x,
            petBarSettings.y
    )

    local previousButton
    for i = 1, NUM_PET_ACTION_SLOTS do
        local button = _G["PetActionButton"..i]

        if button then
            if i == 1 then
                self:SetPoint(button, "LEFT", PetBar, "LEFT", 6, 0)
            else
                self:SetPoint(button, "LEFT", previousButton, "RIGHT", 8, 0)
            end

            previousButton = button
        end
    end

    self:CreateMover(PetBar, petBarSettings)

    if petBarSettings.hide then
        PetBar:Hide()
        PetActionBarFrame:UnregisterAllEvents()
        PetActionBarFrame:SetParent(self.hideFrameContainer)
    end
end

function ScarletUI:multiCastBar(module)
    local multiCastBarSettings = module.multiCastBar;
    if not MultiCastActionBarFrame then
        return
    end

    MultiCastActionBarFrame.settingsKey = "multiCastBar"

    -- stupid hack to fix the position of the MultiCastActionBarFrame
    C_Timer.NewTimer(1, function()
        MultiCastActionBarFrame:ClearAllPoints()
        MultiCastActionBarFrame:SetPoint(
                self.frameAnchors[multiCastBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[multiCastBarSettings.screenAnchor],
                multiCastBarSettings.x,
                multiCastBarSettings.y
        )
    end)

    self:CreateMover(MultiCastActionBarFrame, multiCastBarSettings)

    if multiCastBarSettings.hide then
        MultiCastActionBarFrame:UnregisterAllEvents()
        MultiCastActionBarFrame:SetParent(self.hideFrameContainer)
    end
end

-- TODO: improve this functionality, maybe add to options
function ScarletUI:possessBarFrame()
    if not PossessBarFrame then
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

function ScarletUI:experienceBar(module)
    local experienceBarSettings = module.experienceBar;

    self.movingExperienceBar = true

    MainMenuExpBar:SetSize(510, 10)
    MainMenuExpBar:ClearAllPoints()
    MainMenuExpBar:SetPoint(
            self.frameAnchors[experienceBarSettings.frameAnchor],
            UIParent,
            self.frameAnchors[experienceBarSettings.screenAnchor],
            experienceBarSettings.x,
            experienceBarSettings.y
    )

    if not self.experienceBarEventRegistered then
        hooksecurefunc(MainMenuExpBar, "SetPoint", function()
            if self.movingExperienceBar then
                return
            end

            self:experienceBar(module)
        end)
        self.experienceBarEventRegistered = true
    end

    MainMenuExpBar.settingsKey = "experienceBar"
    self:CreateMover(MainMenuExpBar, experienceBarSettings)
    self.movingExperienceBar = false

    if experienceBarSettings.hide then
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:SetParent(self.hideFrameContainer)
    end

    MainMenuBarMaxLevelBar:UnregisterAllEvents()
    MainMenuBarMaxLevelBar:SetParent(self.hideFrameContainer)

    -- Get Current, Maximum, and Rested Experience
    local currXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restXP = GetXPExhaustion() or 0
    local mainMenuBarWidth = 510
    local exhaustionBarStart = (currXP / maxXP) * mainMenuBarWidth
    local exhaustionBarEnd = ((currXP + restXP) / maxXP) * mainMenuBarWidth

    -- Ensure the exhaustion bar does not exceed the main bar's width
    exhaustionBarEnd = min(exhaustionBarEnd, mainMenuBarWidth)
    ExhaustionLevelFillBar:ClearAllPoints()
    ExhaustionLevelFillBar:SetPoint("TOPLEFT", MainMenuExpBar, "TOPLEFT", exhaustionBarStart, 0)
    ExhaustionLevelFillBar:SetPoint("BOTTOMRIGHT", MainMenuExpBar, "TOPLEFT", exhaustionBarEnd, -11)
    ExhaustionTick:SetPoint("CENTER", ExhaustionLevelFillBar, "RIGHT")

    MainMenuXPBarTexture0:SetWidth("255")
    MainMenuXPBarTexture0:ClearAllPoints()
    MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT", 0, 0)
    MainMenuXPBarTexture1:Hide()
    MainMenuXPBarTexture2:Hide()
    MainMenuXPBarTexture3:SetWidth("255")
    MainMenuXPBarTexture3:ClearAllPoints()
    MainMenuXPBarTexture3:SetPoint("LEFT", MainMenuXPBarTexture0, "RIGHT", 0, 0)
end

function ScarletUI:reputationBar(module)
    local reputationBarSettings = module.reputationBar;

    self.movingReputationBar = true

    ReputationWatchBar:SetWidth(510)
    ReputationWatchBar.StatusBar:SetWidth(510)
    ReputationWatchBar:ClearAllPoints()
    ReputationWatchBar:SetPoint(
            self.frameAnchors[reputationBarSettings.frameAnchor],
            UIParent,
            self.frameAnchors[reputationBarSettings.screenAnchor],
            reputationBarSettings.x,
            reputationBarSettings.y
    )

    if not self.reputationBarEventRegistered then
        hooksecurefunc(ReputationWatchBar, "SetPoint", function()
            if self.movingReputationBar then
                return
            end

            self:reputationBar(module)
        end)
        self.reputationBarEventRegistered = true
    end

    ReputationWatchBar.settingsKey = "reputationBar"
    self:CreateMover(ReputationWatchBar, reputationBarSettings)
    self.movingReputationBar = false

    if reputationBarSettings.hide then
        ReputationWatchBar:UnregisterAllEvents()
        ReputationWatchBar:SetParent(self.hideFrameContainer)
    end

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
    end

    self:mainMenuBar(actionbarsModule)
    self:vehicleLeaveButton(actionbarsModule)
    self:microBar(actionbarsModule)
    self:bagBar(actionbarsModule)
    self:multiBarLeft(actionbarsModule)

    local bars = {
        "multiBarBottomLeft",
        "multiBarBottomRight",
        "multiBarRight",
        "stanceBar",
    }

    for _, v in ipairs(bars) do
        local data = self:GetFrameData(v)

        if data ~= nil then
            local frame = data.frame
            local settings = self:GetValueFromPath(self.db.global, self.frameData[v].databasePath)
            local width
            local height

            if v == "multiBarBottomLeft" then
                MultiBarBottomRightButton1:ClearAllPoints();
                MultiBarBottomRightButton1:SetPoint("BOTTOMLEFT", MultiBarBottomRight, "BOTTOMLEFT", 2, 1);
            end

            if v == "multiBarBottomRight" then
                MultiBarBottomLeftButton1:ClearAllPoints();
                MultiBarBottomLeftButton1:SetPoint("BOTTOMLEFT", MultiBarBottomLeft, "BOTTOMLEFT", 2, 1);
            end

            if v == "stanceBar" then
                frame.settingsKey = "stanceBar"
                width = 250
                height = 35
            end

            self:CreateContainerAndMover(frame, settings, width, height)
        else
            self:Print("Frame data is nil for settings key: " .. self.selectedMover.settingsKey)
        end
    end

    self:petActionBar(actionbarsModule)
    self:multiCastBar(actionbarsModule)
    self:possessBarFrame()
    self:experienceBar(actionbarsModule)
    self:reputationBar(actionbarsModule)

    if not self.actionbarEventRegistered then
        self.actionbarEventRegistered = true;
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:RegisterEvent("UNIT_EXITED_VEHICLE")
        self.frame:RegisterEvent("UPDATE_POSSESS_BAR")
        self.frame:RegisterEvent("CINEMATIC_STOP")
        self.frame:HookScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                self:microBar(actionbarsModule)
                self:possessBarFrame()
            end

            if event == "UNIT_EXITED_VEHICLE" then
                self:microBar(actionbarsModule)
            end

            if event == "UPDATE_POSSESS_BAR" then
                self:possessBarFrame()
            end
        end)
        self.frame:SetScript("OnShow", function(...)
            self:microBar(actionbarsModule)
        end)
    end
end
