ScarletUI.editModeLayoutSchemaVersion = 10

-- Exported from Blizzard Edit Mode at 2560x1440. Native Edit Mode anchors
-- retain their edge/center relationships as the display resolution changes.
ScarletUI.editModeStandardLayoutString = [====[
2 31 0 0 0 7 7 UIParent -383.7 2.0 -1 ##$%%/&''%)$+#,$ 0 1 0 6 0 MainActionBar 0.0 4.0 -1 ##$%%/&''%(#,$ 0 2 0 6 0 MultiBarBottomLeft 0.0 4.0 -1 ##$%%/&''%(#,$ 0 3 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 4 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(&,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 1 1 4 UIParent 0.0 -50.0 -1 ##$$%/&('%(#,$ 0 7 1 1 4 UIParent 0.0 -100.0 -1 ##$$%/&('%(#,$ 0 10 0 0 0 UIParent 653.2 -720.0 -1 ##$$&('% 0 11 0 6 0 ChatFrame1 -32.0 64.0 -1 ##$$&('%,# 0 12 0 0 0 UIParent 2.0 -667.0 -1 ##$$&('% 1 -1 0 7 7 UIParent 0.0 314.0 -1 ##$# 2 -1 0 1 1 UIParent 819.7 -2.0 -1 ##$#%( 3 0 0 7 7 UIParent -218.0 296.0 -1 3# 3 1 0 7 7 UIParent 218.0 296.0 -1 %$3# 3 2 0 7 7 UIParent -366.5 540.0 -1 %#&#3# 3 3 0 0 0 UIParent 653.2 -754.0 -1 '$(#)$-A.3/#1#3#5$6(7-7$ 3 4 0 0 0 UIParent 675.2 -754.0 -1 ,$-9.1/#0#1#2(5$6(7-7$ 3 7 0 8 6 PlayerFrame 20.0 12.0 -1 3# 5 -1 0 0 0 UIParent 138.2 -554.0 -1 # 6 0 0 2 0 MinimapCluster -4.0 0.0 -1 ##$#%#&.(()( 6 1 0 0 6 BuffFrame 0.0 -4.0 -1 ##$#%#'.(()( 8 -1 0 6 0 MicroMenuContainer 32.0 36.0 -1 #&$Z%$&Y 9 -1 0 0 0 UIParent 1135.2 -718.0 -1 # 13 -1 0 7 7 UIParent -815.7 2.0 -1 ##$#%) 14 -1 0 7 7 UIParent 794.2 2.0 -1 ##$#%(&( 15 0 0 1 1 UIParent 0.0 -2.0 -1 &- 15 1 0 0 6 MainStatusTrackingBarContainer 0.0 -4.0 -1 &- 16 -1 0 8 2 ChatFrame1 25.0 64.0 -1 #( 18 -1 0 6 8 ChatFrame1 29.0 -32.0 -1 #- 24 -1 1 6 7 UIParent -240.0 46.0 -1 #
]====]

ScarletUI.editModeFrameCandidates = {
    -- MainActionBar is the Edit Mode system. MainMenuBar is the 1024px
    -- Classic artwork container and is not the movable button row.
    mainMenuBar = { "MainActionBar", "MainMenuBar" },
    multiBarBottomLeft = { "MultiBarBottomLeft" },
    multiBarBottomRight = { "MultiBarBottomRight" },
    multiBarLeft = { "MultiBarLeft" },
    multiBarRight = { "MultiBarRight" },
    stanceBar = { "StanceBar", "StanceBarFrame" },
    petBar = { "PetActionBar", "PetActionBarFrame" },
    playerFrame = { "PlayerFrame" },
    targetFrame = { "TargetFrame" },
    focusFrame = { "FocusFrame" },
    castBar = { "PlayerCastingBarFrame", "CastingBarFrame" },
    chatFrame = { "ChatFrame1" },
    vehicleLeaveButton = { "MainMenuBarVehicleLeaveButton" },
    extraActionBar = { "ExtraAbilityContainer", "ExtraActionBarFrame" },
    playerPowerBarAlt = { "EncounterBar", "PlayerPowerBarAlt" },
    microBar = { "MicroMenuContainer", "MicroButtonAndBagsBar", "MicroBar" },
    bagBar = { "BagsBar", "BagBar", "MicroButtonAndBagsBar" },
    experienceBar = { "MainStatusTrackingBarContainer", "MainMenuExpBar" },
    reputationBar = { "SecondaryStatusTrackingBarContainer", "ReputationWatchBar" },
    partyFrame = { "PartyFrame", "CompactPartyFrame" },
    raidFrame = { "CompactRaidFrameContainer", "CompactRaidFrameManager" },
}

