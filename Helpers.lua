local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

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

ScarletUI.defaults = {
    global = {
        tidyIconsEnabled = true,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        unitFramesModule = {
            enabled = true,
            playerFrame = {
                move = true,
                frameAnchor = 9,
                screenAnchor = 4,
                x = -65,
                y = -190,
            },
            targetFrame = {
                mirrorPlayerFrame = true;
                move = true,
                frameAnchor = 8,
                screenAnchor = 4,
                x = 65,
                y = -190,
            },
            focusFrame = {
                move = true,
                frameAnchor = 9,
                screenAnchor = 4,
                x = -220,
                y = -255,
            },
        },
        actionbarsModule = {
            enabled = true,
            stackActionbars = true,
            showGryphons = false,
            microBag = false,
            mainBar = {
                move = true,
                frameAnchor = 1,
                screenAnchor = 1,
                x = 0,
                y = 0,
            },
            stanceBar = {
                move = true,
                hide = false,
                frameAnchor = 2,
                screenAnchor = 8,
                x = 0,
                y = 0,
            },
            microBar = {
                move = true,
                frameAnchor = 2,
                screenAnchor = 2,
                x = 2,
                y = 2,
            },
            bagBar = {
                move = true,
                frameAnchor = 3,
                screenAnchor = 3,
                x = -2,
                y = 2,
            }
        },
        chatModule = {
            enabled = true,
            fontSize = 14,
            height = 150,
            width = 400,
            chatFrame = {
                move = true,
                frameAnchor = 2,
                screenAnchor = 2,
                x = 0,
                y = 75,
            }
        },
        raidFramesModule = {
            enabled = true,
            partyFrames = {
                move = true,
                x = 535,
                y = 450,
                height = 295
            },
            raidFrames = {
                move = true,
                x = 165,
                y = 375,
                height = 90
            }
        },
        nameplatesModule = {
            enabled = true,
            targetIndicator = {
                show = true,
                indicatorSize = 30,
                indicatorDistance = -5,
                indicatorHeight = 0,
            },
            castBarText = {
                show = true,
                fontSize = 10,
            },
            nonTankThreatColors = {
                noThreat = { 0.0824, 1, 0, 1 },
                lowThreat = { 1, 0.9176, 0, 1 },
                threat = { 1, 0.0353, 0, 1 },
                tank = { 0, 0.7020, 1, 1 }
            },
            tankThreatColors = {
                noThreat = { 1, 0.0353, 0, 1 },
                lowThreat = { 1, 0.9176, 0, 1 },
                threat = { 0.0824, 1, 0, 1 },
                tank = { 0, 0.7020, 1, 1 }
            },
            tankNames = ""
        },
        CVarModule = {
            enabled = false,
            CVars = {
                -- UI CVars
                useUiScale =  '1',
                UIScale =  '0.75',
                XpBarText = '1',
                lootUnderMouse = '1',
                autoLootDefault = '1',
                floatingCombatTextCombatHealing = '1',
                showTargetOfTarget = '1',
                doNotFlashLowHealthWarning = '0',

                -- Chat CVars
                chatStyle = 'classic',
                whisperMode = 'inline',
                colorChatNamesByClass = '1',
                chatClassColorOverride = '0',
                speechToText = '0',
                textToSpeech = '0',
                chatMouseScroll = '1',

                -- Floating Combat Text
                enableFloatingCombatText = '0',
                floatingCombatTextLowManaHealth = '1',
                floatingCombatTextDodgeParryMiss = '1',
                floatingCombatTextCombatState = '1',
                floatingCombatTextFriendlyHealers = '1',
                floatingCombatTextEnergyGains = '1',

                -- Raid Frame CVars
                useCompactPartyFrames = '1',

                -- Nameplate CVars
                UnitNameOwn = '1',
                nameplateMotion = '1',
                nameplateShowEnemies = '1',

                -- Misc CVars
                countdownForCooldowns = '1',
                Sound_EnableErrorSpeech = '0',
            }
        },
    }
}

