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

ScarletUI.frameData = {
    playerFrame = {
        frame = PlayerFrame,
        databasePath = "unitFramesModule.playerFrame",
        settingsPath = "unitFramesModuleSettings.args.playerFrame",
    },
    targetFrame = {
        frame = TargetFrame,
        databasePath = "unitFramesModule.targetFrame",
        settingsPath = "unitFramesModuleSettings.args.targetFrame",
    },
    focusFrame = {
        frame = FocusFrame,
        databasePath = "unitFramesModule.focusFrame",
        settingsPath = "unitFramesModuleSettings.args.focusFrame",
    },
    castBar = {
        frame = CastingBarFrame,
        databasePath = "unitFramesModule.castBar",
        settingsPath = "unitFramesModuleSettings.args.castBar",
    },
    chatFrame = {
        frame = ChatFrame1,
        databasePath = "chatModule.chatFrame",
        settingsPath = "chatModuleSettings.args.chatFrame",
    },
    mainMenuBar = {
        frame = MainMenuBar,
        databasePath = "actionbarsModule.mainMenuBar",
        settingsPath = "actionbarsModuleSettings.args.mainMenuBar",
    },
    vehicleLeaveButton = {
        frame = MainMenuBarVehicleLeaveButton,
        databasePath = "actionbarsModule.vehicleLeaveButton",
        settingsPath = "actionbarsModuleSettings.args.vehicleLeaveButton",
    },
    multiBarBottomLeft = {
        frame = MultiBarBottomLeft,
        databasePath = "actionbarsModule.multiBarBottomLeft",
        settingsPath = "actionbarsModuleSettings.args.multiBarBottomLeft",
    },
    multiBarBottomRight = {
        frame = MultiBarBottomRight,
        databasePath = "actionbarsModule.multiBarBottomRight",
        settingsPath = "actionbarsModuleSettings.args.multiBarBottomRight",
    },
    multiBarLeft = {
        frame = MultiBarLeft,
        databasePath = "actionbarsModule.multiBarLeft",
        settingsPath = "actionbarsModuleSettings.args.multiBarLeft",
    },
    multiBarRight = {
        frame = MultiBarRight,
        databasePath = "actionbarsModule.multiBarRight",
        settingsPath = "actionbarsModuleSettings.args.multiBarRight",
    },
    stanceBar = {
        frame = StanceBarFrame,
        databasePath = "actionbarsModule.stanceBar",
        settingsPath = "actionbarsModuleSettings.args.stanceBar",
    },
    petBar = {
        frame = PetActionBarFrame,
        databasePath = "actionbarsModule.petBar",
        settingsPath = "actionbarsModuleSettings.args.petBar",
    },
    multiCastBar = {
        frame = MultiCastActionBarFrame,
        databasePath = "actionbarsModule.multiCastBar",
        settingsPath = "actionbarsModuleSettings.args.multiCastBar",
    },
    microBar = {
        frame = MicroButtonAndBagsBar,
        databasePath = "actionbarsModule.microBar",
        settingsPath = "actionbarsModuleSettings.args.microBar",
    },
    bagBar = {
        frame = BagBar,
        databasePath = "actionbarsModule.bagBar",
        settingsPath = "actionbarsModuleSettings.args.bagBar",
    },
}

function ScarletUI:MoversOptions()
    if self.selectedMover == nil then
        -- Grab the first available mover in alphabetical order
        local keys = {}
        for k in pairs(self.movers) do
            table.insert(keys, k)
        end

        table.sort(keys)
        self:SelectMover(self.movers[keys[1]])
    end

    local options = self:Options().args
    local frameData = self.frameData[self.selectedMover.settingsKey]
    local frameOptions = self:GetValueFromPath(options, frameData.settingsPath)

    frameOptions.name = ""
    frameOptions.inline = true
    frameOptions.order = 4

    local frameSettingsOptions = {}
    for k, _ in pairs(self.frameData) do
        if self.movers[k] then
            frameSettingsOptions[k] = self:ConvertToPascalCase(k)
        end
    end

    return {
        type = "group",
        name = "Movers",
        childGroups = "tab",
        order = 1,
        args = {
            toggleMovers = {
                type = "execute",
                name = "Toggle Movers",
                desc = "Toggle the visibility of all movers.",
                func = function() self:ToggleMovers() end,
                order = 1,
            },
            resetPositions = {
                type = "execute",
                name = "Reset Positions",
                desc = "Reset all frame positions to their default settings.",
                func = function() self:ResetPositions() end,
                order = 2,
            },
            frameSelection = {
                type = "select",
                name = "Select Frame",
                desc = "Select a frame to modify.",
                order = 3,
                width = 1,
                values = frameSettingsOptions,
                get = function() return self.selectedMover.settingsKey end,
                set = function(_, value)
                    self:SelectMover(self.movers[value])
                    self:RefreshMoverOptions()
                end,
                order = 3,
            },
            frame = frameOptions
        },
    }
end

function ScarletUI:RefreshMoverOptions()
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
    ScarletUI:UpdateMovers()
end