local function EnumValue(enumTable, key)
    return { enumTable = enumTable, key = key }
end

local horizontal = EnumValue("ActionBarOrientation", "Horizontal")
local vertical = EnumValue("ActionBarOrientation", "Vertical")
local alwaysVisible = EnumValue("ActionBarVisibleSetting", "Always")

local function ActionBarSettings(orientation, includeVisibility)
    local settings = {
        { setting = EnumValue("EditModeActionBarSetting", "Orientation"), value = orientation },
        { setting = EnumValue("EditModeActionBarSetting", "NumRows"), value = 1 },
        { setting = EnumValue("EditModeActionBarSetting", "NumIcons"), value = 12 },
        { setting = EnumValue("EditModeActionBarSetting", "IconSize"), value = 100 },
        { setting = EnumValue("EditModeActionBarSetting", "IconPadding"), value = 3 },
        { setting = EnumValue("EditModeActionBarSetting", "AlwaysShowButtons"), value = 1 },
    }

    if includeVisibility then
        table.insert(settings, {
            setting = EnumValue("EditModeActionBarSetting", "VisibleSetting"),
            value = alwaysVisible,
        })
    end

    return settings
end

local standardFrames = {
    mainMenuBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 16,
        settings = {
            { setting = EnumValue("EditModeActionBarSetting", "Orientation"), value = horizontal },
            { setting = EnumValue("EditModeActionBarSetting", "NumRows"), value = 1 },
            { setting = EnumValue("EditModeActionBarSetting", "NumIcons"), value = 12 },
            { setting = EnumValue("EditModeActionBarSetting", "IconSize"), value = 100 },
            { setting = EnumValue("EditModeActionBarSetting", "IconPadding"), value = 3 },
            -- Keep the centered button row independent from Classic's much
            -- wider MainMenuBar artwork container.
            { setting = EnumValue("EditModeActionBarSetting", "HideBarArt"), value = 1 },
            { setting = EnumValue("EditModeActionBarSetting", "HideBarScrolling"), value = 0 },
            { setting = EnumValue("EditModeActionBarSetting", "AlwaysShowButtons"), value = 1 },
        },
    },
    multiBarBottomLeft = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 58,
        settings = ActionBarSettings(horizontal, true),
    },
    multiBarBottomRight = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 100,
        settings = ActionBarSettings(horizontal, true),
    },
    multiBarLeft = {
        point = "RIGHT", relativePoint = "RIGHT", x = -44, y = 0,
        settings = ActionBarSettings(vertical, true),
    },
    multiBarRight = {
        point = "RIGHT", relativePoint = "RIGHT", x = -2, y = 0,
        settings = ActionBarSettings(vertical, true),
    },
    stanceBar = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOM", x = -245, y = 145,
        settings = ActionBarSettings(horizontal, false),
    },
    petBar = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOM", x = -240, y = 145,
        settings = ActionBarSettings(horizontal, false),
    },
    playerFrame = {
        point = "TOPRIGHT", relativePoint = "CENTER", x = -65, y = -190,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameSize"), value = 100 },
        },
    },
    targetFrame = {
        point = "TOPLEFT", relativePoint = "CENTER", x = 65, y = -190,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "BuffsOnTop"), value = 1 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameSize"), value = 100 },
        },
    },
    focusFrame = {
        point = "TOPRIGHT", relativePoint = "CENTER", x = -220, y = -255,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "BuffsOnTop"), value = 1 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameSize"), value = 100 },
        },
    },
    castBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 192,
        settings = {
            { setting = EnumValue("EditModeCastBarSetting", "BarSize"), value = 100 },
            { setting = EnumValue("EditModeCastBarSetting", "LockToPlayerFrame"), value = 0 },
        },
    },
    chatFrame = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 0, y = 75,
        settings = {
            { setting = EnumValue("EditModeChatFrameSetting", "WidthHundreds"), value = 4 },
            { setting = EnumValue("EditModeChatFrameSetting", "WidthTensAndOnes"), value = 0 },
            { setting = EnumValue("EditModeChatFrameSetting", "HeightHundreds"), value = 1 },
            { setting = EnumValue("EditModeChatFrameSetting", "HeightTensAndOnes"), value = 50 },
        },
    },
    vehicleLeaveButton = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 234, y = 145,
    },
    extraActionBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 245,
    },
    playerPowerBarAlt = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 217,
    },
    experienceBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 0,
        settings = {
            { setting = EnumValue("EditModeStatusTrackingBarSetting", "Size"), value = 100 },
        },
    },
    reputationBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 0,
        settings = {
            { setting = EnumValue("EditModeStatusTrackingBarSetting", "Size"), value = 100 },
        },
    },
    microBar = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 2, y = 2,
        settings = {
            { setting = EnumValue("EditModeMicroMenuSetting", "Orientation"), value = EnumValue("MicroMenuOrientation", "Horizontal") },
            { setting = EnumValue("EditModeMicroMenuSetting", "Size"), value = 100 },
        },
    },
    bagBar = {
        point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -2, y = 2,
        settings = {
            { setting = EnumValue("EditModeBagsSetting", "Orientation"), value = EnumValue("BagsOrientation", "Horizontal") },
            { setting = EnumValue("EditModeBagsSetting", "Direction"), value = EnumValue("BagsDirection", "Left") },
            { setting = EnumValue("EditModeBagsSetting", "Size"), value = 100 },
        },
    },
    partyFrame = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 535, y = 225,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "UseRaidStylePartyFrames"), value = 1 },
            { setting = EnumValue("EditModeUnitFrameSetting", "UseHorizontalGroups"), value = 0 },
            { setting = EnumValue("EditModeUnitFrameSetting", "DisplayBorder"), value = 0 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameHeight"), value = 46 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameWidth"), value = 90 },
        },
    },
    raidFrame = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 165, y = 90,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "RaidGroupDisplayType"), value = EnumValue("RaidGroupDisplayType", "SeparateGroupsHorizontal") },
            { setting = EnumValue("EditModeUnitFrameSetting", "SortPlayersBy"), value = EnumValue("SortPlayersBy", "Group") },
            { setting = EnumValue("EditModeUnitFrameSetting", "DisplayBorder"), value = 0 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameHeight"), value = 46 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameWidth"), value = 90 },
            { setting = EnumValue("EditModeUnitFrameSetting", "RowSize"), value = 5 },
        },
    },
}

