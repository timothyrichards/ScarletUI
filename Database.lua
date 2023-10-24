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
        moversModule = {
            enabled = true,
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
            },
            multiBarLeft = {
                move = true,
                buttonsPerColumn = 1,
                spacing = 6,
                frameAnchor = 6,
                screenAnchor = 6,
                x = -42,
                y = 0,
            },
            multiBarRight = {
                move = true,
                buttonsPerColumn = 4,
                spacing = 6,
                frameAnchor = 6,
                screenAnchor = 6,
                x = 0,
                y = 0,
            },
        },
        chatModule = {
            enabled = true,
            fontSize = 14,
            height = 150,
            width = 400,
            tabs = {
                loot = true,
                lfg = true,
                trade = true,
            },
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
            classColored = true,
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
                nameplateNotSelectedAlpha = '1',

                -- Misc CVars
                countdownForCooldowns = '1',
                Sound_EnableErrorSpeech = '0',
            }
        },
    }
}

function ScarletUI:ResetDefaults()
    self.db:ResetDB()
    self:Setup()
    AceConfigRegistry:NotifyChange("ScarletUI")
end