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
    bagBar = {
        frame = BagBar,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.bagBar",
    },
    castBar = {
        frame = CastingBarFrame,
        module = "unitFramesModule",
        databasePath = "unitFramesModule.castBar",
    },
    chatFrame = {
        frame = ChatFrame1,
        module = "chatModule",
        databasePath = "chatModule.chatFrame",
    },
    experienceBar = {
        frame = MainMenuExpBar,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.experienceBar",
    },
    focusFrame = {
        frame = FocusFrame,
        module = "unitFramesModule",
        databasePath = "unitFramesModule.focusFrame",
    },
    mainMenuBar = {
        frame = MainMenuBar,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.mainMenuBar",
    },
    microBar = {
        frame = MicroButtonAndBagsBar,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.microBar",
    },
    multiBarBottomLeft = {
        frame = MultiBarBottomLeft,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.multiBarBottomLeft",
    },
    multiBarBottomRight = {
        frame = MultiBarBottomRight,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.multiBarBottomRight",
    },
    multiBarLeft = {
        frame = MultiBarLeft,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.multiBarLeft",
    },
    multiBarRight = {
        frame = MultiBarRight,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.multiBarRight",
    },
    multiCastBar = {
        frame = MultiCastActionBarFrame,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.multiCastBar",
    },
    petBar = {
        frame = PetActionBarFrame,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.petBar",
        buttonSize = 30,
        buttonCount = 10,
        buttonName = "PetActionButton",
    },
    playerFrame = {
        frame = PlayerFrame,
        module = "unitFramesModule",
        databasePath = "unitFramesModule.playerFrame",
    },
    reputationBar = {
        frame = ReputationWatchBar,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.reputationBar",
    },
    stanceBar = {
        frame = StanceBarFrame,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.stanceBar",
        buttonSize = 30,
        buttonCount = 10,
        buttonName = "StanceButton",
    },
    targetFrame = {
        frame = TargetFrame,
        module = "unitFramesModule",
        databasePath = "unitFramesModule.targetFrame",
    },
    vehicleLeaveButton = {
        frame = MainMenuBarVehicleLeaveButton,
        module = "actionbarsModule",
        databasePath = "actionbarsModule.vehicleLeaveButton",
    },
}

local function rotateMoverLabel(text, mover)
    -- Calculate the width of the FrameName
    local frameNameWidth = text:GetStringWidth()

    -- Rotate the text if the FrameName is longer than the mover's width
    if frameNameWidth > mover:GetWidth() and frameNameWidth < mover:GetHeight() then
        text:SetRotation(math.pi / 2)
    else
        text:SetRotation(0)
    end
end

function ScarletUI:GenerateMoverConfig(name, _order)
    local frameData = self:GetFrameData(name)
    if frameData == nil then
        self:Print("Frame data is nil for " .. name)
        return
    end

    local module = self.db.global[frameData.module]
    local defaults = self.db.defaults.global[frameData.module];

    if defaults[name] == nil then
        self:Print("Database defaults are missing for " .. name)
        return
    end

    return {
        name = (name:gsub("(%a)(%u)", "%1 %2"):gsub("^%l", string.upper)),
        type = "group",
        disabled = function() return self:SettingDisabled(module.enabled) end,
        order = _order,
        args = {
            moveFrame = {
                name = "Move Frame",
                desc = "Allows you to choose the X and Y position of the frame.",
                type = "toggle",
                width = 1,
                order = 1,
                get = function(_) return module[name].move end,
                set = function(_, val)
                    module[name].move = val

                    if val then
                        self:SetupActionBars()
                        self:RefreshMoverOptions()
                    else
                        self:ShowReloadDialog()
                    end
                end,
            },
            hide = {
                name = "Hide Frame",
                desc = "Allows you to hide the frame.",
                type = "toggle",
                width = 1,
                order = 2,
                get = function(_) return module[name].hide end,
                set = function(_, val)
                    module[name].hide = val
                    self:SetupActionBars()

                    if not val then
                        self:ShowReloadDialog()
                    end
                end,
            },
            spacer1 = {
                name = "",
                type = "description",
                width = "full",
                order = 3,
            },
            frameAnchor = {
                name = "Frame Anchor",
                desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults[name].frameAnchor] .. ")",
                type = "select",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                width = 1,
                order = 4,
                values = function() return self.frameAnchors end,
                get = function(_) return module[name].frameAnchor end,
                set = function(_, val)
                    module[name].frameAnchor = val
                    self:Setup()
                end,
            },
            screenAnchor = {
                name = "Screen Anchor",
                desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults[name].screenAnchor] .. ")",
                type = "select",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                width = 1,
                order = 5,
                values = function() return self.frameAnchors end,
                get = function(_) return module[name].screenAnchor end,
                set = function(_, val)
                    module[name].screenAnchor = val
                    self:Setup()
                end,
            },
            spacer2 = {
                name = "",
                type = "description",
                width = "full",
                order = 6,
            },
            x = {
                name = "Frame X",
                desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults[name].x .. ")",
                type = "range",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                min = math.floor(GetScreenWidth()) * -1,
                max = math.floor(GetScreenWidth()),
                step = 1,
                width = 1,
                order = 7,
                get = function(_) return module[name].x end,
                set = function(_, val)
                    module[name].x = val
                    self:Setup()
                end,
            },
            y = {
                name = "Frame Y",
                desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults[name].y .. ")",
                type = "range",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                min = math.floor(GetScreenHeight()) * -1,
                max = math.floor(GetScreenHeight()),
                step = 1,
                width = 1,
                order = 8,
                get = function(_) return module[name].y end,
                set = function(_, val)
                    module[name].y = val
                    self:Setup()
                end,
            },
            scale = {
                name = "Frame Scale",
                desc = "Must be a number, this is the scale of the frame.\n(Default " .. defaults[name].scale .. ")",
                type = "range",
                min = 0.5,
                max = 2,
                step = 0.1,
                width = 1,
                order = 9,
                get = function(_) return module[name].scale end,
                set = function(_, val)
                    module[name].scale = val
                    self:Setup()
                end,
            }
        }
    }
