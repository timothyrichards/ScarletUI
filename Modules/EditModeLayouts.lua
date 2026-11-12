ScarletUI.editModeLayoutSchemaVersion = 19

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
    possessBar = { "PossessActionBar", "PossessBarFrame" },
    petFrame = { "PetFrame" },
    bossFrame = { "BossTargetFrameContainer" },
    hudTooltip = { "GameTooltipDefaultContainer" },
    durabilityFrame = { "DurabilityFrame" },
    essentialCooldowns = { "EssentialCooldownViewer" },
    buffIconCooldowns = { "BuffIconCooldownViewer" },
    buffBarCooldowns = { "BuffBarCooldownViewer" },
    utilityCooldowns = { "UtilityCooldownViewer" },
    totemBar = { "MultiCastActionBarFrame" },
    swingTimerMainHand = { "SwingTimerMainHandFrame" },
    swingTimerOffHand = { "SwingTimerOffHandFrame" },
    swingTimerRanged = { "SwingTimerRangedFrame" },
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

local function UnitFrameSetting(key, value)
    return { setting = EnumValue("EditModeUnitFrameSetting", key), value = value }
end

-- Aura options shared by the party and raid frames.
local function GroupAuraSettings(settings)
    table.insert(settings, UnitFrameSetting("AuraOrganizationType", EnumValue("RaidAuraOrganizationType", "Legacy")))
    table.insert(settings, UnitFrameSetting("DebuffIconSize", 100))
    table.insert(settings, UnitFrameSetting("BigDefensiveIconSize", 75))
    table.insert(settings, UnitFrameSetting("BuffIconSize", 100))
    return settings
end

local function CooldownViewerSetting(key, value)
    return { setting = EnumValue("EditModeCooldownViewerSetting", key), value = value }
end

local function CooldownViewerSettings(orientation, iconLimit, iconDirection, iconPadding)
    return {
        CooldownViewerSetting("Orientation", EnumValue("CooldownViewerOrientation", orientation)),
        CooldownViewerSetting("IconLimit", iconLimit),
        CooldownViewerSetting("IconDirection", EnumValue("CooldownViewerIconDirection", iconDirection)),
        CooldownViewerSetting("IconSize", 100),
        CooldownViewerSetting("IconPadding", iconPadding),
        CooldownViewerSetting("VisibleSetting", EnumValue("CooldownViewerVisibleSetting", "Always")),
        CooldownViewerSetting("HideWhenInactive", 1),
        CooldownViewerSetting("ShowTimer", 1),
        CooldownViewerSetting("ShowTooltips", 1),
    }
end

local buffBarSettings = CooldownViewerSettings("Vertical", 1, "Left", 5)
table.insert(buffBarSettings, CooldownViewerSetting("BarContent", EnumValue("CooldownViewerBarContent", "IconAndName")))
table.insert(buffBarSettings, CooldownViewerSetting("BarWidthScale", 150))

local function SwingTimerSetting(key, value)
    return { setting = EnumValue("EditModeSwingTimerSetting", key), value = value }
end

-- Width and Height are stored as the distance above the slider minimum.
local swingTimerSettings = {
    SwingTimerSetting("Scale", 80),
    SwingTimerSetting("Opacity", 100),
    SwingTimerSetting("Visibility", EnumValue("EditModeSwingTimerVisibility", "Always")),
    SwingTimerSetting("Width", 426),
    SwingTimerSetting("Height", 30),
    SwingTimerSetting("ShowBarTitle", 1),
    SwingTimerSetting("ShowTime", 1),
}