ScarletUI.editModeLayouts = {
    STANDARD = {
        label = "Standard",
        frames = standardFrames,
    },
    COMPACT = {
        label = "Compact",
        overrides = {
            playerFrame = { x = -50, y = -170 },
            targetFrame = { x = 50, y = -170 },
            focusFrame = { x = -170, y = -230 },
            chatFrame = {
                settings = {
                    { setting = EnumValue("EditModeChatFrameSetting", "WidthHundreds"), value = 3 },
                    { setting = EnumValue("EditModeChatFrameSetting", "WidthTensAndOnes"), value = 50 },
                    { setting = EnumValue("EditModeChatFrameSetting", "HeightHundreds"), value = 1 },
                    { setting = EnumValue("EditModeChatFrameSetting", "HeightTensAndOnes"), value = 30 },
                },
            },
            partyFrame = { x = 40, y = 225 },
        },
    },
    ULTRAWIDE = {
        label = "Ultrawide",
        overrides = {
            -- Combat elements intentionally remain centered on ultrawide displays.
            chatFrame = { x = 24, y = 75 },
            microBar = { x = 24, y = 2 },
            bagBar = { x = -24, y = 2 },
        },
    },
}

local function MergeLayout(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            MergeLayout(target[key], value)
        else
            target[key] = value
        end
    end
end

function ScarletUI:GetEditModeLayoutDefinition(variant)
    local layout = self.editModeLayouts[variant] or self.editModeLayouts.STANDARD
    local frames = CopyTable(self.editModeLayouts.STANDARD.frames)
    MergeLayout(frames, layout.overrides)
    return frames
end