end

function ScarletUI:GenerateAllMoversConfigs()
    local bars = {
        "bagBar",
        "castBar",
        "chatFrame",
        "experienceBar",
        "focusFrame",
        "mainMenuBar",
        "microBar",
        "multiBarBottomLeft",
        "multiBarBottomRight",
        "multiBarLeft",
        "multiBarRight",
        "multiCastBar",
        "petBar",
        "playerFrame",
        "reputationBar",
        "stanceBar",
        "targetFrame",
        "vehicleLeaveButton",
    }
    local configs = {}

    for i, barName in ipairs(bars) do
        local frameData = self:GetFrameData(barName)
        if frameData == nil then
            self:Print("Frame data is nil for " .. barName)
            return
        end

        local module = self.db.global[frameData.module];
        local defaults = self.db.defaults.global[frameData.module];

        configs[barName] = self:GenerateMoverConfig(barName, i + 1)

        if module[barName].buttonsPerRow then
            configs[barName].args.buttonsPerRow = {
                name = "Buttons Per Row",
                desc = "Configure the number of action buttons per row.\n(Default " .. defaults[barName].buttonsPerRow .. ")",
                type = "range",
                disabled = function() return self:SettingDisabled(module[barName].move) end,
                min = 1,
                max = frameData.buttonCount or 12,
                step = 1,
                width = 1,
                order = 3.1,
                get = function(_) return module[barName].buttonsPerRow end,
                set = function(_, val)
                    module[barName].buttonsPerRow = val
                    self:SetupActionBars()
                end,
            }

            configs[barName].args.buttonsPerRowSpacer = {
                name = "",
                type = "description",
                width = "full",
                order = 3.2,
            }
        end

        if barName == "bagBar" then
            configs[barName].args.microBag = {
                name = "Micro Bag",
                desc = "Hide all non backpack bag icons.",
                type = "toggle",
                width = "full",
                order = 0.9,
                get = function(_) return module.microBag end,
                set = function(_, val)
                    module.microBag = val
                    self:SetupActionBars()
                end,
            }
        end

        if barName == "experienceBar" or barName == "reputationBar" then
            configs[barName].args.short = {
                name = "Short",
                desc = "Shorten the bar to a smaller size.",
                type = "toggle",
                width = 1,
                order = 0.9,
                get = function(_) return module[barName].short end,
                set = function(_, val)
                    module[barName].short = val
                    if val then
                        self:SetupActionBars()
                    else
                        self:ShowReloadDialog()
                    end
                end,
            }
        end

        if barName == "focusFrame" or barName == "targetFrame" then
            configs[barName].args.buffsOnTop = {
                name = "Buffs On Top",
                desc = "Force buffs to show on top of the frame.",
                type = "toggle",
                width = 1,
                order = 0.8,
                get = function(_) return module[barName].buffsOnTop end,
                set = function(_, val)
                    module[barName].buffsOnTop = val
                    self:SetupUnitFrames()
                end,
            }
        end

        if barName == "targetFrame" then
            configs[barName].args.mirrorPlayerFrame = {
                name = "Mirror Player Frame",
                desc = "Mirrors the X and Y position of the player frame.",
                type = "toggle",
                width = 1,
                order = 0.9,
                get = function(_) return module.targetFrame.mirrorPlayerFrame end,
                set = function(_, val)
                    module.targetFrame.mirrorPlayerFrame = val
                    self:SetupUnitFrames()
                end,
            }
        end

        if barName == "mainMenuBar" then
            configs[barName].args.showGryphons = {
                name = "Show Gryphons",
                desc = "Show the gryphon graphics on the sides of your main bar.",
                type = "toggle",
                disabled = function() return self:SettingDisabled(module[barName].move) end,
                width = 1,
                order = 0.8,
                get = function(_) return module.showGryphons end,
                set = function(_, val)
                    module.showGryphons = val
                    self:SetupActionBars()
                end,
            }

            configs[barName].args.pagingNumbers = {
                name = "Paging Numbers",
                desc = "Show the actionbar paging numbers and buttons.",
                type = "toggle",
                disabled = function() return self:SettingDisabled(module[barName].move) end,
                width = 1,
                order = 0.9,
                get = function(_) return module.showPagingNumbers end,
                set = function(_, val)
                    module.showPagingNumbers = val
                    self:SetupActionBars()
                end,
            }
        end

        if barName == "multiCastBar" then
            local version = self:GetWoWVersion();
            configs[barName].hidden = function() return version ~= "WRATH" and version ~= "CATA" end
        end

        configs[barName].args.spacer = {
            name = "",
            type = "description",
            width = "full",
            order = 0.91,
        }
    end

    return configs
