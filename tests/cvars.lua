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
ScarletUI.db = { global = ScarletUI.defaults.global }
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
GetCVar = function() error("Disabled module must not read or write CVars") end
ScarletUI:SetupCVars()
print("PASS: raid display CVars, new CVar defaults, native pet/party settings, explicit overrides, and unsupported clients")
