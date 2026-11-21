-- Run from the addon root: lua tests/nameplates.lua
local function noop() end
local handlers = {}
local client = "VANILLA"
local SECRET = {}
issecretvalue = function(v) return v == SECRET end
LibStub = function() return { NotifyChange = noop } end
CreateFrame = function() return { SetScript = noop } end
ScarletUI = {
    defaults = { global = {}, char = {} },
    originalUIDefaults = { global = {}, char = {} },
    RegisterEventHandler = function(_, event, fn) handlers[event] = fn end,
    GetWoWVersion = function() return client end,
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
        SetTextColor = noop, ClearAllPoints = noop, SetFont = noop,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        SetPoint = function(self, _, relativeTo) self.relativeTo = relativeTo end,
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

-- Classic keeps every settings tab.
local page = ScarletUI:GetNameplatesModuleSettingsPage(ScarletUI.db.global, ScarletUI.defaults.global.nameplatesModule, 7)
assert(page.args.auras and page.args.threatColors and page.args.text.args.healthBarText)

-- Forever (lightweight mode) only adds the threat numbers, beside Blizzard's own colors.
client, ScarletUI.lightWeightMode, ScarletUI.nameplateEventsRegistered, handlers = "FOREVER", true, nil, {}
module.healthBarText.show, module.castBarText.show, module.threatColored = true, true, false
CompactUnitFrame_UpdateHealthColor = noop
hooksecurefunc = function() error("Forever must not hook Blizzard's health colors") end
ScarletUI:SetupNameplates()
assert(handlers.NAME_PLATE_UNIT_ADDED and handlers.UNIT_THREAT_LIST_UPDATE)
assert(not handlers.UNIT_AURA and not handlers.PLAYER_TARGET_CHANGED, "Forever registered aura or arrow events")

raid, members, assignments = false, 2, {}
names = { player = "Me", Player = "Me", party1 = "Other", nameplate1 = "Boss" }
threat = { Me = { tanking = true, status = 3, amount = 10000 }, Other = { amount = 6000 } }
local plate = Plate()
plate.UnitFrame.healthBar.color = { 0.1, 0.2, 0.3 }
local createdText = plate.threatAmountText
plate.threatAmountText = nil
plate.CreateFontString = function() return createdText end
plate.UnitFrame.healthBar.CreateFontString = function() error("Forever added health text") end
plates = { nameplate1 = plate }
now = now + 10
handlers.NAME_PLATE_UNIT_ADDED(nil, "nameplate1")
assert(plate.threatAmountText.text == "40" and plate.threatAmountText.shown, "Forever threat number missing")
assert(plate.UnitFrame.healthBar.color[1] == 0.1, "Forever recolored Blizzard's health bar")
assert(plate.threatAmountText.relativeTo == plate.UnitFrame.healthBar)

-- Blizzard moves pooled UnitFrames between nameplates; the number follows the current health bar.
local oldBar = plate.UnitFrame.healthBar
plate.UnitFrame = Plate().UnitFrame
plate.UnitFrame.healthBar.color = { 1, 0, 0 }
ScarletUI:UpdateNameplate("nameplate1")
assert(plate.threatAmountText.relativeTo == plate.UnitFrame.healthBar and plate.UnitFrame.healthBar ~= oldBar)

-- Turning the threat text off keeps it hidden through later threat updates.
module.threatAmountText.show = false
ScarletUI:UpdateNameplate("nameplate1")
assert(not plate.threatAmountText.shown, "threat text came back after it was turned off")
module.threatAmountText.show = true

-- Restricted (secret) threat hides the number instead of erroring on comparisons.
threat.Me.amount = SECRET
ScarletUI:UpdateNameplate("nameplate1")
assert(not plate.threatAmountText.shown, "secret threat left the number shown")
threat.Me.amount, threat.Other.amount = 10000, SECRET
ScarletUI:UpdateNameplate("nameplate1")
assert(plate.threatAmountText.shown, "another member's secret threat hid the player's number")

-- Forever's settings page keeps only the switch and threat text.
page = ScarletUI:GetNameplatesModuleSettingsPage(ScarletUI.db.global, ScarletUI.defaults.global.nameplatesModule, 7)
assert(not page.hidden() and page.args.enabled and page.args.text.args.threatAmountText)
assert(not page.args.auras and not page.args.threatColors and not page.args.specialUnits and not page.args.targetIndicator)
assert(not page.args.classColored and not page.args.text.args.healthBarText and not page.args.text.args.castBarText)
-- Retail stays hidden if the file ever loads there.
client = "RETAIL"
assert(ScarletUI:GetNameplatesModuleSettingsPage(ScarletUI.db.global, ScarletUI.defaults.global.nameplatesModule, 7).hidden())
client, ScarletUI.lightWeightMode, hooksecurefunc, CompactUnitFrame_UpdateHealthColor, issecretvalue = "VANILLA", nil, nil, nil, nil

-- Non-nameplate tokens (targettarget etc.) must never reach GetNamePlateForUnit, which errors on them.
local badLookups = 0
C_NamePlate = { GetNamePlateForUnit = function(unit)
    if not unit:match("^nameplate%d+$") then badLookups = badLookups + 1 end
    return plates[unit]
end }
module.debuffTracker.track, module.buffTracker.track = true, true
names = { player = "Me", targettarget = "Boss", target = "Boss", nameplate1 = "Boss" }
plates = { nameplate1 = Plate() }
ScarletUI:UpdateNameplate("targettarget")
ScarletUI:CheckUnitAuras("targettarget")
ScarletUI:CheckUnitAuras("player")
if handlers.UNIT_AURA then handlers.UNIT_AURA(nil, "targettarget") end
handlers.UNIT_THREAT_LIST_UPDATE(nil, "targettarget")
handlers.UNIT_THREAT_LIST_UPDATE(nil, "target")
assert(badLookups == 0, "non-nameplate token reached GetNamePlateForUnit")

print("PASS: nameplate raid threat lead, main tank detection, missing frames, aura toggles, and Forever threat numbers")
