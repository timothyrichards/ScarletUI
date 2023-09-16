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

local function multiBarRight()
    ScarletUI:ConvertBarToHorizontal(MultiBarRight)
    MultiBarRight:SetMovable(true)
    MultiBarRight:SetUserPlaced(true)
    MultiBarRight:UnregisterAllEvents();
    MultiBarRight:ClearAllPoints()
    MultiBarRight:SetWidth(500)
    MultiBarRight:SetHeight(40)
    MultiBarRight:SetPoint("BOTTOM", MultiBarBottomRight, "TOP", 0, 0)
end

local function multiBarLeft()
    ScarletUI:ConvertBarToHorizontal(MultiBarLeft)
    MultiBarLeft:SetMovable(true)
    MultiBarLeft:SetUserPlaced(true)
    MultiBarLeft:UnregisterAllEvents();
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetWidth(500)
    MultiBarLeft:SetHeight(40)
    MultiBarLeft:SetPoint("BOTTOM", MultiBarRight, "TOP", 0, 2)
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
        MainMenuExpBar:HookScript('OnShow', function()
            ScarletUI:UpdateMainBar()
        end)
        MainMenuExpBar:HookScript('OnHide', function()
            ScarletUI:UpdateMainBar()
        end)
    end
    MainMenuExpBar:SetWidth(510)
    MainMenuBarMaxLevelBar.Show = function()
        MainMenuBarMaxLevelBar:Hide()
    end
    ExhaustionLevelFillBar:SetPoint("TOPRIGHT", MainMenuExpBar, "TOPLEFT", 510, 0)
    ExhaustionTick:SetPoint("CENTER", MainMenuExpBar, "LEFT", 510, 0)
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
        ReputationWatchBar:HookScript('OnShow', function()
            ScarletUI:UpdateMainBar()
        end)
        ReputationWatchBar:HookScript('OnHide', function()
            ScarletUI:UpdateMainBar()
        end)
    end
    ReputationWatchBar:SetWidth(510)
    ReputationWatchBar.StatusBar:SetWidth(510)
    ReputationWatchBar.StatusBar.WatchBarTexture1.Show = function()
        ReputationWatchBar.StatusBar.WatchBarTexture1:Hide()
    end
    ReputationWatchBar.StatusBar.WatchBarTexture2.Show = function()
        ReputationWatchBar.StatusBar.WatchBarTexture2:Hide()
    end
    ReputationWatchBar.StatusBar.WatchBarTexture2:Hide()
    ReputationWatchBar.StatusBar.WatchBarTexture3:ClearAllPoints()
    ReputationWatchBar.StatusBar.WatchBarTexture3:SetPoint("LEFT", ReputationWatchBar.StatusBar.WatchBarTexture0, "RIGHT", 0, 0)
end

function ScarletUI:SetupActionbars()
    local actionbarsModule = self.db.global.actionbarsModule;
    if not actionbarsModule.enabled then
        return
    end

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

function ScarletUI:RevertSidebars()
    local childrenMultiBarRight = { MultiBarRight:GetChildren() }
    local previousChildMultiBarRight;
    for _, child in ipairs(childrenMultiBarRight) do
        child:ClearAllPoints()

        if previousChildMultiBarRight then
            child:SetPoint("TOP", previousChildMultiBarRight, "BOTTOM", 0, -6)
        else
            child:SetPoint("TOPRIGHT", MultiBarRight, "TOPRIGHT", -2, -3)
        end

        previousChildMultiBarRight = child
    end

    MultiBarRight:SetWidth(40)
    MultiBarRight:SetHeight(500)
    MultiBarRight:ClearAllPoints()
    MultiBarRight:SetPoint("TOPRIGHT", VerticalMultiBarsContainer, "TOPRIGHT", 0, 0)

    for i=1,12 do
        local background = _G["MultiBarLeftButton"..i.."FloatingBG"]
        background:Show()
    end

    local childrenMultiBarLeft = { MultiBarLeft:GetChildren() }
    local previousChildMultiBarLeft;
    for _, child in ipairs(childrenMultiBarLeft) do
        child:ClearAllPoints()

        if previousChildMultiBarLeft then
            child:SetPoint("TOP", previousChildMultiBarLeft, "BOTTOM", 0, -6)
        else
            child:SetPoint("TOPRIGHT", MultiBarLeft, "TOPRIGHT", -2, -3)
        end

        previousChildMultiBarLeft = child
    end

    MultiBarLeft:SetWidth(40)
    MultiBarLeft:SetHeight(500)
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetPoint("TOPRIGHT", MultiBarRight, "TOPLEFT", -2, 0)
end

function ScarletUI:ConvertBarToHorizontal(bar)
    local children = { bar:GetChildren() }
    local previousChild;
    for _, child in ipairs(children) do
        child:ClearAllPoints()

        if previousChild then
            child:SetPoint("LEFT", previousChild, "RIGHT", 6, 0)
        else
            child:SetPoint("LEFT", bar, "LEFT", 0, 0)
        end

        previousChild = child
    end
end