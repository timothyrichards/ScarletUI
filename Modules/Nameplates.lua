local allStates = {}
local tanks = {}
local specialUnits = {}
local lastNameplate

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function split(input)
    input = input or ""
    local ret = {}

    for element in input:gmatch("[^,]+") do
        element = trim(element)
        if element ~= "" then
            ret[element] = true
        end
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
    local mainTank = GetPartyAssignment("MAINTANK", playerName)
    local mainAssist = GetPartyAssignment("MAINASSIST", playerName)

    -- Check if the player has the tank role
    if mainTank or mainAssist then
        return true
    end

    if UnitGroupRolesAssigned then
        local role = UnitGroupRolesAssigned(playerName)
        if role == "TANK" then
            return true
        end
    end

    -- If not in WotLK Classic or no roles assigned, check if the player's name is in the otherTanks list
    return tanks[playerName]
end

local function HideTargetArrows()
    if lastNameplate and lastNameplate.leftArrow and lastNameplate.rightArrow then
        lastNameplate.leftArrow:Hide()
        lastNameplate.rightArrow:Hide()
    end
end

function ScarletUI:UpdateCastText(castBar)
    if castBar then
        local abilityName = castBar.Text and castBar.Text:GetText()
        if castBar.castBarText then
            castBar.castBarText:SetText(abilityName)
        end
    end
end

function ScarletUI:UpdateHealthText(healthBar)
    if healthBar then
        local unitID = healthBar:GetParent().unit or healthBar.unit
        local healthPercent = (UnitHealth(unitID) / UnitHealthMax(unitID)) * 100;
        if healthBar.healthBarText then
            healthBar.healthBarText:SetText(string.format("%.0f%%", healthPercent))
        end
    end
end

local function SetupNameplate(nameplate)
    local module = ScarletUI.db.global.nameplatesModule
    if not module.castBarText.show then
        return
    end

    local castBar = nameplate.UnitFrame and nameplate.UnitFrame.CastBar
    if castBar then
        -- Create a font string if it doesn't exist
        if not castBar.castBarText then
            castBar.castBarText = castBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            castBar.castBarText:SetPoint("CENTER")
            castBar.castBarText:SetFont("Fonts\\FRIZQT__.TTF", module.castBarText.fontSize, "OUTLINE")
        end
        ScarletUI:UpdateCastText(castBar)

        -- Hook into the OnValueChanged script to update the text during casting
        if not castBar.castBarTextHooked then
            castBar:HookScript("OnValueChanged", function(self)
                ScarletUI:UpdateCastText(self)
            end)
            castBar.castBarTextHooked = true
        end
    end

    if not module.healthBarText.show then
        return
    end

    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if healthBar then
        if not healthBar.healthBarText then
            healthBar.healthBarText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            healthBar.healthBarText:SetPoint("CENTER")
            healthBar.healthBarText:SetFont("Fonts\\FRIZQT__.TTF", module.healthBarText.fontSize, "OUTLINE")
        end
    end
    ScarletUI:UpdateHealthText(healthBar)

    -- Hook into the OnValueChanged script to update the text during casting
    if not healthBar.healthBarTextHooked then
        healthBar:HookScript("OnValueChanged", function(self)
            ScarletUI:UpdateHealthText(self)
        end)
        healthBar.healthBarTextHooked = true
    end
end

function ScarletUI:UpdateTargetArrows()
    local module = ScarletUI.db.global.nameplatesModule
    if not module.targetIndicator.show then
        HideTargetArrows()
        return
    end

    -- Hide arrows on the previous nameplate
    HideTargetArrows()

    local nameplate = C_NamePlate.GetNamePlateForUnit("target")
    if nameplate then
        -- Get the name text region of the nameplate.
        local healthBarRegion = nameplate and nameplate.UnitFrame and nameplate.UnitFrame.healthBar.border
        local size = module.targetIndicator.indicatorSize
        local spacer = module.targetIndicator.indicatorDistance * -1
        local height = module.targetIndicator.indicatorHeight

        if healthBarRegion then
            -- Left texture
            local leftTexture = nameplate:CreateTexture(nil, "OVERLAY")
            leftTexture:SetTexture("interface/minimap/minimaparrow.blp")
            leftTexture:SetSize(size, size)
            leftTexture:SetPoint("RIGHT", healthBarRegion, "LEFT", spacer, height)
            leftTexture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
            nameplate.leftArrow = leftTexture

            -- Right texture
            local rightTexture = nameplate:CreateTexture(nil, "OVERLAY")
            rightTexture:SetTexture("interface/minimap/minimaparrow.blp")
            rightTexture:SetSize(size, size)
            rightTexture:SetPoint("LEFT", healthBarRegion, "RIGHT", spacer * -1, height)
            rightTexture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
            nameplate.rightArrow = rightTexture
        end

        lastNameplate = nameplate
    end
end

function ScarletUI:SetupTanks()
    local nameplatesModule = self.db.global.nameplatesModule
    tanks = split(nameplatesModule.tankNames)
end

function ScarletUI:SetupSpecialUnits()
    local nameplatesModule = self.db.global.nameplatesModule
    specialUnits = split(nameplatesModule.specialUnitNames)
end

