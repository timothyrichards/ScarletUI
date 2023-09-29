local allstates = {}
local otherTanks = {}

local function split(input)
    input = input or ""
    local ret = {}
    local split, element = true
    split = input:find("[,%s]")
    while(split) do
        element, input = input:sub(1, split-1), input:sub(split+1)
        if(element ~= "") then
            ret[element] = true
        end
        split = input:find("[,%s]")
    end
    if(input ~= "") then
        ret[input] = true
    end
    return ret
end

local function IterateGroupMembers()
    local i = 0
    local max = IsInRaid() and GetNumGroupMembers() or IsInGroup() and GetNumGroupMembers() or 1
    local prefix = IsInRaid() and "raid" or "party"

    return function()
        i = i + 1
        if i == 1 then
            return "player"
        elseif i <= max + 1 then
            return prefix .. (i - 1)
        end
    end
end

local function ThreatFunc(unit)
    local firstUnit, secondUnit
    local firstThreat, secondThreat = -1, -1  -- Initialize with values less than zero
    local threat, pet

    for member in IterateGroupMembers() do
        threat = select(5, UnitDetailedThreatSituation(member, unit))

        if threat then
            if threat > firstThreat then
                secondUnit = firstUnit
                secondThreat = firstThreat
                firstUnit = member
                firstThreat = threat
            elseif threat > secondThreat then
                secondUnit = member
                secondThreat = threat
            end
        end

        pet = member.."pet"
        if UnitExists(pet) then
            threat = select(5, UnitDetailedThreatSituation(pet, unit))

            if threat then
                if threat > firstThreat then
                    secondUnit = firstUnit
                    secondThreat = firstThreat
                    firstUnit = pet
                    firstThreat = threat
                elseif threat > secondThreat then
                    secondUnit = pet
                    secondThreat = threat
                end
            end
        end
    end

    return firstUnit, firstThreat, secondUnit, secondThreat
end

local function IsTank(playerName)
    -- In WotLK Classic, check if the player has the tank role
    if UnitGroupRolesAssigned then
        local role = UnitGroupRolesAssigned(playerName)
        if role == "TANK" then
            return true
        end
    end

    -- If not in WotLK Classic or no roles assigned, check if the player's name is in the otherTanks list
    return otherTanks[playerName]
end

function ScarletUI:SetupTanks()
    local nameplatesModule = self.db.global.nameplatesModule
    otherTanks = split(nameplatesModule.tankNames)
end

function ScarletUI:SetupNameplates()
    local nameplatesModule = self.db.global.nameplatesModule
    if not nameplatesModule.enabled or self.inCombat then
        return
    end

    self:SetupTanks(nameplatesModule)
    self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self.frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    self.frame:HookScript("OnEvent", function(_, event, unitId)
        if not unitId or not UnitExists(unitId) then
            return
        end

        if event == "NAME_PLATE_UNIT_REMOVED" then
            local state = allstates[unitId]
            if state then
                state.show = false
                state.changed = true
                return true
            end
        else
            local isTanking, threatStatus, _, _, threatValue = UnitDetailedThreatSituation("player", unitId)
            local firstUnit, firstThreat, secondUnit, secondThreat = ThreatFunc(unitId)
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
            local displayValue

            if not nameplate then
                return
            end

            local threatColorGroup = nameplatesModule.nonTankThreatColors
            if IsTank(UnitName("Player")) then
                threatColorGroup = nameplatesModule.tankThreatColors
            end

            if firstUnit and IsTank(UnitName(firstUnit)) and not UnitIsUnit(firstUnit, "Player") then
                threatStatus = 4
            end

            if UnitIsPlayer(unitId) then
                local _, class = UnitClass(unitId)
                local color = RAID_CLASS_COLORS[class]
                nameplate.UnitFrame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
            elseif UnitIsTapDenied(unitId) then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
            elseif threatStatus == nil then
                local red, green, blue, alpha = UnitSelectionColor(unitId, true)
                nameplate.UnitFrame.healthBar:SetStatusBarColor(red, green, blue, alpha)
            elseif threatStatus == 0 or threatStatus == 1 then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.noThreat))
            elseif threatStatus == 2 then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.lowThreat))
            elseif threatStatus == 3 then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.threat))
            elseif threatStatus == 4 then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.tank))
            end

            if not threatValue then
                return
            end

            if isTanking then
                displayValue = threatValue - secondThreat
            else
                displayValue = threatValue - firstThreat
                if firstUnit and not UnitIsUnit(firstUnit, "Player") and otherTanks[UnitName(firstUnit)] then
                    threatStatus = 4
                end
            end

            allstates[unitId] = allstates[unitId] or {unit = unitId}
            local state = allstates[unitId]
            state.changed = true
            if string.find(unitId, "nameplate") then
                state.show = true
            else
                state.show = false
            end
            state.status = threatStatus < 1 and 1 or threatStatus
            state.value = Round(math.abs(displayValue) / 100)

            return true
        end
    end)
end
