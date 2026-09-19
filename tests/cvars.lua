-- Run from the addon root: lua tests/cvars.lua
local function noop() end
ScarletUI = {}
LibStub = function() return { NotifyChange = noop } end
C_AddOns = { IsAddOnLoaded = function() return false end }
dofile("Modules/Database.lua")
dofile("Modules/Helpers.lua")
dofile("Modules/CVars.lua")
ScarletUI.InCombat = function() return false end
ScarletUI.ShowReloadDialog = function() error("Raid CVars should not request a reload") end
ScarletUI.db = { global = ScarletUI.defaults.global, char = ScarletUI.defaults.char }
local expected = {
    damageMeterEnabled = "1",
    enableMouseoverCast = "1",
    raidFramesDisplayClassColor = "1",
    raidFramesDisplayPowerBars = "1",
    raidFramesDisplayDebuffs = "1",
    raidFramesDisplayOnlyDispellableDebuffs = "1",
    raidFramesHealthText = "perc",
    raidOptionDisplayMainTankAndAssist = "0",
}
local values, writes = {}, {}
for name, value in pairs(expected) do
    assert(ScarletUI:ArrayHasValue(ScarletUI.knownCVars, name), name)
    assert(ScarletUI.defaults.global.CVarModule.overrides[name] == value, name)
    assert(ScarletUI.originalUIDefaults.global.CVarModule.overrides[name] == value, name)
    values[name] = value == "0" and "1" or "0"
end
-- Preserve native pet/party settings instead of choosing between old raid profiles.
assert(ScarletUI.defaults.global.CVarModule.overrides.raidOptionDisplayPets == nil)
values.raidOptionDisplayPets, values.useCompactPartyFrames = "1", "1"
GetCVar = function(name) return values[name] end
GetCVarDefault = function() return "0" end
SetCVar = function(name, value)
    assert(values[name] ~= nil, "Unsupported CVar: " .. name)
    values[name], writes[name] = tostring(value), value
end
ScarletUI:SetupCVars()
for name, value in pairs(expected) do assert(values[name] == value, name) end
assert(ScarletUI.db.global.CVarModule.overrides.raidOptionDisplayPets == "1")
assert(ScarletUI.db.global.CVarModule.overrides.useCompactPartyFrames == "1")

-- Explicit overrides still win; clients without these CVars are skipped.
ScarletUI.db.global.CVarModule.overrides.raidFramesDisplayPowerBars = "0"
ScarletUI:SetupCVars()
assert(values.raidFramesDisplayPowerBars == "0")
values, writes = {}, {}
ScarletUI:SetupCVars()
assert(next(writes) == nil)
ScarletUI.db.global.CVarModule.enabled = false
GetCVar = function() return nil end
ScarletUI:SetupCVars()
print("PASS: raid display CVars, new CVar defaults, native pet/party settings, explicit overrides, and unsupported clients")

-- Exercise real AceDB persistence and the settings callbacks.
CreateFrame = function()
    return { RegisterEvent = noop, SetScript = function(self, _, fn) self.onEvent = fn end }
