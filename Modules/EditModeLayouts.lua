ScarletUI.editModeLayoutSchemaVersion = 13

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
    damageMeter = { "DamageMeter" },
}

local function EnumValue(enumTable, key)
    return { enumTable = enumTable, key = key }
end

local horizontal = EnumValue("ActionBarOrientation", "Horizontal")
local vertical = EnumValue("ActionBarOrientation", "Vertical")
local alwaysVisible = EnumValue("ActionBarVisibleSetting", "Always")

local function ActionBarSettings(orientation, includeVisibility, iconSize)
    local settings = {
        { setting = EnumValue("EditModeActionBarSetting", "Orientation"), value = orientation },
        { setting = EnumValue("EditModeActionBarSetting", "NumRows"), value = 1 },
        { setting = EnumValue("EditModeActionBarSetting", "NumIcons"), value = 12 },
        { setting = EnumValue("EditModeActionBarSetting", "IconSize"), value = iconSize or 100 },
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

-- Frames with relativeTo snap to another layout key, matching Blizzard's
-- stacked-bar anchors. Screen anchors use the nearest screen edge so they
-- hold across UI scales.
local standardFrames = {
    mainMenuBar = {
        point = "CENTER", relativePoint = "BOTTOM", x = 0, y = 41.9,
        settings = {
            { setting = EnumValue("EditModeActionBarSetting", "Orientation"), value = horizontal },
            { setting = EnumValue("EditModeActionBarSetting", "NumRows"), value = 1 },
            { setting = EnumValue("EditModeActionBarSetting", "NumIcons"), value = 12 },
            { setting = EnumValue("EditModeActionBarSetting", "IconSize"), value = 90 },
            { setting = EnumValue("EditModeActionBarSetting", "IconPadding"), value = 3 },
            -- Keep the centered button row independent from Classic's much
            -- wider MainMenuBar artwork container.
            { setting = EnumValue("EditModeActionBarSetting", "HideBarArt"), value = 1 },
            { setting = EnumValue("EditModeActionBarSetting", "HideBarScrolling"), value = 0 },
            { setting = EnumValue("EditModeActionBarSetting", "AlwaysShowButtons"), value = 1 },
        },
    },
    multiBarBottomLeft = {
        point = "BOTTOMRIGHT", relativeTo = "mainMenuBar", relativePoint = "TOPRIGHT", x = 0, y = 4,
        settings = ActionBarSettings(horizontal, true, 90),
    },
    multiBarBottomRight = {
        point = "BOTTOMRIGHT", relativeTo = "multiBarBottomLeft", relativePoint = "TOPRIGHT", x = 0, y = 4,
        settings = ActionBarSettings(horizontal, true, 90),
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
        point = "BOTTOMLEFT", relativeTo = "multiBarBottomRight", relativePoint = "TOPLEFT", x = 0, y = 4,
        settings = ActionBarSettings(horizontal, false),
    },
    petBar = {
        point = "BOTTOMLEFT", relativeTo = "multiBarBottomRight", relativePoint = "TOPLEFT", x = 0, y = 4,
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
        point = "BOTTOMLEFT", relativeTo = "playerFrame", relativePoint = "TOPLEFT", x = 4.5, y = -26,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "BuffsOnTop"), value = 1 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameSize"), value = 100 },
        },
    },
    castBar = {
        point = "TOP", relativePoint = "BOTTOM", x = 0, y = 210,
        settings = {
            { setting = EnumValue("EditModeCastBarSetting", "BarSize"), value = 100 },
            { setting = EnumValue("EditModeCastBarSetting", "LockToPlayerFrame"), value = 0 },
        },
    },
    chatFrame = {
        point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 33, y = 86,
        settings = {
            { setting = EnumValue("EditModeChatFrameSetting", "WidthHundreds"), value = 4 },
            { setting = EnumValue("EditModeChatFrameSetting", "WidthTensAndOnes"), value = 30 },
            { setting = EnumValue("EditModeChatFrameSetting", "HeightHundreds"), value = 1 },
            { setting = EnumValue("EditModeChatFrameSetting", "HeightTensAndOnes"), value = 70 },
        },
    },
    vehicleLeaveButton = {
        point = "BOTTOMRIGHT", relativeTo = "multiBarBottomRight", relativePoint = "TOPRIGHT", x = 0, y = 4,
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
    -- Blizzard's default is the screen's top-left corner.
    damageMeter = {
        point = "BOTTOMRIGHT", relativeTo = "bagBar", relativePoint = "TOPRIGHT", x = 0, y = 4,
    },
    partyFrame = {
        point = "TOPLEFT", relativePoint = "TOPLEFT", x = 534.2, y = -444,
        settings = {
            { setting = EnumValue("EditModeUnitFrameSetting", "UseRaidStylePartyFrames"), value = 1 },
            { setting = EnumValue("EditModeUnitFrameSetting", "UseHorizontalGroups"), value = 0 },
            { setting = EnumValue("EditModeUnitFrameSetting", "DisplayBorder"), value = 0 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameHeight"), value = 46 },
            { setting = EnumValue("EditModeUnitFrameSetting", "FrameWidth"), value = 90 },
        },
    },
    raidFrame = {
        point = "TOPLEFT", relativePoint = "TOPLEFT", x = 154.6, y = -210,
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
            focusFrame = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "CENTER", x = -170, y = -230 },
            chatFrame = {
                settings = {
                    { setting = EnumValue("EditModeChatFrameSetting", "WidthHundreds"), value = 3 },
                    { setting = EnumValue("EditModeChatFrameSetting", "WidthTensAndOnes"), value = 50 },
                    { setting = EnumValue("EditModeChatFrameSetting", "HeightHundreds"), value = 1 },
                    { setting = EnumValue("EditModeChatFrameSetting", "HeightTensAndOnes"), value = 30 },
                },
            },
            partyFrame = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 40, y = 225 },
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
