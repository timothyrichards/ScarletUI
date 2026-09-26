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
local setupMethods = { "SetupDebugFrame", "SetupActionBarToggles", "SetupTracking", "SetupChat", "SetupCVars",
    "SetupItemLevels",
    "SetupTidyIcons", "SetupSpellCostPercent", "SetupExpandCharacterInfo" }
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
        ReanchorFrame = function(_, frame, point, relativeTo, _, x, y) anchors[frame] = { x, y, point, relativeTo } end,
        SetFrameSetting = noop,
    }
end
ScarletUI.GetWoWVersion = function() return "VANILLA", 11509 end
ScarletUI.FindEditModeFrame = function(_, key) return key end
for _, variant in ipairs({ "STANDARD", "COMPACT", "ULTRAWIDE" }) do
    anchors = {}
    assert(ScarletUI:ApplyEditModeLayout(variant))
    assert(#ScarletUI.editModeSkippedSystems == 0)
    assert(anchors.raidFrame[1] == 154.6 and anchors.raidFrame[2] == -210)
    assert(anchors.partyFrame[3] == (variant == "COMPACT" and "BOTTOMLEFT" or "TOPLEFT"))
    assert(anchors.mainMenuBar[1] == 0 and anchors.mainMenuBar[2] == 41.9)
    assert(anchors.multiBarBottomLeft[4] == "mainMenuBar")
    assert(anchors.stanceBar[4] == "multiBarBottomRight")
    if variant == "COMPACT" then
        assert(anchors.focusFrame[4] == UIParent)
    else
        assert(anchors.focusFrame[4] == "playerFrame")
    end
    assert(anchors.playerFrame[1] == (variant == "COMPACT" and -50 or -65))
    assert(anchors.chatFrame[1] == (variant == "ULTRAWIDE" and 24 or 33))
end

-- A snapped frame whose anchor frame is missing is skipped, not moved to UIParent.
anchors = {}
ScarletUI.FindEditModeFrame = function(_, key) return key ~= "mainMenuBar" and key or nil end
assert(ScarletUI:ApplyEditModeLayout("STANDARD"))
assert(anchors.multiBarBottomLeft == nil)
assert(anchors.multiBarBottomRight)
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

-- Action bar toggles: a first character seeds them on logout, an alt receives them on login.
dofile("Modules/ActionBars.lua")
local bars = { true, false, false, false, false, false, false }
local updated = false
GetActionBarToggles = function() return unpack(bars) end
SetActionBarToggles = function(...) bars = { ... } end
MultiActionBar_Update = function() updated = true end
local originalHandlers, originalFrame = ScarletUI.eventHandlers, ScarletUI.frame
ScarletUI.eventHandlers = {}
ScarletUI.frame = { RegisterEvent = noop }
local shutdown = {}
ScarletUI.db.RegisterCallback = function(target, event, handler)
    if event == "OnDatabaseShutdown" then shutdown[target] = handler end
end
local function Fire(event)
    if event == "PLAYER_LOGOUT" then
        for _, handler in pairs(shutdown) do handler() end
    end
    for _, handler in ipairs(ScarletUI.eventHandlers[event] or {}) do handler(event) end
end
ScarletUI:SetupActionBarToggles()
assert(not updated)
bars[2], bars[3] = true, true
Fire("PLAYER_LOGOUT")
assert(ScarletUI.db.global.actionBarToggles.bars[3] == true)
bars, ScarletUI.actionBarTogglesApplied = { false, false, false, false, false, false, false }, nil
ScarletUI.InCombat = function() return true end
ScarletUI:SetupActionBarToggles()
assert(not bars[2] and not updated)
ScarletUI.InCombat = function() return false end
Fire("PLAYER_REGEN_ENABLED")
assert(bars[1] and bars[2] and bars[3] and not bars[4] and updated)

-- Minimap tracking: merged by name; alts only receive entries they have.
local tracking = { { name = "Mailbox", active = true }, { name = "Find Herbs", active = true } }
C_Minimap = {
    GetNumTrackingTypes = function() return #tracking end,
    GetTrackingInfo = function(i) return tracking[i] end,
    SetTracking = function(i, on) tracking[i].active = on end,
}
dofile("Modules/Tracking.lua")
ScarletUI:SetupTracking()
tracking[1].active = false
Fire("PLAYER_LOGOUT")
local states = ScarletUI.db.global.trackingModule.states
assert(states.Mailbox == false and states["Find Herbs"] == true)
tracking, ScarletUI.trackingApplied = { { name = "Mailbox", active = true }, { name = "Stable Master", active = false } }, nil
ScarletUI:SetupTracking()
assert(tracking[1].active == false and tracking[2].active == false)
Fire("PLAYER_LOGOUT")
assert(states["Find Herbs"] == true and states["Stable Master"] == false)
assert(#shutdown == 0 and shutdown["ScarletUI-ActionBars"] and shutdown["ScarletUI-Tracking"])
ScarletUI.eventHandlers, ScarletUI.frame = originalHandlers, originalFrame

-- Spell tooltip mana percent: once, on the cost line only, with per-mana beneath it.
local function Line(text)
    return { GetText = function() return text end, SetText = function(_, t) text = t end,
        IsShown = function() return true end }
end
GameTooltipTextLeft1, GameTooltipTextLeft2, GameTooltipTextLeft3 = Line("Renew"), Line("105 Mana"),
    Line("Heals the target of 206 damage over 15 sec.")
GameTooltipTextRight2 = Line("40 yd range")
local postCalls, SECRET = {}, {}
local description = "Heals the target of 206 damage over 15 sec."
GameTooltip = { NumLines = function() return 3 end, IsForbidden = function() return false end }
Enum.TooltipDataType = { Spell = 1, Macro = 2 }
TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) postCalls[kind] = fn end }
C_Spell = { GetSpellPowerCost = function() return { { type = 0, cost = 105 } } end,
    GetSpellDescription = function() return description end }
