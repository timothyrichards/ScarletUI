local function mainMenuBar()
    MainMenuBarLeftEndCap:Hide()
    MainMenuBarRightEndCap:Hide()
    MainMenuBarMaxLevelBar:Hide()
    MainMenuBarPerformanceBarFrame:Hide()
    MainMenuBarTexture0:Hide()
    MainMenuBarTexture1:Hide()
    MainMenuBarTexture2:Hide()
    MainMenuBarTexture3:Hide()
    MainMenuBar:SetWidth(510)
    ActionButton1:SetPoint("BOTTOMLEFT", MainMenuBarArtFrame, "BOTTOMLEFT", 7, 4)

    MainMenuBarPageNumber:Hide()
    ActionBarUpButton:Hide()
    ActionBarDownButton:Hide()

    ScarletUI.Frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    ScarletUI:UpdateMainBar()

    for i = 1, 12 do
        local button = _G["ActionButton"..i]
        button:SetAttribute("showgrid", 1)
        ActionButton_Update(button)
    end

    --[[
    TODO: fix this stupid hack
    the code above makes the main actionbar action slots show all the time,
    but the change doesn't apply till an ability is moved on the bars,
    so the code below forcefully picks up and places down the same ability just to satisfy that condition
    ]]--
    PickupAction(_G["ActionButton1"].action)
    PlaceAction(_G["ActionButton1"].action)
end

local function microBar()
    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 2, 2)
    CharacterMicroButton.SetPoint = function() end
end

local function bagBar()
    MainMenuBarBackpackButton:ClearAllPoints();
    MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 2);
    MainMenuBarBackpackButtonNormalTexture:Hide()

    CharacterBag0Slot:ClearAllPoints()
    CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -5, 0)
    CharacterBag0SlotNormalTexture:Hide()
    CharacterBag1SlotNormalTexture:Hide()
    CharacterBag2SlotNormalTexture:Hide()
    CharacterBag3SlotNormalTexture:Hide()
end

local function multiBarBottomLeft()
    for i=1,12 do
        local background = _G["MultiBarBottomLeftButton"..i.."FloatingBG"]
        background:Hide()
    end

    MultiBarBottomLeft:SetMovable(true)
    MultiBarBottomLeft:SetUserPlaced(true)
    MultiBarBottomLeft:UnregisterAllEvents();
    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetWidth(500)
    MultiBarBottomLeft:SetHeight(40)
    MultiBarBottomLeft:SetPoint("BOTTOM", MainMenuBar, "TOP", 2, -6)
    --MultiBarBottomLeft.SetPoint = function() end
end

local function multiBarBottomRight()
    for i=1,12 do
        local background = _G["MultiBarBottomRightButton"..i.."FloatingBG"]
        background:Hide()
    end

    MultiBarBottomRight:SetMovable(true)
    MultiBarBottomRight:SetUserPlaced(true)
    MultiBarBottomRight:UnregisterAllEvents();
    MultiBarBottomRight:ClearAllPoints()
    MultiBarBottomRight:SetWidth(500)
    MultiBarBottomRight:SetHeight(40)
    MultiBarBottomRight:SetPoint("BOTTOM", MultiBarBottomLeft, "TOP", 0, 2)
    --MultiBarBottomRight.SetPoint = function() end
end

local function multiBarRight()
    for i=1,12 do
        local background = _G["MultiBarRightButton"..i.."FloatingBG"]
        background:Hide()
    end

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
    MultiBarRight:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 0)
    --MultiBarRight.SetPoint = function() end
end

