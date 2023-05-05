function ScarletUI:SetupUnitFrames()
    PlayerFrame:SetMovable(true)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", -65, -200)

    TargetFrame:SetMovable(true)
    TargetFrame:SetUserPlaced(true)
    TargetFrame:ClearAllPoints()
    TargetFrame:SetPoint("TOPLEFT", UIParent, "CENTER", 65, -200)

    if FocusFrame then
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", -60, 150)
    end

    CompactRaidFrameManagerContainerResizeFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 650, -450)

    self:SetupClassColoredFrames()
end

function ScarletUI:SetupClassColoredFrames()
    -- Create background frame for player frame
    local PlayFN = CreateFrame("FRAME", nil, PlayerFrame)
    PlayFN:SetWidth(TargetFrameNameBackground:GetWidth())
    PlayFN:SetHeight(TargetFrameNameBackground:GetHeight())

    local _, _, _, x, y = TargetFrameNameBackground:GetPoint()
    PlayFN:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)

    PlayFN.t = PlayFN:CreateTexture(nil, "BORDER")
    PlayFN.t:SetAllPoints()
    PlayFN.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")

    local c = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
    if c then PlayFN.t:SetVertexColor(c.r, c.g, c.b) end

    -- Create color function for target and focus frames
    local function TargetFrameCol()
        if UnitIsPlayer("target") then
            local targetColor = RAID_CLASS_COLORS[select(2, UnitClass("target"))]
            if targetColor then TargetFrameNameBackground:SetVertexColor(c.r, c.g, c.b) end
        end
        if UnitIsPlayer("focus") then
            local focusColor = RAID_CLASS_COLORS[select(2, UnitClass("focus"))]
            if focusColor then FocusFrameNameBackground:SetVertexColor(c.r, c.g, c.b) end
        end
    end

    local ColTar = CreateFrame("FRAME")
    ColTar:SetScript("OnEvent", TargetFrameCol) -- Events are registered if target option is enabled

    -- Refresh color if focus frame size changes
    if FocusFrame_SetSmallSize then
        hooksecurefunc("FocusFrame_SetSmallSize", function()
            TargetFrameCol()
        end)
    end

    -- Player frame
    PlayFN:Show()

    -- Target and focus frames
    ColTar:RegisterEvent("GROUP_ROSTER_UPDATE")
    ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
    ColTar:RegisterEvent("PLAYER_FOCUS_CHANGED")
    ColTar:RegisterEvent("UNIT_FACTION")
    TargetFrameCol()
end