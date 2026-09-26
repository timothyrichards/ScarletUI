-- Run from the addon root: lua tests/nameplates.lua
local function noop() end
local handlers = {}
LibStub = function() return { NotifyChange = noop } end
CreateFrame = function() return { SetScript = noop } end
ScarletUI = {
    defaults = { global = {}, char = {} },
    originalUIDefaults = { global = {}, char = {} },
    RegisterEventHandler = function(_, event, fn) handlers[event] = fn end,
}
dofile("Modules/Nameplates.lua")
ScarletUI.db = { global = { nameplatesModule = ScarletUI.defaults.global.nameplatesModule }, char = { priorityDebuffs = "" } }
local module = ScarletUI.db.global.nameplatesModule
ScarletUI:SetupNameplates()

-- Time only moves between scenarios, so per-second caches are reused within one.
local now, raid, members, names, threat, assignments, plates = 5
GetTime = function() return now end
wipe = function(t) for k in pairs(t) do t[k] = nil end end
IsInRaid = function() return raid end
IsInGroup = function() return members > 1 end
GetNumGroupMembers = function() return members end
UnitExists = function(unit) return names[unit] ~= nil end
UnitName = function(unit) return names[unit] end
UnitIsUnit = function(a, b) return names[a] ~= nil and names[a] == names[b] end
UnitIsPlayer = function() return false end
UnitIsTapDenied = function() return false end
GetPartyAssignment = function(_, name) return assignments[name] end
UnitDetailedThreatSituation = function(unit)
    local value = threat[names[unit]]
    if value then return value.tanking, value.status, nil, nil, value.amount end
end
UnitDebuff, UnitBuff = noop, noop
AbbreviateNumbers = tostring
Round = function(v) return math.floor(v + 0.5) end
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }

local function Plate()
    local plate = { UnitFrame = { healthBar = {
        SetStatusBarColor = function(self, ...) self.color = { ... } end,
        GetStatusBarColor = function(self) return unpack(self.color) end,
    } } }
    plate.threatAmountText = {
        SetTextColor = noop, Show = noop, Hide = noop,
        SetText = function(self, text) self.text = text end,
    }
    return plate
end

-- In a raid the player is also raidN; counting them twice made the tank lead 0.
raid, members, assignments = true, 2, {}
names = { player = "Me", Player = "Me", raid1 = "Me", raid2 = "Other", nameplate1 = "Boss" }
threat = { Me = { tanking = true, status = 3, amount = 10000 }, Other = { amount = 6000 } }
plates = { nameplate1 = Plate() }
assert(ScarletUI:UpdateNameplate("nameplate1"))
assert(plates.nameplate1.threatAmountText.text == "40", "raid tank lead counted the player twice")

-- Main tank assignments count for every player, not just the first one checked each second.
raid, members, assignments = false, 2, { Tank = true }
names = { player = "Me", Player = "Me", party1 = "Tank", nameplate1 = "Boss" }
threat = { Me = { status = 0, amount = 100 }, Tank = { amount = 5000 } }
plates = { nameplate1 = Plate() }
now = now + 10
ScarletUI:UpdateNameplate("nameplate1")
assert(plates.nameplate1.UnitFrame.healthBar.color[3] == module.nonTankThreatColors.tank[3], "main tank not detected")

-- Units without a nameplate or UnitFrame must not error, including special units.
module.specialUnitNames = "Boss"
ScarletUI:SetupNameplates()
ScarletUI.specialUnits = { Boss = true }
raid, members, threat, plates = false, 1, {}, {}
names = { player = "Me", Player = "Me", nameplate1 = "Boss" }
ScarletUI:UpdateNameplate("nameplate1")
module.healthBarText.show, module.castBarText.show = false, false
plates = { nameplate1 = {} }
handlers.NAME_PLATE_UNIT_ADDED(nil, "nameplate1")

-- Turning aura tracking off hides icons already on the plate.
local hidden = 0
local icon = { icon = { Hide = function() hidden = hidden + 1 end } }
plates = { nameplate1 = { myDebuffIcons = { Sunder = icon }, myBuffIcons = { Shield = icon } } }
module.debuffTracker.track, module.buffTracker.track = false, false
ScarletUI:CheckUnitAuras("nameplate1")
assert(hidden == 2 and next(plates.nameplate1.myDebuffIcons) == nil, "aura icons stayed after tracking was disabled")

print("PASS: nameplate raid threat lead, main tank detection, missing frames, and aura toggles")
