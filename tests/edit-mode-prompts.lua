-- Run from the addon root: lua tests/edit-mode-prompts.lua
local function noop() end
CreateFrame = function()
    return { RegisterEvent = noop, SetScript = function(self, _, fn) self.onEvent = fn end }
end
GetRealmName = function() return "Test Realm" end
UnitName = function() return "Test Character" end
UnitClass = function() return "Warrior", "WARRIOR" end
UnitRace = function() return "Human", "Human" end
UnitFactionGroup = function() return "Alliance" end
GetLocale = function() return "enUS" end
GetCurrentRegion = function() return 1 end
securecallfunction = function(fn, ...) return fn(...) end
LibStub = nil
dofile("Libs/LibStub/LibStub.lua")
dofile("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("Libs/AceDB-3.0/AceDB-3.0.lua")
LibStub:NewLibrary("AceConfigRegistry-3.0", 1).NotifyChange = noop
ScarletUI, StaticPopupDialogs = {}, {}
dofile("Modules/Database.lua")
dofile("Modules/EditModeLayouts.lua")
dofile("Modules/EditMode.lua")
local AceDB = LibStub("AceDB-3.0")
local saved = {}
ScarletUI.db = AceDB:New(saved, ScarletUI.defaults, true)
ScarletUI.editModeReady = true
local variant, exists, prompts, popupData = "STANDARD", true, 0
ScarletUI.GetWoWVersion = function() return "FOREVER" end
ScarletUI.GetEditModeVariant = function() return variant end
ScarletUI.DoesEditModeProfileExist = function() return exists end
ScarletUI.GetActiveEditModeProfile = function() return "My Custom Profile" end
StaticPopup_Show = function(name, _, _, data)
    assert(name == "SCARLET_EDIT_MODE_SWITCH")
    prompts, popupData = prompts + 1, data
end
C_Timer = { After = function(_, fn) fn() end }
ScarletUI:EvaluateEditModeProfilePrompt()
assert(prompts == 1)
local cancel = StaticPopupDialogs.SCARLET_EDIT_MODE_SWITCH.OnCancel
cancel(nil, popupData, "override")
assert(not ScarletUI.db.global.editMode.suppressPrompts, "Popup replacement is not a user opt-out")
cancel(nil, popupData, "clicked")
assert(ScarletUI.db.global.editMode.suppressPrompts, "Keep Current must save the account opt-out")

-- Exercise AceDB's actual logout cleanup and reload, including another character.
AceDB.frame.onEvent(AceDB.frame, "PLAYER_LOGOUT")
assert(saved.global.editMode.suppressPrompts)
ScarletUI.db = AceDB:New(saved, ScarletUI.defaults, true)
ScarletUI.db.char = { editMode = { activationPromptedVersions = {}, declinedVersions = {} } }
ScarletUI.editModeLayoutSchemaVersion = ScarletUI.editModeLayoutSchemaVersion + 1
for _, display in ipairs({ "STANDARD", "COMPACT", "ULTRAWIDE" }) do
    variant = display
    for _, installed in ipairs({ true, false }) do
        exists = installed
        ScarletUI:EvaluateEditModeProfilePrompt()
        ScarletUI:HandleEditModeDisplayChanged()
    end
end
assert(prompts == 1, "No automatic Edit Mode popup is allowed after Keep Current")

-- Opting out must not disable manual switching from the settings page.
local library = LibStub:NewLibrary("LibEditModeOverride-1.0", 1)
local activated
library.SetActiveLayout = function(_, name) activated = name end
library.ApplyChanges = noop
ScarletUI.InCombat = function() return false end
ScarletUI.LoadEditModeLayouts = function() return true end
ScarletUI.Print = noop
exists, variant = true, "STANDARD"
ScarletUI:SwitchEditModeProfile()
assert(activated == "ScarletUI - Standard")
assert(ScarletUI.db.global.editMode.suppressPrompts)
-- Exercise the actual addon initializer with a restored SavedVariables table.
LibStub:NewLibrary("AceAddon-3.0", 1).NewAddon = function()
    return { RegisterChatCommand = noop }
end
LibStub:NewLibrary("AceConfig-3.0", 1).RegisterOptionsTable = noop
local dialog = LibStub:NewLibrary("AceConfigDialog-3.0", 1)
dialog.SetDefaultSize, dialog.AddToBlizOptions = noop, noop
C_AddOns = { IsAddOnLoaded = function() return false end }
ScarletUIDB = saved
dofile("ScarletUI.lua")
dofile("Modules/Database.lua")
ScarletUI:OnInitialize()
assert(ScarletUI.db.sv == saved)
assert(ScarletUI.db.global.editMode.suppressPrompts, "Startup must retain the restored opt-out")
print("PASS: Keep Current persists through AceDB logout/reload, suppresses all automatic prompts, and allows manual switching")
