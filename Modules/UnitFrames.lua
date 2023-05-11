function ScarletUI:SetupUnitFrames()
    PlayerFrame:SetMovable(true)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", -65, -190)

    TargetFrame:SetMovable(true)
    TargetFrame:SetUserPlaced(true)
    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("TOPLEFT", UIParent, "CENTER", 65, -190)

    if FocusFrame then
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", -60, 150)
    end
end
