local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

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
        itemLevel = true,
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
                x = -65,
                y = -190,
            },
        },
        actionbarsModule = {
            enabled = true,
            stackActionbars = true,
            mainBar = {
                move = true,
                frameAnchor = 1,
                screenAnchor = 1,
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

ScarletUI.threatNameplatesWA = ""

function ScarletUI:ImportWeakAuras(weakAura)
    -- Serialize the table to a string
    local serializedData = AceSerializer:Serialize(weakAura)

    -- Compress the serialized string
    local compressedData = LibDeflate:CompressDeflate(serializedData)

    -- Encode the compressed string
    local encodedData = LibDeflate:EncodeForPrint(compressedData)

    -- Prepare the inData table
    local inData = {
        d = encodedData  -- Encoded and compressed data
    }

    -- Import the WeakAura
    local successful, error = WeakAuras.Import(inData)

    if not successful and error then
        print("There was a problem importing the WeakAura:", error)
    end
end

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