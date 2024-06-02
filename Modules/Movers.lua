local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

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

function ScarletUI:MoversOptions()
    local global = self.db.global
    if self.selectedMover == nil then
        self.selectedMover = PlayerFrameMover
    end

    local frameOptions = {}
    if self.selectedMover == PlayerFrameMover then
        frameOptions = self:GetUnitFramesModuleSettingsPage(global.unitFramesModule, global.unitFramesModule, 0).args.playerFrame
    elseif self.selectedMover == TargetFrameMover then
        frameOptions = self:GetUnitFramesModuleSettingsPage(global.unitFramesModule, global.unitFramesModule, 0).args.targetFrame
    elseif self.selectedMover == FocusFrameMover then
        frameOptions = self:GetUnitFramesModuleSettingsPage(global.unitFramesModule, global.unitFramesModule, 0).args.focusFrame
    elseif self.selectedMover == ChatFrame1Mover then
        frameOptions = self:GetChatModuleSettingsPage(global.chatModule, global.chatModule, 0).args.chatFrame
    elseif self.selectedMover == MainMenuBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.mainBar
    elseif self.selectedMover == StanceBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.stanceBar
    elseif self.selectedMover == PetBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.petBar
    elseif self.selectedMover == MultiCastBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.multiCastBar
    elseif self.selectedMover == MicroBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.microBar
    elseif self.selectedMover == BagBarMover then
        frameOptions = self:GetActionbarsModuleSettingsPage(global, global.actionbarsModule, 0).args.bagBar
    end

    frameOptions.inline = true
    frameOptions.order = 3

    return {
        type = "group",
        name = "Movers",
        childGroups = "tab",
        order = 1,
        args = {
            toggleMovers = {
                type = "execute",
                name = "Toggle Movers",
                desc = "Toggle the visibility of all movers",
                func = function() self:ToggleMovers() end,
                order = 1,
            },
            resetPositions = {
                type = "execute",
                name = "Reset Positions",
                desc = "Reset all frame positions to their default settings",
                func = function() self:ResetPositions() end,
                order = 2,
            },
            frame = frameOptions
        },
    }
end

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
            self.selectedMover = mover
            AceConfigRegistry:NotifyChange("ScarletUI_Movers")
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

function ScarletUI:CreateGrid()
    if self.grid then
        return
    end

    local gridSize = 32
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    local gridWidth = ceil(screenWidth / gridSize)
    local gridHeight = ceil(screenHeight / gridSize)

    -- Calculate the offset needed to center the grid
    local offsetX = (screenWidth - gridSize * gridWidth) / 2
    local offsetY = (screenHeight - gridSize * gridHeight) / 2 - 0.5

    self.grid = self.grid or CreateFrame("Frame", "SUI_Grid", UIParent)
    self.grid:SetAllPoints(UIParent)
    self.grid:SetFrameStrata("BACKGROUND")

    local texturePath = "Interface\\BUTTONS\\WHITE8X8"

    for i = 0, gridHeight do
        local texture = self.grid:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture(texturePath)
        texture:SetSize(screenWidth, 1)
        texture:SetColorTexture(1, 1, 1, 0.5)
        texture:SetPoint("TOPLEFT", self.grid, "TOPLEFT", offsetX, -gridSize * i - offsetY)
    end

    for i = 0, gridWidth do
        local texture = self.grid:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture(texturePath)
        texture:SetSize(1, screenHeight)
        texture:SetColorTexture(1, 1, 1, 0.5)
        texture:SetPoint("TOPLEFT", self.grid, "TOPLEFT", gridSize * i + offsetX, -offsetY)
    end

    -- Create a center vertical line
    local verticalLine = self.grid:CreateTexture(nil, "BACKGROUND")
    verticalLine:SetTexture(texturePath)
    verticalLine:SetSize(1, screenHeight)
    verticalLine:SetColorTexture(1, 0, 0, 1)
    verticalLine:SetPoint("CENTER", self.grid)

    -- Create a center horizontal line
    local horizontalLine = self.grid:CreateTexture(nil, "BACKGROUND")
    horizontalLine:SetTexture(texturePath)
    horizontalLine:SetSize(screenWidth, 1)
    horizontalLine:SetColorTexture(1, 0, 0, 1)
    horizontalLine:SetPoint("CENTER", self.grid)

    self.grid:Hide()
end

function ScarletUI:ToggleMovers()
    self:CreateGrid()
    if self.moversEnabled then
        self.moversEnabled = false
        self.grid:Hide()
        AceConfigDialog:Open("ScarletUI")
        AceConfigDialog:Close("ScarletUI_Movers")
    elseif not self.moversEnabled then
        self.moversEnabled = true
        self.grid:Show()
        AceConfigDialog:Close("ScarletUI")
        AceConfigDialog:Open("ScarletUI_Movers")
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
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
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
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
end

function ScarletUI:SetPoint(frame, frameAnchor, frameParent, parentAnchor, x, y)
    if self:InCombat() then
        return
    end

    frame:SetMovable(true)
    frame:ClearAllPoints()
    frame:SetPoint(frameAnchor, frameParent, parentAnchor, x, y)
    frame:SetUserPlaced(true)
    frame:SetMovable(false)
end
