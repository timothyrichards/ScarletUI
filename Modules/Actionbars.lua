local function mainMenuBar()
    MainMenuBarLeftEndCap:Hide()
    MainMenuBarRightEndCap:Hide()
    MainMenuBarPerformanceBarFrame:Hide()

    MainMenuBarTexture0:ClearAllPoints()
    MainMenuBarTexture0:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 0, 0)
    MainMenuBarTexture1:ClearAllPoints()
    MainMenuBarTexture1:SetPoint("BOTTOMLEFT", MainMenuBarTexture0, "BOTTOMRIGHT", 0, 0)
    MainMenuBarTexture2:Hide()
    MainMenuBarTexture3:Hide()

    MainMenuBar:SetWidth(510)
    ActionButton1:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 8, 4)

    MainMenuBarPageNumber:Hide()
    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()

    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        button:SetAttribute("showgrid", 1)
        ActionButton_Update(button)
    end

    MainMenuBarVehicleLeaveButton:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", 5, -5)
    MainMenuBarVehicleLeaveButton:HookScript("OnShow", function()
        MainMenuBarVehicleLeaveButton:SetPoint("LEFT", MainMenuBarArtFrame, "RIGHT", 5, -5)
    end)
end

local function microBar(actionbarsModule)
    local microBarSettings = actionbarsModule.microBar;
    if not microBarSettings.move then
        return
    end

    CharacterMicroButton:SetMovable(true)
    CharacterMicroButton:SetUserPlaced(true)
    CharacterMicroButton:ClearAllPoints()
    ScarletUI:SetPoint(
            CharacterMicroButton,
            ScarletUI.frameAnchors[microBarSettings.frameAnchor],
            UIParent,
            ScarletUI.frameAnchors[microBarSettings.screenAnchor],
            microBarSettings.x,
            microBarSettings.y
    )
end

local function bagBar(actionbarsModule)
    local bagBarSettings = actionbarsModule.bagBar;
    if not bagBarSettings.move then
        return
    end

    MainMenuBarBackpackButton:SetMovable(true);
    MainMenuBarBackpackButton:SetUserPlaced(true);
    MainMenuBarBackpackButton:ClearAllPoints();
    MainMenuBarBackpackButton:SetPoint(
            ScarletUI.frameAnchors[bagBarSettings.frameAnchor],
            UIParent,
            ScarletUI.frameAnchors[bagBarSettings.screenAnchor],
            bagBarSettings.x,
            bagBarSettings.y
    );
    MainMenuBarBackpackButtonNormalTexture:Hide()

    CharacterBag0Slot:SetMovable(true)
    CharacterBag0Slot:SetUserPlaced(true)
    CharacterBag0Slot:ClearAllPoints()
    CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -5, 0)
    CharacterBag0SlotNormalTexture:Hide()
    CharacterBag1SlotNormalTexture:Hide()
    CharacterBag2SlotNormalTexture:Hide()
    CharacterBag3SlotNormalTexture:Hide()
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
    MultiBarBottomRight:SetMovable(true)
    MultiBarBottomRight:SetUserPlaced(true)
    MultiBarBottomRight:UnregisterAllEvents();
    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetWidth(500)
    MultiBarBottomRight:SetHeight(40)
    MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 2)
end

local function stanceBar(parent)
    StanceBarFrame:SetMovable(true)
    StanceBarFrame:SetUserPlaced(true)
    StanceBarFrame:UnregisterAllEvents();
    StanceBarFrame:ClearAllPoints()
    StanceBarFrame:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 1)
end

local function multiCastBar(parent)
    if MultiCastActionBarFrame then
        MultiCastActionBarFrame:SetMovable(true)
        MultiCastActionBarFrame:SetUserPlaced(true)
        MultiCastActionBarFrame:UnregisterAllEvents();
        MultiCastActionBarFrame:ClearAllPoints()
        MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 1)
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
        stanceBar(parent)
        multiCastBar(parent)
        petActionBar(parent)
        experienceBar()
        reputationBar()
        ScarletUI:UpdateMainBar()
    end
end

function ScarletUI:UpdateMainBar()
    if not self.inCombat then
        local point, relativeTo, relativePoint, offsetX, _ = MultiBarBottomLeft:GetPoint()
        if MainMenuExpBar:IsShown() and ReputationWatchBar:IsShown() then
            MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 12)
        elseif MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
            MultiBarBottomLeft:SetPoint(point, relativeTo, relativePoint, offsetX, 4)
        end
    end
end
