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

    MainMenuBarPageNumber:Hide()
    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()

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
    if not microBarSettings.move then
        return
    end

    -- Create or retrieve the MicroBar frame
    local MicroBar = _G["MicroBar"] or CreateFrame("Frame", "MicroBar", UIParent)
    local buttonSpacing = 1
    local buttonWidth, buttonHeight = CharacterMicroButton:GetWidth(), CharacterMicroButton:GetHeight()
    local totalWidth = buttonWidth * (11 - buttonSpacing)

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

    -- Make CharacterMicroButton movable
    CharacterMicroButton:SetMovable(true)
    CharacterMicroButton:SetUserPlaced(true)
    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint("LEFT", MicroBar, "LEFT", 0, 0)

    ScarletUI:CreateMover(MicroBar, microBarSettings)
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
    MainMenuBarBackpackButton:SetMovable(true)
    MainMenuBarBackpackButton:SetUserPlaced(true)
    MainMenuBarBackpackButton:ClearAllPoints()
    MainMenuBarBackpackButton:SetPoint("RIGHT", BagBar, "RIGHT", 0, 0)
    MainMenuBarBackpackButtonNormalTexture:Hide()

    -- Position the other bag buttons relative to the Backpack button
    CharacterBag0Slot:SetMovable(true)
    CharacterBag0Slot:SetUserPlaced(true)
    CharacterBag0Slot:ClearAllPoints()
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
    MultiBarBottomLeft:SetMovable(true)
    MultiBarBottomLeft:SetUserPlaced(true)
    MultiBarBottomLeft:UnregisterAllEvents();
    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetWidth(500)
    MultiBarBottomLeft:SetHeight(40)
    MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 3, -6)
end

local function multiBarBottomRight()
    MainMenuBarVehicleLeaveButton:SetPoint("BOTTOM", MultiBarBottomRightButton12, "BOTTOM", 0, 0)
    MainMenuBarVehicleLeaveButton:HookScript("OnShow", function()
        MainMenuBarVehicleLeaveButton:SetPoint("BOTTOM", MultiBarBottomRightButton12, "BOTTOM", 0, 0)
    end)

    MultiBarBottomRight:SetMovable(true)
    MultiBarBottomRight:SetUserPlaced(true)
    MultiBarBottomRight:UnregisterAllEvents();
    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetWidth(500)
    MultiBarBottomRight:SetHeight(40)
    MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 2)
end

local function stanceBar(module, parent)
    local stanceBarSettings = module.stanceBar;

    if stanceBarSettings.hide then
        ScarletUI.stanceBar = CreateFrame("FRAME", "SUI_StanceBar", UIParent)
        ScarletUI.stanceBar:Hide()
        StanceBarFrame:UnregisterAllEvents()
        StanceBarFrame:SetParent(ScarletUI.stanceBar)
    else
        StanceBarFrame:SetMovable(true)
        StanceBarFrame:SetUserPlaced(true)
        StanceBarFrame:UnregisterAllEvents();
        StanceBarFrame:ClearAllPoints()
        StanceBarFrame:SetPoint(
                ScarletUI.frameAnchors[stanceBarSettings.frameAnchor],
                parent,
                ScarletUI.frameAnchors[stanceBarSettings.screenAnchor],
                stanceBarSettings.x,
                stanceBarSettings.y
        )
    end
end

local function multiCastBar(parent)
    if MultiCastActionBarFrame then
        local movingTotemBar = false
        hooksecurefunc(MultiCastActionBarFrame, "SetPoint", function()
            if movingTotemBar or InCombatLockdown() then
                return
            end

            movingTotemBar = true
            MultiCastActionBarFrame:SetMovable(true)
            MultiCastActionBarFrame:SetUserPlaced(true)
            MultiCastActionBarFrame:UnregisterAllEvents();
            MultiCastActionBarFrame:ClearAllPoints()
            MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 1)
            movingTotemBar = nil
        end)
    end
end

local function petActionBar(parent)
    PetActionBarFrame:SetMovable(true)
    PetActionBarFrame:SetUserPlaced(true)
    PetActionBarFrame:ClearAllPoints()
    PetActionBarFrame:SetPoint("BOTTOM", parent, "TOP", 0, 1)
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
    MainMenuExpBar:SetSize(510, 11)
    MainMenuBarMaxLevelBar:Hide()
    MainMenuBarMaxLevelBar.Show = function()
        MainMenuBarMaxLevelBar:Hide()
    end
    ExhaustionLevelFillBar:SetPoint("TOPRIGHT", MainMenuExpBar, "TOPLEFT", 510, 0)
    ExhaustionTick:SetPoint("CENTER", ExhaustionLevelFillBar, "RIGHT", 510, 0)
    MainMenuXPBarTexture0:ClearAllPoints()
    MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT", 0, 0)
    MainMenuXPBarTexture1:Hide()
    MainMenuXPBarTexture2:Hide()
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
                ScarletUI.frameAnchors[mainBarSettings.frameAnchor],
                UIParent,
                ScarletUI.frameAnchors[mainBarSettings.screenAnchor],
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

        local parent = MultiBarBottomRight;
        stanceBar(actionbarsModule, parent)
        multiCastBar(parent)
        petActionBar(parent)
        experienceBar()
        reputationBar()
        ScarletUI:UpdateMainBar()
    end

    if not self.actionbarEventRegistered then
        self.actionbarEventRegistered = true;
        local frame = CreateFrame("Frame", "SUI_ActionbarFrame", SUI_Frame)
        frame:RegisterEvent("UPDATE_FACTION")
        frame:RegisterEvent("UNIT_EXITED_VEHICLE")
        frame:RegisterEvent("CINEMATIC_STOP")
        frame:SetScript("OnEvent", function(_, event, ...)
            if event == "UPDATE_FACTION" then
                ScarletUI:UpdateMainBar()
            elseif event == "UNIT_EXITED_VEHICLE" or event == "CINEMATIC_STOP" then
                if actionbarsModule.stackActionbars then
                    microBar(actionbarsModule)
                end
            end
        end)
    end
end

function ScarletUI:UpdateMainBar()
    if not self.inCombat then
        local point, relativeTo, relativePoint, offsetX, _ = MultiBarBottomLeft:GetPoint()
        if MainMenuExpBar:IsShown() and ReputationWatchBar:IsShown() then
            MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 12)
        elseif MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
            MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 4)
        else
            MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, -6)
        end
    end
end
