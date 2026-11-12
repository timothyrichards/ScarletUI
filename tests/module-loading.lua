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
    "SetupTidyIcons", "SetupSpellCostPercent", "SetupZoneLevels", "SetupFiveSecondRule", "SetupFishing", "SetupXPFood", "SetupStatDisplay", "SetupCraftProfit", "SetupExpandCharacterInfo", "SetupGameMenuButtons",
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
-- Crate fill costs: every priced bundle gets its total, the cheapest turns green, once.
local itemNames = { "Vision Dust", "Greater Mystic Essence" } -- the shard's name loads later
local auctionPrices = { 100, 400, 9999 }
C_Item = { GetItemNameByID = function(id) return itemNames[id] end }
GetMoneyString = function(copper) return copper .. "c" end
Auctionator = { Database = { db = { ["1"] = {}, ["2"] = {}, ["3"] = {}, ["p:7"] = {} } }, API = { v1 = {
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
-- The crate setting sits on the Auction Prices page with Craft Profit (Forever only).
local auctionPage = ScarletUI:Options().args.auctionSettings
local crateOption = auctionPage.args.crateFillCosts
assert(ScarletUI:Options().args.generalSettings.args.interface.args.crateFillCosts == nil)
assert(not auctionPage.disabled() and crateOption.get() and not crateOption.desc():find("Requires"))
assert(auctionPage.args.craftProfit.hidden() and auctionPage.args.craftProfit.get())
Auctionator, C_Item = nil, nil
-- Without Auctionator the page is grayed out, reads off, and says what it needs.
assert(auctionPage.disabled() and not crateOption.get() and not auctionPage.args.craftProfit.get())
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

-- XP food reminder: the icon shows while the XP buff is missing and the bags
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
C_UnitAuras = { GetPlayerAuraBySpellID = function(id) return id == 1249523 and foodAura or nil end }
UnitLevel = function() return foodLevel end
IsPlayerAtEffectiveMaxLevel = function() return atMax end
C_Container = { GetContainerNumSlots = function() return 4 end,
    GetContainerItemID = function(bag, slot) return bag == 0 and foodBags[slot] or nil end }
C_Item = { GetItemInfoInstant = function(id) return id, nil, nil, nil, "icon" .. id end,
    GetItemCount = function(id) return id % 10 end }
issecretvalue = function(v) return v == SECRET_AURA end
dofile("Modules/XPFood.lua")
issecretvalue = nil
ScarletUI:SetupXPFood() -- this harness is the Forever client
local foodIcon, foodList = ScarletUI.xpFoodFrame, nil
for _, widget in ipairs(foodWidgets) do
    if widget.kind == "Frame" then foodList = widget end
end
local settings = ScarletUI.db.global.xpFoodModule
local function Food(event) foodIcon.scripts.OnEvent(nil, event, "player") end
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
-- Hidden at max level.
atMax = true; Food("PLAYER_LEVEL_UP"); assert(not foodIcon.shown)
atMax = false
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
-- Its switch is in the Interface group.
local foodOption = ScarletUI:Options().args.generalSettings.args.interface.args.xpFood
assert(not foodOption.hidden())
foodOption.set(nil, false); assert(not foodIcon.shown)
foodOption.set(nil, true); assert(foodIcon.shown)
-- Dragging saves the position, which a rerun of setup applies.
foodIcon.scripts.OnDragStop()
ScarletUI:SetupXPFood()
assert(foodIcon.point[1] == "TOPLEFT" and foodIcon.point[4] == 40 and foodIcon.point[5] == -50)
-- Only a Ctrl-left-click puts it back at its default position, without opening the list.
Click("LeftButton"); assert(foodIcon.point[1] == "TOPLEFT" and foodList.shown)
Click("LeftButton")
ctrl = true; Click("RightButton"); assert(foodIcon.point[1] == "TOPLEFT")
Click("LeftButton")
assert(foodIcon.point[1] == "CENTER" and settings.position == nil and not foodList.shown)
CreateFrame, IsControlKeyDown = savedCreateFrame, nil
UnitLevel, C_Container, C_Item, C_UnitAuras, IsPlayerAtEffectiveMaxLevel = savedUnitLevel, nil, nil, nil, nil
end

-- Stat display: off by default. Switched on, a panel lists the stats for the
-- character's role and the same line goes out as a broker feed.
do
local statWidgets = {}
local function StatWidget(kind, name)
    local widget = { kind = kind, name = name, scripts = {}, shown = true }
    widget.SetScript = function(self, script, fn) self.scripts[script] = fn end
    widget.Show = function(self) self.shown = true end
    widget.Hide = function(self) self.shown = false end
    widget.SetShown = function(self, shown) self.shown = shown and true or false end
    widget.SetText = function(self, text) self.text = text end
    widget.GetStringWidth = function(self) return #(self.text or "") end
    widget.SetPoint = function(self, ...) self.point = { ... } end
    widget.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 40, -50 end
    widget.SetSize = function(self, width, height) self.size = { width, height } end
    widget.SetTexture = function(self, texture) self.icon = texture end
    widget.CreateTexture = function() return StatWidget("Texture") end
    widget.CreateFontString = function() return StatWidget("FontString") end
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
issecretvalue = function(v) return v == SECRET end
dofile("Modules/StatDisplay.lua")
issecretvalue = nil
assert(ScarletUI.defaults.global.statDisplay.enabled == false)
ScarletUI:SetupStatDisplay() -- this harness is the Forever client
local statPanel, statHandle = ScarletUI.statDisplayFrame, nil
for _, widget in ipairs(statWidgets) do
    if widget.kind == "Button" then statHandle = widget end
end
-- The visible label = value rows, top to bottom.
local function Rows()
    local rows = {}
    for _, widget in ipairs(statWidgets) do
        if widget.kind == "FontString" and widget.shown and widget.point and widget.point[1] ~= "LEFT" then
            rows[#rows + 1] = widget.text
        end
    end
    return table.concat(rows, "|")
end
local function Tick() statPanel.scripts.OnUpdate(nil, 1) end
-- Off: no panel and no feed for broker displays to list.
assert(statPanel.name == "ScarletUIStatDisplay" and not statPanel.shown and feed == nil)
local statOption = ScarletUI:Options().args.generalSettings.args.interface.args.statDisplay
assert(not statOption.hidden() and not statOption.get())
statOption.set(nil, true)
-- A warrior starts on melee: buffs count toward attack power, hit adds rating and modifier.
assert(statPanel.shown and statHandle.texture.icon == "Interface\\Icons\\Ability_MeleeDamage")
assert(Rows() == "Attack Power|115|Crit Chance|12.50%|Hit Chance|5.00%|Attack Speed|2.60 / 1.80")
assert(feed.name == "ScarletUI Stats" and feed.text == "AP 115  Crit 12.50%  Hit 5.00%  Speed 2.60 / 1.80")
-- The panel is sized to its rows, and follows stat changes while it shows.
assert(statPanel.size[2] == 12 * 2 + 28 + 8 + 4 * 16)
power = 200; statPanel.scripts.OnUpdate(nil, 0.2); assert(feed.text:find("AP 115", 1, true))
statPanel.scripts.OnUpdate(nil, 0.4); assert(feed.text:find("AP 215", 1, true))
-- A secret value or a function this client lacks drops that row and closes the gap.
power, GetCritChance = SECRET, nil; Tick()
assert(Rows() == "Hit Chance|5.00%|Attack Speed|2.60 / 1.80" and feed.text == "Hit 5.00%  Speed 2.60 / 1.80")
assert(statPanel.size[2] == 12 * 2 + 28 + 8 + 2 * 16)
power, GetCritChance = 100, function() return 12.5 end
-- Clicking the icon steps through the roles, saved for the character; ranged has no API here.
statHandle.scripts.OnClick(); assert(ScarletUI.db.char.statDisplay.set == "RANGED" and Rows() == "Hit Chance|3.00%")
statHandle.scripts.OnClick(); assert(ScarletUI.db.char.statDisplay.set == "CASTER")
-- Caster: the best school, healing when it differs, and mana per 5 seconds while casting.
assert(Rows() == "Spell Power|250|Healing|300|Crit Chance|7.00%|Hit Chance|0.00%|MP5 (Casting)|23")
GetSpellBonusHealing = function() return 250 end; Tick()
assert(Rows() == "Spell Power|250|Crit Chance|7.00%|Hit Chance|0.00%|MP5 (Casting)|23")
feed.OnClick(); assert(ScarletUI.db.char.statDisplay.set == "MELEE" and feed.text:find("AP 115", 1, true))
-- A character that never switched starts on its class's role.
ScarletUI.db.char.statDisplay.set = nil
class = "MAGE"; Tick(); assert(feed.text:find("SP 250", 1, true))
class = "HUNTER"; Tick(); assert(feed.icon == "Interface\\Icons\\Ability_Marksmanship")
class = "WARRIOR"; Tick(); assert(ScarletUI.db.char.statDisplay.set == nil and feed.text:find("AP 115", 1, true))
-- Dragging the icon saves the position, which a rerun of setup applies; Ctrl-click resets it.
statHandle.scripts.OnDragStop()
ScarletUI:SetupStatDisplay()
assert(statPanel.point[1] == "TOPLEFT" and statPanel.point[4] == 40 and ScarletUI.db.global.statDisplay.position)
ctrl = true; statHandle.scripts.OnClick()
assert(statPanel.point[1] == "CENTER" and ScarletUI.db.global.statDisplay.position == nil)
assert(ScarletUI.db.char.statDisplay.set == nil)
-- Switched off, the panel hides and the feed empties.
statOption.set(nil, false); assert(not statPanel.shown and feed.text == "")
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
print("PASS: remaining settings, setup dispatcher, Era/TBC/Mists legacy modules, shared Era presets, and Edit Mode installation")

-- Run last: the prompt regression loads real AceDB in its own addon setup.
dofile("tests/edit-mode-prompts.lua")

dofile("tests/cvars.lua")

-- Replaces the ScarletUI global, so it runs after everything else.
dofile("tests/nameplates.lua")
