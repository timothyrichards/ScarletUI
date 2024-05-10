local function mainMenuBar(module)
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

    MainMenuBar:SetMovable(true)
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

    local mainBarSettings = module.mainBar;
    ScarletUI:CreateMover(MainMenuBar, mainBarSettings)
end

local function microBar(actionbarsModule)
    local microBarSettings = actionbarsModule.microBar;
    if not microBarSettings.move or ScarletUI:InCombat() then
        return
    end

    ScarletUI.movingMicroButtons = true;

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
            ScarletUI.frameAnchors[microBarSettings.frameAnchor],
            UIParent,
            ScarletUI.frameAnchors[microBarSettings.screenAnchor],
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
            if buttonName == "CharacterMicroButton" then
                ScarletUI:SetPoint(button, "BOTTOMLEFT", MicroBar, "BOTTOMLEFT", 0, 0)
            else
                ScarletUI:SetPoint(button, "LEFT", previousButton, "RIGHT", -3, 0)
            end

            if not button.setPointEventRegistered then
                hooksecurefunc(button, "SetPoint", function()
                    if ScarletUI.movingMicroButtons then
                        return
                    end

                    microBar(actionbarsModule)
                end)
                button.setPointEventRegistered = true
            end

            previousButton = button;
        end
    end

    ScarletUI:CreateMover(MicroBar, microBarSettings)
    ScarletUI.movingMicroButtons = false;
end

local function bagBar(actionbarsModule)
    local bagBarSettings = actionbarsModule.bagBar;
    if not bagBarSettings.move then
        return
    end

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
            ScarletUI.frameAnchors[bagBarSettings.frameAnchor],
            UIParent,
            ScarletUI.frameAnchors[bagBarSettings.screenAnchor],
            bagBarSettings.x,
            bagBarSettings.y
    )

    -- Move the Backpack button to the new BagBar frame
    MainMenuBarBackpackButton:ClearAllPoints()
    MainMenuBarBackpackButton:SetMovable(true)
    MainMenuBarBackpackButton:SetUserPlaced(true)
    MainMenuBarBackpackButton:SetPoint("RIGHT", BagBar, "RIGHT", 0, 0)
    MainMenuBarBackpackButtonNormalTexture:Hide()

    -- Position the other bag buttons relative to the Backpack button
    CharacterBag0Slot:ClearAllPoints()
    CharacterBag0Slot:SetMovable(true)
    CharacterBag0Slot:SetUserPlaced(true)
    CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -buttonSpacing, 0)
    CharacterBag0SlotNormalTexture:Hide()
    CharacterBag1SlotNormalTexture:Hide()
    CharacterBag2SlotNormalTexture:Hide()
    CharacterBag3SlotNormalTexture:Hide()

    if actionbarsModule.microBag then
        CharacterBag0Slot:Hide()
        CharacterBag1Slot:Hide()
        CharacterBag2Slot:Hide()
        CharacterBag3Slot:Hide()
        KeyRingButton:ClearAllPoints()
        KeyRingButton:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -5, 0)
    end

    ScarletUI:CreateMover(BagBar, bagBarSettings)
end

local function multiBarBottomLeft()
    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetMovable(true)
    MultiBarBottomLeft:SetUserPlaced(true)
    MultiBarBottomLeft:UnregisterAllEvents();
    MultiBarBottomLeft:SetWidth(500)
    MultiBarBottomLeft:SetHeight(40)
    MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 3, -6)
end

local function multiBarBottomRight()
    MainMenuBarVehicleLeaveButton:ClearAllPoints()
    MainMenuBarVehicleLeaveButton:SetPoint("BOTTOM", MultiBarBottomRightButton12, "TOP", 0, 4)
    MainMenuBarVehicleLeaveButton:HookScript("OnShow", function()
        MainMenuBarVehicleLeaveButton:ClearAllPoints()
        MainMenuBarVehicleLeaveButton:SetPoint("BOTTOM", MultiBarBottomRightButton12, "TOP", 0, 4)
    end)

    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetMovable(true)
    MultiBarBottomRight:SetUserPlaced(true)
    MultiBarBottomRight:UnregisterAllEvents();
    MultiBarBottomRight:SetWidth(500)
    MultiBarBottomRight:SetHeight(40)
    MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 2)
end

