-- Run from the addon root: lua tests/module-loading.lua
dofile("tests/client-compatibility.lua")
dofile("ScarletUI.lua")
local function noop() end
LibStub = function()
    return { NotifyChange = noop, AddLayout = noop, ApplyChanges = noop }
end
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
GetBuildInfo = function() return nil, nil, nil, 16001 end
Enum = { EditModeLayoutType = { Account = 1 } }
for _, name in ipairs({ "Database", "Helpers", "Options", "EditModeLayouts", "EditMode" }) do
    dofile("Modules/" .. name .. ".lua")
end
ScarletUI.db = {
    global = ScarletUI.defaults.global,
    char = ScarletUI.defaults.char,
    defaults = ScarletUI.defaults,
}
ScarletUI.knownCVars = {}
GetCVar = function() return nil end
assert(ScarletUI.defaults.global.actionbarsModule == nil)
assert(ScarletUI.originalUIDefaults.global.actionbarsModule == nil)
assert(ScarletUI.SetupActionBars == nil and ScarletUI.SetupActionBarPreferences == nil)
assert(ScarletUI.defaults.global.bagModule == nil and ScarletUI.originalUIDefaults.global.bagModule == nil)
assert(ScarletUI.SetupBags == nil and ScarletUI.SetupBank == nil)
assert(ScarletUI.CreateMover == nil and ScarletUI.SetupUnitFrames == nil)
assert(ScarletUI.defaults.global.moversModule == nil and ScarletUI.defaults.global.unitFramesModule == nil)
assert(ScarletUI.SetupNameplates == nil and ScarletUI.GetNameplatesModuleSettingsPage == nil)
assert(ScarletUI.defaults.global.nameplatesModule == nil and ScarletUI.originalUIDefaults.global.nameplatesModule == nil)
assert(ScarletUI.defaults.char.priorityDebuffs == nil)

assert(ScarletUI.SetupRaidProfiles == nil and ScarletUI.UpdateProfileOptions == nil)
assert(ScarletUI.defaults.global.raidFramesModule == nil and ScarletUI.originalUIDefaults.global.raidFramesModule == nil)
assert(StaticPopupDialogs.SCARLET_UI_RAID_FRAME_DIALOG == nil)
assert(StaticPopupDialogs.SCARLET_DELETE_RAID_PROFILE_DIALOG == nil)

-- Both fresh settings and saved settings from before removal must load.
for _, oldSettings in ipairs({ false, true }) do
    ScarletUI.db.global.actionbarsModule = oldSettings and { enabled = true } or nil
    ScarletUI.db.global.bagModule = oldSettings and { enabled = true } or nil
    ScarletUI.db.global.moversModule = oldSettings and { enabled = true } or nil
    ScarletUI.db.global.nameplatesModule = oldSettings and { enabled = true } or nil
    ScarletUI.db.char.priorityDebuffs = oldSettings and "Sunder Armor" or nil
    ScarletUI.db.global.raidFramesModule = oldSettings and { enabled = true } or nil
    local options = ScarletUI:Options()
    assert(options.args.actionBarSettings == nil)
    assert(options.args.generalSettings.args.modules.args.actionbarsModuleEnabled == nil)
    assert(options.args.bagModuleSettings == nil and options.args.editModeSettings)
    assert(options.args.generalSettings.args.modules.args.bagModuleEnabled == nil)
    assert(options.args.toggleMovers == nil and options.args.resetPositions == nil)
    assert(options.args.generalSettings.args.general.args.clampMovers == nil)
    assert(options.args.generalSettings.args.modules.args.unitFramesModuleEnabled == nil)
    assert(options.args.raidFramesModuleSettings == nil)
    assert(options.args.generalSettings.args.modules.args.raidFramesModuleEnabled == nil)
    assert(options.args.nameplatesModuleSettings == nil)
    assert(options.args.generalSettings.args.modules.args.nameplatesModuleEnabled == nil)
end

-- Exercise the real setup dispatcher with only the remaining module methods.
local calls = {}
local setupMethods = { "SetupDebugFrame", "SetupChat", "SetupCVars",
    "SetupItemLevels",
    "SetupTidyIcons", "SetupExpandCharacterInfo" }
for _, name in ipairs(setupMethods) do
    ScarletUI[name] = function() calls[name] = true end
end
for _, editMode in ipairs({ false, true }) do
    calls = {}
    ScarletUI.editMode = editMode
    ScarletUI:Setup()
    for _, name in ipairs(setupMethods) do
        assert(calls[name], name)
    end
end

