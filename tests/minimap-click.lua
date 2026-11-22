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

-- Bag portrait: right-click closes Blizzard's menu and toggles the bank; left-click is untouched.
dofile("Modules/FrameTweaks.lua")
local hooks, closed, tip = {}, 0, {}
GameTooltip = { AddLine = function(_, t) tip[#tip + 1] = t end, Show = function() end }
local portrait = { HookScript = function(_, s, f) hooks[s] = f end, CloseMenu = function() closed = closed + 1 end }
ContainerFrameCombinedBags = { PortraitButton = portrait }
ScarletUI.db.global.bankCacheModule.enabled = true
ScarletUI:SetupBagPortraitHooks()
log = {}
hooks.OnMouseDown(portrait, "LeftButton")
assert(#log == 0 and closed == 0)
hooks.OnMouseDown(portrait, "RightButton")
assert(table.concat(log, ",") == "bank" and closed == 1)
hooks.OnEnter()
assert(tip[1] == "Right-click: open bank")