local function stanceBar(module)
    local stanceBarSettings = module.stanceBar;
    if not StanceBarFrame then
        return
    end

    if stanceBarSettings.hide then
        ScarletUI.stanceBar = _G["StanceBar"] or CreateFrame("FRAME", "StanceBar", UIParent)
        ScarletUI.stanceBar:Hide()
        StanceBarFrame:UnregisterAllEvents()
        StanceBarFrame:SetParent(ScarletUI.stanceBar)
    else
        local StanceBar = _G["StanceBar"] or CreateFrame("FRAME", "StanceBar", UIParent)

        -- Set dimensions and position of StanceBar
        StanceBar:ClearAllPoints()
        StanceBar:SetSize(250, 35)
        StanceBar:SetPoint(
                ScarletUI.frameAnchors[stanceBarSettings.frameAnchor],
                UIParent,
                ScarletUI.frameAnchors[stanceBarSettings.screenAnchor],
                stanceBarSettings.x,
                stanceBarSettings.y
        )

        StanceBarFrame:ClearAllPoints()
        StanceBarFrame:SetMovable(true)
        StanceBarFrame:SetUserPlaced(true)
        StanceBarFrame:UnregisterAllEvents();
        StanceBarFrame:SetPoint("LEFT", StanceBar, "LEFT")

        ScarletUI:CreateMover(StanceBar, stanceBarSettings)
    end
end

local function petActionBar(module)
    local petBarSettings = module.petBar;

    -- Create or retrieve the PetBar frame
    local PetBar = _G["PetBar"] or CreateFrame("Frame", "PetBar", UIParent)

    -- Set dimensions and position of MicroBar
    PetBar:ClearAllPoints()
    PetBar:SetSize(509, 43)

    if petBarSettings.hide then
        PetBar:Hide()
        PetActionBarFrame:UnregisterAllEvents()
        PetActionBarFrame:SetParent(PetBar)
    else
        ScarletUI:CreateMover(PetBar, petBarSettings)
        PetBar:SetPoint(
                ScarletUI.frameAnchors[petBarSettings.frameAnchor],
                UIParent,
                ScarletUI.frameAnchors[petBarSettings.screenAnchor],
                petBarSettings.x,
                petBarSettings.y
        )

        local previousButton
        for i = 1, NUM_PET_ACTION_SLOTS do
            local button = _G["PetActionButton"..i]

            if button then
                if i == 1 then
                    ScarletUI:SetPoint(button, "LEFT", PetBar, "LEFT", 6, 0)
                else
                    ScarletUI:SetPoint(button, "LEFT", previousButton, "RIGHT", 8, 0)
                end

                previousButton = button
            end
        end
    end
end

local function multiCastBar(module)
    local multiCastBarSettings = module.multiCastBar;
    if not MultiCastActionBarFrame then
        return
    end

    -- Create or retrieve the PetBar frame
    local TotemBar = _G["TotemBar"] or CreateFrame("Frame", "TotemBar", UIParent)

    -- Set dimensions and position of MicroBar
    TotemBar:ClearAllPoints()
    TotemBar:SetSize(509, 43)

    if multiCastBarSettings.hide then
        TotemBar:Hide()
        MultiCastActionBarFrame:UnregisterAllEvents()
        MultiCastActionBarFrame:SetParent(TotemBar)
    else
        ScarletUI:CreateMover(TotemBar, multiCastBarSettings)
        TotemBar:SetPoint(
                ScarletUI.frameAnchors[multiCastBarSettings.frameAnchor],
                UIParent,
                ScarletUI.frameAnchors[multiCastBarSettings.screenAnchor],
                multiCastBarSettings.x,
                multiCastBarSettings.y
        )

        local totemBarButtons = {
            "MultiCastSlotButton",
            "MultiCastActionButton",
        }

        ScarletUI:SetPoint(MultiCastSummonSpellButton, "LEFT", TotemBar, "LEFT", 6, 0)

        local previousButton = MultiCastSummonSpellButton
        for i = 1, 4 do
            for _, buttonName in ipairs(totemBarButtons) do
                local button = _G[buttonName..i]

                if button then
                    if buttonName == "MultiCastSlotButton" then
                        ScarletUI:SetPoint(button, "LEFT", previousButton, "RIGHT", 8, 0)
                        previousButton = button
                    else
                        button:ClearAllPoints()
                        button:SetMovable(true)
                        button:SetUserPlaced(true)
                        button:SetAllPoints(previousButton)
                    end
                end
            end
        end

        ScarletUI:SetPoint(MultiCastRecallSpellButton, "LEFT", previousButton, "RIGHT", 8, 0)
    end
end

