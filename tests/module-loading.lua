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
-- Playtime: the /played total is saved per character and topped up at logout.
do
    local oldTime, oldClass, now = time, UnitClass, 1000
    time = function() return now end
    UnitClass = function() return "Paladin", "PALADIN" end
    ScarletUI.db.keys = { char = "Scarlet Bubbles" }
    -- The first version's "Name-Realm" table is dropped on Forever, where the
    -- names collide, and moved to AceDB's "Name - Realm" keys elsewhere.
    ScarletUI.db.global.played = { ["Scarlet-Realm"] = 1 }
    RegionalUniqueNamesEnabled = function() return true end
    local function Fire(event, ...)
        for _, handler in ipairs(ScarletUI.eventHandlers[event]) do handler(event, ...) end
    end
    Fire("PLAYER_LOGOUT") -- nothing received yet: nothing saved
    assert(ScarletUI.db.global.playtime == nil)
    Fire("TIME_PLAYED_MSG", 5000, 20)
    assert(ScarletUI.db.global.playtime["Scarlet Bubbles"] == 5000 and ScarletUI.db.global.played == nil)
    now = 1600
    Fire("PLAYER_LOGOUT")
    assert(ScarletUI.db.global.playtime["Scarlet Bubbles"] == 5600)
    assert(ScarletUI.db.global.playtime["Scarlet - Realm"] == nil)
    RegionalUniqueNamesEnabled = nil
    ScarletUI.db.keys.char = "Tester - Azjol-Nerub"
    ScarletUI.db.global.played = { ["Other-Azjol-Nerub"] = 7, ["Tester-Azjol-Nerub"] = 8 }
    Fire("TIME_PLAYED_MSG", 9000, 20)
    assert(ScarletUI.db.global.playtime["Other - Azjol-Nerub"] == 7 and ScarletUI.db.global.played == nil)
    assert(ScarletUI.db.global.playtime["Tester - Azjol-Nerub"] == 9000)
    -- The class is saved beside the total, only for characters that logged in.
    assert(ScarletUI.db.global.playtimeClasses["Tester - Azjol-Nerub"] == "PALADIN")
    assert(ScarletUI.db.global.playtimeClasses["Other - Azjol-Nerub"] == nil)
    ScarletUI.db.global.playtime, ScarletUI.db.global.playtimeClasses = nil, nil
    ScarletUI.db.keys, time, UnitClass = nil, oldTime, oldClass
end
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
    assert(options.args.generalSettings.args.modules == nil and options.args.defaultSettings == nil)
    -- Retail and Forever get a Bags page with only the sorting switch, sorting, and highlight settings.
    local bagPage = options.args.bagModuleSettings
    local bagGroups = 0
    for _ in pairs(bagPage.args) do bagGroups = bagGroups + 1 end
    assert(bagPage.name == "Bags" and bagPage.args.sortSettings and bagPage.args.highlightSettings and bagGroups == 3)
    assert(options.args.editModeSettings and options.args.actionBarTogglesSettings)
    -- Retail never loads Bag.lua or Nameplates.lua, and Forever never loads Bag.lua, so these toggles do not exist.
    assert(bagPage.args.enabled == nil and bagPage.args.shareSorting.order < bagPage.args.sortSettings.order)
    assert(options.args.toggleMovers == nil and options.args.resetPositions == nil)
    assert(options.args.generalSettings.args.interface.args.clampMovers == nil)
    assert(options.args.raidFramesModuleSettings == nil)
    assert(options.args.nameplatesModuleSettings == nil)
    -- Each feature is switched on its own page.
    assert(options.args.actionBarTogglesSettings.args.enabled and options.args.chatModuleSettings.args.enabled)
    assert(options.args.CVarModuleSettings.args.enabled and options.args.generalSettings.args.tracking.args.enabled)
end

-- Exercise the real setup dispatcher with only the remaining module methods.
local calls = {}
local setupMethods = { "SetupDebugFrame", "SetupActionBarToggles", "SetupBagSort", "SetupBankCache", "SetupTracking", "SetupChat", "SetupCVars",
    "SetupItemLevels",
    "SetupTidyIcons", "SetupSpellCostPercent", "SetupZoneLevels", "SetupFiveSecondRule", "SetupQuestXPBar", "SetupXPPerHour", "SetupFishing", "SetupXPFood", "SetupWeaponReminder", "SetupCampReminders","SetupSpecGearSets", "SetupStatDisplay", "SetupSealSlots", "SetupWindfury", "SetupCraftProfit", "SetupExpandCharacterInfo", "SetupGameMenuButtons",
    "SetupFrameTweaks", "SetupMinimapIcon" }
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
    if variant == "COMPACT" then
        assert(anchors.raidFrame[1] == 196.6 and anchors.raidFrame[2] == -174)
    else
        assert(anchors.raidFrame[1] == 264.7 and anchors.raidFrame[2] == -268)
        assert(anchors.partyFrame[1] == 614.7 and anchors.partyFrame[2] == -472)
    end
    assert(anchors.swingTimerOffHand[4] == "swingTimerMainHand" and anchors.totemBar[4] == "multiBarBottomRight")
    assert(anchors.utilityCooldowns[3] == "BOTTOM" and anchors.utilityCooldowns[4] == "essentialCooldowns")
    assert(anchors.castBar[3] == "BOTTOM" and anchors.castBar[4] == "utilityCooldowns" and anchors.castBar[2] == 18)
    assert(anchors.essentialCooldowns[1] == 0 and anchors.essentialCooldowns[3] == "TOP")
    assert(anchors.swingTimerMainHand[2] == 221.6 and anchors.swingTimerMainHand[3] == "BOTTOM")
    assert(anchors.swingTimerRanged[4] == "swingTimerMainHand" and anchors.swingTimerRanged[2] == -3.2)
    assert(anchors.partyFrame[3] == (variant == "COMPACT" and "BOTTOMLEFT" or "TOPLEFT"))
    assert(anchors.mainMenuBar[1] == 0 and anchors.mainMenuBar[2] == 22)
    assert(anchors.multiBarBottomLeft[4] == "mainMenuBar")
    assert(anchors.stanceBar[4] == "multiBarBottomRight")
    if variant == "COMPACT" then
        assert(anchors.focusFrame[4] == UIParent)
    else
        assert(anchors.focusFrame[4] == "multiBarBottomRight")
        assert(anchors.petFrame[4] == "multiBarBottomRight")
    end
    assert(anchors.playerFrame[1] == (variant == "COMPACT" and -50 or -248))
    assert(anchors.playerFrame[3] == (variant == "COMPACT" and "TOPRIGHT" or "BOTTOM"))
    assert(anchors.chatFrame[1] == (variant == "ULTRAWIDE" and 24 or 33))
end

-- A snapped frame whose anchor frame is missing is skipped, not moved to UIParent.
anchors = {}
ScarletUI.FindEditModeFrame = function(_, key) return key ~= "mainMenuBar" and key or nil end
assert(ScarletUI:ApplyEditModeLayout("STANDARD"))
assert(anchors.multiBarBottomLeft == nil)
assert(anchors.multiBarBottomRight)

-- Unless it has a fallback: without the Cooldown Manager the cast bar anchors to the screen.
anchors = {}
ScarletUI.FindEditModeFrame = function(_, key) return not key:find("Cooldowns") and key or nil end
assert(ScarletUI:ApplyEditModeLayout("STANDARD"))
assert(anchors.castBar[4] == UIParent and anchors.castBar[2] == 327)
assert(anchors.utilityCooldowns == nil)

-- The gryphon end caps are child frames, found by dotted name, hidden and left in place.
local leftEndCap, hidden = {}, {}
MainActionBar = { EndCaps = { LeftEndCap = leftEndCap } }
Enum.EditModeMainActionBarEndCapSetting = { Hidden = 0 }
LibStub = function()
    return {
        HasEditModeSettings = function(_, frame) return frame == leftEndCap end,
        ReanchorFrame = function(_, frame) anchors[frame] = true end,
        SetFrameSetting = function(_, frame, setting, value) hidden[frame] = setting == 0 and value end,
    }
