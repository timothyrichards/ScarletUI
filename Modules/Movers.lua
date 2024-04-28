local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

ScarletUI.movers = {}

ScarletUI.frameAnchors = {
    'BOTTOM',
    'BOTTOMLEFT',
    'BOTTOMRIGHT',
    'CENTER',
    'LEFT',
    'RIGHT',
    'TOP',
    'TOPLEFT',
    'TOPRIGHT',
}

function ScarletUI:CreateMover(targetFrame, module)
    if targetFrame.mover then
        return targetFrame.mover
    end

    local targetFrameName = targetFrame:GetName()

    targetFrame:SetMovable(true)
    targetFrame:SetClampedToScreen(true)

    local mover = CreateFrame("Frame", targetFrameName .. "Mover", UIParent)
    mover.targetFrame = targetFrame
    mover:SetSize(targetFrame:GetWidth(), targetFrame:GetHeight())
    mover:SetPoint("BOTTOM", targetFrame, "BOTTOM", 0, 0)
    mover:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Background
    local bg = mover:CreateTexture("Background", "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.4, 0.6, 1, 0.5) -- light blue background

    -- Border
    local borderSize = 4
    local borders = {
        mover:CreateTexture("TopBorder", "BORDER"),
        mover:CreateTexture("BottomBorder", "BORDER"),
        mover:CreateTexture("LeftBorder", "BORDER"),
        mover:CreateTexture("RightBorder", "BORDER"),
    }

    for _, border in ipairs(borders) do
        border:SetColorTexture(0.2, 0.4, 0.8, 1)
    end

    borders[1]:SetPoint("TOPLEFT", mover, "TOPLEFT")
    borders[1]:SetPoint("TOPRIGHT", mover, "TOPRIGHT")
    borders[1]:SetHeight(borderSize)

    borders[2]:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT")
    borders[2]:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT")
    borders[2]:SetHeight(borderSize)

    borders[3]:SetPoint("TOPLEFT", mover, "TOPLEFT")
    borders[3]:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT")
    borders[3]:SetWidth(borderSize)

    borders[4]:SetPoint("TOPRIGHT", mover, "TOPRIGHT")
    borders[4]:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT")
    borders[4]:SetWidth(borderSize)

    -- Display the frame's name in the center of the mover
    local text = mover:CreateFontString("FrameName", "OVERLAY", "GameFontNormal")
    text:SetText(targetFrameName)
    text:SetPoint("CENTER", mover, "CENTER")

    mover:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and targetFrame:IsMovable() then
            targetFrame:StartMoving()
        end
    end)

    mover:SetScript("OnMouseUp", function(_, _)
        targetFrame:StopMovingOrSizing()
        if module ~= nil then
            self:UpdateFramePositionSettings(targetFrame, module)
        end
    end)

    mover:Hide()

    -- Hook into the SetSize method
    hooksecurefunc(targetFrame, "SetSize", function()
        mover:SetSize(targetFrame:GetWidth(), targetFrame:GetHeight())
    end)

    -- Hook into the SetWidth method (in case width is adjusted independently)
    hooksecurefunc(targetFrame, "SetWidth", function()
        mover:SetWidth(targetFrame:GetWidth())
    end)

    -- Hook into the SetHeight method (in case height is adjusted independently)
    hooksecurefunc(targetFrame, "SetHeight", function()
        mover:SetHeight(targetFrame:GetHeight())
    end)

    targetFrame.mover = mover
    self.movers[targetFrameName] = mover
    return mover
end

function ScarletUI:ToggleMovers()
    if self.moversEnabled then
        self.moversEnabled = false
    elseif not self.moversEnabled then
        self.moversEnabled = true
    end

    for _, v in pairs(self.movers) do
        if self.moversEnabled then
            v:SetMovable(true)
            v:Show()
        else
            v:SetMovable(false)
            v:Hide()
        end
    end
end

function ScarletUI:UpdateFramePositionSettings(frame, module)
    local point, _, relativePoint, xOffset, yOffset = frame:GetPoint()
    module.frameAnchor = self:GetArrayIndex(point)
    module.screenAnchor = self:GetArrayIndex(relativePoint)
    module.x = xOffset
    module.y = yOffset
    AceConfigRegistry:NotifyChange("ScarletUI")
end

function ScarletUI:ResetPositions()
    local db = self.db.global
    local defaults = self.defaults.global
    local frames = {
        "unitFramesModule.playerFrame",
        "unitFramesModule.targetFrame",
        "unitFramesModule.focusFrame",
        "actionbarsModule.mainBar",
        "actionbarsModule.stanceBar",
        "actionbarsModule.petBar",
        "actionbarsModule.multiCastBar",
        "actionbarsModule.microBar",
        "actionbarsModule.bagBar",
        "chatModule.chatFrame",
    }
    local settings = {
        "frameAnchor",
        "screenAnchor",
        "x",
        "y",
    }

    for _, framePath in ipairs(frames) do
        local frameParts = {}
        for part in string.gmatch(framePath, "[^.]+") do
            table.insert(frameParts, part)
        end
        local frameCategory, frameName = frameParts[1], frameParts[2]
        for _, setting in ipairs(settings) do
            if defaults[frameCategory] and defaults[frameCategory][frameName] and defaults[frameCategory][frameName][setting] then
                db[frameCategory][frameName][setting] = defaults[frameCategory][frameName][setting]
            end
        end
    end

    self:Setup(false)
    AceConfigRegistry:NotifyChange("ScarletUI")
    StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
end

function ScarletUI:SetPoint(frame, frameAnchor, frameParent, parentAnchor, x, y)
    if self:InCombat() then
        return
    end

    if not frame.SetPointBackup then
        frame.SetPointBackup = frame.SetPoint
    else
        frame.SetPoint = frame.SetPointBackup
    end

    frame:SetPoint(frameAnchor, frameParent, parentAnchor, x, y)
    frame.SetPoint = function() end
end
