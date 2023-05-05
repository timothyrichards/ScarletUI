function ScarletUI:SetupActionbars()
    MainMenuBarLeftEndCap:Hide()
    MainMenuBarRightEndCap:Hide()
    MainMenuBarMaxLevelBar:Hide()
    MainMenuBarPerformanceBarFrame:Hide()
    MainMenuBarTexture0:Hide()
    MainMenuBarTexture1:Hide()
    MainMenuBarTexture2:Hide()
    MainMenuBarTexture3:Hide()
    MainMenuBar:SetWidth(510)

    if MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 15)
    end

    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()
    MainMenuBarPageNumber:Hide()

    MainMenuBarBackpackButton:ClearAllPoints();
    MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 2);
    MainMenuBarBackpackButtonNormalTexture:Hide()

    CharacterBag0Slot:ClearAllPoints()
    CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -3, -2)
    CharacterBag0SlotNormalTexture:Hide()
    CharacterBag1SlotNormalTexture:Hide()
    CharacterBag2SlotNormalTexture:Hide()
    CharacterBag3SlotNormalTexture:Hide()

    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 2, 2)
    CharacterMicroButton.SetPoint = function() end

    MultiBarBottomLeft:SetMovable(true)
    MultiBarBottomLeft:SetUserPlaced(true)
    MultiBarBottomLeft:UnregisterAllEvents();
    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetWidth(500)
    MultiBarBottomLeft:SetHeight(40)
    if MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
        MultiBarBottomLeft:SetPoint("BOTTOM", UIParent, "BOTTOM", 3, 61)
    else
        MultiBarBottomLeft:SetPoint("BOTTOM", UIParent, "BOTTOM", 3, 45)
    end
    MultiBarBottomLeft.SetPoint = function() end

    local childrenMultiBarRight = { MultiBarRight:GetChildren() }
    local previousChildMultiBarRight;
    for _, child in ipairs(childrenMultiBarRight) do
        child:ClearAllPoints()

        if previousChildMultiBarRight then
            child:SetPoint("LEFT", previousChildMultiBarRight, "RIGHT", 6, 0)
        else
            child:SetPoint("LEFT", MultiBarRight, "LEFT", 0, 0)
        end

        previousChildMultiBarRight = child
    end

    MultiBarRight:SetMovable(true)
    MultiBarRight:SetUserPlaced(true)
    MultiBarRight:UnregisterAllEvents();
    MultiBarRight:ClearAllPoints()
    MultiBarRight:SetWidth(500)
    MultiBarRight:SetHeight(40)
    if MainMenuExpBar:IsShown() or ReputationWatchBar:IsShown() then
        MultiBarRight:SetPoint("BOTTOM", UIParent, "BOTTOM", 3, 101)
    else
        MultiBarRight:SetPoint("BOTTOM", UIParent, "BOTTOM", 3, 85)
    end
    MultiBarRight.SetPoint = function() end

    MultiBarLeft:SetMovable(true)
    MultiBarLeft:SetUserPlaced(true)
    MultiBarLeft:UnregisterAllEvents();
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetPoint("RIGHT", UIParent, "RIGHT", -2, 0)
    --MultiBarLeft.SetPoint = function() end

    StanceBarFrame:SetMovable(true)
    StanceBarFrame:SetUserPlaced(true)
    StanceBarFrame:UnregisterAllEvents();
    StanceBarFrame:ClearAllPoints()
    StanceBarFrame:SetPoint("BOTTOMLEFT", MultiBarRight, "TOPLEFT", 0, 3)
    --StanceBarFrame.SetPoint = function() end

    PetActionBarFrame:SetMovable(true)
    PetActionBarFrame:SetUserPlaced(true)
    PetActionBarFrame:UnregisterAllEvents();
    PetActionBarFrame:ClearAllPoints()
    PetActionBarFrame:SetPoint("BOTTOMLEFT", StanceBarFrame, "TOPLEFT", -4, 3)
    --PetActionBarFrame.SetPoint = function() end

    ReputationWatchBar:SetWidth(510)
    ReputationWatchBar.StatusBar:SetWidth(510)
    ReputationWatchBar.StatusBar.XPBarTexture1:Hide()
    ReputationWatchBar.StatusBar.XPBarTexture2:Hide()
    ReputationWatchBar.StatusBar.XPBarTexture3:ClearAllPoints()
    ReputationWatchBar.StatusBar.XPBarTexture3:SetPoint("LEFT", ReputationWatchBar.StatusBar.XPBarTexture0, "RIGHT", 0, 0)
    ReputationWatchBar:SetMovable(true)
    ReputationWatchBar:SetUserPlaced(true)
    ReputationWatchBar:UnregisterAllEvents();
    ReputationWatchBar:ClearAllPoints()
    ReputationWatchBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    --ReputationWatchBar.SetPoint = function() end

    MainMenuExpBar:SetWidth(510)
    ExhaustionLevelFillBar:SetWidth(510)
    MainMenuXPBarTexture0:ClearAllPoints()
    MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT", 0, 0)
    MainMenuXPBarTexture1:Hide()
    MainMenuXPBarTexture2:Hide()
    MainMenuXPBarTexture3:ClearAllPoints()
    MainMenuXPBarTexture3:SetPoint("LEFT", MainMenuXPBarTexture0, "RIGHT", 0, 0)
    MainMenuExpBar:ClearAllPoints()
    MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    --MainMenuExpBar.SetPoint = function() end

    self:TidyIcons_Update()
end