local resetCalled = false
InCombatLockdown = function() return false end
ScarletUI.db.ResetDB = function() resetCalled = true end
ScarletUI.Print = noop
ScarletUI:ResetDefaults()
assert(resetCalled)

-- Era applies the same preset definitions as the other clients.
CopyTable = function(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = type(value) == "table" and CopyTable(value) or value
    end
    return copy
end
assert(ScarletUI.editModeStandardLayoutString == nil)
assert(ScarletUI.ApplyImportedEditModeLayout == nil)
local originalLibStub, originalClient = LibStub, ScarletUI.GetWoWVersion
local originalFindFrame = ScarletUI.FindEditModeFrame
local anchors = {}
LibStub = function()
    return {
        ReanchorFrame = function(_, frame, _, _, _, x, y) anchors[frame] = { x, y } end,
        SetFrameSetting = noop,
    }
end
ScarletUI.GetWoWVersion = function() return "VANILLA", 11509 end
ScarletUI.FindEditModeFrame = function(_, key) return key end
for _, variant in ipairs({ "STANDARD", "COMPACT", "ULTRAWIDE" }) do
    anchors = {}
    assert(ScarletUI:ApplyEditModeLayout(variant))
    assert(#ScarletUI.editModeSkippedSystems == 0)
    assert(anchors.raidFrame[1] == 165 and anchors.raidFrame[2] == 90)
    assert(anchors.partyFrame)
    assert(anchors.mainMenuBar[1] == 0 and anchors.mainMenuBar[2] == 16)
    assert(anchors.playerFrame[1] == (variant == "COMPACT" and -50 or -65))
    assert(anchors.chatFrame[1] == (variant == "ULTRAWIDE" and 24 or 0))
end
LibStub, ScarletUI.GetWoWVersion = originalLibStub, originalClient
ScarletUI.FindEditModeFrame = originalFindFrame

-- Profile installation must complete without calling the removed preference hook.
ScarletUI.InCombat = function() return false end
ScarletUI.Print = noop
ScarletUI.LoadEditModeLayouts = function() return true end
ScarletUI.DoesEditModeProfileExist = function() return false end
ScarletUI.ApplyEditModeLayout = function() return true end
ScarletUI:InstallEditModeProfile("STANDARD")
assert(ScarletUI.editModeLastError == nil)
assert(ScarletUI.db.global.editMode.installed["FOREVER:STANDARD"])

-- The move command uses Blizzard Edit Mode and preserves its combat guard.
local opened, message
ShowUIPanel = function(frame) opened = frame end
EditModeManagerFrame = {}
ScarletUI:SlashCommand("move")
assert(opened == EditModeManagerFrame)
opened = nil
ScarletUI.InCombat = function() return true end
ScarletUI:SlashCommand("move")
assert(opened == nil)
ScarletUI.InCombat = function() return false end
EditModeManagerFrame = nil
ScarletUI.Print = function(_, text) message = text end
ScarletUI:SlashCommand("move")
assert(message == "Blizzard Edit Mode is unavailable on this client.")

-- Chat tabs and font size still work without legacy position settings or frames.
dofile("Modules/Chat.lua")
CHAT_FRAMES, NUM_CHAT_WINDOWS = { "ChatFrame1" }, 1
ChatFrame1 = { name = "General", GetID = function() return 1 end }
FCF_OpenNewWindow = function(name)
    local id = #CHAT_FRAMES + 1
    local key = "ChatFrame" .. id
    _G[key] = { name = name, GetID = function() return id end }
    table.insert(CHAT_FRAMES, key)
end
GetChatWindowInfo = function(id) return _G[CHAT_FRAMES[id]].name end
FCF_SetChatWindowFontSize = function(_, frame, size) frame.fontSize = size end
ChatFrame_RemoveMessageGroup, ChatFrame_RemoveAllMessageGroups = noop, noop
ChatFrame_AddMessageGroup, ChatFrame_AddChannel = noop, noop
FCFDock_SelectWindow = noop
C_Timer = { NewTimer = function(_, callback) callback() end }
ScarletUI.lightWeightMode, ScarletUI.editMode = false, false
ScarletUI:SetupChat()
assert(#CHAT_FRAMES == 4)
for _, key in ipairs(CHAT_FRAMES) do
    assert(_G[key].fontSize == ScarletUI.db.global.chatModule.fontSize)
end
print("PASS: remaining settings, setup dispatcher, shared Era presets, and Edit Mode installation")

-- Run last: the prompt regression loads real AceDB in its own addon setup.
dofile("tests/edit-mode-prompts.lua")

dofile("tests/cvars.lua")
