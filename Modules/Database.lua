local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

ScarletUI.defaults = {
    global = {
        installationComplete = false,
        tidyIconsEnabled = true,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        expandCharacterInfo = true,
        unitFramesModule = {
            enabled = true,
            playerFrame = {
                move = true,
                frameAnchor = 9, -- TOPRIGHT
                screenAnchor = 4, -- CENTER
                x = -65,
                y = -190
            },
            targetFrame = {
                mirrorPlayerFrame = true,
                buffsOnTop = true,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 4, -- CENTER
                x = 65,
                y = -190
            },
            focusFrame = {
                buffsOnTop = true,
                move = true,
                frameAnchor = 9, -- TOPRIGHT
                screenAnchor = 4, -- CENTER
                x = -220,
                y = -255
            },
            castBar = {
                move = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 192
            },
        },
        moversModule = {
            enabled = true
        },
        actionbarsModule = {
            enabled = true,
            showPagingNumbers = true,
            showGryphons = true,
            microBag = false,
            mainMenuBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 0
            },
            vehicleLeaveButton = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 234,
                y = 140
            },
            multiBarBottomLeft = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 58
            },
            multiBarBottomRight = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 100
            },
            multiBarLeft = {
                move = true,
                hide = false,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = -42,
                y = 0
            },
            multiBarRight = {
                move = true,
                hide = false,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = 0,
                y = 0
            },
            stanceBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 140
            },
            petBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 140
            },
            multiCastBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 140
            },
            experienceBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 44
            },
            reputationBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 42
            },
            microBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 2, -- BOTTOMLEFT
                x = 2,
                y = 2
            },
            bagBar = {
                move = true,
                hide = false,
                frameAnchor = 3, -- BOTTOMRIGHT
                screenAnchor = 3, -- BOTTOMRIGHT
                x = -2,
                y = 2
            },
        },
        chatModule = {
            enabled = true,
            fontSize = 14,
            height = 150,
            width = 400,
            tabs = {
                loot = true,
                trade = true,
                lfg = true
            },
            chatFrame = {
                move = true,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 2, -- BOTTOMLEFT
                x = 0,
                y = 75
            }
        },
        raidFramesModule = {
            enabled = true,
            profiles = {
                Party = {
                    move = true,
                    x = 535,
                    y = 450,
                    height = 225,
                    keepGroupsTogether = false,
                    horizontalGroups = false,
                    displayPowerBar = true,
                    useClassColors = true,
                    displayPets = true,
                    displayMainTankAndAssist = false,
                    displayBorder = false,
                    displayNonBossDebuffs = true,
                    displayOnlyDispellableDebuffs = true,
                    healthText = 'perc',
                    frameHeight = 46,
                    frameWidth = 90,
                    autoActivatePvE = true,
                    autoActivatePvP = true,
                    autoActivate2Players = true,
                    autoActivate3Players = true,
                    autoActivate5Players = true,
                    autoActivate10Players = false,
                    autoActivate15Players = false,
                    autoActivate20Players = false,
                    autoActivate40Players = false
                },
                Raid = {
                    move = true,
                    x = 165,
                    y = 375,
                    height = 90,
                    keepGroupsTogether = true,
                    horizontalGroups = true,
                    displayPowerBar = true,
                    useClassColors = true,
                    displayPets = false,
                    displayMainTankAndAssist = false,
                    displayBorder = false,
                    displayNonBossDebuffs = true,
                    displayOnlyDispellableDebuffs = true,
                    healthText = 'perc',
                    frameHeight = 46,
                    frameWidth = 90,
                    autoActivatePvE = true,
                    autoActivatePvP = true,
                    autoActivate2Players = false,
                    autoActivate3Players = false,
                    autoActivate5Players = false,
                    autoActivate10Players = true,
                    autoActivate15Players = true,
                    autoActivate20Players = true,
                    autoActivate40Players = true
                }
            }
        },
        nameplatesModule = {
            enabled = true,
            classColored = true,
            threatColored = true,
            specialUnitsColored = true,
            debuffTracker = {
                track = true,
                iconSize = 30,
                spacing = 2,
                verticalOffset = 20,
            },
            targetIndicator = {
                show = true,
                indicatorSize = 30,
                indicatorDistance = -5,
                indicatorHeight = 0
            },
            healthBarText = {
                show = true,
                fontSize = 10
            },
            castBarText = {
                show = true,
                fontSize = 10
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
            tankNames = "",
            specialUnitColor = { 1, 0, 1, 1 },
            specialUnitNames = ""
        },
        bagModule = {
            enabled = true,
            slotsPerRow = 10,
            slotSize = 37,
            slotSpacing = 4,
        },
        CVarModule = {
            enabled = false,
            CVars = {
                advancedCombatLogging = '1',
                autoLootDefault = '1',
                chatClassColorOverride = '0',
                chatMouseScroll = '1',
                chatStyle = 'classic',
                colorChatNamesByClass = '1',
                countdownForCooldowns = '1',
                doNotFlashLowHealthWarning = '0',
                enableFloatingCombatText = '0',
                floatingCombatTextCombatHealing = '1',
                floatingCombatTextCombatState = '1',
                floatingCombatTextDodgeParryMiss = '1',
                floatingCombatTextEnergyGains = '1',
                floatingCombatTextFriendlyHealers = '1',
                floatingCombatTextLowManaHealth = '1',
                lootUnderMouse = '1',
                mapFade = '0',
                nameplateMotion = '1',
                nameplateNotSelectedAlpha = '1',
                nameplateShowEnemies = '1',
                showDynamicBuffSize = '1',
                showTargetCastbar = '1',
                showTargetOfTarget = '1',
                Sound_EnableErrorSpeech = '0',
                speechToText = '0',
                textToSpeech = '0',
                UnitNameOwn = '1',
                UIScale =  '0.75',
                useCompactPartyFrames = '1',
                useUiScale =  '1',
                whisperMode = 'inline',
                XpBarText = '1',
            }
        }
    },
    char = {
        priorityDebuffs = "",
    }
}

