function ScarletUI:SetupUnitFrames()
    local unitFramesModule = ScarletUI.db.global.unitFramesModule

    if unitFramesModule.playerFrame.move then
        ScarletUI:SetupPlayerFrame(unitFramesModule)
    end

    if unitFramesModule.targetFrame.move then
        ScarletUI:SetupTargetFrame(unitFramesModule)
    end

    if unitFramesModule.focusFrame.move then
        ScarletUI:SetupFocusFrame(unitFramesModule)
    end

    -- Change health bar to class color
    --hooksecurefunc("UnitFrameHealthBar_Update", function(self)
    --    if UnitIsPlayer(self.unit) then
    --        local _, class = UnitClass(self.unit)
    --        local c = RAID_CLASS_COLORS[class]
    --        if c then
    --            self:SetStatusBarColor(c.r, c.g, c.b)
    --            if self.t then
    --                self.t:Hide()
    --            end
    --        end
    --    else
    --        local reaction = UnitReaction("target", "player")
    --        local c = FACTION_BAR_COLORS[reaction]
    --        if c then
    --            self:SetStatusBarColor(c.r, c.g, c.b)
    --            if self.t then
    --                self.t:Hide()
    --            end
    --        end
    --    end
    --end)
end

function ScarletUI:SetupPlayerFrame(unitFramesModule)
    PlayerFrame:SetMovable(true)
    PlayerFrame:SetUserPlaced(true)
    PlayerFrame:ClearAllPoints()
    PlayerFrame:SetPoint("TOPRIGHT", UIParent, "CENTER", unitFramesModule.playerFrame.x, unitFramesModule.playerFrame.y)

    -- Move mana bar to health bar position
    --local _, _, _, x, y = PlayerFrameHealthBar:GetPoint()
    --PlayerFrameManaBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", x, y)
    --
    --PlayerFrameManaBarTextLeft:ClearAllPoints()
    --PlayerFrameManaBarTextLeft:SetPoint("LEFT", PlayerFrameManaBar, "LEFT", 5, 0)
    --
    --PlayerFrameManaBarTextRight:ClearAllPoints()
    --PlayerFrameManaBarTextRight:SetPoint("RIGHT", PlayerFrameManaBar, "RIGHT", 0, 0)

    -- Move health bar to name bar position
    --PlayerFrameHealthBar:SetWidth(TargetFrameNameBackground:GetWidth())
    --PlayerFrameHealthBar:SetHeight(TargetFrameNameBackground:GetHeight())
    --
    --local _, _, _, x, y = TargetFrameNameBackground:GetPoint()
    --PlayerFrameHealthBar:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)
    --PlayerFrameHealthBar.t = PlayerFrameHealthBar:CreateTexture(nil, "BORDER")
    --PlayerFrameHealthBar.t:SetAllPoints()
    --PlayerFrameHealthBar.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
    --
    --PlayerFrameHealthBarTextLeft:ClearAllPoints()
    --PlayerFrameHealthBarTextLeft:SetPoint("LEFT", PlayerFrameHealthBar, "LEFT", 5, 0)
    --
    --PlayerFrameHealthBarTextRight:ClearAllPoints()
    --PlayerFrameHealthBarTextRight:SetPoint("RIGHT", PlayerFrameHealthBar, "RIGHT", 0, 0)

    -- Move name
    --PlayerName:ClearAllPoints()
    --PlayerName:SetPoint("BOTTOM", PlayerFrameHealthBar, "TOP", 0, 5)
end

function ScarletUI:SetupTargetFrame(unitFramesModule)
    TargetFrame:SetMovable(true)
    TargetFrame:SetUserPlaced(true)
    TargetFrame:ClearAllPoints()
    if not unitFramesModule.targetFrame.mirrorPlayerFrame then
        TargetFrame:SetPoint("TOPLEFT", UIParent, "CENTER", unitFramesModule.targetFrame.x, unitFramesModule.targetFrame.y)
    else
        TargetFrame:SetPoint("TOPLEFT", UIParent, "CENTER", unitFramesModule.playerFrame.x * -1, unitFramesModule.playerFrame.y)
    end

    -- Move mana bar to health bar position
    --local _, _, _, x, y = TargetFrameHealthBar:GetPoint()
    --TargetFrameManaBar:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", x, y)
    --
    --TargetFrameManaBarTextLeft:ClearAllPoints()
    --TargetFrameManaBarTextLeft:SetPoint("LEFT", TargetFrameManaBar, "LEFT", 5, 0)
    --
    --TargetFrameManaBarTextRight:ClearAllPoints()
    --TargetFrameManaBarTextRight:SetPoint("RIGHT", TargetFrameManaBar, "RIGHT", 0, 0)

    -- Move health bar to name bar position
    --TargetFrameHealthBar:SetWidth(TargetFrameNameBackground:GetWidth())
    --TargetFrameHealthBar:SetHeight(TargetFrameNameBackground:GetHeight())
    --
    --local _, _, _, x, y = TargetFrameNameBackground:GetPoint()
    --TargetFrameHealthBar:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", x, y)
    --TargetFrameHealthBar.t = TargetFrameHealthBar:CreateTexture(nil, "BORDER")
    --TargetFrameHealthBar.t:SetAllPoints()
    --TargetFrameHealthBar.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")
    --
    --TargetFrameHealthBarTextLeft:ClearAllPoints()
    --TargetFrameHealthBarTextLeft:SetPoint("LEFT", TargetFrameHealthBar, "LEFT", 5, 0)
    --
    --TargetFrameHealthBarTextRight:ClearAllPoints()
    --TargetFrameHealthBarTextRight:SetPoint("RIGHT", TargetFrameHealthBar, "RIGHT", 0, 0)
    --
    --TargetFrameTextureFrameName:ClearAllPoints()
    --TargetFrameTextureFrameName:SetPoint("BOTTOM", TargetFrameHealthBar, "TOP", 0, 5)
end

function ScarletUI:SetupFocusFrame(unitFramesModule)
    if FocusFrame then
        FocusFrame:SetMovable(true)
        FocusFrame:SetUserPlaced(true)
        FocusFrame:ClearAllPoints()
        FocusFrame:SetPoint("TOPLEFT", UIParent, "CENTER", unitFramesModule.focusFrame.x, unitFramesModule.focusFrame.y)
    end
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

function ScarletUI:UpdateActiveRaidProfile()
    if not IsAddOnLoaded('Blizzard_CUFProfiles') then
        LoadAddOn("Blizzard_CUFProfiles")
    end

    local activeRaidProfile = GetActiveRaidProfile()
    if IsInRaid() and activeRaidProfile ~= 'Raid' then
        ScarletUI.settings:Print("Setting Raid Profile to 'Raid'.")
        CompactUnitFrameProfiles_ActivateRaidProfile('Raid')
    elseif not IsInRaid() and activeRaidProfile ~= 'Party' then
        ScarletUI.settings:Print("Setting Raid Profile to 'Party'.")
        CompactUnitFrameProfiles_ActivateRaidProfile('Party')
    end
end