local function multiBarLeft()
    for i=1,12 do
        local background = _G["MultiBarLeftButton"..i.."FloatingBG"]
        background:Hide()
    end

    local childrenMultiBarLeft = { MultiBarLeft:GetChildren() }
    local previousChildMultiBarLeft;
    for _, child in ipairs(childrenMultiBarLeft) do
        child:ClearAllPoints()

        if previousChildMultiBarLeft then
            child:SetPoint("LEFT", previousChildMultiBarLeft, "RIGHT", 6, 0)
        else
            child:SetPoint("LEFT", MultiBarLeft, "LEFT", 0, 0)
        end

        previousChildMultiBarLeft = child
    end

    MultiBarLeft:SetMovable(true)
    MultiBarLeft:SetUserPlaced(true)
    MultiBarLeft:UnregisterAllEvents();
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetWidth(500)
    MultiBarLeft:SetHeight(40)
    MultiBarLeft:SetPoint("BOTTOM", MultiBarRight, "TOP", 0, 2)
    --MultiBarLeft.SetPoint = function() end
end

local function stanceBar(parent)
    StanceBarFrame:SetMovable(true)
    StanceBarFrame:SetUserPlaced(true)
    StanceBarFrame:UnregisterAllEvents();
    StanceBarFrame:ClearAllPoints()
    StanceBarFrame:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 1)
    --StanceBarFrame.SetPoint = function() end
end

local function multiCastBar(parent)
    if MultiCastActionBarFrame then
        MultiCastActionBarFrame:SetMovable(true)
        MultiCastActionBarFrame:SetUserPlaced(true)
        MultiCastActionBarFrame:UnregisterAllEvents();
        MultiCastActionBarFrame:ClearAllPoints()
        MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 1)
        --StanceBarFrame.SetPoint = function() end
    end
end

local function petActionBar(parent)
    PetActionBarFrame:SetMovable(true)
    PetActionBarFrame:SetUserPlaced(true)
    --PetActionBarFrame:UnregisterAllEvents();
    PetActionBarFrame:ClearAllPoints()
    PetActionBarFrame:SetPoint("BOTTOM", parent, "TOP", 0, 1)
    --PetActionBarFrame.SetPoint = function() end
end

local function experienceBar()
    MainMenuExpBar:SetWidth(510)
    ExhaustionLevelFillBar:SetPoint("TOPRIGHT", MainMenuExpBar, "TOPLEFT", 510, 0)
    ExhaustionTick:SetPoint("CENTER", MainMenuExpBar, "LEFT", 510, 0)
    MainMenuXPBarTexture0:ClearAllPoints()
    MainMenuXPBarTexture0:SetPoint("LEFT", MainMenuExpBar, "LEFT", 0, 0)
    MainMenuXPBarTexture1:Hide()
    MainMenuXPBarTexture2:Hide()
    MainMenuXPBarTexture3:ClearAllPoints()
    MainMenuXPBarTexture3:SetPoint("LEFT", MainMenuXPBarTexture0, "RIGHT", 0, 0)
    MainMenuExpBar:ClearAllPoints()
    MainMenuExpBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    --MainMenuExpBar.SetPoint = function() end
end

local function reputationBar()
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
end

function ScarletUI:SetupActionbars()
    local actionbarsModule = ScarletUI.db.global.actionbarsModule;

    local multiBarBottomLeftValue = InterfaceOptionsActionBarsPanelBottomLeft.value == '1'
    local multiBarBottomRightValue = InterfaceOptionsActionBarsPanelBottomRight.value == '1'
    if actionbarsModule.stackActionbars and multiBarBottomLeftValue and multiBarBottomRightValue then
        mainMenuBar()
        microBar()
        bagBar()
        multiBarBottomLeft()
        multiBarBottomRight()

        local parent = MultiBarBottomRight;
        local multiBarLeftValue = InterfaceOptionsActionBarsPanelBottomLeft.value == '1'
        local multiBarRightValue = InterfaceOptionsActionBarsPanelBottomRight.value == '1'
        if actionbarsModule.stackSidebars and multiBarLeftValue and multiBarRightValue then
            multiBarRight()
            multiBarLeft()
            parent = MultiBarLeft;
        end

        stanceBar(parent)
        multiCastBar(parent)
        petActionBar(parent)
        experienceBar()
        reputationBar()
    end
end