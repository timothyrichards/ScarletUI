-- Run from the addon root: lua tests/nameplates.lua
local function noop() end
local handlers = {}
local client = "VANILLA"
-- The module keeps its own reference to issecretvalue, so later secrets are added to this set.
local SECRET = {}
local secretSet = { [SECRET] = true }
issecretvalue = function(v) return secretSet[v] == true end
LibStub = function() return { NotifyChange = noop } end
local onUpdate
CreateFrame = function() return { SetScript = function(_, script, fn) if script == "OnUpdate" then onUpdate = onUpdate or fn end end } end
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
    if value then return value.tanking, value.status, nil, value.raw, value.amount end
end
UnitThreatSituation = function(unit) local value = threat[names[unit]] return value and value.situation end
UnitThreatPercentageOfLead = function(unit) local value = threat[names[unit]] return value and value.lead end
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
        IsShown = function(self) return self.shown end,
        Hide = function(self) self.shown = false end,
        SetPoint = function(self, _, relativeTo) self.relativeTo = relativeTo end,
        SetText = function(self, text) self.text = text end,
        SetFormattedText = function(self, fmt, value) self.format, self.text = fmt, value end,
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

-- Restricted (secret) threat can't be compared or subtracted (SECRET errors if it is), so the
-- number falls back to the game's own percentage, passed straight to the font string.
local secretMeta = { __lt = function() error("compared a secret") end, __le = function() error("compared a secret") end,
    __sub = function() error("subtracted a secret") end, __eq = function() error("compared a secret") end }
setmetatable(SECRET, secretMeta)
local function Percent(expected, message)
    plate.threatAmountText.text, plate.threatAmountText.shown = nil, nil
    ScarletUI:UpdateNameplate("nameplate1")
    assert(plate.threatAmountText.shown and plate.threatAmountText.format == "%.0f%%", message)
    assert(rawequal(plate.threatAmountText.text, expected), message)
end
local secretRaw, secretLead = setmetatable({}, secretMeta), setmetatable({}, secretMeta)
secretSet[secretRaw], secretSet[secretLead] = true, true
-- Everything secret: no tanking status to go on, so the raw percent of the tank's threat.
threat.Me = { tanking = SECRET, status = SECRET, raw = secretRaw, amount = SECRET, situation = SECRET, lead = secretLead }
Percent(secretRaw, "all-secret threat didn't show the raw percent")
-- A readable threat situation says we're tanking: show the lead percent instead.
threat.Me.situation = 3
Percent(secretLead, "secret tank threat didn't show the lead percent")
threat.Me.situation = 1
Percent(secretRaw, "secret non-tank threat didn't show the raw percent")
-- Not on the threat list at all.
threat.Me.situation = nil
ScarletUI:UpdateNameplate("nameplate1")
assert(not plate.threatAmountText.shown, "number shown for a unit we're not on the threat list of")
-- Only other members' threat is secret: the lead can't be worked out, so use the percent.
threat.Me = { tanking = true, status = 3, raw = 100, amount = 10000, lead = 167 }
threat.Other.amount = SECRET
Percent(167, "another member's secret threat didn't fall back to the lead percent")
threat.Me.tanking, threat.Me.status = false, 1
Percent(100, "another member's secret threat didn't fall back to the raw percent")
threat.Me.raw = 0
ScarletUI:UpdateNameplate("nameplate1")
assert(not plate.threatAmountText.shown, "0% threat was shown")
threat.Me, threat.Other.amount = { tanking = true, status = 3, amount = 10000 }, 6000
ScarletUI:UpdateNameplate("nameplate1")
assert(plate.threatAmountText.text == "40", "readable threat lost the lead amount")

-- Secret unit tokens on threat events refresh every plate, and Forever also refreshes on a timer.
local updated = {}
local realUpdate = ScarletUI.UpdateNameplate
ScarletUI.UpdateNameplate = function(_, unitId) updated[unitId] = (updated[unitId] or 0) + 1 end
handlers.UNIT_THREAT_LIST_UPDATE(nil, SECRET)
onUpdate(nil, 0.11)
assert(updated.nameplate1 == 1, "secret threat event didn't refresh the plates")
updated = {}
for _ = 1, 5 do onUpdate(nil, 0.11) end
assert(updated.nameplate1 == 1, "Forever plates weren't refreshed on the timer")
ScarletUI.UpdateNameplate = realUpdate

-- A removed plate drops its number so the next unit on it doesn't inherit it.
plate.threatAmountText:Show()
handlers.NAME_PLATE_UNIT_REMOVED(nil, "nameplate1")
assert(not plate.threatAmountText.shown, "removed plate kept its threat number")

-- If our NAME_PLATE_UNIT_ADDED runs before Blizzard hands out a UnitFrame, the text is made on the next update.
local late = Plate()
local lateText = late.threatAmountText
late.threatAmountText, late.CreateFontString = nil, function() return lateText end
local lateFrame = late.UnitFrame
late.UnitFrame = nil
lateFrame.healthBar.color = { 1, 1, 1 }
plates = { nameplate1 = late }
handlers.NAME_PLATE_UNIT_ADDED(nil, "nameplate1")
late.UnitFrame = lateFrame
ScarletUI:UpdateNameplate("nameplate1")
assert(late.threatAmountText and late.threatAmountText.shown and late.threatAmountText.text == "40", "late UnitFrame never got a number")
plates = { nameplate1 = plate }
setmetatable(SECRET, nil)

-- /sui threatdebug prints without erroring on secrets.
local printed = {}
ScarletUI.Print = function(_, line) printed[#printed + 1] = line end
threat.Me = { tanking = SECRET, status = SECRET, raw = SECRET, amount = SECRET, situation = SECRET }
ScarletUI:PrintThreatDebug()
assert(#printed >= 2 and table.concat(printed, " "):find("SECRET"), "threatdebug output missing")
threat.Me = { tanking = true, status = 3, amount = 10000 }

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
