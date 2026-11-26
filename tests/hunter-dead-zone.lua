-- Run from the addon root: lua tests/hunter-dead-zone.lua
-- Hunter dead zone: the range readings that make it, and the overlay on the ranged swing timer.
ScarletUI = { db = { global = { hunterDeadZone = true } } }
local SECRET = {}
issecretvalue = function(v) return v == SECRET end -- FrameTweaks reads it at load
dofile("Modules/FrameTweaks.lua")

local hostile, dead, swingMelee, raptor, shot, close
local asked = {}
UnitCanAttack = function() return hostile end
UnitIsDeadOrGhost = function() return dead end
C_SwingTimer = { IsTargetWithinSwingRange = function(swingType)
    assert(swingType == 0)
    return swingMelee
end }
C_Spell = {
    GetSpellName = function(id) return id == 2973 and "Raptor Strike" or nil end,
    IsSpellInRange = function(spell, unit)
        assert(unit == "target")
        if spell == 75 then return shot end
        assert(spell == "Raptor Strike")
        return raptor
    end,
}
CheckInteractDistance = function(unit, index)
    assert(unit == "target" and index == 2)
    asked.close = true
    return close
end
-- Defaults to the dead zone; each case then changes what it tests.
local function Reset()
    hostile, dead, swingMelee, raptor, shot, close = true, false, false, nil, false, true
    asked.close = nil
end
local InDeadZone = ScarletUI.TargetInDeadZone

Reset()
assert(InDeadZone() == true)                                     -- 5-8 yd
Reset() shot = true assert(InDeadZone() == false)             -- 8-35 yd
assert(not asked.close)                                          -- no distance check needed
Reset() swingMelee = true assert(InDeadZone() == false)            -- in melee
Reset() close = false assert(InDeadZone() == false)           -- past 35 yd
Reset() hostile = false assert(InDeadZone() == false)         -- friendly or no target
Reset() hostile = nil assert(InDeadZone() == false)
Reset() dead = true assert(InDeadZone() == false)
-- Unknown or secret readings never count as out of range.
Reset() shot = nil assert(InDeadZone() == false)              -- no ranged weapon
Reset() shot = SECRET assert(InDeadZone() == false)
Reset() swingMelee = SECRET raptor = SECRET assert(InDeadZone() == false)
Reset() close = SECRET assert(InDeadZone() == false)
Reset() hostile = SECRET assert(InDeadZone() == false)
-- Without a melee weapon the swing check is nil; Raptor Strike's range stands in.
Reset() swingMelee = nil raptor = false assert(InDeadZone() == true)
Reset() swingMelee = nil raptor = true assert(InDeadZone() == false)
Reset() swingMelee = nil raptor = nil assert(InDeadZone() == false)
C_SwingTimer = nil
Reset() raptor = false assert(InDeadZone() == true)
Reset() raptor = true assert(InDeadZone() == false)
C_SwingTimer = { IsTargetWithinSwingRange = function() return swingMelee end }

-- The overlay: hunters only, polled only with a hostile target, follows the toggle.
local function Region()
    local r = {}
    function r.SetAllPoints() end
    function r.SetPoint() end
    function r.SetColorTexture() end
    function r.SetText(_, text) r.text = text end
    return r
end
local overlay, poll
local frames = {}
CreateFrame = function(_, _, parent)
    local f = Region()
    f.parent, f.scripts, f.shown = parent, {}, true
    function f.Show() f.shown = true end
    function f.Hide() f.shown = false end
    function f.SetShown(_, on) f.shown = on and true or false end
    function f.SetFrameLevel(_, level) f.level = level end
    function f.CreateTexture() return Region() end
    function f.CreateFontString() f.label = Region() return f.label end
    function f.RegisterEvent() end
    function f.RegisterUnitEvent() end
    function f.SetScript(_, name, fn) f.scripts[name] = fn end
    frames[#frames + 1] = f
    return f
end
local bar = { GetFrameLevel = function() return 3 end }
SwingTimerRangedFrame = { StatusBar = bar }
UnitClass = function() return "Mage", "MAGE" end
ScarletUI:SetupHunterDeadZone()
assert(ScarletUI.hunterDeadZoneOverlay == nil and #frames == 0)

UnitClass = function() return "Hunter", "HUNTER" end
Reset() hostile = false
ScarletUI:SetupHunterDeadZone()
overlay, poll = frames[1], frames[2]
assert(overlay == ScarletUI.hunterDeadZoneOverlay and overlay.parent == SwingTimerRangedFrame)
assert(overlay.level > 3 and overlay.label.text == "Dead zone")
assert(not overlay.shown and poll.scripts.OnUpdate == nil)       -- no target: no polling

Reset()
poll.scripts.OnEvent(poll, "PLAYER_TARGET_CHANGED")
assert(overlay.shown and poll.scripts.OnUpdate)                  -- checked at once, then polled
Reset() shot = true
poll.scripts.OnUpdate(poll, 0.05)
assert(overlay.shown)                                            -- throttled
poll.scripts.OnUpdate(poll, 0.06)
assert(not overlay.shown)                                        -- stepped out to range
Reset()
poll.scripts.OnUpdate(poll, 0.1)
assert(overlay.shown)

ScarletUI.db.global.hunterDeadZone = false
ScarletUI.UpdateHunterDeadZone()
assert(not overlay.shown and poll.scripts.OnUpdate == nil)
ScarletUI.db.global.hunterDeadZone = true
ScarletUI.UpdateHunterDeadZone()
assert(overlay.shown)

Reset() hostile = false
poll.scripts.OnEvent(poll, "UNIT_FACTION", "target")
assert(not overlay.shown and poll.scripts.OnUpdate == nil)

-- Set up once.
ScarletUI:SetupHunterDeadZone()
assert(#frames == 2)

SwingTimerRangedFrame, C_SwingTimer, C_Spell, CheckInteractDistance, issecretvalue = nil, nil, nil, nil, nil
UnitCanAttack, UnitIsDeadOrGhost = nil, nil
print("PASS: hunter dead zone range readings, secret and unknown values, Raptor Strike fallback, overlay polling, toggle, and hunters only")
