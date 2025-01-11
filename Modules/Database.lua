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
                y = -190,
                scale = 1
            },
            targetFrame = {
                mirrorPlayerFrame = true,
                buffsOnTop = true,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 4, -- CENTER
                x = 65,
                y = -190,
                scale = 1
            },
            focusFrame = {
                buffsOnTop = true,
                move = true,
                frameAnchor = 9, -- TOPRIGHT
                screenAnchor = 4, -- CENTER
                x = -220,
                y = -255,
                scale = 1
            },
            castBar = {
                move = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 192,
                scale = 1
            },
        },
        moversModule = {
            enabled = true
        },
        actionbarsModule = {
            enabled = true,
            showPagingNumbers = true,
            showGryphons = true,
            showMainBarBackground = true,
            microBag = false,
            mainMenuBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 0,
                scale = 1
            },
            vehicleLeaveButton = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 234,
                y = 145,
                scale = 1
            },
            multiBarBottomLeft = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 58,
                scale = 1
            },
            multiBarBottomRight = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 100,
                scale = 1
            },
            multiBarLeft = {
                move = true,
                hide = false,
                buttonsPerRow = 1,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = -44,
                y = 0,
                scale = 1
            },
            multiBarRight = {
                move = true,
                hide = false,
                buttonsPerRow = 1,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = -2,
                y = 0,
                scale = 1
            },
            stanceBar = {
                move = true,
                hide = false,
                buttonsPerRow = 10,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -245,
                y = 145,
                scale = 1
            },
            petBar = {
                move = true,
                hide = false,
                buttonsPerRow = 10,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -240,
                y = 145,
                scale = 1
            },
            multiCastBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 1, -- BOTTOM
                x = -240,
                y = 145,
                scale = 1
            },
            experienceBar = {
                move = true,
                hide = false,
                short = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 44,
                scale = 1
            },
            reputationBar = {
                move = true,
                hide = false,
                short = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 42,
                scale = 1
            },
            microBar = {
                move = true,
                hide = false,
                frameAnchor = 2, -- BOTTOMLEFT
                screenAnchor = 2, -- BOTTOMLEFT
                x = 2,
                y = 2,
                scale = 1
            },
            bagBar = {
                move = true,
                hide = false,
                frameAnchor = 3, -- BOTTOMRIGHT
                screenAnchor = 3, -- BOTTOMRIGHT
                x = -2,
                y = 2,
                scale = 1
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
                y = 75,
                scale = 1
            }
        },
        raidFramesModule = {
            enabled = true,
            profiles = {
                Party = {
                    move = true,
                    createProfile = true,
                    savedPosition = {
                        dynamic = false,
                        topPoint = "TOP",
                        topOffset = 450,
                        bottomPoint = "BOTTOM",
                        bottomOffset = 225,
                        leftPoint = "LEFT",
                        leftOffset = 535
                    },
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
                    createProfile = true,
                    savedPosition = {
                        dynamic = false,
                        topPoint = "TOP",
                        topOffset = 375,
                        bottomPoint = "BOTTOM",
                        bottomOffset = 90,
                        leftPoint = "LEFT",
                        leftOffset = 165
                    },
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
            dropdownMenuButton = true,
            buffTracker = {
                track = true,
                iconSize = 30,
                spacing = 2,
                verticalOffset = 20,
            },
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
            threatAmountText = {
                show = true,
                fontSize = 18,
                anchor = 1, -- LEFT
            },
            castBarText = {
                show = true,
                fontSize = 10
            },
            nonTankThreatColors = {
                noThreat = { 0.0824, 1, 0, 1 },
                lowThreat = { 1, 0.9176, 0, 1 },
                threat = { 1, 0.0353, 0, 1 },
                pet = { 0, 0.95, 1, 1 },
                tank = { 0, 0.7020, 1, 1 }
            },
            tankThreatColors = {
                noThreat = { 1, 0.0353, 0, 1 },
                lowThreat = { 1, 0.9176, 0, 1 },
                threat = { 0.0824, 1, 0, 1 },
                pet = { 0, 0.95, 1, 1 },
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
                nameplateShowAll = '1',
                nameplateOverlapH = '0.8',
                nameplateOverlapV = '1.1',
                nameplateMinScale = '1',
                nameplateMaxScale = '1',
                nameplateMinAlpha = '1',
                nameplateMaxAlpha = '1',
                nameplateSelfScale = '1',
                nameplateSelfAlpha = '0.75',
                nameplateOtherAtBase = '0',
                nameplateShowEnemies = '1',
                nameplateShowFriends = '0',
                nameplateMaxDistance = '41',
                nameplateMotionSpeed = '0.025',
                nameplateGlobalScale = '1',
                nameplateLargerScale = '1.2',
                nameplateSelfTopInset = '0.5',
                nameplateShowEnemyPets = '0',
                nameplateSelectedScale = '1',
                nameplateNotSelectedAlpha = '1',
                pvpFramesDisplayClassColor = '1',
                pvpFramesDisplayPowerBars = '1',
                raidFramesDisplayClassColor = '1',
                raidFramesDisplayPowerBars = '1',
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
                y = -4,
                scale = 1
            },
            targetFrame = {
                mirrorPlayerFrame = false,
                buffsOnTop = false,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 8, -- TOPLEFT
                x = 250,
                y = -4,
                scale = 1
            },
            focusFrame = {
                buffsOnTop = false,
                move = true,
                frameAnchor = 8, -- TOPLEFT
                screenAnchor = 8, -- TOPLEFT
                x = 250,
                y = -240,
                scale = 1
            },
            castBar = {
                move = true,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 192,
                scale = 1
            },
        },
        moversModule = {
            enabled = true
        },
        actionbarsModule = {
            enabled = true,
            showPagingNumbers = true,
            showGryphons = false,
            showMainBarBackground = true,
            microBag = false,
            mainMenuBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -256,
                y = 0,
                scale = 1
            },
            vehicleLeaveButton = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 490,
                y = 100,
                scale = 1
            },
            multiBarBottomLeft = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -256,
                y = 57,
                scale = 1
            },
            multiBarBottomRight = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 254,
                y = 57,
                scale = 1
            },
            multiBarLeft = {
                move = true,
                hide = false,
                buttonsPerRow = 1,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = -42,
                y = 0,
                scale = 1
            },
            multiBarRight = {
                move = true,
                hide = false,
                buttonsPerRow = 1,
                frameAnchor = 6, -- RIGHT
                screenAnchor = 6, -- RIGHT
                x = 0,
                y = 0,
                scale = 1
            },
            stanceBar = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -260,
                y = 105,
                scale = 1
            },
            petBar = {
                move = true,
                hide = false,
                buttonsPerRow = 12,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 260,
                y = 105,
                scale = 1
            },
            multiCastBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = -361,
                y = 103,
                scale = 1
            },
            experienceBar = {
                move = true,
                hide = false,
                short = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 44,
                scale = 1
            },
            reputationBar = {
                move = true,
                hide = false,
                short = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 0,
                y = 42,
                scale = 1
            },
            microBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 185,
                y = 2,
                scale = 1
            },
            bagBar = {
                move = true,
                hide = false,
                frameAnchor = 1, -- BOTTOM
                screenAnchor = 1, -- BOTTOM
                x = 410,
                y = 2,
                scale = 1
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
                y = 184,
                scale = 1
            }
        },
        raidFramesModule = {
            enabled = true,
            profiles = {
                Party = {
                    move = true,
                    createProfile = true,
                    savedPosition = {
                        dynamic = false,
                        topPoint = "TOP",
                        topOffset = 450,
                        bottomPoint = "BOTTOM",
                        bottomOffset = 225,
                        leftPoint = "LEFT",
                        leftOffset = 535
                    },
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
                    createProfile = true,
                    savedPosition = {
                        dynamic = false,
                        topPoint = "TOP",
                        topOffset = 375,
                        bottomPoint = "BOTTOM",
                        bottomOffset = 90,
                        leftPoint = "LEFT",
                        leftOffset = 165
                    },
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
            buffTracker = {
                track = true,
                iconSize = 30,
                spacing = 2,
                verticalOffset = 20,
            },
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
                pet = { 0, 0.95, 1, 1 },
                tank = { 0, 0.7020, 1, 1 }
            },
            tankThreatColors = {
                noThreat = { 1, 0.0353, 0, 1 },
                lowThreat = { 1, 0.9176, 0, 1 },
                threat = { 0.0824, 1, 0, 1 },
                pet = { 0, 0.95, 1, 1 },
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
                nameplateShowAll = '1',
                nameplateOverlapH = '0.8',
                nameplateOverlapV = '1.1',
                nameplateMinScale = '1',
                nameplateMaxScale = '1',
                nameplateMinAlpha = '1',
                nameplateMaxAlpha = '1',
                nameplateSelfScale = '1',
                nameplateSelfAlpha = '0.75',
                nameplateOtherAtBase = '0',
                nameplateShowEnemies = '1',
                nameplateShowFriends = '0',
                nameplateMaxDistance = '41',
                nameplateMotionSpeed = '0.025',
                nameplateGlobalScale = '1',
                nameplateLargerScale = '1.2',
                nameplateSelfTopInset = '0.5',
                nameplateShowEnemyPets = '0',
                nameplateSelectedScale = '1',
                nameplateNotSelectedAlpha = '1',
                pvpFramesDisplayClassColor = '1',
                pvpFramesDisplayPowerBars = '1',
                raidFramesDisplayClassColor = '1',
                raidFramesDisplayPowerBars = '1',
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
    self:UpdateProfileOptions()
    self:Print("Settings have been reset to default.")
    AceConfigRegistry:NotifyChange("ScarletUI")
end