UnitPowerMax, MANA, GetLocale = function() return 1300 end, "Mana", function() return "enUS" end
issecretvalue = function(v) return v == SECRET end
dofile("Modules/Tooltips.lua")
issecretvalue = nil
ScarletUI:SetupSpellCostPercent()
local function PerMana() return GameTooltipTextLeft2:GetText():match("\n|cff40a0ff(.-)|r$") or false end
local costText = "105 |cff40a0ffMana|r (8%)\n|cff40a0ff1.96 healing per mana|r"
postCalls[1](GameTooltip, { id = 139 })
postCalls[1](GameTooltip, { id = 139 })
assert(GameTooltipTextLeft2:GetText() == costText)
assert(GameTooltipTextRight2:GetText() == "40 yd range\n ")
assert(GameTooltipTextLeft3:GetText() == "Heals the target of 206 damage over 15 sec.")
GameTooltipTextLeft2 = Line("105 Mana")
postCalls[2](GameTooltip, { lines = { { tooltipID = 139 } } })
assert(GameTooltipTextLeft2:GetText() == costText)
-- Secret tooltip (spell on cooldown): left untouched.
GameTooltipTextLeft2, GameTooltipTextRight2 = Line(SECRET), Line(SECRET)
postCalls[1](GameTooltip, { id = 139 })
assert(GameTooltipTextLeft2:GetText() == SECRET and GameTooltipTextRight2:GetText() == SECRET)
-- Per mana: range average plus heal over time, or absorb; damage adds nothing.
for text, expected in pairs({
    ["Heals a friendly target for 93 to 107 and another 98 over 21 sec."] = "1.89 healing per mana",
    ["Heals a friendly target for 1,193 to 1,237."] = "11.57 healing per mana",
    ["Blasts the target for 50 to 60 Shadow damage."] = false,
    ["Draws on the soul of the party member to shield them, absorbing 48 damage. Lasts 30 sec."]
        = "0.46 absorb per mana",
    ["Shields an ally for 15 sec, absorbing 12,345 damage."] = "117.57 absorb per mana",
}) do
    description, GameTooltipTextLeft2 = text, Line("105 Mana")
    postCalls[1](GameTooltip, { id = 139 })
    assert(PerMana() == expected, text)
end
print("PASS: remaining settings, setup dispatcher, shared Era presets, and Edit Mode installation")

-- Run last: the prompt regression loads real AceDB in its own addon setup.
dofile("tests/edit-mode-prompts.lua")

dofile("tests/cvars.lua")