-- Frames with relativeTo snap to another layout key, matching Blizzard's
-- stacked-bar anchors. Screen anchors use the nearest screen edge so they
-- hold across UI scales. The group frames, Essential cooldowns, and swing timers
-- line up with the bottom-center unit frames, so they anchor to the bottom
-- center too; offsets were captured on a 2133x1200 UIParent (1440p).
-- A fallback is the screen anchor used when the relativeTo frame is missing.
local standardFrames = {
    mainMenuBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 22,
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
    totemBar = {
        point = "BOTTOMLEFT", relativeTo = "multiBarBottomRight", relativePoint = "TOPLEFT", x = 0, y = 4,
    },
    possessBar = {
        point = "BOTTOMRIGHT", relativeTo = "vehicleLeaveButton", relativePoint = "BOTTOMLEFT", x = -4, y = 0,
        settings = {
            { setting = EnumValue("EditModeActionBarSetting", "Orientation"), value = horizontal },
            { setting = EnumValue("EditModeActionBarSetting", "NumRows"), value = 1 },
            { setting = EnumValue("EditModeActionBarSetting", "IconSize"), value = 100 },
            { setting = EnumValue("EditModeActionBarSetting", "IconPadding"), value = 2 },
        },
    },
    playerFrame = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = -258, y = 236,
        settings = {
            UnitFrameSetting("CastBarUnderneath", 0),
            UnitFrameSetting("FrameSize", 100),
        },
    },
    targetFrame = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 258, y = 236,
        settings = {
            UnitFrameSetting("BuffsOnTop", 1),
            UnitFrameSetting("FrameSize", 100),
        },
    },
    focusFrame = {
        point = "TOPLEFT", relativeTo = "multiBarBottomRight", relativePoint = "TOPRIGHT", x = -11.5, y = 12.5,
        settings = {
            UnitFrameSetting("BuffsOnTop", 1),
            UnitFrameSetting("UseLargerFrame", 0),
            UnitFrameSetting("FrameSize", 100),
        },
    },
    petFrame = {
        point = "TOPRIGHT", relativeTo = "multiBarBottomRight", relativePoint = "TOPLEFT", x = 0, y = 3,
        settings = {
            UnitFrameSetting("FrameSize", 100),
        },
    },
    bossFrame = {
        point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -412.2, y = -334,
        settings = {
            UnitFrameSetting("UseLargerFrame", 0),
            UnitFrameSetting("CastBarOnSide", 1),
            UnitFrameSetting("FrameSize", 100),
        },
    },
    -- Stacked upward: Essential cooldowns, cast bar, Utility cooldowns. The
    -- spell name box hangs 14 below the cast bar frame, so 18 leaves a gap of 4.
    -- Clients without the Cooldown Manager get the same spot as a screen anchor.
    castBar = {
        point = "BOTTOM", relativeTo = "essentialCooldowns", relativePoint = "TOP", x = 0, y = 18,
        fallback = { point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 327 },
        settings = {
            { setting = EnumValue("EditModeCastBarSetting", "BarSize"), value = 100 },
            { setting = EnumValue("EditModeCastBarSetting", "LockToPlayerFrame"), value = 0 },
            { setting = EnumValue("EditModeCastBarSetting", "ShowCastTime"), value = 0 },
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
            { setting = EnumValue("EditModeStatusTrackingBarSetting", "Size"), value = 50 },
        },
    },
    reputationBar = {
        point = "BOTTOM", relativePoint = "BOTTOM", x = 0, y = 0,
        settings = {
            { setting = EnumValue("EditModeStatusTrackingBarSetting", "Size"), value = 50 },
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
        settings = {
            { setting = EnumValue("EditModeDamageMeterSetting", "Visibility"), value = EnumValue("DamageMeterVisibility", "Always") },
            { setting = EnumValue("EditModeDamageMeterSetting", "Style"), value = EnumValue("DamageMeterStyle", "Default") },
            { setting = EnumValue("EditModeDamageMeterSetting", "Numbers"), value = EnumValue("DamageMeterNumbers", "Compact") },
            { setting = EnumValue("EditModeDamageMeterSetting", "FrameWidth"), value = 287 },
            { setting = EnumValue("EditModeDamageMeterSetting", "FrameHeight"), value = 213 },
            { setting = EnumValue("EditModeDamageMeterSetting", "BarHeight"), value = 16 },
            { setting = EnumValue("EditModeDamageMeterSetting", "Padding"), value = 4 },
            { setting = EnumValue("EditModeDamageMeterSetting", "Transparency"), value = 100 },
            { setting = EnumValue("EditModeDamageMeterSetting", "BackgroundTransparency"), value = 50 },
            { setting = EnumValue("EditModeDamageMeterSetting", "TextSize"), value = 100 },
            { setting = EnumValue("EditModeDamageMeterSetting", "ShowSpecIcon"), value = 1 },
            { setting = EnumValue("EditModeDamageMeterSetting", "ShowClassColor"), value = 1 },
        },
    },
    hudTooltip = {
        point = "BOTTOMRIGHT", relativeTo = "damageMeter", relativePoint = "TOPRIGHT", x = 0, y = 4,
    },
    durabilityFrame = {
        point = "TOPLEFT", relativePoint = "TOPRIGHT", x = -356.6, y = -286,
        settings = {
            { setting = EnumValue("EditModeDurabilityFrameSetting", "Size"), value = 100 },
        },
    },
    -- Center anchors, so the bars stay centered as icons are added or removed.
    essentialCooldowns = {
        point = "TOP", relativePoint = "BOTTOM", x = 0, y = 309,
        settings = CooldownViewerSettings("Horizontal", 12, "Right", 2),
    },
    utilityCooldowns = {
        point = "BOTTOM", relativeTo = "castBar", relativePoint = "TOP", x = 0, y = 4,
        settings = CooldownViewerSettings("Horizontal", 7, "Right", 2),
    },
    swingTimerMainHand = {
        point = "CENTER", relativePoint = "BOTTOM", x = 0, y = 400,
        settings = swingTimerSettings,
    },
    swingTimerOffHand = {
        point = "BOTTOMLEFT", relativeTo = "swingTimerMainHand", relativePoint = "TOPLEFT", x = 0, y = 3.2,
        settings = swingTimerSettings,
    },
    swingTimerRanged = {
        point = "CENTER", relativePoint = "BOTTOM", x = 0, y = 400,
        settings = swingTimerSettings,
    },
    buffIconCooldowns = {
        point = "BOTTOMRIGHT", relativeTo = "playerFrame", relativePoint = "TOPRIGHT", x = -20, y = -12,
        settings = CooldownViewerSettings("Horizontal", 1, "Right", 5),
    },
    buffBarCooldowns = {
        point = "TOP", relativePoint = "TOP", x = 0, y = -34,
        settings = buffBarSettings,
    },
    partyFrame = {
        point = "TOPLEFT", relativePoint = "BOTTOM", x = -372, y = 698,
        settings = GroupAuraSettings({
            UnitFrameSetting("UseRaidStylePartyFrames", 1),
            UnitFrameSetting("ShowPartyFrameBackground", 0),
            UnitFrameSetting("UseHorizontalGroups", 0),
            UnitFrameSetting("SortPlayersBy", EnumValue("SortPlayersBy", "Role")),
            UnitFrameSetting("DisplayBorder", 0),
            UnitFrameSetting("FrameHeight", 52),
            UnitFrameSetting("FrameWidth", 96),
            UnitFrameSetting("FrameSize", 100),
        }),
    },
    raidFrame = {
        point = "TOPLEFT", relativePoint = "BOTTOM", x = -712, y = 898,
        settings = GroupAuraSettings({
            UnitFrameSetting("RaidGroupDisplayType", EnumValue("RaidGroupDisplayType", "SeparateGroupsHorizontal")),
            UnitFrameSetting("SortPlayersBy", EnumValue("SortPlayersBy", "Group")),
            UnitFrameSetting("DisplayBorder", 0),
            UnitFrameSetting("FrameHeight", 46),
            UnitFrameSetting("FrameWidth", 90),
            UnitFrameSetting("RowSize", 5),
            UnitFrameSetting("FrameSize", 100),
        }),
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
            -- Compact keeps its previous center-anchored unit frames.
            playerFrame = { point = "TOPRIGHT", relativePoint = "CENTER", x = -50, y = -170 },
            targetFrame = { point = "TOPLEFT", relativePoint = "CENTER", x = 50, y = -170 },
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
            -- The Standard raid offsets reach past a compact screen's left and top edges.
            raidFrame = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 196.6, y = -174 },
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