end

function ScarletUI:GetMoversOptions()
    if self.selectedMover == nil then
        -- Grab the first available mover in alphabetical order
        local keys = {}
        for k in pairs(self.movers) do
            table.insert(keys, k)
        end

        table.sort(keys)
        self:SelectMover(self.movers[keys[1]])
    end

    local options = self:GenerateAllMoversConfigs()
    local frameData = self:GetFrameData(self.selectedMover.settingsKey)
    if frameData == nil then
        self:Print("Frame data is nil for settings key: " .. self.selectedMover.settingsKey)
        return
    end

    local frameOptions = self:GetValueFromPath(options, self.selectedMover.settingsKey)

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
                name = "Lock Frames",
                desc = "Lock all mover frames.",
                func = function() self:ToggleMovers() end,
                order = 1,
            },
            resetPosition = {
                type = "execute",
                name = "Reset Position",
                desc = "Reset this frames position to its default position.",
                func = function() self:ResetPosition(frameData) end,
                order = 2,
            },
            spacer = {
                name = "",
                type = "description",
                width = "full",
                order = 2.1,
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
        }
    }
end

function ScarletUI:RefreshMoverOptions()
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
    self:UpdateMovers()
end

function ScarletUI:GetFrameData(settingsKey)
    local frameData = self.frameData[settingsKey]

    if frameData == nil then
        self:Print("Frame data is nil for settings key: " .. (settingsKey or "nil"))
        return
    end

    return frameData
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

    targetFrame.locked = false
    targetFrame:SetMovable(true)
    targetFrame:SetUserPlaced(true)
    targetFrame:SetClampedToScreen(true)

    local mover = CreateFrame("Frame", targetFrameName .. "Mover", UIParent)
    mover.targetFrame = targetFrame
    mover.settingsKey = targetFrame.settingsKey or self:ConvertToCamelCase(targetFrameName)
    mover:SetSize(targetFrame:GetWidth(), targetFrame:GetHeight())
    mover:SetScale(targetFrame:GetScale())
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

    -- Set initial label rotation
    rotateMoverLabel(text, mover)

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

        rotateMoverLabel(text, mover)
    end)

    -- Hook into the SetWidth method
    hooksecurefunc(targetFrame, "SetWidth", function()
        mover:SetWidth(targetFrame:GetWidth())
    end)

    -- Hook into the SetHeight method
    hooksecurefunc(targetFrame, "SetHeight", function()
        mover:SetHeight(targetFrame:GetHeight())
    end)

    -- Hook into the SetScale method
    hooksecurefunc(targetFrame, "SetScale", function()
        mover:SetScale(targetFrame:GetScale())
    end)

    targetFrame.mover = mover
    self.movers[mover.settingsKey] = mover
    return mover
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

    self.moversEnabled = not self.moversEnabled
    self.grid:SetShown(self.moversEnabled)
    SUI_MoverPropertyText:SetText("- moversEnabled: " .. tostring(self.moversEnabled))
    self:UpdateMovers()
