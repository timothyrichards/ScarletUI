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
for _, name in ipairs({ "Database", "Helpers", "Movers", "Options", "EditModeLayouts", "EditMode" }) do
    dofile("Modules/" .. name .. ".lua")
end
ScarletUI.db = {
    global = ScarletUI.defaults.global,
    char = ScarletUI.defaults.char,
    defaults = ScarletUI.defaults,
}
ScarletUI.knownCVars = {}
assert(ScarletUI.defaults.global.actionbarsModule == nil)
assert(ScarletUI.originalUIDefaults.global.actionbarsModule == nil)
assert(ScarletUI.SetupActionBars == nil and ScarletUI.SetupActionBarPreferences == nil)
assert(ScarletUI.defaults.global.bagModule == nil and ScarletUI.originalUIDefaults.global.bagModule == nil)
assert(ScarletUI.SetupBags == nil and ScarletUI.SetupBank == nil)

-- Both fresh settings and saved settings from before removal must load.
for _, oldSettings in ipairs({ false, true }) do
    ScarletUI.db.global.actionbarsModule = oldSettings and { enabled = true } or nil
    ScarletUI.db.global.bagModule = oldSettings and { enabled = true } or nil
    local options = ScarletUI:Options()
    assert(options.args.actionBarSettings == nil)
    assert(options.args.generalSettings.args.modules.args.actionbarsModuleEnabled == nil)
    assert(options.args.bagModuleSettings == nil and options.args.editModeSettings)
    assert(options.args.generalSettings.args.modules.args.bagModuleEnabled == nil)
    local configs = ScarletUI:GenerateAllMoversConfigs()
    local remaining = { castBar = true, chatFrame = true, focusFrame = true, playerFrame = true, targetFrame = true }
    for name in pairs(configs) do
        assert(remaining[name], "Unexpected mover: " .. name)
        remaining[name] = nil
    end
    assert(next(remaining) == nil, "A remaining mover was lost")
end

-- Exercise the real setup dispatcher with only the remaining module methods.
local calls = {}
local setupMethods = { "SetupDebugFrame", "CreateMoverGrid", "SetupChat", "SetupCVars",
    "SetupItemLevels", "SetupUnitFrames", "SetupRaidProfiles",
    "SetupTidyIcons", "SetupNameplates", "SetupExpandCharacterInfo" }
for _, name in ipairs(setupMethods) do
    ScarletUI[name] = function() calls[name] = true end
end
for _, editMode in ipairs({ false, true }) do
    calls = {}
    ScarletUI.editMode = editMode
    ScarletUI:Setup()
    for _, name in ipairs(setupMethods) do
        assert(not not calls[name] == (name ~= "CreateMoverGrid" or not editMode), name)
    end
end

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
print("PASS: remaining settings, movers, setup dispatcher, shared Era presets, and Edit Mode installation")