-- TODO: improve this functionality, maybe add to options
local function possessBarFrame()
    if not PossessBarFrame then
        return
    end

    PossessBarFrame:ClearAllPoints()
    ScarletUI:SetPoint(
            PossessBarFrame,
            "BOTTOMRIGHT",
            MultiBarBottomRight,
            "TOPRIGHT",
            -100,
            0
    )

    PossessBarFrame:HookScript("OnShow", function()
        PossessBarFrame:ClearAllPoints()
        ScarletUI:SetPoint(
                PossessBarFrame,
                "BOTTOMRIGHT",
                MultiBarBottomRight,
                "TOPRIGHT",
                -100,
                0
        )
    end)
end

local function experienceBar()
    if not ScarletUI.experienceBarEventRegistered then
        ScarletUI.experienceBarEventRegistered = true
        MainMenuExpBar:HookScript("OnShow", function()
            ScarletUI:UpdateMainBar()
        end)
        MainMenuExpBar:HookScript("OnHide", function()
            ScarletUI:UpdateMainBar()
        end)
    end
    MainMenuExpBar:SetSize(510, 10)
    MainMenuBarMaxLevelBar:Hide()
    MainMenuBarMaxLevelBar.Show = function()
        MainMenuBarMaxLevelBar:Hide()
    end

    -- Get Current, Maximum, and Rested Experience
    local currXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restXP = GetXPExhaustion() or 0
    local mainBarWidth = 510
    local exhaustionBarStart = (currXP / maxXP) * mainBarWidth
    local exhaustionBarEnd = ((currXP + restXP) / maxXP) * mainBarWidth

    -- Ensure the exhaustion bar does not exceed the main bar's width
    exhaustionBarEnd = min(exhaustionBarEnd, mainBarWidth)
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

local function reputationBar()
    if not ScarletUI.reputationBarEventRegistered then
        ScarletUI.reputationBarEventRegistered = true
        ReputationWatchBar:HookScript("OnShow", function()
            ScarletUI:UpdateMainBar()
        end)
        ReputationWatchBar:HookScript("OnHide", function()
            ScarletUI:UpdateMainBar()
        end)
    end
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

function ScarletUI:SetupActionbars()
    local actionbarsModule = self.db.global.actionbarsModule;
    if not actionbarsModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    local mainBarSettings = actionbarsModule.mainBar;
    if mainBarSettings.move then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint(
                self.frameAnchors[mainBarSettings.frameAnchor],
                UIParent,
                self.frameAnchors[mainBarSettings.screenAnchor],
                mainBarSettings.x,
                mainBarSettings.y
        )
    end

    if actionbarsModule.stackActionbars then
        local bar2, bar3, bar4, bar5, lock, cooldowns, show = GetActionBarToggles()
        if bar2 == false or bar3 == false then
            SetActionBarToggles(1, 1, bar4, bar5, lock, cooldowns, show)
            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
            return
        end

        mainMenuBar(actionbarsModule)
        microBar(actionbarsModule)
        bagBar(actionbarsModule)
        multiBarBottomLeft()
        multiBarBottomRight()
        stanceBar(actionbarsModule)
        petActionBar(actionbarsModule)
        multiCastBar(actionbarsModule)
        possessBarFrame()
        experienceBar()
        reputationBar()
        self:UpdateMainBar()
    end

    if not self.actionbarEventRegistered then
        self.actionbarEventRegistered = true;
        self.frame:SetAllPoints(UIParent)
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:RegisterEvent("UNIT_EXITED_VEHICLE")
        self.frame:RegisterEvent("UPDATE_POSSESS_BAR")
        self.frame:RegisterEvent("CINEMATIC_STOP")
        self.frame:HookScript("OnEvent", function(_, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                microBar(actionbarsModule)
                possessBarFrame()
            end

            if event == "UNIT_EXITED_VEHICLE" then
                microBar(actionbarsModule)
            end

            if event == "UPDATE_POSSESS_BAR" then
                possessBarFrame()
            end

            ScarletUI:UpdateMainBar()
        end)
        self.frame:SetScript("OnShow", function(...)
            microBar(actionbarsModule)
        end)
    end
end

function ScarletUI:UpdateMainBar()
    local module = self.db.global.actionbarsModule
    if not module.stackActionbars or self:InCombat() then
        return
    end

    local point, relativeTo, relativePoint, offsetX, _ = MultiBarBottomLeft:GetPoint()
    if MainMenuExpBar:IsShown() and ReputationWatchBar:IsShown() then
        MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 12)
    elseif MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
        MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 4)
    else
        MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, -6)
    end
end