function ScarletUI:SetupNameplates()
    local nameplatesModule = self.db.global.nameplatesModule
    if not nameplatesModule.enabled or self.inCombat then
        return
    end

    self:SetupTanks()
    self:SetupSpecialUnits()
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("UNIT_AURA")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self.frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    self.frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    self.frame:HookScript("OnEvent", function(_, event, unitId)
        if event == "PLAYER_TARGET_CHANGED" then
            ScarletUI:UpdateTargetArrows()
        elseif event == "UNIT_AURA" then
            ScarletUI:CheckUnitDebuffs(nameplatesModule.debuffTracker)
        else
            if not unitId or not UnitExists(unitId) then
                return
            end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
            local unitName, _ = UnitName(unitId)
            if event == "NAME_PLATE_UNIT_ADDED" then
                ScarletUI:UpdateTargetArrows()
                if nameplate then
                    SetupNameplate(nameplate)
                end
            end

            if specialUnits[unitName] and nameplate.UnitFrame then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(nameplatesModule.specialUnitColor))
                return
            end

            if event == "NAME_PLATE_UNIT_REMOVED" then
                local state = allStates[unitId]
                if state then
                    state.show = false
                    state.changed = true
                    return true
                end
            else
                local isTanking, threatStatus, _, _, threatValue = UnitDetailedThreatSituation("player", unitId)
                local firstUnit, firstThreat, _, secondThreat = ThreatFunc(unitId)

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

                if UnitIsPlayer(unitId) and nameplatesModule.classColored then
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
                    if firstUnit and not UnitIsUnit(firstUnit, "Player") and tanks[UnitName(firstUnit)] then
                        threatStatus = 4
                    end
                end

                allStates[unitId] = allStates[unitId] or { unit = unitId}
                local state = allStates[unitId]
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
        end
    end)
end

-- List all nameplates and check if the specified debuff is present on the unit the nameplate belongs to
function ScarletUI:CheckUnitDebuffs(settings)
    if not settings.track then
        return
    end

    local nameplates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(nameplates) do
        plate.myDebuffIcons = plate.myDebuffIcons or {}
        plate.myDebuffNames = plate.myDebuffNames or {}

        local unit = plate.namePlateUnitToken
        local i = 1
        local debuffName, icon, _, _, _, _, source = UnitDebuff(unit, i) -- including icon in the unpacking

        -- store and display debuffs for each unit
        local plateDebuffs = {}
        while debuffName do
            if source == "player" then
                plateDebuffs[debuffName] = true
                ScarletUI:DisplayDebuffIcon(settings, plate, debuffName, icon, i) -- passing icon along
            end
            i = i + 1
            debuffName, icon, _, _, _, _, source = UnitDebuff(unit, i) -- including icon in the unpacking
        end

        -- Remove icons for debuffs no longer on the unit
        for name, _icon in pairs(plate.myDebuffIcons) do
            if not plateDebuffs[name] then
                _icon.icon:Hide()
                plate.myDebuffIcons[name] = nil
            end
        end

        -- Sort and reposition the icons based on remaining duration
        local sortedDebuffs = {}
        for _, debuffData in pairs(plate.myDebuffIcons) do
            if debuffData.icon:IsShown() then
                table.insert(sortedDebuffs, debuffData)
            end
        end

        -- Sorting the table in ascending order of expireTime.
        table.sort(sortedDebuffs, function(a, b) return a.expireTime < b.expireTime end)

        -- Reposition icons
        local shownCount = 0
        local totalWidth = #sortedDebuffs * (settings.iconSize + settings.spacing)
        for _, debuffData in ipairs(sortedDebuffs) do
            debuffData.icon:Hide()

            local xOffset = (shownCount * (settings.iconSize + settings.spacing)) - totalWidth / 2
            debuffData.icon:SetPoint('BOTTOMLEFT', plate, 'CENTER' , xOffset, settings.verticalOffset)
            debuffData.icon:Show()
            shownCount = shownCount + 1
        end
    end
end

-- Display debuff icon on the provided nameplate.
function ScarletUI:DisplayDebuffIcon(settings, plate, debuffName, icon, debuffIndex)
    if not plate.myDebuffIcons then
        plate.myDebuffIcons = {}
    end

    local debuffIcon
    local _, _, count, _, duration, expireTime = UnitDebuff(plate.namePlateUnitToken, debuffIndex)

    if not plate.myDebuffIcons[debuffName] then
        debuffIcon = CreateFrame("Frame", "_SUI_C_"..debuffName, plate)
        debuffIcon:SetSize(settings.iconSize, settings.iconSize)

        debuffIcon.icon = debuffIcon:CreateTexture("_SUI_I_"..debuffName)
        debuffIcon.icon:SetAllPoints()
        debuffIcon.icon:SetTexture(icon)

        debuffIcon.cooldown = CreateFrame("Cooldown", "_SUI_C_"..debuffName, debuffIcon, "CooldownFrameTemplate")
        debuffIcon.cooldown:SetAllPoints()
        debuffIcon.cooldown:SetReverse(true)

        debuffIcon.stack = debuffIcon:CreateFontString("_SUI_S_"..debuffName, "OVERLAY", "NumberFontNormal")
        debuffIcon.stack:SetPoint("BOTTOMRIGHT", -2, 2)

        local fontName, _, fontFlags = debuffIcon.stack:GetFont()
        debuffIcon.stack:SetFont(fontName, 11, fontFlags)
        plate.myDebuffIcons[debuffName] = { icon = debuffIcon, expireTime = expireTime }
    else
        debuffIcon = plate.myDebuffIcons[debuffName].icon
        plate.myDebuffIcons[debuffName].expireTime = expireTime
    end

    if count and tonumber(count) >= 1 then
        debuffIcon.stack:SetText(count)
    end

    local startTime = expireTime - duration
    debuffIcon.cooldown:SetCooldown(startTime, duration)
    debuffIcon:Show()
end