ScarletUI.reloadCVars = {
    'XpBarText',
}

ScarletUI.movers = {}

function ScarletUI:SwapActionbar(sourceBar, destinationBar)
    for i = 1, 12 do
        local sourceButton = _G[sourceBar.."Button"..i].action
        local destinationButton = _G[destinationBar.."Button"..i].action

        PickupAction(sourceButton)
        if GetCursorInfo() ~= nil then
            PlaceAction(destinationButton)
            PlaceAction(sourceButton)
        else
            PickupAction(destinationButton)
            PlaceAction(sourceButton)
            PlaceAction(destinationButton)
        end
    end
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

function ScarletUI:OppositeFrameAnchor(index)
    local anchor = self.frameAnchors[index]
    if anchor == "BOTTOM" then
        return "TOP"
    elseif anchor == "BOTTOMLEFT" then
        return "BOTTOMRIGHT"
    elseif anchor == "BOTTOMRIGHT" then
        return "BOTTOMLEFT"
    elseif anchor == "CENTER" then
        return "CENTER"
    elseif anchor == "LEFT" then
        return "RIGHT"
    elseif anchor == "RIGHT" then
        return "LEFT"
    elseif anchor == "TOP" then
        return "BOTTOM"
    elseif anchor == "TOPLEFT" then
        return "TOPRIGHT"
    elseif anchor == "TOPRIGHT" then
        return "TOPLEFT"
    end
end

function ScarletUI:SettingDisabled(moduleEnabled)
    if ScarletUI.inCombat then
        return true
    else
        return not moduleEnabled
    end
end

function ScarletUI:CreateMover(targetFrame, module)
    if targetFrame.mover then
        return targetFrame.mover
    end

    local mover = CreateFrame("Frame", nil, UIParent)
    mover.targetFrame = targetFrame
    mover:SetSize(targetFrame:GetWidth(), targetFrame:GetHeight())
    mover:SetPoint("BOTTOM", targetFrame, "BOTTOM", 0, 0)
    mover:SetFrameStrata("FULLSCREEN_DIALOG")

    -- Background
    local bg = mover:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.4, 0.6, 1, 0.5) -- light blue background

    -- Border
    local borderSize = 4
    local borders = {
        mover:CreateTexture(nil, "BORDER"), -- Top
        mover:CreateTexture(nil, "BORDER"), -- Bottom
        mover:CreateTexture(nil, "BORDER"), -- Left
        mover:CreateTexture(nil, "BORDER"), -- Right
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
    local text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetText(targetFrame:GetName())
    text:SetPoint("CENTER", mover, "CENTER")

    mover:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and targetFrame:IsMovable() then
            targetFrame:StartMoving()
        end
    end)

    mover:SetScript("OnMouseUp", function(_, _)
        targetFrame:StopMovingOrSizing()
        self:UpdateFramePositionSettings(targetFrame, module)
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
    self.movers[targetFrame:GetName()] = mover
    return mover
end

function ScarletUI:ToggleMovers()
    if self.moversEnabled then
        self.moversEnabled = false
    elseif not self.moversEnabled then
        self.moversEnabled = true
    end

    for k, v in pairs(self.movers) do
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

function ScarletUI:SetPoint(frame, frameAnchor, frameParent, parentAnchor, x, y)
    if self.inCombat then
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

function ScarletUI:DumpTable(table, indent)
    indent = indent or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. " = {")
            self:DumpTable(value, indent .. "    ")
            print(indent .. "}")
        else
            print(indent .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

function ScarletUI:ArrayHasValue(array, value)
    for _, v in ipairs(array) do
        if tostring(v) == tostring(value) then
            return true
        end
    end

    return false
end

function ScarletUI:GetArrayIndex(value)
    for index, v in ipairs(ScarletUI.frameAnchors) do
        if v == value then
            return index
        end
    end

    return nil
end