ScarletUI.originalUIDefaults = {
    global = {
        installationComplete = false,
        tidyIconsEnabled = false,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        expandCharacterInfo = false,
        unitFramesModule = {
            enabled = true,
            playerFrame = {
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 8, -- TOPLEFT
                x = -19,
                y = -4
            },
            targetFrame = {
                mirrorPlayerFrame = false,
                buffsOnTop = false,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 8, -- TOPLEFT
                x = 250,
                y = -4
            },
            focusFrame = {
                buffsOnTop = false,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 8, -- TOPLEFT
                x = 250,
                y = -240
            },
            castBar = {
                move = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 192
            },
        },
        moversModule = {
            enabled = true
        },
        actionbarsModule = {
            enabled = true,
            showPagingNumbers = true,
            showGryphons = false,
            microBag = false,
            mainMenuBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 0
            },
            vehicleLeaveButton = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 490,
                y = 100
            },
            multiBarBottomLeft = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 57
            },
            multiBarBottomRight = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 260,
                y = 57
            },
            multiBarLeft = {
                move = true,
                hide = false,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = -42,
                y = 0
            },
            multiBarRight = {
                move = true,
                hide = false,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = 0,
                y = 0
            },
            stanceBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -351,
                y = 95
            },
            petBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 335,
                y = 95
            },
            multiCastBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -361,
                y = 103
            },
            experienceBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 44
            },
            reputationBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -250,
                y = 42
            },
            microBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 200,
                y = 2
            },
            bagBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 430,
                y = 2
            },
        },
        chatModule = {
            enabled = true,
            fontSize = 14,
            height = 120,
            width = 430,
            tabs = {
                loot = true,
                trade = true,
                lfg = true
            },
            chatFrame = {
                move = true,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 2, -- BOTTOMLEFT
                x = 35,
                y = 184
            }
        },
        raidFramesModule = {
            enabled = true,
            profiles = {
                Party = {
                    move = true,
                    x = 535,
                    y = 450,
                    height = 225,
                    keepGroupsTogether = false,
                    horizontalGroups = false,
                    displayPowerBar = true,
                    useClassColors = true,
                    displayPets = true,
                    displayMainTankAndAssist = false,
                    displayBorder = false,
                    displayNonBossDebuffs = true,
                    displayOnlyDispellableDebuffs = true,
                    healthText = 'perc',
                    frameHeight = 46,
                    frameWidth = 90,
                    autoActivatePvE = true,
                    autoActivatePvP = true,
                    autoActivate2Players = true,
                    autoActivate3Players = true,
                    autoActivate5Players = true,
                    autoActivate10Players = false,
                    autoActivate15Players = false,
                    autoActivate20Players = false,
                    autoActivate40Players = false
                },
                Raid = {
                    move = true,
                    x = 165,
                    y = 375,
                    height = 90,
                    keepGroupsTogether = true,
                    horizontalGroups = true,
                    displayPowerBar = true,
                    useClassColors = true,
                    displayPets = false,
                    displayMainTankAndAssist = false,
                    displayBorder = false,
                    displayNonBossDebuffs = true,
                    displayOnlyDispellableDebuffs = true,
                    healthText = 'perc',
                    frameHeight = 46,
                    frameWidth = 90,
                    autoActivatePvE = true,
                    autoActivatePvP = true,
                    autoActivate2Players = false,
                    autoActivate3Players = false,
                    autoActivate5Players = false,
                    autoActivate10Players = true,
                    autoActivate15Players = true,
                    autoActivate20Players = true,
                    autoActivate40Players = true
                }
            }
        },
        nameplatesModule = {
            enabled = true,
            classColored = true,
            threatColored = true,
            specialUnitsColored = true,
            debuffTracker = {
                track = true,
                iconSize = 30,
                spacing = 2,
                verticalOffset = 20,
            },
            targetIndicator = {
                show = true,
                indicatorSize = 30,
                indicatorDistance = -5,
                indicatorHeight = 0
            },
            healthBarText = {
                show = true,
                fontSize = 10
            },
            castBarText = {
                show = true,
                fontSize = 10
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
            tankNames = "",
            specialUnitColor = { 1, 0, 1, 1 },
            specialUnitNames = ""
        },
        bagModule = {
            enabled = true,
            slotsPerRow = 10,
            slotSize = 37,
            slotSpacing = 4,
        },
        CVarModule = {
            enabled = false,
            CVars = {
                advancedCombatLogging = '1',
                autoLootDefault = '1',
                chatClassColorOverride = '0',
                chatMouseScroll = '1',
                chatStyle = 'classic',
                colorChatNamesByClass = '1',
                countdownForCooldowns = '1',
                doNotFlashLowHealthWarning = '0',
                enableFloatingCombatText = '0',
                floatingCombatTextCombatHealing = '1',
                floatingCombatTextCombatState = '1',
                floatingCombatTextDodgeParryMiss = '1',
                floatingCombatTextEnergyGains = '1',
                floatingCombatTextFriendlyHealers = '1',
                floatingCombatTextLowManaHealth = '1',
                lootUnderMouse = '1',
                mapFade = '0',
                nameplateMotion = '1',
                nameplateNotSelectedAlpha = '1',
                nameplateShowEnemies = '1',
                showDynamicBuffSize = '1',
                showTargetCastbar = '1',
                showTargetOfTarget = '1',
                Sound_EnableErrorSpeech = '0',
                speechToText = '0',
                textToSpeech = '0',
                UnitNameOwn = '1',
                UIScale =  '0.75',
                useCompactPartyFrames = '1',
                useUiScale =  '1',
                whisperMode = 'inline',
                XpBarText = '1',
            }
        }
    },
    char = {
        priorityDebuffs = "",
    }
}

function ScarletUI:ResetDefaults()
    self.db:ResetDB()
    self:Setup()
    AceConfigRegistry:NotifyChange("ScarletUI")
end
