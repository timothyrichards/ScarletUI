-- Run from the addon root: lua tests/auto-shot-clip.lua
-- Auto Shot clipping window: the band's share of the ranged swing timer and its width.
ScarletUI = { db = { global = { autoShotClip = true } } }
dofile("Modules/FrameTweaks.lua")
local Share = ScarletUI.AutoShotClip
local function Near(a, b) return math.abs(a - b) < 1e-9 end

assert(Near(Share(2.0, 0), 0.25))            -- 0.5s of a 2.0s swing
assert(Near(Share(3.0), 0.5 / 3))            -- no haste reading
assert(Near(Share(1.5, 50), 0.5 / 1.5 / 1.5)) -- 50% haste: 0.333s windup
assert(Share(0.4, 0) == 1)                   -- never wider than the bar
assert(Share(nil, 0) == 0 and Share(0, 0) == 0) -- no ranged weapon

-- The band sits on the ranged bar's right end, follows the swing and the toggle.
local band, scripts, hooks = {}, {}, {}
local bar = {
    GetWidth = function() return 400 end,
    HookScript = function(_, name, fn) hooks[name] = fn end,
    CreateTexture = function()
        return setmetatable(band, { __index = {
            SetColorTexture = function() end, SetPoint = function() end,
            SetWidth = function(t, w) t.width = w end,
            SetShown = function(t, on) t.shown = on end,
        } })
    end,
}
SwingTimerRangedFrame = { StatusBar = bar }
Enum = { PlayerSwingType = { MainHand = 0, Ranged = 2 } }
local ranged, haste = 2.0, 0
UnitClass = function() return "Hunter", "HUNTER" end
UnitAttackSpeed = function() return 1.8, nil, ranged end
GetRangedHaste = function() return haste, 0 end
CreateFrame = function()
    local f = {}
    function f.RegisterEvent() end
    function f.RegisterUnitEvent() end
    function f.SetScript(_, name, fn) scripts[name] = fn end
    return f
end
ScarletUI:SetupAutoShotClip()
assert(band.width == 100 and band.shown)
scripts.OnEvent(nil, "PLAYER_SWING", 1.6, Enum.PlayerSwingType.MainHand) -- melee swings are ignored
assert(band.width == 100)
scripts.OnEvent(nil, "PLAYER_SWING", 2.5, Enum.PlayerSwingType.Ranged)
assert(band.width == 80)
ranged, haste = 1.5, 50
scripts.OnEvent(nil, "UNIT_ATTACK_SPEED", "player")
assert(Near(band.width, 400 * 0.5 / 1.5 / 1.5))
ScarletUI.db.global.autoShotClip = false
hooks.OnSizeChanged()
assert(not band.shown)
ScarletUI.db.global.autoShotClip = true
ranged = nil -- ranged weapon unequipped
scripts.OnEvent(nil, "UNIT_INVENTORY_CHANGED", "player")
assert(not band.shown)

-- Only hunters get the band.
ScarletUI.autoShotClipBand = nil
UnitClass = function() return "Mage", "MAGE" end
ScarletUI:SetupAutoShotClip()
assert(ScarletUI.autoShotClipBand == nil)

SwingTimerRangedFrame, UnitAttackSpeed, GetRangedHaste = nil, nil, nil
print("PASS: Auto Shot clipping window share of the ranged swing, band width, toggle, and hunters only")