end
GetRealmName = function() return "Test Realm" end
local character = "First"
UnitName = function() return character end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitRace = function() return "Human", "Human" end
UnitFactionGroup = function() return "Alliance" end
GetLocale = function() return "enUS" end
GetCurrentRegion = function() return 1 end
securecallfunction = function(fn, ...) return fn(...) end
local saved, AceDB = {}, nil
local function login()
    LibStub = nil
    dofile("Libs/LibStub/LibStub.lua")
    dofile("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
    dofile("Libs/AceDB-3.0/AceDB-3.0.lua")
    LibStub:NewLibrary("AceConfigRegistry-3.0", 1).NotifyChange = noop
    dofile("Modules/Database.lua")
    dofile("Modules/Options.lua")
    AceDB = LibStub("AceDB-3.0")
    ScarletUI.db = AceDB:New(saved, ScarletUI.defaults, true)
end
local function clone(source)
    local result = {}
    for k, v in pairs(source) do result[k] = type(v) == "table" and clone(v) or v end
    return result
end
local function logout()
    AceDB.frame.onEvent(AceDB.frame, "PLAYER_LOGOUT")
    saved = clone(saved) -- SavedVariables contain values, not AceDB metatables.
end
local combat, omniCC, failWrite, reloads = false, false, false, 0
ScarletUI.Print = noop
ScarletUI.InCombat = function() return combat end
ScarletUI.ShowReloadDialog = function() reloads = reloads + 1 end
C_AddOns.IsAddOnLoaded = function() return omniCC end
-- The module's cached addon check uses this table function from its load time.
dofile("Modules/CVars.lua")
values = { damageMeterEnabled = "0", custom = "7", customDefault = "0", countdownForCooldowns = "1", XpBarText = "0", shared = "4" }
GetCVar = function(name) return values[name] end
C_CVar = { GetCVarInfo = function(name) return values[name], "0", name == "shared", name ~= "shared" end }
GetCVarDefault = function(name) if values[name] ~= nil then return "0" end end
SetCVar = function(name, value)
    if failWrite then error("Test write failure") end
    assert(ScarletUI.db.char.cvarOriginalValues[name] ~= nil or ScarletUI.db.global.CVarModule.originalValues[name] ~= nil, "Write without backup: " .. name)
    values[name] = tostring(value)
end
login()
ScarletUI:SetupCVars()
assert(values.damageMeterEnabled == "1")
assert(ScarletUI.db.char.cvarOriginalValues.damageMeterEnabled == "0")

local function page() return ScarletUI:GetCVarModuleSettingsPage(ScarletUI.db.global, 1) end
local function controls(name)
    local args = page().args.search.args
    for key, option in pairs(args) do
        if key:match("^label") and (option.name == name or option.name == "|cff00ff00" .. name .. "|r") then
            local index = key:match("%d+")
            return args["input" .. index], args["clear" .. index], args["remove" .. index]
        end
    end
    error("Missing CVar control: " .. name)
end
local function toggle(enabled)
    ScarletUI:GetGeneralSettingsPage(ScarletUI.db.global, 1).args.modules.args.cVarModuleEnabled.set(nil, enabled)
end
page().args.addCustom.args.addField.set(nil, "custom")
page().args.addCustom.args.addField.set(nil, "customDefault")
assert(ScarletUI.db.char.cvarOriginalValues.custom == "7")
assert(ScarletUI.db.char.cvarOriginalValues.customDefault == "0")
controls("custom").set(nil, "9")
controls("custom").set(nil, "11")
logout()
login()
ScarletUI:SetupCVars()
assert(values.custom == "11" and ScarletUI.db.char.cvarOriginalValues.custom == "7")
assert(ScarletUI.db.char.cvarOriginalValues.customDefault == "0")
assert(controls("customDefault"))
local input, default, remove = controls("custom")
default.func()
assert(values.custom == "0" and ScarletUI.db.char.cvarOriginalValues.custom == "7")
input.set(nil, "")
assert(values.custom == "7" and ScarletUI.db.global.CVarModule.overrides.custom == false)
controls("damageMeterEnabled").set(nil, "")
logout()
login()
ScarletUI:SetupCVars()
assert(values.damageMeterEnabled == "0" and ScarletUI.db.global.CVarModule.overrides.damageMeterEnabled == false)
assert(values.custom == "7" and ScarletUI.db.global.CVarModule.overrides.custom == false)

input, default, remove = controls("custom")
input.set(nil, "12")
remove.func()
assert(values.custom == "7" and ScarletUI.db.global.CVarModule.hiddenCVars.custom)
page().args.addCustom.args.addField.set(nil, "custom")
controls("custom").set(nil, "13")
combat = true
toggle(false)
controls("custom").set(nil, "")
assert(ScarletUI.db.global.CVarModule.enabled and values.custom == "13")
combat = false
failWrite = true
toggle(false)
assert(ScarletUI.db.char.cvarOriginalValues.custom == "7")
failWrite = false
ScarletUI:SetupCVars()
assert(values.custom == "7" and ScarletUI.db.char.cvarOriginalValues.custom == nil)
assert(ScarletUI.db.global.CVarModule.overrides.custom == "13")
values.custom = "8"
ScarletUI:SetupCVars()
assert(values.custom == "8", "Disabled module must not keep restoring")
toggle(true)
assert(values.custom == "13" and ScarletUI.db.char.cvarOriginalValues.custom == "8")

omniCC = true
ScarletUI.db.global.CVarModule.overrides.countdownForCooldowns = "1"
ScarletUI:SetupCVars()
assert(values.countdownForCooldowns == "0")
assert(ScarletUI.db.char.cvarOriginalValues.countdownForCooldowns == "1")
controls("XpBarText").set(nil, "1")
assert(reloads == 1)
toggle(false)
assert(values.countdownForCooldowns == "1" and values.XpBarText == "0" and reloads == 2)
omniCC = false

toggle(true)
page().args.addCustom.args.addField.set(nil, "shared")
controls("shared").set(nil, "6")
assert(ScarletUI.db.global.CVarModule.originalValues.shared == "4")

-- A global disable restores each character's backup when that character logs in.
toggle(true)
logout()
character, values.custom = "Second", "20"
login()
ScarletUI:SetupCVars()
assert(ScarletUI.db.char.cvarOriginalValues.custom == "20")
assert(ScarletUI.db.global.CVarModule.originalValues.shared == "4")
assert(ScarletUI.db.char.cvarOriginalValues.shared == nil)
toggle(false)
assert(values.custom == "20" and values.shared == "4")
logout()
character, values.custom = "First", "13"
login()
ScarletUI:SetupCVars()
assert(values.custom == "8")

-- Resetting preferences must retain every character's existing backup.
toggle(true)
saved.char["Offline - Test Realm"] = { cvarOriginalValues = { custom = "30" } }
ScarletUI.Setup = ScarletUI.SetupCVars
ScarletUI:ResetDefaults()
assert(values.custom == "8", "Reset must restore custom CVars removed from preferences")
assert(saved.char["Offline - Test Realm"].cvarOriginalValues.custom == "30")
assert(values.damageMeterEnabled == "1")
toggle(false)
assert(values.damageMeterEnabled == "0")
print("PASS: CVar snapshots, settings actions, real AceDB reloads, disable/re-enable, failures, combat, OmniCC, character backups, and reset")
