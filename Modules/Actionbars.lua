function ScarletUI:SetupActionbars()
    if MicroButtonAndBagsBar then
        MainMenuBarBackpackButton:ClearAllPoints();
        MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 2);

        CharacterBag0Slot:ClearAllPoints()
        CharacterBag0Slot:SetPoint("RIGHT", MainMenuBarBackpackButton, "LEFT", -2, -4)

        CharacterMicroButton:ClearAllPoints()
        CharacterMicroButton:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 2, 2)
        CharacterMicroButton.SetPoint = function() end

        MicroButtonAndBagsBar.MicroBagBar:Hide()
    end

    if MainMenuBarArtFrameBackground then
        MainMenuBarArtFrameBackground:Hide()
    end

    if MainMenuBarArtFrame.LeftEndCap and MainMenuBarArtFrame.RightEndCap then
        MainMenuBarArtFrame.LeftEndCap:Hide()
        MainMenuBarArtFrame.RightEndCap:Hide()
    end

    MultiBarBottomLeft:SetMovable(true)
    MultiBarBottomLeft:SetUserPlaced(true)
    MultiBarBottomLeft:ClearAllPoints()
    MultiBarBottomLeft:SetWidth(500)
    MultiBarBottomLeft:SetHeight(40)
    MultiBarBottomLeft:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, 6)
    MultiBarBottomLeft.SetPoint = function() end

    local childrenMultiBarRight = { MultiBarRight:GetChildren() }
    local previousChildMultiBarRight;
    for __, child in ipairs(childrenMultiBarRight) do
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
    MultiBarRight:ClearAllPoints()
    MultiBarRight:SetWidth(500)
    MultiBarRight:SetHeight(40)
    MultiBarRight:SetPoint("BOTTOMLEFT", MultiBarBottomLeft, "TOPLEFT", 0, -1)
    MultiBarRight.SetPoint = function() end

    MultiBarLeft:SetMovable(true)
    MultiBarLeft:SetUserPlaced(true)
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetPoint("RIGHT", UIParent, "RIGHT", -2, 0)
    MultiBarLeft.SetPoint = function() end

    StanceBarFrame:SetMovable(true)
    StanceBarFrame:SetUserPlaced(true)
    StanceBarFrame:ClearAllPoints()
    StanceBarFrame:SetPoint("BOTTOMLEFT", MultiBarRight, "TOPLEFT", 0, 3)
    StanceBarFrame.SetPoint = function() end

    PetActionBarFrame:SetMovable(true)
    PetActionBarFrame:SetUserPlaced(true)
    PetActionBarFrame:ClearAllPoints()
    PetActionBarFrame:SetPoint("BOTTOMLEFT", StanceBarFrame, "TOPLEFT", -4, 3)
    PetActionBarFrame.SetPoint = function() end

    ScarletUI:TidyIcons_Update()
end