function ScarletUI:CreateMover(targetFrame, settings, canMoveFrame)
    canMoveFrame = canMoveFrame or function() return true end

    if targetFrame.mover then
        return targetFrame.mover
    end

    local targetFrameName = targetFrame.originalFrameName or targetFrame:GetName()
    if targetFrame.settingsKey then
        targetFrameName = self:ConvertToPascalCase(targetFrame.settingsKey)
    end

    targetFrame:SetMovable(true)
    targetFrame:SetUserPlaced(true)
    targetFrame:SetClampedToScreen(true)

    local mover = CreateFrame("Frame", targetFrameName .. "Mover", UIParent)
    mover.targetFrame = targetFrame
    mover.settingsKey = targetFrame.settingsKey or self:ConvertToCamelCase(targetFrameName)
    mover:SetSize(targetFrame:GetWidth(), targetFrame:GetHeight())
    mover:SetPoint("BOTTOM", targetFrame, "BOTTOM", 0, 0)
    mover:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Background
    mover.background = mover:CreateTexture("Background", "BACKGROUND")
    mover.background:SetAllPoints()
    mover.background:SetColorTexture(0.4, 0.6, 1, 0.5) -- light blue background

    -- Border
    local borderSize = 4
    mover.borders = {
        mover:CreateTexture("TopBorder", "BORDER"),
        mover:CreateTexture("BottomBorder", "BORDER"),
        mover:CreateTexture("LeftBorder", "BORDER"),
        mover:CreateTexture("RightBorder", "BORDER"),
    }

    for _, border in ipairs(mover.borders) do
        border:SetColorTexture(0.2, 0.4, 0.8, 1)
    end

    mover.borders[1]:SetPoint("TOPLEFT", mover, "TOPLEFT")
    mover.borders[1]:SetPoint("TOPRIGHT", mover, "TOPRIGHT")
    mover.borders[1]:SetHeight(borderSize)

    mover.borders[2]:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT")
    mover.borders[2]:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT")
    mover.borders[2]:SetHeight(borderSize)

    mover.borders[3]:SetPoint("TOPLEFT", mover, "TOPLEFT")
    mover.borders[3]:SetPoint("BOTTOMLEFT", mover, "BOTTOMLEFT")
    mover.borders[3]:SetWidth(borderSize)

    mover.borders[4]:SetPoint("TOPRIGHT", mover, "TOPRIGHT")
    mover.borders[4]:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT")
    mover.borders[4]:SetWidth(borderSize)

    -- Display the frame's name in the center of the mover
    local text = mover:CreateFontString("FrameName", "OVERLAY", "GameFontNormal")
    text:SetText(targetFrameName)
    text:SetPoint("CENTER", mover, "CENTER")

    -- Calculate the width of the FrameName
    local frameNameWidth = text:GetStringWidth()

    -- Rotate the text if the FrameName is longer than the mover's width
    if frameNameWidth > mover:GetWidth() and frameNameWidth < mover:GetHeight() then
        text:SetRotation(math.pi / 2)
    end

    mover:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            self:SelectMover(mover)

            if targetFrame:IsMovable() and canMoveFrame() then
                mover.timer = C_Timer.NewTimer(0.025, function()
                    targetFrame:StartMoving()
                end)
            end
        end
    end)

    mover:SetScript("OnMouseUp", function(_, _)
        if mover.timer then
            mover.timer:Cancel()
        end

        targetFrame:StopMovingOrSizing()

        if settings ~= nil then
            self:UpdateFramePositionSettings(targetFrame, settings)
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
    self.movers[mover.settingsKey] = mover
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
    if self.moversEnabled then
        if self.optionsWasOpen and not self:InCombat() then
            AceConfigDialog:Open("ScarletUI")
        end

        self.optionsWasOpen = false
        AceConfigDialog:Close("ScarletUI_Movers")
    elseif not self.moversEnabled then
        if self:IsAceDialogOpen("ScarletUI") then
            self.optionsWasOpen = true
        end

        AceConfigDialog:Close("ScarletUI")

        if not self:IsAceDialogOpen("ScarletUI_Movers") then
            AceConfigDialog:Open("ScarletUI_Movers")
        end
    end

    self:CreateGrid()
    self.grid:SetShown(not self.moversEnabled)
    self.moversEnabled = not self.moversEnabled
    SUI_MoverPropertyText:SetText("- moversEnabled: " .. tostring(self.moversEnabled))
    self:UpdateMovers()
end

function ScarletUI:UpdateMovers()
    for _, v in pairs(self.movers) do
        local data = self.frameData[v.settingsKey]
        local frameSettings = self:GetValueFromPath(self.db.global, data.databasePath)
        local show = self.moversEnabled and frameSettings.move and not frameSettings.hide

        v:SetMovable(show)
        v:SetShown(show)
    end
end

function ScarletUI:SelectMover(mover)
    if self.selectedMover then
        self.selectedMover.background:SetColorTexture(0.4, 0.6, 1, 0.5)

        for _, border in ipairs(self.selectedMover.borders) do
            border:SetColorTexture(0.2, 0.4, 0.8, 1)
        end
    end

    self.selectedMover = mover

    if self.selectedMover then
        self.selectedMover.background:SetColorTexture(0.4, 1, 0.6, 0.5)

        for _, border in ipairs(self.selectedMover.borders) do
            border:SetColorTexture(0.2, 1, 0.4, 1)
        end
    end

    if self.moversEnabled then
        self:RefreshMoverOptions()
        AceConfigDialog:Open("ScarletUI_Movers")
    end
end

function ScarletUI:UpdateFramePositionSettings(frame, module)
    local point, _, relativePoint, xOffset, yOffset = frame:GetPoint()
    module.frameAnchor = self:GetArrayIndex(self.frameAnchors, point)
    module.screenAnchor = self:GetArrayIndex(self.frameAnchors, relativePoint)
    module.x = xOffset
    module.y = yOffset

    AceConfigRegistry:NotifyChange("ScarletUI")
    self:RefreshMoverOptions()
end

function ScarletUI:ResetPositions()
    local db = self.db.global
    local defaults = self.defaults.global
    local settings = {
        "frameAnchor",
        "screenAnchor",
        "x",
        "y",
    }

    for _, data in pairs(self.frameData) do
        local frameParts = {}
        for part in string.gmatch(data.databasePath, "[^.]+") do
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
    self:SelectMover(nil)
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