end

function ScarletUI:UpdateMovers()
    for _, v in pairs(self.movers) do
        local data = self:GetFrameData(v.settingsKey)
        if data == nil then
            self:Print("Frame data is nil for settings key: " .. self.selectedMover.settingsKey)
            return
        end

        local frameSettings = self:GetValueFromPath(self.db.global, data.databasePath)
        if frameSettings ~= nil then
            local show = self.moversEnabled and frameSettings.move and not frameSettings.hide

            v:SetMovable(show)
            v:SetShown(show)
            v.targetFrame:StopMovingOrSizing()
        else
            self:Print("Frame settings are nil for database path: " .. data.databasePath)
        end
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

    self:RefreshMoverOptions()
end

function ScarletUI:ResetPositions()
    for _, data in pairs(self.frameData) do
        self:ResetPosition(data)
    end

    self:Setup()
    AceConfigRegistry:NotifyChange("ScarletUI")
    self:SelectMover(nil)
end

function ScarletUI:ResetPosition(data)
    local db = self.db.global
    local defaults = self.db.defaults.global
    local settings = {
        "frameAnchor",
        "screenAnchor",
        "x",
        "y",
    }

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

    self:Setup()
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
end

function ScarletUI:CreateMoverGrid(spacing)
    if SUI_Grid then
        return
    end

    -- Create the parent frame
    local parent = _G["SUI_Grid"] or CreateFrame("Frame", "SUI_Grid", UIParent)
    parent:SetAllPoints(UIParent)
    parent:SetFrameStrata("BACKGROUND")
    parent:Hide()

    self.grid = parent

    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local uiScale = UIParent:GetScale()

    -- Scale-adjusted dimensions
    local scaledWidth = screenWidth * uiScale
    local scaledHeight = screenHeight * uiScale

    -- Create a line template
    local function CreateLine(lineParent, isRed)
        local line = lineParent:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(1, isRed and 0 or 1, isRed and 0 or 1, 0.5) -- Red or White with transparency
        return line
    end

    -- Center lines
    local verticalCenterLine = CreateLine(parent, true)
    verticalCenterLine:SetWidth(1)
    verticalCenterLine:SetPoint("TOP", parent, "TOP")
    verticalCenterLine:SetPoint("BOTTOM", parent, "BOTTOM")
    verticalCenterLine:SetPoint("CENTER", parent, "CENTER")

    local horizontalCenterLine = CreateLine(parent, true)
    horizontalCenterLine:SetHeight(1)
    horizontalCenterLine:SetPoint("LEFT", parent, "LEFT")
    horizontalCenterLine:SetPoint("RIGHT", parent, "RIGHT")
    horizontalCenterLine:SetPoint("CENTER", parent, "CENTER")

    -- Helper to create grid lines
    local function CreateGridLines(isVertical)
        for offset = spacing, scaledWidth, spacing do
            local linePos = offset / uiScale

            -- Positive offset lines
            local posLine = CreateLine(parent, false)
            if isVertical then
                posLine:SetWidth(1)
                posLine:SetPoint("TOP", parent, "TOP")
                posLine:SetPoint("BOTTOM", parent, "BOTTOM")
                posLine:SetPoint("LEFT", parent, "CENTER", linePos, 0)
            else
                posLine:SetHeight(1)
                posLine:SetPoint("LEFT", parent, "LEFT")
                posLine:SetPoint("RIGHT", parent, "RIGHT")
                posLine:SetPoint("TOP", parent, "CENTER", 0, -linePos)
            end

            -- Negative offset lines
            local negLine = CreateLine(parent, false)
            if isVertical then
                negLine:SetWidth(1)
                negLine:SetPoint("TOP", parent, "TOP")
                negLine:SetPoint("BOTTOM", parent, "BOTTOM")
                negLine:SetPoint("RIGHT", parent, "CENTER", -linePos, 0)
            else
                negLine:SetHeight(1)
                negLine:SetPoint("LEFT", parent, "LEFT")
                negLine:SetPoint("RIGHT", parent, "RIGHT")
                negLine:SetPoint("BOTTOM", parent, "CENTER", 0, linePos)
            end
        end
    end

    -- Create vertical and horizontal grid lines
    CreateGridLines(true) -- Vertical lines
    CreateGridLines(false) -- Horizontal lines
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
