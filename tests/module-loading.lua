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
    assert(options.args.generalSettings.args.modules == nil and options.args.defaultSettings == nil)
    -- Retail and Forever get a Bags page with only the sorting switch, sorting, and highlight settings.
    local bagPage = options.args.bagModuleSettings
    local bagGroups = 0
    for _ in pairs(bagPage.args) do bagGroups = bagGroups + 1 end
    assert(bagPage.name == "Bags" and bagPage.args.sortSettings and bagPage.args.highlightSettings and bagGroups == 3)
    assert(options.args.editModeSettings and options.args.actionBarTogglesSettings)
    -- Retail and Forever never load Bag.lua or Nameplates.lua, so their toggles do not exist.
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
local setupMethods = { "SetupDebugFrame", "SetupActionBarToggles", "SetupBagSort", "SetupTracking", "SetupChat", "SetupCVars",
    "SetupItemLevels",
    "SetupTidyIcons", "SetupSpellCostPercent", "SetupZoneLevels", "SetupFiveSecondRule", "SetupFishing", "SetupExpandCharacterInfo", "SetupGameMenuButtons",
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
        assert(anchors.raidFrame[1] == -722 and anchors.raidFrame[2] == 898)
        assert(anchors.partyFrame[1] == -372 and anchors.partyFrame[2] == 698)
    end
    assert(anchors.swingTimerOffHand[4] == "swingTimerMainHand" and anchors.totemBar[4] == "multiBarBottomRight")
    assert(anchors.utilityCooldowns[3] == "BOTTOM" and anchors.utilityCooldowns[4] == "essentialCooldowns")
    assert(anchors.essentialCooldowns[1] == 0 and anchors.essentialCooldowns[3] == "TOP")
    assert(anchors.swingTimerRanged[2] == 400)
    assert(anchors.partyFrame[3] == (variant == "COMPACT" and "BOTTOMLEFT" or "TOPLEFT"))
    assert(anchors.mainMenuBar[1] == 0 and anchors.mainMenuBar[2] == 22)
    assert(anchors.multiBarBottomLeft[4] == "mainMenuBar")
    assert(anchors.stanceBar[4] == "multiBarBottomRight")
    if variant == "COMPACT" then
        assert(anchors.focusFrame[4] == UIParent)
    else
        assert(anchors.focusFrame[4] == "multiBarBottomRight")
        assert(anchors.petFrame[4] == "playerFrame")
    end
    assert(anchors.playerFrame[1] == (variant == "COMPACT" and -50 or -258))
    assert(anchors.playerFrame[3] == (variant == "COMPACT" and "TOPRIGHT" or "BOTTOM"))
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
GetSpellInfo = nil

-- Bag sorting: shared on logout; Era, TBC, and Mists lack the sort direction.
local sort, unconfirmed = { SortBagsRightToLeft = false, InsertItemsLeftToRight = false }, {}
C_Container = {
    GetSortBagsRightToLeft = function() return sort.SortBagsRightToLeft end,
    SetSortBagsRightToLeft = function(on) unconfirmed.SortBagsRightToLeft = on end,
    GetInsertItemsLeftToRight = function() return sort.InsertItemsLeftToRight end,
    SetInsertItemsLeftToRight = function(on) sort.InsertItemsLeftToRight = on end,
}
dofile("Modules/BagSort.lua")
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
sort.SortBagsRightToLeft = true
Fire("PLAYER_LOGOUT")
local bagSort = ScarletUI.db.global.bagSortModule
assert(bagSort.sortBagsRightToLeft == true and bagSort.insertItemsLeftToRight == false)
bagSort.insertItemsLeftToRight = true
sort, ScarletUI.bagSortApplied = { InsertItemsLeftToRight = false }, nil
C_Container.GetSortBagsRightToLeft, C_Container.SetSortBagsRightToLeft = nil, nil
ScarletUI:SetupBagSort()
assert(sort.InsertItemsLeftToRight == true and sorting.sortBagsRightToLeft.hidden())
assert(not sorting.insertItemsLeftToRight.hidden())
C_Container = nil
assert(#shutdown == 0 and shutdown["ScarletUI-ActionBars"] and shutdown["ScarletUI-Tracking"]
    and shutdown["ScarletUI-BagSort"])
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
local microOption = ScarletUI:Options().args.generalSettings.args.interface.args.hideMicroMenuArt
assert(not microOption.hidden())
microOption.set(nil, false)
assert(MicroMenu.BackgroundArt.shown and MicroMenu.BorderArt.shown)
gamepadUI = true
bagHooks.OnShow()
assert(GamepadBagBar.shown)
ScarletUI.db.global.hideMicroMenuArt = true
MicroMenu, GamepadBagBar, InputUtil, ContainerFrameCombinedBags = nil, nil, nil, nil
assert(ScarletUI:Options().args.generalSettings.args.interface.args.hideMicroMenuArt.hidden())

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
assert(fishBar.shown and barLures == "6530,6529" and barApplied == 6530)
assert(fishCurrent.shown and fishCurrent.itemID == 6530 and fishCurrent.count.text == 5 and not fishList.shown)
-- Clicking the lure opens and closes the list; losing the pole closes it too.
fishCurrent.scripts.OnClick(); assert(fishList.shown)
fishCurrent.scripts.OnClick(); assert(not fishList.shown)
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
fishingOptions.args.autoLure.set(nil, true); assert(fishCurrent.shown and BarLures() == "6530,6529")
-- Dragging the Fishing icon saves the bar position, which a rerun of setup applies.
for _, widget in ipairs(fishWidgets) do
    if widget.scripts.OnDragStop then widget.scripts.OnDragStop() end
end
ScarletUI:SetupFishing()
assert(fishBar.point[1] == "TOPLEFT" and fishBar.point[4] == 40 and fishBar.point[5] == -50)
ScarletUI.db.global.fishingModule.position = nil
ScarletUI:SetupFishing(); assert(fishBar.point[1] == "CENTER")
CreateFrame, GetCVar, C_Container, C_Item = savedCreateFrame, savedGetCVar, nil, nil
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
calls = {}
local legacyMethods = { "SetupBags", "SetupBank", "SetupNameplates" }
for _, name in ipairs(setupMethods) do ScarletUI[name] = noop end
for _, name in ipairs(legacyMethods) do
    ScarletUI[name] = function() calls[name] = true end
end
ScarletUI:Setup()
for _, name in ipairs(legacyMethods) do assert(calls[name], name) end
print("PASS: remaining settings, setup dispatcher, Era/TBC/Mists legacy modules, shared Era presets, and Edit Mode installation")

-- Run last: the prompt regression loads real AceDB in its own addon setup.
dofile("tests/edit-mode-prompts.lua")

dofile("tests/cvars.lua")

-- Replaces the ScarletUI global, so it runs after everything else.
dofile("tests/nameplates.lua")