end
ScarletUI.FindEditModeFrame = originalFindFrame
anchors = {}
assert(ScarletUI:ApplyEditModeLayout("STANDARD"))
assert(hidden[leftEndCap] == 1 and anchors[leftEndCap] == nil)
assert(ScarletUI:FindEditModeFrame("endCapRight") == nil)
MainActionBar, Enum.EditModeMainActionBarEndCapSetting = nil, nil
LibStub, ScarletUI.GetWoWVersion = originalLibStub, originalClient

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
local dockSelections = 0
FCFDock_SelectWindow = function() dockSelections = dockSelections + 1 end
C_Timer = { NewTimer = function(_, callback) callback() end }
ScarletUI.lightWeightMode, ScarletUI.editMode = false, false
ScarletUI:SetupChat()
assert(#CHAT_FRAMES == 4)
for _, key in ipairs(CHAT_FRAMES) do
    assert(_G[key].fontSize == ScarletUI.db.global.chatModule.fontSize)
end
-- Reruns with every tab present leave the dock selection alone (it taints chat).
assert(dockSelections == 1)
ScarletUI:SetupChat()
assert(dockSelections == 1)

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
-- Unchecked bars keep each character's own state and leave the shared state alone.
local barModule = ScarletUI.db.global.actionBarToggles
local barOptions = ScarletUI:Options().args.actionBarTogglesSettings.args.bars.args
assert(barOptions.bar1.name == "Action Bar 2" and barOptions.bar7 and not barOptions.bar8)
barOptions.bar2.set(nil, false)
assert(barModule.ignored[2] == true and not barOptions.bar2.get())
bars, ScarletUI.actionBarTogglesApplied = { false, false, false, false, false, false, false }, nil
ScarletUI:SetupActionBarToggles()
assert(bars[1] and not bars[2] and bars[3])
bars[4] = true
Fire("PLAYER_LOGOUT")
assert(barModule.bars[2] == true and barModule.bars[4] == true)
barOptions.bar2.set(nil, true)
assert(barModule.ignored[2] == nil)

-- Minimap tracking: merged by name; alts only receive entries they have.
local tracking = { { name = "Mailbox", active = true }, { name = "Find Herbs", active = true } }
local dead = false
UnitIsDeadOrGhost = function() return dead end
C_Minimap = {
    GetNumTrackingTypes = function() return #tracking end,
    GetTrackingInfo = function(i) return tracking[i] end,
    SetTracking = function(i, on) tracking[i].active = on end,
}
C_Timer.NewTicker = function() end
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

-- Always-on tracking: re-enabled at login and resurrection, skipped while dead.
dead = true
local now, resting, cooldown = 100, false, 0
GetTime = function() return now end
GetSpellCooldown = function() return 0, cooldown end
GetSpellInfo = function(id) return ({ [2580] = "Find Minerals", [2383] = "Find Herbs" })[id] end
tracking = { { name = "Find Minerals", active = false }, { name = "Find Herbs", active = false } }
ScarletUI.db.global.trackingModule.alwaysOn[2580] = true
Fire("PLAYER_ALIVE")
assert(tracking[1].active == false, "tracking was enabled while dead")
dead = false
Fire("PLAYER_UNGHOST")
assert(tracking[1].active == true and tracking[2].active == false)
-- Knowing both: the timer swaps to the inactive one, as Classic tracks one at a time.
now = now + 3
IsInInstance = function() return false end
IsResting = function() return resting end
UnitOnTaxi = function() return false end
SpellIsTargeting = function() return false end
GetCursorInfo = function() end
GetNumLootItems = function() return 0 end
Minimap = { IsMouseOver = function() return false end }
C_Minimap.SetTracking = function(i, on)
    for _, entry in ipairs(tracking) do entry.active = false end
    tracking[i].active = on
end
ScarletUI.db.global.trackingModule.alwaysOn[2383] = true
ScarletUI:SwitchTracking()
assert(tracking[2].active and not tracking[1].active, "did not swap to herbs")
ScarletUI:SwitchTracking()
assert(tracking[2].active, "swapped again before the interval passed")
now, resting = now + 3, true
ScarletUI:SwitchTracking()
assert(tracking[2].active, "swapped while resting")
resting, cooldown = false, 1.5
ScarletUI:SwitchTracking()
assert(tracking[2].active, "swapped during the global cooldown")
cooldown = 0
ScarletUI:SwitchTracking()
assert(tracking[1].active and not tracking[2].active, "did not swap back to minerals")
-- With only one known, the timer leaves a hand-picked tracking type alone.
now = now + 3
tracking = { { name = "Find Minerals", active = false }, { name = "Track Beasts", active = true } }
ScarletUI:SwitchTracking()
assert(tracking[2].active and not tracking[1].active, "timer overrode a single tracker")
-- Forever: cooldown numbers are secret (comparing one errors); isActive is read instead.
local savedSpell, onCooldown = C_Spell, true
C_Spell = { GetSpellCooldown = function() return { duration = {}, isActive = onCooldown } end }
tracking = { { name = "Find Minerals", active = false }, { name = "Find Herbs", active = true } }
ScarletUI:SwitchTracking()
assert(tracking[2].active, "swapped during a secret cooldown")
onCooldown = false
ScarletUI:SwitchTracking()
assert(tracking[1].active and not tracking[2].active, "did not swap after a secret cooldown")
C_Spell = savedSpell
GetSpellInfo = nil

-- Bag sorting: shared when changed; Era, TBC, and Mists lack the sort direction.
local bagSortHook = hooksecurefunc
hooksecurefunc = function(target, key, hook)
    local original = target[key]
    target[key] = function(...) original(...) hook(...) end
end
local sort, unconfirmed = { SortBagsRightToLeft = false, InsertItemsLeftToRight = false }, {}
C_Container = {
    GetSortBagsRightToLeft = function() return sort.SortBagsRightToLeft end,
    SetSortBagsRightToLeft = function(on) unconfirmed.SortBagsRightToLeft = on end,
    GetInsertItemsLeftToRight = function() return sort.InsertItemsLeftToRight end,
    SetInsertItemsLeftToRight = function(on) sort.InsertItemsLeftToRight = on end,
}
dofile("Modules/BagSort.lua")
hooksecurefunc = bagSortHook
-- A change before this character received the shared values is not shared.
C_Container.SetInsertItemsLeftToRight(true)
assert(ScarletUI.db.global.bagSortModule.insertItemsLeftToRight == nil)
C_Container.SetInsertItemsLeftToRight(false)
ScarletUI:SetupBagSort()
-- Right to left is on by default; the insert setting keeps the client's value.
assert(unconfirmed.SortBagsRightToLeft == true and sort.InsertItemsLeftToRight == false)
local sorting = ScarletUI:Options().args.bagModuleSettings.args.sortSettings.args
-- The client confirms a change later; the toggle shows the request until then.
sorting.sortBagsRightToLeft.set(nil, true)
assert(not sort.SortBagsRightToLeft and sorting.sortBagsRightToLeft.get())
sort.SortBagsRightToLeft = unconfirmed.SortBagsRightToLeft
assert(sorting.sortBagsRightToLeft.get())
-- Once confirmed, changes made elsewhere show again.
sort.SortBagsRightToLeft = false
assert(not sorting.sortBagsRightToLeft.get())
-- A change is saved when made; whatever the client reports at logout is not.
Fire("PLAYER_LOGOUT")
local bagSort = ScarletUI.db.global.bagSortModule
assert(bagSort.sortBagsRightToLeft == true and bagSort.insertItemsLeftToRight == nil)
sorting.insertItemsLeftToRight.set(nil, true)
assert(bagSort.insertItemsLeftToRight == true)
-- So is one made outside the settings, by the bag menu or another addon.
C_Container.SetSortBagsRightToLeft(false)
assert(bagSort.sortBagsRightToLeft == false)
sort, ScarletUI.bagSortApplied = { InsertItemsLeftToRight = false }, nil
C_Container.GetSortBagsRightToLeft, C_Container.SetSortBagsRightToLeft = nil, nil
ScarletUI:SetupBagSort()
assert(sort.InsertItemsLeftToRight == true and sorting.sortBagsRightToLeft.hidden())
assert(not sorting.insertItemsLeftToRight.hidden())
C_Container = nil
assert(#shutdown == 0 and shutdown["ScarletUI-ActionBars"] and shutdown["ScarletUI-Tracking"])
ScarletUI.eventHandlers, ScarletUI.frame = originalHandlers, originalFrame

-- Escape menu buttons: separate frames under the menu, never children of its layout.
local menuHooks, created, panelCalls = {}, {}, {}
local originalCreateFrame, originalShowPanel, originalHidePanel = CreateFrame, ShowUIPanel, HideUIPanel
CreateFrame = function(_, _, parent, template)
    local widget = { parent = parent, template = template, enabled = true }
    function widget:SetFrameStrata() end
    function widget:SetText(text) self.text = text end
    function widget:SetScript(_, handler) self.onClick = handler end
    function widget:ClearAllPoints() self.anchor = nil end
    function widget:SetPoint(_, relativeTo) self.anchor = relativeTo end
    function widget:SetEnabled(on) self.enabled = on end
    function widget:SetShown(on) self.shown = on end
    function widget:Hide() self.shown = false end
    table.insert(created, widget)
    return widget
end
GameMenuFrame = { buttonTemplate = "MainMenuFrameButtonTemplate", GetFrameStrata = function() return "DIALOG" end,
    HookScript = function(_, script, handler) menuHooks[script] = handler end }
CooldownViewerSettings = {}
ShowUIPanel = function(frame) panelCalls.shown = frame end
HideUIPanel = function(frame) panelCalls.hidden = frame end
PlaySound, SOUNDKIT = noop, SOUNDKIT or { IG_MAINMENU_OPTION = 1 }
dofile("Modules/GameMenu.lua")
ScarletUI:SetupGameMenuButtons()
-- Both buttons are opt-in: nothing is created until one is turned on.
assert(not ScarletUI.db.global.gameMenuButtons.sui and not ScarletUI.db.global.gameMenuButtons.cooldownManager)
menuHooks.OnShow()
assert(#created == 0)
ScarletUI.db.global.gameMenuButtons.sui, ScarletUI.db.global.gameMenuButtons.cooldownManager = true, true
menuHooks.OnShow()
local suiButton, cooldownButton = created[1], created[2]
assert(#created == 2 and suiButton.parent ~= GameMenuFrame and suiButton.template == "MainMenuFrameButtonTemplate")
assert(suiButton.anchor == GameMenuFrame and cooldownButton.anchor == suiButton and cooldownButton.shown)
cooldownButton.onClick()
assert(panelCalls.hidden == GameMenuFrame and panelCalls.shown == CooldownViewerSettings)
-- Turned-off entries hide and the rest move up; combat disables the buttons.
local menuSettings = ScarletUI.db.global.gameMenuButtons
menuSettings.sui = false
InCombatLockdown = function() return true end
menuHooks.OnShow()
assert(not suiButton.shown and cooldownButton.anchor == GameMenuFrame and not cooldownButton.enabled)
panelCalls = {}
cooldownButton.onClick()
assert(panelCalls.shown == nil)
-- Clients without the Cooldown Manager hide its option and button.
InCombatLockdown = function() return false end
CooldownViewerSettings = nil
assert(ScarletUI:Options().args.generalSettings.args.shortcuts.args.cooldownManager.hidden())
menuHooks.OnShow()
assert(not cooldownButton.shown and #created == 2)
menuSettings.sui = true
CreateFrame, ShowUIPanel, HideUIPanel, GameMenuFrame = originalCreateFrame, originalShowPanel, originalHidePanel, nil

-- Micro menu art follows its setting; the gamepad bag bar shows only with Gamepad UI on.
local function Shown() return { shown = true, SetShown = function(t, on) t.shown = on end } end
MicroMenu = { BackgroundArt = Shown(), BorderArt = Shown() }
local bagHooks, gamepadUI = {}, false
GamepadBagBar = Shown()
InputUtil = { IsGamepadUIEnabled = function() return gamepadUI end }
ContainerFrameCombinedBags = { HookScript = function(_, script, handler) bagHooks[script] = handler end }
dofile("Modules/FrameTweaks.lua")
ScarletUI:SetupFrameTweaks()
assert(not MicroMenu.BackgroundArt.shown and not MicroMenu.BorderArt.shown and not GamepadBagBar.shown)
assert(ScarletUI:Options().args.generalSettings.args.interface.args.hideMicroMenuArt == nil)
local microOption = ScarletUI:Options().args.actionBarTogglesSettings.args.hideMicroMenuArt
assert(not microOption.hidden())
microOption.set(nil, false)
assert(MicroMenu.BackgroundArt.shown and MicroMenu.BorderArt.shown)
gamepadUI = true
bagHooks.OnShow()
assert(GamepadBagBar.shown)
ScarletUI.db.global.hideMicroMenuArt = true
MicroMenu, GamepadBagBar, InputUtil, ContainerFrameCombinedBags = nil, nil, nil, nil
assert(ScarletUI:Options().args.actionBarTogglesSettings.args.hideMicroMenuArt.hidden())

-- Collapsing inactive tracked buffs: shown items take the slots at one end.
local collapseOption = ScarletUI:Options().args.generalSettings.args.interface.args.collapseInactiveBuffs
assert(collapseOption.hidden() and ScarletUI.db.global.collapseInactiveBuffs == "OFF")
local buffItems, buffViewer, layouts = {}, {}, 0
for index, shown in ipairs({ false, true, false, true }) do
    local item = { layoutIndex = index, shown = shown, scripts = {} }
    item.IsShown = function() return item.shown end
    item.GetPoint = function() return unpack(item.point, 1, 5) end
    item.ClearAllPoints = noop
    item.SetPoint = function(_, ...) item.point = { ... } end
    item.HookScript = function(_, script, handler) item.scripts[script] = handler end
    buffItems[index] = item
end
local slotDirection = 1
buffViewer.itemFramePool = { EnumerateActive = function()
    local i = 0
    return function() i = i + 1 return buffItems[i] end
end }
buffViewer.Layout = function()
    layouts = layouts + 1
    for i, item in ipairs(buffItems) do item.point = { "TOPLEFT", buffViewer, "TOPLEFT", (i - 1) * 40 * slotDirection, 0 } end
end
buffViewer:Layout()
local function BuffX() return buffItems[2].point[4], buffItems[4].point[4] end
local savedHook = hooksecurefunc
hooksecurefunc = function(target, key, hook)
    local original = target[key]
    target[key] = function(...) original(...) hook(...) end
end
BuffIconCooldownViewer = buffViewer
assert(not collapseOption.hidden())
-- Off leaves the viewer unhooked.
ScarletUI:SetupBuffCollapse()
assert(buffItems[2].scripts.OnShow == nil)
collapseOption.set(nil, "START")
local x2, x4 = BuffX()
assert(x2 == 0 and x4 == 40 and buffItems[1].point[4] == 0)
collapseOption.set(nil, "END")
x2, x4 = BuffX()
assert(x2 == 80 and x4 == 120)
-- A buff starting repacks without a Blizzard layout; a layout repacks too.
buffItems[3].shown = true
buffItems[3].scripts.OnShow()
x2, x4 = BuffX()
assert(x2 == 40 and buffItems[3].point[4] == 80 and x4 == 120 and layouts == 1)
buffItems[3].shown = false
buffViewer:Layout()
x2, x4 = BuffX()
assert(x2 == 80 and x4 == 120 and layouts == 2)
-- A reversed icon direction puts slot 1 on the right, so Left uses the last slots.
slotDirection = -1
collapseOption.set(nil, "START")
buffViewer:Layout()
x2, x4 = BuffX()
assert(x2 == -80 and x4 == -120)
-- Off returns every item to its own slot.
collapseOption.set(nil, "OFF")
x2, x4 = BuffX()
assert(x2 == -40 and x4 == -120)
BuffIconCooldownViewer, hooksecurefunc = nil, savedHook

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
Enum.TooltipDataType = { Spell = 1, Macro = 2, Item = 3 }
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
-- Secret max mana (combat): the percent uses the last readable value.
UnitPowerMax = function() return SECRET end
GameTooltipTextLeft2, GameTooltipTextRight2 = Line("105 Mana"), Line("40 yd range")
postCalls[1](GameTooltip, { id = 139 })
assert(GameTooltipTextLeft2:GetText() == costText)
UnitPowerMax = function() return 1300 end
-- Per mana: range average plus heal over time, or absorb; damage adds nothing.
for text, expected in pairs({
    ["Heals a friendly target for 93 to 107 and another 98 over 21 sec."] = "1.89 healing per mana",
    ["Heals a friendly target for 1,193 to 1,237."] = "11.57 healing per mana",
    ["Blasts the target for 50 to 60 Shadow damage."] = false,
    ["Blasts the target with Holy energy, causing 314 to 335 Holy damage to an enemy, or 359 to 381 healing to an ally."]
        = "3.52 healing per mana",
    ["Draws on the soul of the party member to shield them, absorbing 48 damage. Lasts 30 sec."]
        = "0.46 absorb per mana",
    ["Shields an ally for 15 sec, absorbing 12,345 damage."] = "117.57 absorb per mana",
}) do
    description, GameTooltipTextLeft2 = text, Line("105 Mana")
    postCalls[1](GameTooltip, { id = 139 })
    assert(PerMana() == expected, text)
end
-- Crate fill costs: every priced bundle gets its total, the cheapest turns green, once.
local itemNames = { "Vision Dust", "Greater Mystic Essence", [4] = "Crafted Solid Shot" } -- the shard's name loads later
local auctionPrices = { 100, 400, 9999, 10 }
local quality
-- Mainline has no global GetItemInfo, only C_Item.GetItemInfo.
C_Item = { GetItemNameByID = function(id) return itemNames[id] end,
    GetItemInfo = function() return nil, nil, quality end }
GetItemInfo = nil
GetMoneyString = function(copper) return copper .. "c" end
Auctionator = { Database = { db = { ["1"] = {}, ["2"] = {}, ["3"] = {}, ["4"] = {}, ["p:7"] = {} } }, API = { v1 = {
    GetVendorPriceByItemID = function(_, id) return id == 3 and 500 or nil end,
    GetAuctionPriceByItemID = function(_, id) return auctionPrices[id] end,
} } }
dofile("Modules/Tooltips.lua") -- again, to pick up C_Item
ScarletUI.spellCostHooked = nil
ScarletUI:SetupSpellCostPercent()
local function CrateTooltip()
    GameTooltipTextLeft2 = Line("Use: Fill the crate:\n- 20 Vision Dust\n- 4 Greater Mystic Essence")
    GameTooltipTextLeft3 = Line("|cffffffff- 6 Small Radiant Shard|r")
end
CrateTooltip()
postCalls[3](GameTooltip)
assert(GameTooltipTextLeft3:GetText() == "|cffffffff- 6 Small Radiant Shard|r") -- name not loaded yet
itemNames[3] = "Small Radiant Shard"
CrateTooltip()
local crateText = "Use: Fill the crate:\n- 20 Vision Dust\n    |cffffffff2000c|r\n"
    .. "|cff20ff20- 4 Greater Mystic Essence|r\n    |cffffffff1600c|r"
for _ = 1, 2 do
    postCalls[3](GameTooltip)
    assert(GameTooltipTextLeft2:GetText() == crateText, GameTooltipTextLeft2:GetText())
    assert(GameTooltipTextLeft3:GetText() == "|cffffffff- 6 Small Radiant Shard|r\n    |cffffffff3000c|r")
end
ScarletUI.db.global.crateFillCosts = false
GameTooltipTextLeft2 = Line("- 20 Vision Dust")
postCalls[3](GameTooltip)
assert(GameTooltipTextLeft2:GetText() == "- 20 Vision Dust")
ScarletUI.db.global.crateFillCosts = true
-- Writ info: reputation (Diplomacy for Humans), what the requested items cost,
-- with reputation and quality colors; nothing on other items or with the setting off.
dofile("Modules/Writs.lua")
do
    local added, race = {}, 2
    local colors = {}
    GameTooltip.AddDoubleLine = function(_, left, right, r, g, b)
        added[#added + 1] = left .. " = " .. right
        colors[#colors + 1] = r .. "," .. g .. "," .. b
    end
    ITEM_QUALITY_COLORS = { [3] = { r = 0, g = 0.5, b = 1 } }
    UnitFactionGroup = function() return race == 1 and "Alliance" or "Horde" end
    UnitRace = function() return "", "", race end
    GameTooltipTextLeft2, GameTooltipTextLeft3 = Line("Journeyman"), Line("A pending crafting order.")
    local function Writ(id)
        added, colors = {}, {}
        postCalls[3](GameTooltip, { id = id })
        return table.concat(added, "; ")
    end
    assert(Writ(264037) == "Durotar Supply and Logistics = +75; 200 Crafted Solid Shot = 2000c", Writ(264037))
    -- Light-blue fallback without ChatTypeInfo; white item until it is cached.
    assert(colors[1] == "0.5,0.5,1" and colors[2] == "1,1,1", table.concat(colors, " "))
    ChatTypeInfo = { COMBAT_FACTION_CHANGE = { r = 0.2, g = 0.3, b = 0.4 } }
    quality = 3
    Writ(264037)
    assert(colors[1] == "0.2,0.3,0.4" and colors[2] == "0,0.5,1", table.concat(colors, " "))
    quality = nil
    race = 1
    assert(Writ(264037) == "Azeroth Commerce Authority = +82; 200 Crafted Solid Shot = 2000c", Writ(264037))
    assert(Writ(264160) == "Azeroth Commerce Authority = +220; Soul Pouch = No price", Writ(264160))
    assert(Writ(1) == "")
    ScarletUI.db.global.writInfo = false
    assert(Writ(264037) == "")
    ScarletUI.db.global.writInfo = true
    -- Every writ has a tier with a reputation value and a requested item.
    local count = 0
    for _, writ in pairs(ScarletUI.WRITS) do
        count = count + 1
        assert(ScarletUI.WRIT_REPUTATION[writ[1]] and writ[2] ~= "")
    end
    assert(count == 150)
end
-- The crate setting sits on the Auction Prices page with Craft Profit (Forever only).
local auctionPage = ScarletUI:Options().args.auctionSettings
local crateOption = auctionPage.args.crateFillCosts
assert(ScarletUI:Options().args.generalSettings.args.interface.args.crateFillCosts == nil)
assert(not auctionPage.disabled() and crateOption.get() and not crateOption.desc():find("Requires"))
assert(auctionPage.args.craftProfit.hidden() and auctionPage.args.craftProfit.get() and auctionPage.args.writInfo.get())
Auctionator, C_Item = nil, nil
-- Without Auctionator the page is grayed out, reads off, and says what it needs.
assert(auctionPage.disabled() and not crateOption.get() and not auctionPage.args.craftProfit.get()
    and not auctionPage.args.writInfo.get())
assert(crateOption.desc():find("Requires the Auctionator addon") and auctionPage.desc():find("scan the auction house"))
-- Craft Profit pricing rules; setup builds nothing without Auctionator.
dofile("Modules/CraftProfit.lua")
ScarletUI:SetupCraftProfit()
assert(SLASH_SCARLETUICRAFTPROFIT1 == nil)
ScarletUI.craftProfitSupported = nil
do
    local CP = ScarletUI.CraftProfit
    local prices = { [1] = 10, [2] = 50 }
    local function buy(id) return prices[id] end
    local function sell(id) return id == 9 and 200 or 0 end
    local cost, value, profit = CP.Evaluate({ reagents = { { id = 1, count = 3 }, { id = 2, count = 1 } }, output = 9, yield = 1 }, buy, sell)
    assert(cost == 80 and value == 200 and profit == 120)
    assert(select(2, CP.Evaluate({ reagents = {}, output = 9, yield = 1.5 }, buy, sell)) == 300) -- average of a 1-2 craft
    local c, _, p, missing = CP.Evaluate({ reagents = { { id = 3, count = 1 } }, output = 9, yield = 1 }, buy, sell)
    assert(c == nil and p == nil and missing == 3) -- a reagent with no price
    assert(select(3, CP.Evaluate({ reagents = { { id = 1, count = 2 } }, yield = 1 }, buy, sell)) == -20) -- enchants have no output
    assert(CP.Keep(1, 100, false) and not CP.Keep(0, 100, false)) -- gray break-even gains nothing
    assert(CP.Keep(0, 100, true) and CP.Keep(-10, 100, true) and not CP.Keep(-11, 100, true)) -- within 10% of cost
    assert(not CP.Keep(nil, nil, true))
    assert(CP.Money(12345) == "1|cffffd700g|r 23|cffc7c7cfs|r" and CP.Money(-205) == "-2|cffc7c7cfs|r 5|cffeda55fc|r")
    assert(CP.Money(7) == "7|cffeda55fc|r" and CP.Money(nil) == "?")
end
-- World map zone levels: appended once, difficulty-colored, only for known zones.
local hovered, difficultyLevel = 1429, nil
local areaLabel = { labelInfoByType = { [3] = {} } }
areaLabel.SetLabel = function(label, kind, name) label.labelInfoByType[kind].name = name end
areaLabel.dataProvider = { GetMap = function() return {
    GetMapID = function() return 1415 end,
    GetNormalizedCursorPosition = function() return 0.5, 0.5 end,
} end }
MAP_AREA_LABEL_TYPE = { AREA_NAME = 3 }
WorldMapFrame = { dataProviders = { [{}] = true, [{ Label = areaLabel }] = true } }
C_Map = { GetMapInfoAtPosition = function() return { mapID = hovered } end }
hooksecurefunc = function(target, key, hook)
    local original = target[key]
    target[key] = function(...) original(...); hook(...) end
end
local playerLevel = 5
UnitLevel = function() return playerLevel end
QuestDifficultyColors = { difficult = { r = 1, g = 1, b = 0 } }
GetQuestDifficultyColor = function(level) difficultyLevel = level; return { r = 0.5, g = 0.5, b = 0.5 } end
dofile("Modules/ZoneLevels.lua")
ScarletUI:SetupZoneLevels() -- this harness is the Forever client
local function ZoneLabel(name) areaLabel:SetLabel(3, name); return areaLabel.labelInfoByType[3].name end
assert(ZoneLabel("Elwynn Forest") == "Elwynn Forest|cffffff00 (1-10)|r")
assert(ZoneLabel(nil) == nil)
playerLevel = 30
assert(ZoneLabel("Elwynn Forest") == "Elwynn Forest|cff7f7f7f (1-10)|r" and difficultyLevel == 8)
hovered = 1957
assert(ZoneLabel("Isle of Quel'Danas") == "Isle of Quel'Danas|cff7f7f7f (70)|r" and difficultyLevel == 70)
assert(ZoneLabel("Isle|cffff0000 (70)|r") == "Isle|cffff0000 (70)|r")
hovered = 1453
assert(ZoneLabel("Stormwind City") == "Stormwind City")
hovered = 1429
ScarletUI.db.global.zoneLevels = false
assert(ZoneLabel("Elwynn Forest") == "Elwynn Forest")
ScarletUI.db.global.zoneLevels = true
assert(ScarletUI.zoneLevelsHooked)
assert(not ScarletUI:Options().args.generalSettings.args.interface.args.zoneLevels.hidden())
-- Five second rule: a cast that costs mana starts a 5 second line across the mana bar.
local sparkShown, sparkX = false, nil
local manaBar = { GetWidth = function() return 100 end, CreateTexture = function() return {
    SetColorTexture = noop, SetWidth = noop,
    Hide = function() sparkShown = false end,
    SetShown = function(_, shown) sparkShown = shown end,
    SetPoint = function(_, _, _, _, x) sparkX = x end,
} end }
PlayerFrame_GetManaBar = function() return manaBar end
local ruleScripts, ruleShown, savedCreateFrame = {}, false, CreateFrame
CreateFrame = function() return {
    SetScript = function(_, name, fn) ruleScripts[name] = fn end,
    RegisterUnitEvent = noop,
    Show = function() ruleShown = true end,
    Hide = function() ruleShown = false end,
} end
local now, powerType = 100, 0
GetTime = function() return now end
UnitPowerType = function() return powerType end
-- Spell 1 costs mana, 2 costs energy, 3 is free, and 4 costs mana but arrives secret.
local manaCost = { { type = 0, cost = 50 } }
C_Spell.GetSpellPowerCost = function(id) return ({ manaCost, { { type = 3, cost = 40 } }, nil, manaCost })[id] end
issecretvalue = function(v) return v == 4 end
dofile("Modules/FiveSecondRule.lua")
ScarletUI:SetupFiveSecondRule() -- this harness is the Forever client
CreateFrame, issecretvalue = savedCreateFrame, nil
local function Cast(spellID) ruleScripts.OnEvent(nil, "UNIT_SPELLCAST_SUCCEEDED", "player", "guid", spellID) end
Cast(2); Cast(3); Cast(4)
assert(not ruleShown)
Cast(1)
assert(ruleShown)
now = 102; ruleScripts.OnUpdate()
assert(sparkShown and sparkX == 40)
powerType = 3; ruleScripts.OnUpdate() -- druid form: bar shows energy
assert(not sparkShown)
powerType = 0
ScarletUI.db.global.fiveSecondRule = false; ruleScripts.OnUpdate()
assert(not sparkShown)
ScarletUI.db.global.fiveSecondRule = true
Cast(3) -- a free spell does not restart the timer
now = 105; ruleScripts.OnUpdate()
assert(not sparkShown and not ruleShown)
assert(not ScarletUI:Options().args.generalSettings.args.interface.args.fiveSecondRule.hidden())
-- Quest XP bar: completed quests' XP is highlighted after the fill, up to the bar's end.
do
    local shown, width
    local expBar = { isExpBar = true, StatusBar = {
        GetWidth = function() return 200 end,
        GetStatusBarTexture = function() return {} end,
        CreateTexture = function() return {
            SetTexture = noop, SetVertexColor = noop, SetPoint = noop,
            SetShown = function(_, value) shown = value end,
            SetWidth = function(_, value) width = value end,
        } end,
    } }
    StatusTrackingBarManager = { barContainers = { { bars = { {}, expBar } } } }
    local savedQuestLog, xp = C_QuestLog, 500
    UnitXP = function() return xp end
    UnitXPMax = function() return 1000 end
    -- Quest 1 is complete, 2 is in progress, 3 is complete but hidden.
    local entries = { { isHeader = true }, { questID = 1 }, { questID = 2 }, { questID = 3, isHidden = true } }
    C_QuestLog = {
        GetNumQuestLogEntries = function() return #entries end,
        GetInfo = function(i) return entries[i] end,
        IsComplete = function(id) return id ~= 2 end,
    }
    GetQuestLogRewardXP = function(id) return id * 100 end
    local scripts, savedCreate = {}, CreateFrame
    CreateFrame = function() return { RegisterEvent = noop, SetScript = function(_, name, fn) scripts[name] = fn end } end
    dofile("Modules/QuestXPBar.lua")
    ScarletUI:SetupQuestXPBar()
    CreateFrame = savedCreate
    assert(shown and width == 20) -- 100 of 1000 XP on a 200 wide bar
    xp = 950; scripts.OnEvent() -- only 50 XP left in the level
    assert(shown and width == 10)
    ScarletUI.db.global.questXPBar = false; scripts.OnEvent()
    assert(not shown)
    ScarletUI.db.global.questXPBar = true
    -- Classic quest log API.
    C_QuestLog, xp = {}, 0
    GetNumQuestLogEntries = function() return 3 end
    GetQuestLogTitle = function(i) return "q", 1, 0, i == 1, false, i == 2 and 1 or -1, 0, i end
    scripts.OnEvent()
    assert(shown and width == 40)
    C_QuestLog = savedQuestLog
    assert(not ScarletUI:Options().args.generalSettings.args.interface.args.questXPBar.hidden())
end
-- XP per hour: session average from PLAYER_XP_UPDATE deltas, level-ups add back
-- the previous level's max, hidden until XP is gained and at max level.
do
    local savedXP, savedMax, savedTime, savedLevel = UnitXP, UnitXPMax, GetTime, UnitLevel
    local savedSecret, savedFrame, savedTrack = issecretvalue, CreateFrame, StatusTrackingBarManager
    local xp, max, clock, level = 100, 1000, 0, 10
    UnitXP = function() return xp end
    UnitXPMax = function() return max end
    UnitLevel = function() return level end
    GetTime = function() return clock end
    GetMaxPlayerLevel = function() return 60 end
    local barRight, anchor = 300, nil
    local xpBar = { GetRight = function() return barRight end }
    StatusTrackingBarManager = { barContainers = { { bars = { {}, { isExpBar = true, StatusBar = xpBar } } } } }
    local savedUIParent, savedAFK = UIParent, UnitIsAFK
    UIParent = { GetRight = function() return 1000 end }
    local afk = false
    UnitIsAFK = function() return afk end
    local fontText, shown, size
    local scripts, eventScripts = {}, {}
    local fontString = {
        SetPoint = noop, GetFont = function() return "font", 10 end, SetFont = noop,
        SetText = function(_, value) fontText = value end,
        GetStringWidth = function() return 50 end, GetStringHeight = function() return 10 end,
    }
    local first = true
    CreateFrame = function()
        local f = { RegisterEvent = noop, SetFrameStrata = noop, SetPoint = function(_, point, rel, relPoint, x) if rel == xpBar then anchor = { point, relPoint, x } end end,
            ClearAllPoints = function() anchor = nil end, EnableMouse = noop,
            CreateFontString = function() return fontString end,
            SetScript = function(_, name, fn) (first and scripts or eventScripts)[name] = fn end,
            SetSize = function(_, w) size = w end, Hide = function() shown = false end,
            Show = function() shown = true end, GetScript = function() return noop end }
        first = false
        return f
    end
    local secret = false
    issecretvalue = function() return secret end -- captured when the module loads
    dofile("Modules/XPPerHour.lua")
    ScarletUI:SetupXPPerHour()
    CreateFrame = savedFrame
    assert(shown == false) -- nothing gained yet: no "0 xp/hr"
    clock, xp = 3600, 600 -- 500 XP in an hour, 400 left
    eventScripts.OnEvent(nil, "PLAYER_XP_UPDATE", "player")
    assert(shown and fontText == "500 xp/hr  TTL 48m", fontText)
    -- Placed just right of the XP bar; inside its end when that would run off screen.
    assert(anchor[1] == "LEFT" and anchor[2] == "RIGHT" and anchor[3] == 6)
    barRight = 990; ScarletUI.UpdateXPPerHour()
    assert(anchor[1] == "RIGHT" and anchor[2] == "RIGHT" and anchor[3] == -6)
    barRight = 300; ScarletUI.UpdateXPPerHour()
    -- AFK pauses the clock: an hour away doesn't dilute the rate.
    afk = true; eventScripts.OnEvent(nil, "PLAYER_FLAGS_CHANGED", "player")
    assert(fontText == "500 xp/hr  TTL 48m (paused)", fontText)
    clock = 7200; ScarletUI.UpdateXPPerHour()
    assert(fontText == "500 xp/hr  TTL 48m (paused)", fontText)
    afk = false; eventScripts.OnEvent(nil, "PLAYER_FLAGS_CHANGED", "player")
    assert(fontText == "500 xp/hr  TTL 48m", fontText)
    -- Level-up: 600/1000 -> 300 into a 2000 XP level: 400 + 300 more, 1200 total.
    xp, max, level = 300, 2000, 11
    eventScripts.OnEvent(nil, "PLAYER_XP_UPDATE", "player")
    assert(fontText == "1200 xp/hr  TTL 1h 25m", fontText)
    -- Seconds from login are floored at a minute.
    ScarletUI.ResetXPPerHour()
    assert(shown == false)
    clock, xp = 7210, 400
    eventScripts.OnEvent(nil, "PLAYER_XP_UPDATE", "player")
    assert(fontText:find("^6000 xp/hr"), fontText) -- 100 XP over the 60 second floor
    -- Secret XP is skipped, not counted.
    secret = true
    xp = 99999
    eventScripts.OnEvent(nil, "PLAYER_XP_UPDATE", "player")
    secret, issecretvalue = false, savedSecret
    assert(fontText:find("^6000 xp/hr"), fontText)
    -- Toggle off hides it; max level hides it.
    ScarletUI.Print = noop
    ScarletUI:ToggleXPPerHour()
    assert(ScarletUI.db.global.xpPerHour == false and shown == false)
    ScarletUI:ToggleXPPerHour()
    assert(shown)
    level = 60; ScarletUI.UpdateXPPerHour()
    assert(shown == false)
    assert(not ScarletUI:Options().args.generalSettings.args.interface.args.xpPerHour.hidden())
    UnitXP, UnitXPMax, GetTime, UnitLevel, StatusTrackingBarManager = savedXP, savedMax, savedTime, savedLevel, savedTrack
    UIParent, UnitIsAFK = savedUIParent, savedAFK
end
-- Fishing mode: with a pole equipped the key clicks our button, and during the
-- Fishing cast it is Interact With Target with soft targeting widened.
do
local fishWidgets, fishBinding, fishCVars = {}, nil, { SoftTargetInteract = "0", SoftTargetInteractArc = "1" }
local function FishWidget(kind, name)
    local widget = { kind = kind, name = name, scripts = {}, attributes = {}, shown = true }
    widget.SetScript = function(self, script, fn) self.scripts[script] = fn end
    widget.SetAttribute = function(self, attribute, value) self.attributes[attribute] = value end
    widget.Show = function(self) self.shown = true end
    widget.Hide = function(self) self.shown = false end
    widget.SetShown = function(self, shown) self.shown = shown and true or false end
    widget.IsShown = function(self) return self.shown end
    widget.SetText = function(self, text) self.text = text end
    widget.GetStringWidth = function(self) return #tostring(self.text or "") end
    widget.SetSize = function(self, width, height) self.width, self.height = width, height end
    widget.GetNormalTexture = function() return FishWidget("Texture") end
    widget.CreateAnimationGroup = function() return FishWidget("AnimationGroup") end
    widget.CreateAnimation = function() return FishWidget("Animation") end
    widget.Play = function(self) self.played = (rawget(self, "played") or 0) + 1 end
    widget.SetPoint = function(self, ...) self.point = { ... } end
    widget.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
    widget.CreateTexture = function() return FishWidget("Texture") end
    widget.CreateFontString = function() return FishWidget("FontString") end
    fishWidgets[#fishWidgets + 1] = widget
    return setmetatable(widget, { __index = function() return noop end })
end
local function FishNamed(name)
    for _, widget in ipairs(fishWidgets) do
        if widget.name == name then return widget end
    end
end
-- Item IDs of the entries in the lure list, in order, and the highlighted one.
local function BarLures()
    local shown, applied = {}, nil
    for _, widget in ipairs(fishWidgets) do
        if rawget(widget, "applied") and widget.shown then
            shown[#shown + 1] = widget.itemID
            if widget.applied.shown then applied = widget.itemID end
        end
    end
    return table.concat(shown, ","), applied
end
local function ClickLure(itemID)
    for _, widget in ipairs(fishWidgets) do
        if rawget(widget, "applied") and widget.itemID == itemID and widget.shown then return widget.scripts.OnClick() end
    end
    error("no lure button for " .. itemID)
end
savedCreateFrame = CreateFrame
CreateFrame = FishWidget
local savedGetCVar, poleID, casting, enchanted = GetCVar, 6256, false, false
GetCVar = function(name) return fishCVars[name] end
SetCVar = function(name, value) fishCVars[name] = value end
IsPlayerMoving = function() return false end
GetInventoryItemID = function() return poleID end
C_Item = { GetItemInfoInstant = function(id) return id, nil, nil, nil, nil, 2, id == 6256 and 20 or 7 end }
GetItemCount = function() return 5 end
C_Spell.GetSpellName = function(id) return (id == 7620 or id == 7731) and "Fishing" or "Other" end
UnitCastingInfo = function() return casting or nil end
GetWeaponEnchantInfo = function() return enchanted end
ClearOverrideBindings = function() fishBinding = nil end
SetOverrideBinding = function(_, _, key, action) fishBinding = key .. ">" .. action end
SetOverrideBindingClick = function(_, _, key, name) fishBinding = key .. ">click:" .. name end
BACKPACK_CONTAINER, NUM_BAG_SLOTS = 0, 4
-- Bag 2 holds Shiny Bauble in slot 1 and Nightcrawlers in slot 3.
C_Container = { GetContainerNumSlots = function() return 4 end,
    GetContainerItemID = function(bag, slot) return bag == 2 and ({ 6529, nil, 6530 })[slot] or nil end }
local fishSkill = { rank = 150, maxRank = 225 }
C_SkillInfo = { GetSkillLineInfoByID = function(id) return id == 356 and fishSkill or nil end }
local function FishText(text)
    for _, widget in ipairs(fishWidgets) do
        if widget.kind == "FontString" and rawget(widget, "text") == text then return true end
    end
end
dofile("Modules/Fishing.lua")
ScarletUI:SetupFishing()
local fishButton, fishBar = FishNamed("ScarletUIFishingButton"), FishNamed("ScarletUIFishingBar")
-- The button for the lure in use has a count but no highlight; the list is the last unnamed frame.
local fishCurrent, fishList
for _, widget in ipairs(fishWidgets) do
    if rawget(widget, "count") and not rawget(widget, "applied") then fishCurrent = fishCurrent or widget end
    if widget.kind == "Frame" and not rawget(widget, "name") then fishList = widget end
end
local function Fish(event, spellID) fishWidgets[1].scripts.OnEvent(nil, event, "player", "guid", spellID) end
local function Press() fishButton.scripts.PreClick(); return fishButton.attributes.macrotext end
assert(fishBinding == "SPACE>click:ScarletUIFishingButton" and fishButton.attributes.type == "macro")
Fish("UNIT_SPELLCAST_CHANNEL_START", 5)
assert(fishBinding == "SPACE>click:ScarletUIFishingButton" and fishCVars.SoftTargetInteract == "0") -- another channel
Fish("UNIT_SPELLCAST_CHANNEL_START", 7731)
assert(fishBinding == "SPACE>INTERACTTARGET" and fishCVars.SoftTargetInteract == "3" and fishCVars.SoftTargetInteractArc == "2")
Fish("UNIT_SPELLCAST_CHANNEL_STOP", 7731)
assert(fishBinding == "SPACE>click:ScarletUIFishingButton" and fishCVars.SoftTargetInteract == "0")
-- The range CVar is missing in this harness, so it is left alone.
assert(fishCVars.SoftTargetInteractArc == "1" and fishCVars.SoftTargetInteractRange == nil)
-- The key is released while moving, in combat, with no pole, and when switched off.
Fish("PLAYER_STARTED_MOVING"); assert(fishBinding == nil)
Fish("PLAYER_STOPPED_MOVING"); assert(fishBinding)
Fish("PLAYER_REGEN_DISABLED"); assert(fishBinding == nil)
Fish("PLAYER_EQUIPMENT_CHANGED"); assert(fishBinding == nil)
Fish("PLAYER_REGEN_ENABLED"); assert(fishBinding)
-- The bar shows with the pole, even in combat: the best lure, with a closed list of them all.
local barLures, barApplied = BarLures()
assert(fishBar.shown and barLures == "6530,6529,0" and barApplied == 6530) -- 0 is the no-lure entry
assert(fishCurrent.shown and fishCurrent.itemID == 6530 and fishCurrent.count.text == 5 and not fishList.shown)
-- Clicking the lure opens and closes the list; losing the pole closes it too.
fishCurrent.scripts.OnClick(); assert(fishList.shown)
fishCurrent.scripts.OnClick(); assert(not fishList.shown)
-- Left open, it closes after a second with the mouse off the lures, counted from the last hover.
fishCurrent.scripts.OnClick()
fishList.scripts.OnUpdate(nil, 0.6); assert(fishList.shown)
fishCurrent.IsMouseOver = function() return true end
fishList.scripts.OnUpdate(nil, 5); assert(fishList.shown)
fishCurrent.IsMouseOver = nil
fishList.scripts.OnUpdate(nil, 0.6); assert(fishList.shown)
fishList.scripts.OnUpdate(nil, 0.6); assert(not fishList.shown)
fishCurrent.scripts.OnClick()
poleID = 2092; Fish("PLAYER_REGEN_DISABLED"); Fish("PLAYER_EQUIPMENT_CHANGED")
assert(not fishBar.shown and not fishList.shown)
Fish("PLAYER_REGEN_ENABLED"); assert(fishBinding == nil)
poleID = 6256; Fish("PLAYER_EQUIPMENT_CHANGED"); assert(fishBar.shown and fishBinding)
-- Fishing has its own settings page, led by its switch.
local fishingOptions = ScarletUI:Options().args.fishingSettings
assert(not fishingOptions.hidden() and fishingOptions.args.enabled.order == 0)
assert(ScarletUI:Options().args.generalSettings.args.fishing == nil)
fishingOptions.args.enabled.set(nil, false); assert(fishBinding == nil and not fishBar.shown)
fishingOptions.args.enabled.set(nil, true); assert(fishBar.shown)
fishingOptions.args.key.set(nil, "F"); assert(fishBinding == "F>click:ScarletUIFishingButton")
fishingOptions.args.key.set(nil, ""); assert(fishBinding == nil)
fishingOptions.args.key.set(nil, "SPACE")
-- A press applies the best lure, waits out its cast, then casts Fishing.
now = 200
assert(Press() == "/use 2 3\n/use 16")
Fish("UNIT_SPELLCAST_START", 9); casting = true
assert(Press() == nil)
casting = false; Fish("UNIT_SPELLCAST_SUCCEEDED", 9)
assert(Press() == "/cast Fishing") -- enchant not reported yet
now = 202; enchanted = true
assert(Press() == "/cast Fishing")
-- A lure that fails to start a cast gives way to Fishing on the next press.
enchanted = false
assert(Press() == "/use 2 3\n/use 16")
assert(Press() == "/cast Fishing")
-- Clicking a lure in the list picks it and closes the list; clicking it again goes back to the best one.
fishCurrent.scripts.OnClick()
ClickLure(6529)
assert(ScarletUI.db.global.fishingModule.lure == 6529 and select(2, BarLures()) == 6529)
assert(fishCurrent.itemID == 6529 and not fishList.shown)
assert(Press() == "/use 2 1\n/use 16" and Press() == "/cast Fishing")
ClickLure(6529)
assert(ScarletUI.db.global.fishingModule.lure == nil and select(2, BarLures()) == 6530 and fishCurrent.itemID == 6530)
-- A picked lure that has run out falls back to the best one.
ScarletUI.db.global.fishingModule.lure = 6532; Fish("BAG_UPDATE_DELAYED")
assert(select(2, BarLures()) == 6530 and Press() == "/use 2 3\n/use 16" and Press() == "/cast Fishing")
ScarletUI.db.global.fishingModule.lure = nil
-- With auto lures off the bar keeps only the Fishing icon and the key only casts.
fishCurrent.scripts.OnClick()
fishingOptions.args.autoLure.set(nil, false)
assert(fishBar.shown and not fishCurrent.shown and not fishList.shown)
assert(Press() == "/cast Fishing" and Press() == "/cast Fishing")
fishingOptions.args.autoLure.set(nil, true); assert(fishCurrent.shown and BarLures() == "6530,6529,0")
-- The no-lure entry shows as an empty slot and makes the key only cast.
ClickLure(0)
assert(ScarletUI.db.global.fishingModule.lure == 0 and fishCurrent.itemID == 0 and fishCurrent.count.text == "")
assert(select(2, BarLures()) == 0 and Press() == "/cast Fishing" and Press() == "/cast Fishing")
ClickLure(0)
assert(ScarletUI.db.global.fishingModule.lure == nil and fishCurrent.itemID == 6530)
-- The bar names the addon and shows the Fishing skill and its cap, following skill-ups.
assert(FishText("Scarlet UI") and FishText("Fishing 150") and FishText("/225"))
local fishDrop, fishRise
for _, widget in ipairs(fishWidgets) do
    if widget.kind == "AnimationGroup" then fishRise = widget end
    if widget.kind == "FontString" and rawget(widget, "shown") == false then fishDrop = widget end
end
assert(fishDrop and not rawget(fishRise, "played")) -- reading the skill at login is no skill-up
fishSkill.rank = 151; Fish("SKILL_LINES_CHANGED"); assert(FishText("Fishing 151") and FishText("/225"))
-- A skill-up floats the gain up from the rank, then hides again.
assert(fishDrop.shown and fishDrop.text == "+1" and fishRise.played == 1)
fishRise.scripts.OnFinished(); assert(not fishDrop.shown)
Fish("SKILL_LINES_CHANGED"); assert(fishRise.played == 1 and not fishDrop.shown)
-- Era and TBC read it from the skill list; an unlisted skill shows nothing.
C_SkillInfo = nil
GetNumSkillLines = function() return 2 end
GetSkillLineInfo = function(index)
    if index == 1 then return "Secondary Skills", true end
    return "Fishing", false, nil, 75, 0, 0, 150
end
Fish("SKILL_LINES_CHANGED"); assert(FishText("Fishing 75") and FishText("/150"))
GetNumSkillLines = function() return 1 end
local skillWidth = fishBar.width
Fish("SKILL_LINES_CHANGED"); assert(not FishText("Fishing 75") and not FishText("/150"))
-- The panel wraps its contents: narrower without the skill text, never narrower than the title.
assert(fishBar.width < skillWidth and fishBar.width >= 32 + #"Scarlet UI" and fishBar.height == 86)
-- Mists reads it from the profession list.
GetProfessions = function() return nil, nil, nil, 9 end
GetProfessionInfo = function(index) return "Fishing", nil, index == 9 and 300, 600 end
Fish("SKILL_LINES_CHANGED"); assert(FishText("Fishing 300") and FishText("/600"))
GetNumSkillLines, GetSkillLineInfo, GetProfessions, GetProfessionInfo = nil, nil, nil, nil
-- Dragging the Fishing icon saves the bar position, which a rerun of setup applies.
for _, widget in ipairs(fishWidgets) do
    if widget.scripts.OnDragStop then widget.scripts.OnDragStop() end
end
ScarletUI:SetupFishing()
assert(fishBar.point[1] == "TOPLEFT" and fishBar.point[4] == 40 and fishBar.point[5] == -50)
-- Only a Ctrl-click on the icon puts the bar back at its default position.
local function ClickFishingIcon()
    for _, widget in ipairs(fishWidgets) do
        if widget.scripts.OnDragStop and widget.scripts.OnClick then widget.scripts.OnClick() end
    end
end
IsControlKeyDown = function() return false end
ClickFishingIcon(); assert(fishBar.point[1] == "TOPLEFT" and ScarletUI.db.global.fishingModule.position)
IsControlKeyDown = function() return true end
ClickFishingIcon(); assert(fishBar.point[1] == "CENTER" and ScarletUI.db.global.fishingModule.position == nil)
IsControlKeyDown = nil
CreateFrame, GetCVar, C_Container, C_Item = savedCreateFrame, savedGetCVar, nil, nil
end

-- Reminders. Food buff: the icon shows while Well Fed is missing and the bags
-- hold a food the character can eat. Right-click eats the food shown;
-- left-click opens a list of the usable foods to pick which one that is.
do
local foodWidgets = {}
local function FoodWidget(kind, name, _, template)
    local widget = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, shown = true }
    widget.SetScript = function(self, script, fn) self.scripts[script] = fn end
    widget.SetAttribute = function(self, attribute, value) self.attributes[attribute] = value end
    widget.Show = function(self) self.shown = true end
    widget.Hide = function(self) self.shown = false end
    widget.SetShown = function(self, shown) self.shown = shown and true or false end
    widget.IsShown = function(self) return self.shown end
    widget.SetText = function(self, text) self.text = text end
    widget.SetPoint = function(self, ...) self.point = { ... } end
    widget.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
    widget.SetWidth = function(self, width) self.width = width end
    widget.SetTexture = function(self, texture) self.icon = texture end
    widget.CreateTexture = function() return FoodWidget("Texture") end
    widget.CreateFontString = function() return FoodWidget("FontString") end
    widget.GetNormalTexture = function() return FoodWidget("Texture") end
    foodWidgets[#foodWidgets + 1] = widget
    return setmetatable(widget, { __index = function() return noop end })
end
local savedCreateFrame, savedUnitLevel = CreateFrame, UnitLevel
CreateFrame = FoodWidget
local SECRET_AURA = {}
-- Spiced Wolf Meat needs level 1, Bristle Whisker Catfish 15, Mithril Head Trout 25.
local foodAura, foodLevel, foodBags, atMax = nil, 20, { 2680, 4593, 8364 }, false
-- The hidden XP aura (1243969) is never reported; a visible Well Fed spell is.
-- Eating shows the ordinary Food aura; the use spell's own aura is hidden too.
local eatingAura, clock = nil, 500
-- Another client's Well Fed is only known by its name.
local namedAura
C_UnitAuras = { GetPlayerAuraBySpellID = function(id) return id == 1249523 and foodAura or nil end,
    GetAuraDataBySpellName = function(_, name)
        return name == "Food" and eatingAura or name == "Well Fed" and namedAura or nil
    end }
local savedSpell, savedGetTime = C_Spell, GetTime
-- Use spell text of the unlisted items 5000 to 5002; the third has not loaded yet.
local spellText = { [95000] = "Restores 552 health. If you spend at least 10 seconds eating you will become well fed.",
    [95001] = "Restores 61 health over 18 sec.", [95002] = "" }
C_Spell = { GetSpellName = function(id) return ({ [433] = "Food", [430] = "Drink", [19705] = "Well Fed" })[id] end,
    GetSpellDescription = function(id) return spellText[id] end,
    GetSpellTexture = function(id) return "buff" .. id end }
GetTime = function() return clock end
UnitLevel = function() return foodLevel end
IsPlayerAtEffectiveMaxLevel = function() return atMax end
C_Container = { GetContainerNumSlots = function() return 4 end,
    GetContainerItemID = function(bag, slot) return bag == 0 and foodBags[slot] or nil end }
-- Weapons by item ID: a sword, a mace, a fishing pole; 99 is a shield.
local weaponSubclass = { [50] = 7, [51] = 4, [52] = 20 }
-- Required levels of the weapon enhancements below; the rest need none.
local requiredLevel = { [12404] = 35, [2871] = 15, [3241] = 15, [20749] = 45 }
C_Item = { GetItemInfoInstant = function(id)
        return id, nil, nil, nil, "icon" .. id, weaponSubclass[id] and 2 or id == 99 and 4 or 0, weaponSubclass[id]
    end,
    GetItemInfo = function(id) return "item", nil, nil, nil, requiredLevel[id] or 1 end,
    GetItemCount = function(id) return id % 10 end,
    GetItemSpell = function(id) return "Nutritious Food", 90000 + id end }
issecretvalue = function(v) return v == SECRET_AURA end
dofile("Modules/Reminders.lua")
issecretvalue = nil
-- The food icon's own position, from before the reminders shared a bar.
ScarletUI.db.global.xpFoodModule.position = { "CENTER", "CENTER", 5, 6 }
ScarletUI:SetupXPFood() -- this harness is the Forever client
local foodIcon, foodList, reminderBar = ScarletUI.xpFoodFrame, nil, nil
for _, widget in ipairs(foodWidgets) do
    if widget.name == "ScarletUIReminders" then reminderBar = widget end
    if widget.kind == "Frame" and not rawget(widget, "name") then foodList = foodList or widget end
end
local settings = ScarletUI.db.global.xpFoodModule
-- It became the bar's position.
assert(settings.position == nil and ScarletUI.db.global.remindersPosition[3] == 5)
assert(reminderBar.point[1] == "CENTER" and reminderBar.point[4] == 5 and reminderBar.point[5] == 6)
assert(foodIcon.point[1] == "LEFT" and foodIcon.point[2] == reminderBar and foodIcon.point[4] == 0)
local function Food(event, ...) foodIcon.scripts.OnEvent(nil, event, "player", ...) end
local function Click(button) foodIcon.scripts.PostClick(foodIcon, button) end
local function Eats() return foodIcon.attributes.macrotext2 end
-- Item IDs of the list entries from the icon upward, and the highlighted one.
local function ListFoods()
    local shown, applied = {}, nil
    for _, widget in ipairs(foodWidgets) do
        if rawget(widget, "applied") and widget.shown then
            shown[#shown + 1] = widget.itemID
            if widget.applied.shown then applied = widget.itemID end
        end
    end
    return table.concat(shown, ","), applied
end
local function PickFood(itemID)
    for _, widget in ipairs(foodWidgets) do
        if rawget(widget, "applied") and widget.shown and widget.itemID == itemID then return widget.scripts.OnClick() end
    end
    error("no food button for " .. itemID)
end
-- A secure button whose right-click eats; its own OnClick is left to the template.
assert(foodIcon.name == "ScarletUIXPFood" and foodIcon.template == "SecureActionButtonTemplate")
assert(foodIcon.attributes.type2 == "macro" and foodIcon.attributes.type == nil and foodIcon.scripts.OnClick == nil)
-- The best usable food shows with its stack count.
assert(foodIcon.shown and foodIcon.itemID == 4593 and foodIcon.texture.icon == "icon4593")
assert(foodIcon.count.text == 3 and Eats() == "/use item:4593" and not foodList.shown)
-- Buffed, or an unreadable aura: hidden.
foodAura = {}; Food("UNIT_AURA"); assert(not foodIcon.shown)
foodAura = SECRET_AURA; Food("UNIT_AURA"); assert(not foodIcon.shown)
foodAura = nil; Food("UNIT_AURA"); assert(foodIcon.shown)
-- Hidden on entering combat, and nothing on the secure button changes until it ends.
Food("PLAYER_REGEN_DISABLED"); assert(not foodIcon.shown)
foodBags = { 2680 }; Food("BAG_UPDATE_DELAYED")
assert(not foodIcon.shown and foodIcon.itemID == 4593 and Eats() == "/use item:4593")
Food("PLAYER_REGEN_ENABLED"); assert(foodIcon.shown and foodIcon.itemID == 2680 and Eats() == "/use item:2680")
foodBags = { 2680, 4593, 8364 }
-- Max level does not hide it: Well Fed is more than the XP bonus.
atMax = true; Food("PLAYER_LEVEL_UP"); assert(foodIcon.shown)
atMax = false
-- Hidden while dead or a ghost, back on resurrection.
dead = true; Food("PLAYER_DEAD"); assert(not foodIcon.shown)
Food("BAG_UPDATE_DELAYED"); assert(not foodIcon.shown)
dead = false; Food("PLAYER_UNGHOST"); assert(foodIcon.shown)
-- An unlisted consumable is a food when its use spell's text says Well Fed.
foodBags = { 5000, 5001, 5002 }; Food("BAG_UPDATE_DELAYED")
assert(foodIcon.shown and foodIcon.itemID == 5000 and Eats() == "/use item:5000")
-- Text that had not loaded is asked for again, and the higher level food leads.
spellText[95002], requiredLevel[5002] = "You will become Well Fed.", 10
Food("BAG_UPDATE_DELAYED"); assert(foodIcon.itemID == 5002)
requiredLevel[5002] = 30; Food("BAG_UPDATE_DELAYED"); assert(foodIcon.itemID == 5000)
-- A Well Fed aura known only by name hides it, as Forever's by ID do.
namedAura = {}; Food("UNIT_AURA"); assert(not foodIcon.shown)
namedAura = SECRET_AURA; Food("UNIT_AURA"); assert(not foodIcon.shown)
namedAura = nil; Food("UNIT_AURA"); assert(foodIcon.shown)
foodBags = { 2680, 4593, 8364 }; Food("BAG_UPDATE_DELAYED")
-- Eating a food in the bags covers it with the Well Fed icon and a countdown to the buff.
local foodTimer, buffIcon
for _, widget in ipairs(foodWidgets) do
    if widget.kind == "Frame" then foodTimer = widget end
    buffIcon = buffIcon or widget.icon == "buff1248406"
end
assert(buffIcon)
local function Eat() Food("UNIT_SPELLCAST_SUCCEEDED", "cast", 94593) end
assert(foodTimer ~= foodList and not foodTimer.shown)
Food("UNIT_SPELLCAST_SUCCEEDED", "cast", 12345); assert(not foodTimer.shown) -- some other spell
Eat(); assert(foodTimer.shown and foodIcon.shown)
clock = clock + 3.5; foodTimer.scripts.OnUpdate(); assert(foodTimer.text.text == 7)
-- Standing up ends it: the Food aura was there and went. Before it shows, nothing does.
Food("UNIT_AURA"); assert(foodTimer.shown)
eatingAura = {}; Food("UNIT_AURA"); assert(foodTimer.shown)
eatingAura = nil; Food("UNIT_AURA"); assert(not foodTimer.shown and foodIcon.shown)
-- It ends when the time is up, and Well Fed or combat end it early.
Eat(); clock = clock + 10; foodTimer.scripts.OnUpdate(); assert(not foodTimer.shown)
Eat(); foodAura = {}; Food("UNIT_AURA"); assert(not foodTimer.shown and not foodIcon.shown)
foodAura = nil; Food("UNIT_AURA")
Eat(); Food("PLAYER_REGEN_DISABLED"); assert(not foodTimer.shown)
Eat(); assert(not foodTimer.shown) -- nothing starts in combat
Food("PLAYER_REGEN_ENABLED"); assert(foodIcon.shown and not foodTimer.shown)
-- A higher level unlocks the better food; food that is too high or absent hides the icon.
foodLevel = 30; Food("PLAYER_LEVEL_UP"); assert(foodIcon.shown and foodIcon.itemID == 8364 and Eats() == "/use item:8364")
foodBags = { 267341, 6529 }; Food("BAG_UPDATE_DELAYED"); assert(not foodIcon.shown) -- level 55 jam, a lure
foodBags = { 2680, 4593, 8364 }; Food("BAG_UPDATE_DELAYED"); assert(foodIcon.shown)
-- The list holds every usable food, best first, and highlights the one shown.
local listed, applied = ListFoods()
assert(listed == "8364,4593,2680" and applied == 8364)
-- Left-click opens and closes it; right-click (eating) leaves it alone.
local ctrl = false
IsControlKeyDown = function() return ctrl end
Click("LeftButton"); assert(foodList.shown)
Click("RightButton"); assert(foodList.shown)
Click("LeftButton"); assert(not foodList.shown)
-- Left open, it closes after a second with the mouse off the foods.
Click("LeftButton")
foodList.scripts.OnUpdate(nil, 0.6); assert(foodList.shown)
foodIcon.IsMouseOver = function() return true end
foodList.scripts.OnUpdate(nil, 5); assert(foodList.shown)
foodIcon.IsMouseOver = nil
foodList.scripts.OnUpdate(nil, 0.6); assert(foodList.shown)
foodList.scripts.OnUpdate(nil, 0.6); assert(not foodList.shown)
-- Clicking a food in the list picks it and closes the list.
Click("LeftButton"); PickFood(2680)
assert(settings.food == 2680 and foodIcon.itemID == 2680 and Eats() == "/use item:2680")
assert(not foodList.shown and select(2, ListFoods()) == 2680)
-- A picked food that has run out falls back to the best one, and returns with the food.
foodBags = { 4593, 8364 }; Food("BAG_UPDATE_DELAYED")
assert(foodIcon.itemID == 8364 and ListFoods() == "8364,4593")
foodBags = { 2680, 4593, 8364 }; Food("BAG_UPDATE_DELAYED"); assert(foodIcon.itemID == 2680)
-- Clicking the picked food again goes back to the best one.
PickFood(2680); assert(settings.food == nil and foodIcon.itemID == 8364 and Eats() == "/use item:8364")
-- Combat and the buff both close an open list.
Click("LeftButton"); Food("PLAYER_REGEN_DISABLED"); assert(not foodList.shown and not foodIcon.shown)
Food("PLAYER_REGEN_ENABLED"); assert(foodIcon.shown and not foodList.shown)
Click("LeftButton"); foodAura = {}; Food("UNIT_AURA"); assert(not foodList.shown and not foodIcon.shown)
foodAura = nil; Food("UNIT_AURA")
-- Its switch is on the Reminders page, not in the Interface group.
local remindersPage = ScarletUI:Options().args.remindersSettings
local foodOption = remindersPage.args.xpFood
assert(not remindersPage.hidden() and not foodOption.hidden() and remindersPage.args.weapon.hidden())
assert(ScarletUI:Options().args.generalSettings.args.interface.args.xpFood == nil)
foodOption.set(nil, false); assert(not foodIcon.shown)
foodOption.set(nil, true); assert(foodIcon.shown)
-- Dragging saves the bar's position, which a rerun of setup applies.
foodIcon.scripts.OnDragStop()
ScarletUI:SetupXPFood()
assert(reminderBar.point[1] == "TOPLEFT" and reminderBar.point[4] == 40 and reminderBar.point[5] == -50)
-- Only a Ctrl-left-click puts it back at its default position, without opening the list.
Click("LeftButton"); assert(reminderBar.point[1] == "TOPLEFT" and foodList.shown)
Click("LeftButton")
ctrl = true; Click("RightButton"); assert(reminderBar.point[1] == "TOPLEFT")
Click("LeftButton")
assert(reminderBar.point[1] == "LEFT" and reminderBar.point[3] == "CENTER" and reminderBar.point[4] == -18)
assert(ScarletUI.db.global.remindersPosition == nil and not foodList.shown)
ctrl = false

-- Weapon enhancements: the icon shows for a weapon with no temporary enchant
-- while the bags hold a stone, oil, or poison that fits it.
local firstWeaponWidget = #foodWidgets + 1
local mainHand, offHand, mainEnchant, offEnchant, class = 50, nil, false, false, "WARRIOR"
local expiryTimer, cancelled = nil, 0
local savedTimer = C_Timer
C_Timer = { NewTimer = function(seconds, callback)
    expiryTimer = { seconds = seconds, callback = callback, Cancel = function() cancelled = cancelled + 1 end }
    return expiryTimer
end }
GetWeaponEnchantInfo = function()
    return mainEnchant and true or false, mainEnchant or nil, nil, nil, offEnchant and true or false, offEnchant or nil
end
GetInventoryItemID = function(_, slot) return slot == 16 and mainHand or slot == 17 and offHand or nil end
UnitClass = function() return "Class", class end
-- Heavy Sharpening Stone, Instant Poison, Heavy Weightstone, Brilliant Wizard Oil; the bags have four slots.
local weaponBags = { 2871, 6947, 3241, 20749 }
foodLevel, foodBags = 40, weaponBags
foodAura = {}; Food("UNIT_AURA") -- Well Fed, so only the weapon icon is left
ScarletUI:SetupWeaponReminder()
local weaponIcon, weaponList = ScarletUI.weaponReminderFrame, nil
for index = firstWeaponWidget, #foodWidgets do
    if foodWidgets[index].kind == "Frame" then weaponList = weaponList or foodWidgets[index] end
end
local weaponSettings = ScarletUI.db.global.weaponReminderModule
local function Weapon(event) weaponIcon.scripts.OnEvent(nil, event, "player") end
local function Applies() return weaponIcon.attributes.macrotext2 end
local function WeaponItems()
    local shown = {}
    for index = firstWeaponWidget, #foodWidgets do
        local widget = foodWidgets[index]
        if rawget(widget, "applied") and widget.shown then shown[#shown + 1] = widget.itemID end
    end
    return table.concat(shown, ",")
end
local function PickWeaponItem(itemID)
    for index = firstWeaponWidget, #foodWidgets do
        local widget = foodWidgets[index]
        if rawget(widget, "applied") and widget.shown and widget.itemID == itemID then return widget.scripts.OnClick() end
    end
    error("no enhancement button for " .. itemID)
end
assert(weaponIcon.name == "ScarletUIWeaponReminder" and weaponIcon.template == "SecureActionButtonTemplate")
-- On the bar, where the hidden food icon leaves it the first place.
assert(weaponIcon.point[2] == reminderBar and weaponIcon.point[4] == 0 and reminderBar.width == 36)
-- With both shown the food comes first and the weapon moves over beside it.
foodAura, foodBags = nil, { 2680, 2871 }; Food("UNIT_AURA"); Weapon("BAG_UPDATE_DELAYED")
assert(foodIcon.shown and weaponIcon.shown)
assert(foodIcon.point[4] == 0 and weaponIcon.point[4] == 48 and reminderBar.width == 84)
foodAura, foodBags = {}, weaponBags; Food("UNIT_AURA"); Weapon("BAG_UPDATE_DELAYED")
assert(weaponIcon.point[4] == 0 and reminderBar.width == 36)
-- Dragging the weapon icon moves the shared bar too.
weaponIcon.scripts.OnDragStop(); assert(ScarletUI.db.global.remindersPosition[1] == "TOPLEFT")
ScarletUI.db.global.remindersPosition = nil
-- A sword takes the sharpening stone: not a weightstone, another class's
-- poison, or the level 45 oil.
assert(weaponIcon.shown and weaponIcon.itemID == 2871 and Applies() == "/use item:2871\n/use 16")
assert(WeaponItems() == "2871" and weaponIcon.hint:find("main hand") and not weaponList.shown)
-- A mace takes the weightstone, and at 45 the oil outranks it; a rogue's sword takes poison too.
mainHand = 51; Weapon("PLAYER_EQUIPMENT_CHANGED"); assert(weaponIcon.itemID == 3241 and WeaponItems() == "3241")
foodLevel = 45; Weapon("PLAYER_LEVEL_UP"); assert(weaponIcon.itemID == 20749 and WeaponItems() == "20749,3241")
mainHand, class = 50, "ROGUE"; Weapon("PLAYER_EQUIPMENT_CHANGED"); assert(WeaponItems() == "20749,2871,6947")
class, foodLevel = "WARRIOR", 40
-- Nothing for a fishing pole, an empty hand, or bags with nothing that fits.
mainHand = 52; Weapon("PLAYER_EQUIPMENT_CHANGED"); assert(not weaponIcon.shown)
mainHand = nil; Weapon("PLAYER_EQUIPMENT_CHANGED"); assert(not weaponIcon.shown)
mainHand, foodBags = 50, { 3241, 2680 }; Weapon("BAG_UPDATE_DELAYED"); assert(not weaponIcon.shown)
-- The better of two stones is the one shown.
foodBags = { 2871, 12404, 3241 }; Weapon("BAG_UPDATE_DELAYED")
assert(weaponIcon.shown and weaponIcon.itemID == 12404 and WeaponItems() == "12404,2871")
-- An enchanted main hand hides it, and a timer rechecks when the enchant runs out.
mainEnchant = 1800000; Weapon("UNIT_INVENTORY_CHANGED")
assert(not weaponIcon.shown and expiryTimer.seconds == 1801)
mainEnchant = false; expiryTimer.callback(); assert(weaponIcon.shown and weaponIcon.itemID == 12404)
-- Each update replaces the timer instead of stacking another.
mainEnchant = 1800000; Weapon("UNIT_INVENTORY_CHANGED"); cancelled = 0
Weapon("BAG_UPDATE_DELAYED"); assert(cancelled == 1)
-- With the main hand done, a bare off-hand weapon is next; a shield is not.
offHand = 51; Weapon("PLAYER_EQUIPMENT_CHANGED")
assert(weaponIcon.shown and weaponIcon.itemID == 3241 and Applies() == "/use item:3241\n/use 17")
assert(weaponIcon.hint:find("off hand"))
offHand = 99; Weapon("PLAYER_EQUIPMENT_CHANGED"); assert(not weaponIcon.shown)
offHand = 51; offEnchant = 60000; Weapon("UNIT_INVENTORY_CHANGED")
assert(not weaponIcon.shown and expiryTimer.seconds == 61) -- the sooner of the two
mainEnchant, offEnchant = false, false; Weapon("UNIT_INVENTORY_CHANGED"); assert(weaponIcon.shown)
-- A pick is kept per hand, and clicking it again goes back to the best.
weaponIcon.scripts.PostClick(weaponIcon, "LeftButton"); assert(weaponList.shown)
PickWeaponItem(2871)
assert(weaponSettings.items[16] == 2871 and weaponIcon.itemID == 2871 and not weaponList.shown)
mainEnchant = 1800000; Weapon("UNIT_INVENTORY_CHANGED")
assert(weaponIcon.itemID == 3241 and weaponSettings.items[17] == nil) -- the off hand has no pick
mainEnchant = false; Weapon("UNIT_INVENTORY_CHANGED"); assert(weaponIcon.itemID == 2871)
PickWeaponItem(2871); assert(weaponSettings.items[16] == nil and weaponIcon.itemID == 12404)
-- Unreadable enchants keep it quiet. The file was loaded with issecretvalue set.
local readEnchants = GetWeaponEnchantInfo
GetWeaponEnchantInfo = function() return SECRET_AURA end
Weapon("UNIT_INVENTORY_CHANGED"); assert(not weaponIcon.shown)
GetWeaponEnchantInfo = readEnchants; Weapon("UNIT_INVENTORY_CHANGED"); assert(weaponIcon.shown)
-- Hidden in combat and while dead, like the food.
Weapon("PLAYER_REGEN_DISABLED"); assert(not weaponIcon.shown)
Weapon("BAG_UPDATE_DELAYED"); assert(not weaponIcon.shown)
Weapon("PLAYER_REGEN_ENABLED"); assert(weaponIcon.shown)
dead = true; Weapon("PLAYER_DEAD"); assert(not weaponIcon.shown)
dead = false; Weapon("PLAYER_UNGHOST"); assert(weaponIcon.shown)
-- Its switch sits under the food switch on the Reminders page.
local weaponOption = ScarletUI:Options().args.remindersSettings.args.weapon
assert(not weaponOption.hidden() and weaponOption.order > foodOption.order)
weaponOption.set(nil, false); assert(not weaponIcon.shown)
weaponOption.set(nil, true); assert(weaponIcon.shown)

-- Camp items, Forever: a switch at the front of the bar flips it to a page with
-- an icon per profession for that profession's camp items in the bags.
foodBags = { 12404, 279981, 279961, 279968 } -- a stone, Basic and Journeyman kits, a First Aid Kit
ScarletUI:SetupCampReminders()
local campIcons, pageSwitch = ScarletUI.campReminderFrames, nil
for _, widget in ipairs(foodWidgets) do
    if rawget(widget, "name") == "ScarletUIRemindersPage" then pageSwitch = widget end
end
local cooking, firstAid, fishing = campIcons[1], campIcons[2], campIcons[3]
assert(#campIcons == 12 and cooking.name == "ScarletUICampCooking" and firstAid.name == "ScarletUICampFirstAid")
local function Camp(icon, event) icon.scripts.OnEvent(nil, event, "player") end
-- The buff page: the switch leads and offers the camp page; no camp icon shows.
Weapon("BAG_UPDATE_DELAYED")
assert(pageSwitch.shown and pageSwitch.point[4] == 0 and pageSwitch.texture.icon == "icon279981")
assert(weaponIcon.shown and weaponIcon.point[4] == 48 and not cooking.shown and not firstAid.shown)
pageSwitch.scripts.OnClick()
assert(ScarletUI.db.global.remindersPage == "camp" and not weaponIcon.shown and pageSwitch.texture.icon == "buff19705")
-- The higher tier kit leads; a profession with nothing in the bags has no icon.
assert(cooking.shown and cooking.itemID == 279961 and cooking.attributes.macrotext2 == "/use item:279961")
assert(cooking.point[4] == 48 and firstAid.shown and firstAid.point[4] == 96 and not fishing.shown)
assert(reminderBar.width == 132)
foodBags = { 12404, 279981 }; Camp(cooking, "BAG_UPDATE_DELAYED"); Camp(firstAid, "BAG_UPDATE_DELAYED")
assert(cooking.itemID == 279981 and not firstAid.shown and reminderBar.width == 84)
-- Combat hides the switch with the icons; another icon's layout after combat
-- does not show one still waiting for its own update.
Weapon("PLAYER_REGEN_DISABLED"); Camp(cooking, "PLAYER_REGEN_DISABLED")
assert(not pageSwitch.shown and not cooking.shown)
Weapon("PLAYER_REGEN_ENABLED"); assert(pageSwitch.shown and not cooking.shown)
Camp(cooking, "PLAYER_REGEN_ENABLED"); assert(cooking.shown)
-- Ctrl-click resets the position and keeps the page.
ScarletUI.db.global.remindersPosition = { "TOPLEFT", "TOPLEFT", 1, 2 }
ctrl = true; pageSwitch.scripts.OnClick(); ctrl = false
assert(ScarletUI.db.global.remindersPosition == nil and ScarletUI.db.global.remindersPage == "camp")
-- Back to the buffs.
pageSwitch.scripts.OnClick()
assert(ScarletUI.db.global.remindersPage == nil and weaponIcon.shown and not cooking.shown)
-- Its switch is the third on the Reminders page; off, the switch goes and the buffs stay.
local campOption = ScarletUI:Options().args.remindersSettings.args.camp
assert(not campOption.hidden() and campOption.order > weaponOption.order)
pageSwitch.scripts.OnClick(); campOption.set(nil, false)
assert(not pageSwitch.shown and weaponIcon.shown and weaponIcon.point[4] == 0 and not cooking.shown)
campOption.set(nil, true); assert(pageSwitch.shown and cooking.shown and not weaponIcon.shown)
ScarletUI.db.global.remindersPage = nil
C_Timer, GetWeaponEnchantInfo, GetInventoryItemID, UnitClass = savedTimer, nil, nil, nil
CreateFrame, IsControlKeyDown = savedCreateFrame, nil
UnitLevel, C_Container, C_Item, C_UnitAuras, IsPlayerAtEffectiveMaxLevel = savedUnitLevel, nil, nil, nil, nil
C_Spell, GetTime = savedSpell, savedGetTime
end

-- Gear set per talent specialization: the set picked on a talent tab is
-- equipped when that spec group becomes active, after combat if need be.
do
local hooks, onLoaded = {}, nil
local savedCreateFrame, savedHook, savedCombat, savedClient = CreateFrame, hooksecurefunc, InCombatLockdown, ScarletUI.GetWoWVersion
CreateFrame = function(kind, name)
    local frame = { kind = kind, name = name, events = {}, scripts = {}, generated = 0 }
    frame.SetScript = function(self, script, fn) self.scripts[script] = fn end
    frame.RegisterEvent = function(self, event) self.events[event] = true end
    frame.UnregisterEvent = function(self, event) self.events[event] = nil end
    frame.SetupMenu = function(self, generator) self.generator = generator end
    frame.GenerateMenu = function(self) self.generated = self.generated + 1 end
    return setmetatable(frame, { __index = function() return noop end })
end
hooksecurefunc = function(_, key, hook) hooks[key] = hook end
EventUtil = { ContinueOnAddOnLoaded = function(name, fn) assert(name == "Blizzard_PlayerSpells"); onLoaded = fn end }
-- Set IDs start at 0 and have gaps.
local sets, activeGroup, tab, combat, used = { [0] = "Ret", [3] = "Holy" }, 1, 1, false, {}
C_SpecializationInfo = { GetActiveSpecGroup = function() return activeGroup end }
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 0, 3 } end,
    GetEquipmentSetInfo = function(id) return sets[id] end,
    GetEquipmentSetID = function(name)
        for id, setName in pairs(sets) do if setName == name then return id end end
    end,
    UseEquipmentSet = function(id) used[#used + 1] = id end,
}
InCombatLockdown = function() return combat end
PlayerSpellsFrame = { TalentsFrame = { ActiveSpec = {}, BackgroundBorder = {}, GetTab = function() return tab end } }
dofile("Modules/SpecGearSets.lua")
-- Mists has dual specialization too, but another talent window.
ScarletUI.GetWoWVersion = function() return "MOP", 50504 end
ScarletUI:SetupSpecGearSets()
assert(ScarletUI.specGearSetEvents == nil and onLoaded == nil)
ScarletUI.GetWoWVersion = savedClient
ScarletUI:SetupSpecGearSets()
local events = ScarletUI.specGearSetEvents
assert(events.events.ACTIVE_TALENT_GROUP_CHANGED and ScarletUI.specGearSetDropdown == nil)
-- The dropdown waits for the load-on-demand talent window.
onLoaded()
local dropdown = ScarletUI.specGearSetDropdown
assert(dropdown.kind == "DropdownButton" and dropdown.name == "ScarletUISpecGearSet")
local radios = {}
dropdown.generator(dropdown, { CreateRadio = function(_, text, isSelected, setSelected, data)
    radios[#radios + 1] = { text = text, picked = function() return isSelected(data) end, pick = function() setSelected(data) end }
end })
assert(#radios == 3 and radios[1].text == "No Gear Set" and radios[2].text == "Ret" and radios[3].text == "Holy")
assert(radios[1].picked() and not radios[2].picked())
-- A pick belongs to the tab being viewed, not the active specialization.
tab = 2; radios[3].pick()
assert(ScarletUI.db.char.specGearSets[2] == "Holy" and radios[3].picked() and #used == 0)
tab = 1; assert(radios[1].picked() and not radios[3].picked())
radios[2].pick(); assert(radios[2].picked())
-- Switching tabs redraws the dropdown's text.
hooks.Refresh(); assert(dropdown.generated == 1)
local fire = events.scripts.OnEvent
activeGroup = 2; fire(events, "ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
assert(#used == 1 and used[1] == 3)
-- The event without a change of specialization equips nothing.
fire(events, "ACTIVE_TALENT_GROUP_CHANGED", 2, 2); assert(#used == 1)
-- In combat the set waits.
combat, activeGroup = true, 1
fire(events, "ACTIVE_TALENT_GROUP_CHANGED", 1, 2)
assert(#used == 1 and events.events.PLAYER_REGEN_ENABLED)
combat = false; fire(events, "PLAYER_REGEN_ENABLED")
assert(#used == 2 and used[2] == 0 and not events.events.PLAYER_REGEN_ENABLED)
-- A deleted set counts as no set.
sets[3], activeGroup, tab = nil, 2, 2
fire(events, "ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
assert(#used == 2 and radios[1].picked() and not radios[3].picked())
tab = 1; radios[1].pick(); assert(ScarletUI.db.char.specGearSets[1] == nil)
ScarletUI.db.char.specGearSets = {}
CreateFrame, hooksecurefunc, InCombatLockdown = savedCreateFrame, savedHook, savedCombat
EventUtil, C_SpecializationInfo, C_EquipmentSet, PlayerSpellsFrame = nil, nil, nil, nil
end

-- Stat display: off by default. Switched on, each role the character shows
-- lists its stats, in one panel or a panel per role, and the same stats go
-- out as a broker feed.
do
local statWidgets = {}
local function StatWidget(kind, name, parent)
    local widget = { kind = kind, name = name, parent = parent, scripts = {}, shown = true }
    widget.SetScript = function(self, script, fn) self.scripts[script] = fn end
    widget.Show = function(self) self.shown = true end
    widget.Hide = function(self) self.shown = false end
    widget.SetShown = function(self, shown) self.shown = shown and true or false end
    widget.SetParent = function(self, newParent) self.parent = newParent end
    widget.SetText = function(self, text) self.text = text end
    widget.GetStringWidth = function(self) return #(self.text or "") end
    widget.SetPoint = function(self, ...) self.point = { ... } end
    widget.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
    widget.SetSize = function(self, width, height) self.size = { width, height } end
    widget.SetWidth = function(self, width) self.size = { width, self.size and self.size[2] } end
    widget.SetTexture = function(self, texture) self.icon = texture end
    widget.CreateTexture = function() return StatWidget("Texture") end
    widget.CreateFontString = function(self) return StatWidget("FontString", nil, self) end
    widget.GetNormalTexture = function() return StatWidget("Texture") end
    statWidgets[#statWidgets + 1] = widget
    return setmetatable(widget, { __index = function() return noop end })
end
local savedCreateFrame, savedLibStub, feed = CreateFrame, LibStub, nil
CreateFrame = StatWidget
LibStub = function() return { NewDataObject = function(_, name, object) feed = object; feed.name = name; return object end } end
local SECRET, class, power, ctrl = {}, "WARRIOR", 100, false
UnitClass = function() return "Class", class end
UnitAttackPower = function() return power, 20, -5 end
GetCritChance = function() return 12.5 end
CR_HIT_MELEE, CR_HIT_SPELL = 6, 8
GetCombatRatingBonus = function(rating) return rating == 6 and 2 or 0 end
GetHitModifier = function() return 3 end
UnitAttackSpeed = function() return 2.6, 1.8 end
GetSpellBonusDamage = function(school) return school == 3 and 250 or 200 end
GetSpellBonusHealing = function() return 300 end
GetSpellCritChance = function(school) return school end
GetSpellHitModifier = function() return nil end -- Era returns nil at zero
GetManaRegen = function() return 10, 4.6 end
IsControlKeyDown = function() return ctrl end
-- 99.5 stands for a secret number; formatting one gives a secret string.
issecretvalue = function(v) return v == SECRET or v == 99.5 or v == "99.50%" end
dofile("Modules/StatDisplay.lua")
issecretvalue = nil
local statSettings = ScarletUI.db.global.statDisplay
assert(statSettings.enabled == false and statSettings.layout == "COMBINED")
ScarletUI:SetupStatDisplay() -- this harness is the Forever client
local statPanel, ticker = ScarletUI.statDisplayFrame, nil
local function Named(name)
    for _, widget in ipairs(statWidgets) do
        if widget.name == name then return widget end
    end
end
local melee, ranged, caster = Named("ScarletUIStatDisplayMelee"), Named("ScarletUIStatDisplayRanged"), Named("ScarletUIStatDisplayCaster")
for _, widget in ipairs(statWidgets) do
    if widget.scripts.OnUpdate then ticker = widget end
end
-- A role's icon, the handle its panel is dragged by.
local function Handle(section)
    for _, widget in ipairs(statWidgets) do
        if widget.kind == "Button" and widget.parent == section then return widget end
    end
end
-- A role's visible label = value rows, top to bottom.
local function Rows(section)
    local rows = {}
    for _, widget in ipairs(statWidgets) do
        if widget.kind == "FontString" and widget.parent == section and widget.shown and widget.point[1] ~= "LEFT" then
            rows[#rows + 1] = widget.text
        end
    end
    return table.concat(rows, "|")
end
local function Tick() ticker.scripts.OnUpdate(nil, 1) end
-- Off: nothing shows and broker displays have no feed to list.
assert(statPanel.name == "ScarletUIStatDisplay" and not statPanel.shown and not melee.shown and feed == nil)
-- Its settings are their own page, led by the switch, and no longer part of Interface.
local statPage = ScarletUI:Options().args.statDisplaySettings
local roles = statPage.args.roles.args
assert(not statPage.hidden() and statPage.args.enabled.order == 0 and not statPage.args.enabled.get())
assert(ScarletUI:Options().args.generalSettings.args.interface.args.statDisplay == nil)
statPage.args.enabled.set(nil, true)
-- A warrior starts with melee only: buffs count toward attack power, hit adds rating and modifier.
assert(statPanel.shown and melee.shown and not ranged.shown and not caster.shown)
assert(roles.melee.get() and not roles.ranged.get() and not roles.caster.get())
assert(Handle(melee).texture.icon == "Interface\\Icons\\Ability_MeleeDamage")
assert(Rows(melee) == "Attack Power|115|Crit Chance|12.50%|Hit Chance|5.00%|Attack Speed|2.60 / 1.80")
assert(feed.name == "ScarletUI Stats" and feed.text == "AP 115  Crit 12.50%  Hit 5.00%  Speed 2.60 / 1.80")
-- A role is sized to its rows and the panel to its roles; both follow stat changes.
assert(melee.size[2] == 12 * 2 + 28 + 8 + 4 * 16 and statPanel.size[1] == melee.size[1] and statPanel.size[2] == melee.size[2])
power = 200; ticker.scripts.OnUpdate(nil, 0.2); assert(feed.text:find("AP 115", 1, true))
ticker.scripts.OnUpdate(nil, 0.4); assert(feed.text:find("AP 215", 1, true))
-- In combat the client hands out secret values. A stat that needs arithmetic keeps its
-- last readable text; a single value is shown live, while the feed keeps the readable one.
power, GetCritChance = SECRET, function() return 99.5 end; Tick()
assert(Rows(melee) == "Attack Power|215|Crit Chance|99.50%|Hit Chance|5.00%|Attack Speed|2.60 / 1.80")
assert(feed.text == "AP 215  Crit 12.50%  Hit 5.00%  Speed 2.60 / 1.80")
power, GetCritChance = 100, function() return 12.5 end; Tick()
assert(Rows(melee) == "Attack Power|115|Crit Chance|12.50%|Hit Chance|5.00%|Attack Speed|2.60 / 1.80")
-- Roles are switched per character. With several on, the one panel holds them side by side.
roles.caster.set(nil, true)
assert(caster.shown and caster.parent == statPanel and caster.point[2] == statPanel and caster.point[4] == melee.size[1])
assert(statPanel.size[1] == melee.size[1] + caster.size[1] and statPanel.size[2] == caster.size[2])
-- Caster: the best school, healing when it differs, and mana per 5 seconds while casting.
assert(Rows(caster) == "Spell Power|250|Healing|300|Crit Chance|7.00%|Hit Chance|0.00%|MP5 (Casting)|23")
assert(feed.text == "AP 115  Crit 12.50%  Hit 5.00%  Speed 2.60 / 1.80  |  SP 250  Heal 300  Crit 7.00%  Hit 0.00%  MP5 23")
GetSpellBonusHealing = function() return 250 end; Tick()
assert(Rows(caster) == "Spell Power|250|Crit Chance|7.00%|Hit Chance|0.00%|MP5 (Casting)|23")
-- A stat that was never readable (secret, or a function this client lacks) has no row, and the gap closes.
UnitRangedAttackPower = function() return SECRET, 0, 0 end
roles.ranged.set(nil, true)
assert(Rows(ranged) == "Hit Chance|3.00%" and ranged.size[2] == 12 * 2 + 28 + 8 + 1 * 16)
assert(ranged.point[4] == melee.size[1] and caster.point[4] == melee.size[1] + ranged.size[1])
UnitRangedAttackPower = nil
roles.ranged.set(nil, false)
assert(not ranged.shown and ScarletUI.db.char.statDisplay.roles.RANGED == false and caster.point[4] == melee.size[1])
-- Dragging any icon moves the one panel and saves its position, which a rerun of setup applies.
Handle(caster).scripts.OnDragStop()
ScarletUI:SetupStatDisplay()
assert(statPanel.point[1] == "TOPLEFT" and statPanel.point[4] == 40 and statSettings.position)
-- Only a Ctrl-click puts it back.
Handle(melee).scripts.OnClick(); assert(statPanel.point[1] == "TOPLEFT")
ctrl = true; Handle(melee).scripts.OnClick(); ctrl = false
assert(statPanel.point[1] == "CENTER" and statSettings.position == nil)
-- Separate panels: each role stands alone with its own border and position.
statPage.args.layout.set(nil, "SPLIT")
assert(not statPanel.shown and melee.shown and caster.shown and rawget(melee, "parent") == UIParent and melee.border.shown)
assert(melee.point[1] == "CENTER" and melee.point[5] == 130 and caster.point[5] == -130)
Handle(caster).scripts.OnDragStop()
assert(statSettings.positions.CASTER[1] == "TOPLEFT" and statSettings.positions.MELEE == nil and statSettings.position == nil)
-- The refresh leaves a separate panel where it is: a drag may be in progress.
caster.point = nil; Tick(); assert(rawget(caster, "point") == nil)
ScarletUI:SetupStatDisplay(); assert(caster.point[1] == "TOPLEFT" and caster.point[4] == 40 and melee.point[1] == "CENTER")
ctrl = true; Handle(caster).scripts.OnClick(); ctrl = false
assert(caster.point[1] == "CENTER" and statSettings.positions.CASTER == nil)
statPage.args.layout.set(nil, "COMBINED")
assert(statPanel.shown and melee.parent == statPanel and not melee.border.shown and caster.point[2] == statPanel)
-- Stacked vertically, the one panel holds the roles one above another, all as
-- wide as the widest so the value columns line up. Separate panels ignore it.
local meleeWidth, casterWidth = melee.size[1], caster.size[1]
assert(statPage.args.orientation.get() == "HORIZONTAL" and not statPage.args.orientation.disabled())
statPage.args.orientation.set(nil, "VERTICAL")
assert(caster.point[4] == 0 and caster.point[5] == -melee.size[2])
assert(statPanel.size[1] == math.max(meleeWidth, casterWidth) and statPanel.size[2] == melee.size[2] + caster.size[2])
assert(melee.size[1] == statPanel.size[1] and caster.size[1] == statPanel.size[1])
statPage.args.layout.set(nil, "SPLIT")
assert(statPage.args.orientation.disabled() and melee.size[1] == meleeWidth and caster.size[1] == casterWidth)
statPage.args.layout.set(nil, "COMBINED")
statPage.args.orientation.set(nil, "HORIZONTAL")
assert(caster.point[4] == meleeWidth and caster.point[5] == 0 and melee.size[1] == meleeWidth)
assert(statPanel.size[1] == meleeWidth + casterWidth and statPanel.size[2] == caster.size[2])
-- A character that never switched a role shows its class's.
ScarletUI.db.char.statDisplay.roles = {}
class = "MAGE"; Tick()
assert(caster.shown and not melee.shown and feed.icon == "Interface\\Icons\\Spell_Holy_MagicalSentry" and caster.point[4] == 0)
class = "HUNTER"; Tick(); assert(ranged.shown and not caster.shown and not melee.shown)
class = "WARRIOR"; Tick(); assert(melee.shown and not ranged.shown)
-- Switched off, everything hides, the feed empties, and the refresh stops.
statPage.args.enabled.set(nil, false)
assert(not statPanel.shown and not melee.shown and feed.text == "" and not ticker.shown)
CreateFrame, LibStub, IsControlKeyDown, UnitClass = savedCreateFrame, savedLibStub, nil, nil
end

-- Era, TBC, and Mists also load the Classic-UI-only modules and their old settings keys.
C_Container = {}
dofile("Modules/Bag.lua")
dofile("Modules/Nameplates.lua")
assert(ScarletUI.defaults.global.bagModule.enabled and ScarletUI.originalUIDefaults.global.bagModule)
assert(ScarletUI.defaults.global.nameplatesModule.enabled and ScarletUI.originalUIDefaults.global.nameplatesModule)
assert(ScarletUI.defaults.char.priorityDebuffs == "" and StaticPopupDialogs.SCARLET_PURCHASE_BANK_SLOT)
ScarletUI.db.global.bagModule = ScarletUI.defaults.global.bagModule
ScarletUI.db.global.nameplatesModule = ScarletUI.defaults.global.nameplatesModule
ScarletUI.lightWeightMode = false
-- These tests run as Forever, which only gets the threat numbers; check the Classic page here.
local foreverVersion = ScarletUI.GetWoWVersion
ScarletUI.GetWoWVersion = function() return "VANILLA", 11509 end
local legacyOptions = ScarletUI:Options()
assert(legacyOptions.args.bagModuleSettings and legacyOptions.args.nameplatesModuleSettings)
-- Sorting joins the Classic Bag page and stays visible when ElvUI hides the custom bag groups.
local legacyBagPage = legacyOptions.args.bagModuleSettings
assert(legacyBagPage.name == "Bags" and legacyBagPage.args.sortSettings and legacyBagPage.hidden == nil)
ScarletUI.lightWeightMode = true
assert(legacyBagPage.args.generalSettings.hidden() and legacyBagPage.args.bankSettings.hidden() and legacyBagPage.args.enabled.hidden())
ScarletUI.lightWeightMode = false
assert(not legacyBagPage.args.enabled.hidden() and legacyOptions.args.nameplatesModuleSettings.args.enabled)
-- The debuff toggle once wrote the buff setting.
local auraOptions = legacyOptions.args.nameplatesModuleSettings.args.auras.args
ScarletUI.ReapplySettingsToAuraIcons = noop
auraOptions.debuffs.args.track.set(nil, false)
assert(not ScarletUI.db.global.nameplatesModule.debuffTracker.track and ScarletUI.db.global.nameplatesModule.buffTracker.track)
auraOptions.debuffs.args.track.set(nil, true)
ScarletUI.GetWoWVersion = foreverVersion
calls = {}
local legacyMethods = { "SetupBags", "SetupBank", "SetupNameplates" }
for _, name in ipairs(setupMethods) do ScarletUI[name] = noop end
for _, name in ipairs(legacyMethods) do
    ScarletUI[name] = function() calls[name] = true end
end
ScarletUI:Setup()
for _, name in ipairs(legacyMethods) do assert(calls[name], name) end
-- The prototype settings window flattens option groups into rows.
dofile("Modules/SettingsFrame.lua")
local settingsGroup = { args = {
    alpha = { type = "toggle", name = "Alpha", order = 2 },
    beta = { type = "toggle", name = "Beta", desc = "alpha", order = 1, hidden = function() return true end },
    group = { type = "group", name = "Group", order = 3, disabled = function() return true end,
        args = { gamma = { type = "range", name = "Gamma" } } },
    empty = { type = "group", name = "Empty", order = 4, args = { delta = { type = "toggle", name = "Delta", hidden = true } } },
} }
local rows = ScarletUI:CollectSettings(settingsGroup)
-- Loose settings share an untitled card; each child group gets its own.
assert(#rows == 4 and rows[1].card == "" and rows[2].option.name == "Alpha" and not rows[2].disabled)
assert(rows[3].card == "Group" and rows[4].option.name == "Gamma" and rows[4].disabled)
rows = ScarletUI:CollectSettings(settingsGroup, "gam")
assert(#rows == 2 and rows[1].card == "Group" and rows[2].option.name == "Gamma")
-- A page's master switch turns its toggles off and later restores them.
local pageState = { alpha = true, beta = false, mode = "END" }
local function PageToggle(key)
    return { type = "toggle", name = key, get = function() return pageState[key] end,
        set = function(_, value) pageState[key] = value end }
end
local masterPage = { id = "testPage", groups = { { args = {
    alpha = PageToggle("alpha"), beta = PageToggle("beta"),
    mode = { type = "select", name = "mode", values = { OFF = "Off", END = "End" },
        get = function() return pageState.mode end, set = function(_, value) pageState.mode = value end },
} } } }
assert(ScarletUI:IsSettingsPageEnabled("testPage"))
ScarletUI:SetSettingsPageEnabled(masterPage, false)
assert(not ScarletUI:IsSettingsPageEnabled("testPage"))
assert(pageState.alpha == false and pageState.beta == false and pageState.mode == "OFF")
ScarletUI:SetSettingsPageEnabled(masterPage, true)
assert(ScarletUI:IsSettingsPageEnabled("testPage"))
assert(pageState.alpha == true and pageState.beta == false and pageState.mode == "END")
-- Numbered CVar options collapse into one row per CVar.
rows = ScarletUI:CollectSettings({ args = {
    searchField = { type = "input", name = "" },
    label1 = { type = "description", name = "nameplateShowAll" }, input1 = { type = "input", name = "" },
    label2 = { type = "description", name = "autoLootDefault", hidden = function() return true end },
} }, "showall")
assert(#rows == 2 and rows[1].card == "Overrides" and rows[2].cvar.input.type == "input")
assert(#ScarletUI:CollectSettings(settingsGroup, "zzz") == 0)
-- Gimmicks: the Seal Slots rules (from the standalone addon's tests) and the
-- Windfury combat log rule.
dofile("Modules/Gimmicks.lua")
do
    local ns = ScarletUI.Gimmicks.SealSlots
    local COMMAND, RIGHTEOUSNESS = "Seal of Command", "Seal of Righteousness"

    -- Three swings stack a seal; the fourth stays at three.
    local state = {}
    for i = 1, 4 do assert(ns.Swing(state, COMMAND, i) == nil) end
    assert(state.stacks == 3 and state.seal == COMMAND)

    -- A swing with another seal spends them and stores the new seal once.
    local seal, spent = ns.Swing(state, RIGHTEOUSNESS, 5)
    assert(seal == COMMAND and spent == 3)
    assert(state.stacks == 1 and state.seal == RIGHTEOUSNESS)

    -- Stacks that ran out are not spent.
    assert(ns.Swing(state, COMMAND, 5 + ns.STACK_TIME) == nil)
    assert(state.stacks == 1 and state.seal == COMMAND)

    -- No seal known: nothing stored or spent.
    assert(ns.Swing(state, nil, 30) == nil and state.stacks == 1)

    local hit, crit, miss, cast = { amount = 1 }, { amount = 2, crit = true }, { miss = "MISS" }, { cast = true }

    -- Procs: one per stack at most, in order.
    local procs = ns.Procs({ hit, crit, hit, hit }, 3)
    assert(#procs == 3 and procs[2] == crit)
    assert(#ns.Procs({}, 3) == 0)

    -- A miss is a stack's outcome too.
    procs = ns.Procs({ miss, crit }, 3)
    assert(#procs == 2 and procs[1].miss == "MISS" and procs[2] == crit)

    -- A cast's own result (the new seal's proc, a Judgement) is not a stack's.
    procs = ns.Procs({ hit, cast, crit, hit, hit }, 3)
    assert(#procs == 3 and procs[1] == hit and procs[2] == hit and procs[3] == hit)
    assert(#ns.Procs({ cast, miss }, 3) == 0)

    -- Righteousness adds one plain hit of its own to the swing.
    procs = ns.Procs({ miss, hit, crit }, 3, true)
    assert(#procs == 2 and procs[1] == miss and procs[2] == crit)
    assert(#ns.Procs({ hit }, 3, true) == 0)

    -- Tiers.
    assert(ns.Tier(3, {}) == "BUST")
    assert(ns.Tier(3, { miss, miss }) == "BUST")
    assert(ns.Tier(3, { hit, crit }) == "WIN")
    assert(ns.Tier(3, { hit, crit, miss }) == "WIN")
    assert(ns.Tier(2, { crit, crit }) == "WIN")
    assert(ns.Tier(3, { hit, crit, hit }) == "JACKPOT")
    assert(ns.Tier(3, { crit, crit, crit }) == "MEGA")

    -- Record: most crits, then most hits, then newest; busts are only counted.
    local db = {}
    ns.Record(db, { crits = 0, hits = 2, id = "a" }, "WIN")
    ns.Record(db, { crits = 1, hits = 1, id = "b" }, "WIN")
    ns.Record(db, { crits = 0, hits = 0, id = "bust" }, "BUST")
    ns.Record(db, { crits = 0, hits = 3, id = "c" }, "JACKPOT")
    ns.Record(db, { crits = 1, hits = 1, id = "d" }, "WIN")
    local order = {}
    for i, entry in ipairs(db.best) do order[i] = entry.id end
    assert(table.concat(order) == "dbca", table.concat(order))
    assert(db.tally.spins == 5 and db.tally.WIN == 3 and db.tally.BUST == 1 and db.tally.JACKPOT == 1)
    for _ = 1, 20 do ns.Record(db, { crits = 3, hits = 3 }, "MEGA") end
    assert(#db.best == ns.BEST and db.best[ns.BEST].crits == 3)

    -- Windfury. Log() builds an event as CombatLogGetCurrentEventInfo returns it.
    local WF = ScarletUI.Gimmicks.WindfuryEvent
    local function Log(subevent, ...) return 0, subevent, false, "Player-1", "Me", 0, 0, "Creature-1", "Boar", 0, 0, ... end
    local wf, hit, fresh = {}
    -- The totem: extra attacks, then that many main-hand swings.
    hit, fresh = WF(wf, 10, Log("SPELL_EXTRA_ATTACKS", 8516, "Windfury Attack", 1, 1))
    assert(hit == nil and fresh)
    assert(WF(wf, 10, Log("SWING_DAMAGE", 250, 0, 1, nil, nil, nil, true, nil, nil, true)) == nil) -- off hand
    hit, fresh = WF(wf, 10, Log("SWING_DAMAGE", 250, 0, 1, nil, nil, nil, true, nil, nil, nil))
    assert(hit.amount == 250 and hit.crit and not fresh)
    assert(WF(wf, 10.2, Log("SWING_DAMAGE", 100, 0, 1)) == nil) -- an ordinary swing
    WF(wf, 20, Log("SPELL_EXTRA_ATTACKS", 8516, "Windfury Attack", 1, 1))
    assert(WF(wf, 21.5, Log("SWING_MISSED", "DODGE")) == nil) -- too late to be the extra one
    WF(wf, 30, Log("SPELL_EXTRA_ATTACKS", 8516, "Windfury Attack", 1, 1))
    assert(WF(wf, 30.4, Log("SWING_MISSED", "PARRY", nil)).miss == "PARRY")
    -- The weapon in TBC and Mists: its own Windfury Attack hits, one proc.
    hit, fresh = WF(wf, 40, Log("SPELL_DAMAGE", 25504, "Windfury Attack", 1, 400, 0, 1, nil, nil, nil, nil))
    assert(hit.amount == 400 and not hit.crit and fresh)
    hit, fresh = WF(wf, 40, Log("SPELL_MISSED", 25504, "Windfury Attack", 1, "DODGE"))
    assert(hit.miss == "DODGE" and not fresh)
    assert(WF(wf, 40.1, Log("SWING_DAMAGE", 100, 0, 1)) == nil) -- no swings owed
    -- Extra attacks paid in Windfury Attack hits leave no swing owed.
    WF(wf, 50, Log("SPELL_EXTRA_ATTACKS", 8516, "Windfury Attack", 1, 2))
    assert(WF(wf, 50, Log("SPELL_DAMAGE", 25504, "Windfury Attack", 1, 800, 0, 1, nil, nil, nil, true)).crit)
    assert(WF(wf, 50, Log("SPELL_DAMAGE", 25504, "Windfury Attack", 1, 400, 0, 1)).amount == 400)
    assert(WF(wf, 50.2, Log("SWING_DAMAGE", 100, 0, 1)) == nil)
    -- Windfury's buffs and other spells are not procs.
    assert(WF(wf, 60, Log("SPELL_AURA_APPLIED", 8515, "Windfury Totem", 8, "BUFF")) == nil)
    assert(WF(wf, 60, Log("SPELL_DAMAGE", 1752, "Sinister Strike", 1, 90)) == nil)

    -- Both gimmicks are off by default; Seal Slots only shows where it is set up.
    local page = ScarletUI:Options().args.gimmicksSettings
    assert(not page.args.sealSlots.get() and not page.args.windfury.get() and page.args.sound.get())    ScarletUI.sealSlotsSupported = nil
    assert(page.args.sealSlots.hidden() and not page.args.windfury.hidden)
    -- With the standalone addon loaded the switch still shows: its saved spins
    -- are taken over (not its always-shown setting, which this one lacks),
    -- and turning the switch on turns that addon off.
    local oldVersion, oldLoaded, oldAddOns = ScarletUI.GetWoWVersion, ScarletUI.IsAddOnLoaded, C_AddOns
    ScarletUI.GetWoWVersion = function() return "FOREVER" end
    ScarletUI.IsAddOnLoaded = function(_, name) return name == "SealSlots" end
    local disabled
    C_AddOns = { DisableAddOn = function(name, character) disabled = { name, character } end }
    SealSlotsDB = { best = { { crits = 1, hits = 1 } }, show = true }
    ScarletUI:SetupSealSlots()
    local slots = ScarletUI.db.global.gimmicks.sealSlots
    assert(not page.args.sealSlots.hidden() and slots.best == SealSlotsDB.best and slots.show == nil and not disabled)
    page.args.sealSlots.set(nil, true)
    assert(slots.enabled and disabled[1] == "SealSlots" and disabled[2] == nil)
    slots.enabled, slots.best, slots.imported = false, nil, nil
    ScarletUI.sealSlotsSupported, ScarletUI.sealSlotsStandalone, SealSlotsDB = nil, nil, nil
    ScarletUI.GetWoWVersion, ScarletUI.IsAddOnLoaded, C_AddOns = oldVersion, oldLoaded, oldAddOns
end

-- Transmog: a switch per saved outfit. Switching is protected, so each row
-- carries the attributes of Blizzard's "outfit" secure action instead.
do
    local oldRetail, oldPrint, protected = ScarletUI.retail, ScarletUI.Print, false
    C_TransmogOutfitInfo = {
        GetOutfitsInfo = function() return {
            { outfitID = 7, name = "Outfit 1", icon = 123, situationCategories = {}, playerFacingOutfitIndex = 1 },
            { outfitID = 9, name = "Outfit 2", icon = 456, situationCategories = { "Mounted" }, playerFacingOutfitIndex = 2 },
        } end,
        GetActiveOutfitID = function() return 7 end,
        ChangeToOutfit = function() protected = true end,
        ClearOutfit = function() protected = true end,
    }
    ScarletUI.retail = false
    assert(ScarletUI:Options().args.transmogSettings.hidden)
    ScarletUI.retail = true
    local outfits = ScarletUI:Options().args.transmogSettings.args
    assert(outfits.outfit7.get() and not outfits.outfit9.get())
    assert(outfits.outfit7.desc == nil and outfits.outfit9.desc == "Situations: Mounted." and outfits.outfit9.name == "|T456:16|t Outfit 2")
    local secure = outfits.outfit9.arg.secure
    assert(secure.type == "outfit" and secure["outfit-index"] == 2 and secure.action == nil)
    ScarletUI.Print = noop
    outfits.outfit9.set(nil, true)
    assert(not protected)
    ScarletUI.Print = oldPrint
    C_TransmogOutfitInfo.GetOutfitsInfo = function() end
    assert(ScarletUI:Options().args.transmogSettings.args.none)
    ScarletUI.retail, C_TransmogOutfitInfo = oldRetail, nil
end

print("PASS: remaining settings, setup dispatcher, Era/TBC/Mists legacy modules, shared Era presets, and Edit Mode installation")

-- Run last: the prompt regression loads real AceDB in its own addon setup.
dofile("tests/edit-mode-prompts.lua")

dofile("tests/cvars.lua")

-- Replaces the ScarletUI global, so it runs after everything else.
dofile("tests/nameplates.lua")

-- Also replaces the ScarletUI global.
dofile("tests/bank-cache.lua")
