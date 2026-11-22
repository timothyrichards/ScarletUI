-- Run from the addon root: lua tests/minimap-click.lua
-- Minimap button: right-click toggles the bank viewer, shift-right-click is Edit Mode.
local launcher, shift = nil, false
IsShiftKeyDown = function() return shift end
dofile("tests/client-compatibility.lua")
dofile("ScarletUI.lua")
LibStub = function()
    return {
        GetMinimapButton = function() end,
        NewDataObject = function(_, _, data) launcher = data; return data end,
        Register = function() end,
    }
end
local log, printed = {}, {}
ScarletUI.db = { global = { minimapIcon = {}, bankCacheModule = { enabled = true } } }
ScarletUI.ToggleSettingsFrame = function() log[#log + 1] = "settings" end
ScarletUI.ToggleBankViewer = function() log[#log + 1] = "bank" end
ScarletUI.OpenEditMode = function() log[#log + 1] = "editmode" end
ScarletUI.Print = function(_, msg) printed[#printed + 1] = msg end
ScarletUI:SetupMinimapIcon()

local function Click(button, shiftHeld, expected)
    log, shift = {}, shiftHeld
    launcher.OnClick(nil, button)
    assert(table.concat(log, ",") == expected, button .. " -> " .. table.concat(log, ","))
end
Click("LeftButton", false, "settings")
Click("RightButton", false, "bank")
Click("RightButton", true, "editmode")
assert(#printed == 0)

-- With the module off, right-click says so and opens nothing; shift-right-click still works.
ScarletUI.db.global.bankCacheModule.enabled = false
Click("RightButton", false, "")
assert(#printed == 1 and printed[1]:find("turned off"))
Click("RightButton", true, "editmode")

local lines = {}
launcher.OnTooltipShow({ AddLine = function(_, text) lines[#lines + 1] = text end })
assert(lines[3]:find("Right%-click") and lines[3]:find("bank"))
assert(lines[4]:find("Shift%-right%-click") and lines[4]:find("Edit Mode"))
print("minimap-click ok")

-- Bag portrait: the dropdown only takes left-button mouse events, so an overlay child takes
-- right-clicks and passes left-clicks and mouse motion through to Blizzard's menu button.
dofile("Modules/FrameTweaks.lua")
local hooks, tip, overlay = {}, {}, nil
GameTooltip = { AddLine = function(_, t) tip[#tip + 1] = t end, Show = function() end }
local portrait = { HookScript = function(_, s, f) hooks[s] = f end, SetPassThroughButtons = true }
CreateFrame = function(kind, _, parent)
    overlay = { kind = kind, parent = parent, scripts = {} }
    function overlay:SetAllPoints(f) self.points = f end
    function overlay:RegisterForClicks(...) self.clicks = { ... } end
    function overlay:SetPassThroughButtons(...) self.pass = { ... } end
    function overlay:SetPropagateMouseMotion(v) self.motion = v end
    function overlay:SetScript(s, f) self.scripts[s] = f end
    return overlay
end
ContainerFrameCombinedBags = { PortraitButton = portrait }
ScarletUI.db.global.bankCacheModule.enabled = true
local combat = true
InCombatLockdown = function() return combat end
ScarletUI.frame = { RegisterEvent = function() end }
ScarletUI.eventHandlers = {}
ScarletUI:SetupBagPortraitHooks()
assert(overlay == nil, "pass-through setters are protected; wait for combat to end")
combat = false
ScarletUI.eventHandlers.PLAYER_REGEN_ENABLED[1]("PLAYER_REGEN_ENABLED")
assert(overlay and overlay.kind == "Button" and overlay.parent == portrait and overlay.points == portrait)
assert(overlay.clicks[1] == "RightButtonUp" and #overlay.clicks == 1)
assert(overlay.pass[1] == "LeftButton" and overlay.motion == true)
assert(hooks.OnMouseDown == nil, "nothing hooks Blizzard's click path")
log = {}
overlay.scripts.OnClick(overlay, "RightButton")
assert(table.concat(log, ",") == "bank")
ScarletUI:SetupBagPortraitHooks()
assert(#ScarletUI.eventHandlers.PLAYER_REGEN_ENABLED == 1)
hooks.OnEnter()
assert(tip[1] == "Right-click: open bank")
