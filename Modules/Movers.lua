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
                    self:SetupActionBars()
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
                    self:SetupActionBars()
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
                    self:SetupActionBars()
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
                    self:SetupActionBars()
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
                    self:SetupActionBars()
                end,
            }
        }
    }
end

function ScarletUI:GetMoversConfigs()
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

        configs[barName] = self:GenerateMoverConfig(barName, i + 1)

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

    local options = self:GetMoversConfigs()
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
            resetPositions = {
                type = "execute",
                name = "Reset Positions",
                desc = "Reset all frame positions to their default settings.",
                func = function() StaticPopup_Show('SCARLET_RESTORE_POSITIONS_DIALOG') end,
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
        },
    }
end

function ScarletUI:RefreshMoverOptions()
    AceConfigRegistry:NotifyChange("ScarletUI_Movers")
    ScarletUI:UpdateMovers()
end

function ScarletUI:GetFrameData(settingsKey)
    local frameData = self.frameData[settingsKey]

    if frameData == nil then
        self:Print("Frame data is nil for settings key: " .. settingsKey)
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

    AceConfigRegistry:NotifyChange("ScarletUI")
    self:RefreshMoverOptions()
end

function ScarletUI:ResetPositions()
    local db = self.db.global
    local defaults = self.db.defaults.global
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

    self:Setup()
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
